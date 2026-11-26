#!/bin/sh
# Self-test for the wiki hooks. Builds throwaway wikis, runs the hooks inside them and checks:
#   A  a new-layout wiki (log/ files, date-slug ADRs, no ADR table, no Recently shipped)
#   B  an old-layout wiki (a single log.md, numbered ADRs with a table, Recently shipped), as product-os <= 1.2.0 made
#   C  a mixed wiki (log/ newest first, topped up from log.md), with the ru messages
#   D  a wiki built from the real skills/wiki-init/templates/ files with every placeholder substituted
#   E  an over-budget digest at several caps: the truncation marker stays inside the cap
# Every digest case asserts the byte cap, valid single-line JSON and the Decisions count. Then the Stop hook
# nudges for a code change without a wiki change, honours the anti-loop flag, goes quiet when a new log/ file
# and the READMEs were written, and both hooks are silent without wiki.conf.
#   sh hooks/wiki-selftest.sh        Exit 0 = OK, 1 = a check failed (the reason is printed).

HOOKS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
[ -n "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/lib.sh" ] || { echo "FAIL: lib.sh not found next to the self-test"; exit 1; }
TEMPLATES="$HOOKS_DIR/../skills/wiki-init/templates"

MAX_JSON_BYTES=8000   # Claude Code inlines hook output only below ~10 KB; keep a margin
DEFAULT_CAP=6500      # the hook's total_bytes default
T=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/wiki-selftest.$$")
mkdir -p "$T" || { echo "FAIL: cannot create a temp dir"; exit 1; }
trap 'rm -rf "$T"' EXIT
fail() { echo "FAIL: $1"; exit 1; }
. "$HOOKS_DIR/lib.sh"

# digest <case> <cap>: runs the SessionStart hook in $CLAUDE_PROJECT_DIR, checks the JSON and the byte cap,
# and leaves the decoded context in $ctx.
digest() {
    out=$(sh "$HOOKS_DIR/wiki-session-start.sh" < /dev/null)
    [ -n "$out" ] || fail "$1: SessionStart printed nothing"
    bytes=$(printf '%s' "$out" | LC_ALL=C wc -c | tr -d ' ')
    [ "$bytes" -lt "$MAX_JSON_BYTES" ] || fail "$1: hook JSON is $bytes bytes (limit $MAX_JSON_BYTES): it would be spilled to a file"
    nl=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    [ "$nl" -le 1 ] || fail "$1: the hook JSON spans $nl lines: raw newlines inside a JSON string make it invalid"
    ctx=$(printf '%s' "$out" | json_get hookSpecificOutput.additionalContext) || fail "$1: additionalContext missing: JSON does not parse"
    cbytes=$(printf '%s\n' "$ctx" | LC_ALL=C wc -c | tr -d ' ')
    [ "$cbytes" -le "$2" ] || fail "$1: the digest is $cbytes bytes, over its cap of $2"
}
has() { printf '%s\n' "$ctx" | grep -qF -- "$2" || fail "$1: digest lacks \"$2\""; }
lacks() { printf '%s\n' "$ctx" | grep -qF -- "$2" && fail "$1: digest must not contain \"$2\""; return 0; }
# before <case> <a> <b>: the first line holding <a> comes before the first line holding <b>.
before() {
    la=$(printf '%s\n' "$ctx" | grep -nF -- "$2" | head -n 1 | cut -d: -f1)
    lb=$(printf '%s\n' "$ctx" | grep -nF -- "$3" | head -n 1 | cut -d: -f1)
    [ -n "$la" ] && [ -n "$lb" ] && [ "$la" -lt "$lb" ] || fail "$1: \"$2\" must come before \"$3\""
}
titles() { printf '%s\n' "$ctx" | grep -c '^## \['; }
conf() {
    mkdir -p "$1/.claude"
    printf 'wiki_dir=docs/wiki\nlang=%s\nwatch=src/\ncode_ext=py\nreadme_per_child=src/modules\nreadme_flat=src/workers\n%s\n' "$2" "$3" > "$1/.claude/wiki.conf"
}
index_md() {
    cat <<'EOF'
# Index

## Root pages

| Page | Purpose |
|---|---|
| [overview](overview.md) | state |
| [log](log/) | journal |

## Decisions

One file per decision, listed by the folder.

## Modules

| Page | Purpose |
|---|---|
| [billing](modules/billing.md) | billing |

## Concepts

| Page | Purpose |
|---|---|
| [events](concepts/events.md) | events |
EOF
}

