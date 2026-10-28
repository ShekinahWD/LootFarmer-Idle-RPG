# LootFarmer — Change 25: Final UI/UX & Onboarding Correction Batch

**Task type:** Implement the full approved correction batch in Claude's **current repository**, update documentation, verify once at completion, and **commit autonomously**. Do not use an attached ZIP as the source baseline.

**Latest known baseline:** Change 24, commit `909cf3a09cfd6ec107bf4fa9a29fde131e6251ca`, project/Android Release version 24, save-file version 3; maintained suite **32/32**. First confirm the actual branch, HEAD, worktree, current code and current docs, and derive the next Change number from Git rather than trusting this description blindly.

**Authority and references:** Read the current repository copies of `docs/Reusable_Game_Development_Playbook.md` (especially §§16, 18.2–18.10, 19–21, 44, 56, 60.1, 61.1, 63.1, 125, 128–129), `docs/LootFarmer_GDD.md`, `docs/LootFarmer_State_Contracts.md`, `docs/LootFarmer_Test_Suite.md`, `docs/LootFarmer_Change_24_Performance_Report.md`, `docs/LootFarmer_Full_Production_Audit_Report.md` (§§4.3–4.4, 6.1–6.3), and the newest implementation files. The developer's decisions here supersede the **previous universal menu-reveal requirement** in the old GDD/Playbook. Preserve unrelated gameplay and economy decisions.

## 1. Non-negotiable decisions: three genuinely different onboarding modes

The current defect: **None and Basic are still governed by progressive first-profile menu reveals, as though they were Guided with fewer or no arrows.** Correct the underlying visibility/authorization behavior, not just the tutorial display.

| Contract | Guided | Basic | None |
|---|---|---|---|
| Menus/features available immediately | No; keep action-based staged reveal | **Yes, all navigation and ordinary panels** | **Yes, all navigation and ordinary panels** |
| Teaching | Keep current detailed interactive Guided steps, including two 15-active-real-second waits | **Only a short up-front overview of ~3–5 concise cards**; no staged lesson chain | **No instructional cards, arrows, tips, or delayed teaching** |
| Arrows/pointers/forced actions | Current Guided only | **None** | **None** |
| Inventory slot display size on initial mode choice | Preserve current Guided default/behavior | **Large** | **Large** |
| The Road Ahead | One time at the existing Guided conclusion | Once **after** final overview card | Once **immediately after** choosing None |
| Normal game progression | Unchanged | Unchanged | Unchanged |

**Definition of “all menus unlocked”:** Every ordinary HUD navigation control and direct entry path must be **visible and usable immediately** for Basic and None: World/maps/camps, Missions and Main Objectives, Player Upgrades, enemy information/upgrades, inventory and Filters, Prestige, Map Mastery, Settings/Stats/Help, and related controls, badges, minimap and progression HUD surfaces. Audit the actual first-profile feature reveal table and ALL panel-opening/interaction gates, not just visibility flags. Do not leave controls invisible, non-clickable, or silently blocked because `first_profile` / `onboarding.reveal` is incomplete. No artificial tutorial/level/merge/time gate may delay their opening.

**Crucial separation:** Opening a menu is **not** granting content. Unavailable stages, undiscovered enemies/camps/gear, purchased upgrades, Prestige redemption, Map Mastery rewards, keys, mission slots and special abilities must retain their **normal game rules**. A newly opened panel should accurately show a locked state, prerequisites, or empty/undiscovered content instead of granting the item. Avoid spoiling undiscovered enemy positions/identities. Keep the early merge-compatible equipment drop guarantee and ordinary combat/balance identical across all three modes.

**Prestige specifics:** The Prestige menu and Map Mastery navigation are open from the beginning in Basic/None, even before the Snowman is found. Do not grant Prestige access to *redeem cards or reset* early: the existing Snowman-discovery/ready-opportunity gating remains the gameplay authority. If the existing code conflates menu revelation with the gameplay Prestige unlock, separate the concerns and make the panel communicate the remaining requirement. Likewise, having World open must not bypass stage/camp ownership or travel-in-combat rules.

