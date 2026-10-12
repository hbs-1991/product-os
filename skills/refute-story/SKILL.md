---
name: refute-story
description: "The post-code review step of feature-pipeline stage 3: after execute-story's gate is green and before the PR, fresh read-only reviewers try to prove the change does NOT do what its story says — story-refuter always, security-reviewer on its surface — then a zero-context finding-verifier confirms or dismisses every blocker against the real code, the implementer fixes only confirmed ones, and at most two fix rounds run before the owner decides. Writes a Review record for the PR body. Use when execute-story reaches review, or when the owner says 'refute it', 'review the story', 'проверь историю', 'проверь, что всё сделано'."
---

# Refute Story

A change is not done because its author says so.
This step hands the finished change to reviewers who did not write it, and asks them to prove it is **not** done: an acceptance criterion unmet, a Locked Decision broken, more changed than asked, a consumer forgotten, a test that proves nothing, a vulnerability.
Then it checks the reviewers too, with a verifier that saw neither the code being written nor the review being made — because a false positive "fixed" is damage of its own.

It is a step **inside** stage 3, not a stage: the owner is not asked for approval before it runs, only when the rules below send something to them.

```text
gate green (execute-story §4.1–2)
  │
  0. commit + sync, record HEAD and BASE
  1. pick the lanes
  2. review   ── story-refuter ─┐  in parallel, read-only, fresh
  │           ── security-reviewer (its surface) ─┘
  │           (wait for BOTH lanes to return)
  3. verify   ── finding-verifier, zero context, over every blocker of both lanes
  4. fix      ── the story's Agent: fixes CONFIRMED only, one test each, new commit
  5. re-run   ── only the lanes that found something (+ security if a fix touched its surface)
  │              round ≤ 2, then the owner
  6. Review record → PR body
  ▼
e2e-recorder (UI) → wiki-ingest (if wiki) → verify-before-pr → PR
```

## Agents

Use the repository's own agent when `.claude/agents/<name>.md` exists — it knows the repo's rules; otherwise the plugin's `product-os:<name>`:

- `story-refuter` — the story lane;
- `security-reviewer` — the security lane;
- `finding-verifier` — the verify step.

If none of these can be launched (a session without plugin agents), use a `general-purpose` subagent with [`refuter-brief.md`](refuter-brief.md) pasted into its prompt, and tell the owner the generic brief was used.
If `finding-verifier` cannot be launched, fall back to **one fresh** `story-refuter` in verify mode (`MODE: verify` in the handoff) and say in the Review record which verifier ran.
A repo without a `security-reviewer` of its own still gets the plugin's; if none can be launched, say so in the Review record rather than substituting a generic one.

## Inputs

- The story path — the absolute path in the main checkout, `<repo>\.plans\stories\YYYY-MM-DD-<slug>.md` (`<repo>` = `git rev-parse --path-format=absolute --git-common-dir` minus `\.git`; worktrees do not contain `.plans`) — or the task text when there is no story.
  `.plans` is a nested git repo excluded from the code repo: never commit it there.
- The worktree the change lives in, and the story's `Agent:`.

## 0. Commit, sync, record

The reviewers read a commit, never a moving working tree:

