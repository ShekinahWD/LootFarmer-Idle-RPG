"""Change 81: catalog values written into data/game/catalog.json (idempotent; --check reports pending
differences and exits 1 when any exist). Brief: docs/LootFarmer_Change_81_Final_Boss_Combat_Progression.md.
Run tools/tune_campaign.py afterwards (this tool runs it itself unless --check).

1. Camp Reveal Radius (upgrades.camp_radius) becomes ONE global permanent Gem upgrade: 10 / 20 / 40 Gems
   (70 in all), cap 3, +25% of the base camp reveal radius per level (additive), for every owned camp.
   Per-camp records migrate once (campaign.migrate_camp_radius_global).
2. Player level cap (progression.max_level) 1000 -> 500. XP curve ceil(12 x L^1.35) and every XP reward unchanged.
3. Spring I / Spring II enemy attack damage x1.5 (every direct hit at least 1.50x the Change 80 value):
   - normal types: progression.combat.normal_damage_scale {"7","8"} 0.60 -> 0.90 (exactly x1.5, every variant;
     enemy skills scale from this same definition damage, so they rise with it and are NOT multiplied again);
   - bosses: their boss_tuning damage multiplier is set so the tuned damage is >= 1.5x BOSS_DAMAGE_BEFORE. The
     Change 62 spot floor also reads normal_damage_scale, so the multiplier is solved against the NEW floor
     (never a double x1.5). Their HP multiplier is divided by 1.5 (BOSS_HP_BEFORE / 1.5): each hit stays x1.5
     while a whole fight deals about the damage it used to, so the first-clear path moves about one ladder rung
     instead of walling Spring II (measured: generated/evidence/change_81/, tests/tmp/c81/).
   - summoned helpers (Sunflower, Green Alien) are scaled in resources/game/enemy_abilities.tres (damage_scale x1.5).
4. Obsidian Sword / Obsidian Axe (final weapon tier) merge to ^500 (progression.merge.final_weapon_cap) with a
   post-^100 tail of 0.5 per level (final_weapon_tail_rate, the outfit tail) and offensive milestones at
   ^100-^500 (progression.weapon_milestones, by weapon family; values replace the previous step's, as outfits).
"""
from pathlib import Path
import json, math, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
sys.path.insert(0, str(ROOT / 'tools'))
import tune_campaign

CAMP_RADIUS = {"currency": "gems", "base": 10, "growth": 1, "prices": [10, 20, 40], "cap": 3, "keep": True,
               "effect": 0.25, "scope": "global", "flat": True}
MAX_LEVEL = 500
SPRING_STAGES = ("7", "8")
NORMAL_SCALE_BEFORE = 0.6
NORMAL_SCALE = 0.9
DAMAGE_FACTOR = 1.5
# Boss damage in the catalog before Change 81 (Change 79 tuning, Change 80 untouched) - the x1.5 reference.
BOSS_DAMAGE_BEFORE = {
    'boss-bee': 150.1769, 'boss-orange-tabby-cat': 160.9878,
    'boss-red-panda': 379.0051, 'boss-sunflower': 346.0978, 'boss-green-alien': 415.013,
}
# boss_tuning HP multipliers before Change 81 (Change 79; Bee and Orange Tabby had no entry = 1.0), divided by 1.5.
BOSS_HP_BEFORE = {'boss-bee': 1.0, 'boss-orange-tabby-cat': 1.0, 'boss-red-panda': 0.45, 'boss-sunflower': 0.45, 'boss-green-alien': 0.45}
FINAL_WEAPON_CAP = 500
FINAL_WEAPON_TAIL = 0.5
WEAPON_MILESTONES = {
    # Sword: precision. Critical Chance / Critical Damage (flat additions) and a share of the sword's core damage.
    "sword": [
        {"merge": 100, "id": "honed_edge", "crit": 0.02},
        {"merge": 200, "id": "keen_edge", "crit": 0.02, "crit_damage": 0.10},
        {"merge": 300, "id": "tempered_blade", "crit": 0.04, "crit_damage": 0.10, "damage_share": 0.10},
        {"merge": 400, "id": "razor_edge", "crit": 0.04, "crit_damage": 0.20, "damage_share": 0.10},
        {"merge": 500, "id": "obsidian_mastery", "crit": 0.06, "crit_damage": 0.25, "damage_share": 0.15},
    ],
    # Axe: weight and sustain. Lifesteal and a larger share of the axe's core damage (no Defense/HP/regen).
    "axe": [
        {"merge": 100, "id": "bloodthirst", "lifesteal": 0.01},
        {"merge": 200, "id": "heavy_head", "lifesteal": 0.01, "damage_share": 0.10},
        {"merge": 300, "id": "bloodthirst_2", "lifesteal": 0.02, "damage_share": 0.10},
        {"merge": 400, "id": "crushing_head", "lifesteal": 0.02, "damage_share": 0.20},
        {"merge": 500, "id": "obsidian_mastery", "lifesteal": 0.03, "damage_share": 0.25},
    ],
}


