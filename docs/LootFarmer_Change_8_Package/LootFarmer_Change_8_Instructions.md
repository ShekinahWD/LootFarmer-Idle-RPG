# LootFarmer — Change 8 Implementation Instructions

**Project:** LootFarmer – Idle RPG · Godot 4.7 · Android-first  
**Baseline:** The **current working tree AFTER completed Change 7**. Do not apply older ZIPs, replay older changes, or replace newer source with the earlier project snapshot.  
**Goal:** Implement the approved Change 8 gameplay/UI/economy changes, give the developer an **early buildable version**, then improve all eight map environments, then perform **focused deferred validation**. The developer, not an extended bot campaign, determines whether gameplay balance feels right.

## 0. Read first; respect existing work

Read the **current** `docs/Reusable_Game_Development_Playbook.md`, GDD, equipment/upgrade/prestige catalogs, asset registry, and `docs/LootFarmer_Change_7_Notes.md` plus relevant Change 7 validation files. Follow applicable Playbook practices, especially inspector-editable visuals/configuration, owned-asset use, fog/discovery contracts, touch/safe areas, save compatibility, and layered tests (notably §§17, 60.1, 63.1, 103, 117.9, 121, 124, and newer project-added sections where applicable).

Change 7 is finished. **Do not reimplement or regress** its shared sword/axe tiers, first-loot tutorial fix, explicit offline-earnings claim, mission-claim states, existing equipment navigation arrows, camera/respawn fix, weather world anchoring, boss-alive map gating, tutorial guidance, compact panels, or prior performance improvements.

Only inspect enough to implement this approved scope correctly. Do **not** launch a general game redesign or a lengthy design study. Prefer existing data/catalogs, Godot resources, and editor-visible/inspector-configurable scene elements over scattered magic numbers. Use **only existing licensed project art**; the supplied screenshots are visual **references**, not sprites to paste into the game.

## 1. Mandatory delivery order and Git commits

**PHASE A — Gameplay, UI, data, economy and fog implementation**

1. Implement **all approved Change 8 changes in §§2–7** below (including stage/map mechanics, but **not** the large decorative visual overhaul in §8). Update essential documentation affected by these rules as you go.
2. Run only the **minimum necessary buildability checks** (Godot import/parse and brief startup smoke, plus tiny targeted checks needed to prevent a known softlock). No full regression battery, multi-run balance testing, map screenshot sweep, prolonged bots or extensive profiling yet.
3. **Commit the finished gameplay/UI/economy batch to Git**, with a descriptive Change 8 commit message. Do not commit caches, private signing keys, generated reports, or unrelated user edits. Respect existing `export_presets.cfg` version-code and export configuration edits.
4. **Immediately write this conspicuous interim message in the chat, without waiting for tests or the map-art pass:**

   > **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   > **Change 8 gameplay/UI/economy/fog implementation is buildable and committed.**  
   > **🎨 I AM NOW IMPROVING THE VISUALS OF ALL 8 MAPS.**  
   > **Automated regression tests and physical Android verification are not yet complete.**

   The developer can build from this state while you continue. This notice must precede §8 map aesthetics/collision work. **Do not stop working or request approval at this milestone.**

**PHASE B — Eight-map visual polish (AFTER first build-ready notice; BEFORE remaining tests)**

5. Implement **§8** visual changes on every map; keep map gameplay/discovery topology, collision and path accessibility valid. Do quick editor/launch and essential blocked-path smoke checks needed to say the new build can start; defer the full test battery.
6. **Commit the map-visual/collision batch to Git**. Then immediately write a second interim message:

   > **✅ MAP VISUAL IMPROVEMENTS READY — REBUILD TO TEST.**  
   > **All 8 maps have received the Change 8 environment pass.**  
   > **🧪 I AM NOW GENERATING AND RUNNING THE REMAINING FOCUSED TESTS.**  
   > **The earlier gameplay-only APK does not contain these map changes.**

   Do not wait for extended testing before this second notice. Do not stop working after posting it.

