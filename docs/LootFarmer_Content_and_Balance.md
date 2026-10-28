# LootFarmer — Content and Balance v1 — Change 17

> **Balance status (production audit, 2026-10-28):** the developer has playtested Android builds throughout development and reports that **Stages 1–5 feel well balanced**; they are accepted and must not be redesigned. **Stages 6–8, the final boss and late Prestige pacing are still awaiting acceptance play.** The last recorded late-game benchmark (`change_9_balance`, Change 17) was 33/35 and was not re-run in the audit. Later economy values (Change 16 per-map 1.5 / 1.55) remain in force.

## Change 17 — current gameplay authority (27 October 2026)

Change 17 supersedes earlier descriptions of skill power/cooldowns, supply mastery/healing, automatic skill slots and mission rewards. It adds persistent boss countdown APIs and permanent critical upgrades, reuses the supply interval/shop systems, and optimizes rain calculations without changing authored appearance. Schema 8 saves remain compatible; existing mastery and automation purchases migrate. No UI/tutorial implementation is included.

Read [Change 17 behavior and decisions](LootFarmer_Change_17_Notes.md), [Claude integration API](LootFarmer_Change_17_Claude_Integration.md) and [validation and unresolved balance](LootFarmer_Change_17_Validation.md). The later numbered sections below are historical change records; Change 17 takes precedence where their rules differ.

All exact assignments and newly authored values in this document are delegated starting tuning, NOT approved playtest results. Approved mechanics in GDD remain binding. The Change 4 runtime catalog and eight scene files now implement these assignments. Enemy_Roster.csv assigns all 48 existing sheets exactly once using stable descriptive ids and original paths/hashes.

## Stage layouts and characters

| Stage | Name | Normal types | Bosses | Weather | Advance / completion | New skills |
|---|---|---|---|---|---|---|
| 1 | Winter I | 3 | 1 | Clear | snowman | None |
| 2 | Winter II | 6 | 1 | Blue falling leaves | cyan-robot | Heal (late stage) |
| 3 | Summer I | 3 | 1 | Clear | gray-cat | Frost Burst; Fire Burst; Lightning Strike |
| 4 | Summer II | 6 | 2 | Rain | Dinosaur (`boss-elephant`), teal-dinosaur | Arcane Focus; Arcane Strike |
| 5 | Autumn I | 3 | 2 | Clear | red-fox | Existing combinations |
| 6 | Autumn II | 4 | 2 | Falling leaves | black-cat, grim-reaper | Existing combinations |
| 7 | Spring I | 3 | 2 | Clear | bee, orange-tabby-cat | Existing combinations |
| 8 | Spring II | 6 | 3 | Rain | All six normal types + three bosses | Existing combinations |

Map footprint equivalents (24 world units per design tile): 40×40, 64×64, 48×48, 72×72, 52×52, 64×64, 56×56, 88×88. Implemented footprints are 960, 1536, 1152, 1728, 1248, 1536, 1344 and 2112 world units square. Actual TileMapLayers use the supplied 16-unit tiles. Each has one free arrival camp; Stage 1 one extra camp, other stages two. Use loops, visible landmarks and distinct farming clearings rather than long empty corridors. Leave safe room for six actors per variant spot and readable skill cues. Load/simulate the active stage; freeze inactive combat/respawn timers as a performance default, preserving gate flags and world state. Travel does not grant offline income.

Implemented final boss appearance: green alien, with Arcane Focus, Fire Burst and Arcane Strike. It is stronger through authored stats, arena/telegraphs and combat, not by silently treating a normal costume as a new roster entry. All 13 other boss ids correspond to persistent key ids. Stages 4, 6 and 7 use both listed bosses; Stage 5's squirrel remains optional for travel but required for the final key mission.

Normal spawn baseline: 3 actors per variant spot, upgradable to 6. Cooldown = 5 + 2×(stage−1) seconds, reducible to half. Boss: one per spot, 60-second respawn (final boss 120 seconds), no spawn upgrades. Fourth variants exist only where the roster has a skill; they carry that one skill, weapon and outfit. Later stages combine skill-bearing types in encounters, not unexplained additional skill families.

