import csv,sys,json,statistics as st
from collections import defaultdict
def load(p):
    try: return list(csv.DictReader(open(p,encoding='utf-8')))
    except FileNotFoundError: return []
base=load('docs/Player_Feedback_Audit_Evidence/baseline_trials_main.csv')+load('docs/Player_Feedback_Audit_Evidence/baseline_trials_supplementary.csv')
L=json.load(open('tests/tmp/c49/builds_ladder.json'))['builds']
twin={b['id']:b['label'].split('(from ')[-1].rstrip(')') for b in L}
files=[a for a in sys.argv[1:] if not a.startswith('--')]
def summ(rows,bid):
    rs=[r for r in rows if r['build']==bid]
    if not rs: return None
    out={}
    g=defaultdict(list)
    for r in rs: g[(r['enc'],r['target'],r['variant'],r['count'])].append(r)
    worst3=None;worst6=None;boss=[];farm=[]
    for k,v in g.items():
        w=sum(r['result']=='win' for r in v); hp=st.median(float(r['player_left']) for r in v)
        score=(w,hp)
        if k[0]=='spot':
            tgt=k[1].replace('unit-','')+(' sk' if k[2]=='3' else ' v'+k[2])
            if k[3]=='3' and (worst3 is None or score<worst3[0]): worst3=(score,tgt)
            if k[3]=='6' and (worst6 is None or score<worst6[0]): worst6=(score,tgt)
        elif k[0]=='boss': boss.append('%s %d/%d %d%% %.0fs'%(k[1].replace('boss-',''),w,len(v),hp*100,st.median(float(r['time']) for r in v)))
        elif k[0]=='farm':
            r=v[0]; m=max(.1,float(r['minutes']))
            farm.append('%s k/m %.1f xp/m %.0f d/10m %.0f'%(k[1].replace('unit-','')+'v'+k[2],float(r['kills'])/m,float(r['xp'])/m,float(r['deaths'])*10/m))
    f=lambda x:'-' if x is None else '%d/3 %d%% %s'%(x[0][0],x[0][1]*100,x[1])
    w3=sum(1 for k,v in g.items() if k[0]=='spot' and k[3]=='3' and all(r['result']=='win' for r in v)); n3=sum(1 for k in g if k[0]=='spot' and k[3]=='3')
    r0=rs[0]
    return {'dmg':float(r0['damage']),'hp':float(r0['hp']),'s3':f'{w3}/{n3}','w3':f(worst3),'w6':f(worst6),'boss':'; '.join(boss),'farm':'; '.join(farm)}
for b in L:
    bid=b['id']
    print(f'## {bid}  [{b["label"]}]')
    t=summ(base,twin[bid])
    if t: print(f'  baseline twin {twin[bid]:26s} dmg {t["dmg"]:7.1f} hp {t["hp"]:7.0f} | 3-spots {t["s3"]} worst {t["w3"]} | x6 {t["w6"]} | {t["boss"]}')
    for p in files:
        s=summ(load(p),bid)
        if s: print(f'  {p.split("/")[-1][:-4]:40s} dmg {s["dmg"]:7.1f} hp {s["hp"]:7.0f} | 3-spots {s["s3"]} worst {s["w3"]} | x6 {s["w6"]} | {s["boss"]}'+(f' | FARM {s["farm"]}' if s['farm'] else ''))
