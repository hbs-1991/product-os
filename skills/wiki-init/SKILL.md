---
name: wiki-init
description: "Set up the project wiki (LLM-Wiki memory) in a repository: scaffolds docs/wiki (index, overview, log, conventions with the memory contract, ADR/module/concept templates), writes .claude/wiki.conf so the plugin's SessionStart and Stop hooks switch on, and offers a CLAUDE.md pointer. Use when the owner says 'init wiki', 'set up project memory', 'заведи вики/память проекта', or when project-pipeline / execute-story find no wiki in a project that should have one."
---

# Wiki Init

The wiki is the project's **durable, agent-maintained memory**: a persistent knowledge layer between the planning artifacts / code and the agent (the LLM-Wiki pattern: a synthesis wiki, not RAG).
It records the **plan ↔ reality delta and dev knowledge** that is not visible from the code: what was actually built and wired, decisions made while building, gotchas, cross-cutting concepts.
This skill creates the structure and switches the hooks on. Keeping it alive is `wiki-ingest`; keeping it healthy is `wiki-lint`.

```text
SessionStart hook   injects a ~6.5 KB DIGEST (current focus, newest shipped, newest log titles, page names)
Stop hook           nudges when code changed but the wiki / the area README did not (never blocks)
wiki-ingest         the agent integrates new knowledge: module page, ADR, concept, overview, index, log
wiki-lint           periodic health check: contradictions, stale claims, orphans, boundary drift
```

The hooks ship with the plugin and are **opt-in per repository**: they do nothing until `.claude/wiki.conf` exists. That file is what this skill writes.

## 0. Preconditions (read, don't ask)

- A git repository (the Stop hook reads `git status`). If there is none, say so and stop.
- Does `<wiki_dir>` (default `docs/wiki`) already exist? If yes: **do not scaffold over it**. Offer: write only `.claude/wiki.conf` to adopt it (check that the headings the digest needs exist: `## Current focus`, `## Recently shipped` in overview.md; `## Root pages`, `## Modules`, `## Concepts`, `## Decisions` in index.md; log entries start with `## [`) and run `wiki-lint` afterwards.
- Does the repo already have its own wiki hooks in `.claude/settings.json` (a project-level `SessionStart`/`Stop` wiki script)? Then installing `wiki.conf` would double-inject. Tell the owner and stop unless they choose to retire the project hooks.
- Read `CLAUDE.md`, `.claude/rules/*`, the top-level layout and the language of existing docs, to fill the config sensibly.

## 1. Ask (one message, max 5 questions; propose defaults from step 0)

1. **Wiki directory** (default `docs/wiki`).
2. **Language of hook messages**: `en` or `ru` (the wiki pages themselves are written in whatever language the project's docs use; ask).
3. **Watched code roots** for the "code changed, wiki not" nudge, e.g. `src/ app/ lib/` (default: the main source dirs you found).
4. **In-code READMEs?** If the repo keeps (or wants) a README per module/area next to the code: which roots are *per-child* (`src/modules` → one README per child folder) and which are *flat* (`src/workers` → one README for the folder). Skip when the owner does not want that layer.
5. **Sources of truth** the wiki must reference but never copy: where *work status* lives (GitHub issues, `.plans\milestones`, a tracker), where *architecture/design* lives (`.plans\product\architecture.md`, an `architecture/` dir), where *agent rules* live (`CLAUDE.md`, `.claude/rules/`).

## 2. Scaffold

Create, from this skill's `templates\` folder (substituting `{{project}}`, `{{date}}` = today's real date, `{{wiki_dir}}`, and the sources of truth from question 5):

