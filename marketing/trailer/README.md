# LootFarmer Google Play trailer (Change 32, revised in Change 33)

The 30 s portrait store trailer: three black title cards, genuine gameplay takes and the approved feature
graphic restaged as an animated portrait end card, under the developer's own
`assets/sounds/background_music.wav` and nothing else. Built with the pinned **Godot Marketing Capture
Toolkit 1.0.2** (`Godot-Marketing-Toolkit/`, lock `marketing_capture_toolkit.lock.json`). Nothing here ships:
`marketing/*` is in the Release preset's `exclude_filter` and `store_assets/` is ignored by Git and Godot.

Finished video: **`store_assets/video/LootFarmer_Play_Trailer_en-US.mp4`** (1080x1920, 30 fps, 30.000 s,
H.264 High yuv420p, AAC 48 kHz stereo, faststart). Earlier cuts for comparison:
`store_assets/video/change_32/` (the first Change 32 cut, re-rendered byte-identical from its committed manifest)
and `store_assets/video/rejected_change_27/`.

## Files

| Path | Tracked | What |
|---|---|---|
| `make_trailer_manifest.py` -> `manifest.json` | yes | Takes (scenario + options + length), title-card copy, the cut (shot order, in-points, transitions), music settings. Edit the tables, re-run. `--draft` writes `manifest_draft.json`: the same takes at 360x640 for staging checks. |
| `../game_scenarios.gd` | yes | The game adapter: `_stage_profile` (a first-run profile at any map), `trailer_gear`, `trailer_merge`, `trailer_farm`; `boss_sunflower` takes an `outfit` option. Change 33 adds clean takes (`clean`), a closer camera and push-in, and direct equipping (`wear_*` steps). |
| `end_card.json`, `compose_end_card.py` | yes | The end card: `marketing/brand/feature_graphic/compositions/portrait_endcard_preview.json` rendered layer by layer with the feature-graphic composer's own painters, then animated (stacked layers and last frame verified equal to the study). |
| `review_trailer.py` | yes | Evidence sheets and `validation.json` from the rendered MP4 (non-zero exit on a failed contract). |
| `store_assets/raw/video/trailer_c32/*.avi` (+ `.log`) | no | **Original Movie Maker masters** (MJPEG + the game's PCM sound, which the cut never uses) and each take's event log: `c32_*` (Change 32 takes, kept) and `c33_*` (Change 33 takes). |
| `store_assets/raw/video/trailer_c32/end_card.mkv`, `end_card_layers/`, `end_card_final.png` | no | Lossless end-card master (FFV1 RGB, 4.5 s), every layer alone, last frame. |
| `store_assets/raw/video/trailer_c32/draft/` | no | 360x640 staging drafts (not used by the cut). |
| `store_assets/video/review_c32/` | no | Full-size review sheets and `validation.json`; reduced copies in `docs/Change_33_Evidence/`. |

## Commands (project root, Windows)

```powershell
$G = "D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
python Godot-Marketing-Toolkit/tools/marketing.py status --project .            # toolkit 1.0.2 pinned
python marketing/trailer/make_trailer_manifest.py                               # manifest.json
# one take, e.g. c32_boss, c33_gear, c33_closeup, c33_winter, c33_summer, c33_autumn, c33_spring (about 15 s each)
python Godot-Marketing-Toolkit/tools/marketing.py record --project . --manifest marketing/trailer/manifest.json --job c33_gear --godot $G --overwrite
python marketing/trailer/compose_end_card.py                                    # end_card.mkv
python Godot-Marketing-Toolkit/tools/marketing.py video --manifest marketing/trailer/manifest.json --locales en-US --overwrite
python marketing/trailer/review_trailer.py                                      # sheets + validation
```

Recomposing (copy, timing, transitions, music in-point) never needs a new recording: edit `make_trailer_manifest.py`,
regenerate, run `video` and `review_trailer.py`. Re-record a take only when its gameplay or framing must change.

## Takes used by the cut (all real play of `res://scenes/game/main.tscn`)

Every take uses the isolated `capture-store` profile with `--no-autosave`; the adapter starts from
`sim.new_profile()`, so the developer's profile is never opened. Fixtures only replace play time (a profile at a
map, owned gear and merge levels, earlier boss defeats, opportunities announced earlier, a summon or skill
cooldown moved to just before the real event); combat, summons, drops, pickups and equipping are the game's own
code. Each take logs its events (`LOOTFARMER_MARKETING ...`) and any banner it raised.

