# LootFarmer — Change 60: Stat Change Feedback & Cleave Balance

**Status:** Developer-approved implementation brief for Claude  
**Execution order:** Change 60 (this batch) → Guided Tutorial restructuring (next separate change) → targeted localization → Android device validation.  
**Authority:** Current working-tree code, the game's canonical GDD, and `docs/Reusable_Game_Development_Playbook.md`. The uploaded `lootFarmer2.zip` was used to identify likely locations; Claude must inspect the **current repository**, including changes applied since that ZIP, before editing.  
**Scope:** Player-facing stat-change animation and one Cleave balance adjustment only.

## 1. Objective

Make it obvious that the player's **effective combat attributes** improve or decline when they level up, collect unique equipment, equip/unequip an item, merge gear, reroll attributes, buy relevant upgrades, or gain other effective stat modifiers. In particular, collecting a **new, unequipped** weapon or outfit may boost stats immediately, and that change should be visible without forcing the player into Stats.

Do not introduce tutorial lessons in this batch. The separate Guided Tutorial change will teach the stored-equipment rule and other approved lessons afterward.

## 2. Visual feedback — approved behavior

- Show a clean, readable **individual floating stat delta** near the player, styled to fit LootFarmer's portrait/pixel-art presentation. Use a green upward-arrow animation for an increase and a red downward-arrow animation for a decrease.
- **Show only the signed numeric change and stat name**, e.g., `↑ +12 HP`, `↑ +8 Damage`, `↓ −5 Damage`, `↑ +0.5% Crit Chance`. These are format examples, **not fixed rewards**. Do not add `Stored Bonus`, `Equipment Bonus`, `Level Bonus`, or other source explanations to the popup.
- When **several different stats change**, present each **as its own popup**, with **1.0 second between their start times**. Example: HP starts at t=0; Damage at t=1; Crit Chance at t=2. Animations may overlap while fading; do not combine the stats into one banner or display all simultaneously.
- Each popup should rise modestly, briefly emphasize the gain/loss, and fade away. Keep it readable above both snow and dark terrain without covering essential controls or the character for an extended period. Use existing theme/fonts/art where possible; no new external graphics or generated art.
- The floating text must not receive mouse/touch input. Anchor presentation to the visible player/camera, not to a fixed screen corner, while avoiding clipping at mobile viewport edges.
- Pausing or a blocking modal must not cause queued feedback to run ahead and disappear unseen. Cleanly clear transient feedback when a save is loaded, a hard reset occurs, or the presentation is replaced. Do not persist its queue in saves.

### Delta calculation and event scope

- **Use authoritative effective player attributes** from the simulation (`sim.stats()` in the inspected ZIP) **before and after actual state mutations**. Never display the raw item's stat or a guessed multiplier as if it were the total effective increase.
- Relevant examples: player level, new unique weapon/outfit pickup (including their stored contribution), merges, item evolution and rerolls where they actually change effective values, equipping/unequipping, persistent stat upgrades, and other changes to effective attributes. A collected duplicate of an already owned item should **not** produce a fake stat gain unless it actually changes the effective totals.
- The inspected project uses `sim.touch()`/`changed` to invalidate the computed `stats()` cache. Claude should use a safe, low-overhead authoritative comparison/event strategy, avoiding per-frame full-history scans or duplicate popups from repeated refreshes.
- **Do not** trigger for ordinary HP loss/healing during combat, XP accumulation without a level, coins/gems, item quantity changes without effective stat changes, or simply opening/closing a panel. Existing combat-damage, healing and currency notifications remain separate.
- Cover the actual effective stats in the existing Stats panel as appropriate (`hp`, `damage`, `defense`, `crit`, `crit_damage`, `lifesteal`, `regen`, `regen_pct`, `speed`). Use **existing localized stat names** and correct formats. Percentage-based attributes must display the correct percentage-point difference (do not display internal fractions like `+0.005 Crit Chance`). Use sensible precision and ignore purely floating-point noise.
- Use a consistent order for multi-stat changes (e.g., HP, Damage, Defense, Crit, Crit Damage, Lifesteal, Regen, Recovery, Attack Speed). If multiple rapid actions affect the same not-yet-displayed attribute, coalesce its pending net delta where practical, to avoid a growing backlog or misleading feedback. Never fabricate a positive gain when the net value did not rise.
- Preserve existing Stats breakdowns, comparison calculations, stored-equipment passive effects, and item/economy rules **unchanged**. In the inspected code, stored **weapons contribute 30%** and stored **outfits contribute 15%** (`stat_sources()` / `stored_factor()`); each distinct owned equipment type contributes once, and duplicate copies do not stack.

