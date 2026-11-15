# LootFarmer — Change 80 report: Spring XP, Critical Damage, Camp Supplies, stage selector

Date: 2026-11-15. Base: 80c0bf4 (after Change 79 c050d99 and the Player Profiles framework). Brief: `docs/LootFarmer_Change_80_XP_Critical_Camp_Stage_Progression.md`. Evidence: `docs/Change_80_Evidence/`. Shipped rules: `docs/LootFarmer_GDD.md` (Change 80 section).

## 1. Files

- Data: `data/game/catalog.json`, written by `tools/change80_catalog.py` (idempotent, `--check`). It changes 12 `groups[].xp` values, `upgrades.critical_damage.effect`, `campaign.cards.challenge_c3.value` and `campaign.cards.regional_c3.value` and adds `regional_c3.cooldown`. `tools/tune_campaign.py --check` and `tools/change79_catalog.py --check` report no differences, and `tools/validate_campaign_source.py` passes 1791 checks.
- Rules: `scripts/game/campaign.gd` has the Camp Supplies rewrite, the migration, the Prestige keep list and `stage_progress()` / `next_stage_to_unlock()`. `scripts/game/simulation.gd` changes the `camp_supply_granted(ids, owed)` signal and adds the migration id. The `prestige_card.gd` change is a comment only.
- UI: `scripts/game/game_ui.gd` has the Camp Supplies toast, the camp-panel status line and the stage selector (`_stage_progression`, `_stage_row`, `_stage_status`, `_stage_badge`).
- Strings: `tools/change80_strings.json` (18 new keys plus the reworded, still-pending CAMP_SUPPLY_WAITING) and `tools/change80_changed_strings.json` (2 changed). Both went through `tools/localization_handoff.py`.
- Tests: `tests/change_80_probe` (new, in the suite), `tests/change_80_capture` (windowed evidence), `tests/change_80_xp_audit` (measurement). `tests/change_74_probe.gd` has one check rewritten for the new list. `tools/run_probes.py` and `docs/LootFarmer_Test_Suite.md` add change_80_probe and drop change_77_probe (see 6).