1. Commit the change on the story branch, **explicit paths only** (no `git add -A` — a shared tree may hold other sessions' edits).
   `git status --porcelain` in the worktree must then be empty.
2. Sync onto the integration branch now, not after the review: `git fetch origin`, then `git merge origin/<integration-branch>`.
   A merge, not a rebase, so the SHA you record stays the SHA you ship.
3. Record `WORKTREE` (absolute path), `HEAD` (`git rev-parse HEAD`), `BASE` (`git merge-base HEAD origin/<integration-branch>`).

## 1. Pick the lanes

- **Story lane — always.** `story-refuter`.
- **Security lane** — `security-reviewer`, when `git diff --name-only BASE..HEAD` touches the surface listed in that agent's `## When the pipeline runs you` section (auth, money, webhooks, tenancy, secrets/PII, uploads, agent tool calls, dependencies).
  When unsure, run it.

## 2. Review

Launch every lane **in one message**, so they run in parallel and neither sees the other's report, and never with `isolation: "worktree"` (that gives the agent a different checkout, not the story branch).
Each prompt carries the handoff and nothing that steers the verdict:

```text
WORKTREE: <absolute path>
HEAD: <sha>
BASE: <sha>
STORY: <absolute path of the story, or the task text>
MODE: review
Run every git command as `git -C <WORKTREE>`. Verify HEAD and a non-empty BASE...HEAD diff before reviewing.
```

Do not tell a reviewer what the implementer believes, which parts were hard, or that the gate is green — that is the author's view, and the reviewer exists to not have it.
A reviewer that reports the handoff checks failed (wrong HEAD, dirty tree, empty diff) has reviewed nothing: fix the handoff and relaunch.

## 3. Verify

Wait until **every** lane has returned — the verifier runs once, over the union, never on one lane while the other is still reviewing.
Then collect into one numbered list, each with its lane, `file:line` and evidence as the reviewer stated it:

- from `story-refuter`: every 🔴 BLOCKER — which includes every REFUTED criterion and every departed Locked Decision;
- from `security-reviewer`: every 🔴 HIGH **and** 🟠 MEDIUM finding (they are already filtered to confidence ≥ 0.7, so there are few, and a security finding is never fixed or dismissed unverified);
- later, from `e2e-recorder`: every FAIL step.

The same defect raised by both lanes is one item, listing both lanes.
Launch **`finding-verifier`** with the same handoff and that list — no reviewer reasoning beyond what each finding states, no opinion of yours.
It returns each finding as:

- **CONFIRMED** (reproduced) → step 4;
- **DISMISSED** (code evidence; a security finding only with the `file:line` of the guard that closes the path or a test in which the exploit fails) → recorded with its evidence, not fixed;
- **UNRESOLVED** → to the owner, with both sides' evidence; not fixed until they decide.

`story-refuter`'s 🟠 risks and 🟡 nits and `security-reviewer`'s 🟡 LOW findings are not verified and not fixed automatically: they go into the Review record for the owner.
A reviewer you disagree with goes to the owner too — never silently overruled.

## 4. Fix

The story's `Agent:` (or the session, for small work) fixes the CONFIRMED findings only.
Each fix comes with a test that fails without it, or a stated reason a test is impossible.
Commit the fixes as new commits, explicit paths, and record the new `HEAD`.

## 5. Re-run

Re-run only the lanes that had CONFIRMED findings, with the same handoff and the new `HEAD`, telling each which findings to re-check and which commits are the fixes.
Also run the security lane whenever a fix commit touches its surface, even if it found nothing before.
New 🔴 go through step 3 again.

**Two fix rounds at most.**
Still 🔴 after the second → stop and bring the owner the findings, the fixes tried, and your recommendation.

## 6. Review record

Write it for the PR body (for a public repository, describe security findings in general terms):

```markdown
## Review record
Reviewed HEAD `<sha>` against BASE `<sha>` · lanes: story-refuter, security-reviewer · verifier: finding-verifier · rounds: 1

| AC | Outcome | Evidence |
|---|---|---|
| 1 | MET | `tests/…::test_…` red when `src/…:42` is reverted |

| Locked Decision | Outcome | Evidence |
|---|---|---|

| Finding | Lane | Verify | Outcome |
|---|---|---|---|
| … | security | CONFIRMED | fixed in `<sha>` + `tests/…` |

Open for the owner: <🟠 risks, 🟡 nits, UNRESOLVED, UNVERIFIED criteria — or "none">
```

Add one line: `Wiki updated: yes/no` (filled in by `execute-story` after `wiki-ingest`; `no` when the repo has no `.claude/wiki.conf`).

Then hand back to `execute-story`: the E2E recording for UI work, `wiki-ingest` when the repo has a wiki, then `verify-before-pr` re-runs the gate and the tests on the final HEAD — the review does not replace that fresh run.

## Common mistakes

| Mistake | Fix |
|---|---|
| Reviewing uncommitted work | Step 0: commit, the tree must be clean |
| A reviewer run without `WORKTREE`/`HEAD`/`BASE` | Its working directory is the main checkout; an empty diff there looks "clean" |
| Verifying one lane while another is still reviewing | Wait for every lane; the verifier runs once, over the union |
| Fixing a security 🟠 MEDIUM unverified | MEDIUM goes through the verifier like a HIGH |
| Rebasing after the review | Merge; the Review record names the reviewed SHA |
| Fixing every finding as reported | `finding-verifier` first; fix CONFIRMED only |
| Letting the reviewer that raised a finding verify it | The verifier is a different, fresh agent |
| Dismissing a security finding by argument | Code evidence or UNRESOLVED → owner |
| Re-running every lane after a one-line fix | Only the lanes that found something, plus security on its surface |
| A third, fourth fix round | Two, then the owner |
| Telling the reviewer "the gate is green, should be fine" | Handoff only — the reviewer must not inherit the author's view |
| Skipping `verify-before-pr` because the review passed | The review reads code; the final fresh test run is still owed |
