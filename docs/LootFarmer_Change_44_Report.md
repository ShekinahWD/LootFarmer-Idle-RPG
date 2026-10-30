# Change 44: Four-season action match-cut experiment (local review master)

**Video:** `store_assets/video/experiments/LootFarmer_MatchCut_15s_v1_en-US.mp4` (ignored by Git).
15.133 s, 454 frames, 1080x1920, 30 fps, H.264 yuv420p + one AAC 48 kHz stream (music only).
Review: `store_assets/video/experiments/review_v1/transitions_full.png`, `transitions_phone.png`, `validation.json`
(all checks pass). The approved trailer, its manifest and generator are untouched.

## Pipeline
`marketing/match_cut/make_match_manifest.py` -> `manifest.json` (Toolkit 1.0.2), takes recorded with
`marketing.py record --job m_summer|m_autumn|m_spring`, composed with `marketing.py video`, checked with
`marketing/match_cut/review_match_cut.py`. One new capture-only adapter scenario, `match_boss`
(`marketing/game_scenarios.gd`): staged profile, player 30 px below the boss, boss aggroed, real fight; it logs
every hit, summon warning, summon and player skill. No game code, balance, save or export change.

## Cut (output frames, 30 fps)
| Out frames | Shot | Source (frames) | Hero | Opponent |
|---|---|---|---|---|
| 0-60 | Winter II | `c33_winter.avi` 6-66 (reused) | Snowman outfit + Stone Axe, Lv 45 | Reindeer Antlers pack (normal) |
| 61-150 | Summer II, rain | `m_summer.avi` 43-132 | Elephant outfit t2 + Iron Sword, Lv 200 | Teal Dinosaur |
| 151-240 | Autumn II, leaves | `m_autumn.avi` 13-102 | Red Fox outfit t3 + Gold Sword + Fire, Lv 700 | Grim Reaper + 2 summoned Horned Hoods |
| 241-366 | Spring II | `m_spring.avi` 13-138 | Sunflower outfit t5 ^500 + Emerald Sword + Lightning/Fire/Arcane Strike, Lv 238 | Red Panda |
| 355-453 | end card | `end_card.mkv` (0.4 s dip) | | |

**Cut rule:** every outgoing shot ends on the hero's wind-up frame; every incoming shot opens on the first
frame of its own real impact arc (logged hits at 1.42 s / 0.42 s / 0.42 s), so one swing lands across each cut.
Hard cuts at frames 61, 151, 241; no crossfades, slides or synthetic effects. All three boss takes share zoom 3.8,
the follow camera, boss straight above and hero facing right, so Summer->Autumn->Spring match on position, size,
facing and swing phase.

**Real summon evidence (`m_autumn.avi.log`):** `SUMMON_WARNING` 1.19 s, `SUMMON g33_v2_0 helpers=2` 1.79 s (output
~1.79 s into the Autumn shot = frame ~192); the summon timer was moved forward (`summon_in` 1.5), the call is the game's own.
Damage on both helpers is logged at 2.29 s (player Fire).

## Audio
`assets/sounds/background_music.wav` only, from 60.00 s, volume 0.85, 30 ms in / 1.5 s out fades. `game_audio` false
(every segment `-an`); ffprobe: exactly 2 streams (H.264 + AAC).

## Compromises
- Winter->Summer is the weakest cut: the reused Winter take frames the hero ~35 px higher among a surrounding
  pack and the Snowman faces left; the swing phase (wind-up -> impact) still matches. A re-recorded Winter
  take with the pack straight above would tighten it.
- Clean takes still show the boss HP bar at the top of the three boss shots (Winter has none); real game UI.
- Pacing: Winter 2.03 s and Spring 4.2 s (vs guide 2.2 / 3.4) so each cut sits on a real swing.
- Publication gate unchanged: REL-02 audio/art licence records still open; not cleared for upload.
