# Change 46: Match-Cut V3 (zoom rush transitions, swords only)

**Output:** `store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V3.mp4`. This is a local review master and is not cleared for upload (REL-02 still applies). It runs 15.10 s (453 frames) at 1080x1920 and 30 fps, H.264 yuv420p, with one AAC music-only stream and no black frames. All checks in `review_v3/validation.json` pass.

**Review:** `store_assets/video/experiments/review_v3/` holds three sheets and two logs:
- `transitions_full.png`: per cut, the ramp, the 3 frames on each side of the cut and the settle, map area only.
- `transitions_phone.png`: the same frames, whole portrait, at phone size.
- `strip_phone.png`: one frame every 0.5 s.
- `speed_applied.json`: which frames were blurred and how strongly.
- `protected_sha256.json`: hashes of the older deliverables, used to confirm they are unchanged.

**Source:** `marketing/match_cut_v3/` (manifest generator, `speed.json`, speed pass, review). The adapter `marketing/game_scenarios.gd` gains `hud: "match"`, `numbers_gap` and `pack` (all capture-only). The live game, saves, balance, the trailer, V1 and V2 are unchanged.

```
python marketing/match_cut_v3/make_match_v3_manifest.py
python Godot-Marketing-Toolkit/tools/marketing.py record --project . --manifest marketing/match_cut_v3/manifest.json --job v3_<shot> --godot $G --overwrite   # winter summer autumn spring
python Godot-Marketing-Toolkit/tools/marketing.py video --manifest marketing/match_cut_v3/manifest.json --locales en-US --overwrite
python marketing/match_cut_v3/add_speed_blur.py
python marketing/match_cut_v3/review_match_cut_v3.py
```

| Shot | Take (raw `match_cut_v3/`, all `match_boss`) | Encounter | Sword / outfit | Take frames | Output frames |
|---|---|---|---|---|---|
| Winter II | v3_winter (seed 4501, `pack`) | Reindeer Antlers pack; target g7_v0_3 straight above the hero | Wood / Snowman | 13-72 | 0-59 |
| Summer II | v3_summer (4402) | Teal Dinosaur, rain | Iron / Elephant T2 | 43-132 | 60-149 |
| Autumn II | v3_autumn (4403) | Grim Reaper: real summon warning at take 1.19 s, **2 Horned Hoods at 1.79 s** (output 5.76 s / 6.36 s), Fire at 2.29 s | Gold / Red Fox T3 | 13-102 | 150-239 |
| Spring II | v3_spring (4404) | Red Panda: Lightning at 0.69 s, Fire at 1.89 s, Arcane Strike at 2.89 s | Emerald / Sunflower T5 | 13-138 | 240-365 |
| End card | trailer_c32/end_card.mkv | | | 0-3.3 s, 0.4 s fade | 366-452 |

## Camera and cuts

- **Zoom only, no sideways travel.** The camera holds a fixed offset straight above the hero's feet, at the midpoint of the hero and their opponent: 47 world px for Winter and Summer, 52 for Autumn and Spring. Those two shots have equipped skills, so the skill row makes the map 84 px shorter. The extra 5 px keeps the hero on the same screen row through the Summer→Autumn cut.
- **Zoom curve.** Zoom follows Hermite keys (game zoom: 1.0 = the default play zoom ×1; screen scale is 3× that). Each rush ramps up over 0.45 s, crosses the cut at full speed and eases out over about 0.4 s.
- **Cut timing.** Every cut leaves on a sword wind-up and enters on the first slash frame of a real hit. The hero faces right on both sides of every cut, with the target straight above.

| Cut (output frame) | Direction | Zoom out → in | Relative speed (1/s) | Settles at |
|---|---|---|---|---|
| 60 Winter→Summer | IN | 2.67 → 2.75 | +0.89 / +0.95 | 3.3 close (Winter opens at 2.05, wide on the pack) |
| 150 Summer→Autumn | OUT | 2.88 → 2.80 | −0.76 / −0.86 | 2.25 reveal (Reaper plus both Horned Hoods in frame) |
| 240 Autumn→Spring | IN | 2.61 → 2.70 | +0.89 / +1.04 | 3.1, then a slow push to 3.25 to the end card |

The zoom step across each cut equals one frame of travel at the shared speed, so there is no scale jump.

**Winter direction fix.** In V2 the target stood to the hero's side. Winter now uses `match_boss` on an ordinary Reindeer Antlers with `pack`, which places the hero below the pack's lowest member. That member becomes the hero's nearest enemy and first target, straight above as in the boss shots.

**Speed effect.** `add_speed_blur.py` applies a radial blur of 7 slightly magnified ghosts, at most 4.5% spread. It covers the map area only and is centered on the camera center (the combat pair). It is masked off inside 230 px of that center, so the hero, sword and boss stay crisp and the ground carries the speed. Strength follows the relative zoom speed: it starts at 0.7/s and is full at 1.0/s.
- Frames 57-62, 149-152 and 238-241 are blurred (about 0.13-0.2 s each).
- The pass re-encodes at CRF 16 and copies the music stream unchanged.

## HUD (capture-only, `hud: "match"`)

| Element | Status |
|---|---|
| Player HP (Top meter and the bar over the hero) | Hidden |
| Map overlays (joystick, minimap, trackers, side buttons) and toasts | Hidden |
| Top XP/coins row, skill row, compact gear/supply dock | Visible; the dock's equipped slots show each sword/outfit upgrade |
| Enemy and boss HP bars and names | Visible, real values |

**Damage numbers** are thinned: none over the hero, and at most one every 1.5 s over enemies. Display only; damage is unchanged.

**Audio:** `assets/sounds/background_music.wav` from 60 s, as in V1 and V2. One continuous passage with a 1.5 s fade at the end only. Game audio is stripped.

## Compromises

- Zoom peaks follow real hit timing rather than a beat analysis of the music.
- A damage number or the boss summon/skill icons can sit over the boss name for a moment, because they are the game's own overhead stack.
- The close-ups stay at or below 3.3. Higher zooms pushed the hero against the dock, because the visible dock leaves about 1160-1240 px of map.
- Winter's pack is small on screen at the opening wide zoom (2.05).
- A reindeer's real "Hey! My outfit!" speech bubble shows during Winter.
- The Green Alien never appears.
