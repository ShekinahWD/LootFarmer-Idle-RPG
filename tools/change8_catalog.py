"""Change 8: drop rules, boss weapon tiers, outfit/skill growth by copies and the upgrade price pass
(idempotent: running it again rewrites the same values; --check reports differences only).

- Normal enemies: 5% base chance per carried gear item on every stage (was 10% Winter I falling to
  3% Spring II). Bosses keep 30%. The Loot Chance upgrade adds 0.5 points per level, 15 levels.
- Bosses carry and drop the weapon one tier above their stage's normal enemies, in their own family
  (Snowman: Wood Axe -> Stone Axe). Enemy damage comes from tools/tune_campaign.py, never from the
  weapon, so the visible weapon and its drop change without double-counting damage.
- Outfits and skills no longer evolve: `next` is cleared and they grow by merging copies of the same
  item up to progression.merge.copy_cap. Tiers that no enemy drops stay in the catalog (`legacy`)
  so saves that own evolved copies keep them and their merge progress.
- Player Upgrade prices: Gem first prices roughly halved, scaling by strength; Auto-Collect Batch is
  premium; Map Details follows one rising price per purchase; slot upgrades rise every purchase.
See docs/LootFarmer_Change_8_Notes.md for the tables and arithmetic.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
MATERIALS = ['wood', 'stone', 'iron', 'gold', 'diamond', 'emerald', 'obsidian']
NORMAL_GEAR_CHANCE = 0.05
BOSS_GEAR_CHANCE = 0.3
# Change 9: outfits grow linearly past ^100 at outfit_tail_rate merge levels per copy (2% then 1% of
# base per copy); skills keep the logarithmic tail (tail_scale).
MERGE = {'weapon_cap': 100, 'copy_cap': 500, 'linear_levels': 100, 'tail_scale': 100.0,
         'outfit_tail_rate': 0.5, 'stock_bonus_per_copy': 0.0005}
# id -> fields replaced on the upgrade definition. "step" = linear price (base + step * level);
# "sequence" = price grows with every purchase of this upgrade on any stage this run.
UPGRADES = {
    'loot': {'effect': 0.005, 'cap': 15, 'base': 20, 'growth': 1.35},
    # Change 16: bought with Gems, 50 on Winter I, still x3 per level (tools/change16_catalog.py).
    'collect_batch': {'base': 50, 'growth': 3.0},
    'map_detail': {'base': 60, 'growth': 1.3, 'sequence': True, 'floor': 40},
    'gear_slots': {'base': 5, 'step': 1},
    'supply_slots': {'base': 4, 'step': 4},
    'merge_supplies': {'base': 10},
    'merge_speed': {'base': 12, 'growth': 1.7},
    'auto_use': {'base': 100, 'growth': 2.6},
    # Change 12 extends the 12 original prices through level 20 (tools/change12_catalog.py).
    'gem_chance': {'base': 25, 'prices': [25, 40, 58, 80, 105, 135, 170, 210, 260, 320, 390, 470, 560, 660, 770, 890, 1020, 1160, 1310, 1470]},
    'gem_amount': {'base': 25, 'prices': [25, 40, 58, 80, 105, 135, 170, 210, 260, 320]},
    'boss_gem_chance': {'base': 50, 'prices': [50, 80, 120, 170, 230, 310, 410, 530]},
    'boss_gem_amount': {'base': 25, 'prices': [25, 40, 58, 80, 105, 135, 170, 210, 260, 320]},
    # Change 13 prices (tools/change13_catalog.py): slots 300 / 600, auto-cast 100 / 250 / 500.
    'skill_slots': {'base': 300, 'prices': [300, 600]},
    'skill_auto_0': {'base': 100},
    'skill_auto_1': {'base': 250},
    'skill_auto_2': {'base': 500},
    'mission_slots': {'base': 25, 'prices': [25, 50, 90, 140, 200]},
    'mission_claim': {'base': 75},
    'offline_cap': {'base': 25, 'prices': [25, 50, 90, 140, 215, 330]},
    'offline_gems': {'base': 20, 'growth': 1.25},
    'offline_coins': {'growth': 1.3},
    'offline_weapon': {'base': 50},
    'offline_outfit': {'base': 50},
    'offline_consumable': {'base': 38},
}
REMOVED_FIELDS = {'map_detail': ['prices']}


def apply(data):
    changes = []

    def put(entry, key, value, label):
        if entry.get(key) != value:
            entry[key] = value
            changes.append(label)

    items, groups = data['items'], data['groups']
    for g in groups:
        put(g, 'gear_chance', BOSS_GEAR_CHANCE if g['boss'] else NORMAL_GEAR_CHANCE, g['id'] + '.gear_chance')
    for g in groups:
        if not g['boss']:
            continue
        normal_tier = max(int(items[n['weapon']]['tier']) for n in groups if not n['boss'] and n['stage'] == g['stage'])
        family = items[g['weapon']]['family']
        weapon = '%s_%s' % (MATERIALS[normal_tier], family)
        old = g['weapon']
        if old != weapon:
            g['loot'] = [weapon if i == old else i for i in g['loot']]
            put(g, 'weapon', weapon, g['id'] + '.weapon')
    dropped = {i for g in groups for i in g['loot']} | {'skill_' + s for g in groups for s in g['skills']}
    for key, entry in items.items():
        if entry['kind'] in ('outfit', 'skill'):
            put(entry, 'next', '', key + '.next')
            put(entry, 'legacy', key not in dropped, key + '.legacy')
    progression = data['progression']
    put(progression, 'merge', MERGE, 'progression.merge')
    put(progression, 'prestige_unlock_boss', 'boss-snowman', 'progression.prestige_unlock_boss')
    if 'prestige_unlock_kills' in progression:
        del progression['prestige_unlock_kills']
        changes.append('progression.prestige_unlock_kills removed')
    if 'prestige_gate_stage' in progression:
        del progression['prestige_gate_stage']
        changes.append('progression.prestige_gate_stage removed')
    for key, fields in UPGRADES.items():
        if key not in data['upgrades']:
            continue  # removed by a later change (Change 11: merge_supplies, merge_speed)
        entry = data['upgrades'][key]
        for field, value in fields.items():
            put(entry, field, value, '%s.%s' % (key, field))
        for field in REMOVED_FIELDS.get(key, []):
            if field in entry:
                del entry[field]
                changes.append('%s.%s removed' % (key, field))
    return changes


def main():
    data = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(data)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)}))
        sys.exit(0 if not changes else 1)
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    print(json.dumps({'changed': len(changes), 'sample': changes[:12]}))


if __name__ == '__main__':
    main()
