---
name: wiki-lint
description: "Health-check the project wiki (docs/wiki or the dir in .claude/wiki.conf): contradictions, stale claims, orphans, broken links, missing concepts, boundary drift from the sources of truth, index/log drift, agent-memory regrowth, budgets. Use when the owner asks to lint or health-check the wiki, periodically after several ingests, and before a major stage (end of a milestone, a release)."
---

# Wiki Lint

**Goal:** keep the wiki healthy as it grows. The rules live in `<wiki_dir>/conventions.md` (§4 Lint and the Memory contract).

**When to run:** on request · after several ingests · before a major stage (a milestone closes, a cutover).

## Step 1: Build the map

Read `.claude/wiki.conf` (HALT with an offer of `wiki-init` if the wiki is not set up), then `index.md`, `overview.md`, `log.md`, and enumerate every page (`modules/*`, `concepts/*`, `decisions/*`).

## Step 2: Checks

- **Contradictions** between pages (the same thing stated two ways). Tie-break by **current code**, never by recency.
- **Stale claims**: statements the code or the tracker has moved past. Verify claims that name a file, route or symbol still exist (cheapest check, catches most rot); re-run, not re-read, anything the page says was established by running something.
- **Perishable words**: "frozen", "final", "closed", "open", counts and states; spot-check them first.
- **Orphans**: pages with no inbound links and not in `index.md`.
- **Broken links**: `[[wiki links]]` and relative markdown links to sources of truth.
- **Missing concepts**: a cross-cutting topic mentioned on two or more pages with no page of its own.
- **Boundary drift**: the wiki copies status or architecture instead of linking (conventions §1). Includes planning facts from `.plans` that are not yet true in the code.
- **Index / log drift**: pages missing from `index.md`; ingest events with no `log.md` entry; log not newest-first; a log header that does not match `## [YYYY-MM-DD] <type> | <title>`.
- **Budgets**: `overview.md` over 300 lines; `index.md` rows with prose; a page too long to read in one sitting.
- **Relative dates** ("last week", "recently") anywhere: replace with absolute dates.
- **Agent-memory regrowth**: an agent definition with a `memory:` field, a `.claude/agent-memory/` directory, or anything pointing into it. Agents keep no private memory; the wiki is the one store.
- **Hook config**: `.claude/wiki.conf` points at an existing `wiki_dir`; the digest headings exist (`## Current focus`, `## Recently shipped` in overview; `## Root pages`, `## Modules`, `## Concepts`, `## Decisions` in index). Run `hooks/wiki-selftest.sh` from the plugin if it can be located.

## Step 3: Report

A grouped list of findings with paths and proposed edits. Suggest new concept pages and questions worth working through. Do not propose adding anything that belongs in the tracker or the design documents.

## Step 4: Fix (on confirmation)

With the owner's agreement apply the edits (using `wiki-ingest` logic) and prepend to `log.md`: `## [YYYY-MM-DD] lint | <outcome>`. Do not fix silently; report first. The exception is an obviously broken link.

## Rules

- Dates from the session context.
- A cleanup of old `log.md` entries follows the bands in conventions §M5 (never touch the newest 30; never alter a header line; carry every outgoing link into a collapsed summary).
