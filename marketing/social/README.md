# LootFarmer social videos (Changes 70, 73)

The LootFarmer implementation of the Playbook's social-video workflow (section 133: 133.5 format, 133.6 posting
copy, 133.9 message types, 133.10 craft, 133.11 runbook, 133.12 techniques, 133.13 tooling). The Playbook holds the
reusable method; this file holds what is specific to this game: the set, the adapter, the commands, the paths and
the open items. Nothing here ships (`marketing/*` is in the Release preset's `exclude_filter`; `store_assets/` is
ignored by Git and Godot) and nothing has been uploaded.

## Status (13 Nov 2026)

- **Eleven masters**, 1080x1920, 30 fps, H.264 High yuv420p (TV range) + AAC 48 kHz stereo, faststart, 14.8 to
  36.1 s: `store_assets/video/social/LootFarmer_Social_NN_<slug>.mp4`. Timelines in `timelines/`, review sheets,
  `overview.png` and `validation.json` in `review/` beside them. Posting copy: [posting_copy.md](posting_copy.md).
- All takes recorded on `83e5492` (Change 73). `review_social.py`: 11/11 pass, 35 approved store media unchanged.
- **Developer review:** the first set (Change 70) was revised once after review (revision 2, approved). Revision 3
  (Change 73) has passed the automated half only; the viewing half (normal speed, sound, phone) is the developer's.
- **Already behind the game:** Change 74 (6351d85) enlarged the HUD by 30% and removed the fight-form chips that the
  HUD shots show; Change 75 reshaped the Next Stage chip and the zoom slider. Every shot with the HUD (videos 1, 4,
  6, 7, 8, 10, 11's first shot) shows the Change 72 HUD. A refresh is a re-record of all takes plus one build (see
  "Revising"), and video 1's caption "Now you see it all." should be re-checked against the Change 74 HUD.
- **Rights (REL-02, open):** no licence or purchase record exists for `assets/sounds` (the music) or the Pixel
  Plains art. These are local review masters, not cleared for upload (Playbook 49).

## The set

| # | Slug | Message type (133.9) | Idea and editing style | Main takes |
|---|---|---|---|---|
| 01 | `review_story` | Bait / Hook | Devlog: a player's 4/10 review (dated old-build footage), the fix, then a few visual improvements (HUD before/now, sorting, bulk shop, Prestige celebration), not a changelog | `before/o_pack`, `n_pack_after`, `before/o_hud_fight`, `n_hud_fight`, `n_sort`, `n_shop`, `n_prestige_fx`, `n_prestige_clean`, `n_endc` |
| 02 | `match_cut` | No Text | Four seasons, four critical hits: a match cut on real crit frames with a punch-in at each cut, ending on a defeat | `c_winter`, `c_summer`, `n_crit`, `c_spring` |
| 03 | `gear_hook` | Bait / Hook | "I beat a dinosaur…": one continuous clean take of defeat, drops on the ground, pickups, push-in, equips | `n_gear2`, `n_gear_fight` |
| 04 | `loop` | Progressive | Numbered cue words (FIGHT, LOOT, MERGE, EVOLVE, PRESTIGE) each on its action | `n_boss_hud`, `n_gear2`, `n_merge`, `n_evolve`, `n_prestige_fx`, `n_prestige_clean`, `n_end` |
| 05 | `split_levels` | Informational | Level 1 vs level 238: HUD-free halves with a gold divider and fixed labels | `n_day1c`, `n_endc` |
| 06 | `sound_on` | No Text | Effects montage on the takes' own game sound with the music low underneath | `n_crit`, `n_merge`, `n_evolve`, `n_supply`, `n_teleport`, `n_prestige_clean`, `n_boss_clean` |
| 07 | `offline` | Bait / Hook | "I closed the game for 8 hours": the offline receipt at full width, Claim, the Auto Farm tile | `n_quick`, `n_offline` |
| 08 | `31_swords` | Bait / Hook | Curiosity question answered by one real UI sequence (merge 20, evolve) | `n_evolve`, `n_gear_fight`, `n_endc` |
| 09 | `lookbook` | Informational | One outfit per beat (145 BPM), four seasons interleaved, name labels | `n_look_w/s/a/p`, `n_gear`, `n_gear_fight` |
| 10 | `revenge` | Bait / Hook | Three acts: the real loss, the upgrade at full width, the real rematch (25 HP left) | `n_rev_lose`, `n_rev_merge`, `n_rev_win` |
| 11 | `prestige` | Bait / Hook | Added in Change 73 for the rebuilt Prestige celebration: the last card kept, the celebration at speed, then a half-speed replay closer in | `n_prestige_fx`, `n_prestige_clean` |