**PHASE C — Deferred focused tests, final docs, final commit and report**

7. Add/update only tests that are needed to cover changed contracts, run the relevant probes and **one** sensible broader regression pass if affordable. Prefer adapting established Change 7 probes to building new suites. Follow Playbook §60.1; run heavy tools sequentially. Allow **at most 1–2 short representative balance scenarios** only if a change could cause an obvious progression failure. No 30-run sweeps, prolonged pacing bots, map screenshot campaigns, or unrelated profiling. A few arithmetic sanity checks are preferable when sufficient.
8. Finish/update GDD, equipment and upgrade data tables, state/save notes and reusable Playbook lessons **where genuinely applicable**, then **commit any remaining test/docs/fix changes** with a descriptive message. Never leave completed work uncommitted.
9. If a post-notice fix changes source, gameplay balance, scenes or collisions, explicitly say that the previous APK is **outdated** and **reissue the appropriate build-ready notice** after a minimal buildability check and commit. Tests/docs-only changes do not require an updated APK notice. Never silently invalidate a developer playtest build.
10. Provide a brief final per-feature implementation status, commits/hashes, tests/pass-fail, save caveats and a short **Android** validation checklist. Desktop/headless evidence must never be called physical-phone verification.

## 2. Gameplay HUD, navigation and inventory presentation

**2.1 Camps open on approach.** When the player enters a camp's sensible interaction area, automatically open that camp's menu. If manually dismissed, do **not** continuously reopen while the player remains inside; rearm on exit/reentry. Respect modal/pause/input state and avoid annoying repeated popups, especially on respawn and teleport; entering combat must not bypass existing camp restrictions.

**2.2 Top-level navigation.** Replace the main **Stats** navigation entry with **Player Upgrades**. Move **Stats** into **Settings** so it remains easy to find. Retain existing player-upgrade functionality and open/close/toggle behavior. Do not create two separate duplicate upgrade panels.

**2.3 Stats readability.** Make Stats comprehensible at Android scale: categories/sections, aligned stat names and values, concise units/descriptions, readable contrast and appropriate scrolling rather than a wall of plain text. Keep active/lifetime playtime and current prestige-run time correct, as implemented in Change 7. Show meaningful effective stats and boosts without duplicating redundant values.

**2.4 Prestige discovery banner.** Place prestige-discovery notifications **horizontally centered at the top**, within Android safe areas, with clear text contrast. Do not leave them left-aligned. Preserve ordinary notification behavior and queueing.

**2.5 Health bars.** Draw **remaining HP / maximum HP** numerically **inside** player, normal-enemy and boss HP bars. Use readable numbers (abbreviate big figures sensibly), contrasting/outlined text, and correct updates on damage, healing, max-HP changes and respawn. Keep bars compact.

**2.6 Inventory pinned equipment.** Always show the currently **equipped weapon and outfit in a dedicated, clearly labeled section pinned at the top** of the Inventory view, independent of item sorting/filtering/scroll position. Correctly update it after equip/unequip, merging, prestige and loading. Avoid cloning/double-counting the same item in inventory logic.

**2.7 Equipment comparison layout.** Use `visual_refs/equipment_comparison_reference.png` as a **layout reference**, not its theme. At top: the **currently equipped item**, its rarity/tier/name and relevant stats. Visually separate the **prospective selected item** below, close to its **Equip** button. Clearly show positive/negative **numeric deltas and direction** for each comparable stat and a concise overall effect. Preserve Change 7's previous/next item arrows, compactness, mobile safe areas, and no-overflow scrolling. **Do not implement a Sell button** from the screenshot; selling is not part of this game. If the slot is empty, show an appropriate placeholder.

## 3. Gear, skills, drops and upgrading

