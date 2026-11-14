import csv,sys,statistics as S
from collections import defaultdict
rows=list(csv.DictReader(open(sys.argv[1],encoding='utf-8')))
agg=defaultdict(list)
for r in rows: agg[(r['build'],r['target'],r['variant'],r['count'])].append(r)
last=None
for k,rs in agg.items():
    b=k[0]
    if b!=last:
        r=rs[0];print(f"\n== {b}  L{r['level']} dmg {float(r['damage']):.1f} hp {float(r['hp']):.0f} def {float(r['defense']):.1f} ls {float(r['lifesteal']):.3f} P{r['prestiges']}")
        last=b
    res='/'.join(x['result'][0] for x in rs)
    t=S.mean(float(x['time']) for x in rs); dps=S.mean(float(x['incoming_dps']) for x in rs)
    left=S.mean(float(x['player_left']) for x in rs); tl=S.mean(float(x['target_hp_left']) for x in rs)
    casts=S.mean(int(x['enemy_casts']) for x in rs); pots=S.mean(int(x['potions']) for x in rs)
    print(f"  {k[1]:26s} v{k[2]} n{k[3]}  {res:6s} t={t:6.1f}s dps_in={dps:7.1f} left={left*100:4.0f}% tgt_left={tl*100:4.0f}% ecasts={casts:4.1f} pots={pots:4.1f}")
