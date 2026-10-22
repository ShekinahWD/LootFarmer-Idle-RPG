# LootFarmer — Test Suite (Change 15)

## Maintained regression suite (gating)

Run: `python tools/run_probes.py` (all) or `python tools/run_probes.py <name> …`. It starts with `tools/validate_campaign_source.py`, then runs each probe headless and **sequentially** (playbook 60.1), each with a hard timeout. Since Change 15 the runner passes `--first-run-complete` to every probe except `change_15_*`: fresh profiles in probes of ordinary play start with every menu revealed and the early equipment guarantee spent (Playbook 18.10); the Change 15 probe covers the progression itself. When running another probe by hand, add the flag. A run fails on a non-zero exit, a timeout, any `SCRIPT ERROR` line or a missing summary line: a runtime script error aborts a probe's coroutine before it can quit, so without the runner it looks like a hang. Set `GODOT` to the console executable on another machine.

| Probe | Covers |
|---|---|
| validate_campaign_source.py | Catalog and source contracts, translations, every catalog tool's `--check` (1,361 checks) |
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

Change 11 final run: 19 / 19 passed. Change 12 run: 21 / 21. Change 13 run: 22 / 22. Change 14 run: 23 / 23. **Change 15 run: 24 / 24** (`tools/run_probes.py`; stale contracts updated first, see below).

`tools/fog_reachability.gd` (run with `godot --headless --path . -s tools/fog_reachability.gd`) checks the stored unreachable fog cells against a fresh flood fill (8 / 8 maps match).

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
| pacing_bot | Not run | Natural-pace benchmark (minutes per run); for pacing questions only. |
| change_*_capture (change_15_capture added), change_6_before, change_8_stage_capture, stage_overview_capture | Not gating | Rendered evidence (screenshots); run with a window. |
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
