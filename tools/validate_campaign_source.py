"""Deterministic source contract checks. Does not read or write player saves.

Usage: python tools/validate_campaign_source.py [--output PATH]
The JSON report goes to tests/tmp/static_checks.json (ignored by Git) unless --output names another
file (Change 24: a test run never rewrites archived evidence such as docs/Change_21_Evidence)."""
from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[1]
c=json.loads((ROOT/'data/game/catalog.json').read_text(encoding='utf-8'))
checks=[]
def check(label, condition):
    checks.append({'check':label,'pass':bool(condition)})
check('8 stages / 48 types / 34 normal / 14 bosses',len(c['stages'])==8 and len(c['groups'])==48 and sum(g['boss'] for g in c['groups'])==14)
check('unique stable group ids',len({g['id'] for g in c['groups']})==48)
check('single superior final boss',sum(g['final'] for g in c['groups'])==1 and c['groups'][-1]['hp']>max(g['hp'] for g in c['groups'][:-1]))
check('three double gates', [s['id'] for s in c['stages'] if len(s['gates'])==2]==[4,6,7])
check('selling absent from item and upgrade definitions',not any('sell' in k.lower() for k in c['upgrades']) and all(not any('sell' in k.lower() for k in i) for i in c['items'].values()))
# Change 10: exactly 70 equipment slots (3 + 67), enough for every reachable equipment identity.
sys.path.insert(0,str(ROOT/'tools'))
import change10_catalog
check('equipment capacity is 70 and holds every reachable identity',c['upgrades']['gear_slots']['cap']+3==70 and len(change10_catalog.reachable_equipment(c))<=70)
check('supply capacity is six total slots',c['upgrades']['supply_slots']['cap']+1==6)
check('boss Gem payout multiplier',c['progression']['gem_limits'].get('boss_amount_multiplier')==3)
check('automerge nine reductions from ten to one',c['upgrades']['gear_merge_speed']['cap']==9)
check('eight baked stage scenes',all((ROOT/f'scenes/game/stages/stage_{i}.tscn').is_file() for i in range(1,9)))
for ident,entry in c['items'].items():
    for key in ['texture','icon_path','attack']:
        if key in entry:check('asset '+ident+' '+key,(ROOT/entry[key].removeprefix('res://')).is_file())
    check('successor '+ident,not entry['next'] or entry['next'] in c['items'])
for combo in c['campaign']['combos']:
    check('combo '+combo['id'],len(combo['cards'])==3 and all(x in c['campaign']['cards'] for x in combo['cards']))
strings=set(re.findall(r'^msgid "([^"]+)"$',(ROOT/'localization/en.po').read_text(encoding='utf-8'),re.M))
for script in (ROOT/'scripts/game').glob('*.gd'):
    for key in re.findall(r'tr\("([A-Z_0-9]+)"\)',script.read_text(encoding='utf-8')):check('translation '+key,key in strings)
for key in c['upgrades']:check('upgrade translation '+key,'UP_'+key.upper() in strings)
for s in c['stages']:
    check('season clear/effect '+str(s['id']), bool(s['weather'])==(s['id']%2==0))
# Change 6: keys built dynamically by the guide, cards and prestige panel.
steps=['move','kill','collect','collect_wait','equip','equip_tap','equip_find','equip_collect','merge','merge_tap','merge_wait','upgrade','upgrade_find','upgrade_earn','upgrade_tab','upgrade_buy','camp','camp_explore','camp_earn','camp_buy','camp_done','overview','aggression','skills','groups','prestige','rest',
    # Change 15: lessons and Basic cards of the reveal sequence.
    'missions','missions_claim','missions_wait','slots','slots_tab','slots_buy','slots_supply_tab','slots_potion','slots_earn','snowman','prestige_open','prestige_follow','prestige_info','tip_equip','tip_merge',
    # Change 16: the View Camp step of the camp lesson.
    'camp_view']+['feature_'+f for f in ['missions','enemy','world','upgrades','objective','prestige']]
for step in steps:
    for suffix in ['','_DETAIL']:check('guide translation '+step+suffix,'GUIDE_'+step.upper()+suffix in strings)
