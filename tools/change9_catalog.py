"""Change 9: outfit growth, passive equipment shares and the Spring II correction
(idempotent: running it again rewrites the same values; --check reports differences only).

- Outfits: two-segment linear growth to ^500 (progression.merge.outfit_tail_rate, owned by
  tools/change8_catalog.py), plus an equipped-only milestone track scaled by the outfit's tier
  (progression.outfit_milestones). Later steps replace Guard/Recovery values; ^200 adds 10% of the
  outfit's own core HP.
- Stored (owned, unequipped) outfits count at 15% (progression.stored_outfit_factor); stored weapons
  stay at 30% (progression.stored_weapon_factor). See docs/LootFarmer_Change_9_Notes.md for why.
- Spring II (stage 8) only: normal levels 195-225, bosses 235/240, final boss 250 with its own HP
  factor 18 (progression.balance.final_hp; only the final boss uses it). Normals carry and drop Tier 5
  (Diamond weapons, the existing `_t5` outfits); bosses carry Tier 5 + 1 (Emerald) via the Change 8
  boss-weapon rule and drop their `_t5` boss outfit. Stages 1-7 are untouched.
Then run tools/tune_campaign.py to recompute enemy HP and damage from the new levels.
"""
from pathlib import Path
import json, sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import change8_catalog  # noqa: E402  (boss +1 weapon tier and the legacy flags)

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
MATERIALS = change8_catalog.MATERIALS
SPRING_II = 8
SPRING_II_TIER = 5
LEVELS = {'unit-flower-crown': 195, 'unit-green-cap': 201, 'unit-pink-cap': 207,
          'unit-pink-flower-hood': 213, 'unit-plain': 219, 'unit-sprout': 225,
          'boss-red-panda': 235, 'boss-sunflower': 240, 'boss-green-alien': 250}
FINAL_HP = 18.0
STORED_OUTFIT_FACTOR = 0.15
STORED_WEAPON_FACTOR = 0.3
# Equipped-only outfit milestones. *_per_tier values are multiplied by the outfit's tier;
# regen_pct is a fraction of max HP per second (0.0005 = 0.05%).
MILESTONES = [
    {'merge': 100, 'id': 'guard', 'defense_per_tier': 3.0},
    {'merge': 200, 'id': 'vitality', 'hp_share': 0.10},
    {'merge': 300, 'id': 'recovery', 'regen_pct_per_tier': 0.0005},
    {'merge': 400, 'id': 'guard_2', 'defense_per_tier': 6.0},
    {'merge': 500, 'id': 'mastery', 'defense_per_tier': 10.0, 'regen_pct_per_tier': 0.0008},
]


def tiered(body, tier):
    return body if tier == 1 else '%s_t%d' % (body, tier)


def apply(data):
    changes = []

    def put(entry, key, value, label):
        if entry.get(key) != value:
            entry[key] = value
            changes.append(label)

    items = data['items']
    for g in data['groups']:
        if g['stage'] != SPRING_II:
            continue
        put(g, 'level', LEVELS[g['id']], g['id'] + '.level')
        outfit = tiered(g['body'], SPRING_II_TIER)
        assert outfit in items, outfit
        if g['boss']:
            # The weapon comes from change8_catalog.apply (normal tier + 1).
            put(g, 'loot', [g['weapon'], outfit], g['id'] + '.loot')
        else:
            # Change 51 supersedes the Diamond (Tier 5) Spring II weapons: Obsidian (Tier 7) on Spring II.
            weapon = '%s_%s' % (MATERIALS[6], items[g['weapon']]['family'])
            put(g, 'weapon', weapon, g['id'] + '.weapon')
            put(g, 'loot', [weapon, outfit], g['id'] + '.loot')
    changes += change8_catalog.apply(data)
    progression = data['progression']
    put(progression, 'outfit_milestones', MILESTONES, 'progression.outfit_milestones')
    put(progression, 'stored_outfit_factor', STORED_OUTFIT_FACTOR, 'progression.stored_outfit_factor')
    put(progression, 'stored_weapon_factor', STORED_WEAPON_FACTOR, 'progression.stored_weapon_factor')
    put(progression['balance'], 'final_hp', FINAL_HP, 'progression.balance.final_hp')
    return changes


def main():
    data = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(data)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes), 'sample': changes[:12]}))
        sys.exit(0 if not changes else 1)
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    print(json.dumps({'changed': len(changes), 'sample': changes[:20]}))


if __name__ == '__main__':
    main()
