# LootFarmer — Game Design Document — Change 1

Date: 2026-10-18 (America/Santo_Domingo). Approved title: LootFarmer - Idle RPG. Android package: com.shekinahwelefuldesigns.lootfarmeridlerpg.
Status: APPROVED by the user on 2026-10-18. Audit A01–A18 is closed with the corrections below. The compact gameplay slice is implemented in v0.3. The user explicitly deferred signing and authorized gameplay development; signed/device release validation remains pending.

## Current implementation authority — Change 1 (2026-10-20)

This section supersedes earlier balance/UI values. The GDD remains open for continued design work after this batch. See `LootFarmer_Change_1_Notes.md` for installation, migration and test evidence.

- Project change identifiers are integers: 1, 2, 3, incremented once per delivered batch. Project version is `1`; Android version codes are separately monotonic (both presets now 8), and toolkit/save-schema versions retain their independent meanings.
- Item panels show all actions immediately; there is no More/Less Options toggle. Player tabs are Player (respawn delay only), Inventory, Supplies and Upgrades (global gem chance/amount). Collection is owned by enemy type, including the boss; every variant of a type shares its upgrades.
- Global gems: base 8% chance and 1 gem. Chance adds 1 percentage point for 12 levels. Amount adds 0.5 for 10 levels, ending at 6 gems. Normal enemies have a hard total 20% chance cap including cards and achievements. Amount prices: 50, 75, 105, 140, 180, 220, 265, 320, 400, 500 gems. Chance uses the same first ten prices, then 600, 700.
- Boss chance: eight +5-percentage-point purchases, prices 100, 150, 225, 325, 450, 600, 800, 1000 gems. Global chance and achievement/card effects apply, with a hard combined 60% cap. Boss amount: ten +1 purchases, using the global amount price list, giving +10 extra and 16 maximum combined gems per successful roll. Boss-specific authored prices are final, without the generic type multiplier.
- Normal spawn capacity starts at 3 per spot, increases by 1 for three levels to 6. Costs per first type: 150, 250, 400 gems. It applies to each of the type's three variant spots; adds new actors without resetting existing fights. Boss remains one and cannot purchase either spawn upgrade.
- Normal spawn cooldown: five levels subtracting 10% of the original delay each, at 100, 175, 275, 400, 550 gems. Original delays 5/7/10 seconds become 2.5/3.5/5. Applies on the next death; an already-running respawn timer completes normally. Boss retains its already-authored 30-second delay.
- Collection unlock/range/batch/interval move to each enemy type. Initial interval 10 seconds, five -1-second levels to 5; initial range 100 and batch 1. Existing range and batch gains/caps/currencies remain. Pickups record their source type, so a collector never picks up another type's shared consumable. Independent timers and eligibility prevent cross-type collection.
- Existing type multipliers 1/2/3/4 apply to ordinary type upgrades, including collection; normal spawn upgrades use 1/2/3. Coin amount retains its separate stronger 1/4/12/30 initial-price scaling. Collection upgrades retain their original permanent status; other type upgrades and global gems reset on prestige. New spawn/boss tracks reset on prestige.
- Save schema 5 copies owned global collection levels to all four types once, resets their timers, and refunds old global gem upgrades at their exact old prices so the new tracks can be purchased deliberately. Schema 3 type-gem refunds still run first when needed. Legacy ground gear gets its authored source type; legacy shared consumables use the nearest type's row because old saves did not record provenance. New drops always use exact source identity. Repeat loading never repeats refunds.
- Destructive confirmations now use the existing Kenney theme inside a bounded in-game panel, with wrapping/scrollable text and pinned Confirm/Cancel buttons. The overlay blocks underlying UI, supports cancel, and hard reset still works while paused.

## Historical implementation — v0.6.3 (2026-10-19)

These approved decisions supersede conflicting historical sections and the v0.6.2 baseline below. See `LootFarmer_v0.6.3_Notes.md` for migration and checks.

