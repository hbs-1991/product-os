---
name: wiki-lint
description: "Health-check the project wiki (docs/wiki or the dir in .claude/wiki.conf): contradictions, stale claims, orphans, broken links, missing concepts, boundary drift from the sources of truth, index/log drift, agent-memory regrowth, budgets. Use when the owner asks to lint or health-check the wiki, periodically after several ingests, and before a major stage (end of a milestone, a release)."
---

# Wiki Lint

**Goal:** keep the wiki healthy as it grows. The rules live in `<wiki_dir>/conventions.md` (§4 Lint and the Memory contract).

**When to run:** on request · after several ingests · before a major stage (a milestone closes, a cutover).

## Step 1: Build the map

Read `.claude/wiki.conf` (HALT with an offer of `wiki-init` if the wiki is not set up), then `conventions.md`, `index.md`, `overview.md`, the journal (every `log/*.md` file, and `log.md` if it exists), and enumerate every page (`modules/*`, `concepts/*`, `decisions/*`).

## Step 2: Checks

- **Contradictions** between pages (the same thing stated two ways). Tie-break by **current code**, never by recency.
- **Stale claims**: statements the code or the tracker has moved past. Verify claims that name a file, route or symbol still exist (cheapest check, catches most rot); re-run, not re-read, anything the page says was established by running something.
- **Perishable words**: "frozen", "final", "closed", "open", counts and states; spot-check them first.
- **Orphans**: pages with no inbound links and not in `index.md`.
- **Broken links**: `[[wiki links]]` and relative markdown links to sources of truth.
- **Missing concepts**: a cross-cutting topic mentioned on two or more pages with no page of its own.
- **Boundary drift**: the wiki copies status or architecture instead of linking (conventions §1). Includes planning facts from `.plans` that are not yet true in the code.
- **Index / log drift**: module or concept pages missing from `index.md`; ingest events with no log entry; a log header that does not match `## [YYYY-MM-DD] <type> | <title>`; in a `log.md`, entries not newest-first.
- **Journal files** (`log/`): a name off the pattern `<YYYY-MM-DD>-<HHMM>-<slug>.md` (slug `[a-z0-9-]+`); a file whose first line is not its only `## [` header; a name date that differs from the header date.
- **Frozen `log.md`**: once `log/` exists, a `log.md` entry dated after the oldest `log/` file (it belongs in `log/` as its own file).
- **Date-slug ADRs** (`decisions/<YYYY-MM-DD>-<slug>.md`): a missing `- **Status:**`, `- **Date:**` or `- **Summary:**` line; a heading other than `# <file name without .md> — <title>`; a `Date:` that differs from the name's date; a row for one in `decisions/README.md` or in `index.md` §Decisions (date-slug ADRs are listed by the folder).
- **Pre-1.3.0 layout**: when `conventions.md` still defines a single `log.md` journal, numbered ADRs or an ADR table, report as a suggestion, never a conversion: "conventions use the pre-1.3.0 single-file layout; adopt `log/` and date-slug ADRs by updating §2, §3, §4 and §5". The owner decides; until then `wiki-ingest` follows the wiki's own rules.
- **Budgets**: `overview.md` over 300 lines; `index.md` rows with prose; a page too long to read in one sitting.
- **Relative dates** ("last week", "recently") anywhere: replace with absolute dates.
- **Agent-memory regrowth**: an agent definition with a `memory:` field, a `.claude/agent-memory/` directory, or anything pointing into it. Agents keep no private memory; the wiki is the one store.
- **Hook config**: `.claude/wiki.conf` points at an existing `wiki_dir`; the digest headings exist (`## Current focus` in overview; `## Root pages`, `## Modules`, `## Concepts`, `## Decisions` in index; `## Recently shipped` is optional and shown only when present). Run `hooks/wiki-selftest.sh` from the plugin if it can be located.

## Step 3: Report

A grouped list of findings with paths and proposed edits. Suggest new concept pages and questions worth working through. Do not propose adding anything that belongs in the tracker or the design documents.

## Step 4: Fix (on confirmation)

With the owner's agreement apply the edits (using `wiki-ingest` logic) and record the run as a new log entry following the wiki's conventions: a new file `log/<YYYY-MM-DD>-<HHMM>-<slug>.md` whose header is `## [YYYY-MM-DD] lint | <outcome>` (a wiki that keeps the pre-1.3.0 single `log.md` gets the entry at the top of that file). Do not fix silently; report first. The exception is an obviously broken link.

## Rules

- Dates from the session context.
- A cleanup of old journal entries follows the bands in conventions §M5 (never touch the newest 30; never alter a header line; collapse band C files into one summary file that carries every outgoing link). Never edit a frozen `log.md` while pull requests are open against it.