**3.1 Outfits — duplication-based growth, no evolution.** Outfits remain outfit-specific in appearance/identity and improve **persistently from additional copies/merges of themselves**. Remove outfit evolution into separate successor IDs. Duplicates should strengthen the same item instead of creating inventory clutter. Keep meaningful boss-exclusive outfit advantages; preserve established random-stat/effective-stat behavior when appropriate.

**3.2 Skills — same growth model as outfits.** Skills are non-consumable owned/equipped items, **do not evolve into other item IDs**, and gain permanent strength by collecting/merging copies of the same skill. Keep existing skill use, unlock, equipping and auto-use behavior. Do not change **weapon** evolution: Wood → Stone → Iron → Gold → Diamond → Emerald → Obsidian continues to apply to existing weapon families.

**3.3 Merge cap and curve — choose based on compact evaluation, not an arbitrary number.** Investigate practical attainable copy counts, Stage 1–8 farming rates, boss rarity and stat curves. Select a justified finite maximum merge level (possibly hundreds; **^500 or ^1000 are examples, not mandates**) and a diminishing-return or otherwise bounded scaling formula to avoid runaway power. Calculate a few representative low/mid/high copy cases, **not** long bot simulations. Document the choice and make important coefficients inspector/data-editable. Preserve valid stored owned-item progress when migrating old evolved outfit/skill saves; avoid duplication/exploits or silent loss of items. Existing no-sell policy stands.

**3.4 Boss weapon tiers.** A boss should **carry and drop a weapon exactly one tier higher** than the regular enemies of **that boss's stage**, using existing matching art and the existing weapon tier ladder. The visible equipped weapon, its identity, its dropped item and combat stat application must agree. Avoid double-applying weapon damage if enemy formulas already incorporate gear.

**3.5 Uniform normal-enemy gear drops.** Set **5% base chance per carried equipment item** for **every normal enemy on every stage**. Roll independently for each carried item. This is the same rule in Winter I through Spring II. Maintain existing gear eligibility, loot presentation and collection rules.

**3.6 Loot Chance upgrade.** Per-enemy-type upgrade gives **+0.5 percentage points per level**, up to **15 levels** (**12.5% total per item**: 5% + 7.5 pp). Keep purchases specific to enemy type. Its starting cost should be appropriately higher for later enemy types, and purchased levels should scale in price as existing progression requires. Keep **boss base equipment chance 30%** and preserve boss-specific chance handling unless the new catalog contract demands a targeted compatibility fix. Make exact percentages consistent across labels, tooltips, tests, and math.

**3.7 Discoverable skill upgrades.** A player must **not see upgrades for skills they have not yet discovered/obtained**. On first discovery, display a brief notice such as **“New upgrades unlocked: [Skill] (Player Upgrades)”**. Don't repeatedly notify for duplicate drops. Unlock/display state must persist correctly across save/load and prestige according to the current skill ownership rules.

## 4. Prestige availability and compact tracker

**4.1 Prestige entry gate.** Unlock **access to the Prestige system immediately after the player defeats the first boss (Winter I Snowman)**. *(Corrected: an earlier wording said "the first enemy"; regular kills do not unlock Prestige.)* The actual reset/prestige action is permitted **only when at least one prestige opportunity is completed/ready and can award at least one card choice**. A card is **selected during the prestige process**; do **not** require the player to own a prestige card beforehand. Explain unmet requirements on the button/panel and preserve card selection, reset, rewards, keys and duplicate-award protections. Update any previous stage-based reset gate accordingly, without unnecessary additional restrictions.

**4.2 Followed prestige HUD — MINIMAL.** While following an in-progress opportunity, display a **small persistent lower-left tracker** with only:

- **Name** of the prestige opportunity.
- **Its icon**.
- **Step + next actionable objective**, including **short numeric progress** if relevant.

