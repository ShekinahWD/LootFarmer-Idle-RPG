# LootFarmer — Change 80: Spring XP, Critical Damage, Camp Supplies, and Stage Progression UI

**Task type:** Evaluate the current implementation, implement the four approved changes below, test, document, and make a **local Git commit**. Do not stop at an analysis or recommendation.  
**Source of truth:** The **current checkout**, not an older project ZIP or the numerical examples in historical reports.  
**Out of scope:** Reworking the reusable Godot player-profile architecture, unrelated game balance, and publishing.

## 0. Working rules

1. Read the repository's `docs/Reusable_Game_Development_Playbook.md`, `docs/LootFarmer_GDD.md`, and the relevant game code/data/UI/save/localization/test infrastructure. Use the **actual current paths** and files in the repository rather than assuming a particular structure.
2. This task starts after **Change 79** (`c050d99`) and the reusable player-profile framework commit (`80c0bf4`). Preserve those features. Inspect the worktree before editing. The developer's **uncommitted version-42 changes** to `project.godot` and `export_presets.cfg` belong to the developer: do not overwrite, revert, stage, or commit them. Do not force game version or Android version code back to 41.
3. Implement approved game rules in the existing systems rather than adding disconnected special-case code. Maintain compatibility with existing profiles, equipment, achievements, Prestige cards, and earned upgrades. Add save migration only where necessary, with tests.
4. Follow English-first localization rules: update source keys/copy, keep placeholders consistent, use safe English fallback in other locales, and record outstanding translations. Do not fabricate mass translations for 19 languages.
5. Verify results with actual game calculations, focused tests, regression checks, and visually inspected Godot captures for affected UI. Clearly distinguish measurements from estimates, and compare against the known baseline failures rather than claiming they were fixed.
6. Don't push, export, upload to Google Play/itch.io, or alter unrelated player profiles, store assets, gameplay, or the shared external Playbook. Commit **only your authorized implementation and necessary repo documentation/tests** locally, per Playbook. Never include developer-owned uncommitted changes.

---

## 1. Spring I / Spring II XP reward rebalance

### Problem

The player reports that XP progression through **Autumn I and Autumn II feels broadly acceptable**, but Spring XP reward scaling has excessive jumps, particularly in Spring II. As one real observation, a player near level 63 in Autumn I earned the next level by fighting Mushroom Cap enemies for about five minutes. Keep this real datapoint as context, **not** as a mandatory leveling rate at every stage.

**Approved direction:** Keep the existing **player XP requirement formula** (`ceil(12 * level^1.35)`, subject to current-code verification), level cap, XP upgrade effects, and rewards for stages 1–6 unchanged. Increase the starting Spring I normal enemy XP from **358 to 500**, then adopt smoother increments throughout Spring I and Spring II; reduce Spring II's wildly disproportionate boss rewards. Do not globally nerf XP or touch Winter, Summer, or Autumn.

### Normal enemy XP target table

These numbers were proposed in the conversation as the **initial target values**. Verify entity IDs/names and their current base rewards in the live catalog before editing; use the current in-repo names if any display names differ. Implement the target schedule and validate its real progression effects.

| Stage | Enemy | Prior base XP | Target base XP |
|---|---|---:|---:|
| Spring I (7) | Bunny Ears | 358 | **500** |
| Spring I (7) | Cat Ears | 600 | **650** |
| Spring I (7) | Elf Ears | 1,005 | **850** |
| Spring II (8) | Flower Crown | 2,821 | **1,050** |
| Spring II (8) | Green Cap | 3,978 | **1,250** |
| Spring II (8) | Pink Cap | 5,612 | **1,500** |
| Spring II (8) | Pink Flower Hood | 7,916 | **1,800** |
| Spring II (8) | Plain | 11,166 | **2,150** |
| Spring II (8) | Sprout | 15,750 | **2,550** |

### Boss XP target table

| Stage | Boss | Prior base XP | Target base XP |
|---|---|---:|---:|
| Spring I | Bee | 20,000 | **20,000 (unchanged)** |
| Spring I | Orange Tabby Cat | 23,750 | **23,750 (unchanged)** |
| Spring II | Red Panda | 879,610 | **30,000** |
| Spring II | Sunflower | 1,044,700 | **35,000** |
| Spring II | Green Alien | 4,912,510 | **45,000** |

