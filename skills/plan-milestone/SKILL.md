---
name: plan-milestone
description: "Use to plan a project milestone and split it into epics that can each be run through feature-pipeline. Triggers: 'create a milestone', 'plan milestone', 'break this into epics', 'роадмап', 'создай майлстоун', 'разбей на эпики', 'следующий эпик', 'run epic E2'. Also ROADMAP mode for a new project ('roadmap', 'план проекта', 'несколько майлстоунов'): first outline several milestones, then decompose one milestone at a time (roadmap -> milestones -> epics -> stories). Three modes: PLAN (goal -> milestone document with ordered, dependency-aware epics, each carrying a ready brief for brainstorming), RUN (pick the next unblocked epic, hand its brief to feature-pipeline, update status when done) and STATUS ('статус майлстоуна', 'progress'): a milestone -> epics -> stories report read live from GitHub. Optionally mirrors the plan to GitHub (milestone + epic issues + sub-issues) after the owner agrees."
---

# Plan Milestone — milestone → epics → feature-pipeline

A milestone is an **outcome the owner can verify**, not a pile of tasks.
An epic is **one pass through `feature-pipeline`**: one design, one story, one PR (or one backend+frontend pair).
This skill sits *above* the pipeline: it decides what to build and in what order; the pipeline decides how.

```text
 goal ──► PLAN ──► milestone file (epics E1..En, deps, briefs)
                        │  owner approves
                        ▼
                  RUN: next unblocked epic ──► feature-pipeline (brief as input)
                        ▲                              │
                        └──── status update ◄──────────┘ PR / issues
```

The milestone file lives next to the code, in the repo's `.plans` folder:

```text
<repo>\.plans\milestones\<slug>.md      milestone + epics (the canonical file)
<repo>\.plans\stories\...               the repo's own stories (write-story)
```

- `<repo>` is the **main checkout** (`git rev-parse --path-format=absolute --git-common-dir`, minus `\.git`), never a worktree.
- `.plans` is its own nested git repo, excluded from the code repo (`.git/info/exclude`, local). First use: `git init` there, add the exclude line, tell the owner in one line. Never track plans in the code repo.
- After the owner approves the plan, and after each status change, commit inside `.plans` (`git -C <repo>\.plans add -A && git commit`); never push unless the owner asks.

**Cross-repo milestone.** The canonical file lives in the **backend** repo's `.plans\milestones\` (backend is the main repo).
Every other repo involved gets a **link stub** at `<other repo>\.plans\milestones\<slug>.link.md` instead of a copy, because a copy drifts:

```markdown
# Milestone <slug> (link)
Canonical: <backend repo>\.plans\milestones\<slug>.md
GitHub milestone: <owner/backend-repo>#<number>   (if synced)
Epics touching this repo: E3, E5
```

Keep the stub's epic list in sync whenever the canonical epics change; frontend stories carry `Epic: E3, <slug>` and are linked to the backend epic as described under GitHub sync.
Chat language follows the owner; the file itself is in English.

## Four levels, elaborated just in time

```text
roadmap      the project: ordered milestones M1..Mn            .plans\roadmap.md
 └─ milestone   a verifiable outcome                           .plans\milestones\M1-<slug>.md
     └─ epic       one feature-pipeline run                    inside the milestone file (M1.E2)
         └─ story     one approved story (+ issues)            .plans\stories\...
```

**Progressive elaboration is the rule.** Each level is detailed only when it is next:
the roadmap outlines *all* milestones, but epics are written for **one milestone at a time** (the next one), and stories only when an epic is run.
Detailing M3's epics while M1 is unbuilt produces fiction: M1 will change what M3 needs.
A milestone therefore has a planning state: `outlined` (outcome and rough DoD only) → `planned` (epics and briefs written, owner approved) → `in-progress` → `done`.

## Mode detection

