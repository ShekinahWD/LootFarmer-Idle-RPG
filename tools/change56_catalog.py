"""Change 56 (approved progression brief §6): "cheap first five", written into data/game/catalog.json
(idempotent; --check reports). The first five levels of each enemy type's Coin Amount, Enemy XP and Loot Chance
Coin upgrades cost x0.25 (75% cheaper); later levels keep the existing curve. No other upgrade changes
(progression.economy.cheap_first_*; campaign.upgrade_cost applies it)."""
from pathlib import Path
import json, sys
ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
# Change 71: the x0.25 discount holds for the first three levels and then fades geometrically to the full price at
# level 8 (campaign.cheap_first_factor), replacing the one-step x5.4 price jump after level 5.
ECONOMY = {'cheap_first_upgrades': ['coin_amount', 'group_xp', 'loot'], 'cheap_first_levels': 3, 'cheap_taper_until': 8, 'cheap_first_factor': 0.25}

def apply(c):
    if c['progression'].get('economy') == ECONOMY:
        return []
    c['progression']['economy'] = ECONOMY
    return ['progression.economy']

def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': changes}))

if __name__ == '__main__':
    main()
