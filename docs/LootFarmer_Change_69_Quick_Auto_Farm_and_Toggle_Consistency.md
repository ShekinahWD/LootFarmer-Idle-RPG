# LootFarmer — Change 69: Quick Auto Farm, Manual-Movement Countdown & ON/OFF Visual Consistency

**Status:** Approved implementation brief — 11 November 2026.  
**Baseline:** Latest local Godot working tree after Change 68 (`60a86d7`) and all prior changes. Inspect the actual repository before modifying anything; older ZIP archives and GDD historical entries are not authoritative.  
**Process:** Follow the current Reusable Game Development Playbook and the game's canonical GDD. In particular, follow the established HUD/surface ownership, one-action/state-source, onboarding/pointer, translation, safe-area, focus/save and local-commit practices. Do not modify the Reusable Playbook.

## 1. Approved user-facing requirements

### A. Quick Auto Farm action below nearby enemy controls

When the existing contextual controls appear because the player is near a discovered enemy group, show **three vertically stacked actions in this exact order**:

```text
[ Achievements  ]
[ Upgrades      ]
[ Auto Farm OFF ]   <- red when this enemy isn't the active farming target
```

When **this same enemy type/variant/spot** is the currently selected active Focused Farming target, render the single bottom control as:

```text
[ Achievements ]
[ Upgrades     ]
[ Auto Farm ON ]    <- green
```

- **One button only**: show either `Auto Farm ON` or `Auto Farm OFF` according to live state; never two mutually exclusive buttons. **The Farm button belongs BELOW Upgrades**, not next to it.
- OFF tap: activate the currently contextual enemy's existing Focused Farming action (or switch the active target from another group). ON tap: explicitly stop Focused Farming immediately, with no countdown.
- Color is **target-specific**: if the hero is focused on group A, group B shows OFF (red), even while Focused Farming globally remains active. If focus switches, the previous button reflects OFF. Treat the currently selected farming target and eligibility according to the authoritative current game logic; do not invent a second focus registry.
- Focused Farming remains a **global, one-time 25-Gem Player upgrade**. Before the unlock, make the quick control clearly locked/unavailable, state why, and give the same route to the Player upgrade as the existing enemy-panel Farm action. No free unlock, hidden charge or second purchase. A locked/unavailable state is distinct from user-selected OFF (see colors below).
- **Keep the Farm / Stop Farming control inside the enemy Upgrades panel**, and keep both controls synchronized via the **same single state owner and action handler**. Do not alter Auto-Collect, Auto-Merge or Auto-Evolution ownership or mechanics.
- Preserve existing target eligibility (discovered spots, reached stages, correct enemy identity/variant, restrictions, pause/death/combat rules, and current farm/respawn behavior). If the context changes while standing near overlapping groups, correctly label which group the quick control affects, reuse existing contextual enemy selection, and avoid accidental target switching.
- Respect HUD layout and touch input at **432×960 and 540×960**, including safe-area insets, short and long translations, and contextual-controls appearing/disappearing. Do not shrink the existing Achievements/Upgrades controls into unusable targets or obscure game/navigation/tutorial elements.

### B. Focused Farming cancels only after 5 continuous seconds of manual walking

The hero currently stops Focused Farming immediately after manual movement. Replace that **manual-movement cancellation** with the following:

1. A genuine player-controlled walking input immediately gives manual directional control. **The selected farming target remains active** while the player is moving manually, and the hero must not fight the joystick with auto-navigation.
2. Starting with the first continuous qualifying manual walking input, count **5.0 real seconds** (not simulation time and not accelerated by game speed). During the countdown, visibly communicate the pending cancellation, e.g. **`Turning off Auto Farming in 5…`**, then `4…`, `3…`, `2…`, `1…`. Position it so the warning is readable without obscuring movement controls, gameplay, or active Guided instructions.
3. If the player releases the joystick/stops qualifying manual movement before the full 5 seconds, **reset the timer immediately**, hide the countdown, and seamlessly resume traveling to/farming the selected enemy. Subsequent walking starts a new full five seconds, never adds partial sessions together.
4. On reaching the full 5.0 seconds **continuously** walking, stop Focused Farming **once** via the existing authoritative stop action. The quick button and enemy-panel button both become OFF immediately; dismiss the countdown and provide a concise, nonintrusive confirmation if the existing UI convention warrants one.
5. Explicit `Auto Farm ON` tap remains an **immediate** stop. Explicit selection of another group switches immediately (and cancels any pending movement countdown). Death/respawn, automatic farming/navigation, auto-attack, game speed, animations, camera movement or other non-manual motion **must not count** as the five seconds. Do not cancel Focused Farming merely because the character's position changes.
6. Define qualifying manual movement from **actual active joystick/walk input after deadzone processing**, not tiny touch jitter, UI taps or drag-to-target gestures. Respect legitimate keyboard/controller walking input if supported by the current game. Do not let paused gameplay or a blocking panel silently advance the countdown. Hide/reset the countdown when manual walking no longer qualifies (including interruptions such as death and map transitions).
7. Preserve selected farming target through ordinary death/respawn and save/load as currently designed. The **transient countdown itself need not be saved**: on reload return to the saved Focused Farming state with no half-completed timer. Continue to honor intentional non-walking focus-stop/switch actions; inspect such paths and report any potentially conflicting existing rules rather than silently rewriting unrelated mechanics.
8. Use a single source of truth for target, ownership and cancellation; if manual movement currently clears focus from multiple call sites, reconcile all relevant paths rather than patching a button-only symptom.

### C. Red OFF / green ON throughout the game's binary toggle buttons

Audit **all user-operable binary ON/OFF buttons** across gameplay panels and Settings and give them a consistent visual vocabulary:

