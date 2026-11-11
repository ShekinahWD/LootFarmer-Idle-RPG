"""Recompute enemy stats from the balance constants in catalog.progression.balance (Change 6).

Normal both-variant enemy at fixed roster level L:
    ramp(L)  = 1 + min(L, ramp_cap) / ramp_div          (separate divisors for HP and damage)
    hp(L)    = hp_base * hp_growth^(L-1) * ramp_hp(L)
    dmg(L)   = damage_base * damage_growth^(L-1) * ramp_damage(L)
Bosses multiply the normal value at their level (boss_overrides may set [hp, damage] per boss id,
used where an authored boss meets a very different player-level advantage); the final boss uses
its own multipliers.
The first enemy keeps the approved prototype opening (18 HP, 2 damage, 2 s).
Variant multipliers, XP and coin formulas are unchanged and applied at runtime / below.
Run after editing the constants; --check verifies the catalog matches without writing.
"""
from pathlib import Path
import json, math, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'


def compute(group, b):
    L = group['level']
    ramp_hp = 1 + min(L, b['ramp_cap']) / b['ramp_hp_div']
    ramp_dmg = 1 + min(L, b['ramp_cap']) / b['ramp_damage_div']
    hp = b['hp_base'] * b['hp_growth'] ** (L - 1) * ramp_hp
    dmg = b['damage_base'] * b['damage_growth'] ** (L - 1) * ramp_dmg
    if group['final']:
        hp *= b['final_hp']; dmg *= b['final_damage']
    elif group['boss']:
        hm, dm = b.get('boss_overrides', {}).get(group['id'], [b['boss_hp'], b['boss_damage']])
        hp *= hm; dmg *= dm
    if group['id'] == b['opening_type']:
        hp, dmg = b['opening'][0], b['opening'][1]
    return round(hp, 4), round(dmg, 4)


def spot_reference(data, stage):
    """Change 62: (type id, pre-Defense damage) of the stage's strongest normal type in its standard full
    loadout, on the game's own basis (catalog damage x progression.combat.normal_damage_scale)."""
    b = data['progression']['balance']
    scale = float(data['progression'].get('combat', {}).get('normal_damage_scale', {}).get(str(stage), 1.0))
    rows = [(g['id'], compute(g, b)[1] * scale) for g in data['groups'] if not g['boss'] and int(g['stage']) == stage]
    return max(rows, key=lambda r: r[1])


def boss_floor(data, stage):
    """Change 62: a boss's basic attack is at least boss_spot_share (0.90) of a three-enemy spot of that
    reference type, rounded up to 4 decimals. 0 when the balance has no share."""
    share = float(data['progression']['balance'].get('boss_spot_share', 0))
    return math.ceil(share * 3 * spot_reference(data, stage)[1] * 10000 - 1e-6) / 10000 if share > 0 else 0.0


def main():
    data = json.loads(CATALOG.read_text())
    b = data['progression']['balance']
    mismatch = 0
    for g in data['groups']:
        hp, dmg = compute(g, b)
        if g['boss']:
            dmg = max(dmg, boss_floor(data, int(g['stage'])))
        if abs(g['hp'] - hp) > 1e-3 or abs(g['damage'] - dmg) > 1e-3:
            mismatch += 1
            g['hp'], g['damage'] = hp, dmg
    if '--check' in sys.argv:
        print(json.dumps({'groups': len(data['groups']), 'mismatches': mismatch}))
        sys.exit(1 if mismatch else 0)
    CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    for g in data['groups']:
        print('%-26s L%-3d %s hp=%10.1f dmg=%8.2f' % (g['id'], g['level'], 'BOSS' if g['boss'] else '    ', g['hp'], g['damage']))
    print(json.dumps({'groups': len(data['groups']), 'updated': mismatch}))


if __name__ == '__main__':
    main()
