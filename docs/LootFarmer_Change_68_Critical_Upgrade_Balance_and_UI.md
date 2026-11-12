# LootFarmer — Change 68: Critical Upgrade Pricing, Damage Balance & Effective-Stat Display

**Status:** Approved implementation brief — 11 November 2026.  
**Baseline:** Current local Godot repository after Change 67 (Phase 1 `2f1acb2`, Phase 2 `bd64446`). Claude must check the **live working tree** and current GDD/Upgrade Catalog before editing; earlier ZIP snapshots are not authoritative.  
**Process:** Follow `docs/Reusable_Game_Development_Playbook.md` (the shared Playbook link), especially effective statistics from authoritative gameplay getters (§17), save compatibility, localization, responsive UI, targeted validation, and local Git commits. **Do not modify the Playbook.**

## 1. Exact approved decisions

| Property | Existing/reference | Approved value | Scope |
|---|---:|---:|---|
| Player base Critical Chance | 5% | **5% — unchanged** | Do not change base chance |
| Critical Chance per purchased upgrade level | +1 percentage point | **+1 pp — unchanged** | No effect rebalance |
| Critical Chance upgrade first price | 250 Gems | **25 Gems** | Global Player upgrade |
| Critical Chance upgrade price growth | ×1.50 per level | **×1.25 per level** | All 20 ranks |
| Player base Critical Damage | 150% (1.50× hit multiplier) | **110% (1.10×)** | Change authoritative player base stat |
| Critical Damage per purchased upgrade level | +5 percentage points | **+10 percentage points** | +0.10 to multiplier per level |
| Critical Damage upgrade first price | 200 Gems | **15 Gems** | Global Player upgrade |
| Critical Damage upgrade price growth | ×1.50 per level | **×1.25 per level** | All 20 ranks |
| Maximum purchased upgrade ranks | 20 each | **20 each — unchanged** | Keep ownership and level storage |
| Critical Chance combat cap | Existing 75% | **Leave completely unchanged** | **No cap removal, increase, decrease or redistribution of other bonus sources** |
| Critical Damage combat cap | Existing cap, if any | **Leave unchanged** | No new cap design |

**Explicitly rejected/unapproved:** Do **not** raise base Critical Chance to 10%. Do **not** rebalance equipment, Prestige cards, stored-equipment contributions or other sources to make theoretical Critical Chance equal 75%. Do **not** change the existing Critical Chance cap. The user's only Critical Chance gameplay change is **price**, not stats.

### Unmodified effects of the new ranks

For a fresh player without equipment/Prestige/other sources:

| Purchased rank | Effective Critical Chance | Effective Critical Damage |
|---:|---:|---:|
| 0 | **5%** | **110%** (1.10×) |
| 1 | **6%** | **120%** (1.20×) |
| 5 | 10% | 160% (1.60×) |
| 10 | 15% | 210% (2.10×) |
| 15 | 20% | 260% (2.60×) |
| 20 | **25%** | **310%** (3.10×) |

These are **base + purchased upgrade only**, not global theoretical maxima. Other sources contribute through the existing formulas and retain all current cap behavior.

## 2. Implementation guidance

1. Inspect the live price/effect definitions for `critical_chance` and `critical_damage` (historically in `data/game/catalog.json`) and the authoritative player base stats (historically in `scripts/game/simulation.gd`). Confirm keys/ownership; change only the approved values.
2. Set prices to `25` / `15` Gems with `growth = 1.25`, using the game's **existing** purchase cost formula and rounding convention. Do not introduce manually authored prices or a separate critical pricing algorithm. For a formula `ceil(base × growth^(rank−1))`, example first purchases are Critical Chance **25, 32** and Critical Damage **15, 19**; derive actual values using the live formula, and ensure UI and purchase debit agree. Other upgrades, currencies, discount mechanics and cost growth remain unchanged.
3. Set player base Critical Damage to **1.10×**. Change each `critical_damage` rank to add **0.10** to the hit multiplier; no extra multiplication or doubling. Preserve the actual critical-hit damage pipeline and authoritative damage calculations.
4. Leave all player **Critical Chance** contribution getters, default 5% base, rank effect +0.01, stored/equipped gear contribution, Prestige modifiers and existing 75% cap **untouched**. Do not change critical chance of enemies unless it is accidentally coupled to player base stats; any necessary decoupling must preserve existing enemy behavior.
5. Preserve the Crit Damage cap and any existing saturation behavior. Do not expand or redistribute caps as a consequence of a user's earlier hypothetical max calculation.
6. All previously purchased levels survive save/load and Prestige unchanged; new effective values and future prices are computed from those saved levels after the update. Hard Reset keeps its current behavior. **No automatic refunds** and no save-schema bump unless the actual current data structure requires one. Do not alter item/Prestige rolls, effects or persistence.

