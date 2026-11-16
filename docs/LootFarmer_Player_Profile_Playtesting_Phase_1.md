# LootFarmer — Player-Profile Automated Playtesting: Phase 1 Implementation

**Status:** Authorized for implementation. **Batch scope:** simulation foundation + **Active** profile + repeatable, comparative-ready evidence reporting. Other six profiles are **not** part of this batch.

## 0. Read and verify first

Read the repository's current `docs/Reusable_Game_Development_Playbook.md`, particularly §§59, 60, 60.1, 111, 112, 112.2, 140 and 141.5. Read `docs/LootFarmer_GDD.md`, `docs/LootFarmer_Test_Suite.md` and the latest approved gameplay/balance changes. Inspect the *actual working tree* before editing; the following paths are reference entry points, not an assumption that yesterday's signatures are still current:

- `scripts/game/simulation.gd` (`LootSimulation`, `step(dt)`, `new_profile`, `save_snapshot`, `restore`, `buy_upgrade`, real actions and seeded RNG).
- `scripts/game/campaign.gd` (missions, progression, gates, camp travel, Prestige, offline settlement).
- `tests/pacing_bot.gd` (historical steering/boss/farming ideas; known outdated behavior, **do not treat as a valid balance oracle**).
- `tests/progression_audit.gd`, `tests/player_feedback_audit.gd`, `tests/prestige_field_diff.gd` (legitimate transactions, measurements, reset checks).
- `tools/progression_audit_run.py`, `tools/run_probes.py` (sequential subprocesses, watchdogs, explicit success/failure requirements).

Preserve the production game and its existing test suite. The Playbook's earlier advice against long simulations for a small balance patch (Change 62) was scoped to *that patch*: this separate, explicitly approved playtesting-system project is permitted, but long runs remain opt-in.

## 1. Goal and principles

Create a **reusable framework** for running player-policy decisions against LootFarmer's **authoritative Godot simulation** headlessly, at accelerated wall-clock speed. This batch delivers **one real Active player** that can play from a clean profile toward and through its **first completed Prestige transaction** (not merely discover a ready opportunity). It also delivers structured evidence that supports the Reddit-style **comparative table, individual experience evaluation, and balance assessment** once more profiles are added.

Non-negotiable:

1. **Never manufacture progression** in an actual playthrough. Fresh save; legitimate movement, farming, pickup, equipment, upgrades, bosses, missions, travel, opportunities, actual `begin_prestige` and `choose_card` transactions. No direct state injections to speed it up, grant drops, insert keys, set levels, or fake achievements. Test fixtures for isolated engine checks must be clearly distinguished from real playthrough evidence.
2. Use the **real combat, loot, economy, offline and Prestige rules**; do not independently reimplement formulas in Python. Heuristics may estimate choices, but outcomes come from real actions.
3. Preserve shipping gameplay, save compatibility, balance constants, UI and Android behavior. The only permissible production-code change is a **narrow, testable, default-disabled clock injection seam** if necessary for deterministic mission/offline/Prestige behavior. Confirm it does not alter the production default. Do not introduce a new save schema merely for tests.
4. **Bots measure; humans decide.** Do not modify balancing, progression targets, equipment, enemy AI, content, or the historical pacing bot merely to make an audit reach an objective.
5. Build for all seven profiles later, **implement only Active now**. No premature UI, dashboard, Steam work, or expensive all-profile simulations.

## 2. Implementation boundaries

Use a clear separation (exact filenames subject to the repository conventions):

- **Driver — reusable Godot:** advances time in `<= 0.1 s` real game steps, schedules policy decisions, maintains explicit simulated active/offline time, milestones, stalls, fail-fast assertions, deterministic seed, configurable stop conditions and max iterations. Do not call `step(60)` expecting a minute to pass; the engine clamps it.
- **LootFarmer adapter — game-specific:** offers read-only observations and **named player actions** that delegate to established public game APIs. No action may mutate a state dictionary directly to grant outcomes. Report rejected actions/reasons where available. Keep policy logic separate from mechanics.
- **Active policy — one profile:** distinct, documented decision priorities for discovery, movement, picking up loot, equipping/merging/evolving, useful upgrades with a savings goal, supplies/skills, camp rest/travel, missions, boss attempts, and first Prestige/card choice. Reuse compatible behavior from the old bot but correct obsolete assumptions (Auto-Collect, Focused Farming, current merge/evolution rules, relevant automation and Map Mastery). Movement should steer every game step, avoid 26px threshold oscillation, and commit to a boss attempt unless a genuine retreat condition is met (Playbook §112).
- **Python runner — orchestration/reporting:** invokes one Godot headless process at a time by default, enforces process timeouts, catches any `SCRIPT ERROR` even on exit code 0, requires a success/failure summary sentinel, and produces machine-readable and human-readable outputs. Never require Claude/API calls during a playthrough. Use Python only to summarize the game's recorded results.

