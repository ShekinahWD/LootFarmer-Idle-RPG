#!/bin/sh
# Change 49 audit batches, one Godot at a time (Playbook 60.1). Output: tests/tmp/c49/out/
G="D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
O=tests/tmp/c49/out; mkdir -p $O
run() { # name builds patch [only]
  start=$(date +%s)
  timeout 3000 "$G" --headless --path . res://tests/tmp/c49/c49_audit.tscn -- --probe --profile=probe-audit49 --no-autosave --first-run-complete \
    --builds=res://tests/tmp/c49/$2.json --csv=res://tests/tmp/c49/out/$1.csv --patch=$3 ${4:+--only=$4} > $O/$1.log 2>&1
  echo "$1 exit $? $(( $(date +%s)-start ))s $(grep -c 'SCRIPT ERROR' $O/$1.log) script errors | $(grep 'PFA_AUDIT rows' $O/$1.log)"
}
timeout 300 "$G" --headless --path . res://tests/tmp/c49/c49_prestige_diff.tscn -- --probe --profile=probe-audit49p --no-autosave --first-run-complete > $O/prestige_diff.log 2>&1; echo "prestige_diff exit $?"
run s3ctl_ind builds_s3control s3aggro_individual
run s3ctl_pas builds_s3control s3aggro_passive
run lad_CUR builds_ladder tiers_CUR,s3aggro_individual
run lad_A19 builds_ladder tiers_A19,s3aggro_individual
run lad_B22 builds_ladder tiers_B22,s3aggro_individual
run lad_A19_s3group builds_ladder tiers_A19 N3_arr,N3_mid,N3_rdy,N3_rdy_P1,N3_evo,N3_rdy_sword
run tune_A19 builds_tuning tiers_A19,s3aggro_individual
echo ALL_DONE
