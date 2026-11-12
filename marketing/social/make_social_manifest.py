"""Writes marketing/social/manifest.json (Godot Marketing Capture Toolkit 1.0.2): the capture jobs for the
ten 15 s social masters. Every take is real play of res://scenes/game/main.tscn at the current build through
marketing/social/social_scenarios.gd (scenario "soc") or the store adapter's own scenarios. The cut itself is
composed by build_social.py from these masters; this manifest only records.

    python marketing/social/make_social_manifest.py            # manifest.json (1080x1920)
    python marketing/social/make_social_manifest.py --draft    # manifest_draft.json (540x960 staging checks)
"""
import argparse
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = '../../store_assets/raw/video/social'
F = 30

SNOWMAN = 'boss-snowman_outfit'
TEAL = 'boss-teal-dinosaur_outfit_t2'
RED_FOX = 'boss-red-fox_outfit_t3'
ALL_SUPPLIES = ['coin_boost', 'guard_tonic', 'recovery_salve', 'wisdom_tonic', 'potion']
# Loadouts by map: a weapon tier earlier bosses drop, at the ^20 an evolvable weapon merges to (Change 51),
# a boss outfit of that map's tier, a level near that map's bosses.
SUMMER2 = dict(stage=4, level=200)
AUTUMN2 = dict(stage=6, level=500)
AUTUMN_GEAR = dict(items=[['diamond_sword', 20], [RED_FOX, 500]], wear=['diamond_sword', RED_FOX])
CRIT = {'critical_chance': 20, 'critical_damage': 20}
REAPER_HISTORY = ['boss-grim-reaper', 'boss-black-cat']
REAPER = dict(boss_history=REAPER_HISTORY, challenges=REAPER_HISTORY)

TAKES = {}


def take(tid, seconds, scenario, options):
    TAKES[tid] = (scenario, options, seconds)


def soc(tid, seconds, **o):
    take(tid, seconds, 'soc', o)


# ---- the gear chain (Summer II, rain). A hero in the Snowman outfit defeats the Teal Dinosaur; its real
# drops (its outfit and its Gold Sword) are collected and worn.
soc('n_gear', 12.0, **SUMMER2, items=[['iron_sword', 20], [SNOWMAN, 500]], wear=['iron_sword', SNOWMAN], seed=3209,
    boss='boss-teal-dinosaur', dx=30, dy=10, explored=320.0, fight_until=0.08, clean=True, zoom=4.2,
    seed_search=60, want_drops=[TEAL, 'gold_sword'], boss_history=['boss-elephant', 'boss-teal-dinosaur'],
    challenges=['boss-elephant', 'boss-teal-dinosaur'], known_opportunities=['masterwork_o3', 'arsenal_o1'],
    after_defeat=[[1.5, 'collect', TEAL], [1.8, 'collect', 'gold_sword'], [2.2, 'zoom', 5.4, 0.9],
                  [3.4, 'equip', TEAL], [4.4, 'equip', 'gold_sword']])
soc('n_gear_fight', 6.0, **SUMMER2, items=[['gold_sword', 20], [TEAL, 200]], wear=['gold_sword', TEAL], seed=3210,
    boss='unit-cowboy-bandana', pack=True, dy=30, clean=True, zoom=5.0)
# ---- crits (Autumn II, leaves): both crit upgrades at their 20 levels.
soc('n_crit', 12.0, **AUTUMN2, **AUTUMN_GEAR, seed=6101, upgrades=CRIT, boss='boss-black-cat', dy=30, clean=True,
    zoom=4.4, **REAPER)
# ---- boss fight to the defeat (Autumn II Grim Reaper; Fire equipped), with the HUD and clean.
soc('n_boss_hud', 12.0, **AUTUMN2, **AUTUMN_GEAR, seed=6102, skills=[['skill_fire', 60]], upgrades=CRIT,
    boss='boss-grim-reaper', dy=34, zoom=2.6, fight_until=0.2, skill_at={'fire': 1.6}, **REAPER,
    after_defeat=[[2.2, 'collect_all', 200.0]])
