# LootFarmer — State and Reset Contracts — current (2026-10-29, Change 41)

## Change 41 — playtest corrections (29 October 2026)

| Record | Meaning | Default | Save | Prestige | Hard Reset |
|---|---|---|---|---|---|
| settings `joystick_position` | 0 Left, 1 Center, 2 Right: where `joystick.place` anchors the stick along the bottom of the map. | 1 | settings record; missing or non-numeric → 1, clamped 0–2 | keep | keep (settings survive) |

- **Collection contracts:** no new field. `campaign.collection_goal(n)` = 20 / 30 / 40 (handed in), `collection_required(n)` = goal + 1 (shown and required). `collection_counts(id)[i]` = `min(goal, min(online_items[item], opportunities[id]["item_"+item]))` + (1 if `quantity(item)` exceeds that), a pure function of state. `collection_complete(id)` (all at the requirement) is what `submit` checks; it removes `collection_goal(n)` of each through `sim._remove` (credits fall with the copies). `opportunity_progress`, `follow_summary`, `follow_focus` and `follow_steps_done` use the same counts. Existing saves load unchanged; a profile with 20 of each and no spare copy now reads 20/21 (it could not submit before either).
- **Focus Farming targets:** `sim.auto_target(radius, view)`: under a Focus, the nearest visible `focus_match` enemy within radius, else the nearest `threatens_player` enemy (alive, `aggro`, not `returning`, player alive); without a Focus, the nearest visible enemy (unchanged). `_combat_target` keeps a lock while it is the manual target, a focus match, or an attacker with no eligible focused enemy (`_keeps_lock`). `campaign.skill_activation_target` uses `auto_target` within the activation distance after the locked target. Nothing is saved; `locked_target` / `manual_target` stay session state.
- **Drops:** presentation reads `pickup.ttl` only; a view created while `ttl >= 299.5` plays the arrival. `pickup_spark.gd` never writes `state.pickups` or uses `sim.rng`.
- **External links:** `resources/game/external_links.tres` (`discord_url`, `repeat_guard_seconds`); `open(url)` returns false for a failure or a repeat inside the guard (`failure_was_repeat`); the opener is replaceable in probes. No game state changes on success or failure.

## Change 35 — review invitation and targeting step (28 October 2026)

