---
name: write-story
description: "Stage 2 of feature-pipeline: turns an approved brainstorming design into ONE story document that carries its spec context — Agent:, numbered Acceptance Criteria, column-zero Tasks, Locked Decisions and Work Streams that say what can run in parallel — asks the owner whether it runs locally in sequence or in parallel across file-disjoint streams, and has the implementation-advisor agent check it against the repo's architecture, rules and security before the owner approves. Use after brainstorming approved a design, or when the owner asks to 'write the story', 'turn this into a story', 'оформи историю'."
---

# Write Story — one document, story plus spec

Turn the design approved in `brainstorming` into a single document an executor can implement without asking anything.

There is no separate spec and no separate plan.
The story **is** the spec: it carries the context, the locked decisions and the task list, in a fixed shape a fresh implementer agent can follow and a reviewer can check against.

Core principle: **nothing downstream fills a gap.**
Whoever executes the story — a fresh subagent that never saw this conversation — cannot ask the owner a question.
Every gap is closed here, with the owner still in the conversation.
Chat with the owner in their language; the story file itself is written in English.

## Inputs

- The approved design from `brainstorming`, still in the conversation (Locked Decisions, Open Questions, triaged blind spots).
- If the design is not in the conversation, stop and run `brainstorming` first.
- If the story belongs to a milestone epic (`plan-milestone`) and a PRD exists, also read the covered FRs and their testable consequences.

## 1. Learn the repository's shape

```bash
ls .claude/agents/ 2>/dev/null   # repo-specific implementers and reviewers (they win over the plugin's)
ls .claude/skills/ 2>/dev/null   # a create-pr skill? a test-selection skill?
cat CLAUDE.md; ls .claude/rules/ 2>/dev/null
ls .github/workflows/ 2>/dev/null   # what CI runs = the real gate
ls .claude/wiki.conf 2>/dev/null    # the optional project wiki (wiki-init)
```

From these, note:

- the **implementer** for `Agent:` — a repo agent that fits the work (e.g. `frontend-dev`, `backend-engineer`), else `product-os:story-implementer`;
- the **reviewers** — the repo's own `implementation-advisor`, `story-refuter`, `security-reviewer` if it has them, else the plugin's;
- the **gate** — the exact lint / type-check / test / build commands the rules and CI name for "done".

Always re-check with `ls`; never assume which agents a repo has.
Post-code review is not a task you write into the story: `execute-story` runs `refute-story`.

## 2. Decompose into tasks

Turn the design into an ordered task list.
For each task, close the questions the executor cannot ask:

- **Which file(s)** does it create, edit or delete? A task without a path is a guess waiting to happen.
- **Which acceptance criterion** does it serve? A task serving none is scope creep; a criterion served by no task is work nobody will do.
- **What must come before it?** A code dependency (it imports a symbol another task creates) or a delete-after-replace order.
- **Is it a barrier?** Integration, "retire the old flow", docs/README updates, the final gate — anything touching several streams' files.

Every repo rule still applies: a test per change, the module README updated on a contract change, an ADR for a new decision — whatever the repo's rules require.
Those are tasks too — write them down.
If `.claude/wiki.conf` exists, the last task is "run `wiki-ingest`".

## 3. Partition into Work Streams

Group the tasks into **streams**:

- Two tasks go in the **same** stream if they share any file OR one depends on the other.
- Streams with **fully disjoint** file sets may run in parallel.
- Barrier tasks form the **last** stream, which runs after all the others.
- A shared wiring file, README, index or lockfile that several streams touch belongs to the barrier stream.

Then state the verdict plainly: **parallel OK** (≥2 disjoint streams) or **sequential** (one stream).
Be honest — a nine-task story is usually two or three streams, often one.
Parallel execution that turns out to share a file clobbers work; a wrong "sequential" only costs time.

## 4. Ask the owner how it will run

Execution is always local, in a git worktree.
The choice is how, and it shapes the story (where an owner checkpoint may sit), so ask it before drafting, as its own `AskUserQuestion`:

| Route | Available when | Effect on the story |
|---|---|---|
| **Local — sequential** | always | one implementer works the tasks in order; owner checkpoints allowed anywhere |
| **Local — parallel** | §3 found ≥2 file-disjoint streams | one implementer per stream concurrently (`parallel-story-execution`), then the barrier stream; checkpoints only before the fan-out or in the barrier |

