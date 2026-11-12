# LootFarmer — Change 63: Guided Tutorial UI Corrections & Prestige Probe Repair

**Status:** Developer-approved follow-up from physical Android playtesting.  
**Scope:** Three Guided tutorial presentation issues plus the 11 outdated Prestige assertions in `change_16_probe`.  
**Source of truth:** Current local repository and its latest commits (particularly Changes 61/62 and Prestige correction `6d247d9`), the canonical GDD and the Reusable Game Development Playbook (especially sections 18.1, 18.3, 18.5, 18.6, 18.8, 44, 61 and 132).  
**Delivery:** A focused local commit; no localization integration, exports, push or publication.

## 1. Objective and boundaries

Fix three issues observed during real gameplay:

1. Guided pointers sometimes indicate a label/card/row that **cannot actually be clicked** to satisfy the lesson. In Winter II the optional-Prestige lesson points at **First Bounty**, but tapping it does nothing; the player must **close the Prestige panel** to continue, without being told to do so.
2. The tutorial never introduces **Map Mastery**. After the player reaches **100% exploration on ANY stage map**, offer a **one-time, optional and non-blocking** instruction showing where Map Mastery progress is viewed. No 100% exploration requirement may be added to the main Guided tutorial.
3. Notifications such as **Camp Found** overlap a Guided instruction while the player is following the world arrow to find enemies. The tutorial caption must remain visible and understandable, without waiting for an unrelated notice to disappear.

Also correct the **11 failing Prestige assertions in `change_16_probe`** inherited from the intentional Change 61 / `6d247d9` rules. Do not change the approved Prestige rules merely to make an obsolete test green.

**Preserve** the completed 35-step Guided flow, Basic/None mode behavior, existing final `THE ROAD AHEAD` message, mission tracking, Map Details, boss progression, selected respawn camp, save compatibility, Change 60 stat popups/VFX, Change 62 combat balance and all unrelated work.

## 2. Fix A — Every Guided pointer must indicate a real actionable target

### Specific Winter II Prestige defect

The approved optional-Prestige behavior is:

1. The player arrives in Winter II after defeating Snowman.
2. Guided points to the **actual Prestige navigation button**; entering the Prestige panel is required.
3. Inside Prestige, explain that the earned **First Bounty** opportunity can be redeemed now through an optional Prestige reset, or kept while the player earns more opportunities.
4. **When inspecting the panel, the guidance must explicitly say how to finish without resetting:** close the Prestige panel. Show its pointer on the live, tappable **Close / X control**, **not** on a non-interactive First Bounty card/label. If a player chooses a valid Prestige reset instead, that also completes the lesson.
5. Complete the lesson only when the player has actually opened Prestige and then either **closed it** or **performed a legitimate Prestige**. Then display the existing final `THE ROAD AHEAD` card, unchanged.

