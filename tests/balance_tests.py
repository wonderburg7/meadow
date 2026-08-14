#!/usr/bin/env python3
"""Balance tests for Meadow.

Run with:  python3 tests/balance_tests.py

These read the tuning values and the rules straight out of the GDScript
source and re-run them in Python, so what is tested is what ships rather
than a copy that has drifted. They exist because every balance system in
this game so far has shipped with a real bug that reading the code did
not catch and thirty seconds of simulation did:

  * the rival colony either ran to its population cap or died out,
    whatever the player did -- it wasn't responsive to anything
  * winter needed 48 full honey cells for a 50-bee colony, which is more
    comb than the hive has
  * a single dead larva made the whole colony sick in under two days
  * there was a stretch of the year with nothing at all in flower

None of those are visible by inspection. All of them are obvious the
moment you run the numbers forward.

There is no Godot here, so these can't test behaviour -- only arithmetic
and the feedback loops. That is the half worth testing anyway.
"""

import math
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts")

failures = []
notes = []


def source(name):
    with open(os.path.join(ROOT, name), encoding="utf-8") as handle:
        return handle.read()


CONFIG = source("game_config.gd")


def cfg(name, default=None):
    """A tuning value, read from game_config.gd."""
    match = re.search(rf"^var {name}: (?:float|bool|int) = ([\d.]+|true|false)",
                      CONFIG, re.M)
    if not match:
        if default is not None:
            return default
        raise AssertionError(f"no such tuning value: {name}")
    raw = match.group(1)
    if raw in ("true", "false"):
        return raw == "true"
    return float(raw)


def check(condition, message, note=None):
    if condition:
        if note:
            notes.append(note)
    else:
        failures.append(message)


def section(title):
    print(f"\n{title}")
    print("-" * len(title))


# ---------------------------------------------------------------- winter
def test_winter():
    section("Winter: can the colony actually store enough?")
    seconds = cfg("winter_length_days") * cfg("seconds_per_day")
    honey_cell = cfg("honey_cell_capacity") * cfg("honey_energy_factor")

    for bees in (10, 25, 50, 100):
        need = bees * cfg("energy_burn_rate") * cfg("winter_burn_factor") * seconds
        cells = need / honey_cell
        print(f"  {bees:3d} bees -> {need:7.0f} energy = {cells:5.1f} honey cells")

    fifty = 50 * cfg("energy_burn_rate") * cfg("winter_burn_factor") * seconds / honey_cell
    check(3.0 <= fifty <= 30.0,
          f"a 50-bee colony needs {fifty:.1f} honey cells -- outside a reachable 3-30",
          f"50-bee target is {fifty:.1f} honey cells: reachable")

    # A colony has to be able to build the comb in the run-up, not just
    # in principle.
    build_seconds = cfg("cell_build_time")
    days = cfg("winter_countdown_days") * cfg("seconds_per_day")
    workers_needed = fifty * build_seconds / days
    check(workers_needed < 8.0,
          f"would need {workers_needed:.1f} comb workers building non-stop for the whole countdown",
          f"about {workers_needed:.1f} comb workers' worth of building in the countdown")


