# LootFarmer — Player-Profile Automated Playtesting (Phase 1)

Brief: `docs/LootFarmer_Player_Profile_Playtesting_Phase_1.md`. This document is the how-to: what exists, how to run it and how to read its output. Phase 1 delivers the framework and one profile, **Active**. The other six profiles are extension points only.

## What it is

A policy (a set of player decisions) plays the real `LootSimulation` headlessly from a fresh, isolated profile. Every outcome comes from the game's own step and transactions; nothing is injected. The game records what happened; Python only starts runs, checks them and tabulates the files.

| Part | File | Role |
|---|---|---|
| Driver (reusable, game-agnostic) | `tests/playtest/playtest_driver.gd` | Steps the game in 0.1 s steps, schedules decisions, keeps active / offline / calendar time, detects stalls, enforces active-time, step and wall budgets, classifies the stop |
| Recorder (reusable) | `tests/playtest/playtest_recorder.gd` | `events.jsonl` and `trace.jsonl`; collapses repeated rejections; SHA-256 of the event log |
| Game adapter (LootFarmer) | `tests/playtest/lootfarmer_adapter.gd` | Read-only observations and named player actions, each delegating to one public game function; measures currency moved by each action; the Prestige field diff |
| Active policy | `tests/playtest/policies/active_policy.gd` | The only implemented profile (`active-1`); its header lists the decision priorities and known simplifications |
| Run scene | `tests/playtest/player_profile_run.tscn` | One run; writes `summary.json`; ends with a `PLAYTEST_RESULT` line |
| Runner | `tools/player_profile_run.py` | One Godot process at a time, process timeout, `SCRIPT ERROR` check, sentinel check, `comparison.csv/.md`, `measurements.md` |
| Infrastructure probe (in the suite) | `tests/player_profile_probe.tscn` | 45 fast checks: clock seam, mission day rollover, offline claim once, short deterministic playthrough, snapshot round trip |

The long playthroughs are **non-gating** and are never run by `tools/run_probes.py` (Playbook 60.1). Only the small probe is in the suite.

## The one production change: a clock seam

`LootSimulation.clock_override` (default `-1.0`, session-only, never saved) with `now_unix()` and `today()`. When it is negative, the game reads the system clock exactly as before. A harness may set a virtual Unix time. The call sites routed through it:

- `campaign.refresh_missions()` (the day that selects daily missions);
- `campaign.offline_snapshot()` and `campaign.settle_offline()`;
- `simulation.save_snapshot()`, the app-pause stamp and `settle_boss_respawns()`;
- `campaign.begin_prestige()` (transaction id) and the load-time default of `boss_saved_at`.

Active-time clocks, offline caps and every timer rule are unchanged. No save field or schema was added. `SaveService` keeps writing the real time in the save file's own `last_seen_unix`, which is outside game state.

A run starts at the fixed virtual time 2026-01-05T08:00:00Z and advances it by simulated active (and, later, offline) seconds.

## Running it

Requires the Godot 4.7 console executable (environment variable `GODOT`, same default as `tools/run_probes.py`).

```
# 10-minute smoke
python tools/player_profile_run.py run --batch phase1 --seeds 1 --active-minutes 10 --label smoke --trace

# one hour, then the same again from a fresh profile, asserting identical event log and state digest
python tools/player_profile_run.py determinism --batch phase1 --seeds 1 --active-minutes 60 --trace

# more seeds, sequential
python tools/player_profile_run.py run --batch phase1 --seeds 2,3 --active-minutes 60 --trace

# bounded first-Prestige playthrough (stops when the first real Prestige transaction completes)
python tools/player_profile_run.py run --batch phase1 --seeds 1,2,3 --until first-prestige --max-active-minutes 120 --trace

# rebuild the comparison from the runs already in a batch
python tools/player_profile_run.py report --batch phase1
```

Options: `--player-profile` (only `active`), `--seeds`, `--active-minutes` (active simulated time, not calendar time), `--until first-prestige` with `--max-active-minutes`, `--max-wall-seconds` (default 600, per Godot process; the runner kills the process 120 s later), `--stall-minutes` (default 30), `--trace`, `--label`.

Direct Godot arguments (after `--`): `--probe --no-autosave --profile=probe-pp-<id> --player-profile=active --seed=N --active-minutes=M | --until=first-prestige --max-active-minutes=M --max-wall-seconds=N --stall-minutes=N --trace --output=<absolute folder>`.

## Stop classes