# --- A. new layout -------------------------------------------------------------------------------------
A="$T/a"
mkdir -p "$A/docs/wiki/log" "$A/docs/wiki/decisions" "$A/docs/wiki/modules" "$A/src/modules/billing" "$A/src/workers"
printf '# Overview\n\n## Current focus\n\nBuilding the billing module.\n' > "$A/docs/wiki/overview.md"
index_md > "$A/docs/wiki/index.md"
printf '# Decisions\n\nOne file per decision, listed by the folder.\n' > "$A/docs/wiki/decisions/README.md"
printf '# YYYY-MM-DD-<slug> — <title>\n' > "$A/docs/wiki/decisions/_template.md"
printf '# 2026-01-03-billing-ids — Billing ids\n\n- **Status:** accepted\n- **Date:** 2026-01-03\n- **Summary:** x\n' \
    > "$A/docs/wiki/decisions/2026-01-03-billing-ids.md"
i=1
while [ "$i" -le 10 ]; do
    d=$(printf '2026-01-%02d' "$i")
    printf '## [%s] ingest | entry %02d\nbody\n' "$d" "$i" > "$A/docs/wiki/log/$d-0900-entry-$i.md"
    i=$((i + 1))
done
printf 'no header in this one\n' > "$A/docs/wiki/log/2026-01-10-1200-headless.md"
printf 'not an entry\n' > "$A/docs/wiki/log/README.md"
conf "$A" en ""
echo "x = 1" > "$A/src/modules/billing/a.py"
echo "y = 1" > "$A/src/workers/w.py"

export CLAUDE_PROJECT_DIR="$A"
digest A "$DEFAULT_CAP"
bytes_a=$cbytes
for m in "docs/wiki/overview.md" "docs/wiki/index.md" "Modules: billing" "Concepts: events" "Decisions: 1 ADRs in docs/wiki/decisions/" \
    "docs/wiki/log/ -- newest 8 entries, newest file name first" "Journal: docs/wiki/log/"; do
    has A "$m"
done
lacks A "not found in"
lacks A "Recently shipped"
lacks A "topped up from log.md"
has A "log/2026-01-10-1200-headless.md [no"
before A "log/2026-01-10-1200-headless.md" "entry 10"
before A "entry 10" "entry 09"
lacks A "entry 03"
lacks A "not an entry"
[ "$(titles)" -eq 7 ] || fail "A: expected 7 header titles plus the headless file name (8 newest files), got $(titles)"

# --- B. old layout (product-os <= 1.2.0) --------------------------------------------------------------------
B="$T/b"
mkdir -p "$B/docs/wiki/decisions"
printf '# Overview\n\n## Current focus\n\nBuilding the billing module.\n\n## Recently shipped\n\n- 2026-01-02 - wiki set up\n' \
    > "$B/docs/wiki/overview.md"
cat > "$B/docs/wiki/index.md" <<'EOF'
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
printf '# 0001 — x\n' > "$B/docs/wiki/decisions/0001-x.md"
printf '# Decisions\n\n| # | Decision |\n|---|---|\n| [0001](0001-x.md) | x |\n' > "$B/docs/wiki/decisions/README.md"
printf '# NNNN — template\n' > "$B/docs/wiki/decisions/_template.md"
{
    printf '# Log\n\n'
    for d in 06 05 04 03 02; do printf '## [2026-01-%s] ingest | old %s\nbody\n\n' "$d" "$d"; done
} > "$B/docs/wiki/log.md"
conf "$B" en "focus_bytes=2600
shipped_lines=6
log_titles=4
total_bytes=6500"

export CLAUDE_PROJECT_DIR="$B"
digest B "$DEFAULT_CAP"
for m in "Modules: billing" "Decisions: 1 ADRs" "docs/wiki/overview.md -- Recently shipped (newest 6)" "- 2026-01-02 - wiki set up" \
    "docs/wiki/log.md -- newest 4 entries"; do
    has B "$m"
done
lacks B "not found in"
before B "old 06" "old 03"
lacks B "old 02"
[ "$(titles)" -eq 4 ] || fail "B: expected 4 titles from log.md, got $(titles)"

