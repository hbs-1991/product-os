#!/bin/sh
# Stop hook: a gentle, non-blocking reminder to update (1) the project wiki and (2) the in-code README
# when code changed but the matching doc did not. It never blocks (no decision is set): a nudge only.
# Noise filter: silent on chat-only turns; per concern, silent when its doc was touched.
# Anti-loop: exits at once when stop_hook_active=true.
#
# Two independent nudges merged into ONE systemMessage:
#   (a) wiki nudge   - a watched code path changed but <wiki_dir>/ was untouched.
#   (b) README nudge - a code file changed but the README that explains its area was untouched.
# Configured in <project>/.claude/wiki.conf (keys: wiki_dir, lang, watch, code_ext,
# readme_per_child, readme_flat). Silent no-op without that file.
#
# README mapping (all optional):
#   readme_per_child=src/modules  : src/modules/<m>/**   -> src/modules/<m>/README.md
#                                   src/modules/<file>   -> src/modules/README.md
#   readme_flat=src/workers       : src/workers/**       -> src/workers/README.md
#
# Output: only { systemMessage, suppressOutput } -- the Stop schema has no hookSpecificOutput variant.

HOOKS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)
[ -n "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/lib.sh" ] || exit 0
. "$HOOKS_DIR/lib.sh"
wiki_enabled || exit 0

payload=$(cat)
if [ -n "$payload" ]; then
    active=$(printf '%s' "$payload" | json_get stop_hook_active)
    [ "$active" = "true" ] && exit 0
fi

WIKI_REL=$(conf_get wiki_dir docs/wiki)
LANG_CODE=$(conf_get lang en)
[ -d "$HOOKS_DIR/messages/$LANG_CODE" ] || LANG_CODE=en
WATCH=$(conf_get watch "src/")
CODE_EXT=$(conf_get code_ext "")
README_PER_CHILD=$(conf_get readme_per_child "")
README_FLAT=$(conf_get readme_flat "")

# -uall expands untracked directories into files (a new src/<area>/ would otherwise be one '?? src/' line).
status=$(cd "$REPO_ROOT" 2>/dev/null && git status --porcelain -uall 2>/dev/null)
[ -n "$status" ] || exit 0

paths=$(printf '%s\n' "$status" | awk '
    length($0) > 3 {
        p = substr($0, 4)
        i = index(p, " -> ")
        if (i > 0) p = substr(p, i + 4)
        sub(/^[ \t]+/, "", p); sub(/[ \t\r]+$/, "", p)
        sub(/^"/, "", p);      sub(/"$/, "", p)
        if (p != "") print p
    }')
[ -n "$paths" ] || exit 0

parts=""
append_part() {
    [ -n "$1" ] || return 0
    if [ -z "$parts" ]; then parts="$1"; else parts="$parts

$1"; fi
}

read_msg() {
    [ -f "$1" ] || return 0
    tr -d '\015' < "$1" 2>/dev/null | sed -e 's/[[:space:]]*$//' -e "s|{wiki_dir}|$WIKI_REL|g"
}

# filter_code: stdin paths -> those with a code extension (all paths when code_ext is empty).
filter_code() {
    awk -v ext="$CODE_EXT" '
        BEGIN { n = split(ext, EX, " ") }
        {
            if (n == 0) { print; next }
            for (i = 1; i <= n; i++) {
                e = "." EX[i]
                if (length($0) > length(e) && substr($0, length($0) - length(e) + 1) == e) { print; break }
            }
        }'
}

code_paths=$(printf '%s\n' "$paths" | grep -v '/README\.md$' | filter_code)

# --- (a) wiki nudge ---
watched=""
for w in $WATCH; do
    hit=$(printf '%s\n' "$code_paths" | awk -v w="$w" 'index($0, w) == 1 { print; exit }')
    [ -n "$hit" ] && { watched=$hit; break; }
done
wiki_touched=$(printf '%s\n' "$paths" | awk -v w="$WIKI_REL/" 'index($0, w) == 1 { print; exit }')

if [ -n "$watched" ] && [ -z "$wiki_touched" ]; then
    append_part "$(read_msg "$HOOKS_DIR/messages/$LANG_CODE/stop-wiki.txt")"
fi

# --- (b) README nudge ---
if [ -n "$README_PER_CHILD$README_FLAT" ]; then
    readme_changed=$(printf '%s\n' "$paths" | grep -E '(^|/)README\.md$')
    stale=$(printf '%s\n' "$code_paths" | awk -v pc="$README_PER_CHILD" -v fl="$README_FLAT" '
        BEGIN { npc = split(pc, PC, " "); nfl = split(fl, FL, " ") }
        {
            p = $0
            for (i = 1; i <= npc; i++) {
                r = PC[i] "/"
                if (index(p, r) == 1) {
                    rest = substr(p, length(r) + 1)
                    k = index(rest, "/")
                    if (k > 0) print PC[i] "/" substr(rest, 1, k - 1) "/README.md"
                    else print PC[i] "/README.md"
                    next
                }
            }
            for (i = 1; i <= nfl; i++) {
                r = FL[i] "/"
                if (index(p, r) == 1) { print FL[i] "/README.md"; next }
            }
        }' | LC_ALL=C sort -u)

    list=""
    while IFS= read -r expected; do
        [ -n "$expected" ] || continue
        printf '%s\n' "$readme_changed" | grep -Fxq -- "$expected" && continue
        list="${list:+$list, }$expected"
    done <<STALE
$stale
STALE

    if [ -n "$list" ]; then
        rm_msg=$(read_msg "$HOOKS_DIR/messages/$LANG_CODE/stop-readme.txt")
        [ -n "$rm_msg" ] && append_part "$rm_msg $list"
    fi
fi

[ -n "$parts" ] || exit 0

printf '{"systemMessage":"%s","suppressOutput":true}\n' \
    "$(printf '%s\n' "$parts" | json_escape)"
exit 0
