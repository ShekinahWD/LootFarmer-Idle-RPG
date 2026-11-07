"""Change 51: the Change 36 final-boss ladder rebuilt on the H24 weapon ladder (non-gating evidence input).

Reads docs/Change_36_Evidence/final_boss_builds.json and writes docs/Change_51_Evidence/final_boss_builds_obsidian.json:
every equipped Diamond/Emerald sword becomes the Obsidian Sword at the merge level whose damage equals the old
weapon's (rounded up, capped at the legal ^100), stored weapons move to Spring-era tiers that exist under the
^20 caps (Gold -> Emerald, Diamond -> Obsidian Axe, Diamond Sword ^100 -> Diamond Sword ^20). Everything else
(level, outfits, skills, supplies, Prestige sets, seeds) is unchanged. Each label records the mapping.
"""
from pathlib import Path
import json, math
ROOT = Path(__file__).resolve().parents[1]
OLD = {'diamond_sword': (169.13002499999996, 3.3826004999999992), 'emerald_sword': (431.28156374999986, 8.625631274999998)}
OBSIDIAN = 237.705504
STORED = {'gold_sword': 'emerald_sword', 'gold_axe': 'emerald_axe', 'diamond_axe': 'obsidian_axe', 'diamond_sword': 'diamond_sword'}

def equivalent(item, level):
    base, gain = OLD[item]
    damage = base + gain * level
    return min(100, max(0, math.ceil((damage / OBSIDIAN - 1) / 0.02 - 1e-9))), damage

def main():
    spec = json.loads((ROOT / 'docs/Change_36_Evidence/final_boss_builds.json').read_text(encoding='utf-8'))
    for b in spec['builds']:
        item, level = b['weapon']
        if item in OLD:
            n, damage = equivalent(item, level)
            b['label'] = f"{b['label']} [Change 51: {item} ^{level} ({damage:.0f} dmg) -> obsidian_sword ^{n} ({OBSIDIAN * (1 + .02 * n):.0f} dmg)]"
            b['weapon'] = ['obsidian_sword', n]
        b['stored_weapons'] = [[STORED.get(i, i), min(int(l), 20 if STORED.get(i, i) != 'obsidian_axe' else 100)] for i, l in b.get('stored_weapons', [])]
    spec['farms'] = []
    spec['_about'] = 'Change 51 rebuild of the Change 36 final-boss ladder on the H24 weapon ladder (tools/change51_final_boss_builds.py). ' + spec.get('_about', '')
    out = ROOT / 'docs/Change_51_Evidence/final_boss_builds_obsidian.json'
    out.write_bytes((json.dumps(spec, indent=1) + '\n').encode('utf-8'))
    for b in spec['builds']:
        print(b['id'], b['weapon'], b['stored_weapons'])

if __name__ == '__main__':
    main()
