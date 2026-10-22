# Change 9: outfit growth and late-game balance

Baseline: 780f0f4 (Change 8 + Snowman prestige gate). Brief: `docs/LootFarmer_Change_9_Late_Game_Balance.md`. Save schema stays 7; no migration is needed. Catalog values come from `tools/change9_catalog.py`, followed by `tools/tune_campaign.py`. Both are idempotent and support `--check`.

## What changed

| Area | Implementation |
|---|---|
| Outfit growth | `core = base × (1 + 0.02·min(m,100) + 0.01·max(0, m−100))`, m clamped to 0–500. It uses the existing pipeline (`merge_levels`): every outfit's merge gain is 2% of base, and past ^100 each copy counts as `outfit_tail_rate` 0.5 levels (`catalog.progression.merge`). ^100 3×, ^200 4×, ^300 5×, ^400 6×, ^500 7×. Skills keep the Change 8 log tail. Weapons stay linear to ^100. |
| Milestones | Equipped outfit only (`catalog.progression.outfit_milestones`, `sim.outfit_milestones()`), t = the outfit's tier. ^100 Guard +3t Defense; ^200 +10% of the outfit's core HP; ^300 Recovery 0.05%·t of max HP per second; ^400 Guard 6t; ^500 Mastery Guard 10t and Recovery 0.08%·t. Later steps replace Guard and Recovery values. The ^200 HP share uses core HP (base + merges), never the spare-copy bonus or random extras. Milestones appear in Stats as their own source, "Outfit milestones (worn)". |
| Recovery | New `regen_pct` stat. It is added to the existing heal line in `simulation.step` (`regen + maxHP × (rest + regen_pct)`), so it runs only while alive, unpaused and online, and is capped at max HP. |
| Defense | Guard flows through `stats().defense` into the existing `100/(100+def)` for basic hits and enemy skills. There is no second protection path. |
| Passive shares | Unequipped outfits count 15% (`stored_outfit_factor`), including their random extras. Unequipped weapons stay at 30% (`stored_weapon_factor`). The equipped item counts once at full value; its spare copies add nothing. Stored outfits never add milestones. |
| Spring II | Normal levels 195/201/207/213/219/225, bosses Red Panda 235 and Sunflower 240, final Green Alien 250. Normals carry and drop Diamond weapons (same family as before) and the existing `_t5` outfits, which are now active rather than legacy. Bosses carry and drop Emerald weapons (Change 8 rule: normals' tier + 1) and their `_t5` boss outfit. The final boss uses its own `final_hp` 18; the other bosses keep 14.5. Result: Red Panda 177.0K HP / 280.7 damage, Sunflower 197.3K / 301.0, final 304.5K / 345.8. Stages 1–7 are unchanged. Drop chances are unchanged (5% / 30%, Loot Chance +0.5 points × 15). |
| UI | Outfit details show "Milestones (while worn): …", "Next at ^N: …" or "All milestones reached (Mastery)", and the growth rule with the stored share. The comparison shows Defense and Recovery deltas from the same `stats_with()` getter. Stats shows Recovery (% and HP/s) and "Stored gear counts: Weapons 30% · Outfits 15%". |
| Saves | No new saved fields. Owned Tier 4 Spring II outfits become `legacy` but stay owned, mergeable and equippable. Evolved legacy outfits (for example tier 7) use their own tier for milestones. Prestige still resets items, so no milestone carries over. |

## Weapon passive: kept at 30%

The test uses the same realistic loadouts as the duels below, with stored weapons set to 15%:

- Damage falls 11.6% at the Red Panda (935 → 827) and 13.9% at the final boss (1,574 → 1,354).
- The final boss fight at ^300 with 4 cards and 3 skills changes from a win (58 s, 25% HP left) to a loss (boss at 6.5%).

Weapons have only 14 shared identities (two ladders), so their passive cannot stack across many families the way 48 outfits could. They are also the player's only damage scaling. Cutting them would have to be paid back with extra farming. Outfits drop to 15% because milestones now move their value into the worn item.

## Realistic loadouts (tests/change_9_balance, real simulation duels)

Each duel uses the real simulation: basic attacks, auto-cast skills, boss skills and boss Heal, Defense, Recovery and lifesteal, stepped at 0.1 s for up to 600 s. Every item must be dropped by some enemy (no legacy items, no weapon above the best drop tier) and every equip must succeed. Random extras are cleared. Cards: Arsenal HP +20%, Hunter boss damage +25%, Arsenal Guard 10% and Arsenal damage +15%; the six-card case adds Hunter boss guard 20% and Challenge lifesteal 5%.

| Fight | Loadout | Result |
|---|---|---|
| Bee (Stage 7), first kill, Change 8 rules | L190, Gold Sword ^100, elf-ears T4 ^100, 2 skills, 2 cards | loss at 24 s, boss 71% |
| same, Change 9 | same | loss at 28 s, boss 63% (no regression) |
| Bee, farmed | elf-ears ^300, 4 cards | loss at 42 s, boss 41% |
| Red Panda | L225, Diamond Sword ^100, sprout T5 ^100, 3 skills ^50, 4 cards | loss at 30 s, boss 55% |
| Red Panda | sprout ^300 | loss at 44 s, boss 36% |
| Red Panda | sprout ^300, 6 cards | win in 65 s, 63% HP left |
| Red Panda | sprout ^500 | win in 65 s, 24% HP left |
| Final | L240, Emerald Sword ^50, Sunflower boss outfit T5 ^100, 3 skills, 4 cards | loss at 38 s, boss 34% |
| Final | Sunflower outfit ^300 | **win in 58 s**, 25% HP left |
| Final | ^300, no cards | loss at 46 s, boss 45% |
| Final | ^300, no skills | loss at 66 s, boss 60% |
| Final | ^300, stored weapons 15% | loss at 62 s, boss 6.5% |
| Final | ^500 | win in 58 s, 68% HP left |

Basic attacks alone are only part of the damage. The content probe's basic-attack figure for the final loadout is 210 s to kill and 57 s survival; skills, the boss-damage card and Defense make up the gap. Boss skills (Fire, Strike, Focus) and boss Heal make real fights harsher than the investigation's hand estimates, which counted basic hits only.

**Feasibility:** the final boss is beatable before ^500 (at ^300) with Emerald gear from the Spring II bosses, 3 skills and 4 cards. It is not trivial: ^100, no cards or no skills all lose. Reaching player level 225 takes 1.71M XP in total (level 240: 1.99M), about 110–130 kills of the top Spring II type, so level is not a bottleneck. ^300 on one outfit is about 300 copies. At 5–12.5% per item on 3 of 4 spots, that is roughly 6–20 hours of focused farming of one Spring II normal type. ^500 is an optional ceiling, not a requirement.

**For device playtesting:**
- The Red Panda is the Spring II wall. With Diamond gear it needs ^500 on a Tier 5 outfit or about 6 prestige cards. No further numeric change was made, because it is beatable and the brief allows narrow changes only to prevent impossibility.
- The Stage 7 first kills (Bee, Tabby) also lose with a stage-tier Gold weapon, before and after this change. Stages 1–7 were out of scope.
- Both are flagged for Android.

## Checks (desktop, headless; not device evidence)

| Suite | Result |
|---|---|
| tests/change_9_probe (new: curve ^0–^500 and over-cap, milestones per step, equip/unequip/switch, stored 15%/30%, no double count, Recovery in step / paused / dead, Guard in the real attack, Spring II tiers/levels/final factor/drops, Stage 1–7 unchanged, Change 8 save with legacy outfits, prestige reset, item and Stats UI) | 51 / 0 |
| tests/change_9_balance (new: 13 duels, weapon share, impossible-loadout rejection, level feasibility) | 35 / 0 |
| tests/campaign_content_probe (ceiling fixture replaced; see below) | 110 / 0 |
| change_8_probe / change_7_probe / change_6_probe / change_5_probe / campaign_probe | 73/0, 78/0, 200/0, 137/0, 262/0 |
| tests/change_7_smoke | clean |
| tools/validate_campaign_source.py (now writes docs/Change_9_Evidence/static_checks.json) | 1250 / 0 |

**Ceiling fixture:** the old fixture equipped `boss-green-alien_outfit_t7` without owning it (the equip failed silently, so no outfit was worn) and used obsidian weapons that no enemy drops. Its 463 s / 14 s figures are withdrawn. The new fixture asserts that every item is obtainable and that each equip succeeds.

**Assertions updated** (each encoded a rule this change replaced): the Change 7 tier rule now says Spring II is Tier 5 (and it resets its shared counter), and the Change 8 ^500 bound is now 7× base.

Evidence: docs/Change_9_Evidence (balance.log, change_9_probe.log, static_checks.json). The roster sheet docs/LootFarmer_Enemy_Roster.csv still lists the old Spring II levels; the catalog is authoritative. The sheet was not edited, to avoid regenerating its imported translation files.

Not re-run: `change_8_walk_probe` (no map or solid changes) and the pacing bot (no long campaigns, per the brief).
