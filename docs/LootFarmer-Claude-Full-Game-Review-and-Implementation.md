# LootFarmer: full game review and implementation brief

## Assignment and authority

Review the complete LootFarmer game, decide what needs improvement, and implement those improvements. This is an implementation assignment, not a report-only audit. Prioritize **simplicity, readability, responsiveness and enjoyable progression**. A smaller, clearer solution is preferable to more controls, decoration, abstraction or explanation.

Work from the actual latest project in your workspace. Inspect its current GDD, state/balance contracts, asset registry, reusable development playbook and applicable project instructions before changing it. The supplied `lootFarmer(7).zip` predates the separately delivered `LootFarmer-5-corrections-changed-files.zip`. Determine whether those corrections are already applied. Do not overwrite newer work with the older attachment or assume a patch was installed. If the latest baseline cannot be established, ask one focused question before editing conflicting files.

The user authorizes implementation through the accompanying “write code” message. Exercise judgment on layout, tuning, performance and implementation within the approved game. Do not stop after listing recommendations or ask for approval for each ordinary improvement. Ask when an actual ambiguity would change an approved core mechanic or requires an unavailable asset. Preserve unrelated work.

The additional user requirements below supersede conflicting earlier tuning: first prestige must require at least one hour of meaningful first-run progression, rewards must justify the reset, and prestige choices must be presented as actual visual cards.

This document defines the work; it does not certify the existing game. Previous test counts and “fixed” statements are evidence to investigate, not proof that the experience is good.

## 1. Design direction: simplicity first

Use the three attached reference screenshots as brief examples of clear visual hierarchy:

- A readable playfield with relatively few competing HUD elements.
- Recognizable item icons arranged consistently with clear grouping.
- A prominent primary action where a real primary action exists.
- An item comparison that brings identity, important stats, differences and relevant actions together.
- Strong separation of gameplay, navigation, information and actions.

Borrow these principles, not the reference game's mechanics, assets or exact styling. Do not introduce its Loot button, extra equipment slots, selling, rarity system, promotional captions or exaggerated button sizing into LootFarmer merely because they appear in the examples. Selling was removed from the campaign design; do not restore it from older prototype documents or screenshots.

Use only existing owned assets, including the project's Kenney Fantasy UI and PixelPlains resources. Do not draw or generate replacement art, import screenshot art, invent icons, or replace the established theme with generic flat UI. Use supplied arrows/pointers for tutorial guidance where available; verify the asset inventory rather than assuming a path exists. Report a genuine asset gap and use a permitted existing-asset highlight if needed. Code-driven layout, clipping and functional fog masks are distinct from creating decorative art.

Keep text concise, with familiar labels. Icons must help identify meaning, not add decoration. Keep important values readable without opening several extra screens. Avoid unnecessary nested panels, repeated borders, redundant labels, excessive empty space, animation clutter and new management systems.

## 2. Audit every panel and UI state, then improve it

Build a complete inventory from actual routes, scenes and interactions. Cover all panels and transient UI, including anything not named here:

| Surface | Required evaluation |
| --- | --- |
| Main HUD | World visibility, HP/XP, currency, joystick, skill controls, zoom, minimap and navigation |
| Inventory and equipment | Equipped state, tiers, quantity, merge level, filtering, capacity and usable touch targets |
| Item details and comparisons | Content-sized layout, effective stats, meaningful deltas, equip/use/merge/evolve/reroll actions |
| Player/global upgrades | Grouping, benefits, costs, availability, progression disclosure and opening latency |
| Enemy information/upgrades | Type/variant clarity, actual drops/stats, upgrade ordering, farming selection and disabled reasons |
| Achievements | Progress, earned effects, claim state, compact presentation and combat visibility |
| Missions | Main/regular/final objectives, understandable targets, progress, rewards and claim feedback |
| World/travel/camps | Destinations, discovered/locked/selected state, purchase/selection distinction, travel restrictions |
| Minimap/expanded map | Discovery consistency, useful markers, input, scale and readable placement |
| Skills and supplies | Cooldown, eligibility, potency, automation and distinct heal/potion roles |
| Prestige/cards | Eligibility, consequences, comparisons, pending choices, confirmation and return path |
| Statistics/offline receipt | Useful summaries, effective values, provenance and no redundant detail |
| Settings/pause/reset | Clear grouping, input locks, confirmation and safe return to gameplay |
| Guidance and feedback | Tutorial, tooltips, notifications, errors, floating values, death/respawn and confirmations |

