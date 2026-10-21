# LootFarmer — State and Reset Contracts — Change 3

These are implementation contracts, not implemented behavior. Approved reset decisions are explicit; engineering defaults are labelled below.

## Prestige matrix

| State | Prestige behavior |
|---|---|
| Stage access / gate kills / final-stage per-type kills | Clear; Winter I available |
| Arrival camps | Winter I free camp restored; later free camps become available with their stages |
| Purchased camps / selected camp | Clear purchases; select Winter I arrival |
| Explored cells / discovered map locations / map detail and radius ranks | Clear per stage |
| Collected unique boss keys / final-mission discovery | Keep; key drops active on new run if mission discovered |
| Final boss lock | Requires all 13 persistent keys and physical stage access; independent of mission reward history |
| Cards / combos / consumed opportunities / discovered opportunity descriptions | Keep |
| Unconsumed ordinary opportunity progress and readiness | Clear after rewarding the snapshotted ready batch |
| Offline opportunity counters and readiness | Keep until consumed; only one reward per opportunity |
| Rewarded main objectives / permanent achievement ownership | Keep |
| Unfinished main progress | Clear except persistent final discovery/keys |
| Completed unclaimed main objectives | Discard reward; reset to unfinished, since only completed AND rewarded objectives persist |
| Regular missions / unclaimed rewards | Clear; assign fresh achievable goals after reset |
| Currency / level / inventory / equipped bindings / merge, evolution, rolls, copy bonuses | Clear; restore authored starting profile |
| Upgrade purchases | Follow Upgrade Catalog Keep/Reset field |
| Automation bindings / toggles / farm focus | Engineering default: retain capability, clear targets and switch automation off until reconfigured |
| Pending casts / cooldowns / temporary buffs / ground drops | Clear |
| Settings / audio / language / accessibility | Keep |

Death and ordinary travel retain progression, keys, exploration and purchases. Hard Reset clears every progression state including permanent keys and cards, but retains settings. Final mission is never paid twice. After world completion, future runs may fight final boss again once the stage is reached because keys remain owned.

## Durable prestige batch (engineering contract)

Before entering selection, snapshot all ready unconsumed opportunities and eligible cards under a transaction id; freeze gameplay. Cancel is allowed before first confirmed card choice only. Persist choices sequentially; each chosen card is excluded from subsequent choices immediately. If interrupted, resume that exact batch and next choice, not normal gameplay. Only after all choices, atomically commit card grants, opportunity consumption, combos and the one run reset. A committed transaction id cannot be applied again. Grant/reward/animation are separate operations. If a legacy state has no remaining card for an opportunity, quarantine the inconsistent entry for migration rather than silently duplicate a card. No opportunity may be added during selection.

## Offline accounting (engineering contract)

Snapshot fixed rates, duration cap, category unlocks and positive-stock eligible ids at departure/suspension. Use elapsed UTC, clamp negative elapsed to zero; exclude foreground pause and card-selection time. Persist a processed-until timestamp and settlement id. Settle once before allowing prestige or item mutations on resume; UI summary is a receipt, not a second reward button. Time beyond cap contributes only to offline-time counters. Continuous absence is measured per interval, reset by return; cumulative time and income are lifetime.

Fractional currency is retained. Per-category fractional item-credit remainders accumulate; whole item credits choose uniformly among eligible ids using persisted RNG/settlement results. If a category had no eligible ids at departure it earns no item credits. No offline chaining into newly evolved identities or offline merges before settlement. Tags `offline`, `mission_reward`, `online_drop` prevent event recursion. Offline grants do not advance ANY non-offline opportunity, even inventory-collection checks; the latter count tagged online acquisitions. Owned offline copies may later be used in ordinary online actions, such as an explicit merge, which is a new online action.

Clock rollback: no negative rewards and never lower the processed timestamp; resume earning after time catches up. Forward jumps remain a local-clock limitation in this offline game; capped income and once-only settlements bound currency awards but cannot prove actual absence. No network-time dependency is introduced. Test rollback, forward changes, timezone/daylight changes and process death around each write.

## Fog and map contracts

One map-id/layout-revision discovery store. Proposed algorithm: unobstructed circular reveal, no wall occlusion; player base radius 144 world units, camp 192, each up to double. Reveal cells intersected along continuous movement, not teleport segments. Camps remain reveal sources after unlock. A spawn site is discovered when its authored marker cell is revealed by an eligible source. A visible actual enemy can be inspected even when map-marker rank is low; map upgrades regulate map intelligence only. Stat/drop unlocks still apply.

Known spawn markers do not show remote live HP or respawn state. Unknown locations cannot be clicked, searched or targeted through the map. Auto-farm selects only discovered unlocked-stage sites; offline never reveals them. Gate totals and key checklist identities may be public mission information without showing coordinates. Basic map has no enemy markers; higher detail tiers expose eligible known sites only. Defer inactive-map rendering; update stored camp reveal on purchase, not each frame. Initialize disclosure before first draw. Revisit/death/load restore explored state; prestige clears it.

## Item atomicity and quantity power

Check ^100, quantity >=101, final-tier cap and successor capacity before consuming anything. Evolution reduces source quantity by 100 and adds one successor in a single saved operation. Existing successor roll/merge progress is retained. Quantity power is computed from current quantity, not saved as an accumulated permanent stat. Consuming a potion reduces quantity before the next use; its current use snapshots potency once before decrement. Offline grants, evolution, manual use and merge use the same getter. Equipped-only and stored-30% contributions must not double count an identity.

## Required focused acceptance

Fault-inject before/after each prestige choice and final commit; verify one reset and one grant. Validate same-path multi-opportunity batches, all 33 unique cards and 17 combos, persistent keys with reset gates, final quest already rewarded, unclaimed mission reset, local midnight claim ordering, offline provenance and no double settlement. Exercise copy bonus gain/loss, tier 7 surplus, evolution output-full rollback, family cooldown swap, cast/death cancellation, six actors at every fourth spot, and fog hidden-marker input. Perform phone touch/performance acceptance separately from headless logic checks.
