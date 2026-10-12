# Roadmap: <project>

- project: <name>
- status: draft            # draft | approved | in-progress | done
- created: YYYY-MM-DD
- main_repo: <owner/backend-repo>
- repos: [<backend>, <frontend>]
- inputs: [product/brief.md, product/prd.md, product/ux/, product/architecture.md]   # the discovery chain; list what exists

## End state
<What exists when the project is "done", observable by someone other than the author.>

## First usable release
<Which milestone makes the product usable end to end, and for whom.>

## Constraints
- <deadline / stack / contracts / money / auth / prod data>

## Out of scope
- <explicitly excluded>

## Milestones

| ID | Name | Outcome | Depends on | Estimate (days) | Plan state | Status |
|----|------|---------|------------|-----------------|------------|--------|
| M1 | ...  | thinnest end-to-end slice | — | 2–4 | outlined | todo |
| M2 | ...  | ...     | M1         | 3–6             | outlined   | todo   |

Graph: M1 → M2 → M3, M2 → M4

## Milestone outlines

### M1 — <name>
- plan_state: outlined     # outlined | planned
- status: todo             # todo | in-progress | done | dropped
- depends_on: []
- github_milestone: none
- file: none               # milestones\M1-<slug>.md once planned

**Outcome.** One sentence, demoable.
**Covers.** UJ-1 (Core), FR-1..FR-6 (when a PRD exists). **Proves.** AD-n (when an architecture exists).
**Rough DoD.** 2–4 bullets (revisable when the milestone is planned).
**Main risk.** The assumption this milestone proves or breaks.
**Estimate.** N–M days (AI agents write the code); `actual:` filled when done.

## Change log
- YYYY-MM-DD — created
