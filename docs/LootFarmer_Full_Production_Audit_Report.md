# LootFarmer – Idle RPG — Full Production Audit Report

**Date:** 2026-10-28 · **Auditor:** Claude (repository-aware coding agent) · **Brief:** `docs/LootFarmer_Full_Production_Audit.md`
**Mode:** audit only. No gameplay code, scene, asset, test, project-setting or export change was made. Documentation edits are listed in section 8. Nothing was committed, exported or published.

> **Status update (Change 24, 2026-10-28):** batches A (test truth), C (hitch removal) and D (rain/map frame time) were implemented together on the developer's instruction, without the phone baseline of batch B (no Android profiling was requested). PERF-01–07, TEST-01–04, UI-04, UI-05 (decided: no pointer in None) and DOC-02 (version 24) are addressed; see `LootFarmer_Change_24_Performance_Report.md`. Phone measurements, the device checklists and all other findings remain open. The body of this report is unchanged.

---

## 1. Audit baseline

| Item | Value |
|---|---|
| Repository | `D:\Godot\lootFarmer`, branch `main` |
| Revision | `b51a209a65e7f13feb1a333ace462e54d1b0d14c` ("Change 23: fix dialog flickering, auto-claim guidance, prestige card sections, and tutorial timing", 2026-10-28 06:10) |
| Worktree at start | Clean except the untracked brief `docs/LootFarmer_Full_Production_Audit.md` |
| Engine | Godot **4.7.2-stable (official)**, Windows console build `D:/Programs/Godot_v4.7.2-stable_win64.exe/…_console.exe`. Project `config/features` = `4.7`, `Mobile`; renderer `mobile` with `gl_compatibility` on mobile. |
| Application version | `project.godot config/version="22"`; Android `version/code=22`, `version/name=""` (inherits). **Note:** the commit titled "Change 23" did not bump the version and its notes file is named `LootFarmer_Change_22_Notes.md` (see DOC-02). |
| Save | `SaveService.SAVE_VERSION=2` (container), game schema 8, fog layout revision 2 |
| Latest exported artifact | `builds/LootFarmerIdleRPG.22.aab`, 2026-10-27 18:45, 117.6 MB. It **predates** commit b51a209, so no exported build contains the Change 22/23 fixes (REL-04). |
| Measurement machine | Windows 10 Home 19045, Intel i5-10300H (8 threads), NVIDIA GTX 1650, 540×960 window, Compatibility renderer, V-Sync off in harness. **Desktop only; no Android device was connected to this audit.** |

**Documents examined.** In full: the audit brief; `LootFarmer_Design_README.md`, `LootFarmer_GDD.md`, `LootFarmer_Change_20_Report.md`, `LootFarmer_Change_21_Report.md`, `LootFarmer_Change_22_Notes.md`, `Final_Tutorial_Announcement_Change.md`, the Change 21/22/23 sections of `LootFarmer_State_Contracts.md`, the current sections of `LootFarmer_Test_Suite.md`, and the headers and change sections of the Upgrade, Prestige, Content and Balance catalogs, Asset Registry and Prototype Status. **Playbook** (`Reusable_Game_Development_Playbook.md`, 8,649 lines, 636 KB): sections 0–2, 13, 14–22.4, 26–31, 48–49, 56–61, 63–68, 84–89, 95–100, 112–113, 117.9, 121.8–121.11, 125–127, 132–146 were read in full. The remaining sections (3–12, 23–25, 32–47, 50–55, 62, 69–83, 90–94, 101–111, 114–124, 128–131) were reviewed by heading and topic map for applicability; most cover worker/army/city-builder mechanics LootFarmer does not have. I state this explicitly instead of claiming a line-by-line read of all 8,649 lines.

**Code, scenes, resources and data inspected.** `project.godot`, `export_presets.cfg` (secrets not read into this report), `.gitignore`; autoloads `boot_context.gd`, `save_service.gd`, `localization_service.gd`; `game_ui.gd` (HUD/panel host, 3,192 lines, 181 KB), `simulation.gd` (1,568 lines), `campaign.gd` (2,035 lines; reveal, fog, offline settlement, Prestige keep list, normalisation), `guided_progress.gd`, `tutorial_guide.gd`, `world.gd`, `fog_layer.gd`, `season_weather.gd`, `map_view.gd`; `scenes/game/main.tscn` structure and `scenes/game/stages/stage_1..8.tscn`; `resources/game/*.tres`; `data/game/catalog.json` (397 items: 336 outfits, 42 skills, 14 weapons, 5 supplies; 48 groups, 14 bosses; 8 stages); `localization/en.po` (1,908 msgids); `tools/run_probes.py`, `tools/validate_campaign_source.py`; the exported AAB's file list.

**Tool limits.** No Android device or ADB session; no GPU profiler; no store console access. Desktop measurements rank suspects; they are not phone results. The 2026-10-28 run of the maintained suite is the only fresh test evidence; earlier pass counts in the change reports are history.

---

## 2. Executive status matrix (Playbook 0.9, 20 stages)

Legend: **Done** (implemented and evidenced), **Dev-accepted** (developer judged on Android), **Partial**, **Open**, **N/A**.

| # | Stage | Status | Evidence / gap |
|---:|---|---|---|
| 1 | Concept & GDD | Done | `LootFarmer_GDD.md` (now with a current-status section, see §8) |
| 2 | Bootstrap & Android validation | Done | Signed AAB builds 7–22 exist; developer installs and plays on Android |
| 3 | Core gameplay | Done, dev-accepted | Movement/targeting/attack timing probes pass; developer playtests |
| 4 | Variety & mechanics | Done | 48 characters, 14 bosses, skills, summons; content probes pass |
| 5 | Restart/debug/tools | Done | Hard Reset, probe profiles, `--first-run-complete`, prepared fixtures |
| 6 | Progression & unlocks | Done | Upgrades, Prestige (33 opportunities/cards), Map Mastery, reveal table |
| 7 | Save/resume/offline | Done in source; device interruption checks open | Atomic temp+rename+backup save; offline pending claim; see SAVE-01..03 |
| 8 | Objectives & completion | Done in source | Final boss, 13 keys, Map Mastery 100%, The Road Ahead |
| 9 | Secondary systems | Done | Missions, automation, supplies, Farming Guide, trackers |
| 10 | UI/UX & onboarding | Done in source | Guided/Basic/None; Change 20–23 corrections |
| 11 | Assets/animation/effects/audio | Done in source; provenance open | AST-01..05 |
| 12 | Feature/content completion | **Done (scope frozen by brief)** | No missing GDD feature found; see §3 |
| 13 | UI/UX refinement & Android validation | **Partial** | Developer device testing continuous; Change 22/23 fixes not yet in any build; final UI revision list in §6 |
| 14 | Balance & full playthrough | **Stages 1–5 developer-accepted on Android. Stages 6–8 open.** | Late benchmark `change_9_balance` last recorded 33/35 (Change 17), not re-run here (balance runs are deliberate, Playbook 60.1) |
| 15 | Performance & stability | **Open — not started on device** | Desktop harness found four concrete hotspots (§5); no phone profile exists |
| 16 | Demo generation, stripping & validation | **Documented, not started** (approved scope: Winter I/II) | Playbook 0.9.1; prerequisites in §9 |
| 17 | Play Store prep & marketing | Open | Toolkit 1.0.2 pinned and installed; no `marketing/` adapter, no captures, no copy (MKT-01) |
| 18 | Release candidate & final Android validation | Open | Needs exact-artifact play of a build ≥ b51a209 |
| 19 | Google Play publishing | Open | Price, Data safety, content rating, listing |
| 20 | Post-launch | N/A yet | — |

