"""Change 7: shared weapon families and stage-tiered gear (one-shot, idempotent).

Before: every normal enemy type owned a private 7-tier weapon chain (34 functionally identical
"<type> Sword" families, all drawn with the wood-sword art) and dropped tier 1 of its outfit with a
base that grew 8% per stage. Prototype items (sprout, robot, dinosaur, reaper, death scythe and
the tier-4+ iron sword) were unreachable duplicates.

After:
- Two shared weapon families, Sword and Axe, each a 7-tier material ladder with its own owned icon
  (PixelPlains 16x16 All Items v1: row 0 swords, row 1 axes) and owned swing sheet (PixelPlains
  Animation Pack material sets). A Wood Sword is the same item whichever enemy carries it.
- Enemy types alternate Sword/Axe (roster order, pairs: S S A A ...); bosses carry the family of
  their stage's last normal type, as before.
- Stages 1-2 carry/drop tier 1, 3-4 tier 2, 5-6 tier 3, 7-8 tier 4 (weapons and outfits).
- Every normal outfit of a tier has the same base; boss outfits are BOSS_OUTFIT times stronger.
- catalog.legacy_items maps every removed id to its replacement so current saves keep their gear.
Run once; --check reports whether the catalog already matches without writing.
"""
from pathlib import Path
import json, re, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
ICONS = 'res://assets/PixelPlains/Items/16x16 All Items v1.png'
ANIM = 'res://assets/PixelPlainsAnimationPack/'
# (material id, icon column, swing set folder, swing set number)
MATERIALS = [('wood', 0, 'Wood set', 1), ('stone', 1, 'Onix set', 7), ('iron', 2, 'Iron set', 2),
             ('gold', 3, 'Gold set', 3), ('diamond', 4, 'Diamond set', 4), ('emerald', 6, 'Emerald set', 5),
             ('obsidian', 7, 'Ruby set', 6)]
# One shared stack replaces several stored per-enemy families, so the tier-1 base is a third higher
# than the old per-enemy 3.0 (Change 7 pacing: 3.0 left the Winter II gate ~10% short on damage).
FAMILIES = {'sword': {'row': 0, 'swing': 'Sword', 'normal': {'damage': 4.0}},
            # The Axe trades a fifth of the damage for sturdiness, so the two never duplicate.
            'axe': {'row': 1, 'swing': 'Axe', 'normal': {'damage': 3.2, 'hp': 12.0}}}
TIER_GROWTH = 2.55       # catalog.progression.evolution: base_multiplier 0.85 x 3
MERGE_SHARE = 0.02       # each merge adds 2% of the tier base (x3 at ^100), as before
OUTFIT_HP = 8.0          # tier-1 normal outfit HP (the stage-1 value before)
BOSS_OUTFIT = 3.0        # boss-exclusive outfits (was 2x the stage's normal outfit)
WEAPON_EXTRAS = {"crit": [0.01, 0.03], "crit_damage": [0.05, 0.15], "speed": [0.02, 0.06], "lifesteal": [0.005, 0.015]}
LEGACY_PREFIXES = ('sprout', 'robot', 'dinosaur', 'reaper', 'death_scythe', 'iron_sword_tier_')


def stage_tier(stage):
    return 1 + (stage - 1) // 2


def weapon_id(family, tier):
    return '%s_%s' % (MATERIALS[tier - 1][0], family)


def tiered(base, tier):
    return base if tier == 1 else '%s_t%d' % (base, tier)


def weapon_normal(spec, tier):
    scale = TIER_GROWTH ** (tier - 1)
    return {k: [v * scale, v * scale * MERGE_SHARE] for k, v in spec['normal'].items()}


def retune(data):
    """Re-applies the weapon constants above to an already converted catalog; returns mismatches."""
    changed = 0
    for family, spec in FAMILIES.items():
        for tier in range(1, 8):
            entry = data['items'][weapon_id(family, tier)]
            normal = weapon_normal(spec, tier)
            if entry['normal'] != normal:
                changed += 1
                entry['normal'] = normal
                entry['merge_gain'] = {k: v[1] for k, v in normal.items()}
    return changed


