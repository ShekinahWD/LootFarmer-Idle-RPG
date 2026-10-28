# LootFarmer — Change 25 Report: onboarding modes and final mobile UI

Date 2026-10-28. Commit "Change 25: correct onboarding modes and finalize mobile UI", on top of Change 24 (`909cf3a`). Brief: `LootFarmer_Change_25_Final_UI_UX_and_Onboarding_Corrections.md`. Application version and Android Release `version/code` **25** (`version/name` stays blank and inherited; the Bootstrap preset is untouched). Save schema 8 and save file version 3 are unchanged.

## 1. Onboarding modes (the critical correction)

**Defect.** Basic and None still used the Change 15 first-profile reveal table: World, Missions, Upgrades, Prestige, Map Mastery and the HUD chips appeared one by one after merges, claims, purchases or player levels, so they behaved like Guided with fewer cards.

**Fix: one authority, `campaign.onboarding.revealed(feature)`.** Guided → `guided_progress.feature_allowed` (its staged lesson reveal, unchanged). Basic/None → always open. Chooser (`pending`) → the saved `onboarding.reveal` list, which is empty on a real profile. Every HUD element, badge, notification sound, the panel opener (`panel_allowed`, the only way into a panel: navigation, character, enemy and camp taps, minimap, banners, trackers, chips) and Help asks this one query. The progressive reveal table and its level backstops (`OnboardingRules.missions_level` … `objective_level`) are removed.

| | Guided | Basic | None |
|---|---|---|---|
| Menus | Staged reveal from the lessons, two 15 s active waits | All open at once | All open at once |
| Teaching | 28 steps with pointers, unchanged | 5 overview cards up front (n/5, Skip, Got it, 20 s auto-advance), then nothing | Nothing |
| Pointers | Lessons, Focused Farming, Auto Claim | None (the Focused Farming and Auto Claim pointers are now Guided only) | None |
| Slots on first choice | Unchanged | Large | Large |
| The Road Ahead | At the Guided end | After the last card or Skip | Right after the choice |

- **Choice handler** (`onboarding.choose_mode`): Basic/None record all six features, mark every menu as opened (no ✦ cascade, no unlock sound) and set `inventory_zoom` = 2. It is called only from the chooser, so reloads, restarts and Prestige never force Large again. A Hard Reset keeps settings and shows the chooser again; choosing Basic or None there sets Large again.
- **Menus are not content.** Opening any menu changes no stage, camp, purchase, currency, discovery, opportunity or Mastery record (asserted by snapshot comparison). Prestige shows its checklist ("✗ Find the Winter I Snowman") and "Prestige locked · find the Snowman"; World offers no travel to an unopened map; the enemy chips still need a discovered type; Map Mastery still names unmet enemies "Undiscovered enemy".
- **Prestige announcement:** in Basic/None the menu was open all along, so finding the Snowman now plays the notification and shows one "Prestige unlocked" banner, latched as `tutorial.seen` `announced:prestige` (no repeat after reload or Prestige).
- **Basic overview deck** (`TutorialGuide.BASIC_DECK`): Walk, fight, collect · Equip and merge gear · Upgrades and Missions · Explore, camps and stages · Prestige and Map Mastery. Help shows the same deck (one data source); in Guided, Help leaves out cards for systems not yet revealed. The old Basic tips, per-feature cards and contextual cards (aggression, skills, groups, rest) no longer appear.
- **Chooser labels:** "Basic · All menus open, a short overview", "None · All menus open, no tips".

## 2. UI/UX findings

| ID | Finding | Result |
|---|---|---|
| REL-03 Android Back | System Back had no handler and `quit_on_go_back` was on (Back quit the app). | **Fixed.** `game_ui.back()` serves `NOTIFICATION_WM_GO_BACK_REQUEST` and Escape: Prestige confirmation → confirmation → panel → on the bare HUD "Leave LootFarmer? Your progress is saved." (saved before showing, again before quitting). Ignored at the chooser; once per frame. `quit_on_go_back=false`. |
| UI-01 | Confirmation stability, Auto-Claim OFF/ON, Prestige sections, 15 s waits, Road Ahead once per mode | Confirmed by change_22/change_25 probes; Basic no longer points at the Auto Claim toggle (Guided only). |
| UI-02 responsive | Followed mission/Prestige trackers measured before their text wrapped: on first appearance they were laid out 426–646 px tall for one HUD tick (0.15 s), covering the map. Found by the new layout probe at 540×960. | **Fixed:** trackers re-lay out on `minimum_size_changed` (deferred) and only write size/position when they change. At 540×960, 432×960 and 360×640 the probe asserts trackers above the joystick, map chips on screen, sheet and Close on screen (Close ≥ 44 px), touch-sized Prestige stage headers (≥ 44 px, ≥ 16 px text), the pinned Prestige action reachable, a long confirmation on screen, and the Basic card inside the map above the joystick. |
| Inventory & Filters | 70 slots at Small/Medium/Large, supply slots, scrolling, layout cache | Confirmed (probe: 70 slots and a scrollable grid at each density; change_24 layout-cache checks still pass). No change. |
| Panels | Scrollbars, headers, counters, Main Objectives manual, blocked reasons | Confirmed by change_21/22/25 probes and captures 06–08. No change. |
| World map/camps | Camps visible/tappable without Map Details, tap vs drag, travel rules, no spoilers | Confirmed by change_20/21 probes. No change. |
| UI-06 / AST-03 | Countdown, labels in rain/fog, fog shader, culling | Desktop captures 10–11 at zoom 1× and 3× show no fog colour or shape regression and no missing actors at the wide zoom. Phone check remains (below). |
| AST-02 audio | Music, pause, volume | `change_16_audio` windowed: 11/11. No change. |
| Help/Settings | Help without staging, languages, no dev controls | Confirmed (change_16 probe; Help now uses the overview deck). |

