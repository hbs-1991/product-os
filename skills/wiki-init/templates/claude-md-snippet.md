# Project Wiki / Memory

`{{wiki_dir}}/` is this project's self-updating wiki: the agent's memory for what was built, decisions made on the way and gotchas.

- **Reading:** the SessionStart hook injects only a ~6.5 KB digest. Open `{{wiki_dir}}/index.md` before working on a module and `{{wiki_dir}}/overview.md` for the full state. A claim that names a file, route or symbol must be re-verified against the code before you rely on it.
- **Updating (mandatory):** new dev knowledge (a module implemented, a decision made, a gotcha found) means running the `wiki-ingest` skill: module/concept page, `decisions/`, `overview.md`, `log.md`. The Stop hook nudges when code changed and the wiki did not. Health check: `wiki-lint`.
- **Boundary:** the wiki references the tracker and the design documents; it never duplicates them. Rules: `{{wiki_dir}}/conventions.md`.
