"""Compare boss results of candidate CSVs with the baseline at each profile's own farming power.
usage: compare.py base.csv(,..) cand.csv(,..) [--rungs]
R6 = first rung (per stage and Prestige profile) where both strongest 6-enemy spots are won with >=25% HP (baseline spots).
Per boss: first winning rung (base -> cand), gap to R6, and the fight at R6 and R6+1 (min HP%, end HP%, seconds,
potions, damage taken/s) next to the 6-spot's damage taken/s at R6."""
import csv, sys, statistics as S
from collections import defaultdict
def load(arg):
    rows = []
    for f in arg.split(','): rows += list(csv.DictReader(open(f, encoding='utf-8')))
    D = defaultdict(list)
    for r in rows: D[(r['build'], r['target'], int(r['variant']), int(r['count']))].append(r)
    return rows, D
brows, BD = load(sys.argv[1]); crows, CD = load(sys.argv[2])
def cell(D, b, t, v=2, n=1):
    rs = D.get((b, t, v, n))
    if not rs: return None
    return dict(win=all(x['result'] == 'win' for x in rs), any=any(x['result'] == 'win' for x in rs), left=S.mean(float(x['player_left']) for x in rs),
                mn=S.mean(float(x['player_min']) for x in rs), t=S.mean(float(x['time']) for x in rs), dps=S.mean(float(x['incoming_dps']) for x in rs),
                pots=S.mean(int(x['potions']) for x in rs), casts=S.mean(int(x['enemy_casts']) for x in rs))
def fmt(c):
    if c is None: return '      -                     '
    res = 'W' if c['win'] else ('w' if c['any'] else 'L')
    return f"{res} min{c['mn']*100:3.0f}% {c['t']:4.0f}s p{c['pots']:4.1f} in{c['dps']:5.0f}"
for st in range(4, 9):
    for P in (0, 1, 3):
        bs = [f'L{st}_r{r}_P{P}' for r in range(10)]
        spots = sorted({(r['target'], int(r['variant'])) for r in brows if r['build'] == bs[0] and r['enc'] == 'spot'})
        r6 = None; s6dps = {}
        for r, b in enumerate(bs):
            cs = [cell(BD, b, g, v, 6) for g, v in spots]
            s6dps[r] = max(c['dps'] for c in cs)
            if r6 is None and all(c['win'] and c['left'] >= .25 for c in cs): r6 = r
        bosses = sorted({r['target'] for r in crows if r['build'] == bs[0] and r['enc'] == 'boss'}, key=lambda x: (x == 'boss-green-alien', x))
        print(f"S{st} P{P}  R6=r{r6} (6-spot taken/s {s6dps[r6]:.0f})")
        for g in bosses:
            fb = next((r for r, b in enumerate(bs) if (cell(BD, b, g) or {}).get('win')), None)
            fc = next((r for r, b in enumerate(bs) if (cell(CD, b, g) or {}).get('win')), None)
            line = f"   {g[5:18]:13s} first win r{fb}->r{fc} (gap {'-' if fb is None else '%+d' % (fb-r6)}->{'-' if fc is None else '%+d' % (fc-r6)}) |"
            for r in (r6, min(9, r6 + 1), min(9, r6 + 2)):
                line += f" r{r}: {fmt(cell(BD, bs[r], g))} -> {fmt(cell(CD, bs[r], g))} |"
            print(line)