- Owner describes a new project / asks for several milestones / "roadmap" / "план проекта" → **ROADMAP**.
- Owner says "распиши майлстоун M2" / "plan M2" → **PLAN** for that one milestone (it must be `outlined` in the roadmap, or there is no roadmap and this is a standalone milestone).
- Owner gives a single goal with no roadmap / "plan milestone" / "создай майлстоун" → **PLAN**.
- Owner says "next epic", "run E2", "что дальше по майлстоуну" → **RUN**.
- Owner asks "статус / progress / как идёт майлстоун" → **STATUS**.
- Owner wants to change the scope of an existing milestone → **PLAN (revise)**: edit the file, never recreate it.

## ROADMAP (new project, several milestones)

Writes `<repo>\.plans\roadmap.md` from `roadmap-template.md`.
No epics, no stories here: this level answers only "what outcomes, in what order".

0. **Foundation check (the discovery chain).** Look in `<repo>\.plans\product\` for `brief.md`, `prd.md`, `ux\DESIGN.md` + `EXPERIENCE.md`, `architecture.md`.
   - Present ones are **inputs**: read them (extract by subagent if long) and inherit what they settle; do not re-ask it.
   - Missing ones: say which, and offer the matching skill (`create-product-brief` → `create-prd` → `create-ux-design` → `create-architecture`). Never start one unasked. The owner may proceed without them; then the gap is recorded as a risk in the roadmap (e.g. "no architecture: M1 must also decide the stack").
   - Size gate: a small tool needs at most a brief; UX is for user-facing products; architecture matters once more than one epic will be built in parallel.
1. **Ground yourself** as in PLAN §1. For a brand-new project with no repo yet, ask once where the project lives, then use `<that dir>\.plans` (git-init the code dir only if the owner says so).
2. **Frame the project (max 4 questions, one message):** the project's end state (what exists when it is "done"), the first usable release, hard constraints (deadline, stack, money/auth/prod data, repos involved), what is explicitly out.
3. **Cut milestones** by *verifiable outcomes that someone can demo*, not by phases or layers ("backend first", "UI later" are not milestones). Rules:
   - **M1 is the thinnest end-to-end slice** that proves the riskiest assumption (walking skeleton), not "set up the project". With a PRD: M1 delivers the **Core-weight journey(s)** end to end; with an architecture: M1 also proves the riskiest `AD` (the one most likely to be wrong).
   - **Cut by journeys, not by features.** With a PRD, every milestone outcome is one or more `UJ-n` working end to end; **Core** journeys first, **Supporting** next, **Edge** last or out. Each milestone row records `Covers: UJ-1, FR-1..FR-6`.
   - Each milestone is demoable on its own and leaves the system working.
   - 3–7 milestones; more means the roadmap is detailing too far ahead, so merge the tail into one `later` milestone.
   - Per milestone: id, name, outcome (1 sentence), rough DoD (2–4 bullets), `depends_on`, main risk, rough size.
4. **Estimate coarsely.** Use the rules in *Estimating duration* (AI agents write the code) but give each milestone a **range of days**, not a number, and state what drives it. The tail milestones are wide ranges on purpose; they get re-estimated when planned.
5. **Self-check:** (with a PRD) every `Core` journey and every MVP-scope FR is covered by some milestone, and nothing out of MVP scope sneaks in; M1 has no dependencies; every project end-state bullet is covered by some milestone; nothing in the roadmap is an epic (if you can name a PR, it is too small); no milestone lacks an outcome the owner can verify.
6. **Owner approval:** show the milestone table (id / name / outcome / depends / range), ask: approve / change cut / change order. Write the file only after an explicit yes; every milestone starts as `outlined`.
7. **Then offer the next step, don't start it:** "распишем M1 на эпики?" → PLAN for M1.

GitHub sync for a roadmap (only with the owner's yes): create **all** milestones now (they are cheap: title + outcome in the description, the milestone number goes into `roadmap.md`), but create **epic issues only when that milestone is planned**.

Cross-repo project: `roadmap.md` lives in the backend repo; other repos get a stub `roadmap.link.md` (same format as the milestone link stub).

Changing the roadmap later (split, merge, reorder, drop a milestone) is a proposal to the owner, applied only on yes, and logged in the roadmap's Change log.

## PLAN

PLAN works on **one** milestone.
With a roadmap, it takes an `outlined` milestone, copies its outcome / DoD / risks as the starting point (the owner may revise them: the roadmap is a plan, this is the contact with reality), writes `milestones\M<n>-<slug>.md`, and flips the roadmap row to `planned`.
Epic ids are local to the milestone (`E1..En`); across milestones refer to them as `M2.E3`, and stories carry `Epic: M2.E3, <slug>`.
Before planning M(n), read the finished milestones' epics' **Pipeline log** and *actual* times: fold what was learned (changed contracts, debt, real velocity) into the new epics and estimates.
Without a roadmap, the file is simply `milestones\<slug>.md` and ids are `E1..En`.

### 1. Ground yourself (read, don't ask)

Before any question, read what exists: `README`, `CLAUDE.md`, `.claude/rules/*`, open issues / TODOs, existing `<repo>\.plans\milestones\` and `stories\`, recent `git log`.
Questions the code can answer are not questions for the owner.

### 2. Frame the milestone (max 3 questions, one message)

Ask only what you cannot find out:

1. **Outcome** — what is true when the milestone is done, observable by someone other than the author?
2. **Boundary** — what is explicitly *not* in this milestone?
3. **Constraints** — deadline, cross-repo contracts, money/auth/prod data, things that must not break.

If the owner already gave these, skip.
Restate them as **Definition of Done** (3–7 verifiable bullets).

### 3. Slice into epics

Slice by **vertical, user-visible value**, not by layer ("DB", "API", "UI" are not epics).
Each epic must pass the **pipeline test**:

| Test | Fails when |
|---|---|
| One-sentence outcome | It needs "and" twice |
| Fits one story | More than ~3 Work Streams, or touches >1 unrelated module |
| Independently verifiable | Can only be checked after another epic ships |
| Has a size | `S` / `M` / `L` per **Estimating duration** below — **split every L** |
| Worth the pipeline | Trivial edits (typo, config value) are not epics: fold into a neighbour or drop |

Then add:

- **Dependencies** (`depends_on: [E1]`) — only real ones: a contract, data, or code that must exist first. Prefer reshaping epics to remove a dependency over keeping it.
- **Order** — de-risk first (the epic with the biggest unknown goes early), then value, then polish.
- **Cross-repo** — backend and frontend halves are separate epics (backend first), linked by `depends_on`.
- **UI flag** — `ui: yes` if the epic adds or noticeably changes a screen, so the pipeline asks about `ui-direction`.
- **Risks / unknowns** per epic — seeds for the brainstorming Unknowns Matrix.

### Estimating duration — the code is written by AI agents, not people

**Never estimate in human developer-days.**
The code is written by AI agents (local subagents working in parallel worktrees), so typing and coding time is close to zero.
Human-team estimates ("3–4 weeks") overshoot by roughly an order of magnitude; do not use them, not even as an upper bound.

Duration is made of what is still slow with agents:

| Component | What drives it |
|---|---|
| Owner decisions | brainstorming Q&A, design / story / route approvals, UI direction pick; this is waiting for the owner, so it is often the largest part |
| Agent execution | story run (minutes to a few hours); independent Work Streams run **in parallel**, same-lane stories queue |
| Review loop | `refute-story` + up to 2 fix rounds, e2e-recorder for UI epics |
| Gates and CI | test / build / deploy time of the repo, PR merge wait |
| External | third-party APIs, keys, access, data, another team |

Size an epic by its **pipeline weight**, not by lines of code:

- `S` — one story, one Work Stream, no new contract, no UI decision → about **half a day** (a few hours of agent work + approvals).
- `M` — one story with 2–3 parallel Work Streams, or a new contract, or a UI epic → about **1 day**.
- `L` — more than 3 Work Streams, a sequential chain inside one story, a risky unknown, or heavy external dependency → **split it**, or if it truly cannot be split, mark it `L` and say why.

Milestone duration = the **critical path** through `depends_on` (epics on parallel branches overlap, they do not add up), plus owner-wait buffer, plus external waits.
Report it as a range with the assumption stated, e.g. "~4–5 days, assuming same-day owner approvals; +1 day per day the owner is away".
A milestone that a team would call "3–4 weeks" usually lands at a few days here; if your estimate comes out in weeks, re-check whether an external wait or a missing split is hiding in it.

These numbers are defaults.
Calibrate from the **Pipeline log**: when epics finish, record the actual elapsed time next to the estimate, and in later PLAN runs on the same project use the observed hours per `S`/`M` instead of the defaults.

### 4. Write each epic's brief

The brief is what makes the epic runnable: it is handed to `brainstorming` as pre-filled *known knowns*, so stage 1 does not start from zero.

```markdown
### E2 — <short outcome title>
- status: todo            # todo | in-design | in-progress | in-review | done | dropped
- size: M                 # pipeline weight, see "Estimating duration"
- estimate: ~1 day        # agent time + approvals, not human dev-days
- depends_on: [E1]
- ui: no
- repo: <repo or repos>

**Outcome.** One sentence, user-visible.

**Brief for brainstorming.**
- Known: facts, existing code/modules involved, decisions already made.
- Inputs (when the discovery chain exists): `Covers: FR-3, FR-4 (UJ-2, weight Core)` · `Design: ux\EXPERIENCE.md#<flow>, DESIGN.md tokens` · `Architecture: AD-2, AD-5 (+ Inherited)` · research digests. Cite ids, not prose; the pipeline reads the originals.
- Wanted: behaviour in the owner's words.
- Out of scope: what this epic must not touch.
- Open questions / risks: for the Unknowns Matrix.

**Done when.** 2–5 checkable bullets (they seed the story's Acceptance Criteria). With a PRD, take them from the covered FRs' *testable consequences* instead of inventing new ones.

**Pipeline log.** (filled by RUN: story path, PR link, date)
```

### 5. Self-check before showing the owner

Fix silently, then present:

- Every DoD bullet is covered by at least one epic; an epic that covers no DoD bullet is scope creep → move it to **Parking lot**.
- No dependency cycles; the first epic has no dependencies.
- No `L` epics; no epic without "Done when".
- Show the dependency graph as a compact line (`E1 → E2, E3 → E4`) and the **critical-path duration** with its stated assumptions (not a sum of sizes, not human-days).

### 6. Owner approval

Present the milestone in chat (title, DoD, epic table: id / title / size / deps), not the whole file.
Offer exactly: approve / change epics / change order or scope.
Only after an explicit approval write the file with `status: approved`.
Silence is not approval.

File template: `template.md` next to this skill.

## RUN

1. **Read the milestone file** (with a roadmap: the first milestone that is `planned`/`in-progress` and whose dependencies are `done`; if the next milestone is only `outlined`, offer to PLAN it first instead of running anything).
2. **Pick the epic.** The first `todo` epic whose `depends_on` are all `done`. If the owner named one whose dependencies are not done, say so and offer the unblocked ones; do not run it silently.
3. **Show the epic** (outcome, brief, done-when) and ask whether to run it now through `feature-pipeline`. Wait for an explicit yes.
4. **Hand off.** Set `status: in-design`, then invoke `feature-pipeline` with the brief as the starting input: give it to `brainstorming` as known knowns / out of scope / open questions, and state that the size gate's answer is "run it".
   - `ui: yes` → feature-pipeline asks about `ui-direction` as usual (never assumed).
   - All of the pipeline's owner-approval gates still apply; this skill adds none and removes none.
5. **Track.** If GitHub sync is on, keep the epic issue's Stories checklist current as described above. Update `status` at each stage boundary: `in-design` → `in-progress` (story approved, executing) → `in-review` (PR open) → `done` (PR merged or the owner confirms). Append the story path and PR link to the epic's **Pipeline log** and refresh the overview table.
6. **Replan on contact with reality.** If brainstorming shows the epic is wrong-sized or mis-ordered, stop and propose the change (split / merge / reorder / drop) to the owner; edit the file only after approval and note it in **Change log**.
7. When the last epic is `done`, walk the DoD bullets with the owner; the milestone is `done` only when they agree each one is verifiably true. With a roadmap, set the row `done`, record the milestone's actual duration next to its estimate, and **suggest planning the next `outlined` milestone** (do not start it).

## GitHub sync (optional, three levels)

Mirrors the file to GitHub so progress is visible without opening it.
**Ask first** (in the owner's language: "mirror this plan to GitHub?"): creating milestones and issues is visible to others.
Never run it before the plan is approved.

```text
milestone            GitHub milestone, in the MAIN repo
  └─ epic            issue, label `epic`, in the milestone, body = brief
       └─ story      a story file in `.plans\stories` and its PR, listed in the epic issue's Stories checklist
                     (a GitHub issue per story only if the repo files them, linked as a SUB-ISSUE of the epic)
```

**Main repo.** Backend is always the main repo for cross-repo epics: the milestone and all epic issues live there.
Frontend stories are created in the frontend repo and linked to the backend epic as cross-repo sub-issues.
Single-repo milestones live in that repo.

**The one rule that keeps repo automation safe:** an epic issue carries the label `epic` and **no label that any automation of the repo uses to pick up work** (for example a `story:ready`-style trigger; check `gh label list` and the repo's `CLAUDE.md`/rules).
An epic is a tracker, not a story, and its brief is not in a story's shape.
Story issues, if any exist, are **not** added to the milestone: only epics are, so the milestone bar counts epics.

### Creating (after approval and "yes")

```bash
gh label list --repo {owner}/{repo} --search epic          # create `epic` if missing, ask first
gh api repos/{owner}/{repo}/milestones -f title="<name>" -f description="<outcome>"   # -> milestone number
gh issue create --repo {owner}/{repo} --title "E2 — <title>" --label epic \
  --milestone "<name>" --body-file <brief.md>               # one per epic
```

Dependencies between epics: `gh api --method POST repos/{owner}/{repo}/issues/<N>/dependencies/blocked_by -F issue_id=<blocker id>` (the issue **id**, not the number).
Write every milestone number and epic issue number back into the file (`github: #12` in each epic, `milestone:` in the header).
Show the owner the list of what will be created before running anything.

### Tracking stories under the epic (RUN)

Stories are local files plus PRs, so the epic issue carries a **Stories checklist** in its body, kept current by RUN (`gh issue edit <N> --body-file ...`):

```markdown
## Stories
- [x] <story title> (`M2.E3`) — PR #41, merged 2026-10-14
- [ ] <story title> — PR #44, in review
```

Add a line when a story is approved, link its PR when opened, tick it when merged. Record the same in the epic's **Pipeline log** in the file.
If the repo also files a GitHub issue per story (its own process), link each as a sub-issue of the epic:

```bash
ID=$(gh api repos/{owner}/{story-repo}/issues/<story N> -q .id)
gh api --method POST repos/{owner}/{main-repo}/issues/<epic N>/sub_issues -F sub_issue_id=$ID
```

If that call fails (sub-issues unavailable, cross-owner repo), fall back to a `Part of {owner}/{main-repo}#<epic N>` line at the end of the story issue's body and tell the owner.
Do not put `Closes #<epic>` in a story body or PR: the first merged PR would close the epic while other stories are still running.
Do not touch labels or bodies of story issues that automation owns.

### Closing

- **Story**: done when its PR is merged (a story issue, if any, closes with that PR).
- **Epic**: closed by RUN, never automatically: when every story in its checklist is merged (and every sub-issue, if any, is closed) **and** the epic's *Done when* is confirmed (the integration PR merged, or the owner says so). Set `status: done` in the file in the same step.
- **Milestone**: closed after the DoD walk with the owner (RUN step 7).

## STATUS

Read-only report, always from live GitHub data when synced, from the files otherwise.
With a roadmap, report all four levels, one line each, expanding only the milestone in progress:

```text
Roadmap: <project>   — 1/4 milestones done
 ✔ M1 <name>                         done
 ▶ M2 <name>  (planned, 2/5 epics)   ~3–4 days left
     ✔ M2.E1 ...   ▶ M2.E2 [3/5 stories] ...   ⏸ M2.E3 blocked by M2.E2
 ○ M3 <name>  (outlined)             not yet decomposed
 ○ M4 <name>  (outlined)
```

Outlined milestones are never shown with epics (they have none): that is not a gap, it is the plan.
Also flag: a milestone `in-progress` whose predecessor is not `done` (without an owner decision), and a milestone that has sat `outlined` while its successor is already being built.

Single-milestone detail:

```bash
gh api repos/{owner}/{repo}/milestones/<n> -q '{title,open_issues,closed_issues,state}'
gh issue list --repo {owner}/{repo} --milestone "<name>" --label epic --state all --json number,title,state,labels
gh issue view <epic N> --repo {owner}/{repo} --json body -q .body          # the Stories checklist: ticked / total
gh api repos/{owner}/{repo}/issues/<epic N> -q '.sub_issues_summary'     # only if story issues are linked: total / completed / percent_completed
gh api repos/{owner}/{repo}/issues/<epic N>/sub_issues -q '.[] | {number,title,state,repository_url}'
```

(Progress comes from the Stories checklist; `sub_issues_summary` is what GitHub shows as the epic's progress bar when story issues are linked. If that field is missing on this account, count the sub-issues list.)

Report as a tree, one line per level:

```text
M: <name>  — 2/5 epics done            (DoD: 1/4 verified)
 ✔ E1 <title>                           done
 ▶ E2 <title>   [3/5 stories]  in review: PR #44, #45
 ⏸ E3 <title>   blocked by E2
 ○ E4 <title>   todo
```

Flag drift instead of silently fixing it: an epic `done` in the file with unticked stories or open sub-issues, a story issue with no epic parent, an epic carrying a label that repo automation picks up (advise removal, never auto-remove), a file status that disagrees with GitHub.
Ask before reconciling the file with GitHub.

## Rules

- **One epic per pipeline run.** Never batch several epics into one story to save time.
- **Do not design here.** Briefs capture what is known; solution design belongs to `brainstorming`. If you catch yourself choosing libraries or schemas, put it under Open questions instead.
- **Do not write stories or code here.** This skill ends at a brief.
- **Repo rules win.** `CLAUDE.md` / `.claude/rules/*` override this skill.
- **Honest status.** Never mark `done` without a merged PR or the owner's word.
- **The file is the source of truth.** Chat summaries are views; edits go to the file.

## Common mistakes

| Mistake | Fix |
|---|---|
| Epics sliced by layer ("backend", "frontend") | Slice vertically; split by repo only for contract-first cross-repo work |
| Twelve epics of size S | Merge neighbours; an epic is a pipeline run, not a ticket |
| "3–4 weeks" for a milestone | Human-team thinking. Re-estimate on the critical path with agent execution times |
| Every epic depends on the previous one | Reshape for parallelism; only real contracts are dependencies |
| Brief says "implement X" with no unknowns | Add risks; if there are truly none, the epic may be too trivial for the pipeline |
| Milestone with no "out of scope" | Ask for the boundary; use the Parking lot |
