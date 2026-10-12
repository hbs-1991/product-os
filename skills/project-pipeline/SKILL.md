---
name: project-pipeline
description: "Use to take a new project (or a big new product area) from an idea to a planned, runnable roadmap in one guided flow: 'new project', 'новый проект', 'с нуля', 'run the project pipeline', 'прогони весь флоу', 'от идеи до роадмапа', 'продолжи проект'. Orchestrates the discovery chain with an owner gate between stages: product brief -> PRD (user flows + journey weights) -> UX design (design system) -> architecture (stack) -> roadmap (plan-milestone ROADMAP) -> plan the first milestone -> hand epics to feature-pipeline. Detects where a project already is and resumes there; tracks staleness when an upstream document changes."
---

# Project Pipeline

The entry point for **a whole project**, one level above `feature-pipeline` (which is for one feature).
It does not write documents itself: it runs the stage skills in order, keeps the state, checks the handoffs and stops at every owner gate.

```text
 idea
  │
  ▼
 1. create-product-brief    what and why, honest, 1-2 pages              ──┐
 2. create-prd              user flows + journey WEIGHTS, numbered FRs     │  .plans\product\
 3. create-ux-design        design system: DESIGN.md + EXPERIENCE.md       │  (state: pipeline.md)
 4. create-architecture     paradigm, stack, invariants (AD-n)           ──┘
 5. plan-milestone ROADMAP  milestones M1..Mn, outlined only
 6. plan-milestone PLAN M1  epics with briefs (just in time)
 7. RUN: epic by epic ──►  feature-pipeline (brainstorming → story → PR)  → next milestone: back to 6
```

Chat language follows the owner; every written artifact is in English.
**Owner approval between stages is explicit** ("yes", "approve", a choice picked), never inferred from silence or from a background-task notification. Approval covers only what the question asked.
Repo rules (`CLAUDE.md`, `.claude/rules/*`) win wherever stricter.

## 0. Where is the project? (always first)

