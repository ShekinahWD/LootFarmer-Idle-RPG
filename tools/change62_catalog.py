"""Change 62 (approved brief docs/LootFarmer_Change_62_Boss_Balance_and_Aggression.md): boss damage, boss attack
intervals and stage aggression, written into data/game/catalog.json (idempotent; --check reports pending
differences, --table prints the per-boss reference table).

- Boss basic attack: progression.balance.boss_spot_share = 0.90, applied by tools/tune_campaign.py (the
  balance source of every enemy's HP/damage): a boss deals at least 90% of a representative three-enemy spot of
  its own stage. The reference spot is the stage's strongest normal type in its standard full loadout
  (variant 2), on the same pre-Defense basis the game uses (simulation._build_definition: catalog damage x
  progression.combat.normal_damage_scale for the stage). threshold = 0.90 x 3 x reference, rounded up to 4
  decimals. A boss already above its threshold keeps its formula value (never lowered). Boss HP, normal
  damage and skill powers are untouched.
- Boss basic attack interval (seconds between normal attacks): 2.00 s Winter I down to 1.30 s for the final
  boss, per the approved schedule below. Normal enemies keep theirs.
- Aggression (aggro_mode): stages 1-2 every enemy "passive" (retaliates once attacked); stage 3 normals
  "passive", stage 3 boss proximity ("group", as before); stages 4-8 "group" (proximity + spot assist).
- Standard boss skill cooldowns (10 s) live in resources/game/enemy_abilities.tres (boss_skill_cooldown),
  because the catalog skill cooldown is shared with the player's skills and normal enemies.
"""
from pathlib import Path
import json, sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from tune_campaign import boss_floor as threshold, spot_reference as reference
ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
INTERVALS = {
    'boss-snowman': 2.0, 'boss-cyan-robot': 1.9, 'boss-gray-cat': 1.8,
    'boss-elephant': 1.7, 'boss-teal-dinosaur': 1.65,
    'boss-squirrel': 1.6, 'boss-red-fox': 1.55,
    'boss-black-cat': 1.5, 'boss-grim-reaper': 1.45,
    'boss-bee': 1.4, 'boss-orange-tabby-cat': 1.35,
    'boss-red-panda': 1.33, 'boss-sunflower': 1.32, 'boss-green-alien': 1.3,
}
SHARE = 0.9

def aggro_for(stage, boss):
    if stage <= 2: return 'passive'
    if stage == 3: return 'group' if boss else 'passive'
    return 'group'

def apply(c):
    changes = []
    if c['progression']['balance'].get('boss_spot_share') != SHARE:
        c['progression']['balance']['boss_spot_share'] = SHARE; changes.append('progression.balance.boss_spot_share')
    if [g['id'] for g in c['groups'] if g['boss']] != list(INTERVALS):
        sys.exit('Boss order differs from the approved schedule; refusing to guess.')
    for g in c['groups']:
        stage = int(g['stage'])
        mode = aggro_for(stage, g['boss'])
        if g['aggro_mode'] != mode:
            g['aggro_mode'] = mode; changes.append(g['id'] + '.aggro_mode')
        if not g['boss']: continue
        if g['interval'] != INTERVALS[g['id']]:
            g['interval'] = INTERVALS[g['id']]; changes.append(g['id'] + '.interval')
        need = threshold(c, stage)
        if float(g['damage']) < need:
            g['damage'] = need; changes.append(g['id'] + '.damage')
    return changes

def table(before, after):
    print('| Boss | Stage | Reference spot (3x) | 90% threshold | Attack before -> after | Interval before -> after |')
    print('|---|---:|---|---:|---|---|')
    old = {g['id']: g for g in before['groups']}
    for g in after['groups']:
        if not g['boss']: continue
        ref = reference(after, int(g['stage'])); o = old[g['id']]
        print('| %s | %d | %s %.4f (x3 = %.4f) | %.4f | %.4f -> %.4f | %.2f -> %.2f |' % (
            g['id'], g['stage'], ref[0], ref[1], 3 * ref[1], threshold(after, int(g['stage'])),
            float(o['damage']), float(g['damage']), float(o['interval']), float(g['interval'])))

def main():
    before = json.loads(CATALOG.read_text(encoding='utf-8'))
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--table' in sys.argv:
        table(before, c); return
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': changes}))

if __name__ == '__main__':
    main()
