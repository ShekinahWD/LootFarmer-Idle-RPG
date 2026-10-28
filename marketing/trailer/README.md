# LootFarmer Google Play trailer (Change 32)

The 30 s portrait store trailer: three black title cards, five genuine gameplay takes and the approved
feature graphic restaged as an animated portrait end card, under the developer's own
`assets/sounds/background_music.wav` and nothing else. Built with the pinned **Godot Marketing Capture
Toolkit 1.0.2** (`Godot-Marketing-Toolkit/`, lock `marketing_capture_toolkit.lock.json`). Nothing here ships:
`marketing/*` is in the Release preset's `exclude_filter` and `store_assets/` is ignored by Git and Godot.

Finished video: **`store_assets/video/LootFarmer_Play_Trailer_en-US.mp4`** (1080x1920, 30 fps, 30.000 s,
H.264 High yuv420p, AAC 48 kHz stereo, faststart). The rejected Change 27 cut is kept beside it in
`store_assets/video/rejected_change_27/` for comparison.

## Files

| Path | Tracked | What |
|---|---|---|
| `make_trailer_manifest.py` -> `manifest.json` | yes | Takes (scenario + options + length), title-card copy, the cut (shot order, in-points, transitions), music settings. Edit the tables, re-run. `--draft` writes `manifest_draft.json`: the same takes at 360x640 for staging checks. |
| `../game_scenarios.gd` | yes | The game adapter. Change 32 adds `_stage_profile` (a first-run profile at any map) and the scenarios `trailer_gear`, `trailer_merge`, `trailer_farm`; the boss take is the existing `boss_sunflower` with an `outfit` option. |
| `end_card.json`, `compose_end_card.py` | yes | The end card: `marketing/brand/feature_graphic/compositions/portrait_endcard_preview.json` (the approved feature graphic restaged for 9:16) rendered layer by layer with the feature-graphic composer's own painters, then animated. The script checks that the stacked layers equal the composer's render and that the last frame equals the static study. |
| `review_trailer.py` | yes | Evidence sheets and `validation.json` from the rendered MP4 (see Review). |
| `store_assets/raw/video/trailer_c32/c32_*.avi` (+ `.log`) | no | **Original Movie Maker masters** (MJPEG + the game's PCM sound, which the cut never uses) and the adapter's event log per take. Keep them: the social cut reuses them. |
| `store_assets/raw/video/trailer_c32/end_card.mkv`, `end_card_layers/`, `end_card_final.png` | no | Lossless end-card master (FFV1 RGB, 4.5 s), every layer alone, last frame. |
| `store_assets/raw/video/trailer_c32/draft/` | no | 360x640 staging drafts (not used by the cut). |
| `store_assets/video/review_c32/` | no | Full-size review sheets and `validation.json`; reduced copies in `docs/Change_32_Evidence/`. |

## Commands (project root, Windows)

```powershell
$G = "D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
python Godot-Marketing-Toolkit/tools/marketing.py status --project .            # toolkit 1.0.2 pinned
python marketing/trailer/make_trailer_manifest.py                               # manifest.json
# one take (c32_boss, c32_gear, c32_merge, c32_autumn, c32_winter); about 15 s each
python Godot-Marketing-Toolkit/tools/marketing.py record --project . --manifest marketing/trailer/manifest.json --job c32_gear --godot $G --overwrite
python marketing/trailer/compose_end_card.py                                    # end_card.mkv
python Godot-Marketing-Toolkit/tools/marketing.py video --manifest marketing/trailer/manifest.json --locales en-US --overwrite
python marketing/trailer/review_trailer.py                                      # sheets + validation (non-zero exit on a failed contract)
```

Recomposing (copy, timing, transitions, music in-point) never needs a new recording: edit `make_trailer_manifest.py`,
regenerate, run `video` and `review_trailer.py`. Re-record a take only when its gameplay must change.

## Takes (all real play of `res://scenes/game/main.tscn`)

Every take uses the isolated `capture-store` profile with `--no-autosave`; the adapter starts from
`sim.new_profile()`, so the developer's profile is never opened. Fixtures only replace play time (a profile
that has reached a map, owned gear and merge levels, earlier boss defeats, opportunities announced earlier, a
summon or skill cooldown moved to just before the real event); combat, summons, drops, pickups, equipping and
merging are the game's own code. Each take logs its events (`LOOTFARMER_MARKETING ...`) and any banner it raised.

