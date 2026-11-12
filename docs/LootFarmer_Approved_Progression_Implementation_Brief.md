# LootFarmer: Idle RPG — Approved Progression, Prestige & Balance Implementation

**Status:** Approved for implementation in **separate, validated, locally committed batches**.  
**Date:** 2026-11-07  
**Authority:** Developer decisions in the November 2026 design discussion, superseding contrary *recommendations* in the audits.  
**No store upload, publication, push, or release tag is authorized.**

## 1. Source of truth and workflow

Before editing, inspect the **actual current Claude working tree**, including Git status, version, catalog, saves, tests, and any developer-owned uncommitted changes. Follow the **current** `docs/Reusable_Game_Development_Playbook.md` (especially §§44–45, 59–61, 112, 132, 140), the canonical game GDD and runtime source. Use these reports as evidence, not as replacements for the live game:

- `docs/LootFarmer_Consolidated_Progression_and_Prestige_Audit_Report.md` and `docs/Consolidated_Audit_Evidence/`.
- `docs/LootFarmer_Player_Feedback_Balance_Audit_Report.md` and `docs/Player_Feedback_Audit_Evidence/`.
- Preserved `tests/player_feedback_audit.gd/.tscn`, `tools/player_feedback_audit_*.py`, and the Change 36 final-boss tests, **if present in the live tree**.

**Implementation is authorized**, unlike the earlier audit-only requests. Implement the approved design in the dependency order in §9. Keep the work in focused batches and **create one local Git commit after every completed, validated batch**, without waiting for the developer's manual Android playtest. Use the next available sequential `change-N` identifier, the Playbook's commit format (`feat(change-N): …`, etc.), and report hashes. Do not assume the audit's `3dd2eab` commit, save schema, version, or test paths are still current.

**Guardrails:** Preserve every existing player save; do not weaken game logic merely to satisfy stale tests, do not overwrite unrelated developer work, and do not alter store identity/signing or release settings. Stage only intended files. If a destructive compatibility conflict cannot be resolved safely, stop that affected batch and report the blocker instead of risking save loss. A successful automated check is not an Android acceptance test.

## 2. Approved Prestige model — definitive behavior

| **Keep through Prestige** | **Reset on Prestige** |
|---|---|
| Player level and XP | Completed levels/stage clears and playable stage access (restart at Winter I) |
| **Coin balance** and Gem balance | All carried **weapons, outfits, skills and consumables/supplies**, quantities and loadout |
| **Every purchased upgrade**, whether Coin- or Gem-funded | Current inventory-specific random attributes/rolls, including boss extras |
| Permanent **per-item-ID merge levels** of weapons, outfits, skills | Purchased camps (ownership only) |
| Prestige cards, original Set bonuses, achievements/milestones | Incomplete missions and run-specific counters/state |
| Discovered enemies/bosses, revealed terrain/fog, exploration | Supply Mastery/usage credit, transient buffs, boss timers and pending pickups |
| Already-earned, unclaimed **main objectives** remain claimable | No unearned objective or item reward is fabricated |

- **No currency conversion is needed.** Coins and Gems have different prices/purposes, **not** different Prestige persistence. Coins earned before Prestige stay in the wallet.
- **Merge memory** must be a persistent per-ID record separate from inventory. Reacquiring an item restores its prior merge level; owning none grants **zero equipped, stored or passive item power**. Different evolution tiers are different IDs; do not add an evolution-unlock record.
- **Camp exception:** camp purchase/ownership resets. A previously purchased camp-scoped upgrade (e.g., camp reveal radius) **remains bought**, but activates only after the camp is bought again.
- Previously discovered and explored places may remain **visible** on the map but cannot be entered until their stage access is re-earned. Map Detail stays bought, so discovered markers remain visible where eligible.
- **Completed but unclaimed regular missions:** auto-credit rewards **once** inside the atomic Prestige transaction, then reset the mission list. Incomplete missions lose progress. **Earned but unclaimed main objectives:** preserve their claimable state through Prestige (do not silently discard or auto-complete additional objectives).
- **Unclaimed offline earnings:** resolve in the same transaction before the inventory wipe. Credit earned Coins/Gems once; any pending gear/supply copies are removed by the inventory reset, so they cannot be claimed into the fresh run. Do not duplicate grants across saves/reloads.
- Price repeat-run missions from **the current run's unlocked stage**, not the player's historical highest stage; avoid late-map rewards for trivial Winter I missions.
- Normal Hard Reset still wipes everything, **including merge memory**. Do not confuse it with Prestige.
- Maintain the current atomic/recoverable Prestige card-choice transaction. Test interrupted writes, resume, reload twice, and failed save writes for duplication or partial resets.
- Prestige confirmation must explicitly say what is retained and lost, including Coins, all upgrades, per-ID merges, item rolls, stage access and camps. Distinguish existing permanent camp upgrades from reset camp ownership.

