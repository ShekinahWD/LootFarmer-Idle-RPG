# LootFarmer — Change 27 Report: Google Play Store Assets + First Snowman Reward

**Date:** 2026-10-28. **Baseline:** Change 26 (`37ae83e`), Godot 4.7.2. **Version:** application and Android Release `version/code` **27** (`version/name` inherited). **Save:** schema 8, save file version 3, no new saved field, no reset. **Toolkit:** Godot Marketing Capture Toolkit **1.0.2** (`status`: 11 installed files identical to the lock and the toolkit source; ffmpeg/ffprobe 8.0.1, Pillow, Godot 4.7.2).

The starting worktree again carried a stale editor overwrite of `project.godot` / `export_presets.cfg` (version 24). It was corrected in place to 27; nothing else in those files changed except the icon fields below.

## G01 — First Snowman weapon (hidden, once per profile)

- `scripts/game/onboarding.gd` `boss_first_kill(a, def, dropped)`, called from `simulation._reward` after every natural roll and after the Change 15 early equipment guarantee. If the group is listed in `OnboardingRules.first_kill_weapon_bosses` (`resources/game/onboarding_rules.tres`: only `boss-snowman`) and its lifetime `group_kills` is exactly 1, it adds one ordinary ground pickup (`sim._drop`) of the boss's **catalog weapon** (`def.weapon` = `stone_axe`) unless that weapon already dropped naturally on the same kill.
- Durable fact: `group_kills` is only raised by real defeats (`_kill`, just before `_reward`, same step), saved, kept by Prestige and zeroed by Hard Reset (`new_profile`). So no new field, no schema change, no reload/claim race. The drop uses no RNG, so every other roll on that kill is identical to an ordinary defeat.
- No copy, banner, history line, effect or tutorial text. The defeated enemy's normal loot line ("weapon") follows the actual drops as it always has.
- `tests/change_27_probe` (registered): gear chance 0 fixture → exactly one Stone Axe as a ground pickup (not in inventory), none on the second defeat; natural axe not duplicated; same-seed first vs ordinary defeat: identical other drops, coins, XP, level, Gems and signals; disk save → reload and snapshot round trip do not regrant; real Prestige keeps the lifetime kill and the next run's first defeat is ordinary; Hard Reset re-arms it; Guided, Basic and None; a fixture catalog weapon (`wood_sword`) is the one granted; an unlisted boss (Cyan Robot) is unaffected; the Change 15 guarantee does not count the boss; no player-facing copy.

## M01 — 24 Google Play screenshots (portrait)

All captured by the toolkit's `record` through `marketing/game_scenarios.gd` in the real game scene, each device class as its **own render at its own size** (the game's 720×1280 reference layout under `canvas_items`/`expand`; same 9:16 aspect, so the layout is identical and only the pixel density differs). Window sizes beyond the 1080 px monitor are handled by the toolkit (`fit_window`), and the read-back size is checked.

| Device folder | Size | Files |
|---|---|---|
| `store_assets/screenshots/Phone/` | 1080×1920 | Phone_01 … Phone_06 (133–229 KB) |
| `store_assets/screenshots/Tablet_7/` | 1440×2560 | Tablet_7_01 … _06 (170–292 KB) |
| `store_assets/screenshots/Tablet_10/` | 1800×3200 | Tablet_10_01 … _06 (207–351 KB) |
| `store_assets/screenshots/Desktop/` | 1620×2880 | Desktop_01 … _06 (188–324 KB) |

| # | Scenario | Moment (identical frame in all four classes) |
|---|---|---|
| 01 | `boss_sunflower` | Spring II **Sunflower** (non-final summoner) at 1.5 s: its real summon spawned two Sprout helpers; the player's Lightning/Fire/Arcane Strike effects and damage numbers visible. |
| 02 | `loot_collection` | Spring I **Bee** just defeated in the real simulation (16 s fight): its genuine drops Diamond Axe, Recovery Salve and Heal skill on the ground beside the player. |
| 03 | `equipment_merge` | Equipped Emerald Sword detail after a real Merge (^91, Damage 1.22K, "Merge" and "Merge 2 spare copies" ready). |
| 04 | `late_farming` | The Spring II pack spot with the most live enemies (18 nearby), auto-attacks and skills, Auto-Collect bought. |
| 05 | `world_progress` | Spring II World panel: camps (travel / respawn / locked 3.23K-coin camp) and the explored map. |
| 06 | `prestige_cards` | Prestige panel: Cards owned 3 (earned by a real earlier Prestige), Ready 2, "Prestige · 2 card(s)". |

