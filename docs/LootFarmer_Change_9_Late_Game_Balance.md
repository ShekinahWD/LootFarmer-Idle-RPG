# LootFarmer — Change 9: Outfit Growth and Late-Game Balance

**Engine:** Godot 4.7 · Android-first  
**Baseline:** The **latest repository state after Change 8 and the Snowman prestige-gate correction** (commit `780f0f4fe0f53e6e2caba17f53d919a823c6b8f5`), including any later legitimate work. **Do not revert to the old ZIPs, reference snapshots or prior versions of the game.**  
**Mode:** **IMPLEMENTATION REQUEST**, not another investigation. The developer has reviewed your late-game balance findings and approved the direction below. Make practical decisions on small remaining tuning details, implement, commit, notify when buildable, then finish focused tests. **The developer will evaluate feel and final balance through Android playtesting.**

## 1. Read first, scope, and environment safety

Consult the **current** project GDD, current content/balance and equipment catalogs, `docs/LootFarmer_Change_8_Notes.md`, relevant prestige documentation, current `docs/Reusable_Game_Development_Playbook.md` (especially layered validation §60.1, save compatibility §61, practical data/inspector editability §63.1, and campaign ceiling checks §137.3), plus **your most recent late-game outfit/final-boss investigation**. The numbers below are the outcome of that investigation, not an instruction to repeat it.

Inspect the latest code/configuration as needed to implement correctly. Stay focused on outfit growth, passive equipment contributions, Spring II enemy/equipment scaling and final-boss viability. **Preserve Change 8** UI, inventory comparison/pinning, map overhaul, fog/vision, camp interaction, skill duplicate-merging, 5% normal per-item drops, 30% boss drops, and Snowman-only prestige unlock. Do not redesign unrelated systems.

**Repository hygiene:** The prior investigation reported an unexpected change in `export_presets.cfg` (Android `version/code` 10 → 11 and `.10.aab` → `.11.aab`) and about 50 untracked `.import` / `.uid` artifacts. Inspect the working tree **without presuming who owns these changes**. Do not use indiscriminate `git clean -f`, checkout/reset, or overwrite export/signing settings. Do not add generated import/cache artifacts to Git. Preserve user edits; if their status requires attention, report it separately and commit only this change's intended files.

## 2. Required implementation and handoff order

### Phase A — Implement, commit, notify the developer

1. Implement the **approved balance changes in §§3–6**. Update source catalogs, effective-stat getters, player-facing explanations and essential balance documentation together. Keep save/legacy item compatibility intact.
2. Run only **small essential checks** before the build announcement: confirm the game parses/launches, new item stats can be calculated/equipped, Spring II catalog loads, and there is no obvious deterministic crash or hard progression blocker. Short arithmetic spot checks are fine; **no long campaigns or broad test suites now**.
3. **Commit the implementation** with a descriptive Git commit message. Never leave completed work uncommitted; don't include unrelated export/cache changes.
4. **Immediately send this as a separate, prominent chat update:**

   > **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   > **Change 9 outfit and late-game balance changes are implemented and committed.**  
   > **Build from: `<actual commit hash>`.**  
   > **🧪 I AM NOW GENERATING AND RUNNING THE REMAINING FOCUSED TESTS.**  
   > **Final regression checks and Android device testing are not complete.**

   Do **not** hold this notice until the test suite finishes. Do not stop work at the notice; proceed directly to Phase B.

### Phase B — Focused checks, docs, final commit/report

5. Add or adapt **only necessary targeted tests**, then run relevant existing groups and **one reasonable overall regression pass**, if affordable. Any balance evidence should come from **a few realistic, deterministic loadouts and arithmetic checks**; at most **1–2 short representative combat/pacing scenarios** if genuinely necessary. No long multi-seed campaigns, repeated 60–130-minute simulations, huge benchmark sweeps or unrelated performance work. Run heavy Godot tasks sequentially.
6. Finish GDD, content/balance, equipment/stat tooltips, save/contract documentation and Playbook lessons **only where changes actually require them**. Commit any additional test/docs/fix changes.
7. If a post-notice fix modifies gameplay or catalog values, **the earlier APK is outdated**. Commit, perform minimal buildability verification, and issue **a new build-ready notice with the newest hash**. Documentation/test-only edits do not require a new APK notice.
8. End with a short implementation table, important final formulas and costs/effective values, concise results of focused checks, exact commit hashes, working-tree caveats, and **what still needs real Android playtesting**. Never call headless results phone verification.

## 3. Outfit merge power — approved linear progression to ^500

**Keep outfits as single persistent item identities per outfit**; duplicates merge into permanent power, **without evolution into successor inventory items**. Keep **^500** as the maximum merge level. Do **not** extend to ^1000 or remove the cap.