**Clean takes (`clean: true`, Change 33):** the adapter puts the HUD (rows below the map; minimap, side buttons,
labels and joystick over it; toasts) in the toolkit's `ui_group` and keeps it hidden, so the world fills the
9:16 frame (an intentional clean shot, Playbook 87.2). With no zoom slider on screen the camera may come closer
than the slider's 3x (`SettingsState.camera_zoom` set without saving; the same follow camera). Actors, health
bars, numbers, loot, speech and weather are untouched.

| Take | Map | Player | What happens (take time) |
|---|---|---|---|
| `c32_boss` (HUD) | Spring II, rain | level 238, Red Panda outfit + Emerald Sword, three auto skills | Sunflower: Lightning 0.89 s, summon of two `unit-sprout` 2.23 s, Fire 3.29 s, Arcane Strike 4.39 s |
| `c33_gear` (clean, zoom 4.2 -> 6.0) | Summer II, rain | level 200, plain body + Wood Sword ^100 | Teal Dinosaur (wears `boss-teal-dinosaur_outfit`, holds `iron_sword`; loot = those two) fought to 8% before the take; defeated 2.96 s, drops both (seed 3209, found by search, never forced); collected 3.79/4.09 s; camera pushes in 4.39-5.29 s; outfit equipped 5.59 s and Iron Sword 6.59 s through `sim.equip()` (what the item panel's Equip button calls), no panel shown |
| `c33_closeup` (clean, zoom 5.5) | Summer II, rain | Teal Dinosaur outfit + Iron Sword | attacking a Cowboy Bandana pack |
| `c33_winter` (clean, 3.8) | Winter II, snow, blue leaves | Snowman outfit + Stone Axe | Reindeer Antlers pack |
| `c33_summer` (clean, 3.8) | Summer II, rain | Snorkeler outfit + Iron Sword | Duck Swim Ring pack |
| `c33_autumn` (clean, 3.8) | Autumn II, falling leaves | Grim Reaper outfit + Gold Sword, Fire | TV Head pack |
| `c33_spring` (clean, 3.8) | Spring I | Bee outfit + Diamond Axe, Lightning | Bunny Ears pack |

The game's leaves are sparse (12 per 440x500 world px, a fixed pattern of position and time): the Winter spot
offset was computed so the pattern keeps leaves in frame during the shot.

## Timeline (output seconds)

| Shot | Out | Source in-point | Content |
|---|---|---|---|
| card_boss | 0.00 to 2.30 | | "This boss calls for backup." (fully readable 0.20 to 1.70) |
| boss | 1.90 to 6.10 | `c32_boss` 0.6 | Lightning 2.19, summon 3.53, Fire 4.59, Arcane Strike 5.69 |
| card_gear | 5.70 to 8.80 | | "Defeat an enemy and wear its gear." (6.30 to 8.20) |
| gear | 8.40 to 16.77 | `c33_gear` 1.2 | defeat 10.16, pickups 10.99/11.29, push-in 11.59, outfit on 12.79, Iron Sword on 13.79, new look held |
| closeup | 16.47 to 18.27 (crossfade) | `c33_closeup` 1.2 | the new look attacking |
| card_seasons | 17.87 to 20.70 | | "Each season has its own gear." (18.47 to 20.10) |
| winter | 20.30 to 22.10 | `c33_winter` 0.9 | |
| summer | 21.80 to 23.60 (crossfade) | `c33_summer` 1.0 | |
| autumn | 23.30 to 25.10 (crossfade) | `c33_autumn` 1.6 | |
| spring | 24.80 to 26.60 (crossfade) | `c33_spring` 1.4 | |
| end_card | 26.20 to 30.00 | `end_card.mkv` 0.0 | unchanged from Change 32 |

Transitions: 0.4 s through black at every card (text only on black, Playbook 133.2) and into the end card;
0.3 s crossfades between the gear and close-up shots and between the four seasons (no black between seasons).

## Music

`assets/sounds/background_music.wav` only (SHA-256 `b3664d04791bb86f220b790823dab34ec6912ba93a1a60cf035e82b557b45778`,
132.41 s, 44.1 kHz 16-bit stereo). One continuous section from **60.00 s** to 90.00 s (past the intro's rests);
the louder section (86.07 s in the track) lands at 26.07 s, as the end card arrives. Volume 0.85, 30 ms fade-in,
1.8 s fade-out, limiter at -1 dBFS. `game_audio` is false: every gameplay segment is encoded with `-an` and the
final graph maps only the WAV input. `review_trailer.py` subtracts the WAV section from the decoded MP4 audio
(residual about -26 dB: AAC coding and the limiter, no other sound).

**Rights (REL-02, open):** no licence or purchase record exists in the repository for `assets/sounds` or Pixel
Plains art. The trailer is a local review master, **not cleared for upload or publication**.