# --- C. mixed: log/ first, topped up from log.md; ru messages ---------------------------------------------
C="$T/c"
mkdir -p "$C/docs/wiki/log" "$C/docs/wiki/decisions"
printf '# Overview\n\n## Current focus\n\nФокус: модуль оплаты.\n' > "$C/docs/wiki/overview.md"
index_md > "$C/docs/wiki/index.md"
printf '# 0001 — x\n' > "$C/docs/wiki/decisions/0001-x.md"
printf '# 2026-02-02-y — y\n' > "$C/docs/wiki/decisions/2026-02-02-y.md"
printf '## [2026-02-01] ingest | new A\n' > "$C/docs/wiki/log/2026-02-01-0800-new-a.md"
printf '## [2026-02-02] ingest | new B\n' > "$C/docs/wiki/log/2026-02-02-0730-new-b.md"
{
    printf '# Log\n\n'
    for d in 31 30 29 28 27 26 25 24 23 22; do printf '## [2026-01-%s] ingest | old %s\nbody\n\n' "$d" "$d"; done
} > "$C/docs/wiki/log.md"
conf "$C" ru ""

export CLAUDE_PROJECT_DIR="$C"
digest C "$DEFAULT_CAP"
for m in "DIGEST вики проекта" "Журнал: docs/wiki/log/" "Фокус: модуль оплаты." "Decisions: 2 ADRs" \
    "docs/wiki/log/ -- newest 8 entries, newest file name first, topped up from log.md"; do
    has C "$m"
done
lacks C "not found in"
lacks C "Recently shipped"
before C "new B" "new A"
before C "new A" "old 31"
before C "old 31" "old 26"
lacks C "old 25"
[ "$(titles)" -eq 8 ] || fail "C: expected 8 titles (2 from log/, 6 from log.md), got $(titles)"

# --- D. the real wiki-init templates --------------------------------------------------------------------
[ -d "$TEMPLATES" ] || fail "D: skills/wiki-init/templates not found at $TEMPLATES"
D="$T/d"
W="$D/docs/wiki"
mkdir -p "$W/log" "$W/decisions" "$W/modules" "$W/concepts" "$D/.claude"
subst() {
    sed -e 's|{{project}}|demo|g' -e 's|{{date}}|2026-03-04|g' -e 's|{{time}}|0915|g' -e 's|{{wiki_dir}}|docs/wiki|g' \
        -e 's|{{lang}}|en|g' -e 's|{{watch}}|src/|g' -e 's|{{code_ext}}|py|g' -e 's|{{readme_per_child}}||g' \
        -e 's|{{readme_flat}}||g' -e 's|{{status_source}}|GitHub issues|g' \
        -e 's|{{architecture_source}}|docs/architecture.md|g' -e 's|{{current_focus}}|Building the first module.|g' \
        "$TEMPLATES/$1" > "$2" || fail "D: cannot render template $1"
}
subst index.md "$W/index.md"
subst overview.md "$W/overview.md"
subst conventions.md "$W/conventions.md"
subst log-bootstrap.md "$W/log/2026-03-04-0915-bootstrap.md"
subst decisions-_template.md "$W/decisions/_template.md"
subst decisions-README.md "$W/decisions/README.md"
subst decisions-llm-wiki-memory-system.md "$W/decisions/2026-03-04-llm-wiki-memory-system.md"
subst modules-_template.md "$W/modules/_template.md"
subst concepts-README.md "$W/concepts/README.md"
subst wiki.conf "$D/.claude/wiki.conf"
left=$(grep -rl '{{' "$W" "$D/.claude" 2>/dev/null)
[ -z "$left" ] && [ ! -e "$W/log.md" ] || fail "D: unsubstituted placeholder or a log.md in the scaffold: $left"
head -n 1 "$W/log/2026-03-04-0915-bootstrap.md" | grep -q '^## \[2026-03-04\] bootstrap | ' || fail "D: the bootstrap entry's first line is not its header"
head -n 1 "$W/decisions/2026-03-04-llm-wiki-memory-system.md" | grep -q '^# 2026-03-04-llm-wiki-memory-system — ' || fail "D: the seed ADR heading is not its id"
# The headings wiki-init's adoption check and wiki-lint key on, even where the digest no longer reads them.
for h in '## Root pages' '## Decisions' '## Modules' '## Concepts'; do
    grep -qx "$h" "$W/index.md" || fail "D: the index template lacks the heading \"$h\""
done
grep -qx '## Current focus' "$W/overview.md" || fail "D: the overview template lacks \"## Current focus\""
for l in '- \*\*Status:\*\*' '- \*\*Date:\*\* 2026-03-04' '- \*\*Summary:\*\*'; do
    grep -q "^$l" "$W/decisions/2026-03-04-llm-wiki-memory-system.md" || fail "D: the seed ADR lacks \"$l\""
done

export CLAUDE_PROJECT_DIR="$D"
digest D "$DEFAULT_CAP"
for m in "Building the first module." "[log](log/)" "Decisions: 1 ADRs" "## [2026-03-04] bootstrap | Wiki set up" \
    "docs/wiki/log/ -- newest 8 entries"; do
    has D "$m"
