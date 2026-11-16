# LootFarmer — Implementation Audit, Corrections & Visual Polish

**Handoff:** 2026-11-12  
**Suggested change identifier:** Change 70 (confirm the actual next identifier from repository history before naming the commit).  
**Mode:** Investigate the **already-integrated** changes, correct worthwhile issues, visually validate, test, and commit. This is **not** a request to rebuild the features from scratch.

## 1. Context and authority

The developer has **already extracted the latest ChatGPT-generated change ZIP into the real LootFarmer Godot project** and is testing it in Godot. Treat the **current working tree** as the starting point, including uncommitted edits. Do not replace it with an older ZIP, reset it, discard existing work, or assume the ZIP's implementation is correct merely because static checks passed.

**Read before acting:**

1. `docs/Reusable_Game_Development_Playbook.md` — authoritative reusable process, especially sections **16, 18.8, 19/19.1, 44, 46, 48, 60/60.1, 61, 68, 92, 121, 125, 127 and 128–129** where relevant.
2. The current project source, scenes, data/resources, tests, localization and any existing authoritative game design documents.
3. This brief. The screenshots in the developer's conversation illustrate actual UI problems; **verify the current project visually rather than relying on code inspection or the screenshots alone**.

**Workflow:** Audit each requirement against the implementation; reproduce defects; fix the underlying cause; validate appearance and behavior in a running Godot project; add/update focused regression tests; run maintained tests that can be executed; inspect the diff and make **one local Git commit** for the completed batch. Do **not** push. Report the commit, tests, findings/fixes, current game version and any physical-Android checks still needed. Do not create a separate status report or competing design document.

### Guardrails

- Existing gameplay, saves, player assets, translations, onboarding, accessibility and unlocked systems must continue to work.
- Make focused changes instead of unrelated redesigns. Prefer a consistent source of truth, stable UI layout, reused theme controls and explicit save contracts.
- For the Cartoon Coffee VFX pack: **NEVER delete files needed or potentially needed to recreate ANY effects in Godot**, even assets not currently used. Preserve relevant Unity prefabs, materials, shaders, scripts, metadata, texture slicing and timing sources. Reuse the existing art; do not replace it with generated art.
- Any animation/VFX is presentation only: loot, currency, Prestige and saved state must be committed by the game systems, not by VFX callbacks.
- Do not declare responsive/mobile quality verified from headless checks alone. Distinguish editor/windowed evidence from physical-Android testing.
- Before editing, inspect `git status --short`; preserve unrelated uncommitted developer work. Avoid adding large generated evidence files to Git.

## 2. Newly reported issues — **must resolve**

### 2.1 Inventory filtering and sorting must operate on the **main inventory** and persist

**Current problem:** In the extracted implementation, **category filtering temporarily hides gear slots while Filters is open**, but closes back to All; **sorting only reorders the list inside the Filters panel**, not the actual gear grid. Neither preference is retained when leaving the panel. The goal is a persistent organization preference controlling the **main inventory**, not a temporary panel-only effect.

**Required behavior:**

- The existing categories in Filters should filter the actual main gear inventory, whether the Filters panel is open or closed. Sorting choices (**Default, Tier, Evolution, Quantity**) must rearrange how items appear in that same main inventory, not just sort the panel list.
- The Filters panel should show the same filtered/sorted view as the dock; a choice updates the dock immediately.
- **Persist both selected category and sorting mode** across panel close/reopen, stage travel, Prestige, application exit and launch. They are presentation preferences, not an item ownership rule; use the established saved-settings mechanism where suitable. On older saves, default safely to the current full/default view. Define an appropriate reset-to-default behavior for the Settings/Hard Reset pathway in line with existing preferences.
- Sorting stays current as tiers, evolution readiness and quantities change. Make ordering deterministic (stable tie-breaks), and use meaningful ranking when evaluating **Evolution** (e.g. ready-to-evolve before progress toward eligibility); do not silently mutate owned items to display them.
- **Critical:** Gear slots currently bind actions to numeric backing indices. After visual reordering/filtering, quick-tap, long-press, selection, equip, merge, evolve, tooltips, drag/scroll and tutorial focus must still target the correct **item and source slot**. Empty-slot behavior, equipped slots, inventory capacity, supply slots and all saved quantities must remain correct. Prefer a view-to-backing-slot mapping rather than rewriting `sim.state.gear` merely to sort.
- Clearly show the current preference, offer an obvious Default/All choice, and avoid recreating the entire grid every frame.