Suggested brief English copy while the Prestige panel is open (use the UI's exact button wording if different):

> **Prestige is optional.** You can reset now to claim your ready opportunities, or keep playing to earn more and redeem them together. **To continue without resetting, close this panel.**

Only add/change the specific semantic English key(s) needed to communicate the action; do not rewrite the entire lesson or 19 translated catalogs.

### Audit other pointer states within the existing Guided flow

- Inspect each **actual runtime substate**, not only the list of step IDs: before opening its panel; after opening; after following/selecting; when the target becomes unavailable; and after a panel closes or reopens.
- A tap pointer/arrow may target only a **visible, enabled, hit-testable control** that performs the indicated action, or an **actually valid interactive world target**. A static description, unclickable reward card, progress label, invisible/scrolled-away row or disabled button is not a legitimate tap target.
- For a **wait-only** lesson (farm 30 enemies; fight Snowman), use an appropriate world-direction cue or progress caption rather than a false tap pointer. For a purely informational message, either point at a real way to continue/close or use no tap arrow; never suggest clicking a passive element.
- The caption must name the actual next action and match the pointer: e.g. “Tap Close to continue” when only closing the panel advances; if both Close and a valid optional action advance, describe both.
- Resolve live controls after their layout settles and recompute pointers while panels scroll/rebuild. The pointer must hide rather than retain stale coordinates when the target disappears. Respect viewports, safe areas, modals, confirmation dialogs and input transparency.
- Do **not** make non-interactive cards clickable as a workaround, weaken completion predicates or skip mandatory lessons simply to remove an arrow.

## 3. Fix B — Optional Map Mastery introduction after 100% exploration

**Trigger:** The player reaches **100% exploration on any one map** (not necessarily Winter I, and not requiring all maps). Use the same authoritative completion criterion the game already uses for full-map exploration / Map Mastery. Do not create a competing percentage calculation.

**Presentation mode:** This is **optional contextual guidance for players who chose Guided**, not a new blocking step in the 35-step first-run sequence. The mandatory tutorial proceeds even if the player never reaches 100%. Do not inject Guided pointers into Basic or None.

**At the next safe moment** (with no mandatory Guided lesson/card, modal, incompatible panel or blocking notice covering the UI):

1. Briefly acknowledge the map is fully explored.
2. Tell the player where to view **Map Mastery**, using the **actual current navigation label and real clickable control**. Indicate that Map Mastery has additional objectives / rewards, without promising an unverified reward.
3. Offer a non-blocking pointer to the existing Map Mastery entry **only when it is visible and can be clicked**. Otherwise defer that pointer/notice safely; never show an arrow at hidden content.
4. Let the player **dismiss/ignore** the hint or open Map Mastery naturally. Opening Map Mastery may retire the hint; neither action is required for the main Guided tutorial to proceed or finish.

Suggested copy (adjust to the real surface's name):

> **Map fully explored!** Open **Map Mastery** to see your remaining mastery goals and rewards. This is optional—you can keep adventuring.

**Persistence and edge cases:** One-time per profile (not once per map); save its shown/dismissed/acknowledged state through save/load, stage travel and Prestige. Hard Reset may make it available again. If exploration reaches 100% during mandatory Guided teaching, leave the optional hint pending until a safe interval; do not steal the active tutorial pointer. If a Guided player already has a fully explored map but hasn't seen this hint, show it at the next safe moment where appropriate rather than requiring another map to reach 100%. A completed Guided tutorial does **not** disable this later contextual lesson. Never block progression or require the player to open Map Mastery for final onboarding completion.

If the current UI cannot offer an unobstructed pointer at the required moment, show a compact instruction when safe, without inventing navigation controls or suppressing gameplay.

## 4. Fix C — Tutorial/notification layout priority

**Reproduction:** The Guided lesson directs the player toward enemies using an arrow; a **Camp Found** notification appears over the instruction card/caption and obscures it for several seconds.

**Required outcome:** The active Guided instruction remains fully readable and its actionable control remains accessible at all times. Ordinary notifications never cover tutorial text or tap targets.

- Reuse the game's **existing banner/toast/tutorial arbitration** rather than adding a second notification system or a one-off `Camp Found` screen-specific workaround.
- Preserve important discoveries/alerts, but **defer, queue, or reposition** overlapping notifications so they display when space is available. Avoid dropping notifications or holding them indefinitely behind a guide that stays active during long farming steps. If an unobstructed independent location exists, show the notice there; otherwise use safe deferral/coalescing.
- Tutorial cards/pointers and toast banners must not overlap at **432×960** or **540×960**. Include cases with an open panel, a newly discovered camp and other discovery/banner notifications. Neither overlay may steal taps from the other.
- Respect priority: blocking modals/confirmations first, active Guided teaching next, ordinary notices afterward. But do not hide a legitimate active gameplay alert forever or permanently pause gameplay because of a low-priority notification.
- When a notice disappears, the tutorial should remain at its current step; it must not jump forward, lose its pointer, reset its caption or require the player to restart the action.

## 5. Fix D — Repair `change_16_probe` Prestige checks (11 failures)

The relevant approved progression, now implemented after Change 61 / `6d247d9`, is:

| State | Prestige menu / first opportunity | Prestige reset |
|---|---|---|
| Snowman **discovered**, never defeated | Menu open; `hunter_o1` discovered and followable | **Locked** in all modes |
| Snowman defeated **once** in Basic or None | `hunter_o1` completed/ready | **Unlocked** when other legitimate reset conditions are met |
| Snowman defeated once in Guided, but Winter II optional lesson not reached | Opportunity ready | **Still locked by Guided** |
| Guided reaches Winter II optional Prestige lesson | Opportunity ready | Optional reset available; closing without reset also completes lesson |
| Existing save already contains a lifetime Snowman defeat | Prior defeat recognized | Respects other genuine gates; no repeat kill required |

Work method:

1. Reproduce and inspect **exactly which 11 `change_16_probe` assertions fail** on the current repository, including fixture setup and old assumptions.
2. Update **only outdated test setup/expectations** to the approved one-defeat + Guided Winter II gate, using actual game state and APIs. A discovery-only fixture must now expect the reset to remain locked; a reset-eligible fixture must include a legitimate boss defeat.
3. Keep independent Change 16 expectations (e.g. combat/ability behavior and unrelated Prestige arithmetic) intact; never delete assertions, blanket-skip failures or falsely pass the probe.
4. If any failures reveal an **actual gameplay defect** rather than obsolete assumptions, fix only the necessary code and report the distinction. Cross-check with the existing focused Change 61 Prestige probe to guard against regressing the unlock rules.
5. The target is **`change_16_probe` fully passing**, with the previously failing Prestige checks meaningfully verifying current behavior.

Do not change the Prestige unlock rules, card rewards or first-boss goals simply to satisfy historical tests.

## 6. Focused validation only

This is a targeted Android-playtest correction, **not** another full balance pass. Do not launch the full 57-probe suite, long progression bots or lengthy Android automation. Keep each focused validation pass **approximately 10 minutes or less**, and repeat quick checks only when adjusting a defect.

Minimum checks:

1. **Prestige in Winter II:** Open panel → pointer targets real Close / X and copy tells player to close → tap Close → next/final lesson; also verify choosing a legitimate Prestige reset instead completes the lesson.
2. **Other interactive steps:** Quick pass over existing 35 Guided steps, especially steps that change panel context/scroll or follow a mission; no tap arrows on non-interactive labels/cards, no blocked targets, and no unrelated forced skips.
3. **Map Mastery optional:** At 99% nothing fires; at 100% on any map, one safe optional hint; dismiss/ignore and finish Guided without interacting; late 100% after Guided completion still teaches once; save/load/Prestige do not repeat it. A fully explored eligible old profile is handled safely.
4. **Notification collision:** Trigger Camp Found while enemy-direction guidance is active and inspect at **432×960 / 540×960**; both message and pointer stay readable; notice remains deliverable. Check an open-panel and another common banner case if quick.
5. **Prestige probe:** `change_16_probe` all checks passing and `change_61_probe` relevant reset eligibility checks still passing. Report exact counts, including any genuinely unrelated failures.
6. **Localization hygiene:** Register only new/changed English keys in `localization/en.po` and the existing pending-translation record; ensure all **19 non-English `.po` files remain byte-for-byte untouched**. Do not start the pending localization batches.

State explicitly what was *not* tested on physical Android. The developer will repeat the on-device tutorial check later.

## 7. Local commit and deliverable

- Start with `git status --short`; use the **current working tree**, not an older archived ZIP. Preserve the developer's unrelated uncommitted changes (`project.godot`, `export_presets.cfg`, Playbook, `add_speed_blur.py`) and the untracked Cartoon Coffee library/other assets. Stage only files this correction owns.
- Use the next sequential change number **63** unless the existing repository has already assigned it to something else; if so, report the conflict instead of silently reusing a number.
- After targeted validation, create one local commit, suggested subject:

  `fix(change-63): repair guided pointers, mastery hint and prestige probe`

- Report: changed files; what was fixed in each of the four areas; exact focused checks/results; `change_16_probe` before/after; English translation key delta; any remaining Android manual checks; commit hash.
- **Do not** modify the GDD, Reusable Playbook, approved non-English catalogs, unrelated gameplay/balance or other asset packs. **Do not push, export or publish. Stop after Change 63.**
