# LootFarmer — Player-Profile Automated Playtesting (Phases 1 and 2)

Briefs: `docs/LootFarmer_Player_Profile_Playtesting_Phase_1.md` (framework + Active) and the Phase 2 brief (Casual, Idle, sessions and offline time). This document is the how-to: what exists, how to run it and how to read its output. The Phase 2 results are in `docs/LootFarmer_Player_Profile_Playtesting_Phase_2_Report.md`.

Three profiles exist: **Active**, **Casual** and **Idle**. Collector, Speedrunner, Beginner and Completionist are extension points only.

## What it is

A policy (a set of player decisions) plays the real `LootSimulation` headlessly from a fresh, isolated profile. Every outcome comes from the game's own step and transactions; nothing is injected. Session profiles leave the game and come back: the game's own background notice saves, the virtual calendar runs while the game is closed, and the return loads the save file again, so the game's own offline settlement, caps and Claim decide what the absence pays. The game records what happened; Python only starts runs, checks them and tabulates the files.

| Part | File | Role |
|---|---|---|
| Driver (reusable, game-agnostic) | `tests/playtest/playtest_driver.gd` | Steps the game in 0.1 s steps, schedules decisions, keeps active / offline / calendar time, runs sessions (leave, absence, return), detects stalls and progress gaps, enforces active-time, calendar-time, step and wall budgets, classifies the stop |
| Session schedule (reusable) | `tests/playtest/session_schedule.gd` | When a profile plays: session lengths and daily start slots, from its own seeded random stream |
| Recorder (reusable) | `tests/playtest/playtest_recorder.gd` | `events.jsonl` and `trace.jsonl`; collapses repeated rejections (and tallies them); SHA-256 of the event log |
| Game adapter (LootFarmer) | `tests/playtest/lootfarmer_adapter.gd` | Read-only observations and named player actions, each delegating to one public game function; leave/return through the game's own save path with a persistence check; measures currency moved by each action, offline earned vs claimed, automation purchases, milestones in active and calendar time; the Prestige field diff |
| Profile registry | `tests/playtest/profiles.json` | Each profile's policy script, the scripts hashed into its identity, and its schedule(s) |
| Active policy | `tests/playtest/policies/active_policy.gd` | `active-1`, frozen since Phase 1 (unchanged file, so continuous Active runs give exactly the Phase 1 events) |
| Session policy family | `tests/playtest/policies/profile_policy.gd` | Extends Active; replaces only attention cadence, spending lists, automation set-up, boss/Prestige timing, resting and session hooks, all as parameters |
| Casual policy | `tests/playtest/policies/casual_policy.gd` | `casual-1` parameters and wish lists |
| Idle policy | `tests/playtest/policies/idle_policy.gd` | `idle-1` parameters and wish lists |
| Run scene | `tests/playtest/player_profile_run.tscn` | One run; writes `summary.json`; ends with a `PLAYTEST_RESULT` line |
| Runner | `tools/player_profile_run.py` | One Godot process at a time, process timeout, `SCRIPT ERROR` check, sentinel check, `comparison.csv/.md`, `profile_comparison.md`, `findings.md`, `measurements.md` |
| Infrastructure probe (in the suite) | `tests/player_profile_probe.tscn` | 78 fast checks: clock seam, mission day rollover, offline claim once, deterministic playthrough, snapshot round trip; Phase 2: schedule determinism, a real one-day Casual session run (cold returns, settlement, cap, exactly-once claims, midnight rollover, determinism), warm returns, continuous Active has no offline time |

The long playthroughs are **non-gating** and are never run by `tools/run_probes.py` (Playbook 60.1). Only the small probe is in the suite.

## The one production change: a clock seam (Phase 1, unchanged)

`LootSimulation.clock_override` (default `-1.0`, session-only, never saved) with `now_unix()` and `today()`. When it is negative, the game reads the system clock exactly as before. A harness may set a virtual Unix time. Phase 2 adds no production change: sessions use the existing background notice, `SaveService.load_and_apply()`, `restore()`, `settle_offline()` and `claim_offline()`.

A run starts at the fixed virtual time 2026-01-05T08:00:00Z (calendar 0) and advances it by simulated active and offline seconds. Virtual days are UTC days.

