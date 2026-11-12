# LootFarmer: Idle RPG — Consolidated Progression, Prestige & Combat Design Audit

**Request date:** 2026-11-07  
**Mode:** **AUDIT / INVESTIGATION ONLY**. Evaluate the approved design, run controlled simulations, recommend balanced values and implementation batches. **Do not implement gameplay, balance, catalog, UI, localization, save, test, GDD or Playbook changes; do not commit.** Deliver a report and supporting evidence for developer review and authorization.

## 1. Source of truth and baseline

Use the **current Claude working tree** as the source of truth, not an older ZIP or a past assistant description. First record the Git commit, branch, game version, catalog/save-schema versions, relevant uncommitted changes, and the state of the test harness. Read the current:

- `docs/Reusable_Game_Development_Playbook.md` (especially reset boundaries; §18.6–18.8 contextual guidance; §44 handoff; §59–60 valid probes; §61 save compatibility; §112/112.1/112.2 pacing, controlled comparisons and boss-readiness; §132 localization; §140 legitimate equipped builds and real fights).
- `docs/LootFarmer_GDD.md`, `docs/LootFarmer_Content_and_Balance.md`, and more recent approved decisions/change reports.
- `docs/LootFarmer_Player_Feedback_Balance_Audit_Report.md` and `docs/Player_Feedback_Audit_Evidence/README.md` plus the baseline build definitions/results.
- Actual `data/game/catalog.json`, `scripts/game/campaign.gd`, `scripts/game/simulation.gd`, inventory/evolution/bonus/reroll/UI and save code, and relevant probes.

**Baseline observations, not approved fixes:** The November 6 audit reproduced normal groups becoming more dangerous than bosses from **Summer I**, early boss gear invalidating later normal drops, target-switch income reductions, and missed Map Detail/offline-gear explanations. Earlier proposals such as a three-attacker cap, ×1.15 skill variant, ×0.60 Spring normals, a 50% map-floor upgrade, or Prestige-card nerfs **are not approved**. Re-evaluate them against the decisions below.

**Harness availability check:** In the ZIP supplied for this handoff, `docs/Player_Feedback_Audit_Evidence/README.md` documents a preserved `tests/player_feedback_audit.gd`/`.tscn` harness and `tools/player_feedback_audit_*.py`; the archive contains the evidence and some tools but **does not include a `tests/` directory**. Verify actual availability in the current working tree. Do not assume the harness exists or silently substitute old CSVs for reruns. If it is missing, identify what must be recovered before full reproducible testing. Any test tooling changes require a separate authorization, unless already available in the workspace.

## 2. Approved product decisions — treat as fixed design constraints

### A. Prestige reset boundary

| **Preserved through Prestige** | **Reset by Prestige** |
|---|---|
| Player **level and XP** | Completed stage/level clears and **stage access/progression**; restart the campaign |
| **Coins and Gems**, including their balances | **All current inventory items**: weapons, outfits, skills and consumables/supplies |
| **Every already-purchased upgrade**, whether bought with Coins or Gems | Inventory quantities, equipped loadout, and transient per-run item state |
| Per-**item-ID merge level** achieved for weapons, outfits and skills (independently for every evolution/item identity) | **Purchased camps** / their run-specific ownership |
| Prestige cards, permanent milestones/achievements, enemy discoveries, previously explored terrain | **Incomplete mission progress** and other clearly run-specific objectives |

- Reobtaining a previously merged item restores its saved **merge level**; simply retaining its merge progress **does not grant ownership, equipment bonuses or inventory copies**. It becomes usable only after obtaining that item again.
- An evolved weapon is a **different item ID**, not a persistent evolution-unlock flag. Its merge level is tracked like any other item ID. No separate persistent `evolved_tiers` requirement is wanted.
- Preserve *all* purchased Coin and Gem upgrades; **do not** convert Coin upgrades to Gems to achieve permanence. Coin and Gem prices/currencies may remain distinct for gameplay/economy reasons.
- Camps are an explicit exception: **camp purchase/ownership resets**, even though purchasable upgrades persist. Audit any representation of camps as upgrade records to avoid violating this distinction.
- Enemy/map discoveries and explored terrain stay recorded, even if campaign access is locked again. Explain what can be seen versus visited after Prestige.
- Hard Reset is **not** Prestige and should still wipe everything it is supposed to wipe. Avoid changing that meaning inadvertently.
- The Prestige confirmation must explain retained and lost state without misleading players. Identify ambiguity in existing UI and docs (e.g., existing descriptions saying player level resets).
- Identify any additional current fields not listed above (e.g., supply mastery, skill cooldown timers, unclaimed mission rewards, pending drops, current boss state, map detail, offline snapshots) and **recommend their correct layer**; do not invent an approved behavior for unspecified edge cases. Include a complete, explicit reset/keep matrix from actual save fields.