```text
<wiki_dir>\index.md            page catalog; sections: Root pages · Decisions · Modules · Concepts
<wiki_dir>\overview.md         "where the project stands": ## Current focus · ## Recently shipped
<wiki_dir>\log.md              append-only journal, newest entry at the TOP
<wiki_dir>\conventions.md      schema + maintenance rules + the Memory contract (M1-M7)
<wiki_dir>\decisions\_template.md   and decisions\README.md (the ADR table)
<wiki_dir>\modules\_template.md
<wiki_dir>\concepts\README.md
<repo>\.claude\wiki.conf       hook configuration (parsed by the hooks, never sourced)
```

Template map (`templates\` file -> target):

| Template | Target |
|---|---|
| `index.md`, `overview.md`, `log.md`, `conventions.md` | `<wiki_dir>\` same name |
| `decisions-_template.md`, `decisions-README.md` | `<wiki_dir>\decisions\_template.md`, `README.md` |
| `0001-llm-wiki-memory-system.md` | `<wiki_dir>\decisions\0001-llm-wiki-memory-system.md` |
| `modules-_template.md` | `<wiki_dir>\modules\_template.md` |
| `concepts-README.md` | `<wiki_dir>\concepts\README.md` |
| `wiki.conf` | `<repo>\.claude\wiki.conf` |
| `claude-md-snippet.md` | shown to the owner, appended to `CLAUDE.md` on a yes |

Placeholders: `{{project}}`, `{{date}}`, `{{wiki_dir}}`, `{{lang}}`, `{{watch}}`, `{{code_ext}}`, `{{readme_per_child}}`, `{{readme_flat}}`, `{{status_source}}`, `{{architecture_source}}`, `{{current_focus}}`. Leave an optional config value empty rather than inventing it.

Rules:
- **Do not pre-create module or concept pages.** They are born when the code or knowledge appears; empty placeholders go stale before they are ever born.
- Seed `decisions\0001-llm-wiki-memory-system.md` from `templates\0001-llm-wiki-memory-system.md` (why the wiki exists and its boundaries, adapted to this repo).
- Seed `log.md` with one `bootstrap` entry; seed `overview.md` §Current focus from the repo's reality (what the project is, the current state as far as the README/`.plans` say). If the owner has `.plans\product\` documents, **link** to them; never copy them.
- Write `.claude/wiki.conf` from `templates\wiki.conf` with the answers. It is committed with the repo (shared with the team); it contains no secrets.
- If the plugin's hooks are not yet active in this session, say that they switch on from the **next session start** (`/hooks` or a restart); the Stop nudge starts at the next turn after that.

## 3. CLAUDE.md pointer (offer, don't write unasked)

Show the owner `templates\claude-md-snippet.md` (a short "Project Wiki / Memory" section: the wiki is read via the digest + `index.md`, updated through `wiki-ingest`, checked by `wiki-lint`, and the in-code README rule when enabled). Append it to `CLAUDE.md` only on a yes.

## 4. Verify

1. The plugin ships `hooks\wiki-selftest.sh` (two levels above this skill's base directory); run it with `sh` and expect `OK`. It tests the hooks in a throwaway repo, not this one, so also read the new `wiki.conf` back and check that every digest heading above exists in the new files. If the script cannot be located, the heading check alone is enough.
2. List what was created, the config values, and the next step ("run `wiki-ingest` when the first module lands").
3. Commit nothing unasked; mention that `.claude/wiki.conf` and `<wiki_dir>` are meant to be committed.

## Relation to the planning layer

- `.plans\` (milestones, stories, product documents) is **working planning**: not committed to the code repo, mutable, pre-implementation.
- The wiki is **durable knowledge about what exists**: committed, versioned in PRs, travels with the code.
- A planning fact becomes wiki knowledge only when it has become true in the code; `wiki-ingest` (run at the end of `execute-story`) is the bridge. The wiki links to `.plans` only for history, never as guidance.

## Rules

- Never overwrite an existing wiki or config without the owner's explicit yes.
- Dates are real (`{{date}}` from the session context), absolute, never relative.
- The scaffold is small on purpose; growth happens through `wiki-ingest`.
