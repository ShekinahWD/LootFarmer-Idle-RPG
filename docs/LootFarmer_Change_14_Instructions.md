# LootFarmer — Change 14: Android HUD, Combat VFX and Usability Corrections

**Task type:** Implement the following eight changes in the **latest committed LootFarmer – Idle RPG Godot 4.7 project**. This brief is self-contained for a new Claude conversation. The current repository, not an older ZIP or a commit hash copied from a prior report, is the implementation authority.

## Before editing

1. Inspect `git status`, the latest commits, the current GDD, **Reusable Game Development Playbook**, existing Change 13 notes, applicable state contracts, scenes/resources, and the maintained test suite.
2. Preserve prior gameplay and UI improvements. Do not overwrite a newer implementation with an older archive. Check whether any item below is already resolved in the live tree; if so, verify rather than duplicate it.
3. This is a focused **implementation request**, not a broad redesign or an invitation to run a long balance investigation. Use only existing approved UI/animation assets; prefer inspector-editable presentation settings, scene nodes, and shared logic over hidden hard-coded numbers.
4. Preserve local Android export/version/signing edits (`export_presets.cfg`, `project.godot`) and unrelated work. Development-only saves require no migration. Follow the Playbook's mobile HUD, safe-area, tutorial-guidance, visual-feedback, and testing requirements.

## 1. Make Next Stage progress legible

**Observed on Android:** the `Next stage · Bosses 0/1` (or `0/2`) line below the minimap blends into the game world. Its small, pale text is hard to read.

- Give it a compact, high-contrast, subtly dark-backed HUD surface, with enough padding and a readable font size. Keep seasonal backgrounds and fog from washing it out.
- Show the actual gate progress for the **specific required bosses** (e.g., `Next Stage · Bosses 0/2`); retain the current final-world completion wording when applicable.
- Keep it immediately associated with the minimap. Preserve existing boss-gate indicators, discovery restrictions, state updates, and interaction behavior.
- Honor Android safe areas; avoid overlap with the map, zoom controls, other information labels, and gameplay touch targets. No gratuitous enlargement or redesign of the minimap.

**Accept when:** the next-stage requirement is readable over Winter, Summer, Autumn, Spring, and rainy environments; the counter updates as required bosses are defeated.

## 2. Move and improve Map Explored percentage

**Observed on Android:** `Map explored: N%` is faint and currently placed in the bottom-right of the game, away from related map information.

Organize the **upper-right map-information cluster** in this order:

1. Existing camera **zoom slider**.
2. **Map Explored: N%** in a compact, readable, dark-backed label.
3. Existing **minimap**.
4. The improved **Next Stage / Bosses progress** label from §1.

- Remove the redundant percentage from the bottom-right.
- Read the existing authoritative **permanently explored** percentage; transient vision, panning, and camera zoom must not count toward completion.
- Retain existing number conventions, anchoring, safe-area handling, and responsive layout. Keep labels readable without covering each other.

**Accept when:** the percent and stage gate appear together around the minimap, and their values update correctly without displacing essential controls.

## 3. Fix the always-visible Missions `!` badge

**Observed:** the Missions navigation button keeps showing `!` even when the player sees no claimable reward or other actionable mission state.

- Trace the badge predicate **through the same eligibility/state logic used by the actual Claim actions**, including daily missions, main objectives, completed-but-not-claimable entries, and auto-claim.
- Show a *ready-to-claim* badge only when the player can genuinely claim a reward right now. Do not show `!` merely because an underlying progress array or stale flag is nonempty.
- Recalculate immediately after claims, automatic claims, mission refresh, Prestige reset, load, and relevant progression changes.
- Preserve the Playbook's badge semantics: an actionable reward indicator must not be confused with an affordable purchase indicator. Do not add unrelated purchase notifications to Missions without an actual feature that needs them.

**Accept when:** after all actionable mission rewards are claimed, the badge disappears; it reappears when a real manual claim becomes available.

## 4. Fix rain splash movement at impact

**Observed:** when falling rain reaches its ground-impact/splatter animation, the splash continues traveling, making it look as though the impact is sliding over the ground.

- Preserve falling rain's movement until the actual transition to the splash animation.
- On impact, **freeze the particle's world-space impact position** and stop fall/drift movement for the entire splash sequence.
- Play the existing splash frames at that fixed point; remove/recycle the particle only after the splash finishes.
- Camera panning must not move the impact relative to the terrain. Retain rain density, overcast look, existing assets and reasonable Android performance.

**Accept when:** rain falls, impacts, splashes in place, and disappears cleanly at all camera zoom levels.

## 5. Audit and correct all six skill effects — player and enemies

**Observed:** **Lightning** visibly spawns too low, *below* its enemy target instead of striking visibly on/over the target.

Review **Lightning, Fire, Frost, Strike, Heal, and Focus** in BOTH directions: player casts on enemies and enemy/boss casts on the player or self.

- Confirm the intended cast origin, target point, skill-specific offsets, scaling, screen/world layer (`z_index`/canvas ordering), and sprite anchoring. A target's world origin is not necessarily its visible body center.
- Fix Lightning's impact so the effect clearly strikes the **visible body of the target** and is not hidden beneath its sprite. Ground effects may belong under actors, while striking/projectile effects may need to render above: choose per effect, not one universal offset.
- Ensure caster-attached buffs/healing follow a moving actor; ground impacts remain attached to their actual impact point as appropriate.
- Verify each skill's **real effect** (damage, slow, buff, heal), cooldown, animation timing, and visibility for normal-sized and boss-sized actors.
- Avoid false or duplicate effects during a boss wind-up/telegraph and the actual cast. Preserve combat values and balance unless a confirmed functional bug requires a correction.
- Prefer existing skill VFX resources with inspectable position/layer settings, not bespoke new artwork.