**Headline:** the game is feature-complete and developer-validated through Stage 5. The remaining production work is concentrated in Stage 13 (final UI revision), Stage 14 (Stages 6–8 acceptance) and Stage 15 (performance). Stage 15 has had no device measurement, and the desktop run already shows recurring hitches worth fixing before release. Release-gate items (icon, asset provenance, 19 translations, store assets) are known future work rather than defects.

---

## 3. GDD feature matrix

Status: **V** verified by fresh automated run or inspection; **V-dev** also developer-accepted on device; **NC** needs correction; **DEV** requires physical Android verification; **DOC** documentation conflict.

| Subsystem | Approved behavior / source | Implementation evidence | Test evidence (2026-10-28 run) | Status | Issue |
|---|---|---|---|---|---|
| Eight-stage campaign, gates, Spring II completion, final boss + 13 keys | GDD "Eight-stage world" | `catalog.json` stages/groups; `campaign.gate_status`, `stage_*.tscn` | campaign_probe 262/0, campaign_content_probe 98/0, change_13 154/0 | V (1–5 V-dev) | BAL-01 |
| Movement, targeting, attack contact | GDD core loop; Playbook 13.2 | `simulation.step`, `_combat_target`, single-contact attack | targeting 23/0, attack_timing 49/0, gameplay 72/0 | V-dev | — |
| Solid scenery / walking | GDD Change 8 | stage StaticBody2D solids | change_8_walk 2,178/0 | V | — |
| Fog: explored vs vision, camp sighting, boss found, reachable 100% | GDD Map and discovery; Ch 15/16 | `campaign.reveal*`, `fog_layer.gd`, `fog_rules.tres` | change_15/16/12 fog sections pass | V | PERF-03 |
| Skills, cooldowns, 64-unit activation, Heal exception | GDD Skills; Ch 19/20 | `campaign.skill_cast_block_reason` | skill_proximity 133/0, change_17 679/0 | V | — |
| Enemy skills, telegraphs, summons, final boss kit | GDD Ch 12–13 | `enemy_abilities.tres`, `campaign` boss AI | change_12 149/0, change_13 154/0 | V | BAL-01 |
| Inventory 70 slots, merges, evolution, copy growth, outfit milestones | GDD Inventory; Ch 9/10 | `simulation.gd` merge/evolve | change_9/10 pass, inventory 119/0 | V | PERF-04 |
| Auto-Merge, Auto Evolution, per-item exclusion | GDD Ch 13, Ch 20 | `campaign.automate` | change_13, change_20 (automation sections pass) | V | — |
| Supplies, mastery (use-based), 6 slots, auto-use | GDD Ch 11/17/20/21 | `simulation.supply_*` | change_11/17/21 pass | V | — |
| Coins/Gems economy, per-map 1.5 / 1.55 | GDD Ch 16 | `catalog.progression`, `change16_catalog.py` | change_16 197/0, validator 1,570/0 | V (1–5 V-dev) | BAL-01 |
| Missions, Main Objectives, follow, Auto-Claim | GDD Missions; Ch 22/23 | `campaign` missions; `game_ui` toggle | change_14/16 pass; change_22 38/1 | NC (copy) / DEC | UI-04, UI-05 |
| Prestige: entry, batch redeem, keep list, confirmation, stage sections | GDD Prestige; Ch 16/20/21/23 | `campaign.choose_card` keep list incl. `prestige_collapsed` | change_16/20/21/22 Prestige sections pass | V | DOC-03 |
| Map Mastery | GDD Ch 15 | `mastery.gd`, `mastery_rules.tres` | change_15 Mastery sections pass | V | — |
| Offline earnings: pending claim, exactly-once | GDD Offline; Playbook 58 | `campaign.settle_offline` / `claim_offline`, rollback if save fails | gameplay/change_7 offline sections pass | V in source; DEV | SAVE-03 |
| Death/respawn, camp rest | GDD core loop | `simulation.step` respawn | gameplay probe | V-dev | — |
| Hard Reset | GDD; Playbook 27 | `SaveService.hard_reset` + provider resets, backup overwritten | change_15/16/20 Hard Reset sections | V | — |
| Onboarding: Guided / Basic / None, reveal table, Road Ahead | GDD Ch 15/20/22/23 | `onboarding.gd`, `guided_progress.gd`, `tutorial_guide.gd` | **change_15 172/13, change_20 81/17, change_5 159/1 (stale fixtures)**; change_22 38/1 | NC (tests) / DEC | TEST-01, UI-05 |
| Confirmation dialogs (Drop All, Hard Reset) | Ch 22 | `_layout_confirm` settle with generation token | change_22 modal checks pass | V source; DEV | UI-01 |
| Audio cue set, music hold | GDD Ch 12/16 | `audio_cues.tres`, `AudioService._sync_music` | change_12 audio sections pass; windowed check `change_16_audio` not run | V source; DEV | AST-02 |
| Localization infrastructure | Playbook 0.11/132 | `localization_service.gd` English-only gate; 1,908 keys | validator translation checks pass | Partial | LOC-01..03 |
| Settings, slot density, Help | GDD Ch 16/20 | `game_ui` settings | change_16/20 settings sections pass | V | — |
| Android packaging | Playbook 49/88 | `export_presets.cfg` | AAB 22 inspected | Partial | REL-01..05 |

No GDD feature was found missing or unreachable in source. The open items are corrections, tests, device acceptance and release assets.

---

## 4. Prioritized findings ledger

Format per finding: **ID · Severity · Classification**, then evidence, impact, root cause (verified or hypothesis), remedy, acceptance test, phase.
Classifications: **Verified** (fact established in this audit), **Needs correction**, **Missing**, **Physical Android verification** (cannot be settled off-device).

### 4.1 Release-blocking

**REL-01 · P0 · Missing — Store/launcher icon is a placeholder.**
Evidence: `icon.svg` is a 192 px "LF" monogram on a flat green square. `export_presets.cfg` `launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432` and `adaptive_monochrome_432x432` are all empty, so Android uses the project icon for every density.
Impact: the store listing and the launcher show a placeholder; adaptive-icon masks may crop it badly.
Remedy: produce the final icon from the game's own pixel art (Playbook 101), plus adaptive foreground/background/monochrome at 432 px, and set the four preset fields. Phase: Stage 17 (asset), verified in Stage 18.
Acceptance: an exported build shows the final icon in the launcher on two launchers (round and squircle masks), and the 512 px Play icon matches.