Not touched: `addons/player_profiles/`, profile definitions, store and marketing assets, the external Playbook, `project.godot` and `export_presets.cfg` (the developer's uncommitted version 42 stays uncommitted).

## 2. Spring XP

### Base XP before and after

These are base values before multipliers. Stages 1-6 and the formula are unchanged.

| Stage | Type | Before | After |
|---|---|---:|---:|
| Spring I | Bunny Ears | 358 | **500** |
| Spring I | Cat Ears | 600 | **650** |
| Spring I | Elf Ears | 1,005 | **850** |
| Spring I | Bee (boss) | 20,000 | 20,000 |
| Spring I | Orange Tabby Cat (boss) | 23,750 | 23,750 |
| Spring II | Flower Crown | 2,821 | **1,050** |
| Spring II | Green Cap | 3,978 | **1,250** |
| Spring II | Pink Cap | 5,612 | **1,500** |
| Spring II | Pink Flower Hood | 7,916 | **1,800** |
| Spring II | Plain | 11,166 | **2,150** |
| Spring II | Sprout | 15,750 | **2,550** |
| Spring II | Red Panda (boss) | 879,610 | **30,000** |
| Spring II | Sunflower (boss) | 1,044,700 | **35,000** |
| Spring II | Green Alien (final boss) | 4,912,510 | **45,000** |

The live catalog matched every "prior" value in the brief, so there was nothing to reconcile. The table is implemented exactly, with no deviations.

### XP sources and what is unchanged

XP comes only from kills (`simulation._kill` → `group_xp`). Missions, offline rewards and Prestige grant no XP, so nothing else needed to change. These are unchanged and checked by the probe: `xp_required = ceil(12 × L^1.35)`, cap 1000, the XP upgrade (+10% per level per type), cards, Veteran Traveler and Wisdom Tonic.

### Measured leveling speed

Source: controlled Focus-farm runs of 5 minutes with the unchanged audit harness, on HEAD and on Change 80. The builds are base-XP fixtures. Full table: `docs/Change_80_Evidence/xp_tables.md`.

| Build (fixture) | Type | Kills/min | XP/min before → after | Min per level before → after | Levels in 5 min before → after |
|---|---|---:|---:|---:|---:|
| Autumn II L135, supplied (reference, unchanged) | Horned Hood … Top Hat | 9.2–10.6 | 816–1,656 (same) | 5.5–11.1 (same) | 0 |
| Spring I L137 arrival, no supplies | Bunny Ears | 5.6 | 2,005 → 2,800 | 4.6 → 3.3 | 1 → 1 |
| Spring I L190 boss-ready | Bunny / Cat / Elf | 9.0 / 8.6 / 8.0 | 3,222 / 5,160 / 8,040 → 4,500 / 5,590 / 6,800 | 4.4 / 2.8 / 1.8 → 3.2 / 2.6 / 2.1 | 1/1/2 → 1/1/2 |
| Spring II L192 arrival, no supplies | Flower Crown / Green Cap | 3.4 / 2.6 | 9,591 / 10,343 → 3,570 / 3,250 | 1.5 / 1.4 → 4.1 / 4.5 | 3 / 3 → 1 / 1 |
| Spring II L165 arrival, no supplies | Flower Crown / Green Cap | 3.6 / 2.8 | 10,156 / 11,138 → 3,780 / 3,500 | 1.2 / 1.1 → 3.1 / 3.4 | 4 / 4 → 1 / 1 |
| Spring II L235 boss-ready | Flower Crown … Sprout | 7.0 … 4.6 | 19,747 … 72,450 → 7,350 … 11,730 | 0.97 … 0.26 → 2.6 … 1.6 | 5 … 18 → 1 … 3 |

What this shows:

- The real datapoint (about 5 minutes per level near L63 in Autumn I) and the Autumn II reference (5.5–11 minutes per level at L135) are untouched.
- Spring I is smoother. Bunny Ears levels about 28% faster, Cat Ears about the same, and Elf Ears about 15% slower, so the three types now sit close together (2.1–3.3 min per level at L190) instead of 1.8–4.4.
- Spring II normal farming stays the fastest leveling in the game per minute: a ready build gets 7,350–11,730 XP per minute, against 4,500–6,800 in Spring I. It is no longer runaway. At L235 a level takes 1.6–2.6 minutes, where it used to take 15–58 seconds, and a 5-minute session gives 1–3 levels instead of 5–18. Spring II farming is therefore not pointlessly slow, so no compensating change was made.
- The arrival builds without supplies die 5–10 times in 5 minutes on the harder Spring II types (Pink Cap and up). That is their combat fixture and the same before and after. Their kill rates are a lower bound. The aligned early types (Flower Crown, Green Cap) still level in 3–4.5 minutes.

### One boss kill (exact arithmetic, base XP)

| Boss | At level | Levels before | Levels after |
|---|---:|---:|---:|
| Red Panda | 165 / 192 | 59 / 51 | **2 / 2** |
| Sunflower | 165 / 192 | 68 / 59 | **2 / 2** |
| Green Alien | 165 / 192 / 235 | 211 / 193 / 169 | **3 / 3 / 2** |
| Bee, Orange Tabby Cat (unchanged) | 150 | 1, 2 | 1, 2 |

The probe also checks that a Green Alien kill at L150 gives 4 levels. That is below a normal Spring II level.

Side effect, an estimate: players reach Spring II and later Prestiges at lower levels than before, because the old Spring II bosses alone added 150–300 levels. The level cap of 1000, Prestige (it keeps player level and XP) and the boss tuning of Change 79 are unchanged. Change 79 tuned bosses against fixture levels L192–L235, which came from the old XP curve. On device, check whether a Spring II boss attempt at the new, lower natural level still feels fair. This change makes no balance change for it.

## 3. Critical Damage

| Upgrade level | No card | With Hard Hit |
|---:|---:|---:|
| 0 | 110% | 150% |
| 1 | 115% | 155% |
| 5 | 135% | 175% |
| 10 | 160% | 200% |
| 15 | 185% | 225% |
| 20 | 210% | 250% |

- Catalog: `upgrades.critical_damage.effect` 0.10 → **0.05**, `campaign.cards.challenge_c3.value` 0.75 → **0.40**. Currency (Gems), base 15, growth 1.25, cap 20, keep, card id, path and set membership are unchanged.
- One formula feeds every place the value appears: `simulation.player_upgrade_value` returns `n × effect`, a flat addition. `stat_sources` and `stats()` feed combat (`_resolve_attack` multiplies a critical hit by `stats().crit_damage`), the Stats panel, the upgrade row (`_critical_benefit` through `stats_with_upgrade`), stat-delta popups, simulations and the playtest adapters. There was no other copy of the number to update.
- English: CONTENT_CHALLENGE_C3_DESCRIPTION is now "Critical hits deal +40% more damage" (`change`: stale translations removed and the key is pending translation). The upgrade row has no hard-coded number.
- Probe-verified: the table above, flat rather than compounded (level 10 = +0.50), the preview 160% → 165%, a +10-point weapon extra on top, a real critical hit (damage with the card / without at level 5 = 1.75 / 1.35), and the values kept through save/reload and Prestige for a level 20 + card profile.

## 4. Camp Supplies

| Rule | Behaviour |
|---|---|
| Who | Owners of `regional_c3` (id, Regional path and set unchanged) |
| Where | Alive, inside an owned camp's rest radius, on the current map, which must be reached this run |
| Reward | 3 random supplies from that map's weighted supply pool, free |
| Cooldown | 10 minutes of active play per camp, from the moment the batch is complete. Camps are independent. |
| Clock | `playtime_total`. Runs while farming or travelling anywhere. **Stops while the app is closed**, paused, in the background or holding a Prestige choice, so there is no offline production. Device-clock changes have no effect. |
| Ready while standing in the camp | Yes, checked every fog tick. No need to leave and re-enter. |
| Backpay | None: one pending batch at most per camp |
| Full inventory | Units are granted one at a time and each is saved. Units that do not fit stay owed (`left`) and are delivered exactly once later. One notice per visit. The cooldown starts after the 3rd unit. Supply stacks are unlimited, so a real batch is all-or-nothing. |
| Feedback | Toast "Camp Supplies: +3 supplies" (actual count; "+1 <name>" for one unit), recent-finds feed per unit, camp panel "Camp Supplies: ready (3)" or "next in 7m 47s" |
| Prestige | Keeps every cooldown (`camp_supply` is on the keep list, and so are the clock and the camps). Map access resets, so late-map camps wait. |
| Hard Reset | Clears every record |
| Save | `state.camp_supply` {"stage:camp": {next, left}}. Normalized on load: invalid maps, camps and keys dropped; `next` clamped to one cooldown ahead of the saved clock; `left` clamped to 0..3. |
| Migration | Once, `camp_supply_cooldowns`. The old `camp_supplies` list is removed. Camps in it (they already gave their one supply this run) start a full 10-minute cooldown at load, so updating never pays them at once. All other owned camps are ready. A released schema 8 save (Camp Survey era) loads with every camp ready. |

Card text: "Get 3 free random supplies at each owned camp, every 10 minutes per camp" (`change`). The headline is "+3".

## 5. Stage selector

World → "Travel to another stage" now always lists **01–08** in order under Winter, Summer, Autumn and Spring headers, with a summary line. States come from `campaign.stage_progress()` and use this run only:

| State | Rule | Display |
|---|---|---|
| HERE | The map the player stands on | Cyan ring + HERE badge. Cannot be chosen. |
| Cleared | `stage < unlocked_stage` (its gate opened the next stage this run); Spring II after `world_complete` | "Gate bosses defeated" / "Final stage cleared" |
| Unlocked | The frontier stage (`stage == unlocked_stage`) | "Unlocked · gate bosses d / t" |
| NEXT | `unlocked_stage + 1`, from the frontier, never from the current map; none once all 8 are open | Gold ring + NEXT badge, "Locked · defeat the gate bosses of <previous> to unlock" |
| Locked | Everything after NEXT | Dimmed, "Locked" |

- An unlocked map other than the current one travels exactly as before: a full-card tap target that calls `_select_travel_stage` and keeps the guide key `travel_stage_N`. Locked maps get a disabled tap target (`stage_row_N`), so the Guided Winter II lesson and the Change 25 rule (no travel control to an unopened stage) still hold. The Teleport picker's stage row is unchanged.
- Performance: the list is built with the panel (at most once a second, never during a scroll gesture), not per frame. The panel refresh reuses same-shape controls and does not copy style overrides. Each card's look is therefore keyed by its `theme_type_variation`, so a state change replaces the card. The capture found a stale NEXT ring before this fix, and the probe now checks for it.
- Checked at 432×960 and 540×960 in English, 540×960 German and 432×960 Russian. The new keys fall back to English there. Every case passed the bounds audit (labels inside cards, no overlap, cards ≥ 56 px, list inside the sheet).

## 6. Validation

- `change_80_probe`: **153 checks, 0 failures**.
- `change_80_capture`: 5 runs, 0 audit failures. Screenshots are in `docs/Change_80_Evidence/`.
- Maintained suite: 55/71, no new failures (section 7).
- Localization: `tools/validate_localization.py` reports problems=0, with 372 keys pending translation, including the 21 added or changed here.

## 7. Suite comparison

`python tools/run_probes.py`: Change 80 **55/71**. Baseline: clean HEAD 80c0bf4 in a worktree, **54/71**. The failing probes are the same set, except that change_79_probe passes here and fails only in the worktree (its 540x960 reroll-row check). Error lines were compared probe by probe:

- **change_17_probe:** two checks hard-coded the old +10/level (3.1 at level 20, 13.1 with a +10 extra). They are updated to 2.1 / 12.1, the approved rule. What remains is its 1 baseline failure ("Prestige fixture must earn an opportunity").
- **change_57_probe:** the same pre-existing "no combat stat lost" failure. Its crit_damage figure is lower now because crit damage per level was reduced on purpose.
- **localization_batch01_probe:** the same failure, with the counts moved by the new pending keys (2000/2276).
- **localization_sweep:** the same 6 findings, recorded on a different Basic screen.
- **change_7_probe:** the same 8 failures. Its "resources still in use at exit" line is an intermittent engine shutdown warning: it appears in 6 logs on HEAD and 5 here, on different probes.
- **localization_progression_probe:** 55 findings against 54. The new one is `plate_off_screen` on de_DE `item_boss_enhanced` at 540x960 (sheet 717 px wide). A direct check rolled the same boss axe with seeds 0-11 on HEAD and on Change 80. Both give an identical result: 11 of 12 rolls overflow the sheet in German. This is a pre-existing width issue of the Change 79 reroll item panel. The probe now meets it only because the random roll sequence before that screen changed. It is not fixed here (out of scope).
- Unchanged pre-existing failures: export_manifest (the developer's uncommitted version 42), change_55, 54, 52, 51, 41, 27, 24, 20, 13.

No new failure is caused by Change 80. change_77_probe left the suite (superseded by change_80_probe), and change_74_probe passes with its rewritten Travel check.

## 8. Still to check on a phone

- Touch scrolling through the longer World panel with the 8-card list (fling and stop, no jump on refresh). The code path is the same panel scroll as before.
- The Camp Supplies toast placement in the bottom lane, and the camp-panel countdown, on real safe-area insets.
- How fast Spring II leveling feels at the lower natural levels the new curve produces, and whether Spring II bosses (tuned at L192–235 in Change 79) feel fair there.
- Translations: 21 Change 80 keys are pending for the 19 non-English catalogs, which show English until then.
