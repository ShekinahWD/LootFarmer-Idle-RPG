"""Writes marketing/match_cut_v2/manifest.json (Godot Marketing Capture Toolkit 1.0.2) for the Change 45
moving-camera match-cut experiment (V2): the Change 44 four-season story, swords only (Wood, Iron, Gold,
Emerald), with one camera move carried through each hard cut. A local review master; marketing/trailer/
and marketing/match_cut/ (V1) are untouched.

Each take is genuine play of res://scenes/game/main.tscn. The adapter's capture-only scripted camera
(options.cam, Hermite keys [clock, dx, dy, vx, vy, zoom, vzoom], game_scenarios.gd) leaves a take on a
camera offset, zoom and velocity and the next take starts on exactly the same ones, so at every cut the
hero keeps screen position and size and the frame keeps moving the same way at the same speed.
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw/video/trailer_c32'
OUT = '../../store_assets/raw/video/match_cut_v2'
MUSIC = '../../assets/sounds/background_music.wav'
Z = 3.8
F = 30

# Shot windows in take frames (in, out exclusive). Each in-point is the first impact-arc frame of a real
# sword hit, each out-point the wind-up before one (hits logged by the adapter, HIT t=).
WIN = {'winter': (0, 0), 'summer': (43, 133), 'autumn': (13, 103), 'spring': (13, 139)}

# The three joins: camera state (dx, dy, vx, vy, zoom, vzoom) at the cut.
J1 = (6, 0, 28, 0, Z, 0)              # Winter -> Summer: tracking right
J2 = (8, -9, 0, -26, 4.7, 2.6)        # Summer -> Autumn: push-in toward the clash
J3 = (14, -16, 22, -22, 4.2, -0.9)    # Autumn -> Spring: diagonal track up-right, easing back


def k(t, s):
    return [round(t, 4), *s]


def cams(w_in, w_out) -> dict:
    t = lambda f: f / F
    s0, s1 = t(WIN['summer'][0]), t(WIN['summer'][1])
    a0, a1 = t(WIN['autumn'][0]), t(WIN['autumn'][1])
    p0 = t(WIN['spring'][0])
    rest_s = (13, 0, 0, 0, Z, 0)
    return {
        'winter': [k(0, (-6, 0, 0, 0, Z, 0)), k(t(w_out) - 0.6, (-6, 0, 0, 0, Z, 0)), k(t(w_out), J1)],
        'summer': [k(s0, J1), k(s0 + 0.5, rest_s), k(s1 - 0.55, rest_s), k(s1, J2)],
        'autumn': [k(a0, J2), k(a0 + 0.3, (6, -14, 0, 0, 5.0, 0)), k(a0 + 1.5, (4, -18, 0, 0, 3.4, 0)),
                   k(a1 - 0.6, (6, -14, 0, 0, 3.6, 0)), k(a1, J3)],
        'spring': [k(p0, J3), k(p0 + 0.6, (20, -22, 0, 0, 3.7, 0)), k(p0 + 4.2, (18, -18, 0, 0, 4.1, 0))],
    }


WINTER = {'clean': True, 'stage': 2, 'zoom': Z, 'seed': 4501, 'level': 45, 'advance': 0.5,
          'near': 'unit-reindeer-antlers', 'dx': 0, 'dy': 25,
          'items': [['wood_sword', 100], ['boss-snowman_outfit', 40]], 'wear': ['wood_sword', 'boss-snowman_outfit']}
SUMMER = {'clean': True, 'stage': 4, 'boss': 'boss-teal-dinosaur', 'zoom': Z, 'seed': 4402, 'level': 200,
          'dx': 0, 'dy': 30, 'advance': 0.3,
          'items': [['iron_sword', 100], ['boss-elephant_outfit_t2', 60]], 'wear': ['iron_sword', 'boss-elephant_outfit_t2'],
          'boss_history': ['boss-elephant'], 'known_opportunities': ['masterwork_o3', 'arsenal_o1']}
AUTUMN = {'clean': True, 'stage': 6, 'boss': 'boss-grim-reaper', 'zoom': Z, 'seed': 4403, 'level': 700,
          'dx': 0, 'dy': 30, 'advance': 0.3, 'summon_in': 1.5, 'skill_at': {'fire': 2.6},
          'items': [['gold_sword', 100], ['boss-red-fox_outfit_t3', 80]], 'wear': ['gold_sword', 'boss-red-fox_outfit_t3'],
          'skills': [['skill_fire', 60]], 'boss_history': ['boss-red-fox', 'boss-black-cat']}
SPRING = {'clean': True, 'stage': 8, 'boss': 'boss-red-panda', 'zoom': Z, 'seed': 4404, 'level': 238,
          'dx': 0, 'dy': 30, 'advance': 0.3, 'skill_at': {'lightning': 1.0, 'fire': 2.2, 'strike': 3.2},
          'items': [['emerald_sword', 90], ['boss-sunflower_outfit_t5', 500]], 'wear': ['emerald_sword', 'boss-sunflower_outfit_t5'],
          'skills': [['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]],
          'boss_history': ['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower']}
END = ('end_card', f'{RAW}/end_card.mkv', 0.0, 3.3)


def manifest(w_in: int, w_out: int) -> dict:
    WIN['winter'] = (w_in, w_out)
    c = cams(w_in, w_out)
    takes = [('v2_winter', 'trailer_farm', WINTER, 5.0, 'winter'), ('v2_summer', 'match_boss', SUMMER, 6.0, 'summer'),
             ('v2_autumn', 'match_boss', AUTUMN, 5.0, 'autumn'), ('v2_spring', 'match_boss', SPRING, 6.0, 'spring')]
    jobs = [{'id': tid, 'kind': 'video', 'scenario': sc, 'options': {**o, 'cam': c[sid]}, 'width': 1080, 'height': 1920,
             'fps': F, 'duration': sec, 'capture_ui': True, 'output': f'{OUT}/{tid}.avi'} for tid, sc, o, sec, sid in takes]
    shots = []
    for i, (tid, _, _, _, sid) in enumerate(takes):
        a, b = WIN[sid]
        s = {'id': sid, 'kind': 'clip', 'source': f'{OUT}/{tid}.avi', 'start': a / F, 'duration': (b - a) / F}
        if i:
            s['transition_in'] = {'type': 'cut'}
        shots.append(s)
    shots.append({'id': END[0], 'kind': 'clip', 'source': END[1], 'start': END[2], 'duration': END[3],
                  'transition_in': {'type': 'fade', 'duration': 0.4}})
    total = sum(s['duration'] for s in shots) - 0.4
    video = {'id': 'match_cut_v2', 'profile': 'play_store', 'width': 1080, 'height': 1920, 'fps': F,
             'target_duration': round(total, 3), 'output': '../../store_assets/video/experiments/LootFarmer_MatchCut_Camera_V2.mp4',
             'fade_in': 0.0, 'fade_out': 0.0, 'music': MUSIC, 'music_start': 60.0, 'music_volume': 0.85,
             'music_fade_in': 0.03, 'music_fade_out': 1.5, 'game_audio': False, 'shots': shots}
    return {'text_renderer': 'pillow', 'quality': 'high',
            'fonts': {'default': {'file': '../../assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'}},
            'strings': {'en-US': {}}, 'game_scene': 'res://scenes/game/main.tscn',
            'adapter_script': 'res://marketing/game_scenarios.gd', 'ui_group': 'store_screenshot_ui',
            'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
            'log_show': ['LOOTFARMER_MARKETING'], 'output_root': '../../store_assets',
            'capture_jobs': jobs, 'videos': [video]}


# Winter window in take frames: opens on a real hit's arc, ends on the wind-up before a later one.
WINTER_WINDOW = (7, 67)


def main() -> None:
    argparse.ArgumentParser(description=__doc__).parse_args()
    out = HERE / 'manifest.json'
    out.write_bytes((json.dumps(manifest(*WINTER_WINDOW), indent=2) + chr(10)).encode('utf-8'))
    print('wrote', out)


if __name__ == '__main__':
    main()
