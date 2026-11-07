"""Change 49 audit build files (tests/tmp only, git-ignored). Proposed-ladder builds reuse the baseline
builds' level, outfit, skills, supplies, kills, Prestige sets and encounter lists; only the weapon and
stored weapons change. Model: one weapon tier per stage, non-final tiers stop merging at ^20 (evolution
requirement), Obsidian merges to ^100. Run with --patch=tiers_<table>,s3aggro_<mode>."""
import json, copy
E='docs/Player_Feedback_Audit_Evidence/'
main=json.load(open(E+'builds_main.json')); sup=json.load(open(E+'builds_supplementary.json'))
cat=json.load(open('data/game/catalog.json',encoding='utf-8'))
by={b['id']:b for b in main['builds']+sup['builds']}
T=['wood','stone','iron','gold','diamond','emerald','obsidian']
def w(t,fam='axe'): return T[t-1]+'_'+fam
def normals(st): return [g['id'] for g in cat['groups'] if g['stage']==st and not g['boss']]
def mk(base,new_id,weapon,stored,label,extras=None,farm=False):
    b=copy.deepcopy(by[base]); b['id']=new_id; b['weapon']=weapon; b['stored']=stored
    b['label']='[C49 ladder] '+label+' (from '+base+')'
    if extras: b['extras']=extras
    if farm:
        ns=normals(b['stage'])
        b['encounters']=b['encounters']+[{'kind':'farm','group':ns[0],'variant':2,'minutes':5,'seeds':[1]},{'kind':'farm','group':ns[-1],'variant':1,'minutes':5,'seeds':[1]}]
    return b
# stage: (arrival base, mid base, ready base, ready-P1 base)
S={2:('W2_L10_arrive','W2_L16_snow','W2_L20_snow','W2_L20_snow_P1'),
   3:('S3_L22_arrive','S3_L28_snow','S3_L35_snow','S3_L35_snow_P1'),
   4:('S4_L38_arrive_manual_P0','S4_L38_arrive_manual_P1','S4_L60_ready_P0','S4_L60_ready_P1'),
   5:('S5_L65_arrive_manual_P0','S5_L65_arrive_manual_P1','S5_L95_ready_P0','S5_L95_ready_P1'),
   6:('S6_L95_arrive_manual_P0','S6_L95_arrive_manual_P1','S6_L140_ready_P0','S6_L140_ready_P1'),
   7:('S7_L140_arrive_manual_P0','S7_L140_arrive','S7_L195_ready_P0','S7_L195_ready_P1'),
   8:('S8_L195_arrive_manual_P0','S8_L195_arrive','S8_L240_ready_P0','S8_L240_ready_P1')}
L=[mk('W1_L9_wood20','N1_rdy',['wood_axe',20],[],'W1 ready: Wood Axe ^20 (unchanged)',farm=True)]
for s,(arr,mid,rdy,rdy1) in S.items():
    prev=min(s-1,7); cur=min(s,7)
    st_prev=[[w(prev-1),20]] if prev>1 else []
    arr_w=[w(prev),20] if s<8 else [w(7),20]
    L.append(mk(arr,f'N{s}_arr',arr_w,st_prev,f'S{s} arrival: {arr_w[0]} ^{arr_w[1]}'))
    if s<8:
        L.append(mk(mid,f'N{s}_mid',[w(cur),10],[[w(prev),20]],f'S{s} mid: {w(cur)} ^10'))
        L.append(mk(rdy,f'N{s}_rdy',[w(cur),20],[[w(prev),20]],f'S{s} ready: {w(cur)} ^20',farm=True))
        L.append(mk(rdy1,f'N{s}_rdy_P1',[w(cur),20],[[w(prev),20]],f'S{s} ready P1: {w(cur)} ^20'))
    if s<7:
        L.append(mk(rdy,f'N{s}_evo',[w(cur+1),0],[[w(cur),20],[w(prev),20]],f'S{s} evolved: {w(cur+1)} ^0 + {w(cur)} ^20 stored'))
    if s==7:
        L.append(mk(rdy,'N7_obs50',[w(7),50],[[w(6),20]],'S7 ready: Obsidian Axe ^50'))
    if s==8:
        L.append(mk(rdy,'N8_obs60',[w(7),60],[[w(6),20]],'S8 mid: Obsidian Axe ^60',farm=True))
        L.append(mk(rdy,'N8_obs100',[w(7),100],[[w(6),20]],'S8 ready: Obsidian Axe ^100',farm=True))
        L.append(mk(rdy1,'N8_obs100_P1',[w(7),100],[[w(6),20]],'S8 ready P1: Obsidian Axe ^100'))
# Sword vs Axe twins
L.append(mk('S3_L35_snow','N3_rdy_sword',['iron_sword',20],[['stone_axe',20]],'S3 ready: Iron Sword ^20'))
L.append(mk('S7_L195_ready_P0','N7_rdy_sword',['obsidian_sword',20],[['emerald_axe',20]],'S7 ready: Obsidian Sword ^20'))
# boss-enhanced value probe (base extra + two boss extras), mean and max rolls of the live weapon pool
L.append(mk('S3_L35_snow','N3_rdy_enh_mean',['iron_axe',20],[['stone_axe',20]],'S3 ready, 3 extras at mean roll',{'speed':0.04,'crit':0.02,'crit_damage':0.10}))
L.append(mk('S3_L35_snow','N3_rdy_enh_max',['iron_axe',20],[['stone_axe',20]],'S3 ready, 3 extras at max roll',{'speed':0.06,'crit':0.03,'lifesteal':0.015}))
L.append(mk('S7_L195_ready_P0','N7_rdy_enh_max',['obsidian_axe',20],[['emerald_axe',20]],'S7 ready, 3 extras at max roll',{'speed':0.06,'crit':0.03,'lifesteal':0.015}))
json.dump({'seeds':[1,2,3],'card_sets':main['card_sets'],'builds':L},open('tests/tmp/c49/builds_ladder.json','w'),indent=1)
ids=[b['id'] for b in main['builds'] if b['id'].startswith(('S3_','LAD_S3_snow_L','LAD_S3_normal','NB_S3','FARM_S3','FARM_SW_S3'))]+['S3_L22_guaranteed','FARM_S3v6_L28','FARM_S3v6_L35']
ctl=[copy.deepcopy(by[i]) for i in ids if i in by]
json.dump({'seeds':[1,2,3],'card_sets':main['card_sets'],'builds':ctl},open('tests/tmp/c49/builds_s3control.json','w'),indent=1)
n=lambda bs:sum(sum(len(e.get('seeds',b.get('seeds',[1,2,3]))) for e in b['encounters']) for b in bs)
print(len(L),'ladder builds',n(L),'trials;',len(ctl),'control builds',n(ctl),'trials')
