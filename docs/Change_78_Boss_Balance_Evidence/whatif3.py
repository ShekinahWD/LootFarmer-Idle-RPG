import json
L=json.load(open('tests/tmp/c78/ladder_c78.json'))
REC={
 'boss-elephant':{"damage":1.2,"skills":["strike","focus"],"hp":0.75},
 'boss-teal-dinosaur':{"damage":1.2,"hp":0.75},
 'boss-squirrel':{"damage":1.15,"skills":["strike","heal"],"hp":0.75},
 'boss-red-fox':{"damage":1.15,"hp":0.75},
 'boss-red-panda':{"hp":0.5,"damage":1.2},
 'boss-sunflower':{"hp":0.5,"damage":1.1,"skills":["fire","heal"]},
}
B=[]
for b in L['builds']:
    st=int(b['stage'])
    if st<4 or b['id'].endswith('_P1') or b['rung'] not in (3,6,9):continue
    for tag,pre in (("P1",["p1"]),("P3",["p1","p2","p3"])):
        enc=[]
        for e in b['encounters']:
            if e['kind']!='boss':continue
            enc.append(dict(e))
            if e['group'] in REC:enc.append(dict(e,patch=REC[e['group']]))
        nb=dict(b,id=b['id']+'_'+tag,prestige=pre,encounters=enc)
        B.append(nb)
json.dump({"seeds":[1,2],"card_sets":L['card_sets'],"builds":B},open('tests/tmp/c78/whatif3_c78.json','w'),indent=1)
print(len(B),'builds',sum(len(b['encounters'])*2 for b in B),'trials')
