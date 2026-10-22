"""Maintained LootFarmer regression suite (Change 11). Runs each probe headless, one at a time
(playbook 60.1), with a hard timeout, and counts a run as failed when it exits non-zero, times out
or prints any SCRIPT ERROR (a script error aborts a probe's coroutine before it can quit).

Usage: python tools/run_probes.py [name ...]      (no names = the whole maintained suite)
       python tools/run_probes.py --list
Environment: GODOT = path to the Godot 4.7 console executable (default: the developer laptop path).

Not in this suite on purpose: rendered captures (change_*_capture, stage_overview_capture), the
natural-pace pacing_bot and the change_9_balance fixture (balance benchmarks, run deliberately), and
the historical probes listed in docs/LootFarmer_Test_Suite.md.
"""
from pathlib import Path
import os, re, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
# name -> timeout in seconds
SUITE = {
    'change_11_probe': 300,
    'change_11_smoke': 180,
    'change_10_probe': 300,
    'change_9_probe': 300,
    'change_8_probe': 300,
    'change_7_probe': 300,
    'change_6_probe': 300,
    'change_5_probe': 300,
    'campaign_probe': 300,
    'campaign_content_probe': 300,
    'gameplay_probe': 180,
    'ui_probe': 180,
    'inventory_probe': 180,
    'targeting_probe': 180,
    'camera_probe': 180,
    'attack_timing_probe': 180,
    'bootstrap_probe': 180,
    'change_8_walk_probe': 300,
}


def run(name, timeout):
    command = [GODOT, '--headless', '--path', str(ROOT), 'res://tests/%s.tscn' % name, '--',
               '--probe', '--profile=probe-suite-%s' % name, '--no-autosave']
    start = time.time()
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
        output, code, timed_out = result.stdout + result.stderr, result.returncode, False
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or b'').decode('utf-8', 'replace') if isinstance(error.stdout, bytes) else (error.stdout or '')
        code, timed_out = -1, True
    script_errors = len(re.findall(r'SCRIPT ERROR', output))
    summary = [line for line in output.splitlines() if re.search(r'CHECKS|checks=|SMOKE done|_PROBE PASS', line)]
    ok = code == 0 and not timed_out and script_errors == 0 and bool(summary)
    status = 'PASS' if ok else ('TIMEOUT' if timed_out else 'FAIL')
    print('%-24s %-7s %5.0fs  %s%s' % (name, status, time.time() - start, summary[-1].strip() if summary else '(no summary)',
                                     '  script_errors=%d' % script_errors if script_errors else ''))
    if not ok:
        failed = [line for line in output.splitlines() if line.startswith('ERROR:') or 'SCRIPT ERROR' in line][:8]
        for line in failed:
            print('    ' + line)
    return ok


def main():
    if '--list' in sys.argv:
        print('\n'.join(SUITE))
        return
    names = [a for a in sys.argv[1:] if not a.startswith('--')] or list(SUITE)
    unknown = [n for n in names if n not in SUITE]
    if unknown:
        raise SystemExit('not in the maintained suite: %s' % unknown)
    static = subprocess.run([sys.executable, str(ROOT / 'tools/validate_campaign_source.py')], capture_output=True, text=True)
    print('%-24s %-7s        %s' % ('validate_campaign_source', 'PASS' if static.returncode == 0 else 'FAIL', static.stdout.strip().splitlines()[0] if static.stdout else ''))
    results = [run(n, SUITE[n]) for n in names]
    passed = sum(results) + (static.returncode == 0)
    print('SUITE %d/%d passed' % (passed, len(results) + 1))
    sys.exit(0 if all(results) and static.returncode == 0 else 1)


if __name__ == '__main__':
    main()
