# LootFarmer — Game Design Document — Change 2

Date: 2026-10-20. Source reviewed: lootFarmer(6).zip. Status: design consolidation; final GDD remains OPEN. Runtime remains Change 1. This delivery changes documentation only.

## Authority and reading order

This document owns game-specific decisions. The Reusable Game Development Playbook owns reusable production methods. Latest explicit user decisions supersede older proposals. Read the Design Audit for implementation gaps and evidence, the Asset Registry for available resources, and Checkpoints for the remaining sequence. Prior documents are preserved under `history/pre_change_2/` as historical evidence, not current requirements. Historical release notes and probe results describe their original builds only.

Premium Android-first portrait idle RPG; no ads, IAP, subscriptions, tracking or network-dependent gameplay. Working title LootFarmer - Idle RPG; package com.shekinahwelefuldesigns.lootfarmeridlerpg. Proposed price at most USD 2 remains a storefront decision. Project declares Godot 4.7; exact production engine/export-template pair must be validated. Toolkit 1.0.2 remains pinned.

Use integer change numbers, increasing once per delivered batch. This is documentation Change 2, not a new executable build. Save schema, Android versionCode and toolkit version are independent. Finish remaining design decisions before implementing the full game.

## Core game and existing baseline

Move, stop, acquire a target after 0.5 seconds, approach, attack, collect visible loot, equip/merge/evolve, buy upgrades and optionally pursue prestige. Joystick/manual movement cancels pursuit and focus; normal targeting can chain between nearby groups. Farming focus is per enemy type and outfit/weapon/both variant. Death costs time, not possessions; respawn at the selected unlocked point. Buying a spawn point does not select it automatically.

Combat owns each damage contact and each reward once; animation only presents it. Pending windups cancel on load. Explicit pause freezes gameplay mutations and timers; reading panels/settings remains possible. Panels alone do not pause combat. Confirmed Hard Reset clears progression/cards and resumes a clean run, retaining settings. Its confirmation must remain inside the safe area with reachable pinned buttons at every supported size.

Current playable content is three normal types (Sprout, Robot, Dinosaur), Death and summoned cats. It is a prototype slice, not the final world roster. Player level currently runs 1–1000 with +5 HP/+0.5 damage each level; final balance remains reviewable.

Currency is credited immediately on kills. Ground items record source enemy type. Distinct owned identities occupy capacity; duplicates stack even when full. Auto-sell is identity-based, applies on acquisition, and does not retroactively sell stock. The last equipped copy cannot be sold. Shared merge/roll state survives zero stock within a run. Merge cap is ^100. Evolution needs 101 source copies, consumes 100, retains the ^100 source and creates a successor; output capacity is checked before spending. Existing successor progression persists; new successors start ^0. Current same-art evolution ends at tier 7.

## World direction — approved, roster still open

Progress through boss-gated sections: a small linear opening with roughly three enemy types, a small open section, then a larger open section with multiple bosses and enemy levels. Levels are fixed by location, not scaled automatically to the player. Supplied environments support several visual areas; art availability does not establish playable navigation or a final enemy count.

Still decide exact normal/boss roster, section gates, travel/checkpoints and which world unlocks reset on prestige. Earlier proposals of 13 normal enemies/5 bosses are not approved. Earlier unrestricted access to all areas is superseded by the boss-gated direction.

## Upgrades and stats

All item actions are visible without More/Less. Consolidate gems and automation under Upgrades, with clear player/per-type ownership. Player respawn delay remains player-specific; movement speed is an approved additional player upgrade. Suggested movement tuning is coins, up to +50%, reset on prestige; currency and balance belong to the upcoming full catalog review.

Each distinct owned unequipped weapon AND outfit contributes 30% of its normal/extra stats including merge gains, once per identity, not per duplicate. Equipped gear contributes normally. The implementation currently applies stored contribution only to weapons: outfit support remains work. Unequipped skills confer no passive stats.

Implemented Change 1 baseline, subject to the later comprehensive upgrade review:

