# LootFarmer — Change 24: Performance Optimization and Regression Coverage — Report

**Date:** 2026-10-28 · **Brief:** `LootFarmer_Change_24_Full_Performance_and_Test_Corrections.md` · **Baseline:** `LootFarmer_Full_Production_Audit_Report.md` (revision `b51a209`)
**Build identity:** application `config/version` **24**, Android Release `version/code` **24** (`version/name` blank, inherited), save schema 8, **save file version 3**. The Android Bootstrap APK preset (utility build, code 20) was left unchanged.
**Scope:** presentation, persistence and test work only. No balance value, reward, spawn rule, combat decision, fog disclosure, weather density or look, pixel filtering, asset, animation or UI layout was changed.

## 1. Results at a glance

- **Maintained suite: 32/32 pass** (validator 1,570 checks; 31 Godot scenes, 5,689 checks), no script errors or timeouts. It was 27/30 at the audit; `change_22_probe` and the new `change_24_probe` are now registered.
- **Desktop benchmark** (same machine, same fixture builder and scenarios as the audit): mean frame interval on rainy Spring II at maximum spawn **14.15 → 5.16 ms**, p99 **27.2 → 10.2 ms**; the late-game save **125 → 14.8 ms** and **466 → 75 KB**; per-kill inventory refresh **8.4 → 0.4 ms**; worst stage-switch frame **422 → 132 ms**. These are desktop numbers. **They are not Android measurements and guarantee nothing about phone frame rates.**
- **Development saves reset once:** profiles written before this build (save file version 2) start fresh on first launch. No migration (Playbook 61.1).

## 2. Implementation map

