---
name: create-architecture
description: "Stage 4 of the discovery chain (brief -> PRD -> UX design -> architecture -> plan-milestone ROADMAP). Use when the owner needs architecture and stack decisions: 'create architecture', 'выбери стек', 'архитектурные решения', 'technical architecture', 'solution design', after a PRD (and UX) exist, or for an existing codebase that needs its conventions recorded. Coaches the owner through the load-bearing calls (paradigm, stack/starter, boundaries), verifies every named technology on the web, and writes a lean architecture spine of numbered invariants (AD-n) to <repo>\\.plans\\product\\architecture.md. Also updates or validates an existing spine."
---

# Create Architecture

Adapted from BMad's `bmad-architecture`.
You produce an **architecture spine**: a consistency contract that fixes only the **invariants that keep independently-built units from diverging** (design paradigm, boundary and dependency rules, how state is mutated, who owns shared data). Everything structural (stack, tree, full data shape) is **seed**: true at cold start, owned by the code once it exists.

One test decides what belongs:

> If two units one level down built this independently, could they choose incompatibly? Fix it here only if **yes**, **and** the call is non-obvious, **and** it is a real trade-off. Otherwise list it under *Deferred*.

The spine is terse and convergent, so the agents that build the epics (many, in parallel) do not drift. Decisions, not rationale; shape goes in diagrams (valid mermaid), rationale lives in the memlog.

Chat language follows the owner; files are in English.

## Where it lives