### B. Weapon tier distribution

One normal **weapon tier per stage** (both Sword and Axe families); the stage's bosses drop the **same tier**, not the next one.

| Stage | Normal weapon tier | Boss weapon tier |
|---|---|---|
| 1 — Winter I | T1 **Wood** | T1 Wood, enhanced |
| 2 — Winter II | T2 **Stone** | T2 Stone, enhanced |
| 3 — Summer I | T3 **Iron** | T3 Iron, enhanced |
| 4 — Summer II | T4 **Gold** | T4 Gold, enhanced |
| 5 — Autumn I | T5 **Diamond** | T5 Diamond, enhanced |
| 6 — Autumn II | T6 **Emerald** | T6 Emerald, enhanced |
| 7 — Spring I | T7 **Obsidian** | T7 Obsidian, enhanced |
| 8 — Spring II | T7 **Obsidian** | T7 Obsidian, enhanced |

Spring I/II intentionally provide time to **merge and optimize Obsidian** instead of introducing an eighth tier. Existing boss equipment/guaranteed first Snowman Stone Axe and stage drop tables must be audited for redesign and save compatibility; do not preserve old higher-tier boss guarantees by accident. New normal-stage tiers should make current-stage farming worthwhile. Existing gear from previous versions must not disappear or silently corrupt a save.

### C. Boss-enhanced weapons and rerolls

- A normal weapon has its normal existing random bonus attribute behavior; a **boss version of that stage's same-tier weapon always has two additional random attributes** (i.e., normally one base bonus + two boss bonuses, subject to confirming the live model).
- Those attributes come from the **existing rerollable weapon stat pool** (e.g., crit chance, crit damage, attack speed, lifesteal), not new arbitrary stat types. Each bonus is **independently rerollable**.
- Normal duplicates must be usable for the **same weapon's merge progression** even after obtaining a boss-enhanced variant. Normal loot must stay useful.
- Merging should continue enhancing **core item stats**, not automatically increasing rolled bonus percentages, unless the live code contradicts the prior audit; verify current behavior and state what migration or schema changes are necessary.
- Audit **how enhancements are stored and selected**: current item-ID-based bonuses versus multiple copies/variants, how a boss-enhanced drop upgrades an already owned normal weapon, whether bonuses persist or reset with inventory, which item is equipped, how a reroll targets an individual attribute, how merging avoids overwriting enhancements, and avoiding duplication/exploit paths.
- Propose the **simplest safe representation** and handling for multiple boss drops of the same item. This is a technical design question for the audit; do not silently add a new rarity/quality ladder.

### D. Weapon evolution (economic target, not final tuned value)

- Current configuration (verify in live catalog): evolution at **^100** plus **100 spare copies**, ~**201 acquired copies** including the initial item; `base_multiplier = 0.85` needs re-evaluation.
- Preferred starting candidate: evolve at **^20** plus **10 additional copies**, ~**31 total acquired copies**, but **Claude must evaluate**, not assume this is balanced.
- Evolution **produces one copy of the next-tier item ID**. If that target item has never been merged, it starts at **^0**; if its ID already has a persisted merge level (including after Prestige), it **keeps that level** and the evolved copy adds to that item's normal inventory quantity. The target's merge progress is **never overwritten/reset** by evolution.
- Independently evaluate the source item's cost/consumption and preservation of its per-ID merge record, repeat evolution, source/target quantity accounting, cross-Prestige behavior, maximum tier, auto-evolution, boss-enhanced variants, and any loop or duplication exploit. Do **not** interpret evolving as automatically inheriting the source's merge level.
- Evolution is an **optional farming path** to a later tier; dropping a higher tier when entering a new stage remains valid. Preserve relevance of both choices.

### E. Combat structure — revised decision supersedes prior cap proposal

- **Stages 1, 2 and 3 (Winter I, Winter II, Summer I): normal enemies should not initiate coordinated group aggression.** Preserve individual/early-stage behavior; distinguish having multiple enemies spawned from enemies assisting/aggroing together.
- **Starting Stage 4 (Summer II), normal enemies may coordinate and attack in groups**; Stages 4–8 use group aggression.
- **Do not limit the number of simultaneous attackers.** The prior `cap3` option is explicitly **rejected**. Keep large spots a meaningful risk; tune enemy damage, telegraphs, aggro behavior, spawn scaling, recovery opportunities and boss challenge **without** an attacker cap.
- Evaluate skill-variant ×1.35, boss burst/telegraph, healing/potions, Spawn Amount doubling spots, Spring I/II, boss summons, and all eight stages using this new Stage 4 boundary. A satisfactory design makes normal farming possible at appropriate build strength while bosses remain milestone encounters, especially on first arrival.

