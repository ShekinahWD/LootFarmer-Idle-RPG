# LootFarmer Change 22 — Android Correction Batch

Source: project ZIP dated 2026-10-28 09:35. These are targeted fixes; existing gameplay progression and artwork are unchanged.

## 1. Drop All dialog flicker

- **Root issue:** `game_ui._process` called `_layout_confirm()` every frame. The previous height calculation also added the wrapped label's minimum height to the modal minimum, potentially double-counting and feeding reflow changes back into its own position.
- **Correction:** fit at show time, then perform two deferred settled-layout passes before revealing the modal; recompute only on actual viewport/safe-area changes. A generation token invalidates pending passes on cancel/reopen. The same shared confirmation handles Drop All, Hard Reset and other confirmations. The scrollable message and explicit Cancel / Confirm remain.
- **Device check:** repeatedly open/close Drop All on a long stack description; rotate/test narrow screens; keep dialog stationary for 15 seconds; verify scrolling and both actions still work.

## 2. Automatic Mission Claiming activation

- Upgrade remains **OFF after purchase** (player-controlled). Purchase explanatory text says Auto Claim covers **regular missions including purchased slots**, but **never Main Objectives**.
- An inline hint appears while the unlock has not yet been enabled. The existing centralized guide points to **Missions** when closed and the actual **Automatic Claiming: OFF** button when open, using the shared arrow/frame; it does not introduce a modal. The first ON tap stores `tutorial.seen["mission_auto_enabled"]` (implemented as a string in the seen array), keeping the hint one-time even if the user turns it OFF later. Other Guided lessons keep priority.
- **Device check:** buy Auto Claim, verify OFF, follow arrow to Missions, enable it, claim a complete regular mission in a purchased slot, verify Main Objective still requires manual claim, toggle OFF and reload (no repeated hint).

## 3. Prestige objectives by stage

- Each unlocked stage and General has a touch-sized `▶ / ▼` heading with a **completed / total objectives** counter. Multi-stage objectives appear in every relevant stage, and General contains its existing paths.
- A stage where all its objectives were **consumed** defaults **collapsed**; otherwise defaults **expanded**. Taps override the default. Overrides persist in `prestige_collapsed` on the profile, survive Prestige and reload, and reset on Hard Reset. Old schema-8 saves default to `{}` and invalid entries are stripped on load.
- The Owned Cards and Card Sets sections stay visible and unaffected. Scroll position is preserved by the existing panel reconciliation system.
- **Device check:** inspect an incomplete stage, complete it through Prestige, reopen, expand manually, close/reopen and reload, confirm preference and counters persist.

## 4. Guided tutorial delay measured in real time

- Data values remain **15 s after Merge** and **15 s after closing Missions**; no other tutorial waits were changed.
- The old calculation used `state.playtime_total`, driven by physics `_step(dt)` whose `dt` is capped at `0.1`. Under heavy device load it could take far more than 15 wall seconds to advance by 15 gameplay seconds.
- New saved `tutorial.flow.wait_seconds` accumulates actual `TutorialGuide._process(dt)` frame seconds while the game is **active and unpaused**, independent of physics tick caps. It does not advance while suspended, paused, in Prestige selection or offline. Partial progress survives save/reload and existing `times` values are migrated conservatively.
- **Device check:** use a phone stopwatch for Merge → Missions and close Missions → Upgrades on a slow/loaded device, pause mid-wait and return, force-close and reopen mid-wait, verify delay is ~15 active real seconds and not 45.

## Tests

- Targeted Godot scene: `res://tests/change_22_probe.tscn` (modal stability, 15s elapsed checks, save/load, automation guidance, Prestige headings). Run using project Godot version and inspect `CHANGE_22_CHECKS` summary. **Not executed in this environment: Godot binary unavailable.**
- Static Python checks cover changed symbol wiring, translation completeness and JSON progression delay values.
- No `.godot`, `.import`, Android build or export files in patch. No source Playbook changes: behavior is documented here and in the State Contracts, and can be consolidated into the reusable manual after physical validation.