**Preliminary source pointers to verify:** `scripts/game/game_ui.gd`: `inventory_filter`, `inventory_sort`, `_inventory_panel()`, `_sorted_inventory_ids()`, `_refresh_slots()`, `_clear_filters()`, `_activate_slot()`, `_select_slot()`; `scripts/autoload/settings_state.gd` for persistent preferences. In the extracted version, `_clear_filters()` resets both settings on close; `_sorted_inventory_ids()` is only used to render the panel list.

**Acceptance:** Change a sort/filter, close the panel, visibly inspect the actual inventory; interact with several distinct items; save/reload; advance/Prestige; compare order and selected actions with the real inventory records. No items disappear from saved data.

### 2.2 Reorganize the top-right map HUD

The minimap sits too far down and consumes an awkward middle portion of the screen. Reposition it as a compact **top-right stack in this order**:

**MINIMAP → ZOOM SLIDER → MAP/STATUS MESSAGES**

- Put the **minimap at the top-right**, safely inset, rather than low near the middle. Put the **zoom slider immediately below** and map-status information/messages below that, with clear consistent gaps. Include relevant chips such as explored percent, stage/gate guidance and any nearby context messages without creating duplicate status text.
- Transient messages/toasts/banners should fit in their appropriate priority/notification region without overlapping other HUD elements; they do not have to be forced into a permanent space if their purpose differs from map status.
- Keep minimap tapping/open-map behavior, zoom functionality, safe-area spacing and other game overlays. Do not stretch the minimap or make it too small to interact with comfortably.
- Build/validate a layout that responds to viewport size, content visibility and safe area instead of relying exclusively on hardcoded offsets. Check tall/narrow phones, 16:9, tablet and notch/gesture inset scenarios.

**Pointers:** `scenes/game/main.tscn` nodes `Safe/Layout/Map/MiniMap`, `Zoom`, `Explored`, `Gate`, `Objective`, etc.; `scripts/game/game_ui.gd` `_refresh_explored()`, `_refresh_gate()`, `_refresh_objective()`, notice/toast positioning and HUD layout logic.

### 2.3 Lift left HUD controls and eliminate overlapping trackers

The **enemy name**, **Achievements**, **Upgrades** and **Auto Farm** controls must move **higher**, with uniform breathing room, so **three followed objectives at once** (one Mission, one Prestige objective, one Mastery objective) fit without collision.

- Reserve real rectangles for every tracked objective; ensure tracker stacks respect joystick placement, changing text height and visibility.
- Keep controls readable and tap-safe; do not fix by merely shrinking everything or shifting the conflict elsewhere.
- Check all supported joystick positions and localization expansion. Ensure notices, the minimap/status stack and guided tutorial elements also avoid the reserved areas.

**Pointers:** `scenes/game/main.tscn` `EnemySection`, `Achievement`, `EnemyUpgrades`, `QuickFarm`, `FollowTracker`, `MissionTracker`; `scripts/game/game_ui.gd` `_layout_trackers()`, `_notice_blockers()` and dynamic `mastery_tracker`.

### 2.4 Remove redundant permanent Winter I boss message

