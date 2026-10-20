# LootFarmer — Design audit v0.3

Date: 2026-10-18. Result: DESIGN APPROVED. A01/A02/A03 corrected by user; A04–A18 approved. Signing was explicitly deferred by the user for prototype development; it remains a release obligation.

The user approved the consolidated GDD. The following table is the authoritative closed audit; balance inputs remain adjustable under delegated authority.

## Approved contradictions resolved

| Earlier statement | Authoritative outcome |
|---|---|
| Only joystick control | Joystick is direct movement control; management and consumable buttons also exist. |
| Outfits have no visual rank | Merging never changes outfit appearance; later complete costumes can have better base stats. |
| Immediate-use dropped potion / shared pool | Separate consumable inventory replaces pool; dropped consumables must be collected. |
| Potion at ≤80% | Latest instruction is strictly <80%; exactly 80% cannot use. |
| Unlimited merges | Latest approval caps every item type at ^100. |
| ^100 weapon immediately transforms/resets | Replaced by approved evolution costing 100 spare copies while retaining ^100 source. |
| Per-copy random rolls | One shared roll and merge level per identity; survives zero inventory quantity. |
| Permanently merged | Persists through use/sale/reload, but prestige explicitly clears item progression. |
| Prototype clears progression | Never: normal saves persist. Only confirmed reset/prestige clears its defined scope. |
| No pause in menus | Panels remain live; explicit pause stops simulation. Background suspension is separate. |
| Offline omitted | Deferred from first playable only; required in full game. |
| Prestige cards temporary | Permanent accumulation across runs; Hard Reset clears them. |

## Approved missing-state resolutions

Approved on 2026-10-18. A01–A03 use the user’s final corrections; A04–A18 were approved as a batch.

| ID | Gap | Approved rule |
|---|---|---|
| A01 | Currency-upgrade scope | A group owns its upgrades and all members receive them. Each enemy has an individual runtime identity and independently rolls its rewards when killed. No group-shared kill roll. |
| A02 | Currency collection | Credit currencies immediately on enemy death, with no ground pickup or inventory requirement. Coin animation is later presentation only. |
| A03 | Auto-sell selection | Select item identities in a capacity-limited list, upgradeable to mark more types. Sell selected pickups on acquisition, even at full inventory. Never bind auto-sell to slots. No retroactive stock sale. Preserve approved equipped-item protection in A04. |
| A04 | Selling equipped gear | Allow selling spare copies; reject sale of last equipped copy until unequipped. Shared merge/roll survives selling all unequipped copies. Show quantity and proceeds before bulk sale. |
| A05 | Potions and boost timing | Manual until auto-use unlocked. Every scheduled attempt checks health <80%, cooldown, quantity and alive state; unsuccessful checks consume nothing. No heal while dead. Boost reuse adds new duration and uses max(old,new) potency for all remaining duration; no weaker overwrite. |
| A06 | Prestige details | Reset other per-run upgrades (drop rates/amounts, respawn delay), active boosts and temporary world state. Keep purchased automation levels including speed/range/batch size, and all slot capacities. Clear focus target, auto-sell selections and slot bindings to avoid surprise actions in the new run; retain capabilities. Settings survive. |
| A07 | Prestige transaction | First Death kill in a run opens one entitlement. Offer persists across reload; three distinct cards. Choose -> show reset summary -> commit new run+card atomically. Cancel before commit retains old run and offer. Re-kills do not generate more offers that run. |
| A08 | Spawn and death | Start respawn timer at logical death; finish visible death independently; respawn full health at selected unlocked point. Buying a point does not auto-select it. New run uses default point. |
| A09 | Auto-return and manual movement | Manual joystick movement cancels current automatic action and focus mode; re-enable focus explicitly. If focused group is dead, wait near its area for respawns. Nonfocused pursuit still freely chains nearby targets. |
| A10 | Evolution output space | Require source quantity ≥101 and existing target stack or free slot. Reject without spending if full. Source remains equipped if it was equipped; target is not auto-equipped. New target rolls once; existing target never rerolls. |
| A11 | Final tier and cap | At ^100, stop manual/auto merge and display MAX. No evolution button without an authored next-tier mapping. Outfit/consumable caps do not imply transformations. |
| A12 | Pause/background timers | All simulation timers, including loot expiry, boosts, respawn and enemy regen, use game time. Explicit pause freezes them. Background saves and suspends; first-playable resume has no elapsed-time catch-up. Paused menu purchases/merges remain possible but auto-actions do not tick. |
| A13 | Save/reload combat | Restore consistent position, HP, enemies and timers; cancel an uncommitted attack windup on load. Never restore an already rewarded enemy alive. Pending authoritative reward pickups persist until collected/expired. |
| A14 | Hard Reset | Confirm irreversible progression deletion, cancel pending prestige, clear live state/timers, write clean profile and return to unpaused new game. Keep settings; clear progression and all cards. Works from paused/dead/completion states. |
| A15 | Boss reset | Leash/death resets boss HP and removes summoned cats, without awards for removed cats. Summon caps prevent actor accumulation. Victory grants one kill outcome; presentation cannot grant again. |
| A16 | Full inventories and duplicates | Same-identity pickups stack even when all slots occupied. New identities remain on ground. Ground pickups are collected one unit per pickup initially; visually overlapping pickups may be grouped without changing quantity/expiry semantics. |
| A17 | Consumable empty-slot binding | Retain binding to slot index; label its automation clearly. A later item placed there will inherit enabled automation. Let user disable/move binding. Empty slots spend no consumables. |
| A18 | Reroll behavior | One gem cost replaces both extra bonuses with two distinct types from eligible pool; no per-stat locks or keep-best prompt in first playable. Show this before purchase; never alter normal stats/merge level. |

## Still outside this approval package

Full-game offline economy needs its own contract before implementation: elapsed-time cap, reward rate basis, alive/dead handling, item weighting/quantity, acquisition automation interactions, pending-claim and clock rollback policy. Approved boundaries are currencies initially and upgrade-gated currently-owned inventory identities later. Do not infer that unowned or zero-quantity identities qualify merely because their progression record exists.

Final release content count, full-game completion-time target and additional weapons/consumables remain outside the compact slice. Portrait at 720×1280 is the bootstrap layout and needs safe-area/device testing. Game name is LootFarmer - Idle RPG. Source starter specifies Godot 4.7; Toolkit documents 4.7.2 Windows validation. The exact installed engine/export-template pair must be recorded locally, not claimed tested here.

## Audit verification and limitations

Reviewed current conversation decisions, current standalone Playbook sections for startup, staged GDD, localization, asset presentation/editor editability, source archive QuickPlan text and project.godot, and bundled toolkit release notes. Existing project.godot identifies “New Game Project” and Godot feature 4.7; it is not proof of a signed or physically validated baseline. Toolkit release notes identify 1.0.2 but installation integrity/runtime compatibility have not been tested.

Older reference GDDs were not used to import mechanics or numbers. If consulted at bootstrap, classify each separately into reusable engineering patterns, original-game decisions, and anti-patterns; do not silently inherit their world/economy/UI.

Bootstrap infrastructure is prepared in v0.2; no gameplay implementation, animation coverage certification, balance simulation, Android export or device validation is claimed. Design approval is complete. This historical bootstrap limit was superseded by the user’s signing deferral and successful editor check. See LootFarmer_Prototype_Status.md for v0.3 implementation evidence.

## Additional approved feature

Show the latest three acquisitions in a notification section and expand history to ten. Tap-to-expand/collapse is the chosen UI interpretation. This is part of the first playable, not yet implemented in the bootstrap.
