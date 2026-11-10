"""Maintained LootFarmer regression suite (Change 11; later changes added their probes, Change 24 the
change_22 and change_24 probes, Change 25 the change_25 probe, Change 26 the change_26 probe and the
export manifest check, Change 27 the change_27 probe, Change 34 the change_34 screenshot-set probe, Change 35
the change_35 review-invitation and targeting-lesson probe, Change 36 the change_36 supply-mastery probe, Change 38
the Localization Batch 01 probe and the rendered-text localization sweep, Change 40 the change_40 language
dropdown and progressive-activation probe, Change 41 the change_41 playtest-corrections probe, Change 42 the
Localization Batch 03 probe, Change 43 the Localization Batch 04 probe, Change 50 the change_50 save-migration and Prestige probe, Change 51 the change_51 weapon ladder and evolution probe, Change 52 the change_52 boss-enhanced weapon probe, Change 53 the change_53 combat probe, Change 54 the change_54 Prestige expansion probe, Change 55 the change_55 contextual hints and layout probe, Change 56 the change_56 economy probe, Change 57 the released-save compatibility probe, Change 58 the progression-update localization probe, Change 61 the change_61 guided-restructure contracts probe). Runs each probe headless, one at a time
(playbook 60.1), with a hard timeout, and counts a run as failed when it exits non-zero, times out
or prints any SCRIPT ERROR (a script error aborts a probe's coroutine before it can quit).

Usage: python tools/run_probes.py [name ...]      (no names = the whole maintained suite)
       python tools/run_probes.py --list
Environment: GODOT = path to the Godot 4.7 console executable (default: the developer laptop path).

Not in this suite on purpose: rendered captures (change_*_capture, stage_overview_capture), the windowed
music playback check (change_16_audio: the audio service never decodes music headless), the
natural-pace pacing_bot and the change_9_balance fixture (balance benchmarks, run deliberately), and
the historical probes listed in docs/LootFarmer_Test_Suite.md, and the non-gating desktop performance
benchmark (tools/run_benchmark.py, Change 24: timings are reported, never asserted), and the packaged-artifact
check (tools/verify_export.py, Change 26: needs an exported AAB/APK or, since Change 40, a PCK), and the windowed
captures (change_40_capture, change_41_capture).
"""
from pathlib import Path
import os, re, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
# name -> timeout in seconds
SUITE = {
    'change_61_probe': 300,
    'change_57_probe': 300,
    'change_56_probe': 180,
    'change_55_probe': 300,
    'change_54_probe': 300,
    'change_53_probe': 300,
    'change_52_probe': 300,
    'change_51_probe': 300,
    'change_50_probe': 300,
    'change_41_probe': 300,
    'change_40_probe': 300,
    'localization_batch01_probe': 300,
    'localization_batch02_probe': 300,
    'localization_batch03_probe': 300,
    'localization_batch04_probe': 300,
    'localization_sweep': 1500,
    'localization_progression_probe': 600,
    'change_36_probe': 180,
    'change_35_probe': 240,
    'change_34_probe': 120,
    'change_27_probe': 180,
    'change_26_probe': 300,
    'change_25_probe': 300,
    'change_24_probe': 240,
    'change_22_probe': 240,
    'change_21_probe': 180,
    'change_20_probe': 180,
    'skill_proximity_probe': 120,
    'change_17_probe': 120,
    'change_17_weather': 120,
    'change_16_probe': 300,
    'change_15_probe': 300,
    'change_14_probe': 300,
    'change_13_probe': 300,
    'change_12_probe': 300,
    'change_12_smoke': 180,
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
    # Change 15 (Playbook 18.10): probes of ordinary play start with the first-profile progression
    # complete; the onboarding probes (change_15_*) cover the progression itself and run without it.
    if not name.startswith('change_15'):
        command.append('--first-run-complete')
    start = time.time()
    try:
        result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
        output, code, timed_out = result.stdout + result.stderr, result.returncode, False
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or b'').decode('utf-8', 'replace') if isinstance(error.stdout, bytes) else (error.stdout or '')
        code, timed_out = -1, True
    if os.environ.get('PROBE_LOG_DIR'):
        log_dir = Path(os.environ['PROBE_LOG_DIR']); log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / (name + '.log')).write_text(output, encoding='utf-8')
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
    # Change 26: the export allowlist and the Release preset must match the current code and data.
    export = subprocess.run([sys.executable, str(ROOT / 'tools/export_manifest.py'), '--check'], capture_output=True, text=True)
    print('%-24s %-7s        %s' % ('export_manifest', 'PASS' if export.returncode == 0 else 'FAIL', (export.stdout.strip().splitlines() or [''])[0]))
    # Change 39: every validated translation catalog against the English source (Playbook 132.5 mechanical checks).
    l10n = subprocess.run([sys.executable, str(ROOT / 'tools/validate_localization.py')], capture_output=True, text=True, encoding='utf-8')
    print('%-24s %-7s        %s' % ('validate_localization', 'PASS' if l10n.returncode == 0 else 'FAIL', (l10n.stdout.strip().splitlines() or [''])[-1]))
    statics = [static.returncode == 0, export.returncode == 0, l10n.returncode == 0]
    results = [run(n, SUITE[n]) for n in names]
    passed = sum(results) + sum(statics)
    print('SUITE %d/%d passed' % (passed, len(results) + len(statics)))
    sys.exit(0 if all(results) and all(statics) else 1)


if __name__ == '__main__':
    main()
