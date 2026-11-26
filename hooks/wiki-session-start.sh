#!/bin/sh
# SessionStart hook: injects a DIGEST of the project's wiki into the session context.
#
# Why a digest and not the files: Claude Code inlines hook `additionalContext` only up to roughly
# 10 KB; anything larger is written to a file and the model sees a ~2 KB preview, so a whole-file
# injection silently never reaches a session. The digest is capped in BYTES (LC_ALL=C awk), never
# characters: gawk (Git Bash) and mawk (Linux) disagree on what length() counts for UTF-8.
# Every cut is loud ("[... truncated ...]" tells the agent to read the file), and the marker's own
# bytes count against the cap, so the output never exceeds it. A heading that is not
# found falls back to the head of the file and says so, so a renamed heading cannot empty the digest
# silently. CR characters are dropped everywhere so CRLF (Windows) and LF checkouts inject the same text.
#
# Section order is deliberate: the total cap cuts from the END, so the short page map sits right
# after Current focus and the growing tails (shipped bullets, log titles) come last.
#
# Two wiki layouts are read. Since product-os 1.3.0 a log entry is one file,
# <wiki>/log/<YYYY-MM-DD>-<HHMM>-<slug>.md, so two pull requests never write the same file: the titles
# come from log/ newest file name first (LC_ALL=C sort -r; only the newest N files are opened) and are
# topped up from an older single log.md. A wiki without log/ is read from log.md alone. The
# "Recently shipped" block of overview.md is printed only when that heading exists (wikis scaffolded
# before 1.3.0 keep it). Decisions are counted as the files in decisions/ minus README.md and
# _template.md, so date-slug ADRs, which sit in no table, are counted too.
#
# Opt-in: silent no-op unless <project>/.claude/wiki.conf exists (written by the wiki-init skill).
# Self-test: sh hooks/wiki-selftest.sh

HOOKS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
[ -n "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/lib.sh" ] || exit 0
. "$HOOKS_DIR/lib.sh"
wiki_enabled || exit 0

WIKI_REL=$(conf_get wiki_dir docs/wiki)
LANG_CODE=$(conf_get lang en)
[ -d "$HOOKS_DIR/messages/$LANG_CODE" ] || LANG_CODE=en
WIKI="$REPO_ROOT/$WIKI_REL"
[ -d "$WIKI" ] || exit 0

INDEX_FILE="$WIKI/index.md"
OVERVIEW_FILE="$WIKI/overview.md"
LOG_FILE="$WIKI/log.md"
LOG_DIR="$WIKI/log"
DECISIONS_DIR="$WIKI/decisions"
H_FOCUS='## Current focus'
H_SHIPPED='## Recently shipped'
H_ROOT='## Root pages'
H_MODULES='## Modules'
H_CONCEPTS='## Concepts'
H_DECISIONS='## Decisions'
LOG_ENTRY_MARKER='## ['

FOCUS_BYTES=$(conf_get focus_bytes 2600)
SHIPPED_LINES=$(conf_get shipped_lines 6)
LOG_TITLES=$(conf_get log_titles 8)
TOTAL_BYTES=$(conf_get total_bytes 6500)

# section <file> <heading-prefix>: the section from its heading to (not including) the next "## ".
# `index($0, h) == 1` is a substring check on purpose: a regex via `awk -v` goes through backslash processing.
section() {
    [ -f "$1" ] || return 0
    tr -d '\015' < "$1" 2>/dev/null | awk -v h="$2" '
        index($0, h) == 1 { f = 1; print; next }
        f && index($0, "## ") == 1 { exit }
        f { print }
    '
}

# cap_bytes <n> <what>: passes whole lines while they fit in <n> bytes. Over budget it keeps the lines that
# fit together with a loud marker line, and the marker's bytes count against <n> too. Never splits a character.
cap_bytes() {
    LC_ALL=C awk -v n="$1" -v what="$2" '
        { line[NR] = $0; total += length($0) + 1 }
        END {
            if (total <= n) { for (i = 1; i <= NR; i++) print line[i]; exit }
            marker = sprintf("[%s truncated at %d bytes -- over budget, read the file]", what, n)
            room = n - length(marker) - 1
            for (i = 1; i <= NR && used + length(line[i]) + 1 <= room; i++) {
                print line[i]
                used += length(line[i]) + 1
            }
            print marker
        }
    '
}

# link_names: from index table rows "| [name](path) | ..." prints "name" per line.
link_names() {
    awk '
        index($0, "| [") == 1 {
            s = substr($0, 4)
            i = index(s, "](")
            if (i > 1) print substr(s, 1, i - 1)
        }
    '
}

join_csv() {
    awk 'BEGIN { ORS = "" } { if (NR > 1) printf ", "; printf "%s", $0 } END { printf "\n" }'
}

section_or_head() {
    out=$(section "$1" "$2")
    if [ -z "$out" ]; then
        printf '[heading "%s" not found in %s -- showing the file head; fix the heading or the hook]\n' \
            "$2" "$(basename "$1")"
        [ -f "$1" ] && tr -d '\015' < "$1" 2>/dev/null
        return 0
    fi
    printf '%s\n' "$out"
}

