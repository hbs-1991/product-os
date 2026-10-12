#!/bin/sh
# Self-test for the wiki hooks. Builds a throwaway git repo with a minimal wiki and a wiki.conf, runs both
# hooks inside it, and checks: the SessionStart digest stays under the inlining limit and parses as JSON, all
# digest sections are present, the Stop hook nudges for a code change without a wiki change and is silent
# when the wiki was touched or the repo has no wiki.conf.
#   sh hooks/wiki-selftest.sh        Exit 0 = OK, 1 = a check failed (the reason is printed).

HOOKS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
[ -n "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/lib.sh" ] || { echo "FAIL: lib.sh not found next to the self-test"; exit 1; }

MAX_BYTES=8000
T=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/wiki-selftest.$$")
mkdir -p "$T/repo" || { echo "FAIL: cannot create a temp dir"; exit 1; }
trap 'rm -rf "$T"' EXIT
R="$T/repo"
fail() { echo "FAIL: $1"; exit 1; }

cd "$R" || fail "cd"
git init -q . 2>/dev/null || fail "git init"
git config user.email t@example.com; git config user.name t
mkdir -p .claude docs/wiki/decisions docs/wiki/modules src/modules/billing src/workers
cat > docs/wiki/overview.md <<'EOF'
# Overview

## Current focus

Building the billing module.

## Recently shipped

- 2026-01-02 - wiki set up
EOF
cat > docs/wiki/index.md <<'EOF'
# Index

## Root pages

| Page | Purpose |
|---|---|
| [overview](overview.md) | state |

## Decisions

| # | Decision |
|---|---|
| [0001](decisions/0001-x.md) | x |

## Modules

| Page | Purpose |
|---|---|
| [billing](modules/billing.md) | billing |

## Concepts

| Page | Purpose |
|---|---|
EOF
cat > docs/wiki/log.md <<'EOF'
# Log

## [2026-01-02] bootstrap | Wiki set up
Created.
EOF
cat > .claude/wiki.conf <<'EOF'
wiki_dir=docs/wiki
lang=en
watch=src/
code_ext=py
readme_per_child=src/modules
readme_flat=src/workers
EOF
echo "x = 1" > src/modules/billing/a.py
echo "y = 1" > src/workers/w.py
git add -A; git commit -qm init

export CLAUDE_PROJECT_DIR="$R"

# 1. SessionStart digest
out=$(sh "$HOOKS_DIR/wiki-session-start.sh" < /dev/null)
[ -n "$out" ] || fail "SessionStart printed nothing"
bytes=$(printf '%s' "$out" | LC_ALL=C wc -c | tr -d ' ')
[ "$bytes" -lt "$MAX_BYTES" ] || fail "digest is $bytes bytes (limit $MAX_BYTES): it would be spilled to a file"
nl=$(printf '%s
' "$out" | wc -l | tr -d ' ')
[ "$nl" -le 1 ] || fail "the hook JSON spans $nl lines: raw newlines inside a JSON string make it invalid"
. "$HOOKS_DIR/lib.sh"
ctx=$(printf '%s' "$out" | json_get hookSpecificOutput.additionalContext) || fail "additionalContext missing: JSON does not parse"
for must in "overview.md" "index.md" "log.md" "Modules: billing" "Decisions: 1"; do
    printf '%s' "$ctx" | grep -q -- "$must" || fail "digest lacks \"$must\""
done
printf '%s' "$ctx" | grep -q "not found in" && fail "a digest heading was not found (check the wiki headings)"

# 2. Stop hook: code changed, wiki untouched -> nudge (wiki + READMEs)
echo "x = 2" > src/modules/billing/a.py
echo "y = 2" > src/workers/w.py
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
printf '%s' "$msg" | grep -q "systemMessage" || fail "Stop hook did not nudge on a code change without a wiki change"
nl=$(printf '%s
' "$msg" | wc -l | tr -d ' ')
[ "$nl" -le 1 ] || fail "the Stop hook JSON spans $nl lines (raw newlines make it invalid)"
printf '%s' "$msg" | grep -q "src/modules/billing/README.md" || fail "README nudge lacks the per-child candidate"
printf '%s' "$msg" | grep -q "src/workers/README.md" || fail "README nudge lacks the flat candidate"

# 3. Stop hook: anti-loop
msg=$(printf '{"stop_hook_active":true}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent when stop_hook_active=true"

# 4. Stop hook: wiki + READMEs touched -> silent
echo "- touched" >> docs/wiki/log.md
echo "# billing" > src/modules/billing/README.md
echo "# workers" > src/workers/README.md
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent when the wiki and READMEs were updated: $msg"

# 5. Opt-in: no wiki.conf -> silent no-op
rm .claude/wiki.conf
out=$(sh "$HOOKS_DIR/wiki-session-start.sh" < /dev/null)
[ -z "$out" ] || fail "SessionStart must be silent without wiki.conf"
echo "x = 3" > src/modules/billing/a.py
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent without wiki.conf"

echo "OK: digest $bytes bytes (limit $MAX_BYTES), valid JSON, all sections present; Stop hook nudges, honours anti-loop, goes quiet when docs are updated; both hooks are no-ops without wiki.conf"
exit 0
