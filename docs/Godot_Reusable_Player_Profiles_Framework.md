# Godot — Reusable Player Profiles and Automated Playtesting Framework

**Task type:** Evaluate the existing implementation, decide the architecture, **implement it in this same batch**, validate, and report. Do not stop at an architecture proposal or ask for a second approval.

**Scope:** Godot projects only. LootFarmer is the first integration and regression case, **not** the design target. Player-profile definitions and the framework must be reusable in future Godot games with different mechanics, genres, and progression models.

**Out of scope:** Changing game balance or progression, adjusting the seven profiles to manufacture wins, changing store versions, publishing/exporting builds, or expanding other games without explicit access/authorization.

## 1. Audit before choosing the architecture

Read the **current** repository and Playbook, especially the player-testing, reusable-system, Godot architecture, validation, folder, and Git instructions. Read the existing LootFarmer player-profile docs and Phase 2 report. Inspect the current files rather than assuming that paths, APIs or behavior from previous reports are still up to date:

- `tests/playtest/` (driver, recorder, policies, adapter, run scene, scheduler if present).
- `tools/player_profile_run.py` and existing commands/report formats.
- `docs/LootFarmer_Player_Profile_Playtesting.md` and `docs/LootFarmer_Player_Profile_Playtesting_Phase_2_Report.md` (if present).
- Current playtesting probes and `docs/LootFarmer_Test_Suite.md`.
- The game's authoritative simulation, actual actions, saves, offline settlement, and virtual-clock seam.

Start by classifying the current code into **game-independent framework**, **universal behavior**, **LootFarmer interpretation/strategy**, and **LootFarmer runtime adapter**. Phase 2's Casual and Idle policies reportedly inherit LootFarmer Active behavior; explicitly eliminate that cross-layer dependency. Keep existing measured runs and policy versions available as a labeled historical baseline, rather than silently rewriting comparison history.

The installed Playbook describes a shared Windows master, but its symlink migration may not yet have been performed in this workspace. **Verify actual paths and Git status**; do not overwrite a shared master, invent a working symlink, move unrelated files, or assume the current working tree is clean. In particular, preserve the developer's pre-existing uncommitted `project.godot` and `export_presets.cfg` changes, reportedly for version 42.

## 2. Architecture to deliver — three explicit layers

Design the final boundaries yourself after the audit, but implement all three responsibilities below:

**A. Universal reusable definitions and decision framework**

- Seven named profile presets, stable identifiers, documented defaults, behavioral traits, session styles, and policy rules. These do **not** mention LootFarmer enemies, bosses, Prestige, weapons, gems, Godot node paths, or other game-specific mechanics.
- Generic scheduling, decision cadence, deterministic seeded decisions, time budgets, offline/calendar tracking where supported, persistence across sessions, observations, action selection, auditing, events, reporting, and stop classifications.
- Prefer data-driven profile configurations and composable policies over seven duplicated hardcoded scripts. Support per-run overrides (not per-game rewrites) and a framework/schema version.

**B. Standardized game-capability/intent contract**

- A game declares what is available, including **unsupported** mechanics. Consider an extensible, explicit set of generic intents, such as: pursue main objective; discover/explore; strengthen or prepare; improve economy; invest in passive/automation systems; recover/survive; attempt challenging objective; collect or complete optional content; save for a goal; wait/continue existing plan; exit/return to session.
- The contract must carry enough **player-observable** information for an intent to be chosen: eligibility, affordance, approximate cost/benefit or priority signals where a normal player could judge them, risk, required resources, expected commitment, and actionable failure reasons. Not every game needs every intent. Avoid making the framework assume combat, maps, currencies, offline production, Prestige, collections, or a specific win condition.
- Define deterministic tie-breaking and action outcomes. Prevent thrashing: preserve short-term commitments, cooldowns, and reevaluation limits. Record when an intent was unsupported, unaffordable, blocked, or failed.
- Keep **decision selection** separate from **execution and outcome**. The game simulation remains authoritative; no direct granting of resources, levels, inventory, wins, or hidden boosts.
- **Do not give profiles omniscient hidden game state.** If the adapter has privileged telemetry for reporting, keep it separate from policy observations. Explicitly label any unavoidable policy oracle limitations.

**C. Game-specific strategy/adapter**

