# LootFarmer — Game Design Document — Change 3

Date: 2026-10-20. Documentation-only consolidation authorized by “write code”. Runtime remains Change 1. No gameplay, assets, save schema, export presets or store version changed.

## Authority and status

This GDD owns approved behavior. The Upgrade Catalog owns purchased scope/currency/reset rules; Content and Balance contains delegated initial tuning, which is NOT playtested. The State Contracts owns implementation semantics. Latest explicit approvals supersede old notes and examples. History folders and old release/test reports are evidence only. The supplied updated fog Playbook has been merged with Change 2's project additions, not substituted wholesale.

Premium Android-first portrait idle RPG, English-first development, no ads/IAP or network-dependent gameplay. Title LootFarmer – Idle RPG. Project declares Godot 4.7; production engine/export-template pair needs verification. Marketing toolkit remains pinned to 1.0.2. Release localization, price, provenance and device acceptance remain production gates.

## Core loop and controls

Joystick movement, then 0.5 seconds idle before target acquisition/approach/attack. Keep current target until dead or player movement; chain nearby eligible targets. Manual target drag uses line/arrow feedback. Camera drag/pinch/zoom slider; joystick returns camera to player. Manual movement cancels auto-farming focus. Focus chooses enemy type and variant and can return after death. Player HP is red; level bar blue/white. Player starts at level 1; existing level ceiling 1000 remains the baseline.

Death costs time, not possessions. Respawn at selected owned camp. Purchasing a camp does not silently select it. Combat effects/rewards are simulation-owned once per action; animation/audio never apply a second hit. Panels do not pause combat; explicit global pause freezes simulation. Settings/panel navigation remains usable while paused. Cancel pending windups on load. Hard Reset clears progression, including keys/cards, and retains settings.

Use Kenney Fantasy UI and supplied PixelPlains content. Keep visual composition inspector-editable where robust. Long panels scroll with pinned actions, safe-area layout and proper touch arbitration. Do not restore retired Cartoon GUI styling. Remove permanent overhead variant-description text only; names/HP remain. Tutorial may explain variants. Recent finds remain top-left (last three, expandable to ten; no coin spam).

## Eight-stage world

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

Totals: 34 normal appearance/type identities and 14 bosses; 48 characters. Variants and spawned instances do not increase those totals. The count/gate/season structure is approved; exact character placement is delegated authoring in Content and Balance. Winter I is the smallest tutorial map; each second seasonal stage is larger than its first, Spring II largest. Fixed encounter levels, no player-level scaling. Weather is cosmetic; winter blue-leaf animation replaces rain. Sparks are available optional polish, not additional gameplay or an approved replacement for summer rain.

Stages 4, 6 and 7 require both designated bosses. Stages 1–3 and 5 require one gate boss. Credit required kills once per run; respawns do not relock exits. Earlier areas remain accessible for farming. Each unlocked stage has a free safe arrival camp; additional camps cost coins. Travel between unlocked camps is free. Stage access/camps reset on prestige.

Spring II completion requires defeating each of its six normal enemy types at least once in that run and all three bosses, not an empty map. One boss is clearly superior and final. First approaching it blocks combat and discovers the final main mission. Only then do the other 13 bosses begin granting guaranteed unique keys, one per boss; earlier kills do not count. All 13 keys unlock final-boss combat. Keys and mission discovery survive prestige; no second approach is needed to reactivate key earning. The final objective rewards once; farming remains afterward.

## Map and discovery

Discovery-only fog: unexplored terrain hidden, revealed terrain remembered throughout the run, no mandatory dimmed current-vision layer. Player movement and owned camps reveal territory; camera movement never does. Camps reveal a small radius at unlock and when upgraded even with player elsewhere. Player reveal radius upgrades are per stage; camp radius upgrades per camp, both up to +100%. Teleport reveals destination only. Death and stage revisits retain exploration; prestige clears it.

Map detail purchases per stage: base terrain/player/discovered camps/exits; level 1 generic enemy-location markers with bosses distinguished; level 2 identities and inspection; level 3 farming details respecting purchased stat/drop information. Never reveal undiscovered places through upgrades. Markers remember spawn sites, not live remote positions/HP. Boss requirement counters are public (0/2 etc.); unknown boss locations remain hidden. Minimap/expanded map share one disclosure authority, uniform aspect-preserving transforms and hit filtering. Playbook 117.9, 124.12 and 127.6 apply.

## Enemies, variants and loot

Normal types have outfit-only, weapon-only and both variants. Selected types additionally have a fourth extra-strong variant carrying weapon, outfit and skill. It uses the skill and can drop all three through independent rolls. It shares upgrades/achievements with its type and supports focused farming. It remains a normal enemy, with up to six actors per spot from spawn upgrades. First skill variant uses Heal visibly on itself.

Normal skill chance starts at 5%, upgradeable by +15 percentage points. Early bosses use one introduced skill, later bosses two, final boss three complementary skills with clear cues. Boss skill chance starts at 10%, upgradeable to 25%; one skill roll per kill, then choose one of that boss's used skills. No three independent boss skill rolls. Drops are base-tier; higher skill tiers require evolution. Normal and boss gear rules remain type-owned, rolled per individual enemy death. Currency credits immediately; ground items retain source type. No manual selling or auto-sell remains in final design.

## Inventory, merges, evolution and copy bonuses

