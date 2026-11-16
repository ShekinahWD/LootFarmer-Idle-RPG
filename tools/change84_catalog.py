"""Change 84: the Green Alien's basic attack ~900 -> ~700 per hit, written into data/game/catalog.json (idempotent;
--check reports pending differences and exits 1 when any exist). Run tools/tune_campaign.py afterwards (this tool
runs it itself unless --check).

A hit on the player is definition damage x the player's guard / boss guard / Focus multipliers x 100 / (100 +
player defense): every factor after the definition damage is multiplicative, and Rage Mode does not change the
boss's outgoing damage (only its attack speed, damage taken and healing). So the reported 900 becomes 700 by
scaling the definition damage by 7/9, through the boss_tuning damage multiplier (the last step tune_campaign applies
to a boss): 3.252 -> 2.5293, attack 1,245.5378 -> 968.7. HP (0.6), interval, defense, Heal, summons, Rage Mode and
every other type keep their values. Its damage skills stay definition damage x skill power (unchanged rule).
"""
from pathlib import Path
import json, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'

FINAL_ID = 'boss-green-alien'
FACTOR = 7 / 9
# Change 83 boss_tuning entry (tools/change83_catalog.py): HP 182,708.2142, damage 1,245.5378.
TUNING_BEFORE = [0.6, 3.252]
TUNING = [TUNING_BEFORE[0], round(TUNING_BEFORE[1] * FACTOR, 4)]
HP = 182708.2142
DAMAGE_BEFORE = 1245.5378


def apply(c):
    tuning = c['progression']['balance']['boss_tuning']
    if tuning.get(FINAL_ID) not in (TUNING_BEFORE, TUNING):
        raise SystemExit('%s boss_tuning is %s, not the expected Change 83 value' % (FINAL_ID, tuning.get(FINAL_ID)))
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
    expected = DAMAGE_BEFORE / TUNING_BEFORE[1] * TUNING[1]
    if abs(g['hp'] - HP) > 0.01 or abs(g['damage'] - expected) > 0.01:
        raise SystemExit('%s hp %.4f / damage %.4f, expected %.4f / %.4f' % (FINAL_ID, g['hp'], g['damage'], HP, expected))
    print(json.dumps({'changed': changes, 'tuning': [TUNING_BEFORE, TUNING], 'damage': [DAMAGE_BEFORE, g['damage']],
                      'hit_900_becomes': round(900 * g['damage'] / DAMAGE_BEFORE, 1)}))


if __name__ == '__main__':
    main()