- The enemy Upgrades shortcut sits below Achievements, aligned left.
- Farming unlock remains per enemy type. Choose outfit-only (column 0), weapon-only (column 1), or both (column 2). Focus acquires only that type/variant, returns to its camp column after death and persists on save/load. Boss has only the both variant. Manual movement cancels farming; repeated selection of the active choice turns it off. Legacy focused saves default to both.
- Same-art evolution extends outfits, consumables and terminal weapon chains through tier 7. Existing Wooden → Stone → Iron weapon transitions retain their authored values. Generated successors use stable catalog IDs and the source art/animation/consumable family; seven distinct slot colors plus the item-details tier distinguish them.
- Evolution requires ^100 and 100 spare copies: minimum quantity 101, consumes 100, retains one source copy with its existing ^100/roll and creates one successor. A newly owned successor starts ^0 with its own roll; existing successor progression persists. Target capacity is checked before spending. Final tier cannot evolve.
- For a generated successor, each base stat is 1.25 × the predecessor's merge-100 stat, calculated before prestige merge multipliers. Its per-merge increment is 1.25 × the predecessor's increment. Existing extra-stat roll ranges stay unchanged; normal-stat caps in effective player stats remain in force. Evolved consumables work with manual/auto use, and source-family gear auto-merge applies to evolved outfits/weapons. Drops and shop purchases still grant base authored IDs.
- Gem chance and gem amount are global, purchased in Player → Gems, and reset on prestige. Chance adds 0.1 percentage point per level, cap 20 (+2 points), initial cost 50 gems. Amount adds 0.1 gem per drop, cap 10 (+1 gem), initial cost 100 gems. Both cost curves grow ×1.8 per level with ceiling. Fractional gems are real saved currency, displayed through NumberFormat.
- Global base gem chance is min(25%, 8% × prestige gem multiplier + global chance increment); existing per-enemy achievement chance is then added for that type only. Gem amount is 1 + 0.1 × global amount level. Achievement ownership and other group upgrades are unchanged.
- Schema 4 migrates prior schemas and refunds the exact catalog-priced old type-specific gem purchases once; new global tracks start unpurchased. Gear, levels, achievements, fractional balances and earlier migrations remain intact. A saved migrated profile cannot receive the refund again.
- Reusable asset specifics are recorded in Playbook section 22.4, including frame segments, tight crops, Kenney slicing, fonts, art-family mapping and verification limits.

## v0.6.2 baseline (overridden by v0.6.3 where different)

This section and the v0.5.x/v0.6.x release notes supersede the historical initial balance proposals below. Runtime tuning lives in data/game/catalog.json; those historical tables are not tuning inputs.

- UI: Kenney Fantasy UI borders, red health and blue XP, gear/supplies divider, square adaptive slots. GUIPackCartoon is retired. Tap supplies to use, hold for details; dragging scrolls without activation.
- Player level 1–1000 adds 5 HP and 0.5 damage per level. One equipped weapon/outfit; each distinct owned unequipped weapon contributes 30% of normal and extra stats, including its merge gains. Stored outfits contribute zero.
- Base gear chances: Sprout 10%, Robot 9%, Dinosaur 8%, boss 30%. Per-type gear and consumable upgrades add at most 15 percentage points each. Three variants: outfit, weapon, both; only worn gear drops. Type upgrades apply across variants.
- Group XP upgrades add 10% per level (20 levels). Group achievements persist across prestige; type upgrades reset. Gear auto-merge belongs to each type; consumable auto-merge remains a player upgrade.
- Gear/tonic merge increments are three times the authored catalog pair increment; potion override is +0.4 HP per merge before prestige. Extra rolls do not increase with merges. Evolution stock rule below is unchanged.
- Coin upgrade starting prices: 30 / 120 / 360 / 900, growth 1.4 / 1.5 / 1.6 / 1.7. Per-level coin gain 0.5 / 1 / 1 / 1. Fractional balances are stored as real values; presentation uses NumberFormat, two decimals and compact suffixes.
- After 0.5 seconds idle, acquire a target; manual movement or target death clears it. Drag from player to enemy selects a chase target with a gold arrow. Each attack has one authoritative damage contact synchronized to its visual swing.
- Player pause locks gameplay mutations (including inspector actions). Read-only panels/settings remain usable; hard reset remains available and resumes. Pause is session state and legacy saved pause is ignored. Panels themselves do not pause combat. Prestige retains its separate result transaction.
- Scroll children pass input, including dynamically created cards/buttons. Changes reconcile into existing controls; only changed structure replaces nodes, with scroll restoration after two layout frames. A tap activates; dragging cancels activation.
- Upgrade cards show effective current/next values from simulation getters, fixed status rows and shared affordability/lock reasons. Stats show base, level, equipped and stored contributions before permanent HP/damage multipliers and caps.
- Notifications remain visible, show icons/counts and exclude coins. Gem pickup feedback lasts four seconds; damage feedback lasts 1.8 seconds. Display numbers and units must use shared formatting and localized templates.
- Validation: automated headless probes cover rules, actual routed gestures, layout and save behavior. Physical Android visual acceptance and a complete natural run still require human testing; no signed release is produced by this patch.

