"""Writes marketing/match_cut_v3/manifest.json (Godot Marketing Capture Toolkit 1.0.2) and speed.json for the
Change 46 zoom match-cut experiment (V3): the Change 44/45 four-season story, swords only (Wood, Iron, Gold,
Emerald), with the camera rushing IN -> OUT -> IN through the three hard cuts. A local review master;
marketing/trailer/, marketing/match_cut/ (V1) and marketing/match_cut_v2/ (V2) are untouched.

Each take is genuine play of res://scenes/game/main.tscn through the adapter's match_boss scenario (Winter
uses it on an ordinary Reindeer Antlers so the pack target stands straight above the hero, as the bosses do).
The camera never moves sideways: options.cam keys hold one fixed offset (the midpoint of the hero and their
opponent) and only the zoom moves, on Hermite keys whose zoom and zoom velocity are identical on both sides
of every cut. hud 'match' keeps the compact HUD (no player HP, thinned damage numbers).

speed.json lists, per output frame, the zoom speed (relative, 1/s) that add_speed_blur.py turns into a
short radial blur around the combat pair.
"""
import argparse
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw/video/trailer_c32'
OUT = '../../store_assets/raw/video/match_cut_v3'
MUSIC = '../../assets/sounds/background_music.wav'
F = 30
# Camera offset from the hero's feet (world px): the midpoint of hero and opponent. Autumn and Spring have
# equipped skills, so the skill row shortens the map by 84 px and moves its centre up 42 px; their offset
# is 5 px lower so the hero stays on the same screen row across the Summer -> Autumn cut (at zoom 2.8).
DY = {'winter': -47, 'summer': -47, 'autumn': -52, 'spring': -52}

# Shot windows in take frames (in, out exclusive). Each in-point is the first impact-arc frame of a real
# sword hit, each out-point the wind-up before one (hits logged by the adapter, HIT t=). The boss takes keep
# Change 45's seeds and staging, so their hits are the same frames.
WIN = {'winter': (13, 73), 'summer': (43, 133), 'autumn': (13, 103), 'spring': (13, 139)}

# Zoom at the three joins: (zoom, zoom velocity per second). Each rush ramps up over RAMP seconds, crosses
# the cut at full speed and eases out over SETTLE seconds in the next shot.
J1 = (2.75, 2.6)   # Winter -> Summer: rushing IN
J2 = (2.8, -2.4)   # Summer -> Autumn: pulling OUT
J3 = (2.7, 2.8)      # Autumn -> Spring: rushing IN
RAMP, SETTLE = 0.45, 0.4
WIDE, CLOSE, REVEAL, HERO = 2.1, 3.3, 2.25, 3.1


def k(t, z, v=0.0, dy=-47):
    return [round(t, 4), 0, dy, 0, 0, z, v]


def cams() -> dict:
    t = lambda f: f / F
    w0, w1 = map(t, WIN['winter'])
    s0, s1 = map(t, WIN['summer'])
    a0, a1 = map(t, WIN['autumn'])
    p0, p1 = map(t, WIN['spring'])
    keys = {
        'winter': [k(0, WIDE - 0.05), k(w1 - RAMP, WIDE + 0.08, 0.15), k(w1, *J1)],
        'summer': [k(s0, *J1), k(s0 + SETTLE, CLOSE), k(s1 - RAMP, CLOSE), k(s1, *J2)],
        'autumn': [k(a0, *J2), k(a0 + SETTLE + 0.1, REVEAL), k(a1 - RAMP, REVEAL + 0.1, 0.1), k(a1, *J3)],
        'spring': [k(p0, *J3), k(p0 + SETTLE + 0.05, HERO), k(p1 + 1.0, HERO + 0.15)],
    }
    return {sid: [[*key[:2], DY[sid], *key[3:]] for key in ks] for sid, ks in keys.items()}


def hermite(a, b, tt):
    h = b[0] - a[0]
    u = min(1.0, max(0.0, (tt - a[0]) / h))
    u2, u3 = u * u, u * u * u
    z = (2 * u3 - 3 * u2 + 1) * a[5] + (u3 - 2 * u2 + u) * h * a[6] + (-2 * u3 + 3 * u2) * b[5] + (u3 - u2) * h * b[6]
    dz = ((6 * u2 - 6 * u) * a[5] + (3 * u2 - 4 * u + 1) * h * a[6] + (-6 * u2 + 6 * u) * b[5] + (3 * u2 - 2 * u) * h * b[6]) / h
    return z, dz


def zoom_at(keys, tt):
    for a, b in zip(keys, keys[1:]):
        if tt < b[0]:
            return hermite(a, b, tt)
    return keys[-1][5], 0.0


WINTER = {'stage': 2, 'boss': 'unit-reindeer-antlers', 'pack': True, 'zoom': 3.0, 'seed': 4501, 'level': 45, 'dx': 0, 'dy': 30,
          'advance': 0.3, 'items': [['wood_sword', 100], ['boss-snowman_outfit', 40]],
          'wear': ['wood_sword', 'boss-snowman_outfit']}
