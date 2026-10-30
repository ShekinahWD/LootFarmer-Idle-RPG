"""Writes marketing/match_cut/manifest.json (Godot Marketing Capture Toolkit 1.0.2) for the Change 44
four-season action match-cut experiment: ~15 s portrait, hard cuts on matched sword swings, the
developer's background music only, the approved portrait end card. A local review master, not the
store trailer (marketing/trailer/ is untouched).

Every take is genuine play of res://scenes/game/main.tscn at the same clean camera zoom (3.8, the
Change 33 seasons' zoom), so the follow camera keeps the hero at the same screen position and size in
all four; the cut in-points below are chosen on the same phase of a real swing (see README.md).
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw/video/trailer_c32'
OUT = '../../store_assets/raw/video/match_cut'
MUSIC = '../../assets/sounds/background_music.wav'
ZOOM = 3.8

# (id, scenario, options, seconds). Gear climbs one tier per season; every boss outfit is a real drop of
# a boss the profile has defeated before (boss_history), every weapon a real drop of its map or earlier.
TAKES = [
    # Summer II, rain: Elephant outfit (tier 2) + Iron Sword against the Teal Dinosaur.
    ('m_summer', 'match_boss', {
        'clean': True, 'stage': 4, 'boss': 'boss-teal-dinosaur', 'zoom': ZOOM, 'seed': 4402, 'level': 200,
        'dx': 0, 'dy': 30, 'advance': 0.3,
        'items': [['iron_sword', 100], ['boss-elephant_outfit_t2', 60]], 'wear': ['iron_sword', 'boss-elephant_outfit_t2'],
        'boss_history': ['boss-elephant'], 'known_opportunities': ['masterwork_o3', 'arsenal_o1']}, 6.0),
    # Autumn II, falling leaves: Red Fox outfit (tier 3) + Gold Sword + Fire against the Grim Reaper,
    # whose real summon (two Horned Hoods) is due 1.5 s into the take.
    ('m_autumn', 'match_boss', {
        'clean': True, 'stage': 6, 'boss': 'boss-grim-reaper', 'zoom': ZOOM, 'seed': 4403, 'level': 700,
        'dx': 0, 'dy': 30, 'advance': 0.3, 'summon_in': 1.5, 'skill_at': {'fire': 2.6},
        'items': [['gold_sword', 100], ['boss-red-fox_outfit_t3', 80]], 'wear': ['gold_sword', 'boss-red-fox_outfit_t3'],
        'skills': [['skill_fire', 60]], 'boss_history': ['boss-red-fox', 'boss-black-cat']}, 8.0),
    # Spring II: Sunflower outfit (tier 5, ^500) + Emerald Sword + three auto skills against the Red Panda
    # (the Change 9 fixture's Spring II loadout; the final Green Alien is never framed).
    ('m_spring', 'match_boss', {
        'clean': True, 'stage': 8, 'boss': 'boss-red-panda', 'zoom': ZOOM, 'seed': 4404, 'level': 238,
        'dx': 0, 'dy': 30, 'advance': 0.3, 'skill_at': {'lightning': 1.0, 'fire': 2.2, 'strike': 3.2},
        'items': [['emerald_sword', 90], ['boss-sunflower_outfit_t5', 500]], 'wear': ['emerald_sword', 'boss-sunflower_outfit_t5'],
        'skills': [['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]],
        'boss_history': ['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower']}, 7.0),
]

# The cut: (shot id, source, in-point s, duration s). Hard cuts between the four seasons, each placed
# on the same swing phase; Winter reuses the Change 33 take (Snowman outfit + Stone Axe, zoom 3.8).
CUT = [
    # c33_winter frames 6-66: approach and wind-up; its arc frame 67 is never shown.
    ('winter', f'{RAW}/c33_winter.avi', 6 / 30, 61 / 30),
    # Opens on the impact arc (frame 43, hit logged 1.42 s); ends on the wind-up before frame 133.
    ('summer', f'{OUT}/m_summer.avi', 43 / 30, 90 / 30),
    # Opens on the impact arc (frame 13); summon warning 1.19 s, two Horned Hoods 1.79 s, Fire 2.29 s;
    # ends on the wind-up before frame 103.
    ('autumn', f'{OUT}/m_autumn.avi', 13 / 30, 90 / 30),
    # Opens on the impact arc (frame 13); Lightning 0.69 s, Fire 1.89 s, Arcane Strike 2.89 s, held to 4.63 s.
    ('spring', f'{OUT}/m_spring.avi', 13 / 30, 126 / 30),
]
END = ('end_card', f'{RAW}/end_card.mkv', 0.0, 3.3)


def shots() -> list:
    out = []
    for i, (sid, src, start, dur) in enumerate(CUT):
        s = {'id': sid, 'kind': 'clip', 'source': src, 'start': start, 'duration': dur}
        if i:
            s['transition_in'] = {'type': 'cut'}
        out.append(s)
    out.append({'id': END[0], 'kind': 'clip', 'source': END[1], 'start': END[2], 'duration': END[3],
                'transition_in': {'type': 'fade', 'duration': 0.4}})
    return out


def manifest() -> dict:
    jobs = [{'id': take_id, 'kind': 'video', 'scenario': scenario, 'options': options, 'width': 1080, 'height': 1920,
             'fps': 30, 'duration': seconds, 'capture_ui': True, 'output': f'{OUT}/{take_id}.avi'}
            for take_id, scenario, options, seconds in TAKES]
    total = sum(c[3] for c in CUT) + END[3] - 0.4
    video = {
        'id': 'match_cut', 'profile': 'play_store', 'width': 1080, 'height': 1920, 'fps': 30, 'target_duration': round(total, 3),
        'output': '../../store_assets/video/experiments/LootFarmer_MatchCut_15s_v1.mp4',
        'fade_in': 0.0, 'fade_out': 0.0,
        'music': MUSIC, 'music_start': 60.0, 'music_volume': 0.85, 'music_fade_in': 0.03, 'music_fade_out': 1.5,
        'game_audio': False,
        'shots': shots(),
    }
    return {
        'text_renderer': 'pillow', 'quality': 'high',
        'fonts': {'default': {'file': '../../assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'}},
        'strings': {'en-US': {}},
        'game_scene': 'res://scenes/game/main.tscn',
        'adapter_script': 'res://marketing/game_scenarios.gd',
        'ui_group': 'store_screenshot_ui',
        'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
        'log_show': ['LOOTFARMER_MARKETING'],
        'output_root': '../../store_assets',
        'capture_jobs': jobs,
        'videos': [video],
    }


def main() -> None:
    argparse.ArgumentParser(description=__doc__).parse_args()
    out = HERE / 'manifest.json'
    out.write_bytes((json.dumps(manifest(), indent=2) + '\n').encode('utf-8'))
    print('wrote', out)


if __name__ == '__main__':
    main()