**REL-02 · P0 · Missing — Licence/provenance records for shipped audio and Pixel Plains.**
Evidence: `LootFarmer_Asset_Registry.md` lines 38–42 and 91: `assets/sounds` (in use: `background_music.wav`, `ui_confirm.wav`, `mission_ready.wav`, `reveal_unlock.wav`, `stage_clear.wav`) has no licence record in the repository; the Pixel Plains packs carry only `ReadMe.txt`. `assets/Audio` is documented as original sine tones; Kenney, Willosuna spell packs and DejaVu have licence files.
Impact: publishing without a retained licence record for shipped audio and art is a legal risk.
Remedy: the developer adds the purchase/licence records (receipt or licence text) for Pixel Plains and the origin of the `assets/sounds` set to the repository or a private release folder, and the registry links them. Phase: before Stage 18.
Acceptance: every packed asset directory in the release artifact maps to a licence record in the registry.

**REL-03 · P1 · Physical Android verification — Android back gesture may quit the game instead of closing a panel.**
Evidence: `game_ui.gd:1053` closes the confirmation/panel on `ui_cancel`; no code handles `NOTIFICATION_WM_GO_BACK_REQUEST`, and `project.godot` does not set `application/config/quit_on_go_back` (Godot default `true`).
Hypothesis: on Android the system back gesture arrives as a go-back request and quits before the panel closes.
Remedy (if confirmed): set `quit_on_go_back=false`, handle `NOTIFICATION_WM_GO_BACK_REQUEST` (close confirmation → close panel → otherwise a quit confirmation or move-to-background), and save on that path.
Acceptance: on the phone, back with a panel open closes the panel; back with a confirmation open cancels it; back on the bare HUD does not lose progress.

**REL-04 · P1 · Verified — No exported build contains the latest fixes.**
Evidence: newest artifact `builds/LootFarmerIdleRPG.22.aab` (2026-10-27 18:45) is older than b51a209 (2026-10-28 06:10). The Change 22 notes record that their probe was not run at the time.
Impact: dialog flicker, Auto-Claim guidance, Prestige stage sections and the real-time tutorial waits have never been on a phone.
Remedy: after TEST-01 is fixed, bump the version (DOC-02), export, and run the Change 22 device checklist.
Acceptance: an installed build whose Settings version equals the committed version, with the Change 22 checklist ticked.

**REL-05 · P2 · Verified — Android export ships x86/x86_64 engine libraries.**
Evidence: every `architectures/*` entry in `export_presets.cfg` is `false` (since commit f397381, Change 7). The AAB nevertheless contains `base/lib/{arm64-v8a,armeabi-v7a,x86,x86_64}`, about 26 MB compressed each.
Impact: Play delivers per-ABI splits, so player download size is mostly unaffected. Upload size and build time grow, and the preset does not say what is intended.
Remedy: select `arm64-v8a` (required) and `armeabi-v7a` explicitly. Acceptance: AAB lists only the two ARM ABIs; the game installs and runs on the test phone.

**REL-06 · P2 · Verified — Unused packs and variants are exported.**
Evidence: `export_filter="all_resources"`. The AAB contains 1,863 Pixel Plains files, 283 Kenney files, 413 animation-pack files, plus `Zombies Free ver` (5), `PP Pumpkins Set Free` (4) and `LootFarmer-seasonal-animation-sheets` (56), which have **zero** references in scripts, scenes, resources or data. Some art paths are built at runtime (`game_ui.gd:22` `Item-%d.png`), so a grep allowlist alone is insufficient.
Impact: larger artifact and import time. More importantly, this is the blocker for the Stage 16 demo, which needs a dependency-verified allowlist.
Remedy: build an export allowlist from real dependencies plus the runtime-constructed item indices (catalog icons, `MASTERY_ART`, `_art()` indices). Put `.gdignore` on reference-only packs. Re-run a headless load of every packed scene. Playbook 22.2 and 0.9.1.
Acceptance: the AAB file list equals the allowlist, the game loads every stage and panel, and `tests/` still pass.

### 4.2 Performance (Stage 15)

All numbers come from the desktop harness (§5) and rank suspects. Every item needs before/after measurement on the phone.

**PERF-01 · P1 · Verified (desktop) + Physical Android verification — Whole-profile save every ~5 s of play.**
Evidence: `simulation.gd:1183-1186` calls `SaveService.mark_dirty()` every 2 s of active play; `save_service.gd:51-53` flushes on a 5 s timer. `save_now()` serialises the whole state, writes a temp file, **parses it back** (`_read(temporary)`), **parses the previous primary** (`_read(path)`), copies it to `.bak` and renames. Desktop with a late-game profile (all 8 maps explored, 70 items): file 466 KB; `save_now` p50 **125 ms**, JSON.stringify 24 ms, one JSON parse 33 ms.
Impact (hypothesis to confirm): a visible hitch every ~5 s on phones, growing with exploration (Prestige keeps explored cells since Change 16, so the save only grows).
Root cause (verified): validation by full re-parse (two parses per save) plus a per-cell string-keyed `explored` dictionary (30,864 keys at 100% exploration).
Remedy, in order of risk: (1) validate the temp file by size plus a cheap header or hash instead of parsing it, and do not parse the old primary (keep the version in memory); (2) lengthen the coalescing timer for ordinary progress, keeping immediate saves at committed boundaries (claims, purchases, Prestige, travel, background), as Playbook 30 describes; (3) later and as a schema change, store explored cells per map as a compact bitset string. Keep atomic temp+rename+backup.
Acceptance: phone trace shows no recurring save spike above the agreed budget; force-kill during play loses at most the agreed rollback window; the save probes and a real JSON/disk round trip still pass.

**PERF-02 · P1 · Verified (desktop) — Teleport/stage switch blocks a frame for 300–420 ms.**
Evidence: `world.gd:58-73` `load()`s and instantiates `stage_%d.tscn` inside `_process` when the stage changes. Desktop scenario `stage_switch_every_40f`: p99 284 ms, max 422 ms. No node leak afterwards (5,000 → 5,000).
Remedy: start `ResourceLoader.load_threaded_request` for the destination when travel is confirmed, and swap behind a short fade; optionally keep the previous stage scene cached.
Acceptance: on the phone, travel shows no frozen frame longer than the agreed budget; all travel/teleport probes pass.

**PERF-03 · P1 · Verified (desktop) — Spring II and Summer II rain: heavy per-frame CPU.**
Evidence (desktop frame interval): Winter I idle mean 3.1 ms; Summer II rain farming mean 10.5 ms, p95 14.6 ms; Spring II rain farming (135 actors at max spawn) mean 14.2 ms, p95 22.2 ms, p99 27.2 ms; Spring II exploring unexplored ground p99 31.9 ms, max 51 ms. Pure `simulation.step` on Spring II p50 4.7 ms, p95 5.6 ms.
Contributing code (verified by reading; costs not individually profiled):
- `world.gd:74-131` updates **every** actor on the map every frame, on screen or not: `enemy_definition()`, `campaign.can_see()` (which re-derives `player_radius()` bonuses), `load(attack sheet)` per actor per frame, and two `catalog.art_id()` calls.
- `simulation.step` duplicates the enemy array twice per tick and builds `[p]+state.enemies` (`simulation.gd:1091,1130,1179`).
- `season_weather.gd:51-…` redraws every frame on rainy maps and formats a `"%d,%d"` key per particle for the fog test.
- `fog_layer.gd:16-…` redraws the whole map (7,744 cells on Spring II), formatting a string key per cell, every time the player crosses a 24-unit cell or discovery changes; `map_view.gd` redraws every explored cell as its own rect on discovery changes.
Impact (hypothesis): a 3–5× slower phone CPU puts Spring II and Summer II well under 60 fps, matching the "later wet maps" concern in Change 17.
Remedy candidates (each measured before/after, appearance unchanged): cull or slow-update off-screen actor views; cache per-group definitions and attack textures in the view; precompute fog visibility into a packed array or texture once per discovery change and sample it in weather and fog; reuse the actor arrays in `step`.
Acceptance: phone profile of the same scenarios meets the targets agreed after the first phone measurement; weather equivalence probe (`change_17_weather` 60/60) and fog probes still pass; side-by-side captures show identical rain and fog.

