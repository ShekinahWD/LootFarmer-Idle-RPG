import json, copy
s=json.load(open('tests/tmp/c49/builds_ladder.json'))
by={b['id']:b for b in s['builds']}
base=['N3_rdy','N4_rdy','N4_rdy_P1','N5_rdy','N5_rdy_P1','N6_rdy','N6_rdy_P1','N7_rdy','N7_rdy_P1','N7_obs50','N8_obs60','N8_obs100','N8_obs100_P1']
sets={'base':[],'v115':['v3_115'],'stg50':['stagger50'],'stg100':['stagger100'],'v115_stg50':['v3_115','stagger50'],
      'ld75':['late_dmg75'],'ld75_stg50':['late_dmg75','stagger50'],'ld60':['late_dmg60'],'ld60_v115_stg50':['late_dmg60','v3_115','stagger50']}
L=[]
for bid in base:
    for name,tags in sets.items():
        if name.startswith('ld') and by[bid]['stage']<7:continue
        b=copy.deepcopy(by[bid]);b['id']=bid+'__'+name;b['whatif']=tags
        b['encounters']=[e for e in b['encounters'] if e['kind']!='farm']
        L.append(b)
json.dump({'seeds':[1,2,3],'card_sets':s['card_sets'],'builds':L},open('tests/tmp/c49/builds_tuning.json','w'),indent=1)
print(len(L),sum(len(b['encounters'])*3 for b in L))
