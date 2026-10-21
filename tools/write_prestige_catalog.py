"""Generate docs/LootFarmer_Prestige_Catalog.md from the runtime catalog plus the Change 6 review notes.
Counts and current texts come from data/game/catalog.json and localization/en.po, so the document cannot
drift from runtime ids. Review notes (routes, effort, problems) are authored below."""
from pathlib import Path
import json, re

ROOT = Path(__file__).resolve().parents[1]
d = json.loads((ROOT / 'data/game/catalog.json').read_bytes())
po = (ROOT / 'localization/en.po').read_bytes().decode('utf-8')


def t(key):
    m = re.search(r'msgid "%s"\nmsgstr "(.*)"' % re.escape(key), po)
    return m.group(1) if m else key


OLD = {'hunter_c1': '+3% boss damage', 'hunter_c2': '−2% boss damage taken', 'hunter_c3': '+3% boss coins',
       'expedition_c1': '+3% normal damage', 'expedition_c2': '+3% normal coins', 'expedition_c3': '+3% normal XP',
       'collection_c1': '+5% collect radius', 'collection_c2': '+1 pt gear chance', 'collection_c3': '+1 pt supply chance',
       'masterwork_c1': '+2% merge gains', 'masterwork_c2': '−3% reroll cost', 'masterwork_c3': '+2% equipped base stats',
       'arsenal_c1': '+3% max HP', 'arsenal_c2': '+2% damage', 'arsenal_c3': '−1% damage taken',
       'regional_c1': '+2% move speed', 'regional_c2': '+5% reveal radius', 'regional_c3': '+5% camp reveal radius',
       'challenge_c1': '+1 pt crit chance', 'challenge_c2': '−2% boss damage taken (same effect as Boss Guard)', 'challenge_c3': '+3% crit damage',
       'offering_c1': '+2% coins', 'offering_c2': '+0.5 pt gem chance', 'offering_c3': '−2% coin prices',
       'specialist_c1': '+3% mission coins', 'specialist_c2': '+3% mission gems', 'specialist_c3': '+2% skill strength',
       'trophy_c1': '+2% boss XP', 'trophy_c2': '+2% boss damage', 'trophy_c3': '+2% boss gems',
       'offline_c1': '+5% offline coins', 'offline_c2': '+5% offline gems', 'offline_c3': '+5% offline items'}

IMPACT = {'hunter_c1': 'Boss TTK −20%; fewer potions per boss.',
          'hunter_c2': 'Boss incoming damage −20%; boss HP race shifts ~25% in the player\'s favour.',
          'hunter_c3': 'Boss coins ×2 (Snowman 8 → 16).',
          'expedition_c1': 'Normal TTK −17%: roughly 15–20% faster farming.',
          'expedition_c2': '+30% of the main coin source.',
          'expedition_c3': '+30% XP from the main XP source: levels about 25% sooner (bot: see validation).',
          'collection_c1': 'Only with auto-collect: a later-run card.',
          'collection_c2': 'Winter gear drops 10% → 13% (+30% drops and merges).',
          'collection_c3': 'Supplies 5% → 10% (twice the potions).',
          'masterwork_c1': 'Every merge +25%: a tier-1 ^100 weapon 9 → 10.5 damage.',
          'masterwork_c2': 'Gem-sink discount; little early value.',
          'masterwork_c3': 'Equipped weapon/outfit base stats +20%.',
          'arsenal_c1': '+20% HP. Measured: next run reached the gate in 73–77 min on two seeds (133 on the third) vs 92–113 with no cards; first boss 14–18 vs 23–29 min.',
          'arsenal_c2': '+15% all damage including skills.',
          'arsenal_c3': '−10% damage from every enemy; longer fights between rests.',
          'regional_c1': '+15% movement: travel, farming and loot pickup.',
          'regional_c2': '+50% personal reveal radius: faster discovery.',
          'regional_c3': 'Camps half price (Winter I 50 → 25 coins).',
          'challenge_c1': 'Crit 5% → 20%: about +7% DPS alone, about +25% with Hard Hit.',
          'challenge_c2': 'Heals 5% of damage dealt (≈0.75 HP/s at 15 DPS).',
          'challenge_c3': 'Crit ×1.5 → ×2.25; strong only with crit chance (synergy card).',
          'offering_c1': '+25% coins from every enemy.',
          'offering_c2': 'Gem chance 8% → 11% (normal cap 20%).',
          'offering_c3': 'Coin upgrades −15%.',
          'specialist_c1': 'Missions pay +50% coins (Winter hunt 150 → 225).',
          'specialist_c2': 'Missions pay +50% gems.',
          'specialist_c3': '+25% Heal and damage skills (skills start late Winter II).',
          'trophy_c1': 'Boss XP +50% (Snowman 40 → 60).',
          'trophy_c2': 'Boss TTK −17%.',
          'trophy_c3': 'Boss gems +50%.',
          'offline_c1': 'Offline coins 120 → 180 per hour.',
          'offline_c2': 'Offline gems 2 → 3 per hour.',
          'offline_c3': 'Offline item rates +50%.'}

