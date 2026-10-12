# product-os

**An owner-gated path from an idea to merged code, with a memory that survives the session.**
A Claude Code plugin in four layers. Every layer ends in an explicit owner approval before the next one starts, and every review is done by a *fresh* agent that never saw the work it is checking.

```text
                        ┌─ 1 create-product-brief   what and why, honest, 1-2 pages
 project-pipeline ──────┼─ 2 create-prd             user journeys + journey WEIGHTS, numbered FRs
 (a whole project)      ├─ 3 create-ux-design       design system: DESIGN.md + EXPERIENCE.md
                        ├─ 4 create-architecture    paradigm, stack, numbered invariants (AD-n)
                        └─ 5 plan-milestone         roadmap M1..Mn, then epics one milestone at a time
                                         │
                                         ▼  one epic at a time
 feature-pipeline ──── brainstorming (Unknowns Matrix, blind-spot pass) ─► write-story ─► execute-story
 (one feature)          └ ui-direction / ui-mockup for screens            └ refute-story, e2e, PR

 wiki-memory ───────── SessionStart digest · Stop nudge · wiki-init / wiki-ingest / wiki-lint
```

Four levels of planning, detailed just in time: **roadmap → milestones → epics → stories**.
A milestone is a verifiable outcome, an epic is one feature-pipeline run, a story is one approved spec. Only the next milestone gets epics; later ones stay outlines until their predecessor is done.

## Install

```text
/plugin marketplace add hbs-1991/product-os
/plugin install product-os@product-os
```

Or from a local clone: `/plugin marketplace add ./product-os`.

Then say what you want: "new project", "plan a milestone", "let's build X", "set up the project wiki", or call a skill directly, e.g. `/product-os:project-pipeline`.

## Skills

**Project level**

| Skill | Role |
|---|---|
| `project-pipeline` | entry for a whole project: stage plan, working mode, gates, handoff checks between documents, staleness tracking, state in `.plans\product\pipeline.md` |
| `create-product-brief` | coached brain dump, optional brainstorm, landscape and user-voice research, a 1-2 page brief |
| `create-prd` | the user-flow stage (named-protagonist journeys, user-flow research of comparable products, Core / Supporting / Edge weights), then a PRD with glossary, numbered FRs with testable consequences, NFRs, non-goals, MVP, metrics and counter-metrics |
| `create-ux-design` | UI/UX research, UI-system choice, three visual directions via `ui-direction`, then `DESIGN.md` (tokens) and `EXPERIENCE.md` (IA, states, flows) |
| `create-architecture` | coached load-bearing decisions, web-verified stack and versions, a lean spine of `AD-n` invariants, FR → architecture map |
| `research-protocol` | the shared research rules: never conclude from training data, project context shapes questions not facts, cited digests, subagent brief, shared memlog |
| `plan-milestone` | ROADMAP (outline milestones), PLAN (epics with briefs for one milestone), RUN (next unblocked epic into feature-pipeline), STATUS (tree report); optional GitHub mirror (milestone, epic issues, sub-issues); estimates assume AI agents write the code |

**Feature level**

| Skill | Role |
|---|---|
| `feature-pipeline` | entry point: size gate, the three stages, the rules across them |
| `brainstorming` | the Unknowns Matrix: known knowns, known unknowns, unknown knowns, unknown unknowns (blind-spot pass) |
| `ui-direction`, `ui-mockup`, `gpt-image-2` | research → taste filter → three directions → three mocks → your pick; image generation via an OpenAI API key or the local Codex CLI |
| `write-story` | one story = spec: Agent, acceptance criteria, tasks, work streams, locked decisions |
| `execute-story`, `parallel-story-execution` | worktree, implementers (parallel when file-disjoint), gate, review, E2E, verification, PR |
| `refute-story` | review → verify → fix confirmed only → ≤2 rounds → Review record |
| `root-cause-debugging`, `verify-before-pr` | root cause before any fix; evidence before "done" |

**Memory**

| Skill | Role |
|---|---|
| `wiki-init` | scaffold the project wiki, write `.claude/wiki.conf`, offer a CLAUDE.md pointer |
| `wiki-ingest` | integrate new knowledge: module page, ADR, concept, overview, index, log |
| `wiki-lint` | contradictions, stale claims, orphans, boundary drift, regrowth guards, budgets |

**Agents** (`agents/`): `blind-spot-reviewer`, `ui-mocker`, `implementation-advisor`, `story-implementer`, `story-refuter`, `finding-verifier`, `security-reviewer`, `e2e-recorder`. A repo's own agent of the same name always wins.

## Where files go

Planning documents live **next to the code but never in the code repo's git**:

```text
<repo>\.plans\                      its own nested git repo, excluded via .git/info/exclude
  product\brief.md, prd.md, ux\, architecture.md, research\, pipeline.md, .memlog.md
  roadmap.md   milestones\M1-<slug>.md   stories\YYYY-MM-DD-<slug>.md   design\<slug>\
```

`<repo>` is the main checkout (never a worktree). In a cross-repo project the **backend** repo is main: the roadmap, milestones and architecture live there, the other repos get link stubs, and each repo keeps its own stories. Nothing in `.plans` is pushed unless you ask.

The **wiki** (`docs/wiki`, committed with the code) is the other half: durable knowledge about what *exists*. A planning fact enters the wiki only once it is true in the code; `execute-story` runs `wiki-ingest` at the end of every story.

## The wiki hooks

`hooks/hooks.json` registers two hooks, both **opt-in**: they do nothing until `.claude/wiki.conf` exists in the repo (`wiki-init` writes it).

- **SessionStart** injects a ~6.5 KB digest (current focus, newest shipped, newest log titles, page names). It is a digest because Claude Code inlines hook output only up to ~10 KB and spills the rest to a file no session reads.
- **Stop** nudges (never blocks) when watched code changed but the wiki, or the area's README, did not.

`.claude/wiki.conf` is parsed, never sourced: `wiki_dir`, `lang` (`en`/`ru`), `watch`, `code_ext`, `readme_per_child`, `readme_flat`, and the digest budgets. A repo that already has its own wiki hooks should not add a `wiki.conf`, or both would run. Self-test: `sh hooks/wiki-selftest.sh`.

## Requirements

| What | Needed for | How |
|---|---|---|
| Claude Code with plugin support, `git` | everything | n/a |
| POSIX `sh` + `awk` (Git Bash on Windows) | the wiki hooks | bundled with Git for Windows |
| `gh` CLI, logged in | the PR, and the optional GitHub mirror of milestones | `gh auth login` |
| `OPENAI_API_KEY` with `gpt-image-2` access, **or** the Codex CLI logged in | UI mocks | optional, only for screens |
| `playwright-cli` | the E2E screen recording | `npm install -g @playwright/cli@latest`, optional, only for UI |
| Node.js | the brainstorming visual board | optional |

Without the optional tools everything still runs; each skill says which step it skipped.

## Make it yours

The skills read **your** repository's `CLAUDE.md`, `.claude/rules/`, ADRs, READMEs and CI to know what "correct" means. The better those describe your architecture and rules, the sharper the reviews. To specialise an agent, put one with the same name in the repo's `.claude/agents/`.

## Credits

The discovery chain is adapted from [BMad Method](https://github.com/bmad-code-org/bmad-method) (`bmad-product-brief`, `bmad-prd`, `bmad-ux`, `bmad-architecture`, `bmad-deep-recon`) and re-shaped for this pipeline. The wiki follows the LLM-Wiki pattern.

## License

MIT