soc('n_boss_clean', 10.0, **AUTUMN2, **AUTUMN_GEAR, seed=6103, skills=[['skill_fire', 60]], upgrades=CRIT,
    boss='boss-grim-reaper', dy=30, zoom=3.6, clean=True, fight_until=0.14, skill_at={'fire': 1.2},
    **REAPER, after_defeat=[[2.4, 'collect_all', 200.0]])
# ---- merge (item panel): spare copies of the worn outfit.
soc('n_merge', 9.0, **SUMMER2, items=[['gold_sword', 20], [TEAL, 0]], wear=['gold_sword', TEAL], seed=6104,
    extra=[[TEAL, 60]], zoom=2.4,
    steps=[[0.8, 'item', TEAL], [2.2, 'merge', TEAL], [2.9, 'merge', TEAL], [3.6, 'merge', TEAL],
           [4.8, 'merge_copies', TEAL], [7.0, 'close']])
# ---- evolution: 31 Iron Swords -> ^20 -> Gold Sword.
soc('n_evolve', 13.0, **SUMMER2, items=[['iron_sword', 0], [TEAL, 200]], wear=['iron_sword', TEAL], seed=6105,
    extra=[['iron_sword', 30]], zoom=2.4, known_opportunities=['masterwork_o1', 'masterwork_o2', 'masterwork_o3', 'arsenal_o1'],
    steps=[[0.8, 'item', 'iron_sword'], [2.4, 'merge_copies', 'iron_sword'], [4.2, 'evolve', 'iron_sword'],
           [7.6, 'evo_continue'], [8.3, 'equip', 'gold_sword'], [9.6, 'close']])
# ---- Teleport: the visual camp map, Autumn I -> Winter II (violet portal); same-map hops (cyan).
soc('n_teleport', 10.0, stage=5, level=95, items=[['gold_sword', 20], [RED_FOX, 100]], wear=['gold_sword', RED_FOX],
    seed=6106, camps_by_stage={'2': [0, 1, 2], '5': [0, 1, 2], '4': [0, 1], '3': [0, 1]}, zoom=2.4,
    steps=[[0.7, 'teleport_open'], [1.9, 'teleport_stage', 2], [3.0, 'teleport_pick', 2], [4.2, 'teleport_go']])
soc('n_blink', 7.0, stage=5, level=95, items=[['gold_sword', 20], [RED_FOX, 100]], wear=['gold_sword', RED_FOX],
    seed=6107, camps=[0, 1, 2], zoom=2.4, clean=True, steps=[[1.5, 'travel', 5, 1], [4.0, 'travel', 5, 2]])
# ---- supplies: each of the five used once (their own bursts and auras).
soc('n_supply', 10.0, **AUTUMN2, **AUTUMN_GEAR, seed=6108, extra=[[s, 5] for s in ALL_SUPPLIES],
    supply_capacity=5, boss='unit-top-hat', pack=True, dy=30, clean=True, zoom=4.6, hp=0.35,
    steps=[[1.0, 'supply', 'coin_boost'], [2.6, 'supply', 'guard_tonic'], [4.2, 'supply', 'recovery_salve'],
           [5.8, 'supply', 'wisdom_tonic'], [7.4, 'supply', 'potion']])
# ---- loot: drops left on the ground by real farming, then collected (they fly into the hero).
soc('n_loot', 9.0, **AUTUMN2, **AUTUMN_GEAR, seed=6109, near='unit-top-hat', dy=30, clean=True, zoom=3.6,
    farm_drops=7, full_hp=True, steps=[[2.0 + 0.22 * i, 'collect', 'next'] for i in range(9)])
soc('n_farm_hud', 9.0, **AUTUMN2, **AUTUMN_GEAR, seed=6110, skills=[['skill_fire', 60]], near='unit-television-head',
    dy=30, zoom=2.6, auto_collect=True, advance=2.0, full_hp=True, skill_at={'fire': 1.5})
