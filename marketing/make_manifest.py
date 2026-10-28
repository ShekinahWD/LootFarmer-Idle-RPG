"""Writes marketing/manifest.json (Godot Marketing Capture Toolkit 1.0.2): the 7 Change 27 clips (the
store trailer is marketing/trailer/, Change 32; the store screenshots marketing/screenshots/, Change 34;
the Change 27 screenshot table below is kept as the record of the replaced set).
Edit the tables below (scenario options, capture frames, cuts), run this script, then the commands in
marketing/README.md. Every capture runs the game's own scene through marketing/game_scenarios.gd.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

# Google Play device classes, all genuine 9:16 portrait renders (the game's 720x1280 reference layout
# with canvas_items/expand). Desktop is the Chromebook/desktop listing slot, still portrait.
DEVICES = [
    ('Phone', 1080, 1920),
    ('Tablet_7', 1440, 2560),
    ('Tablet_10', 1800, 3200),
    ('Desktop', 1620, 2880),
]

# The approved order: combat, collection, merging, late farming, world, Prestige. One scenario and
# one frame per concept, identical for every device class (the simulation is resolution independent).
SCREENSHOTS = [
    ('01', 'boss_sunflower', {'zoom': 2.5, 'summon_in': 0.6}, 45),
    ('02', 'loot_collection', {'stage': 7, 'seed': 2712, 'zoom': 3.0, 'after': 1.6}, 20),
    ('03', 'equipment_merge', {'merges_before': 1}, 15),
    ('04', 'late_farming', {'zoom': 1.75, 'advance': 2.5, 'radius': 220}, 30),
    ('05', 'world_progress', {}, 15),
    ('06', 'prestige_cards', {}, 15),
]

# Every clip starts with ~0.6 s of live play (the HUD's first refresh and layout settle) before its
# first action; the trailer cuts in at 0.6 s (HEAD).
HEAD = 0.6
CLIPS = [
    ('clip_boss', 'boss_sunflower', {'zoom': 2.5, 'summon_in': 1.3, 'skill_at': {'lightning': 0.9, 'fire': 1.6, 'strike': 3.0}}, 8.0),
    ('clip_loot', 'loot_collection', {'stage': 7, 'seed': 2712, 'zoom': 3.0, 'finish_hp': 0.1, 'collect_from': 2.2, 'collect_every': 0.45}, 5.0),
    ('clip_merge', 'equipment_merge', {'press_at': [1.3, 2.3]}, 4.2),
    ('clip_farm', 'late_farming', {'zoom': 1.75, 'advance': 0.3, 'radius': 220}, 10.0),
    ('clip_world', 'world_progress', {'open_at': 1.0}, 3.6),
    ('clip_prestige', 'prestige_cards', {'open_at': 0.9, 'choose': True, 'begin_at': 2.2}, 4.0),
    ('clip_victory', 'boss_victory', {'zoom': 2.5, 'until': 0.03, 'seed': 2737}, 4.5),
]

RAW = '../store_assets/raw'


def manifest() -> dict:
    jobs = []
    # Change 34: the store screenshots are produced by marketing/screenshots/ (their own manifest); the
    # Change 27 table above stays as the record of the replaced set and no longer emits capture jobs.
    for device, w, h in []:
        for number, scenario, options, frame in SCREENSHOTS:
            jobs.append({'id': f'{device}_{number}', 'kind': 'screenshot', 'scenario': scenario, 'options': options,
                         'width': w, 'height': h, 'fps': 30, 'capture_frame': frame, 'settle_frames': 4,
                         'capture_ui': True, 'output': f'{RAW}/screenshots/{device}/{device}_{number}.png'})
    for clip_id, scenario, options, seconds in CLIPS:
        jobs.append({'id': clip_id, 'kind': 'video', 'scenario': scenario, 'options': options,
                     'width': 1080, 'height': 1920, 'fps': 30, 'duration': seconds, 'capture_ui': True,
                     'output': f'{RAW}/video/{clip_id}.avi'})
    return {
        'game_scene': 'res://scenes/game/main.tscn',
        'adapter_script': 'res://marketing/game_scenarios.gd',
        'ui_group': 'store_screenshot_ui',
        # Isolated capture profile (BootContext capture-*), no autosave, first-profile progression complete.
        'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
        'log_show': ['LOOTFARMER_MARKETING'],
        'output_root': '../store_assets',
        'capture_jobs': jobs,
        'text_renderer': 'auto',
        'quality': 'high',
        'fonts': {'default': {'file': 'toolkit:NotoSans[wdth,wght].ttf', 'weight': 800}},
        # Brand name only (Playbook 87.9 / brief M03): no tagline, claim or call to action.
        'strings': {'en-US': {'BRAND.NAME': 'LootFarmer'}},
        'style': {'text_color': '#FFD65C', 'accent_color': '#FFD65C', 'text_fade': 0.2},
        'screenshots': [],
        # Change 32 replaced the rejected Change 27 cut: the store trailer is built from
        # marketing/trailer/manifest.json. The clips above stay as recorded masters for social reuse.
        'videos': [],
    }


if __name__ == '__main__':
    out = HERE / 'manifest.json'
    out.write_bytes((json.dumps(manifest(), indent=2) + '\n').encode('utf-8'))
    print('wrote', out)
