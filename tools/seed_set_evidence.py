"""Measure paired seed-set effects; all generated artefacts stay outside Git."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile

from analyze_session import load_entries
from godot_compile_check import find_godot
import run_scenario as runner

ROOT = Path(__file__).resolve().parent.parent
SEEDS = (12345, 7, 2026, 90210, 555)
SPECIES = ("Clover", "Borage", "Foxglove", "Poppy", "Bramble", "Dandelion")
SPECIALISTS = ("Clover", "Borage")
PROVENANCE_KEYS = ("baseline_commit", "reporter_sha256", "fixture_sha256", "engine_version",
                   "fixed_fps", "controls")



def number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError("missing or invalid numeric measurement")
    return value


def species_index(value):
    value = number(value)
    if int(value) != value or not 0 <= value < len(SPECIES):
        raise ValueError("invalid species index")
    return int(value)


def aggregate_arm(entries, save, result, scenario, end_day=10):
    """Reject incomplete evidence before counting any observed events."""
    if result.get("status") != "passed" or result.get("process", {}).get("exit_code") != 0:
        raise ValueError("failed or missing arm")
    if result.get("actions") != {"rejected": 0, "failed": 0, "unresolved": 0}:
        raise ValueError("unresolved actions")
    if not entries or any(not isinstance(e, dict) or "type" not in e for e in entries):
        raise ValueError("malformed session entry")
    summaries = [e for e in entries if e["type"] == "summary"]
    if len(summaries) != 1 or entries[-1] != summaries[0]:
        raise ValueError("missing final summary")
    summary = summaries[0]
    elapsed = number(summary.get("game_time"))
    if (summary.get("outcome") != "actions_resolved" or number(summary.get("day")) != end_day
            or elapsed < (end_day - 1) * scenario["config_overrides"]["seconds_per_day"]):
        raise ValueError("incomplete endpoint coverage")
    clock = save.get("clock", {})
    if number(clock.get("day")) != end_day or not math.isclose(number(clock.get("sim_time")), elapsed, abs_tol=1e-6):
        raise ValueError("end save does not match the session endpoint")
    expected = Counter(a["do"] for a in scenario["actions"])
    completed = Counter()
    eligible = deaths = 0
    replacements = Counter(seed=0, seasonal=0)
    for e in entries:
        if e["type"] != "action":
            continue
        do = e.get("do")
        if do in expected:
            if e.get("result") != "accepted":
                raise ValueError("action did not complete")
            completed[do] += 1
        if do not in ("pollination_withered", "pollination_replant"):
            continue
        if e.get("result") != "recorded" or not 0 <= number(e.get("game_time")) <= elapsed:
            raise ValueError("malformed pollination event")
        detail = json.loads(e["reason"])
        if not isinstance(detail, dict):
            raise ValueError("malformed pollination payload")
        index = species_index(detail.get("species_index"))
        if do == "pollination_withered":
            if e.get("target") != SPECIES[index] or type(detail.get("sets_seed")) is not bool:
                raise ValueError("malformed flower death")
            if detail.get("seed_set_on") is not scenario["seed_set"]:
                raise ValueError("wrong seed-set arm")
            for key in ("compatible_visits", "incompatible_visits"):
                if number(detail.get(key)) < 0 or int(detail[key]) != detail[key]:
                    raise ValueError("invalid pollen count")
            deaths += 1
            eligible += int(detail["sets_seed"])
        else:
            kind = e.get("target")
            if kind not in replacements or detail.get("species") != SPECIES[index]:
                raise ValueError("malformed replacement")
            replacements[kind] += 1
    if completed != expected:
        raise ValueError("missing completed scenario actions")
    counts = dict.fromkeys(SPECIES, 0)
    if not isinstance(save.get("flowers"), list):
        raise ValueError("missing end-save flowers")
    for flower in save["flowers"]:
        counts[SPECIES[species_index(flower["species"])]] += 1
    total = sum(counts.values())
    return {"elapsed_seconds": elapsed, "eligible_deaths": eligible, "all_deaths": deaths,
            "seed_replacements": replacements["seed"], "seasonal_replacements": replacements["seasonal"],
            "live_by_species": counts, "live_total": total,
            "clover_share": counts["Clover"] / total if total else None}


def count_map(value):
    if not isinstance(value, dict) or set(value) - set(SPECIES):
        raise ValueError("invalid species counts")
    counts = dict.fromkeys(SPECIES, 0)
    for species, count in value.items():
        if number(count) < 0 or int(count) != count:
            raise ValueError("invalid species count")
        counts[species] = int(count)
    return counts


def snapshot(save):
    counts = Counter(SPECIES[species_index(f["species"])] for f in save["flowers"])
    counts = count_map(dict(counts))
    total = sum(counts.values())
    bank = save.get("seed_bank", {})
    return {"live_by_species": counts, "clover_share": counts["Clover"] / total if total else None,
            "seed_counts": count_map(bank.get("seed_counts")),
            "spring_counts": count_map(bank.get("spring_counts"))}


def difference(after, before):
    return {key: ({s: after[key][s] - before[key][s] for s in SPECIES}
                  if isinstance(after[key], dict) else
                  None if after[key] is None or before[key] is None else after[key] - before[key])
            for key in after}


def aggregate_spring(entries, summer, spring, result, scenario):
    row = aggregate_arm(entries, spring, result, scenario, 25)
    config = scenario["config_overrides"]
    day = config["seconds_per_day"]
    start = (config["season_length_days"] + config["winter_length_days"]) * day
    end = start + config["spring_regrowth_days"] * day
    summer_time = number(summer.get("clock", {}).get("sim_time"))
    if number(summer["clock"].get("day")) != 10 or not 9 * day <= summer_time < config["season_length_days"] * day:
        raise ValueError("summer save outside pre-winter phase")
    if row["elapsed_seconds"] < end:
        raise ValueError("incomplete spring regrowth")
    last = -1
    rolls = []
    replacements = dict.fromkeys(SPECIES, 0)
    weights = []
    save_times = []
    for entry in entries:
        if entry.get("type") != "action":
            continue
        t = number(entry.get("game_time"))
        if t < last or t > row["elapsed_seconds"]:
            raise ValueError("non-forward event timeline")
        last = t
        do = entry.get("do")
        if do == "save_run":
            save_times.append(t)
        if do == "pollination_spring":
            if entry.get("result") != "recorded" or not start <= t < end:
                raise ValueError("spring rollover outside regrowth")
            rolls.append(count_map(json.loads(entry["reason"]).get("spring_counts")))
        if do == "pollination_replant" and start <= t < end:
            detail = json.loads(entry["reason"])
            replacements[SPECIES[species_index(detail["species_index"])]] += 1
            if entry["target"] == "seed":
                continue
            values = detail.get("weights")
            if not isinstance(values, list) or len(values) != len(SPECIES) or any(number(v) < 0 for v in values):
                raise ValueError("missing spring draw weights")
            weights.append(tuple(values))
    if save_times != [summer_time, row["elapsed_seconds"]] or len(rolls) != int(scenario["seed_set"]) or not weights:
        raise ValueError("incomplete spring coverage")
    row["summer"] = snapshot(summer)
    row["spring"] = snapshot(spring)
    rollover = rolls[0] if rolls else dict.fromkeys(SPECIES, 0)
    if row["spring"]["spring_counts"] != rollover:
        raise ValueError("spring bank does not match rollover")
    row["summer_to_spring"] = difference(row["spring"], row["summer"])
    row["spring_replacements"] = replacements
    row["spring_weights"] = {s: {"min": min(w[i] for w in weights), "max": max(w[i] for w in weights)}
                             for i, s in enumerate(SPECIES)}
    row["spring_rollover_counts"] = rollover
    return row


def spring_report(rows, seeds=SEEDS):
    report = paired_report(rows, seeds)
    pairs = []
    for seed in seeds:
        arms = {r["arm"]: r for r in rows if r["seed"] == seed}
        pair = {"seed": seed}
        for phase in ("summer", "spring", "summer_to_spring"):
            pair[phase] = difference(arms["on"][phase], arms["off"][phase])
        pair["spring_replacements"] = {s: arms["on"]["spring_replacements"][s] - arms["off"]["spring_replacements"][s] for s in SPECIES}
        pairs.append(pair)
    def summarise(values):
        first = values[0]
        if isinstance(first, dict):
            return {key: summarise([v[key] for v in values]) for key in first if key != "seed"}
        values = [v for v in values if v is not None]
        return {"n": len(values), "median": statistics.median(values) if values else None,
                "min": min(values) if values else None, "max": max(values) if values else None}
    report["spring_on_minus_off"] = pairs
    report["spring_paired_summary"] = summarise(pairs)
    report["within_arm_summary"] = {arm: summarise([r["summer_to_spring"] for r in rows if r["arm"] == arm]) for arm in ("off", "on")}
    return report


def paired_report(rows, seeds=SEEDS):
    pairs = []
    for seed in seeds:
        arms = [r for r in rows if r["seed"] == seed]
        if len(arms) != 2 or {r["arm"] for r in arms} != {"on", "off"}:
            raise ValueError("missing or duplicate paired arm")
        by_arm = {r["arm"]: r for r in arms}
        on, off = by_arm["on"], by_arm["off"]
        pairs.append({"seed": seed, "seed_replacements": on["seed_replacements"] - off["seed_replacements"],
                      "clover_share": None if on["clover_share"] is None or off["clover_share"] is None
                      else on["clover_share"] - off["clover_share"]})
    if len(rows) != 2 * len(seeds):
        raise ValueError("unexpected arms")
    summaries = {}
    for metric in ("seed_replacements", "clover_share"):
        values = [p[metric] for p in pairs if p[metric] is not None]
        summaries[metric] = {"n": len(values), "median": statistics.median(values) if values else None,
                             "min": min(values) if values else None, "max": max(values) if values else None}
    return {"rows": rows, "on_minus_off": pairs, "paired_summary": summaries}


def summarise_tree(values):
    first = values[0]
    if isinstance(first, dict):
        return {k: summarise_tree([v[k] for v in values]) for k in first if k != "seed"}
    defined = [number(v) for v in values if v is not None]
    return {"n": len(defined), "median": statistics.median(defined) if defined else None,
            "min": min(defined) if defined else None, "max": max(defined) if defined else None}


def specialist_snapshot(value):
    counts = count_map(value["live_by_species"])
    total = sum(counts.values())
    return {"live_by_species": counts,
            "shares": {s: counts[s] / total if total else None for s in SPECIES},
            "seed_counts": count_map(value["seed_counts"]),
            "spring_counts": count_map(value["spring_counts"])}


def specialist_difference(after, before):
    if isinstance(after, dict):
        return {key: specialist_difference(value, before[key]) for key, value in after.items()}
    return None if after is None or before is None else number(after) - number(before)


def specialist_report(rows, provenance, seeds=SEEDS):
    """Validate a matched four-treatment matrix before calculating contrasts."""
    if not seeds or len(set(seeds)) != len(seeds):
        raise ValueError("invalid campaign seeds")
    if any(not provenance.get(k) for k in PROVENANCE_KEYS) or provenance["fixed_fps"] != 30:
        raise ValueError("missing or incompatible campaign provenance")
    expected = {(seed, s, arm) for seed in seeds for s in SPECIALISTS for arm in ("off", "on")}
    matrix = {}
    reported_rows = []
    for row in rows:
        key = (row.get("seed"), row.get("specialist"), row.get("arm"))
        if type(row.get("seed")) is not int or key not in expected or key in matrix:
            raise ValueError("missing, duplicate or mislabeled specialist arm")
        if (row.get("treatment") != {"specialist": key[1], "seed_set": key[2] == "on"}
                or type(row["treatment"].get("seed_set")) is not bool):
            raise ValueError("mislabeled treatment")
        scenario = row.get("scenario")
        wanted = dict(provenance["controls"], random_seed=key[0], forager_species=key[1], seed_set=key[2] == "on")
        if scenario != wanted or type(scenario.get("seed_set")) is not bool:
            raise ValueError("incompatible scenario controls or treatment")
        if row.get("provenance") != {k: provenance[k] for k in PROVENANCE_KEYS}:
            raise ValueError("incompatible arm provenance")
        value = {phase: specialist_snapshot(row[phase]) for phase in ("summer", "spring")}
        value["summer_to_spring"] = specialist_difference(value["spring"], value["summer"])
        value["spring_replacements"] = count_map(row["spring_replacements"])
        matrix[key] = value
        reported_rows.append(dict(row, **value))
    if set(matrix) != expected:
        raise ValueError("missing specialist arms")
    pairs = {s: [] for s in SPECIALISTS}
    contrasts = []
    for seed in seeds:
        for s in SPECIALISTS:
            pairs[s].append(dict(specialist_difference(matrix[seed, s, "on"], matrix[seed, s, "off"]), seed=seed))
        contrasts.append(dict(specialist_difference(
            {k: v for k, v in pairs["Borage"][-1].items() if k != "seed"},
            {k: v for k, v in pairs["Clover"][-1].items() if k != "seed"}), seed=seed))
    coverage = {s: any(r["seed_events_by_species"][s] > 0 for r in rows) for s in SPECIES}
    limitations = ["Descriptive controlled comparisons, not confidence intervals; matched seeds do not "
                   "guarantee identical random draws after treatments diverge."]
    limitations += [f"No {s} seed events observed." for s, present in coverage.items() if not present]
    biological_coverage = {
        "eligible": any(r["eligible_deaths"] > 0 for r in rows),
        "ineligible": any(r["all_deaths"] > r["eligible_deaths"] for r in rows),
        "seed_replacements": any(r["seed_replacements"] > 0 for r in rows),
        "seasonal_replacements": any(r["seasonal_replacements"] > 0 for r in rows)}
    limitations += [f"No {key} coverage observed." for key, present in biological_coverage.items() if not present]
    return {"rows": reported_rows, "provenance": provenance, "specialist_on_minus_off": pairs,
            "specialist_paired_summary": {s: summarise_tree(pairs[s]) for s in SPECIALISTS},
            "borage_minus_clover_effect": contrasts, "contrast_summary": summarise_tree(contrasts),
            "within_arm_summary": {s: {arm: summarise_tree(
                [matrix[seed, s, arm]["summer_to_spring"] for seed in seeds])
                for arm in ("off", "on")} for s in SPECIALISTS},
            "seed_event_coverage": coverage, "coverage": biological_coverage, "limitations": limitations}


def specialist_readable(report):
    """Retain raw evidence and defined-pair denominators in the readable output."""
    lines = ["# Specialist spring comparison", "",
             "Shares use all live flowers; null means an empty meadow (undefined share).",
             "Differences are on minus off; contrasts are Borage effect minus Clover effect.",
             "Logged draw-weight ranges are separate from realised spring replacements.", ""]
    lines += report["limitations"]
    lines += ["", "Summaries use defined pairs/arms only; shares and share effects are fractions.",
              "", "| Comparison | Measurement | n | Median | Minimum | Maximum |",
              "| --- | --- | --- | --- | --- | --- |"]
    def add_summary(label, tree, path=""):
        if "median" in tree:
            values = ["undefined" if tree[k] is None else f'{tree[k]:.6g}'
                      for k in ("median", "min", "max")]
            lines.append(f'| {label} | {path} | {tree["n"]} | ' + " | ".join(values) + " |")
        else:
            for key, value in tree.items():
                add_summary(label, value, f"{path}/{key}".strip("/"))
    for specialist, summary in report["specialist_paired_summary"].items():
        add_summary(f"{specialist} on minus off", summary)
    add_summary("Borage effect minus Clover effect", report["contrast_summary"])
    for specialist, arms in report["within_arm_summary"].items():
        for arm, summary in arms.items():
            add_summary(f"{specialist}/{arm} spring minus summer", summary)
    for title, key in (("Provenance and controls", "provenance"), ("Raw arm data", "rows"),
                       ("Paired effects", "specialist_on_minus_off"),
                       ("Paired summaries (n, median, min, max)", "specialist_paired_summary"),
                       ("Borage minus Clover effects", "borage_minus_clover_effect"),
                       ("Contrast summaries (n, median, min, max)", "contrast_summary"),
                       ("Within-arm spring minus summer", "within_arm_summary"),
                       ("Seed-event coverage", "seed_event_coverage")):
        lines += ["", f"## {title}", "", "```json", json.dumps(report[key], indent=2), "```"]
    return "\n".join(lines) + "\n"


def readable(report):
    if "specialist_paired_summary" in report:
        return specialist_readable(report)
    if "spring_paired_summary" in report:
        def vector(counts):
            return "/".join(str(counts[s]) for s in SPECIES)
        def share(value):
            return "undefined" if value is None else f"{100 * value:.4f}"
        lines = ["Species order: Clover / Borage / Foxglove / Poppy / Bramble / Dandelion.",
                 "Shares and share changes are percentages and percentage points respectively.", "",
                 "| Seed | Arm | Phase | Live species | Clover share | Seed counts | Spring counts |",
                 "| --- | --- | --- | --- | --- | --- | --- |"]
        for row in report["rows"]:
            for phase in ("summer", "spring", "summer_to_spring"):
                p = row[phase]
                lines.append(f'| {row["seed"]} | {row["arm"]} | {phase} | {vector(p["live_by_species"])} | {share(p["clover_share"])} | {vector(p["seed_counts"])} | {vector(p["spring_counts"])} |')
        lines += ["", "| Seed | Arm | Observed spring replacements | Logged seasonal draw weights (min:max) |",
                  "| --- | --- | --- | --- |"]
        for row in report["rows"]:
            weights = "/".join(f'{row["spring_weights"][s]["min"]:.4f}:{row["spring_weights"][s]["max"]:.4f}' for s in SPECIES)
            lines.append(f'| {row["seed"]} | {row["arm"]} | {vector(row["spring_replacements"])} | {weights} |')
        lines += ["", "Paired on-minus-off differences:", "",
                  "| Seed | Phase | Live species | Clover share | Seed counts | Spring counts |",
                  "| --- | --- | --- | --- | --- | --- |"]
        for pair in report["spring_on_minus_off"]:
            for phase in ("summer", "spring", "summer_to_spring"):
                p = pair[phase]
                lines.append(f'| {pair["seed"]} | {phase} | {vector(p["live_by_species"])} | {share(p["clover_share"])} | {vector(p["seed_counts"])} | {vector(p["spring_counts"])} |')
            lines.append(f'| {pair["seed"]} | spring replacements | {vector(pair["spring_replacements"])} | | | |')
        lines += ["", "Summaries: median [minimum, maximum]; n is the number of defined pairs or arms.", "",
                  "| Comparison | Measurement | Median [min, max] | n |", "| --- | --- | --- | --- |"]
        def add_summary(label, tree, path=""):
            if "median" in tree:
                scale = 100 if path.endswith("clover_share") else 1
                values = [tree[k] for k in ("median", "min", "max")]
                values = ["undefined" if v is None else f"{v * scale:.4f}" for v in values]
                lines.append(f'| {label} | {path} | {values[0]} [{values[1]}, {values[2]}] | {tree["n"]} |')
            else:
                for key, value in tree.items():
                    add_summary(label, value, f"{path}/{key}".strip("/"))
        add_summary("paired", report["spring_paired_summary"])
        for arm, summary in report["within_arm_summary"].items():
            add_summary(f"{arm} spring minus summer", summary)
        return "\n".join(lines) + "\n"
    lines = ["| Seed | Arm | Seconds | Eligible / all deaths | Seed / seasonal replacements | Live (C/B/F/P/Br/D) | Total | Clover share |",
             "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    for r in report["rows"]:
        share = "undefined" if r["clover_share"] is None else f'{r["clover_share"]:.6f}'
        counts = "/".join(str(r["live_by_species"][s]) for s in SPECIES)
        lines.append(f'| {r["seed"]} | {r["arm"]} | {r["elapsed_seconds"]:.3f} | {r["eligible_deaths"]} / {r["all_deaths"]} | {r["seed_replacements"]} / {r["seasonal_replacements"]} | {counts} | {r["live_total"]} | {share} |')
    lines += ["", "On minus off:", "", "| Seed | Seed replacements | Clover share |", "| --- | --- | --- |"]
    for p in report["on_minus_off"]:
        lines.append(f'| {p["seed"]} | {p["seed_replacements"]} | {p["clover_share"]} |')
    lines += ["", "Paired summary (median, minimum, maximum, defined pairs):", json.dumps(report["paired_summary"], indent=2)]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=("summer", "spring", "specialists"))
    parser.add_argument("--output", type=Path, help="new directory outside tracked files")
    parser.add_argument("--fixture", type=Path, help="scenario fixture (default: EE-2 spring, or EE-1 for summer)")
    args = parser.parse_args()
    output = args.output.resolve() if args.output else Path(tempfile.mkdtemp(prefix=f"meadow-seed-set-{args.phase}-"))
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise ValueError("output directory must be empty")
    if output.is_relative_to(ROOT):
        raise ValueError("retain bulk artefacts outside the checkout")
    fixture = ROOT / f'test_scenarios/{"ee1_seed_set_summer" if args.phase == "summer" else "ee2_seed_set_spring"}.json'
    fixture = args.fixture.resolve() if args.fixture else fixture
    base = json.loads(fixture.read_text(encoding="utf-8"))
    godot = find_godot()
    if not godot:
        raise ValueError("Godot executable not found")
    refusal = runner.prepare_launch(godot)
    if refusal:
        raise ValueError(refusal)
    provenance = {"baseline_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                  "reporter_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  "phase": args.phase,
                  "engine_version": subprocess.check_output([godot, "--version"], text=True).strip(),
                  "fixture": str(fixture), "fixture_sha256": hashlib.sha256(fixture.read_bytes()).hexdigest(),
                  "seeds": SEEDS, "fixed_fps": 30, "controls": base, "output": str(output),
                  "species": SPECIES, "clover_denominator": "all live flowers in the end save; empty meadow gives null share",
                  "eligibility": "logged sets_seed, independent of the arm's enabled flag",
                  "replacement_unit": "one logged pollination_replant per actual flower, including bush flowers"}
    if args.phase in ("spring", "specialists"):
        config = base["config_overrides"]
        start = (config["season_length_days"] + config["winter_length_days"]) * config["seconds_per_day"]
        provenance["spring_window"] = {"from_inclusive": start,
                                       "to_exclusive": start + config["spring_regrowth_days"] * config["seconds_per_day"],
                                       "weights": "per-species min/max of logged seasonal draw weights; never realised counts"}
    (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    rows = []
    for seed in SEEDS:
        for specialist in (SPECIALISTS if args.phase == "specialists" else (base["forager_species"],)):
            for arm in ("off", "on"):
                case_dir = output / (f"{seed}-{specialist}-{arm}" if args.phase == "specialists" else f"{seed}-{arm}")
                case_dir.mkdir()
                scenario = dict(base, random_seed=seed, seed_set=arm == "on", forager_species=specialist)
                case = case_dir / "scenario.json"
                case.write_text(json.dumps(scenario, indent=2) + "\n", encoding="utf-8")
                code = runner.run_verdict_scenario(case, godot, 900, 30, case_dir)
                run_dir, = [p for p in case_dir.glob("run-*") if p.is_dir()]
                result = json.loads((run_dir / "result.json").read_text(encoding="utf-8"))
                private = runner.PRIVATE_USER_ROOT / result["run_id"]
                if private.exists():
                    shutil.copytree(private, case_dir / "private_user")
                if code:
                    raise ValueError(f"failed arm: {run_dir / 'result.json'}")
                saves = list((case_dir / "private_user").rglob("ee1-end.json" if args.phase == "summer" else "ee2-spring.json"))
                if len(saves) != 1:
                    raise ValueError(f"missing or ambiguous end save: {case_dir}")
                entries = load_entries(run_dir / "session.jsonl")
                end_save = json.loads(saves[0].read_text(encoding="utf-8"))
                if args.phase in ("spring", "specialists"):
                    summer_path, = (case_dir / "private_user").rglob("ee2-summer.json")
                    row = aggregate_spring(entries, json.loads(summer_path.read_text(encoding="utf-8")), end_save, result, scenario)
                else:
                    row = aggregate_arm(entries, end_save, result, scenario)
                row.update(seed=seed, arm=arm, artefacts={"run": str(run_dir), "end_save": str(saves[0])})
                if args.phase == "specialists":
                    events = dict.fromkeys(SPECIES, 0)
                    for entry in entries:
                        if entry.get("do") == "pollination_withered":
                            detail = json.loads(entry["reason"])
                            if detail["sets_seed"]:
                                events[SPECIES[species_index(detail["species_index"])]] += 1
                    row.update(specialist=specialist,
                               treatment={"specialist": specialist, "seed_set": arm == "on"},
                               scenario=scenario, provenance={k: provenance[k] for k in PROVENANCE_KEYS},
                               seed_events_by_species=events)
                rows.append(row)
    report = (specialist_report(rows, provenance) if args.phase == "specialists" else
              dict((spring_report if args.phase == "spring" else paired_report)(rows), provenance=provenance))
    coverage = {"eligible": any(r["eligible_deaths"] > 0 for r in rows),
                "ineligible": any(r["all_deaths"] > r["eligible_deaths"] for r in rows),
                "seed_replacements": any(r["seed_replacements"] > 0 for r in rows),
                "seasonal_replacements": any(r["seasonal_replacements"] > 0 for r in rows)}
    report["coverage"] = coverage
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (output / "report.md").write_text(readable(report), encoding="utf-8")
    print(readable(report))
    print("Report:", output / "report.json")
    if args.phase != "specialists" and not all(coverage.values()):
        raise ValueError(f"missing causal coverage: {coverage}")


if __name__ == "__main__":
    main()
