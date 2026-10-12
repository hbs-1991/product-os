---
name: root-cause-debugging
description: "Use for any bug, failing test, flaky test or behaviour nobody expected — before proposing a fix. Reproduces the failure on the real path first, turns the reproduction into a failing test, localises where the wrong value first appears, tests one written hypothesis at a time, fixes at the origin, and stops after three failed fixes to question the design. Used by feature-pipeline as the entry for bugs and by execute-story whenever something unexpected happens. Triggers: 'баг', 'не работает', 'упал тест', 'почему так', 'debug this', 'fix this error'."
---

# Root-Cause Debugging

A bug is fixed when you can say **what** was wrong, **where** it started, and **which test** goes red without the fix.
Anything less is a guess that happened to make a symptom disappear.

<HARD-GATE>
No code change that is meant as a fix before the failure is reproduced and the cause is named in one sentence.
Instrumentation (a log line, a probe script, a failing test) is allowed — it is how you get there.
</HARD-GATE>

Use it for every technical failure (tests, build, integration, performance), and especially under time pressure, after a fix already failed, or when the bug "looks simple": guess-and-check thrashing is slower than this.

## 1. Pin the symptom

Write down, before touching anything:

- **What happens** — the exact error text, status code, wrong value, or screenshot; never a paraphrase.
- **What should happen** — and where that expectation comes from (a story criterion, docs, the owner).
- **Where** — endpoint, screen, job, test name; which environment (local, staging, production).
- **Since when** — `git log` on the paths involved, plus new dependencies, config and environment differences; if it used to work, the last good commit is the strongest clue you will get (`git bisect` when the range is large).
- **How often** — always, sometimes, only for one user or one record.

Read the whole error and stack trace. The line that fails is rarely the line that is wrong, but the trace tells you which way to walk.

## 2. Reproduce on the real path

Make it fail on demand, as close to how a user hits it as the repo allows: the real endpoint, the real job through its queue, the real webhook payload, the real screen in a browser.
Then shrink it to the smallest input that still fails.
The reproduction becomes a **failing test** in the repo's test suite — it stays there as the regression test.

Cannot reproduce?
Do not fix blind.
Collect evidence instead: the production logs for that request, the record's actual data, the config that differs between environments; add logging at each boundary the value crosses and wait for the next occurrence.
Tell the owner what you need (an id, a time, access) rather than guessing.

## 3. Localise: walk back to the origin

From the symptom, trace the bad value backwards through every boundary it crossed — UI → API → service → storage → job → external call — until you find the first place where it is already wrong.
That place, not the place it crashed, is where the fix belongs.

Techniques, cheapest first:

- **Compare with a working case** — a sibling endpoint, the same flow for another user, the last good commit. List every difference; one of them is the cause.
- **Log at the boundaries** — one line per layer with the value going in and out, run once, read where it changes.
- **Bisect** — over commits (`git bisect run <test>`), over input (halve the payload), over configuration.
- **Read the reference completely** — when copying a pattern, read the working implementation in full, not a skim.
- **Read the contract** — the docs of the library or API at the version actually installed, not the one you remember.

## 4. One hypothesis at a time

Write it down: **"It fails because X; if that is true, then Y will show when I do Z."**
Run the smallest experiment that would show Y.

- Confirmed → go to §5.
- Refuted → write it under "ruled out" and form the next one. Do not stack a second change on top of the first.

Never change two things at once: when it starts working you will not know which one mattered, and the other one is now an unreviewed change.

## 5. Fix at the origin

1. The failing test from §2 is red.
2. Make **one** change, at the origin found in §3.
3. The test goes green; the related tests stay green.
4. Revert the fix once and watch the test go red again — this proves the test guards the bug.
5. If the bad value can enter from several places, add a guard at the boundary where it enters (validation, a type, an assertion with a clear message) — not a patch at every place it later hurts.

No "while I'm here" refactors in the fix: they hide the real change from the reviewers.

## 6. Three strikes

Three fixes tried and it still fails, or each fix surfaces a new failure somewhere else → stop.
That pattern means the design is wrong, not the line.
Bring the owner what you know: the symptom, the reproduction, what was ruled out, the three attempts — and recommend going to `feature-pipeline` for a design decision.

## When there is truly no code root cause

If the investigation shows the cause is environmental, timing-dependent or external, you have still finished the process: document what you ruled out, add the right handling (retry, timeout, clear error message) and logging for next time. Most "no root cause" verdicts are an incomplete investigation, so check twice.

## Flaky and slow failures

- **Timing:** a fixed `sleep` is a guess about speed. Wait for the condition itself (the element visible, the row present, the job finished) with a timeout and a clear failure message.
- **Test pollution:** a test passes alone and fails in the suite → some earlier test leaves state behind. Run the suite with the failing test last and halve the tests before it until one remains; that one is the polluter. Fix its cleanup, not the victim.
- **Order and concurrency:** run the failing test many times in a row and in random order; a failure rate is evidence, a single green run is not.

## Hand-off

- A small fix with no design decision → commit with the regression test, then `verify-before-pr` before claiming it is fixed.
- The fix needs a design decision (a contract change, a migration, a behaviour change the owner must approve) → `feature-pipeline`, carrying the reproduction and the named cause into brainstorming as known knowns.
- Inside `execute-story` → return to the task you were on once the cause is fixed; if the story itself is wrong, stop and tell the owner.

## Red flags — stop and go back to §2

| You are thinking | What it means |
|---|---|
| "Let me just try changing this" | No hypothesis — write one first |
| "It's probably the cache / the network / a race" | A guess — get the evidence that shows it |
| "I'll add a null check here" | Treating the symptom; where did the null come from? |
| "It works now, not sure why" | Not fixed — it will come back |
| "One more fix" after the third | §6 — question the design |
| "I can't reproduce it, but this should fix it" | §2 — collect evidence instead |
| "Skip the test, I'll check by hand" | The test is the proof it stays fixed |
| "Several fixes at once saves time" | You cannot tell which one worked, and one of them is a new bug |
| "I see the problem" | You see a symptom; name the origin first |

Owner signals that you are guessing: "stop guessing", "is that actually happening?", "will it show us...?", "we're stuck". Go back to §2 and collect evidence.
