# LootFarmer — Change 64: Visual Teleportation, Prestige Screen Fit & Offline Rewards

**Status:** Approved for implementation. **Base:** Claude's current working tree after Change 63 and correction commit `82449e6`; do not replace it with an older ZIP. **Scope:** Three player-reported UI improvements. **Target:** Android portrait. **Do not edit** the Reusable Game Development Playbook or unrelated systems.

## 0. Read first / constraints

1. Inspect the live repository and relevant rules in the Reusable Game Development Playbook before editing. In particular apply the guidance on mobile safe areas, scrollable/settled panels and cards (sections 14–16, 128–129), stable controls, travel authorization (section 137.1), and offline reward transaction boundaries (sections 30–31, 58, 136.4).
2. Reuse the existing Godot presentation and travel systems. The reference snapshot previously showed `scripts/game/game_ui.gd` functions `_teleport_panel()`, `_travel_map_panel()`, `_travel_to()` and `_offline_panel()` and the reusable `scripts/game/camp_picker.gd`. **Verify their current names and behavior against the live tree**, not an outdated ZIP.
3. Preserve Change 61–63 Guided behavior, Change 62 balance, existing save compatibility, existing Prestige decisions/cards, all current economic formulas and claim semantics. Do not modify gameplay just to satisfy a presentation request.
4. Preserve all developer changes, unrelated uncommitted files, and untracked assets. No push, export, publication, or Playbook edit.

## 1. Teleport from a camp: choose destinations on a LARGE visual map

### Problem

At a camp, selecting **Teleport** currently presents a list of camp names (for example, *Camp 2*) without showing where each destination is. Players cannot tell where they will arrive. A visual camp picker already exists elsewhere in the game; do not create an unrelated travel system.

### Required player flow

1. Player taps **Teleport** at an owned camp.
2. Open a **large map-focused destination selector** that occupies the practical available mobile screen area inside the safe area, rather than a stack of text-only camp rows with a small map appended. Leave room for stage selection, clear destination feedback, and Back / Confirm controls.
3. Provide a visible, touch-friendly selector for **every unlocked stage**, with the current displayed stage clearly distinguished. If the stage selector needs more room, it scrolls/wraps safely. Never auto-teleport merely because a stage has only one owned camp.
4. For the selected stage, show the existing map visual with camps at **their real authored stage positions** and existing exploration/discovery presentation. Distinguish:
   - current player/camp (when displayed on that map),
   - owned/eligible teleport destinations,
   - currently selected destination,
   - locked/unavailable camps (if existing map rules reveal them; do not leak new undiscovered information).
5. Tap a valid camp marker to **select** it, not travel immediately. Show the chosen stage/camp in readable text and mark it on the map. Make markers easy to tap without causing accidental activation when dragging/scanning.
6. **Confirm Teleport** performs the travel using the **existing authoritative travel action**. **Back/Close** cancels without movement and returns to the appropriate camp context. A current-position marker must not silently re-travel.
7. Revalidate **at confirmation time**: combat/recent damage, player death, pause/suspension, ongoing Prestige or other transaction locks, camp ownership, unlocked stage, and all existing game-specific travel restrictions. Display the reason for disabled/failed travel; never bypass it via a new UI route.
8. Preserve the difference between **travel** and **respawn selection**: teleporting must not change the chosen respawn camp. Preserve camera reset/follow, fog/discovery and arriving-without-reopening-camp behavior.
9. The preexisting World → visual travel-map flow must continue working; reuse shared map data and interactions where sensible. Do not regress Guide pointers or hide actionable controls behind overlays.

**Design intent:** Reuse/refactor `camp_picker.gd` or the existing visual map components with an explicit **select vs. immediate-travel mode** if necessary, and keep a single source of truth for the actual travel command. Avoid duplicate camp coordinates or travel rules.

## 2. Prestige: nothing extends outside the screen

### Problem

Some Prestige options/cards become too large and render partly beyond the phone screen. This is unacceptable even if a parent ScrollContainer technically exists.

### Required behavior

- **Reproduce and fix the actual offending Prestige surfaces**, not only the first reported card. Audit the stage-grouped opportunity list, objective/action rows, path/card chips, offered choice cards (including the largest offer set), owned-card grid, Prestige confirmation, and any selection/confirmation popups used in the Prestige flow.
- Fit every visible **card, text line, button, highlighted selection and modal** within the **available parent width and mobile safe-area bounds** at 432×960 and 540×960. Also check the game's other supported compact portrait shape if applicable.
- Long names, large numbers, and expanded translations must **wrap/reflow** and fit inside cards. Do not solve overflow by shrinking text below the existing mobile-readable floor, hiding a primary action, truncating required instructions, or adding horizontal page scroll.
- Use responsive rows or wrapping where two controls cannot fit side by side; keep usable tap targets and preserve correct action labels. Scroll vertically within constrained content. Keep **Close / Cancel / Confirm / Keep Card / Begin Prestige** reachable.
- Preserve Change 63's rule that **an open lesson panel must not jump in size while the user interacts**. Correct intrinsic card sizing and overflow without destabilizing existing modal/scroll behavior. Do not unintentionally hide Guided captions that were previously visible.
- Verify real rendered screenshots (not only static rectangle checks), including **maximum-content cases**: many discovered opportunities, long path/card names, a full offered-card selection (up to the actual catalog maximum), and a full confirmation summary.
- Preserve Prestige eligibility, opportunity ownership, reset/keep rules and all other game state unchanged.

**Important:** Check content against the viewport/parent safe area, not just whether children fall within their oversized parent (Playbook section 16.3). Identify the precise culprit(s) in the implementation report.

