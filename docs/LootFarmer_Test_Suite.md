# LootFarmer — Test Suite (Change 20)

## Change 21 validation — 27 October 2026

Final combined maintained result: **30/30 entries pass** (static validator plus 29 Godot probes). The full run passed 26/30 initially; the obsolete Change 16/8 tracker placement and Change 11 five-slot migration assertions were updated to the requested behavior. The inventory interaction fixture now waits for container layout before tapping, and the runtime ignores inventory sizing until both column widths exist. All four affected probes pass on the targeted rerun. The new Change 21 probe passes **104 checks, zero failures**; the static validator passes **1,568 checks, zero failures**.

Raw initial run: `Change_21_Evidence/suite_summary.txt`. Final targeted run: `Change_21_Evidence/final_targeted_summary.txt` (6/6 entries, including static and Change 21). Per-probe logs reflect the most recent execution. Existing Change 20 tests still pass 81/0, including real Prestige level/XP retention and mastery reset. Android hardware validation remains outstanding.


## Change 20 current result

**29/29 maintained entries passed in one full run** on Godot 4.7.2 Linux headless: one source validator and 28 Godot scenes, run sequentially. Source validation: **1,567 checks, zero failures**. That full run included **79 checks** in `change_20_probe`. A final targeted rerun after adding dormant automatic-assignment clearing passed **81 checks, zero failures**, plus the source validator. The existing proximity probe passes **133**, original Change 17 gameplay **679**, and weather equivalence **60** checks. No maintained test failures, timeouts or script errors. Exact output: `Change_20_Evidence/suite_summary.txt` and `final_targeted_summary.txt`; per-scene logs and static JSON are beside it.

The new probe drives the real item toggle, automatic-slot assignment and travel APIs, checks saved state with JSON and actual disk reloads, executes Prestige, verifies level/XP retention and mastery reset, checks 3/4/6-column slot density with fixed enclosing height, checks settings through Hard Reset, verifies boss reveal/countdown and marker priority, tests camp touch/drag/combat behavior, and walks the ordered Guided flow including both waits and delayed final confirmation. Existing Change 6/7/8/11/13/14/15/16/17 assertions were updated where the approved tutorial, layout, combat or Prestige rules changed; their interaction coverage remains in the maintained suite.

Rendered evidence is in `Change_20_Evidence/ui/`. `change_20_capture` is a separate desktop OpenGL Compatibility capture at 540×960, not a headless gate or Android test. It has no script errors, but its renderer reports unsupported V-Sync and shutdown resource warnings. Physical-device visual, touch, background and performance checks remain open; use the checklist in `LootFarmer_Change_20_Report.md`. Earlier late-game balance failures are still documented and are not part of the maintained gating suite.

| New/retained probe | Scope |
|---|---|
| `change_20_probe` | Remaining-features/UI/tutorial acceptance, persistence, resets and interactive controls |
| `skill_proximity_probe` | Manual/automatic activation boundaries, eligible targets, failed-cast side effects and effective Gem chance |
| `change_17_probe` | Prior 17 gameplay changes, their saves and current Prestige contracts |
| `change_17_weather` | Weather output equivalence |

## Historical Change 19 result

**28/28 maintained entries passed in one full run**, Godot 4.7.2 Linux headless. Source validation: 1,557 checks; new `skill_proximity_probe`: 133 checks; original Change 17 gameplay: 679 checks; weather equivalence: 60 checks. No failures or script errors. Current evidence is in `Change_19_Evidence/`; see `LootFarmer_Change_19_Report.md` for scope and pending device/UI acceptance. The following Change 17 results are historical.

## Historical Change 17 result

27/27 maintained entries passing on Godot 4.7.2 (full run plus the targeted wall-clock-tolerance correction). Source validator 1,557/1,557; `change_17_probe` 679/679; `change_17_weather` 60/60 exact original-output comparisons. See [Change 17 validation](LootFarmer_Change_17_Validation.md) and `Change_17_Evidence/` for raw logs and the precise run/rerun history.

New gates cover gameplay/save/Prestige APIs and particle equivalence. `change_17_performance` is a non-gating eight-map simulation CPU sampler; `change_9_balance` was run separately and remains **33/35, two failures**, compared with 34/35 in the untouched supplied project. These balance failures are not suppressed; developer review is required. UI/tutor integration and physical Android GPU testing remain pending.