Completely remove the permanent HUD text **“Farm until you can beat the boss”** (the existing `OBJECTIVE_WINTER_BOSS` overlay). Followed objectives already convey progression. Reclaim its layout space and remove stale dependencies/empty reservations, **without removing the real boss unlock, boss spawn, stage gate, tutorial rules or legitimate temporary notifications**.

**Pointer:** `scripts/game/game_ui.gd` `_refresh_objective()` and related scene `Objective`. Review `_refresh_gate()` because its placement currently depends on the Objective's height.

### 2.5 Small, consistent Follow/Unfollow buttons in ALL three panels

Mastery, Missions and Prestige currently present different follow controls (some oversized colored bars).

- Reuse the **normal small game button** dimensions and theme, with consistent card padding and location. Never fill a whole card width solely to show Follow.
- **Follow = red; Unfollow = green**, consistently in all three systems. Ensure the color applies regardless of the underlying button family/default theme, while maintaining legible contrast and touch hit area.
- Preserve actual eligibility, saved follow choice, tracker interaction and transitions. Do not silently change the number of simultaneous follow slots.
- Audit the same styles in unfinished/completed/ready/disabled states and across translations.

### 2.6 Remove the unnecessary “Next:” row from the compact followed-objective display

The developer's screenshot shows a followed objective with a **“Next: …”** line that wastes HUD space. The **compact in-game followed-objective tracker should show the **current actionable requirement and progress**, not a preview of the next step. This particularly applies to the Prestige follow text where `_refresh_follow_tracker()` currently uses `campaign.follow_summary()` containing an optional `FOLLOW_NEXT` line.

- Remove/omit the **Next** line in the compact followed HUD card while retaining the important current-action line and progress.
- It is acceptable—and useful—to keep future-step details **inside the full Prestige/opportunity details panel** where space is available; do not globally strip the information from every context by accident.
- Validate the reduced tracker height and the three-tracker stack in actual UI, including collection, expedition, trophy and other multi-step opportunities.

**Pointers:** `scripts/game/campaign.gd` `follow_summary()`, `scripts/game/game_ui.gd` `_refresh_follow_tracker()`, Prestige panel rendering, localized key `FOLLOW_NEXT`.

### 2.7 Supplies purchases must look like a real shop and support bulk quantities

The current **Player Upgrades → Supplies** purchase area is a group of plain text buttons. Replace it with compact, coherent **shop rows/cards** using existing assets:

- Each purchasable supply shows **item icon, name, price per unit, owned count, quantity to buy, and total Coin cost**. Use normal shop hierarchy and touch-readable controls; preserve the existing scroll behavior and all five authored consumables.
- Support quantity presets **×1, ×5, ×10, ×25** plus a **Custom** positive integer choice (bounded appropriately). One selected purchase quantity is shared among items.
- **Remember the last selected amount** as the default for subsequent purchases, even after closing/reopening the panel and restarting the app. Old profiles default to ×1. Keep the selected value until the player changes it. Do not silently reduce the chosen quantity to fit the player's wallet.
- Calculate total from the authoritative per-unit Coin price; update it on quantity/currency changes; show a clear, actionable insufficient-coins/inventory-capacity reason. Disable purchase when the whole requested quantity cannot be acquired.
- Purchase must be **atomic**: charge `unit price × selected count`, add exactly that many items, or leave both money and stock unchanged; guard invalid/negative/huge custom input and overflow. Verify capacity/stock behavior against the actual inventory model before choosing the exact validation path.
- Existing `purchase_consumable()` buys only one. Implement a single authoritative bulk transaction rather than looping the visible button callback in a way that could partially buy or partially credit progression. Preserve the correct single purchase action semantics for tutorial/missions if applicable.
- **Buying is not using:** purchases never advance Supply Mastery; normal/auto successful uses still do, at **5 uses per level**. Verify current unlocked automation and supply-slot behavior.

**Pointers:** `scripts/game/game_ui.gd` `_buy_supply_actions()`, `_supply_panel()`; `scripts/game/simulation.gd` `purchase_consumable()`, `can_add()`, `pay()`, `add_item()`; `scripts/autoload/settings_state.gd`.

