# LootFarmer — Game Design Document — Change 6

Date: 2026-10-21. Change 6 is a full-game review: encounter layout, first-boss and prestige pacing, prestige rewards and cards, guided tutorial routes, content-sized panels and UI performance. Change 5 corrected the opening, teaching, healing roles, saves, fog and presentation. Game save schema is 7 (fog layout revision 2); outer container version is 2; application version is 6. Android export codes and signing configuration are unchanged.

## Authority and status

This GDD owns approved behavior. The Upgrade Catalog owns purchased scope/currency/reset rules; Content and Balance contains delegated initial tuning, which is NOT playtested. The State Contracts owns implementation semantics. Latest explicit approvals supersede old notes and examples. History folders and old release/test reports are evidence only. The supplied updated fog Playbook has been merged with Change 2's project additions, not substituted wholesale.

Premium Android-first portrait idle RPG, English-first development, no ads/IAP or network-dependent gameplay. Title LootFarmer – Idle RPG. Project declares Godot 4.7; production engine/export-template pair needs verification. Marketing toolkit remains pinned to 1.0.2. Release localization, price, provenance and device acceptance remain production gates.

## Core loop and controls

Joystick movement, then 0.5 seconds idle before target acquisition/approach/attack. Keep current target until dead or player movement; chain nearby eligible targets. Manual target drag uses line/arrow feedback. Camera drag/pinch/zoom slider; joystick returns camera to player. Manual movement cancels auto-farming focus. Focus chooses enemy type and variant and can return after death. Player HP is red; level bar blue/white. Player starts at level 1; existing level ceiling 1000 remains the baseline.

Death costs time, not possessions. Respawn at selected owned camp. Out of combat (five seconds without being hit, no aggressive enemy) the player recovers 1% max HP per second anywhere and 10% per second beside an owned camp of the current stage; nothing recovers in combat, so Heal and potions keep their roles. Purchasing a camp does not silently select it. Combat effects/rewards are simulation-owned once per action; animation/audio never apply a second hit. Panels do not pause combat; explicit global pause freezes simulation. Settings/panel navigation remains usable while paused. Cancel pending windups on load. Hard Reset clears progression, including keys/cards, and retains settings.

Use Kenney Fantasy UI and supplied PixelPlains content. Keep visual composition inspector-editable where robust. Long panels scroll with pinned actions, safe-area layout and proper touch arbitration. Do not restore retired Cartoon GUI styling. Remove permanent overhead variant-description text only; names/HP remain. Tutorial may explain variants. Recent finds remain top-left (last three, expandable to ten; no coin spam).

## Eight-stage world

| Stage | Name | Normal types | Bosses | Weather | Advance / completion | New skills |
|---|---|---|---|---|---|---|
| 1 | Winter I | 3 | 1 | Clear | snowman | None |
| 2 | Winter II | 6 | 1 | Blue falling leaves | cyan-robot | Heal (late stage) |
| 3 | Summer I | 3 | 1 | Clear | gray-cat | Frost Burst; Fire Burst; Lightning Strike |
| 4 | Summer II | 6 | 2 | Rain | elephant, teal-dinosaur | Arcane Focus; Arcane Strike |
| 5 | Autumn I | 3 | 2 | Clear | red-fox | Existing combinations |
| 6 | Autumn II | 4 | 2 | Falling leaves | black-cat, grim-reaper | Existing combinations |
| 7 | Spring I | 3 | 2 | Clear | bee, orange-tabby-cat | Existing combinations |
| 8 | Spring II | 6 | 3 | Rain | All six normal types + three bosses | Existing combinations |

Totals: 34 normal appearance/type identities and 14 bosses; 48 characters. Variants and spawned instances do not increase those totals. The count/gate/season structure is approved; exact character placement is delegated authoring in Content and Balance. Winter I is the smallest tutorial map; each second seasonal stage is larger than its first, Spring II largest. Fixed encounter levels, no player-level scaling. Weather is cosmetic; winter blue-leaf animation replaces rain. Sparks are available optional polish, not additional gameplay or an approved replacement for summer rain.

