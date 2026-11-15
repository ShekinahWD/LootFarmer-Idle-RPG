"""Change 80: catalog values written into data/game/catalog.json (idempotent; --check reports pending
differences and exits 1 when any exist). Brief: docs/LootFarmer_Change_80_XP_Critical_Camp_Stage_Progression.md.

1. Spring I / Spring II base kill XP (groups[].xp, before every multiplier: XP upgrades, Prestige cards,
   Veteran Traveler, Wisdom Tonic). Stages 1-6, the Spring I bosses, the XP requirement
   (ceil(12 x level^1.35)) and the level cap are unchanged. Kills are the only XP source
   (simulation._kill -> group_xp), so missions, offline rewards and summaries need no change.
2. Critical Damage: upgrades.critical_damage.effect 0.10 -> 0.05 (flat +0.05 to the crit multiplier per
   level; base 1.10 in simulation.stat_sources, cap 20, price 15 Gems x1.25 unchanged) and the Challenge
   card Hard Hit (campaign.cards.challenge_c3, effect crit_damage) 0.75 -> 0.40. Both are read at runtime,
   so purchased levels and owned cards take the new value on load with no migration.
3. Camp Supplies (campaign.cards.regional_c3, same id/path/set): value 1 -> 3 (supplies per batch) and a
   per-camp cooldown of 600 s of active play (campaign.camp_supply_step).
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
XP = {
    # Spring I (stage 7)
    'unit-bunny-ears': 500, 'unit-cat-ears': 650, 'unit-elf-ears': 850,
    # Spring II (stage 8)
    'unit-flower-crown': 1050, 'unit-green-cap': 1250, 'unit-pink-cap': 1500,
    'unit-pink-flower-hood': 1800, 'unit-plain': 2150, 'unit-sprout': 2550,
    'boss-red-panda': 30000, 'boss-sunflower': 35000, 'boss-green-alien': 45000,
}
# The values Change 80 replaced (kept for the report and the probe's before/after table).
XP_BEFORE = {
    'unit-bunny-ears': 358, 'unit-cat-ears': 600, 'unit-elf-ears': 1005,
    'unit-flower-crown': 2821, 'unit-green-cap': 3978, 'unit-pink-cap': 5612,
    'unit-pink-flower-hood': 7916, 'unit-plain': 11166, 'unit-sprout': 15750,
    'boss-red-panda': 879610, 'boss-sunflower': 1044700, 'boss-green-alien': 4912510,
}
CRIT_DAMAGE_EFFECT = 0.05
HARD_HIT_VALUE = 0.40
CAMP_SUPPLIES = {'effect': 'camp_supplies', 'value': 3, 'cooldown': 600}


def apply(c):
    changes = []
    for g in c['groups']:
        if g['id'] in XP and g['xp'] != XP[g['id']]:
            g['xp'] = XP[g['id']]
            changes.append('groups.%s.xp' % g['id'])
    up = c['upgrades']['critical_damage']
    if up['effect'] != CRIT_DAMAGE_EFFECT:
        up['effect'] = CRIT_DAMAGE_EFFECT
        changes.append('upgrades.critical_damage.effect')
    card = c['campaign']['cards']['challenge_c3']
    if card['effect'] != 'crit_damage':
        raise SystemExit('challenge_c3 is no longer the crit_damage card')
    if card['value'] != HARD_HIT_VALUE:
        card['value'] = HARD_HIT_VALUE
        changes.append('campaign.cards.challenge_c3.value')
    camp = c['campaign']['cards']['regional_c3']
    for key, value in CAMP_SUPPLIES.items():
        if camp.get(key) != value:
            camp[key] = value
            changes.append('campaign.cards.regional_c3.' + key)
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
