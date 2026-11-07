# Consolidated Progression & Prestige Audit — evidence (2026-11-07)

Evidence for [LootFarmer_Consolidated_Progression_and_Prestige_Audit_Report.md](../LootFarmer_Consolidated_Progression_and_Prestige_Audit_Report.md). The audit ran at commit `3dd2eab` (game version 27, catalog unchanged). **Nothing in the tracked project was changed.** The what-if harness and probe ran from the git-ignored `tests/tmp/c49/`. The copies here use `.txt` extensions so Godot ignores them (`docs/` also has `.gdignore`).

## Files

| File | What it is |
|---|---|
| `baseline_rerun.log` | `python tools/player_feedback_audit_run.py --crosscheck` on the unchanged tree: 4 batches COMPARE PASS, Change 36 MIN/REC PASS |
| `c49_audit.gd.txt` / `.tscn.txt` | What-if harness = `tests/player_feedback_audit.gd` plus three additions: `--patch=` in-memory catalog what-ifs (`s3aggro_<individual\|passive>`, `s2aggro_<mode>`, `tiers_<CUR\|A19\|B22\|H24\|H28>`), a build `extras` field, and the `staggerNN` what-if. It never writes the catalog. |
| `c49_prestige_diff.gd.txt` / `.tscn.txt` | Runs the real Prestige transaction on a fully populated fixture and classifies every state field as KEPT, RESET or OTHER |
| `prestige_diff.log` | Probe output (report §2) |
| `builds_ladder.json` | 40 proposed-ladder builds (baseline builds with only the weapon swapped) |
| `builds_s3control.json` | 53 unchanged baseline Summer I builds, ladders and farms |
| `builds_tuning.json` | 89 what-if builds (13 ladder builds × candidates) |
| `gen_builds.py`, `gen_whatif.py` | Build generators (run from the repo root; they read the committed baseline builds and catalog) |
| `s3ctl_ind.csv`, `s3ctl_pas.csv`, `s3ctl_cmp.txt` | Summer I `individual` / `passive` versus baseline, row by row |
| `lad_CUR.csv`, `lad_A19.csv`, `lad_B22.csv`, `lad_H24.csv`, `lad_H28.csv`, `lad_A19_s3group.csv`, `ladder_summary.txt` | Tier-table ladders (report §3.3) |
| `tune_A19.csv`, `tuning_summary.txt` | Stage 4–8 tuning what-ifs (report §5.2) |
| `copies_model.py/.txt`, `coin_sink.py/.txt`, `prestige_inventory.py/.md` | Projections and inventories (report §3.4, §6.1, §7.1) |
| `cmp.py`, `ladsum.py`, `tunesum.py` | Summaries |
| `run_all.sh`, `run_h.sh` | The exact sequential commands used |

## Reproduce

```text
mkdir -p tests/tmp/c49/out
cp docs/Consolidated_Audit_Evidence/c49_audit.gd.txt tests/tmp/c49/c49_audit.gd        # and the .tscn / probe the same way
cp docs/Consolidated_Audit_Evidence/builds_*.json tests/tmp/c49/
sh docs/Consolidated_Audit_Evidence/run_all.sh     # about 35 min, one Godot at a time
sh docs/Consolidated_Audit_Evidence/run_h.sh
python docs/Consolidated_Audit_Evidence/ladsum.py tests/tmp/c49/out/lad_A19.csv
```

The simulation is deterministic per seed, so an unchanged tree reproduces every cell. Seeds: 1, 2, 3 per fight; farm entries use seed 1 for 5 simulated minutes. Profiles: `probe-audit49` and `probe-audit49p` with `--no-autosave`. Known invalid rows: 1 per `s3ctl_*` batch (the baseline's `FARM_S3` boss entry: Focus cannot target bosses).

## Limits

- Every build is a constructed fixture (seeded levels, merges, kills and supplies).
- The ladder builds keep the baseline fixtures' levels, outfits and supplies.
- No natural playthrough (the pacing bot is stale).
- The Change 36 final-boss ladder was not rerun on Obsidian.
- No Prestige card effects were simulated (none exist yet).

## Promoted harness (Change 49, B0 of the approved implementation brief)

The what-if harness and the Prestige field probe now live in the tracked tree, unchanged except for their header
comments: `tests/progression_audit.gd/.tscn` (= `c49_audit.gd.txt`) and `tests/prestige_field_diff.gd/.tscn`
(= `c49_prestige_diff.gd.txt`). `tools/progression_audit_run.py <batch>` reruns any recorded batch of
`run_all.sh` / `run_h.sh` (same builds, patches and `--only` lists, seeds 1–3) into the git-ignored
`tests/tmp/progression_audit/` and compares it field by field with the CSV here; `--prestige-diff` reruns the
Prestige field classification. The CSVs here are the **pre-implementation references** (commit `3dd2eab`):
once a later batch changes the catalog or the rules, a rerun measures the new game and is expected to differ.
The preserved `tests/player_feedback_audit.gd` and its runner are untouched.
