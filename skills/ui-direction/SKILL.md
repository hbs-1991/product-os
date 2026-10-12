---
name: ui-direction
displayName: "🧭 UI Direction — research, taste filter, 3 directions, 3 mocks"
description: >
  Decide what a new or substantially changed screen should look like before it is specified or
  built: a brief, internet research on how the best current products solve this kind of screen,
  a taste filter through the project's design system (.plans\product\ux\DESIGN.md and the repo's own DESIGN.md / PRODUCT.md), three distinct design directions,
  one generated mock per direction (ui-mocker agents via ui-mockup -> gpt-image-2), and the owner's choice recorded
  as a design artefact in .plans\design\. Invoked by feature-pipeline stage 1 whenever a feature touches a screen,
  by create-ux-design for the project-level pick, and directly when the owner says "дизайн-направления", "как должен выглядеть экран",
  "найди стиль для страницы", "design directions for this page", "explore the look of X".
emoji: "🧭"
---

# UI Direction

Decides **what to draw**; `ui-mockup` decides **how to draw it**.
The output is one chosen direction, with its mock, that the story locks and the implementation is checked against.

```text
 1. Brief         screen, user, job, data, states, constraints from DESIGN.md
 2. Research      how leading products solve THIS kind of screen today (subagent, web)
 3. Taste filter  every idea against DESIGN.md / PRODUCT.md: keep, adapt, or reject
 4. Directions    exactly 3, genuinely different, each built from the repo's kit
 5. Mocks         one per direction, ui-mockup, in parallel, verified
 6. Choice        owner picks (or blends) -> up to 2 --ref refinements -> recorded
```

## 0. When it runs

**Always ask, never assume.** When a feature adds a screen or noticeably changes one (a page, a widget, a modal, a flow, a new empty/error state), ask the owner one question:
"This screen is new or changes noticeably — run the design step (3 directions + 3 mocks, about 15 minutes)?"
Pure style fixes, copy changes and backend-only work do not trigger the question.
A "no" is fine: note "UI direction skipped by owner" in the design and move on.

