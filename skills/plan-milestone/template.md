# Milestone: <name>

- slug: <kebab-slug>
- status: draft            # draft | approved | in-progress | done
- created: YYYY-MM-DD
- main_repo: <owner/backend-repo>     # backend for cross-repo epics
- github_milestone: none              # or: number, set after the owner agrees to sync

## Outcome
<What is true when this is done, observable by someone other than the author.>

## Definition of Done
- [ ] <verifiable bullet>
- [ ] <verifiable bullet>

## Out of scope
- <explicitly excluded>

## Constraints
- <deadline / contracts / money / auth / prod data>

## Estimate
Critical path: E1 → E2 → E4 ≈ <N> days (AI agents write the code; the time is owner approvals, agent runs, review loop, CI).
Assumptions: <same-day owner approvals / external waits / ...>

## Epics overview

| ID | Title | Size | Estimate | Depends on | UI | Status |
|----|-------|------|----------|------------|----|--------|
| E1 | ...   | M    | ~1 day   | —          | no | todo   |

Graph: E1 → E2, E3 → E4

## Epics

### E1 — <outcome title>
- status: todo
- size: M
- estimate: ~1 day         # agent time + approvals; fill `actual:` when done
- depends_on: []
- ui: no
- repo: <repo>
- github: none            # epic issue number in main_repo, e.g. #12

**Outcome.** ...

**Brief for brainstorming.**
- Known: ...
- Wanted: ...
- Out of scope: ...
- Open questions / risks: ...

**Done when.**
- ...

**Pipeline log.**
- (story path, story issues as owner/repo#N, PR links)

## Parking lot
- <ideas that belong to a later milestone>

## Change log
- YYYY-MM-DD — created
