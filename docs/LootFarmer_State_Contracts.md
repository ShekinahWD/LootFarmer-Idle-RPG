# LootFarmer — State and Reset Contracts — Change 6

These contracts are implemented in Change 4 and exercised by the campaign/content probes; device and interruption-at-OS-write checks remain release gates. Approved reset decisions are explicit; engineering defaults are labelled below.

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
| Automation bindings / toggles / farm focus | Retain purchased capabilities and explicitly approved per-skill-slot auto toggles. Clear item/equipment/farm targets and consumable bindings; regular mission-auto toggle resets. |
| Pending casts / cooldowns / temporary buffs / ground drops | Clear |
| Tutorial mode / completed lessons / acknowledged introductions | Keep; reset on Hard Reset |
| Settings / audio / language / accessibility | Keep |

Teleport is rejected during combat, death, pause, suspension and prestige selection. Respawn is not a travel action. Death and ordinary travel retain progression, keys, exploration and purchases. Hard Reset clears every progression state including permanent keys and cards, but retains settings. Final mission is never paid twice. After world completion, future runs may fight final boss again once the stage is reached because keys remain owned.

## Durable prestige batch (engineering contract)

Before entering selection, snapshot all ready unconsumed opportunities and eligible cards under a transaction id; freeze gameplay. Cancel is allowed before first confirmed card choice only. Persist choices sequentially; each chosen card is excluded from subsequent choices immediately. If interrupted, resume that exact batch and next choice, not normal gameplay. Only after all choices, atomically commit card grants, opportunity consumption, combos and the one run reset. A committed transaction id cannot be applied again. Grant/reward/animation are separate operations. An inconsistent choice batch must never duplicate a card; invalid development profiles follow the documented reset policy. No opportunity may be added during selection.

## Offline accounting (engineering contract)

Snapshot fixed rates, duration cap, category unlocks and positive-stock eligible ids at departure/suspension. Use elapsed UTC, clamp negative elapsed to zero; exclude foreground pause and card-selection time. Persist a processed-until timestamp and settlement id. Settle once before allowing prestige or item mutations on resume; UI summary is a receipt, not a second reward button. Time beyond cap contributes only to offline-time counters. Continuous absence is measured per interval, reset by return; cumulative time and income are lifetime.

Fractional currency is retained. Per-category fractional item-credit remainders accumulate; whole item credits choose uniformly among eligible ids using persisted RNG/settlement results. If a category had no eligible ids at departure it earns no item credits. No offline chaining into newly evolved identities or offline merges before settlement. Tags `offline`, `mission_reward`, `online_drop` prevent event recursion. Offline grants do not advance ANY non-offline opportunity, even inventory-collection checks; the latter count tagged online acquisitions. Owned offline copies may later be used in ordinary online actions, such as an explicit merge, which is a new online action.

Clock rollback: no negative rewards and never lower the processed timestamp; resume earning after time catches up. Forward jumps remain a local-clock limitation in this offline game; capped income and once-only settlements bound currency awards but cannot prove actual absence. No network-time dependency is introduced. Test rollback, forward changes, timezone/daylight changes and process death around each write.

## Fog and map contracts

One stage-id discovery store under game save schema 7. Fog layout revision 1 invalidates only discovery when the authored layout revision changes. Discovery-only mode, 24-unit cells, source radii and refresh cadence are owned by resources/game/fog_rules.tres. Implemented algorithm: unobstructed circular reveal, no wall occlusion; player base radius 144 world units, camp 192, each up to double. Reveal cells intersected along continuous movement, not teleport segments. Camps remain reveal sources after unlock. A spawn site is discovered when its authored marker cell is revealed by an eligible source. A visible actual enemy can be inspected even when map-marker rank is low; map upgrades regulate map intelligence only. Stat/drop unlocks still apply.

Known spawn markers do not show remote live HP or respawn state. Unknown locations cannot be clicked, searched or targeted through the map. Auto-farm selects only discovered unlocked-stage sites; offline never reveals them. Gate totals and key checklist identities may be public mission information without showing coordinates. Basic map has no enemy markers; higher detail tiers expose eligible known sites only. Defer inactive-map rendering; update stored camp reveal on purchase, not each frame. Initialize disclosure before first draw. Revisit/death/load restore explored state; prestige clears it.

## Item atomicity and quantity power

Check ^100, quantity >=101, final-tier cap and successor capacity before consuming anything. Evolution reduces source quantity by 100 and adds one successor in a single saved operation. Existing successor roll/merge progress is retained. Quantity power is computed from current quantity, not saved as an accumulated permanent stat. Consuming a potion reduces quantity before the next use; its current use snapshots potency once before decrement. Offline grants, evolution, manual use and merge use the same getter. Equipped-only and stored-30% contributions must not double count an identity.

## Required focused acceptance

Fault-inject before/after each prestige choice and final commit; verify one reset and one grant. Validate same-path multi-opportunity batches, all 33 unique cards and 17 combos, persistent keys with reset gates, final quest already rewarded, unclaimed mission reset, local midnight claim ordering, offline provenance and no double settlement. Exercise copy bonus gain/loss, tier 7 surplus, evolution output-full rollback, family cooldown swap, cast/death cancellation, six actors at every fourth spot, and fog hidden-marker input. Perform phone touch/performance acceptance separately from headless logic checks.

## Change 4 implementation notes