For each surface inspect empty, populated, locked, affordable/unaffordable, selected, completed and overflow states where applicable. Include long names, large numbers, higher tiers and full inventories. Record what was wrong, what changed and the evidence that it works. Do not write identical generic “verified” rows for every panel.

### Content-sized panels are mandatory

The current item-detail window wastes height. Fix it and audit every other panel for the same problem.

- Determine panel height from actual content plus sensible padding, capped to the safe viewport. Do not automatically fill the map area or screen.
- Short item details, confirmations and small menus should be compact. Long lists may use larger panels when useful.
- Enable scrolling only when content exceeds the maximum available height. Keep the important action reachable without excessive scrolling.
- Preserve stable sizing while values change. A disabled reason, currency tick or progress update must not repeatedly resize the panel or move a button under a finger.
- Do not achieve compactness by shrinking fonts or touch targets. Reorganize information and remove redundancy first.
- Use consistent spacing, alignment, close/back placement and action hierarchy. Avoid nested scrolling and accidental world input through menus.
- Inspect on multiple portrait aspect ratios and safe areas. Mouse-only interaction is insufficient evidence of touch quality.

### Browse items without closing details

Add visible left/right arrow controls, using owned assets, to move directly between the previous and next item while item details remain open. Follow the inventory's current category/filter and stable display order; make the selected item clear. Keep the arrows and primary actions in consistent positions while content changes. Handle the first/last item, a single item, empty categories, consumed items and evolution safely. Choose and document a consistent boundary behavior. Do not create stale callbacks that act on the previously inspected item. Rapid browsing must remain responsive and must not rebuild the entire inventory or reload assets unnecessarily. Validate equipment, supplies and skills, including item removal while details are open.

### Notification contrast on every environment

The user reports white notification text disappearing against the white winter map. Audit notifications, floating values, world labels, tutorial text and transient messages against every seasonal background and bright VFX. Use an appropriate owned-asset backing, strong contrast, text outline/shadow and deliberate color hierarchy as supported by the established theme. Color alone must not carry meaning. Preserve compactness and world visibility while ensuring information can actually be read on a phone. Capture the winter-map case explicitly; testing only dark backgrounds is insufficient.

## 3. Make the tutorial genuinely guided across screens

The user reports being told to buy a camp, opening World, and then losing all direction. A line of text plus an occasional outline is insufficient.

Implement a state-driven sequence that always explains and visually identifies the next required action. Use a clear supplied arrow/pointer and/or an obvious owned-asset highlight. Recompute its target from the actual visible control, including after resize, scrolling, panel transitions and layout changes. Never point at hidden, disabled, off-screen or unrelated controls.

For the camp lesson, guide the full legitimate route: reach/discover an eligible camp when needed, open the relevant World/map/travel surface, identify the correct destination or entry, open its details, purchase when affordable, and explain the resulting unlock/selection. Determine the correct route from gameplay rather than inventing a menu sequence. Do not reveal undiscovered map locations through a tutorial marker. If coins or discovery are missing, show a specific attainable next action instead of an impossible purchase instruction.

Apply the same end-to-end treatment to combat, pickup, equip, merge, upgrades and later skills/group aggression. Advance on successful state changes, not merely clicking a button. Support the player doing actions ahead of the tutorial. Prevent lessons that require a lucky drop from leaving the player without useful guidance.

Keep Guided, Basic/Overview and None meaningful. Guidance should resume after unrelated panels, pause, interruptions and reload without duplicate prompts or lost progress. Related panels must continue the active lesson. Keep one owner for guidance arbitration; prevent competing hints and blocked controls. Preserve documented prestige/reset behavior. Do not add a complicated tutorial framework or force a different game mode to solve these issues.

Acceptance includes a fresh-profile walkthrough from movement through camp purchase without guessing, including the exact World-panel transition reported by the user.

## 4. Investigate the first boss and the complete world layout

The user reports the first-map boss appearing next to the player. Reproduce from a fresh production-style profile and inspect player spawn, selected camp, boss spawn, movement/leash, camera and any debug/capture setup. Do not treat a staged screenshot as proof of the real starting layout.