## 3. Offline Rewards: visible zeroes for locked categories + an upgrade CTA

### Problem

The Offline Rewards receipt currently displays only item IDs that were awarded. When **Weapons**, **Outfits**, or **Supplies** have not been unlocked for offline generation, those categories may simply disappear. The player should see **0**, understand why, and be able to reach the unlock upgrades.

### Required receipt display

Always show the established offline reward categories in a compact readable overview, even when zero:

| Category | Example | Expected display |
| --- | --- | --- |
| Coins | 1,250 | Actual accrued amount, or 0 |
| Gems | 15 | Actual accrued amount, or 0 |
| Weapons / Gear | 0 | 0 + **Locked** if `offline_weapon` is not unlocked |
| Outfits / Gear | 0 | 0 + **Locked** if `offline_outfit` is not unlocked |
| Supplies | 0 | 0 + **Locked** if `offline_consumable` is not unlocked |

- **Zero is not always Locked.** If a category has been unlocked but nothing was earned this offline period, show **0** as an ordinary outcome; do not misleadingly call it locked.
- Compute item category totals from the **actual pending/claim receipt**, using canonical catalog item kinds (not guessed names or a fake reward). Where there are real item rewards, preserve/show the individual awarded items in addition to the category totals if that information was shown before.
- Use the existing unlock levels/state to determine availability, with no duplicate cached flags. The labels *Weapons*, *Outfits* and *Supplies* should match the player's existing terminology.
- While one or more item categories remain locked, display a short persistent explanatory message, such as: **“Unlock Offline upgrades to earn weapons, outfits, and supplies while away.”** Show an obvious **Go to Upgrades** action opening **Upgrades → Offline**. Use localized keys.
- Do not make this hint a one-time disposable tutorial that disappears while the rewards remain locked. Avoid duplicate explanatory banners if Change 61 already teaches the Offline tab.
- **No retroactive earnings:** buying offline unlocks applies to future eligible offline time only. Do not recalculate or fabricate previously settled rewards. The displayed receipt must remain an immutable snapshot of what was earned.
- Preserve **explicit claim, pending settlement persistence, save/reopen durability, and no double-credit**. In the reference snapshot the existing `OFFLINE_UPGRADES_JUMP` handler claimed before navigating. Inspect and preserve the intended live behavior; make any claim-before-navigation behavior transparent to the player rather than silently altering pending rewards. Do not introduce a new implicit claim path unless existing rules require it.
- If an Offline upgrades tab is also used as a status/receipt surface, keep its presentation consistent with the new categories without duplicating entitlement or earnings logic.

### Example (illustrative only)

```
Welcome back!
Coins        1,250
Gems            15
Weapons          0   Locked
Outfits          0   Locked
Supplies         0   Locked

Unlock Offline upgrades to earn these items while away.
[Go to Upgrades]     [Claim]
```

Do not copy these example numbers into game data. Actual category names and presentation must use the game's localized conventions.

## 4. Localization and design ownership

- Write any necessary **English source text** in `localization/en.po` and update the established **pending-translation tracker** with `change-64`. Record the exact new/changed keys in the report.
- **Do not modify** the 19 non-English `.po` catalogs; preserve all previously approved translations for the upcoming consolidated localization pass.
- Reuse existing localization keys where accurate; do not hardcode English UI labels outside the locale system.
- No GDD/Playbook edits unless the user explicitly requests them. The only new instructions document for this batch is this Change 64 brief, which the user places in `docs/`.

## 5. Focused validation (no full or lengthy simulations)

Use targeted existing UI/state probes and extend them only as needed. Run quick actual Godot UI renders; record results honestly. Do **not** run the full regression suite, long balance simulations, exports, Android installs or releases.

**Teleport**
- Open a camp's Teleport → large visual map, stage switch among unlocked stages, select camp, confirm, Back/cancel.
- Current camp marker, owned/unowned marker states, stage with just one owned camp, and multiple camps; touch/drag does not accidentally teleport.
- Travel blocked mid-picker (combat/death/transaction) remains blocked on Confirm; successful travel leaves respawn camp unchanged; existing World map travel still works.

**Prestige**
- Render actual layout screenshots at **432×960** and **540×960**, normal and longest realistic content/localized names; test all relevant Prestige surfaces, including maximal offers and long confirmation lists.
- Assert each card/button/modal is bounded by the actual panel/viewport safe area, all necessary actions reachable by scrolling, no horizontal overflow, and stable open-panel geometry.

**Offline**
- Fresh profile: locked Weapons/Outfits/Supplies each read 0, explained, and link to Offline upgrades.
- Partially unlocked: only truly locked category says Locked; an unlocked category with no items shows 0 (not Locked).
- Fully unlocked with awarded items: correct per-category totals plus original item details; locked hint no longer shown.
- Navigate to upgrades and return, claim once, reload with pending settlement, no retroactive reward, no duplicate credit.

**Regression safeguards:** brief verification for Guided pointer targets, Change 63 notification/panel layout, and existing Prestige reset requirements. If an unrelated preexisting probe fails, report it with evidence; do not broaden scope to fix it casually.

## 6. Completion / Git handoff

1. Summarize the exact changes and any still-open platform-only findings. Include **which Prestige element(s) actually overflowed and why**.
2. List screenshots/probes, screen dimensions, result counts, English translation keys, and changed files. Don't claim Android device validation without doing it.
3. After focused checks, create a **local** commit, e.g.:

   `feat(change-64): use visual camp teleport and fix prestige/offline UI`

4. Do not push, publish, export, run a release workflow, edit the Reusable Playbook, or stage unrelated files. Stop after Change 64.
