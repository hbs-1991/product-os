#!/usr/bin/env bash
# Render a UI mockup image (page / component / widget / card / screen sheet) by composing a
# style preset + global rendering constraints + the caller's layout spec, then handing the
# whole prompt to the gpt-image-2 skill: gen.py (OpenAI Images API, OPENAI_API_KEY) or gen.sh
# (local Codex CLI, ChatGPT plan).
#
# Usage:
#   mock.sh --spec "<layout specification>" [--preset <name>] [--aspect <ratio>]
#           [--out <path.png>] [--name <slug>] [--ref <image>]... [--timeout-sec N]
#           [--style-file <file>] [--quality low|medium|high|auto] [--size WxH]
#           [--backend auto|api|codex] [--no-rules] [--dry-run]
#   mock.sh --list-presets
#
# Notes:
#   --spec  is the part YOU write: canvas, regions, every visible string in single quotes.
#   --preset picks assets/presets/<name>.txt (default: saas-light). Use --style-file for a
#           project-specific style block you generated yourself.
#   --ref   is repeatable; passes reference images through for image-to-image iteration.
#   --quality defaults to high (labels render cleaner); --size defaults from --aspect.
#   --backend auto (default): API if OPENAI_API_KEY is set, else Codex CLI if `codex` is on PATH.
#           --quality/--size apply to the API backend only; the Codex route takes the canvas from the prompt.
#   --dry-run prints the composed prompt and exits 0 without calling the generator.
#
# Exit codes: 0 ok · 2 bad args · 3 gpt-image-2 gen.py or Python not found · 4 unknown preset
#             5 reference file missing · 13 no backend available (no OPENAI_API_KEY, no codex)
#             anything else: from the generator (gen.py: 5 API error, 6 network/timeout, 7 no image;
#             gen.sh: 5 codex failed, 6 no session, 7 no image).

set -euo pipefail

SKILL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PRESET_DIR="$SKILL_DIR/assets/presets"
RULES_FILE="$SKILL_DIR/assets/render-rules.txt"

