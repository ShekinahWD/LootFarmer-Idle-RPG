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
| Upgrade purchases | Every gem-funded upgrade is kept (Change 11, `simulation.upgrade_kept`); coin upgrades follow the Upgrade Catalog Keep/Reset field. Kept Spawn Amount re-spawns its extra actors in the fresh world at once |
| Supply mastery (`supply_found`) | Keep (Change 11); supply stock, buffs and supply-slot bindings clear with the inventory |
| Automation bindings / toggles / farm focus | Retain purchased capabilities and explicitly approved per-skill-slot auto toggles. Clear item/equipment/farm targets and consumable bindings; regular mission-auto toggle resets. |
| Pending casts / cooldowns / temporary buffs / ground drops | Clear |
| Tutorial mode / completed lessons / acknowledged introductions | Keep; reset on Hard Reset |
| Settings / audio / language / accessibility | Keep (Change 12: music_volume, sfx_volume, mute_gameplay, mute_special) |

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

Check ^100, quantity >=101, final-tier cap and successor capacity before consuming anything. Evolution reduces source quantity by 100 and adds one successor in a single saved operation. Existing successor roll/merge progress is retained. Quantity power is computed from current quantity, not saved as an accumulated permanent stat. Consuming a potion reduces quantity before the next use; its current use snapshots potency once before decrement. Offline grants, evolution, manual use and merge use the same getter. Equipped-only and stored contributions (weapons 30%, outfits 15% since Change 9) must not double count an identity. Outfit milestones (Guard, Recovery, +10% HP) come only from the worn outfit and are derived from its saved merge level; nothing new is saved.

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
- **Merges:** `merge_cap(id)` is 500 for outfits and skills (`copy_growth`) and 100 otherwise. `merge_levels()` is linear to 100; past it, outfits add `outfit_tail_rate` (0.5) levels per copy (Change 9) and skills follow the logarithmic tail. The merge level is clamped to the item's cap. The stock bonus applies at the item's own cap. Validation uses the per-item cap. Outfits and skills never evolve (`next` empty); legacy evolved tiers stay valid items.
- **Prestige keep list** adds `skills_seen`.
- **Migration:** see docs/LootFarmer_Change_8_Notes.md, section Saves. Older current-schema saves derive the three new fields on load and are never reset for them.

## Change 10

- `gear` has exactly 3 + `upgrades.gear_slots` entries (at most 70); `valid_snapshot` requires it and `normalize_snapshot` enforces it (campaign.clamp_equipment_slots). Development saves need no migration (Playbook §61.1).
- The Farming Guide stores nothing: entries derive from `upgrades.map_detail:<stage>` (reset by prestige), `reveal_stats` / `reveal_drops` (kept) and `discovered` / `discovered_spots` (reset by prestige). Its open map is session UI state.
- Outfit slot looks derive from `items[id].merge`; nothing new is saved.

## Change 11 supply state

| Field | Meaning | Default | Save / load | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `items[id].qty` (supply) | Stock: charges. Use spends one; a found copy or a purchase adds one. | absent | saved; load requires `qty` ≥ 0 | clear (items) | clear |
| `supply_found[id]` | Lifetime copies **found** (drops, claimed offline earnings). Mastery = clamp(found − 1, 0, 100). Never lowered by use. Purchases do not count. | `{}` | saved; non-supply ids dropped, values clamped ≥ 0 | **keep** | clear |
| `buffs[id]` | Running timed supply other than the Coin Tonic: `{time, power}` in active (online, unpaused) seconds. Guard adds Defense and Recovery adds max-HP regeneration through `stat_sources()["SOURCE_SUPPLY"]`; Wisdom multiplies kill XP. | `{}` | saved; expired, malformed or non-supply entries dropped | clear | clear |
| `boost_time`, `boost_power` | Coin Tonic buff (kept from earlier changes). | 0 | saved | clear | clear |
| `supplies` | Supply slot row, exactly 1 + `supply_slots` (max 5). | `[""]` | load folds retired tier ids into the base supply (`legacy_items`), keeps each supply in its slot when it fits and clamps the row; `auto_slots` must point inside it | size kept, emptied | `[""]` |

A supply's effect is `base + gain × mastery` (gain = 1% of base, so ^100 doubles it); milestones at ^25/^50/^100 lengthen timed supplies (×1.2/×1.4/×1.6) and shorten the potion cooldown (×0.9/×0.85/×0.8). Use and auto-use rules live in `simulation.supply_block_reason` and `supply_auto_ready`; the UI and automation call the same functions.

## Change 12

| Field / rule | Meaning | Default | Save / load | Prestige | Hard Reset |
|---|---|---|---|---|---|
| settings `music_volume`, `sfx_volume` | 0–1; 0 is silent. The sound-effect volume applies to both categories. | 1.0 | settings record; clamped to 0–1 | keep | keep (settings survive) |
| settings `mute_gameplay`, `mute_special` | Independent category mutes (replace `sfx_enabled` / `music_enabled`). | false | settings record; missing → false | keep | keep |
| `upgrades.merge_all` | One-time 5,000-Gem unlock (level 0/1). Using Merge All is free. | absent | saved with upgrades | keep (Gem upgrade) | clear |
| `campaign.follow_tracked` / `follow_steps` | Session baseline for followed-step cues. **Not saved**: the first reading after load or a new follow only sets it. | "" / 0 | never saved | — | — |

