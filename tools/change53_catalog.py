"""Change 53 (approved progression brief, B4): combat structure and tuning, written into data/game/catalog.json
(idempotent; --check reports pending differences).

- Summer I (stage 3) normal enemies: aggro_mode "group" -> "individual" (Winter II's proximity rule). Winter I stays
  passive, Winter II individual, Summer II-Spring II (stages 4-8) keep coordinated group aggression. Bosses keep theirs.
- progression.combat.skill_variant_damage 1.15 (was a hard-coded 1.35 damage multiplier for the skill variant;
  its HP multiplier stays 1.35).
- progression.combat.normal_damage_scale {"7": 0.6, "8": 0.6}: Spring I and Spring II normal enemies (every
  loadout variant) deal 60% of their stage damage; with the skill variant the factors multiply (0.6 x 1.15).
  Bosses and summoned helpers are exempt. No attacker cap and no join stagger (both rejected).
"""
from pathlib import Path
import json, sys
ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
COMBAT = {'skill_variant_damage': 1.15, 'skill_variant_hp': 1.35, 'normal_damage_scale': {'7': 0.6, '8': 0.6}}

def apply(c):
    changes = []
    for g in c['groups']:
        if int(g['stage']) == 3 and not g['boss'] and g['aggro_mode'] != 'individual':
            g['aggro_mode'] = 'individual'; changes.append(g['id'] + '.aggro_mode')
    if c['progression'].get('combat') != COMBAT:
        c['progression']['combat'] = COMBAT; changes.append('progression.combat')
    return changes

def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': changes}))

if __name__ == '__main__':
    main()
