# LootFarmer — Upgrade Catalog — Change 3

Behavior/currency/persistence approved in review unless explicitly marked. New prices, unset caps and exact increments below are delegated tuning v1, NOT measured balance. `pp` means percentage points. `Keep` preserves purchases, not inventory. Entries describing separate scopes instantiate independently per owner id. Prerequisites: accessible owner/type discovered, preceding rank, affordable price; automation requires its unlock. A rank with no effective benefit must not be sold.

For `first; growth`, next cost = ceil(first × growth^purchased_rank × scope_multiplier). Stage/ordinary-type coin multiplier = 2^(stage−1); type gem multiplier = 1 + 0.25×(stage−1). Global/player/offline/mission tracks use 1. Explicit boss-global gem tables also use 1. Stage arrays use the stage coin multiplier; per-type arrays use their currency multiplier. One-time amounts use the same scope rule. These replace prototype 1/2/3/4 type indexing for the final roster.

| ID | Owner | Currency | Effect / cap | Prestige | Initial price schedule |
|---|---|---|---|---|---|
| player_speed | Player | Coins | 10 × +10%; max +100% | Reset | 40; 1.65 |
| respawn | Player | Coins | 7 × −1s; 10s → 3s | Reset | 30; 1.70 |
| inventory | Shared inventory | Gems | +1 identity slot; max all gear/outfit/skill tier ids | Keep | 10 + 5×floor(purchased_rank/10) gems |
| consumable_capacity | Consumables | Gems | +1 identity slot; max all consumable tier ids | Keep | 8 + 4×purchased_rank gems |
| skill_slots | Player | Gems | 1 → 3 equipped skills | Keep | [100, 300] |
| skill_auto | Each skill slot | Gems | One unlock + toggle per slot | Keep | [75, 150, 300] by slot |
| skill_cooldown | Each skill family | Coins | 6 × −5% original cooldown; max −30%; 2s floor | Reset | 100; 1.65 |
| consumable_auto | Each consumable slot | Gems | One unlock per slot | Keep | [10, 25, 50] by slot |
| consumable_auto_interval | Player | Coins | 8 × −1s check interval; 10 → 2s | Keep | 40; 1.60 |
| consumable_merge | Player | Gems | Unlock; 5s per merge initially | Keep | 20 once |
| consumable_merge_rate | Player | Gems | 4 × −1s; minimum 1s | Keep | 25; 1.70 |
| equipment_drop | Enemy type | Coins | 6 × +2pp then +3pp; max +15pp | Reset | 20; 1.35 |
| consumable_drop | Enemy type | Coins | 6 × +2pp then +3pp; max +15pp | Reset | 20; 1.35 |
| skill_drop | Skill-bearing enemy type | Coins | 6 × +2pp then +3pp; max +15pp | Reset | 35; 1.40 |
| coin_amount | Enemy type | Coins | 20 × +0.5 × authored base coin amount | Reset | 30; 1.40 |
| coin_chance | Eligible enemy type | Coins | +5pp to 100%; omit if already 100% | Reset | 25; 1.40 |
| xp | Enemy type | Coins | 20 × +10% base XP; max +200% | Reset | 30; 1.40 |
| spawn_count | Normal type, each spot | Gems | 3 → 6 actors, +1 per rank | Reset | [150, 250, 400] |
| spawn_cooldown | Normal type | Gems | 5 × −10% original; max −50% | Reset | [100, 175, 275, 400, 550] |
| farming | Enemy type | Gems | Unlock focus/return; selectable variant | Keep | 25 once |
| gear_skill_merge | Enemy type | Gems | Unlock; applies to source families and evolutions | Keep | 30 once |
| gear_skill_merge_rate | Enemy type | Gems | 4 × −1s; 5 → 1s per duplicate | Keep | 30; 1.70 (persistence/rate purchase is provisional; see note) |
| collect | Enemy type incl. boss | Coins | Unlock; 100-unit radius, batch 1, 10s | Keep | 20 once |
| collect_range | Enemy type | Coins | 4 × +50 units; max 300 | Keep | 30; 1.50 |
| collect_batch | Enemy type | Coins | 5 × +1; max 6 per check | Keep | 30; 1.50 |
| collect_interval | Enemy type | Coins | 5 × −1s; 10 → 5s | Keep | 30; 1.50 |
| reveal_stats | Enemy type | Coins | One unlock | Keep | 25 once |
| reveal_drops | Enemy type | Coins | One unlock | Keep | 35 once |
| gem_chance | Global | Gems | 8% + 12 × 1pp; hard total cap 20% normal | Reset | [50,75,105,140,180,220,265,320,400,500,600,700] |
| gem_amount | Global | Gems | 1 + 10 × 0.5 = 6 | Reset | [50,75,105,140,180,220,265,320,400,500] |
| boss_gem_chance | All bosses together | Gems | 8 × +5pp; combined hard cap 60% | Reset | [100,150,225,325,450,600,800,1000] |
| boss_gem_amount | All bosses together | Gems | 10 × +1; combined upgrade maximum 16 | Reset | [50,75,105,140,180,220,265,320,400,500] |
| map_detail | Stage | Coins | 3 sequential detail levels | Reset | [40,100,200] |
| camp | Each additional camp | Coins | Unlock travel/respawn/reveal | Reset | [50,150] by camp order |
| player_reveal | Stage | Coins | 4 × +25% base radius; max +100% | Reset | 30; 1.60 |
| camp_reveal | Each camp | Coins | 4 × +25% base radius; max +100% | Reset | 25; 1.60 |
| mission_slots | Player | Gems | 3 → 8; +1 per purchase | Keep | [50,100,175,275,400] |
| mission_claim | Regular missions | Gems | Auto-claim unlock + toggle | Keep | 150 once |
| offline_cap | Player | Gems | Hours: 5,8,12,18,24,36,48 | Keep | [50,100,175,275,425,650] |
| offline_coins | Player | Coins | 20 × +60 coins/h; base 120/h | Keep | 100; 1.50 |
| offline_gems | Player | Gems | 20 × +0.5 gems/h; base 2/h | Keep | 40; 1.45 |
| offline_weapon | Player | Gems | Enable owned-weapon drops, base 1/h | Keep | 100 once |
| offline_outfit | Player | Gems | Enable owned-outfit drops, base 1/h | Keep | 100 once |
| offline_consumable | Player | Gems | Enable owned-consumable drops, base 2/h | Keep | 75 once |
| offline_weapon_rate | Player | Coins | 10 × +0.5/h; max 6/h | Keep | 100; 1.50 |
| offline_outfit_rate | Player | Coins | 10 × +0.5/h; max 6/h | Keep | 100; 1.50 |
| offline_consumable_rate | Player | Coins | 10 × +1/h; max 12/h | Keep | 75; 1.50 |

