---
name: brainstorming
description: "Stage 1 of feature-pipeline: turns an idea into an approved design by walking the Unknowns Matrix (known knowns, known unknowns, unknown knowns, unknown unknowns) with the owner, including a blind-spot pass by a fresh subagent. Use when an idea, feature, behavior change or non-trivial fix must be designed before a story is written — invoked by feature-pipeline; use feature-pipeline as the entry point when the owner wants the whole idea-to-PR flow."
---

# Brainstorming — the Unknowns Matrix

Turn an idea into an approved design the owner and the agent share.

The method comes from how Anthropic engineers prompt agents on hard problems: the goal is to bring the **map in the owner's head** as close as possible to the **territory the agent will walk**.
Every task carries four kinds of knowledge, and each one is surfaced differently:

| Quadrant | What it is | Who surfaces it | How |
|---|---|---|---|
| **Known knowns** | facts the owner knows and would say | the agent, from the repo | read first, then show a short "what I understood" summary for the owner to correct |
| **Known unknowns** | what the owner knows they don't know | the owner, then the agent adds its own | never guess: 2–3 options each, plus the assumption that decides between them |
| **Unknown knowns** | what the owner knows so well they don't think to say it | the agent, by asking | a targeted interview about context that is not in the code |
| **Unknown unknowns** | what nobody in the conversation has thought of | a fresh subagent | the blind-spot pass (`references/blind-spot-pass.md`) |

The third and fourth quadrants are why this skill exists.
A design built only from the first two looks complete and is wrong in ways nobody could have asked about.

<HARD-GATE>
Do NOT write code, scaffold anything, or invoke an implementation skill until the owner has approved the design.
The design may be three sentences for a small change, but it is presented and approved.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order:

1. **Scope check** — is this one thing or several?
2. **Known knowns** — read the repo, present the summary, get corrections
3. **Known unknowns** — collect them, frame each as options + deciding assumption
4. **Unknown knowns** — the tacit-context interview
5. **Draft design** — 2–3 approaches with a recommendation, then the draft of the chosen one
6. **Unknown unknowns** — blind-spot pass by a fresh subagent, triage every finding with the owner
7. **Present the final design** — section by section, get approval
8. **Hand off** — to `write-story` (or back to the caller)

## 1. Scope check

Before any question, decide whether the request is one design or several.
If it describes several independent subsystems ("chat, billing and analytics"), say so immediately and help the owner split it: what are the pieces, how do they relate, which comes first.
Then run this skill on the first piece only.

## 2. Known knowns — read first, then summarise

Do the reading yourself; the owner should never have to tell you what the code already says.

- The repo's `CLAUDE.md` and `.claude/rules/*`.
- The wiki, if `.claude/wiki.conf` exists: read `<wiki_dir>/index.md`, the relevant module/concept pages and decisions (ADRs) as known-knowns sources. Treat their claims as hypotheses: when a page names a file, route or symbol, confirm it still exists in the code before relying on it.
- The in-code README of every module the idea touches, then its models, services, router.
- `git log` on those paths — recent changes often explain the current shape.
- The sibling repo(s) the change reaches — a backend and its frontends, a shared library and its consumers — when the owner names them or the repo's docs do.

Then show the owner a **short** summary — five to ten bullets:

> Here is what I understood from the code and docs. Correct anything that's wrong:
> - today X works like …
> - the data lives in …
> - the frontend calls …

Corrections from the owner here are cheap and extremely valuable.
Do not ask questions the code already answers.

### Input is an epic brief

