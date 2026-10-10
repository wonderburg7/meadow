# Check runner -- one filed hands-on check, run by a subagent

<!-- CONTEXT: reference | LAYER: reference | LOAD: by a check-runner subagent, a check pass that dispatches one, or a session filing a check -->
Status: reference | Owner: Dave / Claude Code | Next: tune the runner choices from the first pass that dispatches by Runner line | Dependency: none | Verified: 2026-10-10

You are a `check-runner` subagent (`check-runner-haiku`, `check-runner` or
`check-runner-opus`; the brief is the same). A hands-on check pass has handed
you `ROOT` (the primary checkout's absolute path) and one check id. You run
that one check with computer use and return a verdict. The pass records it
and asks Dave anything open; you never talk to Dave. The last two sections
are for the pass and for whoever files a check, not for you.

## Inputs and reading

- Read only the check's own file under `ROOT/checks/ready/` (find it by id).
  Read nothing else in `checks/`, and no plans.
- Do what its "What this checks" says, and judge by its pass condition. Its
  `Runner:` line is for the pass that dispatched you; ignore it.

## Launching and driving the game

- Computer-use access name: `Godot.exe`.
- Launch as the check says. If that fails, launch from Git Bash, from `ROOT`:
  `"/c/Program Files/Godot/Godot.exe" --path .`
- Never press "Back to the run" on a fresh boot.
- A 1-2 s lag in screen captures, and a few pixels of click offset, are tool
  artefacts, not findings. Retake the capture before judging.
- A synthetic Escape is no evidence. If the check needs a real key press (or
  anything only Dave's keyboard or eye can confirm), do not guess: return
  `cannot-run` and say what is needed in `needs_dave`.
- Close the game before you return.

## Limits

- Never edit `checks/`, never run `tools/new_check.py`, never ask Dave
  anything. The check pass does those.
- Keep screenshots few: take one when the check's condition is on screen,
  not after every click.

## What you return

Your final message is only this JSON, no prose around it:

```json
{"id": "C-<n>", "verdict": "pass|fail|cannot-run", "evidence": "<one sentence of what was on screen>", "needs_dave": "<what only Dave's keyboard or eye can confirm, or empty>"}
```

`cannot-run` means the check could not be run honestly (needs a real key,
the game would not launch, the screen never showed the condition); say which
in `evidence`.

## Dispatching a pass (the coordinating session, not the runner)

The coordinator can be Opus: it holds only one JSON verdict per check, never
a screenshot, so its context stays small. For each check in
`checks/ready.md`, read only that check's `Runner:` line
(`grep -h "^Runner:" checks/ready/C-<n>.md`) and:

| Runner | Do |
| --- | --- |
| `haiku` | dispatch `check-runner-haiku` |
| `sonnet` | dispatch `check-runner` |
| `opus` | dispatch `check-runner-opus` |
| `dave` | dispatch nothing; list it for Dave with its "What this checks" line |
| missing | treat as `sonnet` |

Pass `ROOT` and the check id, one check per dispatch, one dispatch at a time
(two runners would fight over one screen and one Godot window). Record a
`pass` as it comes. A `fail` or `cannot-run` from `haiku` or `sonnet` with an
empty `needs_dave` is re-run once by `check-runner-opus` before you report it.
Its verdict stands, because a false fail costs Dave a re-diagnosis. A verdict
that names `needs_dave` goes straight to Dave. When an `opus` re-run passes
what a cheaper runner failed, note that the check's `Runner:` line should be
raised.

## Choosing a runner (filing a check)

`python tools/new_check.py ... --runner <haiku|sonnet|opus|dave>` writes the
line; add ` -- <why>` after it. Choose the cheapest runner that can judge the
PASS line from still screenshots:

- `haiku`: navigate menus and read text that is plainly there, or plainly not.
- `sonnet`: the default. Several steps, settings changes, save/load or
  restarts, and judging clipped text or layout on panels that stand still.
- `opus`: a long playthrough (a winter, a gyne's life), timing across the
  1-2 s capture lag, precise input (a window-corner drag, clicking a moving
  bee), or a fine visual judgement such as whether one colour reads apart from
  another.
- `dave`: physical keys (a synthetic key is no evidence), motion that stills
  cannot show (shimmer, paths over time), or a perceptual or feel judgement
  ("at a glance", "without guessing").
