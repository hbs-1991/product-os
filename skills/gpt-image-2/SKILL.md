---
name: gpt-image-2
description: "Generate and edit images with OpenAI's GPT Image 2 (model gpt-image-2) by one of two backends: the OpenAI Images API with your own OPENAI_API_KEY (dependency-free Python script), or the local Codex CLI logged in to a ChatGPT Plus/Pro plan (no API key, no per-image billing) — text-to-image, image-to-image editing, style transfer and multi-reference composition. Used by ui-mockup / ui-mocker for screen mocks; also triggers on 'gpt image 2', 'gpt-image-2', 'ChatGPT Images 2.0', 'image 2', or an explicit ask to generate or edit an image with OpenAI or through the user's ChatGPT plan."
---


# GPT Image 2 — image generation, two backends

| Backend | Script | Needs | Billing |
|---|---|---|---|
| **API** | `scripts/gen.py` | `OPENAI_API_KEY` (Python 3.8+, standard library only) | per image, to the key's account |
| **Codex CLI** | `scripts/gen.sh` | `codex` installed and logged in (`codex login`) with a ChatGPT Plus/Pro plan that includes image generation; bash + Python 3.8+ | none beyond the subscription |

## Which backend

1. The user named one ("use my ChatGPT plan", "use the API") -> that one; never switch silently.
2. `OPENAI_API_KEY` is set -> **API** (explicit size/quality, faster, parallel-safe).
3. No key, `codex` on PATH and logged in -> **Codex CLI**.
4. Neither -> say so in one sentence and offer text-only alternatives; do not fake an image.

`ui-mockup`'s `mock.sh` applies the same rule automatically (`--backend auto|api|codex`).

# Backend A — OpenAI API

One Python script calls the OpenAI Images API directly with your API key.
No SDK, no `pip install`.

- Text-to-image → `POST /v1/images/generations`
- With `--ref` images → `POST /v1/images/edits` (each reference sent as `image[]`)

## Setup (API)

1. Create an API key at https://platform.openai.com/api-keys (the organisation may need verification to use GPT Image models).
2. Put it in the environment — never in a file inside a repository:

   ```bash
   export OPENAI_API_KEY="sk-..."            # bash / zsh — add to ~/.bashrc or ~/.zshrc
   ```

   ```powershell
   setx OPENAI_API_KEY "sk-..."              # Windows — then open a new terminal / restart Claude Code
   ```

3. Python 3.8+ on PATH (`python3` or `python`).

Optional: `OPENAI_BASE_URL` (a compatible proxy), `OPENAI_ORG_ID`, `OPENAI_IMAGE_MODEL` (a different default model, e.g. a newer GPT Image snapshot).

**Each call is billed to the key's account.** `high` quality costs more than `medium`; the script prints the API's `usage` to stderr after each call.

## How to invoke

Use `python3` (or `python` where `python3` is not available) with the script in this skill's `scripts/` folder:

**Text-to-image:**

```bash
python3 <gpt-image-2 base dir>/scripts/gen.py \
  --prompt "<the prompt>" \
  --size 1536x1024 --quality high \
  --out /absolute/path/to/output.png
```

**Image-to-image** (`--ref` is repeatable for multi-reference composition):

```bash
python3 <gpt-image-2 base dir>/scripts/gen.py \
  --prompt "<e.g. 'keep this layout, repaint in watercolor'>" \
  --ref /absolute/path/to/reference.png \
  --out /absolute/path/to/output.png
```

| Flag | Default | Values |
|---|---|---|
| `--size` | `auto` | `auto`, `1024x1024`, `1536x1024`, `1024x1536`, or a custom `WxH` (multiples of 16, edges ≤ 3840, ratio between 1:3 and 3:1) |
| `--quality` | `auto` | `low`, `medium`, `high`, `auto` |
| `--model` | `gpt-image-2` | any GPT Image model id your key can use |
| `--background` | — | `auto`, `opaque`, `transparent` (transparent needs `png` or `webp`) |
| `--format` | `png` | `png`, `jpeg`, `webp` |
| `--timeout-sec` | `300` | seconds |

If the model rejects a custom size, the script retries once with the closest standard size and says so on stderr.

# Backend B — Codex CLI (ChatGPT subscription)

```bash
bash <gpt-image-2 base dir>/scripts/gen.sh --prompt "<the prompt>" [--ref /abs/ref.png]... --out /abs/output.png
```

- Prerequisites: `codex` CLI installed (see github.com/openai/codex), `codex login` with a plan that includes Image 2, Python 3.8+.
- No `--size` / `--quality` flags: put the aspect and detail in the prompt. Optional `--timeout-sec` (default 300).
- Expect 2-5 minutes per image. Run it in the background; two in parallel are fine, more are serialised by the Codex session queue.
- How it works: `codex exec --enable image_generation --sandbox read-only` (never `--ephemeral`, the image must persist); the script reads the generated image from `~/.codex/generated_images/` (newer CLI) or decodes it from only the session rollouts its own run created. It touches no other Codex history and reads no credentials.
- Exit codes: 0 ok, 2 bad args, 3 `codex` or Python missing, 4 `--ref` missing, 5 `codex exec` failed (auth, network, model), 6 no new session file, 7 no image produced (feature not enabled, quota or refusal).
- Do not imply it works without a local `codex` login and an entitled plan. No hosted fallback is built in; if neither backend is available, say so.

# Both backends

## Default behavior

- **Pass the user's prompt through raw** unless they asked you to improve it (`ui-mockup` composes its own prompts — that is its job).
- **Choose the output path.** Default to `./image-<YYYYMMDD-HHMMSS>.png` in the current working directory if the user didn't specify.
- **Deliver the image.** After the script succeeds, Read the file and show it. Do not stop at "done, see path X".

## Exit codes (API, `gen.py`)

| code | meaning |
|------|---------|
| 0 | success — output path printed on stdout |
| 2 | bad args |
| 3 | `OPENAI_API_KEY` not set |
| 4 | a `--ref` file does not exist |
| 5 | the API returned an error (invalid key, no access to the model, quota, moderation, bad parameter) — the message is printed |
| 6 | network error or timeout |
| 7 | the response contained no image |

On failure, name the layer in one sentence instead of dumping the full stderr at the user.

## Hard constraints

- Never print, log, echo or write the API key anywhere; never put it into a command line, a prompt, or a file in the repo.
- Do not silently switch to another image model, an HTML mockup or a screenshot when the user asked for GPT Image 2 — if the call fails, say why.
- Do not imply the API backend works without a valid `OPENAI_API_KEY` that has access to the model.
- Text-heavy layouts (infographics, UI mocks) are fine for Image 2; do not warn pre-emptively, but verify the rendered text by reading the file back.
- Same prompt discipline on both backends: one image per call, every visible string quoted in the prompt, `--ref` for edits and style transfer.