### 2.8 Fix sudden Coin-upgrade price jumps — audit the **whole Coin-upgrade economy**

**Observed:** an upgrade's next Coin cost jumps from approximately **38** straight to **200+**. The developer suspects this affects multiple Coin upgrades. Such a discontinuity is unacceptable unless explicitly explained by an approved milestone (none was approved here).

**Important probable cause to investigate, not assume as the only cause:**

- `scripts/game/campaign.gd` `upgrade_cost()` applies the early-price factor to a subset of upgrades only during their first five levels.
- The extracted `data/game/catalog.json` has `progression.economy.cheap_first_upgrades = [coin_amount, group_xp, loot]`, `cheap_first_levels = 5`, and `cheap_first_factor = 0.25`. Removing a **75% discount in a single step** would create a roughly fourfold cost discontinuity exactly at that boundary, before normal growth and map factors. Audit this first.

**Required audit and correction:**

1. Enumerate **all Coin-priced upgrades**, including type, boss-specific, global, camp/map, skills and unlocks where applicable. Calculate each price for every meaningful level, especially levels **1–10**, capped tracks and each map/stage price scale. Include discounts and Prestige effects. Identify abrupt jumps by ratio and absolute cost (not just one anecdote).
2. Compare prices against actual Coin income, unlock timing and affordable progression. Follow Playbook section 92: assess major Coin sources and sinks together. Check whether the 38→200+ symptom originates in the cheap-first boundary, stage scaling, another special condition or several interacting ones.
3. Replace unreasonable price cliffs with a **smooth, intentional curve** while keeping the first few upgrades inviting and mid/late-game upgrades meaningful. A transitional discount taper or adjusted schedule can work; **do not automatically divide all prices by four**, flatten the entire economy or change Gem pricing.
4. Verify purchasing and UI labels use one authoritative cost function, caps/max statuses work, and saved upgrade levels remain compatible. Preserve the approved **boss minimum 15-second respawn** and its Coin-upgrade progression.
5. Add deterministic pricing tests at level boundaries, across multiple stages/groups and before/after a Prestige/discount; record representative before→after sample prices in the final response so the developer can judge the revised curve. If economic pacing profiles/test harnesses are present, run the relevant subset rather than guessing.

**Pointers:** `scripts/game/campaign.gd` `upgrade_cost()`, `map_cost_factor()`; `scripts/game/simulation.gd` `buy_upgrade()`; `data/game/catalog.json` upgrade definitions and economy progression; existing upgrade UI.

## 3. FULL AUDIT of the 13 previously integrated changes

The latest ZIP introduced or changed these features. For **each**: inspect implementation and scene/UI, run the relevant gameplay scenario, fix correctness and meaningful UX/performance defects, add/update probes, and report whether it was **verified as-is** or **fixed**. Treat the constraints below as the approved design; do not silently substitute new design decisions.

