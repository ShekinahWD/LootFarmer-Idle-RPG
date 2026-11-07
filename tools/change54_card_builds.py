"""Change 54: card-effect measurement builds (non-gating evidence input). Copies four ready builds of the audit
ladder (docs/Consolidated_Audit_Evidence/builds_ladder.json) without Prestige, with the eight new farming and
survival cards (real Prestige transaction, explicit picks) and with the two boss-leaning cards, and writes
docs/Change_54_Evidence/builds_cards.json. Run: tests/progression_audit.tscn --builds=<that file>."""
from pathlib import Path
import copy, json
ROOT = Path(__file__).resolve().parents[1]
spec = json.loads((ROOT / 'docs/Consolidated_Audit_Evidence/builds_ladder.json').read_text(encoding='utf-8'))
spec['card_sets']['pfarm'] = {
    'ready': ['expedition_o1', 'expedition_o2', 'expedition_o3', 'expedition_o4', 'expedition_o5', 'collection_o1'],
    'picks': ['expedition_c4', 'expedition_c5', 'expedition_c6', 'expedition_c7', 'expedition_c8', 'collection_c6']}
spec['card_sets']['pboss'] = {'ready': ['hunter_o1', 'challenge_o1'], 'picks': ['hunter_c4', 'challenge_c4']}
out = []
for b in spec['builds']:
    if b['id'] not in ('N3_rdy', 'N5_rdy', 'N7_rdy', 'N8_obs100'):
        continue
    out.append(b)
    for name in ('pfarm', 'pboss'):
        c = copy.deepcopy(b)
        c['id'] = f"{b['id']}_{name}"
        c['prestige'] = list(b.get('prestige', [])) + [name]
        c['label'] = f"{b.get('label', b['id'])} + {name} ({', '.join(spec['card_sets'][name]['picks'])})"
        out.append(c)
spec['builds'] = out
(ROOT / 'docs/Change_54_Evidence/builds_cards.json').write_bytes((json.dumps(spec, indent=1) + '\n').encode('utf-8'))
print([b['id'] for b in out])