## Historical design narrative and initial tuning

## 1. Authority and scope

The supplied standalone Reusable_Game_Development_Playbook.md, including its 2026-10-18 asset update, is the production/engineering authority. This GDD owns this game's design. The included Playbook contains the 2026-10-18 asset-workflow update. docs/QuickPlan.xlsx supplies the original concept; later explicit conversation decisions supersede it. Older GDDs are reference-only and are not imported as gameplay requirements.

The user approved the GDD and authorized bootstrap and subsequent prototype implementation with “write code.” On 2026-10-18 the user explicitly deferred the signing gate for prototype development, confirmed the bootstrap works in their Godot editor, and reauthorized implementation. This does not certify Android release readiness. Read the closed audit alongside this GDD. Initial balance values are delegated tuning, not final promises.

Premium Android-first, portrait, intended one-time price USD 2 or less (final storefront price later). No ads, IAP, subscriptions, analytics, crash tracking or other player tracking. No network-dependent gameplay is required.

## 2. Identity, hook and loop

Move into an enemy group, automatically fight for their visible weapons/outfits, merge duplicates, choose a useful equipment combination, and move farther up the world. Unlock collection and inventory automation, defeat Death, and optionally prestige for permanent bonuses.

Personality: people hanging out, startled reactions when attacked, humorous clothing-theft reactions. Enemies visually show their potential outfit/weapon loot. Reactions use localized text and verified expressions, not text baked into art. The player's visual outfit does not evolve through merging; later enemy costumes can nevertheless represent stronger drops.

Loop: move -> stop for 0.5 seconds -> acquire nearest eligible enemy -> approach/attack -> collect -> equip/merge/sell/spend -> survive tougher groups -> defeat boss -> continue or prestige.

## 3. Movement, combat and world

Start as the basic unarmed, unclothed unit. One circular joystick controls manual movement; combat itself is automatic. Consumable and management UI actions remain available. Manual movement overrides automatic pursuit. After 0.5 seconds without manual movement, acquire a nearby enemy, approach into attack range, and attack. After a kill remain at that position, acquiring another nearby enemy if available; do not walk back to the original idle position. Targeting can freely chain between groups. Design spatial separation accordingly, rather than enforcing an unapproved group lock.

Map advances upward, with lateral space for at least two groups and routes around most encounters. All areas are accessible from the beginning. Some rows may be blocked by hostile enemies; surviving passage is allowed. Strength, not a level gate, limits practical advancement.

Some enemies retaliate individually, others alert their group. First enemies do not alert their group. Enemy regeneration begins after 5 seconds without being attacked. Enemies abandon pursuit beyond a configurable distance from their group area. Initial aggro, range, respawn and regeneration values are delegated to tuning (section 11).

Death costs time only: no loss of gear or currency. Initial respawn delay is 10 seconds, reducible through upgrades. Respawn at a selected purchased spawn point. Initially remain there until moved. Later purchase focused-group automation to return to a selected group after death. Player manual input takes priority; automation resumption follows audit A09.

Death is immediate logically; animation completes separately. The timer starts at logical death and restores full health at respawn. Enemy kill/reward events occur once, independently of presentation callbacks.

