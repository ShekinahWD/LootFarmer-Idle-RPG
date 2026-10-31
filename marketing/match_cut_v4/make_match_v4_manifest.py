"""Writes marketing/match_cut_v4/manifest.json (Godot Marketing Capture Toolkit 1.0.2) and speed.json for the
Change 47 zoom match-cut experiment (V4): Change 46's four takes (same seeds, staging and shot windows, so the
same real hits and the same Grim Reaper summon), re-recorded with a stronger IN -> OUT -> IN camera rush.
A local review master; the trailer and V1/V2/V3 are untouched.

What changes from V3 is the camera alone (options.cam keys; no sideways travel, only zoom):
- Each rush is a cubic ease-in (zoom speed builds from rest to 3x the ramp's mean speed at the cut) and a
  cubic ease-out in the next shot, so the camera crosses every cut at its fastest, about 1.5x V3's speed.
- The cuts match the hero's apparent size, not the raw zoom number. The four outfits are different sprites
  (OUTFIT_SIZE), so the zoom on the far side of a cut is scaled by the size ratio; the relative zoom speed
  (dz/dt / z) is the same on both sides. Autumn -> Spring applies 65% of the ratio (in log scale), so the hero grows a little
  with the IN rush instead of the world shrinking against it.
- DY (the camera's height above the hero's feet) is solved per shot so the hero's feet sit on the same
  screen row on both sides of every cut. Winter opens closer than V3 (2.45 instead of 2.05).

speed.json lists, per output frame, the zoom speed (relative, 1/s) that add_speed_blur.py turns into a
short radial blur on the outer world area.
"""
import argparse
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
RAW = '../../store_assets/raw/video/trailer_c32'
OUT = '../../store_assets/raw/video/match_cut_v4'
MUSIC = '../../assets/sounds/background_music.wav'
F = 30
SCALE = 3.0   # screen px per world px at zoom 1.0 in a 1080-wide capture
# Map area: the skill row (Autumn, Spring have equipped skills) makes it 84 px shorter.
MAP_H = {'winter': 1240, 'summer': 1240, 'autumn': 1156, 'spring': 1156}
# Apparent hero size of each outfit (24x24 sheet, idle frame): mean of its height and sqrt(w*h), in sheet px.
# Snowman 15x19, Elephant 16x16, Red Fox 16x18, Sunflower 17x20.
OUTFIT_SIZE = {s: (h + math.sqrt(w * h)) / 2 for s, (w, h) in
               {'winter': (15, 19), 'summer': (16, 16), 'autumn': (16, 18), 'spring': (17, 20)}.items()}

# Shot windows in take frames (in, out exclusive), as in V3: each in-point the first impact-arc frame of a
# real sword hit, each out-point the wind-up before one.
WIN = {'winter': (13, 73), 'summer': (43, 133), 'autumn': (13, 103), 'spring': (13, 139)}

RAMP = 0.33                      # seconds of acceleration before each cut
WIDE = (2.45, 2.5)               # Winter hold (start, end of hold): the whole pack, closer than V3
CLOSE = (3.8, 3.85)              # Summer hold
REVEAL = (2.15, 2.2)             # Autumn hold: Grim Reaper and both Horned Hoods
HERO = (3.35, 3.45)              # Spring settle, then a slow push to the end card
CUT_OUT = {'winter': 3.0, 'summer': 3.2, 'autumn': 2.8}   # zoom on the last frame-time of each outgoing shot
DY_WINTER = 45.0                 # world px from the hero's feet up to the camera centre


