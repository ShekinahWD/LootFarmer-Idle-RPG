"""Change 79: catalog values written into data/game/catalog.json (idempotent; --check reports pending
differences and exits 1 when any exist).

Offline Skills (brief section 4): two new global upgrades in the established offline-item pattern.
- offline_skill       Unlock offline skill drops: 75 Gems, cap 1 (weapon/outfit unlocks: 50 Gems).
- offline_skill_rate  Offline skills per hour: 150 Coins x1.5 per level, cap 10 (gear rates: 100 Coins x1.5).
  Rate (campaign.offline_snapshot): (0.5 + 0.25 x rate level) copies per hour once unlocked, so 0.5/h to 3.0/h,
  half the weapon/outfit rate (1/h to 6/h). Skills drop from 29 of 48 enemy types at 5% (bosses 10%) and every
  copy merges into a whole ability, so offline skill income stays below the gear rates and far below online
  farming. Only skills owned at departure are eligible (no discoveries), like every other offline item.
The two entries are inserted right after offline_consumable_rate so the upgrade list keeps its offline block.

Boss balance (brief section 5; evidence docs/LootFarmer_Change_79_Boss_Balance_Report.md):
- progression.balance.boss_tuning {id: [hp x, damage x]}: applied by tools/tune_campaign.py after the spot floor
  (run it after this script; --check here verifies the table, tune_campaign --check verifies the stats).
  Summer II: Elephant [0.80, 1.15], Teal Dinosaur [0.85, 1.15]. Autumn I: Squirrel [0.80, 1.30], Red Fox [0.85, 1.15].
  Autumn II: Black Cat [0.90, 1.10], Grim Reaper [0.90, 0.88]. Spring II: Red Panda [0.45, 1.35], Sunflower
  [0.45, 1.15], Green Alien (final) [0.45, 1.20]. Winter I to Summer I and Spring I: unchanged.
- Boss kits (groups[].skills): Elephant Strike + Focus (was Focus), Squirrel Strike + Heal (was Heal + Focus),
  Sunflower Fire + Heal (was Heal + Focus): every boss from Summer II on has a telegraphed damaging skill.
- Boss-only Prestige effects (same ids and owners; the value is read at runtime, so owned cards change at once and
  no save migration is needed): Giant Slayer (hunter_c1) +25% -> +15% damage against bosses, Trophy Power
  (trophy_c2) +20% -> +10%, Boss Guard (hunter_c2) 20% -> 10% less damage from bosses, the Challenge set and the
  Boss Specialist combo +10% -> +5% damage against bosses. Their English descriptions change with
  tools/localization_handoff.py change tools/change79_changed_strings.json (stale translations removed).
"""
from pathlib import Path
import json, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
OFFLINE = {
    'offline_skill': {"currency": "gems", "base": 75, "growth": 1, "cap": 1, "keep": True, "effect": 1, "scope": "global"},
    'offline_skill_rate': {"currency": "coins", "base": 150, "growth": 1.5, "cap": 10, "keep": True, "effect": 0.25, "scope": "global"},
}


BOSS_TUNING = {
    'boss-elephant': [0.80, 1.15], 'boss-teal-dinosaur': [0.85, 1.15],
    'boss-squirrel': [0.80, 1.30], 'boss-red-fox': [0.85, 1.15],
    'boss-black-cat': [0.90, 1.10], 'boss-grim-reaper': [0.90, 0.88],
    'boss-red-panda': [0.45, 1.35], 'boss-sunflower': [0.45, 1.15], 'boss-green-alien': [0.45, 1.20],
}
BOSS_SKILLS = {'boss-elephant': ['strike', 'focus'], 'boss-squirrel': ['strike', 'heal'], 'boss-sunflower': ['fire', 'heal']}
CARD_VALUES = {'hunter_c1': 0.15, 'trophy_c2': 0.10, 'hunter_c2': 0.10}
COMBO_VALUES = {'challenge_set': 0.05, 'boss_specialist': 0.05}


def apply_bosses(c):
    changes = []
    bal = c['progression']['balance']
    if bal.get('boss_tuning') != BOSS_TUNING:
        bal['boss_tuning'] = BOSS_TUNING
        changes.append('progression.balance.boss_tuning')
    for g in c['groups']:
        if g['id'] in BOSS_SKILLS and g['skills'] != BOSS_SKILLS[g['id']]:
            g['skills'] = list(BOSS_SKILLS[g['id']])
            changes.append('groups.%s.skills' % g['id'])
    for key, value in CARD_VALUES.items():
        if c['campaign']['cards'][key]['value'] != value:
            c['campaign']['cards'][key]['value'] = value
            changes.append('campaign.cards.%s.value' % key)
    for d in c['campaign']['combos']:
        if d['id'] in COMBO_VALUES and d['value'] != COMBO_VALUES[d['id']]:
            d['value'] = COMBO_VALUES[d['id']]
            changes.append('campaign.combos.%s.value' % d['id'])
    return changes


def apply(c):
    changes = apply_bosses(c)
    ups = c['upgrades']
    if any(ups.get(k) != v for k, v in OFFLINE.items()):
        rebuilt = {}
        for key, value in ups.items():
            if key in OFFLINE:
                continue
            rebuilt[key] = value
            if key == 'offline_consumable_rate':
                rebuilt.update(OFFLINE)
        c['upgrades'] = rebuilt
        changes.append('upgrades.offline_skill/offline_skill_rate')
    return changes


def main():
    c = json.loads(CATALOG.read_text(encoding='utf-8'))
    changes = apply(c)
    if '--check' in sys.argv:
        print(json.dumps({'pending_changes': changes})); sys.exit(1 if changes else 0)
    CATALOG.write_bytes((json.dumps(c, indent=2) + '\n').encode('utf-8'))
    print(json.dumps({'changed': changes}))


if __name__ == '__main__':
    main()