### Existing-player migration — mandatory

The game is already released; **no existing player is allowed to lose a save or achieved merge level** because of this update.

1. Add versioned save migration (audit suggests **schema 9** if still applicable), performed before validation. Preserve a **restorable, pre-migration save/backup**; guard against older builds rejecting and replacing a migrated file. Never treat an unknown old field as permission to delete the profile.
2. Populate merge memory from the maximum valid per-ID merge seen in **current items and historical Map Mastery**. This intentionally restores merge progress previously lost during older Prestiges. Never assign inventory ownership when restoring historical merge levels.
3. Older weapons already above the new ^20 cap **retain their original exact merge level and earned progression**; they remain valid on load and after Prestige, but new merges for evolvable tiers stop at ^20. Do not clamp or invalidate these records. Obsidian retains its normal ^100 ceiling.
4. Existing high-tier copies that would lose power from rebased tier stats must remain **playable at their old power until the player's next Prestige** (e.g., legacy-stat representation, if verified safe). On the next Prestige they leave with inventory; when the item is reacquired, it uses **the new balanced stats**, plus the **original preserved merge level** for its canonical ID. Reacquired random attributes are rolled anew and can be rerolled normally. **Never map legacy IDs in a way that discards the original canonical ID's merge memory** or grants a different tier for free.
5. Preserve old owned Prestige cards, consumed opportunities, original 3-card Set activation and existing achievements. Validate fresh, midgame, late-game/high merge, open-Prestige-batch, and pre-upgrade old-save fixtures. Test save/load once and twice, atomic rollback, and hard reset.
6. If a save migration policy for a special edge case conflicts with the approved preservation promise, show the exact case and a safe alternative before destructive changes.

## 3. Weapon tiers, merge and evolution — approved numbers

| Stage | Normal enemies | Stage bosses |
|---|---|---|
| 1 — Winter I | Wood (T1) | **Enhanced Wood** |
| 2 — Winter II | Stone (T2) | **Enhanced Stone** |
| 3 — Summer I | Iron (T3) | **Enhanced Iron** |
| 4 — Summer II | Gold (T4) | **Enhanced Gold** |
| 5 — Autumn I | Diamond (T5) | **Enhanced Diamond** |
| 6 — Autumn II | Emerald (T6) | **Enhanced Emerald** |
| 7 — Spring I | Obsidian (T7) | **Enhanced Obsidian** |
| 8 — Spring II | Obsidian (T7) | **Enhanced Obsidian** |

Keep the existing Sword/Axe families and normal-enemy weapon-family assignments. Include the final boss: its loot must be a same-tier **enhanced Obsidian** weapon (audit recommends a Sword). The first Snowman boss weapon guarantee now grants an **enhanced Wood Axe**, not a Stone Axe.

