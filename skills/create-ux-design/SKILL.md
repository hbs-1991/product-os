---
name: create-ux-design
description: "Stage 3 of the discovery chain (brief -> PRD -> UX design -> architecture -> plan-milestone ROADMAP). Use for user-facing products when the owner needs the UI/UX foundation and a design system decided: 'create UX design', 'design system', 'определи дизайн систему', 'UX research', 'как должен выглядеть продукт', after a PRD exists or for a UI-heavy idea. Researches current UI/UX patterns and UI systems with subagents, elicits the owner's taste, then writes two contracts to <repo>\\.plans\\product\\ux\\: DESIGN.md (how it looks: tokens + rationale) and EXPERIENCE.md (how it behaves: IA, states, flows, accessibility). Reuses ui-direction for the three-directions pick."
---

# Create UX Design

Adapted from BMad's `bmad-ux`.
You are a UX facilitator. **Elicit and capture the owner's vision; never impose yours.** Probe like a senior practitioner; do not volunteer colours, patterns or directions unless a theme is already in place and the owner confirms it. Showing options is fine (and encouraged); the picks are the owner's.

Two peer contracts, each winning over any mock or wireframe on conflict:

- **DESIGN.md**, *how it looks*: YAML tokens (`colors`, `typography`, `rounded`, `spacing`, `components`) + prose in this order: Brand & Style · Colors · Typography · Layout & Spacing · Elevation & Depth · Shapes · Components · Do's and Don'ts (sections omittable, order fixed). Follows the Google Labs DESIGN.md spec (<https://github.com/google-labs-code/design.md>); if unsure about a field, fetch the spec instead of guessing.
- **EXPERIENCE.md**, *how it behaves*: Foundation (form-factor, UI system) · Information Architecture · Voice & Tone (microcopy) · Component Patterns (behavioural) · State Patterns (empty / loading / error / success) · Interaction Primitives · Accessibility Floor · **Key Flows** (named-protagonist journeys with a climax beat, mirroring the PRD's `UJ-n` ids and weights). When triggered: Inspiration & Anti-patterns, Responsive & Platform. Reference DESIGN.md tokens by name (`{colors.primary}`).

When Foundation names a UI system (shadcn, MUI, native UIKit, Compose, an internal system), both files inherit from it: tokens extend its defaults and EXPERIENCE.md states only the behavioural delta.

Chat language follows the owner; files are in English.

## Where it lives

`<repo>\.plans\product\ux\DESIGN.md`, `EXPERIENCE.md`, `mockups\` (HTML), `wireframes\`, `imports\` (owner-supplied visuals), `.working\` (scratch). Memlog, research folder, repo resolution, `.plans` git rules: as in `create-product-brief`.
Load the `research-protocol` skill first (Skill tool): the research firewall, cited digests, research types and the shared memlog format.
Repo-level `DESIGN.md` / `PRODUCT.md` already in the code repo are inputs, not outputs: `ui-direction` reads them as the taste filter.

## Discovery

1. **Sources.** List (paths only, extract by subagent) `product\brief.md`, `prd.md`, research digests, existing `DESIGN.md`/`PRODUCT.md` in the repo. Confirm which apply. The PRD's **journey weights** set the effort: Core journeys get full flows, key-screen mocks and strict states; Edge journeys get a line.
2. **Brain dump, then stakes:** hobby / internal / consumer / regulated. Brand assets, references the owner loves and hates, existing Figma / sketches (to `imports\`).
3. **Form-factor must resolve before IA closes** (mobile / web / desktop / multi-surface). Journeys often decide it; if not, ask.
4. **Concern scan** (open list): accessibility, platforms, brand, regulated language, motion, i18n/RTL, dark mode, offline, content density, input modalities, notifications. Drives invented sections.
5. **UI/UX research stage** (per the research protocol, parallel subagents):
   - `ux-pattern` — how the best current products solve this kind of screen/flow; which patterns users already know.
   - `choice` — candidate **UI systems / component libraries** for the form-factor (current versions, accessibility, theming, maintenance health, licence).
   Digests to `research\ux-*.md`.
6. **Design direction** (consumer / branded / UI-heavy): hand the hero screen and the research digests to **`ui-direction`**. It produces three distinct directions with mocks and records the owner's pick; bring the chosen direction, its tokens and its **Locked visual decisions** into DESIGN.md. If `ui-direction` or its mock tool is unavailable, render directions as self-contained HTML files yourself (3 personalities, not palette swaps, real product copy, no lorem) and ask the owner to pick. Internal tools may skip this and take the UI system's defaults, with the owner's yes.
7. **Working mode:** Fast (draft both files with `[ASSUMPTION]` tags) · Coaching (walk decisions, mocks woven in) · Design handoff (build a prompt for an external design tool; the owner returns the output to `imports\`).
8. **Journeys.** Take the PRD's `UJ-n`; if no PRD, the owner narrates a session with a named protagonist. Structure into numbered steps with a climax beat; **surface closure**: every stated need has a screen, every screen is reached by a journey; never invent the missing piece.

## Finalize

1. **Distil** both files from the memlog, `.working\`, `imports\` and sources (a subagent for long runs). Visual decisions go to DESIGN.md, behavioural ones to EXPERIENCE.md. Surface gaps; never invent.
2. **Key-screen mocks** for surfaces where layout drives behaviour. Walk every IA surface and mark it *mocked* or *spine-only*; ask: "these are built from the tables alone, any need a visual?"
3. **Reviewer pass (opt-in, ask first; it costs tokens):** accessibility lens for consumer/regulated products; `blind-spot-reviewer` on both files. Resolve findings before polish.
4. **Open items:** `[ASSUMPTION]`, `[NOTE FOR UX]`; blockers one at a time, the rest deferred in the memlog.
5. `status: final` in both files, `updated:`; log `event: UX finalized`; commit in `.plans`; promote keepers from `.working\` to `mockups\` / `wireframes\`.
6. Next (suggest): `create-architecture`, or `plan-milestone` ROADMAP if the architecture exists or is not needed.

## Rules

- The owner picks every visual direction; you research, render and recommend.
- UI libraries and versions are verified on the web (research firewall), not recalled.
- Core journeys first: effort follows the PRD's journey weights.
- **Forwarded activation.** When `project-pipeline` invoked you with a stated working mode (Fast / Coaching), use it and do not ask again; the owner can still switch at any point. The pipeline owns the cross-stage gate: finish with your own review and `status: final`, then return the result; do not start the next stage yourself.
