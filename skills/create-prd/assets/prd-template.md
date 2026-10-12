---
title: <Product>
status: draft            # draft | final
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [brief.md, research/...]
---

# PRD: <Product>

## 0. Document Purpose
Who reads this, how it is structured (glossary-anchored; features group FRs; assumptions tagged inline and indexed), what it builds on (brief, research digests).

## 1. Vision
2–3 paragraphs that stand alone.

## 2. Target User
### 2.1 Jobs To Be Done
- functional / emotional / social / contextual
### 2.2 Non-Users (v1)
Who this is explicitly not for.

### 2.3 Key User Journeys
- **UJ-1. <Persona doing the thing>**
  - Persona + context: ...
  - Entry state: authenticated? which surface? coming from where?
  - Path: 3–5 concrete beats
  - Climax: the moment value lands, and how the user knows
  - Resolution: state they are left in
  - Edge case: one real failure and what the user does next

### 2.4 Journey Weights
| Journey | Frequency | User value | Business value | Risk if broken | Weight (Core / Supporting / Edge) |
|---|---|---|---|---|---|

Research: `research/user-flow-<topic>.md` (how comparable products handle these flows).

## 3. Glossary
- **Term** — definition; relationships; cardinality. No synonyms elsewhere in the PRD.

## 4. Features
### 4.1 <Feature>
**Description:** behavioural narrative. Realizes UJ-x. `[ASSUMPTION: ...]` inline where inferred.

#### FR-1: <capability>
<Actor> can <capability> <conditions>. Realizes UJ-x.

**Consequences (testable):**
- <specific, checkable condition>

**Out of scope:** (optional)

**Feature-specific NFRs / Notes:** (optional)

## 5. Cross-cutting NFRs
Performance, security, reliability, accessibility, observability, privacy: only those that matter.

## 6. Non-Goals
What this product is not and will not do in v1.

## 7. MVP Scope
### In scope
### Out of scope (with one-line reason; deferred items marked v2/v3)

## 8. Success Metrics
- **SM-1** metric, definition, target. Validates FR-x.
- **SM-C1 (counter-metric)** what must not be optimised. Counterbalances SM-1.

## 9. Open Questions
1. ...

## 10. Assumptions Index
Every inline `[ASSUMPTION]`, listed for confirmation.

<!-- Adapt-in sections (add only those the concern scan calls for): Constraints & Guardrails · Why Now · Aesthetic & Tone · Information Architecture · Monetisation · Platform · Stakeholders & Approvals · Risks · ROI · Operational Requirements · Integrations & Dependencies · Rollout · Data Governance · Compliance · API Contracts & Versioning · Hardware Constraints. Delete this comment. -->
