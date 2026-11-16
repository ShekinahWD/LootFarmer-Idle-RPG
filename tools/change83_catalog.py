"""Change 83: the Green Alien's approved difficulty increase, written into data/game/catalog.json (idempotent;
--check reports pending differences and exits 1 when any exist). Brief: docs/LootFarmer_Change_83.md.
Run tools/tune_campaign.py afterwards (this tool runs it itself unless --check).

The final boss's maximum HP and base attack damage are doubled from their Change 81 values, through its
progression.balance.boss_tuning entry (the last step tune_campaign applies to a boss). Nothing else changes:
attack interval, skills, Heal (a share of max HP, so it follows the HP), summon rules, rewards and every other
type keep their values. Enemy damage skills are definition damage x skill power, so they double once with the
hit and are not multiplied again. Rage Mode (+50% attack speed, -30% damage taken, +20% healing below 20% HP)
is a runtime rule in scripts/game/campaign.gd, not catalog data.
"""
from pathlib import Path
import json, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'

FINAL_ID = 'boss-green-alien'
FACTOR = 2.0
# Change 81 boss_tuning entry (tools/change81_catalog.py): HP 91,354.1071, damage 622.7689.
TUNING_BEFORE = [0.3, 1.626]
TUNING = [round(TUNING_BEFORE[0] * FACTOR, 4), round(TUNING_BEFORE[1] * FACTOR, 4)]
HP_BEFORE = 91354.1071
DAMAGE_BEFORE = 622.7689
# Change 84 supersedes the damage multiplier (x7/9, 3.252 -> 2.5293): tools/change84_catalog.py.
SUPERSEDED = [TUNING[0], 2.5293]


def apply(c):
    tuning = c['progression']['balance']['boss_tuning']
    if tuning.get(FINAL_ID) == SUPERSEDED:
        return []
    if tuning.get(FINAL_ID) not in (TUNING_BEFORE, TUNING):
        raise SystemExit('%s boss_tuning is %s, not the expected Change 81 value' % (FINAL_ID, tuning.get(FINAL_ID)))
    if tuning[FINAL_ID] != TUNING:
        tuning[FINAL_ID] = list(TUNING)
        return ['progression.balance.boss_tuning.' + FINAL_ID]
    return []


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    subprocess.run([sys.executable, str(ROOT / 'tools/tune_campaign.py')], check=True, capture_output=True)
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    g = next(g for g in c['groups'] if g['id'] == FINAL_ID)
    if c['progression']['balance']['boss_tuning'][FINAL_ID] == SUPERSEDED:
        print(json.dumps({'changed': changes, 'superseded_by': 'tools/change84_catalog.py'})); return
    for key, before in (('hp', HP_BEFORE), ('damage', DAMAGE_BEFORE)):
        if abs(g[key] - before * FACTOR) > 0.01:
            raise SystemExit('%s %s is %.4f, expected %.4f' % (FINAL_ID, key, g[key], before * FACTOR))
    print(json.dumps({'changed': changes, 'hp': [HP_BEFORE, g['hp']], 'damage': [DAMAGE_BEFORE, g['damage']]}))


if __name__ == '__main__':
    main()