Stages 4, 6 and 7 require both designated bosses. Stages 1–3 and 5 require one gate boss. Credit required kills once per run; respawns do not relock exits. Earlier areas remain accessible for farming. Each unlocked stage has a free safe arrival camp; additional camps cost coins. Travel between unlocked camps is free. **No teleport during combat:** block all camp/stage travel while the player has a pending attack, took a hit within five seconds, or a living enemy is aggroed/winding up. Death, explicit pause, app suspension and an unfinished prestige batch also block travel. Respawning after death remains automatic at the selected camp. Stage access/camps reset on prestige.

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

Stage 1 no skills; late stage 2 Heal; stage 3 Frost Burst, Fire Burst and Lightning Strike; stage 4 Arcane Focus and Arcane Strike. Stages 5–8 combine these families. Skills use shared inventory with a filter, one equipped slot initially up to three, no duplicate family across slots. Casts never consume skills. No mana. Cooldown is per family and shared between manual/automatic use; swapping/evolving/re-equipping cannot reset it. Per-slot auto-use unlock/toggle survives prestige. Cooldown upgrade is per family, coins, max 30% reduction and minimum cooldown, resets on prestige.

Attacks require a valid target; Frost Burst affects nearby enemies, Fire Burst target area. Heal auto below 80% HP; Arcane Focus only during combat. Buff recasts refresh rather than stack unlimited copies. Strength improves by merge/evolution; cooldown improves only through its defined upgrade. Exact skill numbers and VFX/SFX mappings appear in Content and Balance and Asset Registry.

## Missions

Regular daily missions start with 3 slots, expand to 8 (supersedes old 20). Capacity and auto-claim cost gems and persist. New slots fill immediately. No mission-reward multiplier purchase. Regular missions target 15–60 minutes of relevant play, no expiry; local-midnight refresh replaces claimed missions, never unfinished progress or unclaimed rewards. Missed days do not stack. A reward claimed after crossing its eligible refresh fills the slot immediately; claims before refresh wait until refresh. Goals/rewards fixed at assignment; no identical active tasks; only achievable content. Mission rewards cannot recursively satisfy earn-currency goals.

Main objectives teach progression; completed AND rewarded ones stay completed after prestige. Unfinished main progress resets, except final mission discovery/keys. All unclaimed mission rewards clear on prestige, with no extra claim-first step. Regular missions regenerate for restarted progress. Main objective states are detailed in State Contracts. Mission Specialist is an automatic sequential prestige chain alongside ordinary missions; it never pauses/replaces the board or requires activation.

## Prestige

Eleven paths, three unique cards each; three discoverable one-use opportunities per path. **Prestige gate (Change 6):** a reset is possible only after the current run has cleared Winter (defeated the Winter II gate boss and unlocked Summer I). Opportunities may be discovered and become ready earlier, but nothing can be redeemed before the gate; the Prestige panel states the gate. Measured first gate (pacing bot): 92–113 min ordinary policy; fastest completed route 76.3 min (see Change 6 validation). Opportunities are not repeatable prestige routes. Discovery persists, shows requirements/cards, and emits a discovery notice. All track automatically; Follow merely pins the next step. Ordinary progress resets on prestige; offline path progress survives. Sequence breaks affect only unfinished sequences; ready opportunities remain secured while farming.

One reset may redeem multiple ready opportunities. Choose one remaining card per opportunity, sequentially; same-path options shrink 3 → 2 → 1, no duplicates. Consume all redeemed opportunities and reset once after choices. Completed paths stop offering opportunities; keep history. Eleven same-path and six mixed three-distinct-card combos each grant a small permanent bonus once. 33 card awards do not imply 33 resets. First opportunity target 1–2 hours. Collecting all cards and world completion are separate goals. Cards are presented as visual cards (owned Kenney frame tinted per path, PixelPlains path art, large computed value, one line of meaning); a card is selected by tapping and kept through a confirmation that states what is kept and reset. Discovery, completion, each card and the reset get a short queued celebration banner (owned star and spark frames, existing prestige sound) and a persistent badge on the Prestige button. See authored catalog and durable transaction contract.

## Offline

Fixed authored rates, unrelated to recent combat performance. Duration starts 5 hours, max 48. Separate permanent coin/gem rate purchases and weapon/outfit/consumable unlocks/rate upgrades. Only identities with positive inventory stock at departure are eligible for offline item grants; no offline skills or new discoveries. Stack duplicates; selling no longer applies. Offline grants never advance ordinary missions or non-offline prestige progress. Dedicated offline path: cumulative 72 hours, continuous 24 hours, offline-income milestone. Time beyond earnings cap counts; all three progress records persist across prestige. Exact rates/clock policy below.