### F. More Prestige opportunities and reward-card variety

- Expand meaningful **stage-specific Prestige opportunities** across **all eight stages**. A suitable recurring objective type (e.g., defeat several normal enemies) should recur in later stages with **that stage's** enemy types, rather than existing only in a few stages.
- Expand the existing Prestige **card pool**, not just the number of objectives that award no available cards. Prefer **new effects and strategic options** over blindly stacking more +damage/−damage bonuses. Do not introduce a new currency solely for the expansion.
- First produce a **verified by-stage inventory** of every existing opportunity and path/card, its requirements, reward, run/lifetime status, and the **stage where the requirement is actually performed** (correct any mislabeled grouping, without editing yet).
- Show a recurrence matrix by stage for each objective family: Hunter, Expedition, Collection, Regional, Challenge, Trophy and General paths (or their current canonical names). Propose new requirements using real stage content.
- Analyze card saturation, selection logic, stage-specific grouping, rewards retained over Prestiges, balance between boss-focused and normal-farming cards, combos, opportunities that could repeat, save compatibility for current owned cards, and reasonable progression to the enlarged pool.
- **No fixed new card count, effects or opportunity count has been approved.** Propose numbers, tradeoffs and a concrete recommendation with evidence.

### G. Contextual discoverability

- When a player opens a map with discovered enemies but does not understand **Map Detail**, explain that Map upgrades reveal markers and route them to the relevant upgrade. Reflect permanent Map Detail purchases after the redesign.
- After offline rewards, if gear farming is not unlocked, explain the separate offline upgrade(s) that grant **copies only of already-owned gear** and route the player to the purchase (when relevant and affordable).
- No new mandatory tutorial steps. Respect safe moments, panel bounds, guided/basic/none behavior, one-hint arbitration and previously released 20-language catalogs. Provide English text/key proposals and translation/migration implications; do not change catalogs now.
- Update proposed Prestige confirmation wording to match the approved reset rules.

## 3. Required evaluations and experiments

### 3.1 Weapon and loot economy

Build an **eight-stage, two-family weapon table** with: current versus proposed tier, real base stats and `merge_gain`, rolled stats/reroll price, stage enemy/boss source, realistic drop rates, and time/copies to reach meaningful merge levels/evolution. Evaluate at least these evolution candidates:

| Candidate | Merge requirement | Spares to evolve | Approx. total copies |
|---|---:|---:|---:|
| Current | ^100 | 100 | 201 |
| **Preferred starting point** | **^20** | **10** | **31** |
| Easier comparator | ^10 | 10 | 21 |
| Slower comparator | ^30 | 10 | 41 |

Measure realistic acquisition time from actual eligible enemies and kill rates, including drop upgrades, inventory/auto-merge capacity, prestige carryover, boss drops and poor/good luck. Confirm exact copy mathematics. Evaluate whether the existing ~×2.55 tier scaling and 0.85 evolution carryover still work when tiers advance every stage; propose replacement **numerical stats and merge formulas**, with comparisons at ^0, ^20, ^50, ^100 where meaningful. Assess Sword-vs-Axe tradeoffs and final Obsidian merging time. Show normal vs boss-enhanced rolls and expected benefits without invalidating ordinary loot.

### 3.2 Fresh progression, repeated Prestige and reset integrity

Test at least **first run**, **after one Prestige**, and **after multiple Prestiges**, using both legal constructed fixtures and a limited number of **natural/replayable player policies** where practical. Specifically check:

- Reacquisition of retained ^merge items with **empty inventory**; no stock or passive item bonuses while unowned.
- Permanent Coin and Gem upgrades at high levels, while purchased camps and incomplete missions reset.
- Currency persistence and its interaction with purchase prices/economy after repeated cycles: do Coins become useless or allow near-instant skip of progression?
- Persisted player level/XP combined with preserved upgrades and cards; do early bosses become trivially skippable, and does that match intended shorter replay rather than destroying first-time discovery progression?
- World map fog/discovery retained but stage gates relocked; marker visibility, map detail, travel/camp access and saved objective state after re-entry.
- Equipment evolution/source/target merge records across Prestige; save/reload during the reset (atomic operation), outdated save schema, Hard Reset and rollback/duplication protection.

Return a **field-by-field before/after Prestige matrix** derived from the code, including deviations from the approved rules and a migration plan that does not wipe paid players' progress.

### 3.3 Combat and eight-stage balance

