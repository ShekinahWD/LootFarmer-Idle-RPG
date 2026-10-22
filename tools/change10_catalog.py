"""Change 10: equipment slot cap and boss Gem payout (idempotent; --check reports differences only).

- Equipment (gear) inventory: exactly 70 slots, 3 initial + 67 purchasable (upgrades.gear_slots.cap).
  The reachable equipment identities (every type's loot, its skills and the weapon evolution chains)
  are 68; outfits and skills grow by merging copies, so copies never need extra slots. Supplies are
  a separate pool and keep their own cap.
- Boss Gem payout: a successful boss Gem roll pays boss_amount_multiplier (3) times the normal
  enemy's amount under the same Gem Amount upgrades, before the boss-only Boss Gem Amount bonus
  and the boss Gem card (simulation.gem_amount). Chances are unchanged.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
EQUIPMENT_SLOTS = 70
INITIAL_SLOTS = 3
BOSS_GEM_MULTIPLIER = 3


def reachable_equipment(data):
    items = data['items']
    found = set()
    for g in data['groups']:
        found.update(g['loot'])
        found.update('skill_' + s for s in g['skills'])
    grew = True
    while grew:
        grew = False
        for ident in list(found):
            successor = items[ident].get('next', '')
            if successor and items[ident]['kind'] == 'weapon' and successor not in found:
                found.add(successor)
                grew = True
    return sorted(i for i in found if items[i]['kind'] != 'consumable')


def apply(data):
    changes = []

    def put(entry, key, value, label):
        if entry.get(key) != value:
            entry[key] = value
            changes.append(label)

    put(data['upgrades']['gear_slots'], 'cap', EQUIPMENT_SLOTS - INITIAL_SLOTS, 'gear_slots.cap')
    put(data['progression']['gem_limits'], 'boss_amount_multiplier', BOSS_GEM_MULTIPLIER,
        'gem_limits.boss_amount_multiplier')
    return changes


def main():
    data = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(data)
    reachable = reachable_equipment(data)
    assert len(reachable) <= EQUIPMENT_SLOTS, len(reachable)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': changes, 'reachable_equipment': len(reachable)}))
        return
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    print(json.dumps({'changed': changes, 'reachable_equipment': len(reachable)}))


if __name__ == '__main__':
    main()