Every caption, in-point and music in-point is in `build_social.py` (one function per video); every take's options
are in `make_social_manifest.py`. Figures in captions come from the take logs: offline receipt +6,720 Coins and
96 items (`n_offline`), rematch won with 25 HP left (`n_rev_win`), 9 vs 646 damage (`soc` stat lines of
`n_day1c`/`n_endc`), five Prestige cards granted (`MILESTONE prestiged` in `n_prestige_clean`), dates and the
one-week span from Git (`3dd2eab` 6 Nov to `83e5492` 13 Nov).

## Files

| Path | Tracked | What |
|---|---|---|
| `social_scenarios.gd` | yes | Adapter. Extends `../game_scenarios.gd` (the store adapter) and adds one data-driven scenario, `soc`. Also adds timed `steps` to the store adapter's own scenarios (used with `shot_prestige`). |
| `make_social_manifest.py` | yes | Writes `manifest.json` (41 jobs at 1080x1920), `--draft` -> `manifest_draft.json` (540x960, output in `draft/`), `--before` -> `manifest_before.json` (the "before" jobs, output in `before/`). `SOC_PROBE=1` adds balance probes. |
| `record_takes.py` | yes | Records jobs one after another with the toolkit (`marketing.py record`), prints each take's event summary, writes a contact sheet per take in `sheets/`. `--draft`, `--manifest`, `--project` (record from another checkout). |
| `social_engine.py` | yes | Project-side frame compositor (Playbook 133.13): decode, crop/push, split, cut/flash/crossfade, speed, captions with plates and the safe-area guard, music section or game-sound mix, one H.264 encode. |
| `build_social.py` | yes | The storyboards (`v1`..`v11`, table `VIDEOS`) and the build: audio, render, timeline JSON. |
| `review_social.py` | yes | Validation (`review/validation.json`, non-zero exit on a failed contract), per-video sheets, `overview.png`, `overview_first_frames.png`, the approved-media hash check. |
| `posting_copy.md` | yes | One caption + hashtags block per video. |
| `store_assets/raw/video/social/*.avi` (+ `.avi.log`) | no | Raw takes (Movie Maker MJPEG + PCM) and their event logs. `sheets/` contact sheets, `draft/` 540x960 staging takes. |
| `store_assets/raw/video/social/before/` | no | Dated "before" takes recorded from older commits: `o_pack`, `o_teleport` (3dd2eab, 6 Nov), `o_hud_fight` (3856390, 12 Nov). |
| `store_assets/raw/video/social/rev2/`, `store_assets/video/social/rev2/` | no | Revision-2 takes, logs, masters, timelines and review (kept when revision 3 replaced them). |
| `store_assets/raw/video/social/approved_hashes_before.txt` | no | SHA-256 of 35 approved store media (trailer, 8 match-cut experiments, 24 screenshots, feature graphic, Play icon); `review_social.py` checks them unchanged. |
| `store_assets/raw/video/social/work/` | no | Intermediate audio WAVs of the last build. |
| `store_assets/raw/video/trailer_c32/end_card.mkv`, `c33_gear.avi` | no | The approved brand end card (lossless) and a 28 Oct take used once as "before". |

## Setup (Windows 10, validated 13 Nov 2026)

- Godot 4.7.2 console: `D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe` (path
  constant `GODOT` in `record_takes.py`).
- Godot Marketing Capture Toolkit 1.0.2 in `Godot-Marketing-Toolkit/`, pinned by `marketing_capture_toolkit.lock.json`;
  `python Godot-Marketing-Toolkit/tools/marketing.py status --project .` must pass.