Shared inventory holds weapons, outfits and nonconsumable skills; consumables have separate capacity. One slot per distinct owned tier identity; duplicates stack without a designed gameplay quantity cap, including when capacity is full. Maximum purchasable capacities derive from the complete catalog including evolutions. Capacity is checked before acquiring a new identity or evolving into a missing identity. One equipped weapon/outfit. Each distinct owned UNEQUIPPED weapon/outfit contributes 30% of its stats once, not once per duplicate. Stored skills confer no passive stats.

Merge cap ^100. Same-id duplicates power merges below cap. Merge and random-roll records survive zero stock during the run. At ^100, current spare quantity gives a small bonus; copies are NOT consumed merely to gain this bonus and no reservation bucket exists. Spending/using copies reduces their corresponding bonus. Bonus is quantity-dependent, not a permanent incremental reward. Random rolls do not grow with merges or stock bonuses.

Evolution needs ^100 and at least 101 source copies: consumes 100, retains one source copy and its progression, and grants a successor. New successors start ^0; existing successor progression persists. Successor intrinsic ^0 base stats equal 85% of source ^100 base stats, excluding stock bonuses, random rolls and external player/card buffs. Later merges surpass the predecessor. Same rule for weapons, outfits, consumables and skills; tier 7 remains the current authored ceiling. Same-art successors use distinct stable ids and tier colors. Source stock bonuses decrease when evolution spends copies. Final-tier stock can still grow. Items and all their progression reset on prestige.

## Skills

Stage 1 Heal; stage 2 Frost Burst; stage 3 Fire Burst and Lightning Strike; stage 4 Arcane Focus and Arcane Strike. Stages 5–8 combine these families. Skills use shared inventory with a filter, one equipped slot initially up to three, no duplicate family across slots. Casts never consume skills. No mana. Cooldown is per family and shared between manual/automatic use; swapping/evolving/re-equipping cannot reset it. Per-slot auto-use unlock/toggle survives prestige. Cooldown upgrade is per family, coins, max 30% reduction and minimum cooldown, resets on prestige.

Attacks require a valid target; Frost Burst affects nearby enemies, Fire Burst target area. Heal auto below 80% HP; Arcane Focus only during combat. Buff recasts refresh rather than stack unlimited copies. Strength improves by merge/evolution; cooldown improves only through its defined upgrade. Exact skill numbers and VFX/SFX mappings appear in Content and Balance and Asset Registry.

## Missions

Regular daily missions start with 3 slots, expand to 8 (supersedes old 20). Capacity and auto-claim cost gems and persist. New slots fill immediately. No mission-reward multiplier purchase. Regular missions target 15–60 minutes of relevant play, no expiry; local-midnight refresh replaces claimed missions, never unfinished progress or unclaimed rewards. Missed days do not stack. A reward claimed after crossing its eligible refresh fills the slot immediately; claims before refresh wait until refresh. Goals/rewards fixed at assignment; no identical active tasks; only achievable content. Mission rewards cannot recursively satisfy earn-currency goals.

Main objectives teach progression; completed AND rewarded ones stay completed after prestige. Unfinished main progress resets, except final mission discovery/keys. All unclaimed mission rewards clear on prestige, with no extra claim-first step. Regular missions regenerate for restarted progress. Main objective states are detailed in State Contracts. Mission Specialist is an automatic sequential prestige chain alongside ordinary missions; it never pauses/replaces the board or requires activation.

## Prestige

Eleven paths, three unique cards each; three discoverable one-use opportunities per path. Opportunities are not repeatable prestige routes. Discovery persists, shows requirements/cards, and emits a discovery notice. All track automatically; Follow merely pins the next step. Ordinary progress resets on prestige; offline path progress survives. Sequence breaks affect only unfinished sequences; ready opportunities remain secured while farming.

One reset may redeem multiple ready opportunities. Choose one remaining card per opportunity, sequentially; same-path options shrink 3 → 2 → 1, no duplicates. Consume all redeemed opportunities and reset once after choices. Completed paths stop offering opportunities; keep history. Eleven same-path and six mixed three-distinct-card combos each grant a small permanent bonus once. 33 card awards do not imply 33 resets. First opportunity target 1–2 hours. Collecting all cards and world completion are separate goals. See authored catalog and durable transaction contract.

## Offline

Fixed authored rates, unrelated to recent combat performance. Duration starts 5 hours, max 48. Separate permanent coin/gem rate purchases and weapon/outfit/consumable unlocks/rate upgrades. Only identities with positive inventory stock at departure are eligible for offline item grants; no offline skills or new discoveries. Stack duplicates; selling no longer applies. Offline grants never advance ordinary missions or non-offline prestige progress. Dedicated offline path: cumulative 72 hours, continuous 24 hours, offline-income milestone. Time beyond earnings cap counts; all three progress records persist across prestige. Exact rates/clock policy below.

## Reset ownership and implementation status

Read State Contracts for the complete matrix. Preserve cards/combos/discovered opportunities/history/keys/final mission discovery/rewarded main objectives/permanent upgrades/settings/offline-path counters. Reset stage access, camps, fog, map upgrades, run currency/items/item progress/player level, run upgrades, temporary combat state and ordinary challenge progress. Group achievement ownership remains permanent baseline; stage kill flags are separate and reset.

Current runtime is the compact prototype, not these eight stages. Missions, final prestige, fog map, offline and skills need implementation; sell removal and new evolution/stock math are not coded. Existing boss-loadout failure and physical Android/engine/provenance gates remain open. Detailed documents are an implementation handoff, not a claim that the final game has passed QA.