def build(data):
    items, groups = data['items'], data['groups']
    legacy = {}
    normal_types = [g for g in groups if not g['boss']]
    family_of = {g['id']: ('sword' if i % 4 < 2 else 'axe') for i, g in enumerate(normal_types)}
    # Old per-type weapon chains -> shared family at the same tier.
    for ident in list(items):
        m = re.fullmatch(r'(unit-[a-z-]+)_weapon(?:_t(\d))?', ident)
        if m:
            legacy[ident] = weapon_id(family_of[m.group(1)], int(m.group(2) or 1))
            del items[ident]
    # Unreachable prototype duplicates -> nearest current item.
    proto_outfits = {'sprout': 'unit-sprout_outfit', 'robot': 'boss-cyan-robot_outfit',
                     'dinosaur': 'boss-teal-dinosaur_outfit', 'reaper': 'boss-grim-reaper_outfit'}
    for ident in list(items):
        if ident.startswith(LEGACY_PREFIXES):
            tier = int(items[ident]['tier'])
            root = ident.split('_tier_')[0]
            legacy[ident] = tiered(proto_outfits[root], tier) if root in proto_outfits else weapon_id('sword', tier)
            del items[ident]
    for ident in ['wood_sword', 'stone_sword', 'iron_sword']:
        items.pop(ident, None)
    # Shared weapon ladders.
    for family, spec in FAMILIES.items():
        for tier in range(1, 8):
            material, column, folder, number = MATERIALS[tier - 1]
            normal = weapon_normal(spec, tier)
            swing = ('Axe 1' if family == 'axe' else 'Sword 1') if tier == 1 else '%s %d' % (spec['swing'], number)
            items[weapon_id(family, tier)] = {
                'kind': 'weapon', 'tier': tier, 'normal': normal, 'extras': dict(WEAPON_EXTRAS),
                'reroll': 3 * 2 ** (tier - 1), 'next': weapon_id(family, tier + 1) if tier < 7 else '',
                'texture': ICONS, 'icon': [column * 32, spec['row'] * 32, 32, 32],
                'art_id': weapon_id(family, tier), 'family': family,
                'name': 'ITEM_' + weapon_id(family, tier).upper(),
                'attack': ANIM + folder + '/' + swing + ' 64x32.png',
                'merge_gain': {k: v[1] for k, v in normal.items()}}
    # Outfits: one base per tier; bosses stronger.
    boss_bodies = {g['body'] for g in groups if g['boss']}
    for ident, entry in items.items():
        if entry['kind'] != 'outfit':
            continue
        base = OUTFIT_HP * TIER_GROWTH ** (int(entry['tier']) - 1) * (BOSS_OUTFIT if entry['art_id'] in boss_bodies else 1.0)
        entry['normal'] = {'hp': [base, base * MERGE_SHARE]}
        entry['merge_gain'] = {'hp': base * MERGE_SHARE}
    # Groups carry and drop shared weapons and stage-tiered outfits.
    last_normal = {}
    for g in groups:
        tier = stage_tier(int(g['stage']))
        if not g['boss']:
            last_normal[g['stage']] = g['id']
            family = family_of[g['id']]
        else:
            family = family_of[last_normal[g['stage']]]
        g['weapon'] = weapon_id(family, tier)
        g['loot'] = [g['weapon'], tiered(g['body'], tier)]
    data['legacy_items'] = dict(sorted(legacy.items()))
    gear = sum(i['kind'] != 'consumable' for i in items.values())
    data['upgrades']['gear_slots']['cap'] = gear - 3
    data['progression'].setdefault('coin_boost_duration', 30.0)
    return data


def main():
    data = json.loads(CATALOG.read_text(encoding='utf-8'))
    applied = 'legacy_items' in data
    if '--check' in sys.argv:
        mismatches = retune(data) if applied else -1
        print(json.dumps({'applied': applied, 'weapon_mismatches': mismatches}))
        sys.exit(0 if applied and mismatches == 0 else 1)
    if applied:
        changed = retune(data)
        CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
        print(json.dumps({'applied': True, 'retuned': changed}))
        return
    data = build(data)
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    print(json.dumps({'applied': True, 'items': len(data['items']), 'legacy': len(data['legacy_items']),
                      'gear_slots_cap': data['upgrades']['gear_slots']['cap']}))


if __name__ == '__main__':
    main()
