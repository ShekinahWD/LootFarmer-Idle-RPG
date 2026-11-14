# Integrate Player Profiles into a New Godot Game

**Start file:** `D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles\INTEGRATION_FOR_CLAUDE.md` (this file; after
installation also `res://addons/player_profiles/INTEGRATION_FOR_CLAUDE.md`). Read `README.md` next.

You are adapting **fixed** universal profiles to a game. You do not redesign the framework, and you never edit
`core/profiles.json`, `core/*.gd` or another game's integration. Everything you write lives in the game's repository,
under `tests/playtest/<game>/`. If a game truly needs a framework change, stop and propose a package version bump
instead of patching a copy.

## 0. Install and pin

```powershell
$KIT = "D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles"
python "$KIT\tools\player_profiles.py" verify  --package $KIT
python "$KIT\tools\player_profiles.py" install --source $KIT --project .
python .\addons\player_profiles\tools\player_profiles.py status --project . --source $KIT
python .\addons\player_profiles\tools\player_profiles.py selftest --project . --godot "<godot console exe>"
```

`install` copies the package to `res://addons/player_profiles/` and writes `player_profiles.lock.json`. Commit both
(and the generated `*.gd.uid` files). Add `addons/player_profiles/*` and `player_profiles.lock.json` to every release
preset's exclusions, or confirm that the game's export allowlist cannot reach them, then list the exported pack to
verify. Never edit installed package files; update by reinstalling a newer version with `--overwrite`.

## 1. Inspect the game (no code yet)

Read the GDD and the code. Write down, with file:line references:
- The **authoritative simulation** object and how to step it headlessly at a fixed `dt` (no rendering, no input events).
- Every **player-accessible action** and the public function a tap/click reaches; the game's own refusal reasons.
- **Objectives and milestones** (levels, stages, waves, resets, endings), optional content, collections, achievements.
- **Persistence:** save/load entry points, a test/isolated save namespace, how to keep autosave off for real profiles.
- **Clock and offline:** where the game reads time, whether a clock seam exists (add a minimal, default-off seam if not:
  production must read the system clock when it is unset), how offline time is settled and claimed, caps.
- **Randomness:** the game's RNG and how to seed it for a run.
- What a player can **see** (values on screen) versus what only the code knows. Estimates from hidden data are
  oracle limitations: avoid them or list them explicitly in the adapter header.

## 2. Map capabilities to intents

Fill this table in the adapter header. Every generic intent gets a row; unsupported ones say why.

| generic intent | this game's legitimate actions | kind (instant/activity) | signals the player can judge |
|---|---|---|---|
| recover | ... or **unsupported**: why | | urgency from ... |
| claim_rewards | | | |
| progress_main | | | milestone, advances |
| attempt_challenge | | | confidence from ..., risk |
| strengthen | | | benefit from ... |
| improve_economy | | | |
| invest_automation | ... or **unsupported** | | |
| explore | | | |
| complete_optional | | | optional |
| collect | | | novelty |
| wait | always: do nothing | activity | |

Do not invent mechanics to fill a row. If the game has no offline or automation, declare them unsupported: Idle then
simply means low attention.

## 3. Implement the adapter, tactics and integration

Create `tests/playtest/<game>/` with:

- `<game>_adapter.gd` — `extends "res://addons/player_profiles/core/adapter_base.gd"`. Implement:
  `integration_info()`, `capabilities()`, `configure(profile)`, `observe()`, `options()`, `begin(option)`,
  `advance(now)`, `cancel()`, `steer()`, `set_clock()`, `step(dt)`, `failed()`, `session_can_end()`, `leave_session()`,
  `return_session()`, and the telemetry methods `progress_signature()`, `trace_sample()`, `state_digest()`,
  `game_summary()`, `generic_metrics()`. Contract rules:
  - `begin()` calls **only** the game's own player-action functions; never write state to grant an outcome.
  - A running activity keeps appearing in `options()` as eligible while it can continue.
  - Ineligible options carry the game's own refusal key in `block`; unaffordable ones set `affordable=false` and `shortfall`.
  - `observe().urgent` lists only options with urgency > 0 (cheap: it is read every tick).
  - Unsupported generic metrics are the string `"unsupported"`, never 0.
  - Option order must be deterministic (iterate sorted keys).
