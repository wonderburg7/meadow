"""Choose Meadow's headless run class from five explicit facts.

This helper deliberately has no project-state knowledge and never calls a
model.  Callers decide the five facts, then receive a small reproducible
execution policy without reconstructing it from plans or runner history.
"""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass


ROUTING_CARD = """1. Can Python/source checks answer without real Godot behaviour? Use them and stop.
2. Is a mid-run judgement impossible to express as semantic actions, triggers or assertions? Use checkpointed AI.
3. One deterministic command/mechanism check: use verdict with one pinned seed.
4. Randomness or a comparison: use experiment with three matched seeds; use five only if three disagree or are near threshold.
5. Need a time series: use trend with a named snapshot profile; otherwise summary-only capture.
6. Expected wall time over 30 seconds: add background.
7. On failure, rerun only the failed seed with one targeted diagnostic profile; do not expand successful runs."""


class RouteError(ValueError):
    """The supplied facts cannot describe a supported route."""


@dataclass(frozen=True)
class RouteFacts:
    needs_godot: bool
    adaptive: bool
    comparison: str
    time_series: bool
    expected_seconds: float


@dataclass(frozen=True)
class Route:
    run_class: str
    capture: str
    seeds: str
    background: bool
    report: str
    matched_rules: tuple[str, ...]

    def line(self) -> str:
        return ("route=%s capture=%s seeds=%s background=%s report=%s" % (
            self.run_class, self.capture, self.seeds,
            "yes" if self.background else "no", self.report,
        ))


def choose_route(facts: RouteFacts) -> Route:
    """Map explicit facts to one stable route, rejecting contradictions."""
    if facts.comparison not in {"none", "stochastic", "paired"}:
        raise RouteError("comparison must be none, stochastic or paired")
    if not math.isfinite(facts.expected_seconds) or facts.expected_seconds < 0:
        raise RouteError("expected_seconds must be a finite non-negative number")
    if facts.adaptive and not facts.needs_godot:
        raise RouteError("adaptive=yes requires needs_godot=yes")

    background = facts.expected_seconds > 30
    if not facts.needs_godot:
        return Route("python", "none", "n/a", background, "verdict", (
            "needs_godot=no: use Python/source checks and stop",
        ))
    if facts.adaptive:
        return Route("checkpointed", "targeted", "as-designed", background, "packet", (
            "adaptive=yes: scripted scenarios are insufficient",
        ))
    if facts.time_series:
        seeds = "3" if facts.comparison != "none" else "1"
        rule = "time_series=yes: use a named balance snapshot profile"
        if facts.comparison != "none":
            rule += " with matched seeds"
        return Route("trend", "balance", seeds, background, "table", (rule,))
    if facts.comparison != "none":
        return Route("experiment", "behaviour", "3", background, "verdict", (
            "comparison=%s: use three matched seeds" % facts.comparison,
        ))
    return Route("verdict", "verdict", "1", background, "verdict", (
        "one scripted Godot check: use one pinned seed",
    ))


def _yes_no(value: str) -> bool:
    return value == "yes"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--needs-godot", required=True, choices=("yes", "no"))
    parser.add_argument("--adaptive", required=True, choices=("yes", "no"))
    parser.add_argument("--comparison", required=True, choices=("none", "stochastic", "paired"))
    parser.add_argument("--time-series", required=True, choices=("yes", "no"))
    parser.add_argument("--expected-seconds", required=True, type=float)
    parser.add_argument("--explain", action="store_true", help="print the matched rule after the route")
    args = parser.parse_args(argv)
    try:
        route = choose_route(RouteFacts(
            needs_godot=_yes_no(args.needs_godot),
            adaptive=_yes_no(args.adaptive),
            comparison=args.comparison,
            time_series=_yes_no(args.time_series),
            expected_seconds=args.expected_seconds,
        ))
    except RouteError as error:
        parser.error(str(error))
    print(route.line())
    if args.explain:
        for rule in route.matched_rules:
            print("rule=%s" % rule)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