### Implementation/validation requirements

- Base rewards above are **before multipliers** (XP upgrades, Prestige, etc.); existing multipliers continue to work unchanged. No XP requirement formula change, skill changes, enemy strength changes, boss encounter changes, or other stage reward changes.
- Check whether the game grants XP through boss kills, scripted objectives, missions, offline rewards or another route and ensure changes affect the intended **base kill XP** consistently without breaking reward or UI summaries.
- Measure **XP/minute, kills/minute, XP per level, predicted time to next level, and boss level-jump impact** for representative real stage-appropriate builds in Autumn II, Spring I and Spring II. Use multiple seeds/build states where reasonable, and account for player upgrades and the current boss rebalance. A controlled test is preferable to reusing player-profile results that may contain policy limitations.
- Verify Spring II bosses do not unexpectedly award many levels in one kill under normal builds. Also check that reducing their kill XP does not make Spring II normal farming pointlessly slow. **Do not independently change other balance numbers** to compensate. If this schedule exposes a serious progression problem, report the exact evidence and apply only narrowly justified changes **within these listed XP rewards**; disclose deviations from the table rather than silently replacing the approved direction.
- Record a clear before/after XP table and measured/estimated impact in the Change 80 completion report.

---

## 2. Critical Damage Gem upgrade and Prestige card

### Approved values

| Setting | Before | New |
|---|---:|---:|
| Base critical-hit damage multiplier | 110% | **110% (unchanged)** |
| Each level of the global Critical Damage Gem upgrade | +10 percentage points | **+5 percentage points** |
| Global Critical Damage upgrade cap | 20 | **20 (unchanged)** |
| Challenge Prestige Critical Damage card | +75 percentage points | **+40 percentage points** |
| Upgrade currency, base price, cost scaling, and purchased levels | Current values | **Unchanged** |

For the current catalog this was historically `upgrades.critical_damage.effect: 0.10 -> 0.05` and `campaign.cards.challenge_c3.value: 0.75 -> 0.40`. Confirm current keys and implementation before changing.

**Expected base + upgrades + that card only (excluding equipment/other bonuses):**

| Critical Damage upgrade level | No card | Card owned |
|---:|---:|---:|
| 0 | 110% | 150% |
| 5 | 135% | 175% |
| 10 | 160% | 200% |
| 15 | 185% | 225% |
| 20 | 210% | 250% |

### Requirements

- Keep existing **purchased upgrade levels**, the existing card ID, ownership, set/path requirements, cost progression and prices. Apply the new effect automatically to existing saves (no removal, refund, or reset).
- Verify the game computes critical damage consistently in actual combat, stat panels, descriptions, previews, and any simulations/tools. Don't accidentally treat +5% as a multiplicative 5% compounded increase; this is a **flat +0.05 to the crit multiplier per upgrade level**.
- Update English UI card and upgrade descriptions if they contain the old numerical effect. Retire stale keys/strings through the normal process and record translation work outstanding.
- Test levels 0/1/5/10/20, card owned/not owned, equipment modifiers, critical-hit combat damage, and persistence after save/load and Prestige.

---

## 3. Camp Supplies — three supplies per camp every 10 minutes

### Problem and approved rule

Camp Supplies (`regional_c3`, formerly Camp Survey) currently gives **one free random supply on the first qualifying visit to each owned camp per Prestige run**. That one-time reward is not sufficiently meaningful. Replace that model with **three free random supplies per eligible owned camp, repeatable every ten minutes per camp**.

**Keep its card identity and all existing Regional path/set/ownership requirements unchanged.** The camp's independent cooldown, **not Prestige**, controls future rewards.

### Required behavior