## Enemy and reward tuning

Let L be fixed roster level. Opening exception: the first normal type uses 18 HP, 2 damage and a 2-second interval. Other normal both-variant HP = 25×1.022^(L−1), damage = 2×1.014^(L−1), attack interval 1.5 seconds. Outfit-only multiplies HP by 1.25 and damage by 0.75; weapon-only HP by 0.75 and damage by 1.25. Fourth variant multiplies both HP and damage by 1.35 and casts its skill. Ordinary boss HP ×6 and damage ×1.6 relative to the normal formula at its level, attack interval 2s. Final boss uses ×12 HP and ×2 damage. These are first-pass formulas requiring loadout/time-to-kill evaluation; the old exponential wall is replaced. A seeded all-gear ceiling probe verifies numerical feasibility; it does not certify natural campaign pacing.

Normal base coin reward = 1.5^(stage−1) since Change 16 (was 1.25^(stage−1)); boss ×8. Coin chance starts 100%, so no useless coin-chance purchase is shown. XP = ceil(3×1.035^(L−1)); boss ×10. Normal equipment chance = max(3%, 10%−(stage−1) percentage points), boss 30%; independently roll only carried weapon/outfit. Consumable base chance 5% normal, 15% boss; successful roll selects potion 80% or coin tonic 20%. Gear/consumable upgrades add at most 15pp. Normal skill 5%, boss 10%, each +15pp max. For boss skills one roll then uniform selection among used families. Keys are guaranteed separately, never consume loot-roll eligibility. Gem chance (Change 12): 5% base for normal and boss rolls, + Gem Chance (20 × 0.5 points), + Gem Wisdom (5 points), + the type's kill achievements (8 × 0.5 points), + Boss Gem Chance on bosses (8 × 5 points); no game cap, clamped to 0–100% (fully stacked 24% normal, 64% boss). Gem amounts are unchanged (boss 3× normal).

Player baseline progression stays level 1–1000, +5 HP and +0.5 damage per level until measured balancing changes it. XP-to-next starting draft = ceil(10×1.025^(level−1)); cap level without overflow. Target first ready prestige at 1–2 hours and daily tasks 15–60 minutes; adjust reward/HP/XP/price coefficients together based on play evidence, not by deleting failing probes.

## Current player skill table (Change 17)

| Skill | ^0 | ^100 | ^250 | ^500 | Base cooldown | Target |
|---|---:|---:|---:|---:|---:|---|
| Heal | 10.00% | 17.66% | 24.69% | 30.00% | 20 s | Self; missing HP |
| Frost Burst | 0.5000× | 1.0748× | 1.6016× | 2.0000× | 20 s | 96-unit caster area |
| Fire Burst | 0.7500× | 1.6123× | 2.4023× | 3.0000× | 20 s | 64-unit target area, 120 reach |
| Lightning Strike | 1.2500× | 2.6871× | 4.0039× | 5.0000× | 20 s | One enemy, 120 reach |
| Arcane Focus | 10.00% | 25.33% | 39.37% | 50.00% | 20 s | Self, combat only, 5 s |
| Arcane Strike | 2.0000× | 4.2993× | 6.4062× | 8.0000× | 20 s | One enemy, 80 reach |

Values are before Skill/Merge Wisdom and target bonuses. Heal is a fraction of maximum HP; Focus is additional damage. Legacy tier and surplus stock do not inflate player skills. Existing logarithmic merge progress is normalized to the ^500 endpoints. Merge Wisdom accelerates progress up to the endpoint. Heal's effective cap is 30% HP; Fire's effective cap is 3× damage including Focus/Skill/target bonuses. Family cooldown purchases still reduce 20 → 14 seconds.

Frost slows movement 25% for 3 seconds. Player Lightning slows attack rate 50% for 3 seconds, without changing movement. Boss timed statuses last half as long, including their own Focus. Enemy skill power remains separately authored; enemy Heal thresholds remain 80% (final boss 50%), and the Cyan Robot retains its 12-second override. Other skill base cooldowns use the shared 20-second catalog values.

## Item families and evolution mathematics

