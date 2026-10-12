---
name: parallel-story-execution
description: "Runs an approved feature-pipeline story whose Work Streams are file-disjoint in parallel, locally in the story's git worktree: one fresh implementer agent per stream, launched together, then the barrier stream, then the full gate once at the end. Used by execute-story whenever the Work Streams verdict is 'parallel OK'; also when asked to implement a written multi-task story in parallel or fan its streams out across subagents. Works in any repository — the verification commands come from the repository itself."
---

# Parallel Story Execution

Run a story's file-disjoint Work Streams at the same time, each by its own fresh implementer, in the story's one git worktree.

Core principle: **parallelism is bounded by file-disjointness and by git, not by task count.**
Streams that share no file run concurrently; everything that shares a file — including git itself — runs one at a time.
A nine-task story is usually two or three streams plus a barrier, rarely nine.

## Inputs

- The approved story (its `## Tasks / Subtasks` and `## Work Streams`), by absolute path.
- The worktree `execute-story` created for it, by absolute path.

**Not for** a single-stream story whose tasks chain on the same files (run it in order in the session), a story with no per-task file lists (do the file-overlap analysis first), or 1-2 trivial tasks.

## 1. Read the repository

- **Rules** — `CLAUDE.md` and every file under `.claude/rules/`; note the ones each stream needs (layering, error types, logging, design tokens, naming).
- **The gate** — the commands the rules and the CI workflow run for "done".
- **Implementers** — the story's `Agent:`, or per stream a better-fitting repo agent from `.claude/agents/` (a frontend stream → the repo's frontend agent); with none, `product-os:story-implementer`.

## 2. Re-check the partition

Do not trust the `## Work Streams` table blindly — a stale table clobbers work.
For every task, list the files it creates, edits or deletes, then confirm:

- two streams never share a file (a README, a route registry, a DI/wiring file, a shared types file, a lockfile count as shared);
- no task in one stream imports a symbol another stream creates;
- delete-after-replace order holds: a "retire X" task follows every task that builds X's replacement;
- "retire / delete the old flow", integration and docs that touch several streams are in the **barrier** stream.

A conflict → move the tasks into one stream (or the barrier).
Fewer than two streams left → this skill does not apply: run the story sequentially and tell the owner why.

## 3. Launch the streams together

Launch **one Agent per stream in a single message**, so they run concurrently.
All of them work in the same worktree (`WORKTREE`), never with `isolation: "worktree"` — that would give each agent a different checkout than the story branch.

Every stream prompt carries:

```text
WORKTREE: <absolute path>
STORY: <absolute path>
TASKS: <the task numbers of this stream>
SCOPE: <the exact files this stream may create, edit or delete>
GIT: none
Do not touch any file outside SCOPE — other agents are editing them right now.
Run only focused checks on your own files; no git, no repo-wide formatter, no full build.
Return STATUS, files changed, tests added, and the exact checks you ran with their output.
```

Focused checks means the repository's test runner on the stream's own test files and its linter / formatter / type-checker **scoped to the stream's files** — e.g. Python `pytest <files>`, `ruff check <files>`; Node `vitest run <files>`, `eslint <files>`.
Whole-project checks (a full type-check, an import-contract linter, a production build) read the other streams' half-written files and fail for reasons that are not the stream's; they run once, at the end.

Wait for all streams.
A stream that returns `BLOCKED` (an owner checkpoint, a wrong assumption in the story) → stop before the barrier and bring it to the owner.

## 4. Barrier, then the gate

1. Run the **barrier stream** with one implementer: integration, retiring the old flow, shared wiring, READMEs and docs.
2. Run the **full gate and the full affected test suite** yourself — the first moment everything exists together, so cross-stream breakage shows up here.
   Red → `root-cause-debugging`, then a fix by the implementer of the stream that owns the file.
3. Commit in logical groups (per stream, then the barrier), **explicit paths only**.
   A strict per-task commit history is not possible after a parallel run — say so in the PR if it matters.

Then hand back to `execute-story` for the review (`refute-story`).
This skill runs no review of its own: the reviewers run once, over the combined result.

## Optional: the Workflow tool

When the owner explicitly asks for a workflow (and only then — the `Workflow` tool needs their opt-in), the same partition can run as a script: `parallel()` over the stream agents with the prompts above and `opts.model: 'opus'`, then the barrier agent, with git kept out of the script and the gate run by you afterwards.
It changes how the agents are launched, not the rules above.

## Common mistakes

| Mistake | Fix |
|---|---|
| Two streams that both touch a README, a registry or a lockfile | That file belongs to the barrier stream |
| Parallel agents running `git` in the shared worktree | `GIT: none`; you commit after the gate |
| A repo-wide formatter inside a stream | It rewrites the other agents' in-flight files — focused checks only |
| Retiring old code in the parallel phase | The replacement may not exist yet — barrier only |
| `isolation: "worktree"` on the stream agents | They must all edit the story's worktree |
| Believing a stream's "all green" | You run the full gate after the barrier |
| Expecting a strict per-task commit history | Commit in logical groups and say why |
| Hard-coding one repo's commands | Read the gate from the repository you are in; the examples above are not the contract |
| A vague scope ("work on the API part") | Exact file list — disjoint scope is what makes parallel safe |