Investigate actual save-service behavior before implementation. Use isolated `probe-...` save identifiers, an opt-in no-autosave/test profile where appropriate, and never overwrite or read the developer's real profile. Real Prestige and claims may invoke `SaveService.save_now()`; make test transactions durable in their isolated location while preserving their normal semantics. Clean teardown and no contamination between seeds are required.

## 3. Deterministic virtual clock

Implement or reuse the smallest possible **test-only clock seam** so a session can start at a fixed timestamp and progress predictably. Production mode must continue using the real system clock. Audit all time-related call sites needed for this flow, including:

- `campaign.refresh_missions()` (currently reads system date; day determines mission selection).
- `campaign.offline_snapshot()`, `campaign.settle_offline(now)` and `claim_offline()`.
- `simulation.save_snapshot()`, `restore()` and `settle_boss_respawns(now)`.
- `campaign.begin_prestige()` transaction identifier (currently has a wall-clock component).

Do **not** change active-time clocks, the rules for offline reward caps or production timers. Keep the injected clock out of player save data and reset it when the harness ends. Prove at least: identical seed/config -> identical normalized event log; a simulated day boundary refreshes missions; an offline interval is correctly settled and claimable exactly once in an isolated test; ordinary production calls default to system time. If Phase 1 Active is continuous-play, test clock behavior independently but do not fabricate offline sessions for that profile.

**Determinism comparison:** normalized event log **and final game-state digest** should match across two fresh runs using the same seed/config. Exclude wall-run duration, absolute file paths and other intentionally volatile process metadata from the deterministic digest. Don't suppress meaningful gameplay divergence through over-normalization. Include catalog/content fingerprint and profile policy version in metadata. If legitimate real saves introduce nondeterministic IDs, stabilize the test-only clock instead of dropping transaction evidence.

## 4. CLI, stopping conditions and bounded runs

Support arguments equivalent to (names may be adjusted consistently and documented):

- `--player-profile=active`
- `--seed=1`
- `--active-minutes=60` (active simulated gameplay, not offline/calendar time)
- `--until=first-prestige` with a **configurable maximum active-time limit**
- `--max-wall-seconds=<N>` for every Godot process
- `--trace` to enable periodic diagnosis
- `--output=<ignored directory>`

Stop classifications must be explicit: `duration_reached`, `first_prestige_completed`, `stalled`, `time_budget_exceeded`, `wall_timeout`, `action_error`, `script_error`, `engine_failure`, etc. Reaching the requested time horizon without Prestige is **not** automatically a failure; failing to demonstrate first Prestige during a bounded investigation must be reported honestly, with trace and blocker. Never silently run unbounded or restart indefinitely.

Do not yet add parallel mode. Keep full-playthrough balance audits **outside** `tools/run_probes.py` (non-gating by design; Playbook §60.1). Register *new small deterministic test probes* under the normal suite if they guard shipping/test infrastructure invariants and are fast; document separately from long audits.

## 5. Required evidence — build the outputs from Phase 1

Produce under an ignored scratch directory such as `tests/tmp/player_profiles/<batch_id>/` (include `.gdignore` for folders Godot might scan; check existing `.gitignore`). Do not write generated CSVs into historical tracked evidence folders.

### A. Machine-readable, per run

- `events.jsonl`: stable chronological records of observations/decisions/results and milestone events, with active time and virtual calendar time. Log action failures, boss-attempt starts/outcomes, purchases and resource changes, pickups/gear advancement, stage travel, Prestige decisions and transaction completion when observable. Keep event volume bounded (do not log every 0.1-second tick except optional trace samples).
- `summary.json`: run ID, game commit hash or explicit dirty-worktree marker, catalog/config fingerprint, profile policy version, seed, stop reason, active time, offline time, calendar elapsed time, real execution seconds, current stage/map, stage unlock times, character level, equipment tier/merge, cards, Prestige count, deaths, encounters, purchases, earn/spend breakdown **only where reliably measurable**, mission claims, and longest meaningful-progression stall interval. For anything not captured yet, use `not_measured`/`null`, not zero.
- `trace.jsonl` or concise periodic trace on demand: position, target, action, boss viability estimate, HP, damage, stage and reasons for rejected decisions; enough to identify a bot-loop vs a true game wall.

### B. Comparison-ready sheet

Generate `comparison.csv` plus a matching readable table in `comparison.md`. **Even with one profile in Phase 1, produce a single Active row** with a stable schema designed to add Casual, Idle, Collector, Speedrunner, Beginner and Completionist later. When the same profile has multiple seeds, include **per-seed rows** and an optional clearly labelled aggregate row (median and range where supported, never imply a real-player distribution).

