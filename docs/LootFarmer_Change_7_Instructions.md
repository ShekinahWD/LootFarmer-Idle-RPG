# LootFarmer — Change 7: Android Playtest Corrections

## Objective and source of truth

Continue from the **latest working project tree with Change 6 already applied**. Do **not** replace it with an earlier ZIP or replay previous patches. Read the current GDD, `docs/Reusable_Game_Development_Playbook.md`, and Change 6 notes, validation, audit, and prestige catalog. If the working tree is newer than the provided snapshot, respect the newer implementation. This is a **focused correction batch**, not another full-game audit.

The developer has tested the game on Android. The observations below are reports to investigate, **not proof they still exist**: inspect current behavior first, skip fixes that are already correct, and preserve Change 6 improvements. Implement approved corrections without a prolonged design or balance study. Explain genuine design conflicts briefly rather than silently changing approved rules.

### Non-negotiable workflow: make the game buildable **before** deferred testing

**Phase A — Inspect and implement (priority):**
1. Briefly inspect each observation and identify the real cause; group related fixes. Do not perform a broad or repetitive audit.
2. Implement **all gameplay, UI, data, scene, persistence and configuration changes** for this batch. Finish the code needed for the developer to build a playable Android version. Keep changes compatible with Godot 4.7 and the project's inspector-first/owned-assets rules.
3. Use **only minimal checks necessary to establish build-readiness**, such as parsing/import/compilation and a very short startup smoke check. Fix any errors that prevent launching. Do not start lengthy test creation, full regression suites, balance bots, soak runs, screenshot sweeps or profiling before the build-ready notice. If a tiny targeted check is indispensable to safely complete a particular feature, that is permitted.
4. **Immediately send a separate, highly visible message in the chat**, as soon as implementation is complete and the current tree is buildable, using exactly this format:

   > **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   > **All Change 7 implementation changes are in the current project tree.**  
   > **🧪 I AM NOW GENERATING AND RUNNING THE REMAINING TESTS.**  
   > **Android playtesting and final regression validation are still pending.**

   This is a **build-ready notification**, not a claim that every test passed or that Android behavior was verified. **Do not wait for the final test report to send it.** Do not stop working or ask for permission after posting; proceed to Phase B while the developer builds and plays.

**Phase B — Test and report (after the chat notification):**
5. Add/update the **necessary focused regression tests**, then run them. Prefer adapting existing probes over creating sprawling new harnesses. Run a single relevant broader regression pass after targeted checks, provided it is reasonably quick. Classify obsolete assertions before changing working production logic.
6. Run **at most 1–2 short, deterministic representative pacing/balance scenarios** if the equipment redesign materially affects combat/progression. No large multi-seed bot campaigns, repeated 30-run sweeps, hours-long playthroughs, or unrelated performance benchmarks. The developer decides whether balance **feels right** through Android playtesting; tests only catch glaring exploits, softlocks and broken progression.
7. Keep heavy processes sequential. Do not repeat already-passed suites or collect huge evidence packages without a concrete reason. Honor Playbook §§44.2 and 60.1.
8. If later testing finds a defect that requires editing gameplay/source/scene/configuration **after** the build-ready notification, tell the developer clearly that the earlier build is **outdated**, fix it, perform the minimum necessary build check and send a **new build-ready notification**. Never silently invalidate the version the developer is testing. Changes to tests, logs or documentation alone do not require a new notice.
9. End with a concise table of **Fixed / Already Correct / Needs Developer Decision / Android Verification Needed**, noteworthy test results, and a short phone-check list. Never imply that desktop/headless results equal physical-device validation.

**Important:** The primary milestone is a **playable game early**, not a finished test campaign. Leave all testing that safely can wait until Phase B.

## Corrections to inspect and implement

### 1. First-loot tutorial resilience

A first enemy may drop a **consumable rather than equipment**, leaving the Equip tutorial step without a usable item. Progress must depend on the **actual inventory/equipment state**, not a generic item-acquired flag. If there is no equipable item, direct the player toward farming/obtaining one; where sensible, point to the **empty equipment slot** to explain it, but never request an impossible Equip action. Preserve Change 6's context-aware arrows, camp unlock route and tutorial suspension; cover None, Basic and Guided modes.

### 2. Shared weapons, not enemy-specific weapon identities (structural change)

A **Wood Sword** is the same inventory item no matter which ordinary enemy carries or drops it. A Red Scarf enemy can carry a Wood Sword. Evolution creates a **different gear item/tier**, e.g. Wood Sword → Stone Sword → Iron Sword, using existing weapon art. Apply equivalent sharing/progression to other weapon families where supported by owned assets. Harder-stage enemies may carry higher-tier weapons, but the **same weapon type and tier** has the same identity and base stats regardless of the enemy.

Keep outfits tied to their visual enemy type. Audit drop mapping, merge counts, evolution, equipment slots, equip comparisons, passive inventory bonuses, prestige challenges, unlocks, achievements, serialization and any catalog references to old enemy-specific weapons. Avoid duplicate functional items. Preserve present save data where practical via a small deterministic mapping; per Playbook §61, **do not spend excessive time on legacy migrations for unreleased development saves**. Explicitly report if a reset is necessary; never silently destroy current-schema saves. Run only lightweight sanity checks before build-ready; leave exhaustive regressions for Phase B.

### 3. Outfit progression and boss equipment relevance