### None — immediate unguided play

- After selection, dismiss the chooser, reveal every available navigation surface at once, initialize **Large** inventory slot density and leave the player fully free to act; no tutorial-milestone progress required to open UI.
- Show the approved **The Road Ahead** announcement exactly once, directly after selecting None. This is the **sole intentional onboarding-message exception**. No automatic Auto-Claim arrow (already removed in Change 24); only ordinary inline description in the relevant panel when applicable.
- No Basic tips, contextual tutorial cards, directed hints, timed lesson prompts, mode-specific game-balance rules, or mandatory tutorial waits. Ordinary milestone/achievement/boss notifications remain game feedback, not lessons.

### Basic — short explanatory overview, not unguided Guided

- Immediately reveal the same full menu set as None; initialize **Large** inventory slot density.
- Display **3–5 short, practical overview cards** on first selection, covering core movement/automatic combat, collecting/equipping/merging gear, Upgrades/Missions, exploration/camps/World, and Prestige/long-term goals as appropriate; 4 or 5 cards is fine if content remains readable. Be concise and accurate to the real mechanics. Reuse the current **Help/reference deck and existing card renderer/data** where practical rather than creating a second drifting set of descriptions. Do not over-explain locked abilities or spoil future content.
- Cards are **dismissible/skippable** and do not block game systems, actions, menu opening or the player's freedom to explore. No later per-menu cards/tips/arrows, mandatory tasks, timed unlocks, or guided state machine. Basic is a compact informational introduction only.
- The approved **The Road Ahead** appears once after the last overview card (including an early skip/dismiss if the deck is skipped); use the existing non-auto-dismiss confirmation policy. Ensure no duplicate after save/load, Prestige or opening Help.

### Guided — preserve existing working lessons

- Keep the existing sequence of 28 completed steps, interactive pointers, progression-based feature revelation, saved partial progress, safe pointer arbitration, two 15-active-real-second waits and current final Road Ahead presentation. No unapproved shortening or balancing changes.
- Guided continues to use normal gameplay rules for combat/drops/economy. The change is **mode-specific menu access and teaching**, not three divergent combat simulations.
- Avoid any regression in Guided on fresh profile, pause/resume, reload, Prestige or Hard Reset.

### Slot-density initialization and persistence

- The stored `settings.inventory_zoom` contract is **0 Small / 1 Medium / 2 Large**. Explicitly apply **2 (Large)** when Basic or None is first chosen, unless this would overwrite a user-selected layout on a continuing profile; handle initial selection vs reload deliberately.
- The player can still change size at any time; later reloads, Prestige and normal app restarts must **not** silently force Large again. Hard Reset follows existing settings retention rules; if the chooser is presented again, handle the first-choice default deterministically and document it. Do not change inventory capacity, scrolling or slot controls.

### Single authority, saved lifecycle and test fixtures

- Reconcile onboarding mode selection, first-profile `REVEAL`/menu gating, the feature-availability API, HUD visibility, panel opening, enemy interactions, Prestige/Map Mastery panel access, direct shortcuts and UI badges through **one coherent authority**. Do not fake completion by awarding gameplay progression or opening a Stage 2+ map.
- Ensure fresh Basic/None, saved/reloaded Basic/None, Prestige and Hard Reset behave correctly. The mere opening of full menus must not trigger a cascade of incorrect tutorial alerts or repeat feature-unlocked audio.
- Existing probe fixtures such as `--first-run-complete` and `onboarding.reveal_all` may remain as **test-only helpers**, not requirements a Basic/None player must invoke. Update affected tests to the approved new contract.
- This is development (Playbook §61.1). Old development saves **do not require backward-compatible migrations**. If incompatible data demands a reset, document it; current-version save/load must still function.

## 2. Final UI/UX corrections and validation from the production audit

These are the remaining UI findings and verification gaps. **Inspect first and make targeted corrections where actually needed.** Avoid cosmetic redesigns or changing a previously accepted layout simply because a checklist names it. If a finding cannot be verified without a real Android device, perform desktop window/capture and input-path checks and report the phone-only remainder honestly.

