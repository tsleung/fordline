#!/usr/bin/env python3
"""Measures of play against DESIGN.md's "Play over time" targets. Reads the
ROW lines tests/luck_skill.gd prints and reports, per battle and commander,
each horizon's measure, and the ladder as DESIGN.md's table; the VS lines
tests/versus.gd prints, the AI against its yardstick from both ends; and the
PLAN lines tests/plans.gd prints, the audit. tests/studies.sh runs them all.

    python3 tests/play.py build/studies/NAME/*.txt
"""
import json
import sys
from collections import defaultdict
from statistics import mean, median

LADDER = ["idle", "person", "standard", "sharp", "reserve", "hills", "planner"]


def load(paths, tag="ROW "):
    rows = []
    for path in paths:
        with open(path) as f:
            for line in f:
                if line.startswith(tag):
                    rows.append(json.loads(line[len(tag):]))
    return rows


PAIR_ORDER = [("base", "base"), ("ai", "base"), ("base", "ai"), ("person", "ai"), ("person", "plan"), ("ai", "ai"), ("ai", "plan"), ("plan", "ai")]


def share(won):
    return f"{mean(won):.0%}" if won else "–"


def ladder(rows):
    """DESIGN.md's table: win rates up the ladder, and the standard
    commander's length, lead changes and orders a minute (the person-paced
    commander's beside them). A battle where a rung stands below the one
    beneath it is marked."""
    by = defaultdict(list)
    for r in rows:
        by[(str(r["battle"]), r["policy"])].append(r)
    rungs = ["idle", "person", "standard", "sharp"]
    print("| Battle | " + " | ".join(rungs) + " | planner | minutes | lead changes | orders a minute | rises |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for battle in sorted({b for b, _ in by}, key=lambda b: (b.isdigit(), b)):
        rates = [mean(r["won"] for r in by[(battle, p)]) if by.get((battle, p)) else None for p in rungs]
        st, pe = by.get((battle, "standard"), []), by.get((battle, "person"), [])
        known = [x for x in rates if x is not None]
        rises = "yes" if all(a <= b for a, b in zip(known, known[1:])) else "no"
        cells = [share([r["won"] for r in by.get((battle, p), [])]) for p in rungs + ["planner"]]
        length = f"{mean(r['time'] for r in st) / 60:.1f} | {mean(r['lead_changes'] for r in st):.1f}" if st else "– | –"
        orders = f"{mean(r['orders_min'] for r in pe):.0f} / {mean(r['orders_min'] for r in st):.0f}" if st and pe else "–"
        print(f"| {battle} | " + " | ".join(cells) + f" | {length} | {orders} | {rises} |")
    pooled = [share([r["won"] for r in rows if r["policy"] == p]) for p in rungs + ["planner"]]
    print("over every battle: " + ", ".join(f"{p} {w}" for p, w in zip(rungs + ["planner"], pooled)))
    planned = {str(r["battle"]) for r in rows if r["policy"] == "planner"}
    if planned:
        same = [share([r["won"] for r in rows if r["policy"] == p and str(r["battle"]) in planned]) for p in rungs + ["planner"]]
        print("where the planner fought: " + ", ".join(f"{p} {w}" for p, w in zip(rungs + ["planner"], same)))


def plans(rows):
    """The audit: how many fixed plans beat the enemy on every die, and on
    none; and how the AI's own line, the first plan tried, does."""
    for battle in sorted({r["scenario"] for r in rows}):
        tried = [r for r in rows if r["scenario"] == battle]
        dice = tried[0]["dice"]
        print(f"{battle:12s} its own line wins {tried[0]['wins']} of {dice}; plans that win all "
              f"{dice}: {sum(r['wins'] == dice for r in tried)} of {len(tried)}; none: {sum(r['wins'] == 0 for r in tried)}")


def both_ends(rows, label):
    """The AI against the yardstick, from both ends of `rows`."""
    rate = lambda p, e: [r["won"] for r in rows if r["player"] == p and r["enemy"] == e]
    base, player, enemy = rate("base", "base"), rate("ai", "base"), rate("base", "ai")
    if not player or not enemy:
        return
    wins = sum(player) + len(enemy) - sum(enemy)
    n = len(player) + len(enemy)
    p = wins / n
    print(f"{label}: the AI wins {wins} of {n} from both ends, {p:.0%} ±{2 * (p * (1 - p) / n) ** 0.5:.0%}; "
          f"the player wins {share(base)} base against base, {share(player)} with the AI as the player, "
          f"{share(enemy)} with the AI as the enemy")


def versus(rows):
    """The player's win rate for each pairing, player's AI against the
    enemy's; and what the AI changes against the yardstick's base rate."""
    by = defaultdict(list)
    for r in rows:
        by[(r["job"], r["player"], r["enemy"])].append(r["won"])
    pairs = sorted({(r["player"], r["enemy"]) for r in rows}, key=lambda pe: PAIR_ORDER.index(pe) if pe in PAIR_ORDER else len(PAIR_ORDER))
    print(f"{'battle':24s} " + " ".join(f"{p + ' v ' + e:>12s}" for p, e in pairs) + "    n")
    pooled = defaultdict(list)
    for job in sorted({r["job"] for r in rows}):
        cells = []
        for pe in pairs:
            won = by.get((job,) + pe, [])
            pooled[pe] += won
            cells.append(f"{mean(won):12.0%}" if won else f"{'-':>12s}")
        print(f"{job:24s} " + " ".join(cells) + f" {len(by.get((job,) + pairs[-1], [])):4d}")
    rate = {pe: mean(w) for pe, w in pooled.items()}
    print(f"{'all':24s} " + " ".join(f"{rate[pe]:12.0%}" for pe in pairs))
    mirror = lambda r: r["job"].startswith("scenario:skirmish")
    both_ends([r for r in rows if not mirror(r)], "designed battles")
    both_ends([r for r in rows if mirror(r)], "mirror Skirmishes")


def report(rows):
    by = defaultdict(list)
    for r in rows:
        by[(str(r["battle"]), r["policy"])].append(r)
    print(f"{'battle':16s} {'commander':9s} {'n':>3s} {'win':>5s} {'min':>5s} {'leadΔ':>6s} {'comeb':>6s} "
          f"{'quiet':>6s} {'warn':>5s} {'unann':>6s} {'ord/m':>6s}")
    for (battle, policy) in sorted(by, key=lambda k: (k[0], LADDER.index(k[1]) if k[1] in LADDER else 99)):
        rs = by[(battle, policy)]
        warns = [r["warning"] for r in rs if r["warning"] >= 0]
        print(f"{battle:16s} {policy:9s} {len(rs):3d} {mean(r['won'] for r in rs):5.0%} "
              f"{mean(r['time'] for r in rs) / 60:5.1f} {mean(r['lead_changes'] for r in rs):6.2f} "
              f"{mean(r['comeback'] for r in rs):6.0%} {max(r['quiet'] for r in rs):5.0f}s "
              f"{(median(warns) if warns else -1):4.0f}s {mean(r['unannounced'] for r in rs):6.0%} "
              f"{mean(r['orders_min'] for r in rs):6.1f}")
    impacts = [(r["battle"], i) for r in rows for i in r.get("impact", [])]
    if impacts:
        print()
        print("sensitivity (one order taken out, every other order kept, battle fought again)")
        per = defaultdict(list)
        for battle, i in impacts:
            per[str(battle)].append(i)
        for battle, items in sorted(per.items()):
            matters = mean(abs(i["margin"]) >= 5 for i in items)
            flips = mean(i["flip"] for i in items)
            soon = mean(abs(i["soon"]) for i in items)
            end = mean(abs(i["end"]) for i in items)
            print(f"  {battle:16s} orders {len(items):3d}  move the margin 5+ {matters:4.0%}  flip the winner {flips:4.0%}  "
                  f"growth {end / soon if soon > 0 else float('nan'):4.1f}")


if __name__ == "__main__":
    rows, vs, tried = load(sys.argv[1:]), load(sys.argv[1:], "VS "), load(sys.argv[1:], "PLAN ")
    if rows:
        report(rows)
        print()
        ladder(rows)
    if vs:
        print()
        versus(vs)
    if tried:
        print()
        plans(tried)