Replace the current logarithmic outfit core-stat growth with the proposed **two-segment linear formula**:

```text
m = clamp(outfit_merge_level, 0, 500)
core_stat_multiplier = 1 + 0.02 * min(m, 100) + 0.01 * max(0, m - 100)
core_stat = outfit_base_stat * core_stat_multiplier
```

Reference values before milestone bonuses:

| Merge | Core-stat multiplier |
|---:|---:|
| ^0 | 1.0× |
| ^100 | 3.0× |
| ^200 | 4.0× |
| ^300 | 5.0× |
| ^400 | 6.0× |
| ^500 | 7.0× |

Use the existing core-stat/effective-stat pipeline; apply consistently in combat, previews, inventory comparisons, save/load, merges and offline item handling. Avoid unintended multiplicative stacking of random rolls, bonuses and milestones. **Do not change weapon evolution or skill merging** as part of this task.

### Outfit milestone bonuses (only while THAT outfit is equipped)

Use a **deterministic identical milestone ladder** for all outfits, scaled appropriately by the outfit's own tier `t`:

| Merge milestone | Equipped-only milestone effect |
|---:|---|
| **^100** | Unlock **Guard**: +`3 × t` Defense. |
| **^200** | Gain **+10% outfit HP** (a milestone bonus to that outfit's HP). |
| **^300** | Unlock **Recovery**: regenerate `0.05% × t` of max HP per second. |
| **^400** | Guard improves to **`6 × t` Defense** (replaces, does not add to, the ^100 value). |
| **^500** | **Mastery:** Guard improves to **`10 × t` Defense**; Recovery improves to `0.08% × t` max HP per second (replace prior values). Preserve any already-approved surplus-copy behavior at cap without multiplying milestone rewards. |

- Defense uses the existing combat reduction `100 / (100 + effective_defense)`; derive from authoritative effective stats instead of creating a second protection path.
- Recovery is **one new percentage-of-max-HP-per-second stat**, using existing health/healing rules and normal caps. The effect is active only while equipped, alive and in an appropriate combat/gameplay state; it must not accrue when paused, dead or offline unless the game explicitly supports that elsewhere. Use the authoritative healing/stat calculation, not a duplicate visual-side tick.
- The ^200 HP bonus is also a **milestone bonus**, so it is equipped-only; don't sneak it into stored-item passive power.
- Do **not** grant random permanent milestone rolls or ask players to choose a stat; the milestone track is predictable, compact and clear in the UI. Reaching ^100/^200/^300 should feel meaningful.
- Show **upcoming milestone**, attained milestone bonuses and current effects clearly (concise, scroll-safe Android item details, avoiding inventory clutter). Ensure items at ^500 and legacy saved items display the correct benefits.
- Implement the formula and milestone coefficients in the existing authoritative tuning/catalog infrastructure, not as scattered hard-coded copies. Inspector/data-editable when this fits the Playbook and current architecture.

## 4. Owned-but-unequipped equipment: passive bonus rules

Current owned-item passive bonus is **30%**. Change its treatment as follows:

- **Outfits:** passive contribution from an **unequipped** outfit's normal/core stats (including its duplicate-merge growth) is **15%**, instead of 30%.
- **Outfit milestone effects are equipped-only:** **0%** passive contribution when stored/unequipped, including Guard, Recovery and the ^200 milestone HP bonus.
- **Weapons:** decide during implementation whether their passive contribution should remain **30%** or also decrease to **15%**. Use a **brief** realistic damage comparison for middle/late stages and the final boss, taking into account their previously corrected shared identities and actual obtainable tiers. Choose the option that maintains useful progression **without compensating by unrealistic item farming**, and document the choice. No further approval is needed for this specific decision.
- The currently equipped item contributes its full equipped stats **once**, with **no extra owned-item passive from itself**. Validate it against the actual stat aggregation and upgrade/compare screens. Preserve other unrelated stat-source rules.
- Ensure outfit milestones from multiple stored outfits **cannot accumulate Guard or percent-regen** and that switching outfits updates stats immediately, without stale residual effects.

## 5. Spring II correction — fix the actual difficulty spike

Your investigation found that the previous reported **14-second survival / 463-second kill** ceiling test was invalid (it equipped no outfit, and relied on practically unreachable obsidian weapons). **Do not use that test as balance truth.** Fix its fixture or exclude its conclusions; make failed equips explicit rather than silent.

Apply the specific Spring II adjustment you recommended:

| Content | Current reported value | Target |
|---|---:|---:|
| Spring II normal enemy level band | 200–250 | **195–225** (retain intended within-stage progression) |
| Red Panda boss | 300 | **235** |
| Sunflower boss | 305 | **240** |
| Green Alien (final) boss | 350 | **250** |
| Final boss dedicated HP multiplier | — | **18×**, as a dedicated authored final-boss factor (avoid accidentally applying global ×18). |
| Spring II regular weapon drops | Tier 4 | **Tier 5 (Diamond)** |
| Spring II regular outfit drops | Tier 4 | **Tier 5** |
| Spring II boss weapon tiers | Tier 5 | **Tier 6 (Emerald)**, maintaining the approved *boss = regular enemies' tier +1* contract |

Further notes:

- The investigation estimated the retuned final boss around **305,000 HP and 346 damage**. These are **sanity-check anchors**, not unquestionable exact numbers; compute them from the actual current catalog after implementation, including the dedicated final HP multiplier and combat formulas.
- Keep the **existing boss-exclusive outfit strength** and outfit identity. Make Tier 5 Spring II outfit drops work with the no-outfit-evolution policy and actual available assets; the catalog reportedly contains suitable legacy tier-5 definitions. Reuse and activate those safely rather than introducing a new sprite pack or unrelated inventory IDs. Validate existing owned-item migrations and that drops, enemy visuals/gear, and boss gear use the same tiers.
- **Stages 1–7 stay as they are.** Do not rebalance their levels, weapon/drop tiers, drop chances, boss stats or terrain in this task. No global enemy HP boost.
- **Keep existing drop rules:** normal enemies 5% base per carried equipment item, per-type Loot Chance +0.5 percentage points per level up to 15 levels, boss equipment base 30%; this isn't an economy retune.
- Don't make the final boss trivial: it should remain a rewarding, difficult end-of-content challenge rather than an impossible exponential wall.

## 6. Validate against realistic progression, not impossible test inventories

Do a **bounded, trustworthy sanity check** of the revised combat math. Include at least:

1. One representative Stage 6 or 7 boss as a guard against accidental regressions.
2. Spring II Red Panda and final Green Alien at feasible gear levels (e.g. stage-appropriate weapon/outfit around ^100 and ^300–^500), **using real item identities and an inventory that actually owns and can equip them**.
3. A late-game setup with a **small plausible number of prestige cards** plus several naturally obtained attack skills; account for whether those auto-cast skills are actually accessible. Avoid giving the bot every card or inaccessible obsidian weapons.
4. Player **level feasibility** and drop/merge grind realism at the current 5% normal / 30% boss drop probabilities. A 35–50-hour maximum boss-outfit grind may be an optional ceiling, **not a mandatory progression bottleneck**. The final boss should be plausibly beatable before an outfit reaches ^500.
5. Survival vs. time-to-kill, including damage, Defense and Recovery, and the effect of reducing the outfit passive contribution to 15%. Check milestone-only-when-equipped behavior.

Do not claim that skills guarantee a ~180-second final-boss kill until the effective damage calculation supports it. Prefer a compact before/after table of a **few actual configurations** and list uncertainties for human playtesting. If your exact simulated damage differs from hand estimates, use the current game's formulas and briefly explain the discrepancy. Perform a narrow numerical adjustment only if essential to prevent an obvious late-game impossibility or exploit; don't start a whole-game retuning cycle.

**No extended bot campaign.** The developer, not an automated agent, will determine final combat feel from Android builds.

## 7. Focused acceptance, save behavior, docs and commits

Implement and/or update short tests for:

- Outfit linear merge multipliers at ^0/^100/^200/^300/^400/^500 and over-cap behavior.
- Equipping/unequipping a milestone outfit, percentage regeneration, Defense mitigation and pause/death handling.
- Stored outfit 15% core contribution, **zero** passive milestone bonuses, chosen weapon passive percentage and no self-double-counting.
- The actual Tier 5 Spring II normal drops and Tier 6 boss weapon drops, consistent sprite/item IDs, Stage 8 boss levels, and final HP multiplier.
- Existing old saves with outfit merge levels or legacy-tier items, including prestige/run-reset behavior and display/effective-stat consistency.
- A corrected ceiling/combat fixture that **verifies every requested item exists and the equip call succeeds** before calculating damage and survival. It must reject unrealistic impossible-to-obtain loadouts as proxies for natural progression.
- A few compact late-stage representative cases; include a Stage 1–7 smoke check showing you didn't shift earlier content.

Do essential checks **before** the first build-ready message only as needed to avoid shipping obviously broken code; defer the remaining work until after the notification. Document exact implemented formulas and the reason for the chosen **weapon** passive percentage. Add any broadly reusable technical lesson to the Playbook (e.g., realistic ceiling-fixture validation) without duplicating the entire investigation.

**Final communication:** link/identify the latest commits, distinguish the initial playable hash from later fixes, summarize what changed and what remains to be visually/balance-tested on Android. Always commit code and documentation changes; preserve unrelated local files and export configuration.