done
lacks D "not found in"
lacks D "Recently shipped"
[ "$(titles)" -eq 1 ] || fail "D: expected the one bootstrap title, got $(titles)"

# --- E. over budget: the marker counts against the cap ------------------------------------------------------
E="$T/e"
mkdir -p "$E/docs/wiki/log" "$E/docs/wiki/decisions"
{
    printf '# Overview\n\n## Current focus\n\n'
    i=1
    while [ "$i" -le 60 ]; do printf 'Focus line %02d: a sentence long enough to fill the budget quickly — ünïcödé.\n' "$i"; i=$((i + 1)); done
} > "$E/docs/wiki/overview.md"
index_md > "$E/docs/wiki/index.md"
printf '# 2026-01-03-x — x\n' > "$E/docs/wiki/decisions/2026-01-03-x.md"
printf '## [2026-01-03] ingest | e\n' > "$E/docs/wiki/log/2026-01-03-1000-e.md"
export CLAUDE_PROJECT_DIR="$E"
for cap in 1500 1537 1574 1611 1648 1685 1722 1759 1796 1833 2000 2600; do
    conf "$E" en "total_bytes=$cap"
    digest "E(total_bytes=$cap)" "$cap"
    has "E(total_bytes=$cap)" "[wiki digest truncated at $cap bytes"
done
for fb in 300 517 731 1000; do
    conf "$E" en "focus_bytes=$fb"
    digest "E(focus_bytes=$fb)" "$DEFAULT_CAP"
    has "E(focus_bytes=$fb)" "[overview.md Current focus truncated at $fb bytes"
    fbytes=$(printf '%s\n' "$ctx" | awk '/^===== .*Current focus/ { f = 1; next } /^===== / { f = 0 } f' |
        sed -e '$ { /^$/ d; }' | LC_ALL=C wc -c | tr -d ' ')
    [ "$fbytes" -le "$fb" ] || fail "E(focus_bytes=$fb): the focus section is $fbytes bytes, over its cap"
    has "E(focus_bytes=$fb)" "Decisions: 1 ADRs"
done

# --- Stop hook (in the new-layout wiki A) -------------------------------------------------------------------
cd "$A" || fail "cd"
git init -q . 2>/dev/null || fail "git init"
git config user.email t@example.com; git config user.name t
git add -A; git commit -qm init
export CLAUDE_PROJECT_DIR="$A"

echo "x = 2" > src/modules/billing/a.py
echo "y = 2" > src/workers/w.py
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
printf '%s' "$msg" | grep -q "systemMessage" || fail "Stop hook did not nudge on a code change without a wiki change"
nl=$(printf '%s\n' "$msg" | wc -l | tr -d ' ')
[ "$nl" -le 1 ] || fail "the Stop hook JSON spans $nl lines (raw newlines make it invalid)"
printf '%s' "$msg" | grep -q "a new entry file in log/" || fail "the Stop nudge does not name log/"
printf '%s' "$msg" | grep -q "src/modules/billing/README.md" || fail "README nudge lacks the per-child candidate"
printf '%s' "$msg" | grep -q "src/workers/README.md" || fail "README nudge lacks the flat candidate"

msg=$(printf '{"stop_hook_active":true}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent when stop_hook_active=true"

printf '## [2026-01-11] ingest | touched\n' > docs/wiki/log/2026-01-11-1000-touched.md
echo "# billing" > src/modules/billing/README.md
echo "# workers" > src/workers/README.md
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent when a new log/ file and the READMEs were written: $msg"

# --- Opt-in: no wiki.conf -> silent no-op -------------------------------------------------------------------
rm .claude/wiki.conf
out=$(sh "$HOOKS_DIR/wiki-session-start.sh" < /dev/null)
[ -z "$out" ] || fail "SessionStart must be silent without wiki.conf"
echo "x = 3" > src/modules/billing/a.py
msg=$(printf '{}' | sh "$HOOKS_DIR/wiki-stop-reminder.sh")
[ -z "$msg" ] || fail "Stop hook must be silent without wiki.conf"

echo "OK: digest cases A (new layout, $bytes_a bytes), B (old layout), C (mixed, ru), D (real wiki-init templates), E (over budget at 12 total and 4 focus caps) stay within their byte caps as valid single-line JSON with the right titles and Decisions counts; Stop hook nudges, honours anti-loop, goes quiet when a log/ file and the READMEs are written; both hooks are no-ops without wiki.conf"
exit 0