## 4. Inventory and equipment

Two inventories: gear starts with 3 slots, consumables with 1. Each slot holds one item identity with unlimited stack quantity. Capacity expands through purchases; numbers must be formatted safely at large quantities. Equip exactly one weapon and one outfit. Equipped gear remains in its inventory slot with an equipped marker.

Each gear identity has one shared random-stat roll and one shared merge level, including while quantity is zero. Distinct weapon tiers are distinct identities. The player can inspect normal and extra stats. Gem-priced rerolls depend on tier and alter extra stats only. Random-stat ranges and initial counts are delegated; initial recommendation is two distinct bonus types, rerolled together.

Sell items for coins. Later unlock a per-identity auto-sell rule on acquisition. Protect the equipped last copy under audit A04. Auto-sell targets item identities, never inventory slot indices. Select known item types in an upgradeable-capacity sell list; initially allow one type after unlocking auto-sell. Marked loot sells immediately on acquisition without occupying a slot, even if inventory is full. Existing stock is not retroactively sold. Equipped identities cannot be marked until unequipped. List capacity starts at one; initial extra-entry cost is 10 gems, multiplied by 1.8 for each further entry (tunable). No discard feature was requested.

Loot initially requires tapping. Auto-collection initially collects one item within range every configurable interval; separate upgrades improve range, collection batch size and interval. A full inventory accepts existing identities but rejects new identities; rejected loot stays on the ground. Uncollected loot expires after 5 minutes. Currency is credited immediately on each enemy death and never occupies inventory or ground space. A later optional coin animation is presentation only and cannot delay or duplicate credit. Ground-item and timer behavior follows A12/A16.

## 5. Permanent-within-run merging and evolution

Merging consumes spare copies of the same identity to increase its shared merge level, leaving at least one owned copy. Example: quantity 4 at ^0 -> merge 3 -> quantity 1 at ^3. All remaining copies use the shared level; do not multiply credit by the level already displayed on a consumed copy. Emptying inventory does not erase that identity's level or random bonuses. Prestige does erase them.

Normal stats increase by small authored per-merge increments; extra stats do not change. Gear and consumables cap at ^100. Gear auto-merge is unlocked per enemy type in that enemy’s upgrade panel (weapons and outfits together, resets on prestige). Consumable auto-merge stays in player upgrades. A shared frequency upgrade affects both. At cap, stop consuming duplicates.

Approved weapon evolution: at ^100, spend 100 spare copies to receive one next-tier weapon and keep at least one current-tier copy. Thus minimum quantity is 101. Wooden Sword remains ^100, and future Wooden Sword drops remain ^100. Target tier uses its existing shared progression/roll, or starts ^0 with an initial roll if new. Repeatable. Cost is provisional for balancing. Last-tier weapons, outfits and consumables have no defined evolution and retain ^100 cap.

Evolution must be transactional: validate target inventory capacity, quantities and eligibility before spending. Do not destroy the source or reset the target. At maximum merge level, automated merging preserves potential evolution stock. Evolution is manual in the first playable unless separately approved.

## 6. Consumables

Consumables stack and merge in their own inventory. Using one Potion ^3 from quantity 2 leaves one Potion ^3; using the last leaves zero quantity but preserves ^3 progression. The old shared-pool design is superseded.

Potions can be used only when health is strictly below 80%, whether manual or automated. Heal amount is capped by missing HP. Automation is assigned to a chosen inventory slot, initially one automated slot and eventually up to three, with an upgradeable use interval. Use is manual-only until automation unlock, replacing earlier dropped-potion assumptions.

Boost reuse extends duration. If a stronger merged version is used while active, increase active potency as well; do not reduce potency on reuse. A05 defines the approved duration/potency interaction. Purchases and enemy drops provide consumables. They enter inventory through collection rather than an immediate-use pool.

## 7. Economy and upgrades

Coins and gems are gameplay-earned only. Currency drop chance and amount are four separate upgrade tracks: coin chance, gem chance, coin amount, gem amount. Gear loot chance uses coins. Extra slots use gems. Auto-merge uses gems and should be relatively expensive. Temporary boosts can cost coins/gems. Remaining prices are delegated tuning.

