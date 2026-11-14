"""Summarize a C79 ladder CSV: per stage and Prestige profile, each rung's boss and 6-spot results; the rung
where the strongest 6-spots become farmable (R6: both won with >=25% HP, every seed) and each boss's first winning
rung. usage: analyze.py csv[,csv] [--brief]"""
import csv, sys, statistics as S, json
from collections import defaultdict
rows = []
for f in sys.argv[1].split(','):
    rows += list(csv.DictReader(open(f, encoding='utf-8')))
D = defaultdict(list)
for r in rows:
    D[(r['build'], r['target'], int(r['variant']), int(r['count']))].append(r)
def cell(b, t, v, n):
    rs = D.get((b, t, v, n))
    if not rs: return None
    return dict(win=all(x['result'] == 'win' for x in rs), wins=sum(x['result'] == 'win' for x in rs), left=S.mean(float(x['player_left']) for x in rs),
                mn=S.mean(float(x['player_min']) for x in rs), t=S.mean(float(x['time']) for x in rs), dps=S.mean(float(x['incoming_dps']) for x in rs),
                pots=S.mean(int(x['potions']) for x in rs), ec=S.mean(int(x['enemy_casts']) for x in rs), tl=S.mean(float(x['target_hp_left']) for x in rs),
                hp=float(rs[0]['hp']), dmg=float(rs[0]['damage']), L=int(rs[0]['level']))
builds = sorted({r['build'] for r in rows})
brief = '--brief' in sys.argv
out = {}
for st in range(4, 9):
    for P in (0, 1, 3):
        bs = sorted([b for b in builds if b.startswith(f'L{st}_r') and b.endswith(f'_P{P}')], key=lambda b: int(b.split('_r')[1].split('_')[0]))
        if not bs: continue
        bosses = sorted({r['target'] for r in rows if r['build'] == bs[0] and r['enc'] == 'boss'}, key=lambda x: (x == 'boss-green-alien', x))
        spots = sorted({(r['target'], int(r['variant'])) for r in rows if r['build'] == bs[0] and r['enc'] == 'spot'})
        print(f"\n=== Stage {st} P{P}")
        r6 = None; first = {}
        for b in bs:
            rung = int(b.split('_r')[1].split('_')[0])
            s6 = [cell(b, g, v, 6) for g, v in spots]; s3 = [cell(b, g, v, 3) for g, v in spots]
            c0 = s6[0] or s3[0]
            line = f" r{rung} L{c0['L']:3d} dmg{c0['dmg']:6.0f} hp{c0['hp']:6.0f} |"
            for g in bosses:
                c = cell(b, g, 2, 1)
                if c is None: continue
                line += f" {g[5:13]:8s} {'W' if c['win'] else ('w' if c['wins'] else 'L')}{c['left']*100:3.0f}% {c['t']:4.0f}s in{c['dps']:6.0f} p{c['pots']:4.1f} |"
                if first.get(g) is None and c['win']: first[g] = rung
                out[(st, P, rung, g)] = c
            for c in s6:
                line += f" 6:{'W' if c['win'] else 'L'}{c['left']*100:3.0f}% in{c['dps']:5.0f}"
            for (g, v), c in zip(spots, s6): out[(st, P, rung, f'6:{g}:{v}')] = c
            for (g, v), c in zip(spots, s3): out[(st, P, rung, f'3:{g}:{v}')] = c
            if not brief: print(line)
            if r6 is None and all(c['win'] and c['left'] >= .25 for c in s6): r6 = rung
        print(f"  -> 6-spot farming from r{r6}; first boss wins {first}")
