# LootFarmer — Content and Balance v1 — Change 3

All exact assignments and newly authored values in this document are delegated starting tuning, NOT approved playtest results. Approved mechanics in GDD remain binding. No assets/code are installed by these tables. Enemy_Roster.csv assigns all 48 existing sheets exactly once using stable descriptive ids and original paths/hashes.

## Stage layouts and characters

| Stage | Name | Normal types | Bosses | Weather | Advance / completion | New skills |
|---|---|---|---|---|---|---|
| 1 | Winter I | 3 | 1 | Clear | snowman | Heal |
| 2 | Winter II | 6 | 1 | Blue falling leaves | cyan-robot | Frost Burst |
| 3 | Summer I | 3 | 1 | Clear | gray-cat | Fire Burst; Lightning Strike |
| 4 | Summer II | 6 | 2 | Rain | elephant, teal-dinosaur | Arcane Focus; Arcane Strike |
| 5 | Autumn I | 3 | 2 | Clear | red-fox | Existing combinations |
| 6 | Autumn II | 4 | 2 | Falling leaves | black-cat, grim-reaper | Existing combinations |
| 7 | Spring I | 3 | 2 | Clear | bee, orange-tabby-cat | Existing combinations |
| 8 | Spring II | 6 | 3 | Rain | All six normal types + three bosses | Existing combinations |

Map footprint targets (tiles, 24 world units per tile): 40×40, 64×64, 48×48, 72×72, 52×52, 64×64, 56×56, 88×88. These are authoring footprints, not shipped maps. Each has one free arrival camp; Stage 1 one extra camp, other stages two. Use loops, visible landmarks and distinct farming clearings rather than long empty corridors. Leave safe room for six actors per variant spot and readable skill cues. Load/simulate the active stage; freeze inactive combat/respawn timers as a performance default, preserving gate flags and world state. Travel does not grant offline income.

Proposed final boss appearance: green alien, with Arcane Focus, Fire Burst and Arcane Strike. It is stronger through authored stats, arena/telegraphs and combat, not by silently treating a normal costume as a new roster entry. All 13 other boss ids correspond to persistent key ids. Stages 4, 6 and 7 use both listed bosses; Stage 5's squirrel remains optional for travel but required for the final key mission.

Normal spawn baseline: 3 actors per variant spot, upgradable to 6. Cooldown = 5 + 2×(stage−1) seconds, reducible to half. Boss: one per spot, 60-second respawn (final boss 120 seconds), no spawn upgrades. Fourth variants exist only where the roster has a skill; they carry that one skill, weapon and outfit. Later stages combine skill-bearing types in encounters, not unexplained additional skill families.

## Enemy and reward tuning

Let L be fixed roster level. Normal both-variant HP = 25×1.045^(L−1), damage = 2×1.035^(L−1), attack interval 1.5 seconds. Outfit-only multiplies HP by 1.25 and damage by 0.75; weapon-only HP by 0.75 and damage by 1.25. Fourth variant multiplies both HP and damage by 1.35 and casts its skill. Ordinary boss HP ×6 and damage ×1.6 relative to the normal formula at its level, attack interval 2s. Final boss uses ×12 HP and ×2 damage. These are first-pass formulas requiring loadout/time-to-kill evaluation; the known prototype boss failure is not fixed by writing them.

Normal base coin reward = 1.25^(stage−1); boss ×8. Coin chance starts 100%, so no useless coin-chance purchase is shown. XP = ceil(3×1.035^(L−1)); boss ×10. Normal equipment chance = max(3%, 10%−(stage−1) percentage points), boss 30%; independently roll only carried weapon/outfit. Consumable base chance 5% normal, 15% boss; successful roll selects potion 80% or coin tonic 20%. Gear/consumable upgrades add at most 15pp. Normal skill 5%, boss 10%, each +15pp max. For boss skills one roll then uniform selection among used families. Keys are guaranteed separately, never consume loot-roll eligibility. Achievements/cards respect hard gem probability limits.

Player baseline progression stays level 1–1000, +5 HP and +0.5 damage per level until measured balancing changes it. XP-to-next starting draft = ceil(10×1.025^(level−1)); cap level without overflow. Target first ready prestige at 1–2 hours and daily tasks 15–60 minutes; adjust reward/HP/XP/price coefficients together based on play evidence, not by deleting failing probes.

## Skill starting table

| ID | Skill | First stage | Tier 1 effect at ^0 | Cooldown | Target / behavior | Asset mapping |
|---|---|---|---|---|---|---|
| heal | Heal | 1 | 10 HP | 12s | 0.08s cast; self; below 80% HP | heal / heal_01 |
| frost | Frost Burst | 2 | 1.2 × attack damage | 10s | 96-unit radius; slow 25% for 3s | ice_shatter / ice_shatter_01 |
| fire | Fire Burst | 3 | 1.6 × attack damage | 8s | 64-unit radius around target | fire_impact / fire_impact_01 |
| lightning | Lightning Strike | 3 | 1.4 × attack damage | 4s | Current target in 120-unit range | zap / zap_01 |
| focus | Arcane Focus | 4 | +15% attack damage | 15s | Self buff 5s, combat only | cast / cast_01 |
| strike | Arcane Strike | 4 | 2.8 × attack damage | 10s | Current target in 80-unit range | impact / impact_01 |

