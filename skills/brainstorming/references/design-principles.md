# Design principles

How the draft design in brainstorming §5 is written, so that `write-story` can turn it into a story without guessing and the reviewers can check the result against it.
Read once per session, before the first draft.

## 1. Start from what exists

Every unit of the design first names what it builds on — files, tables, services, components, helpers, endpoints — and only then what it adds.
The reader should see the real delta, not a retelling of the codebase.
Before proposing a new module, file or helper, search for an existing home: the module READMEs, the docs index, a sibling feature that solved the same shape.
A design that adds something the repo already has is the most common, cheapest-to-prevent waste.

## 2. Lock what is expensive to undo

Some choices cannot be changed cheaply once data or callers depend on them.
Find them before scoping, and decide them now even if most of the feature ships later:

| Kind | Examples |
|---|---|
| wire format | request and response shapes, event payloads, job arguments, file formats |
| public names | URLs, slugs, event and job names, token formats, ids shown to users |
| stored shape | tables and columns, enum values, how money and time are stored |
| ownership | who may read or change what, how a record is scoped to its user or organisation |

Each goes into **Locked Decisions** with a one-line reason.
`write-story` copies them verbatim; `story-refuter` checks the code against them.

## 3. The smallest cut that proves it

Scope to the smallest first version that proves the approach without closing doors.
Say explicitly what is **in** and what is **deferred**; deferred items go to Out of scope with the reason, so nobody builds them by accident.

## 4. Keep the abstraction above its first example

When the idea is general (a framework, a cross-cutting change, a provider-agnostic port), do not let the first concrete case become the design.
Name the core idea, then the example that motivated it, labelled as an example — unless the example *is* the whole scope.

## 5. One question, one place

Every decision that is not made yet lives in **Open Questions** at the end, never buried in prose.
Each entry: the question, the options, and a **recommended default** so work can continue if nobody answers.
Before hand-off, sweep once: anything that would change architecture, scope, stored data or rollout is either decided here with a reason or listed with its default.

## 6. Written for a stranger

The design is read later by agents that never saw this conversation: the blind-spot reviewer, the implementation advisor, the implementers.
So write it to stand alone — no "as we discussed", no "unlike the earlier version", no revision history.
When the scope changes, rewrite the affected section so it is still true on its own.

## 7. Show relationships, don't narrate them

Where a relationship is clearer drawn than described, put the picture into the design itself — one per decision, not decoration:

- a **Mermaid** diagram for architecture, data flow, a state machine or a sequence:
  ```mermaid
  flowchart LR
    UI -->|POST /exports| API --> Service --> Store[(DB)]
    Service -->|enqueue| Job --> Storage[(files)]
  ```
- a **table** for a data model (field → type → notes) or an endpoint contract (method and path → request → response → status codes);
- a **file tree** for what the change touches;
- a **before / after** pair when behaviour changes.

Group by layer or region rather than drawing one long chain, unless the flow really is a sequence.
These blocks stay in the design and travel into the story; screen mocks and the visual board are separate and live in their own folders.