| Record | Meaning | Default | Save | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `state.review` = `{status, eligible_at, answered_at, channel, open_failures}` | `status`: `none` (not offered) → `pending` (playtime_total ≥ `ReviewRules.eligible_seconds`) → `dismissed` (Maybe Later / Back) or `opened` (store page opened). Dismissed/opened are final for the profile, whatever the storefront. `channel` = storefront at the answer; `open_failures` counts failed launches (status unchanged). | `none`, -1, -1, "", 0 | saved (schema 8; `review_invitation.normalize` fills/repairs older or malformed records) | keep | clear (new profile) |
| `tutorial.flow.done` gains `"target"` | Guided step after `move`. Marked only by `guided.action("target")` from a successful `sim.select_target` (the map gesture's release on an enemy), or by the escape below. Satisfied without action only when `"kill"` is already done (profiles saved before the step existed; `normalize` also appends it). | absent | with tutorial | keep | clear |
| `tutorial.flow.target_unavailable`, `target_skipped` | Active seconds the guide spent in `target_find` (no targetable enemy in sight); at `OnboardingRules.target_escape_seconds` (60) the step is marked and `target_skipped` = true. | 0.0, false | with tutorial | keep | clear |
| `tutorial.seen` gains `"basic_target"` | Basic overview card 2/6 (`TutorialGuide.BASIC_DECK`); Skip appends it with the rest. | absent | with tutorial | keep | clear |

- **Hold:** `sim.held` (session only) is true exactly while the review panel is open (`game_ui` sets it every frame from `ReviewInvitation.is_open()`). `sim.step` and `sim.select_target` refuse while held; the guide's real-time waits do not advance. `game_ui.modal_open()` includes the panel, so the guide, banners, movement and the offline claim wait.
- **Back priority:** ReviewInvitation (= Maybe Later) → PrestigeConfirm → Confirm → sheet → exit confirmation.
- **Storefront:** `resources/game/distribution_channels.tres` (`scripts/game/distribution_channels.gd`): `current()` = the single channel whose `feature` tag `OS.has_feature` reports, else "". `--store-channel=<id|none>` overrides it only in test profiles (`BootContext.store_channel_override`). A missing channel suppresses the panel and the Settings action and never changes `state.review`.
- **Export presets:** `Android Release` (Play AAB) `custom_features="store_google_play"`; `Android itch.io APK` and `Windows itch.io` `custom_features="store_itch_io"` (same allowlist, mirrored by `tools/export_manifest.py`); `Android Bootstrap APK` none. `export_manifest.py --check` fails on any release preset whose store tag differs from `tools/export_rules.json` `store_tags`, or any other preset carrying one.

## Change 25 — onboarding mode authority (28 October 2026)

No new saved field, schema change (8) or save-file version change (3); current saves load unchanged. These supersede the Change 15 "Reveal evaluation" rule and the `campaign.focus_hint` note below.

- **One authority:** `campaign.onboarding.revealed(feature)` answers for the HUD, the badges, the notification sounds, the panel opener (`game_ui.panel_allowed`, the only way into a panel) and Help. `tutorial.mode` `guided` → `guided_progress.feature_allowed(feature)` (staged; all true once Guided is complete); `basic` / `none` → always true; `pending` (the chooser) → `onboarding.reveal.has(feature)` (empty on a real profile, all six in `--first-run-complete` probe fixtures). The simulation never refuses an action because of it.
- **Mode choice** (`tutorial_guide.choose` → `onboarding.choose_mode(mode)`): sets `tutorial.mode`; for Basic/None also records all six features in `onboarding.reveal`, appends every `"opened:<feature>"` to `tutorial.seen` (no ✦) and calls `SettingsState.set_inventory_zoom(2)`; then `save_now()`. Never called on load or Prestige. Hard Reset clears the profile (mode `pending`, reveal `[]`) but keeps settings, so `inventory_zoom` survives until the next Basic/None choice.
- **`onboarding.evaluate`** (same call sites as Change 15): ends the loot guarantee when a pair exists; Guided advances `guided.next_step()`; Basic/None latch `tutorial.seen` `"announced:prestige"` the first time `prestige_unlocked()` holds and emit `notice("feature_unlocked","prestige")` + `milestone("prestige_unlocked", n)` once. The Change 15 level backstops and progressive reveal table are removed (`OnboardingRules` keeps `first_item_kills`, `copy_kills`, `card_seconds`, `path_target`, `path_reach`).
- **`tutorial.seen` keys added:** `overview`, `basic_gear`, `basic_growth`, `basic_world`, `basic_prestige` (Basic overview cards, `TutorialGuide.BASIC_DECK`; Skip appends all five) and `announced:prestige`. Old `tip_*` / `feature_*` keys in development saves are ignored.
- **`campaign.focus_hint`:** set only in Guided (Basic and None show the confirmation only).
- **Back:** `game_ui.back()` from `NOTIFICATION_WM_GO_BACK_REQUEST` and `ui_cancel`; at most once per process frame; priority PrestigeConfirm → Confirm → sheet → exit confirmation (`save_now()` before showing it, again before `quit()`); no-op while `tutorial.mode == "pending"`. Saving on background/close is unchanged (`SaveService._notification`).


## Change 24 — persistence and presentation contracts (28 October 2026)

These supersede the audit's "Save cadence (current)" note below and the "Fog keys must lie within authored map bounds" sentence of the Change 5 contract.

- **Save file version 3** (`SaveService.SAVE_VERSION`); game schema still 8. A version-2 development profile (and its backup) starts fresh (`last_load_result = "development_reset"`). No migration (Playbook 61.1).
- **`state.explored` in memory:** `{"<stage>": PackedByteArray}`, one byte per fog cell, row-major (`index = y × columns + x`, `columns = ceil(width / cell_size)`), 1 = explored. API: `campaign.explored_mask/explored_count/cell_explored/explore_cells/fog_columns/fog_rows/fog_cell_count`. Prestige keeps it (Change 16 keep list unchanged); Hard Reset clears it; a fog layout revision change empties it.
- **`explored` on disk:** each mask deflated and Base64-encoded (`campaign.encode_explored`). `normalize_snapshot` decodes; `valid_snapshot` accepts a stored string or an in-memory mask only when it decodes to exactly one 0/1 byte per cell of that map, otherwise the profile is invalid (fresh profile, as before).
- **Snapshots:** the save provider is `sim.save_snapshot()` (a shallow view of the live state, serialized at once and never kept). `sim.snapshot()` is its independent deep copy for probes and tools; both encode `explored`.
- **Write verification:** the temporary file must have the serialized byte length and MD5; it is not parsed back. The primary becomes `.bak` only while it is known valid (loaded from it or written by this session) and unchanged in size on disk; after a backup recovery the backup is never overwritten by the bad primary. Atomic temp-file, backup copy and rename order unchanged.
- **Cadence:** `mark_dirty()` (ordinary progress) writes within `ORDINARY_SAVE_DELAY` = 30 s of the first unsaved change (repeated marks never postpone it); `mark_committed()` (purchases through `sim.pay`, panel action buttons, a supply used from the dock, settings changes) writes after `COMMITTED_SAVE_DELAY` = 1 s; `save_now()` stays immediate for travel, claims, Prestige, Hard Reset, guidance choice, pause, background and quit; the 120 s periodic save remains. **Accepted rollback window after a crash or force-stop without a pause notice: up to 30 s of ordinary progress.**
- **Sight:** `campaign.sight()` returns the inputs of `can_see()` for one moment (`Sight.sees(pos)` is the identical predicate). Hot loops (targeting, skill areas, world views, pickups, rain) take one Sight per pass instead of re-deriving the reveal bonuses per position. Never saved.
- **Presentation-only state (never saved):** off-screen actor views pause their own processing and stay hidden while the world keeps their actor, position, look and disclosure current; actor views are pooled across map changes; the last closed panel's controls are retained hidden (processing paused) until that panel reopens (reconciled) or another opens (replaced).

## Production audit notes (28 October 2026)

No contract changed in the audit. The current Change 22/23 records (`tutorial.flow.wait_seconds`, `mission_auto_enabled`, `prestige_collapsed`) are specified near the end of this document. Facts recorded for the coming performance and release work (see [audit report](LootFarmer_Full_Production_Audit_Report.md) PERF-01, SAVE-01..03):

- **Save cadence (current):** active play marks the save dirty every 2 s and the save service flushes dirty state every 5 s, plus a 120 s periodic save, plus immediate saves on background/close and committed transitions. Each save writes the whole profile to a temporary file, re-parses it, re-parses the previous primary, copies the primary to `.bak` and renames. A fully explored late-game profile measured 466 KB and about 125 ms per save on the desktop audit machine. Any change to this cadence must keep the atomic temp-file, rename and backup sequence and state the accepted force-close rollback window explicitly.
- **Development reset policy is still active:** an unreadable or wrong-version profile without a valid backup starts fresh. Before the first public build the developer declares the release phase (Playbook 61.2); from then on schema changes need migrations and an unreadable profile must be preserved aside, not replaced.
- **Offline clock:** the snapshot keeps the later of the stored and current time; turning the clock back earns nothing until real time catches up; each absence is capped by the offline duration upgrade. No network time is used (offline game). Accepted behavior.

## Change 21 — previous corrections (27 October 2026)

Built on the exact delivered Change 20 project; application/Android version is 21 and save schema remains 8. See [Change 21 report](LootFarmer_Change_21_Report.md) for the complete correction checklist and validation.

- Guided Missions unlock 15 active real seconds after the first merge. Inventory expansion now explicitly points to Close before teaching potions. Already advanced saves do not repeat the new close step.
- Auto-merge item controls appear only with the applicable purchased upgrade, and remain available when excluded.
- Supplies support six total slots (one initial plus five purchases). Small shows 3 columns × 2 rows, Medium 2 × 2 visible, Large one visible; the viewport stays fixed. Gear and Supply headings and slot rows align.
- Missions, Mastery, Filters, Prestige and Upgrades show visible scrollbars on overflow. Claim has a compact, centered height.
- Mission/Prestige followers stack just above the joystick. The farming objective is larger and padded; boss countdowns show only seconds.
- Prestige opportunities are grouped by relevant unlocked maps with completed/total counters, followed by General, Owned Cards and Card Sets. Objectives spanning multiple maps appear in each relevant section. General contains offline, merging, arsenal, offering and mission objectives.
- Expanded map camps are visible without Map Details and support release-to-travel with larger icons/hit areas. Camp-list buttons remain. Combat restrictions still apply.


## Change 20 — previous delivery (27 October 2026)

The full 22-section **Remaining Features, UI & Tutorial** brief is implemented, including interfaces. It supersedes the earlier gameplay-only scope and handoff to Claude. Application/Android version is 20; save schema remains 8. See [Change 20 implementation and acceptance report](LootFarmer_Change_20_Report.md) and [current test suite](LootFarmer_Test_Suite.md). Earlier numbered change descriptions are historical evidence, not conflicting current instructions.

Guided onboarding follows saved action outcomes and 15/15-second real-frame-time delays, teaches physical camp purchase, boss preparation, inventory expansion and potion use, and ends in Winter II after a five-second visible-message delay and acknowledgement. Only Guided mode has the tutorial Prestige gate. Slots have saved Small/Medium/Large controls in Filters and Settings. Item details expose Auto-merge On/Off. Prestige keeps player level and XP, but resets Supply Mastery and partial use progress. World stage selection travels directly for one unlocked camp or shows a visual camp map for multiple camps. Map markers, trackers, mission layout and boss discovery/countdown presentation are integrated. All offensive skills (including Focus) require combat and an eligible target within the configurable 64-unit activation distance; Heal needs missing HP and works outside combat. Boss Gem previews include the existing base once.

These contracts are implemented in Change 4 and exercised by the campaign/content probes; device and interruption-at-OS-write checks remain release gates. Approved reset decisions are explicit; engineering defaults are labelled below.

## Prestige matrix

| State | Prestige behavior |
|---|---|
| Stage access / gate kills / final-stage per-type kills | Clear; Winter I available |
| Arrival camps | Winter I free camp restored; later free camps become available with their stages |
| Purchased camps / selected camp | Clear purchases; select Winter I arrival |
| Explored cells / sighted camps / found spots and types / found bosses | **Keep** (Change 16; cleared before) |
| Map detail and radius ranks | Clear per stage |
| Collected unique boss keys / final-mission discovery | Keep; key drops active on new run if mission discovered |
| Final boss lock | Requires all 13 persistent keys and physical stage access; independent of mission reward history |
| Cards / combos / consumed opportunities / discovered opportunity descriptions | Keep |
| Unconsumed ordinary opportunity progress and readiness | Clear after rewarding the snapshotted ready batch |
| Offline opportunity counters and readiness | Keep until consumed; only one reward per opportunity |
| Rewarded main objectives / permanent achievement ownership | Keep |
| Unfinished main progress | Clear except persistent final discovery/keys |
| Completed unclaimed main objectives | Discard reward; reset to unfinished, since only completed AND rewarded objectives persist |
| Regular missions / unclaimed rewards | Clear; assign fresh achievable goals after reset |
| Gem balance | **Keep** (Change 16); the run's online Gem credit (`online_gems`, Offering) clears |
| Player level / earned XP | **Keep**; derived stats recompute once, no level reward replay |
| Coins / inventory / equipped bindings / merge, evolution, rolls, copy bonuses | Clear; restore authored starting profile |
| Upgrade purchases | Every gem-funded upgrade is kept (Change 11, `simulation.upgrade_kept`); coin upgrades follow the Upgrade Catalog Keep/Reset field. Kept Spawn Amount re-spawns its extra actors in the fresh world at once |
| Supply mastery (`supply_uses`, `supply_mastery_credit`) | **Clear both**; zero mastery and zero use remainder (3 successful uses per level since Change 36). Supply stock, buffs and bindings also clear |
| Highest reward stage (`reward_stage`) | Keep, even though stage access resets |
| Boss countdowns (`boss_respawns`, `boss_saved_at`) | Clear with the run |
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

Camp and stage travel call the same travel_reason query used by buttons. Inactive worlds retain enemies and pickups with timers frozen, except boss countdowns which advance centrally (Change 17). Save snapshots retain the departure timestamp while suspended. Offline settlement, claims, submissions and card commits roll back in-memory mutations on save failure. Offline settlement also rolls back RNG. Rewards are credited before the receipt is shown.

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


## Change 14

| Field | Meaning | Default | Save | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `tutorial.seen` gains `"focus_unlocked"` | Written at the profile's first Focused Farming purchase (`campaign.upgrade_bought`), so the confirmation and the guidance never show twice. | absent | saved with tutorial | keep (tutorial is kept) | clear |
| `campaign.focus_hint` | The type whose Farm button the guide points at after that purchase (-1 none). Session only; set only in Guided (Change 25; before: outside "None"). | -1 | **never saved** | — | — |
| `sim.cast_target` | The actor a single-target skill hit, set just before `spell_cast`; presentation reads it. | "" | never saved | — | — |

- **Missions badge** (`campaign.has_claimable`): any `mission_claimable(i)` (kind not "waiting", unclaimed, `progress ≥ goal`, and not `missions_auto_claimed()`), or any `main_claimable(i)` among `main_shown()`. `main_claimable(i)` = `main_ready[str(i)]`, not in `main_claimed`, and (i ≠ 15 or `final_discovered`). `main_shown()` = up to three unclaimed listed objectives, ready ones first in index order, then unfinished ones. The panel lists exactly `main_shown()`, so a lit badge always has a Claim button behind it. Pure state: no stored flag, recomputed every HUD tick.
- **Focused Farming hint** (`TutorialGuide._focus_hint`): pending while `focus_hint ≥ 0`; ends (sets -1) when `state.focus ≥ 0`, the upgrade is gone, the type is not on the current map, "Got it" is pressed or `focus_shown ≥ 45 s`. Surfaces: HUD and the enemy panel of that type; any other panel suspends it.
- **Skill effects** (`world._spell`, `_warning`, `_effect`): presentation only, from `resources/game/skill_effects.tres`. Boss attack wind-ups emit `sim.skill_warning(actor, key, aim)`; `spell_cast` fires once per resolved skill. For Lightning and Strike its position is the hit actor's; for Fire the aim; for Frost the caster.
- **Rain splash** (`season_weather.particles`): a particle in frame ≥ `splash_frame` is placed at the clock of its impact frame, `(tick − (frame − splash_frame)) / fps`. Pure function of clock and world grid.
- No save-schema change (schema 7) and no migration.

## Change 15

Save schema **8** (`simulation.new_profile`, `restore`, `campaign.valid_snapshot`). Schema 7 development saves reset (no migration, by instruction).

| Field | Meaning | Default | Save | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `onboarding.reveal` | Revealed systems in reveal order, from `missions`, `enemy`, `world`, `upgrades`, `objective`, `prestige` (`campaign.onboarding.FEATURES`). Latched, never removed. | `[]` (all six with `--first-run-complete` in probes) | saved | keep | clear |
| `onboarding.loot_phase` | Early equipment guarantee: 0 none, 1 one item without a match, 2 a pair dropped and still on the ground, 3 done (a pair owned or merged). | 0 (3 in probe fixtures) | saved | keep | clear |
| `onboarding.loot_kills` | Eligible kills counted in the current phase. | 0 | saved | keep | clear |
| `tutorial.seen` gains `"opened:<feature>"`, `"snowman"`, `"prestige_intro"`, `"tip_*"`, `"feature_*"` | A revealed menu was opened (no more ✦); Guided/Basic cards seen. | absent | with tutorial | keep | clear |
| `mastery.explored` | Best Map Explored percent per stage key ("1"–"8"). | `{}` | saved | keep | clear |
| `mastery.camps` | Camp indices ever owned per stage key. | `{}` | saved | keep | clear |
| `mastery.found` | Weapons, outfits and skills ever obtained (set). | `{}` | saved | keep | clear |
| `mastery.merge` | Best merge level ever reached per item. | `{}` | saved | keep | clear |
| `mastery.evolved` | Weapons ever evolved (source ids, set). | `{}` | saved | keep | clear |
| `mastery.done` | Latched completions: `"<stage>:<category>"`, `"map:<stage>"`, `"game"`. | `[]` | saved | keep | clear |

- **Reveal evaluation** (`onboarding.evaluate`) *(superseded by Change 25 above; kept as history)*: on the campaign's one-second tick, after `progress()` of merge, upgrade, camp, mission and supply_buy, after `claim_main` and at the end of `killed()`. The Snowman's lifetime kill (`prestige_unlocked()`) reveals everything and emits `notice("feature_unlocked","prestige")` and `milestone("prestige_unlocked", n opportunities)`. A full equipment row reveals every feature up to `upgrades`. `reveal_all(true)` (Settings) is silent. Presentation (`game_ui.panel_allowed`, `_refresh_reveal`, the badges, `_milestone`, `_notice`) reads `revealed()`; the simulation never refuses an action because of it.
- **Guarantee** (`onboarding.loot_kill`, from `simulation._reward` after the natural rolls, before the loot line): the phase is recomputed from owned stock and ground pickups (`loot_state`), so an expired drop lowers it and the next eligible kill replaces it. `loot_state` never creates item records (no RNG use).
- **Mastery** (`campaign.mastery`): `refresh_records()` copies run values upward; `evaluate(announce)` latches completions and emits `notice("mastery_objective")`, `notice/milestone("mastery_map")`, `notice("game_complete")` and `milestone("mastery_game")` once each. `restore` calls `evaluate(false)`. `mastery.bonus(key)` is added inside `campaign.bonus(key)`, so HP, damage, coins (`card`), XP (`group_xp` adds `bonus("xp")`), Loot Chance (`gear_chance`) and Gem Chance (`gem_chance`) each apply it exactly once.
- **Explored percent** (`campaign.explored_fraction`) excludes `fog_rules.unreachable_cells[stage]` from both the explored count and the area.

## Change 16

Save schema stays **8**. `normalize_snapshot` adds the new records to existing saves; nothing resets.

| Field | Meaning | Default / migration | Save | Prestige | Hard Reset |
|---|---|---|---|---|---|
| `bosses_found` | Boss type ids found by sight (`campaign.sight_bosses`): a living boss the living player can see (`can_see`) within `fog_rules.boss_sight_radius` (160). Each id once. Emits `notice` and `milestone` "boss_found" once. | `[]`; an older save gets every boss with `group_kills > 0` (no warning) | saved; validation: boss ids only, unique | **keep** | clear |
| `follow_mission` | The followed mission: `"daily:<slot>:<kind>:<target>:<day>"` or `"main:<index>"`, "" for none. Ends (cleared) when the mission is claimed or its slot holds another assignment (`check_follow_mission`, on claims and the 1 s tick). | `""` | saved | clear (missions restart) | clear |
| `pickups[].qty`, `pickups[].dropped`, `group` −1 | A stack dropped by Drop All (`simulation.discard`): one pile of `qty` copies at the player's feet, owned by no enemy type (no Auto-Collect), 300 s like loot. `dropped = {online, ops}` holds the run's online credit (`online_items[id]`, each opportunity's `item_<id>`) taken with it, at most the quantity. | — | saved with the map's pickups; validation: `group` −1 only with `dropped`, `qty` ≥ 1 | gone (fresh world) | gone |

- **First Snowman weapon (Change 27):** no new saved field. `onboarding.boss_first_kill` runs in `simulation._reward` after the natural rolls and the early equipment guarantee; it adds one ground pickup of `def.weapon` when the defeated group is in `OnboardingRules.first_kill_weapon_bosses` and its lifetime `group_kills` is exactly 1 (incremented in `_kill` just before `_reward`, in the same step, so the kill, the drop and the count are saved together and a reload cannot repeat it). `group_kills` is saved, kept by Prestige and cleared by Hard Reset (new_profile), which gives the once-per-profile rule. Schema stays 8; save file version stays 3.
- **Prestige unlock** (`campaign.prestige_unlocked`): `bosses_found` holds the unlock boss (`progression.prestige_unlock_boss`, the Snowman) **or** its lifetime `group_kills` > 0. `first_boss_defeated()` is the kill alone (the Winter I objective chip).
- **Prestige keep list** adds `gems`, `explored`, `camps_known`, `discovered`, `discovered_spots`, `bosses_found`; after the reset `reveal()` re-identifies spots on the kept fog.
- **Drop and pick up** (`simulation.collect` of a `dropped` pile): `add_item(id, qty, found=false, announce=false)` (no supply mastery, no recent-find line), no `progress("collect"/"gear")`, then `_restore_credit` adds back exactly the stored credit. Equipped items refuse (`DROP_EQUIPPED`). A dropped stack leaves its record (merge, extras) in `items` with `qty` 0.
- **Map-tied Coin prices** (`campaign.map_cost_factor(stage)`): `progression.map_cost_growth`^(stage−1) for Coin upgrades scoped `type`, `normal_type`, `stage`, `camp`, camp unlocks and the Map Details floor.
- **Enemy skill cooldown** (`campaign.enemy_skill_cooldown`): `EnemyAbilityRules.skill_cooldowns["<type>:<skill>"]` or the catalog skill's cooldown, for the rotation and the final boss alike.
- **Music** (`AudioService._sync_music`): starts the track only when it is neither playing nor paused; `stream_paused = music_volume ≤ 0 or tree paused`; called on every settings change, `play_music` and `refresh_music` (after the HUD pause). Nothing saved beyond the existing settings.

## Change 17 saved fields and lifecycle

| Field | Meaning/default | Load/migration | Prestige | Hard Reset |
|---|---|---|---|---|
| boss_respawns | `{actor_id: {group, stage, remaining, x, y}}`, default `{}` | Rebuild absent store from dead bosses in active/inactive worlds; normalize identities and coordinates | Clear | Clear |
| boss_saved_at | Timestamp used only for offline elapsed settlement | Advance remaining once at restore/resume; snapshot timestamps frozen while suspended; negative elapsed is zero | Reset | Reset |
| supply_uses | Per-type successful uses, default `{}`, retained to cap × `change17.supply_uses_per_level` (3 since Change 36: 300) | Clamp 0..cap×per-level (300); no collection-derived uses. Counts are actual uses, so an older save keeps its count and re-derives mastery with the new divisor; mastery at the cap is unchanged by the clamp | Clear | Clear |
| supply_mastery_credit | Legacy mastery, default `{}` | Once, if absent: clamp(supply_found−1,0,100). Later loads never derive it again | Clear | Clear |
| reward_stage | Highest reward stage, default 1 | Max prior unlocked/visited-stage evidence; getter maxes with current unlocked_stage | Keep | 1 |
| upgrades.skill_auto_slots | Capacity 0..3 | Fold old skill_auto_0/1/2 ranks once; erase retired saved ranks | Keep | 0 |
| skill_auto | Existing three booleans now represent chosen equipped positions | Sanitize/cap to owned slots and capacity; empty selections dormant | Keep | All false |
| mission.base_gems | Unscaled per-kind Gem amount | Reconstruct missing legacy base from kind, never from scaled totals | Mission resets | Clear |

Critical upgrades and use_speed use existing upgrades serialization and Gem retention. Actor attack_slow/attack_rate are saved with actors; active combat status time remains pausable, with inactive actor statuses frozen as before. Boss offline countdown settlement does not simulate or grant combat kills. Current UI must poll APIs in the Claude handoff; it must not mutate these stores directly.

## Change 19 eligibility and probability contracts

No new saved fields or migrations. Save schema 8 and all Prestige rules remain unchanged. `skill_cast_block_reason(slot)` is pure and combines action locks, slot ownership, living player, family cooldown, missing HP for Heal, and nearby eligible enemy for every other skill. Focus also retains its combat gate. `skill_activation_target()` prefers a valid in-range locked target, otherwise the nearest eligible enemy matching farming filters; it never acquires or clears the basic-attack target. Boundaries are inclusive. The activation distance is catalog configuration, independent of AoE radius. Availability must be polled while actors move. Successful casts alone write cooldowns and emit spell effects.

`boss_gem_chance(extra)` owns the shared boss probability and upgrade preview; `gem_chance(group)` adds the specific type's achievements and clamps to 100%. The 5% base remains solely in `gem_base_chance`. No UI-owned probability formula is needed.

## Change 20 saved state and UI contracts

- `tutorial.flow`: ordered `done` outcomes, action timestamps in `playtime_total`, one-time `gem_grant` / `supply_grant`, additional-farming kill baseline and `final_seconds`. Invalid optional values normalize without changing schema. It survives saves/Prestige. Hard Reset clears it. Actions already completed are recognized; entering Winter II on an older Guided save leads to the final explanation. Basic/None never consult the new Prestige gate.
- `settings.inventory_zoom`: 0 Small, 1 Medium, 2 Large (default); clamped on load, retained across Prestige/Hard Reset with other settings. Grid and contents resize together; the dock viewport height remains fixed. Scrolling and pinned controls retain their existing ownership.
- `items[id].auto_merge_excluded`: optional boolean default false, owned by the inventory identity/stack. Automatic merge and automatic evolution skip it. Manual merge is allowed; manual evolution transfers the exclusion to the successor. Zero-quantity records retain it, so discard/pickup cannot silently re-enable automation. Run inventory reset clears item records normally.
- Boss discoveries permanently reveal the same footprint radius as camps. Existing discovered bosses backfill that footprint on their stage. The countdown UI reads `boss_respawn_countdowns(stage)` at saved home coordinates, without adding a new clock or simulation.
- Travel picker reads the destination stage without switching the active simulation. Both direct travel and map selection use `travel_reason`; combat remains a hard block. The map uses green vs gray rings plus brightness and numbered camps.
- Player map marker is explicitly one layer above the map drawing. Management panels are layer 10; guide/banner 15, confirmations 20, Toast 25. This keeps the marker above all map markers and below opened management surfaces.
- `playtime_total` measures active unpaused simulation time. Guided tutorial 15/15-second waits accumulate unpaused, active real frame time separately from physics playtime; they do not elapse while closed/suspended, and save/reload preserves partial progress. Final delay is visible, unpaused UI time, not accelerated gameplay time.

## Change 22 — live correction contracts (2026-10-28)

- **Guided 15-second waits:** `progression.change20.mission_delay` and `upgrade_delay` are both 15. `tutorial.flow.wait_seconds` accumulates actual unpaused, active `TutorialGuide._process` seconds after `merge` / `close_missions`. It is independent of the physics-capped `playtime_total`, saved across reload and kept by Prestige. Pausing/backgrounding does not advance it; existing `times` are migrated for current-schema saves.
- **Automatic Mission Claiming:** purchasing `mission_claim` unlocks the option but leaves `mission_auto=false`; all purchased regular mission slots are eligible, Main Objectives remain manual. A one-time guide points from the Missions button to the ON/OFF toggle. `tutorial.seen` stores `mission_auto_enabled` when first enabled; retained by Prestige, cleared by Hard Reset.
- **Prestige stage presentation:** `prestige_collapsed` is a dictionary of stage-id strings (`"1"`…`"8"`, `"0"` for General) to user-selected booleans. Missing entry defaults to `true` when all authored opportunities of that stage are consumed, otherwise `false`. The heading counter counts consumed / authored opportunities (not reward cards). Preserve overrides through Prestige and save/load; Hard Reset clears them. Missing or invalid overrides are normalized on schema-8 load. Owned Cards and Card Sets are not collapsible.
- **Confirmations:** the shared modal fits on open and after safe-area changes only; never per rendered frame. It settles before becoming visible, preserves scrollable descriptions and invalidates pending layout on cancellation. Drop All item mutation logic is unchanged.
