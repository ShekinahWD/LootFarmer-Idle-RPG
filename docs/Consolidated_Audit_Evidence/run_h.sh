#!/bin/sh
G="D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"; O=tests/tmp/c49/out
ONLY=N7_arr,N7_mid,N7_rdy,N7_rdy_P1,N7_obs50,N8_arr,N8_obs60,N8_obs100,N8_obs100_P1,N7_rdy_sword,N6_evo,N6_rdy
for t in H24 H28; do
 timeout 2000 "$G" --headless --path . res://tests/tmp/c49/c49_audit.tscn -- --probe --profile=probe-audit49 --no-autosave --first-run-complete --builds=res://tests/tmp/c49/builds_ladder.json --csv=res://tests/tmp/c49/out/lad_$t.csv --patch=tiers_$t,s3aggro_individual --only=$ONLY > $O/lad_$t.log 2>&1
 echo "lad_$t exit $? $(grep -c 'SCRIPT ERROR' $O/lad_$t.log) script errors | $(grep 'PFA_AUDIT rows' $O/lad_$t.log)"
done
echo H_DONE
