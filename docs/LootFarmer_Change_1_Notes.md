# LootFarmer — Change 1

Date: 2026-10-20. Source: supplied `lootFarmer(4).zip`, previously 0.6.3. No new assets or plugins required.

## Install

Close Godot, back up the project and save, then extract this ZIP directly into the project root and overwrite. No enclosing folder, deletion, dependency install or manual data edit is needed. Open `project.godot` in your Godot 4.7 editor, let it import, and run the main scene. The ZIP includes the updated GDD, reusable Playbook, current handoff/status, tests and manifest.

Project version is 1. Both Android preset codes advance to 8 (previous preset codes 5 and 7); version/name still inherits the project version. Output filenames are LootFarmer-1.aab and LootFarmer-1.apk. This package does not contain a signed export. Continue using your local signing configuration.

## Changes

- Fix Hard Reset and all other confirmation dialogs: themed, bounded, scrollable message with pinned Confirm/Cancel controls; reset works while paused.
- Remove More/Less Options from item panels; show all actions directly.
- Player tab contains respawn delay only. Upgrades holds global gem tracks; Inventory and Supplies retain their existing functions.
- Move auto-collect, range, batch and interval to each enemy type. Start at ten seconds, upgrade to five. Every new drop retains its source type; collection is independent even for shared consumables.
- Normal spawn upgrades: 3 to 6 enemies in every spot, five cooldown reductions down to half the original delay. Boss excluded; remains one enemy with a 30-second respawn.
- Global gems: 8% base, 20% total normal cap, 1 to 6 gems. Boss-specific purchases reach 60% combined chance and +10 gems (16 combined). Exact authored prices and existing type scaling are documented in the GDD and catalog.
- Use integer change numbering from 1, once per delivered batch; store codes, save schemas and toolkit versions remain separate.

## Save compatibility

Schema 5 retains old collection levels for all four types and preserves their original permanent status. Old global gem purchases are refunded at exact former prices and their new tracks start unpurchased. Previous schema migrations still run. New profiles start with zero purchases; repeat loads never refund twice. Existing gear, achievements, currencies, cards, focus and other upgrades remain. Legacy shared consumable pickups use nearest-row provenance because their old data had no source type.

## Verification and limits

Local runtime: Godot 4.6 stable, Linux, headless. The project continues to declare Godot 4.7. Exact 4.7 editor/export-template and physical Android verification remain pending. Import has no GDScript errors; 4.6 reports the supplied 4.7 export-preset runnable format as missing legacy runnable keys. The 4.7 preset format was preserved.

Change-1 probe: 131 checks passing, covering costs/caps, real boss rewards, per-spot actors, boss exclusions, cooldowns, collection provenance/timing, migration/refund idempotence, persistence, panel contents, confirmation bounds at four window shapes and reset while paused. Existing headless functional probes pass after updating expectations for the approved balance/schema/UI and correcting stale decimal-display assertions. Individual results are in `Change_1_Evidence/`.

The boss-loadout balance gate remains failing: all three old sample builds lose. Its fixture previously placed the player outside boss acquisition range; it now derives its starting point from the actual boss. The corrected fixture produces identical failures on the original supplied simulation/catalog and this update (death at 5.8 / 2.2 / 4.0 seconds). Combat stats were not changed to force a pass. Revisit this gate's level/loadout assumptions and boss balance when completing the GDD.

No GPU screenshot review, physical-phone playtest or Android export was performed. On device, check the full item action list, all four upgrade tabs, reset cancel/confirm from pause, narrow-screen text, and the feel of ten-second collection plus higher spawn counts.

Run targeted checks from the project root:

    godot --headless --path . res://tests/change_1_probe.tscn -- --profile=probe-change1 --no-autosave

