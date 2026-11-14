import json
L=json.load(open('tests/tmp/c78/ladder_c78.json'))
REC={
 'boss-elephant':{"damage":1.6,"skills":["strike","focus"],"hp":0.75},
 'boss-teal-dinosaur':{"damage":1.6,"hp":0.75},
 'boss-squirrel':{"damage":1.5,"skills":["strike","heal"],"hp":0.75},
 'boss-red-fox':{"damage":1.4,"hp":0.75},
 'boss-black-cat':{"damage":1.3},
 'boss-grim-reaper':{"damage":1.2},
 'boss-bee':{"damage":1.3},
 'boss-orange-tabby-cat':{"damage":1.25},
 'boss-red-panda':{"hp":0.5,"damage":1.5},
 'boss-sunflower':{"hp":0.5,"damage":1.4,"skills":["fire","heal"]},
}
B=[]
for b in L['builds']:
    st=int(b['stage'])
    if st<4 or b['id'].endswith('_P1') or b['rung'] not in (3,6,9):continue
    for tag,pre in (("P0",[]),("P1",["p1"]),("P3",["p1","p2","p3"])):
        enc=[dict(e,patch=REC[e['group']]) for e in b['encounters'] if e['kind']=='boss']
        B.append(dict(b,id=b['id']+'_'+tag,prestige=pre,encounters=enc))
json.dump({"seeds":[1,2],"card_sets":L['card_sets'],"builds":B},open('tests/tmp/c78/whatif4_c78.json','w'),indent=1)
print(len(B),'builds',sum(len(b['encounters'])*2 for b in B),'trials')
