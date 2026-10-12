# 0001 — The wiki as the project's memory

- **Status:** accepted
- **Date:** {{date}}
- **Related:** [[conventions]] · `.claude/wiki.conf`

## Context
Knowledge accumulates while the project is built that is in no planning document: what was actually built, decisions made on the way, gotchas, the real wiring between modules. It gets lost between sessions. The project needs a persistent memory the agent reads every session and updates as it works (the LLM-Wiki pattern: a synthesis wiki, not RAG).

Non-obvious and therefore recorded: without explicit boundaries a wiki becomes a duplicate of the status tracker and the architecture documents, and drifts from both.

## Decision
1. **Storage:** in-repo `{{wiki_dir}}/`: versioned, visible in PRs, travels with the code. Not private agent memory.
2. **Boundaries:** the wiki stores the plan ↔ reality delta and dev knowledge; it **links** to {{status_source}} (status) and {{architecture_source}} (design) and never copies them.
3. **Mechanism:** the product-os plugin's hooks, switched on by `.claude/wiki.conf`: `SessionStart` injects a size-capped digest; `Stop` nudges when code changed and the wiki did not. The `wiki-ingest` and `wiki-lint` skills do the work.
4. **Minimal growth:** module and concept pages are born with the code or knowledge, never ahead of time.

## Alternatives
- *Native per-user memory*: rejected: not versioned, not visible in PRs, tied to one machine.
- *A manual sync command*: rejected: too easy to forget, so it goes stale.
- *Per-agent private memory*: rejected: invisible to other agents and to the team.

## Consequences
- The hook does not synthesise: it injects and reminds; the agent performs the update (see [[conventions]] §4).
- Update the wiki in the same change as the code, or the Stop hook nudges.
- The wiki never duplicates status or architecture: only links to them (risk #1).