- `<game>_tactics.gd` (optional) — how activities are carried out (movement, attack timing, building placement).
  Tactic parameters may be **derived from traits** in `configure(profile)`; write the formulas in its header.
  Never branch on a profile id.
- `<game>_integration.gd` — `info()`, `prepare(host, options)` (isolated save namespace, autosave off, refuse to run
  otherwise), `create_adapter(context)` (seed the game RNG with `context.seed`, start the clock at `context.start_unix`),
  `fingerprint()` (hash of the game data that decides outcomes), `cleanup()` (delete the isolated saves).

Copy the shapes from `addons/player_profiles/tests/fixture/farmstead_adapter.gd` and `farmstead_integration.gd`.
Benefits and confidences are the strategy's honest estimates on 0..1; flag `bottleneck` only for a blocker a player
can see (a missing slot, "the boss is not beatable yet", "the next milestone is far at the current income").

## 4. Wire runs

Generic runner (no game code needed):

```powershell
godot --headless --path . res://addons/player_profiles/runner/run_scene.tscn -- `
  --integration=res://tests/playtest/<game>/<game>_integration.gd --player-profile=casual --seed=1 `
  --until=calendar --calendar-hours=24 --output="$PWD\tests\tmp\player_profiles\smoke\casual_s1"
python .\addons\player_profiles\tools\player_profiles.py run --godot "<exe>" --project . `
  --integration res://tests/playtest/<game>/<game>_integration.gd --batch smoke --seeds 1 -- --active-minutes=20
```

Pass the game's own command-line flags (test save namespace, no autosave) after `--` if `prepare()` relies on them.
Keep run outputs in an ignored folder with a `.gdignore`.

## 5. Validate before comparing anything

1. **Contract probe** (`tests/<game>_player_profiles_probe.gd`, in the maintained suite): `contract_check.check_adapter`
   is empty; every option passes `check_option` at start and after a short run; an invalid and an unaffordable action
   are rejected with the game's reasons; telemetry is never needed for a decision.
2. **Per-profile behaviour:** all seven profiles run a short real simulation with no `action_error`, decisions > 0,
   progress > 0; attention orders deliberations (Active > Casual > Idle).
3. **Deterministic replay:** the same seed twice gives identical `events_sha256` and `state_sha256`; another seed differs.
4. **Sessions:** cold returns reload the progression unchanged; offline time is settled by the game and claimed once
   through a `claim_rewards` decision (or recorded as unsupported).
5. **Short real runs:** 20-30 active minutes per profile; read `framework_comparison.md` and a few `events.jsonl`.
6. Confirm every executed action is a legal player action, and document unsupported mechanics and oracle limitations.
7. Only then run multi-seed comparisons (sequential, outside the gating suite). Before suggesting a game change for a
   stall, classify it: tool/adapter failure, adapter signal problem (benefit/confidence wrong, option missing), policy
   behaviour (a profile doing what its traits say) or plausible gameplay bottleneck. Check the adapter first.

## 6. Report

Per profile: traits used (and overrides), active/offline/calendar time (never mix them), milestones, failures,
unsupported intents, diagnosis. State which comparisons use equal active exposure and which use equal calendar time.
Profiles that behave identically because the game offers no meaningful choice must be reported as such.

## Checklist

- [ ] Package installed, `status` clean, lock committed, release export excludes it.
- [ ] No edits under `addons/player_profiles/`.
- [ ] Adapter header has the intent table, unsupported list and oracle limitations.
- [ ] Contract probe and self-test in the suite; replay deterministic; sessions verified or declared unsupported.
- [ ] Real saves untouched (isolated namespace, cleaned up); production clock default unchanged.
