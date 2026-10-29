# LootFarmer — Change 36: Supplies 3 Uses + Final Boss Balance Audit

**Date:** 28 October 2026 · **Source:** commit `090e279` (Change 35) plus this change · **Brief:** `LootFarmer_Supplies_3_Uses_and_Final_Boss_Balance_Audit.md`

One gameplay value changed: supply mastery now rises once per **3** successful uses (was 5). No boss, enemy, item, card, upgrade or economy value changed. The final-boss audit below is evidence and recommendations only.

---

## 1. Supply change: 5 uses → 3 uses

| | Before | After |
|---|---|---|
| `data/game/catalog.json` → `progression.change17.supply_uses_per_level` | 5 | **3** |
| Uses for ^1 / ^25 (Steady) / ^50 (Potent) / ^100 (Mastered, cap) | 5 / 125 / 250 / 500 | **3 / 75 / 150 / 300** |

- **Single source.** Every consumer already read the catalog value: `simulation.supply_mastery()`, the use counter in `use_item()`, the save clamp in `campaign.normalize_change17()` and the panel line "Next mastery level: x / 3 uses". No divisor is hard-coded.
- **Unchanged:** effects and per-level gain, cap ^100, the ^25/^50/^100 milestones, stock, shop prices, automatic use, cooldowns, and blocked-use rules (no use is counted for a blocked, bought, dropped or collected copy). Prestige still clears uses and credit.
- **Save compatibility (no schema change).** `supply_uses` holds actual successful uses, so an existing count keeps its meaning. Mastery is re-derived with the new divisor and the remainder carries over: an old save with 11 uses now shows ^3 with 2/3 toward ^4. One-time legacy `supply_mastery_credit` is added exactly as before and is never re-credited. The load clamp is now cap × 3 = 300 uses. A save recording more than 300 uses loads as 300, at the same ^100 mastery, so no visible progress is lost.
- **English copy** (`localization/en.po` only; the 19 pending languages were not touched):
  - `SUPPLY_MASTERY_EXPLAIN` now reads "Every 3 actual uses of this supply grant one mastery level…"
  - `SUPPLY_NO_MERGE` now reads "Every three uses raise Supply Mastery…"
  - Placeholder signatures are unchanged, so the pending translation import is unaffected.
- **Tests:**
  - New `tests/change_36_probe` (180 checks) covers:
    - uses 0–6 for all five supply types, including the 3rd and 6th use, and proof that the 5th use is no longer the level-up;
    - repeated uses, separate counters per type, and the 74/75, 299/300 and counter-ceiling boundaries;
    - milestones, auto-use (two automatic uses complete a level) and blocked uses at full health or on cooldown;
    - purchases, older saves with a remainder, legacy credit migration (once only), 500-use saves, a disk round trip, Prestige, the panel text "2 / 3" → "0 / 3", and the English strings.
  - Fixtures in change_5/11/13/16/17 that wrote `uses = mastery × 5` now multiply by the catalog value.

## 2. Final boss: Green Alien, Spring II (Stage 8), 13-key route

### 2.1 Encounter (read from the live catalog and `enemy_abilities.tres` by the audit)