- Python 3.12 with numpy (2.1) and Pillow (12.3); FFmpeg and ffprobe 8.0.1 on `PATH`.
- Font: `assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf` (the game's title face); music:
  `assets/sounds/background_music.wav` (145 BPM; downbeats at 0.42 s + k x 0.8276 s).
- `record_takes.py` sets `PYTHONUTF8=1` for the toolkit (it crashes on non-cp1252 log characters otherwise).
- The monitor is 1080 px tall: Movie Maker still records 1080x1920 because the toolkit sets the window size through
  a temporary `override.cfg`. One capture at a time per project.

## Commands (project root, PowerShell or Git Bash)

```powershell
python marketing/social/make_social_manifest.py                  # manifest.json (and --draft, --before)
python marketing/social/record_takes.py --draft n_sort n_shop    # 540x960 staging check of chosen takes
python marketing/social/record_takes.py n_sort n_shop            # full-size takes (about 1.3 min each)
python marketing/social/record_takes.py                          # every job in the manifest (41; record only those the set uses)
python marketing/social/build_social.py 1 11                     # build chosen videos (about 20 s each); no argument = all
python marketing/social/review_social.py                         # validate all + sheets (a few minutes)
```

Recording runs in the order of the manifest, not the order of the ids given. Run long recordings and the full
build in the background; an interrupted build leaves a truncated MP4 with the right name ("moov atom not found"),
so rebuild that number and always validate after a build.

**"Before" footage from an older commit** (Playbook 133.10 point 7):

```bash
SP=<scratch folder outside the repository>
git worktree add --detach "$SP/before_3856390" 3856390
cp marketing/social/social_scenarios.gd "$SP/before_3856390/marketing/social/"   # only when the old adapter lacks a step the job needs
"$GODOT" --headless --import --path "$SP/before_3856390"                         # a few minutes
python marketing/social/make_social_manifest.py --before                          # jobs from BEFORE = {'o_hud_fight': 'n_hud_fight'}
python marketing/social/record_takes.py --manifest marketing/social/manifest_before.json --project "$SP/before_3856390" o_hud_fight
git worktree remove --force "$SP/before_3856390"; git worktree prune
```

The copied adapter is marketing code only; the game code that renders the "before" is the old commit's.

## The `soc` scenario (adapter reference)

A take is `soc(id, seconds, **options)` in `make_social_manifest.py`; other scenario ids are passed to the store
adapter (`take(id, seconds, scenario, options)`).

| Group | Options |
|---|---|
| Profile | `stage`, `level`, `items` (`[[id, merge]]`), `wear`, `seed`, `base: "late"` (store late-game profile), `upgrades` (`{key: level}`), `extra` (spare copies, `[[id, n]]`), `supply_capacity`, `coins`, `gems`, `skills`, `camps`, `camps_by_stage`, `boss_history`, `challenges`, `known_opportunities`, `follow` (`[["opportunity"], ["mission"], ["mastery", stage, category]]`), `hp`, `full_hp`, `inventory_zoom` |
| Placement | `boss` (+ `pack`, `dx`, `dy`, `aggro`, `summon_in`), `near` (a normal spot), `pos`, `explored`, `farm` / `auto_collect` (Coin upgrades for the spot) |
| Staging | `skill_at` (`{skill: seconds}`), `fight_until` (boss HP fraction, real 0.05 s steps; `fight_limit`), `player_hp_until`, `boss_skill_in` (boss skills held on a real cooldown), `advance`, `farm_drops` (`farm_limit`), `seed_search` + `want_drops` (+ `want_exact`) |
| Camera and view | `zoom`, `clean` (HUD hidden, camera may pass the 3x slider limit), `hud: "match"`, `cam` (Hermite camera keys, match cut V2-V4), `watch` |
| Timeline | `steps` (`[[seconds, step, args...]]`), `after_defeat` (seconds after the boss defeat) |

Steps (each calls what the player's tap calls): `equip`, `equip_btn`, `collect` (`id` or `next`), `collect_all`,
`tap_gear`, `open`, `item`, `close`, `merge`, `merge_copies`, `evolve`, `evo_continue`, `supply`, `zoom`
(`to`, `seconds`), `teleport_open`, `teleport_stage`, `teleport_pick`, `teleport_go`, `travel`, `focus`, `quick`,
`offline` (hours), `claim_offline`, `aggro`, `place`, `hud_off`, `guide`, `tap` (any guide tag, pinned rows
included), `tab` / `tab_key` (a panel tab by index or translation key), `upgrades_tab`, `scroll`, `scroll_to`
(guide tag, offset), `pick_card`, `confirm` (the shared Confirm dialog), `follow`, `log`.

Every `soc` take starts from `sim.new_profile()` in the isolated `capture-store` profile with `--no-autosave`, and
resets the saved inventory view, slot size and shop quantity (SettingsState preferences survive between takes
otherwise). Its log lines start with `LOOTFARMER_MARKETING`: `HIT <id> <amount> crit=<bool> t=<s>`,
`BOSS_DEFEATED`, `COLLECTED`, `MERGED`, `EVOLVED`, `SUPPLY`, `TRAVELED`, `MILESTONE <kind> <id>`, `PRESS <what>`,
`PRESS MISSING` (a step that found no enabled button: the take is wrong), `SEARCH seed ... ok=`.

**Balance probes.** `SOC_PROBE=1 python marketing/social/make_social_manifest.py` adds jobs that run a fight to its
end; record them to choose loadouts that win (or lose) honestly within the current caps (evolvable weapons ^20,
outfits ^500; hero levels above a map's bosses are those of a player who used Prestige, which keeps the level).
Probed: level 400 with Gold Sword ^20 and an unmerged Red Fox outfit loses to the Grim Reaper; with the outfit at
^500 and a Diamond Sword ^20 it wins with 25 HP left. Never the final Green Alien boss.

## Storyboards (`build_social.py`)

A video is a function returning `{'shots', 'overlays', 'music', 'meta'}`:

- **Shot:** `src` (a take, `OLD / 'x.avi'`, or `END`), `t` (source seconds), `d` (output seconds), optional
  `view` / `view2` (`(cx, cy, zoom)` crop window and its end for a slow push; `MAP` frames the map of a HUD take),
  `speed` (0.5 = half speed by frame repetition), `dim`, `into` (`'cut'`, `'flash'`, `('xfade', frames)`),
  `split` (two shot specs stacked with the gold divider), `note` (the logged event times this shot relies on).
- **Caption values** (the standard is Playbook 133.14; these are where LootFarmer sets them): safe box `SAFE`, plate
  `PLATE` and the 770 px line width in `social_engine.py`; the two bands `UP`/`LOW` in `build_social.py`; the 1.4 s
  and 14 characters-per-second rule in `review_social.py` (`check`).
- **Overlay:** `text(t0, t1, lines, cy=UP|LOW, size, anim)` for captions (dark plate, kept in the safe box) and
  `tag(t0, t1, label, cy, color)` for fixed corner labels; `label=True` exempts a name label from the reading-time
  rule. One caption position per video (`UP` 330 or `LOW` 1345).
- **Audio:** `music: k` starts the track at its k-th two-beat downbeat (`social_engine.music_in`); `game_audio:
  True` with `bed` mixes the takes' sound over the music at that level (video 6).
- `end_card(seconds)` closes every video on the approved brand card.

## Revising

1. Copy, timing, order or music in-point: edit `build_social.py`, build the numbers changed, review.
2. Gameplay or interface changed: archive the current takes and masters (`rev<N>/` folders), re-record **every**
   take the set uses on the current build, build all, review. Fixed seeds and the deterministic simulation replay
   the same fights on the same frames, so in-points normally survive; check each video's `note` events against the
   new logs (`grep -E "BOSS_DEFEATED|crit=true|COLLECTED|PRESS" <take>.avi.log`) and re-check every figure in a
   caption.
3. New or changed take: stage it at 540x960 first (`--draft`), read its log and sheet, then record full size.
4. Known traps: a panel reflows when a Prestige card is selected (start after 1.6 s); the clean Prestige take shows
   the old map until the commit frame (4.03 s); `keep_card` opens the Confirm dialog (`confirm` step); saved
   preferences leak between takes (handled in the adapter).

## History

- **Change 70** (11 Nov, ce65496): ten 15 s masters from fresh takes of `cece9c8`.
- **Revision 2** (12 Nov, 3ba267f, developer review, approved): captions too fast and lost in the picture, cropped
  panels, video 2 a copy of the old match cut, video 3's loot hidden by a boss skill, video 5 too busy. Fixes:
  panels at full width, one caption position per video on a dark plate, the reading-time rule in the validator,
  a crit match cut, `boss_skill_in` + `want_exact` for clean drops, HUD-free split halves; the 15 s cap removed.
- **Revision 3 / Change 73** (13 Nov, adaf2c5): all takes re-recorded on `83e5492` after Changes 71 and 72; video 1
  rebuilt around a few visual improvements, videos 4 and 6 gain the Prestige celebration, video 7 frames the Auto
  Farm tile, video 11 added; adapter steps for the new interface.
