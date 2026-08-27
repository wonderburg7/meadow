#!/usr/bin/env python3
"""Render the compact, reviewable verdict for a foraging experiment run."""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

METRICS = ("flower_visits", "unique_flowers_visited", "orientation_flights",
           "scouting_settled", "recruitment_matches", "forager_deliveries",
           "forager_delivery_amount", "stall_recoveries", "flowers_senesced", "runtime_seconds")


def _mean(values: list[float]) -> float:
	return round(sum(values) / len(values), 4) if values else 0.0


def _summary(run: dict[str, Any], root: Path) -> dict[str, Any]:
	result_path = root / run["result"]
	result = json.loads(result_path.read_text(encoding="utf-8"))
	summary = json.loads((result_path.parent / "report.json").read_text(encoding="utf-8"))["summary"]
	summary["runtime_seconds"] = result.get("process", {}).get("wall_seconds", 0.0)
	return summary


def _metrics(rows: list[dict[str, Any]]) -> dict[str, Any]:
	result: dict[str, Any] = {}
	for metric in METRICS:
		values = [float(row.get(metric, 0.0)) for row in rows]
		result[metric] = {"mean": _mean(values), "min": min(values), "max": max(values)}
	starvation = [float(row.get("deaths_by_cause", {}).get("starvation", 0)) for row in rows]
	result["starvation_deaths"] = {"mean": _mean(starvation), "min": min(starvation), "max": max(starvation)}
	return result


def _handling(rows: list[dict[str, Any]]) -> dict[str, Any]:
	buckets: dict[str, dict[str, float]] = defaultdict(lambda: {"visits": 0.0, "seconds": 0.0})
	for row in rows:
		for bucket, values in row.get("handling_by_experience", {}).items():
			buckets[bucket]["visits"] += float(values.get("visits", 0))
			buckets[bucket]["seconds"] += float(values.get("seconds", 0.0))
	return {bucket: {"visits": int(values["visits"]), "average_seconds": round(values["seconds"] / values["visits"], 4) if values["visits"] else None}
		for bucket, values in sorted(buckets.items())}


def main(argv: list[str]) -> int:
	if len(argv) != 2:
		print("usage: foraging_evidence_report.py <experiment-result.json>", file=sys.stderr)
		return 2
	result_path = Path(argv[1]).resolve()
	experiment = json.loads(result_path.read_text(encoding="utf-8"))
	root = result_path.parent
	cases: dict[str, Any] = {}
	not_exercised: list[str] = []
	for name, runs in experiment["cases"].items():
		rows = [_summary(run, root) for run in runs if run["status"] == "passed"]
		case = {"runs": len(rows), "metrics": _metrics(rows) if rows else {}, "handling_by_experience": _handling(rows)}
		cases[name] = case
		if name != "no_automation" and rows and case["metrics"]["recruitment_matches"]["mean"] == 0:
			not_exercised.append("%s recruitment" % name)
		if name == "senescence_on" and rows and case["metrics"]["flowers_senesced"]["mean"] == 0:
			not_exercised.append("senescence lifecycle")
		if name == "handling_experience" and rows and not case["handling_by_experience"]:
			not_exercised.append("handling experience")
	verdict = {"schema_version": 1, "experiment": experiment["name"], "status": experiment["status"],
			   "seeds": experiment["seeds"], "cases": cases, "not_exercised": not_exercised}
	output = root / "foraging-evidence-verdict.json"
	output.write_text(json.dumps(verdict, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	print("status=%s verdict=%s" % (experiment["status"], output))
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
