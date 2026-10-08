# Guidance explanations -- turn colony facts into a causal player answer

<!-- CONTEXT: plan | LAYER: active -->
Status: active | Owner: Dave / Codex | Next: GD-1 -- decide the causal-explanation contract | Dependency: CD-2 provides the first missing-workforce and blocked-work facts; no guidance UI ships before the contract | Verified: 2026-10-08

## Objective

Design the first-encounter and persistent “Why is this happening?” route the
product scope requires, without making Dr Gallerin a second simulation owner
or prescribing a single colony organisation.

## Current state

The panel can schedule and retain prompts, but its own source says ordinary
runs feed it no real prompts. Existing warnings know symptoms, not a stable
causal explanation contract.

## Open slices

| Slice | What it does | Files it owns | Startable | Level |
| --- | --- | --- | --- | --- |
| GD-1 | choose facts, trigger policy, history and presentation boundary | this plan, `plans/design/product-scope.md` | yes | high |
| GD-2 | implement the accepted persistent entry point and first explanations | specified by GD-1 | after Dave accepts GD-1 | high |

## GD-1 -- decide the causal-explanation contract

<!-- LAYER: immediate-task -->

Produce one decision record with options and costs for: which diagnostic facts
may trigger guidance, when a first encounter becomes shown, how history is
reopened, and how explanations offer responses without declaring a required
organisation. It may update the scope link but changes no runtime code.

```queue
**[Codex] GD-1 -- decide the causal-explanation contract**
- Plan: `plans/now/guidance-explanations.md` -- "GD-1 -- decide the causal-explanation contract"
- Files: `plans/now/guidance-explanations.md`, `plans/design/product-scope.md`
- Check: `python tools/check_docs.py` passes and GD-1 records one owner for facts, trigger policy and presentation
- Proof: `present: scripts/gallerin_panel.gd :: Nothing feeds it real prompts yet`
- Next after: GD-2 -- implement the accepted persistent entry point and first explanations
```

## GD-2 -- implement the accepted persistent entry point and first explanations

<!-- LAYER: immediate-task -->

Specified only after GD-1 records Dave's decision; it must consume diagnostics
and preserve the existing Challenge prompt flow.

```queue-gated
**[Codex] GD-2 -- implement the accepted persistent entry point and first explanations**
- Plan: `plans/now/guidance-explanations.md` -- "GD-2 -- implement the accepted persistent entry point and first explanations"
- Files: specified by GD-1
- Check: specified by GD-1
- Proof: `present: plans/now/guidance-explanations.md :: ## GD-1 -- decide the causal-explanation contract`
- Next after: none -- guidance explanations are complete
```