Suggested columns: profile, policy_version, seed, target_active_hours, actual_active_hours, offline_hours, stop_reason, final_map, highest_stage_unlocked, first_boss_time, first_prestige_ready_time, first_prestige_completed_time, deaths, upgrades_bought, gear_progress, coins_earned/spent, gems_earned/spent, longest_stall_minutes, wall_seconds, evidence_file.

### C. Individual AI-assisted evaluation

Generate `active_evaluation.md` based **strictly on measurements**, with:

1. Brief timeline / milestones / success or noncompletion.
2. Positive indicators backed by events.
3. Friction candidates backed by **timestamps, seeds and traces**.
4. Classification per issue: **possible game balance**, **policy/decision weakness**, **simulation/tool defect**, or **unknown**; assign confidence and what would validate it.
5. Specific questions for **human/device playtesting**, especially UI comprehension and feel (not observable headlessly).
6. Optional **AI experience proxy score (0–10)** for comparison with the Reddit example, *explicitly labelled subjective, not fun measured, not a pass/fail target*. Define the rubric consistently before scoring; use `N/A` if the evidence doesn't support a meaningful assessment. Do not aim to force 9/10.

Claude may write the qualitative AI evaluation after the automated run; the game harness should not pretend to infer human emotions. Keep this section separate from objective test output.

### D. Balance assessment

Generate `balance_assessment.md` with a severity-ranked list of **investigation candidates only**, each linked to specific log evidence. State evidence class: **natural fresh-save playthrough** vs constructed fixture vs projection. Never label a new balance defect merely because an AI bot acts badly; inspect its decision trace first. No changes to game balancing without separate approval.

At the end of the batch provide a concise summary in the chat linking the report artifacts and explaining any uncertainty.

## 6. Phase 1 validation and acceptance

Validate incrementally and sequentially:

1. **Short smoke** (e.g., 5–10 simulated minutes) proves real movement, kills, item pickup, purchase and lack of script errors; each relevant action has transaction evidence.
2. **One 60-minute Active run, seed 1**, with wall-time measurement and the full evidence set; record observed speed, do not extrapolate late maps as fact.
3. **Repeat exactly the same 60-minute configuration from a fresh isolated profile**, assert normalized JSONL and final game-state digest identical. Investigate any difference rather than ignoring it.
4. **Three seeds (e.g., 1, 2, 3), 60 minutes each**, sequential. Publish the comparison, including variance and a review of any anomalies. Reuse the seed-1 result if it is exactly the same config/version; avoid needless duplicate long runs.
5. **Bounded first-Prestige playthrough** using Active, actually complete the Prestige transaction with offered cards; inspect before/after reset using the canonical field-diff contract. Do **not** assume this succeeds. If the policy stalls or run becomes too expensive, stop at the configured budget, diagnose trace, and report the true milestone and blocking reason. Improve *policy defects* without changing shipping game balance.
6. **Clock seam probes**: mission day rollover, simulated offline settlement + exactly-once claim, production default unaffected. Snapshot save/restore fidelity should be checked if the system uses checkpoints. Do not claim checkpoint-resume is working until tested.
7. Run focused tests while iterating; once the implementation is stable, run the **maintained regression suite once** (`python tools/run_probes.py`) if available. Record exact pass/fail counts and pre-existing unrelated failures. Don't falsify full-suite success when the environment cannot run it.
8. Ensure the new long audit is **non-gating**, output paths are ignored, no personal saves modified and no unrelated files deleted or changed. Preserve any pre-existing uncommitted changes.

If first Prestige cannot be completed in the first batch, a reliable driver + report + honest recorded limitation is preferable to a fabricated success. State explicitly which acceptance items remain open.

## 7. Deliverables and Git

Implement the Godot harness, minimal game adapter, single Active policy, Python runner, **focused correctness tests**, and documentation that includes exact execution commands and report interpretation. Return a changed-files list plus run results and paths to the ignored report outputs. Other profiles should be **designed as extension points, not implemented yet**. Leave `docs/Reusable_Game_Development_Playbook.md` unchanged for now; after real-world validation we will reconcile the reusable process in a dedicated consolidated update.

After implementing and running the available tests, create **one Git commit** for this batch without waiting for Android/manual approval (per the project's current workflow); don't include generated scratch logs. Suggested message:

`test(playtesting): add deterministic player-profile simulation foundation`

**Stop.** Do not begin Phase 2, adjust balance, or implement Steam orientation in this batch. In the final report explicitly state what was implemented, what was actually executed, measured run time, first-Prestige outcome, comparison/evaluation report links, failed/untested checks and the commit hash.
