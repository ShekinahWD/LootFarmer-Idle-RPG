import csv,sys,statistics as S,json
from collections import defaultdict
rows=list(csv.DictReader(open(sys.argv[1],encoding='utf-8')))
D=defaultdict(list)
for r in rows: D[(r['build'],r['target'],int(r['count']))].append(r)
def cell(b,t,n):
    rs=D[(b,t,n)]
    return dict(win=all(x['result']=='win' for x in rs),left=S.mean(float(x['player_left']) for x in rs),t=S.mean(float(x['time']) for x in rs),
                dps=S.mean(float(x['incoming_dps']) for x in rs),pots=S.mean(int(x['potions']) for x in rs),ec=S.mean(int(x['enemy_casts']) for x in rs),
                tl=S.mean(float(x['target_hp_left']) for x in rs),hp=float(rs[0]['hp']),dmg=float(rs[0]['damage']),L=int(rs[0]['level']),taken=S.mean(float(x['taken']) for x in rs))
builds=json.load(open(sys.argv[2]))['builds']
out={}
for st in range(1,9):
    bs=[b for b in builds if b['ladder']==f'S{st}' and not b['id'].endswith('_P1')]
    bosses=[e['group'] for e in bs[0]['encounters'] if e['kind']=='boss']
    spots=sorted({(e['group'],e['variant']) for e in bs[0]['encounters'] if e['kind']=='spot'})
    print(f"\n=== Stage {st}  bosses {bosses}  spots {spots}")
    r3=r6=None
    for b in bs:
        sp3=[cell(b['id'],g,3) for g,v in spots]; sp6=[cell(b['id'],g,6) for g,v in spots]
        # spots of the same group but different variants share the target name; handle via encounter order instead
        line=f" r{b['rung']} L{sp3[0]['L']:3d} dmg {sp3[0]['dmg']:6.0f} hp {sp3[0]['hp']:6.0f} |"
        for g in bosses:
            c=cell(b['id'],g,1); line+=f" {g[5:15]:10s} {'W' if c['win'] else 'L'} {c['left']*100:3.0f}% {c['t']:5.0f}s in {c['dps']:6.1f} pot {c['pots']:4.1f} |"
        for c,n in [(x,3) for x in sp3]+[(x,6) for x in sp6]:
            line+=f" {n}:{'W' if c['win'] else 'L'}{c['left']*100:3.0f}% in{c['dps']:6.1f}"
        print(line)
        if r3 is None and all(c['win'] and c['left']>=.5 for c in sp3): r3=b['rung']
        if r6 is None and all(c['win'] and c['left']>=.25 for c in sp6): r6=b['rung']
    print(f"  -> comfortable 3-spot farming from rung {r3}; 6-spot farming from rung {r6}")
    out[st]=(r3,r6)
print(json.dumps(out))