| ID | Finding | What changed (files) | Why it is equivalent |
|---|---|---|---|
| **P01** Save path | PERF-01: 125 ms per save, two full JSON re-parses | `save_service.gd`: the temporary file is verified by byte length and MD5 of the serialized buffer, not parsed back; the old primary is never parsed again (an in-memory "primary valid" flag plus its last written length decides whether it may become `.bak`); provider sections are not deep-copied before serialization. `simulation.gd`: the save provider is `save_snapshot()`, a shallow view serialized at once; `snapshot()` stays an independent deep copy for probes. | Same atomic order (write temp → copy valid primary to `.bak` → rename). A truncated or failed write is still refused; a primary that changed on disk or failed to load never replaces a good backup (probed). |
| **P02** Fog save | 30,864 string keys at full exploration | `campaign.gd`: `state.explored[stage]` is a `PackedByteArray`, one byte per fog cell (`y × columns + x`). Saved deflated + Base64 (`encode_explored` / `decode_explored`); `valid_snapshot` rejects masks of the wrong size or with bytes other than 0/1. Fixture/tool API: `explore_cells`, `explored_count`, `explored_mask`, `fog_columns/rows/cell_count`. Save file version 2 → 3. | Reveal, percent, unreachable-cell exclusion, Prestige keep list, Hard Reset and layout-revision reset read and write the same cells; all fog probes pass. Fully explored Spring II encodes to under 400 characters. |
| **P03** Autosave cadence | Dirty every 2 s, written every 5 s | Two tiers in `save_service.gd`: `mark_dirty()` (ordinary progress) writes **30 s** after the first unsaved change; `mark_committed()` writes **1 s** later (bursts coalesce). Committed: every Coin/Gem payment (`sim.pay`), panel action buttons, a supply used from the dock, settings changes. `save_now()` stays immediate for travel, claims, Prestige, Hard Reset, guidance choice, pause, background and quit; the 120 s periodic save stays. | **New accepted rollback window:** a crash or force-stop *without* the pause notice can lose up to 30 s of ordinary farming (it was ~5 s). Committed actions older than ~1 s and every transaction that already saved at once are unaffected. Android normally delivers the pause notice before a kill. |
| **P04** World transitions | 300–420 ms stall | New `stage_scenes.gd`: one shared, bounded (4 scenes, LRU) PackedScene cache for the world and the obstacle reader, with `ResourceLoader.load_threaded_request` for likely destinations (the next open map and Winter I on arrival; the map a camp picker shows). `campaign._read_obstacles` reads the solids from the cached scene's `SceneState` instead of instantiating and freeing the whole stage (identical output on all 8 maps, probed); background-loaded stages get their obstacle grid one per frame before travel. `world.gd`: the old scenery is hidden at once and freed 400 nodes per frame; actor views are pooled across the switch. | Travel rules, locks, camp state and stage selection are untouched (the simulation still switches state in the same call). Only how the scene arrives changed. |
| **P05** Inventory | 8.4 ms per kill with unchanged slots | `game_ui.gd`: `_layout_inventory()` runs only when its key changes (column widths, zoom, slot counts, heading height, gap); the pinned weapon/outfit buttons are rewritten only when what they show changes; the HUD tick re-checks the key cheaply so resizes still apply. | All slot interactions, density levels and scroll behaviour unchanged (inventory, change_10/11/20/21 probes). |
| **P06** Actor views / simulation | Every actor updated every frame; repeated lookups | `world.gd`: per-loadout looks (textures incl. attack sheets, tint, scale, name, skill icons) resolved once; off-screen views (camera + 96 world units) are hidden and skip their animation while their data stays current; one `campaign.Sight` per frame for fog disclosure of views and pickups. `actor_view.gd`: node references cached; scale-dependent layout written only when the scale changes; `recycle()` for the pool. `simulation.gd`: the per-tick O(n²) `enemies.has(e)` scan now runs only after an actual removal; no per-tick roster concatenations or copies for timers; targeting takes one `Sight`. `campaign.gd`: skill targeting and area damage take one `Sight`. | The simulation is still the only authority: off-screen enemies move, attack, cast, respawn and summon exactly as before (gameplay, targeting, skill, combat probes unchanged). `Sight.sees()` equals `can_see()` at every sampled point, alive and dead, on Winter I and Spring II (probed). |
| **P07** Fog / map / rain | String keys per cell and per particle; whole-map fog redraw per cell crossing | New `resources/game/fog_veil.gdshader`: the fog veil is one texture draw; the explored mask is uploaded as an L8 texture only when discovery or the stage changes, and moving sight updates two shader parameters. Colours still come from `fog_rules.tres`; same cell edges and the same cell-centred sight test. Rain tests each drop with the shared `Sight` (byte index, no string). Minimap and camp picker draw one rectangle per horizontal run of explored cells (same covered area and colour). | Weather equivalence probe 60/60; fog disclosure probes pass. Visual identity of the fog veil is by construction (same colours, same cells); a side-by-side phone capture is still recommended in the UI pass. |
| **P08** Panel spikes | Up to 74 ms on open/close | `game_ui.gd`: the last closed panel's controls stay hidden in the sheet with processing paused; reopening the same panel reconciles them (only changed values are written) instead of building, adding and laying out every row; another panel replaces them. A full replacement now removes the old controls first so new ones keep their names. | Settle-then-reveal (Change 22 flicker fix) unchanged; at most one panel retained (bounded, leak-checked by change_6 and the benchmark). |
| **P09** Startup / memory | 1.09 s load; memory rises across maps | Stage 1 is parsed once at start (shared cache) and its obstacles come from `SceneState`. No boot restructuring: the remaining load time is script compilation and the first stage, which an exported build (binary scenes and tokens) already does faster. Static memory is unchanged (≈69 MB Winter I, ≈118 MB after visiting every map; the 4-scene cache did not raise it measurably). | — |
| **P10** Music | 23 MB WAV source | **Evaluated, not changed.** The import is QOA (`compress/mode=2`), 4.7 MB in the build and resident while playing, with cheap decoding and seamless looping. An OGG would save about 2–3 MB of memory but trade a lossy re-encode and a listening check for it; not a clear benefit, so the source and import stay. | — |

## 3. Test-suite and consistency corrections

