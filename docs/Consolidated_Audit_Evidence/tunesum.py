import csv,statistics as st,sys
from collections import defaultdict
rows=list(csv.DictReader(open(sys.argv[1],encoding='utf-8')))
g=defaultdict(lambda:defaultdict(list))
for r in rows:
    b,v=r['build'].split('__'); g[b][v].append(r)
order=['base','v115','stg50','stg100','v115_stg50','ld75','ld75_stg50','ld60','ld60_v115_stg50']
print('build | variant | 3-spots won | 6-spots won | worst 6 | bosses (HP left)')
for b in g:
    for v in order:
        rs=g[b].get(v)
        if not rs:continue
        e=defaultdict(list)
        for r in rs:e[(r['enc'],r['target'],r['variant'],r['count'])].append(r)
        s3=[k for k in e if k[0]=='spot' and k[3]=='3'];s6=[k for k in e if k[0]=='spot' and k[3]=='6']
        win=lambda k:all(r['result']=='win' for r in e[k])
        hp=lambda k:st.median(float(r['player_left']) for r in e[k])
        w6=min(s6,key=lambda k:(sum(r['result']=='win' for r in e[k]),hp(k))) if s6 else None
        bs=[f"{k[1].replace('boss-','')} {sum(r['result']=='win' for r in e[k])}/3 {hp(k)*100:.0f}%" for k in e if k[0]=='boss']
        print(f"{b} | {v} | {sum(map(win,s3))}/{len(s3)} | {sum(map(win,s6))}/{len(s6)} | "+(f"{w6[1].replace('unit-','')} v{w6[2]} {sum(r['result']=='win' for r in e[w6])}/3 {hp(w6)*100:.0f}%" if w6 else '-')+" | "+'; '.join(bs))
