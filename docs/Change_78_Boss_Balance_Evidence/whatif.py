import json,sys
L=json.load(open('tests/tmp/c78/ladder_c78.json'))
P={
 'boss-elephant':[{"damage":1.3,"skills":["strike","focus"],"hp":0.65},{"damage":1.2,"skills":["strike","focus"],"hp":0.75}],
 'boss-teal-dinosaur':[{"damage":1.3,"hp":0.65},{"damage":1.2,"hp":0.75}],
 'boss-squirrel':[{"damage":1.25,"skills":["strike","heal"],"hp":0.65},{"damage":1.15,"skills":["strike","heal"],"hp":0.75}],
 'boss-red-fox':[{"damage":1.15,"hp":0.75},{"damage":1.1,"hp":0.85}],
 'boss-red-panda':[{"hp":0.5,"damage":1.3},{"hp":0.5,"damage":1.2}],
 'boss-sunflower':[{"hp":0.45,"damage":1.2,"skills":["fire","heal"]},{"hp":0.5,"damage":1.1,"skills":["fire","heal"]}],
}
R={4:range(1,7),5:range(3,9),8:range(5,10)}
B=[]
for b in L['builds']:
    st=int(b['stage'])
    if st not in R or b['id'].endswith('_P1') or b['rung'] not in R[st]:continue
    enc=[]
    for e in b['encounters']:
        if e['kind']!='boss' or e['group'] not in P:continue
        for p in P[e['group']]:enc.append(dict(e,patch=p))
    b=dict(b,encounters=enc,id=b['id']+'_wi')
    B.append(b)
json.dump({"seeds":[1,2],"card_sets":L['card_sets'],"builds":B},open('tests/tmp/c78/whatif2_c78.json','w'),indent=1)
print(len(B),'builds',sum(len(b['encounters'])*2 for b in B),'trials')