| Stop | Meaning | Run counted as sound |
|---|---|---|
| `duration_reached` | The requested active time was played | yes |
| `first_prestige_completed` | `begin_prestige` and every `choose_card` succeeded | yes |
| `stalled` | No meaningful progression for `--stall-minutes` | yes (a finding; the last trace samples are written) |
| `time_budget_exceeded` | A goal run spent `--max-active-minutes` without reaching the goal | yes (a finding) |
| `wall_timeout` | The wall budget was spent | no |
| `action_error`, `engine_failure` | The harness or the game could not continue | no |
| `script_error` | Godot printed `SCRIPT ERROR` (runner classification, even on exit code 0) | no |

Reaching the time horizon without a Prestige is not a failure. "Meaningful progression" is a change in level, map, map access, merge levels or items owned, upgrade levels, boss defeats, Prestige count, cards, opportunities found or ready, or the worn weapon or outfit.

## Output

Everything goes to `tests/tmp/player_profiles/<batch>/` (git-ignored; the folder holds a `.gdignore` so Godot never imports the CSV).

Per run, in `<profile>_s<seed>_<label>/`:

- `events.jsonl`: chronological decisions, action results and milestones. Each line has the active time `t` in seconds and the virtual calendar time `vt`. Types include `action` (with the Coins or Gems it moved), `action_rejected` (with the game's refusal key), `mode`, `farm_target`, `boss_attempt_started` / `boss_attempt_ended`, `boss_found`, `boss_defeated`, `level_up`, `death`, `stage_unlocked`, `opportunity_discovered` / `opportunity_ready`, `prestige_decision`, `card_awarded`, `prestige_completed`, `stuck`, `stalled`. It never holds wall time or paths, so its SHA-256 is the determinism digest.
- `summary.json`: run identity (commit or dirty-worktree marker, content fingerprint, policy version and file hash, seed), stop reason, active / offline / calendar time, the measured game results, the longest interval without progression, the two digests, and under `process` the volatile facts (wall seconds, speed) that are excluded from every comparison. Values that were not captured are `null` or `not_measured`, never zero.
- `trace.jsonl`: with `--trace`, one sample per 30 active seconds (position, target, mode and its reason, HP, damage, boss margin estimate and the margin needed). Without `--trace`, only the last 60 samples before an abnormal stop.
- `godot.log`: the process output.

Per batch:

- `comparison.csv` and `comparison.md`: one row per run in a fixed column order made for more profiles, plus an aggregate row (median and range) per profile and horizon when several seeds exist. The aggregate describes these bot runs only, never a distribution of real players.
- `measurements.md`: per-run timelines, boss attempts, deaths and the Prestige field diffs, copied from the files without interpretation.
- `active_evaluation.md` and `balance_assessment.md`: the labelled interpretation, written after the runs from the measurements. They are not produced by the harness.

## Reading the evidence

- **Evidence class.** A profile run is a *natural fresh-save playthrough* (Playbook 112.2, class 3). The infrastructure probe's clock sections seed a few labelled fixture values and are never playthrough evidence.
- **Currency.** Spending and action income (claims) are measured around each action. Income from kills is the remainder of the balance change, so it is exact as a total and not split by enemy.
- **Estimates are choices, not results.** The policy's boss margin decides when to try; whether the boss falls is the real fight.
- **Determinism.** The same seed, policy and content give the same `events_sha256` and `state_sha256`. A different result on the same commit means a real divergence to investigate.
- **Deaths, stalls and rejections are candidates, not verdicts.** Read the trace first; a bot loop looks like a wall (Playbook 112).

## Adding a profile later

1. Add `tests/playtest/policies/<name>_policy.gd` with `VERSION`, `DECISION`, `setup(adapter)`, `decide()`, `steer()` and `trace_sample()`.
2. Register it in `PROFILES` in `tests/playtest/player_profile_run.gd`.
3. Profiles with sessions need the driver to advance `offline` and call the adapter's background / resume and `claim_offline` actions. The clock seam and the offline settlement are already proven by the probe; the session scheduler itself is not implemented.

The driver, recorder, runner and report columns do not change.

## Limits in Phase 1

- Only Active exists, and it plays one continuous session: no offline time, so `offline_hours` is 0 and offline claims are `not_measured`.
- The profile starts in onboarding mode None. The Guided tutorial and all UI are outside the simulation.
- Loot taps reach any visible pickup within 320 units, one tap per half second.
- The Active policy's own simplifications are listed in its header. Its behaviour beyond map 3 is untested.
- No checkpoint-resume: the probe only shows that a snapshot survives a round trip.
- No parallel mode.
- Speeds measured so far cover maps 1 to 3 only.