Upgrade definitions are authored data with owner/scope, currency, level, cost, effect and cap. Each enemy-group definition owns its upgrades, applied to every member. Every enemy is an individual runtime identity and its own death independently rolls currency and loot; killing one enemy never rolls a shared group-death reward or rewards surviving members. Other tracks: respawn delay, spawn-point purchases, auto-collection and its improvements, auto-use slots/interval, auto-sell, auto-return to a selected group, and inventory capacity.

No normal-stat upgrade purchase on gear: duplicates provide those improvements. Rerolls change random bonuses only.

## 8. Ending and prestige

Death is at the far end of the map, equipped with the pictured dark weapon and periodically spawning black cats. Beat it through strong equipment, useful extra stats and consumables. Initial numbers must make multiple builds viable rather than require a single exact random roll.

After victory, continuing to farm and re-fighting the boss is allowed; prestige is optional. Each prestige presents three random cards and grants one selected permanent bonus. Bonuses accumulate across runs. Card power/limits are delegated balance. Only Hard Reset removes permanent bonuses.

| Reset domain | Prestige behavior |
|---|---|
| World position, enemies, ground loot, boss state | New run |
| Coins, gems, inventories, equipped gear | Clear |
| Item merges and extra-stat rolls | Clear |
| Purchased spawn points | Clear; default starting point remains |
| Purchased automation and inventory capacity | Retain |
| Prior prestige cards | Retain; add chosen card |
| Settings/language/audio | Retain |
| Other upgrades and active consumable effects | Reset; audit A06 |

Offer generation, card choice, bonus grant and reset need persisted transaction state so reload cannot duplicate rewards or reroll an offer. One prestige entitlement per run's first boss defeat; re-killing the boss does not grant extra cards without restarting.

## 9. Persistence, pause and offline

Progress always persists across sessions. Save quantities, item records even when quantity=0, equipment, purchases, selected spawn, runtime positions/HP/timers, pending rewards, boss outcome and prestige transaction. Save settings separately as appropriate. Snapshot runtime state at save boundaries rather than continually mirroring every actor.

Inventory/settings panels do not pause combat. Only explicit player pause stops foreground gameplay. Platform backgrounding suspends simulation safely; it is not a reset. First playable gives no offline income. Full game must add offline coins/gems, and later upgrades permit offline acquisition only of owned identities already present in inventory. Full offline rates, cap, survivability rules and reward calculation remain deferred design, not implemented assumptions.

Hard Reset is explicit and confirmed, works while paused, clears progression including prestige, and returns to a valid starting state. Retain user settings. Save files must be versioned and atomically replaced with recovery behavior. Debug/probe profiles use distinct paths and must never alter real saves.

## 10. First-playable scope and presentation

Approved scope: one compact upward map, three enemy groups plus Death/cat summons; three sword tiers; three outfits; potion and one timed currency boost; complete collection/equipment/merge/evolution/sell/reroll/upgrade/respawn/prestige loop. Purchasable automation is represented in this scope, not implied as all unlocked at start. Offline rewards and additional weapon families are deferred.

Portrait composition: currencies/header, substantial upper world viewport, accessible lower gear/consumable slots, joystick and management controls. Starting outfit candidates: sprout -> intermediate costume -> full costume, contingent on actual animation coverage. No claim that an asset supports a pose until its sheet is inspected.

Use a reusable actor scene with body/outfit/expression/weapon layers where the supplied assets support composition. Verify frame geometry, directions, layer offsets, attack contact and non-looping death for each included family. Unarmed presentation must not silently add a weapon. Choose and approve a fallback if a dedicated unarmed attack is absent.

Editor-authored scenes/cards/themes/resources are preferred for robust visual composition; scripts bind state and generate content through those templates. Runtime must preserve editor changes. Inspect UI asset policy and coverage before making replacements; the Playbook's examples do not automatically assign another game's UI pack to this game.