Implemented roster: one weapon family per normal type (34), one outfit per appearance including bosses (48), six skill families, potion and coin tonic. Bosses use a chosen existing weapon family, not 14 extra unreviewed weapon families. Seven tiers each. The 34 new weapon families reuse the existing Wood Sword icon/contact sheet and tier colors. This is intentional source-art reuse; no unverified weapon crops were invented. Legacy weapons retain their existing artwork. Items dropped by a type must match visible equipment; do not mint unseen loadout ids. Base-tier weapon attack contribution draft = 3×1.08^(stage−1); outfit HP = 8×1.08^(stage−1). Boss outfit HP doubles its stage base. Extra-stat roll behavior remains from the prototype; audit numerical caps before final content sign-off.

For intrinsic stat B at tier t, base merge increment d = 0.02×B for new families and all successor tiers (potion tier 1 override remains 0.4 HP). Existing weapon/outfit base families retain their previous merge increments; all are now explicit merge_gain fields. Coin tonic uses the newly specified 0.005 tier-1 increment. Intrinsic power P(t,m)=B(t)+m×d(t). Successor B(t+1)=0.85×P(t,100); d(t+1)=0.02×B(t+1). This is computed from catalog values, NOT a live buffed item. Existing authored weapon transitions must migrate to this same 85% contract. At typical tiers, successor exceeds predecessor by merge 9; potion's first transition differs because of its explicit override.

At m=100, surplus=max(quantity−1,0). Stock multiplier draft = 1 + 0.0005×surplus (0.05% of intrinsic ^100 power per spare copy). At m<100 stock multiplier=1. Multiplication applies only to intrinsic primary stats, not random extras/cooldown/range. External bonuses apply once afterward. No diminishing-return rule or designed copy cap is imposed. Numeric overflow must be handled safely with the project's large-number policy, not by wrapping or silently deleting stock. At quantity 101, source has 105% intrinsic power; evolution leaves quantity 1 and 100% intrinsic source power and adds the 85% successor. Never advertise the successor as 85% of buffed UI total. Show intrinsic, stock and external contributions separately in details.

Consumables: potion starts 25 HP, coin tonic +25% coin amount for 30s. Tonic merge increment now follows the common 2%-of-base rule, superseding prototype +0.1pp tuning. Potency scales through tier/stock; duration stays fixed, re-use refreshes duration. Consumption snapshots current potency before removing one copy. Skill casting never removes stock. Tier 7 has no evolve action, but stock power continues.

## Offline initial rates

Base 120 coins/h and 2 gems/h; upgrades and caps are in Upgrade Catalog. After unlock: weapon/outfit 1 item/h each, consumables 2/h. Eligible identity selection uniform within category, including already-owned evolved ids; no skills. Rates fixed at departure. Offline income prestige metric chosen for tuning: lifetime coins credited by offline settlements, threshold 10,000. No coin/gem conversion. 72h cumulative and 24h continuous use true credited absence interval including beyond reward cap. Persistent progress and once-only rewards follow State Contracts.

## Mission templates and main chain

Regular objectives are authored at assignment from current accessible content; unclaimed rewards are recomputed from the highest-ever unlocked stage and current bonuses (Change 17). Eligibility prevents impossible categories/locked bosses. Initial template set:

| Template | Goal | Reward |
|---|---|---|
| Hunt | 120 kills of an accessible normal type | 40 normal kills; no Gems |
| Collect gear | 12 online weapon/outfit drops | 40 normal kills + 3 base Gems |
| Merge | 20 manual/auto merges of owned items | 40 normal kills + 3 base Gems |
| Earn | 300×stage coins from online kills | 40 normal kills + 5 base Gems |
| Boss hunt | 5 kills of a previously defeated accessible boss | 80 normal kills + 5 base Gems |
| Skill practice | 40 successful casts of an equipped skill | 40 normal kills + 3 base Gems |

Coin equivalents use the mean normal-enemy payout at the highest-ever unlocked stage. Base Gems use stage multipliers 1/2/3/5/8/12/18/25; mission bonuses apply once.