- Claude, when integrating a *new* game, inspects its GDD, progression, real actions, save system, clock/offline rules, and exposes a game-specific adapter mapping available mechanics to the generic intents and observation contract.
- Game-specific tactics may exist (e.g., how to travel, choose equipment, build a tower or attack a boss), but they live **only in that game's integration**, never inside generic profile presets.
- Game-specific victory/progression milestones and metrics are allowed, while the core report schema and generic metrics remain stable. Unsupported features are `not_applicable`/`unsupported`, **not fabricated zeros**.
- A new game must be usable by mapping capabilities and implementing its adapter, **without rewriting or subclassing a LootFarmer Active policy** and without modifying the seven universal profile definitions.

## 3. Universal behavior presets — implement all seven

Presets represent plausible **behavioral tendencies**, not perfect players or seven fixed hardcoded scripts. Define their values in consistent normalized parameters (document scale, meaning, and defaults). Include at least: attention/decision frequency, session frequency/duration, exploration preference, primary-goal urgency, risk tolerance, spending vs savings, preparation threshold, efficiency/optimization, side-goal preference, collection/completion drive, automation preference when available, tolerance of setbacks, and tendency to revisit decisions. Profiles should remain distinguishable when the game offers meaningful choices; if capabilities make two profiles behaviorally equivalent, report that honestly rather than inventing actions.

| Profile ID | Universal player behavior | Distinctive constraint |
|---|---|---|
| **active** | Frequent/longer play, frequent decisions, explores and pursues progression, learns and adapts, uses available tools. | Engaged does not equal optimal or omniscient; avoid permanent hoarding or aimless combat. |
| **casual** | Short/intermittent play, moderate decisions, follows understandable goals, occasionally explores, spends when benefit is clear. | Less optimized than Active; interruptions and missed opportunities are plausible, not artificial penalties. |
| **idle** | Very brief/infrequent interaction, prioritizes passive systems and automation **if offered**, makes few manual decisions. | If a game lacks offline/automation, model low attention instead; never invent passive rewards. |
| **beginner** | New to systems, tentative exploration, slower/less consistent decisions, some understandable mistakes, conservative use of unfamiliar features. | Bounded and explainable imperfection, not RNG sabotage or perpetual incompetence; can learn from outcomes over time. |
| **collector** | Seeks items, discoveries, variety, sets, rare or unowned content; willing to delay main progression for collection. | Collection-first **not** necessarily 100% completion of every mission or upgrade. |
| **speedrunner** | Prioritizes reaching explicit milestones quickly, skips optional tasks, accepts calculated risk, spends only to remove progression bottlenecks. | Fast is not omniscient, instant-action, or a cheat; failures and resets cost real simulated time. |
| **completionist** | Tries to finish accessible goals, upgrades, achievements and optional objectives before advancing; methodical and persistent. | Broader than Collector; respect in-game accessibility and avoid unreachable-target infinite loops. |

Treat player **habits** and **goals** as separable axes: e.g., a collector can have short sessions, and a beginner need not be idle. The seven defaults are convenient presets; allow config overrides without changing their definitions. Declare reasonable, editable defaults for session patterns; do not claim those are measured human population statistics. For games with very short rounds, session cadence may need scale-appropriate overrides without changing profile identity.