# discovery route, effort to ready, difficulty, problem found, adjustment
OPS = {
    'hunter_o1': ('First Snowman kill (18–31 min measured)', '~15–25 min of Snowman farming after discovery', 'Medium', 'Was 30 kills: 30+ min of repetitive boss farming; raw ids in text', '10 kills; display names; gate'),
    'hunter_o2': ('First Gray Cat kill (Summer I, after the gate)', '~25 min', 'Medium', 'Was 40 kills', '20 kills'),
    'hunter_o3': ('First Grim Reaper kill (Autumn II)', '~35 min', 'Hard', 'Was 50 kills', '30 kills'),
    'expedition_o1': ('10 Blue Cap kills (~3 min)', '~30–45 min of ordered Winter I farming (estimate)', 'Easy–medium', 'Raw ids in text', 'Display names; gate'),
    'expedition_o2': ('10 Straw Hat kills', '~45–60 min', 'Medium', 'Raw ids', 'Text'),
    'expedition_o3': ('10 Bunny Ears kills', '~60–90 min', 'Medium', 'Raw ids', 'Text'),
    'collection_o1': ('Own 3 online gear ids (~5 min)', '~45–70 min (estimate from 10% drops)', 'Medium', 'Raw ids', 'Text; per-outfit progress line'),
    'collection_o2': ('Reach Summer I', '~60–90 min', 'Medium', 'Raw ids', 'Text'),
    'collection_o3': ('Reach Spring I', '90 min+', 'Hard', 'Raw ids', 'Text'),
    'masterwork_o1': ('Merge any item to ^10', '~2–3 h on one type (bot: once within 150 min)', 'Hard', 'Progress said only "In progress"', 'Best ^ shown'),
    'masterwork_o2': ('First evolution', 'Many hours', 'Hard', '—', 'Progress line'),
    'masterwork_o3': ('Own a tier-3 item', 'Many hours', 'Very hard', '—', 'Progress line'),
    'arsenal_o1': ('Equip a weapon and an outfit (<1 min)', 'Ready by the gate in 2 of 3 ordinary bot runs (~90–100 min)', 'Medium', 'Progress said only "In progress"', 'Weapons/outfits at ^50 shown'),
    'arsenal_o2': ('Own 4 gear families', '~2–3 h', 'Hard', '—', 'Progress line'),
    'arsenal_o3': ('Evolve 2 gear families', 'Many hours', 'Very hard', '—', 'Progress line'),
    'regional_o1': ('Enter Winter II', 'Gate plus exploration and 600 coins of camps (~100–120 min, estimate)', 'Medium', '"90%" accepted ~22.5% (48-unit area vs 24-unit cells)', 'Real cell units; progress line'),
    'regional_o2': ('Enter Summer II', 'Second run onward', 'Medium', 'Same unit bug', 'Fixed'),
    'regional_o3': ('Enter Spring II', 'Late game; needs final-boss access', 'Very hard', 'Same unit bug', 'Fixed'),
    'challenge_o1': ('First Cyan Robot kill (the gate)', 'Gate + one supply-free kill (60 s respawn)', 'Medium–hard', 'Was the Snowman: found at the first boss kill and ready on the next clean kill, i.e. the reported reset in under 10 minutes', 'Moved to the Winter II gate boss; gate'),
    'challenge_o2': ('First Teal Dinosaur kill', 'Summer II', 'Hard', 'Raw ids', 'Text'),
    'challenge_o3': ('First Grim Reaper kill', 'Autumn II', 'Hard', 'Raw ids', 'Text'),
    'offering_o1': ('1,000 online coins earned', '~90–150 min; competes with upgrades for coins', 'Medium', '—', 'Text'),
    'offering_o2': ('Reach Autumn I', 'Late', 'Hard', '—', '—'),
    'offering_o3': ('Reach Spring II', 'Late', 'Very hard', '—', '—'),
    'specialist_o1': ('Complete one regular mission (~5–10 min)', 'Ready at 14.9–17.9 min (measured, all seeds)', 'Easy', 'A second early route: prestige possible at 14.9 min before Change 6', 'Redeemable only after the gate'),
    'specialist_o2': ('Complete 5 regular missions', '~60–90 min', 'Medium', '—', 'Text'),
    'specialist_o3': ('Reach Autumn II', 'Late', 'Medium', '—', '—'),
    'trophy_o1': ('First Snowman kill', 'About the gate if the Snowman is fought once more', 'Medium', 'Raw ids', 'Text; trophy count shown'),
    'trophy_o2': ('First Gray Cat kill', 'Summer II', 'Medium', 'Raw ids', 'Text'),
    'trophy_o3': ('First Squirrel kill', 'Autumn', 'Hard', 'Raw ids', 'Text'),
    'offline_o1': ('First positive offline interval', '72 lifetime hours away', 'Low effort, long wait', 'Ready without play; the reset was not gated', 'Gate'),
    'offline_o2': ('First positive offline interval', 'One 24-hour absence: before Change 6, one minute of play plus a day away allowed a reset', 'Low effort', 'Same', 'Gate'),
    'offline_o3': ('First positive offline coin settlement', '10,000 lifetime offline coins (~83 h at the base rate)', 'Low effort, long wait', 'Same', 'Gate'),
}