for combo in c['campaign']['combos']:check('combo name '+combo['id'],'COMBO_'+combo['id'].upper() in strings)
for tab in ['TAB_PLAYER','TAB_INVENTORY','TAB_SUPPLIES','TAB_GEMS','TAB_OFFLINE','PANEL_WORLD']:check('tab translation '+tab,tab in strings)
check('prestige opens after the first boss, the Snowman (Change 8; Winter II gate removed)',c['progression'].get('prestige_unlock_boss')=='boss-snowman' and 'prestige_unlock_kills' not in c['progression'] and 'prestige_gate_stage' not in c['progression'])
check('every path has card art',set(x['path'] for x in c['campaign']['cards'].values())==set(c['campaign']['paths']))
import subprocess
# Change 7: shared weapon families, stage-tiered gear and the legacy id map.
check('shared weapons: no enemy-specific weapon items',not any(re.fullmatch(r'unit-[a-z-]+_weapon(_t\d)?',k) for k in c['items']))
check('shared weapons: every group carries a Sword or Axe',all(c['items'][g['weapon']]['family'] in ('sword','axe') for g in c['groups']))
check('legacy map targets exist',all(v in c['items'] for v in c.get('legacy_items',{}).values()))
check('coin tonic duration authored',c['items']['coin_boost']['supply']['duration']==30)
# Change 11: supplies are single identities with permanent mastery; gem upgrades survive Prestige.
supplies={k:i for k,i in c['items'].items() if i['kind']=='consumable'}
check('five supplies, no tiers or evolution',sorted(supplies)==sorted(['potion','coin_boost','guard_tonic','recovery_salve','wisdom_tonic']) and all(i['next']=='' and i['tier']==1 for i in supplies.values()))
check('supply mastery doubles the base at ^100',c['progression']['supply_mastery']['cap']==100 and all(abs(list(i['normal'].values())[0][1]*100-list(i['normal'].values())[0][0])<1e-6 for i in supplies.values()))
check('every supply drops from some stage',all(1<=i['supply']['min_stage']<=8 and i['supply']['drop_weight']>0 for i in supplies.values()))
check('retired supply tiers fold into their base supply',all(c['legacy_items'].get(f'{b}_tier_{t}')==b for b in ['potion','coin_boost'] for t in range(2,8)))
check('supply auto-merge upgrades removed',not any(k in c['upgrades'] for k in ['merge_supplies','merge_speed']))
check('every gem upgrade is kept by Prestige',all(u['keep'] for u in c['upgrades'].values() if u['currency']=='gems'))
check('spawn prices (Change 11): amount 75/125/200, cooldown 50/100/150/225/300',c['upgrades']['spawn_amount']['prices']==[75,125,200] and c['upgrades']['spawn_cooldown']['prices']==[50,100,150,225,300])
check('every upgrade has one currency',all(u['currency'] in ('coins','gems') for u in c['upgrades'].values()))
# Change 9: outfit growth, milestones, passive shares and the Spring II correction.
m=c['progression']['merge']
check('outfit growth: ^500 cap, 1% per copy past ^100',m['copy_cap']==500 and m['linear_levels']==100 and m['outfit_tail_rate']==0.5)
check('outfit merge gain is 2% of base',all(abs(i['merge_gain']['hp']-0.02*i['normal']['hp'][0])<1e-6 for i in c['items'].values() if i['kind']=='outfit'))
check('outfit milestones ascend ^100..^500',[s_['merge'] for s_ in c['progression']['outfit_milestones']]==[100,200,300,400,500])
check('stored shares: outfits 15%, weapons 30%',c['progression']['stored_outfit_factor']==0.15 and c['progression']['stored_weapon_factor']==0.3)
spring=[g for g in c['groups'] if g['stage']==8]
check('Spring II: Tier 7 (Obsidian) weapons for normals and bosses (Change 51), Tier 5 outfits',all(c['items'][g['weapon']]['tier']==7 and c['items'][g['loot'][1]]['tier']==5 and not c['items'][g['loot'][1]].get('legacy') for g in spring))
check('final boss dedicated HP factor 18',c['progression']['balance']['final_hp']==18.0)
check('dropped gear is never legacy',all(not c['items'][i].get('legacy') for g in c['groups'] for i in g['loot']))
# Change 12: gem chance 5% base, 20 x 0.5-point levels (old 12 prices kept), Gem Wisdom +5, no caps;
# Merge All unlock; stone-tier swing sheet.
g12=c['upgrades']['gem_chance']
check('gem chance: base 5%, 20 levels of +0.5 points, no game caps',c['progression']['gem_limits']['base_chance']==0.05 and g12['cap']==20 and g12['effect']==0.005 and 'normal_cap' not in c['progression']['gem_limits'] and 'boss_cap' not in c['progression']['gem_limits'])
check('gem chance prices: level 1 = 10 (Change 66), 2-12 unchanged, 13-20 rising',g12['prices'][:12]==[10,40,58,80,105,135,170,210,260,320,390,470] and all(b>a for a,b in zip(g12['prices'],g12['prices'][1:])) and len(g12['prices'])==20)
check('Gem Wisdom +5 points',c['campaign']['cards']['offering_c2']['effect']=='gem_chance' and c['campaign']['cards']['offering_c2']['value']==0.05)
# Change 70/71: Merge All costs 500 Gems (approved price change; existing owners keep their unlock).
check('Merge All: one-time 500-gem global unlock',c['upgrades']['merge_all']=={'currency':'gems','base':500,'growth':1,'cap':1,'keep':True,'effect':1,'scope':'global'})
check('stone-tier weapons swing with the tinted Iron set',all(c['items'][i]['attack'].endswith('Iron set/%s 2 64x32.png' % k) and len(c['items'][i]['attack_tint'])==3 for i,k in [('stone_axe','Axe'),('stone_sword','Sword')]))
# Change 13: skill cooldowns and unlock prices, potion cooldown and floor, flat Auto Evolution, enemy
# ability and weather resources.
sk={k:v['cooldown'] for k,v in c['skills'].items()}
check('all six skill base cooldowns 20 seconds',sk=={k:20 for k in c['skills']})
check('auto-cast 100/250/500 gems, skill slots 300/600 gems',[c['upgrades']['skill_auto_%d' % i]['base'] for i in range(3)]==[100,250,500] and c['upgrades']['skill_slots']['prices']==[300,600] and c['upgrades']['skill_slots']['cap']==2)
check('potion 12 s cooldown with a 10 s mastery floor',c['items']['potion']['supply']['cooldown']==12 and c['items']['potion']['supply']['cooldown_floor']==10)
check('Change 65 Focused Farming: one-time global 25-gem Player upgrade',c['upgrades']['focus']=={'currency':'gems','base':25,'growth':1,'cap':1,'keep':True,'effect':1,'scope':'global'})
# Change 66: kill achievements reward damage only (no Gem Chance part); Gem Chance level 1 costs 10 Gems.
check('Change 66 kill achievements: +5% damage per milestone, no gem chance',c['progression']['achievements']['damage_per_milestone']==0.05 and 'gems_per_milestone' not in c['progression']['achievements'])
check('Auto Evolution: one-time flat 2,000-gem per-type unlock',c['upgrades']['auto_evolve']=={'currency':'gems','base':2000,'growth':1,'cap':1,'keep':True,'effect':1,'scope':'type','flat':True})
ab=(ROOT/'resources/game/enemy_abilities.tres').read_text(encoding='utf-8')
ids={g['id']:g for g in c['groups']}
pairs=re.findall(r'summoner_id = "([a-z-]+)"\nhelper_id = "([a-z-]+)"',ab)
check('2-3 summoning types incl. the final boss, later stages, helpers are normal types of the same map',2<=len(pairs)<=3 and any(ids[s]['final'] for s,_ in pairs) and all(ids[s]['stage']>=3 and not ids[h]['boss'] and ids[h]['stage']==ids[s]['stage'] for s,h in pairs))
check('final boss attack pool uses existing skills',all(k in c['skills'] for k in re.search(r'final_attack_pool = PackedStringArray\(([^)]*)\)',ab).group(1).replace('"','').replace(' ','').split(',')))
# Change 16: map economy (income x1.5 per map, map-tied coin prices x1.55), Gem Auto-Collect and Collect
# Batch, the potion's 10% -> 20% heal, the Cyan Robot's 12 s Heal, the Mastery reward swap, the boss
# warning cue, and the strings the new HUD and scenes use.
check('coin income: normal 1.5^(stage-1), bosses 8x',all(abs(g['coins']-1.5**(g['stage']-1)*(8 if g['boss'] else 1))<1e-6 for g in c['groups']))
check('map-tied coin prices grow 1.55 per map, a little faster than income',c['progression'].get('map_cost_growth')==1.55 and c['progression'].get('map_reward_growth')==1.5)
check('Auto-Collect: Gems, 20 on Winter I, kept',{k:c['upgrades']['collect'][k] for k in ['currency','base','cap','keep','scope']}=={'currency':'gems','base':20,'cap':1,'keep':True,'scope':'type'})
check('Collect Batch: Gems, 50 on Winter I, x3 per level, 5 levels, kept',{k:c['upgrades']['collect_batch'][k] for k in ['currency','base','growth','cap','keep','scope']}=={'currency':'gems','base':50,'growth':3.0,'cap':5,'keep':True,'scope':'type'})
check('Health Potion heals 10% at ^0 and 20% at ^100 before bonuses',c['items']['potion']['normal']['heal_pct']==[0.1,0.001])
ab16=(ROOT/'resources/game/enemy_abilities.tres').read_text(encoding='utf-8')
check('Boss skills every 10 s (Change 62; catalog Heal 20 s for the player and normal enemies)','boss_skill_cooldown = 10.0' in ab16 and 'boss-cyan-robot:heal' not in ab16 and c['skills']['heal']['cooldown']==20)
mr=(ROOT/'resources/game/mastery_rules.tres').read_text(encoding='utf-8')
# Change 70/71: Winter I gives +2 pts Gem Chance (was +10% Coins) and Autumn II +5 pts (was +2).
check('Mastery rewards: Winter I +2 pts Gem Chance, Autumn II +5 pts Gem Chance, Spring II +15% HP','[{"gem_chance": 0.02}, {"xp": 0.1}' in mr and '{"gear_chance": 0.01}, {"gem_chance": 0.05}, {"damage": 0.15}, {"hp": 0.15}]' in mr)
check('boss warning cue uses the mission-ready sound','id = "boss_found"\nstream = ExtResource("s8")' in (ROOT/'resources/game/audio_cues.tres').read_text(encoding='utf-8'))
for scene in ['scenes/game/main.tscn','scenes/game/prestige_confirm.tscn','scenes/game/review_invitation.tscn']:
    for key in re.findall(r'^text="([A-Z][A-Z0-9]*_[A-Z0-9_]+)"$',(ROOT/scene).read_text(encoding='utf-8'),re.M):check('scene translation '+key,key in strings)
