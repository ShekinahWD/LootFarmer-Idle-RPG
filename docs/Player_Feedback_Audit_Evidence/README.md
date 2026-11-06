# Player-Feedback Balance Audit — reproducible baseline

Evidence for [LootFarmer_Player_Feedback_Balance_Audit_Report.md](../LootFarmer_Player_Feedback_Balance_Audit_Report.md) (audit of 2026-11-06, commit `0edbae2`, game version 27, catalog unchanged since 2026-10-28). The harness is **non-gating** (Playbook 60.1, 112.1, 112.2): it is not part of `tools/run_probes.py` and runs only when you call it.

## What is where

| Path | Role |
|---|---|
| `tests/player_feedback_audit.tscn` / `.gd` | The harness. It steps the unmodified `LootSimulation` at 0.1 s, builds each fixture through real game calls (Prestige transaction, `buy_upgrade`, `add_item`, `equip`), asserts that every item is obtainable and equipped, and writes one CSV row per trial. It never edits catalog files or production code. What-if counterfactuals (`cap3`, `desync`, `v3_115`, `late_dmgNN`) only replace cached enemy definitions in memory or hold attackers back in the harness loop, and the CSV `whatif` column labels them. |
| `tools/player_feedback_audit_builds.py` | Regenerates the four build-definition files below from the live catalog (fixture levels, merges, kills, supplies, Prestige card sets, seeds). |
| `tools/player_feedback_audit_run.py` | Runs the batches one at a time, compares each with its baseline and, with `--crosscheck`, reruns the Change 36 MIN/REC cells. |
| `tools/player_feedback_audit_analyze.py` | `compare`, `builds-check`, `summary`, `economy` (projected switching), `gear` (catalog formulas). |
| `builds_main.json` | 185 builds, 4,136 trials: the eight-stage matrix, the readiness ladders for the first three bosses, the Gray Cat neighbours and the farm rates. |
| `builds_supplementary.json` | 15 builds, 690 trials: hand-play arrivals on maps 4–8 (P0/P1), the guaranteed-gear Summer I arrival and sustained 6-actor Summer I farms. |
| `builds_whatif.json` | 35 builds, 360 trials: baseline, `cap3`, `desync`, `v3_115` and all three combined, on seven representative builds. |
| `builds_whatif_spring.json` | 6 builds, 63 trials: Spring normal damage ×0.75 and ×0.60, and ×0.60 + `cap3`. |
| `baseline_trials_<batch>.csv` | Per-trial baseline output of each batch (the reference for comparisons). |
| `baseline_summary_main.txt`, `baseline_economy_projection.txt`, `baseline_gear_table.txt` | Analyzer output from the baseline CSVs (`summary`, `economy`, `gear`). |
| `baseline_change36_crosscheck.log`, `baseline_change9_crosscheck.log` | Logs of the original cross-checks. |
| `tests/tmp/player_feedback_audit/` | **Rerun output** (git-ignored): `trials_<batch>.csv`, logs, the Change 36 cross-check CSV. Nothing is written into `docs/`, `data/` or production folders. |

Seeds: 1, 2, 3 per fight (farm entries 1, or 1–2), set in the build files. Profiles: `user://profiles/probe-audit48` (audit) and `probe-audit48x` (Change 36 cross-check), with `--no-autosave`.

## Commands

From the repository root (`GODOT` defaults to the developer laptop path, the same as `tools/run_probes.py`):

```text
# 1. Builds still match the committed definitions (an unchanged catalog gives identical files)
python tools/player_feedback_audit_analyze.py builds-check

# 2. Rerun every batch, compare with the baselines, and rerun the Change 36 cross-check (~20 min)
python tools/player_feedback_audit_run.py --crosscheck

#    one batch:            python tools/player_feedback_audit_run.py main | supplementary | whatif | whatif_spring
#    run without comparing: python tools/player_feedback_audit_run.py whatif --no-compare

# 3. Direct Godot call for one batch, optionally limited to some builds
"$GODOT" --headless --path . res://tests/player_feedback_audit.tscn -- --probe --profile=probe-audit48 \
    --no-autosave --first-run-complete --builds=res://docs/Player_Feedback_Audit_Evidence/builds_main.json \
    --csv=res://tests/tmp/player_feedback_audit/trials_main.csv [--only=S3_L35_snow,NB_S3_base]

# 4. Readable summaries and projections from any trials CSV
python tools/player_feedback_audit_analyze.py summary tests/tmp/player_feedback_audit/trials_main.csv \
    docs/Player_Feedback_Audit_Evidence/builds_main.json [all|matrix|ladder|nb|farm]
python tools/player_feedback_audit_analyze.py economy tests/tmp/player_feedback_audit/trials_main.csv
python tools/player_feedback_audit_analyze.py gear
python tools/player_feedback_audit_analyze.py compare docs/Player_Feedback_Audit_Evidence/baseline_trials_main.csv \
    tests/tmp/player_feedback_audit/trials_main.csv
```

Exit codes: the harness returns 0 when every row is valid, 1 when any build or encounter is invalid, and 2 for an unreadable build file or the watchdog. The main batch has **5 known invalid rows** (boss "farm" entries: Focus cannot target bosses), so it exits 1 by design; the runner accepts exactly those 5. The runner exits 0 only when every run is clean (no `SCRIPT ERROR`) and every comparison passes.

## Comparing a balance change (Playbook 112.1)

1. Run `python tools/player_feedback_audit_run.py --crosscheck` on the **unchanged** tree first; it must report `COMPARE PASS` for every batch. The simulation is deterministic per seed, so an unchanged tree reproduces every field.
2. Apply the authorized change, then run the same command with `--no-compare` and compare cell by cell: `analyze.py compare` lists every trial that moved, and `summary` shows the new matrix.
3. When the change edits the catalog, the regenerated builds can change too (for example, drop tables). Compare like with like, and record any build change with its reason.
4. When a change is accepted as the new reference, copy `tests/tmp/player_feedback_audit/trials_<batch>.csv` over the matching `baseline_trials_<batch>.csv` in that change's commit and say so in its report.

## Known baseline quirks (kept on purpose so the baseline reproduces)

- In `builds_supplementary.json`, both `FARM_S3v_*` and `FARM_S3v6_*` farm **6-actor** spots: the original generator shared one encounter list, and the labels say "3 actors" for the first. The 3-actor sustained Summer I figure comes from `builds_main.json` `FARM_S3` (both-loadout spots).
- Spot fights block respawns during the fight (understates difficulty); the farm entries use real respawns.
- The Spring II boss-level fixture wears a Diamond **Sword**, so it has less HP than the arrival fixture.
- The `.gd.uid` for `tests/player_feedback_audit.gd` is created on the next editor scan (headless runs do not create it); commit it then.
