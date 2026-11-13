# LootFarmer marketing (Google Play listing assets, Change 27; trailer Changes 32 and 33; screenshots Change 34; match cuts Changes 44 to 47; social videos Changes 70 and 73)

Game-owned glue for the **Godot Marketing Capture Toolkit 1.0.2** (`Godot-Marketing-Toolkit/`, installed
addons pinned by `marketing_capture_toolkit.lock.json`). Nothing here ships: `marketing/`, `store_assets/`,
the toolkit and both capture addons are outside the Release allowlist (`tools/export_rules.json`,
`exclude_filter`), checked by `tests/change_27_probe` and `tools/verify_export.py`.

## File map

| Path | Tracked | What |
|---|---|---|
| `marketing/game_scenarios.gd` | yes | The one `prepare_scenario(id, options)` adapter for screenshots **and** trailer clips. Builds a late-game profile through the simulation's own calls, then lets the real game play. `is_capture_safe()` requires a `capture-*` profile and `--no-autosave`. |
| `marketing/make_manifest.py` → `marketing/manifest.json` | yes | The seven Change 27 clips (no video since Change 32, no screenshot jobs since Change 34; the Change 27 screenshot table stays as a record). |
| `marketing/screenshots/` | yes | **Store screenshots (Change 34):** manifest generator (six scenes x four device classes), finalizer/validator/review sheets and README. |
| `marketing/trailer/` | yes | **Store trailer (Change 32, revised in Change 33):** its own manifest generator, end-card animation, review script and README (takes, timeline, music in-point, reuse). |
| `marketing/social/` | yes | **Social videos (Changes 70, 73):** the `soc` adapter (`social_scenarios.gd`, extends `game_scenarios.gd`), take manifests, recorder, the project-side compositor, storyboards, validator, posting copy. See its `README.md` (status, commands, adapter reference, revising). |
| `marketing/match_cut/`, `match_cut_v2/` .. `match_cut_v4/` | yes | **Match-cut experiments (Changes 44 to 47):** one manifest generator and review script per version (V1 cuts on impact frames, V2 Hermite camera keys `options.cam`, V3 zoom rush + `add_speed_blur.py`, V4 hero-size-matched zooms). Reports: `docs/LootFarmer_Change_44_Report.md` to `_47_Report.md`. Review masters only; the approved social match cut is video 2 of the social set. |
| `marketing/finalize_store_assets.py` | yes | Whole-listing check: re-validates the Change 34 screenshots (no copying), ffprobe trailer check, branding check, `store_assets_manifest.json`. |
| `marketing/brand/compose_brand.py`, `brand_config.json` | yes | Record of the rejected Change 27 icon and feature graphic. Since Change 30 it renders nothing unless given `--legacy-change-27`; `--check` still validates the branding files for `finalize_store_assets.py`. |
| `marketing/brand/icon/` | yes | **App icon (Change 30):** layered JSON on a 32-unit grid (`final.json`, three concepts), composer writing the Play icon and all four launcher layers, review sheets and `docs/Change_30_Evidence/`. See its `README.md`. |
| `marketing/brand/feature_graphic/` | yes | **Feature graphic (Change 28):** layered JSON compositions (`final.json`, three concepts, portrait end-card study), `components.json`, composer, review-sheet builder, Lilita One OFL notice. See its `README.md`. |
| `assets/branding/*.png` | yes | Runtime launcher icons (Release preset `launcher_icons/*`, `config/icon`). |
| `store_assets/raw/screenshots/<Device>/<Device>_NN.png` | no (ignored) | Untouched Godot captures (masters) + `.log` per capture (Change 34 set). |
| `store_assets/screenshots/<Device>/<Device>_NN.png` | no | Upload files (byte copies of the masters) and `screenshots_manifest.json`. |
| `store_assets/screenshots_change_27/` | no | The replaced Change 27 screenshots (raw + final + manifest). |
| `store_assets/raw/video/clip_*.avi` (+ `.log`) | no | Change 27 Movie Maker recordings (the rejected cut's footage; kept for social reuse). |
| `store_assets/raw/video/trailer_c32/` | no | Trailer masters: `c32_*.avi` (Change 32) and `c33_*.avi` (Change 33 clean takes) + logs, `end_card.mkv`, layers, drafts. |
| `store_assets/video/LootFarmer_Play_Trailer_en-US.mp4` | no | The Change 32 trailer; `_review.png` / `_review.json` beside it, sheets in `review_c32/`, the first Change 32 cut in `change_32/`, the rejected Change 27 cut in `rejected_change_27/`. |
| `store_assets/video/experiments/` | no | Match-cut experiment MP4s (Changes 44 to 47, hashed in the social set's approved list). |
| `store_assets/raw/video/social/`, `store_assets/video/social/` | no | Social takes (+ logs, `before/`, `draft/`, `rev2/`) and the eleven masters (+ `timelines/`, `review/`, `rev2/`). |
| `store_assets/branding/` | no | `play_icon_512.png`, `icon_manifest.json`, `feature_graphic_1024x500.png`, `feature_graphic_manifest.json`, `source_layers/` (each feature-graphic layer alone; `icon_final/` each icon layer alone), `review/` previews and concepts (`review/icon/` for the icon). |
| `store_assets/store_assets_manifest.json` | no (copy in docs) | Paths, sizes, SHA-256, scenario/options/device per file, alt-text drafts. |

Device classes (all genuine 9:16 portrait renders of the game's own 720x1280 reference layout):
Phone 1080x1920, Tablet_7 1440x2560, Tablet_10 1800x3200, Desktop 1620x2880 (Chromebook/desktop slot).

Screenshot scenarios (Change 34): `boss_sunflower` (01), `shot_gear` (02), `shot_merge` (03), `trailer_farm` (04),
`shot_explore` (05), `shot_prestige` (06); see `marketing/screenshots/README.md`. Other scenario ids: `boss_sunflower` (trailer boss take), `loot_collection` (02), `equipment_merge` (03),
`late_farming` (04), `world_progress` (05), `prestige_cards` (06), `boss_victory` (Change 27 clip),
`trailer_gear`, `trailer_merge`, `trailer_farm` (trailer; option `clean` hides the HUD for a clean, closer shot), `explore` (development aid only).

## Commands (project root, Windows)

```powershell
$G = "D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
python Godot-Marketing-Toolkit/tools/marketing.py status --project .          # installed == lock == toolkit
python marketing/make_manifest.py                                             # manifest.json from the tables
# the store screenshots: see marketing/screenshots/README.md
# the seven Change 27 clips; one job:  --job clip_boss
python Godot-Marketing-Toolkit/tools/marketing.py pipeline --project . --manifest marketing/manifest.json --godot $G --locales en-US --overwrite
# the store trailer: see marketing/trailer/README.md
python marketing/brand/icon/compose_icon.py                                   # Play icon + launcher layers, concepts, review sheets
python marketing/brand/feature_graphic/compose_feature_graphic.py             # feature graphic, concepts, portrait study
python marketing/brand/feature_graphic/make_review.py                         # its review sheets + docs/Change_28_Evidence
python marketing/finalize_store_assets.py                                     # copy, validate, manifest, review sheets
python marketing/finalize_store_assets.py --check                             # validate only
```

Each `record` writes `<output>.log`; the adapter's lines start with `LOOTFARMER_MARKETING` and state the
postconditions (summon happened, skills cast, drops, collect, merge level, Prestige pressed, boss defeated).

## Rules kept

- Real gameplay only: no hand-spawned helpers, no damage/HP changes, no fake UI or overlays. Fixtures
  stand in for play time only (late-game profile, earlier Prestige via the real begin_prestige/prestige,
  a summon/skill cooldown moved to just before the real event, the fight fast-forwarded in the real
  simulation). Never the final Green Alien boss.
- Screenshots carry no added text. Added text elsewhere: the **LootFarmer: Idle RPG** title (feature graphic,
  trailer end card) and the trailer's three black title cards (Change 32).
- Publication is a human decision: nothing is uploaded. Pixel Plains art and `assets/sounds` audio
  (music in the trailer) still need retained licence records (REL-02).
- Social videos are their own task with fresh takes of the current build (the trailer takes were already out of
  date when the set was made): `marketing/social/README.md`. `store_assets/` here is this project's equivalent of
  the Playbook's `generated/` tree for new games (0.2.5); existing paths are not migrated (135.4).
