# LootFarmer — Test Suite (Change 13)

## Maintained regression suite (gating)

Run: `python tools/run_probes.py` (all) or `python tools/run_probes.py <name> …`. It starts with `tools/validate_campaign_source.py`, then runs each probe headless and **sequentially** (playbook 60.1), each with a hard timeout. A run fails on a non-zero exit, a timeout, any `SCRIPT ERROR` line or a missing summary line: a runtime script error aborts a probe's coroutine before it can quit, so without the runner it looks like a hang. Set `GODOT` to the console executable on another machine.

| Probe | Covers |
|---|---|
| validate_campaign_source.py | Catalog and source contracts, translations, every catalog tool's `--check` (1,343 checks) |
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

Change 11 final run: 19 / 19 passed. Change 12 run: 21 / 21. **Change 13 run: 22 / 22** (`tools/run_probes.py`; change_10_probe and change_7_probe were updated first, see below).

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