**PERF-04 · P1 · Verified (desktop) — Inventory HUD relayout on every kill.**
Evidence: `game_ui.gd:303-305` runs `_refresh_slots()` whenever `sim.revision` changes (every kill, at the 0.15 s HUD tick). `_refresh_slots()` always ends with `_layout_inventory()` (`game_ui.gd:588`), which re-applies `custom_minimum_size`, offsets and three `add_theme_font_size_override` calls to every slot (70 gear + 6 supply). Desktop: 8.4 ms per call with **unchanged** contents, 25 ms forced.
Remedy: call `_layout_inventory()` only when slot count, zoom or column width changed; compare before writing overrides.
Acceptance: per-kill HUD cost on the phone drops below the agreed budget; inventory_probe 119/0, change_20/21 density sections pass.

**PERF-05 · P2 · Verified (desktop) — Panel open/close and Prestige panel spikes.**
Evidence: `spring2_panel_open_close_every_15f` max 74 ms, p99 39 ms; `spring2_prestige_panel_open_farming` max 39 ms. After 32 open/close cycles: nodes 5,000 → 5,009, objects 10,358 → 10,415 (small; may be cached styles or queued frees).
Remedy: measure on the phone first; if spikes are visible, reuse panel rows (the reconciler already diffs) and pre-warm the Prestige sections.
Acceptance: no visible stutter opening panels on the phone; repeated open/close over 10 minutes shows flat node and object counts.

**PERF-06 · P2 · Physical Android verification — Startup time and memory.**
Evidence (desktop): main scene `load()` 1.09 s, instantiate 19 ms, first two frames 564 ms. Static memory rose from 69 MB (Winter I) to 117 MB after visiting every stage. That is plausibly caches rather than a leak, since nodes were flat across stage switches.
Remedy: measure cold start and memory on the phone; consider a lighter boot scene with threaded load if cold start exceeds the agreed target.

**PERF-07 · P3 · Verified — 23 MB WAV music.**
Evidence: `assets/sounds/background_music.wav` is 23,357,926 bytes. The packed import is smaller (all imported resources together are about 10 MB in the AAB), so the import compresses it.
Remedy: consider an OGG source for a smaller repository and stream decode; listening check required.

### 4.3 UI/UX (Stage 13 + final revision)

**UI-01 · P1 · Physical Android verification — Change 22 dialog stability, Auto-Claim guidance, Prestige sections and 15 s real waits are untested on device.** Evidence: REL-04; change_22_probe passes its modal, wait and Prestige checks headless. Acceptance: the Change 22 device checklist (`LootFarmer_Change_22_Notes.md`) on a build ≥ b51a209.

