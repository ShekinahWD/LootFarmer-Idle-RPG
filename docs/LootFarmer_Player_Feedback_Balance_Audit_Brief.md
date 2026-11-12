# LootFarmer: Idle RPG — Player-Feedback Balance & Discoverability Audit

**Mode:** Investigation and recommendations only. **Do not implement balance, gameplay, economy, UI, tutorial, content, save, or documentation changes in the game repository.**

## Objective

Investigate the progression and usability issues reported by a real player after approximately 1–2 days of play (reaching the third boss). Establish which problems are reproducible in the current project, how severe they are, and what numerical or UX adjustments should be considered. Deliver evidence-backed recommendations for developer approval **before** any implementation.

The player's rating was **4/10 now**, with an estimated **6–7/10** if balancing improved. Treat this as one detailed playtest, not statistical evidence.

## Primary player feedback (preserve intent)

1. **Normal enemy groups versus bosses:** The second and third bosses felt trivial using the Snowman boss's outfit/axe plus a few Prestige cycles, yet normal NPC groups in those areas could defeat the same character within a few hits. The game appears to reward skipping normal farming and rushing bosses.
2. **Gear relevance:** Early Snowman gear can be more useful than many merged weapons/outfits found later, making repeated drops, farming and merging feel unrewarding.
3. **Coin economy:** After investing coins into one enemy type, changing to another farming target makes progression feel too slow. The player proposed stage-wide normal-enemy upgrades with special/boss upgrades separated. **Evaluate the proposal rather than presuming it is correct.**
4. **Discoverability — map:** The player did not know the existing map upgrades reveal discovered enemy/boss markers and eventually drop information.
5. **Discoverability — offline gear:** The player did not know a purchasable offline upgrade enables rewards for already-owned equipment. This was missed even after selecting full guided training.
6. **Inventory capacity:** The player mentioned a preference for tighter limits but identified it as subjective. **Treat as low-priority; do not propose a cap change without stronger evidence.**

## Source of truth and constraints

- Start from the **current working tree**, not an older remembered balance table or a historical ZIP. Report the exact commit, game version, working-tree state and catalog/schema used; flag any uncommitted modifications that could affect conclusions.
- Read `docs/Reusable_Game_Development_Playbook.md` and current `docs/LootFarmer_GDD.md`, `docs/LootFarmer_Content_and_Balance.md`, relevant newer change reports, and actual runtime source/data. Where historical documentation conflicts with live code, treat the runtime as behavioral authority and disclose the conflict.
- Especially apply Playbook **§112 (pacing bots)**, **§112.1 (controlled comparisons)**, **§112.2 (boss-readiness ladders and legitimacy)**, **§140.1–140.2 (real equipped builds and real fights)**, **§59–60 (valid fixtures and test integrity)**, **§18.6–18.8 (contextual teaching)** and **§44 (audit/report workflow)**.
- Previous documentation described stages 1–5 as accepted after internal testing. **This new external playtest is a reason to re-evaluate, not authorization to silently retune them.**
- Existing test/tool entry points worth inspecting: `tests/pacing_bot.gd`, `tests/change_36_final_boss_audit.gd`, `tests/change_9_balance.gd`, `tests/balance_probe.gd`, `scripts/game/simulation.gd`, and `data/game/catalog.json`. These are navigation hints, **not assumptions that every harness remains valid**.
- Do not change production balance to make probes pass, and do not rely on obsolete seeded fixtures. Run targeted tests sequentially; use timeouts, isolated profiles/saves and explicit random seeds. Record any environment or tool limitation.

## A. Combat difficulty audit — all eight maps

Examine **Winter I, Winter II, Summer I, Summer II, Autumn I, Autumn II, Spring I and Spring II**, prioritizing **Winter I through Summer I** where the reported retention drop occurred.

For each stage, compare:

- Typical **single normal enemies**, full normal **spawn groups**, relevant **special variants**, and every boss (including multi-boss stages).
- Enemy HP, effective damage, attack cadence, pursuit/assist behavior, overlapping attacks, telegraphs, control effects, healing, summons and respawn timing.
- Actual fight outcomes: time-to-kill, time-to-die, player remaining HP, consumable/skill usage, death frequency, whether grouping produces unexpected difficulty spikes, and whether boss fights are easier than ordinary group encounters for the same build.
- The game’s real fight logic and auto/manual distinctions. **Do not equate theoretical DPS or HP ratios with playable difficulty.**

Use multiple legitimate player states: first arrival with prior-stage gear, partially upgraded current-stage gear, current-stage boss-ready gear, and the player-reported Snowman outfit/axe carried forward. Include **zero, low and several Prestige cycles** as *actual reachable states*, clearly labeling constructed fixtures versus replayed progression. Consider plausible casual, ordinary and optimized player policies.

For each boss, give a **minimum credible winning build**, a **recommended resilient build**, and one-variable weaker neighboring builds. Identify cliff thresholds and skipped-content shortcuts. Include samples/seeds and confidence/limitations rather than invented universal win probabilities.

## B. Gear/drop/merge progression

Build a stage-by-stage table using **runtime-effective stats**, not merely base item descriptions:

