"""Writes marketing/trailer/manifest.json (Godot Marketing Capture Toolkit 1.0.2) for the Change 32
Google Play trailer: five gameplay takes and the 30 s portrait cut (three black title cards, the
animated portrait end card from the approved feature graphic, the developer's background music only).

Edit the tables below, run this script, then the commands in marketing/trailer/README.md.
`--draft` writes manifest_draft.json instead: the same takes at 360x640 into raw/video/trailer_c32/draft/,
for fast staging checks (never used by the cut).
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw/video/trailer_c32'
MUSIC = '../../assets/sounds/background_music.wav'

# Every take is genuine play of res://scenes/game/main.tscn staged by marketing/game_scenarios.gd.
# (id, scenario, options, seconds)
TAKES = [
    # Spring II, rain: the Sunflower's real summon (two Sprouts) and the player's auto-cast skills.
    ('c32_boss', 'boss_sunflower', {
        'zoom': 2.5, 'seed': 3210, 'outfit': 'boss-red-panda_outfit_t5', 'dx': 0, 'dy': 32,
        'summon_in': 1.2, 'skill_at': {'lightning': 0.9, 'fire': 3.3, 'strike': 4.4}}, 7.0),
    # Summer II, rain: plain body + Wood Sword finishes the Teal Dinosaur, collects and equips its gear.
    # Seed 3209: this kill rolls both of its loot items (found by search; the drop is never forced).
    ('c32_gear', 'trailer_gear', {
        'zoom': 3.0, 'seed': 3209, 'level': 200, 'until': 0.1, 'dx': 0, 'dy': 30,
        'boss_history': ['boss-teal-dinosaur'], 'challenges': ['boss-teal-dinosaur'],
        'known_opportunities': ['masterwork_o3', 'arsenal_o1'],
        'steps': {'collect_outfit': 0.8, 'collect_weapon': 1.1, 'open_outfit': 1.6, 'equip_outfit': 3.0,
                  'open_weapon': 3.7, 'equip_weapon': 4.8, 'close': 5.3}}, 12.0),
    # Summer II: one Merge of the same outfit's spare copies.
    # Away from the (respawned) Teal Dinosaur, so nothing fights behind the panel.
    ('c32_merge', 'trailer_merge', {'zoom': 3.0, 'copies': 40, 'open_at': 0.8, 'merge_at': 2.3, 'dx': -40, 'dy': 170,
                                    'known_opportunities': ['masterwork_o3', 'arsenal_o1']}, 5.0),
    # Autumn II, falling leaves: Red Fox outfit + Gold Sword farming TV Heads with Fire and Lightning.
    # The game's leaves are sparse (12 per 440x500 world px): the spot is the pack whose open ground
    # (left of and below the player, clear of the minimap) the fixed leaf pattern crosses most often
    # during the shot, and the player stands just above it so the pack comes up from that ground.
    ('c32_autumn', 'trailer_farm', {
        'stage': 6, 'zoom': 3.0, 'seed': 3206, 'level': 700, 'advance': 0.6, 'near': 'unit-television-head', 'dx': 55, 'dy': -5,
        'items': [['gold_sword', 100], ['boss-red-fox_outfit', 60]], 'wear': ['gold_sword', 'boss-red-fox_outfit'],
        'skills': [['skill_fire', 60], ['skill_lightning', 60]]}, 6.0),
    # Winter II, blue leaves: Snowman outfit + Stone Axe farming the Reindeer Antlers pack (same rule).
    ('c32_winter', 'trailer_farm', {
        'stage': 2, 'zoom': 3.0, 'seed': 3202, 'level': 45, 'advance': 0.6, 'near': 'unit-reindeer-antlers', 'dx': 0, 'dy': -50,
        'items': [['stone_axe', 100], ['boss-snowman_outfit', 40]], 'wear': ['stone_axe', 'boss-snowman_outfit'],
        'skills': [['skill_strike', 10]]}, 6.0),

    # ---- Change 33 revision: clean takes (HUD hidden, the world fills the frame) and a closer camera.
    # The same Teal Dinosaur fight (seed 3209, identical simulation), but no item panel: after both
    # pickups the camera pushes in and the drops are equipped through sim.equip() one after the other.
    ('c33_gear', 'trailer_gear', {
        'clean': True, 'zoom': 4.2, 'seed': 3209, 'level': 200, 'until': 0.1, 'dx': 0, 'dy': 30,
        'boss_history': ['boss-teal-dinosaur'], 'challenges': ['boss-teal-dinosaur'],
        'known_opportunities': ['masterwork_o3', 'arsenal_o1'],
        'steps': {'collect_outfit': 0.8, 'collect_weapon': 1.1, 'push_in': [1.4, 6.0, 0.9],
                  'wear_outfit': 2.6, 'wear_weapon': 3.6}}, 10.0),
    # Summer II: the transformed player (Teal Dinosaur outfit + Iron Sword) attacking, close.
    ('c33_closeup', 'trailer_farm', {
        'clean': True, 'stage': 4, 'zoom': 5.5, 'seed': 3331, 'level': 200, 'advance': 0.4,
        'near': 'unit-cowboy-bandana', 'dx': 0, 'dy': 16,
        'items': [['iron_sword', 0], ['boss-teal-dinosaur_outfit_t2', 0], ['wood_sword', 100]],
        'wear': ['iron_sword', 'boss-teal-dinosaur_outfit_t2'],
        'known_opportunities': ['masterwork_o3', 'arsenal_o1']}, 4.0),
    # Four seasons, four looks, four weapons (each outfit and weapon a real drop of its season's map
    # or an earlier one). Clean takes at a closer zoom than the HUD allows; each spot is a pack the
    # fixed weather pattern crosses during the shot.
    ('c33_winter', 'trailer_farm', {
        'clean': True, 'stage': 2, 'zoom': 3.8, 'seed': 3341, 'level': 45, 'advance': 0.5,
        'near': 'unit-reindeer-antlers', 'dx': 20, 'dy': 25,
        'items': [['stone_axe', 100], ['boss-snowman_outfit', 40]], 'wear': ['stone_axe', 'boss-snowman_outfit'],
        'skills': [['skill_strike', 10]]}, 5.0),
    ('c33_summer', 'trailer_farm', {
        'clean': True, 'stage': 4, 'zoom': 3.8, 'seed': 3342, 'level': 120, 'advance': 0.5,
        'near': 'unit-duck-swim-ring', 'dx': 0, 'dy': 18,
        'items': [['iron_sword', 100], ['unit-snorkeler_outfit', 60]], 'wear': ['iron_sword', 'unit-snorkeler_outfit'],
        'known_opportunities': ['masterwork_o3', 'arsenal_o1']}, 5.0),
    ('c33_autumn', 'trailer_farm', {
        'clean': True, 'stage': 6, 'zoom': 3.8, 'seed': 3343, 'level': 700, 'advance': 0.5,
        'near': 'unit-television-head', 'dx': 0, 'dy': 18,
        'items': [['gold_sword', 100], ['boss-grim-reaper_outfit', 60]], 'wear': ['gold_sword', 'boss-grim-reaper_outfit'],
        'skills': [['skill_fire', 60]]}, 5.0),
    ('c33_spring', 'trailer_farm', {
        'clean': True, 'stage': 7, 'zoom': 3.8, 'seed': 3344, 'level': 900, 'advance': 0.5,
        'near': 'unit-bunny-ears', 'dx': 0, 'dy': 18,
        'items': [['diamond_axe', 100], ['boss-bee_outfit', 60]], 'wear': ['diamond_axe', 'boss-bee_outfit'],
        'skills': [['skill_lightning', 60]]}, 5.0),
]


# Title-card copy (en-US): one plain statement each, set on black in the wordmark's font.
STRINGS = {
    'CARD.BOSS': 'This boss calls for backup.',
    'CARD.GEAR': 'Defeat an enemy and wear its gear.',
    'CARD.SEASONS': 'Each season has its own gear.',
}

# The cut, in order. Clip 'start' is seconds into its take; the log of each take (<take>.avi.log)
# gives the event times these in-points were chosen around (see README.md, "Timeline").
fade = {'type': 'fade', 'duration': 0.4}        # through black (a card's edge, or the end card's dip)
cross = {'type': 'crossfade', 'duration': 0.3}  # picture to picture (between seasons: no black)
SHOTS = [
    {'id': 'card_boss', 'kind': 'card', 'duration': 'auto', 'headline_key': 'CARD.BOSS'},
    # Lightning 0.89 s, summon telegraph then two Sprouts 2.23 s, Fire 3.29 s, Arcane Strike 4.39 s.
    {'id': 'boss', 'kind': 'clip', 'source': f'{RAW}/c32_boss.avi', 'start': 0.6, 'duration': 4.2, 'transition_in': fade},
    {'id': 'card_gear', 'kind': 'card', 'duration': 'auto', 'headline_key': 'CARD.GEAR', 'transition_in': fade},
    # Clean take: defeat 2.96 s, both drops collected 3.79/4.09 s, camera pushes in 4.39-5.29 s,
    # Teal Dinosaur outfit on 5.59 s, Iron Sword on 6.59 s, the new look held to the end.
    {'id': 'gear', 'kind': 'clip', 'source': f'{RAW}/c33_gear.avi', 'start': 1.2, 'duration': 'fill', 'min_duration': 7.5,
     'transition_in': fade},
    # The transformed player attacking, close (1.8 s).
    {'id': 'closeup', 'kind': 'clip', 'source': f'{RAW}/c33_closeup.avi', 'start': 1.2, 'duration': 1.8, 'transition_in': cross},
    {'id': 'card_seasons', 'kind': 'card', 'duration': 'auto', 'headline_key': 'CARD.SEASONS', 'transition_in': fade},
    # Four seasons, four looks; in-points where each map's weather crosses the frame.
    {'id': 'winter', 'kind': 'clip', 'source': f'{RAW}/c33_winter.avi', 'start': 0.9, 'duration': 1.8, 'transition_in': fade},
    {'id': 'summer', 'kind': 'clip', 'source': f'{RAW}/c33_summer.avi', 'start': 1.0, 'duration': 1.8, 'transition_in': cross},
    {'id': 'autumn', 'kind': 'clip', 'source': f'{RAW}/c33_autumn.avi', 'start': 1.6, 'duration': 1.8, 'transition_in': cross},
    {'id': 'spring', 'kind': 'clip', 'source': f'{RAW}/c33_spring.avi', 'start': 1.4, 'duration': 1.8, 'transition_in': cross},
    # The approved feature graphic's portrait restaging in motion (compose_end_card.py).
    {'id': 'end_card', 'kind': 'clip', 'source': f'{RAW}/end_card.mkv', 'start': 0.0, 'duration': 3.8, 'transition_in': fade},
]

VIDEO = {
    'id': 'play_trailer', 'profile': 'play_store', 'width': 1080, 'height': 1920, 'fps': 30, 'target_duration': 30.0,
    'output': '../../store_assets/video/LootFarmer_Play_Trailer.mp4',
    'fade_in': 0.0, 'fade_out': 0.0,
    # Music only: the developer's track from a strong onset at 60.00 s (past the intro's rests), so its
    # louder section (86.07 s in the track) arrives at 26.07 s, as the end card fades in. No game audio.
    'music': MUSIC, 'music_start': 60.0, 'music_volume': 0.85, 'music_fade_in': 0.03, 'music_fade_out': 1.8,
    'game_audio': False,
    'style': {'text_min_hold': 1.5, 'reading_cps': 18.0},
    'shots': SHOTS,
}


def manifest(draft: bool) -> dict:
    w, h = (360, 640) if draft else (1080, 1920)
    folder = f'{RAW}/draft' if draft else RAW
    jobs = [{'id': take_id, 'kind': 'video', 'scenario': scenario, 'options': options, 'width': w, 'height': h,
             'fps': 30, 'duration': seconds, 'capture_ui': True, 'output': f'{folder}/{take_id}.avi'}
            for take_id, scenario, options, seconds in TAKES]
    return {
        'text_renderer': 'pillow',
        'quality': 'high',
        'fonts': {'default': {'file': '../../assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'}},
        'strings': {'en-US': STRINGS},
        'style': {'text_color': '#FFD65C', 'text_fade': 0.2},
        'game_scene': 'res://scenes/game/main.tscn',
        'adapter_script': 'res://marketing/game_scenarios.gd',
        'ui_group': 'store_screenshot_ui',
        'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
        'log_show': ['LOOTFARMER_MARKETING'],
        'output_root': '../../store_assets',
        'capture_jobs': jobs,
        'videos': [] if draft else [VIDEO],
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