SUMMER = {'stage': 4, 'boss': 'boss-teal-dinosaur', 'zoom': 3.0, 'seed': 4402, 'level': 200,
          'dx': 0, 'dy': 30, 'advance': 0.3,
          'items': [['iron_sword', 100], ['boss-elephant_outfit_t2', 60]], 'wear': ['iron_sword', 'boss-elephant_outfit_t2'],
          'boss_history': ['boss-elephant'], 'known_opportunities': ['masterwork_o3', 'arsenal_o1']}
AUTUMN = {'stage': 6, 'boss': 'boss-grim-reaper', 'zoom': 3.0, 'seed': 4403, 'level': 700,
          'dx': 0, 'dy': 30, 'advance': 0.3, 'summon_in': 1.5, 'skill_at': {'fire': 2.6},
          'items': [['gold_sword', 100], ['boss-red-fox_outfit_t3', 80]], 'wear': ['gold_sword', 'boss-red-fox_outfit_t3'],
          'skills': [['skill_fire', 60]], 'boss_history': ['boss-red-fox', 'boss-black-cat']}
SPRING = {'stage': 8, 'boss': 'boss-red-panda', 'zoom': 3.0, 'seed': 4404, 'level': 238,
          'dx': 0, 'dy': 30, 'advance': 0.3, 'skill_at': {'lightning': 1.0, 'fire': 2.2, 'strike': 3.2},
          'items': [['emerald_sword', 90], ['boss-sunflower_outfit_t5', 500]], 'wear': ['emerald_sword', 'boss-sunflower_outfit_t5'],
          'skills': [['skill_lightning', 50], ['skill_fire', 50], ['skill_strike', 50]],
          'boss_history': ['boss-bee', 'boss-orange-tabby-cat', 'boss-sunflower']}
END = ('end_card', f'{RAW}/end_card.mkv', 0.0, 3.3)
TAKES = [('v3_winter', WINTER, 4.0, 'winter'), ('v3_summer', SUMMER, 6.0, 'summer'),
         ('v3_autumn', AUTUMN, 5.0, 'autumn'), ('v3_spring', SPRING, 6.0, 'spring')]


def manifest() -> dict:
    c = cams()
    jobs = [{'id': tid, 'kind': 'video', 'scenario': 'match_boss',
             'options': {**o, 'hud': 'match', 'numbers_gap': 1.5, 'cam': c[sid]}, 'width': 1080, 'height': 1920,
             'fps': F, 'duration': sec, 'capture_ui': True, 'output': f'{OUT}/{tid}.avi'} for tid, o, sec, sid in TAKES]
    shots = []
    for i, (tid, _, _, sid) in enumerate(TAKES):
        a, b = WIN[sid]
        s = {'id': sid, 'kind': 'clip', 'source': f'{OUT}/{tid}.avi', 'start': a / F, 'duration': (b - a) / F}
        if i:
            s['transition_in'] = {'type': 'cut'}
        shots.append(s)
    shots.append({'id': END[0], 'kind': 'clip', 'source': END[1], 'start': END[2], 'duration': END[3],
                  'transition_in': {'type': 'fade', 'duration': 0.4}})
    total = sum(s['duration'] for s in shots) - 0.4
    video = {'id': 'match_cut_v3', 'profile': 'play_store', 'width': 1080, 'height': 1920, 'fps': F,
             'target_duration': round(total, 3), 'output': '../../store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V3.mp4',
             'fade_in': 0.0, 'fade_out': 0.0, 'music': MUSIC, 'music_start': 60.0, 'music_volume': 0.85,
             'music_fade_in': 0.03, 'music_fade_out': 1.5, 'game_audio': False, 'shots': shots}
    return {'text_renderer': 'pillow', 'quality': 'high',
            'fonts': {'default': {'file': '../../assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'}},
            'strings': {'en-US': {}}, 'game_scene': 'res://scenes/game/main.tscn',
            'adapter_script': 'res://marketing/game_scenarios.gd', 'ui_group': 'store_screenshot_ui',
            'godot_user_args': ['--profile=capture-store', '--no-autosave', '--first-run-complete'],
            'log_show': ['LOOTFARMER_MARKETING'], 'output_root': '../../store_assets',
            'capture_jobs': jobs, 'videos': [video]}


def speed() -> dict:
    """Per output frame: zoom and relative zoom speed (dz/dt / z), and the output frames of the three cuts."""
    c = cams()
    frames, cuts, n = [], [], 0
    for i, (_, _, _, sid) in enumerate(TAKES):
        a, b = WIN[sid]
        if i:
            cuts.append(n)
        for f in range(a, b):
            z, dz = zoom_at(c[sid], f / F)
            frames.append({'n': n, 'shot': sid, 'zoom': round(z, 4), 'rel_speed': round(dz / z, 4)})
            n += 1
    return {'cuts': cuts, 'frames': frames}


def main() -> None:
    argparse.ArgumentParser(description=__doc__).parse_args()
    for name, data in (('manifest.json', manifest()), ('speed.json', speed())):
        (HERE / name).write_bytes((json.dumps(data, indent=2) + chr(10)).encode('utf-8'))
        print('wrote', HERE / name)


if __name__ == '__main__':
    main()
