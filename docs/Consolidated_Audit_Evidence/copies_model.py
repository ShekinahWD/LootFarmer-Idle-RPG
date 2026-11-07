"""Copies/time to merge and evolve (PROJECTED from catalog drop rules + measured kill rates).
Exact rules (simulation.gd): each kill rolls every item in the variant's loot independently with
p = gear_chance + 0.005*Loot level (cap 15) + Collection II card 0.03; v0 drops outfit only, v1 weapon only,
v2/v3 both. Boss: 0.30 base, respawn 60 s. Copies needed from first drop: total = 1 + merge + spares."""
import random, statistics as st
random.seed(49)
cands={'current ^100+100':(100,100),'^30+10':(30,10),'preferred ^20+10':(20,10),'^10+10':(10,10)}
# focus-farm kill rates (kills/min) measured on a v2 spot at boss-ready builds (baseline FARM rows; S5-S8 from C49 ladder farms if available)
import sys, json, os
kr={1:22.0,2:20.0,3:15.0,4:13.3,5:12.0,6:11.0,7:9.0,8:7.0}
if os.path.exists('tests/tmp/c49/killrates.json'): kr.update({int(k):v for k,v in json.load(open('tests/tmp/c49/killrates.json')).items()})
def kills_needed(n,p,trials=4000):
    out=[]
    for _ in range(trials):
        k=0;got=0
        while got<n:
            k+=1
            if random.random()<p: got+=1
        out.append(k)
    out.sort(); return out[int(.1*trials)],out[int(.5*trials)],out[int(.9*trials)]
print('Copies needed (exact): total acquired = 1 + merge + spares')
for name,(m,s) in cands.items(): print(f'  {name:18s} merge {m:3d} spares {s:3d} total {1+m+s:3d}  (repeat evolution after the first: +{s} copies each)')
print('\nKills of weapon-carrying actors (v1/v2) for N copies of ONE weapon id; P10 / P50 / P90 (Monte Carlo 4000)')
for label,p in [('base 5%',.05),('Loot ^5 7.5%',.075),('Loot ^15 12.5%',.125),('Loot ^15 + Collection II 15.5%',.155)]:
    for n in (21,31,41,201):
        if n==201 and p>.06: pass
        a,b,c=kills_needed(n-1,p,2000 if n==201 else 4000)
        print(f'  {label:32s} {n:3d} copies: {a:5d} / {b:5d} / {c:5d} kills')
print('\nMinutes of focus farming one weapon spot (P50, P90) at the stage kill rate (first copy included in count)')
hdr='  stage kills/min | '+' | '.join(f'{n} copies base / Loot15' for n in (21,31,41,201))
print(hdr)
for s in range(1,9):
    cells=[]
    for n in (21,31,41,201):
        r=[]
        for p in (.05,.125):
            mean=(n)/p/kr[s]
            r.append(f'{mean:5.0f}')
        cells.append(' / '.join(r))
    print(f'  S{s} {kr[s]:5.1f}       | '+' | '.join(cells))
print('\n  (mean minutes = copies / p / kills per minute; P90 is ~1.25x (31 copies) to ~1.1x (201) the mean at these counts)')