Run existing representative stage builds before/after **group aggression only from Stage 4**. Keep boss interactions and higher-stage groups distinct; include 3- and 6-actor spots **without attacker limits**. Compare real time-to-kill, deaths/10 minutes, surviving HP, boss fight times, skill/potion sensitivity, early/late Prestige count, and whether the boss can be rushed without meaningful current-stage farming. Use legitimate owned/equipped items and apply boss abilities through the real simulation (§112.2, §140). Measure separate and combined effects of candidate tuning changes; do not pre-approve any factor. Revisit the earlier Summer I and Spring failure cases, which were measured under **the old group-aggression boundary and old tier loot**.

### 3.4 Coins, XP, drops, progression and player retention

Reassess the previous **78–86% coin-income loss when switching enemy types**, now that Coin upgrades survive Prestige. Compare: same-map switching, changing stages, specialized versus mixed farming, and first versus repeat run. Evaluate floor/shared/cheap-first-level remedies as candidates, but **do not pre-approve** the old 50% floor. Look at mid-game XP pacing, mission rewards, offline income, gem demand, coins after many Prestiges, equipment relevance, and expected time between bosses and next meaningful upgrades. Do not treat per-fight DPS estimates as a proxy for retention; label projected pacing separately from observed simulation outcomes.

### 3.5 Prestige opportunities and cards

Supply a **per-stage count table** (existing + proposed), a **path/objective recurrence matrix**, a card-effects table, and at least 2 alternative expansion designs. Validate objective availability on first/repeat run, normal-farming vs boss-farming incentives, reward eligibility and card capacity, choice fairness, unlock pacing and impact on saves. Establish whether increased offers amplify the prior boss-preference problem or create meaningful alternative progression.

## 4. Nonnegotiable validation rules

1. Verify the **current** branch/tree and catalog; note docs vs runtime disagreements explicitly. Preserve baseline versions and untouched-player save backups.
2. Use the preserved test harness if present; confirm the previous baseline reproduction before experimenting. **If the executable harness is missing, report that blocker** and give a recovery plan rather than pretending to have rerun it.
3. Compare controlled scenarios with the **same seeds and genuinely reachable builds**; classify seeded convenience fixtures versus natural progress and measured results versus extrapolations.
4. Check full progression across **all eight stages** and the **first three bosses** in depth; also preserve final-boss regression coverage (Change 36).
5. Include negative/save-edge tests: missing items, old bonuses, existing owned Prestige cards, stage-cleared saves, interrupted reset, late-stage save downgrades and Hard Reset.
6. Respect development performance and test integrity requirements: targeted probes, timeouts, isolated profiles, sequential runs and no hidden catalog modifications.
7. Identify 432×960 and 540×960 UI impact (especially attribute reroll controls, expanded cards, scrolling and Prestige confirmation), and English-key/19-translation impact, **without implementing**.
8. No attacker-cap recommendation: it conflicts with the current approved design. If any approved decision appears technically unworkable, explain the conflict and recommend an alternative for developer approval; do not silently override it.

## 5. Required deliverable: one consolidated Markdown report

Provide a report that a developer can approve without another discovery cycle. Include:

1. **Source/version and decision compliance:** current branch/save/catalog, approved rules, discrepancies.
2. **Prestige keep/reset matrix:** every relevant persistent field; old→new impact; exact migration/atomic-reset design.
3. **Weapon tier & evolution analysis:** eight-stage table, core/bonus stat effects, ~21/31/41-copy scenarios, recommended formulas and copy/merge accounting.
4. **Boss-enhanced item model:** alternatives, reroll behavior, merge compatibility, save model and exploit risks.
5. **Eight-stage combat comparison:** before/proposed, boss vs normal groups, first vs repeated Prestige, real sim results, chosen numerical proposal with justification.
6. **Economy/pacing:** coin/XP/drop/offline policies, switching cost and repeat-run currency sinks, measured vs projected.
7. **Prestige expansion:** existing opportunity/card counts and location, stage/path recurrence matrix, proposed counts, effect proposals and alternatives.
8. **UX/discoverability:** exact English text proposals, state-driven triggers, UI placement, localization estimate.
9. **Risks and save migration:** current player saves, previously obtained higher-tier boss gear, current item bonuses, merged IDs, existing cards, interdependencies.
10. **Validation record:** test commands, seeds, build definitions, before/after CSVs or concise tables, passed/failed/blocked probes and confidence limits.
11. **Recommended implementation batches:** dependency order, exact scope and measurable acceptance tests for each, reasonable rollback strategy. **Do not implement these batches.**
12. **Developer approval checklist:** list only genuinely open numerical/technical choices; do not reopen already approved product rules without evidence.

### Audit/implementation boundary

**Stop after submitting your report and evidence. No production edits, no catalogs or localized text changes, no test-rewrite-to-pass, no commits, and no gameplay rollout.** Implementation will be authorized in a separate instruction after we review the report.