| Property | Value |
|---|---|
| Level / HP / damage | 250 / **304,514** / **345.8** per hit every 2.0 s (≈173 DPS basic), Defense 0 |
| Gate | All 13 other boss keys (`state.keys`), physical Stage 8 access. Keys drop on each boss's first kill after the final boss has been discovered, so **Red Panda and Sunflower kills are hard prerequisites** |
| Actions | One action every 11 s, with a 0.6 s telegraph; each skill has a 20 s cooldown |
| Attack pool | Strike 968, Fire 553, Lightning 484 (halves the player's attack rate for 3 s), Frost 415 + slow; Focus (+15% damage, 2.5 s on a boss) |
| Heal | Only below 50% HP, and then it takes priority: 4% of max HP = **12,181 HP** per cast. Measured: 4–10 heals per kill, 49K–122K HP restored, i.e. 16–40% of the boss's HP. This is the real DPS check |
| Summons | Green Cap helpers: first after 8 s, then every 20 s, 2 per call, 3 alive at most. Each has 2,330 HP and deals 39.5 per 1.5 s; they give no rewards |
| Reset | Out of combat the boss regenerates 10% of max HP per second after 5 s. **Every attempt starts at full HP; attrition across deaths is impossible** |
| Player behaviour (real auto-play) | Locks onto the boss and stays on it, ignoring helpers. Auto-casts equipped skills; auto-uses supplies from bound slots |

### 2.2 Method

`tests/change_36_final_boss_audit.gd` (non-gating, run deliberately) reads `docs/Change_36_Evidence/final_boss_builds.json` and plays every build in the unmodified simulation at 0.1 s steps for up to 900 s, with 5 seeds each. It runs under a watchdog, exits non-zero on any legitimacy failure, and the run must show no `SCRIPT ERROR`. Each build is constructed the way a player gets it:

- **Prestige cards:** a real Prestige transaction (`begin_prestige` / `choose_card`) over the opportunities the named earlier run would have made ready. The run reset then clears inventory and Coins, as in play.
  - **early** = one Prestige after a run to Summer II (Stage 4). That run readies 23 opportunities, e.g. Snowman/Gray Cat/Teal Dinosaur kills, Winter II/Summer II entries, ^10 merge, a tier-3 item, two missions and offline time. Picks favour combat; the 23 cards include Hunter Boss Damage/Guard, Challenge Crit/**Lifesteal**, Trophy Boss Damage, Arsenal HP/Damage, Masterwork Equipped, and Specialist Skill.
  - **full** = all 33 cards, available after one complete run to Spring II.
  - **none** = no Prestige.
- **Gem and Coin upgrades:** bought through `buy_upgrade`; the currency granted is recorded in the CSV (`gems`, `coins`).
- **Items:** every weapon, outfit and skill must be a non-legacy id an enemy actually drops (or, for weapons, the evolution of one), within its merge cap, and its equip must succeed. Copies needed and drop sources are written per build. Item random rolls are set to none, which is conservative.
- **Seeded (labelled):**
  - player level, with the XP it needs reported;
  - merge levels, with the copies they need reported;
  - supply mastery, set as successful uses (with the old-rule equivalent reported) and stock;
  - the 13 real boss ids as keys;
  - Stage 8 access.

These are **reproducible combat fixtures, not end-to-end progression measurements**. Stored items are a deliberately light set: Gold Sword ^20, Gold Axe ^10, Diamond Axe ^5 and four Stage 8 outfits at ^0.

Command: `godot --headless --path . res://tests/change_36_final_boss_audit.tscn -- --probe --profile=probe-audit36 --no-autosave --first-run-complete` (≈6 min, 140 duels). Add `--mode=farm` for farm rates (≈2 min). Result: **280 checks, 0 failures; farm 14 checks, 0 failures; no script errors.** Evidence:

- `final_boss_trials.csv`: one row per duel, with stats, supplies used, boss and player casts, heals, helpers, damage taken, cards, Gems/Coins and the legitimacy note;
- `farm_rates.csv`, plus both `.log` files.

Before this ladder, about 1,300 exploratory duels (unrecorded grids) located the thresholds. **The fights are nearly deterministic:** seeds move the duration by only ±1–9 s, so 5/5 means a reliable outcome under auto-play, not a statistical win rate.

### 2.3 Builds and results (measured, 5 seeds each)

| Build | Prestige | Level | Weapon | Outfit | Skills (auto) | Supplies (auto, 3 slots) | Result | Time | HP left |
|---|---|---|---|---|---|---|---|---|---|
| **MIN — minimum verified** | early | 250 | Diamond Sword ^75 | Red Panda t5 ^0 | none | Potion, Recovery Salve, Guard Tonic ^25 | **5/5 win** | 256–263 s | 68% |
| MIN-w50 | early | 250 | Diamond ^50 | ″ | none | ^25 | 0/5 | dies 66–88 s | boss ≥64% |
| **MIN-old** (same 75 uses, old rule → ^15) | early | 250 | Diamond ^75 | ″ | none | ^15 | **0/5** | dies 53–72 s | boss ≥64% |
| MIN-s20 | early | 250 | ″ | ″ | none | ^20 | 0/5 | dies 60–77 s | — |
| MIN-L235 | early | 235 | ″ | ″ | none | ^25 | 2/5 | 90–263 s | marginal |
| MIN-stock 15/10/6 | early | 250 | ″ | ″ | none | ^25, low stock | 0/5 | runs out at 152–162 s | boss 31% |
| MIN without Salve / Guard / Potion / any supply | early | 250 | ″ | ″ | none | two of three / none | 0/5 each | dies 24–60 s | — |
| MIN vs Red Panda / vs Sunflower (key prerequisites) | early | 250 | ″ | ″ | none | ^25 | 5/5 / 5/5 | 145–150 s / 161–166 s | 94% / 79% |
| **REC — recommended** | early | 260 | Diamond Sword ^100 | Red Panda t5 ^25 | Strike, Lightning, Focus ^10 | ^25 | **5/5 win** | 156–160 s | 75% |
| REC without skills | early | 260 | ″ | ″ | none | ^25 | 5/5 | 207–211 s | 73% |
| REC supplies ^50 | early | 260 | ″ | ″ | ″ | ^50 | 5/5 | 156–160 s | 88% |
| REC stock 15/10/6 | early | 260 | ″ | ″ | ″ | ^25, low stock | 5/5 | 156–160 s | 69% |
| REC with the full card set | full | 260 | ″ | ″ | ″ | ^25 | 5/5 | 118–123 s | 98% |
| REC without Salve / without supplies | early | 260 | ″ | ″ | ″ | Potion+Guard / none | 0/5 / 0/5 | dies 84–111 s / 36–40 s | — |
| REC with no Prestige cards | none | 260 | ″ | ″ | ″ | ^25 | 0/5 | dies 15–24 s | boss ≥93% |
| FULL — minimum found with all cards | full | 250 | Diamond ^50 | Sprout t5 ^0 | none | ^25 | 5/5 | 222–239 s | 79% |
| FULL supplies ^15 | full | 250 | ″ | ″ | none | ^15 | 0/5 | dies 55–77 s | — |
| **NOP — minimum found, no Prestige** | none | 250 | Emerald Sword ^50 | Red Panda t5 ^100 | none | ^100 | 5/5 | 367–371 s | 67% |
| NOP supplies ^50 / outfit ^50 | none | 250 | ″ | ^100 / ^50 | none | ^50 / ^100 | 0/5 / 0/5 | dies 42–64 s | — |
| NOP-alt | none | 250 | Emerald ^25 | Red Panda ^100 | Strike, Lightning, Heal ^25 | ^100 | 5/5 | 360–365 s | 91% |
| NOP vs Red Panda / Sunflower | none | 250 | Emerald ^50 | Red Panda ^100 | none | ^100 | 5/5 / 5/5 | 203–205 / 238–241 s | 83% / 78% |

**Fight resources (seed 1):**

- **MIN:** used 21 Potions, 20 Salves and 11 Guard Tonics. The boss cast 7 Heals (85,264 HP), 5 Fire, 4 Strike, 4 Lightning, 1 Frost and 1 Focus, and summoned 3 helpers; the player took 50,031 damage.
  - Effective stats: damage 966, HP 3,919, crit 20% ×1.5, lifesteal 5%.
- **REC:** used 13 Potions, 4 Salves and 7 Guard Tonics. The boss cast 4 Heals (48,722 HP); the player took 29,416 damage and cast each skill 8 times.
  - Effective stats: damage 1,130, HP 5,052.

**Upgrades (Gems carry across Prestige):**

- **MIN, 2,044 Gems:** 2 supply slots, Auto Supply ×3 (1,036), Use Speed ×4 (926), and gear slots.
- **REC, 3,836 Gems:** the MIN set, plus 2 skill slots (900) and 3 auto-cast slots (850).

**Level:** XP from level 1 is 2.19M to level 250 and 2.41M to level 260.

### 2.4 What wins and why

1. **Sustain is a cliff, not a slope.** Before Defense the boss deals about 173 DPS from basic hits, plus one skill every 11 s (≈40–90 DPS; a Strike alone is 968) and up to three helpers (≈80 DPS). Prestige-card builds deal enough damage that 5% lifesteal plus the three supplies hold HP steady. Once that holds, the player never dies, and the fight becomes a DPS race against the Heal, which restores about 550 HP/s below 50%. When it does not hold, the player dies within 25–90 s whatever the gear. That is why:
   - ^20 → ^25 supply mastery, where the Steady milestone lengthens buffs by 20% and shortens the potion cooldown by 10%, flips 0/5 to 5/5;
   - removing any one of the three supplies loses, even for REC;
   - more outfit HP above the cliff changes only the HP left, not the result.
2. **Prestige cards are the largest single lever.** The same recommended gear without cards loses within 24 s. One early Prestige gives 23 cards: about +55% boss damage, +20% HP, 5% lifesteal, +15% crit, +20% equipped stats, and the Boss Specialist / Balanced Growth combos.
3. **Skills are optional.** They shorten the fight by about 50 s (207 → 158 s) but are not needed to win.
4. **The 3-use rule changes outcomes at the threshold.** With exactly 75 successful uses per supply, the old rule gives ^15 and loses (MIN-old, FULL-s15: 0/5); the new rule gives ^25 and wins (MIN, FULL: 5/5). For builds clear of the threshold (REC, NOP) it only lowers how many uses mastery takes.

### 2.5 Farm rates (measured; MIN as the farmer unless noted; Stage 8; mission auto-claim on)

| Spot (per-type upgrades) | Minutes | Kills/min | Deaths | XP/h | Kill Coins/h | Relevant drops (count in sample → per hour) |
|---|---|---|---|---|---|---|
| Sprout, both items (none) | 30 | 6.6 | 2 | 8.1M | 12.2K | Diamond Sword 16 → **32/h**; Sprout outfit 12 → 24/h; Potion 12/h, Salve 2/h, Guard 2/h |
| Plain, weapon only (none) | 30 | 7.5 | 0 | 6.6M | 14.0K | Diamond Sword 21 → **42/h** |
| Sprout, both (Loot ×8, cost 12,326 Coins) | 30 | 6.6 | 2 | 8.1M | 12.2K | Diamond Sword 26 → **52/h**; outfit 36/h |
| Sprout, skill casters (none) | 30 | 2.5 | **38** | 3.0M | 4.6K | Focus skill 4 → 8/h (MIN is too weak for this spot) |
| Sprout, both, REC farmer with every per-type upgrade (523K Coins + 20.7K Gems) | 30 | 5.4 | **43** | 6.7M | 10.1K | Spawn Amount ×3 swarms this build; the upgrades are counter-productive here |
| Red Panda loop (none) | 60 | 0.37 (22/h) | 0 | 29M | 3.8K | Emerald Sword 5/h, Red Panda outfit 3/h (expected ≈7.3/h each at 33%) |
| Sunflower loop (none) | 60 | 0.13 (8/h) | **21** | 12.5M | 1.4K | MIN wins the duel but dies to the surrounding spot when looping |

Drop counts match the odds (5% + 3% from the Collection card per carried item: 198 kills → 15.8 expected Diamond Swords, 16 measured). **Gem income was not measured:** kill Gems are about 20/h, and no missions completed within the samples. By formula a Stage 8 gem mission pays 75–125 Gems (base 3–5 × 25). Mission and offline Coin income is also excluded, so the Coin estimates below are conservative.

### 2.6 Preparation time

Measured rates turned into hours by arithmetic. **These are estimates, not measured progressions.**

| Requirement | MIN | REC | Basis |
|---|---|---|---|
| Prestige | one early Prestige (a run to Summer II; design target 1–2 h for the first Prestige) | same | **not measured here**; the last bot figure (76 min, Change 5) predates the current economy |
| Climb back to Stage 8 and earn all 13 keys (discover the final boss, then kill each boss once) | required | required | **not measured** (no current whole-campaign pacing run exists) |
| Level | 250 (≤0.5 h at Stage 8 from about level 200) | 260 | measured XP/h |
| Main weapon | Diamond Sword ^75 = 76 copies → **1.8–2.4 h** | ^100 = 101 copies → **2.4–3.2 h** (≈2 h with Loot ×8) | 32–52/h measured |
| Outfit | Red Panda t5, 1 copy → ≈10–20 min (often already earned with the key) | ^25 = 26 copies → **3.5 h** expected (up to ≈8 h at the 3/h measured in one hour) | 22 kills/h at 33% |
| Skills | — | Strike/Lightning/Focus ^10 = 33 copies → ≈2–4 h (optional) | 8/h measured for Focus; others unmeasured |
| Supplies to ^25 (75 uses each, Coins at flat shop prices) + one attempt's stock | ≈60K + 13K Coins → **≈5–6 h of Stage 8 kill Coins** if all bought (old rule: 125 uses ≈ 100K + 13K → 8–9 h); partly overlaps weapon farming and earlier-stage potion use | same | 12–14K Coins/h measured; mission/offline Coins excluded |
| Gems | 2,044 (kept across Prestige) | 3,836 | income not measured |

- **Stage 8 preparation (estimate):** MIN ≈ **4–6 h** of active play; REC ≈ **8–12 h** (≈6–8 h without the optional skills). Supplies, Coin-limited, are the largest single item for MIN; the Red Panda outfit is the largest for REC.
- **Whole journey:** a first run to Summer II, a Prestige, then a full climb to Stage 8 with every boss key. That earlier part is not simulated in this change. Uncertainty is therefore wide, and **no total hour count is claimed**. A refreshed whole-campaign pacing measurement (or the developer's device playthrough) is needed for one.
- **No Prestige** (NOP): 101 Red Panda outfits at ≈3–7/h is **≈15–35 h of boss looping** alone, plus Emerald ^50 (51 copies at ≈5–7/h ≈ 7–10 h) and supplies ^100 (300 uses each ≈ 240K Coins ≈ 17–20 h of kill Coins). That is realistic only for a dedicated grinder.

## 3. Verdict

**Beatable: yes.** It is reproducibly beatable under the real rules: auto-play, full boss kit, no attrition. The legitimate route runs through **one Prestige**.

- **Minimum verified winning build (MIN):** one early Prestige (23 cards, crucially Challenge Lifesteal and the boss-damage cards), level 250, Diamond Sword ^75, one Red Panda outfit, no skills, and Potion + Recovery Salve + Guard Tonic all at ^25 on three auto slots, with at least about 21/20/11 in stock. It is a tested lower bound for this card set and stored set, not a proven global optimum. The neighbouring losses show it sits right at the cliff: Diamond ^50, supplies ^20 and level 235 all lose or only sometimes win.
- **Recommended for an average player (REC):** the same Prestige, level 260, Diamond Sword ^100, Red Panda outfit ^25, Strike/Lightning/Focus ^10 on auto-cast, and the three supplies at ^25 with 15/10/6 or more in stock. It wins in about 158 s with 75% HP left, and also wins with low stock or without skills.
  - **Essential:** one Prestige, all three supplies at ^25 or more, and Auto Supply ×3.
  - **Optional:** skills, outfit merges above ^0, higher supply mastery.
  - **Best extra safety:** a second Prestige for the full card set (≈120 s, 98% HP left).
- **MIN versus REC:** MIN wins only because sustain *just* holds, and any slip loses: less stock, a missing supply, five fewer levels, a weaker sword. REC deals 17% more damage and has 29% more HP. Its kill comes about 100 s sooner, so it needs about half the supplies and survives low stock or no skills.
- **Without Prestige** it is beatable only after a very long grind (NOP, §2.6).

## 4. Recommendations, not implemented (developer approval required)

1. **Soften the sustain cliff** so preparation reads as a slope. Today a single missing supply type or 5 levels of mastery decides the fight. Options to evaluate, one at a time, with this same ladder before choosing:
   - (a) lower helper damage (`green_alien.damage_scale` 0.35 → 0.25);
   - (b) lower the boss's basic damage by about 10–15% (345.8 → ≈300);
   - (c) raise `final_action_gap` from 11 s to 13 s, which reduces skill pressure.

   **None of these was simulated in this change**; each must be measured against MIN-w50, MIN-s20 and REC-none before adoption.
2. **Say that Prestige is expected.** Help or the Farming Guide could state that the final boss assumes Prestige cards (especially Lifesteal and Boss Damage). A no-Prestige player faces a 30+ hour grind with no signal.
3. **Card choice risk (untested):** builds that skip Challenge Lifesteal were not simulated; it carries much of the sustain. Worth one ladder pass before any device verdict.
4. **Sunflower farm loop:** the MIN farmer dies 21 times per hour looping Sunflower, although it wins the isolated duel. This is out of scope (not the final boss); device check suggested.
5. **Historical `change_9_balance` is superseded** for the final boss. It seeds fake key ids and no supplies, Prestige transaction or upgrades, so its final-boss losses do not describe current play. It was not changed.

## 5. Tests

- Targeted: `change_36_probe` 180/0. The related supply group passed (`change_17_probe` 659/0, `change_11_probe` 153/0, `change_13_probe` 154/0, `change_16_probe` 198/0, `change_5_probe` 161/0, `change_20_probe` 84/0).
- Audit: final-boss ladder 280/0 and farm 14/0, no script errors (non-gating; not in `run_probes.py`).
- Full maintained suite, run once: **38/39, no script errors or timeouts.** The only failure is `change_35_probe` "Only English is shipped and selectable". That check requires `localization/` to contain exactly one file, and the developer's untracked `LootFarmer_Runtime_19_Languages_Partial_Drafts.zip` was placed there during this change. The zip is outside this change and was not moved or committed.

## 6. Files

- `data/game/catalog.json`: the one balance value.
- `localization/en.po`: two English strings.
- `scripts/game/simulation.gd`, `scripts/game/game_ui.gd`: comments only.
- `tests/change_36_probe.*`, `tests/change_36_final_boss_audit.*`: new.
- `tests/change_5/11/13/16/17_probe.gd`: fixtures.
- `tools/run_probes.py`: registers change_36_probe.
- `docs/Change_36_Evidence/`: builds, CSVs, logs.
- Docs: State Contracts, GDD, Content and Balance, Test Suite, this report.