Resolve `<repo>` (main checkout; for a cross-repo project the **backend** repo; a brand-new project with no repo: ask once where it lives and use `<that dir>\.plans`) and read `<repo>\.plans\product\pipeline.md` if it exists.
No state file: infer the position from what exists (`brief.md`, `prd.md`, `ux\DESIGN.md`+`EXPERIENCE.md`, `architecture.md`, `..\roadmap.md`, `..\milestones\`, existing code), write the state file, and show it:

```text
Project: <name>            repo: <repo>
 ✔ 1 brief          final   2026-10-12
 ✔ 2 prd            final   2026-10-13
 ▶ 3 ux design      draft   (in progress)
 ○ 4 architecture   —
 ○ 5 roadmap        —
```

Then ask the owner **where to enter**, with a recommendation:

| Situation | Enter at |
|---|---|
| Idea only | 1 |
| Clear idea, no documents | 1 in Fast path, or 2 if the owner can state the product in a paragraph |
| Has a brief or notes | 2 (the brief is built from the notes) |
| Existing codebase, new milestone-level work | 4 in *ratify* mode (record the conventions already there), then 2 for the new scope |
| Everything exists | 5 |

## 1. The stage plan (once, before stage 1)

Not every project needs every stage. Propose the plan with reasons and let the owner change it:

| Stage | Include when | Skip when |
|---|---|---|
| 1 brief | the idea is not yet sharp, or stakes need an honest one-pager | the owner already has a written brief |
| 2 PRD | more than ~3 features, several user journeys, or several people/agents will build in parallel | a single-purpose tool; the brief already carries the requirements |
| 3 UX design | end users see a UI; a design system must be chosen | API/CLI/library, or an internal tool on a stock UI kit (owner's yes) |
| 4 architecture | more than one epic will be built in parallel, or the stack is open, or there are cross-repo contracts | one tiny epic on an existing, ratified stack |
| 5 roadmap | always, unless the whole thing is one milestone (then `plan-milestone` PLAN directly) | — |

Also ask **once** for the working mode for the whole chain: **Fast** (each stage drafts with `[ASSUMPTION]` tags, the owner corrects in review; fast, shallower) or **Coaching** (each stage walks the decisions; slower, owner-owned). It may differ per stage; the owner can switch at any gate. Pass the choice to each stage skill as its starting answer so it does not ask again.
Record the plan and mode in `pipeline.md`.

## 2. Running a stage

For each stage in the plan, in order:

1. **Announce** in one line: stage, inputs it will read, output, mode.
2. **Invoke the stage skill** (`Skill` tool) in this session. These are interactive (coaching, research, picks); never run them as unattended subagents. The stage skill ends with its own review (cold read by `blind-spot-reviewer`) and writes `status: final`.
3. **Handoff check** (below) on the new document against what feeds it.
4. **Gate:** show the owner the one-paragraph result, the check's verdict, and the open items that survive, then ask: **approve and go on / change this stage / go back**. Only an explicit approve moves on. Update `pipeline.md`; commit in `.plans`.

Independent research can overlap: when stages 3 and 4 are both in the plan, their **research subagents may be launched together** right after the PRD gate (they share the PRD as input), then the two coaching conversations run one after the other. Do not run two coaching conversations at once.

### Handoff checks (cheap, run before each gate; a subagent reads only the named files)

| Handoff | Check |
|---|---|
| brief → PRD | every brief scope item is an FR, a non-goal or a deferred item; the brief's core flow became a `UJ-n`; nothing in the PRD contradicts the brief's *out of scope* |
| PRD → UX | every **Core** journey has a flow in EXPERIENCE.md and every FR with a UI surface has a screen; journey ids mirror the PRD verbatim; form-factor matches |
| PRD (+UX) → architecture | every NFR that binds structure is covered by an `AD`, or listed under Deferred with a reason; the UI system in UX Foundation matches the Stack; every capability appears in the FR → architecture map |
| docs → roadmap | M1 covers the Core journeys and proves the riskiest `AD`; every MVP-scope FR is in some milestone; nothing out of scope sneaked in |
| roadmap → PLAN Mn | the milestone's DoD still follows from the PRD after the previous milestone's findings; epics cite FR/UJ/AD ids that exist |

A failed check is shown to the owner with the exact gap; it is not auto-fixed. Fix = Update mode of the owning stage skill.

## 3. Staleness and going back

Going back is normal. When a later stage shows an earlier document is wrong or incomplete:

1. Say what was found and which stage owns it; propose the change; on yes, run that stage skill's **Update** mode (stable ids kept).
2. In `pipeline.md`, mark every downstream document that was derived from the changed one `stale?` (the dependency order is the stage order, restricted to the plan).
3. At the next gate, for each `stale?` document ask: still valid / needs update / redo. Never silently regenerate it; never silently trust it.

Changes after the roadmap exists (a new requirement, a dropped journey) go through the same path and end with a roadmap change proposal (split / merge / reorder / drop), applied only on the owner's yes.

## 3b. The wiki (durable memory)

`.plans` is working planning (untracked); the project wiki (`wiki-init`, `docs/wiki`) is durable knowledge about what **exists**, committed with the code.
Once the repo exists and the architecture is `final` (or the first epic is about to start), **offer** `wiki-init` if the repo has no wiki; never create it unasked. After that, `execute-story` runs `wiki-ingest` at the end of every story, and a shipped milestone updates the wiki's overview. The architecture spine stays the contract in `.plans`; the wiki records what the code proved or changed (`wiki-ingest` links to the `AD-n` ids).

## 4. After stage 5

1. **Plan the first milestone**: ask, then run `plan-milestone` PLAN for M1 (epics + briefs; GitHub sync only if the owner agrees).
2. **Offer RUN**: "start epic E1 through feature-pipeline?" and hand over (`plan-milestone` RUN: the brief, with `Covers / Design / Architecture` ids, goes to `brainstorming`; `ui: yes` epics get the usual `ui-direction` question).
3. When a milestone is done, `plan-milestone` suggests planning the next outlined one; this skill is re-entered at stage 6.
4. `pipeline.md` stays the project's dashboard: STATUS requests ("статус проекта") show it plus `plan-milestone` STATUS for the active milestone.

## State file

`<repo>\.plans\product\pipeline.md`:

```markdown
# Project pipeline: <name>
- repo: <path>   cross-repo: yes/no   main_repo: <backend>
- mode: fast | coaching            # per stage override allowed
- plan: [1, 2, 3, 4, 5]            # skipped stages are listed with the reason
## Stages
| # | Stage | Status | Approved | Doc | Stale? |
|---|-------|--------|----------|-----|--------|
| 1 | brief | final | 2026-10-12 | product/brief.md | no |
## Decisions
- 2026-10-12 — UX skipped: internal API, owner agreed
## Change log
```

Status values: `todo | in-progress | final | skipped | stale?`. It is committed in the nested `.plans` repo (never in the code repo, never pushed unless asked).

## Rules

- **One stage at a time, one gate per stage.** Do not start the next stage's skill before the owner approved the previous one.
- **Recommend, don't decide.** Skipping a stage, the working mode and every approval are the owner's.
- **No document is written here.** All content comes from the stage skills; this skill owns order, state, checks and gates.
- **Research feeds documents only through cited digests** (the shared research protocol); nothing from memory is promoted to fact.
- **Right-size.** A weekend tool should reach the roadmap in a few short stages; a funded product earns the full chain. When in doubt, shorten the stage (Fast path), not skip the gate.
- **A background notification is not an approval.**