1. A player must own the Camp Supplies Prestige card, be alive, and physically be within an **owned** camp's legitimate visit/rest radius on a map accessible in the current run. Preserve existing blocked states (for example, no grant during Prestige selection) where appropriate.
2. On the first qualifying visit with no active cooldown, grant a **batch of 3 random supplies** via the normal weighted supply pool appropriate to the current map and existing inventory/granting code. No Coins/Gems spent. The supplies need not be the same type.
3. After a completed batch, that specific camp has an independent **10-minute cooldown**. No reward from that camp until it is ready. Other owned camps have independent availability and cooldowns.
4. **Timers continue to progress while the player farms or travels elsewhere.** The player does **not** have to stand in the camp. Once ready, returning to that camp grants another batch of 3. A player already at the camp when it becomes ready should also be able to receive it without leaving/re-entering. Use the game's appropriate clock/cooldown model, persist it across save/load, and **explicitly document whether the clock also advances while the app is closed**; do not invent offline reward production. Ensure pauses, clock changes, and reloads cannot be exploited to claim duplicates.
5. **Prestige does not reset individual camp cooldowns.** Owned camps and card ownership already persist; access still returns to Winter I and only currently accessible maps can be visited. The same cooldowns should resume when later maps are accessed. Hard Reset clears all cooldown and pending-reward records.
6. **No accumulation:** an unvisited ready camp holds **at most one pending 3-supply batch**; it does not bank one batch per elapsed 10-minute interval. No teleport/reload/respawn exploit.
7. Respect actual inventory slot/stack/capacity rules. **Never consume or silently lose a reward because the inventory is full.** Because there are 3 supplies in a batch, handle partial capacity safely: either grant eligible items incrementally with an exactly-once persisted remaining count, or another equally safe policy. Never duplicate already granted units; only restart that camp's 10-minute cooldown after the complete 3-unit batch is delivered. If no supply fits, defer and show the existing concise inventory-full notice without spamming it. Ensure pending state is saved, including partial batches.
8. Keep feedback short and non-obstructive (for example `Camp Supplies: +3 supplies`, or individual item feedback consistent with the existing loot feed). Show actual granted quantity rather than claiming +3 when only 1–2 fitted. Avoid spam while waiting for inventory space.
9. Handle existing saves from Change 77/79 containing the old per-camp, per-Prestige rewarded list: safely migrate/retire the old tracking. Preserve player items, existing ownership and other progress. Prevent instant repeated grants during migration and document the chosen first-eligibility treatment. Avoid retaining stale tracking that will reinstate the once-per-Prestige rule.
10. Update the card's English name/description/effect preview to communicate **3 supplies, each camp, every 10 minutes**; preserve narrow portrait card readability and existing localization fallback.

### Tests

- First eligible visit gives up to 3 units, no cost, correct map supply pool/weights; no grant without card/ownership/access, while dead, or during inappropriate UI states.
- Two camps have independent timers; camping/teleport loops never double-grant; waiting away from camp allows cooldown to complete; ready reward can be claimed without crossing an artificial enter/exit boundary.
- Cooldowns and partially claimed batches survive save/load, app relaunch and Prestige; Hard Reset clears them; late-map camps do not grant before map access is restored.
- Full inventory and partial space are handled without rewards lost or duplicated; the feedback reports exactly what was granted.
- No indefinite backpay after long absences; one outstanding batch max per camp.
- Regression coverage for legacy `regional_c3` ownership and old tracking saves.

---

## 4. Make the 8-stage progression order obvious in the stage/map selector

### Problem

The current stage selection consists largely of independent buttons. It's difficult to tell the canonical progression sequence or which stage to unlock next.

### Approved UX direction

**Improve the existing stage/map selection panel**, rather than adding another permanent HUD widget. Present a **compact, numbered, vertically ordered progression list**, grouped clearly by season:

| Order | Stage | Season |
|---:|---|---|
| 01 | Winter I | Winter |
| 02 | Winter II | Winter |
| 03 | Summer I | Summer |
| 04 | Summer II | Summer |
| 05 | Autumn I | Autumn |
| 06 | Autumn II | Autumn |
| 07 | Spring I | Spring |
| 08 | Spring II | Spring |

### Behavior and visual states

