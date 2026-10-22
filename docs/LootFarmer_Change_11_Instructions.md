# LootFarmer — Change 11: Prestige HUD, Minimap, Camp Travel, Death Dialogue, Supplies & Filters

**Implementation brief for Claude | Baseline: latest committed Change 10 (`4dcc7d4` implementation, `ca0819f` tests/docs), plus any subsequent valid current commits**

## Goal and source of truth

Implement **all six Android-playtest corrections** in the current Godot project, then review and clean up obsolete tests. Work from the **current repository**, not an older ZIP or outdated assumption. Read the current in-repository **Reusable Game Development Playbook** (especially its guidance on Android UI, playable-build handoff, consumable healing/balance, testing and development saves), the current GDD, Change 9–10 notes, and the actual inventory, camp, map, Prestige and supplies systems before editing.

**Scope:** preserve working Change 10 functionality, existing equipment/outfit/skill progression, enemy farming guide, prestige reset/card rules and visual maps unless directly affected below. Prioritize existing assets, compact touch-friendly UI, inspector-editable data where practical, and direct fixes over architectural rewrites. Do not initiate an unrelated balance/pacing overhaul.

**Save policy:** this game is **pre-release**. Per Playbook §61.1, **do not spend time migrating old development saves**. Update the save version or reset old test profiles if needed. Current-schema save/load and reset must still be correct. Preserve any developer-owned uncommitted changes, especially `export_presets.cfg` Android version, signing and export path; don't blindly clean untracked `.import`/`.uid` files.

## 1. Compact followed-Prestige tracker: Winter Collection must not reveal specific required loot

The **small lower-left on-screen follower** should show just the Prestige **name, prestige icon, current step/next objective, and concise progress**. The **Winter Collection** follower currently tells the player exactly which items to gather; remove that spoiler from the small HUD tracker.

- For collection objectives, display a generic instruction and progress, e.g. `Step 2/3 · Collect items · 2/5`, **without item names, gear IDs, item icons or identifying descriptions**. Preserve the Prestige's own icon.
- The **full Prestige panel** remains the authoritative place for detailed requirements and explanations. Do not strip details from it.
- Preserve other Prestige followers' useful guidance and progress; don't apply a generic collection label to unrelated steps.
- Maintain compact lower-left placement, safe-area bounds, readability, updates during play and unfollow behavior. If progress is not meaningful at a particular step, use a concise actionable generic label rather than false numbers.

**Acceptance:** follow Winter Collection at each collection stage; its HUD tracker shows objective/progress but does not name the items. Open the full Prestige panel and confirm complete requirements remain available.

## 2. Minimap: larger, recognizable enemy markers

Currently enemy markers look like **tiny dots** and don't clearly represent discovered enemies. Make the small gameplay map meaningfully usable on a real Android screen.

- Use a **recognizable enemy icon/portrait** from existing assets rather than a dot. Increase marker sizes, and **enlarge the minimap itself if necessary** to accommodate them.
- Retain **one marker per discovered encounter spot**; don't collapse different equipment groups into one indistinguishable marker.
- Visually distinguish a spot's loadout (weapon-only, outfit-only, both, and skill-bearing where applicable) using clear, restrained equipment/skill overlays. The actual enemy identity must remain readable.
- Handle groups close together, different map sizes and zoom/UI scaling without markers merging into an unreadable pile. Prefer a practical larger map or deliberate layout/offset approach over shrinking icons back down. Use available space without covering joystick or essential HUD.
- Preserve **discovery/privacy rules**: never reveal undiscovered enemy locations or identities because of Map Details, a map opening, the Farming Guide or an icon change. Maintain current alive/discovery behavior for boss markers.
- Keep performance reasonable and avoid per-frame rebuilds of static markers.

**Acceptance:** on each representative map a discovered enemy spot can be identified by icon and loadout at Android-target sizes; undiscovered spots are absent, and neighboring spots remain individually distinguishable.

## 3. Camp Teleport must travel to another unlocked camp

The camp menu's **Teleport** option currently teleports to **that same camp**, making it useless.

- Tapping **Teleport** opens a compact **destination picker** listing **eligible previously unlocked camps**. Clearly identify destinations (camp name/map or another existing recognizable identifier), indicate current camp and selected target, and allow cancellation.
- Selecting a different unlocked camp teleports the player to **that destination**. Do not present the current camp as the only actionable destination; disable it or omit it from valid choices.
- Respect the existing world/stage access model when determining eligible destinations. Support travel across maps only through valid existing world-travel rules; don't invent bypasses of stage unlocks.
- **No teleport during combat.** Apply the restriction both when opening/choosing and immediately before executing the move. Do not charge/deduct resources or partially move on a blocked attempt.
- Arrival, player spawn position, camera recenter/follow state, camp selection highlighting and proximity-triggered camp-menu behavior must remain coherent. Teleport arrival **must not force-open/retrigger** an unwanted camp menu, consistent with Change 10's camp-enter behavior.
- Handle 0 or 1 unlocked camp, current camp only, another stage, pause/modal interaction and narrow touch screens gracefully.