# ------------------------------------------------------------- the rival
def test_rival():
    section("Rival colony: does its size track the forage?")
    p = {k: cfg(k) for k in (
        "rival_starting_bees", "rival_max_bees", "rival_eat_per_bee",
        "rival_nectar_per_bee", "rival_pollen_per_bee",
        "rival_pollen_per_bee_raised", "rival_hatch_rate", "rival_starve_rate",
        "rival_crowding_scale", "rival_brood_gate_days", "rival_store_per_bee",
        "rival_brood_per_nurse")}
    rival_src = source("rival_hive.gd")
    min_share = float(re.search(r"MIN_FORAGER_SHARE := ([\d.]+)", rival_src).group(1))
    max_share = float(re.search(r"MAX_FORAGER_SHARE := ([\d.]+)", rival_src).group(1))

    def run(richness, days=200):
        pop = p["rival_starting_bees"]
        nectar, pollen, brood, share = 120.0, 40.0, 0.0, 0.7
        for _ in range(int(days * cfg("seconds_per_day"))):
            nectar -= pop * p["rival_eat_per_bee"]
            if nectar < 0:
                pop -= min(pop, -nectar * p["rival_starve_rate"])
                nectar = 0.0
            crowding = 1.0 / (1.0 + pop / max(1.0, p["rival_crowding_scale"]))
            foraging = pop * share
            nectar = min(nectar + foraging * p["rival_nectar_per_bee"] * richness * crowding,
                         pop * p["rival_store_per_bee"])
            pollen += foraging * p["rival_pollen_per_bee"] * richness * crowding
            days_food = nectar / max(0.01, pop * p["rival_eat_per_bee"])
            if days_food >= p["rival_brood_gate_days"]:
                nurses = pop * (1.0 - share)
                raised = min(pollen / max(0.1, p["rival_pollen_per_bee_raised"]),
                             nurses * p["rival_brood_per_nurse"])
                if raised > 0:
                    pollen -= raised * p["rival_pollen_per_bee_raised"]
                    brood += raised
            hatched = brood * p["rival_hatch_rate"]
            brood -= hatched
            pop += hatched
            pop = min(pop, p["rival_max_bees"])
            if pop < 1.0:
                return 0.0
            if days_food < p["rival_brood_gate_days"] * 0.75:
                share = min(max_share, share + 0.05)
            elif days_food > 90.0:
                share = max(min_share, share - 0.05)
        return pop

    sizes = {}
    for richness in (1.0, 0.7, 0.45, 0.25):
        sizes[richness] = run(richness)
        state = "died out" if sizes[richness] < 1 else f"{sizes[richness]:.0f} bees"
        print(f"  forage at {richness:.0%}: {state}")

    check(sizes[1.0] > 1, "the rival dies out even with a full meadow")
    distinct = len({round(v) for v in sizes.values()})
    check(distinct >= 3,
          "the rival settles at the same size whatever the forage -- it isn't responsive",
          "its size reads the meadow: squeezing it visibly shrinks it")


# ------------------------------------------------------------- pathogens
def test_disease():
    section("Pathogens: does neglect cost, and does cleanliness not?")
    threshold = cfg("disease_threshold")
    per_corpse = cfg("disease_per_corpse")
    per_bee = cfg("disease_per_bee")
    recovery = cfg("disease_recovery")
    day = cfg("seconds_per_day")

    def days_to_sicken(corpses, bees, cells):
        rise = corpses * per_corpse + bees * (bees / cells) * per_bee
        net = rise - recovery
        return None if net <= 0 else threshold / net / day

    for corpses in (0, 1, 2, 4):
        result = days_to_sicken(corpses, 40, 50)
        text = "stays healthy" if result is None else f"sickens in {result:.1f} days"
        print(f"  {corpses} bodies, 40 bees in 50 cells: {text}")

    check(days_to_sicken(0, 40, 50) is None,
          "a clean colony sickens on its own -- that is a tax, not a consequence")
    check(days_to_sicken(0, 90, 70) is None,
          "a clean but busy colony sickens with nothing wrong with it")
    check(days_to_sicken(1, 40, 50) is None,
          "a single dead larva is enough to sicken the colony -- too punishing")
    four = days_to_sicken(4, 40, 50)
    check(four is not None and four < 3.0,
          "four dead larvae never sicken the colony -- clearing has no urgency",
          f"four bodies sicken it in {four:.1f} days: clearing has real urgency")


# --------------------------------------------------------------- seasons
def test_seasons():
    section("Seasons: is there always something in flower?")
    flower = source("flower.gd")
    species = re.findall(
        r'"name": "(\w+)",(?:.*?)"season_start": ([\d.]+), "season_end": ([\d.]+)',
        flower, re.S)
    check(len(species) >= 3, "could not read the flowering windows")

    pollen_rich = []
    for name, start, end in species:
        cap = re.search(rf'"name": "{name}",.*?"pollen_capacity": ([\d.]+)', flower, re.S)
        if cap and float(cap.group(1)) >= 10.0:
            pollen_rich.append((name, float(start), float(end)))
        print(f"  {name:10} {float(start):.2f} -> {float(end):.2f}")

    empty = [t / 100 for t in range(101)
             if not any(float(a) <= t / 100 <= float(b) for _, a, b in species)]
    check(not empty,
          f"nothing in flower between {min(empty):.2f} and {max(empty):.2f} of the year"
          if empty else "",
          "something is in flower all year")

    no_pollen = [t / 100 for t in range(101)
                 if not any(a <= t / 100 <= b for _, a, b in pollen_rich)]
    check(not no_pollen,
          f"no pollen source between {min(no_pollen):.2f} and {max(no_pollen):.2f} of the year"
          if no_pollen else "",
          "a pollen source is available all year")