Changed legacy fixtures assert use-based mastery, the 20-second bases, below-full-HP healing and the approved prices. The old supply-slot membership fixture now owns its automation purchase. `change_16_probe` checks numeric skill-description wiring only; Claude still owns the stale eligibility prose and new effect/cap descriptions.

## Maintained regression suite (gating)

Run: `python tools/run_probes.py` (all) or `python tools/run_probes.py <name> …`. It starts with `tools/validate_campaign_source.py`, then runs each probe headless and **sequentially** (playbook 60.1), each with a hard timeout. Since Change 15 the runner passes `--first-run-complete` to every probe except `change_15_*`: fresh profiles in probes of ordinary play start with every menu revealed and the early equipment guarantee spent (Playbook 18.10); the Change 15 probe covers the progression itself. When running another probe by hand, add the flag. A run fails on a non-zero exit, a timeout, any `SCRIPT ERROR` line or a missing summary line: a runtime script error aborts a probe's coroutine before it can quit, so without the runner it looks like a hang. Set `GODOT` to the console executable on another machine.

| Probe | Covers |
|---|---|
| validate_campaign_source.py | Catalog and source contracts, translations (code, scene keys and dynamic keys), every catalog tool's `--check` including change16_catalog (1,554 checks) |
| change_16_probe | Map economy on all 8 maps (income ×1.5, every map-tied Coin purchase ×1.55, global and Gem prices unchanged, rising cost/income), Gem Auto-Collect / Collect Batch (prices, Prestige, older Coin levels), save migration of the new records, boss discovery (once, sound, banner order, Prestige on discovery without a kill, Prestige, Hard Reset), boss names and skill icons (stacking, contrast), the Winter I objective, mission + Prestige trackers together, followers of all 33 opportunities, Prestige keeping Gems and exploration, the Health Potion 10% → 20% and external HP bonuses, Drop All (slot, pile, Auto-Collect, exploit loops, credit, equipped, save, expiry, red UI), Map Mastery reward swap and chip, Cyan Robot Heal interval, skill descriptions, the Prestige confirmation screen, music hold rules, the Guided path opening, View Camp, Help and no development UI (197 checks) |
| change_15_probe | Early equipment guarantee (3 modes × 3 Winter I types × 4 seeds with natural drops; exact kills 5 and 10 per type and loadout; type switch; natural drops first; supplies and non-matching gear; expiry; bosses; full row; once per profile), menu reveal (hidden HUD and refused panels from every path, the chain, level backstops, full row, Snowman first and banner order, silent opportunities before the reveal, save/load, Prestige, Hard Reset, validation, Show all menus now), Guided sequence to Prestige, Basic cards, None without guidance, notification sounds (streams, triggers, hidden systems silent, shared cooldown, same frame, mutes), Map Mastery (content, records, shared items, latches and notices, percentages, rewards exactly once, Prestige, save/load, Hard Reset, optional), reachable exploration on all eight maps, panels (World entry, list, map page, unnamed unmet enemies, Stats), World map dot through panel refreshes (177 checks) |
| change_14_probe | Top-right map cluster (order, chips, contrast, insets, gate count, explored percent), Missions badge against the Claim rules (ready objectives listed first, auto-claim, waiting slots, Hard Reset), rain splashes frozen at impact, the six skill effects for player and enemy casts (placement, layer, scale, real effect, cooldowns, one effect per boss attack), Reveal Stats / Reveal Drops on both enemy tabs, joystick contrast layers and unchanged input, one-time Focused Farming guidance (modes, exits, suspension) |
| change_13_probe | Exact-identity Auto-Merge (sword and axe Wood→Stone, shared drops, outfits, skills, supplies), Auto Evolution (flat price, manual rule, one tier, own droppers, full inventory, save/Prestige/Hard Reset, panel), potion 12 s and floor, skill prices and cooldowns, next-stage guidance and discovery-only boss markers, currency format across surfaces, rainy-map overcast and world-anchored rain, summoned helpers (cap, no rewards, cleanup, never saved), final boss (Heal priority below 50%, attack pool, pace, summons) |
| change_12_probe | Cyan Robot Heal (real HP, telegraph, cooldown, death, effects on the caster, heal numbers), map explored percent (source, rounding, vision/panning, map switch, placement), Settings copy and audio controls, audio categories/priority/cooldown/persistence, followed-step and mission cues once per transition, Merge All (purchase, rules, UI, save, Prestige, Hard Reset), stone-tier swing mapping, camera after Prestige, gem chance formula and prices |
| change_12_smoke | Every Change 12 panel and action once on the real main scene |
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

