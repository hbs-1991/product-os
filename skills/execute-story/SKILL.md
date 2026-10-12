---
name: execute-story
description: "Stage 3 of feature-pipeline: implements an approved story (from write-story) locally in a git worktree with fresh implementer agents — sequentially or in parallel across file-disjoint Work Streams — then runs the full gate, refute-story (story refuter + finding verifier + security reviewer), an end-to-end screen recording of the user flow for UI work (e2e-recorder), the project wiki update when the repo has one, fresh verification, and opens the PR. Use when the owner says 'implement the story', 'execute it', 'сделай по истории', or when write-story hands off."
---

# Execute Story

Implement an approved story.
It always runs locally in a git worktree; the story's `## Work Streams` verdict decides whether the streams run one after another or concurrently.

Core principle: **parallelism is bounded by file-disjointness and by git, not by task count** — and nothing is "done" until a fresh gate run says so.

## Inputs

- An approved story at `<repo>\.plans\stories\YYYY-MM-DD-<slug>.md`, where `<repo>` is the main checkout: `git rev-parse --path-format=absolute --git-common-dir` minus `\.git`.
  Worktrees do not contain `.plans`, so always read the story from the main-checkout path and pass that **absolute path** to every subagent.
  `.plans` is a nested git repo excluded from the code repo — never commit it to the code repo.
- No approved story → run `write-story` first.
- A historical plan that names `superpowers:executing-plans` or `superpowers:subagent-driven-development` is executed here too: treat its tasks as one sequential stream unless it lists disjoint file sets.
- A story task or plan step that says "run `architecture-reviewer`" means `refute-story` (§4.3).

## 1. Confirm the approval

<HARD-GATE>
Do not create a worktree or launch an implementer until the owner approved **this** story — they picked "Approve" in `write-story` §8, or said so in their own words about this story.
Silence, a background-task notification, or approval of an earlier version is not approval.
</HARD-GATE>

The story always runs **locally, in its own git worktree**.
How parallel it runs is not a choice: the `## Work Streams` verdict decides it (§3).

## 2. Isolate