- Normal gear versus prior boss gear and current boss gear; weapons and outfits analyzed separately.
- Correct merge and weapon evolution curves, rarity/tier, realistic copy counts, drop chance, expected acquisition effort, possible stat rolls, equipped bonuses, passive collection bonuses and Prestige effects.
- Compare **Snowman outfit and Stone Axe** specifically against Winter II and Summer I farming alternatives and their boss rewards.
- Flag stretches where a typical obtainable item is effectively never an upgrade, or the player can skip entire reward tiers without meaningful cost.
- Distinguish an intentional rare, strong boss drop from an unintentional multi-stage best-in-slot item.

Report whether the player's concern is demonstrably true under common builds; specify the builds and conditions under which it is **not** true.

## C. Coin economy and farming-target switching

Inspect the **real** coin source, per-stage multipliers, enemy-specific upgrade costs, reward boosts, level scaling, kills per upgrade, and current switching incentives.

Simulate/compare at least these policies at identical progression points:

1. Stay with one invested enemy type.
2. Switch to a newly unlocked enemy type.
3. Alternate among multiple available enemy types.
4. Progress through a stage normally, including boss preparation.

Report **coins/minute**, **kills per next meaningful upgrade**, **break-even time after switching**, **time to become viable at the next encounter**, and whether later-stage purchases create a practical reset-like stall. Account for permanent/meta multipliers, missions and offline income where they matter; distinguish measured values from projected estimates.

Evaluate several **candidate remedies without applying any**. Possibilities include better first-upgrade affordability, partial stage-wide carryover, shared normal-enemy upgrades, adjusted rewards/prices, or a different progression incentive. Compare each option's likely benefits **and damage to existing strategic choices**.

## D. Prestige's influence on boss skipping

Audit whether early Prestige + persistent upgrades disproportionally boosts survivability/damage against bosses compared with normal groups. Report example builds at multiple Prestige counts, actual time invested or estimated cost (clearly labeled), and whether the dominant strategy becomes repeated rebirths plus Snowman equipment instead of gathering drops in newly unlocked maps. Account for which effects reset and persist using current game behavior.

## E. Feature discoverability (diagnose only)

Trace **actual** Guided/Basic/None onboarding, the map interface and map-upgrade entry point, and the offline reward screen/offline upgrade entry point.

Determine why a full-training player could reach three bosses without noticing:

- Buyable map markers and the prerequisites for markers to appear.
- Offline farming of **already owned gear** and its unlock condition.

Propose compact, non-blocking, contextual explanations shown at the moment they matter (e.g., map opened before marker upgrades; offline reward received without gear-unlock upgrade). Give **specific proposed wording and placement**, state-based show/hide/retirement behavior and a route to the relevant purchase if feasible. Avoid promising equipment from undiscovered gear. Do not add mandatory tutorial steps or tutorial-only economy changes. Check UI discoverability against the existing panel and localization rules.

## F. Regression/risk review

- Assess whether fixing early-stage balance would harm late-game bosses, farming, resource economy, saving, prestige, or an already reasonable difficulty curve.
- Check how any proposed rebalancing changes the **meaning** of previously collected/equipped items on existing saves; identify migration risks only if they exist.
- Do not redesign unrelated systems, including inventory capacity, without direct supporting evidence.
- Separate verified faults, plausible tuning preferences, and UX discoverability gaps.

## Deliverable — one self-contained Markdown audit report

Return the report in Markdown (as a **separate downloadable `.md` file**, or as a complete Markdown response if file output is unavailable) with these sections:

1. **Executive verdict:** Is the player’s progression complaint reproduced? What is the main causal chain?
2. **Reproduction / evidence matrix:** claim, scenario/build, actual measured result, severity, confidence, source file/line or test evidence.
3. **Eight-stage difficulty matrix:** enemy groups vs bosses with measured outcomes; highlight first three bosses.
4. **Equipment effectiveness table:** representative *reachable* gear/merge/Prestige states; Snowman gear carryover.
5. **Economy switching comparison:** strategies, costs, measured results and projected estimates marked separately.
6. **Prestige sensitivity:** how repeated rebirths affect the progression skip.
7. **Discoverability findings:** map markers and offline gear, concrete proposed messaging and placement.
8. **Ranked remediation options:** exact proposed values/formulas **where justified**, expected effects, alternatives and tradeoffs, and what must be re-simulated after implementation.
9. **Validation record:** code/version, harnesses run, profiles/seeds, count of trials, assertions, runtime, failures and untested items. Preserve reproducibility of build definitions and per-trial output where practical.
10. **Developer decisions required:** a compact approval checklist for the next change batch.

Use compact evidence tables, not lengthy prose without measurements. Where a scenario is too expensive or impossible to simulate, provide a smaller controlled experiment and explicitly label the unmeasured claim. **Never present seeded-fixture outcomes as a natural full playthrough**.

## Hard stop / approval gate

**Do not** alter `catalog.json`, scripts, scenes, items, upgrades, prices, drops, tutorial, UI, localization, GDD, Playbook, tests, export settings, or production saves; do not commit or publish. Any temporary instrumentation must be isolated and left out of the project working tree. Submit the audit and proposed changes **only**. We will choose the balance/UX adjustments in a separate, explicitly authorized implementation batch.
