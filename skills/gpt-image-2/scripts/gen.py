#!/usr/bin/env python3
"""Generate or edit an image with OpenAI's GPT Image API (default model: gpt-image-2).

Text-to-image goes to POST /v1/images/generations; with one or more --ref images
it goes to POST /v1/images/edits (multipart, each reference as image[]).
Standard library only — no pip install needed.

Usage:
  gen.py --prompt "<text>" --out <path.png> [--ref <image>]... [--size WxH|auto]
         [--quality low|medium|high|auto] [--model <id>] [--background auto|opaque|transparent]
         [--format png|jpeg|webp] [--timeout-sec N]

Environment:
  OPENAI_API_KEY      required — the key is read from the environment only, never printed
  OPENAI_BASE_URL     optional — default https://api.openai.com/v1 (a compatible proxy also works)
  OPENAI_ORG_ID       optional — sent as OpenAI-Organization
  OPENAI_IMAGE_MODEL  optional — default model when --model is not given

Exit codes:
  0 success (output path printed on stdout)
  2 bad args
  3 OPENAI_API_KEY not set
  4 reference image not found
  5 API returned an error (auth, quota, moderation, bad parameter)
  6 network error or timeout
  7 response contained no image
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import pathlib
import sys
import urllib.error
import urllib.request
import uuid

DEFAULT_MODEL = "gpt-image-2"
STANDARD_SIZES = ((1024, 1024), (1536, 1024), (1024, 1536))


def fail(code: int, message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(code)


def nearest_standard_size(size: str) -> str:
    """Map a custom WxH to the standard size with the closest aspect ratio."""
    try:
        w, h = (int(x) for x in size.lower().split("x"))
    except ValueError:
        return "1024x1024"
    ratio = w / h
    best = min(STANDARD_SIZES, key=lambda s: abs(s[0] / s[1] - ratio))
    return f"{best[0]}x{best[1]}"


def multipart(fields: dict[str, str], files: list[tuple[str, pathlib.Path]]) -> tuple[bytes, str]:
    boundary = f"----gptimage{uuid.uuid4().hex}"
    parts: list[bytes] = []
    for name, value in fields.items():
        parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode()
        )
    for name, path in files:
        ctype = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        header = (
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; '
            f'filename="{path.name}"\r\nContent-Type: {ctype}\r\n\r\n'
        ).encode()
        parts.append(header + path.read_bytes() + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def call_api(url: str, body: bytes, content_type: str, timeout: int) -> dict:
    headers = {
        "Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}",
        "Content-Type": content_type,
    }
    if os.environ.get("OPENAI_ORG_ID"):
        headers["OpenAI-Organization"] = os.environ["OPENAI_ORG_ID"]
    request = urllib.request.Request(url, data=body, headers=headers, method="POST")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def api_error_message(err: urllib.error.HTTPError) -> str:
    try:
        payload = json.loads(err.read().decode("utf-8"))
        return payload.get("error", {}).get("message") or str(payload)
    except (ValueError, OSError):
        return err.reason or "unknown error"


def request_image(args: argparse.Namespace, size: str) -> dict:
    base_url = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
    params = {
        "model": args.model,
        "prompt": args.prompt,
        "n": "1",
        "size": size,
        "quality": args.quality,
        "output_format": args.format,
    }
    if args.background:
        params["background"] = args.background

    if args.ref:
        body, ctype = multipart(params, [("image[]", p) for p in args.ref])
        return call_api(f"{base_url}/images/edits", body, ctype, args.timeout_sec)

    params["n"] = 1
    body = json.dumps(params).encode("utf-8")
    return call_api(f"{base_url}/images/generations", body, "application/json", args.timeout_sec)


def main() -> None:
    parser = argparse.ArgumentParser(description="GPT Image generation / edit via the OpenAI API.")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--ref", action="append", default=[], help="reference image (repeatable)")
    parser.add_argument("--size", default="auto", help="WxH or auto (default auto)")
    parser.add_argument("--quality", default="auto", choices=["low", "medium", "high", "auto"])
    parser.add_argument("--model", default=os.environ.get("OPENAI_IMAGE_MODEL", DEFAULT_MODEL))
    parser.add_argument("--background", choices=["auto", "opaque", "transparent"])
    parser.add_argument("--format", default="png", choices=["png", "jpeg", "webp"])
    parser.add_argument("--timeout-sec", type=int, default=300)
    try:
        args = parser.parse_args()
    except SystemExit as exc:
        sys.exit(0 if exc.code == 0 else 2)

    if not os.environ.get("OPENAI_API_KEY"):
        fail(3, "OPENAI_API_KEY is not set. Export it (or add it to your shell profile) and retry.")

    refs = []
    for ref in args.ref:
        path = pathlib.Path(ref)
        if not path.is_file():
            fail(4, f"Reference image not found: {ref}")
        refs.append(path)
    args.ref = refs

    out = pathlib.Path(args.out).expanduser().resolve()
    out.parent.mkdir(parents=True, exist_ok=True)

    size = args.size
    try:
        try:
            result = request_image(args, size)
        except urllib.error.HTTPError as err:
            message = api_error_message(err)
            # Some models accept only the standard sizes: retry once with the closest one.
            if err.code == 400 and size != "auto" and "size" in message.lower():
                size = nearest_standard_size(size)
                print(f"Size {args.size} rejected ({message}); retrying with {size}.", file=sys.stderr)
                result = request_image(args, size)
            else:
                raise
    except urllib.error.HTTPError as err:
        fail(5, f"OpenAI API error {err.code}: {api_error_message(err)}")
    except (urllib.error.URLError, TimeoutError, OSError) as err:
        fail(6, f"Network error or timeout calling the OpenAI API: {err}")

    data = (result.get("data") or [{}])[0]
    b64 = data.get("b64_json")
    if not b64:
        fail(7, f"The response contained no image (keys: {sorted(result)}).")

    out.write_bytes(base64.b64decode(b64))
    usage = result.get("usage")
    if usage:
        print(f"usage: {json.dumps(usage)}", file=sys.stderr)
    print(out)


if __name__ == "__main__":
    main()
