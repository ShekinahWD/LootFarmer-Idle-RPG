# LootFarmer — Upgrade Catalog — Change 65

## Change 65 — Focused Farming is one global Player upgrade (11 November 2026)

| Id | Scope | Currency | Cap | Prestige | Price |
|---|---|---|---:|---|---|
| focus | **global** (was type) | gems | 1 | Keep (Hard Reset clears) | **25 once** |

- Listed in **Player Upgrades → Player** (after Movement); benefit "Farm any discovered enemy spot, on every map."; owned reads "Owned: tap Farm on any discovered enemy." and MAX. A per-enemy purchase call is refused and charges nothing; any caller naming an enemy type reads the one global rank (`sim._upgrade_key` ignores the group for global upgrades).
- The enemy panel keeps Farm / Stop; it lists no Focused Farming purchase. Locked Farm says why and offers **Open Player Upgrades**.
- **Unchanged and still per enemy type:** `collect`, `collect_range`, `collect_batch`, `collect_speed`, `merge_gear`, `gear_merge_speed`, `auto_evolve`, and every reward/research/spawn upgrade, at the prices below.
- **Save migration (schema 9, on load):** any legacy `focus:<type>` record with level ≥ 1 → global `focus` = 1; none → 0; global already present → stays 1; the legacy records are deleted (repeat loads change nothing). No Gem refund or compensation (the number of legacy records found is reported by `campaign.legacy_focus_records` for the developer's decision). `tools/validate_campaign_source.py` checks the definition.


> **Correction (production audit, 2026-10-28):** the Guided wait values below are superseded. Since the Change 22 notes (commit "Change 23") Missions unlock **15 active real seconds** after the first merge and Player Upgrades 15 seconds after closing Missions (`tutorial.flow.wait_seconds`; GDD "Current status"). Auto Claim (`mission_claim`) stays OFF after purchase until the player enables it. Prices in this catalog are unchanged.

## Change 21 — corrections (27 October 2026)

Built on the exact delivered Change 20 project; application/Android version is 21 and save schema remains 8. See [Change 21 report](LootFarmer_Change_21_Report.md) for the complete correction checklist and validation.

- Guided Missions unlock 60 active gameplay seconds after the first merge. Inventory expansion now explicitly points to Close before teaching potions. Already advanced saves do not repeat the new close step.
- Auto-merge item controls appear only with the applicable purchased upgrade, and remain available when excluded.
- Supplies support six total slots (one initial plus five purchases). Small shows 3 columns × 2 rows, Medium 2 × 2 visible, Large one visible; the viewport stays fixed. Gear and Supply headings and slot rows align.
- Missions, Mastery, Filters, Prestige and Upgrades show visible scrollbars on overflow. Claim has a compact, centered height.
- Mission/Prestige followers stack just above the joystick. The farming objective is larger and padded; boss countdowns show only seconds.
- Prestige opportunities are grouped by relevant unlocked maps with discovered/total counters, followed by General, Owned Cards and Card Sets. Objectives spanning multiple maps appear in each relevant section. General contains offline, merging, arsenal, offering and mission objectives.
- Expanded map camps are visible without Map Details and support release-to-travel with larger icons/hit areas. Camp-list buttons remain. Combat restrictions still apply.


## Change 20 — previous delivery (27 October 2026)

The full 22-section **Remaining Features, UI & Tutorial** brief is implemented, including interfaces. It supersedes the earlier gameplay-only scope and handoff to Claude. Application/Android version is 20; save schema remains 8. See [Change 20 implementation and acceptance report](LootFarmer_Change_20_Report.md) and [current test suite](LootFarmer_Test_Suite.md). Earlier numbered change descriptions are historical evidence, not conflicting current instructions.

Guided onboarding follows saved action outcomes and 60/60-second active-play delays, teaches physical camp purchase, boss preparation, inventory expansion and potion use, and ends in Winter II after a five-second visible-message delay and acknowledgement. Only Guided mode has the tutorial Prestige gate. Slots have saved Small/Medium/Large controls in Filters and Settings. Item details expose Auto-merge On/Off. Prestige keeps player level and XP, but resets Supply Mastery and partial use progress. World stage selection travels directly for one unlocked camp or shows a visual camp map for multiple camps. Map markers, trackers, mission layout and boss discovery/countdown presentation are integrated. All offensive skills (including Focus) require combat and an eligible target within the configurable 64-unit activation distance; Heal needs missing HP and works outside combat. Boss Gem previews include the existing base once.

**Change 16 map pricing and Gem collection:** every Coin price tied to an enemy type, a map or a camp scales by `progression.map_cost_growth`^(map−1) = **1.55** per map (was 2): all `type` / `normal_type` Coin upgrades, `reveal_radius`, `camp_radius`, the `map_detail` floor and camp unlocks (50 / 150 × 1.55^(map−1)). Each upgrade keeps its own base and level growth; `global` Coin upgrades and every Gem price are unchanged (`campaign.map_cost_factor`). The base Coin reward per kill grows 1.5 per map, so each map costs about 3% more relative to its income than the one before. **Auto-Collect** (`collect`) is now bought with **Gems**: 20 on Winter I. **Collect Batch** (`collect_batch`) is bought with **Gems**: 50 × 3^level on Winter I (50 / 150 / 450 / 1,350 / 4,050), limit 5 levels. Both use the Gem map factor 1 + 0.25 × (map − 1) and are kept by Prestige like every Gem upgrade; levels bought with Coins before Change 16 keep their level. Owned by `tools/change16_catalog.py`. The table rows below for `collect` and `collect_batch` are the Change 6 history.


**Change 11 retention rule:** Prestige keeps **every upgrade bought with Gems**, whatever its category (player, enemy type, automation, inventory, map/camp, spawn, offline, missions). Coin upgrades keep their own Keep/Reset column below. Every upgrade has exactly one currency, so no level is ever split between currencies. The rule is enforced in code from the currency (`simulation.upgrade_kept`) and mirrored by `keep: true` on every gem row in catalog.json (`tools/change11_catalog.py`, checked by `tools/validate_campaign_source.py`). Hard Reset clears every upgrade. Before Change 11, Gem Chance, Gem Amount, Boss Gem Chance, Boss Gem Amount, Spawn Amount and Spawn Cooldown were gem-funded yet reset; kept Spawn levels now re-spawn the extra actors immediately after the reset.

**Change 12:** Gem Chance has 20 levels of +0.5 points (+10 points in all; it was 12 × +1). Levels 1–12 keep their prices exactly; levels 13–20 cost 560, 660, 770, 890, 1,020, 1,160, 1,310 and 1,470 gems (each step 10 gems larger than the one before). Base gem chance is 5% (was 8%) and the 20% normal / 60% boss caps are gone: the chance is base + Gem Chance + Gem Wisdom + the type's kill achievements (+ Boss Gem Chance on bosses), clamped only to 0–100%. New **Merge All** (`merge_all`): global, gems, 1 rank, 5,000 gems, kept by Prestige; it adds a free Merge All button to Filters (Upgrades → Inventory).

**Change 11 supplies:** supply capacity is 1 initial slot + 4 purchases = 5, one per supply type (Health Potion, Coin Tonic, Guard Tonic, Recovery Salve, Wisdom Tonic). Supply auto-merge (`merge_supplies`, `merge_speed`) is removed: supplies grow permanent mastery from every copy found.

Change 6: prices and caps unchanged. Player-facing labels now state the implemented effect: loot +1 point, collect range +50, collect/merge intervals −1 s, coins per enemy +50%, experience +10%, supply chance +1 point, movement +10%. Enemy upgrades show reward upgrades first and automation refinements only after their automation is unlocked.

The user approved implementation, removal of selling and the automerge correction to **10 → 1 seconds**. No merge-rate purchase remains provisional. Prices are tunable authored values; exact runtime ids below are the identifiers used by code and saves.

Next price = ceil(base × growth^rank × owner multiplier), unless the table supplies a price list. Type coin multiplier = 1.55^(stage−1) since Change 16 (was 2^(stage−1)), type gem multiplier = 1 + 0.25×(stage−1); stage/camp coin upgrades use their stage multiplier. Global tracks use 1. Coin discounts apply before ceil. Storage special prices: gear 10 + 5×floor(rank/10), supplies 8 + 4×rank.

| Runtime id | Scope | Currency | Ranks | Keep at prestige | Base / growth or list |
|---|---|---|---:|---|---|
| gear_slots | global | gems | 67 (70 slots, Change 10) | Keep | 5 + level |
| supply_slots | global | gems | 5 (6 slots, Change 21) | Keep | 4 + 4 × level |
| collect | type | coins | 1 | Keep | 20 / 1 |
| collect_range | type | coins | 4 | Keep | 30 / 1.5 |
| collect_batch | type | coins | 5 | Keep | 30 / 1.5 |
| collect_speed | type | coins | 5 | Keep | 30 / 1.5 |
| merge_gear | type | gems | 1 | Keep | 30 / 1 (Change 13: covers the exact items the type drops) |
| auto_evolve | type | gems | 1 | Keep | 2,000 on every map (`flat`, Change 13) |
| auto_use | global | gems | 3 | Keep | 100 / 2.6 |
| use_speed | global | gems | 8 | Keep | 100 / 1.6; interval 10 → 2 s |
| focus | type → **global (Change 65)** | gems | 1 | Keep | 25 / 1 → **25 once (Change 65)** |
| respawn | global | coins | 7 | Reset | 30 / 1.7 |
| loot | type | coins | 15 | Reset | 20 / 1.35 |
| gem_chance | global | gems | 20 (Change 12; was 12) | Keep (Change 11) | [25, 40, 58, 80, 105, 135, 170, 210, 260, 320, 390, 470, 560, 660, 770, 890, 1020, 1160, 1310, 1470] (+0.5 points per level) |
| coin_amount | type | coins | 20 | Reset | 30 / 1.4 |
| gem_amount | global | gems | 10 | Keep (Change 11) | [50, 75, 105, 140, 180, 220, 265, 320, 400, 500] |
| reveal_stats | type | coins | 1 | Keep | 25 / 1 |
| reveal_drops | type | coins | 1 | Keep | 40 / 1 |
| supply_drop | type | coins | 15 | Reset | 20 / 1.35 |
| group_xp | type | coins | 20 | Reset | 25 / 1.4 |
| boss_gem_chance | global | gems | 8 | Keep (Change 11) | [100, 150, 225, 325, 450, 600, 800, 1000] |
| boss_gem_amount | global | gems | 10 | Keep (Change 11) | [50, 75, 105, 140, 180, 220, 265, 320, 400, 500] (+1 boss gem per level, added after the boss ×3; Change 10) |
| spawn_amount | normal_type | gems | 3 | Keep (Change 11) | [75, 125, 200] (Change 11; 400 total on Winter I, × 1 + 0.25 × (stage − 1)) |
| spawn_cooldown | normal_type | gems | 5 | Keep (Change 11) | [50, 100, 150, 225, 300] (Change 11; 825 total on Winter I, × 1 + 0.25 × (stage − 1)) |
| movement | global | coins | 10 | Reset | 40 / 1.65 |
| gear_merge_speed | type | gems | 9 | Keep | 30 / 1.7 |
| merge_all | global | gems | 1 | Keep (Change 12) | 5,000 / 1 (one-time unlock; using Merge All is free) |
| skill_slots | global | gems | 2 | Keep | [300, 600] (Change 13) |
| skill_auto_slots | global | gems | 3 | Keep | 100 / 250 / 500; freely assign equipped positions |
| critical_chance | global | gems | 20 | Keep | 250 / 1.5; +1 percentage point per level |
| critical_damage | global | gems | 20 | Keep | 200 / 1.5; +5 percentage points per level |
| cooldown_heal | global | coins | 6 | Reset | 100 / 1.65 |
| cooldown_frost | global | coins | 6 | Reset | 100 / 1.65 |
| cooldown_fire | global | coins | 6 | Reset | 100 / 1.65 |
| cooldown_lightning | global | coins | 6 | Reset | 100 / 1.65 |
| cooldown_focus | global | coins | 6 | Reset | 100 / 1.65 |
| cooldown_strike | global | coins | 6 | Reset | 100 / 1.65 |
| skill_drop | type | coins | 15 | Reset | 35 / 1.4 |
| map_detail | stage | coins | 3 | Reset | [40, 100, 200] |
| reveal_radius | stage | coins | 4 | Reset | 30 / 1.6 |
| camp_radius | camp | coins | 4 | Reset | 25 / 1.6 |
| mission_slots | global | gems | 5 | Keep | [50, 100, 175, 275, 400] |
| mission_claim | global | gems | 1 | Keep | 150 / 1 |
| offline_cap | global | gems | 6 | Keep | [50, 100, 175, 275, 425, 650] |
| offline_coins | global | coins | 20 | Keep | 100 / 1.5 |
| offline_gems | global | gems | 20 | Keep | 40 / 1.45 |
| offline_weapon | global | gems | 1 | Keep | 100 / 1 |
| offline_weapon_rate | global | coins | 10 | Keep | 100 / 1.5 |
| offline_outfit | global | gems | 1 | Keep | 100 / 1 |
| offline_outfit_rate | global | coins | 10 | Keep | 100 / 1.5 |
| offline_consumable | global | gems | 1 | Keep | 75 / 1 |
| offline_consumable_rate | global | coins | 10 | Keep | 75 / 1.5 |

## Effective behavior

- Movement: 10×10%, maximum +100%; respawn 10→3 seconds (combo floor 2).
- Shared storage starts at 3 identities, max 649 including legacy migration identities; supply storage starts at 1, max 14. Capacity covers every runtime item tier. Purchases survive prestige.
- Gear/skill and consumable automerge both start at 10 seconds and have nine −1-second ranks to 1 second. One spare copy per interval, deterministic fair rotation through eligible identities. At ^100, extra copies remain stock.
- Auto-use allows up to three chosen consumable storage-slot bindings; interval 10→2 seconds. Capability persists; consumable bindings reset at prestige. Skill-slot auto toggles persist, with no equipped skill until reconfigured.
- Skill equip slots 1→3; independent per-slot automatic casting unlocks, family cooldown reduction six×5% to −30%, floor 2 seconds.
- Gear, supply and skill drop tracks use 15×1 percentage point. Normals start at 5% skill chance, bosses 10%, maximum 20%/25%. One boss skill roll then uniform choice.
- Normal spawn count 3→6 per variant spot; cooldown five×−10% to half. Bosses have no spawn-count/cooldown purchases.
- Collection radius 100→300, batch 1→6, interval 10→5 seconds. Coin amount +50% base per rank; XP +10% base per rank.
- Global gem chance 5% base + 20 × 0.5 points (Change 12; was 8→20%), Boss Gem Chance +5 points × 8 on bosses, Gem Wisdom +5 points, kill achievements up to +4 points per type. No game-specific cap (the old 20% / 60% caps are removed); only 0–100% clamping. Fully stacked: 24% normal, 64% boss. Normal amount 1→6, boss extra up to +10.
- Map detail three ranks: generic sites, identities, farming details. Player reveal 144→288 per stage, camp reveal 192→384 per camp before cards. No rank reveals undiscovered enemy identities.
- Missions 3→8 slots; automatic claim separate unlock and toggle.
- Offline reward cap hours [5,8,12,18,24,36,48]; coins 120+60/rank per hour, gems 2+0.5/rank. Owned-only category unlocks; weapons/outfits 1+0.5/rank per hour, consumables 2+1/rank. Skills excluded.

Upgrade scope and prerequisites are checked in the simulation. Hidden/locked enemy types cannot be purchased remotely; automation rate/range purchases require the unlock. Rerolls retain stock/merge and change only random extras, priced at 3×2^(tier−1) before card discount. Skills with no random pool have no reroll action. Selling has no UI, service, price or automation. Older development saves reset under schema 7; no selling-refund migration is retained.

Change 5: Heal cooldown starts at 18 seconds; six 5% reductions reach 12.6 seconds. Heal remains capped at 12% maximum HP per cast.

## Change 8 prices and rules

Prices are data: `prices` list, `step` (linear: base + step × level), `sequence` (Map Details: base × growth^k, where k is the number of Map Details purchased this run on any stage, with a floor of `floor` × 2^(stage−1)), otherwise base × growth^level. The Gem first prices of Player Upgrades are roughly halved. Full table and arithmetic: docs/LootFarmer_Change_8_Notes.md.

| Runtime id | Change 8 schedule |
|---|---|
| gear_slots | 5 + level gems (each slot costs 1 more than the previous one) |
| supply_slots | 4 + 4 × level gems |
| auto_use | 100 × 2.6^n gems (merge_supplies and merge_speed removed in Change 11) |
| gem_chance, gem_amount, boss_gem_amount | [25, 40, 58, 80, 105, 135, 170, 210, 260, 320, (390, 470)] gems; Change 12 extends Gem Chance with 560 … 1,470 for levels 13–20 |
| boss_gem_chance | [50, 80, 120, 170, 230, 310, 410, 530] gems |
| skill_slots / skill_auto_0,1,2 | [300, 600] / 100, 250, 500 gems (Change 13; Change 8 had [50, 160] / 38, 75, 150) |
| mission_slots / mission_claim | [25, 50, 90, 140, 200] / 75 gems |
| offline_cap / offline_gems / offline_weapon, outfit, consumable | [25, 50, 90, 140, 215, 330] / 20 × 1.25^n / 50, 50, 38 gems |
| offline_coins | 100 × 1.3^n coins |
| loot | +0.5 points per level, 15 levels (5% → 12.5% per carried item; bosses 30% → 37.5%); 20 × 1.35^n × 2^(stage−1) coins |
| collect_batch | premium: 120 × 3^n × 2^(stage−1) coins (effect unchanged, batch 1 → 6) |
| map_detail | sequence: max(60 × 1.3^k, 40 × 2^(stage−1)) coins |

Skill cooldown upgrades for a skill appear only after that skill was obtained once (`skills_seen`); skill slot and auto-cast upgrades need any skill. Hidden upgrades also refuse purchases (`UNDISCOVERED`).

**Change 10:** Gear capacity caps at 67 purchases (70 equipment slots); loading clamps the level to the cap and the equipment row to 3 + purchases (surplus empty slots go first; items that still do not fit are dropped with their record). Boss Gem payout per successful roll = (3 × (1 + 0.5 × Gem Amount) + Boss Gem Amount) × (1 + boss Gem card). The Farming Guide opens a map's entry at Map Details 3/3 with Reveal Stats and Reveal Drops on every type of that map.

**Change 13:** Auto Evolution (`auto_evolve`) is a one-time 2,000-gem unlock per enemy type, the same price on every map (catalog `flat` skips the stage factor). It evolves, once a second, the weapons that type actually drops, under the manual rule; the successor tier needs a type that drops it. Auto-Merge (`merge_gear`) now covers the exact items the type drops (loot weapon and outfit, base skill items), not evolved or legacy tiers. Skill prices: automatic casting 100 / 250 / 500 gems, second and third skill slots 300 / 600 gems. Both are kept by Prestige and cleared by Hard Reset. Upgrade buttons show prices with the shared currency format, rounded up (1.47K, 2K).