Raw masters `store_assets/raw/screenshots/<Device>/<Device>_NN.png` (+ capture log) are untouched; upload copies are **byte-identical** (SHA-256 recorded). All are 24-bit RGB PNG without alpha, exact 9:16, sides within 320–3840 px, ≤ 8 MB. Contact sheet: `store_assets/review/screenshots_contact_sheet.png` (copy in `docs/Change_27_Evidence/`). Alt-text drafts (≤140 characters) are in `store_assets_manifest.json`. Screenshots carry **no added text**.

**Desktop/Chromebook:** these are genuine portrait captures for the desktop/Chromebook slot. LootFarmer has no landscape desktop mode and no ChromeOS validation, so **Chromebook listing acceptance is pending** (supported-device evidence needed before using that slot).

**How the late-game state is reached (all through the game's own calls):** `new_profile`; lifetime history (gate bosses defeated, Winter I–Spring I explored, boss kills recorded with the same counters `campaign.killed` writes); one **real Prestige** (`begin_prestige` + `prestige` on the opportunities the game itself marked ready: 3 Boss Hunter cards); then the current run (all Winter I–Spring I bosses and camps, Spring II reached, Spring II explored along its routes) and a late-game loadout of items that enemies actually drop at merge levels validated by the Change 9 balance fixture (Emerald Sword ^90, Sprout outfit ^500, stored Diamond/Gold weapons, three skills). Profile writes go only to the isolated `capture-store` profile (`--no-autosave`); `is_capture_safe()` refuses any other profile. Timers moved forward to just before a real event (Sunflower summon cooldown, player skill cooldowns) are the only staging of actions.

## M02 — Icon, adaptive icons, feature graphic

- **Play icon** `store_assets/branding/play_icon_512.png`: 512×512 RGBA, 3.2 KB. The player (Sprout outfit) holding the Emerald Sword on Spring grass, from the game's sprites at whole-number nearest-neighbour scale. Previews at 512/192/96/64/48/32 px on light and dark: `review/play_icon_sizes.png`.
- **Android launcher icons** (runtime, tracked) `assets/branding/`: `launcher_192.png`, `adaptive_foreground_432.png` (transparent, content inside the 288 px safe zone), `adaptive_background_432.png` (opaque), `adaptive_monochrome_432.png`. Set in the Android Release preset `launcher_icons/*` and as `config/icon` (replacing the REL-01 "LF" placeholder; `icon.svg` kept in source). Mask previews: `review/adaptive_masks.png`. Verified inside the signed AAB as `base/res/mipmap-*/icon*.webp` (decoded and viewed).
- **Feature graphic** `store_assets/branding/feature_graphic_1024x500.png`: 1024×500 RGB, 28 KB. Spring terrain and trees, the hero, the Sunflower boss with two tinted helper Sprouts, real loot icons; the **LootFarmer** name only (Noto Sans 800, OFL), no tagline. Half-size preview checked for legibility.
- Editable source: `marketing/brand/brand_config.json` + `compose_brand.py`; `--check` validates sizes, modes, transparency and safe zone.
- **Not claimed:** brand approval. The developer reviews the actual pixels.

## M03 — 30-second portrait trailer

`store_assets/video/LootFarmer_Play_Trailer_en-US.mp4`: **30.000 s, 900 frames, 1080×1920, 30 fps, H.264 High yuv420p (limited range), AAC 48 kHz stereo 192 kb/s, faststart**, 7.75 MB, CRF 18 / slow. Toolkit verification: **transitions 7/7 smooth** (each fade reaches black level 1, no step above a third of its change), card text held 1.0 s (measured). Review sheet `…_review.png` / `_review.json`, half-size copy in docs.

| Time | Shot (raw clip, in-point 0.6 s) | Verified in the capture log |
|---|---|---|
| 0.0–7.0 | `clip_boss`: Sunflower fight | player skills cast at 0.9 s (Lightning), 1.6 s (Fire), 3.0 s (Arcane Strike); **real summon at 2.2 s, 2 Sprout helpers** |
| 6.7–10.1 | `clip_loot`: Bee defeated at 1.2 s | drops Diamond Axe, Recovery Salve, Heal skill; collected at 2.2 / 2.7 / 3.1 s (`sim.collect`, the tap action) |
| 9.8–13.0 | `clip_merge`: Emerald Sword | Merge button pressed twice: ^90 → ^91 → ^92, copies 4 → 2 |
| 12.6–21.2 | `clip_farm`: Spring II pack (18 enemies near) | fade through black in/out |
| 20.9–23.5 | `clip_world`: World panel opens | |
| 23.2–26.2 | `clip_prestige`: Prestige panel → Prestige · 2 card(s) → the game's confirm dialog | the dialog's instant open is the one "abrupt change" the analyzer lists (frame 744): real UI, not a cut |
| 25.8–28.8 | `clip_victory`: Spring II **Red Panda** (non-final) defeated at 1.96 s, player at 43% HP | real level-up; no loot that roll (not forced) |
| 28.4–30.0 | Brand card: Play icon + **LootFarmer** | ~1.6 s, the only added text |

Gameplay ≈ 28.4 s of 30 (≈95%). The final boss is never shown. Audio: each clip's recorded game sound (captured with the music slider at 0) at 0.9 plus the game's own `background_music.wav` as one continuous bed at 0.5 (never restarted per clip), 1.2 s music fade on the card; per-second loudness −22 to −26 dB, peak −3.6 dBFS; the analyzer's short quiet windows are musical rests, not dropouts. Raw recordings (`store_assets/raw/video/clip_*.avi`, 255 MB, with logs) are kept for review and for Change 28; recompose with `marketing.py video`. Not uploaded anywhere.

**Iterations worth knowing:** clips first showed the HUD's first refresh (0 coins, empty grid) in the opening frames, so every clip now has a 0.6 s head before its first action. The game's root Control runs `PROCESS_MODE_ALWAYS`, so a frozen screenshot showed "Resume"; the adapter sets that root PAUSABLE for screenshot jobs (Playbook 87.7 amended). The Sunflower victory was a knife-edge fight this loadout lost below about 4% boss HP, so the closing beat uses the Red Panda. An end fade over the brand card cannot reach black (the toolkit keeps card text through `fade_out`), so the video ends on the card.

## M04 — Reproducibility and source safety

File map and one-line commands: `marketing/README.md`. Tracked: adapter, manifest generator + manifest, finalizer, brand compositor/config, runtime icons, evidence copies. Ignored (`store_assets/` with `.gdignore`): raw masters, upload copies, AVIs, MP4, branding outputs, manifest with hashes (copy in `docs/Change_27_Evidence/store_assets_manifest.json`). The installed toolkit files are unchanged (no fork).

**Toolkit observation (not changed here):** the runner converts only `INHERIT` roots to `PAUSABLE`, so games with an `ALWAYS` UI root need the adapter-side fix above; a future toolkit version could warn about it.

## M05 — Packaging, regression, docs

- `python tools/export_manifest.py`: 232 files (229 + three adaptive icon roots in `export_rules.json`; `launcher_192.png` via `config/icon`; `icon.svg` no longer shipped). `--check` PASS. Nothing under `marketing/`, `store_assets/`, `addons/`, the toolkit or `docs/` ships (`change_27_probe`).
- Signed export `builds/LootFarmerIdleRPG.27.aab` (ignored): **58,948,313 bytes**; `tools/verify_export.py --baseline LootFarmerIdleRPG.24.aab` (the Change 26 artifact): **PASS**, versionCode 27, package `com.shekinahwelefuldesigns.lootfarmeridlerpg`, min SDK 24 / target 36, ABIs arm64-v8a + armeabi-v7a only, 232 sources = manifest, signed (META-INF LOOTFARM.SF/RSA), launcher icons present in all mipmap densities. No device install or run was performed.
- Suite: 36/36 (see "Regression").
- `change_26_probe` now checks version ≥ 26 and the configured project icon (instead of `icon.svg`); `change_27_probe` holds the exact version check.

## Regression

`python tools/run_probes.py` once, after all implementation and media work: **36/36 pass** (validator + export_manifest + 34 Godot scenes), **no `SCRIPT ERROR`**, no timeouts. Validator 1,574 checks; export manifest 232 files; Godot probes **5,883 checks** (Change 26: 5,832 + 51 new in `change_27_probe`) plus two smoke runs. Targeted runs during development: `change_27_probe` / `change_26_probe` only.

## Docs changed

GDD (First Snowman weapon rule), State Contracts (no new field; `group_kills` semantics), Content and Balance (Change 27 note), Test Suite (change_27_probe, counts), Asset Registry (branding provenance, export inclusion/exclusion, rights used, REL-01/02 status), Design README (entry point), this report, `marketing/README.md`, Reusable Playbook §87.7 (one generic rule: a game root that is itself ALWAYS keeps drawing its paused state in frozen captures).

## Open for the developer

1. **Approve or reject the actual pixels and footage** (screenshots, icon, feature graphic, trailer). Nothing was uploaded, posted or published; the store wants the trailer as a YouTube URL later.
2. **REL-02 licences**: Pixel Plains art and `assets/sounds` (including the trailer music) still lack retained licence/purchase records. Do not publish media until they are recorded.
3. **Chromebook slot**: portrait Desktop captures are ready; using the Chromebook listing needs ChromeOS support evidence.
4. **Device checks**: install the v27 AAB and look at the launcher icon under the phone's mask and themed icons; play the first Snowman defeat once.
5. Alt-text drafts in the manifest are for review at listing time.
6. Social videos and posting copy are Change 28.
