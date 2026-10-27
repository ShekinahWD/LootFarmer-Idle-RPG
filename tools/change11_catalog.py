"""Current supply definitions (Change 17 prices and Potion eligibility); historical Change 11: supply catalog with permanent mastery (idempotent; --check reports differences only).

- Five supply identities, one inventory identity each (no tiers, no evolution):
  Health Potion (heal a share of max HP), Coin Tonic (coins), Guard Tonic (Defense), Recovery Salve
  (healing over time) and Wisdom Tonic (XP). The tier copies potion_tier_2..7 and
  coin_boost_tier_2..7 are retired; legacy_items folds them into the base supply.
- Each supply's `normal` stat is [base, gain]: the value is base + gain x mastery, so ^100 doubles it.
  Its `supply` block holds the effect, duration, cooldown, use and auto-use HP thresholds, the first
  stage whose enemies drop it, its share of the existing supply roll and the coin price (shop only).
- Mastery (progression.supply_mastery) counts copies found (drops and offline), capped at ^100, with
  milestones that lengthen buffs and shorten the potion cooldown. Spending a charge never lowers it.
- Every upgrade bought with Gems is kept by Prestige (keep = true), whatever its category; the
  simulation enforces the same rule from the currency (simulation.upgrade_kept). Each upgrade has a
  single currency, so no level is ever split between currencies.
- Enemy spawn prices (Winter I, per enemy type; later stages keep the gem stage factor
  1 + 0.25 x (stage - 1)): Spawn Amount 75 / 125 / 200 (400 total), Spawn Cooldown
  50 / 100 / 150 / 225 / 300 (825 total). Effects and caps unchanged.
- Supply capacity is six: 1 initial slot + 5 purchases (Change 21).
  Supply auto-merge (merge_supplies, merge_speed) is removed: mastery grows on its own.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
ART = 'res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png'
INITIAL_SUPPLY_SLOTS = 1
SPAWN_PRICES = {'spawn_amount': [75, 125, 200], 'spawn_cooldown': [50, 100, 150, 225, 300]}
MASTERY = {
    'cap': 100,
    'milestones': [
        {'merge': 25, 'id': 'steady', 'duration': 1.2, 'cooldown': 0.9},
        {'merge': 50, 'id': 'potent', 'duration': 1.4, 'cooldown': 0.85},
        {'merge': 100, 'id': 'mastered', 'duration': 1.6, 'cooldown': 0.8},
    ],
}
# id: (name key, icon, stat, base, effect, duration s, cooldown s, use HP, auto HP, first stage, weight, price)
SUPPLIES = {
    # Change 13: 12 s potion cooldown (was 5) with a 10 s floor (COOLDOWN_FLOORS), see change13_catalog.py.
    # Change 16: heals 10% at ^0 and 20% at ^100 (was 20% -> 40%), see change16_catalog.py.
    'potion': ('ITEM_POTION', 212, 'heal_pct', 0.1, 'heal', 0, 12, 1, 1, 1, 8, 100),
    'coin_boost': ('ITEM_COIN_BOOST', 68, 'coin_bonus', 0.25, 'coins', 30, 0, 1, 1, 1, 2, 200),
    'guard_tonic': ('ITEM_GUARD_TONIC', 67, 'defense', 20, 'guard', 20, 0, 1, 1, 2, 2.5, 300),
    'recovery_salve': ('ITEM_RECOVERY_SALVE', 71, 'regen_pct', 0.015, 'recovery', 10, 0, 0.9, 0.6, 3, 2, 400),
    'wisdom_tonic': ('ITEM_WISDOM_TONIC', 70, 'xp_bonus', 0.25, 'xp', 60, 0, 1, 1, 4, 1.5, 500),
}


# Change 13: the shortest a mastered cooldown may become (seconds).
COOLDOWN_FLOORS = {'potion': 10}


def supply_item(ident, spec):
    name, icon, stat, base, effect, duration, cooldown, use_hp, auto_hp, stage, weight, price = spec
    gain = round(base / MASTERY['cap'], 6)
    return {
        'kind': 'consumable', 'name': name, 'tier': 1,
        'normal': {stat: [base, gain]}, 'merge_gain': {stat: gain}, 'extras': {},
        'next': '', 'icon_path': ART % icon, 'art_id': ident, 'family': ident,
        'supply': {'effect': effect, 'stat': stat, 'duration': duration, 'cooldown': cooldown,
                   'use_hp': use_hp, 'auto_hp': auto_hp, 'min_stage': stage, 'drop_weight': weight,
                   'price': price, **({'cooldown_floor': COOLDOWN_FLOORS[ident]} if ident in COOLDOWN_FLOORS else {})},
    }


def apply(data):
    changes = []
    items = data['items']
    retired = [k for k, v in items.items() if v['kind'] == 'consumable' and k not in SUPPLIES]
    for ident in retired:
        base = items[ident].get('family', ident)
        del items[ident]
        data['legacy_items'][ident] = base if base in SUPPLIES else 'potion'
        changes.append('retired ' + ident)
    for ident, spec in SUPPLIES.items():
        wanted = supply_item(ident, spec)
        if items.get(ident) != wanted:
            items[ident] = wanted
            changes.append('supply ' + ident)
    # Supplies first in the catalog, in the order above.
    ordered = {k: items[k] for k in SUPPLIES}
    ordered.update({k: v for k, v in items.items() if k not in SUPPLIES})
    if list(ordered) != list(items):
        data['items'] = ordered
        changes.append('item order')
    upgrades = data['upgrades']
    for ident in ['merge_supplies', 'merge_speed']:
        if ident in upgrades:
            del upgrades[ident]
            changes.append('removed upgrade ' + ident)
    for ident, entry in upgrades.items():
        if entry['currency'] not in ('coins', 'gems'):
            raise SystemExit('unexpected currency for ' + ident)
        if entry['currency'] == 'gems' and entry.get('keep') is not True:
            entry['keep'] = True
            changes.append('keep ' + ident)
    for ident, prices in SPAWN_PRICES.items():
        entry = upgrades[ident]
        assert len(prices) == entry['cap'], ident
        if entry.get('prices') != prices or entry.get('base') != prices[0]:
            entry['prices'] = prices
            entry['base'] = prices[0]
            changes.append(ident + '.prices')
    cap = 6 - INITIAL_SUPPLY_SLOTS
    if upgrades['supply_slots'].get('cap') != cap:
        upgrades['supply_slots']['cap'] = cap
        changes.append('supply_slots.cap')
    progression = data['progression']
    if progression.get('supply_mastery') != MASTERY:
        progression['supply_mastery'] = MASTERY
        changes.append('progression.supply_mastery')
    for key in ['potion_cooldown', 'coin_boost_duration']:
        if key in progression:
            del progression[key]
            changes.append('removed progression.' + key)
    return changes


def main():
    data = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(data)
    supplies = [k for k, v in data['items'].items() if v['kind'] == 'consumable']
    assert data['upgrades']['supply_slots']['cap'] + INITIAL_SUPPLY_SLOTS == 6, supplies
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': changes, 'supplies': supplies}))
        return
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    print(json.dumps({'changed': changes, 'supplies': supplies}))


if __name__ == '__main__':
    main()