For progression eligibility, assignment stage is highest unlocked stage with demonstrated kills. Final boss mission is never assigned before key eligibility. No repeat active template+target. Avoid collect/merge tasks if the player cannot accept the needed identity or has no mergeable below-cap items. Quantity estimates need 15–60-minute observed completion; revise templates between assignments only.

Main chain (coins / gems): first five kills (25/0), equip first item (30/0), merge once (40/2), discover and buy a camp (60/3), defeat Winter I gate and reach Winter II (100/5), acquire/equip Heal (80/5), unlock a map-detail rank (100/3), acquire Frost (120/5), reach Summer I (200/8), evolve an item (300/10), obtain four skill families (300/10), reach Autumn (500/15), obtain all six skill families (500/15), reach Spring (800/20), complete one prestige (200/10 permanent completion flag), final quest (2,000/50). Reward values are first-pass; no guaranteed skill grant is implied. Final quest discovers independently on boss approach even if earlier main objectives are unfinished. Its completion requires 13 keys and current-run final-stage six-type/three-boss kill checklist. Rewards once; no forced prestige.

## Balance acceptance

Before shipping: test lowest viable and overpowered loadouts, ^100→tier+1 comparison with both equipped/stored contributions, no-selling full inventories, long-term surplus scaling, all gem caps and permanent coin-rate affordability. Exercise all six skills together with dense normal spots and boss telegraphs. Simulate/test 33 opportunities for reachability, no mutually impossible requirements, and all 17 combos. These tables are a tunable baseline, not an assurance of completed balance.

## Change 4 balance evidence and limits

The unadjusted draft final boss would have 1,408,337,102 HP and 655,001 damage. Revised growth is HP 1.022 and damage 1.014 per fixed level, preserving boss multipliers and all roster levels. The final boss now has about 596,326 HP and 512 damage, above the other bosses. A seeded level-350, all-catalog-new-gear tier-7 ^100 ceiling gives approximately 12.8 seconds basic-attack time-to-kill and 762.7 seconds basic-attack survival. This is an intentionally overpowered ceiling, not a normal progression loadout or measured completion time. Skill encounters, lowest viable loadouts and 1–2-hour first-prestige pacing remain playtest work.

Regular mission generation includes all six families, prevents duplicate active kind+target assignments, snapshots rewards and waits for eligible content when purchased slots exceed available objectives. Eligibility uses the highest accessible stage with demonstrated kills; unfinished/unclaimed missions are never replaced at midnight.

## Change 5 healing roles and encounter pacing

Tier-1 Heal adds 0.12 HP per merge; potion adds 0.4 HP. Both successor chains use the existing 85% evolution rule. At tier 1 ^100 their intrinsic powers are 18 and 65 HP respectively; actual skill healing additionally caps at 12% max HP. The six cooldown purchases reduce Heal from 18 to 12.6 seconds. Potion uses the existing consumable cooldown independently of skill cooldown. Automated checks cover tiers 1–7 at ^0, ^50 and ^100: potion burst exceeds twice effective skill healing at every sampled point. This is a role-separation check, not a measured campaign balance result.

Winter I has no skills or group assistance. Winter II introduces individual proximity aggression, then Heal on its last normal type and boss. Summer I introduces nearby assistance and Frost, Fire and Lightning on successive normal types. Skill-bearing normal variants are the fourth variant only. No new skill family or asset was introduced.

## Change 6 balance decisions (proposals measured by bot, not human playtests)

**Why:** the Change 5 baseline let a level-2 player kill the Snowman at 1.0 simulated minute and unlock Summer II at 10.6 minutes (pacing bot, seed 1); enemy HP grew 1.022×/level and damage 1.014×/level while early player power grew about 5× from level 1 to 20, and bosses were ×6 HP / ×1.6 damage of a normal enemy. The arrival camp sat 261 units from the boss and 650 from the weakest type on Winter I, and the same inversion existed on every stage.

