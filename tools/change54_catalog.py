"""Change 54 (approved progression brief, B5 / audit Design A): Prestige expansion 33 -> 48 opportunities and
33 -> 48 cards on the existing 11 paths, written into data/game/catalog.json (idempotent; --check reports).

- 15 opportunities (audit §7.3): Expedition IV-VIII and Collection IV-VIII on Winter II, Summer II, Autumn I,
  Autumn II and Spring II; Hunter IV (Spring I), Challenge IV (Spring II), Trophy IV (Spring I-II), Regional IV
  (Autumn I-II), Masterwork IV (Spring I-II). Requirements live in scripts/game/campaign.gd's Design A tables.
- Every opportunity gets "stages": the maps where its requirement is performed (the Prestige panel groups by it;
  this also fixes Trophy II/III, shown under the wrong maps before). [0] = general (any map).
- 15 cards, one effect each (starting values from the audit, measured in Change 54). Paths stay path-specific:
  each path has exactly as many cards as opportunities. The original three-card Sets (combos) are untouched:
  the original c1-c3 of a path still activate its Set; no all-cards Set exists.
"""
from pathlib import Path
import json, sys
ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'

NEW_OPPORTUNITIES = [
    ('expedition_o4', 'expedition', 'Kill 10 wolf-hood enemies'),
    ('expedition_o5', 'expedition', 'Kill 10 cowboy-bandana enemies'),
    ('expedition_o6', 'expedition', 'Kill 10 black-cap enemies'),
    ('expedition_o7', 'expedition', 'Kill 10 horned-hood enemies'),
    ('expedition_o8', 'expedition', 'Kill 10 flower-crown enemies'),
    ('collection_o4', 'collection', 'Reach Winter II'),
    ('collection_o5', 'collection', 'Reach Summer II'),
    ('collection_o6', 'collection', 'Reach Autumn I'),
    ('collection_o7', 'collection', 'Reach Autumn II'),
    ('collection_o8', 'collection', 'Reach Spring II'),
    ('hunter_o4', 'hunter', 'Defeat boss-bee once'),
    ('challenge_o4', 'challenge', 'Defeat boss-red-panda once'),
    ('trophy_o4', 'trophy', 'Defeat boss-bee once'),
    ('regional_o4', 'regional', 'Reach Autumn II'),
    ('masterwork_o4', 'masterwork', 'Own an Obsidian weapon'),
]
STAGES = {
    'hunter_o1': [1], 'hunter_o2': [3], 'hunter_o3': [6], 'hunter_o4': [7],
    'challenge_o1': [2], 'challenge_o2': [4], 'challenge_o3': [6], 'challenge_o4': [8],
    'expedition_o1': [1], 'expedition_o2': [3], 'expedition_o3': [7], 'expedition_o4': [2],
    'expedition_o5': [4], 'expedition_o6': [5], 'expedition_o7': [6], 'expedition_o8': [8],
    'collection_o1': [1], 'collection_o2': [3], 'collection_o3': [7], 'collection_o4': [2],
    'collection_o5': [4], 'collection_o6': [5], 'collection_o7': [6], 'collection_o8': [8],
    'regional_o1': [1, 2], 'regional_o2': [3, 4], 'regional_o3': [7, 8], 'regional_o4': [5, 6],
    'trophy_o1': [1, 2], 'trophy_o2': [3, 4], 'trophy_o3': [5, 6], 'trophy_o4': [7, 8],
    'masterwork_o4': [7, 8],
}
# id: (effect, value). Values are the audit's starting points (Change 54 measures them).
NEW_CARDS = {
    'expedition_c4': ('crowd_guard', 0.04),        # -4% damage taken per normal attacker beyond the first, max -20%
    'expedition_c5': ('second_wind', 0.25),        # first drop below 30% HP heals 25% max HP, once per 90 s
    'expedition_c6': ('cleave', 0.30),             # basic attacks hit other enemies within 32 units for 30%
    'expedition_c7': ('broken_rally', 0.5),        # enemies pulled into a group fight start 0.5 s later
    'expedition_c8': ('field_rest', 2.0),          # out-of-combat recovery outside camps x3
    'collection_c4': ('twin_find', 0.10),          # normal gear drops: 10% chance of 2 copies
    'collection_c5': ('thrifty_evolution', 2.0),   # evolution needs 2 fewer spare copies (8)
    'collection_c6': ('steady_supplies', 0.15),    # supply cooldowns -15%
    'collection_c7': ('precise_reroll', 0.25),     # rerolls -25% and never return the same stat
    'collection_c8': ('treasure_sense', 1.0),      # boss attributes roll in the upper half of their range
    'hunter_c4': ('boss_breaker', 0.25),           # boss telegraphs +0.3 s, boss heals -25%
    'challenge_c4': ('last_stand', 0.20),          # below 25% HP: +20% attack speed
    'trophy_c4': ('champions_spoils', 1.0),        # a boss's first defeat each run rolls its loot twice
    'regional_c4': ('veteran_traveler', 0.25),     # +25% XP from normal enemies below the highest unlocked map
    'masterwork_c4': ('obsidian_temper', 0.15),    # Obsidian merge gain +15%
}


def apply(c):
    changes = []
    camp = c['campaign']
    ops = {o['id']: o for o in camp['opportunities']}
    for oid, path, discovery in NEW_OPPORTUNITIES:
        if oid not in ops:
            o = {'id': oid, 'path': path, 'name': f'CONTENT_{oid.upper()}_NAME', 'discovery': discovery,
                 'description': f'CONTENT_{oid.upper()}_DESCRIPTION', 'lifetime': False}
            camp['opportunities'].append(o); ops[oid] = o; changes.append(oid)
    for o in camp['opportunities']:
        stages = STAGES.get(o['id'], [0])
        if o.get('stages') != stages:
            o['stages'] = stages; changes.append(o['id'] + '.stages')
    for cid, (effect, value) in NEW_CARDS.items():
        want = {'path': cid.split('_c')[0], 'name': f'CONTENT_{cid.upper()}_NAME', 'description': f'CONTENT_{cid.upper()}_DESCRIPTION', 'effect': effect, 'value': value}
        if camp['cards'].get(cid) != want:
            camp['cards'][cid] = want; changes.append(cid)
    return changes


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': len(changes), 'opportunities': len(c['campaign']['opportunities']), 'cards': len(c['campaign']['cards'])}))


if __name__ == '__main__':
    main()
