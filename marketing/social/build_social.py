"""Builds the ten LootFarmer social masters (9:16, 1080x1920, 30 fps, 15.000 s) from the recorded takes.

    python marketing/social/build_social.py            # all ten
    python marketing/social/build_social.py 3 7        # only these

Sources (all real play; nothing is drawn here except text and the approved end card):
  store_assets/raw/video/social/*.avi          current build (HEAD), marketing/social/manifest.json
  store_assets/raw/video/social/before/*.avi   the build of 6 Nov 2026 (3dd2eab), recorded from a detached worktree
  store_assets/raw/video/trailer_c32/c33_gear.avi   the 28 Oct 2026 build (Change 33 take), used only as "before"
  store_assets/raw/video/trailer_c32/end_card.mkv   the approved brand end card (feature-graphic layers)
Every string is in STRINGS below (en-US); message type and editing style per video are in VIDEOS[*]['meta'].
"""
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import social_engine as E  # noqa: E402
from social_engine import GOLD, GREEN, RED, WHITE, text, tag  # noqa: E402

ROOT = E.ROOT
RAW = ROOT / 'store_assets/raw/video/social'
OLD = RAW / 'before'
C32 = ROOT / 'store_assets/raw/video/trailer_c32'
END = C32 / 'end_card.mkv'
OUT = ROOT / 'store_assets/video/social'
WORK = RAW / 'work'
F = E.FPS

UP, LOW = 400, 1340            # text bands (centre y) inside the safe box
PANEL = (540, 800, 1.3)        # item / offline panel with the map above it (HUD takes at a pack)
PANEL_CAMP = (540, 1000, 1.3)  # the same panel when the hero stands in a camp (panel sits lower)
MAP = (540, 560, 1.35)         # the map area of a HUD take


def take(name: str) -> Path:
    return RAW / f'{name}.avi'


def end_card(seconds: float, into='flash') -> dict:
    return {'src': END, 't': 4.5 - seconds - 0.4, 'd': seconds, 'into': into, 'note': 'brand end card'}


