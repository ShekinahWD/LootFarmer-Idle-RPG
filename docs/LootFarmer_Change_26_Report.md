# LootFarmer — Change 26 Report: Android Export & Asset Cleanup

Date 2026-10-28. Brief: `LootFarmer_Change_26_Android_Export_and_Asset_Cleanup.md`. Baseline: Change 25 (`0a00530`). Godot 4.7.2.stable.official.ed1daf0bf, Android SDK build-tools 36.1.0, JDK 17. Packaging only: no gameplay, balance, art, UI, save or performance-code change. Project version and Android Release `version/code` are **26**; the state schema (8) and save file version (3) are unchanged, so **no development-save reset**.

Starting worktree: `project.godot` and `export_presets.cfg` were modified but not committed. An editor session from build 23 had written version 23, export path `.23.aab` and `architectures/arm64-v8a` + `armeabi-v7a` = true. The version values were stale (lower than committed 25) and were replaced by 26; the ARM selection is the intended fix (E02) and is kept.

## E01 — Dependency-verified export allowlist (REL-06)

- `tools/export_rules.json` (reviewed): one explicit root (`data/game/catalog.json`, read with `FileAccess`); five dynamic families: stage scenes `stage_%d.tscn` from `catalog.stages[].id`, item art `Item-%d.png` from `_art(<int>)` literals, `MASTERY_ART`/`HELP_ART`, the load-time prewarm list, default indices and `catalog.campaign.paths[].icon`, skill sheets from `catalog.skills[].effect`, catalog `icon_path`/`texture`/`attack` strings, and the three player body sheets built by concatenation in `game_ui`; 20 registered code sites; forbidden prefixes; excluded groups with reasons.
- `tools/export_manifest.py` closes the roots (plus main scene, seven autoloads, icon and `en.po` from `project.godot`) over `ext_resource` paths, literal `res://` strings, `class_name` references and the families. It writes `tools/export_manifest.json` (229 files, a reason for each) and the Release preset (`export_filter="resources"`, `export_files` = the manifest, `include_filter=""`; the old `exclude_filter` stays as a second guard). Fails closed: an unregistered non-literal `load`/`preload`/`ResourceLoader`/`_art()` site, a literal naming no file, a stale rule, a forbidden path, an excluded group reached, an asset without `.import`, a stage-count mismatch, ABIs ≠ reviewed, or Release code ≠ project version. Verified by removing a site and a family's sites: both failed with the exact location.
- `python tools/export_manifest.py --why res://…` explains why a file ships. `--check` runs in the maintained suite.
- Shipped content: all eight stages; every game script (35 in `scripts/game`, 7 autoloads); 52 character sheets (48 enemy/outfit appearances plus player, Autumn/Gato bodies, shadow); 26 item images (19 Black Outline indices + catalog icons + `16x16 All Items v1.png`); 13 weapon-swing sheets; 6 VFX sheets; 7 OGG cues; 4 `assets/sounds` files; 2 `assets/Audio` tones; 13 Kenney PNGs; seasonal tiles/props/weather; theme, font, shader, `.tres` rules, catalog, `en.po`, icon.
- Excluded from the export (sources and licences stay in Git): seven unused Pixel Plains item outline variants and unused Black Outline indices, `New Items`, loose Pixel Plains demo sheets (waterfalls, `All tiles Spring.png`, …), unused animation-pack sets/tools/items, Kenney samples/previews/vector and 267 unused PNGs, the 30 SFX WAV duplicates and 23 unused OGGs, 12 unused `assets/sounds` WAVs, the bootstrap scene/script/theme (`scenes/main.tscn`, `scripts/main.gd`, `ui/bootstrap_theme.tres`), and the retired packs below.
- `.gdignore` added to the reference-only packs `Zombies Free ver`, `PP Pumpkins Set Free` and `LootFarmer-seasonal-animation-sheets` (zero references in code, data, tools or tests; the last one's `index.csv` was also being imported as 7 translation files). Not added to any parent of needed assets.

## E02 — Android ABIs (REL-05)

Root cause, from the generated Gradle template `android/build/config.gradle` `getExportEnabledABIs`: when every `architectures/*` option is false Godot passes an empty list, and the template falls back to `armeabi-v7a|arm64-v8a|x86|x86_64`. The settings intended nothing; the artifact shipped four ABIs. Release preset now selects `arm64-v8a` and `armeabi-v7a` (32-bit kept: no decision to drop it), x86/x86_64 false. No generated Android files, signing settings, permissions, SDK levels, package id or Bootstrap preset changed.

## E03 — Import hygiene (AST-04, AST-05)

- `docs/.gdignore` stops all documentation and evidence screenshots from being imported and stops `docs/LootFarmer_Enemy_Roster.csv` from becoming a translation catalog (no rename needed). Capture scripts only *write* into `docs/…`, which a `.gdignore` does not affect. `localization/en.po` (registered in `project.godot`) is untouched.
- Removed generated files only: 290 tracked (225 `.import`/`.translation` under `docs/`, 65 under the three retired packs; each `.import` checked to have its source beside it) and 26 untracked `docs/Change_25_Evidence/ui/*.png.import`. All screenshots, the CSVs and historical docs remain. A headless `--import` afterwards was clean (exit 0, no errors) and recreated none of them.
- `.gitignore` already covers `.godot/` (including `export_credentials.cfg`), `/android/`, `/builds/`, APK/AAB/PCK, keystores, `.env` and `/tests/tmp/`; nothing needed adding. `tests/change_25_*.gd.uid` (left untracked by Change 25) are now committed, as the ignore policy requires.

## E04 — Real exported artifact

Command: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Android Release" builds/LootFarmerIdleRPG.26.aab` (local release keystore from the ignored `.godot/export_credentials.cfg`; no credential printed or committed; nothing installed or uploaded). Check: `python tools/verify_export.py builds/LootFarmerIdleRPG.26.aab --baseline builds/LootFarmerIdleRPG.22.aab` → **VERIFY_EXPORT PASS**.

| | v22 (committed preset, all four ABIs) | v23 (developer export, ARM only, all resources) | **v26** |
|---|---|---|---|
| AAB bytes | 117,602,722 | 65,144,797 | **58,948,378** |
| ABIs (`base/lib`) | arm64-v8a, armeabi-v7a, x86, x86_64 | arm64-v8a, armeabi-v7a | **arm64-v8a (24.48 MB), armeabi-v7a (25.91 MB)** |
| Archive entries | 5,824 | 5,823 | **587** |
| Packed Godot files / source paths | — / 2,850 | 5,697 / 2,852 | **461 / 229** |
| Godot content (compressed) | 10.67 MB | 10.69 MB | **6.46 MB** |

Both baselines are real, signed Release exports from the same preset type (gradle AAB); v22 has the committed ABI settings and v23 has the same ABIs as v26. So **ABIs: −52.5 MB** (v22→v23), **asset allowlist: −6.20 MB** (v23→v26, of which ~4.2 MB is Godot content, mainly unused WAV cues and SFX WAVs). v26 adds no source path that v23 lacked.

Inspection of the actual AAB:
- Godot content sits in `assetPackInstallTime/assets/`, one stored file per packed path, plus the `assets.sparsepck` directory (GDPC, engine 4.7.2, 459 entries). Each directory entry was matched to a stored file with equal size and MD5; no stored file is outside the directory (except engine files).
- Packed source paths (from `X.import`, `X.remap`, `X.gdc`, raw files) = the 229-file manifest exactly: **0 missing, 0 unexpected**. Every import/remap target (`.godot/imported/*.ctex|.sample|.oggvorbisstr|.fontdata`, `.godot/exported/*.scn|.res`) is packed. Godot's own export dependency walk and the generator agree.
- All eight `stage_N.tscn` packed. No tests, tools, docs, marketing, addons, toolkit, Git data, keystores, credentials, `override.cfg` or saves; no excluded group.
- Manifest identity: versionCode 26, versionName 26 (inherited), package `com.shekinahwelefuldesigns.lootfarmeridlerpg`, minSdk 24, targetSdk 36; signed (`META-INF/LOOTFARM.SF/.RSA`).
- SHA-256 `2bfc5458e1a86b93b28c4b61f959af78a25e63012bceb212b51b8bcbac889528`. The report JSON goes to `tests/tmp/export/` (ignored); the AAB stays in ignored `builds/`.

Remaining sizes inside the content: `assets/sounds` 4.47 MB (the music, PERF-07), scripts 0.78 MB, scenes 0.57 MB, font 0.43 MB; everything else < 0.13 MB per group.

Source-side proof that dynamic content resolves: `tests/change_26_probe` (49 checks) loads every manifest file from source, instantiates all eight stages and records what the running game resolves: catalog icons for all 397 items, body and swing sheets for all 48 groups and every item, Death/Cat bodies, the six effect sheets, and the UI art cache after opening 16 panels, every guide picture branch and every Prestige path icon. Everything it records ships. It also checks the preset (selected resources, 229 files, ARM only, version 26).

## E05 — Demo foundation (not the demo)

The manifest model is positive and data-driven. `python tools/export_manifest.py --catalog <filtered catalog> --manifest <out.json>` re-derives the stage/item/skill/catalog families from a filtered catalog without touching the paid preset. Dynamic families the future Stage 16 generator must filter: stage scenes (`stages[].id`), catalog paths (items reachable from the kept groups), skill sheets, Prestige path icons and the fixed UI art indices (code constants, not stage-scoped). General dependencies every build needs: the main scene, autoloads, theme, font, shader, audio cue set, the rules `.tres` and `en.po`. Code paths that would reference removed stages (`stage_scenes.gd`, campaign travel) need content-presence guards in the demo project. Nothing demo-specific was created.

## E06 — Version, docs, commit

`config/version="26"`, Release `version/code=26`, `version/name=""`; Bootstrap preset unchanged (code 20). The Change 25 probe's exact-25 version check now reads "at least 25; Release code = project version"; the exact-26 check lives in change_26_probe. Updated: Asset Registry, Test Suite, Design README, Full Production Audit Report (addendum), Playbook §22.2 (validated allowlist method and the ABI fallback trap, no game numbers). GDD and State Contracts unchanged: no product or state contract changed.

## Tests

- `python tools/export_manifest.py --check` → `EXPORT_MANIFEST PASS files=229 imported=151 stages=8`.
- `python tools/run_probes.py` (once, at the end): 35 entries (validator + export_manifest + 33 Godot scenes): 35/35 pass on the first full run, no script errors, no timeouts. Validator 1,574 checks; Godot probes 5,832 checks plus two smoke runs.
- `python tools/verify_export.py builds/LootFarmerIdleRPG.26.aab` → PASS (above). Non-gating: needs an exported artifact.

## Limits and open items

- Not installed or run on a phone (not requested). That the packaged game starts and renders is inferred from the package matching the source closure that the suite and change_26_probe load headless. A packaged run on the developer's phone remains the confirming check. Play splits per ABI, so player download size changes less than the upload size.
- `verify_export.py` reads AAB/APK; a standalone `.pck` export would need the same directory parser pointed at the file (supported by `sparse_index`, not wired as a CLI input).
- The Change 25 startup outlier did not show up in this batch's runs; no performance work was started.
- REL-01 (final icon) and REL-02 (Pixel Plains / `assets/sounds` licence records) are still open and unaffected.