Example display: **Robot Hunter** · [icon] · **Step 2/3 — Defeat Robots: 12/20**. Do not display reward descriptions, every step, long explanations or extra controls in the gameplay HUD; details stay in the existing Prestige panel. Respect joystick/HUD areas, safe areas, font size and touch; use a subtle backing for legibility. Update as authoritative progress changes. The tracker persists until the player **unfollows** or the opportunity is consumed/invalidated by a completed prestige/reset. If a followed opportunity becomes Ready, show a compact Ready state until unfollow/reset; **do not allow starting a new Follow on an already-Ready opportunity** (Change 7 rule).

## 5. Fog, vision and map markers

**5.1 Split permanent reveal from momentary vision.** The player's permanently explored/revealed radius is currently much too large. Make it **substantially closer to the player**, using approximately **30% of its current radius as an initial target** (not 30% of the visible area); temporary **vision can be about 2× that reveal radius**. The two states must have different gameplay semantics and clean presentation, according to the Playbook's fog contract. Expose radii through appropriate inspector-editable data. Don't solve travel issues by silently restoring the old oversize reveal.

**5.2 Preserve discoverability without leaking.** Adapt camp discovery/interaction and local wayfinding so ordinary farming still leads to the next camp and no route softlocks under the new close reveal. Stationary camp reveal, unlock effects and map upgrades must respect their documented scope. The player may SEE nearby temporary terrain/enemies without permanently discovering distant encounter coordinates. Persist only the correct exploration/knowledge states; avoid a new full-map reveal on load, relaunch or teleport.

**5.3 Map information must respect encounter discovery.** Map Details or other map-information upgrades may reveal more detail about **already discovered** enemies, but **must NEVER expose the location/marker of an enemy/encounter the player has not found**. Do not leak hidden coordinates via boss markers, labels, map taps, legend, tooltips or search. Preserve Change 7's boss-alive marker requirement.

**5.4 Individual encounter/loadout markers.** Use **smaller independent icons for each encounter spot**, not one marker that visually conflates three or four nearby groups. Display actual loadout clearly: **weapon only**, **outfit only**, **weapon + outfit**, and **skill** as a compact badge/overlay (only when that information is legitimately known). Place/scale to remain legible, nonoverlapping and tappable on mobile. If the player has not discovered a spot, show **no marker** for it. Preserve encounter separation, farming isolation and stage progression.

## 6. Upgrade-economy changes — focused review, then implementation

**6.1 Player Upgrades pricing pass.** Briefly inspect **all Player Upgrades** for cost, effect strength, progression and currency consistency. Fix obvious over/underpricing with coherent formulas, not a massive economy audit. **Cut initial Gem prices by approximately 50%** for Gem-priced Player Upgrades as the general baseline; select subsequent scaling by the actual strength of each upgrade. Round prices to valid positive integers; preserve purchased levels and avoid save exploits. Document exceptions and new formulas succinctly.

**6.2 Auto-Collect Batch is premium.** This upgrade is particularly powerful. Make **Player Auto-Collect Batch considerably more expensive than ordinary player upgrades**, with much steeper cost growth on repeated purchases. **Its required premium pricing takes precedence if applying the general 50% first-price reduction would make it too cheap**; document any exception. Keep its gameplay effect unchanged.

**6.3 Map Details.** Increase the cost of Map Details **moderately** and make **each successive purchase cost more than the preceding purchase**. Prefer a clear monotonic price progression rather than a flat/repeated cheap price; respect its existing currency and purchase scope.

**6.4 Inventory Slots.** Each later Inventory Slot upgrade must cost **at least 1 Gem more than the previous slot purchase**. Check integer rounding, preview prices, caps and saved levels.

No long economy/progression simulations. A short table of 3–5 representative levels per affected price formula and one or two arithmetic power checks is enough; the developer will assess balance on Android.

## 7. Build-ready safeguards and nonvisual map mechanics

Finish all requirements in §§2–6, including the relevant **fog mechanics, encounter marker logic and data-driven configuration**, **before the first build notice**. Preserve save compatibility where sensible and explicitly describe any unavoidable schema/map exploration migration. Keep Android touch regions safe and UI responsive. Do not accidentally modify the Android export version code/signing config. The first build does **not** need the later environment art makeover in §8.

