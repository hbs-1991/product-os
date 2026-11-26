# Wiki Conventions — schema and maintenance rules

This is the **schema file** of {{project}}'s wiki (the LLM-Wiki pattern; see [[decisions/{{date}}-llm-wiki-memory-system]]). Read it before creating or editing wiki pages.

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
├── overview.md       # "where we are now": current focus, links to the sources of truth
├── log/              # the journal: one file per entry, <YYYY-MM-DD>-<HHMM>-<slug>.md
├── conventions.md    # this file
├── decisions/        # dev-time ADR-lite
├── modules/          # one page per module, BORN together with its code
└── concepts/         # cross-cutting concepts, born as needed
```

**Growth principle:** module and concept pages are **born when the code or knowledge appears**, never ahead of time.

---

## 3. Page formats

- **Links between wiki pages:** `[[modules/auth]]`, `[[concepts/events]]`, `[[decisions/{{date}}-llm-wiki-memory-system]]`. A link to a page that does not exist yet is fine: it marks a page worth creating.
- **Links to sources of truth:** ordinary relative markdown links to real files.
- **Module page** (`modules/<name>.md`): `modules/_template.md`: status · purpose · key facts and invariants · ties to other modules · gotchas · links.
- **ADR** (`decisions/<YYYY-MM-DD>-<slug>.md`): `decisions/_template.md`: context · decision · alternatives · consequences, behind the mandatory `- **Status:**`, `- **Date:**` and `- **Summary:**` lines.
  Its id is the file name without `.md`, for example `{{date}}-llm-wiki-memory-system`: the heading is `# <id> — <title>`, it is cited `ADR <id>` and linked `[[decisions/<id>]]`.
  The date is the day the ADR is written (the same as its `Date:` line) and the slug is `[a-z0-9-]+`.
  The id is a date and a slug, never a running number, so two branches never claim the same one.
  ADRs are listed by their folder, `decisions/`: they get no table row in `decisions/README.md` and no row in `index.md`; the `Summary:` line is the abstract a reader greps for.

---

## 4. Operations

### Ingest: when new knowledge appears
Trigger: a story finished / a module implemented / an important fact found / a decision made. Run the `wiki-ingest` skill:
1. Update the in-code README if the module's structure changed (same change as the code).
2. Create/update the module page: the **delta** and a link, not a retelling.
3. Record a decision when something non-obvious was decided: a new file `decisions/<YYYY-MM-DD>-<slug>.md` (§3), with no table row and no number.
4. Update/create a concept page if a cross-cutting aspect was touched.
5. Update `overview.md` (current focus), **without** copying statuses.
6. Add new module and concept pages to `index.md`; ADRs and log entries get no index row.
7. Write the log entry as its own new file, `log/<YYYY-MM-DD>-<HHMM>-<slug>.md` (§5).
One event may touch 3–6 pages: that is normal.

### Query: when answering a question about the project
Read `index.md`, then the relevant pages. If the synthesised answer is reusable (a comparison, a map of relations), **capture it as a page** so knowledge compounds instead of dying in chat.

### Lint: periodic health check
Run `wiki-lint`: contradictions, stale claims, orphans, missing concepts, broken links, boundary drift, index/log drift, agent-memory regrowth.

---

## 5. `log/` journal format

One entry, one file: `log/<YYYY-MM-DD>-<HHMM>-<slug>.md`.
Two pull requests then never write the same file, so the journal produces no merge conflicts ([[decisions/{{date}}-llm-wiki-memory-system]]).
The date and the time (`HHMM`) come from the session's local clock, from one `date +%Y-%m-%d-%H%M` call, so the name and the header agree; the slug is `[a-z0-9-]+`.
The order is the file name: the newest entry is the name that sorts last (`ls log | sort -r | head` lists the newest first).
The first line of the file is its only entry header, and its date is the file name's date.
Every entry starts with the same prefix (tools parse `^## \[`):

```
## [YYYY-MM-DD] <type> | <short title>
<1-3 lines: what happened, which pages were touched, links>
```

`<type>` is one of `bootstrap` · `ingest` · `decision` · `query` · `lint` · `refactor`.
The date comes from the session context, never invented.

A wiki that kept its journal in a single `log.md` before `log/` existed keeps that file as a frozen archive: once `log/` exists nothing new is written into `log.md`, and `wiki-lint` flags a `log.md` entry dated after the oldest `log/` file.

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

### M5. The journal: one file per entry, order and bands

**One entry, one file, and the order is the file name** (§5).
The session hook reads the newest names, so an entry's name decides whether any agent sees it.
The journal is append-only for new entries; only a deliberate cleanup run may rewrite old ones, within these bands, counted over the entry files in name order:

| Band | Range | What a cleanup run may do |
|---|---|---|
| **A** | The newest 30 entries | Nothing. |
| **B** | Older than A, newer than C | Trim the body to 1–3 lines. The `## [YYYY-MM-DD] <type> \| <title>` header is preserved **exactly** (tooling parses it). |
| **C** | Entries from a closed project phase | Collapse the N entry files into one summary file named `<newest date>-<HHMM>-<slug>.md` after the newest collapsed entry's date and time, with the header `## [<newest date>] refactor \| <phase> (<from>..<to>)`; it keeps **every outgoing link** the collapsed entries carried (lint finds orphan pages by counting incoming links), and the N files it replaces are deleted. |

Trim only after anything worth keeping is recorded in the page the entry links to.
A frozen `log.md` (§5) is not edited by a cleanup run while pull requests are open against it; a cleanup of that file is its own pull request, approved by the owner.

### M6. Budgets

`index.md` and `overview.md` are injected into every session, so their size is a cost paid by every agent on every task.

| File | Budget |
|---|---|
| `overview.md` | at most 300 lines |
| `index.md` | one row per page, no prose beyond the header |
| A wiki page | split when it stops being readable in one sitting |

A new fact **merges into an existing page** by default. A new page is justified only when an existing page already links to it.
ADRs and log entries are listed by their folders (`decisions/`, `log/`), never by rows in `index.md`.

### M7. Regrowth guards

`wiki-lint` (or a repo test) fails loudly when: an agent definition carries a `memory:` field; a `.claude/agent-memory/` directory exists; anything points into `.claude/agent-memory/`.

---

## 6. How this runs

- **Reading:** the plugin's `SessionStart` hook injects a **digest** (~6.5 KB: head of `overview.md` §Current focus, page names from `index.md`, the number of ADRs in `decisions/`, and the newest log entry titles, read from `log/` newest file name first and topped up from an old `log.md`). It is a digest because Claude Code inlines hook output only up to ~10 KB; larger output is spilled to a file no session reads. So the files are **not** in context: read `index.md` before working on a module and `overview.md` for the full state.
- **Writing:** the `Stop` hook nudges (never blocks) when code changed but the wiki, or the area's README, did not. It does not do the synthesis: running `wiki-ingest` is the agent's job.
- **Configuration:** `.claude/wiki.conf` (paths, watched roots, README mapping, message language).