1. **Android Back navigation (REL-03):** Implement/reconcile Android system Back (`NOTIFICATION_WM_GO_BACK_REQUEST` and `application/config/quit_on_go_back` as appropriate) with in-game `ui_cancel`. Priority: cancel an open confirmation → close an open panel/overlay → handle bare-HUD back safely (do not silently quit/lose progress; a user-understandable exit/quit confirmation or explicit background action is acceptable). Respect overlays and prevent duplicate handling/touch leakage; save correctly on exit/background. Test desktop escape and notification dispatch as far as possible.
2. **Latest Change 22/24 presentation (UI-01):** Confirmations stable (no per-frame relayout or flicker), Auto-Claim **OFF/ON** guidance correct for Guided and never an arrow in Basic/None, Prestige collapsible stage sections and counters work, and Guided active real-time waits remain 15 s. Preserve The Road Ahead one-time flow for each mode.
3. **Responsive layout & safe areas (UI-02):** Check portrait **540×960**, narrow **20:9** and at least one smaller viewport/simulated safe inset. Ensure tracked mission/Prestige cards don't overlap joystick, objectives/Next Stage/map chips aren't obstructed, banners don't cover open modals, bottom sheet pinned actions remain reachable, readable fonts/tap targets are preserved. Fix actual clipping/overlap issues only; never “solve” by shrinking text below comfortable size.
4. **Inventory & Filters:** Verify 70-gear-slot Small/Medium/Large grids, six supply slots, pinned items, scrollbar discoverability, drag-scroll/tap-versus-hold, and density changes after Change 24's layout caching; avoid needless refresh work.
5. **Prestige/Missions/Upgrades/Mastery panels:** Check scrollbars, touch-sized stage headers, long descriptions, stage counters, Owned Cards/Card Sets, selected collapse-state persistence, Main Objectives still manually claimed, Auto-Claim toggle presentation, clear blocked reasons where a panel is visible but the gameplay system is not yet available.
6. **World map/camps:** Confirm camps remain visible and tappable in the expanded map without requiring Map Details, camp buttons/hit areas are usable, tap vs drag is correct, travel restrictions still apply, and map/minimap do not reveal undiscovered enemies or map content. Verify after Change 24 world-scene cache and shader changes.
7. **World text & effects (UI-06 / AST-03):** Respawn countdown remains legible at min/max zoom; HUD and enemy HP/names/damage numbers readable in rain/overcast; effect positioning/scale/layering on 2× and 2.5× bosses and with simultaneous casts is sane. **Watch the new fog shader for visible colour/shape regressions** and off-screen actor culling for pop-in at wide zoom. Only change actual failures and keep pixel-art style and weather quality.
8. **Audio (AST-02):** Check existing music/pause/volume behavior and cue overlap using the existing desktop/windowed check if available. Do not replace the accepted music or asset set without a concrete defect.
9. **Help, Settings and no-tutorial mode:** Verify Help/reference content is usable without staging, language list remains Automatic + English until localization, tutorial choices persist, settings work while paused, and no internal development controls accidentally become public UI.

**Deferrals:** Do not refactor the entire large `game_ui.gd` into editor scenes now (audit UI-03 recommends after release). Do not change core battle/economy balance, late-stage content, localization, store assets, demo generation, packaging allowlists or audio provenance in this batch. No mandatory Android profiler or elaborate manual phone test rig.

## 3. Implementation and verification strategy — one batched pass