| ID | Change |
|---|---|
| TEST-01 | `change_20/15/5` probes drive the real-time Guided clock (`guided.advance_waits`, `TutorialGuide._process`), assert that pause, suspension and a Prestige choice do not advance it and that playtime alone never opens Missions, walk every Guided step to `tutorial_final` (all 28 steps asserted complete), and expect The Road Ahead once in Basic and None. |
| TEST-02 | `change_22_probe` registered; it now expects "Automatic Claiming: OFF/ON", no None-mode pointer and the Basic pointer. |
| TEST-03 | `tools/validate_campaign_source.py` writes `tests/tmp/static_checks.json` (ignored) by default, `--output PATH` otherwise. |
| TEST-04 | `tests/performance_benchmark.gd` + `tools/run_benchmark.py`: non-gating, isolated profile, 30 s watchdog, writes `tests/tmp/benchmark/report.txt`. Not in `run_probes.py`. |
| UI-04 | `MISSION_AUTO` = "Automatic Claiming: %s" with new `STATE_ON_CAPS`/`STATE_OFF_CAPS` ("ON"/"OFF"); other toggles keep "On"/"Off". |
| UI-05 | `tutorial_guide.gd`: None mode shows only The Road Ahead; the Missions panel text still explains Auto Claim. GDD updated. |
| DOC-02 | Next number from Git history (latest "Change 23") is **24**; project and Android Release version code set to 24. Earlier commits and reports were not renamed. |
| New | `change_24_probe` (53 checks) covers the new mechanisms' correctness (section 1 of the Test Suite document). |

Fixture updates for the new representations (no assertion weakened): explored fixtures/counts through the campaign API; malformed-save checks use wrong-size and non-0/1 masks; probes inspecting an enemy's overhead visuals point the camera at it (off-screen views pause by design); probes judging an in-memory `restore()` clear the boot-time load result first (their on-disk probe profiles were version 2 and reset at boot, as intended); `change_6_probe` takes its node baseline after one warm-up round (one retained panel).

## 4. Desktop performance: audit vs Change 24

**Environment (both runs):** Godot 4.7.2-stable official (editor binary, debug), Windows 10, Intel i5-10300H, GTX 1650, Compatibility renderer, 540×960 window, V-Sync off, physics 60 Hz, isolated profile, autosave off. **Comparability:** the Change 24 harness is the audit's harness promoted into the repository with the same fixture builder, scenario order and frame counts; the only fixture difference is that "fully explored" is set through `explore_cells` instead of writing string keys (same cells). One run per scenario on each side, on different occasions: treat differences under ~3 ms as noise. A desktop debug build is not a phone release build.

Frame interval, ms (mean / p95 / p99 / max):

| Scenario | Audit (b51a209) | Change 24 |
|---|---|---|
| Winter I, fresh, idle | 3.10 / 4.42 / 4.93 / 6.08 | 1.78 / 2.95 / 3.98 / 5.48 |
| Winter I, full inventory, farming | 6.01 / 8.04 / 11.40 / 56.17 | 2.56 / 4.26 / 5.29 / 9.04 |
| Summer II rain, full, farming | 10.52 / 14.57 / 21.61 / 27.50 | 4.57 / 7.13 / 8.30 / 10.83 |
| Spring II rain, full, farming (135 actors) | 14.15 / 22.21 / 27.20 / 37.38 | 5.16 / 8.07 / 10.17 / 13.36 |
| Spring II rain, walking into fog | 15.74 / 22.32 / 31.93 / 51.28 | 5.60 / 9.93 / 13.82 / 19.29 |
| Spring II rain, standing in fog | 17.73 / 36.07 / 45.92 / 54.08 | 5.23 / 8.28 / 11.37 / 15.51 |
| Spring II, panel open/close every 15 frames (8 panels) | 16.69 / 29.44 / 39.13 / 74.38 | 5.99 / 9.13 / 25.14 / 35.17 |
| Spring II, same panel reopened every 15 frames (new) | — | 6.24 / 11.83 / 16.63 / 23.82 |
| Spring II, Upgrades open, farming | 11.00 / 12.63 / 21.94 / 30.13 | 5.56 / 8.65 / 12.65 / 16.93 |
| Spring II, Prestige open, farming | 11.74 / 17.51 / 23.96 / 39.23 | 4.87 / 8.32 / 11.48 / 31.72 |
| Stage switch every 40 frames (all 8 maps) | 15.21 / 22.62 / 283.70 / 422.03 | 4.84 / 10.77 / 59.63 / 132.45 |