**Enemy formula (catalog.progression.balance, applied by tools/tune_campaign.py):** normal hp = 25 × 1.022^(L−1) × (1 + min(L,40)/20); damage = 2 × 1.014^(L−1) × (1 + min(L,40)/16). The ramp makes early types keep pace with early player growth and plateaus at L40, after which the old growth rates continue (late values ×3 HP / ×3.5 damage of Change 5). Bosses ×14.5 HP / ×1.55 damage (final boss the same multipliers at its higher level). Snowman override ×15.6 / ×2.56 because the first boss is met with about a 1.6× player-level advantage, unlike later bosses (≈1.05×). The first enemy keeps the approved 18 HP / 2 damage / 2 s. Ceiling check (level 350, all tier-7 ^100 gear): final boss 2.16M HP, 1,389 damage, 46 s basic-attack TTK, 281 s survival. **Change 9:** that loadout was unreachable and wore no outfit; the figure is withdrawn. Spring II now uses levels 195–225 (normals), 235/240 (bosses) and 250 (final), with Tier 5 drops (Diamond weapons, `_t5` outfits) and Emerald on bosses. The final boss has a dedicated HP factor of 18 (others 14.5): 304.5K HP, 345.8 damage. Realistic duels: docs/LootFarmer_Change_9_Notes.md and tests/change_9_balance.

**Recovery:** out-of-combat 1% max HP/s anywhere, 10%/s within 110 units of an owned camp (catalog.progression.rest). Before this change the only recovery outside potions/Heal was dying. Heal tier 1 10 HP (+0.2/merge, 85% evolution chain recomputed); potion cooldown 5 s (catalog.progression.potion_cooldown). Potion burst stays ≥2.17× Heal at every tier and merge level.

**Layout:** tools/layout_campaign_groups.py places types by level outward from arrival (target distances 300 → 82% of the farthest point), bosses last; variant spots ±100 units; acquisition 110 (was 140). Constraint: closest actors of different spots > acquisition + reach + 12; camps > acquisition + 52 from every actor. All eight stages pass; boss courts and their hand-authored landmark nodes were moved by tools/relocate_boss_arenas.gd without rebuilding the scenes.

**Measured pacing (simulated active play at 0.1 s steps, tests/pacing_bot.gd, seeds 1–3):**

| Policy | Snowman | Winter cleared = prestige gate | Deaths by gate |
|---|---|---|---|
| Ordinary (explores, farms the strongest type it beats comfortably, attempts bosses at 1.4× margin) | 23.2–29.2 min | 91.7, 112.8 min (2 of 3 seeds) | 34–48 |
| Rush (attempts bosses at 1.05× margin) | 14.7–22.2 min | 76.3 min (1 of 3) | 59–136 |
| Expert (XP per second, XP upgrades first, potion-backed attempts, knows the map) | 9.7–18.5 min | 144.7 min (1 of 3) | 5–13 |

The fastest measured first-run route to a possible prestige is 76.3 minutes (76.1 in an earlier bot version). Runs that never reached the gate failed on routing to the far-corner boss, not on combat (see Change 6 validation). A perfect human route was not measured; bot models are approximations (no manual dodging exists in combat, so the main human advantage is better upgrade and boss timing). Daily mission and later-stage pacing (Summer II onward) were not re-measured beyond the ceiling check.

## Change 11 supplies (supersedes the potion and Coin Tonic tier text above)

Five supplies, one identity each; the tier copies and supply evolution are retired (old tier ids fold into the base supply on load). Value = base + 1% of base per mastery level (^100 doubles it). Mastery = copies found − 1, capped at ^100, kept by Prestige, never lowered by use; purchases add stock only. Milestones ^25/^50/^100 multiply duration by 1.2/1.4/1.6 and the potion cooldown by 0.9/0.85/0.8.

| Supply | Stat | Base | Duration / cooldown | First stage | Roll weight | Shop |
|---|---|---|---|---|---|---|
| Health Potion | heal share of max HP | 20% | 12 s cooldown, 10 s floor (Change 13; was 5 s) | 1 | 8 | 10 coins |
| Coin Tonic | coin bonus | +25% | 30 s | 1 | 2 | 30 coins |
| Guard Tonic | Defense | +20 (−16.7% damage) | 20 s | 2 | 2.5 | no |
| Recovery Salve | max HP per second | 1.5% | 10 s | 3 | 2 | no |
| Wisdom Tonic | kill XP | +25% | 60 s | 4 | 1.5 | no |