Distinguish these two independent concepts in all code/reports:
1. **Behavioral profile** (what choices the person tends to make).
2. **Game-specific strategy and capability mapping** (how those tendencies translate into the current game's mechanics).

## 4. Reusable installation and future Claude workflow

Deliver a **self-contained, versioned, Godot-compatible reusable package** (GDScript/core resources plus configuration/schema as appropriate), with minimal external dependencies and clear entry points. Use the Playbook's actual verified shared-kit arrangement; do not assume script symlinks are mandated simply because the Playbook document uses a symlink. Prefer a tracked, portable source package that can be installed into another Godot project's `res://` tree without resolving LootFarmer resource paths. Avoid duplicating writable “master” versions.

If `D:\Godot\ReusableKitForNewGames` is available and writable **and** its ownership/structure is verified, place or update the canonical reusable package there with safe versioning; integrate LootFarmer by a clear pinned install/copy/link mechanism. Otherwise implement the portable package in this repository, make it easy to promote to the reusable kit, and **explicitly report** what couldn't be installed externally. Do not pretend an inaccessible location was updated. Preserve any existing toolkit contents.

Create a concise, reusable **“Integrate Player Profiles into a New Godot Game”** guide that Claude can follow mechanically:
1. Inspect the game and identify actual, player-accessible mechanics, objectives, persistence and clock/offline behavior.
2. Enumerate capabilities and decide how the generic intents map to legitimate game actions; note unsupported intents.
3. Implement the game's adapter and optional tactics without editing the generic profile presets.
4. Wire isolated saves, deterministic seeds, session schedules, metrics, and runner configuration.
5. Execute an adapter-contract probe, per-profile behavior probe, deterministic replay, and short actual simulated run.
6. Confirm that actions obey the game's rules; document unsupported mechanics and interpretation limitations.
7. Only then run multi-seed profile comparisons; classify a stall as game balance vs policy/adapter problem before suggesting game changes.

Give Claude an exact starting file/path in that guide and example commands for applying it to a new game. The framework should support reuse **without requiring a new framework-design conversation each time**. The *adaptation* still requires code and review, since game mechanics differ.

Any Playbook update should be a small, validated, genuinely cross-game lesson in the **actual verified authoritative Playbook**, not an overwritten/duplicated copy. If the shared master isn't configured, report the proposed documentation change instead of changing the wrong file. Never modify unrelated GDDs or other projects merely to showcase reuse.

## 5. Migrate and use LootFarmer as the first real integration

- Refactor the Phase 1/2 foundation to use the common reusable interfaces while retaining the authoritative `LootSimulation`, legal player actions, isolated saves, seeded randomness, real offline settlement and per-session clock progression.
- Retain `active`, `casual`, and `idle` as runnable profile names through the existing user-facing runner; add `beginner`, `collector`, `speedrunner`, and `completionist`. Run **all seven** against LootFarmer, not only instantiate configuration files.
- Preserve or clearly version the original Phase 1/2 Active policy and evidence as a **historical comparison baseline**, especially the known exploration interruption and underspending defects. You may implement improved **LootFarmer-specific** exploration/spending tactics to prevent artificial stalls, but do not make all profiles identical or hide these changes in the universal definitions. Report behavior and metrics that are no longer comparable due to the new adapter/policy version.
- Retain important differences: Casual has fewer decisions and more interrupted play; Idle prefers legitimate automation/offline rewards; Collector and Completionist have distinct objectives; Speedrunner prioritizes stage milestones; Beginner makes bounded mistakes but can learn.
- Keep the existing run CLI and JSON/CSV/Markdown reporting usable where feasible; provide migration notes for changed arguments/schema rather than silently breaking scripts. Preserve backwards-readable run identities, seed, profile version/hash, game adapter version, game build/dirty-state fingerprint, calendar/active/offline time, and stop reasons.
- Do **not** change gameplay, items, boss tuning, upgrade costs, Prestige rules, save schema, the store release, or the player's actual save data as part of this framework migration.

## 6. Prove the package is not disguised LootFarmer code

Test both:

**A. Actual LootFarmer:** smoke-test all seven profiles through real simulation, legitimate progression and bounded sessions, including leave/return and offline settlement where applicable. Demonstrate different decisions between profiles using the same game state/seed where meaningful.

**B. An intentionally different tiny Godot test fixture:** build a compact isolated adapter/test game model with different capabilities (for instance, production/building/progression **without** combat, loot or Prestige; optionally without offline rewards). Use **the same unchanged reusable package and profile definitions**. Exercise all seven profiles, capability fallbacks, deterministic selection and reporting. A fixture proves interface flexibility, not real portability to another shipped game; state that limitation plainly. If another real game repository is conveniently accessible, you may inspect it read-only for portability feedback, but **do not modify it**.

This cross-game fixture is a required acceptance test, not an optional aspiration. Verify that removing LootFarmer's adapter leaves the generic package parsable and its tests runnable.

## 7. Accuracy, determinism, and reports

- Use independent seeded randomness for schedules and decisions. Profile replay from the same seed, game data, config and framework version should produce identical decisions/outcomes and stable event/state digests (ignore volatile wall clock/process fields).
- Prefer real authoritative simulation headlessly; do not invent passive production, unearned rewards, hidden buffs, auto-complete, or impossible actions. Game-specific time semantics and offline caps are enforced by the adapter/game.
- Safeguard real player saves; use isolated test profiles and remove/ignore generated reports according to the Playbook. No mutating production settings merely to run tests.
- Keep active time, offline time, and elapsed calendar time separate. Ensure comparisons use **equivalent exposure** or explicitly label differing playtime; do not imply that a 7-day Idle run equals 7 days of Active gameplay.
- Measure common milestones, successes/failures, decisions, inactivity/stalls, spending/saving/automation preference where supported. Preserve optional game-specific milestones such as LootFarmer maps, bosses and Prestiges separately.
- Report `unsupported`/`not_measured` distinctly from 0. Include a diagnosis that distinguishes bad policy/adapter behavior from a plausible gameplay bottleneck. Do not claim simulations measure UI comprehension or fun.
- Keep long horizons non-gating and sequential by default. Include a fast suite probe and short smoke runs for each profile. If full 7-day × multiple seeds is costly, report what completed, do not block implementation or claim runs you didn't finish.

## 8. Validation, delivery, and Git

Before declaring complete, verify:

1. The shared package has **zero** imports and dependencies on LootFarmer-specific classes/paths/data.
2. All seven universal profiles have documented and distinct default behavior, support overrides, and can run through the same core contract.
3. LootFarmer uses one adapter/strategy implementation mapping generic intents to real game actions; policies no longer derive from LootFarmer Active behavior.
4. A second non-LootFarmer capability model works **without modifying any universal profile or core package file**.
5. Supported and unsupported capability handling, invalid actions, decision commitments, risk/priority, session scheduling, offline settlement and persistence are tested.
6. Identical seeds/config versions replay deterministically, and report metadata identifies profile/core/adapter versions.
7. The three previous profile names still work through supported runner commands; old run evidence stays identifiable.
8. At least one legitimate short gameplay run succeeds per profile and produces inspectable logs/summary.
9. No new production gameplay changes, save compatibility regressions or unrelated source edits were introduced.
10. Test suite results are reported against the actual prior baseline. The last reported full LootFarmer suite was **53/69**, with 16 pre-existing failures; verify current baseline instead of assuming it remains identical.

Execute focused probes, deterministic tests, small smoke runs, and then the maintained regression suite **once** after integration stabilizes. Record concrete command lines, counts, profiles/seeds tested, execution times and notable limitations. Do not start multiple heavy long-running simulations in parallel.

**Git/version safety:** The previously reported local commit is `41eef3d`; inspect actual HEAD and worktree before work. The developer's local `project.godot` and `export_presets.cfg` are reportedly uncommitted with version **42**, while the committed game version is **41**. Preserve these edits and don't include them in this commit; don't bump versions for a testing-framework change. Do not push, export, publish or upload. Commit completed changes locally after validation according to the Playbook. Audit staged files to avoid capturing user work or generated run outputs. For any shared-kit package outside this Git repository, say where it was written and how it is versioned/committed or backed up; a LootFarmer commit by itself cannot prove the external files are safely tracked.

## 9. Required final report

Provide a compact but substantive report with:

- **Before → after architecture:** what was reusable and what was LootFarmer-bound, and the specific dependency breaks made.
- **Seven universal profiles:** compact parameter/behavior matrix and how they differ in practice, including any per-game adaptations.
- **Reusable package:** exact canonical source location, integration location, version/pinning method, and installation steps/entry-point for the next Godot game.
- **Adapter contract:** available intents/capabilities, required methods/data, and explanation of how Claude should implement it for a new game.
- **Portability evidence:** actual LootFarmer runs and the distinct non-LootFarmer fixture; do not call fixture coverage proof of another shipped game's integration.
- **Testing:** focused probes, deterministic replays, sample profile results, regression suite counts, commands, and time spent.
- **Limitations:** remaining game-specific policies, incomplete generic metrics, inaccessible shared kit, or behavioral realism limitations.
- **Git/version:** exact changed-file scope, any external-kit changes, local commit hash; confirmation that versions, user edits, gameplay and store builds were untouched.

**Authority:** Complete the audit, make design decisions, implement all seven reusable profiles, migrate LootFarmer, document the new-game installation process, validate the cross-game boundary, and commit — in **this one task**. Do not return an architecture proposal for approval. If an external shared-kit path is unavailable, deliver the full, tested reusable package in the repository and report the remaining installation step; do not let that block the reusable framework implementation.