1. Start from the current clean Git repository. Read current Playbook and live contracts, inspect code and find all mode/reveal/panel access paths. Do **not** trust the older audit to describe current Change 24 code perfectly.
2. Implement the **entire Change 25 onboarding correction and justified UI fixes together**, including self-contained automated assertions and any necessary locale strings. Ensure scene/theme/resource inspector editability for visual configuration when practical.
3. **Minimize repeated expensive runs.** During implementation, use syntax/import checks and **small targeted tests only when needed for debugging**. Do not run the full maintained regression suite for each individual correction.
4. Once implementation is complete, run the **full maintained suite once as the primary final gate** (`python tools/run_probes.py`). If it fails, distinguish stale expectations from real regression, repair and rerun the affected probes, then do one final complete run for a green result. Do not weaken assertions to manufacture green tests.
5. Include/adjust an explicit Change 25 probe for: all-mode fresh UI/menu accessibility; direct alternate panel paths; Basic cards/skips/no pointers; None complete absence of teaching except Road Ahead; slot default & change persistence; Guided sequence and waits; reset/reload/Prestige; menu-open != gameplay-unlocked; Back navigation; scroll and relevant widget layout. Check no script errors/timeouts, and record exact counts.
6. Use **automated desktop rendered capture evidence** for representative UI states and screen shapes. Preserve visual appearance and previously measured Change 24 performance optimizations; if a change affects hot paths, run the **non-gating desktop benchmark once at the end** and check for a material regression. Do not claim Android FPS or device visual acceptance based on desktop checks.
7. If high-value real-device verification remains (Android back gesture, fog shader first frame, touch targets, effects under rain), supply a **short ordinary-play checklist**, not profiler/ADB procedures or a request to grind to Stage 8. The developer will test naturally when convenient.
8. Update the authoritative GDD, State Contracts, Test Suite, Design README and relevant change report. Update the reusable Playbook's **owning §18.2/§18.10** (and other directly relevant sections only) to record a reusable principle: onboarding *instruction depth* can differ by mode, and a game can choose to reveal ordinary menu navigation immediately in Basic/None while retaining normal gameplay gates; menu visibility must not be conflated with progression purchases/content. Preserve the Playbook's existing Growing Kingdom examples as historical examples, do not impose LootFarmer-specific mode defaults on every game, and do not add another large game-specific appendix. Explicitly supersede contradictory old text in active documents; retain historical reports.
9. **Autonomous Git workflow is mandatory.** Verify next sequential Change number from Git (expected **25**). Align `project.godot` `config/version` and Android **Release** `version/code` to it (keep inherited blank `version/name`). Do not needlessly alter utility/bootstrap signing presets. Stage only this change's code, docs and tests; never include secrets, ignored generated builds or unrequested developer changes. **Commit all finished work yourself** following the current line of commits: suggested message `Change 25: correct onboarding modes and finalize mobile UI`. Do **not push** unless separately authorized. Report commit hash and clean/dirty status. If HEAD differs, preserve unrelated work and name the appropriate next sequential change.

## 4. Acceptance criteria / definition of done

- [ ] **None:** every ordinary menu accessible instantly, inventory Large, no tutorial teaching/arrows/delays, Road Ahead once; gameplay gates intact.
- [ ] **Basic:** every ordinary menu accessible instantly, inventory Large, ~3–5 brief skippable overview cards only, no progressive lesson chain/arrows/delays; Road Ahead once after overview; gameplay gates intact.
- [ ] **Guided:** existing sequential onboarding and 15-second active-real waits pass end-to-end; reveal logic remains intact.
- [ ] Every mode correctly persists after save/load and Prestige, with Hard Reset returning to the chooser; user-changed inventory density is not overwritten on reload.
- [ ] Android Back handling implemented with correct overlay and panel priority; UI responsive/scroll/tap issues corrected where reproducible.
- [ ] Change 24 performance gains not inadvertently undone; fog/culling appearance checked in desktop captures and phone-only uncertainties stated.
- [ ] Updated dedicated probes plus final maintained suite **all green**, with actual counts and no script errors; tests not weakened to mask regressions.
- [ ] Docs reconciled, reusable principle integrated in Playbook, application/Android Release version aligned, implementation report created.
- [ ] **Claude commits automatically** under next sequential `Change N` and reports the commit/hash; no push, no exported Android build or publication unless explicitly instructed.

## 5. Final response format

Give a concise but complete developer-facing report: **implemented changes by ID**, three-mode behavior table, confirmed vs unconfirmed UI findings, validation command/results, any desktop visual/performance evidence, current development-save reset effect, documents changed, remaining **ordinary phone checks**, exact commit message/hash and Git status. Distinguish implementation evidence from phone validation and do not ask the developer to manually commit.