Prerequisite: `ui-mockup` + `gpt-image-2` (both in this plugin), with either backend available: `OPENAI_API_KEY` in the environment, or a logged-in `codex` CLI on a ChatGPT plan (see gpt-image-2's backend rule).
If generation is unavailable, say so in one sentence and offer to continue with text-only directions — never substitute another image source silently.

## 1. Brief

Read first, then write the brief (10–15 lines, English):

- `<repo>\.plans\product\ux\DESIGN.md` if it exists (the project design system from `create-ux-design`: it is the taste filter and the source of tokens), plus the repo's own `DESIGN.md` and `PRODUCT.md` (root) and any design rule file (`.claude/rules/*design*`). `<repo>` is the main checkout (`git rev-parse --path-format=absolute --git-common-dir` minus `\.git`), never a worktree;
- the component kit the repo uses (e.g. `components/ui/*`) — directions may only use what exists or can be extended;
- the nearest existing screens — take a screenshot of one if the dev server is already running; it becomes the `--ref` for style transfer.

The brief names: **screen and its container** (page in the dashboard shell? modal? mobile?), **primary user and their one job here**, **the data shown** (real field names and realistic values), **the states** (default, empty, loading, error, over-long), **hard constraints** from DESIGN.md (brand colours, tokens, one-accent rule, banned patterns), and **locale(s)**.

## 2. Research

Delegate to a subagent (`subagent_type: "general-purpose"`) so the raw pages stay out of the main context.
Its prompt contains the brief and asks for:

- 5–8 **concrete references**: named products (e.g. Linear, Stripe, Vercel, Attio, Notion, Shopify admin — whatever fits the screen type) and recent articles / pattern libraries on this screen type, current year preferred;
- per reference: URL, the **pattern** used (layout, density, how the primary action is surfaced, how empty/error states are handled), and why it works for the job;
- 3–5 **current direction trends** for this screen type, each with the evidence behind it;
- no images copied, no claims without a source URL.

Read its result critically: drop anything with no source, anything that is a generic "2026 trends" listicle with no relation to the screen type.

## 3. Taste filter

Build a table, one row per idea from the research:

| Idea | Source | Verdict | Why (cite DESIGN.md / PRODUCT.md) |
|---|---|---|---|
| … | … | keep / adapt: <how> / reject | … |

The repo's design system wins every conflict — a trend that breaks a brand rule is rejected or adapted, never adopted.
Add the agent's own taste explicitly, marked as such: hierarchy (one focus per screen), density appropriate to the user, honest empty states, motion only with a reduced-motion fallback, copy that says what to do next.

## 4. Three directions

Exactly three, and they must differ on a **real axis** (density, information architecture, guidance level, primary-action placement) — not three colour variants of one layout.
For each:

- **Name** — two or three words ("Dense pro table", "Guided cards", "Split inspector").
- **Idea** — two sentences: who it is best for and what it optimises.
- **Layout** — regions with proportions, as `ui-mockup`'s spec template wants them.
- **Kit mapping** — which existing primitives it uses; what would need a new variant.
- **Trade-offs** — pros, cons, build cost, risk on mobile / in other locales.
- **Borrowed from** — the references from §2 it draws on.

Mark your recommendation and say why, in one line.

## 5. Mocks

Invoke `ui-mockup` and follow its workflow (spec template, verification, max two regenerations).
For this skill:

- **Same canvas, preset and chrome for all three** — only the direction differs, so the owner compares ideas, not renders.
  Prefer a project style block (`--style-file`, derived from the repo's tokens as `ui-mockup/references/style-presets.md` describes) or `--ref` a screenshot of the real app, over a generic preset.
- **Launch three `ui-mocker` agents in one message** (`subagent_type: "product-os:ui-mocker"`, `run_in_background: true`), one per direction.
  Each gets `MOCK_SH` (the absolute path of `scripts/mock.sh` in the `ui-mockup` skill's base directory), `REFERENCES` (its `references/` folder), the brief, its one direction, the shared style flags, the aspect and its output path.
  While they run, present §3 and §4 to the owner.
- **Output folder:** `<repo>\.plans\design\<slug>\` (`<slug>` = `<YYYY-MM-DD>-<topic>`). `.plans` is a nested git repo excluded from the code repo.
  Files: `direction-a-<slug>.png`, `-b-`, `-c-`.
- Read every PNG back yourself as well — the mocker's verification note is a claim — before showing it. Show all three side by side with the direction names.

## 6. Choice and record

Ask the owner to pick A, B, C, or a blend ("layout of B, density of A").
Then at most **two `--ref` refinements** of the chosen mock (blends and targeted fixes), plus a **state sheet** (empty / loading / error) when the screen has non-trivial states.

Write `README.md` into the same folder, English, one sentence per line (the record artefact):

- the brief;
- the research references (URLs) and the taste-filter table;
- the three directions, the choice, and the owner's reason;
- the chosen direction's tokens (colours, type, radii, spacing) when the project has a design system;
- the final mock files and which one is canonical;
- **Locked visual decisions** — 3–7 checkable sentences ("The primary action sits top-right of the table header, one orange button, nothing else orange").

The record is dated and never updated afterwards; if the design later changes, a new record is made.

## Hand-off

- **From `feature-pipeline` / `brainstorming`:** the chosen direction becomes the visual part of the draft design.
  `write-story` copies the **Locked visual decisions** into Locked Decisions and links the record folder and canonical mock under References.
- **`execute-story`** compares the built screen against the canonical mock (see its gate step).
- **From `create-ux-design`:** return the chosen direction, its tokens and its Locked visual decisions in the record, so `create-ux-design` can lift them into `DESIGN.md`.
- The record lives in `.plans`; never commit it to the code repo. Link it from the story instead.

## Hard constraints

- Never skip the ask in §0, never decide the direction for the owner.
- Never fewer or more than three directions in §4.
- Never present a mock without reading it back.
- Never let a researched trend override the repo's DESIGN.md.
- Chat in the owner's language; every written artefact in English.
