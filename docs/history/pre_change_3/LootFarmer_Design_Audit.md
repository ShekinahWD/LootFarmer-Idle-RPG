# LootFarmer — Evaluation — Change 2

2026-10-20. Audited attachment: lootFarmer(6).zip. Verdict: usable prototype foundation and sufficient supplied art/audio to continue final design; not a completed final game or fully compliant release package.

## Scope and evidence

Read-only source/archive review before documentation changes: compared ZIP 6 with ZIP 5 by CRC and size, checked all archive entries for ZIP CRC corruption, inspected current design/playbook/status/asset documents, spell manifests/licenses/images/WAV headers, runtime source, project configuration, localization gate, source resource references and toolkit integrity. No gameplay code changed. No fresh Godot run, Android build, physical-device test, listening review, animation playback review or complete natural progression playthrough was performed in this audit.

ZIP 6 has 12,517 entries. Relative to ZIP 5 it adds 163 files: the VFX pack, SFX pack and generic sounds/import metadata. Only one existing entry differs, `.git/gk/config`; gameplay, scenes, tuning, tests and documentation are unchanged. Archive CRC verification passes. No missing literal `res://` file references were found in gameplay scripts/scenes/resources/UI; this does not prove dynamic references or every future asset assignment.

## Playbook evaluation

| Area | Finding | Required follow-through |
|---|---|---|
| GDD before full production | Partial: subsequent approved conversation decisions were absent; older docs claimed final approval | Change 2 consolidates current rules and marks remaining decisions open |
| Reusable toolkit | Pass for source integrity: 11/11 managed files match SHA-256 lock and vendored source; version 1.0.2; source .gdignore present | Keep pinned; game-specific capture and target-platform verification remain separate |
| Integer changes | Runtime already 1; schema and store versions separate | Documentation batch is 2; do not pretend it is a tested executable build |
| Assets before invention | Six requested spell VFX and matching audio are now supplied | Use verified frame/timing tables; integrate only after design closure |
| UI and editor ownership | Scene templates, centralized theme, simulation/view separation and bounded confirmation are present | Physical-phone safe-area, text wrapping and gesture acceptance still needed |
| Economy ownership | Catalog and simulation provide central rules; Change 1 implements revised gem/spawn/collection values | Review all old/new upgrade tracks together before final pricing |
| Save/lifecycle | Atomic staged writes, backup fallback, schema migrations and profile isolation exist | Extend for missions, offline clocks and multi-choice prestige transactions; fault-test them |
| Localization | English-first gate and 20 planned locales present | Only English PO supplied; remaining translations/font/layout verification are release work |
| Evidence | Archived functional probes and a known failing balance probe are included | Never describe those as a fresh ZIP 6 test or Android acceptance |
| Source handoff | Fails clean-package rule: .godot cache, .git metadata and export_credentials.cfg included | Produce future source ZIP from reviewed source; exclude credentials/cache without deleting local work |

Credential file presence was checked by filename only. Its contents were not read, reproduced or assessed; inclusion is not proof that a real signing secret is stored there.

## Implemented versus approved

| System | Current implementation | Approved work still needed |
|---|---|---|
| Core farming | Combat, gear/outfits, merges/evolution, inventory, pickups, automation and compact map | Full-world content, progression and pacing |
| Gems/spawns | Change 1 caps/prices, normal capacity to six, per-type collection at 10 seconds | Comprehensive final catalog; longer boss-delay tuning |
| UI | Always-visible item actions; bounded themed Hard Reset confirmation | Verify physical-device behavior, especially the original overflow case |
| Stored bonuses | Unequipped weapons contribute 30% | Apply approved 30% to outfits too |
| Player upgrades | Respawn and existing inventory/automation capabilities | Movement speed and new skill/mission/offline tracks |
| Missions | No new mission system implemented | Daily slot lifecycle, manual/auto claim, main objectives and prestige resets |
| Prestige | Old boss entitlement/card flow remains | Eleven paths, discovered one-use opportunities, unique cards, combos and batched choices |
| Offline | Timestamp/save infrastructure; no earnings simulation | Fixed upgradeable rates, 5–48h cap, item unlocks and isolated offline-path credit |
| Skills | Assets present; no gameplay references to new spell packs | Skill inventory/equip/merge/evolve/cast/per-slot automation and enemy demonstration |
| Audio | Existing UI/prestige event registrations | Spell event mapping, mix/priority limits and new generic sound mapping |

## Asset completeness

All six selected VFX sheets and 59 separate frames exist. Each frame is 64×64 RGBA; sheet dimensions/frame counts match the manifest. Timings are 70ms cast, 60ms impact, 70ms fire/ice, 60ms zap, 80ms heal. Heal is marked looping; the game must terminate its visual intentionally.

The spell SFX pack includes 30 sounds in both WAV and OGG, not 60 distinct sounds. All 30 WAV headers read correctly: mono, 44.1kHz; durations approximately 0.53–2.71 seconds. Both spell packs include commercial-use permission; attribution is optional and standalone asset-pack redistribution is restricted. Assets being available does not mean sounds have been listened to or animations integrated.

`assets/sounds/` adds 16 WAV files including music, UI, mission, movement and damage cues. No license file accompanies that folder and no byte-identical source copies were found elsewhere in this archive. Record their origin/license before release. The archive also lacks clearly named PixelPlains license evidence; obtain/retain the applicable purchase/license documentation. This is missing evidence, not a finding that use is prohibited.

There are 54 character v2 sheets under PixelPlains Characters 24x24. These are appearances, not 54 distinct playable enemy species; v1/v2 and costume variations must not inflate the roster. Existing environments/items/UI/animation packs provide a broad palette. Exact enemy roles, skill droppers, bosses and world sections remain a design assignment. No additional spell pack is needed to continue that design.

## Existing test evidence

`Change_1_Evidence/summary.json` reports 15 passing functional probes, 1,071 counted checks across 14 of those probes, and one known existing balance-probe failure. Bootstrap reports pass without a check count. Evidence identifies Godot 4.6 stable Linux headless, declared project 4.7, physical_device_tested=false. These are inherited results, not reruns.

The boss-loadout failure must become a tracked balance task. Resolve intended player levels/loadouts, time-to-kill, incoming damage and recovery before tuning the world and mission durations. Do not remove or weaken the test merely to make the report green.

## Remaining decisions and authoring work

1. World roster and progression: exact enemy/boss counts, section gates, travel and prestige reset behavior. These correspond to the previously unapproved bulk items 1 and 2.
2. Full upgrade catalog: categories, currencies, prices, caps, prerequisites and permanent/run scopes, including boss delay and cooldown minima.
3. Authored content tables: all 33 opportunities/cards, 17 combos, mission templates/rewards, six skill assignments and fixed offline rates/earnings objective. Delegated tuning may be proposed together rather than reopening approved behavior.
4. State-contract edge cases before coding: offline rollback/claim handling, completed-unclaimed main objectives on prestige, and interrupted multi-card transaction behavior.

## Documentation disposition

Change 2 replaces active GDD, design audit, entry point, asset registry and checkpoint/status summaries. Prior versions are preserved under history/pre_change_2 with an explicit historical label. Older release notes, manifests and test results remain unchanged as evidence. The Playbook receives generic review/handoff guidance; this game's numbers stay in the GDD. Gameplay scripts, catalog, scenes, executable version, assets and export configuration are not changed.