`LootSimulation` owns the save section; `campaign.gd` operates on that same state. Outer save version 2 and game schema 7 are current. Old development schemas deliberately reset progression, retain available settings and immediately remain writable; no legacy migration is promised. Invalid current records also recover to a fresh profile with container-level backup fallback for unreadable/invalid save containers. New profiles initialize source discovery before presentation. JSON loading normalizes numeric IDs, stage keys and integer membership arrays before validation. Fog keys must lie within authored map bounds. Tests exercise actual disk serialization and reload, not only in-memory snapshots.

Tutorial mode, completed lessons and acknowledged introductions persist through prestige; Hard Reset clears them. Failed writes continue to report failure; they do not silently report success. Atomic temporary-file replacement and backup behavior are retained. An injected read-only write tests transaction rollback.

Camp and stage travel call the same travel_reason query used by buttons. Inactive worlds retain enemies and pickups with timers frozen. Save snapshots retain the departure timestamp while suspended. Offline settlement, claims, submissions and card commits roll back in-memory mutations on save failure. Offline settlement also rolls back RNG. Rewards are credited before the receipt is shown.

Per-encounter consumable restriction records first hostile contact, clears on death/leash, and disqualifies only that encounter. The discovering kill cannot retrospectively prove the restriction. Per-opportunity online collection credits decrease when copies are spent. Online currency spending credit also decreases on purchases; offline and mission grants cannot create that credit.

## Change 6 contracts

- **Prestige gate:** `campaign.prestige_block_reason()` returns the gameplay lock, `NO_READY_PRESTIGE`, or `PRESTIGE_GATE` while `unlocked_stage < progression.prestige_gate_stage` (3). `begin_prestige()` validates it; the UI disables the pinned Prestige action with the same reason. Discovery, readiness and offline counters are unaffected. Card choices inside an active batch are not blocked by the batch's own `PRESTIGE_IN_PROGRESS` lock.
- **Presentation after commit:** `milestone(kind, id)` is emitted for discovered/ready opportunities, stage unlocks, each saved card choice and the final reset, only after the save succeeded. Celebrations are presentation only and never replay on reload; `new_profile()` emits `reset`, which clears queued banners and toasts.
- **Fog layout revision 2:** moving encounter sites bumps `fog_rules.layout_revision`. Loading a revision-1 current-schema save resets explored cells and discovered sites once (documented mechanism) and stays writable. New profiles use the rule's revision (Change 5 hard-coded 1, which would have wiped exploration on every load after a bump; probe-covered).
- **Re-homing:** on load, saved enemies (current stage and inactive stage worlds) whose home differs from `spawn_home(group, variant, index)` move to the authored home, with aggro cleared.
- **Recovery:** `campaign.rest_rate()` is 0 in combat, `rest.field` elsewhere, `rest.camp` within `rest.camp_radius` of an owned camp in the current stage. Applied in the simulation step only.
- **Seen prestige discoveries:** opening the Prestige panel records `op:<id>` / `op:<id>:ready` in `tutorial.seen` (kept by prestige, cleared by Hard Reset), which drives the gold discovery badge.
- **Regional exploration:** area uses `fog_rules.cell_size` (24) to match the stored cells; Change 4/5 counted 48-unit blocks and accepted about 22.5% real exploration as 90%.

## Change 8 contracts

- **Prestige entry:** `prestige_gate_reason()` returns `PRESTIGE_LOCKED_FIRST_BOSS` until the first boss has been defeated once: `group_kills` of the group named by `progression.prestige_unlock_boss` (`boss-snowman`, Winter I; `prestige_unlock_group()` resolves its index) is above 0. `group_kills` is kept by prestige, so the system never relocks. Regular kills do not open it. `prestige_block_reason()` then requires a ready opportunity (`NO_READY_PRESTIGE`) that can still award a card (`NO_CARD_AVAILABLE`). The batch snapshots `awardable_ids()`: ready ids in order, each taking one unowned card of its path. The Winter II stage gate is removed.
- **Fog:** `explored` cells (saved) come from the player's 48-unit reveal and from camp reveals. Vision (`vision_radius()` = reveal × `vision_factor`) is computed live from the living player and never saved. `can_see()` = explored or in vision; it decides world drawing, targeting, pickups, spell effects and the guide's world targets. Vision never discovers a spot.
- **Spots:** `discovered_spots["g:v"]` (bosses use variant 2) is set when a spot's home cell is explored, a living actor of the spot stands on an explored cell, or the player kills one of its enemies. `discovered[g]` (type known) follows the first found spot. Map markers, map taps and Focus use spots; enemy panels and upgrades still use the type.
- **Camps:** `camps_known[stage]` holds camps sighted within `camp_sight_radius`. Owned camps are always known. A sighted camp reveals `camp_footprint_radius` once. Unlock, select and taps need a known camp.
- **Merges:** `merge_cap(id)` is 500 for outfits and skills (`copy_growth`) and 100 otherwise. `merge_levels()` is linear to 100, then logarithmic. The stock bonus applies at the item's own cap. Validation uses the per-item cap. Outfits and skills never evolve (`next` empty); legacy evolved tiers stay valid items.
- **Prestige keep list** adds `skills_seen`.
- **Migration:** see docs/LootFarmer_Change_8_Notes.md, section Saves. Older current-schema saves derive the three new fields on load and are never reset for them.
