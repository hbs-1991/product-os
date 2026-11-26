---
name: wiki-ingest
description: "Integrate new knowledge into the project wiki (docs/wiki or the dir in .claude/wiki.conf). Use when a module was implemented or changed, a decision was made that the design documents do not hold, a gotcha or finding appeared, the current focus shifted, when execute-story reaches its wiki step, or when the Stop hook nudges that the wiki is stale. Runs the Ingest workflow from the wiki's conventions.md."
---

# Wiki Ingest

**Goal:** integrate new dev knowledge into the project wiki so it compounds instead of getting lost.
The rules live in `<wiki_dir>/conventions.md` (this skill executes them, it does not duplicate them).

**When to run:** a module was implemented or changed · a decision was made that is not in the design documents · a gotcha or compatibility detail was found · the current focus shifted · `execute-story` reached its wiki step · the Stop hook reminded you that the wiki is stale.

## Step 0: Get oriented

- Find the wiki: read `.claude/wiki.conf` (`wiki_dir`, default `docs/wiki`). **HALT** if neither the config nor the directory exists: the wiki is not set up; offer `wiki-init`.
- Read `<wiki_dir>/conventions.md` (§1 boundaries, §4 Ingest, the Memory contract) and `<wiki_dir>/index.md`.
- **Which layout the wiki uses is decided by its own `conventions.md`, never by this skill.**
  - Conventions with the 1.3.0 rules (a new wiki, or one converted to them): a log entry is a new file `log/<YYYY-MM-DD>-<HHMM>-<slug>.md` and an ADR is a new file `decisions/<YYYY-MM-DD>-<slug>.md`, with no table, no index row and no number. Steps 3, 6 and 7 below describe this layout.
  - Conventions that define other rules (every wiki scaffolded by product-os up to 1.2.0 keeps a single `log.md`, numbered ADRs and an ADR table; a project may define its own, for example a frozen archive beside `log/`): follow those rules exactly, and do not convert the wiki. `wiki-lint` suggests the conversion to the owner.
- Work out exactly **what knowledge appeared** and which pages it touches: `git diff` / `git log` since the last ingest (the newest `log/` file whose header type is `ingest`, else the top `ingest` entry of `log.md`), the story that just finished, the conversation.
- Dates come from the session context, never invented. For a new entry or ADR take the date and time from one `date +%Y-%m-%d-%H%M` call (the session's local clock).
- **Filter first.** If a fact already lives in a source of truth (tracker, design document, `.plans` plan that is still being used for guidance, the code itself, an in-code README), do **not** copy it: add a link or skip it. A planning fact enters the wiki only once it has become true in the code.

## Step 1: In-code README (if the repo keeps them)

If the change altered a module's or area's structure, classes, endpoints, tasks, events or cross-module wiring, update the README next to the code **in the same change** (a new or removed class, a changed flow, a corrected diagram). A purely internal edit needs no README change.

## Step 2: Module page

If the work touched a module: create `<wiki_dir>/modules/<name>.md` from `modules/_template.md`, or update the existing page. Record only what is **not visible** from the code at first glance: invariants, gotchas, the real wiring. Link to the in-code README and to the tracker/design, never retell them.

## Step 3: Decision (if one was made)

A non-obvious decision not held by the design documents: a new file `<wiki_dir>/decisions/<YYYY-MM-DD>-<slug>.md` from `decisions/_template.md` (today's date, slug `[a-z0-9-]+`; if the name is taken, pick another slug).
Its heading is `# <YYYY-MM-DD>-<slug> — <title>`, and it carries `- **Status:**`, `- **Date:**` (the name's date) and `- **Summary:**` (a one-paragraph abstract) lines; cite it as `ADR <YYYY-MM-DD>-<slug>` and link it as `[[decisions/<YYYY-MM-DD>-<slug>]]`.
It takes no number and gets no table row in `decisions/README.md` and no row in `index.md`: the folder is the list.
When an `AD-n` from `.plans\product\architecture.md` was **proven or changed by the code**, record that here with a link to the AD id; the ADR holds what happened, the architecture document holds the contract.

## Step 4: Concept (if a cross-cutting aspect is involved)

Create or update `<wiki_dir>/concepts/<concept>.md`; link it from module pages as `[[concepts/<concept>]]`.

## Step 5: Overview

Update `<wiki_dir>/overview.md` §Current focus (keep within the 300-line budget). The log entry of Step 7 is the record of what shipped; a wiki whose conventions still keep a §Recently shipped list follows them. **Do not copy** statuses; link to the tracker. If a milestone or epic from `plan-milestone` shipped, name it with a link to the PR, not its plan.

## Step 6: Index

A new module or concept page gets a row in `<wiki_dir>/index.md` (under the right section; one row per page, no prose). ADRs and log entries get no index row.

## Step 7: Log

Write a new file `<wiki_dir>/log/<YYYY-MM-DD>-<HHMM>-<slug>.md` (date and time from the session's local clock, slug `[a-z0-9-]+`) whose first line is its only header, `## [YYYY-MM-DD] ingest | <title>`, with the name's date, followed by 1–3 lines (what, which pages, links). Mandatory: it records that the ingest was performed.
Never write into a `log.md` once `log/` exists: that file is a frozen archive.

## Validation

- Links between wiki pages are `[[relative/path]]`; links to sources of truth are plain markdown links.
- One claim, one owning page: merge into an existing page by default; a new page only when something already links to it.
- Claims that name a file, route or symbol are checked to exist now.
- No statuses, no architecture copied (the main risk, conventions §1).
- One event may touch 3–6 pages: normal.
- Absolute dates only.

## Rules

- Read-only agents (reviewers, advisors) never write the wiki; the caller records what they reported.
- Do not store session scratch ("module swept clean on DATE"): it goes stale at the next merge and reads as a claim about the project.