## Reset ownership and implementation status

Read State Contracts for the complete matrix. Preserve cards/combos/discovered opportunities/history/keys/final mission discovery/rewarded main objectives/permanent upgrades/settings/offline-path counters. Reset stage access, camps, fog, map upgrades, run currency/items/item progress/player level, run upgrades, temporary combat state and ordinary challenge progress. Group achievement ownership remains permanent baseline; stage kill flags are separate and reset.

Change 4 implements the eight-stage campaign and its progression systems. Current executable evidence is in LootFarmer_Change_5_Validation.md. This is a source implementation, not a signed release or physical-device certification. All prices and progression pacing remain first-pass tuning.

## Change 5 opening and presentation contract

Winter I enemies only retaliate against the player who attacks them; no proximity activation or assistance. This includes both first enemy types. Winter II introduces individual proximity aggression. Summer I introduces assistance limited to living allies of the same type and variant within 110 world units. The first enemy restores prototype baseline 18 HP, 2 damage and a 2-second attack interval; the remainder retains campaign tuning pending playtests.

Heal is reusable sustain: tier-1 10 HP (Change 6; was 6), 18-second cooldown, at most 12% maximum HP per cast. Potion is burst recovery: tier-1 25 HP, consumes one copy, 5-second potion cooldown (Change 6; was 2), usable during Heal cooldown. Both clamp to missing HP. Heal is available below 80% HP; potion at or below 80%. Enemy Heal restores at most 8% maximum HP. Most bosses render at twice normal scale, final boss 2.5×; bee and squirrel keep normal scale. Existing scenery marks all boss arenas. Skill effects render below actors.

First profile chooses Guided, Overview or None. Change 6 guided lessons follow the real route across surfaces with an owned arrow pointer and frame (HUD button, then the panel tab, then the exact control), point only at visible controls and known places, and ask for an attainable action when coins or discovery are missing (explore, earn N coins). Guidance never takes input except an introduction card's Got it button; an unrelated panel, confirmation, pause, prestige choice or celebration hides it entirely, and it returns when that surface closes. Guided lessons follow movement, combat, collection, equipment, merge, upgrade and camp state; unrelated panels/confirmations suspend guidance. Later proximity, skill and group behavior have contextual cards. Guidance preferences persist through prestige; Hard Reset restores the chooser. Tutorial choices do not alter combat rules. See the audit for remaining first-profile progression and device acceptance gaps.

## Change 6 contract summary

- **Encounter layout:** every stage places its weakest normal type nearest the arrival camp, difficulty rising with distance, and every boss farther than every normal type, in its existing landmark arena (moved with its court). Variant spots are 100 units from the type center on both axes; no actor of one spot can be auto-acquired (110 + reach) from another spot, and camps sit outside every spot's acquisition range. tools/layout_campaign_groups.py owns and checks these rules.
- **First boss:** the Snowman is a later encounter in the far arena; it needs roughly level 10–14 with merged gear (measured 15–29 min ordinary/rush, 10–19 expert). Its multiplier is an explicit override; other bosses use the default boss multipliers in Content and Balance.
- **Recovery roles:** Heal tier 1 restores 10 HP (cap 12% max HP) every 18 s; potions restore 25 HP with a 5 s cooldown, so bought supply cannot be chain-drunk through a boss. Out-of-combat recovery and camp resting are above.
- **Panels:** one bottom-anchored sheet over the map, sized to its content, capped to the map and scrolling only when needed, with primary actions pinned in a fixed bar. Item details compare against the equipped item with effective deltas and browse with owned previous/next arrows in inventory order (ends disable the arrow; no wrap). Feedback while a panel is open uses its fixed notice line; otherwise a queued toast on a dark backing.
- **Navigation:** World (camps, map, travel, map upgrades), Missions, Prestige, Stats, Settings. Player upgrades remain on tapping the character (v0.4 decision), also linked from Stats. Badges: green ! for claimable missions or ready prestige, gold ✦ for an unseen discovery.
