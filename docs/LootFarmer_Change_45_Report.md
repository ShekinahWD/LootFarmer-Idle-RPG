# Change 45: Match-Cut V2 (moving camera, swords only)

**Output:** `store_assets/video/experiments/LootFarmer_MatchCut_Camera_V2.mp4` (local review master, not cleared for upload; REL-02 still applies). It is 15.10 s, 1080x1920, 30 fps, H.264 yuv420p, with one AAC music-only stream and no black frames (`review_v2/validation.json` ok).
**Review:** `store_assets/video/experiments/review_v2/` contains `transitions_full.png` and `transitions_phone.png` (frames cut-3..cut+2 for each join) and `strip_phone.png` (one frame every 0.5 s at phone size).
**Source:** `marketing/match_cut_v2/` (generator, manifest, review) plus the capture-only scripted camera in `marketing/game_scenarios.gd` (`options.cam`, Hermite keys for offset and zoom with velocities). The live game camera, saves, the trailer and V1 are unchanged.

| Shot | Take (raw `match_cut_v2/`) | Encounter | Sword / outfit | Window (take frames) |
|---|---|---|---|---|
| Winter II | v2_winter (trailer_farm, seed 4501) | Reindeer pack (normal enemies) | Wood Sword / Snowman | 7-66 |
| Summer II | v2_summer (match_boss, 4402) | Teal Dinosaur | Iron Sword / Elephant T2 | 43-132 |
| Autumn II | v2_autumn (match_boss, 4403) | Grim Reaper; summon warning 1.19 s, **2 Horned Hoods 1.79 s** (output ≈ 5.77 s / 6.36 s), Fire 2.29 s | Gold Sword / Red Fox T3 | 13-102 |
| Spring II | v2_spring (match_boss, 4404) | Red Panda; Lightning, Fire, Arcane Strike | Emerald Sword / Sunflower T5 | 13-138 |
| End card | trailer_c32/end_card.mkv | | | 0-3.3 s, 0.4 s fade |

## Joins

All cuts are hard cuts. Each one leaves on a wind-up and enters on the first arc frame of a real hit. The camera's offset, zoom and velocity are identical on both sides of every cut.

| Cut (output frame) | Move | At the cut |
|---|---|---|
| 60 Winter→Summer | Horizontal track right | 28 world px/s, about 320 screen px/s at zoom 3.8. Eases in over 0.6 s, settles 0.5 s into Summer. |
| 150 Summer→Autumn | Push-in toward the clash | Zoom 3.8→4.7 over 0.55 s, rising 2.6/s at the cut, plus a 26 px/s upward tilt. Peaks at 5.0, then pulls back to 3.4 by about 1.5 s to show the Reaper and its summons. |
| 240 Autumn→Spring | Diagonal track up-right with slight pullback | 22/−22 world px/s, zoom easing at −0.9/s. Settles at 3.7, then a slow push to 4.1 over the Spring hold. |

**Audio:** `assets/sounds/background_music.wav` from 60 s (the same in-point as V1), one continuous passage with a 1.5 s fade at the end only. Game audio is stripped.

**Compared with V1:** the story, seeds and boss takes are the same, so the simulation and hit times are identical. Winter was recaptured with a Wood Sword in place of V1's Stone Axe. V1 cuts on a locked camera; V2 cuts mid-move.

**Compromises:** the Winter hero swings at the pack to its side, while the boss shots swing upward. The phase matches but the direction does not exactly. Spring II's Red Panda was used as specified. The Green Alien never appears.