**Acceptance:** unlock two camps, open Teleport in one, select the other, arrive at the other camp; blocked in combat; inaccessible/locked destinations cannot be chosen; teleporting to the same camp isn't the only action.

## 4. Gate loot-related *enemy death speech*, not loot notifications

Specific issue: on death, an enemy may display speech such as **“HEY, MY OUTFIT!”** even when it **did not actually drop that outfit**. This request is **not** about the game's loot pickup notifications.

- Find the enemy's **on-death dialogue/speech-bubble** selection and connect loot-related lines to the **final actual drop outcome**, after all drop rolls.
- Outfit lines appear **only if an outfit actually dropped**; weapon lines only for an actual weapon drop; skill/supply lines only when their referenced item actually dropped, if such lines exist.
- If no item matching a loot-related line dropped, do **not** show that loot line. Unrelated flavor/death speech can stay unchanged.
- If several eligible items drop together, show at most the existing intended number of speech bubbles using a consistent selection rule. Don't accidentally roll items twice or grant duplicate rewards to justify a line.
- Do not change the ordinary loot notifications, reward probabilities, pickup effects or economy.

**Acceptance:** no-drop death cannot say “my outfit”; outfit-only and weapon-only drops may trigger only matching dialogue; existing loot notifications still work.

## 5. Expand supply variety; permanently merge duplicates; set capacity to real catalog size

The game presently exposes **13 supply slots while effectively offering only two supply types**. Create a **small, meaningful catalog of distinct supplies**, then set the available supply capacity to the **actual number of obtainable unique supply identities**, not an arbitrary 13. Don't add filler just to use 13 slots.

### Supply design

