#!/bin/sh
# usage: run.sh <builds.json> <tag>   -> runs two halves (S4-S6, S7-S8) in parallel, csv tests/tmp/c79/<tag>_a.csv/_b.csv
G="D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
cd /d/Godot/lootFarmer
B=$1; T=$2
python - "$B" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); ids=[b['id'] for b in d['builds']]
open('tests/tmp/c79/_a.txt','w').write(','.join(i for i in ids if i[1] in '456'))
open('tests/tmp/c79/_b.txt','w').write(','.join(i for i in ids if i[1] in '78'))
PY
A=$(cat tests/tmp/c79/_a.txt); Bb=$(cat tests/tmp/c79/_b.txt)
"$G" --headless --path . res://tests/tmp/c79/boss_audit.tscn -- --probe --profile=probe-audit79a --no-autosave --first-run-complete --builds=res://$B --csv=res://tests/tmp/c79/${T}_a.csv --only=$A > tests/tmp/c79/${T}_a.log 2>&1 &
"$G" --headless --path . res://tests/tmp/c79/boss_audit.tscn -- --probe --profile=probe-audit79b --no-autosave --first-run-complete --builds=res://$B --csv=res://tests/tmp/c79/${T}_b.csv --only=$Bb > tests/tmp/c79/${T}_b.log 2>&1 &
wait
grep PFA_AUDIT tests/tmp/c79/${T}_a.log tests/tmp/c79/${T}_b.log
