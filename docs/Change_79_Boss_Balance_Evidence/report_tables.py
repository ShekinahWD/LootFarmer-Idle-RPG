"""Markdown tables for the Change 79 boss report from the baseline and after ladders (same builds, seeds 1-2).
usage: report_tables.py base.csv,base.csv after.csv,after.csv > tables.md"""
import csv, sys, statistics as S
from collections import defaultdict
def load(arg):
    rows = []
    for f in arg.split(','): rows += list(csv.DictReader(open(f, encoding='utf-8')))
    D = defaultdict(list)
    for r in rows: D[(r['build'], r['target'], int(r['variant']), int(r['count']))].append(r)
    return rows, D
brows, B = load(sys.argv[1]); arows, A = load(sys.argv[2])
def cell(D, b, t, v=2, n=1):
    rs = D.get((b, t, v, n))
    if not rs: return None
    return dict(win=all(x['result'] == 'win' for x in rs), any=any(x['result'] == 'win' for x in rs), left=S.mean(float(x['player_left']) for x in rs),
                mn=S.mean(float(x['player_min']) for x in rs), t=S.mean(float(x['time']) for x in rs), dps=S.mean(float(x['incoming_dps']) for x in rs),
                pots=S.mean(int(x['potions']) for x in rs), casts=S.mean(int(x['enemy_casts']) for x in rs), taken=S.mean(float(x['taken']) for x in rs),
                L=int(rs[0]['level']), dmg=float(rs[0]['damage']), hp=float(rs[0]['hp']))
NAMES = {'boss-elephant': 'Elephant', 'boss-teal-dinosaur': 'Teal Dinosaur', 'boss-squirrel': 'Squirrel', 'boss-red-fox': 'Red Fox',
         'boss-black-cat': 'Black Cat', 'boss-grim-reaper': 'Grim Reaper', 'boss-bee': 'Bee', 'boss-orange-tabby-cat': 'Orange Tabby Cat',
         'boss-red-panda': 'Red Panda', 'boss-sunflower': 'Sunflower', 'boss-green-alien': 'Green Alien'}
STAGES = {4: 'Summer II', 5: 'Autumn I', 6: 'Autumn II', 7: 'Spring I', 8: 'Spring II'}
def res(c):
    if c is None: return '–'
    w = 'Win' if c['win'] else ('Split' if c['any'] else 'Loss')
    return f"{w}, low {c['mn']*100:.0f}%, {c['t']:.0f} s, {c['pots']:.0f} pot., {c['dps']:.0f}/s"
r6s = {}
for st in range(4, 9):
    for P in (0, 1, 3):
        bs = [f'L{st}_r{r}_P{P}' for r in range(10)]
        spots = sorted({(r['target'], int(r['variant'])) for r in brows if r['build'] == bs[0] and r['enc'] == 'spot'})
        r6 = None
        for r, b in enumerate(bs):
            cs = [cell(B, b, g, v, 6) for g, v in spots]
            if r6 is None and all(c['win'] and c['left'] >= .25 for c in cs): r6 = r
        r6s[(st, P)] = (r6, spots)
print('### Table A — first winning rung and the fight at farming power (R6), before → after\n')
print('R6 = the first rung where both of the stage\'s two most dangerous variant spots are won at 6 enemies with ≥25% HP left (both seeds), per Prestige profile. "Gap" = first winning rung − R6. Cells: result (both seeds), lowest HP during the fight, duration, Health Potions used, damage taken per second. 6-spot = the worse of the two 6-enemy spots at R6.\n')
print('| Stage | Boss | Prestiges | R6 (level) | 6-spot taken/s | First win: before → after (gap) | At R6 before | At R6 after | At R6+1 before | At R6+1 after |')
print('|---|---|---|---|---|---|---|---|---|---|')
for st in range(4, 9):
    for P in (0, 1, 3):
        r6, spots = r6s[(st, P)]
        bs = [f'L{st}_r{r}_P{P}' for r in range(10)]
        s6 = max(cell(B, bs[r6], g, v, 6)['dps'] for g, v in spots)
        bosses = sorted({r['target'] for r in arows if r['build'] == bs[0] and r['enc'] == 'boss'}, key=lambda x: (x == 'boss-green-alien', x))
        for g in bosses:
            fb = next((r for r, b in enumerate(bs) if (cell(B, b, g) or {}).get('win')), None)
            fa = next((r for r, b in enumerate(bs) if (cell(A, b, g) or {}).get('win')), None)
            gap = lambda f: 'none' if f is None else f"r{f} ({f-r6:+d})"
            r1 = min(9, r6 + 1)
            print(f"| {STAGES[st]} | {NAMES[g]} | {P} | r{r6} (L{cell(B, bs[r6], g)['L']}) | {s6:.0f} | {gap(fb)} → {gap(fa)} | {res(cell(B, bs[r6], g))} | {res(cell(A, bs[r6], g))} | {res(cell(B, bs[r1], g))} | {res(cell(A, bs[r1], g))} |")
print('\n### Table B — boss pressure against the same stage\'s dangerous normal groups (no Prestige, at R6)\n')
print('| Stage | R6 | Strongest 3-spot taken/s | Strongest 6-spot taken/s | Boss | Boss taken/s before → after | ÷ 6-spot before → after | Boss casts/min after |')
print('|---|---|---|---|---|---|---|---|')
for st in range(4, 9):
    r6, spots = r6s[(st, 0)]
    b = f'L{st}_r{r6}_P0'
    s3 = max(cell(B, b, g, v, 3)['dps'] for g, v in spots); s6 = max(cell(B, b, g, v, 6)['dps'] for g, v in spots)
    bosses = sorted({r['target'] for r in arows if r['build'] == b and r['enc'] == 'boss'}, key=lambda x: (x == 'boss-green-alien', x))
    for g in bosses:
        cb, ca = cell(B, b, g), cell(A, b, g)
        print(f"| {STAGES[st]} | r{r6} | {s3:.0f} | {s6:.0f} | {NAMES[g]} | {cb['dps']:.0f} → {ca['dps']:.0f} | {cb['dps']/s6:.2f} → {ca['dps']/s6:.2f} | {ca['casts']/max(ca['t'],1)*60:.1f} |")
print('\n### Table C — fight length and potions at the first winning rung, before → after\n')
print('| Stage | Boss | Prestiges | Before: rung, s, potions, low HP | After: rung, s, potions, low HP |')
print('|---|---|---|---|---|')
for st in range(4, 9):
    for P in (0, 1, 3):
        bs = [f'L{st}_r{r}_P{P}' for r in range(10)]
        bosses = sorted({r['target'] for r in arows if r['build'] == bs[0] and r['enc'] == 'boss'}, key=lambda x: (x == 'boss-green-alien', x))
        for g in bosses:
            out = []
            for D in (B, A):
                f = next((r for r, b in enumerate(bs) if (cell(D, b, g) or {}).get('win')), None)
                if f is None: out.append('no win up to r9'); continue
                c = cell(D, bs[f], g); out.append(f"r{f}: {c['t']:.0f} s, {c['pots']:.0f}, {c['mn']*100:.0f}%")
            print(f"| {STAGES[st]} | {NAMES[g]} | {P} | {out[0]} | {out[1]} |")