# ------------------------------------------------------------------ brood
def test_brood_economics():
    section("Brood: can a nurse keep up, and does a colony pay for itself?")
    feed_seconds = cfg("brood_feed_seconds")
    develop = cfg("brood_develop_time")
    feeds_per_larva = develop / feed_seconds
    carry = cfg("nurse_carry_feeds")
    trips = feeds_per_larva / carry
    print(f"  one larva needs {feeds_per_larva:.1f} feeds, so {trips:.1f} nurse trips")
    check(trips < 30.0, f"{trips:.0f} nurse trips per larva is more work than a colony can absorb",
          f"{trips:.1f} nurse trips per larva")

    # Does a forager bring back more than it costs?
    #
    # Two different questions, and conflating them is misleading. The
    # first version of this test added the baseline metabolism to the
    # cost of a trip and concluded that foraging barely paid -- but a bee
    # burns that whether it forages or sits in the hive, so it isn't a
    # cost *of the trip*. What decides whether a trip is worth making is
    # the flight burn alone.
    #
    # The second question -- whether a forager covers its own upkeep with
    # enough left over to feed somebody else -- is what decides how many
    # non-foragers the colony can carry, and it is a much tighter margin.
    trip_seconds = 60.0
    gathered = cfg("nectar_stomach_capacity")
    collecting = gathered / max(0.1, cfg("nectar_collection_rate"))
    flying = max(1.0, trip_seconds - collecting)

    marginal = cfg("flight_energy_burn") * flying
    print(f"  a 60s trip: brings {gathered:.0f}, flight costs {marginal:.0f}")
    check(gathered > marginal * 2.0,
          f"a trip brings {gathered:.0f} and the flying costs {marginal:.0f} -- not worth making",
          f"a trip returns {gathered / max(1, marginal):.1f}x what the flying costs")

    per_day = cfg("seconds_per_day")
    trips_per_day = per_day / trip_seconds
    day_gathered = trips_per_day * gathered
    day_burned = (cfg("energy_burn_rate") + cfg("flight_energy_burn")) * per_day
    surplus = day_gathered - day_burned
    carried = surplus / max(1.0, cfg("energy_burn_rate") * per_day)
    print(f"  over a day: gathers {day_gathered:.0f}, burns {day_burned:.0f}, "
          f"so one forager supports {carried:.1f} other bees")
    check(carried > 0.3,
          f"a forager only supports {carried:.2f} other bees -- the colony can't afford "
          "nurses, comb workers or a queen",
          f"one forager supports {carried:.1f} other bees")

    # And the queen: how much foraging does one egg represent?
    pollen_per_egg = cfg("egg_pollen_cost")
    pollen_per_trip = cfg("pollen_stomach_capacity")
    print(f"  one egg costs {pollen_per_egg:.0f} pollen = {pollen_per_egg / pollen_per_trip:.1f} pollen trips")
    check(pollen_per_egg / pollen_per_trip < 12.0,
          "an egg costs more pollen trips than a colony can sustain",
          f"an egg is {pollen_per_egg / pollen_per_trip:.1f} pollen trips")


# ------------------------------------------------------- movement margins
def test_movement_invariants():
    section("Movement: the margins that caused the orbiting bug")
    # OBSTACLE_MARGIN/BLOCK_MARGIN moved from bee.gd to bee_movement.gd
    # in the bee.gd split -- see BEE_SPLIT_PLAN.md.
    bee_movement = source("bee_movement.gd")
    main = source("main.gd")

    def const(src, name):
        return float(re.search(rf"const {name} := ([\d.]+)", src).group(1))

    margin = const(bee_movement, "OBSTACLE_MARGIN")
    block = const(bee_movement, "BLOCK_MARGIN")
    flower_clear = const(main, "FLOWER_CLEARANCE")
    print(f"  steering margin {margin}, hard boundary {block}, flower clearance {flower_clear}")

    check(block >= margin,
          "the hard boundary is inside the steering margin: a bee pressed against an "
          "obstacle counts as blocked by it in every direction, and orbits forever",
          "a bee at the boundary is outside the steering margin")
    check(flower_clear > block,
          "flowers can be planted inside the boundary, where no bee can stand",
          "flowers are always reachable")


def main():
    print("Meadow balance tests")
    print("====================")
    for test in (test_winter, test_rival, test_disease, test_seasons,
                 test_brood_economics, test_movement_invariants):
        test()

    print("\n" + "=" * 60)
    for note in notes:
        print(f"  ok  {note}")
    if failures:
        print()
        for failure in failures:
            print(f"  FAIL  {failure}")
        print(f"\n{len(failures)} failed.")
        return 1
    print(f"\nAll {len(notes)} checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
