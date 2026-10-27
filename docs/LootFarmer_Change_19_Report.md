# Change 19 — Change 17 gameplay follow-up

Date: 27 October 2026. Apply to **lootFarmer(20261027-171448).zip**. This supplied project already includes the original 17 gameplay changes and declares version 18; this delivery increments the application and Android build version to 19. Save schema remains 8. No commits.

## Scope and implementation

The explicit chat scope reserves UI/tutorial/navigation for Claude and preserves Supply Mastery through Prestige. An attached `Pasted markdown(1).md` requests conflicting UI ownership and Prestige behavior. A clarification received no answer. This patch follows the chat scope: it does not apply the attached remaining-features brief, reset mastery, retain player level through Prestige, or implement its tutorial/UI work. Those changes require a scope decision before implementation.

The latest project already implements the original seventeen systems: saved per-boss respawns, 5% base Gem probability, permanent critical upgrades, out-of-combat healing, supply unlock pricing, assignable automatic skill capacity, mastery from use, supply interval upgrades, five supply purchases, six 20-second cooldowns, skill curves/caps, Lightning attack slow, reusable boss-duration resistance, highest-stage mission Coin/Gem scaling and weather calculation optimization. These were retained and regression-tested, not duplicated. Their detailed behavior remains in `LootFarmer_Change_17_Notes.md`.

This patch adds the requested follow-up corrections:

- **Skill proximity:** all five offensive/buff skills require a living, visible, eligible enemy within 64 world units, configurable in `data/game/catalog.json` under `progression.change17.skill_activation_distance`. Manual and automatic casts share the check. Direct player skill resolution also refuses an out-of-range cast. No cooldown or effect is spent on refusal. Heal still works at any missing HP outside combat. Arcane Focus retains its existing combat requirement in addition to proximity.
- **Target selection:** prefer an eligible nearby locked target; otherwise select the nearest eligible nearby enemy, respecting farming filters. Availability queries do not clear/acquire the basic attack target or consume RNG. Single-target skills stay single-target; Frost remains caster-centred and Fire target-centred with their existing radii. Enemy skill reach is unchanged.
- **Button API:** `campaign.skill_cast_block_reason(slot)` is empty when available and returns a stable reason otherwise. Claude must poll this as actors move and set the existing disabled appearance. It includes cooldown, death, empty/locked slots and pause/suspension/Prestige locks. No temporary UI was added.
- **Boss Gem display:** `player_upgrade_value("boss_gem_chance", extra)` now returns the total via `boss_gem_chance(extra)`, including the existing 5% base and global bonuses once. With no other upgrades, the first row reads 5% → 10%; the existing renderer already uses this API. Specific-boss `gem_chance(group)` also includes its achievement bonus. Actual drop probabilities are unchanged.

## Validation

Engine: **Godot 4.7.2 stable, Linux headless**. The full maintained runner completed **28/28 entries passing**: source validation plus 27 probes. Source validation: **1,557 checks, zero failures**. New `skill_proximity_probe`: **133 checks, zero failures**. Existing `change_17_probe`: **679 checks, zero failures**. Weather equivalence: **60 checks, zero failures**. No maintained fixture was weakened or rewritten for this patch.

New coverage includes all five skills on both sides of the inclusive 64-unit boundary; manual, automatic and direct resolver refusal; no cooldown/effects while blocked; leaving/re-entering range; dead targets; far locked-target fallback; unchanged Fire area identity; configurable radius; read-only query purity; pause/invalid slots; full-health refusal; manual/automatic Heal outside combat; initial/subsequent boss previews; and unchanged actual Gem probabilities for all 48 enemy types.

The maintained suite additionally covers the original 17 changes, save migration and JSON/disk round trips, Prestige retention, Hard Reset, mission reward formulas, critical caps, skill power at intermediate levels and ^500, real Lightning timing, independent boss countdowns and weather output equivalence. Passing historical UI probes does **not** certify the deferred new UI.

Reproduce:

```sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 python tools/run_probes.py
```

Raw current full-suite and per-probe logs are in `docs/Change_19_Evidence/`. Editor import/compile succeeded without script errors. This is not an Android export or physical-device performance result.

## Claude integration still pending

See `LootFarmer_Change_17_Claude_Integration.md` for state, actions, events and interactions for every surface.

- Disable/re-enable skill buttons from the new query each HUD update; preserve cooldown text and disabled styling. Update range and healing descriptions.
- Connect critical tracks, pooled automatic skill capacity and equipped-slot selection.
- Present supply automation prices/intervals, all five shop supplies and use-based mastery progression.
- Render boss countdowns at known spawn positions with fog/discovery checks.
- Show live highest-stage mission rewards and effective skill power/caps; describe Lightning and boss status durations accurately.
- Verify the existing boss chance row displays effective totals, including global bonuses, without adding another base in presentation code.
- Complete the existing handoff's tutorial/help/localization work. The conflicting attachment's additional UI/tutorial features are not included.

## Android verification checklist and unresolved decisions

- After Claude connects availability, walk into/out of the activation boundary and move between enemies; verify button state, automatic casts and no failed-cast sound/effect. Check Heal near full HP outside combat.
- Verify boss Gem totals and upgrade previews on-device; check long translations and the existing percentage formatting.
- Compare identical rainy-stage camera, actors and loadout with weather on/off; capture CPU/GPU frame times, draw calls and overdraw. Verify rain density, splash anchoring and appearance. The earlier weather optimization remains intact; no new Android speedup is claimed.
- Exercise save/relaunch/background transitions, boss countdowns and Prestige on the exported release.
- **Balance review remains open:** the earlier Change 17 report records non-gating late-boss benchmark failures (33/35 versus baseline 34/35), which were not rerun or silently retuned here. Its fixtures omit new critical upgrades; actual campaign/device playtesting is needed before any rebalance.
- The 64-unit starting activation radius is editable and needs play-feel acceptance. Supply interval growth ×1.6 to 2 seconds, skill slot prices 100/250/500 Gems and mission equivalents 40/80 kills remain the original Change 17 authored decisions.
- Resolve the conflicting attached scope before implementing its UI/tutorial and Prestige reversals.

## Delivery

The ZIP contains only files changed relative to the named latest attachment, with project-relative paths at its root. Generated Godot caches, imported assets, engine binaries and build artifacts are excluded. The patch manifest records payload paths and hashes. Unchanged original Change 17 implementations remain in the base project.