| Track | Baseline and maximum | Price/scope |
|---|---|---|
| Normal gem chance | 8% base; 12 purchases of +1 percentage point; combined cap 20% | 50,75,105,140,180,220,265,320,400,500,600,700 gems |
| Global gem amount | 1 base; ten +0.5 purchases; maximum 6 | 50,75,105,140,180,220,265,320,400,500 gems |
| Boss gem chance | Global bonuses apply; eight +5 percentage-point purchases; combined cap 60% | 100,150,225,325,450,600,800,1000 gems |
| Boss extra gems | Ten +1 purchases; +10 extra, total 16 with max global amount | Same ten-price sequence as global amount |
| Normal spawn capacity | 3 per spot to 6 in three purchases | 150,250,400 gems times normal type multiplier |
| Normal spawn cooldown | Five reductions of 10% of original delay | 100,175,275,400,550 gems times normal type multiplier |
| Collection | Unlock/range/batch/interval per enemy type, including boss | Starts at 10 seconds; five -1 second ranks to 5; starting range 100, batch 1 |

Spawn upgrades exclude bosses. Boss current respawn delay is 30 seconds; the request for a longer delay needs final pacing review, since 30 seconds was already present before Change 1. Normal original delays 5/7/10 seconds reach 2.5/3.5/5. Existing timers finish normally after an upgrade. Normal capacity applies separately to each variant spot, not six actors total across a type.

Ordinary type multipliers currently 1/2/3/4; normal spawn uses 1/2/3. Coin starting-price multipliers are 1/4/12/30. Boss gem table is already final-priced, without another type multiplier. Collection capabilities remain permanent; normal spawn, boss/global gem and other run-specific type upgrades reset on prestige.

Review every upgrade together before final implementation: category, currency, starting value, increment, cap, price curve, prerequisites and reset scope. Proposed new currencies/prices are provisional; approval of behavior does not finalize the whole economy.

## Missions

A fixed main-objective chain accompanies repeatable daily missions. Start with 3 daily slots, upgrade to 20. Missions have no expiry; target roughly 15–60 minutes of relevant gameplay. Daily refresh uses local midnight; missed days do not accumulate.

Unfinished missions retain progress across daily refresh. Completed unclaimed rewards remain claimable. A completed mission crossing a refresh is replaced immediately after its reward is claimed; claiming before that refresh leaves the slot waiting until refresh. Do not penalize late claiming or grant duplicate rewards. Newly bought slots fill immediately.

Rewards are manual initially; player automation unlocks auto-claim. Mission-slot capacity and auto-claim capability survive prestige. Assign only currently achievable missions, fixing their goals/rewards at assignment. Avoid identical active missions. Normal manual and automated gameplay may advance multiple matching missions. Daily progress counts from assignment; prior main milestones may be recognized. Mission coin rewards do not recursively satisfy earn-coin missions.

Daily families: defeat, collect, merge, earn coins and accessible bosses. Main objectives teach camps, automation, evolution, bosses and prestige. Rewards are effort-based coins/gems/both; main milestones may reward more.

Prestige resets daily missions and generates new missions appropriate to the restarted run; unclaimed rewards do not require a claim-before-reset prompt. Completed and rewarded main objectives stay completed once. Unfinished main-objective progress resets. Explicit treatment of completed-but-unclaimed main objectives must be recorded in the final reset matrix.

## Prestige: paths, discovered opportunities and cards

Prestige is optional. There are 11 themed paths, each containing 3 unique fixed cards. The first ten selected concepts are Boss Hunter, Hunting Expedition, Collection Contract, Masterwork, Arsenal Builder, Regional Mastery, Challenge Hunt, Prestige Offering, Mission Specialist and Trophy Expedition; names/content remain authoring labels. The eleventh is Offline. There are 33 card awards; this does NOT require 33 resets.

A path groups cards. An opportunity is one discovered one-use challenge belonging to that path. Plan three distinct opportunities per path, not repeatable copies of one task. Discovery shows YOU DISCOVERED A PRESTIGE with See details, explaining requirements, steps and available cards. Discovered knowledge survives prestige so the player can pursue it later. The robot/boss counts discussed were examples, not mandatory final tasks.

Eligible opportunities track automatically without acceptance or activation. Following one merely pins the next step; unfollowing does not stop progress. Opportunities may advance concurrently. Explicit sequence restrictions may reset incomplete sequences when broken. Completed opportunities remain ready while the player continues farming.

Mission Specialist now tracks an automatic sequential mission chain alongside regular missions. Earlier event activation, pausing and replacement proposals are superseded.

The player can bank multiple completed opportunities. When prestiging, resolve one card choice per completed opportunity before resetting the run ONCE. Each choice offers only remaining cards from its path: 3, then 2, then 1. Same-path choices in the same batch immediately exclude earlier selections. No duplicate cards or duplicate-card upgrades. Consumed opportunities disappear from active opportunities but retain completion history; a completed path cannot award further cards.

