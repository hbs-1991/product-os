---
name: feature-pipeline
description: "Use before any creative or building work — a new feature, a component, added functionality, a behavior change, a non-trivial fix — and whenever the owner says 'let's build X', 'давай сделаем', 'новая фича', 'run the pipeline'. Runs the idea-to-PR chain where fresh agents check each other: brainstorming with the Unknowns Matrix (incl. a blind-spot pass and, for screens, UI mocks) -> write-story (one story with spec context and Work Streams, checked by the implementation advisor) -> execute-story (fresh implementers, then refute-story: story refuter + finding verifier + security reviewer, plus an E2E screen recording for UI) -> PR."
---

# Feature Pipeline

The entry point for turning an idea into a pull request.
No single agent builds a feature alone: every step is checked by a fresh agent that did not do the previous one.
Three stages, each ending with the owner's explicit approval before the next begins:

```text
 idea
  │
  ▼
 1. brainstorming    Unknowns Matrix: known knowns → known unknowns → unknown knowns
  │                  → [screen touched? ask → ui-direction: research → 3 directions
  │                     → 3 mocks (ui-mocker agents) → owner picks]
  │                  → draft → blind-spot pass (blind-spot-reviewer, zero context) → approved design
  ▼   owner approves the design
 2. write-story      decompose → Work Streams
  │                  → one document = story + spec context
  │                  → implementation-advisor: architecture, rules, security — a blocker sends it back
  ▼   owner approves the story
 3. execute-story    local git worktree; fresh implementers — in parallel where streams
  │                  are file-disjoint, otherwise in order → gate
  │                  → refute-story: story-refuter tries to prove it NOT done
  │                    → finding-verifier (zero context) confirms or dismisses every blocker
  │                    → security-reviewer on its surface → ≤2 fix rounds
  │                  → UI work: e2e-recorder clicks through the flow and records a video
  │                  → verify-before-pr → PR
  ▼
 PR
```

Why this order: most wasted work comes from a design that was complete on paper and wrong about something nobody said out loud.
Stage 1 spends its effort exactly there — on what the owner knows but did not say, and on what nobody thought of.

## The agents

This plugin ships these subagents (invoke them as `product-os:<name>`):

| Agent | Stage | Job |
|---|---|---|
| `blind-spot-reviewer` | 1 | sees only the draft design and the repo, never the conversation; finds what nobody considered |
| `ui-mocker` | 1 | turns one design direction into a verified image mock |
| `implementation-advisor` | 2 | pressure-tests the story against the repo's architecture, rules and security before code exists |
| `story-implementer` | 3 | the default implementer when the repo has no specialised one |
| `story-refuter` | 3 | tries to prove the finished change does NOT do what the story says |
| `finding-verifier` | 3 | zero-context check of every blocker against the real code; only confirmed ones get fixed |
| `security-reviewer` | 3 | high-signal hunt for exploitable vulnerabilities in the diff |
| `e2e-recorder` | 3 | clicks through the user flow end to end and returns a screen recording |

**A repo's own agent wins.** If the repository defines `.claude/agents/<name>.md` with the same name (e.g. its own `security-reviewer` that knows its auth model), use that one; the plugin's agent is the generic fallback.

**Entry points.** For a whole new project the entry is `project-pipeline`, which ends by handing epics here. An epic from `plan-milestone` RUN enters at stage 1 with its brief.

## 0. Size gate

Decide first whether the pipeline is warranted.

**Skip it** — do the work directly — for trivial mechanical edits with no design decision: a typo, a comment, a rename with no contract change, a one-line config value the owner dictated.
Say "this is small enough to do directly" and do it.

**Run it** for anything else: a feature, a behavior change, a new endpoint/job/screen, a cross-module or cross-repo change, anything touching money, auth, tenancy or production data.
When in doubt, run it — stage 1 can be short for a small change, but it still happens.

A **bug** is not a feature: start with `root-cause-debugging` (reproduce first).
If the fix turns out to need a design decision, come back here with what the reproduction showed.

## 1. Stage 1 — brainstorming

Invoke the `brainstorming` skill.
It ends with a design the owner approved, held in the conversation.
An epic brief from `plan-milestone` (with `Covers / Design / Architecture` ids) can arrive as the starting input.

**UI direction (frontend).** If the work adds a screen or noticeably changes one, always ask the owner whether to run the design step — never assume either answer.
On "yes", invoke `ui-direction` inside brainstorming, before its §5 draft: research → taste filter → three directions → three mocks → the owner's pick.
The chosen direction is part of the approved design; its record folder and **Locked visual decisions** travel into the story and are checked again in stage 3.

## 2. Stage 2 — write-story

Invoke the `write-story` skill.
It has `implementation-advisor` review the draft and ends with an approved story saved at `<repo>\.plans\stories\YYYY-MM-DD-<slug>.md`. `<repo>` is the main checkout (`git rev-parse --path-format=absolute --git-common-dir` minus `\.git`), never a worktree. `.plans` is its own nested git repo, excluded from the code repo via `.git/info/exclude`: commit there only after the owner approves, never to the code repo, never push unless asked. A story may belong to an epic (optional header line `Epic: <id>, <milestone slug>`).

## 3. Stage 3 — execute-story

Invoke the `execute-story` skill with the story path.
It runs the story locally in its own git worktree — in parallel where the Work Streams are file-disjoint — and ends with a PR into the repo's integration branch.
Its review step is `refute-story`, a step inside this stage: no owner approval before it, only the findings it cannot settle go to the owner.

## Rules across all stages

- **Owner approval between stages** is explicit ("yes", "approve", a choice picked) — never inferred from silence or from a background-task notification.
- **Approval covers only what the question asked.** A "yes" to "approve the design?" approves the design, not the story written from it.
- **Repo rules win.** `CLAUDE.md` and `.claude/rules/*` of the repo override this pipeline wherever they are stricter (a mandatory reviewer, a PR skill, a protected branch, a required PR target).
- **Chat language** follows the owner and the repo's response rules; every written artifact (story, code, PR, ADR) is in English unless the repo says otherwise.
- **Going back is normal.** If stage 2 or 3 uncovers a wrong assumption, return to the stage that owns it instead of patching around it — and tell the owner.
- **Cross-repo work** (backend + a frontend): one story per repo, the backend first when the frontend depends on its contract.
- **Wiki.** If `.claude/wiki.conf` exists, finishing work includes `wiki-ingest` (owned by `execute-story` / `verify-before-pr`).
- **Fresh eyes.** A reviewer never receives the author's conversation, opinion or "the gate is green" — only the artifact and the handoff it needs.
