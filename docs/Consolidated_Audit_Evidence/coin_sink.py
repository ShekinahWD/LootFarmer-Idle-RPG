"""Finite Coin sink once every Coin upgrade is permanent (catalog formulas of campaign.upgrade_cost)."""
import json
c=json.load(open('data/game/catalog.json',encoding='utf-8'))
G=c['groups']; U=c['upgrades']; f=lambda s:1.55**(s-1)
def cost(d,n,st):
    p=d['base']*d['growth']**n
    if 'prices' in d:p=d['prices'][min(n,len(d['prices'])-1)]
    if 'step' in d:p=d['base']+d['step']*n
    return p*(f(st) if d['currency']=='coins' and not d.get('flat') else 1)
by_stage={s:0.0 for s in range(0,9)}; detail={}
for k,d in U.items():
    if d['currency']!='coins' or d['cap']==0:continue
    tot=0.0
    if d['scope'] in('type','normal_type'):
        for g in G:
            if d['scope']=='normal_type' and g['boss']:continue
            if k=='skill_drop' and not g['skills']:continue
            if k in('collect_range','collect_speed'):pass
            s=sum(cost(d,n,g['stage']) for n in range(d['cap'])); by_stage[g['stage']]+=s; tot+=s
    elif d['scope']=='stage':
        if d.get('sequence'):
            # Map Details: 3 ranks x 8 maps, one rising sequence price with a per-map floor
            seq=0
            for st in range(1,9):
                for r in range(3):
                    p=max(d['base']*d['growth']**seq,d['floor']*f(st));seq+=1;by_stage[st]+=p;tot+=p
        else:
            for st in range(1,9):
                s=sum(cost(d,n,st) for n in range(d['cap']));by_stage[st]+=s;tot+=s
    elif d['scope']=='camp':
        for st in range(1,9):
            for camp in range(1,len(c['stages'][st-1]['spawns'])):
                s=sum(cost(d,n,st) for n in range(d['cap']));by_stage[st]+=s;tot+=s
    else:
        s=sum(cost(d,n,1) for n in range(d['cap']));by_stage[0]+=s;tot+=s
    detail[k]=tot
camps=sum(([0,50,150][i])*f(st) for st in range(1,9) for i in range(len(c['stages'][st-1]['spawns'])))
print('Total finite Coin sink (every Coin upgrade to cap, all scopes): %.3g coins'%sum(detail.values()))
for k,v in sorted(detail.items(),key=lambda x:-x[1]):print('  %-22s %12.0f'%(k,v))
print('By map (type/stage/camp scopes; 0 = global):')
for s,v in by_stage.items():print('  map %d: %12.0f'%(s,v))
print('Camps per run (re-bought every Prestige): %.0f coins total, all maps'%camps)
# income reference: normal coins per kill at Coin Amount ^0 and ^20, stage base
for st in range(1,9):
    base=[g['coins'] for g in G if g['stage']==st and not g['boss']][0]
    print('  map %d normal coins/kill: ^0 %.1f, ^10 %.1f, ^20 %.1f'%(st,base,base*6,base*11))