Save the pending batch and choices durably; resume after interruption without duplicate grants or an early reset. The final transaction must be idempotent. Detailed cancel/commit behavior is an engineering contract to finalize before coding.

Three-card combos grant a small permanent extra bonus once: 11 same-path combos and 6 mixed-path combos, with missing-card/path previews. Exact cards, opportunity requirements and combo values need a complete authored catalog, not another assumption that examples are final. Target first opportunity around 1–2 hours without requiring all maps. World completion and all-card completion are separate milestones; continued farming remains possible.

## Prestige reset boundaries

Keep cards, unlocked combo bonuses, discoveries, consumed-opportunity history, permanent automation/capacities, rewarded main objectives, settings and offline-path lifetime progress. Clear run items and their progression, currency/run upgrades, temporary boosts/combat state, unfinished ordinary opportunity progress and old run missions. Banked opportunities being redeemed are consumed through the batch transaction, not discarded before choices resolve. Clear bindings/focus/auto-sell selections as appropriate to avoid unintended actions after restarting; retain purchased capabilities.

World gates/travel reset specifics remain open. Preserve a single explicit reset matrix during implementation; do not inherit the old first-Death-kill/random-card prototype rule.

## Offline rewards and path

Initial earnings cap 5 hours, permanently upgradeable to 48 hours. Use authored fixed earning rates improved by separate upgrades, not measured recent combat performance. Coins/gems available initially; unlock offline gear, outfits and consumables separately. Eligible item identities must currently be owned in inventory; an old progression record with zero stock is insufficient. Duplicate stacking and approved auto-sell behavior apply. No offline skill drops initially.

Offline earnings do not advance regular missions or other prestige opportunities. Only Offline-path objectives receive their own offline credit. Time beyond the earnings cap still counts toward offline-time objectives.

Offline opportunities: 72 hours cumulative offline time, 24 hours continuous offline time, and an authored total-offline-earnings threshold. Their accumulated progress does not reset on prestige. Each is one-use and awards one of the three remaining Offline cards. Define the earnings metric/threshold and clock/claim rules with the numerical offline table before implementation.

## Skills and spell assets

Skills are nonconsumable inventory items using the shared gear/outfit inventory with a skill filter. Equip one skill initially; upgrades expand to three slots. Merge/evolve through the same identity, spare-copy and tier rules as gear. Skills and their merge/evolution progress reset on prestige; purchased equip-slot and per-slot automation capabilities remain permanent.

Specific enemies drop specific skills instead of gear and visibly use those skills. Introduce two skill families per section, with exact enemies depending on the final world roster. Auto-use belongs to the equip SLOT, not the skill identity, like consumable slot automation. No mana; manual and automatic casts share cooldown. No duplicate equipped versions of one family, and swapping cannot bypass cooldown. Merge/evolve increases strength; upgrades may improve cooldown with a bounded minimum.

| Skill | Included VFX | Included SFX | Approved role |
|---|---|---|---|
| Arcane Focus | cast | cast_01 | Temporary self attack-damage buff; auto only in combat |
| Arcane Strike | impact | impact_01 | Heavy hit on current target |
| Fire Burst | fire_impact | fire_impact_01 | Target and nearby damage |
| Frost Burst | ice_shatter | ice_shatter_01 | Nearby damage and slow |
| Lightning Strike | zap | zap_01 | Fast single-target attack, short cooldown |
| Heal | heal | heal_01 | Self heal; auto below 80% health |

Casting needs valid live state/targets. No unlimited buff stacking. Stop Heal's source loop after the intended presentation duration; looping art does not imply recurring healing. Authoritative effects occur once per cast independently of VFX frames/audio. Radius, damage, durations, cooldown minima, drop assignments and upgrade costs remain tuning-table work.

## Production gates

English-only development is deliberate; the 20-language release list exists but translations are not release-ready. Require actual phone layout/touch, performance under crowded spawns/spells, long idle sessions, lifecycle/save interruption, clock rollback and transaction tests. The archived tests ran Godot 4.6 Linux headless, not the declared 4.7 engine or a physical Android device. Existing boss-loadout balance failure remains unresolved. Source assets are present for design work; licensing evidence for some legacy/new generic sounds still needs completion. See the current audit for exact findings.
