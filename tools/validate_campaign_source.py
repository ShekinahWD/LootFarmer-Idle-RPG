"""Deterministic source contract checks. Does not read or write player saves."""
from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[1]
c=json.loads((ROOT/'data/game/catalog.json').read_text())
checks=[]
def check(label, condition):
    checks.append({'check':label,'pass':bool(condition)})
check('8 stages / 48 types / 34 normal / 14 bosses',len(c['stages'])==8 and len(c['groups'])==48 and sum(g['boss'] for g in c['groups'])==14)
check('unique stable group ids',len({g['id'] for g in c['groups']})==48)
check('single superior final boss',sum(g['final'] for g in c['groups'])==1 and c['groups'][-1]['hp']>max(g['hp'] for g in c['groups'][:-1]))
check('three double gates', [s['id'] for s in c['stages'] if len(s['gates'])==2]==[4,6,7])
check('selling absent from item and upgrade definitions',not any('sell' in k.lower() for k in c['upgrades']) and all(not any('sell' in k.lower() for k in i) for i in c['items'].values()))
check('catalog capacity includes every tier',c['upgrades']['gear_slots']['cap']+3==sum(i['kind']!='consumable' for i in c['items'].values()) and c['upgrades']['supply_slots']['cap']+1==sum(i['kind']=='consumable' for i in c['items'].values()))
check('automerge nine reductions from ten to one',c['upgrades']['gear_merge_speed']['cap']==9 and c['upgrades']['merge_speed']['cap']==9)
check('eight baked stage scenes',all((ROOT/f'scenes/game/stages/stage_{i}.tscn').is_file() for i in range(1,9)))
for ident,entry in c['items'].items():
    for key in ['texture','icon_path','attack']:
        if key in entry:check('asset '+ident+' '+key,(ROOT/entry[key].removeprefix('res://')).is_file())
    check('successor '+ident,not entry['next'] or entry['next'] in c['items'])
for combo in c['campaign']['combos']:
    check('combo '+combo['id'],len(combo['cards'])==3 and all(x in c['campaign']['cards'] for x in combo['cards']))
strings=set(re.findall(r'^msgid "([^"]+)"$',(ROOT/'localization/en.po').read_text(),re.M))
for script in (ROOT/'scripts/game').glob('*.gd'):
    for key in re.findall(r'tr\("([A-Z_0-9]+)"\)',script.read_text()):check('translation '+key,key in strings)
for key in c['upgrades']:check('upgrade translation '+key,'UP_'+key.upper() in strings)
for s in c['stages']:
    check('season clear/effect '+str(s['id']), bool(s['weather'])==(s['id']%2==0))
# Change 6: keys built dynamically by the guide, cards and prestige panel.
steps=['move','kill','collect','collect_wait','equip','equip_tap','equip_find','equip_collect','merge','merge_tap','merge_wait','upgrade','upgrade_find','upgrade_earn','upgrade_tab','upgrade_buy','camp','camp_explore','camp_earn','camp_buy','camp_done','overview','aggression','skills','groups','prestige','rest']
for step in steps:
    for suffix in ['','_DETAIL']:check('guide translation '+step+suffix,'GUIDE_'+step.upper()+suffix in strings)
for combo in c['campaign']['combos']:check('combo name '+combo['id'],'COMBO_'+combo['id'].upper() in strings)
for tab in ['TAB_PLAYER','TAB_INVENTORY','TAB_SUPPLIES','TAB_GEMS','TAB_OFFLINE','PANEL_WORLD']:check('tab translation '+tab,tab in strings)
check('prestige opens after the first kill (Change 8; Winter II gate removed)',c['progression'].get('prestige_unlock_kills')==1 and 'prestige_gate_stage' not in c['progression'])
check('every path has card art',set(x['path'] for x in c['campaign']['cards'].values())==set(c['campaign']['paths']))
import subprocess
# Change 7: shared weapon families, stage-tiered gear and the legacy id map.
check('shared weapons: no enemy-specific weapon items',not any(re.fullmatch(r'unit-[a-z-]+_weapon(_t\d)?',k) for k in c['items']))
check('shared weapons: every group carries a Sword or Axe',all(c['items'][g['weapon']]['family'] in ('sword','axe') for g in c['groups']))
check('legacy map targets exist',all(v in c['items'] for v in c.get('legacy_items',{}).values()))
check('coin tonic duration authored',c['progression'].get('coin_boost_duration')==30.0)
for tool in ['tools/layout_campaign_groups.py','tools/tune_campaign.py','tools/share_weapons.py']:
    r=subprocess.run([sys.executable,str(ROOT/tool),'--check'],capture_output=True,text=True)
    check(tool+' --check',r.returncode==0)
report={'checks':len(checks),'failures':sum(not x['pass'] for x in checks),'results':checks}
output=ROOT/'docs/Change_8_Evidence/static_checks.json'
output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['checks','failures']}))
for item in checks:
    if not item['pass']:print('FAIL:',item['check'])
sys.exit(1 if report['failures'] else 0)