| Take | Map | Player | What happens (take time) |
|---|---|---|---|
| `c32_boss` | Spring II, rain (stage 8) | level 238, Red Panda outfit ^120 + Emerald Sword ^90, Lightning/Fire/Arcane Strike | Sunflower (`boss-sunflower`): Lightning 0.89 s, summon of two `unit-sprout` helpers 2.23 s, Fire 3.29 s, Arcane Strike 4.39 s |
| `c32_gear` | Summer II, rain (stage 4) | level 200, plain body (no outfit) + Wood Sword ^100 | Teal Dinosaur (`boss-teal-dinosaur`, wears `boss-teal-dinosaur_outfit`, holds `iron_sword`; loot = exactly those two) fought from 100% to 8% before the take; defeated 2.96 s, drops `iron_sword` + `boss-teal-dinosaur_outfit_t2` (seed 3209), collected 3.79/4.09 s, outfit opened from the gear grid 4.59 s and equipped 5.99 s, Iron Sword opened 6.69 s and equipped 7.79 s, panel closed 8.29 s |
| `c32_merge` | Summer II | the same look, 41 copies of `boss-teal-dinosaur_outfit_t2` at ^0 | tile tapped 0.83 s, "Merge 40 spare copies" 2.33 s: ^0 -> ^40, item Maximum health 61.20 -> 110.16, player HP 1,156 -> 1,205 |
| `c32_autumn` | Autumn II, falling leaves (stage 6) | level 700, Red Fox outfit ^60 + Gold Sword ^100, Fire/Lightning ^60 | farming the TV Head pack with Auto-Collect |
| `c32_winter` | Winter II, blue leaves (stage 2) | level 45, Snowman outfit ^40 + Stone Axe ^100, Arcane Strike | farming Reindeer Antlers and Space Helmets with Auto-Collect |

Staging notes: the HUD's side buttons (left) and minimap (right) cover the upper corners of the world view, so
each boss stands straight above the player in the clear centre column. The game's leaves are sparse (12 per
440x500 world px); the farming spots are the packs whose open ground the fixed leaf pattern crosses most often
during the shot. The Teal Dinosaur seed was found by searching drafts for a kill that rolls both of its items
(a drop is never forced; `review_trailer.py` refuses a take whose log lacks an event).

## Timeline (output seconds)

| Shot | Out | Source in-point | Content |
|---|---|---|---|
| card_boss | 0.00 to 2.30 | | "This boss calls for backup." (fully readable 0.20 to 1.70) |
| boss | 1.90 to 6.10 | `c32_boss` 0.6 s | Lightning 2.19, summon 3.53, Fire 4.59, Arcane Strike 5.69 |
| card_gear | 5.70 to 8.80 | | "Defeat an enemy and wear its gear." (6.30 to 8.20) |
| gear | 8.40 to 17.10 | `c32_gear` 1.3 s | defeat 10.06, pickups 10.89/11.19, outfit panel 11.69, Equip 13.09, Iron Sword panel 13.79, Equip 14.89, new look from 15.39 |
| merge | 16.70 to 20.10 (crossfade in) | `c32_merge` 0.4 s | panel 17.13, Merge 18.63 |
| card_seasons | 19.70 to 22.80 | | "Every season has new gear to farm." (20.30 to 22.20) |
| autumn | 22.40 to 24.70 | `c32_autumn` 3.1 s | |
| winter | 24.30 to 26.60 (crossfade in) | `c32_winter` 2.0 s | |
| end_card | 26.20 to 30.00 | `end_card.mkv` 0.0 s | slots drop 0.30, plain player 0.55, outfitted player 1.00, wordmark 1.20, IDLE RPG 1.50 (card time) |

Transitions: 0.4 s each. Next to a card the picture fades to true black, the card's text fades in only on black
and out before the next scene (toolkit 1.0.2 behaviour, Playbook 133.2); winter to end card is a linear dip through
black; gear to merge and autumn to winter are crossfades.

## Music

`assets/sounds/background_music.wav` only (SHA-256 `b3664d04791bb86f220b790823dab34ec6912ba93a1a60cf035e82b557b45778`,
132.41 s, 44.1 kHz 16-bit stereo, identical to the developer's handoff). One continuous section from **60.00 s**
(a strong onset after the intro, whose rests would sound like dropouts under the first card) to 90.00 s; the
track's louder section begins at 86.07 s, which lands at 26.07 s, as the end card arrives. Volume 0.85, 30 ms
fade-in against a click, 1.8 s fade-out, limiter at -1 dBFS. `game_audio` is false: the toolkit encodes every
gameplay segment with `-an` and the final graph maps only the WAV input, so no game, UI, combat, weather or
notification sound can reach the mix. `review_trailer.py` proves it on the decoded MP4 by subtracting the WAV
section (residual about -26 dB, AAC coding noise and limiter; no window above -16.9 dB).

**Rights (REL-02, open):** the repository holds no licence or purchase record for `assets/sounds` (nor for
Pixel Plains art). This trailer is a local review master; it is **not cleared for upload or publication** until
those records exist.