The per-kill supply roll is unchanged (5% normal, 15% boss, + Supply Drop upgrades and the Supply Fortune card); a successful roll picks among the supplies its map allows, by weight. Winter I keeps the 80/20 Potion/Coin Tonic split; from Summer II on the shares are Potion 50%, Coin Tonic 12.5%, Guard 15.6%, Recovery 12.5%, Wisdom 9.4%. The potion now heals a share of max HP instead of a flat 25 HP, so it stays useful without tiers. Recovery heals 15% (^0) to 48% (^100, 16 s) of max HP over its duration but cannot be started above 90% HP. No damage supply was added: the Focus skill already owns that role. Untested on a device and not balance-simulated; tune weights and values in catalog.json through tools/change11_catalog.py.

## Change 13 combat tuning (see docs/LootFarmer_Change_13_Notes.md)

- **Skill cooldowns** (player and enemy casts alike): Lightning 8 s, Fire 10 s, Frost 10 s, Strike 10 s, Focus 15 s, Heal 18 s. The cooldown upgrade (−5% × 6, 2 s floor) is unchanged.
- **Health Potion:** 12 s base cooldown, mastery ×0.9 / ×0.85 / ×0.8 with a 10 s floor (12 → 10.8 → 10.2 → 10 s). Heal amount unchanged (20% → 40% of max HP).
- **Summoners** (`resources/game/enemy_abilities.tres`): Grim Reaper (Horned Hood helpers, 2 per call, max 2, 22 s, 50% HP / 40% damage), Sunflower (Sprout, 2, max 2, 24 s, 35% / 30%), Green Alien (Green Cap, 2, max 3, 20 s, 40% / 35%). Helpers give no rewards and are never saved.
- **Final boss:** an action every 11 s plus the 0.6 s telegraph. Below 50% HP it heals first when Heal is ready (4% of max HP, 18 s cooldown); otherwise it uses a random ready skill from Fire, Strike, Frost, Lightning, or Focus. HP, damage, drops and the 13-key gate are unchanged.
- **Measured (one deterministic fixture pass):** final boss ^300 + 4 cards now loses narrowly (boss at 3%; it was a 58 s win); ^400, ^500 and ^300 + 6 cards win. The cause is the slower player skills, not the summons. Untested on a device.

## Change 16 economy and combat (see docs/LootFarmer_Change_16_Notes.md)

- **Coin income:** normal base reward 1.5^(map−1): 1, 1.5, 2.25, 3.375, 5.06, 7.59, 11.39, 17.09 (bosses 8×). Owned by `tools/change16_catalog.py`.
- **Coin prices tied to a map:** ×1.55^(map−1) (enemy upgrades, map and camp upgrades, camp unlocks, the Map Details floor). The ratio "Loot Chance level 1 ÷ base income" goes 20.0, 20.7, 21.8, 22.2, 22.9, 23.6, 24.4, 25.2 (it was 20 → 537 at 2× prices and 1.25× income). Later maps therefore cost far fewer kills per upgrade than in Change 15; this is the requested rule, not separately playtested.
- **Health Potion:** heal share 0.10 + 0.001 per mastery level (10% at ^0, 20% at ^100); cooldown and floor unchanged. The shared supply rule (^100 doubles the base) still holds for all five supplies.
- **Cyan Robot Heal:** 12 s between casts (`resources/game/enemy_abilities.tres` `skill_cooldowns`); measured 12.8 s in the probe including the 0.6 s wind-up (18.8 s before). Every other caster keeps the catalog's 18 s.
- **Map Mastery rewards:** Autumn II +2 pts Gem Chance, Spring II +15% max HP (swapped in `resources/game/mastery_rules.tres`).

## Change 27 (2026-10-28): first Snowman weapon

The first lifetime Snowman defeat always drops its carried weapon (catalog `boss-snowman.weapon`, the Stone Axe; natural drop counts, no duplicate). Every probability, price and stat is unchanged; later Snowman defeats use the ordinary 30% boss gear chance (+ Loot Chance). No other balance change in this batch.