Put your recommendation first, marked "(Recommended)", with the reason in its description.
A recommendation is not a choice: the owner picks.
If §3 found a single stream, skip the question and say so in one line.
If the owner already named the route in their own words earlier, do not ask again — state which one you use.
A "yes" to a route you proposed is not the owner naming it, unless the question offered the options.

Record the answer as the first line of the saved story, only after the owner answered:

```text
<!-- route: local-sequential | local-parallel — chosen by the owner, YYYY-MM-DD -->
```

## 5. Draft the body

Use this shape:

```markdown
Agent: <one subagent name, no @, no spaces — a repo agent or product-os:story-implementer>
Epic: <id>, <milestone slug>      <!-- optional; only for a story from plan-milestone, e.g. "Epic: M2.E3, billing" -->

## Story

As a <role>, I want <capability>, so that <outcome>.

## Context

- Where this lives: <modules, directories, key files>
- Current behavior: <what happens today, verbatim error text if any>
- Constraints: <what must not break — including what the blind-spot pass surfaced and the design addressed>
- Covers: <FR-/UJ-/AD- ids, only if an epic and PRD/architecture exist>

## Locked Decisions

- <hard-to-reverse choice> — <one-line rationale>
- <UI work with a ui-direction record: each Locked visual decision copied verbatim, prefixed "Visual:">

## Acceptance Criteria

1. **Given** <state>, **when** <action>, **then** <observable outcome>.
2. <...>

## Tasks / Subtasks

- [ ] Task 1 — <what changes, in which file> (AC: #1)
  - [ ] <a step inside that task, if it helps>
- [ ] Task 2 — <...> (AC: #2, #3)

## Work Streams

Verdict: parallel OK | sequential

| Stream | Tasks | Files (exclusive to this stream) | After |
|---|---|---|---|
| A — <name> | 1, 2 | `src/x/...` | — |
| B — <name> | 3 | `src/y/...` | — |
| Barrier | 4, 5 | README, docs, gate | A, B |

## User Flow                    <!-- UI work only: what e2e-recorder walks and films -->

1. Open `<url path>` as <which user / seed state>.
2. <click / type / expect> — proves AC #<n>.

## Dev Notes

<what the executor must know that the code does not say: the pattern to follow, a file already too large, a migration that must run first, the tacit context the owner gave during brainstorming>

### References

- `<docs/adr/nnnn-slug.md>` — <why it matters here>
- `<src/module/README.md>` — <what it establishes>
- `<records/date-topic-ui-direction/>` — the chosen direction and its canonical mock (UI work only)

## Verification

<the repo's gate commands that must pass — lint / type-check / test / build>

## Out of scope

- <what this deliberately does not do — including blind spots triaged "out of scope", with the reason>
```

### Shape rules

Reviewers grade the change against this shape; an implementer stumbles on any ambiguity in it.

| Part | Exact requirement |
|---|---|
| `Agent:` | its own line at column zero, one token, no `@`, an agent that exists (repo or plugin) |
| `Epic:` | optional; `<id>, <milestone slug>`; the covered `FR-/UJ-` and `AD-` ids go in Context |
| `## Acceptance Criteria` | a **numbered** list (checkboxes here read as empty), each criterion observable |
| `## Tasks / Subtasks` | tasks are checkboxes at **column zero** (indented ones are subtasks) |
| Tasks live **once** | only under `## Tasks / Subtasks`. `## Work Streams` refers to task **numbers** and file sets — it never re-lists tasks as checkboxes |
| `## User Flow` | only when the change has a user-facing flow; a numbered list, each step names the criterion it proves, no checkboxes |

### Epic stories

When the story comes from a milestone epic and a PRD exists, derive the Acceptance Criteria from the covered FRs' testable consequences rather than inventing new ones.
In a cross-repo milestone, the frontend story goes to the **frontend** repo's `.plans\stories\`.

### Where the Unknowns Matrix goes

The matrix is process, not content — do not paste it as its own section.
Fold its outcomes into the body:

| Brainstorming outcome | Lands in |
|---|---|
| known facts, tacit context from the owner | `## Context`, `## Dev Notes` |
| blind spot → **addressed** | the task that addresses it, plus a `Constraints:` line |
| blind spot → **out of scope** | `## Out of scope`, with the reason |
| hard-to-reverse choices | `## Locked Decisions` |
| **open question** | see §6 |

