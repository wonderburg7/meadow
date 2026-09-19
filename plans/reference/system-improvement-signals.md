# System-improvement signal contract

<!-- CONTEXT: plan | LAYER: reference -->

Status: active | Owner: Dave / implementation sessions | Next: use the observation intake and promote only triaged findings | Dependency: `plans/observations/system-improvement-signals.md` | Verified: 2026-09-19

## Contract

The committed observation intake at
`plans/observations/system-improvement-signals.md` is Meadow's single place
for durable, evidence-backed suggestions to improve the development system.
It deliberately has a different audience and format from the local,
automatically-written `meadow-diagnostics.jsonl` workflow event stream.

An implementation session may append a compact signal when it finds material
cross-slice friction. It does not need to conduct a retrospective, invent an
improvement, or act on a signal during the assigned slice. The signal must
remain concise, link evidence, and state a disposition.

Only a deliberate planning review promotes a signal. Promotion verifies the
finding is still true and puts the resulting work in exactly one of
`plans/reference/`, `plans/design/`, or `plans/now/`. The source entry keeps
the link and its final disposition, so later reviews can distinguish an
implemented decision from a discarded hypothesis.

## Reopening criterion

Revisit this contract only when the intake becomes difficult to triage,
duplicates another durable planning record, or repeated implementation
sessions show that its entry format omits essential evidence. Do not broaden
the workflow diagnostic event schema to accommodate narrative observations.
