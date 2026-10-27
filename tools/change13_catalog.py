"""Change 13 catalog edits (idempotent; --check reports differences only).

- Change 17 overrides the old cooldown ladder: all six catalog base cooldowns are now 20 s.
  Historical Change 13 rationale follows: Lightning 4 -> 8 (the only ~4 s skill),
  and the next steps move up so each skill keeps its own place in the ladder instead of Lightning
  matching Fire: Fire 8 -> 10, Frost 10 -> 12, Strike 10 -> 12. Focus (15) and Heal (18) were
  already long on purpose and are unchanged. The cooldown upgrade (-5% per level, 6 levels, 2 s
  floor) is unchanged.
- Skill unlock prices (gems): automatic casting 100 / 250 / 500 (slots 1-3), extra skill slots
  300 (second) / 600 (third). Caps, gating and Prestige permanence unchanged.
- Health Potion: 12 s base cooldown (was 5) and a 10 s floor, so supply mastery (x0.9 / x0.85 / x0.8)
  shortens it to 10.8 / 10.2 / 10 s at most. Heal amount (20% -> 40% of max HP) unchanged.
- Auto Evolution: a per-enemy-type one-time unlock for 2,000 gems (kept by Prestige like every gem
  upgrade). It evolves the weapons that this type actually drops, by the manual evolution rules.

tools/change8_catalog.py (prices) and tools/change11_catalog.py (potion) hold the same values.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
SKILL_COOLDOWNS = {key: 20 for key in ('heal', 'frost', 'fire', 'lightning', 'focus', 'strike')}
SKILL_PRICES = {'skill_auto_0': 100, 'skill_auto_1': 250, 'skill_auto_2': 500}
SLOT_PRICES = [300, 600]
POTION_COOLDOWN = 12
POTION_FLOOR = 10
# 'flat': the same 2,000 gems on every map (type upgrades otherwise scale by stage).
AUTO_EVOLVE = {'currency': 'gems', 'base': 2000, 'growth': 1, 'cap': 1, 'keep': True, 'effect': 1, 'scope': 'type', 'flat': True}


def apply(c):
    for key, seconds in SKILL_COOLDOWNS.items():
        c['skills'][key]['cooldown'] = seconds
    for key, price in SKILL_PRICES.items():
        c['upgrades'][key]['base'] = price
    slots = c['upgrades']['skill_slots']
    slots['prices'] = list(SLOT_PRICES)
    slots['base'] = SLOT_PRICES[0]
    supply = c['items']['potion']['supply']
    supply['cooldown'] = POTION_COOLDOWN
    supply['cooldown_floor'] = POTION_FLOOR
    c['upgrades']['auto_evolve'] = dict(AUTO_EVOLVE)
    return c


def main():
    before = CATALOG.read_bytes().decode('utf-8')
    catalog = apply(json.loads(before))
    assert catalog['upgrades']['skill_slots']['cap'] == len(SLOT_PRICES)
    mastered = min(m['cooldown'] for m in catalog['progression']['supply_mastery']['milestones'])
    assert POTION_COOLDOWN * mastered <= POTION_FLOOR < POTION_COOLDOWN
    after = json.dumps(catalog, indent=2) + '\n'
    if '--check' in sys.argv:
        print('unchanged' if after == before else 'differs')
        sys.exit(0 if after == before else 1)
    CATALOG.write_bytes(after.encode('utf-8'))
    print('skills', SKILL_COOLDOWNS, 'auto-cast', SKILL_PRICES, 'slots', SLOT_PRICES)


if __name__ == '__main__':
    main()
