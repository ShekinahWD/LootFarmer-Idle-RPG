"""Builds the ten LootFarmer social masters (9:16, 1080x1920, 30 fps; 15 to 31 s each) from the recorded takes.

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

# Revision 2 (developer review, 12 Nov 2026): panels are shown at full width (no crop: the merge burst sits on
# the item icon at the panel's left edge), every caption stays in ONE place per video on a dark plate, one at a
# time, long enough to read (review_social.py: at least 1.4 s and at most 14 characters per second), and the
# 15 s cap is gone.
UP, LOW = 330, 1345            # the two caption positions (centre y) inside the safe box
MAP = (540, 560, 1.35)         # the map area of a HUD take
HERO = (540, 900)              # where the hero stands in a clean take


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


# ------------------------------------------------------------------ 1. the review story (Change 73: a week of fixes)
# Revision 3 (13 Nov 2026): the story still opens on the review of 6 Nov and its fix, then shows a few of the
# strongest, most visual improvements made since (not a changelog): the decluttered HUD (dated before/after,
# the old take recorded from a worktree of 3856390), saved inventory sorting, the bulk Supplies shop and the
# rebuilt Prestige celebration.

def v1():
    c = LOW
    shots = [
        {'src': OLD / 'o_pack.avi', 't': 2.0, 'd': 2.8, 'view': MAP, 'note': 'old build (6 Nov): a Summer I pack attacks at once'},
        {'src': OLD / 'o_pack.avi', 't': 4.8, 'd': 3.0, 'view': MAP, 'note': 'old build: HP nearly gone'},
        {'src': take('n_pack_after'), 't': 1.0, 'd': 3.2, 'view': MAP, 'into': 'flash', 'note': 'same hero and spot, current build'},
        {'src': OLD / 'o_hud_fight.avi', 't': 2.0, 'd': 3.0, 'note': '12 Nov build (3856390): the same fight with the HUD before the declutter'},
        {'src': take('n_hud_fight'), 't': 2.0, 'd': 3.4, 'into': 'flash', 'note': 'current build: two edge rails, fight form chips, objective pills counting'},
        {'src': take('n_sort'), 't': 1.9, 'd': 4.6, 'note': 'Filters: order by Tier 2.23, by Quantity 4.63; the dock grid reorders'},
        {'src': take('n_shop'), 't': 1.9, 'd': 3.6, 'note': 'Supplies shop: x10 2.23, Buy x10 3.63, Potions owned 2 -> 12'},
        {'src': take('n_prestige_fx'), 't': 1.65, 'd': 2.35, 'note': 'final Prestige card selected 1.6 (the cards reflow then), Keep 2.83, confirm dialog'},
        {'src': take('n_prestige_clean'), 't': 4.05, 'd': 4.2, 'note': 'Prestige committed 4.03 (Winter I from 4.03): reveal, spiral, impact 5.9, ascend, resolve'},
        {'src': take('n_endc'), 't': 0.6, 'd': 4.0, 'dim': 0.6, 'note': 'closing line'},
        end_card(2.0),
    ]
    at = [0.0]
    for s in shots:
        at.append(at[-1] + s['d'])
    ov = [
        tag(at[0], at[2], 'OLD BUILD · NOV 6', 216),
        text(at[0], at[1] - 0.1, ['A player rated', ('my game 4/10.', GOLD)], cy=c, size=100, anim='slam'),
        text(at[1], at[2] - 0.1, ['“Normal enemies hit', 'harder than bosses.”'], cy=c, size=84),
        tag(at[2], at[3], 'FIXED', 216, color=GREEN, size=70),
        text(at[2] + 0.1, at[3] - 0.1, ['They were right.', ('So I fixed it…', GOLD)], cy=c, size=96),
        tag(at[3], at[4], 'BEFORE', 216, color=RED),
        tag(at[4], at[5], 'NOW', 216, color=GREEN),
        text(at[3] + 0.1, at[4] - 0.1, ['…then kept going.', 'The fight was buried.'], cy=c, size=84),
        text(at[4] + 0.15, at[5] - 0.1, [('Now you see it all.', GOLD)], cy=c, size=92),
        text(at[5] + 0.4, at[6] - 0.1, ['Sort your loot.'], cy=c, size=100),
        text(at[6] + 0.3, at[7] - 0.1, ['Buy by the stack.'], cy=c, size=100),
        text(at[7] + 0.1, at[8] + 0.6, ['And Prestige…'], cy=c, size=100),
        text(at[8] + 2.2, at[9] - 0.1, [('…now feels earned.', GOLD)], cy=c, size=92),
        text(at[9] + 0.1, at[10] - 0.1, ['The 2-day fix', ('became a week.', GOLD), ('Thanks for the 4/10.', WHITE, 64)], cy=c - 60, size=100, anim='slam'),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 62,
            'meta': {'title': 'A player review changed everything', 'type': 'Bait / Hook',
                     'style': 'devlog: dated before/after hard cuts, then a few improvements shown at full width'}}


# ------------------------------------------------------------------ 2. crit match cut (new for this set)

def v2():
    def punch(z0, z1):
        return {'view': (HERO[0], HERO[1] - 50, z0), 'view2': (HERO[0], HERO[1] - 30, z1)}
    shots = [
        {'src': take('c_winter'), 't': 4.675, 'd': 2.5, **punch(1.32, 1.0), 'note': 'Winter II, Cyan Robot: in on the crit at 4.73'},
        {'src': take('c_summer'), 't': 1.675, 'd': 3.0, **punch(1.32, 1.0), 'note': 'Summer II, Elephant: in on the crit at 1.73; crit 3.73'},
        {'src': take('n_crit'), 't': 3.675, 'd': 2.5, **punch(1.25, 1.0), 'note': 'Autumn II, Black Cat: in on the crit at 3.73; crit 4.73'},
        {'src': take('c_spring'), 't': 0.908, 'd': 5.4, **punch(1.32, 1.0), 'note': 'Spring I, Bee: in on the crit at 0.96; crit 1.96; defeated by the crit at 2.96'},
        {'src': END, 't': 1.4, 'd': 2.4, 'into': ('xfade', 12), 'note': 'brand end card'},
    ]
    return {'shots': shots, 'overlays': [], 'music': 72,
            'meta': {'title': 'Four seasons, four crits', 'type': 'No Text', 'style': 'match cut on critical hits, punch-in on each cut, ends on a boss defeat'}}


# ------------------------------------------------------------------ 3. text hook: the gear chain

def v3():
    c = UP
    shots = [
        {'src': take('n_gear2'), 't': 1.06, 'd': 12.4, 'note': 'one continuous take: defeat 2.96, the two drops lie alone and in view for 2 s after the defeat effect, outfit picked up 7.19, sword 8.19, push-in, outfit worn 9.89, sword 11.09'},
        {'src': take('n_gear_fight'), 't': 0.8, 'd': 3.6, 'note': 'the new look in a fight'},
        {'src': take('n_crit'), 't': 3.3, 'd': 2.2, 'note': 'Autumn II, Red Fox outfit'},
        {'src': take('n_endc'), 't': 0.6, 'd': 2.4, 'note': 'Spring II, Sunflower outfit'},
        end_card(2.0),
    ]
    ov = [
        text(0.0, 1.8, ['I beat a dinosaur…'], cy=c, size=104, anim='slam'),
        text(2.4, 5.6, ['It dropped', ('what it wore.', GOLD)], cy=c, size=104),
        text(5.8, 7.9, ['So I took it.'], cy=c, size=104),
        text(8.5, 9.95, [('Its outfit.', GOLD)], cy=c, size=112),
        text(10.05, 12.3, [('And its sword.', GOLD)], cy=c, size=112),
        text(12.5, 15.9, ['Defeat it.', ('Wear it.', GOLD)], cy=c, size=124),
        text(16.1, 20.5, ['48 enemies.', ('48 outfits.', GOLD)], cy=c, size=116),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 102,
            'meta': {'title': 'I beat a dinosaur', 'type': 'Bait / Hook', 'style': 'text hook over one continuous clean take'}}


# ------------------------------------------------------------------ 4. progressive loop

def v4():
    shots = [
        {'src': take('n_boss_hud'), 't': 4.4, 'd': 2.8, 'note': 'Grim Reaper fight, crits 4.96 / 5.96'},
        {'src': take('n_gear2'), 't': 2.7, 'd': 6.0, 'note': 'defeat 2.96, the two drops in view, pickups 7.19 / 8.19'},
        {'src': take('n_merge'), 't': 1.9, 'd': 4.6, 'note': 'full panel: merges 2.23 / 2.93 / 3.63, Merge 57 spare copies 4.83'},
        {'src': take('n_evolve'), 't': 4.2, 'd': 3.6, 'note': 'Iron Sword -> Gold Sword'},
        {'src': take('n_prestige_fx'), 't': 1.65, 'd': 1.8, 'note': 'the final Prestige card selected 1.6, Keep 2.83'},
        {'src': take('n_prestige_clean'), 't': 4.05, 'd': 3.7, 'note': 'Change 71 celebration: Prestige committed 4.03, impact 5.9, resolve'},
        {'src': take('n_end'), 't': 0.6, 'd': 2.8, 'note': 'Spring II'},
        end_card(2.0),
    ]
    at = [0.0]
    for s in shots:
        at.append(at[-1] + s['d'])
    words = ['1  FIGHT', '2  LOOT', '3  MERGE', '4  EVOLVE']
    ov = [text(at[i] + 0.03, at[i + 1] - 0.08, [(w, GOLD)], cy=LOW, size=132, anim='slam') for i, w in enumerate(words)]
    ov.append(text(at[4] + 0.03, at[6] - 0.08, [('5  PRESTIGE', GOLD)], cy=LOW, size=132, anim='slam'))
    ov.append(text(at[6] + 0.03, at[7] - 0.08, ['COME BACK', ('STRONGER', GOLD)], cy=LOW - 30, size=116, anim='slam'))
    return {'shots': shots, 'overlays': ov, 'music': 42,
            'meta': {'title': 'The loop in five words', 'type': 'Progressive', 'style': 'numbered cue words cut to the matching action'}}


# ------------------------------------------------------------------ 5. split screen: level 1 vs level 238

def v5():
    half = (HERO[0], HERO[1] - 40, 1.25)
    shots = [
        {'d': 11.0, 'split': [{'src': take('n_day1c'), 't': 0.3, 'view': half}, {'src': take('n_endc'), 't': 0.3, 'view': half}],
         'note': 'HUD-free halves. Top: level 1, Wood Sword, Winter I; bottom: level 238, Obsidian Sword, three skills, Spring II'},
        {'src': take('n_endc'), 't': 9.3, 'd': 2.6, 'into': 'flash', 'note': 'Spring II, crit 9.73'},
        end_card(2.0),
    ]
    ov = [
        tag(0.0, 11.0, 'LEVEL 1 · WOOD SWORD', 216, size=58),
        tag(0.0, 11.0, 'LEVEL 238 · OBSIDIAN SWORD', 1036, color=GOLD, size=58),
        text(0.0, 2.2, ['SAME GAME.'], cy=960, size=140, anim='slam'),
        text(3.0, 6.6, ['9 damage · 100 HP'], cy=840, size=76),
        text(3.0, 6.6, [('646 damage · 9,099 HP', GOLD)], cy=1418, size=76),
        text(7.2, 10.9, ['Everything in between?', ('You farm it.', GOLD)], cy=960, size=88),
        text(11.2, 13.5, [('Your turn.', GOLD)], cy=UP, size=140, anim='slam'),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 22,
            'meta': {'title': 'Level 1 vs level 238', 'type': 'Informational', 'style': 'HUD-free split screen with a gold divider'}}


# ------------------------------------------------------------------ 6. satisfying, game sound

def v6():
    shots = [
        {'src': take('n_crit'), 't': 3.45, 'd': 1.8, 'note': 'crits 3.73 / 4.73'},
        {'src': take('n_merge'), 't': 1.9, 'd': 4.6, 'note': 'full panel: three single merges, then Merge 57 spare copies 4.83'},
        {'src': take('n_evolve'), 't': 4.1, 'd': 3.6, 'note': 'evolution: charge, burst, reveal'},
        {'src': take('n_supply'), 't': 0.8, 'd': 1.8, 'note': 'Coin Tonic burst and aura'},
        {'src': take('n_teleport'), 't': 3.9, 'd': 2.0, 'note': 'Confirm Teleport, violet portal'},
        {'src': take('n_prestige_clean'), 't': 4.05, 'd': 3.6, 'note': 'Prestige celebration with its own sound (Change 71)'},
        {'src': take('n_boss_clean'), 't': 2.6, 'd': 2.6, 'note': 'boss defeat moment'},
        end_card(1.6),
    ]
    return {'shots': shots, 'overlays': [], 'game_audio': True, 'music': 32, 'bed': 0.3,
            'meta': {'title': 'Sound on', 'type': 'No Text', 'style': 'effects montage on the game sound effects, the game music low underneath'}}


# ------------------------------------------------------------------ 7. offline rewards

def v7():
    c = LOW
    shots = [
        {'src': take('n_quick'), 't': 3.0, 'd': 2.6, 'dim': 0.5, 'note': 'hook over play'},
        {'src': take('n_offline'), 't': 0.5, 'd': 7.6, 'into': 'flash', 'note': 'full frame: the offline receipt after an 8 h absence (real settlement), Claim 5.23, the stats rise'},
        {'src': take('n_quick'), 't': 0.9, 'd': 6.0, 'view': (400, 420, 1.4), 'note': 'Auto Farm tile on the left rail (Change 72): red Off -> green On 1.63; framed on the rail and the fight'},
        end_card(2.0),
    ]
    ov = [
        text(0.0, 2.5, ['I closed the game', ('for 8 hours.', GOLD)], cy=c, size=104, anim='slam'),
        text(2.9, 7.1, ['This was waiting.'], cy=c, size=104),
        text(7.4, 10.1, [('+6.72K coins · 96 items', GOLD)], cy=c, size=78),
        text(10.4, 13.0, ['One tap:', ('AUTO FARM', GREEN)], cy=c, size=104),
        text(13.2, 16.1, ['It keeps farming.', ('You don’t have to.', GOLD)], cy=c, size=90),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 52,
            'meta': {'title': 'I closed the game for 8 hours', 'type': 'Bait / Hook', 'style': 'UI story at full width: receipt, claim, one-tap automation'}}


# ------------------------------------------------------------------ 8. curiosity: 31 swords

def v8():
    c = LOW
    shots = [
        {'src': take('n_evolve'), 't': 0.0, 'd': 10.2, 'note': 'full frame: Iron Sword x31 opened 0.83; Merge 20 spare copies 2.43; Evolve pressed 4.23; the evolution show; Gold Sword equipped 8.33, panel closed 9.63'},
        {'src': take('n_gear_fight'), 't': 0.8, 'd': 3.6, 'into': 'flash', 'note': 'the same outfit with a Gold Sword in a fight'},
        {'src': take('n_endc'), 't': 0.6, 'd': 3.0, 'note': 'Obsidian Sword, Spring II'},
        end_card(2.0),
    ]
    ov = [
        text(0.0, 2.55, ['What if you', ('merge 31 swords?', GOLD)], cy=c, size=96, anim='slam'),
        text(2.7, 4.4, ['20 go into the merge…'], cy=c, size=88),
        text(4.6, 6.2, ['…10 more evolve it.'], cy=c, size=88),
        text(8.0, 10.1, [('Equip the new one.', GOLD)], cy=c, size=92),
        text(10.4, 13.7, ['7 tiers.', ('Wood to Obsidian.', GOLD)], cy=c, size=108),
        text(14.0, 16.7, ['This is the last one.'], cy=c, size=92),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 92,
            'meta': {'title': 'What happens if you merge 31 swords?', 'type': 'Bait / Hook', 'style': 'curiosity question answered by one real UI sequence at full width'}}


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
            ov.append(text(beat(j) / F, beat(j + 1) / F, [LOOK_NAMES[key][i]], cy=1340, size=84, anim='none', plate=None, label=True))
            j += 1
    shots.append({'src': take('n_gear'), 't': 6.1, 'd': (beat(26) - beat(20)) / F, 'note': 'outfit equipped 6.39, sword 7.39'})
    shots.append({'src': take('n_gear_fight'), 't': 1.0, 'd': (beat(32) - beat(26)) / F, 'note': 'in a fight'})
    shots.append(end_card((450 - beat(32)) / F))
    ov += [
        text(0.0, beat(2) / F, ['48 ENEMIES.'], cy=400, size=130, anim='slam', plate=None, label=True),
        text(beat(2) / F, beat(4) / F, [('48 OUTFITS.', GOLD)], cy=400, size=130, anim='slam', plate=None, label=True),
        text(beat(20) / F + 0.05, beat(26) / F - 0.05, ['Beat it.', ('Wear it.', GOLD)], cy=400, size=128, plate=None),
        text(beat(26) / F + 0.05, beat(32) / F - 0.05, ['Which one first?'], cy=400, size=110, plate=None),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 112,
            'meta': {'title': '48 enemies, 48 outfits', 'type': 'Informational', 'style': 'one outfit per beat (145 BPM), four seasons interleaved; unchanged in revision 2 (reviewed as fine)'}}


# ------------------------------------------------------------------ 10. revenge arc

def v10():
    c = LOW
    shots = [
        {'src': take('n_rev_lose'), 't': 1.4, 'd': 4.6, 'note': 'the real loss: hero defeated 4.36'},
        {'src': take('n_rev_merge'), 't': 0.5, 'd': 6.9, 'into': 'flash', 'note': 'full frame: outfit opened 0.73, Merge 500 spare copies 1.93, Diamond Sword ^20 4.63, equipped 5.83, panel closed 7.23'},
        {'src': take('n_rev_win'), 't': 0.3, 'd': 6.2, 'into': 'flash', 'note': 'the real rematch: boss defeated 2.96 with 25 HP left'},
        end_card(2.0),
    ]
    ov = [
        text(0.0, 2.7, ['This boss', ('killed me.', RED)], cy=c, size=116, anim='slam'),
        text(3.0, 4.5, ['So I went farming.'], cy=c, size=96),
        text(4.8, 7.8, [('500 copies', GOLD), 'of one outfit.'], cy=c, size=100),
        text(8.1, 11.4, ['And a sharper sword.'], cy=c, size=92),
        text(11.6, 13.4, [('ROUND 2', GOLD)], cy=c, size=160, anim='slam'),
        text(15.2, 17.6, ['Won with', ('25 HP left.', GOLD)], cy=c, size=112),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 82,
            'meta': {'title': 'This boss killed me', 'type': 'Bait / Hook', 'style': 'three-act story: loss, upgrade at full width, rematch'}}


# ------------------------------------------------------------------ 11. Prestige celebration (Change 73, new)
# The rebuilt Prestige celebration (Change 71) on its own: the last card kept, the panel closes, the effect plays
# once at speed, then again at half speed so its four phases (reveal, spiral, impact, resolve) can be seen.

def v11():
    c = LOW
    shots = [
        {'src': take('n_prestige_fx'), 't': 1.65, 'd': 2.4, 'note': 'Prestige panel, the last of five cards: Veteran Traveler selected 1.6, Keep 2.83, confirm dialog'},
        {'src': take('n_prestige_clean'), 't': 4.05, 'd': 3.9, 'into': 'flash', 'note': 'Prestige committed 4.03: the celebration at speed'},
        {'src': take('n_prestige_clean'), 't': 4.05, 'd': 6.8, 'speed': 0.5, 'into': ('xfade', 8), 'view': (540, 1010, 1.25), 'note': 'the same 3.4 s at half speed, closer, framed below the game banner'},
        end_card(2.0),
    ]
    at = [0.0]
    for s_ in shots:
        at.append(at[-1] + s_['d'])
    at[3] -= 8 / F
    ov = [
        text(0.0, 2.3, ['I gave up', ('all my gear…', GOLD)], cy=c, size=112, anim='slam'),
        tag(at[2] - 0.0, at[3], 'REPLAY · ½ SPEED', 216, color=GOLD, size=56),
        text(at[2] + 4.2, at[3] - 0.1, ['5 cards.', ('Kept forever.', GOLD)], cy=c, size=112),
    ]
    return {'shots': shots, 'overlays': ov, 'music': 122,
            'meta': {'title': 'I gave up all my gear', 'type': 'Bait / Hook',
                     'style': 'one UI beat, the celebration at speed, then a half-speed replay closer in'}}


VIDEOS = {1: ('review_story', v1), 2: ('match_cut', v2), 3: ('gear_hook', v3), 4: ('loop', v4), 5: ('split_levels', v5),
          6: ('sound_on', v6), 7: ('offline', v7), 8: ('31_swords', v8), 9: ('lookbook', v9), 10: ('revenge', v10),
          11: ('prestige', v11)}


def output(n: int) -> Path:
    return OUT / f'LootFarmer_Social_{n:02d}_{VIDEOS[n][0]}.mp4'


def build(n: int) -> None:
    slug, make = VIDEOS[n]
    video = make()
    seconds = sum(round(float(s['d']) * F) - (int(s['into'][1]) if isinstance(s.get('into'), tuple) else 0) for s in video['shots']) / F
    video.update(id=f'{n:02d}_{slug}', duration=seconds)
    wav = WORK / f'{n:02d}_audio.wav'
    if video.get('game_audio'):
        parts = [(s['src'] if Path(s['src']) != END else None, float(s.get('t', 0)), float(s['d'])) for s in video['shots']]
        E.game_audio_track(wav, parts, seconds, bed=(E.music_in(video['music']), video['bed']))
        audio = {'kind': 'game sound effects of the takes over the game music', 'music_start': round(E.music_in(video['music']), 4), 'music_level': video['bed'], 'parts': [[str(p[0]), p[1], p[2]] for p in parts]}
    else:
        start = E.music_in(video['music'])
        gain = E.music_track(wav, start, seconds)
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