## 8. Separate AFTER-build visual overhaul — all eight maps

**Timing requirement:** Begin this section **ONLY AFTER** posting the **first** build-ready chat message in §1. The player should already be able to build/test the complete Change 8 mechanics while you work on environments. Finish §8 and post the **second** build-ready notice **BEFORE** deferred full test creation/execution.

**Visual references:** See `visual_refs/map_reference_01.png` through `visual_refs/map_reference_05.png` (five supplied examples). Learn from their authored-looking **terrain composition, readable routes and clearings, season-colored scenery, visual landmarks, foliage shapes/clusters, density rhythm, paths, structures, ponds/rivers, fences and purposeful prop grouping**. They are **composition references, not additional asset licenses or maps to trace**. Use the project asset registry and owned art; do not generate unrelated-looking new sprites or mix clashing pixel-art scales.

Perform an intentional composition pass for **each of the eight stages**: Winter I, Winter II, Summer I, Summer II, Autumn I, Autumn II, Spring I and Spring II. Improve over sparse/repetitive/random terrain by using connected landscape regions, readable pathways, thematic trees/rocks/vegetation/structures, distinct camp and boss-area landmarks, visual variety and more compelling stage identity. Preserve each stage's seasonal atmosphere/weather and navigation. Prefer editor-visible terrain/decor scenes or data authored in the editor, according to Playbook §63.1, so the developer can visually tune placement.

**Movement-blocking decorations:** Make **suitable large physical objects** (trees, boulders, fences, buildings/structures) block movement where appropriate, with collisions sized to the **base/footprint**, not full sprite artwork or tree canopy. Small foliage, ground decals and particles need not block movement. Avoid invisible walls, narrow bottlenecks and clutter that makes joystick movement frustrating. Use existing navigation/collision conventions; do not block camera touch gestures or UI.

**Functional acceptance per map:** camps and their interaction radii remain reachable; each encounter spot and boss court can be reached; player/enemy approach, aggro/leash and auto-farm routing cannot be trapped by props; the first boss is not beside arrival; neighboring farming spots remain distinct; the player can find the next camp with the new reveal/vision mechanics; enemy spawning and respawning avoid solid obstacles. Keep map bounds, teleport destinations, fog masks and map markers aligned with any scene changes. Do not casually move established spawn courts or break old saves; if moving geography is unavoidable, document migration of exploration and object IDs.

For this phase, use a **bounded visual self-review**: one deliberate composition pass and at most one correction pass per map, plus quick reachability checks. The user will judge visual quality on the device. Save comparably framed before/after screenshots when easily available, but do not spend tokens or time on large screenshot campaigns or subjective endless iteration.

## 9. Focused final acceptance and communication

After the **second** build notice, update or add compact regression cases for: camp entry/reentry; navigation and settings Stats; pinned equipped inventory; comparison deltas; HP text; skill/outfit duplicate merge and cap; migrated saves; boss tier and per-item loot chance; 15-level upgrade and prices; first-kill prestige gate + ready opportunity/card transaction; followed-HUD next-step/Ready behavior; fog reveal vs vision and hidden enemy disclosure; individual loadout markers; eight-stage collision/reachability; safe-area banner and Android-sized UI where programmatically measurable.

Run existing relevant probes and a single broad regression pass if economical. The **only mandatory checks before either build-ready message** are those essential to know the corresponding source/scene tree parses and launches and is not obviously broken. Always distinguish **not tested on phone** from verified on Android. If real Android testing is unavailable, do not invent it.

**Final reply:** Brief table grouping Fixed / Already Correct / Deferred to Developer Android Playtest; exact commits/clean-or-dirty working tree; focused test summary and caveats; direct phone checks (camp entry, pinned compare, first-enemy prestige availability, fog/markers, weather/panning, eight-map movement around decoration). Keep the developer informed at both specified build milestones, and **always commit completed changes**.
