# LootFarmer — Playtest Corrections: Prestige, Focus Farming, Joystick, Onboarding, Drops, Discord

**Implementation handoff to Claude Code**  
**Scope:** One focused gameplay/UI/onboarding correction change, before Localization Batch 03.  
**Expected change:** Next chronological Change after Change 40 (`9175683`); determine actual number from local Git history.  
**Authoritative sources:** Current local repository and its canonical `docs/Reusable_Game_Development_Playbook.md`; the latest GDD, State Contracts, Test Suite, and Change 35–40 reports. The previously uploaded ZIP may not reflect later commits; **do not use it to overwrite newer local files**.

## 0. Mandatory workflow

1. Read the *current* Playbook and the relevant code, scene structure, catalog, tests, and docs. Follow established principles for editable UI/resources, state-driven onboarding, touch arbitration, scrolling/modal sizing, save compatibility, localization, evidence, and tests.
2. Investigate the cause of each issue before implementing. Prefer the smallest correct, maintainable change, with configuration in visually editable scenes/resources when appropriate.
3. Implement all six changes below in the existing working tree. Do not remove, reset, or silently commit unrelated developer edits or untracked assets.
4. Update the canonical English source, **all 10 currently enabled non-English catalogs where text changes**, runtime UI refresh, and relevant tests/docs. Use idiomatic game terminology rather than literal translation. English + the 10 existing released-ready locales must remain complete; preserve nine unfinished drafts. Keep locale readiness and export packaging working.
5. Verify gameplay and visuals at relevant portrait phone/tablet shapes, plus actual touch/gesture arbitration where automatable. Run focused probes first and the full maintained suite **once at the end**; report actual pass counts and unrelated working-tree failures precisely.
6. After validating, document **only new reusable lessons** in the correct Playbook sections, without duplicating existing rules. Add a concise Change report and evidence. Automatically commit the scoped work as the next chronological Change, without pushing.

## 1. Prestige collection: show the true item requirement

**Reported issue:** For Prestige objectives that ask for specific collected equipment/items, a player who acquires exactly the displayed quantity is told to obtain one more item when attempting to submit.

**Approved outcome:** If a collection submission requires one additional copy (for example, a retained copy plus copies consumed), **request that extra copy up front**. The player should never be told only at submission that one more is needed.

- Trace the actual objective contract: counted inventory quantities, equipped/retained copy, disposable copies, submitted/consumed copies, and any stage/map-specific variants. Preserve existing intentional retention semantics; do not blindly add one to tasks that already count correctly.
- Make the **displayed target, progress numerator/denominator, readiness predicate, submission validation, follow tracker and any explanatory text** use the *same authoritative requirement*. Do not implement a UI-only `+1` that leaves another surface inconsistent.
- Example: if the previous card said `Collect 10` but the genuine submit predicate requires 11 available, the objective must explicitly request **11** and display progress toward 11. If 10 really should be sufficient, correct the underlying faulty predicate instead; document which model the current design intends and why.
- Distinguish collected-ever counts from available-to-submit quantities; never promise readiness based on an item already spent, merged, equipped, or otherwise unavailable. Preserve legitimate equipment and do not consume an unexpectedly equipped last copy.
- Check normal, exact-count, one-short, one-over, multiple equipment groups, submission/reload, and post-Prestige transitions. Existing profile compatibility matters.

## 2. Focus Farming: defend against attackers without abandoning the focus

**Reported issue:** Traveling toward a Focus Farming location can pull unrelated enemy aggro. The hero then ignores those enemies and stands taking damage when no focused enemy is currently available.

**Approved targeting order:**

1. **Available eligible focused enemies** are the normal priority.
2. **Enemies actively threatening/attacking the hero** are the fallback priority when no focused target is eligible.
3. Otherwise **wait or return to the selected farming spot**, rather than wandering after unrelated enemies.