def plan() -> dict:
    """Zoom and zoom speed on both sides of each cut, and each shot's DY."""
    t = lambda f: f / F
    order = ['winter', 'summer', 'autumn', 'spring']
    hold = {'winter': WIDE, 'summer': CLOSE, 'autumn': REVEAL}
    cuts, dy = [], {'winter': DY_WINTER}
    for a, b in zip(order, order[1:]):
        z_out = CUT_OUT[a]
        v_out = 3.0 * (z_out - hold[a][1]) / RAMP              # cubic ease-in from rest
        ratio = OUTFIT_SIZE[a] / OUTFIT_SIZE[b]
        if b == 'spring':
            ratio = ratio ** 0.65                              # most of the size step; the rest grows with the IN rush
        z_in = z_out * ratio
        v_in = v_out * ratio                                   # same relative speed
        # Hero feet on the same screen row: map centre + SCALE * DY * zoom.
        feet = MAP_H[a] / 2 + SCALE * dy[a] * z_out
        dy[b] = (feet - MAP_H[b] / 2) / (SCALE * z_in)
        cuts.append({'from': a, 'to': b, 'time_out': t(WIN[a][1]), 'time_in': t(WIN[b][0]),
                     'z_out': z_out, 'v_out': v_out, 'z_in': z_in, 'v_in': v_in, 'feet_y': feet})
    return {'cuts': cuts, 'dy': dy}


def k(t, z, v=0.0):
    return [round(t, 4), 0, 0, 0, 0, round(z, 4), round(v, 4)]


def settle(t0, z0, v0, target):
    """Cubic ease-out from (z0, v0) to rest at target: duration 3 * travel / speed."""
    return k(t0 + 3.0 * (target - z0) / v0, target)


def cams() -> dict:
    p = plan()
    c1, c2, c3 = p['cuts']
    keys = {
        'winter': [k(0, WIDE[0], 0.02), k(c1['time_out'] - RAMP, WIDE[1]), k(c1['time_out'], c1['z_out'], c1['v_out'])],
        'summer': [k(c1['time_in'], c1['z_in'], c1['v_in']), settle(c1['time_in'], c1['z_in'], c1['v_in'], CLOSE[0]),
                   k(c2['time_out'] - RAMP, CLOSE[1]), k(c2['time_out'], c2['z_out'], c2['v_out'])],
        'autumn': [k(c2['time_in'], c2['z_in'], c2['v_in']), settle(c2['time_in'], c2['z_in'], c2['v_in'], REVEAL[0]),
                   k(c3['time_out'] - RAMP, REVEAL[1]), k(c3['time_out'], c3['z_out'], c3['v_out'])],
        'spring': [k(c3['time_in'], c3['z_in'], c3['v_in']), settle(c3['time_in'], c3['z_in'], c3['v_in'], HERO[0]),
                   k(WIN['spring'][1] / F + 0.5, HERO[1])],
    }
    # A key's 3rd value is the camera's y offset from the hero (negative: above).
    return {sid: [[key[0], 0, -round(p['dy'][sid], 2), *key[3:]] for key in ks] for sid, ks in keys.items()}


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
TAKES = [('v4_winter', WINTER, 4.0, 'winter'), ('v4_summer', SUMMER, 6.0, 'summer'),
         ('v4_autumn', AUTUMN, 5.0, 'autumn'), ('v4_spring', SPRING, 6.0, 'spring')]


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
    video = {'id': 'match_cut_v4', 'profile': 'play_store', 'width': 1080, 'height': 1920, 'fps': F,
             'target_duration': round(total, 3), 'output': '../../store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V4.mp4',
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
    """Per output frame: zoom, relative zoom speed (dz/dt / z), the hero's apparent size (zoom x outfit size)
    and feet row; plus the output frames of the three cuts and the cut plan."""
    c, p = cams(), plan()
    frames, cuts, n = [], [], 0
    for i, (_, _, _, sid) in enumerate(TAKES):
        a, b = WIN[sid]
        if i:
            cuts.append(n)
        for f in range(a, b):
            z, dz = zoom_at(c[sid], f / F)
            frames.append({'n': n, 'shot': sid, 'zoom': round(z, 4), 'rel_speed': round(dz / z, 4),
                           'hero_size': round(z * OUTFIT_SIZE[sid], 3),
                           'feet_y': round(MAP_H[sid] / 2 + SCALE * p['dy'][sid] * z, 1)})
            n += 1
    return {'cuts': cuts, 'plan': p, 'frames': frames}


def main() -> None:
    argparse.ArgumentParser(description=__doc__).parse_args()
    for name, data in (('manifest.json', manifest()), ('speed.json', speed())):
        (HERE / name).write_bytes((json.dumps(data, indent=2) + chr(10)).encode('utf-8'))
        print('wrote', HERE / name)


if __name__ == '__main__':
    main()