- Always show **01–08** in canonical order, with visually clear **Winter / Summer / Autumn / Spring** grouping and the I→II sequence. Use the existing icons/art/theme where appropriate; do not invent unrelated assets.
- Clearly distinguish **Completed**, **Current map**, **Next to unlock**, and **Locked**. These are distinct concepts and may overlap: implement sensible status priority or separate badges. **Do not infer that a stage is completed just because it was visited or its map is currently selected**; use existing real completion/unlock data. If necessary, use `Unlocked` instead of a misleading `Completed` status.
- **Next to unlock** is determined from the player's **farthest unlocked stage and genuine progression requirements**, **not** from their current travel location. Returning to Winter I must not falsely make Winter II the next goal if the player has unlocked Autumn I.
- If the next stage is still locked, label it **NEXT** and visibly show that it remains locked/unavailable; do not bypass unlock requirements. If all eight are unlocked, use a clear final/fully-unlocked state without a phantom ninth stage.
- Highlight the currently visited map separately. All previously unlocked stages remain selectable as before, and the stage selector must preserve the existing map travel/camp teleport behavior, disabled states, unlock flow, and input semantics.
- Keep the interface concise enough for Android portrait layouts: vertically scrollable with obvious scrolling, visible progress/selected states, touch targets appropriately sized, no clipped labels and no overlap with other UI. Inspect at least **432×960 and 540×960**, plus narrower/longer localized labels; ensure no clipping on longer translations and no inaccessible stage rows.
- Use localized full messages, not rigid concatenations likely to break translation. Add/update English semantic keys and preserve non-English fallback as needed.
- Avoid expensive per-frame rebuilding of selectable controls, especially while the user scrolls. Do not regress previously fixed touch-scroll instability in Prestige and other panels.

### Test cases

1. Fresh save at Winter I: next stage clearly shows Winter II without permitting premature travel.
2. Stage 5 unlocked, player physically on Stage 1: current location shows Winter I, **next to unlock is Autumn II**, and Winter II is not misrepresented as next.
3. Stage 8 unlocked: no next stage, all eight ordered and available according to existing rules.
4. After Prestige, all prior map unlocks are reset appropriately while camp ownership persists; stage statuses reflect **current-run** access rather than retained camp ownership.
5. Scroll/touch/accessibility at the two portrait sizes and long non-English text; unlocking and teleport functions still work.

---

## 5. Cross-feature tests, deliverables, and boundaries

### Validation

- Add a **focused Change 80 regression probe** covering the exact XP table, crit upgrade/card math, repeatable Camp Supplies/cooldowns/save migration, and stage selector state calculation.
- Run the maintained regression suite and compare failing probe names/error lines with the baseline (previously **16 known failures**); distinguish newly introduced failures. Do not blindly modify old tests to mask genuine regressions.
- Run controlled before/after progression checks for XP and critical damage, including existing equipment and Prestige ownership. Note that the player-profile tool may be used **only as a testing tool**; **do not change the shared `addons/player_profiles/` engine or universal profile definitions**. Don't claim that profile estimates are authentic human behavior.
- Inspect/capture stage selector and Camp Supplies UI at Android portrait sizes; identify what still requires physical-device confirmation.
- Update the game-specific GDD/technical documentation with actual shipped rules; do **not** edit or sync the external Reusable Kit/Playbook in this batch.
- Keep game version/code and release/publishing decisions out of scope. Specifically preserve the developer's existing **uncommitted version-42** files unchanged.

### Final report

Provide a concise but complete report with:

1. Implemented features and files touched; any scope deviations or migration choices.
2. Exact **before/after XP** tables, crit multiplier progression and card value, Camp Supplies cooldown/batch semantics, and stage-selector state rules.
3. Before/after leveling metrics with assumptions and source of measurements, plus important side effects.
4. Validation results, screenshots/evidence paths, known issues, phone checks remaining and baseline vs new failures.
5. Worktree safety confirmation and **local Git commit hash**. No push/export/upload.

**Authorization:** Evaluate and implement all four items in one batch without waiting for a separate approval. Do not substitute a report-only audit. If unexpected current code differs from historical example values, use the current checkout, preserve the approved intended behavior, and transparently explain the discrepancy and resolution.
