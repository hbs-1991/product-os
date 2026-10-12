---
name: verify-before-pr
description: "The last step before a PR, a commit meant to ship, or any claim that work is done, fixed or passing: re-runs the repo's full gate and tests fresh on the exact commit that will ship, reads the real output, checks every acceptance criterion against evidence, and produces the Verification section for the PR body. Agent self-reports and earlier runs do not count. Used by execute-story after refute-story and the E2E recording, and by root-cause-debugging before a fix is called fixed. Triggers: 'готово?', 'всё работает?', 'открывай PR', 'is it done', 'ship it'."
---

# Verify Before PR

Every agent in the pipeline has already said something is fine: the implementers reported green checks, the reviewers read the code, the verifier confirmed findings.
Those are claims.
This step is the one place where the exact commit that ships is built and tested again, by you, now — and the PR says only what that run showed.

<HARD-GATE>
Do not write "done", "fixed", "passing", "ready" or open the PR until every claim below has a command you ran **in this step**, on the **current HEAD**, with its output read.
</HARD-GATE>

## 1. Fix the commit

In the story's worktree:

```bash
git -C <worktree> status --porcelain     # must be empty — uncommitted work is not what ships
git -C <worktree> rev-parse HEAD         # the SHA you are verifying
```

It must be the Review record's HEAD or a later commit made only for the confirmed fixes.
Anything else (an unreviewed commit, a rebase that changed SHAs) goes back to `refute-story`.

## 2. List the claims

Write down what the PR will claim, one line each:

- the full gate passes (lint, type-check, build — whatever the repo's rules and CI run);
- the test suite passes (or the affected part, if the rules say so — then name the selection);
- each acceptance criterion is met;
- for a bug fix: the regression test fails without the fix and passes with it;
- the story/plan is met line by line: re-read it, check every item, report gaps rather than "tests pass, phase complete";
- for UI work: the user flow works end to end (the `e2e-recorder` result for this HEAD).

## 3. Map each claim to proof and run it

| Claim | Proof that counts | Does not count |
|---|---|---|
| gate passes | the repo's own gate commands, run now, exit code 0 | an implementer's report, a run before the last commit, a linter alone |
| tests pass | the test command run now, the summary line read (passed / failed / skipped) | "the relevant tests passed earlier", a partial run passed off as full |
| AC #n met | the test named in the Review record for AC #n, in this run's output, green | the reviewer's grade alone, a test that does not exercise the edge the AC names |
| bug fixed | the regression test red with the fix reverted, green with it | "it doesn't happen anymore when I try" |
| flow works | `e2e-recorder` PASS whose reported HEAD is this HEAD | a recording from before the last fix commit |

Run every command fresh, in the worktree, to the end.
Read the whole output: exit code, the summary counts, warnings that the rules treat as errors, skipped tests that should have run.
Anything red → back to the step that owns it (`root-cause-debugging` for a failure you do not understand, the implementer for a known one), then run this step again from §1.

## 4. Write the Verification section

For the PR body, next to the Review record:

```markdown
## Verification
Verified HEAD `<sha>` · <date>

| Claim | Command | Result |
|---|---|---|
| gate | `<command>` | exit 0 |
| tests | `<command>` | 214 passed, 0 failed, 3 skipped (skips: <why>) |
| AC 1 | `tests/…::test_…` | passed |
| E2E | e2e-recorder | PASS 6/6 · `flow.webm` |

Not verified: <what could not be run here and why — or "nothing">
```

"Not verified" is honest and allowed; a claim without a row is not.

If `.claude/wiki.conf` exists, run `wiki-ingest` before the PR and say so.

## 5. Say it the same way

Tell the owner exactly what the table says — the numbers, the SHA, what was not verified.
No "should work", "looks good", "probably", and no success wording ("Done!", "Perfect!") for something the table does not show. The rule covers paraphrases and implications too; "just this once", "I'm confident" and "I'm tired" are not evidence.

## Common mistakes

| Mistake | Fix |
|---|---|
| Reusing the gate output from before the last fix commit | Run again on the current HEAD |
| Trusting a subagent's "all tests pass" | Run the tests yourself and read the summary |
| Calling a lint pass a build pass | Each claim needs its own proof |
| Hiding skipped tests | List them with the reason |
| Verifying in the main checkout instead of the worktree | Verify where the commit lives |
| Trusting the VCS-less agent report | Check the actual diff for what the agent says it changed |
| Opening the PR "while the tests run" | The PR waits for the result |