Change 11 final run: 19 / 19 passed. **Change 16 run: 25 / 25** (24 probes and the source validator). Change 12 run: 21 / 21. Change 13 run: 22 / 22. Change 14 run: 23 / 23. **Change 15 run: 24 / 24** (`tools/run_probes.py`; stale contracts updated first, see below).

`tools/fog_reachability.gd` (run with `godot --headless --path . -s tools/fog_reachability.gd`) checks the stored unreachable fog cells against a fresh flood fill (8 / 8 maps match).

## Change 16 test updates

First full run after the implementation: 16 / 24. Every failure was a contract this change replaces on purpose, one date-dependent fixture and one test artefact; each was updated with the same intent. No production regression.

| Test | Change | Reason |
|---|---|---|
| change_15_probe | Settings checks: Help present, no Show all menus; `reveal_all(true)` checked directly; MAIN_4 names Winter II only | Change 16 removes Show all menus / Choose guidance again; Prestige opens on finding the Snowman |
| change_13_probe | Potion ^0 10%; camp-price formatting fixture moved to Spring II (first camp price ≥ 1,000 at 1.55 per map) | Change 16 potion and map pricing |
| change_12_probe | Cyan Robot Heal timer 12 s; Prestige keeps Gems; the followed-step notice section counts `follow_step` only | Change 16 Robot and retention. The notice failures were date-dependent: the day's daily missions (chosen by a hash of the date) included a Blue Cap hunt that the section's 200 kills completed |
| change_11_probe | Collection follower names the exact outfit and shows its icon; tracker bottom-right; potion 11% / 20%; Gems kept, coins reset | Change 16 follower, trackers, potion, retention |
| change_8_probe | Camp approach: no pop-up, View Camp opens it; Collect Batch is a Gem upgrade (50); tracker text first line; tracker bottom-right | Change 16 camps, Gem collection, trackers |
| change_5_probe | Potion vs Heal role checked for the droppable Heal (tier 1) at every mastery and the legacy tiers at ^100; tier-one potion 10% | Change 16 potion 10% → 20%; legacy Heal tiers 2–7 reach the 12% cap at level 1000 |
| campaign_probe | Prestige keeps explored cells | Change 16 retention |
| gameplay_probe | Prestige keeps Gems | Change 16 retention |
| ui_probe | Unreleased languages are not offered and are refused (were disabled buttons) | Change 16 removes development notices |
| change_16_probe | New, in the suite (197 checks) | Change 16 contracts |
| change_16_audio | New, windowed, not in the headless suite (11 checks) | Real music playback |
| change_16_capture | New, rendered | docs/Change_16_Evidence/ui/ (desktop evidence only) |

## Change 15 test updates

First full run after the implementation: 17 / 23. Every failure was a stale contract or a test artefact, and was updated with the same intent. The run also exposed one production bug, fixed in `e52054a`.

| Test | Change | Reason |
|---|---|---|
| change_12_probe | "three different sounds" → the three share the mission-ready sound; notices filtered to follow_step / mission_ready; Merge All fixture marks "Merge a duplicate" claimed | Change 15 notification sound family; the new `main_ready` notice (a main objective that becomes ready outranks the confirm click, by design) |
| change_5_probe, campaign_content_probe | `schema==7` → `schema==8` | Change 15 save schema |
| change_8 / 9 / 10_probe | none (passed on rerun) | Their probe profiles on disk were schema 7, so `last_load_result` read `development_reset` once; the same one-time reset happens to a device save |
| change_6_probe | the node-count baseline excludes the world viewport | A damage number expiring during the open/close cycles made the check flaky; the check is about panels |
| change_6_probe (script error) | — | **Production bug:** the panel reconciler pruned the World map's player dot on an in-place refresh. Fixed in `e52054a`; change_15_probe has a regression check that fails without the fix |
| change_15_probe | New, in the suite (177 checks) | Change 15 contracts |
| change_15_capture | New, rendered | docs/Change_15_Evidence/ui/ (desktop evidence only; run without `--first-run-complete`) |