c = d['campaign']
out = ['# LootFarmer — Prestige Content — Change 6', '',
       'Structure unchanged: 11 paths, 33 one-use opportunities, 33 unique cards, 11 same-path and 6 mixed sets. Generated by `tools/write_prestige_catalog.py` from the runtime catalog and English strings, so ids, counts and texts match the game. Values are Change 6 tuning proposals; measured numbers come from the pacing bot (see LootFarmer_Change_6_Validation.md), not human playtests.', '',
       '## Rules changed in Change 6', '',
       '- **Gate:** no reset before the current run clears Winter (Winter II boss defeated, Summer I unlocked). Discovery and readiness are unchanged and may happen earlier; the Prestige panel states the gate. It applies to every run; later runs reach it sooner through cards and kept upgrades.',
       '- **Winter challenge** targets the Cyan Robot (the gate boss) instead of the Snowman. **Boss Hunter** goals are 10/20/30 kills (were 30/40/50).',
       '- **Cards** were 1–5% and two shared one effect. Values now aim at a visible 10–30% change in their own outcome; each path has three distinct effects; two simple effects were added (life steal, camp price discount). Point values show as "+N pts".',
       '- **Regional mastery** exploration counts real fog cells. Every opportunity shows a concrete progress line.', '',
       '## Opportunity matrix', '',
       'Reset cost at the gate (about 90 min of ordinary play): level ~22, every item and merge, coins, gems, camps, map exploration and coin upgrades of the run. Kept: cards, sets, keys, achievements, gem upgrades and automation, inventory space, settings. Effort is measured where marked, otherwise an estimate from drop rates and kill times. Several Winter opportunities can be ready together at the gate; the batch redeems all of them with one card each.', '',
       '| ID | Path | Discovery (earliest route) | Ready requirement | Effort to ready | Difficulty | Problem found | Change 6 adjustment |',
       '|---|---|---|---|---|---|---|---|']
for o in c['opportunities']:
    a = OPS[o['id']]
    out.append('| %s | %s | %s | %s | %s | %s | %s | %s |' % (o['id'], o['path'], a[0], t(o['description']), a[1], a[2], a[3], a[4]))
out += ['', '## Card matrix', '', '| ID | Path | Card | Change 5 | Change 6 | Expected gameplay impact |', '|---|---|---|---|---|---|']
for k, card in c['cards'].items():
    out.append('| %s | %s | %s | %s | %s | %s |' % (k, card['path'], t(card['name']), OLD[k], t(card['description']), IMPACT[k]))
out += ['', '## Sets', '', '| ID | Cards | Change 6 bonus |', '|---|---|---|']
for combo in c['combos']:
    out.append('| %s | %s | %s |' % (combo['id'], ', '.join(combo['cards']), t(combo['description'])))
out += ['', 'Runtime counts: %d opportunities, %d cards, %d sets.' % (len(c['opportunities']), len(c['cards']), len(c['combos'])), '']
assert set(OPS) == {o['id'] for o in c['opportunities']} and set(OLD) == set(c['cards'])
(ROOT / 'docs/LootFarmer_Prestige_Catalog.md').write_bytes('\n'.join(out).encode('utf-8'))
print('written', len(c['opportunities']), len(c['cards']), len(c['combos']))