## 3. Cleave balance — exactly one value change

The Prestige card **Cleave** (catalog ID `expedition_c6`) currently has `effect: "cleave"`, `value: 0.3` in `data/game/catalog.json`.

- Set its secondary-damage share from **30% to 10%**: `value: 0.1`.
- Keep the **existing Cleave radius of 32 world units**, primary target damage, defense handling, acquisition, unlock conditions and all other card values unchanged.
- Update the **English source** `localization/en.po` key `CONTENT_EXPEDITION_C6_DESCRIPTION` from “30%” to “10%” (retain the same meaning and key ID).
- This affects already-owned Cleave cards naturally because the bonus is driven by catalog data; do not add a save migration solely for this change.
- **Do not modify the 19 non-English `.po` catalogs now.** They will receive this precise changed-key translation update in the scheduled localization pass **after** the Guided Tutorial batch. Explicitly flag that those localizations temporarily contain the outdated 30% description. Do not push, export for release, or publish an inconsistent candidate.

## 4. Implementation boundaries

1. Inspect the active working tree first (`git status`, relevant game scripts/scenes and current English source); retain unrelated user edits, Change 59, and translation batches already integrated.
2. Keep the implementation narrowly scoped to presentation/necessary simulation hooks, the single Cleave value, and the English source text. Reuse existing world feedback infrastructure or a small dedicated UI presenter when suitable; avoid a heavyweight new manager.
3. Do **not** restructure Guided onboarding, add new missions, alter camp/respawn travel, edit the GDD/Playbook, or alter approved non-English translations in this batch.
4. No changes to loot/drop/merge economics, combat base damage, save schema, offline rewards, or other Prestige cards.
5. Maintain phone performance: cap concurrent text nodes; use cleanup/pooling as appropriate and do not allocate the full Stats breakdown every frame just to animate feedback.

## 5. Focused validation and acceptance

Perform **targeted desktop smoke checks** and any short checks needed to confirm this batch. Avoid prolonged balance simulations or unrelated, full localization/Android testing; those belong later in the approved sequence. Create only minimal tests if a real regression risk justifies them; do not build a new broad probe framework.

- **Single stat:** leveling up displays the actual HP/Damage gains without treating healing as another stat change.
- **Stored gear:** collecting a first unequipped weapon/outfit visibly reports its *actual* effective delta (30% / 15% stored contribution). A duplicate by itself shows no fake gain; merging a copy reports only the actual new delta.
- **Equipment changes:** equipping/unequipping, a stronger/weaker swap, and a relevant upgrade show correct positive/negative numbers, not item-base stats or double-counting.
- **Several stats:** a change affecting ≥3 stats yields separate floating popups starting at 0 s, 1 s, 2 s. Confirm stable ordering, concise labels, fade and no input blocking.
- **No false triggers:** taking damage/healing, collecting only Coins/Gems, reopening Stats, loading a saved game, and rendering stat comparisons do not create fake attribute popups.
- **Cleave:** verify the catalog `0.1`, unchanged radius 32, unchanged primary hit, and that the English display says **10%**. Prefer a short deterministic combat scenario or existing focused logic check; account for the existing minimum-hit clamp in the damage formula when checking outcomes.
- **UI:** inspect a representative popup at **432×960 and 540×960**. Check text clipping, readability, pause/modal handling and cleanup.

If broader regression tests are not run, report them as **not run**, rather than passed. Do not perform final Android certification in this change.

## 6. Delivery and Git

After focused validation:

- Create **one local commit**, e.g. `feat(change-60): show effective stat deltas and rebalance cleave`.
- Do not push, publish, tag a release, or unexpectedly change user-managed `project.godot` / export settings.
- Report the actual changed files, implementation details, validations run (pass/fail and any unrun checks), commit hash, current game display version, and device/localization work remaining.
- **Stop after Change 60.** Do not start Guided Tutorial restructuring or the non-English translation update until the developer authorizes the next batch.