| Semantic state | Presentation |
|---|---|
| ON / enabled by the player | **Green**, plus an unambiguous `ON` / `Enabled` label or equivalent icon + text |
| OFF / disabled by the player | **Red**, plus `OFF` / `Disabled` label or equivalent icon + text |
| Locked / unavailable / blocked for a separate reason | **Clearly distinct disabled/locked treatment** (not a misleading green ON; explain the reason) |

- This is a **styling and state-clarity pass**, not a gameplay/settings rebalance. Maintain existing preferences, purchases, saves, underlying actions, and enabled/disabled rules.
- Use the project's **existing authored UI assets/themes** and preferably one shared state-style helper; do not create arbitrary raw-color rectangles in a pack-constrained UI or independently hardcode colors for each screen.
- Distinguish **state** from ability to press a control: a toggle that is ON but momentarily blocked by a modal should not claim to be OFF. Determine live states from their authoritative owner, and update reliably when changes originate from another surface.
- This requirement applies to genuine binary ON/OFF controls. **Do not recolor unrelated buy/claim/confirm/destructive buttons, selection chips, level/upgrade progress, multi-choice controls or passive status indicators merely because they contain an on/off-like word.**
- Preserve readable label contrast and icons so colors are not the sole state indicator; make buttons large enough for touch and long locale strings.

## 2. Guided / Basic / Help compatibility

- Inspect the current Guided tutorial's Focused Farming introduction and active hand/pointer targets. If it teaches where to activate Farm, make its pointer/target and instruction **accurate for the quick action now present near a group**, while retaining the enemy-panel Farm action as an alternative. **Do not add unnecessary new mandatory tutorial steps**; reuse existing event/state-driven lesson completion, and keep Basic/None uninterrupted.
- If the Basic/Help Farming demo or help copy implies Focused Farming stops on any tiny movement, update it to **5 continuous seconds of manual walking**. Explain the new quick control where useful, without introducing an oversized tutorial.
- Reuse the existing tutorial/notification arbitration so the countdown does not cover guidance, action targets or milestone banners. This countdown is live, transient status, **not** another persistent tutorial lesson.
- Preserve the intended **automatic return after death** and existing 25-Gem global purchase description.

## 3. Save, localization and documentation

- Preserve existing profile schema where possible; no new currency cost, re-migration, refund, paid unlock, prestige rule, gameplay progression or drop/equipment modification.
- Countdown is runtime state only. Persistent focus ownership/target remain compatible with old saves. Confirm Prestige/Hard Reset follow existing behavior; don't change their rules.
- Add/update **English** localized strings only as needed, and record new, edited and retired keys under `change-69` in the existing pending-localization tracker. **Do not edit the 19 non-English catalogs.** Keep countdown wording localizable (including dynamic number) and avoid user-visible hardcoded English.
- Update the canonical game-specific GDD and relevant Help/Upgrade Catalog/test documentation for the new focus-off rule and quick action. Do **not** update the Reusable Playbook.

## 4. Focused validation and acceptance

Implement a targeted Change 69 probe in the existing test conventions and register it in the maintained runner. Run relevant existing focus, automation, Guided, UI and save probes; use lightweight scene interactions and actual rendered screenshots at **432×960 and 540×960**. Avoid extended simulations and a full suite unless a concrete dependency requires it.

Required checks:

1. Nearby contextual controls render **Achievements → Upgrades → one Auto Farm OFF/ON**, vertically, with usable touch rectangles. OFF is red and ON is green; locked differs. The same active target appears consistently in both Farm controls. Group A ON and group B OFF; switching updates them both.
2. A locked global Focused Farming purchase blocks quick activation with an explanation/route to Player Upgrades; an existing 25-Gem owner can activate without another charge. Existing enemy automation still behaves independently.
3. Continuous manual joystick walking 1–4.9 seconds shows the decrementing 5→1 countdown **without** stopping focus; releasing cancels the countdown, resumes farming and resets it. Two separate 3-second movements must **not** cancel focus; a single full 5-second movement must cancel exactly once.
4. At 3× game speed (if available), cancellation still requires ~5 **real seconds**, not ~1.67 s. Paused/blocked time and non-manual movement do not count. Small joystick/touch jitter doesn't trigger it.
5. Explicit OFF tap stops immediately; explicit switch to another target updates live UI; ordinary death and respawn retain target and do not advance countdown. Save/reload mid-countdown resets only the countdown, not ownership/target. If current code has other cancellation actions, inspect them for semantic consistency.
6. Audit and screenshot real binary ON/OFF buttons in relevant panels and Settings: green/ON, red/OFF, disabled explanation, contrast and touch bounds, with labels reflecting real saved state.
7. Run a quick Guided Focused Farming hand/pointer check to ensure it points to an actual actionable control, and verify it doesn't conflict with the countdown; Basic and None retain their behavior. Inspect mobile screenshots with contextual stack and countdown, including a pseudo-long label where feasible.

Document any pre-existing failing probes separately (do not modify unrelated mechanics solely to turn them green). Report what was and wasn't validated on Android (desktop captures are not device certification).

## 5. Local Git commit and reporting

1. Read live current GDD, Playbook and source; inspect `git status` and preserve all unrelated developer edits/untracked assets.
2. Implement and validate the three approved requirements as one focused batch.
3. Stage only owned paths and create **one local commit**:

   `feat(change-69): add quick auto farm and movement countdown` 

4. Report actual button placement/behavior, every toggle surface updated (and any deliberately excluded), countdown edge cases, tests/screenshots, pending English localization keys, changed files and commit hash.
5. **Do not push, export, publish, or modify developer version numbers.** Android acceptance comes later.