def boss_multipliers(c):
    """{boss id: tuning damage multiplier} giving >= 1.5x BOSS_DAMAGE_BEFORE on the new spot floor."""
    b = c['progression']['balance']
    out = {}
    for g in c['groups']:
        if g['id'] not in BOSS_DAMAGE_BEFORE:
            continue
        pre = max(tune_campaign.compute(g, b)[1], tune_campaign.boss_floor(c, int(g['stage'])))
        target = DAMAGE_FACTOR * BOSS_DAMAGE_BEFORE[g['id']]
        out[g['id']] = math.ceil(target / pre * 1000) / 1000
    return out


def apply(c):
    changes = []
    if c['upgrades']['camp_radius'] != CAMP_RADIUS:
        c['upgrades']['camp_radius'] = dict(CAMP_RADIUS); changes.append('upgrades.camp_radius')
    p = c['progression']
    if p['max_level'] != MAX_LEVEL:
        p['max_level'] = MAX_LEVEL; changes.append('progression.max_level')
    scale = p['combat']['normal_damage_scale']
    for st in SPRING_STAGES:
        if float(scale.get(st, 1.0)) not in (NORMAL_SCALE_BEFORE, NORMAL_SCALE):
            raise SystemExit('normal_damage_scale %s is %s, not the expected Change 80 value' % (st, scale.get(st)))
        if float(scale[st]) != NORMAL_SCALE:
            scale[st] = NORMAL_SCALE; changes.append('progression.combat.normal_damage_scale.' + st)
    tuning = p['balance']['boss_tuning']
    for boss, dm in boss_multipliers(c).items():
        hm = round(BOSS_HP_BEFORE[boss] / DAMAGE_FACTOR, 4)
        # Change 83 supersedes the Green Alien entry (HP and damage x2): tools/change83_catalog.py.
        if boss == 'boss-green-alien':
            hm, dm = round(hm * 2.0, 4), round(dm * 2.0, 4)
        if tuning.get(boss, [1.0, 1.0]) != [hm, dm]:
            tuning[boss] = [hm, dm]; changes.append('progression.balance.boss_tuning.' + boss)
    m = p['merge']
    for key, value in (('final_weapon_cap', FINAL_WEAPON_CAP), ('final_weapon_tail_rate', FINAL_WEAPON_TAIL)):
        if m.get(key) != value:
            m[key] = value; changes.append('progression.merge.' + key)
    if p.get('weapon_milestones') != WEAPON_MILESTONES:
        p['weapon_milestones'] = WEAPON_MILESTONES; changes.append('progression.weapon_milestones')
    return changes


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': len(changes)})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    subprocess.run([sys.executable, str(ROOT / 'tools/tune_campaign.py')], check=True, capture_output=True)
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    after = {g['id']: g['damage'] for g in c['groups'] if g['id'] in BOSS_DAMAGE_BEFORE}
    for boss, before in BOSS_DAMAGE_BEFORE.items():
        if after[boss] < DAMAGE_FACTOR * before - 1e-6:
            raise SystemExit('%s damage %.4f is below x%.2f of %.4f' % (boss, after[boss], DAMAGE_FACTOR, before))
    print(json.dumps({'changed': changes, 'boss_damage': {k: [BOSS_DAMAGE_BEFORE[k], after[k], round(after[k] / BOSS_DAMAGE_BEFORE[k], 4)] for k in after}}))


if __name__ == '__main__':
    main()