**UI-02 · P1 · Physical Android verification — Final responsive pass across shapes and safe areas.** Evidence: all rendered evidence is desktop 540×960 captures (Change 20/21 reports say so explicitly). Items to check on the phone: trackers above the joystick at 20:9; banner/objective/Next Stage stacking; the 70-slot dock at Small density; Prestige confirmation on a small phone; rain readability of HUD chips; tap targets on the camp picker and map camps (24 px icons, 64 px hit area). Acceptance: the UI checklist in §6 signed off on at least two aspect ratios (the developer's phone plus a narrow 20:9 or small device, or Android emulator for layout only).

**UI-03 · P2 · Needs correction — Long-term maintainability of the HUD host.** Evidence: `game_ui.gd` is 181 KB, with lines up to 420 characters; most panels are built in code by factory helpers. Editor-authored parts exist (`main.tscn`, `slot.tscn`, `action_row.tscn`, `info_card.tscn`, `prestige_card.tscn`, the `.tres` style/rule resources). Impact: visual tweaks need code edits (Playbook 63.1 partial). Remedy: **do not refactor before release**; after release, move panel shells into scenes one panel at a time.

**UI-04 · P3 · Needs correction — Auto-Claim toggle text.** Evidence: `change_22_probe` fails "OFF toggle is clearly exposed in Missions". `MISSION_AUTO` renders "Automatic claiming: Off" (`en.po` `OFF` → "Off"), while the Change 22 brief specified "Automatic Claiming: OFF". Remedy: either uppercase the state word for this toggle or update the probe to the approved copy, as the developer prefers.

**UI-05 · P2 · Needs correction (decision) — None mode now shows a pointer for Auto-Claim.** Evidence: `tutorial_guide.gd` `evaluate()`: `if data.mode=="none": if not _road_ahead_if_ready(data): _mission_auto_hint()`, and `_present()` lets `mission_auto_hint` draw the pointer. GDD Change 15: "None: no guide at all (no card, pointer or tip)"; Focused Farming's hint explicitly excludes None. `change_22_probe` asserts the pointer in None, so it was deliberate in that batch, but no GDD line approves it. Remedy: developer decides. Either (a) keep the hint and record it in the GDD as the second exception to None (with The Road Ahead), or (b) suppress the pointer in None and keep the inline text hint in the Missions panel. Acceptance: GDD, probe and behaviour agree.

**UI-06 · P2 · Physical Android verification — Respawn countdown and world text legibility at all zoom levels.** Evidence: Change 21 changed the countdown to a half-scale 32 px label with linear filtering (`world.gd:346-352`). Desktop captures only.

### 4.4 Assets and presentation

**AST-01 · P2 · Verified — Asset registry is out of date.** The registry header still reads "Change 6", and the export-inclusion facts above are not recorded. A 2026-10-28 section was added (see §8).

**AST-02 · P2 · Physical Android verification — Audio mix and music hold.** The windowed playback check `tests/change_16_audio` is outside the suite and was not run here. Listen on the phone for: music hold at volume 0 and on pause, skill cast overlap in Spring II boss fights, and notification cue stacking.

**AST-03 · P2 · Physical Android verification — Animation/effect alignment on bosses.** Effect placement is data-driven (`skill_effects.tres`) and probed arithmetically (change_14). Visual alignment for 2×/2.5× bosses was checked in desktop captures only.

**AST-04 · P3 · Verified — Docs evidence images were imported by Godot.** Commit 5388da7 added `.png.import` files under `docs/Change_10..16_Evidence/ui/`. Later evidence folders have `.gdignore`; older ones do not. `docs/*` is excluded from export, so there is no release impact, only editor import noise. Remedy: add `.gdignore` to the older evidence folders and remove their `.import` files in a cleanup batch.

**AST-05 · P3 · Verified — `docs/LootFarmer_Enemy_Roster.csv` is imported as translations.** `docs/LootFarmer_Enemy_Roster.*.translation` exist; they are not registered in `project.godot` and are excluded from export (Playbook 132.6 / 135.4 trap). Remedy: add `.gdignore` coverage for `docs/` or rename to `.tsv`.

### 4.5 Progression, save and persistence

**BAL-01 · P1 · Physical Android verification — Stages 6–8 acceptance.** The developer reports Stages 1–5 feel well balanced on Android; this audit preserves that and proposes **no** balance change. Stages 6–8, the final boss, the 13-key route and late Prestige pacing need device playthrough. The last recorded `change_9_balance` result is 33/35 (Change 17 validation). It was not re-run here and should be run once, deliberately, when Stage 6–8 acceptance starts. Acceptance: the developer's verdict per stage, plus any evidence-driven change approved separately.

**SAVE-01 · P1 · Physical Android verification — Interruption at save time.** Source: temp-file write, read-back, backup copy, rename; on a bad primary the backup loads (`save_service.gd:84-97`). Device checks: force-stop during play (expect at most ~5 s rollback); force-stop during a Prestige choice (batch resumes); kill right after a purchase or claim; low-storage behaviour (a `save_failed` notice appears).

**SAVE-02 · P2 · Verified — Development reset policy still active.** `save_service.gd:93` "Development-only policy: obsolete or unreadable profiles start fresh." Before any public build (open testing or release), the developer must declare the release phase (Playbook 61.2). From then on, schema changes need migrations, and an unreadable profile with no valid backup should be preserved (renamed aside), not silently replaced.

**SAVE-03 · P2 · Verified — Offline clock behaviour.** `campaign.offline_snapshot()` keeps the maximum of the stored and current time, so setting the clock back pays nothing until real time catches up. Setting it forward pays up to the per-interval cap, and each absence is capped separately. No network time exists (by design: offline game, no tracking). Remedy: none required; document as accepted behaviour.

**SAVE-04 · P3 · Verified — Offline settlement deep-copies the whole state on resume.** `campaign.settle_offline` does `sim.state.duplicate(true)` then `save_now()`. That is a one-time cost per resume, part of PERF-01's save cost.

### 4.6 Localization

**LOC-01 · P0 (release gate) · Missing — 19 translations.** Only `localization/en.po` exists (1,908 msgids). Release requires all 20 languages validated (Playbook 0.11/132). Do not start until the localization freeze, after the final UI revision.

**LOC-02 · P2 · Needs correction (decision) — Settings shows only Automatic and English.** Evidence: GDD Change 16: "Automatic and English only in the language list". Playbook 0.11/132.2 requires the 19 other languages **visible but disabled**. This is a deliberate developer decision that conflicts with the reusable rule. Remedy: the developer confirms the exception for LootFarmer, or the 19 disabled entries are restored before the freeze.

**LOC-03 · P1 (pre-freeze) · Missing — Script fallback fonts and text-server data.** Only `assets/Fonts/DejaVuSans.ttf` exists. No Devanagari, Thai or CJK fallbacks, and `internationalization/locale/include_text_server_data` is not set. These are needed before the Thai/Japanese/Chinese batches (Playbook 132.6).

### 4.7 Tests

**TEST-01 · P1 · Verified — Maintained suite is red: 27/30.**
Evidence (run 2026-10-28, §7): `change_20_probe` 81 checks / 17 failures, `change_15_probe` 172/13, `change_5_probe` 159/1. Every failure traces to approved Change 22/23 behaviour:
- Guided waits now accumulate real frame seconds in `TutorialGuide._process` (`tutorial.flow.wait_seconds`, 15 s) instead of `playtime_total` (Change 21 said 60 s). The older probes advance only the simulation clock, so "Missions appear at delay boundary" fails and **every later Guided step cascades** (boss lesson, inventory lesson, World lessons, final message, completion persistence).
- The Road Ahead now shows in Basic and None (Change 22), so "None mode has no instruction" (change_5) and "None: no card, pointer or tip" (change_15) fail. The Basic card list includes `road_ahead`.
Classification: stale contracts (Playbook 60), **not production regressions**. However, the Guided end-to-end flow after the mission wait currently has **no passing automated coverage**.
Remedy: update the three probes to drive the real-time wait (advance `TutorialGuide._process` or `guided.advance_waits()`), expect 15 s, and accept The Road Ahead in None/Basic, with UI-05 decided first.
Acceptance: the suite is 31/31 green (with TEST-02), and every Guided step from move to `tutorial_final` is asserted again.

**TEST-02 · P1 · Verified — `change_22_probe` is not in the maintained suite and has one failure.** Evidence: `tools/run_probes.py` `SUITE` has no `change_22_probe`; manual run 38 checks / 1 failure (UI-04). The Change 22 notes say it was "Not executed in this environment". Remedy: register it, fix per UI-04.

**TEST-03 · P2 · Verified — Validator writes into a historical evidence folder.** `tools/validate_campaign_source.py:114` writes `docs/Change_21_Evidence/static_checks.json`, so every run dirties a tracked file. During this audit it was restored with `git checkout`, and the run's output was kept in the scratchpad. Remedy: write to an ignored path (for example `tests/tmp/`).

**TEST-04 · P2 · Missing — No automated performance gate or device scenario.** The harness used here (§5) is a scratch script; `tests/change_17_performance.gd` measures simulation CPU only. Remedy: promote a deterministic scenario scene (Spring II rain, max spawn, full inventory) into `tests/` as a **non-gating** benchmark with the §5 output format, runnable on desktop and through the remote debugger on the phone.

### 4.8 Marketing and store (Stage 17, future gates; nothing generated)

**MKT-01 · P1 (future gate) · Missing — Store production not started.** Godot Marketing Capture Toolkit **1.0.2** is pinned (`marketing_capture_toolkit.lock.json`, `"status": "released"`) and its addons are installed (`addons/marketing_capture`, `addons/store_screenshot_capture`); `Godot-Marketing-Toolkit/` is vendored. There is no `marketing/` adapter or manifest yet. Remaining deliverables:
- authentic language-neutral screenshots for every applicable device class (Phone, 7″ and 10″ tablet; portrait 9:16), raw masters retained (Playbook 87);
- 512 px Play icon (REL-01) and the 1024×500 feature graphic;
- the 30-second store trailer;
- **10 master social videos (5 focused + 5 full-landscape)** with one posting-copy entry each;
- English ASO (title ≤ 30, short ≤ 80, full ≤ 4,000 characters) policy-checked and approved, then 19 localized listings via the 20-locale Play import handoff;
- localized release notes;
- final Play listing validation;
- Data safety (no data collected, no network), content rating, one-time price, countries.

Toolkit health (`status` against the lock) was not run in this audit. Trigger: after the final UI revision (Playbook 87.8). The demo (Stage 16) needs its own listing and screenshots.

### 4.9 Documentation

**DOC-01 · P2 · Verified — Active docs disagree on current values.** Examples:
- The Upgrade Catalog Change 21 section and `LootFarmer_Prototype_Status.md` say "Guided Missions unlock **60** active gameplay seconds", while the GDD, State Contracts and runtime (`progression.change20.mission_delay`) say **15 real active seconds**.
- The README entry point still says "Change 20", the GDD header says "Change 21" and the Content and Balance header says "Change 17".
- The Prestige Catalog still states the Change 6 Winter II reset gate, superseded by Change 8, 10, 15 and 16.

Remedy: corrected or annotated in this audit (§8). The catalog bodies are left as historical records.

**DOC-02 · P2 · Verified — Change numbering and version drift.** The commit "Change 23" (b51a209) delivers `LootFarmer_Change_22_Notes.md`; commit "Change 22" (1286472) delivered `Final_Tutorial_Announcement_Change.md` and bumped the version to 22. Remedy: the developer chooses the canonical numbering. Next build: bump `config/version` and `version/code` to 23 so the installed build identifies the Change 22/23 code.

**DOC-03 · P3 · Verified — Playbook sections 138–146 are project-labelled change batches.** The brief asks for owning-section updates. New lessons from this audit were merged into owning sections (§8). Folding 138–146 into their owners is recommended for a later documentation pass; doing it now would be a large rewrite with no release value.

---

## 5. Performance section

### 5.1 Measured desktop baseline (not Android)

Harness: `-s` SceneTree script outside the project (scratchpad `perf_audit.gd`), real `main.tscn`, profile `probe-audit-perf`, `--no-autosave`, V-Sync off, 540×960 window, Godot 4.7.2 Compatibility renderer, GTX 1650 / i5-10300H, physics 60 Hz. Fixture: fresh profile, then a late-game profile (70 gear identities, 6 supplies, level 240, Emerald Sword, three skills on auto, maximum spawn upgrades on the current map, map fully explored, focus farming the strongest normal type). Frame interval measured with `Time.get_ticks_usec()` around `process_frame`. `Performance.TIME_PROCESS` was recorded but discarded as unreliable for per-frame cost in this harness (it reported values larger than the frame interval).

| Scenario | Frames | Mean ms | p50 | p95 | p99 | Max | Draw calls mean/max | Nodes | Enemies |
|---|---:|---:|---:|---:|---:|---:|---|---:|---:|
| Winter I, fresh, idle | 600 | 3.10 | 2.85 | 4.42 | 4.93 | 6.08 | 102 / 109 | 1,135 | 28 |
| Winter I, full inventory, farming | 900 | 6.01 | 5.23 | 8.04 | 11.40 | 56.17 | 157 / 175 | 1,953 | 55 |
| Summer II rain, full, farming | 900 | 10.52 | 10.99 | 14.57 | 21.61 | 27.50 | 162 / 189 | 3,819 | 122 |
| Spring II rain, full, farming | 900 | 14.15 | 13.21 | 22.21 | 27.20 | 37.38 | 145 / 184 | 5,009 | 135 |
| Spring II rain, walking into unexplored fog | 600 | 15.74 | 13.66 | 22.32 | 31.93 | 51.28 | 136 / 170 | 5,000 | 135 |
| Spring II rain, standing in fog | 600 | 17.73 | 15.33 | 36.07 | 45.92 | 54.08 | 132 / 133 | 5,000 | 135 |
| Spring II, panel open/close every 15 frames | 960 | 16.69 | 15.94 | 29.44 | 39.13 | 74.38 | 201 / 307 | 5,008 | 135 |
| Spring II, Upgrades panel open, farming | 600 | 11.00 | 11.03 | 12.63 | 21.94 | 30.13 | 271 / 301 | 5,107 | 135 |
| Spring II, Prestige panel open, farming | 600 | 11.74 | 11.09 | 17.51 | 23.96 | 39.23 | 240 / 245 | 5,194 | 135 |
| Stage switch every 40 frames (all 8 maps) | 320 | 15.21 | 5.44 | 22.62 | 283.70 | 422.03 | 132 / 136 | 5,000 | 135 |

| Micro-benchmark | Result |
|---|---|
| `SaveService.save_now()` late-game state | p50 125.0 ms, max 128.1 ms; file 465,980 bytes; 30,864 explored-cell keys |
| `JSON.stringify(state)` / `JSON.parse_string` | 23.8 ms / 32.9 ms (p50) |
| `game_ui._refresh_slots()` 70 slots | forced full p50 25.2 ms; unchanged signatures p50 8.4 ms |
| `simulation.step(1/60)` Spring II, 135 enemies | p50 4.70 ms, p95 5.60 ms, max 9.25 ms |
| Startup | `load(main.tscn)` 1,085 ms; instantiate+ready 19 ms; first two frames 564 ms |
| Leak checks | 32 panel cycles: nodes +9, objects +57. 8 stage switches: nodes +0 |

Spring II "standing in fog" was slower than "farming". The variance between runs of the same scenario was not measured; treat differences under ~3 ms as noise. One run per scenario; no averaging across runs.

### 5.2 Interpretation

- Frame time scales with **actors × per-actor view work**, with **weather redraw** and with **fog cell count**. The two rainy maps are the worst ordinary play, as the brief anticipated.
- Recurring hitches come from **saves (≈125 ms every ~5 s late-game)**, **stage switches (≈300–420 ms)** and **per-kill inventory relayout (≈8 ms)**. Spikes like these are what players feel as stutter, independent of average FPS.
- GPU load could not be assessed: draw calls stay modest (≤ 307), but fill rate and overdraw of the fog veil plus rain on a phone GPU are unknown.

### 5.3 Android profiling plan (developer steps; targets to be agreed afterwards)

1. **Build:** export an Android **release-like** build from a commit ≥ b51a209, plus a debug build with remote debug for monitors. Record the phone model, Android version, SoC, resolution, refresh rate and thermal state (start cool, plugged in or not, noted).
2. **Scenarios** (same as §5.1, reproduced in game or via a prepared save): Winter I idle; Summer II rain farming; Spring II rain farming with maximum spawn and a full inventory; walking into fog; teleporting between camps on different maps 10 times; opening and closing every panel 10 times; Prestige panel open during combat; 30 minutes of continuous Spring II farming (long-session test); background → resume ×5; Prestige once.
3. **Tools:** Godot remote debugger (Profiler, Monitors: FPS, process/physics time, draw calls, objects, static memory) over USB; Android GPU Inspector or Perfetto (`adb shell perfetto` with gfx/view/sched categories) for GPU and frame pacing; `adb shell dumpsys gfxinfo <package>` for jank counts; a stopwatch for the 15 s tutorial waits; `adb shell dumpsys meminfo <package>` at the start and after 30 minutes.
4. **Record:** frame-time p50/p95/p99/max per scenario, hitch count above 50 ms and 100 ms, memory start/end, battery/thermal throttling after 30 minutes, cold start to first interactive frame.
5. **Agree targets with the developer from those numbers** (for example a p95 frame-time target on the developer's phone and a maximum single-frame hitch). This report intentionally sets none.
6. **Optimize in small batches** (§9), re-run the same scenarios, compare the same percentiles, and confirm visuals are identical (rain/fog side-by-side captures, change_17_weather equivalence).

---

## 6. UI and asset review

### 6.1 Surfaces

| Surface | Implementation | Findings | Editor-editable? | Device-validated? |
|---|---|---|---|---|
| HUD top band (HP, XP, coins, gems, pause) | `main.tscn` + `game_ui._process` 0.15 s tick | Writes text only on change for most chips; HP/XP text rebuilt every tick (cheap) | Scene nodes: yes | Dev-accepted earlier builds |
| Map cluster (zoom, Mastery chip, Map Explored, minimap, Next Stage, objective) | `main.tscn`, `map_view.gd` | Minimap redraws every explored cell on discovery (PERF-03) | Chips in scene; minimap drawing in code | Pending for Change 21 stacking |
| Trackers (mission, Prestige) | `_layout_trackers` | Positions set every tick; fine on desktop | Code-positioned | UI-02 |
| Dock inventory (gear/supplies, density) | `slot.tscn` + `_layout_inventory` | PERF-04 | Slot scene yes; sizing in code | UI-02 |
| Bottom sheet panels (Missions, Upgrades, Prestige, World, Mastery, Filters, Settings, Stats, Help, Farming Guide, item/enemy/camp) | `game_ui` factories + reconciler | Settled reveal; scrollbars Change 21; PERF-05 | Mostly code-built (UI-03) | UI-01/02 |
| Confirmations (Drop All, Hard Reset, reveal all) | `$Confirm` + `_layout_confirm` | Change 22 settle + generation token | Scene shell yes | UI-01 |
| Prestige confirmation | `prestige_confirm.tscn` | Safe-area sized, scrollable | Scene yes | Pending on small phones |
| Milestone banner | `milestone_banner.tscn` | Queued, held under panels | Scene yes | Earlier builds |
| Tutorial guide (pointer, frame, cards, chooser, Road Ahead) | `tutorial_guide.gd` (code-built) | UI-05 None exception; TEST-01 coverage gap | Code-built | Waits pending (UI-01) |
| Offline claim | sheet panel | Exactly-once in source | Code-built | SAVE-01 |
| World map / camp picker / travel | `map_view.gd`, `camp_picker.gd` | Release-to-travel, drag cancels | Code-drawn | UI-02 |
| Joystick | `joystick.tscn` | Backplate modulates in scene | Yes | Dev-accepted |
| Android back | `ui_cancel` only | REL-03 | — | Not verified |

### 6.2 Supplied asset families

| Family | Use | Findings |
|---|---|---|
| Pixel Plains characters (24×24 sheets) | Player, 48 enemies, outfits | Mapping in Playbook 22.4 and the registry; provenance record missing (REL-02) |
| Pixel Plains items (All v3 Black Outline) | Item icons via `catalog.icon` | Seven other outline variants (~2,700 files) exported unused (REL-06) |
| Pixel Plains Animation Pack | Weapon swings | Stone tier uses tinted Iron sheet (Change 12); 413 files exported, ~20 referenced paths |
| Kenney Fantasy UI | Theme, panels, slots, frames | Licence present; 283 files exported, 18 referenced paths |
| Willosuna magic VFX lite | Six skill effects, warning, summon | `skill_effects.tres` placement; `_effect()` builds a new SpriteFrames per cast (minor allocation) |
| Willosuna magic SFX lite | Six cast cues (OGG) | WAV duplicates not referenced; licence present |
| `assets/sounds` (developer cue set) | Music + 4 cues | Provenance record missing (REL-02); 23 MB WAV music (PERF-07) |
| `assets/Audio` | Click, Prestige | Original sine tones (README) |
| DejaVu Sans | All text | Licence present; no script fallbacks (LOC-03) |
| Zombies Free, PP Pumpkins, seasonal sheets | none | Unreferenced but exported (REL-06) |
| GUIPackCartoon | retired | `.gdignore` present, not exported |

**Editor-editability** (Playbook 63.1): verified for tunable data. Fog, weather, onboarding, mastery, skill-effect, outfit-slot, audio-cue and enemy-ability rules are inspector `.tres` resources, and stages are baked editable scenes. The HUD shell is a scene. Panel contents and the tutorial overlay are code-built, a justified-for-now exception for dynamic lists, recorded as UI-03 for after release.

**Visual validation gaps:** every recent capture is a desktop render at 540×960. None establishes phone readability, touch comfort or GPU behaviour.

### 6.3 Final UI revision checklist (for the developer's phone pass)

1. Change 22 checklist (Drop All stillness 15 s, Auto-Claim flow, Prestige sections, stopwatch 15 s waits).
2. Back gesture behaviour (REL-03).
3. 20:9 and smallest supported phone: trackers vs joystick, objective/Next Stage stacking, banners vs panels.
4. Dock at Small/Medium/Large with 70 slots; drag-scroll starting on a slot.
5. Rain maps: HUD chip contrast, damage numbers, boss names over rain and overcast.
6. Prestige confirmation and long confirmations on the smallest screen.
7. Camp picker and map-camp tap comfort; drag versus tap.
8. Respawn countdown legibility at minimum and maximum zoom.
9. Audio: music hold, cue stacking in boss fights, volume sliders.
10. Guided, Basic and None from a fresh profile, including save/reload mid-wait and The Road Ahead in each mode.

---

## 7. Regression coverage map

**Command** (from the repository root, 2026-10-28):
`python tools/run_probes.py` with `PROBE_LOG_DIR` set to the session scratchpad. Runner: headless, sequential, hard timeout, isolated `probe-suite-*` profiles, `--no-autosave`, `--first-run-complete` except `change_15_*`.

| Entry | Result | Checks / failures |
|---|---|---|
| validate_campaign_source | PASS | 1,570 / 0 |
| change_21_probe | PASS | 116 / 0 |
| change_20_probe | **FAIL** | 81 / 17 (stale clock fixture; TEST-01) |
| skill_proximity_probe | PASS | 133 / 0 |
| change_17_probe | PASS | 679 / 0 |
| change_17_weather | PASS | 60 / 0 |
| change_16_probe | PASS | 197 / 0 |
| change_15_probe | **FAIL** | 172 / 13 (stale clock + Road Ahead; TEST-01) |
| change_14_probe | PASS | 202 / 0 |
| change_13_probe | PASS | 154 / 0 |
| change_12_probe / smoke | PASS | 149 / 0; smoke done |
| change_11_probe / smoke | PASS | 153 / 0; smoke done |
| change_10_probe | PASS | 90 / 0 |
| change_9_probe | PASS | 51 / 0 |
| change_8_probe | PASS | 74 / 0 |
| change_7_probe | PASS | 78 / 0 |
| change_6_probe | PASS | 201 / 0 |
| change_5_probe | **FAIL** | 159 / 1 (Road Ahead in None; TEST-01) |
| campaign_probe | PASS | 262 / 0 |
| campaign_content_probe | PASS | 98 / 0 |
| gameplay_probe | PASS | 72 / 0 |
| ui_probe | PASS | 24 / 0 |
| inventory_probe | PASS | 119 / 0 |
| targeting_probe | PASS | 23 / 0 |
| camera_probe | PASS | 17 / 0 |
| attack_timing_probe | PASS | 49 / 0 |
| bootstrap_probe | PASS | — |
| change_8_walk_probe | PASS | 2,178 / 0 |
| **Total** | **27/30 entries pass** | No script errors, no timeouts |

**Additional runs:**
- `change_22_probe` (not in suite, run by hand with an isolated profile): 38 checks / 1 failure (UI-04).
- `python tests/change_22_static.py`: 18 / 0.
- Desktop performance harness: §5.

**Not run:**
- `change_9_balance`, `pacing_bot` (deliberate balance tools; BAL-01);
- `change_16_audio` (windowed listening);
- capture scenes (they write into `docs/` evidence folders);
- `tools/fog_reachability.gd`;
- marketing toolkit `status`.

**Side effect handled:** the validator rewrote the tracked `docs/Change_21_Evidence/static_checks.json`. It was restored with `git checkout --` and the run's copy kept outside the repository (TEST-03). The final worktree contains only documentation changes.

**Save isolation:** verified in source. `BootContext` routes `--profile=probe-*`/`capture-*` to `user://profiles/<name>`; the production profile is `user://profiles/production`, and the audit never opened it for writing.

**Missing coverage worth adding** (after approval):
- the Guided flow after the 15 s wait (TEST-01);
- Android back handling (REL-03);
- a non-gating performance scenario scene (TEST-04);
- an export-content check that lists the AAB against an allowlist (REL-06, Stage 16);
- a save-size and save-time budget probe for a fully explored profile (PERF-01).

**Physical-device/manual steps:** §5.3 and §6.3. Desktop screenshots and headless probes do **not** establish on-device acceptance.

---

## 8. Documentation updates (this audit)

| File | Change | Behaviour/decision it reflects |
|---|---|---|
| `docs/LootFarmer_Full_Production_Audit_Report.md` | **New** — this report | — |
| `docs/Reusable_Game_Development_Playbook.md` | Lifecycle 19 → **20 stages**; new **0.9.1 Stage 16 — Demo Generation, Content Stripping & Validation**; former 16–19 renumbered 17–20; cross-references updated in the header, section 2, 87.8, 133 and 134.4; topic-map row; consolidation note | Developer-approved Stage 16 (2026-10-28); marketing remains Stage 17 |
| same | 16.3 confirmation layout settled once (generation token), 18.5 tutorial waits on an active real-time clock, 22.2 export allowlist for unused pack content, **48.1** desktop measurement method with explicit device boundaries and the four measured hotspot patterns, 60.1 suite hygiene (unregistered probes, evidence-writing validators, clock-source changes) | Verified in this audit's source reading, test runs and desktop harness; each marked where phone validation is still pending. No LootFarmer prices or tuning added. |
| `docs/LootFarmer_Design_README.md` | New current entry point (2026-10-28) above the historical ones | Current revision, version and audit status |
| `docs/LootFarmer_GDD.md` | New "Current status — production audit (2026-10-28)" section at the top: current build identity, Change 22/23 behaviour summary, balance acceptance status (Stages 1–5 developer-accepted, 6–8 open), the approved demo scope (Winter I/II, Stage 16, not built), open decisions (UI-05, LOC-02), release gates | Latest explicit approvals (Change 22 notes, Road Ahead note, developer statements in the audit brief) |
| `docs/LootFarmer_State_Contracts.md` | Header retitled current; short audit note (save cadence measurement, development reset policy until release declaration) | SAVE-01/02, PERF-01 (no rule changed) |
| `docs/LootFarmer_Test_Suite.md` | New 2026-10-28 audit run section with exact results, the stale-contract classification and the unregistered probe | TEST-01..04 |
| `docs/LootFarmer_Upgrade_Catalog.md`, `docs/LootFarmer_Prototype_Status.md` | Correction note: the Guided waits are 15 real active seconds (Change 22/23), superseding the "60 seconds" line | DOC-01 |
| `docs/LootFarmer_Prestige_Catalog.md` | Current-status note: the Change 6 gate text is historical; current entry/reset rules live in the GDD Prestige section | DOC-01 |
| `docs/LootFarmer_Content_and_Balance.md` | Balance status note: Stages 1–5 developer-accepted on Android, 6–8 pending; values remain the delegated tuning | Developer statement in the brief |
| `docs/LootFarmer_Asset_Registry.md` | 2026-10-28 audit section: export inclusion, unreferenced packs, provenance gates, placeholder icon | REL-01/02/06, AST-01 |

Historical change reports, evidence folders and older GDD sections were not rewritten.

**Confirmation:** Stage 16 (free limited-content demo, physically stripped, positive allowlist, separate package and save, end-of-demo invitation, actual APK/AAB/PCK inspection, no demo-to-paid save transfer assumed) is documented in Playbook 0.9.1 and recorded for LootFarmer in the GDD with the approved scope **Winter I and Winter II only**. The demo was **not** generated. Store screenshots, feature graphic, trailer, 10 social videos, posting copy, English ASO, 19 localized listings, localized release notes and final listing validation remain **Stage 17** gates.

---

## 9. Next action plan (for approval; nothing below has been implemented)

Ordered by impact and dependency. Each batch: the smallest relevant probe, then the related group, then the full suite once, then a phone build (Playbook 60.1).

| Batch | Scope | Depends on | Acceptance |
|---|---|---|---|
| **A. Test truth** | TEST-01 (update the three probes to the real-time wait and Road Ahead), TEST-02 (register `change_22_probe`, resolve UI-04), TEST-03 (validator output path). Decide UI-05 first. | UI-05 decision | Suite 31/31 green; Guided flow asserted to `tutorial_final` |
| **B. Phone baseline** | Version bump to 23 (DOC-02), export, run the Change 22 checklist (UI-01), REL-03 back-gesture check, and the §5.3 profiling plan **before any optimization** | A | Recorded phone percentiles per scenario; agreed targets |
| **C. Hitch removal** | PERF-01 (save validation without re-parse; save cadence at committed boundaries), PERF-04 (inventory relayout only on change), PERF-02 (threaded stage preload) | B | Phone hitch counts above 50/100 ms drop; save/round-trip probes, inventory and travel probes pass |
| **D. Rain/map frame time** | PERF-03 (off-screen actor views, fog visibility cache shared by fog/weather/minimap, fewer per-tick array copies) | B, C | Phone p95 on Summer II/Spring II meets the agreed target; weather equivalence 60/60, fog probes pass; identical captures |
| **E. Final UI revision** | Fixes from the §6.3 phone pass (UI-02, UI-06, REL-03 if confirmed) | B | Developer sign-off on the checklist |
| **F. Stages 6–8 acceptance** | Developer playthrough; run `change_9_balance` once; any balance change approved separately (BAL-01) | C, D | Developer verdict per stage |
| **G. Packaging** | REL-05 ABIs, REL-06 export allowlist + `.gdignore`, AST-04/05 cleanup | E | AAB lists only allowlisted files; all scenes load |
| **H. Release declaration and localization freeze** | SAVE-02 declaration, LOC-02 decision, LOC-03 fonts, then Playbook 132 batches 5+5+5+4 | E, G | 20/20 languages validated |
| **I. Stage 16 demo** | Generator + allowlist (Winter I/II), separate package/save, end-of-demo invitation, artifact inspection | F, G | Playbook 0.9.1 validation list |
| **J. Stage 17 marketing** | REL-01 icon, captures, trailer, 10 social masters, ASO, listings | E (UI-readiness), I for the demo listing | Approved artifacts |
| **K. RC / publish** | REL-02 provenance, exact artifact play, Play Console | all | Playbook 49 and 88 |

**Stop/go recommendation:**
- **GO** to Batch A now. It is small, test-only and restores a trustworthy suite.
- **GO** to Batch B (phone baseline) immediately after.
- **STOP** before optimization code (C/D) until the phone numbers exist and targets are agreed. The desktop harness shows where to look, but an optimization without a device baseline cannot be accepted under the brief's evidence rule.
- **STOP** for demo and marketing work until the final UI revision (E) and Stages 6–8 acceptance (F) are complete.
