# Minimal JSON reader for the hook scripts: prints the scalar at a dotted path.
#
#   printf '%s' "$payload" | awk -v jsonpath=tool_input.command -f json.awk
#
# Exit 0 and the decoded value on stdout when the path resolves to a string,
# number or boolean; exit 1 (no output) when the path is missing, null, or an
# object/array. No jq, no python: the Linux sandbox is not guaranteed to have
# either, but awk is (POSIX; mawk on Debian, gawk in Git Bash).
#
# Why a real parser and not a sed one-liner: the value we care about most is
# tool_input.command, an arbitrary shell command that may itself contain
# quotes, backslashes and text that looks like JSON. A greedy sed regex picks
# the wrong occurrence; this scans the document properly instead.
#
# ASCII-only, no gawk/mawk-specific features.

{ doc = doc $0 "\n" }

# --- scanner ------------------------------------------------------------

function skipws(   c) {
    while (p <= len) {
        c = substr(doc, p, 1)
        if (c == " " || c == "\t" || c == "\n" || c == "\r") p++
        else return
    }
}

function hex2dec(s,   i, c, d, n) {
    n = 0
    for (i = 1; i <= length(s); i++) {
        c = tolower(substr(s, i, 1))
        d = index("0123456789abcdef", c) - 1
        if (d < 0) return -1
        n = n * 16 + d
    }
    return n
}

# Reads the string starting at doc[p] (which must be '"') and returns it
# decoded. Chunked on purpose: concatenating character by character is
# quadratic, and a Bash command can be tens of kilobytes.
function readstring(   out, c, e, u, code, start) {
    p++
    out = ""
    start = p
    while (p <= len) {
        c = substr(doc, p, 1)
        if (c == "\\") {
            out = out substr(doc, start, p - start)
            e = substr(doc, p + 1, 1)
            if (e == "n") out = out "\n"
            else if (e == "t") out = out "\t"
            else if (e == "r") out = out "\r"
            else if (e == "b") out = out sprintf("%c", 8)
            else if (e == "f") out = out sprintf("%c", 12)
            else if (e == "u") {
                u = substr(doc, p + 2, 4)
                code = hex2dec(u)
                # Only ASCII is decoded: sprintf("%c", n) emits a byte in mawk
                # but a UTF-8 character in gawk for n > 127, so anything above
                # ASCII is left as the literal escape rather than guessed at.
                # Claude Code's JSON.stringify never escapes non-ASCII anyway.
                if (code > 0 && code < 128) out = out sprintf("%c", code)
                else out = out "\\u" u
                p += 4
            }
            else out = out e            # \" \\ \/ and anything unexpected
            p += 2
            start = p
        } else if (c == "\"") {
            out = out substr(doc, start, p - start)
            p++
            return out
        } else {
            p++
        }
    }
    # End of document inside a string: the payload is truncated, so whatever we
    # collected is not trustworthy. Refuse rather than act on half a value.
    jerr = 1
    out = out substr(doc, start, p - start)
    return out
}

function skipstring(   c) {
    p++
    while (p <= len) {
        c = substr(doc, p, 1)
        if (c == "\\") p += 2
        else if (c == "\"") { p++; return }
        else p++
    }
}

function skipvalue(   c, depth) {
    skipws()
    c = substr(doc, p, 1)
    if (c == "\"") { skipstring(); return }
    if (c == "{" || c == "[") {
        depth = 0
        while (p <= len) {
            c = substr(doc, p, 1)
            if (c == "\"") { skipstring(); continue }
            if (c == "{" || c == "[") depth++
            else if (c == "}" || c == "]") {
                depth--
                if (depth <= 0) { p++; return }
            }
            p++
        }
        return
    }
    while (p <= len) {                  # number / true / false / null
        c = substr(doc, p, 1)
        if (c == "," || c == "}" || c == "]" || c == " " || c == "\t" || c == "\n" || c == "\r") return
        p++
    }
}

# At an object: leaves p on the value of `target` and returns 1, or consumes
# the object and returns 0.
function findkey(target,   c, k) {
    skipws()
    if (substr(doc, p, 1) != "{") return 0
    p++
    while (p <= len) {
        skipws()
        c = substr(doc, p, 1)
        if (c == "}") { p++; return 0 }
        if (c != "\"") return 0
        k = readstring()
        skipws()
        if (substr(doc, p, 1) != ":") return 0
        p++
        if (k == target) { skipws(); return 1 }
        skipvalue()
        skipws()
        c = substr(doc, p, 1)
        if (c == ",") p++
        else return 0
    }
    return 0
}

END {
    # Skip anything before the top-level object: a UTF-8 BOM (Windows
    # PowerShell 5.1 `Set-Content -Encoding utf8` writes one into the lock
    # file) or stray whitespace.
    start = index(doc, "{")
    if (start > 1) doc = substr(doc, start)
    len = length(doc)
    p = 1

    n = split(jsonpath, PARTS, ".")
    for (i = 1; i <= n; i++)
        if (!findkey(PARTS[i])) exit 1

    skipws()
    c = substr(doc, p, 1)
    if (c == "\"") {
        v = readstring()
        if (jerr) exit 1
        printf "%s", v
        exit 0
    }
    if (c == "{" || c == "[" || c == "") exit 1
    vstart = p
    skipvalue()
    v = substr(doc, vstart, p - vstart)
    if (v == "null" || v == "") exit 1
    printf "%s", v
    exit 0
}