Never implement in a shared checkout — another session may be working in it, and a broad `git add` would sweep its edits into your commit.
Find the integration branch (the repo's rules name it; else `git symbolic-ref --short refs/remotes/origin/HEAD`), then take a worktree off its freshest state:

```bash
git fetch origin
git worktree add ../<repo>-<slug> -b <type>/<slug> origin/<integration-branch>
```

The story lives in the main checkout's `.plans` (outside the worktree) — reference it by absolute path.

## 3. Run the streams — fresh implementers

Read the story's `## Work Streams` verdict, then re-check it against the task file lists yourself — a stale verdict clobbers work.
If the story carries a `<!-- route: local-sequential | local-parallel ... -->` line, that is the owner's choice: sequential runs the streams one after another, parallel fans file-disjoint streams out via `parallel-story-execution`. No such line: ask the owner which; never pick silently.

The implementer is the agent named in `Agent:` — a repo agent, or `product-os:story-implementer`.
It gets the story path, the worktree path, the task numbers and the exact file scope — **not this conversation**.
The story is the spec; anything the implementer would need from the chat belongs in the story, so if you catch yourself explaining something extra, the story has a gap — add it to `## Dev Notes` and tell the owner.

- **Sequential (one stream):** delegate the stream (or each substantial task) to the implementer, in order; for very small work, implement directly.
  After each task, run the focused checks for the files it touched.
- **Parallel OK (≥2 disjoint streams):** invoke the `parallel-story-execution` skill with the story.
  The `## Work Streams` table is the partition; one implementer per stream runs concurrently in the same worktree, the barrier stream runs after them, and the final gate runs once at the end.
  Streams run no `git` and no repo-wide formatters — focused checks only; git and the full gate wait for the end.
  If your re-check finds a shared file, the story is sequential — say so to the owner and run it in order.

During implementation:

- A bug, a failing test, or behavior you did not expect → `root-cause-debugging` before any fix.
- A task with an owner checkpoint ("confirm with the owner whether …") → stop there and ask.
- The story turns out wrong (a file does not exist, an assumption fails) → stop and tell the owner; do not quietly redesign.

## 4. Gate, review, record, verify

1. **Full gate** — the repo's own commands: `CLAUDE.md` / `.claude/rules/` name them, and the CI workflow shows the real chain.
   Grep the tests and the other consumers for any payload, job argument, route or exported prop you changed.
2. **Docs** — the module README on a contract change; an ADR when a decision was made, if the repo keeps them.
3. **`refute-story`** — the post-code review: it commits and syncs the branch, runs fresh reviewers that try to prove the story is NOT done (`story-refuter` always, `security-reviewer` on its surface), has `finding-verifier` confirm or dismiss every blocker, has the implementer fix only the confirmed ones, allows two fix rounds, and writes the Review record for the PR body.
   Disagreements and unresolved findings go to the owner.
4. **End-to-end recording** (the story has a `## User Flow`, or the change is user-facing UI): launch `e2e-recorder` (repo agent, else `product-os:e2e-recorder`) with:
   - `WORKTREE`, `STORY` (absolute path), `OUT` (outside the repo);
   - `APP` — the URL when the app already runs from this worktree in this session, else the commands to start it from the worktree on non-default ports (so it does not collide with another session's instance);
   - `LOGIN` — a test account on a local or dev database, never production;
   - `MOCK` + `VIEWPORT` when the story links a `ui-direction` record.

   A fresh worktree has no gitignored env files (`.env.local` and the like): copy them from the original checkout before the launch and point API URLs at the backend the flow needs.
   If the repo guards its running stack with a lock and the recorder reports `BLOCKED`, tell the owner who holds it and ask whether to wait — never delete the lock to get through.
   The recorder walks the flow, films it with a chapter per step, and returns per-step PASS/FAIL, the video path and screenshots.
   A FAIL is a finding: it goes through `finding-verifier` and the fix loop of `refute-story` like any other blocker.
   Show the owner the video path, and the screenshot next to the canonical mock for every "Visual:" Locked Decision — the mock is the target for layout, hierarchy and density, not pixel-exactness; real tokens and kit primitives win where they differ; report each deviation as fixed or deliberate (with the reason).
   A non-UI change skips this step; say so in the PR.
5. **Wiki** — if `.claude/wiki.conf` exists, run the `wiki-ingest` skill now, after review and before the final verification, so the wiki and in-code READMEs are updated in the same change.
   Record "Wiki updated: yes/no" in the Review record; no `wiki.conf` → no.
6. **`verify-before-pr`** — re-run the gate and the tests fresh on the final HEAD, read the output, and check every acceptance criterion against the Review record's evidence.
   Agent self-reports are claims, not evidence, and the review read code — this is the one fresh test run on what ships.

## 5. Land it

- The repo has its own PR procedure (a `create-pr` skill, a CLAUDE.md/rules checklist) → use it.
- It does not → sync onto `origin/<integration-branch>` with a **merge** (never a rebase — the reviewed SHA must survive), stage **explicit paths only**, push the branch, `gh pr create` against the repo's PR target per its `CLAUDE.md` / rules.
- Respect the repo's branch rules: never push to, or open a PR against, a branch the rules protect.
- The branch was already synced and committed by `refute-story`; if the PR procedure finds it behind again, it merges (never rebases).
- PR body: what changed and why, the Review record from `refute-story`, the final gate output, the E2E result (or why it was skipped), and that the wiki was updated in the same change when it was.
  Attach the recording and screenshots once the PR exists (`gh pr comment <n> --attach <file>`, gh 2.99+); otherwise tell the owner where the files are.

Tell the owner the PR link, what was verified and how, the video, and anything left undone.
If the story carries `Epic: <id>, <milestone slug>`, add that the epic is ready for `plan-milestone` RUN to update its status and Pipeline log — `execute-story` itself does not edit the milestone file.
After the merge: `git worktree remove ../<repo>-<slug>`; the story file may be deleted.

## Common mistakes

| Mistake | Fix |
|---|---|
| Starting before the owner approved this version of the story | §1 — approval first |
| Implementing in the shared checkout | Worktree off the integration branch first |
| Handing the implementer this conversation | It gets the story, the worktree and its file scope — the story is the spec |
| Giving a subagent a story path inside the worktree | `.plans` lives in the main checkout; pass the absolute path |
| Trusting the story's parallel verdict without re-checking file lists | Re-derive it; a shared README or wiring file makes streams sequential |
| Parallel agents running `git` or repo-wide formatters in a shared tree | Focused checks per stream; git and the full gate only at the end |
| Believing an agent's "all green" | Re-run the gate yourself — `verify-before-pr` |
| Fixing every reviewer finding as reported | `refute-story` verifies first; only CONFIRMED findings are fixed |
| A UI story shipped without anyone clicking through it | `e2e-recorder` walks the User Flow and films it |
| Deleting the stack lock because the E2E run was blocked | Tell the owner who holds it; they decide whether to wait |
| Rebasing after the review | Merge; the Review record names the reviewed SHA |
| Wiki updated after the final verification | `wiki-ingest` runs before `verify-before-pr`, so the last fresh run covers it |
| Opening a PR against a protected branch | Use the repo's PR target per its CLAUDE.md/rules |