- Inspect the real target-selection, auto-attack, navigation, attack-range, aggro, death/respawn and focus variant systems. Fix the decision in the shared combat decision path, not by a UI workaround.
- Defensive fallback must work while approaching the selected focus spot and while waiting on its respawns; otherwise the character can be helpless. Do not pull the hero across the map after unrelated enemies, permanently retarget Focus Farming, or attack passive non-focused targets just because they are nearby.
- Define a sensible threat criterion (actual attacker / hostile actively engaged, not merely a visible unit) and choose a reachable threat with deterministic tie-breaking. Handle target disappearance, repositioning, manual targeting, skill/auto-attack behavior, and priority restoration when a focused enemy becomes eligible again.
- Preserve the player's movement commands, existing Focus Farming variants (weapon/outfit/both), stages, teleport/combat restrictions and save compatibility.
- Add deterministic tests with focused enemies alive, dead/respawning, out of range, aggro acquired during travel, multiple attackers, manual override, and empty/non-threatening surroundings. Show that enemies *do not* trap the player in a defenseless loop.

## 3. Joystick position setting: Left / Center / Right

Add one player-accessible, saved **Joystick Position** setting with exactly **Left**, **Center**, and **Right**. Default **Center** for existing profiles unless the established design indicates a safer compatible value.

- Move the joystick **only within its existing bottom-HUD zone**, keeping height, sizing, usable thumb space, safe-area clearance and movement feel consistent. Do not relocate other major UI controls or cover the skill bar, buttons, trackers, map interaction, or touch targets.
- Use responsive anchors/containers or editable scene settings rather than hardcoded pixel offsets; inspect narrow phones, tall phones and tablet portrait sizes, including notch/safe-area conditions.
- Make thumb interaction, multi-touch, manual enemy-target drag and camera input continue working. The joystick must not swallow intentional world-targeting gestures or let world touches activate the joystick accidentally.
- Apply changes immediately, survive save/relaunch and reset only according to existing settings-reset rules. Localize the label and the three choices. Test all three positions in portrait layouts and in the Guided tutorial.

## 4. Onboarding readability and joystick discovery

A real playtester missed the joystick and found the tutorial choices insufficiently obvious. Improve both **without changing progression/balance between Guided, Basic and None**.

- **Mode chooser:** Make Guided / Basic / None choices visually distinct, large enough to tap confidently, with clear concise descriptions of what each mode provides. Preserve equal underlying gameplay economy and the exact tutorial mode semantics. Do not disguise None as a recommended beginner option.
- **Movement lesson:** During the initial guided movement lesson, visually indicate the **actual joystick position** and demonstrate how to operate it using the existing pointer/guide style. Recompute the pointer when the setting/screen size changes. A brief temporary emphasis is fine; **no permanent explanatory HUD text**.
- **Basic cards/Help:** Clarify the movement/joystick control succinctly and keep the deck's single shared source; preserve the existing drag-to-target lesson from Change 35. No duplicated decks or contradictory instructions.
- Complete required guided actions on real events, not arbitrary timers; keep existing safe fallbacks and old-save reconciliation. Do not insert intrusive overlays that block the very control being taught. Respect modal/gesture priorities and Back behavior.
- Review the tutorial mode picker and joystick teaching in real rendered frames at several portrait sizes; include evidence both with the default center and one alternate joystick position.

## 5. Equipment-drop feedback: clearer, still fast

Audit the **current actual loot/drop/ground-item effects and animation pipeline** first, including what becomes hard to see at gameplay speed and when many enemies die.

Approved direction: improve the readability and satisfaction of **real equipment drops** without slowing farming, faking loot, introducing a new economy, or obscuring combat.

- Prefer adjusting existing VFX/assets, spawn/scale/fade/easing/z-order or short feedback effects over introducing unrelated art. Use existing licensed art and keep parameters editable.
- A drop should be legible when it appears and remains collectible at its real location; distinguish equipment from ordinary action effects. Avoid excessive particle clutter or delay before pickup.
- Check single item, weapon + outfit together, multiple simultaneous kills/drops, auto-collection, fast combat, small phone preview and performance. Avoid altering drop rates, rarity, pickup semantics, seeds or inventory limits.
- Provide before/after evidence or timing/visibility observations supporting the visual choice. If existing behavior is already suitable after inspection, report that rather than manufacturing an unnecessary change.

