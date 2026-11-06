"""Player-feedback balance audit runner (non-gating; Playbook 60.1: heavy runs are sequential).

  python tools/player_feedback_audit_run.py [batch ...] [--no-compare] [--crosscheck]

Batches: main, supplementary, whatif, whatif_spring (default: all four, in that order, one Godot at a time).
Each batch runs res://tests/player_feedback_audit.tscn with its committed build file and writes
tests/tmp/player_feedback_audit/trials_<batch>.csv + .log (git-ignored). Unless --no-compare, the CSV is
compared with docs/Player_Feedback_Audit_Evidence/baseline_trials_<batch>.csv
(tools/player_feedback_audit_analyze.py compare). --crosscheck also reruns the Change 36 final-boss
audit (MIN, REC) with its CSV redirected to tests/tmp, and checks it against the recorded cells.
Exit 0 only when every run is clean (exit 0, no SCRIPT ERROR) and every comparison passes.
Environment: GODOT = Godot 4.7 console executable (same default as tools/run_probes.py).
"""
from pathlib import Path
import csv, os, re, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
EVIDENCE = ROOT / 'docs/Player_Feedback_Audit_Evidence'
OUT = ROOT / 'tests/tmp/player_feedback_audit'
BATCHES = {'main': 3600, 'supplementary': 900, 'whatif': 900, 'whatif_spring': 600}
# Change 36 recorded cells (docs/LootFarmer_Change_36_Report.md): every seed wins, inside these time windows.
C36 = {'MIN': (250.0, 270.0), 'REC': (150.0, 165.0)}


def godot(args, timeout, log):
    start = time.time()
    try:
        r = subprocess.run([GODOT, '--headless', '--path', str(ROOT)] + args, capture_output=True, text=True,
                           encoding='utf-8', errors='replace', timeout=timeout)
        out, code = r.stdout + r.stderr, r.returncode
    except subprocess.TimeoutExpired as e:
        out, code = str(e.stdout or ''), -1
    log.write_text(out, encoding='utf-8', newline='\n')
    errors = len(re.findall(r'SCRIPT ERROR', out))
    return code, errors, out, time.time() - start


def run_batch(name, compare):
    csv_path = OUT / f'trials_{name}.csv'
    code, errors, out, secs = godot(['res://tests/player_feedback_audit.tscn', '--', '--probe', '--profile=probe-audit48',
                                     '--no-autosave', '--first-run-complete',
                                     f'--builds=res://docs/Player_Feedback_Audit_Evidence/builds_{name}.json',
                                     f'--csv={csv_path.as_posix()}'], BATCHES[name], OUT / f'trials_{name}.log')
    summary = [l for l in out.splitlines() if l.startswith('PFA_AUDIT rows')]
    ok = errors == 0 and summary != []
    # The main batch has 5 known invalid rows (boss "farm" entries: Focus cannot target bosses), exit 1 by design.
    ok = ok and (code == 0 or (name == 'main' and summary and summary[-1].split()[4] == '5'))
    print(f'{name:14s} {"RUN OK" if ok else "RUN FAIL"} {secs:5.0f}s  {summary[-1] if summary else "(no summary)"}  exit {code}  script_errors {errors}')
    if ok and compare:
        r = subprocess.run([sys.executable, str(ROOT / 'tools/player_feedback_audit_analyze.py'), 'compare',
                            str(EVIDENCE / f'baseline_trials_{name}.csv'), str(csv_path)], capture_output=True, text=True)
        print('   ' + r.stdout.strip().replace('\n', '\n   '))
        ok = r.returncode == 0
    return ok


def crosscheck():
    csv_path = OUT / 'change36_crosscheck.csv'
    code, errors, out, secs = godot(['res://tests/change_36_final_boss_audit.tscn', '--', '--probe', '--profile=probe-audit48x',
                                     '--no-autosave', '--first-run-complete', '--only=MIN,REC', f'--csv={csv_path.as_posix()}'],
                                    1200, OUT / 'change36_crosscheck.log')
    ok = code == 0 and errors == 0 and csv_path.exists()
    rows = list(csv.DictReader(open(csv_path, encoding='utf-8'))) if csv_path.exists() else []
    for build, (lo, hi) in C36.items():
        rs = [r for r in rows if r['id'] == build]
        good = len(rs) == 5 and all(r['result'] == 'win' and lo <= float(r['time']) <= hi for r in rs)
        print(f'change36 {build}: {sum(r["result"] == "win" for r in rs)}/{len(rs)} wins, times {[round(float(r["time"])) for r in rs]} {"PASS" if good else "FAIL"}')
        ok &= good
    checks = [l for l in out.splitlines() if 'AUDIT36_CHECKS' in l]
    print(f'change36 {checks[-1] if checks else "(no checks line)"} exit {code} script_errors {errors} {secs:.0f}s')
    return ok


if __name__ == '__main__':
    names = [a for a in sys.argv[1:] if not a.startswith('--')] or list(BATCHES)
    unknown = [n for n in names if n not in BATCHES]
    if unknown:
        print('unknown batch', unknown, 'choose from', list(BATCHES)); sys.exit(2)
    OUT.mkdir(parents=True, exist_ok=True)
    ok = all([run_batch(n, '--no-compare' not in sys.argv) for n in names])
    if '--crosscheck' in sys.argv:
        ok = crosscheck() and ok
    print('PLAYER_FEEDBACK_AUDIT', 'PASS' if ok else 'FAIL')
    sys.exit(0 if ok else 1)