## 3. Correct the UI for BOTH critical upgrades

Current upgrade rows misleadingly present **upgrade-only** values (e.g. Critical Chance `0% → 1%`, Critical Damage `0% → 5%`) as though they were the player's actual stats.

**Required presentation:**

- Display the player's **actual current effective stat → projected effective stat after the next purchase** for both upgrades. For a new unmodified player: **Critical Chance `5% → 6%`**, **Critical Damage `110% → 120%`**.
- Incorporate existing equipment (equipped and stored), Prestige, purchased upgrades and any other applicable current modifiers, without inventing new modifiers or mixing additive percentage points with multipliers. Use the **same authoritative stat aggregation as combat**; the preview must not calculate a competing approximation. If helpful, calculate a non-mutating preview at +1 owned upgrade level through that same stat pipeline.
- Respect existing caps in BOTH the current and projected values; do not show a gain that the simulation will suppress. When the next purchase offers no increase due to a cap, communicate that accurately using the game's existing conventions instead of faking an increase.
- Make it clear that a value such as **110% Critical Damage means 1.10× damage on a critical hit**, not +110% additional damage. Keep numbers and labels consistent across Player Upgrades, Stats, descriptions/tooltips and any Help demos that explain critical stats.
- At rank 20, show the correct effective current stat and MAX state, not a fictitious level 21 preview. Reflect subsequent equipment changes while panel remains open according to existing UI refresh patterns.
- Maintain accessibility, translation-ready labels, layout and touch behavior on **432×960** and **540×960**. Use existing components and localization infrastructure, not hardcoded UI English.

## 4. Localization and documentation

- Update the English `en.po` source if any user-facing strings genuinely change; record newly introduced/edited/retired English keys in the existing `tools/localization_pending.json` structure, tagged to Change 68. Do **not** modify the 19 non-English catalogs during this batch. If the implementation needs no new strings, report that explicitly.
- Update the **current game-specific GDD**, **Upgrade Catalog** and directly affected maintained tests/documentation to record the approved numbers and actual displayed behavior. Preserve historical entries as history, superseding obsolete current assertions where appropriate; **do not edit the shared Reusable Playbook**.

## 5. Short, focused acceptance checks

1. Fresh profile: Crit Chance **5%**, Crit Damage **110%** before purchases. Rank 1 grants **+1 pp** Crit Chance or **+10 pp** Crit Damage, and costs **25** or **15 Gems**, respectively. Verify the next price uses ×1.25 and the existing rounding rule; no other upgrades changed.
2. Rank 20: base + rank contribution is **25%** Crit Chance and **310%** Crit Damage before other sources; verify max levels and any unchanged actual caps.
3. Current/next UI reflects authoritative combat stats with no extra bonuses; then repeat with equipped gear, stored gear and at least one Prestige bonus. Purchase confirmation must match the preview; maxed/capped states must be truthful.
4. Forced/deterministic combat test: a critical hit applies **1.10×** at no critical-damage upgrades, and **1.20×** with one, before unrelated modifiers; critical chance retains existing base/cap/bonus rules.
5. Old-profile load and Prestige: owned critical upgrade levels intact and no refunds or lost purchases; same authoritative totals and prices after reload. Hard Reset unchanged.
6. Capture/check real UI at **432×960 and 540×960**, including long labels when possible. Run related upgrade/stats/localization probes and short scene checks only; **do not run long balance simulations or the entire regression suite** solely for Change 68. Report any pre-existing unrelated failures separately.

## 6. Git / completion

- Preserve unrelated working-tree modifications, developer version-number changes, assets and untracked content. Inspect diff and stage only Change 68 files.
- After focused verification, make **one local commit**:

  `balance(change-68): rebalance critical upgrades and show effective stats`

- Report exact changed numbers, first and last level costs computed from the live cost rule, display examples with/without bonuses, tests, captured evidence, localized English key status, changed files and commit hash.
- **Do not push, export, or publish.** Stop after this change for Android acceptance.