Acquisition history shows the latest three entries and expands to ten. Bootstrap UI interpretation: tap the section to expand/collapse; this small reversible interaction is not a new progression rule. Each currency grant, collected item or auto-sale is recorded once; show auto-sale proceeds clearly. No more than ten history entries; coalesce simultaneous same-kind events if needed without altering economy. History is informational, never a reward owner.

Teach joystick, stop-to-attack, tap loot, equip, merge, potion and automation through short contextual steps. Avoid interruptions that silently stop combat. Explain prestige's reset scope before confirmation.

Native localization begins with the first feature: semantic keys and English source only; no hardcoded player-facing English. Show all 20 approved language buttons, other 19 disabled. Automatic always resolves to English until full localization validation. Use flexible layouts and script-capable font planning. Later translate after English/UI freeze and validate in 5+5+5+4 language batches before enabling non-English choices/device detection.

## 11. Initial balance sheet — agent-selected, adjustable

These are first-test inputs, not sourced Dungeon Rush formulas. Online research did not verify its stat list. No external game's economy or paid mechanics are inherited.

Base player: HP 100, damage 5, 1 attack/second, defense 0, crit chance 5%, crit multiplier 1.5, lifesteal/regen 0. Unarmed reach 28 world units; movement 90 units/second. Acquisition 140 units; manual-stop delay 0.5 seconds. Spatial values must be normalized to the actual art scale.

Damage = (base damage + weapon damage) × (1 + additive damage bonuses) × crit multiplier when critical × 100/(100 + target defense), minimum 1. Crit chance cap 75%; multiplier cap 4; lifesteal cap 15% of actual HP damage (exclude overkill); regeneration is HP/second; attack-speed bonus cap +200%. All caps are provisional and enforced after summation, including prestige.

| Sword | Added damage at ^0 | Added damage per merge | Attack interval |
|---|---:|---:|---:|
| Wooden | 3 | 0.04 | 1.0 s |
| Stone Sword | 9 | 0.08 | 1.0 s |
| Iron Sword | 22 | 0.15 | 1.0 s |

Next tier's base exceeds previous tier's ^100 value. Random bonuses must not make evolution systematically feel like a downgrade. Candidate sword extras: crit chance +1–3 percentage points, crit damage +0.05–0.15 multiplier, attack speed +2–6%, lifesteal +0.5–1.5 percentage points. Choose two distinct types. Higher-tier ranges can improve after playtests.

Three outfit normal-stat profiles: (A) +20 HP, +0.1 HP/merge; (B) +4 percentage points crit chance and +0.15 crit multiplier, increments +0.01 point/+0.001 multiplier per merge; (C) +40 HP, +0.5 HP/second regeneration, +2 percentage points lifesteal, increments +0.2 HP/+0.005 HP/s/+0.005 point per merge. Extra-stat pool: HP, defense, crit chance/damage, lifesteal, regeneration. No repeated bonus type within extra slots; fixed normal stats may overlap a random bonus.

Potion: heals 10 + 0.4×merge HP before prestige multipliers. Coin boost: +25% coin amount for 30 seconds, +0.1 percentage point potency per merge. Manual potion cooldown initially 2 seconds; auto-use initially checks every 10 seconds.

| Encounter | HP | Damage | Attack interval | Defense | Respawn |
|---|---:|---:|---:|---:|---:|
| First group | 18 | 2 | 2.0 s | 0 | 5 s |
| Second group | 65 | 5 | 1.8 s | 5 | 7 s |
| Third group | 150 | 10 | 1.6 s | 10 | 10 s |
| Death | 1200 | 16 | 1.8 s | 20 | 30 s after victory |
| Summoned cat | 25 | 3 | 2.0 s | 0 | Summon only |

Initial behavior: group 1 passive until attacked; group 2 individual proximity aggression; group 3 assists its group. Leash 220 units from group center; regen 10% max HP/s after required 5 seconds. Death summons 2 cats per 12 seconds, maximum 4 living cats. Boss resets to full HP after disengagement/player death, preventing attrition through free deaths.

