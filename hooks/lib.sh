# Shared helpers for the wiki hooks. Sourced, never executed directly.
# The caller sets HOOKS_DIR. POSIX sh only (dash in a Linux sandbox, Git Bash sh on Windows):
# no [[ ]], no arrays, no local, no ${var,,}.

# The project root: Claude Code exports CLAUDE_PROJECT_DIR to hooks; fall back to git, then PWD.
REPO_ROOT=${CLAUDE_PROJECT_DIR:-}
[ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT" ] || REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$REPO_ROOT" ] || REPO_ROOT=$PWD

WIKI_CONF="$REPO_ROOT/.claude/wiki.conf"

# The wiki is opt-in: no .claude/wiki.conf (written by the wiki-init skill) = every wiki hook is a silent no-op.
wiki_enabled() { [ -f "$WIKI_CONF" ]; }

# conf_get <key> <default> -- value of "key=value" in wiki.conf. The file is PARSED, never sourced:
# a repository must not be able to run code through its own config. '#' starts a comment.
conf_get() {
    v=$(tr -d '\015' < "$WIKI_CONF" 2>/dev/null | awk -v k="$1" '
        /^[ \t]*#/ { next }
        {
            i = index($0, "=")
            if (i == 0) next
            key = substr($0, 1, i - 1); gsub(/[ \t]/, "", key)
            if (key != k) next
            val = substr($0, i + 1)
            sub(/[ \t]*#.*$/, "", val); sub(/^[ \t]+/, "", val); sub(/[ \t]+$/, "", val)
            print val; exit
        }')
    if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$2"; fi
}

# json_get <dotted.path> -- reads JSON on stdin, prints the scalar at that path (exit 1 if absent).
json_get() {
    awk -v jsonpath="$1" -f "$HOOKS_DIR/json.awk"
}

# json_escape -- filter: stdin (UTF-8 text) -> the body of a JSON string, single line, no quotes.
# Scanned, not gsub'd: gsub treats backslashes in the replacement differently across awks.
json_escape() {
    awk '
        BEGIN {
            ORS = ""
            for (i = 1; i < 32; i++) if (i != 9 && i != 10 && i != 13) CTL = CTL sprintf("%c", i)
            CTL = CTL sprintf("%c", 127)
        }
        {
            if (NR > 1) printf "%s", "\\n"
            printf "%s", esc($0)
        }
        function esc(s,   out, i, n, c, r, start) {
            out = ""
            start = 1
            n = length(s)
            for (i = 1; i <= n; i++) {
                c = substr(s, i, 1)
                if (c == "\\") r = "\\\\"
                else if (c == "\"") r = "\\\""
                else if (c == "\t") r = "\t"
                else if (c == "\r") r = "\r"
                else if (index(CTL, c) > 0) r = " "
                else continue
                out = out substr(s, start, i - start) r
                start = i + 1
            }
            return out substr(s, start, n - start + 1)
        }
    '
}