| # | Change to confirm | Acceptance and regression checks |
|---|---|---|
| 1 | Inventory filter/sort by **Tier, Evolution, Quantity** | Must work on **real main inventory**, persist choices, and not break slot mapping (section 2.1). |
| 2 | Follow **one specific Mastery objective** | One chosen category/objective for a reached map, proper Follow/Unfollow buttons, progress accuracy, tracker navigates to correct map/category, persistent state. |
| 3 | **Winter I Mastery** reward | Replace former `+10% Coins` with **+2 percentage points Gem Chance**; verify the actual modifier and localized description, no duplicate award. |
| 4 | **Autumn II Mastery** reward | **+5 percentage points Gem Chance**, not the former +2; verify reward after save/reload/Prestige and UI text. |
| 5 | Notification vs followed-objective overlap | Temporary notices, Auto Farm off, 100%-explored and event banners do not cover up to three trackers, tutorial targets or other important controls; queue/delay if no safe region. |
| 6 | Boss Coin upgrade reduces respawn time | Per-boss upgrade to minimum **15 seconds**, including bosses starting at different cooldowns; countdowns, saved boss state and UI update correctly, cap and affordability correct. |
| 7 | Boss item drops ×1→×5 | Four paid levels, **five independent item-drop rolls at ×5**, **NOT five guaranteed item drops**. Use the original drop probability/eligibility per roll; no duplicate extra rewards from one kill. |
| 8 | Boss-roll Gem costs | **25, 35, 50, 100 Gems** for ranks ×2 through ×5. No stage multiplier applied where flat prices are intended; stop at ×5; check persistence and all boss varieties. |
| 9 | Supplies mastery through Prestige | Supply Mastery **tier and used-progress survive Prestige**; **5 successful uses per mastery level** rather than 3; old-save migration retains earned ranks; stock/current effects follow their existing run-reset rules. |
| 10 | Daily missions through Prestige | Preserve mission selection, progress, completion and claimed status during Prestige; **normal real daily reset still happens** on its intended day boundary, with no extra reward/re-roll or stale-day bug. |
| 11 | Bulk evolution | Evolve several copies of the same eligible item in one coherent action; preserve a required owned copy, costs/availability, target counts, messages, visuals and any mission/achievement credit; insufficient copies never produce partial unintended effects. |
| 12 | Prestige celebration VFX | High-quality, readable, satisfying in actual Godot at phone scale; asset, timing, layering and performance improvements per section 4. |
| 13 | Merge All | Permanent unlock price **500 Gems**; once unlocked, merge action remains free; old saves and existing unlock owners remain valid; no duplicate charges/results. |

**Especially check save/reset contracts:** death, new run, Prestige, stage travel, save/load, real daily reset, offline resume and Hard Reset. No permanent upgrades, bonuses or daily status should be lost/rewarded twice. Verify compatibility of pre-change saves, not just fresh profiles.

## 4. Prestige VFX — real visual polish, not just code review

The scripted effect may be technically valid but poorly composed at the real **Godot camera zoom, pixel-art scale, player placement and map backgrounds**. Claude should **run the scene and visually inspect/capture** the full sequence.

**Target sequence, preserving the approved idea:**

1. **Reveal** owned Prestige card/path icons arranged legibly around the player (or a tasteful representative subset if many cards; maintain a visual indication of the collection).
2. **Charge and whirl:** controlled spiral/whirlwind into the player, supported by compatible **Cartoon Coffee charging-light** elements plus existing game VFX.
3. **Impact/ascension:** icons converge; strong but not blinding flash/rings/energy; unmistakable feeling of a successful upgrade.
4. **Resolve:** clean fading aura/recovery so the effect feels finished, without permanently obscuring gameplay.

**Visual acceptance:**

- The effect is centered on the **actual player**, sized appropriately at default, minimum and maximum zoom, and visible over snow/dark/bright environments and equipped sprites.
- Lighting/colors complement the game's established pixel-art style; there are no giant cropped square textures, ugly resampling, z-index conflicts or flat-looking static overlays.
- Icons must not crowd beyond recognition or cover essential buttons. Excessive icon counts, speed, screen shake, draw calls and overdraw must be bounded for Android. Keep sensible reduced/quiet behavior during pause, scene transfer, rapid repeat triggering and modals.
- Timing clearly distinguishes reveal → gathering → impact → fade. Sound/feedback may reuse existing approved cues where appropriate but must respect audio settings.
- All gameplay and save/reward mutation completes at the authoritative point **independently of the effect**; no missed or double Prestige on interrupted visuals.

