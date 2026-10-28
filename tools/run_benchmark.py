"""Non-gating desktop performance benchmark (Change 24, Playbook 48.1). Runs tests/performance_benchmark.gd
windowed at 540x960 on an isolated probe profile (--no-autosave), with a hard timeout, and writes
tests/tmp/benchmark/report.txt (ignored by Git). Nothing is asserted: the numbers rank desktop
hotspots and are not Android measurements. Not part of tools/run_probes.py.

Usage: python tools/run_benchmark.py [--out PATH]
Environment: GODOT = path to the Godot 4.7 console executable (default: the developer laptop path).
"""
from pathlib import Path
import os, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
TIMEOUT = 900


def main():
    out = ROOT / 'tests/tmp/benchmark/report.txt'
    if '--out' in sys.argv and sys.argv.index('--out') + 1 < len(sys.argv):
        out = Path(sys.argv[sys.argv.index('--out') + 1]).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    command = [GODOT, '--path', str(ROOT), '--resolution', '540x960', '-s', str(ROOT / 'tests/performance_benchmark.gd'), '--',
               '--probe', '--profile=probe-benchmark', '--no-autosave', '--first-run-complete', '--out=' + str(out)]
    start = time.time()
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=TIMEOUT)
        output, code = result.stdout + result.stderr, result.returncode
    except subprocess.TimeoutExpired:
        output, code = '', -1
    (out.parent / 'godot_output.log').write_bytes(output.encode('utf-8'))
    lines = [line for line in output.splitlines() if line.split(' ', 1)[0] in
             ('ENV', 'BUILD', 'STARTUP', 'PERF', 'LEAK_CHECK', 'STAGE_SWITCH', 'SAVE', 'HUD', 'SIM', 'BENCHMARK', 'BENCHMARK_ERROR')]
    print('\n'.join(lines))
    errors = output.count('SCRIPT ERROR')
    done = any(line.startswith('BENCHMARK done') for line in lines)
    print('benchmark %s in %.0fs (exit %d, script errors %d); report: %s' % ('finished' if done else 'INCOMPLETE', time.time() - start, code, errors, out))
    sys.exit(0 if done and errors == 0 else 1)


if __name__ == '__main__':
    main()