Source lead, not a final diagnosis: attached ZIP 7 defines the first arrival at approximately (480, 883.2) and the snowman boss center at (691.2, 729.6). Verify current runtime positions and navigable approach. Prior capture tooling deliberately moved the player near the boss for an arena screenshot; distinguish that fixture from production initialization.

Make the starting area teach ordinary encounters safely before the boss. Arrange the first boss as an intentional later encounter with a readable approach and distinct arena, rather than a surprise beside the arrival point. Choose an appropriate location/route using the existing map and owned scenery; do not merely move it to an arbitrary corner or hide it behind unexplained UI restrictions. Keep boss routes, camps, fog, mission goals, selection and spawn data consistent.

Review all stages for encounter spacing, navigation clarity, camera framing, visible landmarks, farming areas, camp usefulness and escalation. Most bosses should clearly exceed normal enemy size; retain deliberate exceptions only when readable. Keep art scale, hit/pick bounds, health bars, weapons and effects consistent. Skill visuals should remain below actors as requested without obscuring telegraphs or making attacks unreadable.

### First boss difficulty and intentional farming boundaries

The user defeated the first boss after roughly ten minutes and found it too easy. Investigate the actual fresh-run loadout, purchase route, drops, incoming damage, recovery and attack behavior that allow this. Rebalance the encounter and progression leading to it so victory requires meaningful preparation and feels earned. Do not merely increase HP into a repetitive damage sponge or impose an unexplained time lock. The one-hour requirement below applies to first prestige; the user has not specified an exact first-boss minute target. Choose and justify an appropriate boss milestone within the campaign.

Enemy groups and equipment variants must be spaced so farming one does not accidentally acquire a neighboring group. Evaluate actual positions together with idle acquisition range, target chaining, movement, spawn spread, leash, later assistance and auto-farm selection. Keep the selected type/variant intentional; do not silently weaken requested targeting to compensate for crowded placement. Test staying in a farming spot through repeated deaths/respawns and target deaths, plus moving deliberately to another group. Keep early separate encounters and later intentional group assistance distinct. Apply this review across all maps rather than moving only one problematic spawn.

## 5. Evaluate and rebalance the whole game

Review the connected economy and combat progression, not just individual values. Preserve approved mechanics and the prototype's approachable opening. First two enemy types must not attack in groups; early skills and group assistance must be deliberately introduced and taught later.

Evaluate enemy HP/damage/cadence, variants, aggression, leash/recovery, bosses, player growth, gear contributions, drops, currency sources/sinks, upgrade prices/caps, inventory pressure, merging/evolution, skill scaling/cooldowns, consumables, automation, respawn, camps, missions, offline rewards and prestige. Check descriptions against actual behavior. Respect existing no-teleport-during-combat rules and other approved contracts.

Heal and potions must each have a reason to exist throughout progression: reusable sustain versus meaningful immediate recovery. Inspect actual effective healing with HP growth, equipment, merges, evolution, stock bonuses and cooldown upgrades. Check whether skill healing makes consumables pointless or consumable supply trivializes all damage. Current Change 5 starting values, if present, are 6 HP/18 seconds with a 12% HP skill cap and 25 HP/2 seconds for a potion; these are tuning inputs to evaluate, not immutable balance targets.

Use natural progression and representative weak, typical and strong loadouts. Include the opening minutes, first upgrade/camp, first boss, stage transitions, introduction of each skill family, mid/late game and prestige. Measure time-to-kill, survival, meaningful purchase intervals, drop droughts and required repetitive farming. Identify dead purchases, dominant choices, traps and exponential walls.

Use deterministic simulations where useful, but also play the real flow. A max-level, fully upgraded artificial loadout does not validate ordinary pacing. Derive targets from the current GDD; label any new tuning targets as proposals/decisions and record their rationale. Implement coherent changes, update related prices/rewards together, and avoid changing core systems solely to simplify testing.

### Mandatory review of every prestige opportunity and reward

The user reports unlocking prestige in under ten minutes through an early winter/first-enemy challenge without consumables, then seeing choices such as +1% critical chance, a -2% boss-damage modifier and +3% critical damage. Treat these as reported examples to reproduce and identify precisely in the current catalog, not assumed exact IDs or effect semantics. Confirm what each modifier actually affects and correct ambiguous wording.

