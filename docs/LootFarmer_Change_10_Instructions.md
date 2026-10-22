# LootFarmer – Change 10: Inventory, Progression Clarity, Farming Index & UI Corrections

**Implementation brief for Claude | Baseline: latest completed/committed Change 9**

## Objective and boundaries

Implement the seven requested corrections below in the **current Godot project**. Start from the latest committed Change 9 state, including the Snowman prestige-unlock correction. Read the **current in-repository Reusable Game Development Playbook**, GDD, State Contracts, upgrade/content catalogs, and Change 8/9 notes where relevant. Follow the game's established assets, data-driven design, Android-first UI rules, and inspector-editability guidance. **Do not reimplement Change 8/9 features or reopen unrelated balance discussions.**

**Development-save policy:** the project is still pre-release. Per Playbook **§61.1**, old development saves do **not** require migrations or preservation. It is acceptable to bump `SAVE_VERSION` and start a fresh profile if the change requires it. However, **current-schema save/load, reset, bounds validation and deterministic state must work**. Do not spend tokens on legacy conversions/refunds. Do not touch unrelated developer-owned settings or uncommitted changes (notably Android export version/signing configuration), or blindly remove generated/untracked files.

## 1. Cap equipment inventory at 70 total slots

- **Exactly 70 equipment slots maximum**: **3 initial + at most 67 purchased**.
- There is **no new content planned**. The last audit found about **68 active unique equipment identities**; inspect the authoritative current catalog for exact counts. Avoid including inaccessible legacy IDs in the slot requirement.
- Outfits/skills improve from duplicate merging without creating additional identities. Do not count item copies as separate equipment slots. Do not accidentally cap consumables or other distinct storage pools if their rules differ.
- Update the upgrade maximum, progression/purchase controls, prices and labels, purchase eligibility, save-schema clamp, UI counters, relevant tests and documentation. At maximum, further purchases must be unavailable and the UI should clearly say it is maxed.
- Old development-save migration is **not** required; correct current-schema bounds **are** required.

## 2. Outfit inventory slot appearance advances at every ^100 milestone

- An outfit **remains the exact same item**, ID, artwork, tier, and merge stack throughout ^0–^500; **do not add outfit evolution or additional item identities**.
- Upgrade **only the inventory slot's visual treatment** (background/frame/border/accent) at each milestone: **^100, ^200, ^300, ^400, ^500**; ^0–^99 uses its normal background.
- Each milestone must be meaningfully distinguishable from the previous one on Android. Preserve the item's underlying rarity/tier meaning and readability. Use the project's **existing UI assets**; no custom drawn replacements or new paid/external assets.
- Apply consistently wherever inventory slots are rendered and ensure the equipped strip/selection/equipment comparison do not lose their distinct equipped/selected states. Avoid unnecessary visual processing every frame; prefer data-driven, inspector-editable milestone styles where practical.
- This is **visual progression only**; Change 9's ^500 outfit stat/milestone mechanics remain as implemented.

## 3. Boss Gem payout = 3× normal-enemy Gem amount

- **Keep the existing Gem-drop chance and chance-upgrade rules.** The request changes **amount paid on a successful Gem roll**, not probability.
- A boss's base Gem amount must be **three times the normal enemy's amount under equivalent applicable normal/global Gem amount upgrades**. Example: a normal successful drop pays 1 Gem → boss pays 3 Gems before any separately authored boss-only amount bonus.
- Inspect the actual reward formula and preserve the purpose of existing boss-specific Gem chance/amount upgrades. Apply the multiplier in a documented, single authoritative place. Avoid unintended triple-scaling of boss-only additive upgrades, fractional rounding errors, double grants, or differences between displayed and awarded Gems.
- Make the amount shown in enemy/boss information consistent with the real outcome. Ensure this applies across all stages and bosses.

## 4. Add a map-by-map enemy farming reference (World / Encyclopedia)

The player needs to know **where to farm specific enemies and what they drop**, without manually revisiting maps to remember each spot.

- Provide a compact, accessible **Farming Guide / Enemy Encyclopedia** section from the **World** UI (or another clearly discoverable existing World subview). Favor reuse of existing panels and information instead of making duplicate upgrade systems.
- **Unlock each map's entry independently** only when **that map's Map Details upgrade is fully purchased** AND **the Stats and Drops details of every relevant enemy type on that map are unlocked** (including bosses where applicable). Use the authoritative per-map/enemy completion data. Show a clear, concise missing-requirements message for locked maps.
- When a map qualifies, it appears as a browsable map entry. Show its enemy types/individual farming spots and the information already researched: recognizable icons, weapon/outfit/skill loadout, obtainable drops and their actual chances, currency rewards where known, and **where each spot can be found/farmed**. Reuse enemy-detail navigation where helpful rather than building oversized cards.
- **Critical fog/discovery rule:** neither maxing Map Details nor opening the Encyclopedia may reveal coordinates, markers, bosses or names of **undiscovered encounter spots**. Display location/directions only for spots actually discovered under the existing rules. If needed, show a discreet “undiscovered spot” placeholder rather than leaking data.
- Respect map/spawn/camp discoverability, selected stage, alive-only boss marker behavior, mobile safe areas, scrolling and input. Avoid turning this into a second map reveal or an automatic teleport system.
- Document whether knowledge is per-run or profile-wide following the **existing** research/map rules; do not invent new prestige-reset behavior without justification.