## Change 14 test updates

One full maintained-suite run after the implementation: **23 / 23**. The three contracts below changed on purpose and were updated with the same intent before that run; none was a production regression.

| Test | Change | Reason |
|---|---|---|
| change_5_probe | "Spell renders beneath actors" → Frost beneath, Lightning above, per `skill_effects.tres` | Change 14 per-effect layers (Lightning no longer hidden under its target). |
| change_12_probe | Explored label placement: top-right cluster between zoom and minimap; "Map Explored"; Heal ring values read from the Heal style | Change 14 map cluster; self-effect values moved from `world.gd` exports to the resource (same numbers). |
| change_13_probe | Gate label path `Row/Label`, "Next Stage"; boss wind-ups counted from `sim.skill_warning` | Change 14 chip and the separate wind-up signal (one warning plus one hit per action, as before). |
| change_14_probe | New, in the suite (202 checks) | Change 14 contracts. |
| change_14_capture | New, rendered | docs/Change_14_Evidence/ui/ (desktop evidence only). |

## Change 13 test updates

One full maintained-suite run after the implementation: 18 / 22 passed. The four failures were stale contracts for intended Change 13 rules (no production regression) and were updated with the same intent; all four then passed (**22 / 22**).

| Test | Change | Reason |
|---|---|---|
| change_7_probe | Auto-Merge covers the type's own outfit, not `unit-blue-cap_outfit_t3` | Change 13 exact-identity Auto-Merge (evolved or legacy tiers follow their own droppers). |
| change_8_probe | First skill-slot price 50 → 300 gems | Change 13 skill prices. |
| change_10_probe | Enemy-panel boss payout read with `fmt_currency` | Change 13 currency format ("×15", not "×15.00"). |
| change_11_probe | Potion ^100 cooldown 4 s → 10 s | Change 13 12 s base with a 10 s floor. |
| change_13_probe | New, in the suite (154 checks) | Change 13 contracts. |
| change_13_capture | New, rendered | docs/Change_13_Evidence/ui/ (desktop evidence only). |
| change_9_balance | Not changed; run once | Non-gating. Now fails "final boss ^300 with 4 cards" (boss at 3%) because of the slower player skills; log in docs/Change_13_Evidence/balance.log. |

## Change 12 test updates

| Test | Change | Reason |
|---|---|---|
| change_10_probe | 2 checks: base gem chance 8% → 5% | Change 12 gem chance rules (same intent: amount upgrades never change the chance; Boss Gem Chance adds 5 points per level). |
| change_7_probe | Heal-effect position read from the caster's view | Self effects are now children of the caster's view so they follow it; the check (ring on the feet, at the actor's scale) is unchanged in intent. Before, the probe crashed on the type change (script error). |
| audit, camera, evolution_farming, inspector, ui probes | `SettingsState.set_sfx_enabled(false)` → `SettingsState.mute_all_sfx()` | The single sound toggle became two category mutes. |
| change_12_capture | New, rendered | docs/Change_12_Evidence/ui/ (desktop evidence only). |

## Not in the default suite (non-gating)

| Item | Status | Why |
|---|---|---|
| change_9_balance | Passes | A balance fixture (deterministic duels); run it deliberately when combat numbers change. |
| change_16_audio | Passes (11 / 11), windowed | Real music playback through volume 0, the game pause and a scene re-entry. The audio service never decodes music headless, so this runs with a window: `godot --path . res://tests/change_16_audio.tscn -- --probe --profile=probe-c16-audio --no-autosave --first-run-complete`. |
| pacing_bot | Not run | Natural-pace benchmark (minutes per run); for pacing questions only. |
| change_*_capture (change_16_capture added), change_6_before, change_8_stage_capture, stage_overview_capture | Not gating | Rendered evidence (screenshots); run with a window. |
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