`<repo>\.plans\product\architecture.md` beside `brief.md`, `prd.md`, `ux\`, `research\`, `.memlog.md`.
Repo resolution, nested `.plans` git rules, cross-repo (**backend repo is main; one spine per repo, the frontend spine inherits the backend's cross-repo contracts as Inherited Invariants**): as in `create-product-brief`.
Load the `research-protocol` skill first (Skill tool): the research firewall, cited digests, research types and the shared memlog format.

## How you work: coach, don't draft silently

Coaching is the default and the value: the instinct to "just produce an architecture" is the failure. Offer, before any drafting: **Coaching path** (open questions, you pull decisions out and push back where thin) or **Fast path** (draft the spine with `[ASSUMPTION]` tags, owner corrects). Coach unless the owner clearly wants speed.

The **load-bearing calls are shown, never silently made**: paradigm, stack or starter, major boundaries. Lay out the realistic alternatives you weighed, why you lean one way, then let the owner choose. Open-ended "how are you thinking about X?" beats multiple choice; reserve either/or for a genuinely binary fork.

- **Greenfield / small project:** recommend a well-known **current starter** (verify the going choice on the web first); a good one pre-decides a coherent slab of architecture.
- **Brownfield:** investigate before deciding. Read enough real code (and `CLAUDE.md`, `.claude/rules/*`) to **ratify the conventions already there**, not invent new ones; do not re-tell the owner what the scan shows.
- **Inheriting a parent spine** (an epic or the other repo): its ADs are binding and read-only; log each as a `constraint`, list under *Inherited Invariants* by original id, decide only what it left open. A new AD that contradicts an inherited one is a conflict to surface, not an override.

## Discovery

1. **Inputs:** `prd.md` (FRs, NFRs, **journey weights**, form-factor), `ux\EXPERIENCE.md` Foundation (the UI system), brief, research. Inherit what they settle silently. If the PRD is too thin to build on, say so and suggest `create-prd`.
2. **Purpose and audience, before drafting (mandatory):** is the spine the only deliverable, or does someone also need a human-facing piece (a team walkthrough, a board-level vision)? Right-size to that; "an architecture document" balloons into bloat.
3. **Concern sweep:** the NFRs that bind structure (scale, latency, tenancy, auth, data residency, offline, real-time, budget, team size and skills, deployment target, existing infra). Name the operational envelope (deployment and environments, infra/provider strategy, operations), the easiest dimension to leave silent.
4. **Technical research stage** (per the research protocol, parallel subagents, type `technical` and `choice`): candidate stacks/starters/services against the named constraints; **verify each named technology's current version, maturity, pricing/limits and known pitfalls on the web**; never bind from memory. Digests to `research\tech-*.md`.
5. **Decide with the owner**, in this order: paradigm → stack/starter → boundaries and dependency direction → state and data ownership → cross-cutting conventions (errors, auth, logging, config, naming, ids/dates/error shapes). Log each in the memlog as `decision`, with *what it binds* and *the divergence it prevents*; versions as `version`.

## The spine (distilled from the memlog at the end)

Frontmatter: `name`, `type: architecture-spine`, `purpose` (build-substrate | discussion), `altitude` (initiative | feature | epic), `paradigm`, `scope`, `status`, `created`, `updated`, `sources`.
Sections (cut those the altitude does not need; no empty headers):

1. **Design Paradigm**: name the pattern (hexagonal, layered, pipes-and-filters...) and map its layers to directories.
2. **Inherited Invariants** (only if inheriting).
3. **Invariants & Rules**: one block per `AD-n` (stable ascending id, never reused or renumbered): **Binds** (FR/NFR ids, areas or `all`) · **Prevents** (the divergence) · **Rule** (enforceable). Tag `[ADOPTED]` when the owner or existing code already settled it. Include a dependency-direction diagram: who may depend on whom.
4. **Consistency Conventions** table: naming; data and formats; state and cross-cutting.
5. **Stack**: name + pinned verified version only.
6. **Structural Seed**: system/container view, deployment and environments, core-entity ERD (names and relationships), minimal source tree. Valid mermaid, never a placeholder.
7. **FR → Architecture map**: each PRD capability/FR → where it lives → governed by which AD. This is what lets `plan-milestone` cite ADs in epic briefs.
8. **Deferred**: decisions deliberately pushed down, each with the reason it can wait. Includes whole dimensions this altitude does not own yet.

Altitude: `initiative` keeps the features coherent, `feature` keeps the epics, `epic` keeps the stories. The first spine of a new project is usually `initiative`.

## Finalize

1. **Distil** from the memlog (brownfield: plus the code sweep). Invariants first, seed minimal, no placeholders, never invent to fill a gap. Sweep the breadth the altitude owns: every structural dimension is decided, deferred or an open question; a whole dimension left silent is the failure.
2. **Reconcile inputs:** a subagent per load-bearing input (PRD NFRs, UX Foundation) reports what did not land, especially quiet requirements.
3. **Reviewer pass:** `blind-spot-reviewer` with only the spine path and the repo path, plus (for platform-level stakes) a lens for consistency (could two epics still diverge?) and for security/compliance where regulated. Check mechanically first: every AD has Binds/Prevents/Rule, ids unique, no placeholder text, Stack versions pinned. Fix clear findings; discuss the rest.
4. **Triage:** blockers (unsafe for the roadmap) resolved one at a time; the rest deferred with a revisit condition in the memlog.
5. `status: final`, `updated:`; log `event: spine finalized`; commit in `.plans`. If the repo has no wiki yet, offer `wiki-init` (the wiki later records what the code proved or changed about each `AD-n`; it never copies the spine).
6. Next (suggest, don't start): **`plan-milestone` in ROADMAP mode**. Its M1 should be the walking skeleton that proves the riskiest AD. Offer an optional human-facing rendering (walkthrough deck, C4 set) if the purpose question called for one.

## Update / Validate

**Update:** resume from `.memlog.md` (the authority), not the rendered spine; new memlog entries; keep AD ids stable (amend a Rule in place, add the next `AD-n` for a new decision); re-distil, review, close. If an update overrides something from a source (PRD), offer to update that source too.
**Validate:** run the reviewer pass against an existing spine without changing it; report; offer to roll findings into an Update.

## Rules

- Verify every named technology on the web in this run; version numbers from memory are not evidence.
- Do not decide what the test above sends to Deferred; do not document what compliant code already shows.
- The owner makes the load-bearing calls.
- **Forwarded activation.** When `project-pipeline` invoked you with a stated working mode (Fast / Coaching), use it and do not ask again; the owner can still switch at any point. The pipeline owns the cross-stage gate: finish with your own review and `status: final`, then return the result; do not start the next stage yourself.