- Inspect the **current** supply/consumable catalog, art, drop sources, auto-use behavior, cooldowns, inventory presentation, buffs and upgrade paths. Preserve useful roles of existing **Potion** and **Coin Tonic**, while adding several supplies with **distinct strategic purposes** (e.g. defense, recovery, short damage boost, where these don't duplicate skills). Choose the final number, unlock timing and effects based on existing mechanics and assets.
- Keep them **discoverable, usable and obtainable** through existing stage/drop/economy channels. Balance availability so they don't all appear immediately, but aren't decorative unobtainable catalog entries. Avoid introducing new art that isn't in the asset pack; reuse approved existing icons intelligently and keep them distinguishable.
- Give the player clear descriptions of **effect, amount, duration, cooldown, use condition, and currently active status** where applicable. Respect inventory and auto-use semantics, existing cooldown limitations, skill overlap and boss-fight balance. Avoid free permanent buffs, unlimited emergency healing, or duplicated effects that trivialize combat.
- All supplies are **consumable in use** but **their mastery/merge progression is permanent**: gaining duplicate copies advances a persistent merge/mastery level; spending a supply charge must **not** lower its merge level. Keep **stock/charges** separate from **lifetime merge progress** and explain both in UI. Do not create another inventory identity every time a supply improves. Make the merge cap/growth and milestones appropriate for consumable frequency; follow the **outfit progression concept**, not blindly its HP formula. If existing supplies already have compatible permanent progression, reuse and extend it instead of rewriting.
- Evaluate whether supplies' permanent growth is triggered automatically when a new copy arrives (preferred for consumable flow) or through a sensible existing control; do not require the user to keep consumable stock untouched forever to improve it.
- Apply the exact resulting number of **active, obtainable supply types** as maximum supply capacity. Existing purchases/upgrades involving supply capacity must be made consistent (no purchasable unreachable slots, no UI implying 13 are necessary). **Equipment inventory remains capped at 70 independently.** Current-schema save, consumption, auto-use, offline rules and hard reset must remain valid.
- Update enemy drop research details/Farming Guide and supply inventory/filter categories for newly obtainable items. Make no unnecessary economy adjustments to equipment or boss drops.

**Acceptance:** multiple useful supplies can actually be acquired; each has working use/auto-use and readable effects; consuming it reduces stock but retains permanent mastery; merging increases effect within bounded limits; supply slot cap equals obtainable distinct supply types; no dangling tier/evolution identities.

## 6. Move inventory filtering to main HUD as **Filters / Filtros**, clear on close

The current filtering/management panel is nested under **Upgrades → Inventory**. This is inconvenient, and persistent filters make the inventory appear empty after the filter panel closes.

- Expose an appropriately sized **Filters** shortcut **next to the gear inventory count** on the main gameplay HUD (e.g. `12/70  [Filters]`). Label it **Filters** in English and **Filtros** in Spanish when that locale exists; use the project's current localization workflow rather than inventing a separate language system.
- Tapping it opens the **existing filter panel directly**, with its working filter options. Don't create a duplicate implementation of the filtering rules.
- Remove/rename the now-redundant **Upgrades → Inventory** navigation entry that was only for filtering, but **preserve actual inventory capacity purchases and upgrade controls** if they share that screen/section.
- **Every way of closing Filters resets ALL active inventory filters immediately** and restores the full inventory: X/Close, toggle button, Back, outside dismissal if supported, navigation to another panel, or programmatic close. Reopening Filters should start **unfiltered**.
- Preserve **sort order** separately if sorting is an independent preference; resetting filters must not erase or sell items, change inventory counts, or affect equipped slots.
- The shortcut and panel must fit Android safe areas and not interfere with existing currency/health/joystick/buttons. The label and state must communicate what's selected while the panel is open.

**Acceptance:** open Filters, apply a filter that returns zero items, close it by each supported method, confirm the inventory immediately shows all items; reopen starts unfiltered; sort unchanged; Inventory Upgrades remain functional.

## 7. Legacy test cleanup: let the current design decide what survives

Change 10 reported that older probes (`change_1`, `ui`, `inventory`, `progression`, `gameplay`) fail or time out on the Change 9 baseline as well as Change 10. These pre-existing failures should not be left as unexplained noise.

**Review these after the game implementation is build-ready**, alongside the deferred Change 11 tests:

1. Inspect **what each old probe is trying to prove**, its current entry point/fixture, and why it fails or hangs. Follow the Playbook's stale-test diagnosis (§60): real regression vs outdated expectation vs invalid fixture vs test harness/timing.
2. **Keep and repair** tests whose behavior is still part of the game's current contract. Update assertions/fixtures to the approved mechanics; use bounded waits/timeouts and fail loudly instead of hanging. If a genuine game bug is revealed, fix it rather than deleting the test.
3. **Delete obsolete tests** that explicitly validate features/rules removed from the game; remove their unused scenes/scripts, runner references and documentation. Consolidate duplicated tests when a newer probe already covers the same contract adequately. Do **not** delete meaningful coverage merely to make all counts green.
4. Publish a **short test-disposition table**: test name → kept/fixed/deleted/consolidated → one-sentence reason and current replacement coverage if deleted.
5. Establish a **small, clearly supported maintained regression set**; distinguish any non-gating historical evidence/benchmarks. Do not run obsolete or repeatedly timing-out tests in the default suite.

No extended pacing bots, repeated battle campaigns or multi-hour validation. Run focused tests that disprove the six features; do one bounded regression pass on the maintained suite when stable. The developer will assess actual Android usability and balance.

## Delivery order — IMPORTANT

**Phase A — Gameplay, UI, supplies, and navigation implementation**

1. Implement sections **1–6** in full. Run only basic compile/smoke/small essential checks to avoid handing over a knowingly broken project. **Defer most test generation, suite runs and legacy test cleanup.**
2. Commit the completed **gameplay implementation** with a descriptive Git commit, selecting relevant files only and preserving developer-owned unrelated modifications.
3. **Immediately post this exact build-ready notice in chat** with the correct commit hash, so I can build and test on my Android device:

   **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   **Commit: `<exact hash>`**  
   **🧪 GENERATING AND RUNNING THE REMAINING FOCUSED TESTS AND REVIEWING LEGACY PROBES.**

**Phase B — Deferred focused validation and old-test cleanup**

4. After the notice, build/adjust focused checks for each acceptance condition above, run the bounded maintained tests, classify and clean up stale/obsolete probes under section 7. Review current-schema save/load and reset for new supply state.
5. Fix any defects found. **If a correction changes gameplay or UI after the first build notice, make a new implementation commit and send a new build-ready hash immediately**; explain that earlier APKs are superseded. Tests/docs-only commits don't invalidate the earlier APK.

**Phase C — Documentation and completion**

6. Update game-specific GDD, catalogs, state contracts, UI/localization copy, and Change 11 notes. Amend the Playbook **only for a genuinely reusable new lesson**; don't change its rules to accommodate a game-specific preference. Commit tests/docs/cleanup changes descriptively, and report whether the working tree contains only intentionally uncommitted developer-owned/generated files.
7. Final chat report: concise status table for the six fixes, chosen supply catalog + exact slot cap, behavior of permanent supply merges, legacy-test disposition, test outcomes, commit hashes, and **Android-only visual/touch checks**. State clearly what was **not** tested on a phone.

**Do not stop after announcing build readiness.** Continue with deferred checks and documentation. The build-ready notice exists so the human can playtest while you finish verification.
