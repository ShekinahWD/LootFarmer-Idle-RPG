"""Change 79: P0 / P1 / P3 power ladder for stages 4-8 (the Change 78 ladder builds, unchanged gear/levels),
bosses + the stage's two strongest variant spots at 3 and 6 actors, and Green Alien on stage 8 (13-key fixture).
Usage: python gen_ladder.py out.json [patchfile.json]  (patch: {boss_id: {damage,hp,skills,interval}} in memory)"""
import json, sys, importlib.util
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("pfa", ROOT / "tools/player_feedback_audit_builds.py")
pfa = importlib.util.module_from_spec(spec); spec.loader.exec_module(pfa)
L = json.load(open(ROOT / 'tests/tmp/c78/ladder_c78.json'))
patch = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else {}
SETS = {0: [], 1: ["p1"], 3: ["p1", "p2", "p3"]}
B = []
for b in L['builds']:
    st = int(b['stage'])
    if st < 4 or b['id'].endswith('_P1'):
        continue
    enc = [dict(e) for e in b['encounters']]
    if st == 8:
        enc.append({"kind": "boss", "group": "boss-green-alien", "limit": 900})
    for e in enc:
        if e['kind'] == 'boss' and e['group'] in patch:
            e['patch'] = patch[e['group']]
    for n, sets in SETS.items():
        nb = dict(b, id=f"{b['id']}_P{n}", prestige=sets, prestiges=n, kills=pfa.kills_for(st, n), encounters=enc)
        B.append(nb)
out = Path(sys.argv[1])
out.write_text(json.dumps({"seeds": [1, 2], "card_sets": L['card_sets'], "builds": B}, indent=1))
print(len(B), 'builds', sum(len(b['encounters']) * 2 for b in B), 'trials')
