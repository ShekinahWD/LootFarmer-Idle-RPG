"""Candidate (what-if) ladder: bosses only (spots are untouched by boss stats and boss-only cards), P0/P1/P3.
usage: gen_cand.py candidate.json out.json ; candidate = {"bosses": {id: patch}, "cards": {id: v}, "combos": {id: v}}"""
import json, sys
from pathlib import Path
base = json.load(open('tests/tmp/c79/base_ladder.json'))
cand = json.load(open(sys.argv[1]))
B = []
for b in base['builds']:
    enc = []
    for e in b['encounters']:
        if e['kind'] != 'boss': continue
        e = dict(e)
        if e['group'] in cand.get('bosses', {}): e['patch'] = cand['bosses'][e['group']]
        enc.append(e)
    B.append(dict(b, encounters=enc))
out = {"seeds": [1, 2], "card_sets": base['card_sets'], "builds": B, "card_values": cand.get('cards', {}), "combo_values": cand.get('combos', {})}
Path(sys.argv[2]).write_text(json.dumps(out, indent=1))
print(len(B), 'builds', sum(len(b['encounters']) * 2 for b in B), 'trials')