## 6. Settings: one button labelled **Discord**

Place a single visible button under the existing **Settings** interface with the exact English label:

**Discord**

It should open this approved invite URL:

`https://discord.gg/zbr9RH6QWa`

- **Do not add a Community section, category or heading.** The user explicitly requested a straightforward **Discord** button in Settings.
- Follow the Playbook's centralized external-link practice: keep the URL in one clearly identifiable configuration/source location; use a platform-compatible URL opener for Android and Windows. Prevent duplicate presses or touch-through if relevant.
- Preserve game state; failure to open a browser should fail gracefully without a blocking gameplay crash. Do not invent a Discord integration, embedded browser or authentication flow.
- Treat **Discord** as an intentional proper name in the translation catalogs (no forced translation); audit it as a player-visible string consistent with the localization system. Verify layout and reachability after adding the button.

## 7. Localization, production and compatibility

- Current validated languages: English plus `es_419`, `es_ES`, `pt_BR`, `fr_FR`, `de_DE`, `it_IT`, `nl_NL`, `pl_PL`, `ru_RU`, `uk_UA` (as Change 40 reports). **Any new/changed player-visible keys must have natural translations for every enabled language.** No new locale can silently fall back to untranslated English just because new text was added.
- Keep the existing dropdown, Automatic resolver, enabled-languages readiness list, Godot locale mapping, runtime refresh and export allowlists intact. The nine unfinished draft locales remain hidden/excluded. Do not start Batch 03 in this change.
- Add/update only necessary English keys and catalogs, verify placeholder integrity and player-facing text coverage, and check that long translations don't break the updated UI.
- All features must preserve save/Prestige/Hard Reset behavior and avoid breaking current tutorial or normal game progression.
- Source of truth is the **current Git working tree**, not the earlier ZIP. Preserve any unrelated user-local version/icon edits and untracked localization/ASO files; clearly report baseline failures without touching their cause unless necessary and authorized.

## 8. Acceptance tests and deliverables

**Targeted evidence expected:**

- Prestige objectives show the quantity actually needed; submitting at the displayed target works without a surprise extra-copy demand. Include a regression for the reported exact-count case.
- Focus Farming prioritizes focused enemies, then **active attackers** when focus is unavailable, and returns to the intended location/priority thereafter. Show no chase or helpless damage loop.
- Joystick left/center/right placements are visible, touch-safe, persistent and correctly reflected in guided movement hints.
- Tutorial choice buttons and descriptions are clearer, with a demonstrably easier-to-find movement control.
- Actual equipment drops are more readable without changed loot odds or blocked pickup; demonstrate representative cases.
- The **Discord** button is directly inside Settings, opens the **exact URL**, and is usable on Android/Windows; no Community header is introduced.
- English and all ten enabled translations pass catalog/key/placeholder checks, visual sweeps and export readiness requirements; the nine drafts remain unavailable.
- Run relevant static/build tests and targeted scenarios, then the complete maintained regression suite **one time at the end**. Provide accurate counts, errors, hashes and any limitations; do not claim device testing without a device.

**Deliverables:** implementation; updated game-specific docs/GDD/State Contracts/Test Suite as appropriate; localized strings; relevant automated tests; annotated screenshots/contact sheets; concise Change report; minimal validated reusable Playbook additions where missing; one scoped next-Change Git commit **without push**. Report all changed files, validation results, any real-device checks still needed and the commit hash.

**Out of scope:** Localization Batch 03, new stage/boss balancing, marketing screenshots/trailer/icon, ASO, Discord community management, replacing current locale infrastructure, unrelated feature development or silent final-boss tuning.