Evaluate briefly and implement the approved direction **unless a concrete dependency makes it unsafe**: normal outfits of the same tier should have comparable base power irrespective of the stage where the wearer spawns; **farming, merging and evolving** should drive long-term growth. Boss-exclusive gear/outfits should be **meaningfully stronger**, reflecting their limited farming opportunities. Preserve visual identity. Review the currently implemented **30% passive contribution** from owned equipment so shared weapons/outfit changes do not accidentally create either runaway stats or a major difficulty spike. Don't launch a full economy rebalance; expose any remaining balance uncertainty for the developer to playtest.

### 4. Offline prestige discovery and claiming

Discover relevant offline prestige opportunities **after the player has entered the game and explicitly claimed offline earnings**, not during startup/background settlement before the player sees them. Reuse the current claim action if present; otherwise implement a clear, compact claim step if required. Save claim state, prevent duplicate claims across reloads, and preserve existing offline reward math/caps. Do not award or discover repeatedly from the same offline interval.

### 5. Ready prestige cannot be followed

Disable/hide **Follow** for an opportunity that is already ready/completed; validate the rule in the action layer as well as the UI. Existing active follows and other states must behave correctly.

### 6. Prestige access must be clear on the button

The **Prestige button/badge itself** should give first-time users an understandable indication of the current gate (with a short actionable reason where space permits); the panel must show the full reason. Change 6 gates the reset behind **clearing Winter/Winter II in the current run**. **Keep that gate**, because the first Snowman boss can be reached well under one hour and we still want roughly one hour or more before the first reset. Do not invent a physical prestige altar/destination unless the existing design truly requires one; if it does, clearly identify where to go.

### 7. Claimed missions must be recognizable

Distinguish **In Progress / Ready to Claim / Claimed** visibly, including after claiming. Avoid a normal-looking disabled Claim control. Keep completed main-objective status/history discoverable where reasonable. Preserve daily reshuffle, completed mission behavior and reward claim protections.

### 8. Coin Tonic duration

Show its effect and **total duration** in the item description, and make **remaining active duration** visible or readily accessible during the effect. Preserve the real duration and buff logic; this is not a balance request.

### 9. Equipment comparison clarity

Change 6 already implemented **equip-stat deltas and ◀ ▶ item browsing**. Preserve both. Briefly inspect whether the comparison with currently equipped gear is clear at Android size; improve only if genuinely hard to interpret. Prefer a compact selected-versus-equipped comparison with obvious positive/negative deltas; do not enlarge panels unnecessarily or recreate functioning arrows.

### 10. Tap the current panel button to close

Tapping a navigation button for the **currently open panel** should close it. Tapping another should switch to that panel. Do not break sub-panels, item browsing, tab selections, confirmations or Change 6's compact panel layout/fast refresh.

### 11. Reduce initial fog reveal

The player reveals too much of the map when starting. Review **both player and arrival-camp reveal radii**, lower them conservatively, and preserve normal progression and discoverability. Put tunable values in suitable inspector-editable resources/settings as the Playbook requires.

### 12. Boss marker only when boss is active

Show a boss marker on the map **only if the corresponding boss is alive/active**, **and** the existing discovery/unlock rules allow it. Remove stale markers on death/despawn; restore on valid respawn. Don't reveal hidden bosses via a marker.

### 13. Camera recenters after respawn

On player revival, recenter the camera on the player and resume appropriate follow behavior even if camera drag previously detached it. Preserve joystick follow, zoom and normal manual camera interaction.

### 14. World-anchored weather

Falling leaves/rain **must not be positioned relative to camera movement**. Anchor distributions to the world/map while allowing natural particle movement and appropriate coverage. Preserve per-season weather variants; avoid visual jumps on camera pan/zoom.

### 15. Cyan Robot Heal VFX placement

Investigate the reported misplaced healing effect on the robot. Check the **rendered sprite bounds, animation frame, world/local transforms, scaling and effect draw order**, not just actor coordinates. Correct any misalignment with existing effects/assets. Mark final device visual verification as pending if only desktop/headless checks are possible.

### 16. Playtime in Stats

Read Playbook **§17**, especially §17.3. Show **lifetime active playtime** and **current prestige-run active playtime** (and the effective-stat/boost overview if already part of the Stats contract). Exclude background/offline time and paused time. Persist across save/load, keep lifetime time across prestige and reset current-run time on prestige. Avoid redundant separate real/game clocks where simulation has no speed multiplier. Show readable Android-friendly formatting.

### 17. Preserve the Change 6 progression fixes

**No first-boss prestige unlock** in this batch. Leave Change 6's first boss placement, encounter spacing/farming isolation, Winter II prestige gate, stronger prestige rewards and cards, tutorial arrows, item arrows, legible notifications, recovery/potion changes, panel performance, regional exploration and fog migration protections intact. Only touch these systems where one of the above corrections genuinely requires it; record the reason.

## Definition of done

**Build-ready notice (Phase A):** all requested implementation changes are present in the current tree; the editor can import/parse and the game can launch; there are no known blocking source errors. The developer can immediately build an Android APK and begin manual gameplay testing. **This does not depend on finishing test generation or broad regression checks.**

**Final report (Phase B):** concise per-item status; key files/systems changed; focused test pass/fail counts and explicitly deferred checks; 1–2 bounded balance observations at most; any save-reset caveat; quick Android checklist (first consumable drop, early equipment, offline reward claim, mission claim state, prestige access, camp fog, boss map markers, weather pan, healing effect, respawn camera, playtime). Do not exaggerate certainty or include a huge audit/evidence archive.

**Delivery:** Work in the existing tree (do not reapply old ZIPs). Update GDD/decision log and relevant Playbook notes **only for genuinely reusable lessons**. Respect Godot 4.7, owned UI art, localization practices, mobile safe areas, and inspector-driven controls. Do not alter Android version codes/export settings accidentally. The developer will judge final feel and balance on the phone.
