# Blind-spot pass — the handoff

The fourth quadrant of the Unknowns Matrix (unknown unknowns) is run by the **`blind-spot-reviewer`** agent.
Its method and checklists live in the agent itself (`agents/blind-spot-reviewer.md` in this plugin, or the repository's own `.claude/agents/blind-spot-reviewer.md` when it has one — that one wins).

The agent must NOT receive the brainstorming conversation.
Its value comes from not sharing the owner's and the orchestrator's assumptions.

## Launch

Agent tool, `subagent_type: "product-os:blind-spot-reviewer"` (or the repo's own agent), with exactly this prompt:

```text
REPO: <absolute path of the repository>

<design>
(the draft design, verbatim — Locked Decisions, data flow, what is in and out of the first cut)
</design>
```

Nothing else: no summary of the discussion, no "we already considered X", no hint about which parts were contested.
If the design spans several repositories, list each path on its own `REPO:` line.

**Fallback** — the agent is not in the session's agent list: launch `subagent_type: "general-purpose"` with a prompt that states the reviewer's job (find circumstances the author most likely did not consider: other consumers, existing production data, rollout and reversal, failure paths, tenancy, money, time, people and process; read-only; report each finding with evidence from the repo) followed by the handoff above — still without the conversation.

## When it comes back

Triage every finding with the owner, as `SKILL.md` §6 says: addressed / out of scope / open question / not real.