# ---- offline: 8 hours away settled by the game's own code, the receipt, Claim; then Auto Farm.
OFFLINE = {'offline_cap': 1, 'offline_coins': 12, 'offline_gems': 6, 'offline_weapon': 1, 'offline_outfit': 1,
           'offline_consumable': 1, 'offline_weapon_rate': 4, 'offline_outfit_rate': 4, 'offline_consumable_rate': 4,
           'focus': 1}
soc('n_offline', 9.0, **AUTUMN2, **AUTUMN_GEAR, seed=6111, extra=[['potion', 3], ['coin_boost', 2]],
    supply_capacity=3, upgrades=OFFLINE, coins=184000.0, gems=420.0, zoom=2.4,
    steps=[[0.8, 'offline', 8.0], [5.2, 'claim_offline']])
soc('n_quick', 9.0, **AUTUMN2, **AUTUMN_GEAR, seed=6112, upgrades=OFFLINE, coins=184000.0, gems=420.0,
    near='unit-top-hat', dy=30, zoom=2.6, auto_collect=True, steps=[[1.6, 'quick']])
# ---- Prestige card choice (the store adapter's own scenario, as a clip).
take('n_prestige', 6.0, 'shot_prestige', {
    'seed': 3406, 'wear': ['boss-bee_outfit_t4', 'diamond_axe'], 'boss_history': ['boss-cyan-robot', 'boss-teal-dinosaur'],
    'challenges': ['boss-cyan-robot', 'boss-teal-dinosaur'], 'path': 'challenge', 'pick': 2, 'pick_at': 2.2})
# ---- lookbook: outfits and a weapon dropped in each season, worn one after another (sim.equip).
LOOKS = {
    'w': (2, 20, [SNOWMAN, 'unit-wolf-hood_outfit', 'boss-cyan-robot_outfit', 'unit-reindeer-antlers_outfit',
                  'unit-space-helmet_outfit'], 'stone_sword'),
    's': (4, 65, ['boss-gray-cat_outfit_t2', 'unit-snorkeler_outfit_t2', 'boss-elephant_outfit_t2',
                  'unit-rainbow-clown_outfit_t2', TEAL], 'gold_sword'),
    'a': (6, 140, ['boss-squirrel_outfit_t3', 'unit-pumpkin-head_outfit_t3', RED_FOX, 'unit-television-head_outfit_t3',
                   'boss-grim-reaper_outfit_t3'], 'emerald_sword'),
    'p': (7, 195, ['unit-bunny-ears_outfit_t4', 'boss-bee_outfit_t4', 'unit-cat-ears_outfit_t4',
                   'boss-orange-tabby-cat_outfit_t4', 'unit-elf-ears_outfit_t4'], 'obsidian_axe'),
}
# In the open beside each map's first camp.
LOOK_POS = {2: [768.0, 1500.0], 4: [864.0, 1676.0], 6: [768.0, 1500.0], 7: [672.0, 1322.0]}
for key, (st, lv, outfits, weapon) in LOOKS.items():
    soc(f'n_look_{key}', 5.0, stage=st, level=lv, items=[[weapon, 20]] + [[o, 50] for o in outfits],
        wear=[weapon, outfits[0]], seed=6120, clean=True, zoom=6.0, camp=0, pos=LOOK_POS[st],
        steps=[[0.9 + 0.8 * i, 'equip', o] for i, o in enumerate(outfits[1:])])
# ---- day one and the endgame.
soc('n_day1', 13.0, stage=1, level=1, items=[['wood_sword', 0]], wear=['wood_sword'], seed=6130, boss='unit-blue-cap',
    pack=True, dy=30, farm=False, zoom=3.0)
