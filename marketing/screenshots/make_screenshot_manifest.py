"""Writes marketing/screenshots/manifest.json (Godot Marketing Capture Toolkit 1.0.2) for the Change 34
Google Play screenshot set: six scenes x four portrait device classes, every image a separate genuine
render of res://scenes/game/main.tscn staged by marketing/game_scenarios.gd.

Edit the SCENES table, run this script, then the commands in marketing/screenshots/README.md.
`--draft` writes manifest_draft.json instead: the same scenes at 540x960 into
store_assets/raw/screenshots_draft/, for fast staging checks (never delivered).
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw'

# Google Play device classes, all genuine 9:16 portrait renders of the game's 720x1280 reference
# layout (canvas_items/expand). Desktop is the Chromebook/desktop listing slot, still portrait.
DEVICES = [
    ('Phone', 1080, 1920),
    ('Tablet_7', 1440, 2560),
    ('Tablet_10', 1800, 3200),
    ('Desktop', 1620, 2880),
]

# The approved order: boss combat, equipment collection, merging, late-game farming, world
# exploration, Prestige. (number, scenario, options, capture frame at 30 fps, notes). The simulation is
# resolution independent, so one scene and one frame give the same moment on every device class.
SCENES = [
    # Spring II, rain. The Sunflower's real summon (two Sprouts rising from their portals) as the
    # player's Lightning Strike lands on it; the player (Red Panda outfit + Emerald Sword) stands
    # straight above the boss so the boss sits in the clear centre of the map view.
    ('01', 'boss_sunflower', {
        'seed': 3410, 'zoom': 2.5, 'wear': ['boss-red-panda_outfit_t5'], 'dx': 0, 'dy': -54,
        'summon_in': 0.9, 'skill_at': {'lightning': 1.3, 'fire': 3.2, 'strike': 1.0}}, 55,
     'Spring II rain; Sunflower summons two Sprouts; Lightning Strike on the boss'),
    # Summer II, rain. Plain body + Wood Sword defeats the Teal Dinosaur; seed 3402 is the first seed
    # from 3401 whose kill drops both of its items (found with seed_search, never forced). Both are
    # collected and worn, the boss respawns after its real 60 s and the player, dressed as it, fights it.
    ('02', 'shot_gear', {'seed': 3402, 'zoom': 3.0, 'level': 200}, 40,
     'Summer II rain; player wears the Teal Dinosaur outfit + Iron Sword it dropped, fighting it again'),
    # Winter I, snow. 100 spare Red Scarf Outfit copies (fixture: farmed from the Red Scarf pack) merged
    # with the item panel's own "Merge 100 spare copies" button: ^0 -> ^100, the first milestone (Guard)
    # active and the tile's ^100 frame. The player stands away from the pack (no fight behind the panel).
    ('03', 'shot_merge', {
        'stage': 1, 'level': 30, 'zoom': 1.5, 'items': [['wood_axe', 40], ['unit-red-scarf_outfit', 0]],
        'wear': ['wood_axe', 'unit-red-scarf_outfit'], 'item': 'unit-red-scarf_outfit', 'copies': 100,
        'near': 'unit-red-scarf', 'dy': 150, 'open_at': 0.2, 'merge_at': 0.8}, 45,
     'Winter I; real Merge All of 100 Red Scarf copies, ^0 -> ^100, Guard milestone active'),
    # Autumn II, magenta canopies. Grim Reaper outfit + Gold Sword farming the Orange Screen Helmet pack
    # for 12 s of real play with Auto-Collect off, so its drops (outfit, Recovery Salve) lie on the ground.
    ('04', 'trailer_farm', {
        'stage': 6, 'zoom': 2.0, 'seed': 3404, 'level': 450, 'advance': 12.0, 'auto_collect': False,
        'near': 'unit-orange-screen-helmet', 'dx': 50, 'dy': -40,
        'items': [['gold_sword', 60], ['boss-grim-reaper_outfit_t3', 60]], 'wear': ['gold_sword', 'boss-grim-reaper_outfit_t3'],
        'skills': [['skill_fire', 40], ['skill_lightning', 40], ['skill_strike', 40]]}, 16,
     'Autumn II; Grim Reaper outfit + Gold Sword farming a pack, real drops on the ground'),
    # Winter II, falling snow. A first-run player exploring: the route from Camp 1 past Camp 2 revealed,
    # fog over the rest, the game's own "Camp spotted!" notice, Cyan Robot outfit + Stone Sword.
    ('05', 'shot_explore', {
        'stage': 2, 'level': 60, 'zoom': 1.0, 'reveal': 150,
        'items': [['stone_sword', 40], ['boss-cyan-robot_outfit', 20]], 'wear': ['stone_sword', 'boss-cyan-robot_outfit'],
        'route': [[768, 1413], [704, 1180], [400, 1000], [184, 845], [300, 700], [528, 700], [330, 470]],
        'camps': [0, 1]}, 20,
     'Winter II snow; exploration at the fog edge, Camp spotted notice, 21% explored'),
    # Prestige card choice (late-game profile, one Prestige already redeemed): four ready opportunities,
    # the first (Unassisted winter: the Cyan Robot beaten with no supply) offers Precision, Resolve and
    # Hard Hit; Hard Hit tapped (selected, not kept). Bee outfit + Diamond Axe in the gear row.
    ('06', 'shot_prestige', {
        'seed': 3406, 'wear': ['boss-bee_outfit_t4', 'diamond_axe'],
        'boss_history': ['boss-cyan-robot', 'boss-teal-dinosaur'], 'challenges': ['boss-cyan-robot', 'boss-teal-dinosaur'],
        'path': 'challenge', 'pick': 2}, 20,
     'Prestige choose a reward 1 of 4: Precision +15 pts, Resolve +5%, Hard Hit +75% selected'),
]

# Alt-text drafts (<= 140 characters), listing metadata only; never drawn on an image.
ALT_TEXT = {
    '01': 'A Sunflower boss summons two Sprout helpers in the rain while the hero strikes it with lightning.',
    '02': 'The hero wears the Teal Dinosaur outfit and Iron Sword it dropped, fighting the dinosaur again.',
    '03': 'Merging 100 spare Red Scarf Outfit copies raises it to level 100 and unlocks a Guard bonus.',
    '04': 'The hero in a Grim Reaper outfit farms a pack of helmeted enemies among autumn trees, with loot dropped.',
    '05': 'Exploring a snowy map: the fog lifts along the path and a new camp is spotted.',
    '06': 'Prestige reward choice: three permanent cards, with Hard Hit +75% critical damage selected.',
}


def manifest(draft: bool) -> dict:
    devices = [('Draft', 540, 960)] if draft else DEVICES
    jobs = []
    for device, w, h in devices:
        for number, scenario, options, frame, _notes in SCENES:
            folder = 'screenshots_draft' if draft else f'screenshots/{device}'
            jobs.append({'id': f'{device}_{number}', 'kind': 'screenshot', 'scenario': scenario, 'options': options,
                         'width': w, 'height': h, 'fps': 30, 'capture_frame': frame, 'settle_frames': 4,
                         'capture_ui': True, 'output': f'{RAW}/{folder}/{device}_{number}.png'})
    return {
        'game_scene': 'res://scenes/game/main.tscn',
        'adapter_script': 'res://marketing/game_scenarios.gd',
        'ui_group': 'store_screenshot_ui',
        # Isolated capture profile (BootContext capture-*), no autosave, first-profile progression complete.
        'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
        'log_show': ['LOOTFARMER_MARKETING'],
        'output_root': '../../store_assets',
        'capture_jobs': jobs,
        'text_renderer': 'auto',
        'quality': 'high',
        'fonts': {'default': {'file': 'toolkit:NotoSans[wdth,wght].ttf', 'weight': 800}},
        'strings': {'en-US': {}},
        # Raw gameplay only: the toolkit adds no headline, band or frame to any screenshot.
        'screenshots': [],
        'videos': [],
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--draft', action='store_true')
    args = ap.parse_args()
    out = HERE / ('manifest_draft.json' if args.draft else 'manifest.json')
    out.write_bytes((json.dumps(manifest(args.draft), indent=2) + '\n').encode('utf-8'))
    print('wrote', out)


if __name__ == '__main__':
    main()
