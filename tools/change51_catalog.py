"""Change 51 (approved progression brief, B2): the H24 weapon ladder, one weapon tier per stage, ^20/^100
weapon merge caps and 31-copy evolution, written into data/game/catalog.json (idempotent).

- Sword base damage: Wood 4.0, x1.9 per tier through Emerald, Emerald -> Obsidian x2.4
  (4.0, 7.6, 14.44, 27.436, 52.1284, 99.04396, 237.705504). Merge gain stays 2% of base per level.
  Axe: 0.8x the sword's damage, HP 3.0x the sword's base damage (the existing formula).
- Loot: every enemy of stage s drops tier min(s, 7) of its own family (Sword/Axe unchanged); bosses drop
  the same tier (their copies are boss-enhanced, Change 52). The final boss drops an Obsidian Sword. A group's
  carried weapon art follows its loot weapon, so the Snowman's guaranteed first-kill weapon (the boss's own
  weapon, onboarding_rules.tres) becomes the Wood Axe.
- Merge caps: weapons with a next tier stop new merges at ^20 (progression.merge.evolvable_weapon_cap);
  Obsidian keeps ^100 (weapon_cap). Evolution: ^20 + 10 spare copies (required_merge 20, spare_cost 10);
  the retired base_multiplier is removed (the tier table is explicit).
- Legacy copies: each tier 2-7 weapon gets a "<id>_legacy" entry with its previous stats (legacy: true,
  no next tier, never dropped, its own merge cap). Saves convert owned old-stat weapons to these once
  (campaign.migrate_legacy_weapons), so nobody loses power before their next Prestige.
"""
from pathlib import Path
import json, copy

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
TIERS = ['wood', 'stone', 'iron', 'gold', 'diamond', 'emerald', 'obsidian']
H24 = [4.0, 7.6, 14.44, 27.436, 52.1284, 99.04396, 237.705504]
EVOLVABLE_CAP, OBSIDIAN_CAP = 20, 100


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    items = c['items']
    for t, name in enumerate(TIERS):
        b = H24[t]
        for family in ('sword', 'axe'):
            iid = f'{name}_{family}'
            it = items[iid]
            legacy_id = iid + '_legacy'
            if t >= 1 and legacy_id not in items:
                old = copy.deepcopy(it)
                old['legacy'] = True
                old['next'] = ''
                old['art_id'] = iid
                old['legacy_of'] = iid
                old['merge_cap'] = EVOLVABLE_CAP if it['next'] else OBSIDIAN_CAP
                items[legacy_id] = old
            if family == 'sword':
                it['normal'] = {'damage': [b, round(b * 0.02, 8)]}
                it['merge_gain'] = {'damage': round(b * 0.02, 8)}
            else:
                d, hp = round(b * 0.8, 8), round(b * 3.0, 8)
                it['normal'] = {'damage': [d, round(d * 0.02, 8)], 'hp': [hp, round(hp * 0.02, 8)]}
                it['merge_gain'] = {'damage': round(d * 0.02, 8), 'hp': round(hp * 0.02, 8)}
    for g in c['groups']:
        tier = min(int(g['stage']), 7)
        loot = []
        for iid in g['loot']:
            it = items[iid]
            if it['kind'] == 'weapon':
                new = f'{TIERS[tier - 1]}_{it["family"]}'
                if g.get('final'):
                    new = 'obsidian_sword'
                if g.get('weapon') == iid:
                    g['weapon'] = new
                loot.append(new)
            else:
                loot.append(iid)
        g['loot'] = loot
    # Masterwork and Arsenal thresholds changed (^20 weapons): new description keys, never a stale translation.
    for op in c['campaign']['opportunities']:
        if op['path'] in ('masterwork', 'arsenal') and op['id'][-1] in '123':
            op['description'] = f"CONTENT_{op['path'].upper()}_O{op['id'][-1]}_RULE"
    merge = c['progression']['merge']
    merge['weapon_cap'] = OBSIDIAN_CAP
    merge['evolvable_weapon_cap'] = EVOLVABLE_CAP
    evo = c['progression']['evolution']
    evo['required_merge'] = EVOLVABLE_CAP
    evo['spare_cost'] = 10
    evo.pop('base_multiplier', None)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print('weapons', {i: items[i]['normal'] for i in items if items[i]['kind'] == 'weapon' and not items[i].get('legacy')})


if __name__ == '__main__':
    main()