- **Approved H24 stat ladder:** sword base damage starts at **4.0 Wood**; each step through Emerald multiplies by **1.9**; Emerald → Obsidian multiplies by **2.4**. The audit's reference bases (rounded) are **4.0, 7.6, 14.44, 27.44, 52.13, 99.04, 237.7**. Preserve intended Axe tradeoffs (0.8× sword damage and HP based on the sword tier's base, per audited formula), subject to the regression gate.
- Weapon core stat merge gain remains **+2% of that weapon's base per merge level**. Normal evolveable weapons stop new merging at **^20**; Obsidian can merge through **^100**. Legacy over-cap values stay valid but cannot be increased beyond their new evolution-cap rule.
- **Evolution requires ^20 plus 10 spare copies**: 31 total acquired including the first copy and 20 merge copies. Each **repeat evolution also costs 10 spares**. Verify that Merge All and Auto-Merge do not eat the 10 spares, and Auto Evolution can actually trigger.
- Evolving consumes **10 spare source copies**, keeps the source's final ^20 record and remaining source copy, and **adds exactly one copy of the next-tier item ID**. The target uses its own persisted merge level, whether ^0, already owned, or reacquired after Prestige; **never transfer the source's merge level to the target**. Do not overwrite the target quantity or roll state.
- Do not use the old evolution `base_multiplier=0.85` to recreate the ×2.55 ladder. Validate realistic copy acquisition and repeated evolution, including auto-merge/auto-evolve interaction and no copy loops.
- **Arsenal and Masterwork** opportunities previously requiring ^50/^100 evolvable weapons need revised achievable thresholds, based on the audit §7.3. Keep the original card IDs and achievements meaningful.

## 4. Boss-enhanced weapon attributes — exact approved model

- A normal weapon uses the game's existing **one rerollable bonus attribute**.
- A boss-origin copy of the same item ID adds **exactly two additional bonus attributes**, giving up to **three independently rerollable attributes** on that owned weapon ID. Use **only** the existing bonus stat pool and normal per-tier reroll price ranges. Do **not** invent new rarities, item identities, or an attribute-quality ladder.
- If the player already owns a normal version, **the first boss-origin copy for that item ID** adds the two extra attributes once. If the first owned copy is from a boss, it receives them immediately. **Later boss drops are ordinary copies for merging**; there is no better-roll comparison, replacement, extra improvement, or new attribute roll on the second boss copy.
- All copies of the same ID, from bosses or normals, share the same inventory stack/merge progression. Merging increases core stats **only**, never rolled bonus percentages. Rerolling **one selected slot** leaves the other two unchanged. Avoid duplicate attribute types across slots as recommended in the audit.
- Preserve an enhanced-drop/source flag through pickups and save/load so delayed collection works. Offline drops remain ordinary copies of gear already owned.
- Attributes, including boss bonuses, are **run-specific and removed with inventory at Prestige**; merge levels alone persist. Newly reacquired equipment rolls attributes for the new run. The final design is **simple first-enhancement-per-run, not a boss-drop roll-hunting system**.

## 5. Combat balance — approved structure and tuning

- **Winter I:** retain passive early behavior. **Winter II:** individual/proximity aggression. **Summer I:** switch from group assistance to **individual/proximity aggression**, as in Winter II. **Summer II through Spring II (Stages 4–8):** coordinated group aggression.
- **Never cap simultaneous attackers.** Default spots normally have **3 enemies**. A player can **voluntarily purchase Spawn Amount to increase to 6**, accepting substantially greater risk. **Do not nerf enemies just to make all optional 6-enemy spots safe.**
- **Approved numerical starting rules:** skill variant's damage multiplier **1.35 → 1.15**; Spring I and Spring II **normal-enemy damage ×0.60** relative to their pre-adjustment stage base. For a Spring normal skill variant these apply **multiplicatively** (0.60 × 1.15 = **0.69** against that enemy's base). **Bosses are exempt** from both normal-only adjustments.
- Do **not** introduce group-joining stagger or three-attacker cap; both were rejected/unneeded. Preserve boss telegraphs and normal boss skill behavior unless a specific verified regression requires a narrowly approved fix.
- **Primary balance target:** first-time progression with default **three-enemy** spots should be farmable at reasonable, attainable builds; **bosses should remain meaningful milestones** and require some current-stage preparation. Difficulty from optional six-enemy spots is the player's chosen risk, not a mandatory pass criterion.
- Check the combined **H24 + Spring ×0.60 + variant ×1.15** outcome; Spring's ×0.60 was originally tested under the A19 ladder. Rebuild/rerun Change 36 final-boss tests with real **Obsidian** weapons. Record boss times, HP left, TTK/TTD, farm deaths, first arrival vs prepared, first run vs Prestige. Use legal owned/equipped builds and actual simulation, not DPS arithmetic alone.