def load_v4():
    spec = importlib.util.spec_from_file_location('v4', HERE.parent / 'match_cut_v4' / 'make_match_v4_manifest.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    spec2 = importlib.util.spec_from_file_location('blur', HERE.parent / 'match_cut_v4' / 'add_speed_blur.py')
    blur = importlib.util.module_from_spec(spec2)
    spec2.loader.exec_module(blur)
    return mod, blur


# ------------------------------------------------------------------ 1. the review story

def v1():
    shots = [
        {'src': OLD / 'o_pack.avi', 't': 2.0, 'd': 1.9, 'view': MAP, 'note': 'old build: a Summer I pack attacks at once'},
        {'src': OLD / 'o_pack.avi', 't': 6.6, 'd': 1.6, 'view': MAP, 'note': 'old build: HP nearly gone'},
        {'src': take('n_pack_after'), 't': 1.0, 'd': 1.5, 'view': MAP, 'into': 'flash', 'note': 'same hero and spot, current build'},
        {'src': take('n_crit'), 't': 3.45, 'd': 0.8, 'note': 'crit impact (9791b1b)'},
        {'src': take('n_gear'), 't': 6.25, 'd': 1.0, 'note': 'stat feedback bursts on equip (8ce00ae, 7ba013e)'},
        {'src': OLD / 'o_teleport.avi', 't': 1.0, 'd': 0.5, 'view': (540, 700, 1.25), 'note': 'old Teleport: a list'},
        {'src': take('n_teleport'), 't': 3.25, 'd': 1.3, 'into': 'flash', 'note': 'visual Teleport map and portal (9a078c4, 0d3b328)'},
        {'src': take('n_merge'), 't': 4.55, 'd': 0.8, 'view': PANEL_CAMP, 'note': 'merge burst (2f1acb2)'},
        {'src': take('n_evolve'), 't': 5.05, 'd': 1.0, 'note': 'evolution show (2f1acb2)'},
        {'src': C32 / 'c33_gear.avi', 't': 2.75, 'd': 0.5, 'note': '28 Oct build: a boss defeat'},
        {'src': take('n_boss_clean'), 't': 2.8, 'd': 1.1, 'into': 'flash', 'note': 'boss defeat moment (0d3b328)'},
        {'src': take('n_end_clean'), 't': 0.8, 'd': 1.5, 'dim': 0.62, 'note': 'closing line'},
        end_card(1.5),
    ]
    ov = [
        tag(0.0, 3.5, 'OLD BUILD · NOV 6', 216),
        text(0.0, 1.85, ['A player rated', ('my game 4/10.', GOLD)], cy=UP + 10, size=100, anim='slam'),
        text(1.9, 3.45, ['“Normal enemies hit', 'harder than bosses.”'], cy=UP + 10, size=84),
        text(2.3, 3.45, [('They were right.', GOLD)], cy=LOW, size=92),
        tag(3.5, 5.0, 'DAY 2', 216, color=GOLD, size=70),
        text(3.6, 4.95, ['Rebalanced.'], cy=UP + 10, size=120),
        text(5.0, 5.8, ['…but then'], cy=UP, size=120, anim='slam'),
        tag(5.8, 6.8, 'DAY 5', 216, color=GOLD, size=70),
        text(5.85, 6.78, ['Stat feedback'], cy=LOW, size=92),
        tag(6.8, 12.0, 'DAY 6', 216, color=GOLD, size=70),
        tag(6.8, 7.3, 'BEFORE', 328, color=RED),
        tag(7.3, 8.6, 'AFTER', 328, color=GREEN),
        text(6.85, 8.58, ['Teleport map'], cy=LOW, size=92),
        text(8.62, 9.38, ['Merge bursts'], cy=LOW, size=92),
        text(9.42, 10.38, ['Evolutions'], cy=LOW, size=92),
        tag(10.4, 10.9, 'BEFORE', 328, color=RED),
        tag(10.9, 12.0, 'AFTER', 328, color=GREEN),
        text(10.42, 11.98, ['Boss defeats'], cy=LOW, size=92),
        text(12.05, 13.45, ['The 2-day fix', ('took 6 days.', GOLD)], cy=UP + 20, size=112, anim='slam'),
        text(12.5, 13.45, ['33 commits later'], cy=LOW, size=72, anim='fade'),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 62,
            'meta': {'title': 'A player review changed everything', 'type': 'Bait / Hook', 'style': 'devlog, dated before/after hard cuts'}}


# ------------------------------------------------------------------ 2. four-season match cut

def v2():
    v4, blur = load_v4()
    speed = v4.speed()['frames']
    shots, n0 = [], 0
    for sid in ('winter', 'summer', 'autumn', 'spring'):
        a, b = v4.WIN[sid]
        rows = speed[n0:n0 + (b - a)]
        map_h = blur.MAP_H[sid]

        def fx(arr, i, rows=rows, map_h=map_h):
            s = blur.strength(rows[min(i, len(rows) - 1)]['rel_speed'])
            return blur.blur(arr, map_h, s) if s > 0 else arr

        shots.append({'src': take(f'm_{sid}'), 't': a / F, 'd': (b - a) / F, 'fx': fx,
                      'note': f'{sid}: cut on a real sword hit; zoom-rush camera recorded in the take'})
        n0 += b - a
    shots.append({'src': END, 't': 0.6, 'd': 3.2, 'into': ('xfade', 12), 'note': 'brand end card'})
    return {'shots': shots, 'overlays': [], 'music': 72,
            'meta': {'title': 'Four seasons, one swing', 'type': 'No Text', 'style': 'match cut on sword hits, zoom rush, radial speed blur'}}


# ------------------------------------------------------------------ 3. text hook: the gear chain

def v3():
    shots = [
        {'src': take('n_gear'), 't': 1.06, 'd': 7.2, 'note': 'one continuous take: fight, defeat 2.96, pickups 4.49/4.79, push-in, outfit 6.39, sword 7.39'},
        {'src': take('n_gear_fight'), 't': 1.0, 'd': 3.2, 'note': 'the new look in a fight'},
        {'src': take('n_crit'), 't': 3.3, 'd': 1.4, 'note': 'Autumn II, Red Fox outfit'},
        {'src': take('n_end_clean'), 't': 0.7, 'd': 1.5, 'note': 'Spring II, Sunflower outfit'},
        end_card(1.7),
    ]
    ov = [
        text(0.0, 1.75, ['I beat a dinosaur…'], cy=UP, size=104, anim='slam'),
        text(2.1, 3.7, ['…so I took', 'its stuff.'], cy=UP, size=112),
        text(4.75, 5.75, [('Its outfit.', GOLD)], cy=LOW, size=112),
        text(5.8, 7.15, [('Its sword.', GOLD)], cy=LOW, size=112),
        text(7.3, 10.3, ['Defeat it.', ('Wear it.', GOLD)], cy=UP, size=128),
        text(10.5, 13.25, ['48 enemies.', ('48 outfits.', GOLD)], cy=UP, size=116),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 102,
            'meta': {'title': 'I beat a dinosaur', 'type': 'Bait / Hook', 'style': 'text hook over one continuous clean take'}}


# ------------------------------------------------------------------ 4. progressive loop

def v4():
    shots = [
        {'src': take('n_boss_hud'), 't': 4.6, 'd': 2.3, 'note': 'Grim Reaper fight, crits 4.96 / 5.96'},
        {'src': take('n_gear'), 't': 2.7, 'd': 2.2, 'note': 'defeat 2.96, drops, pickups 4.49 / 4.79'},
        {'src': take('n_merge'), 't': 4.3, 'd': 2.2, 'view': PANEL_CAMP, 'note': 'Merge 57 spare copies 4.83'},
        {'src': take('n_evolve'), 't': 4.6, 'd': 2.6, 'note': 'Iron Sword -> Gold Sword'},
        {'src': take('n_prestige'), 't': 1.0, 'd': 2.2, 'note': 'Prestige card choice, Hard Hit picked 2.2'},
        {'src': take('n_end'), 't': 0.6, 'd': 1.8, 'note': 'Spring II'},
        end_card(1.7),
    ]
    cues = [(0.0, 2.3, '1  FIGHT', 272), (2.3, 4.5, '2  LOOT', 272), (4.5, 6.7, '3  MERGE', 272), (6.7, 9.3, '4  EVOLVE', LOW),
            (9.3, 11.5, '5  PRESTIGE', LOW)]
    ov = [text(a + 0.02, b - 0.05, [(word, GOLD)], cy=cy, size=140, anim='slam') for a, b, word, cy in cues]
    ov.append(text(11.52, 13.25, ['COME BACK', ('STRONGER', GOLD)], cy=LOW - 30, size=120, anim='slam'))
    return {'shots': shots, 'overlays': ov, 'music': 42,
            'meta': {'title': 'The loop in five words', 'type': 'Progressive', 'style': 'numbered cue words cut to the matching action'}}


# ------------------------------------------------------------------ 5. split screen: level 1 vs level 238

def v5():
    half = (540, 570, 1.2)
    shots = [
        {'d': 11.6, 'split': [{'src': take('n_day1'), 't': 0.5, 'view': half}, {'src': take('n_end'), 't': 0.5, 'view': half}],
         'note': 'top: level 1, Wood Sword, Winter I; bottom: level 238, Obsidian Sword, three skills, Spring II'},
        {'src': take('n_end_clean'), 't': 2.9, 'd': 1.7, 'into': 'flash', 'note': 'Spring II, clean'},
        end_card(1.7),
    ]
    ov = [
        tag(0.0, 11.6, 'LEVEL 1', 222, size=60),
        tag(0.0, 11.6, 'LEVEL 238', 1035, color=GOLD, size=60),
        text(0.0, 1.75, ['SAME GAME.'], cy=960, size=150, anim='slam'),
        text(1.9, 3.7, ['237 levels apart.'], cy=960, size=104),
        text(4.2, 7.5, ['9 damage · 100 HP'], cy=830, size=80),
        text(4.5, 7.5, [('646 damage · 9,099 HP', GOLD)], cy=1105, size=80),
        text(8.0, 11.5, ['Everything in between?', ('You farm it.', GOLD)], cy=960, size=92),
        text(11.75, 13.25, [('Your turn.', GOLD)], cy=UP, size=140, anim='slam'),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 22,
            'meta': {'title': 'Level 1 vs level 238', 'type': 'Informational', 'style': 'simultaneous split screen comparison'}}


# ------------------------------------------------------------------ 6. satisfying, game sound only

def v6():
    shots = [
        {'src': take('n_crit'), 't': 3.45, 'd': 1.6, 'note': 'crits 3.73 / 4.73'},
        {'src': take('n_merge'), 't': 2.0, 'd': 3.5, 'view': PANEL_CAMP, 'note': 'three single merges 2.23 / 2.93 / 3.63, then Merge 57 spare copies 4.83'},
        {'src': take('n_evolve'), 't': 4.1, 'd': 3.2, 'note': 'evolution: charge, burst, reveal'},
        {'src': take('n_supply'), 't': 0.8, 'd': 1.5, 'note': 'Coin Tonic burst and aura'},
        {'src': take('n_teleport'), 't': 3.9, 'd': 1.7, 'note': 'Confirm Teleport, violet portal'},
        {'src': take('n_boss_clean'), 't': 2.6, 'd': 2.1, 'note': 'boss defeat moment'},
        end_card(1.4),
    ]
    return {'shots': shots, 'overlays': [], 'game_audio': True, 'music': 32, 'bed': 0.3,
            'meta': {'title': 'Sound on', 'type': 'No Text', 'style': 'effects montage on the game sound effects, the game music low underneath'}}


# ------------------------------------------------------------------ 7. offline rewards

def v7():
    shots = [
        {'src': take('n_quick'), 't': 3.0, 'd': 2.0, 'dim': 0.5, 'note': 'hook over play'},
        {'src': take('n_offline'), 't': 0.6, 'd': 4.2, 'view': (540, 900, 1.1), 'into': 'flash', 'note': 'the offline receipt after an 8 h absence (real settlement)'},
        {'src': take('n_offline'), 't': 4.9, 'd': 2.2, 'view': (540, 760, 1.2), 'note': 'Claim 5.23'},
        {'src': take('n_quick'), 't': 1.1, 'd': 4.9, 'view': (432, 640, 1.25), 'note': 'Auto Farm OFF -> ON 1.63'},
        end_card(1.7),
    ]
    ov = [
        text(0.0, 1.95, ['I closed the game', ('for 8 hours.', GOLD)], cy=UP + 20, size=108, anim='slam'),
        text(2.5, 6.1, ['This was waiting.'], cy=UP - 110, size=104),
        text(6.45, 8.35, [('+6.72K coins · 96 items', GOLD)], cy=LOW, size=80),
        text(8.75, 10.9, ['One tap:', ('AUTO FARM', GREEN)], cy=LOW - 20, size=108),
        text(11.1, 13.25, ['It keeps farming.', ('You don\'t have to.', GOLD)], cy=LOW - 20, size=92),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 52,
            'meta': {'title': 'I closed the game for 8 hours', 'type': 'Bait / Hook', 'style': 'UI story: receipt, claim, one-tap automation'}}


# ------------------------------------------------------------------ 8. curiosity: 31 swords

def v8():
    shots = [
        {'src': take('n_evolve'), 't': 0.9, 'd': 3.5, 'view': PANEL_CAMP, 'note': 'Iron Sword x31; Merge 20 spare copies 2.43; Evolve pressed 4.23'},
        {'src': take('n_evolve'), 't': 4.4, 'd': 3.1, 'note': 'evolution show'},
        {'src': take('n_evolve'), 't': 7.9, 'd': 1.3, 'view': PANEL_CAMP, 'note': 'Gold Sword equipped 8.33'},
        {'src': take('n_gear_fight'), 't': 0.8, 'd': 3.1, 'into': 'flash', 'note': 'the same outfit with a Gold Sword in a fight'},
        {'src': take('n_end_clean'), 't': 0.6, 'd': 2.3, 'note': 'Obsidian Sword, Spring II'},
        end_card(1.7),
    ]
    ov = [
        text(0.0, 1.9, ['What happens if you', ('merge 31 swords?', GOLD)], cy=UP - 20, size=100, anim='slam'),
        text(2.1, 3.4, ['First: 20 copies in.'], cy=UP - 20, size=92),
        text(5.3, 6.5, [('NEW SWORD.', GOLD)], cy=LOW, size=120, anim='slam'),
        text(6.65, 7.85, ['Equip it.'], cy=UP - 20, size=104),
        text(8.1, 11.0, ['7 tiers.', ('Wood to Obsidian.', GOLD)], cy=UP, size=112),
        text(11.2, 13.25, ['This is the last one.'], cy=UP, size=96),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 92,
            'meta': {'title': 'What happens if you merge 31 swords?', 'type': 'Bait / Hook', 'style': 'curiosity question answered by one real UI sequence'}}


# ------------------------------------------------------------------ 9. outfit lookbook on the beat

LOOK_NAMES = {
    'w': ['Snowman', 'Wolf Hood', 'Cyan Robot', 'Reindeer Antlers', 'Space Helmet'],
    's': ['Gray Cat', 'Snorkeler', 'Elephant', 'Rainbow Clown', 'Teal Dinosaur'],
    'a': ['Squirrel', 'Pumpkin Head', 'Red Fox', 'Television Head', 'Grim Reaper'],
    'p': ['Bunny Ears', 'Bee', 'Cat Ears', 'Orange Tabby Cat', 'Elf Ears'],
}


def v9():
    beat = lambda k: round(k * E.BEAT * F)  # noqa: E731
    shots, ov = [], []
    j = 0
    for i in range(5):
        for key in ('w', 's', 'a', 'p'):
            n = beat(j + 1) - beat(j)
            t = 0.25 if i == 0 else 0.925 + 0.8 * (i - 1) + 0.1
            shots.append({'src': take(f'n_look_{key}'), 't': t, 'd': n / F, 'note': f'{LOOK_NAMES[key][i]} outfit'})
            ov.append(text(beat(j) / F, beat(j + 1) / F, [LOOK_NAMES[key][i]], cy=LOW, size=84, anim='none'))
            j += 1
    shots.append({'src': take('n_gear'), 't': 6.1, 'd': (beat(26) - beat(20)) / F, 'note': 'outfit equipped 6.39, sword 7.39'})
    shots.append({'src': take('n_gear_fight'), 't': 1.0, 'd': (beat(32) - beat(26)) / F, 'note': 'in a fight'})
    shots.append(end_card((450 - beat(32)) / F))
    ov += [
        text(0.0, beat(2) / F, ['48 ENEMIES.'], cy=UP, size=130, anim='slam'),
        text(beat(2) / F, beat(4) / F, [('48 OUTFITS.', GOLD)], cy=UP, size=130, anim='slam'),
        text(beat(20) / F + 0.05, beat(26) / F - 0.05, ['Beat it.', ('Wear it.', GOLD)], cy=UP, size=128),
        text(beat(26) / F + 0.05, beat(32) / F - 0.05, ['Which one first?'], cy=UP, size=110),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 112,
            'meta': {'title': '48 enemies, 48 outfits', 'type': 'Informational', 'style': 'one outfit per beat (145 BPM), four seasons interleaved'}}


# ------------------------------------------------------------------ 10. revenge arc

def v10():
    shots = [
        {'src': take('n_rev_lose'), 't': 1.6, 'd': 3.9, 'note': 'the real loss: hero defeated 4.36'},
        {'src': take('n_rev_merge'), 't': 1.5, 'd': 1.8, 'view': PANEL_CAMP, 'into': 'flash', 'note': 'Merge 500 spare copies 1.93'},
        {'src': take('n_rev_merge'), 't': 4.3, 'd': 2.2, 'view': PANEL_CAMP, 'note': 'Diamond Sword ^20 4.63, equipped 5.83'},
        {'src': take('n_rev_win'), 't': 0.3, 'd': 5.4, 'into': 'flash', 'note': 'the real rematch: boss defeated 2.96 with 25 HP left'},
        end_card(1.7),
    ]
    ov = [
        text(0.0, 2.5, ['This boss', ('killed me.', RED)], cy=UP, size=124, anim='slam'),
        text(2.95, 3.85, ['So I went farming.'], cy=UP, size=100),
        text(4.0, 5.65, [('500 copies', GOLD), 'of one outfit.'], cy=UP - 20, size=104),
        text(5.8, 7.85, ['And a sharper sword.'], cy=UP - 20, size=92),
        text(7.95, 9.0, [('ROUND 2', GOLD)], cy=UP, size=170, anim='slam'),
        text(11.0, 13.25, ['Won with', ('25 HP left.', GOLD)], cy=UP, size=120),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 82,
            'meta': {'title': 'This boss killed me', 'type': 'Bait / Hook', 'style': 'three-act story: loss, upgrade, rematch'}}


VIDEOS = {1: ('review_story', v1), 2: ('match_cut', v2), 3: ('gear_hook', v3), 4: ('loop', v4), 5: ('split_levels', v5),
          6: ('sound_on', v6), 7: ('offline', v7), 8: ('31_swords', v8), 9: ('lookbook', v9), 10: ('revenge', v10)}


def output(n: int) -> Path:
    return OUT / f'LootFarmer_Social_{n:02d}_{VIDEOS[n][0]}.mp4'


def build(n: int) -> None:
    slug, make = VIDEOS[n]
    video = make()
    video.update(id=f'{n:02d}_{slug}', duration=15.0)
    wav = WORK / f'{n:02d}_audio.wav'
    if video.get('game_audio'):
        parts = [(s['src'] if Path(s['src']) != END else None, float(s.get('t', 0)), float(s['d'])) for s in video['shots']]
        E.game_audio_track(wav, parts, 15.0, bed=(E.music_in(video['music']), video['bed']))
        audio = {'kind': 'game sound effects of the takes over the game music', 'music_start': round(E.music_in(video['music']), 4), 'music_level': video['bed'], 'parts': [[str(p[0]), p[1], p[2]] for p in parts]}
    else:
        start = E.music_in(video['music'])
        gain = E.music_track(wav, start, 15.0)
        audio = {'kind': 'music only', 'source': str(E.MUSIC), 'start': round(start, 4), 'volume': round(float(gain), 4)}
    out = output(n)
    record = E.render(video, out, wav)
    record.update(meta=video['meta'], audio=audio, output=str(out))
    E.save_json(OUT / 'timelines' / f'{n:02d}_{slug}.json', record)
    print('built', out)


def main() -> None:
    ids = [int(a) for a in sys.argv[1:]] or list(VIDEOS)
    for n in ids:
        build(n)


if __name__ == '__main__':
    main()
