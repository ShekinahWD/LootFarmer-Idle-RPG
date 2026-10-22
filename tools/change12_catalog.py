"""Change 12 catalog edits (idempotent; --check reports differences only).

- Gem drop chance: base 5% (was 8%) for normal and boss rolls. The old 20% normal / 60% boss caps are
  removed; the only clamp left is the probability range [0, 1] in simulation.gem_chance.
- Global Gem Drop Chance upgrade: 20 levels of +0.5 points (+10 points in all). Prices for levels
  1-12 are unchanged; levels 13-20 continue the existing step pattern (each step 10 gems larger than
  the one before: ... +70, +80, then +90 ... +160).
- Gem Wisdom (Offering card 2): +5 points (was +3).
- Merge All: a one-time 5,000-Gem global unlock (kept by Prestige like every Gem upgrade).
- Stone-tier weapons (Stone Axe, the Winter I Snowman's weapon, and Stone Sword) swing with the Iron
  set sheet in a warm-gray tint (attack_tint) instead of the dark Onix sheet, so the swing matches
  their gray stone-and-wood icon. The Onix sheets stay on the Death boss scythe.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
ANIM = 'res://assets/PixelPlainsAnimationPack/'
OLD_GEM_PRICES = [25, 40, 58, 80, 105, 135, 170, 210, 260, 320, 390, 470]
GEM_PRICES = OLD_GEM_PRICES + [560, 660, 770, 890, 1020, 1160, 1310, 1470]
STONE_TINT = [0.9, 0.84, 0.84]
SWINGS = {
    'stone_axe': ANIM + 'Iron set/Axe 2 64x32.png',
    'stone_sword': ANIM + 'Iron set/Sword 2 64x32.png',
}


def apply(c):
    limits = c['progression']['gem_limits']
    limits['base_chance'] = 0.05
    limits.pop('normal_cap', None)
    limits.pop('boss_cap', None)
    g = c['upgrades']['gem_chance']
    g['cap'] = 20
    g['effect'] = 0.005
    g['prices'] = list(GEM_PRICES)
    c['campaign']['cards']['offering_c2']['value'] = 0.05
    c['upgrades']['merge_all'] = {'currency': 'gems', 'base': 5000, 'growth': 1, 'cap': 1, 'keep': True,
                                  'effect': 1, 'scope': 'global'}
    for item, sheet in SWINGS.items():
        c['items'][item]['attack'] = sheet
        c['items'][item]['attack_tint'] = list(STONE_TINT)
    return c


def main():
    before = CATALOG.read_bytes().decode('utf-8')
    catalog = apply(json.loads(before))
    assert catalog['upgrades']['gem_chance']['prices'][:12] == OLD_GEM_PRICES
    assert all(b > a for a, b in zip(GEM_PRICES, GEM_PRICES[1:]))
    after = json.dumps(catalog, indent=2) + '\n'
    if '--check' in sys.argv:
        print('unchanged' if after == before else 'differs')
        return
    CATALOG.write_bytes(after.encode('utf-8'))
    print('prices 13-20:', GEM_PRICES[12:])


if __name__ == '__main__':
    main()