# log_names: the newest LOG_TITLES entry file names in log/, newest first (the file name is the order).
log_names() {
    [ -d "$LOG_DIR" ] || return 0
    for f in "$LOG_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
        [ -f "$f" ] && printf '%s\n' "${f##*/}"
    done | LC_ALL=C sort -r | head -n "$LOG_TITLES"
}

# log_titles: one header line per newest log/ file (its name when it has no header line), then the head of
# log.md for whatever is still missing.
log_titles() {
    names=$(log_names)
    got=0
    if [ -n "$names" ]; then
        while IFS= read -r name; do
            t=$(tr -d '\015' < "$LOG_DIR/$name" 2>/dev/null |
                awk -v m="$LOG_ENTRY_MARKER" 'index($0, m) == 1 { print; exit }')
            [ -n "$t" ] || t="log/$name [no \"$LOG_ENTRY_MARKER\" header line in the file]"
            printf '%s\n' "$t"
            got=$((got + 1))
        done <<NAMES
$names
NAMES
    fi
    rest=$((LOG_TITLES - got))
    if [ "$rest" -gt 0 ] && [ -f "$LOG_FILE" ]; then
        tr -d '\015' < "$LOG_FILE" 2>/dev/null |
            awk -v m="$LOG_ENTRY_MARKER" -v n="$rest" 'index($0, m) == 1 { print; c++; if (c >= n) exit }'
    fi
}

focus=$(section_or_head "$OVERVIEW_FILE" "$H_FOCUS" | cap_bytes "$FOCUS_BYTES" "overview.md ${H_FOCUS#"## "}")

# The shipped block exists only while overview.md keeps that heading (pre-1.3.0 wikis); otherwise it is omitted.
shipped_block=""
shipped_sec=$(section "$OVERVIEW_FILE" "$H_SHIPPED")
if [ -n "$shipped_sec" ]; then
    shipped=$(printf '%s\n' "$shipped_sec" | grep '^- ' | head -n "$SHIPPED_LINES")
    [ -n "$shipped" ] || shipped="[no \"- \" bullets under \"$H_SHIPPED\" in overview.md -- read the file]"
    shipped_block="

===== $WIKI_REL/overview.md -- ${H_SHIPPED#"## "} (newest $SHIPPED_LINES) =====
$shipped"
fi

if [ -d "$LOG_DIR" ] && [ -f "$LOG_FILE" ]; then
    log_src="$WIKI_REL/log/ -- newest $LOG_TITLES entries, newest file name first, topped up from log.md"
elif [ -d "$LOG_DIR" ]; then
    log_src="$WIKI_REL/log/ -- newest $LOG_TITLES entries, newest file name first"
else
    log_src="$WIKI_REL/log.md -- newest $LOG_TITLES entries"
fi
logt=$(log_titles)
[ -n "$logt" ] || logt="[no \"$LOG_ENTRY_MARKER\" entries found in log/ or log.md -- read the folder]"

root=$(section "$INDEX_FILE" "$H_ROOT" | grep '^|')
modules=$(section "$INDEX_FILE" "$H_MODULES" | link_names | join_csv)
concepts=$(section "$INDEX_FILE" "$H_CONCEPTS" | link_names | join_csv)
[ -n "$root$modules$concepts" ] || root="[none of \"$H_ROOT\" / \"$H_MODULES\" / \"$H_CONCEPTS\" found in index.md -- read the file]"

# Every ADR is a file: date-slug ones sit in no table, numbered ones may also have a row in index.md.
ndec=0
for f in "$DECISIONS_DIR"/*.md; do
    [ -f "$f" ] || continue
    case ${f##*/} in README.md | _template.md) continue ;; esac
    ndec=$((ndec + 1))
done

parts="===== $WIKI_REL/overview.md -- ${H_FOCUS#"## "} (first $FOCUS_BYTES bytes; the section continues in the file) =====
$focus

===== $WIKI_REL/index.md -- page map (names only; the index has one row per page) =====
$root
Modules: $modules
Concepts: $concepts
Decisions: $ndec ADRs in $WIKI_REL/decisions/ -- ls it, or grep the Summary: lines; numbered ones may also be in $WIKI_REL/index.md §Decisions$shipped_block

===== $log_src (titles only; bodies in the files) =====
$logt"

header=""
[ -f "$HOOKS_DIR/messages/$LANG_CODE/session-start.header.txt" ] &&
    header=$(tr -d '\015' < "$HOOKS_DIR/messages/$LANG_CODE/session-start.header.txt" 2>/dev/null | sed "s|{wiki_dir}|$WIKI_REL|g")

if [ -n "$header" ]; then
    context="$header

$parts"
else
    context="$parts"
fi

context=$(printf '%s\n' "$context" | cap_bytes "$TOTAL_BYTES" "wiki digest")

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(printf '%s\n' "$context" | json_escape)"
exit 0