Currency roll starts at coin chance 100%, gem chance 8%; coin amounts by group 1/3/7, gem amount 1. Gear drop chance starts at 10% / 9% / 8% / 30% for Sprout / Robot / Dinosaur / Death, split equally among authored outfit/weapon entries; potion chance 10%. These are independent reward rolls, not promises of a drop on every kill. Tune to first useful drop under 1 minute, first merge under 3 minutes and first automation in roughly 5–10 minutes.

Initial costs: loot chance +2 percentage points/level costs 20×1.35^level coins (cap 50%); coin amount +1 costs 30×1.4^level coins; gem chance +0.5 percentage points costs 5×1.4^level gems (cap 25%); gem amount +1 costs 30×1.5^level gems. Coin chance starts capped at 100% for first-playable groups, omitted from enemy panels rather than selling a useless upgrade. Later content can start lower. Round costs upward.

Capacity: next gear slot 10 gems, consumable slot 8 gems, each subsequent cost ×1.8. Auto-collect unlock 20 coins, 1 pickup/3 seconds in 100-unit range; improvement tracks start 30 coins with ×1.5 cost growth. Auto-sell 20 gems; gear auto-merge 30 gems; consumable auto-merge 20 gems; merge cycle initially 5 seconds, one duplicate/cycle. Auto-use slots cost 10/25/50 gems. Auto-return 25 gems. Spawn points 50/150 coins; respawn reduction costs 30×1.7^level coins, -1 second/level, minimum 3 seconds. Sale coin values provisional: sword 2/6/15, outfit 2/6/15, potion 1; never scale sell value with permanent merge level. Reroll costs 3/6/12 gems by tier. Purchased potion 10 coins; boost 30 coins. All tracks require explicit caps and rounding in authored resources before implementation sign-off.

Prestige card pool: +5% damage, +5% HP, +5% coin amount, +5% gem chance relative bonus, +5% gear drop chance relative bonus, +5% normal-stat merge gain. Draw three distinct eligible types, choose one, accumulate additively by type. Probability caps remain effective; omit capped cards if no remaining benefit. Merge card changes per-merge gain, not number of merges or evolution thresholds. Prestige should shorten subsequent runs without making starting automation irrelevant. Initial complete compact-run target 30–60 minutes, not a promise of final game length.

Balance acceptance: manual and automated play both progress; no infinite resale loop, zero-time respawn cycle, repeated prestige claim, duplicate merge credit or impossible evolution; at least two workable boss loadouts. Real Android play and deterministic isolated simulations guide revisions.

## v0.3 implementation handoff

See `LootFarmer_Prototype_Status.md` for current tests and limits and `LootFarmer_Asset_Registry.md` for verified art mappings. The visual reference is organizational guidance: a scrolling open meadow with two clusters per ordinary encounter band, gear/supply dock, and live management sheets. Balance remains delegated and provisional. No offline rewards were added.

The initial balance sheet above records starting values. `data/game/catalog.json` is the implemented tuning source; delegated price/cap adjustments do not reopen behavioral design approval.


## Approved v0.4.0 interaction and presentation revision

Player tap owns general/automation upgrades; enemy tap owns group information and farming upgrades. Enemy panels show a portrait, locked stats/drops placeholders, and separate permanent Reveal Stats / Reveal Drops purchases. Both reveal purchases survive prestige. Group equipment chance decreases by one percentage point between regular tiers; boss chance is 30%; purchased chance bonus remains +2 percentage points per level.

Camps are visually distinct respawn shrines. Tapping an owned camp selects it without teleportation. Selected, unlocked and locked states are visible. Recent finds move top-left; joystick moves bottom-center; world text uses scalable smooth rendering. Rebuilt scenery includes meaningful clearings and decorated non-walkable surroundings. Boss-gated map sections are explicitly deferred. See LootFarmer_v0.4.0_Notes.md for implementation, initial reveal prices and validation limits.


## Approved implementation revision — 0.5.0

The current interface, XP progression, stored-weapon bonuses, three-column enemy variants, worn-gear drops and schema-2 migration are specified in `LootFarmer_v0.5.0_Notes.md`. Those rules supersede earlier single-group map/UI and equipped-only stat descriptions. Test evidence is in `Progression_UI_Evidence/`. Physical-phone visual review and a complete natural run remain pending.