Prestige must be a difficult, desirable milestone whose permanent reward makes resetting worthwhile. Tiny bonuses that are barely noticeable do not meet that requirement merely because they technically persist.

Audit **every individual prestige opportunity, every offered reward and their combinations**. Produce a concrete matrix with condition, prerequisites, earliest legitimate unlock route, estimated/measured effort, difficulty, reward choices, actual gameplay impact, reset cost, identified problem and implemented adjustment. Verify counts against the runtime catalog so none are omitted. Include trivial/no-consumable objectives, early routes, offline-related routes, optional bosses and opportunities that overlap or can be completed together.

- **First prestige must take at least one hour of meaningful first-run progression.** Measure from a genuinely fresh profile at normal game speed; distinguish active play, idle/offline time and accelerated test time. Challenge discovery may happen earlier, but discovery must not allow an early reset/grant. Audit the fastest plausible knowledgeable-player route as well as ordinary play so an easy side objective cannot bypass the intended milestone.
- Achieve this through worthwhile progression, prerequisites and appropriately difficult challenges, not an arbitrary sixty-minute waiting screen or empty repetitive grind. Preserve an approachable early game while making prestige genuinely earned. If exact time semantics beyond this are required by the implementation, clarify that narrow point rather than silently counting time spent in menus or paused.
- Match reward value to the real effort and everything lost on reset. Tune rewards to make a substantial, visible difference to the next run while preserving meaningful choices and long-term balance. Percentage wording alone is not evidence of strength: evaluate effective DPS, survival, progression speed or other relevant outcomes.
- Prefer clearly distinguishable benefits with an understandable purpose. Implement suitable tuning/design improvements within the existing prestige system; do not inflate every number blindly, make one option always correct, or add unrelated layers just to make rewards look larger.
- Compare the pre-reset run with the new run after each representative reward. Measure recovery to previous progress, noticeable early acceleration, later value and stacking/combination effects. First prestige can be slower than later ones; do not impose the initial one-hour expectation on every subsequent prestige without a design reason.
- Preserve atomic choice/grant/reset behavior, persistent ownership, eligibility and no-duplicate rewards. If several opportunities are ready, make the actual batch and total reward clear before resetting. Update tests and documentation together with intentional condition/reward changes.

### Prestige must look like cards and feel like an achievement

The current presentation reportedly uses ordinary option buttons where actual prestige cards were required. Implement a genuine card-choice presentation using owned card/frame/icon assets: distinct card identity, prominent meaningful benefit, concise explanation and clear selected state. The card may be clickable, but a generic text button is not an acceptable visual substitute. Keep choices easy to compare on a phone without tiny type or excessive scrolling. Clearly explain what is kept, what resets and what the selected reward changes before irreversible confirmation.

Give discovering a prestige opportunity, completing its challenge, choosing a reward and committing prestige appropriate, distinct feedback. Discovery and achievement currently feel too plain. Create a brief celebratory presentation with strong color hierarchy, owned icon/card imagery and restrained animation; supplied sparkle/spark effects and semantic audio may be used where available. This request authorizes richer feedback, not newly drawn or generated art. Verify available assets before using them.

Keep the celebration readable against winter terrain, uncluttered and responsive. It must not stall gameplay, obscure an urgent interaction, replay rewards on reload or require a long forced animation. Queue important messages so they do not overlap; handle pause, panels and reduced-motion/accessibility settings where available. Leave a clear persistent way to inspect the newly discovered or ready opportunity after the celebration ends. Reserve this intensity for major milestones so prestige stands out from ordinary loot.

Validate actual rendered card choices and the discovery/completion celebration, not merely scene instantiation. Include one natural first-run prestige walkthrough, the earliest-route timing evidence, before/after reward comparisons and durable save/reload tests in the handoff. If a complete timed session cannot be run, state that exact validation gap rather than claiming the one-hour goal was proven by catalog inspection.

## 6. Profile and improve performance, especially UI opening

The user reports a noticeable delay opening upgrades. Reproduce and measure before changing the implementation. Separate cold opening, warm reopening, refresh while open, scrolling, buying repeatedly and returning to gameplay. Compare small and large inventories/unlock sets. Capture hardware, engine/build, scenario and profiling method so results can be repeated.

