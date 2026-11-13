"""Change 76: the Auto Buy Supplies unlock, written into data/game/catalog.json (idempotent; --check reports
pending differences).

- auto_buy_slots: a global Gem upgrade, one Auto Buy slot per level, cap 3 (simulation.AUTO_BUY_SLOTS).
  Prices 100 / 160 / 250 Gems: the brief fixes the first (100) and the last (250); the middle step follows the
  x1.6 growth of the neighbouring Supplies automation upgrade (use_speed: 100, 160, ...), and 160 -> 250 is
  x1.56, so the schedule rises evenly. Kept by Prestige like every upgrade (simulation.upgrade_kept).
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
AUTO_BUY = {'currency': 'gems', 'base': 100, 'growth': 1, 'prices': [100, 160, 250], 'cap': 3, 'keep': True,
            'effect': 1, 'scope': 'global'}


def apply(c):
    changes = []
    if c['upgrades'].get('auto_buy_slots') != AUTO_BUY:
        c['upgrades']['auto_buy_slots'] = dict(AUTO_BUY)
        changes.append('upgrades.auto_buy_slots')
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
