# LootFarmer — Test Suite (Change 11)

## Maintained regression suite (gating)

Run: `python tools/run_probes.py` (all) or `python tools/run_probes.py <name> …`. It starts with `tools/validate_campaign_source.py`, then runs each probe headless and **sequentially** (playbook 60.1), each with a hard timeout. A run fails on a non-zero exit, a timeout, any `SCRIPT ERROR` line or a missing summary line: a runtime script error aborts a probe's coroutine before it can quit, so without the runner it looks like a hang. Set `GODOT` to the console executable on another machine.

| Probe | Covers |
|---|---|
| validate_campaign_source.py | Catalog and source contracts, translations, every catalog tool's `--check` (1,326 checks) |
| change_11_probe | Collection follower, minimap markers, Teleport picker, loot speech, supplies and mastery, supply save/load/reset, Filters close paths, gem upgrades kept by Prestige, spawn prices |
| change_11_smoke | Every Change 11 panel and action once on the real main scene |
| change_10_probe … change_5_probe | Each change's approved contracts (stale supply checks updated in Change 11) |
| campaign_probe, campaign_content_probe | Campaign rules and authored content |
| gameplay_probe | Core rules: inventory identity and evolution, supply use, attack timing and single contact, reload safety, respawn, pause and suspension, Prestige retention, invalid saves, leash, regeneration, automation, spawn upgrades, focus, variant loadouts, XP, **ground loot expiry** |
| ui_probe | HUD layout, enemy-panel purchase, supply use, tap-to-collect, joystick, actor frames, zoom and camera |
| inventory_probe | Dock slot tap, hold and scroll, and slot layout |
| targeting_probe | Target lock, manual selection, aim and release, pinch cancel, idle acquisition |
| camera_probe | Map touch routing, pan and pinch |
| attack_timing_probe | Attack windup and contact timing |
| bootstrap_probe | Boot, profile isolation and save-container basics |
| change_8_walk_probe | Movement around solid scenery on every stage |

Change 11 final run: **19 / 19 passed** (`tools/run_probes.py`).

## Not in the default suite (non-gating)

| Item | Status | Why |
|---|---|---|
| change_9_balance | Passes | A balance fixture (deterministic duels); run it deliberately when combat numbers change. |
| pacing_bot | Not run | Natural-pace benchmark (minutes per run); for pacing questions only. |
| change_*_capture, change_6_before, change_8_stage_capture, stage_overview_capture | Not gating | Rendered evidence (screenshots); run with a window. |
| change_7_smoke, change_10_smoke | Pass | Superseded for build readiness by change_11_smoke; kept as history. |
| audit_probe | Historical, fails | Calls the removed `sim.sell` (hangs on the script error). |
| balance_probe | Historical, fails | Reads removed legacy items (`dinosaur`); superseded by change_9_balance. |
| evolution_farming_probe | Historical, fails | Asserts Change 1–4 gem prices and outfit evolution (removed in Change 8). |
| farming_ui_probe | Historical, fails | Reads the removed flat potion `heal` stat. |
| feedback_probe, group_progress_probe, inspector_probe | Historical, fail | Assert pre-Change 6 presentation, unlock and drop-rate contracts that later changes replaced. |

The historical probes are kept as records of their era and are not maintained. Their current contracts are covered by the suite above. Delete them in a later cleanup, or repair one if it turns out to cover something the suite does not.

## Change 11 legacy disposition (brief section 7)

| Test | Disposition | Reason / replacement coverage |
|---|---|---|
| change_1_probe | Deleted | Asserted contracts replaced on purpose: Change 1 gem prices, a schema-4 refund migration, the 4-type world, the victory/offer Prestige (87 of 131 checks failed). Its still-current contracts (per-type collection, spawn upgrades) moved to gameplay_probe; gem payouts are in change_10_probe. |
| progression_probe | Deleted, consolidated | Called the removed `sim.sell()` (script error, so it hung) and assumed removed items, the old Prestige and 28 enemies. Variant loadouts, worn-loot rolls and the XP threshold moved to gameplay_probe; stored shares and level growth are in change_9 and change_10. |
| gameplay_probe | Fixed and consolidated | Core combat and timing rules live only here. Harness fixed: `sim.step` clamps to 0.1 s, so a stepping helper was added; fog fixture; current Prestige batch and invalid-save rule. **Found a genuine bug: ground loot never expired. Fixed in `a047048`.** |
| ui_probe | Fixed | The pending onboarding chooser suspended the simulation; enemy panels need a discovered type; Use is a pinned action; navigation includes Upgrades again; the HP fill is textured (the old `hp_fill` check hung the run). |
| inventory_probe | Kept | Fixture updated (onboarding; 5 supply slots). |
| targeting_probe, camera_probe | Fixed, added to suite | Same onboarding fixture; fog-explored ground for chasing; a stepping helper; marker texture; merge gain from the catalog getter. |
| change_5/6/7/8/10 probes | Updated | Stale supply assertions (potion tiers, `potion_cooldown`, the Coin Tonic text key, `merge_supplies` price, supply cap 13) moved to the Change 11 rules with the same intent. |