Not changed (deferred by the brief): the `game_ui.gd` scene refactor, balance, content, localization, store assets, demo, packaging.

## 3. Verification

- **Final maintained suite** `python tools/run_probes.py`: **33/33 pass** (validator + 32 Godot scenes), no script errors, no timeouts. Validator 1,574 checks; Godot probes 5,783 checks plus two smoke runs. New entry `change_25_probe` (113 checks: chooser state; Basic/None every navigation button and 11 panels plus character/minimap/Mastery chip/banner paths; no progress change; locked Prestige and travel; silent opening; enemy chips follow discovery; one Prestige announcement; save/load; slot size first choice, reload, Prestige, Hard Reset, Guided unchanged, 70 slots per density; Basic deck size, texts, counter, Skip, auto-advance, non-blocking, no later cards across gear/merge/camp/low HP/Auto Claim/Snowman/Focus, Help, reload, Prestige; None nothing after Road Ahead; Guided 28 steps, 15 s waits, saved partial progress; Back priority, de-duplication, notification, Escape, chooser; three portrait shapes; versions).
- The first full run gave 32/33: `change_6_probe`'s "guide takes no input" invariant did not know the new Skip button (an intended control, like Got it); it now allows exactly that button.
- **Updated stale contracts (not weakened):** change_15 (reveal table → mode access; Basic deck; None "menus open throughout"; audio uses Guided for the hidden-Missions case and the Snowman for the unlock cue; World offers Map Mastery before the Snowman in None), change_16 (Mastery chip hidden in Guided, shown in None; Help asserts the deck; objective check without the obsolete reveal fixture), change_14 (Focused Farming pointer asserted in finished Guided; Basic and None get the confirmation only), change_21 (Basic Road Ahead after the deck), change_22 (Basic: no Auto Claim pointer; Guided targets the toggle), change_24 (version check ≥ 24).
- **Desktop captures** (`tests/change_25_capture.tscn`, windowed, Forward Mobile, GTX 1650) in `docs/Change_25_Evidence/ui/` at 540×960 and 432×960: chooser, Basic first and last card, None Road Ahead, None HUD with every menu, locked Prestige, Map Mastery, Player Upgrades, Back exit confirmation, Spring II rain under fog at 1× and 3×, respawn countdown at 1× and 3×. Desktop evidence only.
- **Benchmark** (`python tools/run_benchmark.py`, non-gating, once): Spring II rain farming mean 5.66 ms (Change 24: 5.2), save 14.5 ms / 74.7 KB (14.8 / 74.7), unchanged inventory refresh 0.42 ms (0.42), stage switches 43–175 ms (52–183), simulation step p50 1.94 ms (1.97). Change 24 gains intact. Startup first two frames 999 ms (522) is the only outlier; nothing in this change runs at startup beyond one extra button, so it is most likely a cold shader/disk cache after the capture runs; worth one look in the next benchmark.

## 4. Development saves

No reset. Schema 8 / file version 3 load unchanged. A development profile already in Basic or None gets every menu at once on load (no stored data needed); a Basic profile that had not seen The Road Ahead shows the new five-card deck once. Old `tip_*` / `feature_*` seen keys are ignored. Guided profiles are unaffected.

## 5. Ordinary phone checks (when convenient)

1. Fresh install (or Hard Reset) → choose **None**: every bottom button works at once, slots are Large, only The Road Ahead appears.
2. Hard Reset → **Basic**: five short cards, Skip works, then The Road Ahead; nothing else later.
3. Press the Android **Back** gesture: with a panel open it closes; on the bare map it asks "Leave LootFarmer?"; Cancel keeps playing.
4. Follow a mission and a Prestige opportunity: the trackers appear at normal size above the joystick.
5. On Spring II in rain, glance at the fog edge and zoom out fully: no odd fog colours, enemies do not pop in at the screen edges.

## 6. Documents updated

GDD (Change 25 section; Change 15 menu-reveal, Basic, None, UI-05 and Focused Farming lines marked superseded), State Contracts (Change 25 section; Change 15 reveal evaluation and `focus_hint` marked), Test Suite, Design README, Reusable Playbook §18.2 (menu disclosure per game/mode vs. content gates; first-choice presentation defaults; overview modes) and §18.10 (mode-dependent single reveal query, entry-path audit). Historical reports are unchanged.