Damage skills scale their multiplier; Heal scales HP; Focus scales its additive buff magnitude. Merge scales primary strength only. Frost slow stays 25%, duration/range unchanged by merge; cooldown unchanged except family purchase. Buff/slow refresh, no unbounded stacking. Enemy heal restores at most 15% max HP per cast with same cooldown, below 80%; prevents the first healer becoming an accidental wall. Enemy Focus +15% base, attacks use enemy damage. Telegraph boss area attacks 0.6s before contact with supplied VFX, verify player dodge windows and supplied art in context.

## Item families and evolution mathematics

Authoring plan: one weapon family per normal type (34), one outfit per appearance including bosses (48), six skill families, potion and coin tonic. Bosses use a chosen existing weapon family, not 14 extra unreviewed weapon families. Seven tiers each. Weapon artwork may be reused through art ids and tier colors; verify exact sheets before adding mapping. Items dropped by a type must match visible equipment; do not mint unseen loadout ids. Base-tier weapon attack contribution draft = 3×1.08^(stage−1); outfit HP = 8×1.08^(stage−1). Boss outfit HP doubles its stage base. Extra-stat roll behavior remains from the prototype; audit numerical caps before final content sign-off.

For intrinsic stat B at tier t, base merge increment d = 0.02×B (potion tier 1 override remains 0.4 HP). Intrinsic power P(t,m)=B(t)+m×d(t). Successor B(t+1)=0.85×P(t,100); d(t+1)=0.02×B(t+1). This is computed from catalog values, NOT a live buffed item. Existing authored weapon transitions must migrate to this same 85% contract. At typical tiers, successor exceeds predecessor by merge 9; potion's first transition differs because of its explicit override.

At m=100, surplus=max(quantity−1,0). Stock multiplier draft = 1 + 0.0005×surplus (0.05% of intrinsic ^100 power per spare copy). At m<100 stock multiplier=1. Multiplication applies only to intrinsic primary stats, not random extras/cooldown/range. External bonuses apply once afterward. No diminishing-return rule or designed copy cap is imposed. Numeric overflow must be handled safely with the project's large-number policy, not by wrapping or silently deleting stock. At quantity 101, source has 105% intrinsic power; evolution leaves quantity 1 and 100% intrinsic source power and adds the 85% successor. Never advertise the successor as 85% of buffed UI total. Show intrinsic, stock and external contributions separately in details.

Consumables: potion starts 10 HP, coin tonic +25% coin amount for 30s. Tonic merge increment now follows the common 2%-of-base rule, superseding prototype +0.1pp tuning. Potency scales through tier/stock; duration stays fixed, re-use refreshes duration. Consumption snapshots current potency before removing one copy. Skill casting never removes stock. Tier 7 has no evolve action, but stock power continues.

## Offline initial rates

Base 120 coins/h and 2 gems/h; upgrades and caps are in Upgrade Catalog. After unlock: weapon/outfit 1 item/h each, consumables 2/h. Eligible identity selection uniform within category, including already-owned evolved ids; no skills. Rates fixed at departure. Offline income prestige metric chosen for tuning: lifetime coins credited by offline settlements, threshold 10,000. No coin/gem conversion. 72h cumulative and 24h continuous use true credited absence interval including beyond reward cap. Persistent progress and once-only rewards follow State Contracts.

## Mission templates and main chain

Regular template quantities are authored at assignment from current accessible content; rewards fixed thereafter. Eligibility prevents impossible categories/locked bosses. Initial template set:

| Template | Goal | Reward |
|---|---|---|
| Hunt | 120 kills of an accessible normal type | 150×stage coins |
| Collect gear | 12 online weapon/outfit drops | 120×stage coins + 3 gems |
| Merge | 20 manual/auto merges of owned items | 100×stage coins + 3 gems |
| Earn | 300×stage coins from online kills | 5 gems |
| Boss hunt | 5 kills of a previously defeated accessible boss | 200×stage coins + 5 gems |
| Skill practice | 40 successful casts of an equipped skill | 100×stage coins + 3 gems |

For progression eligibility, assignment stage is highest unlocked stage with demonstrated kills. Final boss mission is never assigned before key eligibility. No repeat active template+target. Avoid collect/merge tasks if the player cannot accept the needed identity or has no mergeable below-cap items. Quantity estimates need 15–60-minute observed completion; revise templates between assignments only.

Main chain (coins / gems): first five kills (25/0), equip first item (30/0), merge once (40/2), discover and buy a camp (60/3), acquire/equip Heal (80/5), defeat Winter I gate (100/5), unlock a map-detail rank (100/3), acquire Frost (120/5), reach Summer I (200/8), evolve an item (300/10), obtain four skill families (300/10), reach Autumn (500/15), obtain all six skill families (500/15), reach Spring (800/20), complete one prestige (200/10 permanent completion flag), final quest (2,000/50). Reward values are first-pass; no guaranteed skill grant is implied. Final quest discovers independently on boss approach even if earlier main objectives are unfinished. Its completion requires 13 keys and current-run final-stage six-type/three-boss kill checklist. Rewards once; no forced prestige.

## Balance acceptance

Before shipping: test lowest viable and overpowered loadouts, ^100→tier+1 comparison with both equipped/stored contributions, no-selling full inventories, long-term surplus scaling, all gem caps and permanent coin-rate affordability. Exercise all six skills together with dense normal spots and boss telegraphs. Simulate/test 33 opportunities for reachability, no mutually impossible requirements, and all 17 combos. These tables are a tunable baseline, not an assurance of completed balance.