## Boundaries and unresolved approval

Manual selling, auto-sell unlocks, auto-sell lists and sell-value tuning are removed. Offline items also cannot auto-sell. Reroll remains an item service, not a levelled upgrade: starting tuning 3×2^(tier−1) gems, changes only the random bonus. Potions and temporary boosts remain consumable purchases, not permanent stat purchases; base potion 10 coins, coin tonic 30 coins.

The gear/skill auto-merge frequency purchase was proposed with auto-sell, then the user replaced selling and discussed stock bonuses without explicitly approving that frequency purchase. Retain the already approved auto-merge unlock and baseline cycle; treat this rate row as provisional until confirmed. Do not silently ship it as approved. Consumable frequency improvements were explicitly approved.

Consumable equipped slot count remains the prototype three-slot baseline; the capacity purchase above is storage, not automatic use slots. Shared capacity starts at the actual prototype value during migration; new-profile starting tuning is four shared identities and two consumable identities. Final maxima are computed from the full authored catalog, never hardcoded to preview counts. With this draft's 34 weapon + 48 outfit + 6 skill families and 7 tiers, shared maximum is 616; two consumable families ×7 tiers gives 14. This family count is an authoring proposal, subject to equipment art mapping, not an approved expansion of enemy types.

All new prices and finite caps require affordability/progression tests. Persisted upgrades never silently grant access to a locked stage. Existing per-type ownership needs stable-id migration, not multiplying old purchases across 48 unrelated identities.
