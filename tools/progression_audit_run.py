"""Progression what-if audit runner (Change 49 / B0; non-gating, Playbook 60.1: one Godot at a time).

  python tools/progression_audit_run.py [batch ...] [--no-compare] [--prestige-diff]

Runs res://tests/progression_audit.tscn (the consolidated audit's what-if harness, promoted from tests/tmp)
with the recorded build files and patches of docs/Consolidated_Audit_Evidence/run_all.sh and run_h.sh, writes
tests/tmp/progression_audit/<batch>.csv + .log (git-ignored) and, unless --no-compare, compares each CSV field by
field with the recorded reference docs/Consolidated_Audit_Evidence/<batch>.csv
(tools/player_feedback_audit_analyze.py compare). The references were recorded on the pre-implementation game
(commit 3dd2eab, catalog unchanged): once a later batch changes the catalog or the rules, a comparison is
expected to differ and the run measures the new game instead.

--prestige-diff also runs res://tests/prestige_field_diff.tscn (real Prestige transaction, every state field
classified KEPT / RESET / OTHER) and prints its classification.
Exit 0 only when every run is clean (exit 0, no SCRIPT ERROR) and every requested comparison passes.
Environment: GODOT = Godot 4.7 console executable (same default as tools/run_probes.py).
"""
from pathlib import Path
import os, re, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
EVIDENCE = ROOT / 'docs/Consolidated_Audit_Evidence'
OUT = ROOT / 'tests/tmp/progression_audit'
H_ONLY = 'N7_arr,N7_mid,N7_rdy,N7_rdy_P1,N7_obs50,N8_arr,N8_obs60,N8_obs100,N8_obs100_P1,N7_rdy_sword,N6_evo,N6_rdy'
# batch -> (builds file, patches, --only, timeout s); exactly the recorded commands (run_all.sh, run_h.sh).
BATCHES = {
    's3ctl_ind': ('builds_s3control', 's3aggro_individual', '', 1500),
    's3ctl_pas': ('builds_s3control', 's3aggro_passive', '', 1500),
    'lad_CUR': ('builds_ladder', 'tiers_CUR,s3aggro_individual', '', 2400),
    'lad_A19': ('builds_ladder', 'tiers_A19,s3aggro_individual', '', 2400),
    'lad_B22': ('builds_ladder', 'tiers_B22,s3aggro_individual', '', 2400),
    'lad_A19_s3group': ('builds_ladder', 'tiers_A19', 'N3_arr,N3_mid,N3_rdy,N3_rdy_P1,N3_evo,N3_rdy_sword', 900),
    'tune_A19': ('builds_tuning', 'tiers_A19,s3aggro_individual', '', 3600),
    'lad_H24': ('builds_ladder', 'tiers_H24,s3aggro_individual', H_ONLY, 2000),
    'lad_H28': ('builds_ladder', 'tiers_H28,s3aggro_individual', H_ONLY, 2000),
}


def godot(args, timeout, log):
    start = time.time()
    try:
        r = subprocess.run([GODOT, '--headless', '--path', str(ROOT)] + args, capture_output=True, text=True,
                           encoding='utf-8', errors='replace', timeout=timeout)
        out, code = r.stdout + r.stderr, r.returncode
    except subprocess.TimeoutExpired as e:
        out, code = str(e.stdout or ''), -1
    log.write_text(out, encoding='utf-8', newline='\n')
    return code, len(re.findall(r'SCRIPT ERROR', out)), out, time.time() - start


def run_batch(name, compare):
    builds, patch, only, timeout = BATCHES[name]
    csv_path = OUT / f'{name}.csv'
    args = ['res://tests/progression_audit.tscn', '--', '--probe', '--profile=probe-audit49', '--no-autosave',
            '--first-run-complete', f'--builds=res://docs/Consolidated_Audit_Evidence/{builds}.json',
            f'--csv={csv_path.as_posix()}', f'--patch={patch}'] + ([f'--only={only}'] if only else [])
    code, errors, out, secs = godot(args, timeout, OUT / f'{name}.log')
    summary = [l for l in out.splitlines() if l.startswith('PFA_AUDIT rows')]
    # s3ctl batches hold one known invalid row (FARM_S3 boss entry: Focus cannot target bosses), exit 1 by design.
    invalid = int(summary[-1].split()[4]) if summary else -1
    ok = errors == 0 and summary != [] and (code == 0 or (name.startswith('s3ctl') and invalid == 1))
    print(f'{name:16s} {"RUN OK" if ok else "RUN FAIL"} {secs:5.0f}s  {summary[-1] if summary else "(no summary)"}  exit {code}  script_errors {errors}')
    if ok and compare:
        r = subprocess.run([sys.executable, str(ROOT / 'tools/player_feedback_audit_analyze.py'), 'compare',
                            str(EVIDENCE / f'{name}.csv'), str(csv_path)], capture_output=True, text=True)
        print('   ' + r.stdout.strip().replace('\n', '\n   '))
        ok = r.returncode == 0
    return ok


def prestige_diff():
    code, errors, out, secs = godot(['res://tests/prestige_field_diff.tscn', '--', '--probe', '--profile=probe-audit49p',
                                     '--no-autosave', '--first-run-complete'], 300, OUT / 'prestige_diff.log')
    fields = [l for l in out.splitlines() if l.startswith('C49P FIELD')]
    for line in fields:
        print('   ' + line.split(' | ')[0])
    ok = code == 0 and errors == 0 and any('C49P DONE' in l for l in out.splitlines())
    print(f'prestige_diff {"RUN OK" if ok else "RUN FAIL"} {secs:.0f}s fields {len(fields)} exit {code} script_errors {errors}')
    return ok


if __name__ == '__main__':
    names = [a for a in sys.argv[1:] if not a.startswith('--')]
    unknown = [n for n in names if n not in BATCHES]
    if unknown:
        print('unknown batch', unknown, 'choose from', list(BATCHES)); sys.exit(2)
    if not names and '--prestige-diff' not in sys.argv:
        names = ['lad_A19']
    OUT.mkdir(parents=True, exist_ok=True)
    ok = all([run_batch(n, '--no-compare' not in sys.argv) for n in names])
    if '--prestige-diff' in sys.argv:
        ok = prestige_diff() and ok
    print('PROGRESSION_AUDIT', 'PASS' if ok else 'FAIL')
    sys.exit(0 if ok else 1)
