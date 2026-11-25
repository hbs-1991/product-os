---
name: research-protocol
description: "Shared protocol for evidence-based research in the product-os discovery chain. Load it before any web/market/user/UX/technical research, whenever create-product-brief, create-prd, create-ux-design or create-architecture spawn research subagents, and when brainstorming researches external facts for a feature. Defines the research firewall (never conclude from training data, project context shapes questions not facts), the cited-digest rule, research types, the subagent brief template and the shared .memlog.md."
---

# Research protocol

Adapted from BMad's `bmad-deep-recon`. Research here serves a **decision**, not curiosity: name the decision first ("which stack", "which journeys are core", "which visual direction"), then research only what changes it.

## Standing rules (also inherited by every research subagent you spawn)

1. **Never conclude from training data alone.** What you already know proposes hypotheses and queries; a conclusion needs evidence retrieved *this run* (WebSearch / WebFetch, official docs, the repo itself). Unevidenced claim = stated as "unverified belief" or dropped. This matters most for AI, frameworks and versions: your knowledge ages by the month.
2. **The research firewall.** Project context (brief, PRD, repo, owner's opinions) shapes *what to ask*, never *what is true*. It is not evidence. A research subagent gets only its brief (question, decision, freshness window) and no project files unless you grant one by name.
3. **A claim is a sentence with a source**: publisher, publication date, access date. No naked numbers. A market figure older than ~18 months, a library version older than the latest release: mark it stale.
4. **Report what is real.** Thin public data is reported as thin; absence of evidence is a finding.
5. **Extract, don't ingest.** Raw pages and long reports never enter the main context. Subagents return a digest (≤ ~300 words: findings, sources with dates, confidence, gaps); the main agent reads digests.
6. **Nothing exists until it is a file.** Each digest is saved when it lands: to `<repo>\.plans\product\research\<topic>.md` in the discovery chain, to `<repo>\.plans\research\YYYY-MM-DD-<topic>.md` for a single feature.

## Types

| Type | Question it answers | Typical use |
|---|---|---|
| `landscape` | What exists in this space, how do comparables position themselves? | brief |
| `user-flow` | How do comparable products walk the end user through the core flows? Steps, friction, drop-off points, what users complain about | prd |
| `user-voice` | What do real users say (reviews, forums, support threads, Reddit/HN) about the problem and the alternatives? | brief, prd |
| `ux-pattern` | Which interaction and visual patterns do the best current products use for this kind of screen; which UI systems exist | ux |
| `technical` | Which stack / starter / service fits these constraints; current versions, maturity, pricing, limits, known pitfalls | architecture, feature |
| `choice` | Candidates A/B/C compared on named criteria with evidence | any, incl. feature |

## Subagent brief (fill and send via the Agent tool, `general-purpose`, run independent ones in parallel)

```text
Research question: <one question>
The decision it feeds: <decision>
Type: <type>   Freshness window: <e.g. last 12 months; versions: latest release>
Use web search. Do not rely on memory for facts. Do not read project files.
Return a digest (<=300 words): 1) findings, each with source + publication date,
2) confidence per finding (high/med/low), 3) what you could not find, 4) contradictions between sources.
Save nothing; return text only.
```

The main agent saves each digest as a file (rule 6), tags it `[source]` in the memlog, and cites it by filename in the document it feeds.
A feature has no memlog: its digests are cited by filename in the design and, later, under the story's References.

## Memlog

`<repo>\.plans\product\.memlog.md` is the shared working memory of the discovery chain: one append-only line per decision, e.g.
`- 2026-10-12 [prd] decision: journeys ranked by weight; UJ-1 core, UJ-4 edge (reason: ...)`.
Types: `decision | assumption | question | constraint | version | source | event`.
The documents are **distilled from it at the end**, not written as you go; anything not logged is lost on resume.
Append with `echo "- <date> [<doc>] <type>: <text>" >> <path>` (never rewrite the file).
