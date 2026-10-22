# LootFarmer — Upgrade Catalog — Change 6 (retention updated in Change 11)

**Change 11 retention rule:** Prestige keeps **every upgrade bought with Gems**, whatever its category (player, enemy type, automation, inventory, map/camp, spawn, offline, missions). Coin upgrades keep their own Keep/Reset column below. Every upgrade has exactly one currency, so no level is ever split between currencies. The rule is enforced in code from the currency (`simulation.upgrade_kept`) and mirrored by `keep: true` on every gem row in catalog.json (`tools/change11_catalog.py`, checked by `tools/validate_campaign_source.py`). Hard Reset clears every upgrade. Before Change 11, Gem Chance, Gem Amount, Boss Gem Chance, Boss Gem Amount, Spawn Amount and Spawn Cooldown were gem-funded yet reset; kept Spawn levels now re-spawn the extra actors immediately after the reset.

**Change 11 supplies:** supply capacity is 1 initial slot + 4 purchases = 5, one per supply type (Health Potion, Coin Tonic, Guard Tonic, Recovery Salve, Wisdom Tonic). Supply auto-merge (`merge_supplies`, `merge_speed`) is removed: supplies grow permanent mastery from every copy found.

Change 6: prices and caps unchanged. Player-facing labels now state the implemented effect: loot +1 point, collect range +50, collect/merge intervals −1 s, coins per enemy +50%, experience +10%, supply chance +1 point, movement +10%. Enemy upgrades show reward upgrades first and automation refinements only after their automation is unlocked.

The user approved implementation, removal of selling and the automerge correction to **10 → 1 seconds**. No merge-rate purchase remains provisional. Prices are tunable authored values; exact runtime ids below are the identifiers used by code and saves.

Next price = ceil(base × growth^rank × owner multiplier), unless the table supplies a price list. Type coin multiplier = 2^(stage−1), type gem multiplier = 1 + 0.25×(stage−1); stage/camp coin upgrades use their stage multiplier. Global tracks use 1. Coin discounts apply before ceil. Storage special prices: gear 10 + 5×floor(rank/10), supplies 8 + 4×rank.

| Runtime id | Scope | Currency | Ranks | Keep at prestige | Base / growth or list |
|---|---|---|---:|---|---|
| gear_slots | global | gems | 67 (70 slots, Change 10) | Keep | 5 + level |
| supply_slots | global | gems | 4 (5 slots, Change 11) | Keep | 4 + 4 × level |
| collect | type | coins | 1 | Keep | 20 / 1 |
| collect_range | type | coins | 4 | Keep | 30 / 1.5 |
| collect_batch | type | coins | 5 | Keep | 30 / 1.5 |
| collect_speed | type | coins | 5 | Keep | 30 / 1.5 |
| merge_gear | type | gems | 1 | Keep | 30 / 1 |
| auto_use | global | gems | 3 | Keep | 10 / 2.4 |
| use_speed | global | coins | 8 | Keep | 40 / 1.6 |
| focus | type | gems | 1 | Keep | 25 / 1 |
| respawn | global | coins | 7 | Reset | 30 / 1.7 |
| loot | type | coins | 15 | Reset | 20 / 1.35 |
| gem_chance | global | gems | 12 | Keep (Change 11) | [50, 75, 105, 140, 180, 220, 265, 320, 400, 500, 600, 700] |
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
| skill_slots | global | gems | 2 | Keep | [100, 300] |
| skill_auto_0 | global | gems | 1 | Keep | 75 / 1 |
| skill_auto_1 | global | gems | 1 | Keep | 150 / 1 |
| skill_auto_2 | global | gems | 1 | Keep | 300 / 1 |
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
- Global gem chance 8→20%, boss extra up to +40pp with final 60% boss cap. Normal amount 1→6, boss extra up to +10. Achievements/cards obey probability caps.
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
| auto_use | 6 × 2.6^n gems (merge_supplies and merge_speed removed in Change 11) |
| gem_chance, gem_amount, boss_gem_amount | [25, 40, 58, 80, 105, 135, 170, 210, 260, 320, (390, 470)] gems |
| boss_gem_chance | [50, 80, 120, 170, 230, 310, 410, 530] gems |
| skill_slots / skill_auto_0,1,2 | [50, 160] / 38, 75, 150 gems |
| mission_slots / mission_claim | [25, 50, 90, 140, 200] / 75 gems |
| offline_cap / offline_gems / offline_weapon, outfit, consumable | [25, 50, 90, 140, 215, 330] / 20 × 1.25^n / 50, 50, 38 gems |
| offline_coins | 100 × 1.3^n coins |
| loot | +0.5 points per level, 15 levels (5% → 12.5% per carried item; bosses 30% → 37.5%); 20 × 1.35^n × 2^(stage−1) coins |
| collect_batch | premium: 120 × 3^n × 2^(stage−1) coins (effect unchanged, batch 1 → 6) |
| map_detail | sequence: max(60 × 1.3^k, 40 × 2^(stage−1)) coins |

Skill cooldown upgrades for a skill appear only after that skill was obtained once (`skills_seen`); skill slot and auto-cast upgrades need any skill. Hidden upgrades also refuse purchases (`UNDISCOVERED`).

**Change 10:** Gear capacity caps at 67 purchases (70 equipment slots); loading clamps the level to the cap and the equipment row to 3 + purchases (surplus empty slots go first; items that still do not fit are dropped with their record). Boss Gem payout per successful roll = (3 × (1 + 0.5 × Gem Amount) + Boss Gem Amount) × (1 + boss Gem card). The Farming Guide opens a map's entry at Map Details 3/3 with Reveal Stats and Reveal Drops on every type of that map.