## 6. Permanent upgrade economy and pacing

- **All purchased Coin and Gem upgrades survive Prestige at their existing purchased levels**, including enemy-specific upgrades. Keep their **current currency type**, except for any explicitly necessary technical correction; do not implement the prior “Coins reset/Gems kept” concept.
- **Approved targeted affordability change:** for **the first five levels** of enemy-type **Coin Amount, Enemy XP and Loot Chance** Coin upgrades, multiply current cost by **0.25** (75% cheaper). Later levels keep the current cost curve. Scope this precisely; do not apply the discount to every Coin upgrade.
- No 50% map floor or shared-map upgrade conversion. Per-enemy investment remains a decision, with affordable early progression on newly farmed targets.
- Keep mission rewards priced from the **current run's unlocked stage** (see §2). Check currency/XP sources and sinks over multiple Prestiges with retained Coin balances and upgrades; ensure earlier stages accelerate while genuinely new stages still require farming. Do not add XP multipliers or new sinks without measured need and another approval.

## 7. Prestige opportunities, cards and Set bonuses

**Approve the audit's Design A:** expand **33 opportunities/33 cards → 48 opportunities/48 cards**, using existing 11 paths and **15 new opportunities + 15 cards** (audit §7.3 contains proposed IDs, actual enemies, targets, card names and initial effect values). Expand repeated Expedition/Collection activities by stage and fill missing boss/exploration objectives. Expected stage appearances are **5, 6, 5, 6, 5, 6, 5, 6** for Winter I to Spring II; an opportunity spanning maps may be shown in more than one grouping. Fix Trophy grouping from the stage where the requirement is really performed.

**Firm Set rule:** **The original three cards in each path activate its existing Set bonus, exactly as before**. An expanded path may show 3/8, 4/8, etc., but its original three-card Set remains earned. **Do not introduce an all-cards second Set bonus; do not require 8/8 for the existing bonus; do not remove or rewrite already-owned cards or Sets.** Additional cards each provide their own effect.

- Implement the audit's proposed **15 cards** as the starting feature specification, with numerical values validated against the new weapon/combat ladder before declaring the Prestige batch complete. New effects should favor normal farming, survival and alternative strategies, not just more boss damage. Existing cards and cross-path combinations keep their meaning.
- Keep **opportunities path-specific**: an exhausted path must **not** silently award random cards from another path. The audit's suggested cross-path overflow rule is **not approved**. Ensure each actual path has enough matching cards for its opportunities (and an honest no-card UI if there is a real exceptional state).
- Preserve already-owned cards and consumed opportunity IDs in old saves. Fix stage categorization through actual requirement data, not brittle suffix/name guesses.
- Validate 3-card Set activation with 4–8 card paths, owning the original three out of order, repeat Prestige, old saves, every opportunity's real reachability, and no accidentally duplicated awards.

## 8. UI, contextual education, documentation and localization

Implement the report's **M1–M3, O1–O2 and E1** contextual guidance with safe-moment arbitration, not mandatory tutorial steps:

- **Map Detail:** when a discovered map lacks markers, explain the upgrade, how to reach it, and that the purchased upgrade survives Prestige. Map cards describe the **actual next rank benefit**, not just `0 → 1`.
- **Offline gear:** where relevant, tell the player that purchased Offline upgrades grant copies **only of gear already owned**; provide navigation to the correct tab. Never promise an undiscovered item or interrupt a modal.
- **Evolution:** a one-time ^20 readiness hint explaining the ten additional copies and next-tier item.
- **Prestige confirmation/overview:** accurate explicit retained/lost lists. Explain that random item attributes reset but per-ID merges persist.

Use the Playbook's lower-panel, touch, accessibility and typography rules; validate **432×960 and 540×960** layouts, scrolling, reroll-per-slot UI, expanded Prestige cards and multi-language wrapping.