## 5. Make player growth and stat sources transparent

The developer observed unexpectedly high HP around **level 11**, despite modest visible equipment. **Do not blindly nerf player growth.** Identify the real contributors and expose them to the player.

- Inspect current authoritative player level-growth and effective-stat calculations (including base HP/damage, level increments, equipped gear, **15% stored outfit core bonus**, **30% stored weapon bonus**, equipped-only outfit milestones, prestige, upgrades and buffs).
- Keep the present level scaling **unless inspection uncovers a genuine bug**, such as a double-applied contribution, invalid level calculation, incorrect UI value or stale effective-stat cache. Report evidence before/after for any bug fix; avoid redesigning balance.
- Provide a compact **level-growth table in your final chat/report** for representative levels including **1, 5, 11, 20 and at least one later level**, with base HP, base damage, level-only increments and next-level XP according to the **actual current formulas**. Also show a **level-11 no-gear/no-prestige baseline** and briefly explain where additional HP can come from.
- In the existing Stats view, make the **effective HP / damage source breakdown** understandable. Use the **same authoritative stat getters and effective values that combat uses** (Playbook **§17**) rather than recomputing unrelated formulas in UI. Clearly distinguish base/level, equipped equipment, stored-equipment passive bonuses, prestige, milestone and temporary effects; include only applicable sources.

## 6. Tap the player XP / level bar to inspect level growth

- Make the **player's level/XP bar tappable** to open a compact **Player Level & Growth** panel similar in purpose to the enemy-achievements progress view. Do not require opening Settings first.
- Show current level, XP progress, XP needed to advance, **base gains per level**, current vs next-level HP/damage gains, and the relevant effective-stat/boost breakdown or an obvious path to its full detail.
- Ensure the panel reflects the **real current formula** and updates after gaining XP/level, swapping equipment, prestige and upgrading. No misleading “next level” at level cap.
- Work with Android safe areas, touch targets, joystick, existing pop-up priority and close/toggle patterns. Do not interfere with joystick control or other HUD taps. Keep it brief, readable and scroll-safe.

## 7. Prestige panel access and Hard Reset message alignment

### 7A. Prestige entry vs actual reset action

- The **navigation/HUD Prestige button must always be usable to OPEN the Prestige panel**, including on a fresh profile before the Snowman has been defeated. Players can browse, discover, inspect and follow opportunities as the current systems allow.
- Only the **actual Prestige/Reset action within the panel** is gated: it requires **the Winter I Snowman first-boss defeat** and **at least one eligible ready/completed prestige opportunity that can award a card**. Card selection happens as part of performing prestige; do **not** require already owning a card.
- When the action is locked, clearly show **which condition is still missing** in the panel/action UI. Keep existing duplicate-card safeguards, card choices, reward delivery, completed states and reset rules.
- Remove any UI behavior that disables the whole panel or makes the panel-opening button itself read like an unusable control. Update outdated English/Spanish text and documentation as needed.

### 7B. Center the Hard Reset message on the X axis

- Locate the **Hard Reset message/confirmation** currently presented to the player and **center it horizontally on the usable screen** (the **X axis**), taking Android safe-area insets into account.
- Align the *actual visible message container* rather than only centering text inside an offset panel. Preserve its intended vertical position, confirmation/cancel buttons, modal priority, hard-reset logic and accessibility.
- Check the position after resolution/orientation/safe-area changes and with longer localized text. This is **horizontal centering only**, not a request to vertically center it or change its behavior.

## Workflow: implement → tell me to build → deferred focused testing

1. **Implement all seven sections** and make the project buildable. Use only small checks needed to avoid knowingly giving me a broken project; defer tests that can safely run later. No long pacing/balance campaign.
2. **Commit the implementation** (select only relevant files; descriptive Git commit, preserve unrelated local changes). As soon as implementation is buildable, post in chat, **without waiting for the deferred test suite**:

   **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   **Commit: `<hash>`**  
   **🧪 GENERATING AND RUNNING THE REMAINING FOCUSED TESTS.**

3. After that notice, complete focused tests for: inventory cap/purchases; ^100…^500 outfit slot backgrounds; boss Gem chance vs amount/upgrade stacking; encyclopedia unlock/undiscovered-spot privacy; level-growth/effective-stat consistency; XP bar tap; Prestige navigation vs reset eligibility; Hard Reset X centering and confirmation behavior. One short real current-schema save/load/reset check where persistent values changed. No unnecessary full campaign reruns or repeated long benchmarks.
4. Update relevant GDD, upgrade/catalog/state docs, UI text/translations, and Playbook only where a reusable lesson actually emerged. **Commit any post-notice tests/docs/fixes**; if fixes change the running game, issue a **new build-ready notice with the new hash** so the first APK is not mistaken for the final one.
5. Finish with a concise table of changes, test results, commits, and items that **need Android visual verification**. Do not claim phone testing without a real device.

**Scope discipline:** avoid unsolicited enemy/boss retuning, new equipment evolution, unrelated map redesign, legacy-save migrations, or sweeping refactors. The developer evaluates gameplay balance on Android.