for key in ['MAIN_HINT_%d' % i for i in range(16)]+['MISSION_DO_'+k.upper() for k in ['kill','boss','gear','merge','coins','cast']]+['FOLLOW_GOAL_'+k.upper() for k in ['kill','gear','merge','boss','cast','mission']]+['SKILL_DESC_'+k.upper() for k in c['skills']]:check('Change 16 translation '+key,key in strings)
check('no double dashes in the English strings (Playbook 74)','--' not in ''.join(re.findall(r'^msgstr "(.*)"$',(ROOT/'localization/en.po').read_text(encoding='utf-8'),re.M)))
for w in ['rain','leaves','blue_leaves']:check('weather style '+w,(ROOT/f'resources/game/weather_{w}.tres').is_file())
for tool in ['tools/layout_campaign_groups.py','tools/tune_campaign.py','tools/share_weapons.py','tools/change8_catalog.py','tools/change9_catalog.py','tools/change10_catalog.py','tools/change11_catalog.py','tools/change12_catalog.py','tools/change13_catalog.py','tools/change16_catalog.py','tools/change53_catalog.py','tools/change54_catalog.py','tools/change56_catalog.py','tools/change62_catalog.py','tools/change79_catalog.py','tools/change81_catalog.py']:
    r=subprocess.run([sys.executable,str(ROOT/tool),'--check'],capture_output=True,text=True)
    check(tool+' --check',r.returncode==0)
report={'checks':len(checks),'failures':sum(not x['pass'] for x in checks),'results':checks}
output=ROOT/'tests/tmp/static_checks.json'
if '--output' in sys.argv and sys.argv.index('--output')+1<len(sys.argv):output=Path(sys.argv[sys.argv.index('--output')+1]).resolve()
output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes((json.dumps(report,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:report[k] for k in ['checks','failures']}))
for item in checks:
    if not item['pass']:print('FAIL:',item['check'])
sys.exit(1 if report['failures'] else 0)
