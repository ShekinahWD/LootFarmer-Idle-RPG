"""Change 77: Camp Survey becomes Camp Supplies, written into data/game/catalog.json (idempotent; --check reports
pending differences).

- campaign.cards.regional_c3 keeps its id, path, name and description keys (ownership, the Regional set and every
  save stay compatible); only its effect changes: camp_discount 0.5 -> camp_supplies 1 (one random supply on the
  first visit to each owned camp per Prestige run, campaign.camp_supply_step). Camps no longer have a discount.
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
EFFECT = {'effect': 'camp_supplies', 'value': 1}


def apply(c):
    changes = []
    card = c['campaign']['cards']['regional_c3']
    for key, value in EFFECT.items():
        if card.get(key) != value:
            card[key] = value
            changes.append('campaign.cards.regional_c3.' + key)
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