soc('n_end', 13.0, stage=8, level=238, items=[['obsidian_sword', 60], ['boss-sunflower_outfit_t5', 500]],
    wear=['obsidian_sword', 'boss-sunflower_outfit_t5'], seed=6131,
    skills=[['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]], upgrades=CRIT, near='unit-sprout',
    dy=30, zoom=3.0, auto_collect=True, skill_at={'lightning': 1.0, 'fire': 2.4, 'strike': 3.8},
    boss_history=['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower'])
# ---- revenge: the same level-400 hero loses to the Grim Reaper with unmerged gear, merges 500 outfit copies
# and a Diamond Sword to ^20, and wins the rematch (probed: both real fights end that way).
REV = dict(stage=6, level=400, upgrades=CRIT, **REAPER)
WEAK = [['gold_sword', 20], [RED_FOX, 0]]
soc('n_rev_lose', 9.0, **REV, items=WEAK, wear=['gold_sword', RED_FOX], seed=6140, boss='boss-grim-reaper', dy=30,
    clean=True, zoom=3.6, player_hp_until=0.22)
soc('n_rev_merge', 9.0, **REV, items=WEAK + [['diamond_sword', 0]], wear=['gold_sword', RED_FOX], seed=6141,
    extra=[[RED_FOX, 500], ['diamond_sword', 20]], zoom=2.4,
    steps=[[0.7, 'item', RED_FOX], [1.9, 'merge_copies', RED_FOX], [3.6, 'item', 'diamond_sword'],
           [4.6, 'merge_copies', 'diamond_sword'], [5.8, 'equip_btn', 'diamond_sword'], [7.2, 'close']])
soc('n_rev_win', 10.0, **REV, items=[['diamond_sword', 20], [RED_FOX, 500]], wear=['diamond_sword', RED_FOX], seed=6142,
    boss='boss-grim-reaper', dy=30, clean=True, zoom=3.6, fight_until=0.06)

# ---- the review's complaint, on the current build: the reviewer's hero (Snowman outfit and Wood Axe) at a
# Summer I pack. Before the rebalance the whole spot attacked at once (marketing/social/before/).
soc('n_pack_after', 10.0, stage=3, level=30, items=[['wood_axe', 20], [SNOWMAN, 40]], wear=['wood_axe', SNOWMAN],
    seed=6150, boss='unit-straw-hat', pack=True, dy=30, zoom=2.6, farm=False)
soc('n_end_clean', 8.0, stage=8, level=238, items=[['obsidian_sword', 60], ['boss-sunflower_outfit_t5', 500]],
    wear=['obsidian_sword', 'boss-sunflower_outfit_t5'], seed=6132,
    skills=[['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]], upgrades=CRIT, near='unit-sprout',
    dy=30, zoom=3.6, clean=True, auto_collect=True, skill_at={'lightning': 1.0, 'fire': 2.4, 'strike': 3.8},
    boss_history=['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower'])


# ---- revision 2 (developer review): the gear chain with the loot left clear (boss skills on cooldown, exactly
# the two items dropped, each picked up with time to read), a new crit match cut, HUD-free halves for the split.
soc('n_gear2', 16.0, **SUMMER2, items=[['iron_sword', 20], [SNOWMAN, 500]], wear=['iron_sword', SNOWMAN], seed=3316,
    boss='boss-teal-dinosaur', dx=30, dy=10, explored=320.0, fight_until=0.08, clean=True, zoom=4.2, boss_skill_in=25.0,
    seed_search=3, want_drops=[TEAL, 'gold_sword'], want_exact=True, boss_history=['boss-elephant', 'boss-teal-dinosaur'],
    challenges=['boss-elephant', 'boss-teal-dinosaur'], known_opportunities=['masterwork_o3', 'arsenal_o1'],
    after_defeat=[[4.2, 'collect', TEAL], [5.2, 'collect', 'gold_sword'], [5.6, 'zoom', 5.4, 0.9],
                  [6.9, 'equip', TEAL], [8.1, 'equip', 'gold_sword']])
soc('c_winter', 12.0, stage=2, level=45, items=[['wood_sword', 20], [SNOWMAN, 40]], wear=['wood_sword', SNOWMAN], seed=7001,
    upgrades=CRIT, boss='boss-cyan-robot', dy=30, clean=True, zoom=3.8, boss_skill_in=25.0)
soc('c_summer', 12.0, **SUMMER2, items=[['iron_sword', 20], ['boss-gray-cat_outfit_t2', 500]],
    wear=['iron_sword', 'boss-gray-cat_outfit_t2'], seed=7002, upgrades=CRIT, boss='boss-elephant', dy=30, clean=True,
    zoom=3.8, boss_skill_in=25.0, boss_history=['boss-elephant'], challenges=['boss-elephant'])
soc('c_spring', 12.0, stage=7, level=800, items=[['emerald_sword', 20], ['boss-bee_outfit_t4', 500]],
    wear=['emerald_sword', 'boss-bee_outfit_t4'], seed=7003, upgrades=CRIT, boss='boss-bee', dy=30, clean=True, zoom=3.8,
    fight_until=0.07, boss_skill_in=25.0, boss_history=['boss-bee'], challenges=['boss-bee'])
soc('n_day1c', 13.0, stage=1, level=1, items=[['wood_sword', 0]], wear=['wood_sword'], seed=6130, boss='unit-blue-cap',
    pack=True, dy=30, farm=False, zoom=3.6, clean=True)
soc('n_endc', 13.0, stage=8, level=238, items=[['obsidian_sword', 60], ['boss-sunflower_outfit_t5', 500]],
    wear=['obsidian_sword', 'boss-sunflower_outfit_t5'], seed=6132,
    skills=[['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]], upgrades=CRIT, near='unit-sprout',
    dy=30, zoom=3.6, clean=True, auto_collect=True, skill_at={'lightning': 1.0, 'fire': 2.4, 'strike': 3.8},
    boss_history=['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower'])


def load_v4():
    spec = importlib.util.spec_from_file_location('v4', HERE.parent / 'match_cut_v4' / 'make_match_v4_manifest.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ---- match cut: the Change 47 zoom-rush camera (make_match_v4_manifest.cams()), re-recorded on the current
# build with loadouts the current balance allows (evolvable weapons at ^20).
V4 = load_v4()
MATCH = {
    'winter': dict(V4.WINTER, items=[['wood_sword', 20], [SNOWMAN, 40]], wear=['wood_sword', SNOWMAN]),
    'summer': dict(V4.SUMMER, items=[['iron_sword', 20], ['boss-elephant_outfit_t2', 200]],
                   wear=['iron_sword', 'boss-elephant_outfit_t2']),
    'autumn': dict(V4.AUTUMN, items=[['diamond_sword', 20], [RED_FOX, 500]], wear=['diamond_sword', RED_FOX]),
    'spring': dict(V4.SPRING, items=[['emerald_sword', 20], ['boss-sunflower_outfit_t5', 500]],
                   wear=['emerald_sword', 'boss-sunflower_outfit_t5']),
}
for sid, seconds in (('winter', 4.0), ('summer', 6.0), ('autumn', 5.0), ('spring', 6.0)):
    take(f'm_{sid}', seconds, 'match_boss', {**MATCH[sid], 'hud': 'match', 'numbers_gap': 1.5, 'cam': V4.cams()[sid]})

def manifest(draft: bool) -> dict:
    w, h = (540, 960) if draft else (1080, 1920)
    sub = '/draft' if draft else ''
    jobs = []
    for tid, (scenario, options, seconds) in TAKES.items():
        jobs.append({'id': tid, 'kind': 'video', 'scenario': scenario, 'options': options, 'width': w, 'height': h,
                     'fps': F, 'duration': seconds, 'capture_ui': True, 'output': f'{OUT}{sub}/{tid}.avi'})
    return {'text_renderer': 'pillow', 'quality': 'high',
            'fonts': {'default': {'file': '../../assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'}},
            'strings': {'en-US': {}}, 'game_scene': 'res://scenes/game/main.tscn',
            'adapter_script': 'res://marketing/social/social_scenarios.gd', 'ui_group': 'store_screenshot_ui',
            'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
            'log_show': ['LOOTFARMER_MARKETING'], 'output_root': '../../store_assets',
            'capture_jobs': jobs, 'videos': []}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--draft', action='store_true')
    a = p.parse_args()
    name = 'manifest_draft.json' if a.draft else 'manifest.json'
    (HERE / name).write_bytes((json.dumps(manifest(a.draft), indent=2) + chr(10)).encode('utf-8'))
    print('wrote', HERE / name, len(TAKES), 'takes')


if __name__ == '__main__':
    main()