## Profiles

| | Active (`active-1`) | Casual (`casual-1`) | Idle (`idle-1`) |
|---|---|---|---|
| Schedule (default) | one continuous session; for a calendar horizon 2 sessions/day of 55-65 min (08:00, 19:00) | 16-24 min sessions at 08:30, 13:00 (50% of days) and 20:00 | 5-10 min sessions at 08:00 and 21:00 (60% of days) |
| Attention | every decision every 0.5 s | inventory/shop/missions once a minute; loot tap every 1.5 s; casts every 3 s | one pass at session start, every 2 min and before leaving; loot tap every 3 s; casts only in boss fights or automatically |
| Spending | savings goal; XP/loot/coin upgrades of its farm, slots, Focused Farming, Gem Chance, Auto-Collect | no savings plan: buys what it can afford from a natural list (Focus, Gem Chance, one Offline Time level, a little crit; farm upgrades to modest levels, Movement, Map Details, two Offline Coins levels, camps) | strict savings plan, automation and offline first (Focus, Offline Time, Auto-Collect, Offline Gems/Weapons/Outfits, Auto-Merge, Auto-Claim, Auto Use, Auto Buy, Offline Supplies/Skills, automatic skills; Offline Coins and item rates before farm upgrades) |
| Objectives | claims at once | claims at its passes; farms an open daily "defeat" mission's type | claims at its passes; Auto-Claim once bought |
| Bosses | margin 1.25 (+0.15 per loss, +0.25 vs skills); retries at once | +0.25 margin, at most 2 attempts a session, no retry after a loss until the next session | +0.35 margin, 1 attempt a session |
| Resting | below 35% to 95% | below 30% to 80% | only notices HP at its 2-minute pass: below 35% rests to 80% |
| Prestige | first as soon as allowed; later ones 30 active min apart | at the first quiet moment of a session, at most every 20 calendar hours | same as Casual |
| Offline | claims on return (driver default) | claims on return | claims on return |