SPEC=""; PRESET="saas-light"; ASPECT=""; OUT=""; NAME="ui-mock"
STYLE_FILE=""; TIMEOUT_SEC=420; DRY_RUN=0; USE_RULES=1; QUALITY="high"; SIZE=""; BACKEND="auto"
REFS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec|--prompt) SPEC="$2"; shift 2 ;;
    --preset)        PRESET="$2"; shift 2 ;;
    --style-file)    STYLE_FILE="$2"; shift 2 ;;
    --aspect)        ASPECT="$2"; shift 2 ;;
    --out)           OUT="$2"; shift 2 ;;
    --name)          NAME="$2"; shift 2 ;;
    --ref)           REFS+=("$2"); shift 2 ;;
    --timeout-sec)   TIMEOUT_SEC="$2"; shift 2 ;;
    --quality)       QUALITY="$2"; shift 2 ;;
    --size)          SIZE="$2"; shift 2 ;;
    --backend)       BACKEND="$2"; shift 2 ;;
    --no-rules)      USE_RULES=0; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    --list-presets)  basename -s .txt -a "$PRESET_DIR"/*.txt; exit 0 ;;
    -h|--help)       sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$SPEC" ]] && { echo "Missing --spec (the layout specification)" >&2; exit 2; }

# --- style block ------------------------------------------------------------
if [[ -n "$STYLE_FILE" ]]; then
  [[ -f "$STYLE_FILE" ]] || { echo "Style file not found: $STYLE_FILE" >&2; exit 4; }
  STYLE="$(cat "$STYLE_FILE")"
else
  if [[ ! -f "$PRESET_DIR/$PRESET.txt" ]]; then
    echo "Unknown preset: $PRESET. Available:" >&2
    basename -s .txt -a "$PRESET_DIR"/*.txt >&2
    exit 4
  fi
  STYLE="$(cat "$PRESET_DIR/$PRESET.txt")"
fi

# --- canvas line ------------------------------------------------------------
CANVAS=""
case "$ASPECT" in
  "")            CANVAS="" ;;
  16:9)          CANVAS="CANVAS: wide landscape 16:9, a full desktop application viewport." ;;
  3:2)           CANVAS="CANVAS: landscape 3:2." ;;
  4:3)           CANVAS="CANVAS: landscape 4:3." ;;
  1:1)           CANVAS="CANVAS: square 1:1, the component centred with even margin around it." ;;
  4:5)           CANVAS="CANVAS: portrait 4:5." ;;
  9:16)          CANVAS="CANVAS: tall portrait 9:16, a single mobile phone screen filling the frame." ;;
  2:1)           CANVAS="CANVAS: extra-wide 2:1 landscape." ;;
  *)             CANVAS="CANVAS: $ASPECT." ;;
esac

# --- API size from aspect --------------------------------------------------
if [[ -z "$SIZE" ]]; then
  case "$ASPECT" in
    16:9) SIZE="1536x864" ;;  3:2) SIZE="1536x1024" ;; 4:3) SIZE="1280x960" ;;
    1:1)  SIZE="1024x1024" ;; 4:5) SIZE="1024x1280" ;; 9:16) SIZE="864x1536" ;;
    2:1)  SIZE="1536x768" ;;  *)   SIZE="auto" ;;
  esac
fi

# --- compose ----------------------------------------------------------------
PROMPT="$STYLE"
[[ -n "$CANVAS" ]] && PROMPT+=$'\n\n'"$CANVAS"
PROMPT+=$'\n\n'"SPECIFICATION:"$'\n'"$SPEC"
if [[ $USE_RULES -eq 1 && -f "$RULES_FILE" ]]; then
  PROMPT+=$'\n\n'"$(cat "$RULES_FILE")"
fi

if [[ $DRY_RUN -eq 1 ]]; then
  printf '%s\n' "$PROMPT"
  exit 0
fi

# --- output path ------------------------------------------------------------
if [[ -z "$OUT" ]]; then
  OUT="$PWD/${NAME}-$(date +%Y%m%d-%H%M%S).png"
fi
case "$OUT" in
  /*|[A-Za-z]:[\/]*) ;;
  *) OUT="$PWD/$OUT" ;;
esac

# --- choose backend ---------------------------------------------------------
case "$BACKEND" in
  auto)  if [[ -n "${OPENAI_API_KEY:-}" ]]; then BACKEND=api
         elif command -v codex >/dev/null 2>&1; then BACKEND=codex
         else echo "No backend: set OPENAI_API_KEY or install and log in to the codex CLI (see the gpt-image-2 skill)." >&2; exit 13; fi ;;
  api)   [[ -z "${OPENAI_API_KEY:-}" ]] && { echo "OPENAI_API_KEY is not set — see the gpt-image-2 skill's Setup." >&2; exit 13; } ;;
  codex) command -v codex >/dev/null 2>&1 || { echo "codex CLI not found — see the gpt-image-2 skill." >&2; exit 13; } ;;
  *)     echo "Unknown --backend: $BACKEND (auto|api|codex)" >&2; exit 2 ;;
esac
EXT="py"; [[ "$BACKEND" == "codex" ]] && EXT="sh"

# --- locate the gpt-image-2 generator and Python ----------------------------
GEN=""
CANDIDATES=(
  "${GPT_IMAGE_2_GEN:-}"
  "$SKILL_DIR/../gpt-image-2/scripts/gen.$EXT"
  "$HOME/.claude/skills/gpt-image-2/scripts/gen.$EXT"
)
for c in "${CANDIDATES[@]}"; do
  [[ -n "$c" && -f "$c" ]] && { GEN="$c"; break; }
done
if [[ -z "$GEN" ]]; then
  echo "gpt-image-2 generator not found (looked for gpt-image-2/scripts/gen.$EXT)." >&2
  echo "Install the product-os plugin, or set GPT_IMAGE_2_GEN to the generator path." >&2
  exit 3
fi

PY=""
for p in python3 python py; do
  if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
    PY="$p"; break
  fi
done
[[ -z "$PY" ]] && { echo "Python 3.8+ not found (tried python3, python, py)." >&2; exit 3; }

gen_args=(--prompt "$PROMPT" --out "$OUT" --timeout-sec "$TIMEOUT_SEC")
[[ "$BACKEND" == "api" ]] && gen_args+=(--quality "$QUALITY" --size "$SIZE")
for r in ${REFS[@]+"${REFS[@]}"}; do
  [[ -f "$r" ]] || { echo "Reference image not found: $r" >&2; exit 5; }
  gen_args+=(--ref "$r")
done

if [[ "$BACKEND" == "codex" ]]; then bash "$GEN" "${gen_args[@]}"; else "$PY" "$GEN" "${gen_args[@]}"; fi