**Localization:** Follow the **current Playbook §132** and the existing released-language readiness architecture. Update semantic **English** keys and create a concrete changed-key/placeholder manifest and source-catalog freeze/handoff for the developer/ChatGPT to translate **19 non-English languages**. Do **not** automatically regenerate all 19 translations in one feature batch or quietly enable unvalidated strings/locales. After translated catalogs are supplied, Claude integrates/validates them in **5 + 5 + 5 + 4** batches with final 20-language QA before publication. Preserve currently enabled languages and safe fallback behavior. Do not claim all 20 translations are updated unless they actually are.

Follow the latest Playbook's documentation ownership: do not independently rewrite the canonical GDD or reusable Playbook without the prescribed developer/ChatGPT review; **report** known doc conflicts and provide precise proposed corrections. Keep handoffs in the appropriate `docs/ClaudeMDs/` structure, and test evidence in approved evidence/test paths; do not create arbitrary root-level Markdown change reports.

## 9. Implementation batches and required checkpoints

The audit recommends B0–B8. Execute as **separate, logically sized, locally committed batches**, adapting to the live code/tests and Playbook. Avoid making a risky all-at-once commit.

| Batch | Scope | Minimum acceptance |
|---|---|---|
| **B0 — Harness** | If needed, promote the audit what-if harness/builds/seeds and baseline evidence into reproducible tests. Do not disturb the preserved original. | Baseline compare is field-identical; Change 36 baseline runs. Commit test-only work. |
| **B1 — Save / Prestige** | Versioned safe migration, permanent Coin/upgrades/merges, inventory/stage/camp reset, atomic rewards handling, stage-based mission pricing. | Real old saves load; historical merges retained; item power absent without copies; no double claims; hard reset and write-failure/rollback pass. |
| **B2 — Weapons / Evolution** | H24 stat ladder and 8-stage drops; ^20/^100 caps; 31-copy evolution; preserve legacy weapon power/history; reachable Masterwork/Arsenal objectives; Snowman guarantee. | Exact copy math, Auto Evolution works, existing merge memory intact, ladder and Change 36 final boss rebuilt and passing. |
| **B3 — Boss enhancements** | First boss-origin enhancement per item ID, two additional attrs, reroll each, pickup persistence, UI. | 3 slots, no stat duplication, ordinary later boss copies, same merge stack, no leaked attributes across Prestige. |
| **B4 — Combat** | Summer I individual aggro, skill ×1.15, Spring normal ×0.60; no attacker cap. | Default 3-actor farming and bosses meet target with H24; optional 6 actors risky by design; boss-only regressions remain valid. |
| **B5 — Prestige expansion** | Design A 15 objectives/15 cards, correct map grouping, effects, same original 3-card Sets. | Every new objective legal and appropriately staged; no dead matching card; Set at original 3; old cards remain; balance cross-check. |
| **B6 — UI / English copy** | Contextual hints, accurate confirmation, translations handoff, layouts; document discrepancy handoff. | Every hint triggers/routes/retires; English key parity; 432/540 tests; no modal interruption. |
| **B7 — Localization integration** | **After** the developer provides translated catalogs, integrate 19 languages in 5+5+5+4 batches. | Per-batch keys, placeholders, layout and language switching; all 20 pass before release. Separate commits for each completed translation batch. |
| **B8 — Regression/release-readiness** | Combined simulation/fixtures, full maintained suite, Android device checklist and release notes. | Record measured vs projected, known failures, old-save checks and untested Android items; **no upload/publish** without separate authorization. |

**Per-batch reporting:** exact files/systems changed; actual tests run with pass/fail; current game display version and save schema; commit hash/subject; remaining risks and specific Android checks. Use the project's next `change-N` number for each implemented batch; **game version `MAJOR.MINOR` is separate** and must not be advanced mechanically on every commit. Never stage or commit user-owned unrelated changes.

**Completion gate:** No silent save data loss; first-run and repeat-Prestige behavior correct; all eight-stage first-arrival and boss-ready scenarios checked; correct inventory/merge/evolution/reward transactions; old 3-card Sets work; final-boss test uses Obsidian; English/UI/localization state reported honestly; Android testing still called out if not performed. Release is a separate approval.