Casual and Idle only: two deaths on the same farm type within 15 active minutes make them avoid that type until they gain 3 levels; Active has no such rule. All three share movement, boss-attempt commitment, estimates, gear comparison (`stats_with`), next-map and camp rules (Active's code).

Schedules and policy parameters are configuration, not code: edit `tests/playtest/profiles.json` or pass overrides (below); policy parameters live in the `P` dictionary of each policy's `_init()`.

## Running it

Requires the Godot 4.7 console executable (environment variable `GODOT`, same default as `tools/run_probes.py`).

```
# smoke: each profile, one seed, one calendar day
python tools/player_profile_run.py run --batch p2 --player-profile active,casual,idle --seeds 1 --until calendar --calendar-hours 24 --trace

# equal active time: one hour of play each (Casual and Idle spread it over days)
python tools/player_profile_run.py run --batch p2 --player-profile active,casual,idle --seeds 1,2,3 --active-minutes 60 --trace

# equal calendar time: 24 hours, then 7 days (raise the per-process wall budget for long Active runs)
python tools/player_profile_run.py run --batch p2 --player-profile casual,idle --seeds 1,2,3 --until calendar --calendar-hours 168 --max-wall-seconds 2400
python tools/player_profile_run.py run --batch p2 --player-profile active --seeds 1,2,3 --until calendar --calendar-hours 168 --max-wall-seconds 3600

# determinism: the same configuration twice from fresh profiles, digests must match
python tools/player_profile_run.py determinism --batch p2 --player-profile idle --seeds 1 --until calendar --calendar-hours 24

# schedule experiments without code changes
python tools/player_profile_run.py run --batch exp --player-profile casual --seeds 1 --until calendar --calendar-hours 72 --session-minutes 30-40 --slots 9,21@0.5 --return-mode warm

# first Prestige, bounded by active and calendar time
python tools/player_profile_run.py run --batch p2 --player-profile idle --seeds 1 --until first-prestige --max-active-minutes 240 --max-calendar-hours 168

# rebuild the reports from the runs already in a batch
python tools/player_profile_run.py report --batch p2
```

Options: `--player-profile` (one or a comma list, run in order), `--seeds`, horizon (`--active-minutes`, or `--until calendar --calendar-hours`, or `--until first-prestige --max-active-minutes [--max-calendar-hours]`; `--max-active-minutes` also caps a calendar run), schedule (`--schedule default|continuous|calendar`, `--session-minutes a-b`, `--slots 8.5,13@0.5,20` (hour[@chance]), `--jitter-minutes`, `--min-gap-minutes`, `--grace-seconds`, `--return-mode cold|warm`), `--max-wall-seconds` (default 600 per Godot process; the runner kills the process 120 s later), `--stall-minutes` (default 30 for continuous runs; session runs record gaps and only stop on a stall when it is given), `--trace`, `--label`.

`--schedule default` uses the profile's schedule; Active is continuous unless the horizon is calendar time, where it uses its `calendar_schedule`. `--schedule continuous` forces one session (a "continuous Casual" is still the Casual policy, only without breaks).

Direct Godot arguments (after `--`): `--probe --no-autosave --profile=probe-pp-<id> --player-profile=<name> --seed=N` plus the same horizon and schedule options in `--key=value` form, `--max-wall-seconds=N --stall-minutes=N --trace --output=<absolute folder>`.

## Sessions and offline time

1. A session plays its scheduled active seconds. It ends at the first moment after that when no boss is engaged and no Prestige choice is open, or after `end_grace_seconds` more at the latest. The policy's `session_end()` runs first (Idle spends before leaving).
2. **Leave**: the stick is released and the game receives `NOTIFICATION_APPLICATION_PAUSED`: it stamps its own offline snapshot (rates, cap, eligible items at that moment) and saves durably to the isolated profile. The adapter records the progression left behind.
3. **Absence**: the virtual clock jumps to the next scheduled start. Nothing steps: no combat, no farming, no timers run.
4. **Return** (`cold`, the default): a fresh profile object is created and `SaveService.load_and_apply()` reads the file; `restore()` settles boss respawns and the offline interval at the virtual now (the game's own `settle_offline`, cap included). `warm` sends `NOTIFICATION_APPLICATION_RESUMED` instead. The adapter checks that level, experience, currencies, items and merges, upgrades, Prestiges, cards, maps, camps, loadout, skills, Focus target, missions and opportunities equal what was left (a mismatch stops the run with `action_error`).
5. The policy's `session_start()` runs: Casual and Idle claim the offline receipt and open a management pass; Active (no hook) gets the driver default, which only claims.

Offline accounting in `summary.json` under `game.offline`: `earned` is what the game's settlement recorded (the change of its pending record per return), `claimed` what the Claim paid (Coins and Gems measured around the call, item copies from the game's receipt), `paid_at_prestige` the pending Coins and Gems a Prestige paid instead (their item copies end with the run, as the game rules say), `capped_seconds` time away past the purchased cap (unpaid), `ineligible_seconds` time away during an open Prestige choice, `rates_at_leave` the Offline tab's figures at each departure.

## Stop classes

| Stop | Meaning | Run counted as sound |
|---|---|---|
| `duration_reached` | The requested active time was played | yes |
| `calendar_reached` | The requested calendar time passed (possibly while away; the cut absence is `away_at_stop_s`, not settled) | yes |
| `first_prestige_completed` | `begin_prestige` and every `choose_card` succeeded | yes |
| `stalled` | No meaningful progression for `--stall-minutes` | yes (a finding; the last trace samples are written) |
| `time_budget_exceeded` | A goal run spent its active or calendar budget without reaching the goal | yes (a finding) |
| `wall_timeout` | The wall budget was spent | no |
| `action_error`, `engine_failure` | The harness or the game could not continue (including a persistence mismatch after a return) | no |
| `script_error` | Godot printed `SCRIPT ERROR` (runner classification, even on exit code 0) | no |

"Meaningful progression" is a change in level, map, map access, merge levels or items owned, upgrade levels, boss defeats, Prestige count, cards, opportunities found or ready, or the worn weapon or outfit. Offline Coins alone are not progression until spent.

## Output

Everything goes to `tests/tmp/player_profiles/<batch>/` (git-ignored; the folder holds a `.gdignore`).

Per run, in `<profile>_s<seed>_<label>/`:

- `events.jsonl`: chronological decisions, action results and milestones, each with active time `t` and virtual calendar time `vt`. Phase 2 adds `schedule`, `session_started` / `session_ended`, `left_game` (with the offline rates), `offline_settled`, `offline_paid_by_prestige`, `missions_refreshed`, `purchase_wait` (a savings goal that lasted at least 10 active minutes or 6 calendar hours), `prestige_skipped` (why a session's Prestige look did not happen), `farm_avoided`. It never holds wall time or paths, so its SHA-256 is the determinism digest.
- `summary.json` (schema 2): identity (commit or dirty marker, content fingerprint, policy version and the hash of every script its decisions come from, seed), horizon, schedule, sessions (start, length, absence before), stop reason, active / offline / calendar time, measured game results, `milestones` (each first time as active and calendar seconds), offline accounting, automation levels and their first purchase times, mission days seen, savings goals (closed and open), rejected actions by reason, progress gaps of at least 10 active minutes (with calendar span), the two digests, and under `process` the volatile facts excluded from every comparison.
- `trace.jsonl`: with `--trace`, one sample per 30 active seconds (now with the session number). Without `--trace`, only the last 60 samples before an abnormal stop.
- `godot.log`: the process output.

Per batch:

- `comparison.csv` / `comparison.md`: one row per run plus a median-and-range row per profile and horizon. `_min` columns are active minutes, `_h` columns calendar hours.
- `profile_comparison.md`: Active, Casual and Idle side by side per horizon (every required metric), milestones as *active minutes / calendar hours*, boss outcomes per boss.
- `findings.md`: automatic progression-problem candidates by fixed thresholds (no-progress gaps, long time without a boss or map, repeated deaths, repeated boss losses, long savings goals, late automation, offline contribution, Prestige ready but not taken or never ready, policy rejections and steering) with a suggested cause class. These are candidates, not verdicts.
- `measurements.md`: per-run timelines, sessions, offline accounting, boss attempts, deaths and the Prestige field diffs, copied without interpretation.

## Reading the evidence

- **Evidence class.** A profile run is a *natural fresh-save playthrough* (Playbook 112.2, class 3). The infrastructure probe's Phase 1 clock sections seed a few labelled fixture values; its Phase 2 sections use none.
- **Active vs calendar time.** Every milestone has both. An equal-active-time comparison (1 hour each) spreads Casual and Idle over days of calendar time, so they also collect offline income Active never sees. An equal-calendar comparison (24 h, 7 days) gives Active far more play. Report both and never read one as the other.
- **Currency.** Spending and action income (claims) are measured around each action. Income from kills is the remainder of the balance change, exact as a total.
- **Estimates are choices, not results.** Margins and wish lists decide what to try; the game decides what happens.
- **Determinism.** The same seed, policy, schedule and content give the same `events_sha256` and `state_sha256`. The schedule has its own random stream, so changing a schedule never changes the game's draws except through what the player does.
- **Deaths, stalls, waits and rejections are candidates.** Read the trace first; a bot loop looks like a wall (Playbook 112). `findings.md` names a suggested cause; the report confirms or rejects it.

## Adding a profile later

1. Add `tests/playtest/policies/<name>_policy.gd`. For a session-style player, extend `profile_policy.gd`, set `P` in `_init()` and write `gem_wishes()` / `coin_wishes()`; for something different, implement `decide()`, `steer()`, `trace_sample()`, `DECISION`, and `policy_version()` or `VERSION`, plus optional `session_start()` / `session_end()`.
2. Register it in `tests/playtest/profiles.json` with its `hash_files` and schedule.

The driver, recorder, adapter, runner and report columns do not change.

## Limits

- The profiles start in onboarding mode None. The Guided tutorial and all UI are outside the simulation; the bots cannot measure comprehension or enjoyment.
- Loot taps reach any visible pickup within 320 units.
- No checkpoint-resume of a run; a run always starts from a fresh profile.
- No parallel mode (by design).
- A cold return recreates the game state from the save file but not the presentation layer (scenes, notices, the offline receipt panel); the Claim is the receipt's button.
- The policies' own simplifications are listed in their headers. The bots never sell or drop items, never keep copies for Collection contracts and never use Reroll Stats.
