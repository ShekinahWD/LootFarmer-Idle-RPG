import csv,json,statistics as S
from collections import defaultdict
def load(p):
    D=defaultdict(list)
    for r in csv.DictReader(open(p,encoding='utf-8')):D[(r['build'],r['target'],int(r['count']),r.get('whatif',''))].append(r)
    return D
lad=load('tests/tmp/c78/ladder_c78_fixed.csv'); mat=load('tests/tmp/c78/trials_c78.csv'); w3=load('tests/tmp/c78/whatif3_c78.csv')
B=json.load(open('tests/tmp/c78/ladder_c78.json'))['builds']
R6={1:0,2:0,3:0,4:2,5:5,6:3,7:4,8:7}
NAMES={1:'Winter I',2:'Winter II',3:'Summer I',4:'Summer II',5:'Autumn I',6:'Autumn II',7:'Spring I',8:'Spring II'}
def m(rs,k):return S.mean(float(x[k]) for x in rs)
def win(rs):return all(x['result']=='win' for x in rs)
print("| Stage | Boss | Rung (L / dmg / HP) | Boss result | Fight s | Boss dmg taken/s | Potions | Boss casts/min | Strongest 3-spot taken/s | Strongest 6-spot taken/s | Boss ÷ 3-spot | Boss ÷ 6-spot | First P0 win rung |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for st in range(1,9):
    bs=[b for b in B if b['ladder']==f'S{st}' and not b['id'].endswith('_P1')]
    bosses=[e['group'] for e in bs[0]['encounters'] if e['kind']=='boss']
    spots=sorted({e['group'] for e in bs[0]['encounters'] if e['kind']=='spot'})
    for g in bosses:
        first=next((b['rung'] for b in bs if win(lad[(b['id'],g,1,'')])),None)
        r=R6[st] if st>3 else (first if first is not None else 0)
        bid=f'L{st}_r{r}'; rs=lad[(bid,g,1,'')]
        s3=max(m(lad[(bid,s,3,'')],'incoming_dps') for s in spots); s6=max(m(lad[(bid,s,6,'')],'incoming_dps') for s in spots)
        d=m(rs,'incoming_dps'); t=m(rs,'time'); casts=m(rs,'enemy_casts')/max(.1,t)*60
        res=('Win %d%% HP' % round(m(rs,'player_left')*100)) if win(rs) else 'Loss'
        print(f"| {st} {NAMES[st]} | {g[5:].replace('-',' ').title()} | r{r} (L{rs[0]['level']} / {float(rs[0]['damage']):.0f} / {float(rs[0]['hp']):.0f}) | {res} | {t:.0f} | {d:.1f} | {m(rs,'potions'):.0f} | {casts:.1f} | {s3:.1f} | {s6:.1f} | {d/s3:.2f} | {d/s6:.2f} | r{first} |")
print()
print("| Stage | Boss | Time to die, boss-ready raw build (no potions/skills) | Same build vs strongest 6-spot | P0 at r6 | P1 at r6 | P3 at r6 |")
print("|---|---|---|---|---|---|---|")
for st in range(1,9):
    bs=[b for b in B if b['ladder']==f'S{st}' and not b['id'].endswith('_P1')]
    bosses=[e['group'] for e in bs[0]['encounters'] if e['kind']=='boss']
    for g in bosses:
        raw=mat[(f'S{st}_ready_raw',g,1,'')]
        sp6=[v for k,v in mat.items() if k[0]==f'S{st}_ready_raw' and k[2]==6]
        worst6=min(sp6,key=lambda rs:m(rs,'time') if not win(rs) else 1e9)
        def f(rs):return ('W %d%% %.0fs' % (round(m(rs,'player_left')*100),m(rs,'time'))) if win(rs) else ('L %.0fs' % m(rs,'time'))
        p0=lad[(f'L{st}_r6',g,1,'')]
        p1=w3.get((f'L{st}_r6_P1',g,1,''),[]) or lad.get((f'L{st}_r6_P1',g,1,''),[])
        p3=w3.get((f'L{st}_r6_P3',g,1,''),[])
        print(f"| {st} | {g[5:].replace('-',' ').title()} | {'killed in %.0f s' % m(raw,'time') if not win(raw) else 'survives (W %d%%)' % round(m(raw,'player_left')*100)} ({m(raw,'incoming_dps'):.1f}/s on {float(raw[0]['hp']):.0f} HP) | {f(worst6)} | {f(p0)} | {f(p1) if p1 else '-'} | {f(p3) if p3 else '-'} |")
