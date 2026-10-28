# LootFarmer marketing (Google Play listing assets, Change 27)

Game-owned glue for the **Godot Marketing Capture Toolkit 1.0.2** (`Godot-Marketing-Toolkit/`, installed
addons pinned by `marketing_capture_toolkit.lock.json`). Nothing here ships: `marketing/`, `store_assets/`,
the toolkit and both capture addons are outside the Release allowlist (`tools/export_rules.json`,
`exclude_filter`), checked by `tests/change_27_probe` and `tools/verify_export.py`.

## File map

| Path | Tracked | What |
|---|---|---|
| `marketing/game_scenarios.gd` | yes | The one `prepare_scenario(id, options)` adapter for screenshots **and** trailer clips. Builds a late-game profile through the simulation's own calls, then lets the real game play. `is_capture_safe()` requires a `capture-*` profile and `--no-autosave`. |
| `marketing/make_manifest.py` → `marketing/manifest.json` | yes | Device classes, the six screenshot concepts, seven clips and the 30 s trailer cut. Edit the tables in the `.py`, re-run it. |
| `marketing/finalize_store_assets.py` | yes | Byte-identical store copies, Play-rule validation, ffprobe check, provenance manifest, contact sheet, review copies in `docs/Change_27_Evidence/`. |
| `marketing/brand/compose_brand.py`, `brand_config.json` | yes | Play icon and Android launcher/adaptive/monochrome icons from existing Pixel Plains sprites. Positions/scales in the JSON. (Wrote the Change 27 feature graphic; since Change 28 it no longer does.) |
| `marketing/brand/feature_graphic/` | yes | **Feature graphic (Change 28):** layered JSON compositions (`final.json`, three concepts, portrait end-card study), `components.json`, composer, review-sheet builder, Lilita One OFL notice. See its `README.md`. |
| `assets/branding/*.png` | yes | Runtime launcher icons (Release preset `launcher_icons/*`, `config/icon`). |
| `store_assets/raw/screenshots/<Device>/<Device>_NN.png` | no (ignored) | Untouched Godot captures (masters) + `.log` per capture. |
| `store_assets/screenshots/<Device>/<Device>_NN.png` | no | Upload files (byte copies of the masters). |
| `store_assets/raw/video/clip_*.avi` (+ `.log`) | no | Original Movie Maker recordings. **Keep until the trailer is approved.** |
| `store_assets/video/LootFarmer_Play_Trailer_en-US.mp4` | no | The trailer; `_review.png` / `_review.json` beside it. |
| `store_assets/branding/` | no | `play_icon_512.png`, `feature_graphic_1024x500.png`, `feature_graphic_manifest.json`, `source_layers/` (each feature-graphic layer alone), `review/` previews and concepts. |
| `store_assets/store_assets_manifest.json` | no (copy in docs) | Paths, sizes, SHA-256, scenario/options/device per file, alt-text drafts. |

Device classes (all genuine 9:16 portrait renders of the game's own 720x1280 reference layout):
Phone 1080x1920, Tablet_7 1440x2560, Tablet_10 1800x3200, Desktop 1620x2880 (Chromebook/desktop slot).

Scenario ids: `boss_sunflower` (01, trailer 0–7 s), `loot_collection` (02), `equipment_merge` (03),
`late_farming` (04), `world_progress` (05), `prestige_cards` (06), `boss_victory` (trailer closing beat),
`explore` (development aid only).

## Commands (project root, Windows)

```powershell
$G = "D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
python Godot-Marketing-Toolkit/tools/marketing.py status --project .          # installed == lock == toolkit
python marketing/make_manifest.py                                             # manifest.json from the tables
# every capture job (24 screenshots + 7 clips); one job:  --job Phone_01
python Godot-Marketing-Toolkit/tools/marketing.py pipeline --project . --manifest marketing/manifest.json --godot $G --locales en-US --overwrite
python Godot-Marketing-Toolkit/tools/marketing.py video --manifest marketing/manifest.json --locales en-US --godot $G --overwrite   # recompose only
python marketing/brand/compose_brand.py                                       # icons
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
- Screenshots carry no added text; the only added text anywhere is the **LootFarmer** name (trailer end
  card, feature graphic).
- Publication is a human decision: nothing is uploaded. Pixel Plains art and `assets/sounds` audio
  (music in the trailer) still need retained licence records (REL-02).
- Social videos/copy are Change 28, not here.
