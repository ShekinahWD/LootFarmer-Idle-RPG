"""Change 16 catalog edits (idempotent; --check reports differences only).

- Coin income: the base Coin reward of a normal enemy is 1.5^(stage - 1) (was 1.25^(stage - 1)), so
  every map pays +50% more than the one before, compounded. Winter I stays at 1 Coin; bosses keep
  their 8x. Coin Amount upgrades and every bonus still multiply this base at runtime.
- Coin prices tied to a map: every Coin purchase scoped to an enemy type, a map or a camp (enemy
  upgrades, Map Details floor, reveal and camp radius, camp unlocks) scales by
  progression.map_cost_growth^(stage - 1) = 1.55 per map (was 2). Each upgrade keeps its own
  level-based price. Global Coin upgrades and every Gem price are unchanged. 1.55 > 1.5, so each
  new map is slightly more expensive relative to its base income than the one before.
- Auto-Collect (`collect`) is bought with Gems: 20 on Winter I. Collect Batch (`collect_batch`) is
  bought with Gems: 50 on Winter I, x3 per level as before (batch 1 -> 6). Like every Gem upgrade
  they scale 1 + 0.25 x (stage - 1) per map and are kept by Prestige. Levels already bought with Coins
  keep their level.
- Health Potion: heals 10% of max HP at ^0 and 20% at ^100 before external bonuses (was 20% -> 40%),
  keeping the shared supply rule (base + 1% of base per mastery level). Max-HP bonuses still raise
  the HP it restores.

tools/change8_catalog.py (Collect Batch) and tools/change11_catalog.py (potion) hold the same values.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
REWARD_GROWTH = 1.5
COST_GROWTH = 1.55
BOSS_COINS = 8
COLLECT = {'currency': 'gems', 'base': 20, 'growth': 1, 'keep': True}
COLLECT_BATCH = {'currency': 'gems', 'base': 50, 'growth': 3.0, 'keep': True}
POTION_HEAL = [0.1, 0.001]


def coins(group):
    return round(REWARD_GROWTH ** (group['stage'] - 1) * (BOSS_COINS if group['boss'] else 1), 6)


def apply(c):
    for g in c['groups']:
        g['coins'] = coins(g)
    c['progression']['map_reward_growth'] = REWARD_GROWTH
    c['progression']['map_cost_growth'] = COST_GROWTH
    c['upgrades']['collect'].update(COLLECT)
    c['upgrades']['collect_batch'].update(COLLECT_BATCH)
    potion = c['items']['potion']
    potion['normal']['heal_pct'] = list(POTION_HEAL)
    potion['merge_gain']['heal_pct'] = POTION_HEAL[1]
    return c


def main():
    before = CATALOG.read_bytes().decode('utf-8')
    catalog = apply(json.loads(before))
    assert COST_GROWTH > REWARD_GROWTH, 'each map must cost slightly more relative to its income'
    assert abs(POTION_HEAL[0] + 100 * POTION_HEAL[1] - 0.2) < 1e-9, 'potion heals 20% at ^100'
    after = json.dumps(catalog, indent=2) + '\n'
    if '--check' in sys.argv:
        print('unchanged' if after == before else 'differs')
        sys.exit(0 if after == before else 1)
    CATALOG.write_bytes(after.encode('utf-8'))
    print('coins per map x%s, coin prices per map x%s, collect %s, collect_batch %s, potion %s'
          % (REWARD_GROWTH, COST_GROWTH, COLLECT, COLLECT_BATCH, POTION_HEAL))


if __name__ == '__main__':
    main()