- **Merge All** (`sim.merge_all`) calls the ordinary `merge(id, true)` for every id where `can_merge(id)` holds, in sorted id order: never supplies, one copy kept, never past `merge_cap(id)`, never `evolve`. Each merge reports its own `progress("merge", id, n)`, exactly as manual merges.
- **Gem chance** (`sim.gem_chance`): clamp(0.05 + 0.005 × Gem Chance + Gem Wisdom + achievements (+ 0.05 × Boss Gem Chance on bosses), 0, 1). The catalog has no `normal_cap` / `boss_cap`. `upgrade_maxed("gem_chance")` is the level cap (20) only.
- **Explored percent** (`campaign.explored_percent(stage)`) = floor(100 × saved explored cells ÷ fog-grid cells), capped at 100; vision and the camera never write explored cells.
- **Skill eligibility** (`campaign.skill_ready`): Heal needs HP below 80% of the caster's maximum; Focus needs combat. Checked before a boss telegraph; `_kill` clears `telegraph`.
- **Notices** (`sim.notice(kind, id)`): `mission_ready` when an unclaimed mission's progress first reaches its goal and auto-claim is not active; `follow_step` when the followed opportunity's completed-step count rises or it becomes ready. Presentation maps them to special sounds; nothing is saved.
- No save-schema change. Development saves keep loading; the old `sfx_enabled` / `music_enabled` settings keys are ignored (mutes default to off).

## Change 13

| State | Meaning | Default | Save / load | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `upgrades["auto_evolve:g"]` | One-time Auto Evolution unlock for type g (level 0/1, 2,000 gems, `flat`). | absent | saved with upgrades | keep (Gem upgrade) | clear |
| Summoned helpers (`state.enemies`, `variant` 4, `summoner`) | Live helpers of a summoner. **Never saved**: `sim.snapshot` drops them from the current and stored maps. | none | never saved | gone (fresh world) | gone |
| Actor `summon_cd`, `summon_cast`, `skill_cds`, `pending` | A boss's summon timer, summon telegraph, per-skill cooldowns (final boss) and announced skill. Transient combat fields; harmless if saved, reset when it leaves combat. | — | saved with actors (ignored by validation) | fresh world | fresh world |

- **Drop identity** (`sim.droppers(id)`): types whose `loot` holds `id`, or whose `skills` include it as `"skill_"+key`. Built once from the catalog. Auto-Merge (`gear_group`) and Auto Evolution (`evolve_group`) both resolve an item through its own droppers only.
- **Auto Evolution** (`campaign.auto_evolve`, once per second of simulated time): for each owned weapon with `evolve_group(id) >= 0` and `evolve_block_reason(id) == ""`, call `sim.evolve(id)` once. Manual Evolve uses the same block-reason function.
- **Potion cooldown** (`sim.supply_cooldown` → `supply_cooldown_with(id, milestone multiplier)`): `max(cooldown_floor, cooldown × multiplier)` = max(10, 12 × m).
- **Skill cooldown**: `campaign.cast` stores `sim.player_upgrade_value("cooldown_"+key)` (the preview's getter).
- **Heal threshold** (`campaign.heal_threshold`): 80% of max HP for everyone, except the final boss: `EnemyAbilityRules.final_heal_below` (50%). Final-boss Heal restores `final_heal_fraction` (4%).
- **Summoning** (`campaign._summon_step`): `summon_cd` counts down while the summoner is aggro (reset to `first_delay` out of combat). A call needs no skill telegraph in progress and fewer than `max_alive` live helpers, and for the final boss Heal must not have priority. After `telegraph` seconds it creates `min(per_cast, room)` helpers and restarts the cooldown. With the cap reached it waits a full cooldown.
- **Helpers** (`sim.is_helper`): `enemy_definition(group, 4)` scales HP and damage by the rule and has no loot, skills, coins or XP. `_kill` gives nothing for a helper and removes it after 1 s. `helper_bound` dissolves it when the summoner is dead, not aggro or returning, the player is dead, or it is off its leash. `identify_sites` and group assistance ignore helpers; `camp_action` clears them before storing a map.
- **Next-stage guidance** (`campaign.gate_status`): stages 1–7 on the frontier (unlocked_stage == stage) give {killed, total} over `stage().gates` from `run_kills`; Spring II gives the world-clear count over all its types until `world_complete`; otherwise {}. `gate_required(g)` is a discovered boss of the current map that still counts. Presentation only; no new counters.
- **Currency display** (`NumberFormat.currency(value, round_up)`): presentation only; every purchase compares the exact `state.coins` / `state.gems`.
- No save-schema change (schema 7) and no migration.

