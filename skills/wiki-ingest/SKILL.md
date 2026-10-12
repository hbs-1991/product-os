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
- Work out exactly **what knowledge appeared** and which pages it touches: `git diff` / `git log` since the last `ingest` entry in `log.md`, the story that just finished, the conversation.
- Dates come from the session context, never invented.
- **Filter first.** If a fact already lives in a source of truth (tracker, design document, `.plans` plan that is still being used for guidance, the code itself, an in-code README), do **not** copy it: add a link or skip it. A planning fact enters the wiki only once it has become true in the code.

## Step 1: In-code README (if the repo keeps them)

If the change altered a module's or area's structure, classes, endpoints, tasks, events or cross-module wiring, update the README next to the code **in the same change** (a new or removed class, a changed flow, a corrected diagram). A purely internal edit needs no README change.

## Step 2: Module page

If the work touched a module: create `<wiki_dir>/modules/<name>.md` from `modules/_template.md`, or update the existing page. Record only what is **not visible** from the code at first glance: invariants, gotchas, the real wiring. Link to the in-code README and to the tracker/design, never retell them.

## Step 3: Decision (if one was made)

A non-obvious decision not held by the design documents: `<wiki_dir>/decisions/NNNN-*.md` from `decisions/_template.md` (next number), a row in `decisions/README.md`. When an `AD-n` from `.plans\product\architecture.md` was **proven or changed by the code**, record that here with a link to the AD id; the ADR holds what happened, the architecture document holds the contract.

## Step 4: Concept (if a cross-cutting aspect is involved)

Create or update `<wiki_dir>/concepts/<concept>.md`; link it from module pages as `[[concepts/<concept>]]`.

## Step 5: Overview

Update `<wiki_dir>/overview.md` (§Current focus, §Recently shipped; keep within the 300-line budget). **Do not copy** statuses; link to the tracker. If a milestone or epic from `plan-milestone` shipped, name it with a link to the PR, not its plan.

## Step 6: Index

A new page gets a row in `<wiki_dir>/index.md` (under the right section; one row per page, no prose).

## Step 7: Log

Prepend an entry at the **top** of `<wiki_dir>/log.md`: `## [YYYY-MM-DD] ingest | <title>` + 1–3 lines (what, which pages, links). Mandatory: it records that the ingest was performed.

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
