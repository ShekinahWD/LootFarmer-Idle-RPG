import csv,statistics as S,sys
from collections import defaultdict
def load(p,key):
    D=defaultdict(list)
    for r in csv.DictReader(open(p,encoding='utf-8')):D[key(r)].append(r)
    return D
base=load('tests/tmp/c78/ladder_c78_fixed.csv',lambda r:(r['build'],r['target'],int(r['count'])))
wi=load(sys.argv[1],lambda r:(r['build'].replace('_wi',''),r['target'],r['whatif']))
def c(rs):
    return f"{'W' if all(x['result']=='win' for x in rs) else 'L'} {S.mean(float(x['player_left']) for x in rs)*100:3.0f}% {S.mean(float(x['time']) for x in rs):4.0f}s in {S.mean(float(x['incoming_dps']) for x in rs):6.1f} pot {S.mean(int(x['potions']) for x in rs):4.1f}"
last=None
for k in sorted(wi,key=lambda k:(k[1],k[2],int(k[0].split('_r')[1]))):
    if (k[1],k[2])!=last:print(f"\n{k[1]}  {k[2]}");last=(k[1],k[2])
    b=base.get((k[0],k[1],1))
    print(f"   {k[0]:7s} base {c(b):34s} | what-if {c(wi[k])}")
