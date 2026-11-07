"""Summarize a progression audit CSV (tests/progression_audit.gd output) per build: bosses (wins/trials, median
player HP left, median time), 3-actor and 6-actor spots won (a spot counts as won when every seed wins) and the
worst spot, and farm deaths per 10 min. Optional second CSV: cells that differ are marked with the reference.

  python tools/progression_ladder_summary.py <trials.csv> [reference.csv]
"""
import csv, statistics as st, sys
from collections import defaultdict


def load(path):
    rows = list(csv.DictReader(open(path, encoding='utf-8')))
    out = defaultdict(lambda: defaultdict(list))
    for r in rows:
        out[r['build']][(r['enc'], r['target'], r['variant'], r['count'])].append(r)
    return out


def summary(cells):
    boss, spots, farms = [], {3: [0, 0, None], 6: [0, 0, None]}, []
    for (enc, target, variant, count), rs in sorted(cells.items()):
        wins = sum(r['result'] == 'win' for r in rs)
        left = st.median(float(r['player_left']) for r in rs)
        if enc == 'boss':
            boss.append(f"{target.replace('boss-', '')} {wins}/{len(rs)} {left * 100:.0f}% {st.median(float(r['time']) for r in rs):.0f}s")
        elif enc == 'spot':
            s = spots.setdefault(int(count), [0, 0, None])
            s[1] += 1
            s[0] += wins == len(rs)
            key = (wins, left)
            if s[2] is None or key < s[2][0]:
                s[2] = (key, f"{target.replace('unit-', '')} v{variant} {wins}/{len(rs)} {left * 100:.0f}%")
        elif enc == 'farm':
            farms.append(f"{target.replace('unit-', '')} {st.mean(float(r['deaths']) * 10 / max(.1, float(r['minutes'])) for r in rs):.0f} d/10m")
    parts = ['; '.join(boss)]
    for n in (3, 6):
        s = spots.get(n)
        if s and s[1]:
            parts.append(f"{n}-actor {s[0]}/{s[1]} worst {s[2][1]}")
    if farms:
        parts.append('farm ' + ', '.join(farms))
    return ' | '.join(p for p in parts if p)


if __name__ == '__main__':
    a = load(sys.argv[1])
    b = load(sys.argv[2]) if len(sys.argv) > 2 else {}
    for build in a:
        line = summary(a[build])
        print(f'{build:14s} {line}')
        if build in b:
            ref = summary(b[build])
            if ref != line:
                print(f'{"  reference":14s} {ref}')