When started from a `plan-milestone` RUN epic brief (`Known / Wanted / Out of scope / Open questions`, plus `Covers: FR-.. (UJ-..)`, `Design:`, `Architecture: AD-..`):
treat Known and Out of scope as pre-filled known knowns, and Open questions as pre-filled known unknowns; do not re-ask what the brief settles.
Read the cited PRD, UX and architecture sections by id from `<repo>\.plans\product\` and treat them as authoritative inputs; if the design must contradict one, raise it with the owner instead of drifting.

## 3. Known unknowns — say "I don't know" out loud

Ask the owner directly: **"What here are you unsure about yourself?"**
Then add the unknowns you found while reading (a behaviour the code does not pin down, a product choice, a trade-off).

For each unknown, do not pick silently.
Present 2–3 options and the **assumption that decides** between them:

> Unknown: how fresh must the numbers be?
> - A — live on every page load (simple; slow and costly if the provider rate-limits)
> - B — refreshed hourly by a beat task (cheap; up to an hour stale)
> - Decides it: does anyone act on these numbers within the hour?

A known unknown the owner cannot answer now becomes an **Open Question** with a recommended default — it does not become a guess.

## 4. Unknown knowns — the tacit-context interview

The owner carries context that is obvious to them and invisible to you: people, promises, history, production reality.
Nothing in the repo will reveal it, and they will not think to mention it.
Ask for it.

Pick the probes that fit this idea (not all of them):

- **Who** actually uses this, how often, and what do they do right before and after?
- **What was promised** to a customer, a partner, or the team about it?
- **Production reality** — how much data, which messy legacy rows, which accounts are special?
- **Coupling** — which frontend screen, report, automation or person depends on today's behaviour?
- **Constraints nobody wrote down** — budget per call, a provider you must not use, a deadline, a policy.
- **People and process** — who has to approve, configure, or be told? Is anyone wary of this change?
- **History** — was this tried before? Why was it built the way it is?
- **What would make you unhappy** even if everything technically works?

Use `AskUserQuestion` with up to **3–4 related questions per round**, multiple choice where possible, with an "other" escape.
Question discipline: one topic per question, each with a recommended answer and why; never ask what the code or docs answer; no leading or yes-by-default questions.
Keep rounds few; stop when the answers stop changing the design.
The owner may not be a technical expert: ask in plain words, and keep technical terms with a short explanation.
Chat with the owner in their language; anything written to a file is English.

## 5. Draft design

**A screen is involved?** Before drafting, ask the owner whether to run `ui-direction` (always ask when a screen is added or noticeably changed).
If yes, run it now; its chosen direction and Locked visual decisions are inputs to this draft, not one of its 2–3 approaches.

**Propose 2–3 approaches** with trade-offs, lead with your recommendation and say why.
Once one is chosen, draft the design, applying the disciplines in `references/design-principles.md` (read it once per session):

- **Reuse-first.** Each unit names what it reuses — files, schema, services, helpers, ports — before what it adds.
- **Hard-to-reverse decisions first.** Wire format, public ids, data-model shape, auth/ownership boundaries → a **Locked Decisions** list with a one-line rationale each.
- **Smallest first cut** that proves the approach without foreclosing it; say what is in and what is deferred.
- **Right altitude.** Keep the core abstraction separate from the first example that motivated it.
- **Design for isolation.** Units with one purpose and a clear interface, testable on their own.
- **Visual blocks** where a relationship is clearer shown than told — a Mermaid diagram, a data-model or endpoint table, a file tree.
- **Working in an existing codebase:** follow its patterns; include targeted improvements only where the current code blocks this work; no unrelated refactoring.

Cover: architecture, data flow, error handling, testing, rollout.

## 6. Unknown unknowns — the blind-spot pass

Now that a draft exists, find what nobody thought of.

1. Launch the **`blind-spot-reviewer`** agent with the Agent tool (`subagent_type: "product-os:blind-spot-reviewer"`, or the repo's own agent of that name; if it is not in the session's agent list, see the fallback in `references/blind-spot-pass.md`).
   Its prompt is only the repository path and the draft design — see `references/blind-spot-pass.md` for the handoff.
   Give it the draft design and the repo — **never the conversation**; its value is that it does not share your assumptions.
2. While it runs, you may continue presenting the draft; do not present the design as final before the pass returns.
3. **Triage every finding with the owner.**
   Each one ends in exactly one bucket:
   - **addressed** — the design changes (say how);
   - **out of scope** — deliberately not done (goes to Out of scope, with the reason);
   - **open question** — only the owner can decide, and they can't yet (goes to Open Questions with a recommended default);
   - **not real** — the finding is wrong for this repo (say why, in one line).

   Present them compactly — a table, one line per finding — and let the owner overrule any bucket.
   Never drop a finding silently and never bucket one on your own authority; a finding that changes the design returns to the owner as a changed section, not as a footnote.

For a genuinely small change, the pass may be skipped **only with the owner's agreement**; say so explicitly rather than skipping silently.

## 7. Present the final design

Present in sections scaled to their complexity — a few sentences when straightforward, up to 200–300 words when nuanced — and ask after each whether it looks right.
Lead with what changes for the product and the user, then the technical side.
End with the **Locked Decisions** and the **Open Questions** (each with a recommended default).

Go back and revise whenever the owner pushes back; approval means the owner said so.

## 8. Hand off

- **Invoked from `feature-pipeline`** (or directly by the owner): the approved design stays in the conversation.
  Do NOT write a separate design document — the next stage, `write-story`, turns it into the one document that carries both story and spec.
  Invoke `write-story`.
- **Invoked from another skill** that only needs a design: stop after approval and return to it.
- **The owner explicitly asks for a standalone design document**: write it to the path they name.

## Where things live

Planning artifacts (boards, notes, any file this skill writes) go under `<repo>\.plans\`, where `<repo>` is the main checkout (`git rev-parse --path-format=absolute --git-common-dir` minus `\.git`), never a worktree.
`.plans\` is a nested git repo excluded from the code repo via `.git/info/exclude`; never commit it to the code repo.

## Key principles

- **Read before you ask.** Questions the code answers waste the owner's attention.
- **"I don't know" is information.** A named unknown with options beats a confident guess.
- **Ask for the context that isn't in the code** — it is usually the part that changes the result.
- **The blind-spot reviewer must be blind** to the conversation.
- **YAGNI.** Remove anything the goal does not need.
- **Standalone wording.** Write the design so a reader who never saw the chat understands it.

## Visual board

When a question is clearer shown than read — two layouts, a flow, a diagram, the ui-direction mocks side by side — you can put it on a local page in the owner's browser and let them answer by clicking.
It is for single questions, not a mode; offer it once, the first time such a question comes up, in a message of its own.
How to start it, write screens and read the answers: `references/visual-board.md` (read it when the owner accepts).
Without Node, or when the owner declines, use Markdown: a table, an ASCII sketch, a Mermaid diagram.
