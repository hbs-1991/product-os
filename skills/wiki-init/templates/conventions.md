# Wiki Conventions — schema and maintenance rules

This is the **schema file** of {{project}}'s wiki (the LLM-Wiki pattern; see [[decisions/0001-llm-wiki-memory-system]]). Read it before creating or editing wiki pages.

> The wiki is the **second layer** between the raw sources (planning artifacts and code) and the agent. The agent **owns this layer**: it creates pages, updates them as knowledge appears, and maintains links and consistency. The human steers direction and asks questions; the agent drives the wiki.

---

## 1. What the wiki is and is not

**The wiki holds the "plan ↔ reality" delta and dev knowledge** that is not in the planning documents or visible from the code:
- what was **actually built** and how modules are wired in practice;
- decisions made **during implementation** (`decisions/`);
- gotchas, findings, non-obvious details;
- cross-cutting concepts (`concepts/`) touching several modules.

**The wiki does not duplicate** (the main desync risk; violating it makes the wiki harmful):

| Source of truth | Where it lives | How the wiki refers to it |
|---|---|---|
| Work status | {{status_source}} | `overview.md` **links**, never copies statuses |
| Design / architecture | {{architecture_source}} | pages **link** to sections, never retell them |
| Code structure | the in-code READMEs (if the repo keeps them) | pages **link**, never retell |
| Rules for agents | `CLAUDE.md`, `.claude/rules/` | link, don't restate |
| Planning documents (`.plans\`: milestones, stories, PRD) | working files, not committed | a planning fact enters the wiki **only when it has become true in the code**; link to `.plans` for history, never as guidance |

If you catch yourself copying status or structure into the wiki: **stop and add a link instead**.

### In-code README: the third layer (optional)

If the repo keeps a README next to the code per module/area, it is the **code-level explainer** (purpose, diagrams, key classes with paths, entry points, wiring, gotchas). The wiki's module page holds the **delta** (status, decisions, gotchas) and **links** to that README. The README is updated in the same change as the code whenever a module's structure, endpoints, tasks, events or wiring changed.

---

## 2. Structure

```
{{wiki_dir}}/
├── index.md          # catalog of all pages: read first
├── overview.md       # "where we are now": current focus, recently shipped
├── log.md            # chronological append-only journal, newest first
├── conventions.md    # this file
├── decisions/        # dev-time ADR-lite
├── modules/          # one page per module, BORN together with its code
└── concepts/         # cross-cutting concepts, born as needed
```

**Growth principle:** module and concept pages are **born when the code or knowledge appears**, never ahead of time.

---

## 3. Page formats

- **Links between wiki pages:** `[[modules/auth]]`, `[[concepts/events]]`, `[[decisions/0001-llm-wiki-memory-system]]`. A link to a page that does not exist yet is fine: it marks a page worth creating.
- **Links to sources of truth:** ordinary relative markdown links to real files.
- **Module page** (`modules/<name>.md`): `modules/_template.md`: status · purpose · key facts and invariants · ties to other modules · gotchas · links.
- **ADR** (`decisions/NNNN-*.md`): `decisions/_template.md`: context · decision · alternatives · consequences. Sequential numbering; each new ADR gets a row in `decisions/README.md` and in `index.md`.

---

## 4. Operations

### Ingest: when new knowledge appears
Trigger: a story finished / a module implemented / an important fact found / a decision made. Run the `wiki-ingest` skill:
1. Update the in-code README if the module's structure changed (same change as the code).
2. Create/update the module page: the **delta** and a link, not a retelling.
3. Record a decision in `decisions/` when something non-obvious was decided.
4. Update/create a concept page if a cross-cutting aspect was touched.
5. Update `overview.md` (current focus), **without** copying statuses.
6. Add new pages to `index.md`.
7. Append an entry to `log.md`.
One event may touch 3–6 pages: that is normal.

### Query: when answering a question about the project
Read `index.md`, then the relevant pages. If the synthesised answer is reusable (a comparison, a map of relations), **capture it as a page** so knowledge compounds instead of dying in chat.

### Lint: periodic health check
Run `wiki-lint`: contradictions, stale claims, orphans, missing concepts, broken links, boundary drift, index/log drift, agent-memory regrowth.

---

## 5. `log.md` format

Append-only, newest at the **top**. Every entry starts with the same prefix (tools parse `^## \[`):

```
## [YYYY-MM-DD] <type> | <short title>
<1-3 lines: what happened, which pages were touched, links>
```

`<type>` is one of `bootstrap` · `ingest` · `decision` · `query` · `lint` · `refactor`.
The date comes from the session context, never invented.

---

## M. Memory contract

This section rules where agent-derived knowledge lives. Where an older section disagrees, this block wins.

### M1. One durable store, and no private memory

`{{wiki_dir}}/` is the only durable store for agent-derived knowledge: decisions, module behaviour, cross-cutting concepts, gotchas.
Agents keep no private memory between conversations: no `memory:` field in an agent definition, no `.claude/agent-memory/` directory.
"Single store" scopes to **agent-derived dev knowledge** only; it does not move the sources of truth of §1 into the wiki.

### M2. Where a new fact goes

- **A fact about the project** (a decision, how a module behaves, a gotcha, an open defect, an accepted risk) goes to the wiki page that owns it, through Ingest.
- **A lesson about how an agent should work** (a review method, a check to run first) goes into the agent's own definition, or into the rule file or skill that owns that process.
- **A read-only agent** (reviewer, advisor, analyst) writes nothing: it puts what it learned in its report, and the caller records it.
- **Session scratch** (verdict-state like "module swept clean on DATE", file locations in repos this one does not own) is not recorded at all: it goes stale on the next merge and would read as a claim about the project.

### M3. Re-verify before acting

A wiki page, README or report is a claim about a codebase that may have moved. Before acting on one:
- **A claim naming a file, route, endpoint or symbol:** confirm it still exists by that name. Cheapest check, catches most rot.
- **A claim about a repository this one does not own:** re-read the source; it is a snapshot, never a fact.
- **A claim established by running something** (a round-trip, a fixture, a test): re-run it; reading code that looks right proves nothing.
- **A claim that something is "frozen", "final", "closed" or "open":** treat that word as the most perishable part; counts and states drift first, silently.

Dates are absolute (`2026-08-27`), never relative ("last week").

### M4. One claim, one owning page

A fact is written in exactly one place; every other mention links to it. When two sources disagree, the tie is broken by **current code**, not by recency or prose quality. The losing statement is deleted, not softened.

### M5. `log.md`: order and bands

**Newest entry at the top.** The session hook reads the newest end, so position decides whether any agent sees an entry. The journal is append-only for new entries; only a deliberate cleanup run may rewrite old ones, within these bands:

| Band | Range | What a cleanup run may do |
|---|---|---|
| **A** | The newest 30 entries | Nothing. |
| **B** | Older than A, newer than C | Trim the body to 1–3 lines. The `## [YYYY-MM-DD] <type> \| <title>` header is preserved **exactly** (tooling parses it). |
| **C** | Entries from a closed project phase | Collapse into one summary entry keeping the date range, the phase name and **every outgoing link** (lint finds orphan pages by counting incoming links). |

Trim only after anything worth keeping is recorded in the page the entry links to.

### M6. Budgets

`index.md` and `overview.md` are injected into every session, so their size is a cost paid by every agent on every task.

| File | Budget |
|---|---|
| `overview.md` | at most 300 lines |
| `index.md` | one row per page, no prose beyond the header |
| A wiki page | split when it stops being readable in one sitting |

A new fact **merges into an existing page** by default. A new page is justified only when an existing page already links to it.

### M7. Regrowth guards

`wiki-lint` (or a repo test) fails loudly when: an agent definition carries a `memory:` field; a `.claude/agent-memory/` directory exists; anything points into `.claude/agent-memory/`.

---

## 6. How this runs

- **Reading:** the plugin's `SessionStart` hook injects a **digest** (~6.5 KB: head of `overview.md` §Current focus, newest §Recently shipped, newest `log.md` titles, page names from `index.md`). It is a digest because Claude Code inlines hook output only up to ~10 KB; larger output is spilled to a file no session reads. So the files are **not** in context: read `index.md` before working on a module and `overview.md` for the full state.
- **Writing:** the `Stop` hook nudges (never blocks) when code changed but the wiki, or the area's README, did not. It does not do the synthesis: running `wiki-ingest` is the agent's job.
- **Configuration:** `.claude/wiki.conf` (paths, watched roots, README mapping, message language).