**Pointers:** `scripts/game/prestige_fx.gd`, its integration in `scripts/game/world.gd`, `scripts/game/game_ui.gd` and `scripts/game/simulation.gd`, plus `assets/Cartoon Coffee/2D Deluxe VFX/`. Inspect relevant VFX source files **without deleting potentially useful Unity originals**. Capture at least a few moments of the effect to confirm the stages and fix any misalignment/poor composition; report what is still Android-only.

## 5. Verification requirements and evidence

### Test gameplay truth and persistence

- Run existing relevant probes (including those for **Mastery**, **Prestige**, **missions**, **supplies**, **bosses**, **inventory**, **evolution**, **Merge All** and **UI**); update stale expectations **only after** establishing that the intended rules changed. The extracted batch modified tests including `tests/change_11_probe.gd`, `change_12_probe.gd`, `change_15_probe.gd`, `change_16_probe.gd`, `change_17_probe.gd`, `change_20_probe.gd`, `change_36_probe.gd`, `change_50_probe.gd`; use the repository's actual maintained runner.
- Add targeted probes for the **main-inventory sort/filter mapping and persistence**, **shared shop quantity and atomic bulk purchase**, **follow tracker height/Next removal**, **all Coin price boundaries**, **three-tracker HUD clearance**, and **new save/reset boundaries**. Prefer testing the real scene/action owners over mocks of unrelated behavior.
- Use isolated probe saves; do not overwrite the developer's real play profile. Import/parse with Godot as required; treat `SCRIPT ERROR:` in logs as failure. Run the complete maintained suite once after integration when feasible. If a command is unavailable, say so.

### Actually look at the UI

- Run the actual game in a Godot window/editor and capture **before/after** visual states for the key panels and HUD (main inventory, Filters, three trackers, left controls, top-right map/slider/messages, Supplies shop, Mastery/Mission/Prestige Follow buttons, and Prestige celebration frames).
- Evaluate four representative viewport shapes, safe-area insets, non-default joystick positions and at least one expanded localization. Check scrollability and touch targets instead of merely hiding overflow.
- Inspect card height, button width, icons, contrast, text wrapping, tooltips and interaction blocking; the screenshot issue may reflect **scene layout** rather than state calculation.
- Headless layout assertions are valuable but **not** a substitute for visually reviewing the game. If physical Android access isn't available, report precise remaining on-device tests without claiming they passed.

### Prioritized execution strategy

1. Baseline: inspect `git status`, Playbook, actual source and tests; reproduce reported defects.
2. Correct functional requirements first (real inventory sorting/persistence, bulk shop atomicity, Coin pricing, follow “Next” presentation, save rules).
3. Reorganize HUD and unify buttons without breaking onboarding or safe-area rules.
4. Visually iterate Prestige VFX in a running scene, testing realistic card counts and camera zoom.
5. Run focused tests, the maintained regression suite, diff checks and targeted visual captures. Fix meaningful regressions discovered during the audit, **not** unrelated speculative redesigns.
6. Make **one local Git commit** using the actual next change number; **do not push**, and do not include generated captures unless the repository explicitly tracks needed evidence. Preserve any unrelated developer edits.

## 6. Final response expected from Claude

Provide a concise but complete response, **not another `.md`**:

- **Audit matrix for all 13 original changes**: verified as-is / changed, and a short reason.
- **Newly reported fixes**: real inventory sorting/filtering and persistence; minimap → slider → messages; raised left controls; removed permanent boss hint; standardized Follow buttons; omitted the compact “Next”; supplies shop/bulk and saved quantity; Coin-cost smoothing across upgrades.
- **Prestige VFX**: what was observed visually, specific adjustments, and where screenshots/captures can be inspected.
- **Economy samples**: representative prices around the former **38→200+** jump, before and after, plus general cross-upgrade conclusions.
- Tests actually executed, pass/fail counts, any remaining known limitations and **specific Android-device checks**.
- Current game version and the **local commit hash**; confirm it was **not pushed**.

**Success means the game itself looks, behaves, persists and prices correctly—not merely that the source compiles.**