Inspect main-thread work, control creation/destruction, layout invalidations, text measurement, resource loads, signal reconnection, per-frame polling, save serialization, redraws, actor updates, VFX and memory growth. Source leads in Change 5: the sheet layout fills the map region, and UI reconciliation still builds temporary control trees and traverses properties/signals. Profile those paths; do not assume either is the only cause.

Prefer simple reusable scenes, cached immutable resources, persistent controls and targeted updates when relevant data changes. Separate structural list changes from numeric updates. Preserve button identity, focus and scroll during updates. Avoid replacing whole trees on every currency/combat revision. Virtualize or pool only when measured list sizes justify the added complexity. Do not hide slow work behind a cosmetic transition or insert arbitrary delays.

Review gameplay performance too: dense encounters, all active skills, fog/map refresh, notifications, inventory growth, stage transitions, autosave and offline settlement. Avoid frame-rate-dependent logic, stale caches and accidental signal accumulation. Repeated panel open/close should not grow nodes or memory without bound.

Use a stated frame budget and report before/after timings, including typical and worst/p95 measurements over repeated runs where practical. Target smooth 60 FPS on the intended Android hardware where feasible; distinguish desktop measurements from device results. If a handset is available, include the user's Moto G Power 5G 2024 or a clearly identified comparable device. Do not claim device performance from a headless pass.

## 7. Reconcile the full reusable playbook

Read the entire current reusable file. For each applicable requirement, connect it to actual implementation and evidence. Correct relevant deficiencies discovered during this work rather than merely recording them as future tasks. Give explicit reasons for non-applicable examples; do not import worker, city-building or army mechanics into this game to match examples literally.

Pay particular attention to mobile sizing/scrolling, content-sized panels, state-driven tutorial arbitration, owned-asset UI, editor-visible composition and configuration, single state ownership, stable UI updates, input/pause, source-based fog discovery, save/reset, offline accounting, tests and honest evidence boundaries.

Fog must follow LootFarmer's documented mode. Verify player/camp sources, camera invariance, continuous movement, teleports, unknown markers, stage bounds, reload, layout revisions and reset. Do not mix another game's current-vision model with permanent discovery-only fog.

Old development saves do not require preservation. Current-version saves absolutely must save/reload correctly without requiring Hard Reset. Check actual disk roundtrips, malformed-save recovery, backup behavior and truthful write failures. Do not wipe valid current saves to conceal persistence bugs.

Expose important layout/visual/tuning settings in appropriate scenes/resources where practical. Keep runtime behavior in clear code; avoid both a monolithic UI builder and unnecessary frameworks. Update the game's documents to match implemented decisions. Add only genuinely reusable lessons to the reusable file, in their owning sections.

## 8. Execution and deliverables

1. Establish the current baseline and read the authoritative documents. Inventory all systems/panels and reproduce reported faults.
2. Record a concise prioritized plan, then proceed with implementation. Start with broken guidance, unsafe/unintended opening encounters and measured stalls; apply a consistent UI direction across the whole game.
3. Validate incrementally with relevant tests and actual rendered interaction. Do not delete failing checks to make results green without explaining a legitimate changed contract.
4. Complete a fresh-player walkthrough and representative later-game sessions. Inspect before/after screenshots for each changed panel family, including compact item details with previous/next arrows, tutorial transitions, winter notification contrast, actual prestige cards and milestone celebrations. Check long-list and low-resource states.
5. Finish with a full coverage matrix: system/panel, issue, decision, implementation, evidence and any remaining limitation. Distinguish source inspection, automated behavior, rendered review, manual play and physical-device evidence.

Deliver the implemented project changes, updated GDD/balance/state/UI/asset documentation as applicable, concise findings, a rationale for tuning/layout decisions, the complete prestige opportunity/reward matrix and first-prestige timing evidence, first-boss and group-spacing results, before/after performance measurements and reproducible verification steps. Choose appropriate project paths based on the repository rather than introducing a parallel documentation structure unnecessarily.

If handing back a ZIP, include only changed/new project files at their project-relative paths, with no extra wrapper folder, and state the exact baseline and application instructions. Exclude caches, credentials, keystores and unrelated build products. Do not publish, sign a release or change monetization/services as part of this task.

Do not declare “everything follows the playbook” from test counts alone. Finish all feasible authorized corrections, identify genuinely blocked work precisely, and do not use vague audit disclaimers as a substitute for implementation. The final result should feel simpler, clearer and smoother to play, with evidence supporting both the improvements and their limits.
