"""Change 78: cheaper boss automation, written into data/game/catalog.json (idempotent; --check reports pending
differences; --table prints the old and new gem price of both unlocks on every boss).

- upgrades.collect (Auto-Collect, "Boss Auto Pick") and upgrades.merge_gear (gear Auto-Merge, "Boss Auto Merge")
  get boss_price_factor 0.25: on a boss type their gem price is x0.25 (campaign.upgrade_cost, before the
  rounding up). 0.25 keeps every boss price at least 70% below its old value after rounding (0.30 would round
  to 68% on Winter II). Normal types and every other automation upgrade (range, batch, interval, Auto
  Evolution) keep their prices. Both unlocks have cap 1 and are kept by Prestige, so a level already bought
  stays bought; nothing is refunded or re-priced in a save.
"""
from pathlib import Path
import json, math, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
FACTOR = 0.25
IDS = ['collect', 'merge_gear']


def apply(c):
    changes = []
    for ident in IDS:
        if c['upgrades'][ident].get('boss_price_factor') != FACTOR:
            c['upgrades'][ident]['boss_price_factor'] = FACTOR
            changes.append('upgrades.%s.boss_price_factor' % ident)
    return changes


def price(u, stage, boss):
    # campaign.upgrade_cost for a gem, type-scope, cap-1 upgrade at level 0.
    value = float(u['base']) * (1 + .25 * (stage - 1))
    if boss:
        value *= float(u.get('boss_price_factor', 1.0))
    return max(1, math.ceil(value - 1e-9))


def table(c):
    old = {i: dict(c['upgrades'][i], boss_price_factor=1.0) for i in IDS}
    for g in c['groups']:
        if not g['boss']:
            continue
        cells = []
        for i in IDS:
            a, b = price(old[i], g['stage'], True), price(c['upgrades'][i], g['stage'], True)
            cells.append('%s %d -> %d (-%.1f%%)' % (i, a, b, 100 * (1 - b / a)))
        print(g['id'], 'stage', g['stage'], ' | '.join(cells))


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--table' in sys.argv:
        table(c); return
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': changes}))


if __name__ == '__main__':
    main()