## 6. No open questions in the body

Resolve every remaining open question with the owner now — take the recommended default if they agree.
An item may stay open only as an explicit checkpoint inside a task: "Task 4 — before writing X, confirm with the owner whether …".
The executor then stops there and asks.
In a parallel story, a checkpoint belongs before the fan-out or in the barrier stream, never in the middle of a concurrent stream, where one stream stopping to ask leaves the others running on a guess.

## 7. Self-check

Before anyone else sees it:

- Every acceptance criterion is named by at least one task; every task names at least one criterion.
- Every task names a file or a clearly identified surface.
- The `Agent:` value exists.
- Work Streams: file sets really are disjoint; every task appears in exactly one stream; barriers run last.
- Every claim about the codebase comes from a file actually read; identifiers, paths and error texts are verbatim.
- Standalone wording — no "as discussed above", no revision language, no "TBD".
- Verification lists commands that really exist in this repo.
- Nothing contradicts the chosen route (no mid-stream checkpoint in a parallel story).

## 8. Implementation advisor — before the owner sees it

Launch the **`implementation-advisor`** agent on the draft story (the repo's own one if `.claude/agents/implementation-advisor.md` exists, else `product-os:implementation-advisor`).
Its prompt is the repository path, the story text and the chosen route — not this conversation; it must judge the story, not the reasoning that produced it.
It checks the story against the repo's architecture, rules and security and returns APPROVE / APPROVE-WITH-CHANGES / REJECT.

- **Any 🔴 blocker → the story goes back:** fix it (return to `brainstorming` if the blocker is a design flaw, not a wording one), then run the advisor **again** on the revised story.
- 🟠 risks and open questions → bring them to the owner.
- If you disagree with the advice, show the owner the disagreement — never override it silently.

Only a story with no open blocker goes to §9.

## 9. Save and get approval

Save the story in the `.plans` folder next to the code, **never tracked by the code repo**:

```text
<repo>\.plans\stories\YYYY-MM-DD-<slug>.md
```

`<repo>` is the **main checkout** (`git rev-parse --path-format=absolute --git-common-dir`, minus `\.git`), never a worktree: a worktree does not contain `.plans`.
First use in a repo: `git init` inside `<repo>\.plans` and add `.plans/` to the code repo's `.git/info/exclude`; tell the owner in one line what you did.
The story is never committed to the code repo — a tracked copy drifts from the code.
After the owner approves it, commit it to the nested `.plans` repo only (`git -C <repo>\.plans add -A`, then commit); never push unless asked.
The durable record is the PR body and the ADR/wiki.

Show the owner the rendered story, the Work Streams verdict, which agent will implement it, the advisor's verdict (and what changed because of it), and the route.
Then ask for approval with `AskUserQuestion`, options naming the route:

- **Approve — run it <route>**
- **Approve, but change the route** — back to §4, re-check §6 and §7, re-run the advisor if tasks changed
- **Needs changes** — say what, revise, re-run the advisor if tasks changed, and ask again

**Do not start implementation until the owner approves.**
A plain "yes" to a question that did not name the route approves the story only, not the route.

Then invoke `execute-story` with the story path and the route.

## Common mistakes

| Mistake | Fix |
|---|---|
| Tasks listed per stream as checkboxes under `## Work Streams` | Tasks live once under `## Tasks / Subtasks`; streams reference numbers |
| "Parallel OK" when two streams both touch a README or a shared wiring file | That file belongs to the barrier stream |
| Calling streams parallel to go faster | Parallel only when the file sets are really disjoint; otherwise sequential |
| Criteria as checkboxes | Numbered list |
| A separate spec file next to the story | The story is the spec |
| An owner checkpoint inside a concurrent stream | Move it before the fan-out or into the barrier stream |
| Deciding the route yourself and stating it as fact | Ask in §4; a "yes" to the story is not a route choice |
| Writing the `<!-- route: -->` line before the owner answered | It records the owner's answer, nothing else |
| Committing the story to the code repo | Stories live in `<repo>\.plans\stories\`; the record is the PR, ADR and wiki |
| Showing the owner a story the advisor has not seen, or one with an open 🔴 | §8 runs first; a blocker sends the story back |
| A UI story without `## User Flow` | Write the flow; `e2e-recorder` walks exactly those steps |
| Epic story with invented criteria while a PRD exists | Take them from the covered FRs' testable consequences |