**Accept when:** all six skills work and render correctly for the player and enemy/boss, with Lightning clearly striking the target. Record what was actually verified by static tests/screenshots versus what needs phone confirmation.

## 6. Show Reveal Stats and Reveal Drops in the enemy's Upgrades tab too

Currently, a discovered enemy's **Overview** tab contains the existing **Reveal Stats** and **Reveal Drops** purchases. Keep those where they are.

- Also expose the SAME upgrades in that enemy's **Upgrades** tab, alongside its other upgrades.
- Both tabs must invoke the same purchase/state logic and immediately show the same prices, status, and unlocked information.
- Do not make duplicated upgrade definitions, duplicate charges, a new research currency, or another separate subsystem. Keep the existing prices and unlock rules.
- The Farming Guide and other research-gated views should respond correctly whichever tab the purchase came from.

**Accept when:** a purchase on either tab is reflected on both, without charging twice or exposing unrevealed information prematurely.

## 7. Improve joystick contrast across all maps

**Observed:** the bottom-center joystick is white/semi-transparent and difficult to distinguish on snowy Winter terrain.

- Select a **subtle, consistent contrast treatment**—such as a slightly more opaque base, muted darker rim or backplate, restrained outline/shadow—that works on **every seasonal map**, including light snow and dark rainy maps.
- The joystick should be easy to find at a glance, but not visually dominate or obscure gameplay.
- Preserve its location, responsive/touch bounds, input arbitration, movement behavior, and Android safe-area positioning.
- Prefer inspector-editable colors/opacity/style where practical. Inspect representative winter, summer, autumn and spring screenshots rather than relying on an isolated dark map.

**Accept when:** joystick remains visibly distinguishable without changing movement controls.

## 8. Teach the player where to use Focused Farming after purchasing it

**Observed:** purchasing/unlocking **Focused Farming** does not clearly teach where its actual **Focus / auto-farm control** is or how to use it.

- Immediately after the first unlock, provide a concise contextual confirmation (`Focused Farming unlocked`) and show **one short explanation** of how to choose and activate a farming target.
- Reuse the **existing tutorial/coach arrow and highlighting system**, pointing to the real, currently visible actionable control. Do not point toward hidden panels, undiscovered enemies, or controls that are not in the current UI.
- If the Focus button requires opening a panel, guide the actual next tap in that navigation path, and update/hide the arrow as panel state changes.
- Allow dismissing the hint. Show it **once on first purchase**, not on every load/reopen or as permanent HUD text. Respect onboarding choice, competing tooltips, modal overlays and safe areas.
- Preserve Focus mechanics, existing unlock requirements, and current gameplay behavior.

**Accept when:** a player who just bought Focused Farming can find its control and understand the next action, without a persistent screen obstruction.

---

## Implementation and verification rules

- This is a narrowly scoped correction batch: **do not add new game systems, alter economy/combat balance beyond a verified fix, or redesign already accepted UI**.
- Follow Playbook guidance on HUD hierarchy, mobile readability, badges, contextual guidance, visual effects and inspector-editable presentation.
- Update the actual GDD and relevant state/implementation documentation, and record only genuinely reusable lessons in the Playbook.
- Keep tests **focused and cheap**. During implementation, use only essential syntax/build/smoke checks. After the game is buildable, add or adjust relevant automated regression tests and run the maintained suite once. Do not run extended pacing bots or performance campaigns; human Android playtesting determines subjective visual quality.
- Suggested targeted checks: badge actionable-state matrix; gate/percentage HUD updates and positions; both enemy research tabs; focused-farming first-unlock guidance; rain impact frozen position; six skills' source/target/effects across player and enemy casts. Use screenshots where they materially help, but do not claim physical Android verification without a device.
- **Always commit all completed gameplay changes and subsequent test/documentation updates.** Preserve unrelated uncommitted files and Android signing/export settings.

## Required delivery sequence

**Phase A — Implementation**

1. Implement all eight requested changes.
2. Make the project buildable; do only essential checks needed to avoid handing off an obviously broken build.
3. Create a descriptive Git commit containing all implementation changes.
4. **Immediately announce in the chat:**

   > ✅ **YOU CAN BUILD AND TEST THE GAME NOW.**  
   > **Commit:** `<actual implementation commit hash>`  
   > 🧪 **GENERATING AND RUNNING THE REMAINING FOCUSED TESTS NOW.**

**Phase B — Deferred validation and documentation**

5. Add/update focused tests; run the maintained suite one time; update relevant project documentation.
6. Commit any subsequent fixes and docs. If a test uncovers a gameplay problem and changes the build, immediately state **NEW BUILD REQUIRED**, give the updated commit hash, and explain what changed.
7. Finish with a concise eight-item completion/status table, focused test totals, commits, and a short Android acceptance checklist. Clearly distinguish desktop/static evidence from actual phone testing.

**Do not stop after the first build-ready announcement; finish Phase B without another user prompt.**
