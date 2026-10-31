# Change 47: Match-Cut V4 (cinematic zoom refinement)

**Output:** `store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V4.mp4`. This is a local review master and is not cleared for upload (REL-02 still applies). It runs 15.10 s (453 frames) at 1080x1920 and 30 fps, H.264 yuv420p, with one AAC music-only stream and no black frames. All checks in `review_v4/validation.json` pass. The trailer, V1, V2 and V3 hash the same as before.

**Review files:** `store_assets/video/experiments/review_v4/`
- `compare_v3_v4_cut1..3.png`: V3 on top, V4 below, at the same output frames (cut −9, −6, −3, −1, 0, +1, +3, +6, +9).
- `transitions_full.png` / `transitions_phone.png`: the ramp, the frames around each cut and the settle.
- `strip_phone.png`: one frame every 0.5 s.
- `shots_phone.png`: the first, middle and last frame of each shot.
- `speed_applied.json`, `validation.json`, `protected_sha256.json`.

**Source:** `marketing/match_cut_v4/` (manifest generator, `speed.json`, speed pass, review). The adapter, live game, HUD rules, content, music and end card are unchanged from V3.

```
python marketing/match_cut_v4/make_match_v4_manifest.py
python Godot-Marketing-Toolkit/tools/marketing.py record --project . --manifest marketing/match_cut_v4/manifest.json --job v4_<shot> --godot $G --overwrite   # winter summer autumn spring
python Godot-Marketing-Toolkit/tools/marketing.py video --manifest marketing/match_cut_v4/manifest.json --locales en-US --overwrite
python marketing/match_cut_v4/add_speed_blur.py
python marketing/match_cut_v4/review_match_cut_v4.py
```

## Takes

The four takes were re-recorded as `store_assets/raw/video/match_cut_v4/v4_*.avi`. The camera is baked into each capture, so the new zoom required new takes. They use V3's seeds, staging and shot windows, so gameplay is identical: the hit and summon logs match V3 exactly (same md5).
- The Grim Reaper's real summon warning comes at take 1.19 s. The two Horned Hoods appear at take 1.79 s (output 6.36 s).
- Sword and outfit pairs are unchanged: Wood/Snowman, Iron/Elephant T2, Gold/Red Fox T3, Emerald/Sunflower T5.

## What changed

1. **Hero-size match, not zoom match.** The outfits are different sprites: Snowman 15x19 px, Elephant 16x16, Red Fox 16x18, Sunflower 17x20. V3 matched the raw zoom, so the hero shrank about 25% at Winter→Summer. V4 now scales the zoom across each cut by the outfit-size ratio (the mean of height and √area). At Autumn→Spring it applies 65% of that ratio, so the remaining growth goes the same way as the IN rush.
2. **Anchor.** Each shot's camera height above the hero (DY: 45 / 40.1 / 48.6 / 51.7 world px) is solved so the hero's feet sit on the same screen row on both sides of each cut.
3. **Kinetics.** Each rush is a cubic ease-in over 0.33 s that reaches its peak speed at the cut. A cubic ease-out then settles over 0.2–0.45 s. Speed is never zero at a cut and never reverses.
4. **Framing.**
   - Winter opens at 2.45 (V3: 2.05).
   - Summer settles at 3.8–3.85 (V3: 3.3).
   - Autumn's reveal is 2.15, wide enough for the Reaper and both Hoods (V3: 2.25).
   - Spring settles at 3.35–3.45.
5. **Speed blur.** It is stronger: 11 taps, up to 8% spread, starting at a relative zoom speed of 0.75/s and full strength at 1.35/s. It now covers about 5–9 frames per cut. Combat is protected by a tall ellipse (300x540 px) around the zoom centre. V3 used a 230 px circle, which partly smeared the hero. Only the world edges streak; the dock is never touched.

## Cuts (output frames; plan values, checked visually)

| Cut | Dir | Zoom out → in | Relative speed out / in (1/s) | V3 speed | Hero size change | Feet row out → in |
|---|---|---|---|---|---|---|
| 60 (2.00 s) Winter→Summer | IN | 2.86 → 3.36 | +1.28 / +1.51 | +0.89 / +0.95 | +4.8% (one frame of travel ≈ 4.2%) | 1007 → 1025 px |
| 150 (5.00 s) Summer→Autumn | OUT | 3.35 → 2.93 | −1.41 / −1.85 | −0.76 / −0.86 | −5.3% (≈ −4.9%) | 1027 → 1005 |
| 240 (8.00 s) Autumn→Spring | IN | 2.66 → 2.63 | +1.67 / +1.95 | +0.89 / +1.04 | +9.8% (≈ +5.6%) | 963 → 987 |

**Measured on the full-resolution frames:**
- Cuts 1 and 2: the hero is about 150 px tall on both sides.
- Cut 3: the hero grows from about 125 to 140 px.
- Feet move by 25 px or less, which is about 2% of the map height.

**Travel over each rush:** about 57% world zoom at cut 1 (2.45→3.85), 79% at cut 2 (3.85→2.15) and 60% at cut 3 (2.2→3.45). In each case most of the travel happens in about 0.6 s.

## Compromises

- **Cut 3:** the hero still grows about 4% more than one frame of motion. Matching the size exactly would have made the background zoom out against the IN rush.
- **Summer close-up:** at 3.85 the overhead damage number and the banner above the Teal Dinosaur's name are clipped at the top edge. The name and HP bar stay readable.
- **Hero height on screen:** the dock limits the close zoom, so the hero sits in the lower third of the map. That leaves room for the boss stack.
- **Fit of the zoom curve:** the curve is tuned to the hit timing, not to the music's beat.
- **Review limits:** I checked the frames one by one and at phone-size sampling. I could not watch the video at normal speed, so the developer should watch it once at normal speed before approving it.
- **Cut 1 speed:** it is the slowest cut (+1.3–1.5/s), because Winter must stay wide enough to show the pack.
