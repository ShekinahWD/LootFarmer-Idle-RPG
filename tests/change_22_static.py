"""Static guardrails for the Change 22 patch. Run from any working directory."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
read=lambda path: (ROOT/path).read_text(encoding='utf-8')
ui=read('scripts/game/game_ui.gd')
flow=read('scripts/game/guided_progress.gd')
guide=read('scripts/game/tutorial_guide.gd')
campaign=read('scripts/game/campaign.gd')
po=read('localization/en.po')
config=json.loads(read('data/game/catalog.json'))['progression']['change20']
checks={
 '15-second mission wait':config['mission_delay']==15,
 '15-second upgrade wait':config['upgrade_delay']==15,
 'unchanged final delay':config['final_delay']==5,
 'waits use real frame dt': 'sim.campaign.guided.advance_waits(dt)' in guide,
 'waits do not rely on physics playtime': 'now()-float(f.times.get(' not in flow,
 'wait persistence': 'wait_seconds' in flow and 'wait_seconds' in read('docs/LootFarmer_State_Contracts.md'),
 'wait paused guard': 'not get_tree().paused and not sim.suspended' in guide,
 'auto claim guide mode none': 'if not _road_ahead_if_ready(data):_mission_auto_hint()' in guide,
 'auto claim target metadata': 'toggle.set_meta("guide","mission_auto_toggle")' in ui,
 'auto claim ON acknowledgement': 'sim.state.tutorial.seen.append("mission_auto_enabled")' in ui,
 'auto claim only regular mission copy': 'Main Objectives' in po and 'purchased slots' in po,
 'stage collapse button': 'header.set_meta("prestige_stage",st)' in ui,
 'stage completion default': 'choices.get(key,completed==total)' in ui,
 'saved stage preferences': '"prestige_collapsed":{}' in campaign and '"opportunities","prestige_collapsed"' in campaign,
 'modal not remeasured each frame': 'if $Confirm.visible:_layout_confirm()\n    gem_pickup_time' not in ui,
 'modal deferred settling': 'func _settle_confirm(generation: int)' in ui,
 'modal generation cancellation': 'confirm_generation+=1\n    $Confirm.hide()' in ui,
 'Godot regression scene included': (ROOT/'tests/change_22_probe.tscn').exists(),
}
for name,passed in checks.items():print(('PASS' if passed else 'FAIL')+' '+name)
print(f'CHANGE_22_STATIC_CHECKS {len(checks)} FAILURES {sum(not v for v in checks.values())}')
if not all(checks.values()):raise SystemExit(1)
