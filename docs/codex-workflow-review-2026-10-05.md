# Codex workflow review -- 5 Oct 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: 180c1a2 | Since: 241f2ee | Scope: Codex-lane sessions and Codex-specific friction through 4 Oct | Previous: none

## Follow-through

None -- no earlier `codex-workflow-review` record exists.

## Evidence

Session rollouts were summarised by a local parser; `cmd` is command-family/count,
and `read` is unique named paths/current KiB, not rollout content. `G` is a
guardian subagent, so it does not require a slice report. All 17 user sessions
ended with the End-of-slice fields; every `G` session appropriately did not.

| Session | UTC | Slice | cmd | failed exit | retry | read | End |
| --- | --- | --- | --- | --- | ---: | ---: | --- |
| 78a6f1d2 | 01 Oct 12:42-12:44 | PE-1 | git/py/ps/Godot/rg/read (8) | 4294967295 | 1 | 8/188 | Y |
| 892c683d G | 01 Oct 12:43 | -- | -- (0) | -- | 0 | 0/0 | N |
| 5770ad43 | 01 Oct 13:14-13:45 | PE-1 | git/py/ps/Godot/rg/read (69) | 4294967295 | 16 | 11/251 | Y |
| 0b524670 G | 01 Oct 13:38-13:45 | PE-1 | -- (0) | -- | 0 | 0/0 | N |
| faf45905 | 01 Oct 13:57-14:38 | PE-1/SF-2 | git/py/ps/Godot/rg/read (108) | 1,1 | 60 | 11/235 | Y |
| da01ef35 G | 01 Oct 14:37 | PE-1 | -- (0) | -- | 0 | 0/0 | N |
| 0117f3ea | 01 Oct 15:25-16:29 | BS-8 | git/py/ps/rg/read (45) | -- | 12 | 22/573 | Y |
| affaaec2 G | 01 Oct 15:26-16:22 | BS-8 | -- (0) | -- | 0 | 0/0 | N |
| 6c86cdd1 | 01 Oct 18:26-20:13 | BS-8 | git/py/ps/Godot/rg/read (67) | -- | 25 | 13/447 | Y |
| 83102763 G | 01 Oct 20:13 | -- | git (1) | -- | 0 | 0/0 | N |
| 3763b3e6 | 01 Oct 20:15-20:23 | -- | git/py/ps/rg/read (15) | -- | 0 | 11/296 | Y |
| 101b9e8d | 01 Oct 20:20-20:23 | -- | git/py/ps/read (11) | -- | 0 | 8/227 | Y |
| 833aee29 | 01 Oct 20:58-21:02 | -- | git/py/ps/Godot/rg/read (15) | -- | 0 | 16/579 | Y |
| 8da4305e | 01 Oct 21:50-02 Oct 05:50 | -- | git/py/ps/read (25) | 1,4294967295,1,1 | 0 | 20/553 | Y |
| fff73fbf G | 01 Oct 22:22-22:56 | -- | -- (0) | -- | 0 | 0/0 | N |
| 4556fc99 | 01 Oct 22:30-22:58 | -- | -- (0) | 417,1,1,1,1 | 0 | 0/0 | Y |
| e6147680 | 02 Oct 05:50-06:17 | SR-1 | git/py/ps/Godot/rg/read (85) | 280,570,1558 | 25 | 15/314 | Y |
| 4489141b | 02 Oct 12:00-12:29 | SR-2 | git/py/ps/Godot/rg/read (86) | -- | 54 | 15/398 | Y |
| 816effad | 02 Oct 14:27-03 Oct 12:40 | SR-3 | git/py/ps/rg/read (56) | -- | 17 | 15/321 | Y |
| d3463df1 G | 02 Oct 14:46-16:59 | SR-3 | -- (0) | -- | 0 | 0/0 | N |
| 5b8a3083 | 03 Oct 12:40-17:08 | SR-5 | git/py/ps/Godot/rg/read (107) | 1 | 44 | 19/455 | Y |
| d6edc5c5 G | 03 Oct 12:41 | -- | -- (0) | -- | 0 | 0/0 | N |
| b5cd3e14 | 04 Oct 21:05-21:17 | SR-5 | git/py/ps/rg/read (25) | -- | 1 | 11/184 | Y |
| d33f1294 | 04 Oct 21:26-21:47 | GC-3 | git/py/ps/Godot/rg/read (64) | -- | 12 | 22/609 | Y |

`python tools/session_cost.py --events --stops`: 217 stops, 119 in a step;
51 were lifecycle-busy. The largest stop steps were primary verification (26),
branch verification (22), Claude archive/delete (20), and archive gate (16).
`tools/slice.ps1 doctor -Lane Codex` found the expected clean GC-3 worktree
one commit ahead, plus blocked remote reachability. `codex sandbox -P meadow --
Godot_console.exe ...` stopped before Godot: `Could not find home directory`.

## Findings

| Id | Finding | Evidence | Severity | Disposition |
| --- | --- | --- | --- | --- |
| F1 | Nine Codex slices (PE-1, BS-8, UI-F-1..3, SR-1..3, SR-5) merged, archived, and refilled their lane; GC-3 is correctly open and clean. | `git log --merges 241f2ee..HEAD --grep=codex/`; merge first-parent file lists; `doctor -Lane Codex` | low | Fixed -- the landed records and current preflight prove the lifecycle outcomes. |
| F2 | Closeout contention recurs (51 lifecycle-busy stops); it is not a Codex-only queue defect. | `session_cost.py --stops`; `agent-lifecycle.md` L-19 | high | Queued -- L-19 in `plans/now/agent-lifecycle.md` owns lock ordering and re-apply. |
| F3 | The sandbox probe cannot reproduce a Godot denial: profile resolution fails before launch. Historical user sessions contain three `4294967295` exits and two tempfile timeouts; no captured `0x58`. | rollout summary; `codex sandbox -P meadow -- ...`; session 78a6f1d2/5770ad43 | medium | Rejected -- changing sandbox/home/profile configuration needs Dave's explicit decision; no safe fix can be inferred. |
| F4 | PE-1 (medium) and SR-1..3 (low) used high-reasoning sessions; SR-5 (medium) did too. No plan forced a missing design decision. | rollout `turn_context.effort`; archived slice `Level:` lines | medium | Rejected -- `CLAUDE.md` rule 4 and `CHATGPT.md` already make the planned level a cap; caller-selected model effort is outside the slice. |
| F5 | `CHATGPT.md` says to archive/refill before `finish`, but `closeout.md` says `finish` performs both. | `CHATGPT.md` closeout paragraph; `closeout.md` “Closeout order” | medium | Queued -- L-20 in `plans/archive/codex-guidance_2026-10-13.md`, low. |

## Hand-offs

- agent-workflow-review: shared lifecycle contention, remote reachability, the short Codex lane, and the Claude archive/delete stop cost remain shared queue/check work; L-19 is already queued.

## Noted, not pursued

- No `0x58` denial was captured before this review; `4294967295` is a concurrent-session kill, not a Godot crash.
- `CHATGPT.md` already routes its end report to CLAUDE's complete template; it is not missing verification, risk, or report rules.

## Not reviewed

Claude lane, shared queue admission, checks, and Claude plans.

## Patterns deliberately not applied

No sandbox-profile change: the probe cannot resolve its home, and changing that configuration requires Dave's decision.