| Micro-benchmark | Audit | Change 24 |
|---|---|---|
| `save_now()` late game, all 8 maps explored | p50 125.0 ms, max 128.1; 465,980 bytes | p50 **14.8 ms**, max 15.7; **74,700 bytes** |
| Serialize the save state | 23.8 ms (`JSON.stringify(state)`) | 4.2 ms (`JSON.stringify(save_snapshot())`) |
| Inventory `_refresh_slots()`, unchanged (every kill) | 8.44 ms | **0.42 ms** |
| Inventory forced full layout (now only on real layout changes) | 25.2 ms | 25.7 ms |
| `simulation.step` Spring II, 135 actors | p50 4.70, p95 5.60, max 9.25 | p50 **1.97**, p95 3.53, max 9.72 |
| Individual stage switches (state change + frame), ms | 300–420 | 2: 183, 3: 68, 4: 88, 5: 58, 6: 71, 7: 65, 8: 145, 1: 52 |
| Startup: `load(main)` / instantiate / first two frames | 1,085 / 19 / 564 ms | 1,141 / 19 / 522 ms (unchanged within noise) |
| Static memory: Winter I → after visiting every map | 69 → 117 MB | 69 → 119 MB |
| Leak checks | panels +9 nodes; stage switches +0 | panels +26 (one retained panel, by design); stage switches −7 |

Draw calls are similar (≤ 296); GPU fill rate and fog/rain overdraw on a phone GPU were not measurable here.

**Reading the stage-switch numbers:** the benchmark changes the stage directly, so it measures the worst case: no destination preload. The 180/145 ms frames are maps whose scene had been evicted from the 4-scene cache and was parsed again synchronously; the 50–90 ms frames are cached maps (instantiate, enter the tree, first draw of ~1–2.5 k scenery nodes). Real travel through the World panel's camp picker requests the destination first, which removes the parse part.

## 5. Verification performed

1. `godot --headless --import`: clean (generated `.uid` files for the new script, shader and tests; `export_presets.cfg` not rewritten).
2. `python tools/run_probes.py` — first full run 25/32 (fixture updates plus one real defect, see the Test Suite document); targeted reruns of the seven entries; second full run **32/32**.
3. `python tools/run_benchmark.py` — once, 50 s, `BENCHMARK done`, no script errors.
4. Current-schema save: serialize → disk → load with all eight maps explored, the backup rule, a version-2 profile resetting to a writable fresh profile, and both coalescing tiers (`change_24_probe`); the existing disk round-trip probes (change_5/6/7/10/11/20) pass.
5. `git status` after the runs: `docs/Change_21_Evidence/static_checks.json` unchanged; benchmark and validator output only under the ignored `tests/tmp/`.

Not run (not affected or deliberately out of scope): Android profiling, exports, pacing bots and balance fixtures, rendered capture scenes, the windowed music check.

## 6. Limits and what still needs the phone

- **No Android number exists.** Desktop gains rank causes; the phone pass should repeat the audit's §5.3 scenarios with `tools/run_benchmark.py`'s scenario list (it can run through the remote debugger) and agree targets from those numbers.
- **Stage switches** still cost one 50–180 ms frame on the desktop when the destination was not preloaded (direct state changes, a Prestige from an uncached map). A short fade or caching all eight scene files would hide the rest; not done, to keep the transition look and memory unchanged.
- **Forced inventory layout** (zoom change, new slot purchase) still costs ~25 ms once; it no longer happens per kill.
- **Fog veil** is now a canvas shader on the Compatibility renderer: confirm on the phone that the veil looks identical (same cells, colours and sight edge) and that the first fog frame after a map change has no shader-compile hitch.
- **Off-screen culling margin** (96 world units) hides views just outside the camera; check at the widest zoom that no enemy pops in visibly at the screen edge.
- **Save rollback window** is now 30 s for ordinary progress after a crash or force-stop without a pause notice; the SAVE-01 device checks should use that value.
- One closed panel stays in memory (bounded); measured +26 nodes.

## 7. Development-save reset

Every profile written before Change 24 (save file version 2, including the developer's phone profile and old probe profiles) **starts fresh once** on first launch: settings are kept, progress is not. This is the Playbook 61.1 development policy; no migration was written. After the first save the profile is version 3 and loads normally.

## 8. Documentation updated

GDD (Change 24 status, UI-04/UI-05 decisions, None contract, save window), State Contracts (save version 3, explored mask format and validation, snapshot, verification, cadence and rollback window, Sight, presentation-only state), Test Suite (Change 24 run and fixture changes), Design README (entry point), audit report (status note only), Asset Registry (music evaluation), Playbook (sections 16.3, 30, 48.2, 60.1, 117.9 F: only techniques validated here, without LootFarmer numbers).
