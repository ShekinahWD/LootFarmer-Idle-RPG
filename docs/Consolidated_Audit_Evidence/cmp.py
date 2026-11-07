import csv,sys,statistics as st
from collections import defaultdict
def load(p): return list(csv.DictReader(open(p,encoding='utf-8')))
base=load('docs/Player_Feedback_Audit_Evidence/baseline_trials_main.csv')+load('docs/Player_Feedback_Audit_Evidence/baseline_trials_supplementary.csv')
def key(r): return (r['build'],r['enc'],r['target'],r['variant'],r['count'])
def agg(rows):
    g=defaultdict(list)
    for r in rows: g[key(r)].append(r)
    return g
def cell(rs):
    if not rs: return '-'
    if rs[0]['enc']=='farm':
        return 'k/m %.1f d/10m %.0f'%(st.mean(float(r['kills'])/max(.1,float(r['minutes'])) for r in rs), st.mean(float(r['deaths'])*10/max(.1,float(r['minutes'])) for r in rs))
    w=sum(r['result']=='win' for r in rs)
    return '%d/%d %3.0f%%'%(w,len(rs),100*st.median(float(r['player_left']) for r in rs))
if __name__=='__main__':
    B=agg(base); files=[a for a in sys.argv[1:] if not a.startswith('--')]; outs=[agg(load(p)) for p in files]
    for r in [x for x in outs[0]]:
        pass
    print('invalid:',[ (r['build'],r['why']) for p in files for r in load(p) if r['result']=='invalid'])
    keys=list(outs[0].keys())
    print('build | enc | base | '+' | '.join(files))
    for k in keys:
        cells=[cell(B.get(k,[]))]+[cell(o.get(k,[])) for o in outs]
        if len(set(cells))>1 or '--all' in sys.argv: print(' | '.join([k[0],f'{k[1]} {k[2]} v{k[3]} n{k[4]}']+cells))
