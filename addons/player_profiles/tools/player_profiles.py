"""Player Profiles package tool (game-independent; Python 3.9+, standard library only).

  python player_profiles.py manifest  --package <pkg dir>                 write PACKAGE_FILES.sha256
  python player_profiles.py verify    --package <pkg dir>                 files == PACKAGE_FILES.sha256
  python player_profiles.py install   --source <pkg dir> --project <godot project> [--overwrite]
  python player_profiles.py status    --project <godot project> [--source <pkg dir>]
  python player_profiles.py isolation --package <pkg dir> [--forbid word,word]
  python player_profiles.py selftest  --godot <console exe> [--project <godot project> | --blank]
  python player_profiles.py run       --godot <exe> --project <dir> --integration res://... --batch <id>
                                      [--profiles active,casual] [--seeds 1,2] [-- <extra runner args>]
  python player_profiles.py report    --runs <folder with */summary.json>

install copies the package into <project>/addons/player_profiles/ and pins it in <project>/player_profiles.lock.json
(version + sha256 per file); it refuses to overwrite a differing installed file unless --overwrite. status checks
installed == lock (== source when given). isolation fails on any res:// path outside the package and on any
--forbid word in package code. selftest --blank copies the package alone into an empty temporary Godot project and
runs its self-test there (proof that it depends on nothing else). run is a sequential generic runner (one Godot
process at a time, hard timeout). report writes framework_comparison.md/.csv from player-profiles.summary/1 files.
"""
from pathlib import Path
import argparse, csv, hashlib, json, os, re, shutil, subprocess, sys, tempfile, time

PKG_NAME = 'player_profiles'
CODE_SUFFIXES = {'.gd', '.tscn', '.json', '.py', '.cfg', '.tres'}
SKIP = {'PACKAGE_FILES.sha256'}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def package_files(pkg):
    pkg = Path(pkg)
    out = []
    for p in sorted(pkg.rglob('*')):
        if p.is_dir() or '__pycache__' in p.parts or p.suffix in ('.uid', '.pyc', '.import') or p.name in SKIP:
            continue
        out.append(p.relative_to(pkg).as_posix())
    return out


def read_manifest(pkg):
    path = Path(pkg) / 'PACKAGE_FILES.sha256'
    if not path.exists():
        return None
    rows = {}
    for line in path.read_text(encoding='utf-8').splitlines():
        if line.strip():
            digest, name = line.split('  ', 1)
            rows[name] = digest
    return rows


def cmd_manifest(a):
    pkg = Path(a.package)
    lines = [f'{sha(pkg / f)}  {f}' for f in package_files(pkg)]
    (pkg / 'PACKAGE_FILES.sha256').write_bytes(('\n'.join(lines) + '\n').encode())
    print(f'manifest: {len(lines)} files, version {(pkg / "VERSION").read_text().strip()}')
    return True


def cmd_verify(a):
    pkg = Path(a.package)
    rows = read_manifest(pkg)
    if rows is None:
        print('no PACKAGE_FILES.sha256');return False
    files = package_files(pkg)
    bad = [f for f in files if rows.get(f) != sha(pkg / f)] + [f for f in rows if f not in files]
    for f in bad:
        print('MISMATCH', f)
    print(f'verify: {len(files)} files, {len(bad)} mismatches')
    return not bad


def cmd_install(a):
    src, proj = Path(a.source), Path(a.project)
    if not (proj / 'project.godot').exists():
        print('not a Godot project:', proj);return False
    rows = read_manifest(src)
    if rows is None or not cmd_verify(argparse.Namespace(package=src)):
        print('source package does not verify; refusing to install');return False
    dest = proj / 'addons' / PKG_NAME
    conflicts = [f for f in rows if (dest / f).exists() and sha(dest / f) != rows[f]]
    if conflicts and not a.overwrite:
        for f in conflicts:
            print('DIFFERS (use --overwrite for a deliberate update):', f)
        return False
    for f in rows:
        (dest / f).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src / f, dest / f)
    shutil.copyfile(src / 'PACKAGE_FILES.sha256', dest / 'PACKAGE_FILES.sha256')
    lock = {'package': 'Godot-Player-Profiles', 'version': (src / 'VERSION').read_text().strip(), 'install_path': f'res://addons/{PKG_NAME}/',
            'source': str(src), 'file_sha256': rows}
    (proj / 'player_profiles.lock.json').write_bytes((json.dumps(lock, indent=2) + '\n').encode())
    print(f'installed {len(rows)} files into {dest} (version {lock["version"]}); lock written')
    return True


def cmd_status(a):
    proj = Path(a.project)
    lock_path = proj / 'player_profiles.lock.json'
    if not lock_path.exists():
        print('no player_profiles.lock.json');return False
    lock = json.loads(lock_path.read_text(encoding='utf-8'))
    dest = proj / 'addons' / PKG_NAME
    problems = [f'installed {f} differs from lock' for f, d in lock['file_sha256'].items() if not (dest / f).exists() or sha(dest / f) != d]
    extra = [f for f in package_files(dest) if f not in lock['file_sha256']]
    problems += [f'installed {f} is not in the lock' for f in extra]
    if a.source:
        rows = read_manifest(a.source) or {}
        problems += [f'source {f} differs from lock' for f in set(rows) | set(lock['file_sha256']) if rows.get(f) != lock['file_sha256'].get(f)]
    for p in problems:
        print(p)
    print(f'status: version {lock["version"]}, {len(lock["file_sha256"])} files, {len(problems)} problems' + (' (installed == lock == source)' if a.source and not problems else ''))
    return not problems


def cmd_isolation(a):
    pkg = Path(a.package)
    forbid = [w.strip().lower() for w in (a.forbid or '').split(',') if w.strip()]
    bad = []
    for f in package_files(pkg):
        p = pkg / f
        if p.suffix not in CODE_SUFFIXES:
            continue
        text = p.read_text(encoding='utf-8', errors='replace')
        for m in re.finditer(r'res://[A-Za-z0-9_./-]*', text):
            if not m.group(0).startswith(f'res://addons/{PKG_NAME}/') and m.group(0) not in ('res://', 'res://addons/', 'res://.../integration.gd', 'res://...'):
                bad.append(f'{f}: {m.group(0)}')
        if re.search(r'^\s*class_name\s', text, re.M):
            bad.append(f'{f}: declares a global class_name')
        low = text.lower()
        # The self-test holds the forbidden vocabulary it checks profiles.json against; it is exempt from the word scan.
        for w in ([] if f == 'tests/selftest.gd' else forbid):
            if w in low:
                bad.append(f'{f}: mentions "{w}"')
    for b in bad:
        print('ISOLATION', b)
    print(f'isolation: {len(package_files(pkg))} files scanned, {len(bad)} problems')
    return not bad


def godot_run(godot, project, scene, args, timeout):
    cmd = [godot, '--headless', '--path', str(project), scene, '--'] + args
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
        return r.returncode, r.stdout + r.stderr, False
    except subprocess.TimeoutExpired as e:
        return -1, (e.stdout or b'').decode('utf-8', 'replace') if isinstance(e.stdout, bytes) else (e.stdout or ''), True


def cmd_selftest(a):
    pkg = Path(__file__).resolve().parents[1]
    if a.blank:
        root = Path(tempfile.mkdtemp(prefix='pp_blank_'))
        (root / 'project.godot').write_bytes(b'config_version=5\n\n[application]\n\nconfig/name="Player Profiles blank test"\n')
        shutil.copytree(pkg, root / 'addons' / PKG_NAME, ignore=shutil.ignore_patterns('__pycache__', '*.uid'))
        project = root
        # First open imports the project (creates .godot/); then the self-test runs.
        subprocess.run([a.godot, '--headless', '--path', str(project), '--import'], capture_output=True, timeout=300)
    else:
        project = Path(a.project)
    start = time.time()
    code, out, timed_out = godot_run(a.godot, project, f'res://addons/{PKG_NAME}/tests/selftest.tscn', [], 600)
    line = [l for l in out.splitlines() if 'PLAYER_PROFILES_SELFTEST' in l]
    errors = len(re.findall('SCRIPT ERROR', out))
    for l in line[-12:]:
        print(l)
    ok = code == 0 and not timed_out and errors == 0 and bool(line) and 'PASS' in line[-1]
    print(f'selftest {"PASS" if ok else "FAIL"} in {"a blank project " + str(project) if a.blank else str(project)} ({time.time() - start:.1f}s, script errors {errors})')
    if a.blank and ok:
        shutil.rmtree(project, ignore_errors=True)
    return ok


def cmd_run(a, extra):
    project = Path(a.project)
    base = project / 'tests' / 'tmp' / 'player_profiles' / a.batch
    base.mkdir(parents=True, exist_ok=True)
    (project / 'tests' / 'tmp' / 'player_profiles' / '.gdignore').touch()
    ok = True
    for profile in a.profiles.split(','):
        for seed in a.seeds.split(','):
            out = base / f'{profile}_s{seed}'
            out.mkdir(parents=True, exist_ok=True)
            args = [f'--integration={a.integration}', f'--player-profile={profile}', f'--seed={seed}', f'--output={out.resolve().as_posix()}'] + extra
            code, log, timed_out = godot_run(a.godot, project, f'res://addons/{PKG_NAME}/runner/run_scene.tscn', args, a.timeout)
            (out / 'godot.log').write_bytes(log.encode())
            sentinel = [l for l in log.splitlines() if l.startswith('PLAYTEST_RESULT')]
            good = code == 0 and not timed_out and 'SCRIPT ERROR' not in log and bool(sentinel)
            ok = ok and good
            print(f'{out.name:28s} {"OK  " if good else "FAIL"} {(sentinel[-1] if sentinel else "(no result line)")[:160]}', flush=True)
    cmd_report(argparse.Namespace(runs=str(base)))
    return ok


# ------------------------------------------------------------------------------------------------ generic report
REPORT_COLUMNS = ['run', 'profile', 'seed', 'game', 'strategy', 'profile_sha', 'until', 'active_h', 'offline_h', 'calendar_h', 'sessions', 'stop',
                  'decisions', 'decisions_per_active_h', 'deliberations_per_active_h', 'mistakes', 'switches', 'holds', 'urgent_interrupts',
                  'save_for_goal', 'rejected', 'failed_activities', 'invalid_options', 'unsupported_intents', 'time_share_by_intent',
                  'decisions_by_intent', 'milestones', 'first_milestones', 'economy_spent_share', 'automation_owned', 'longest_stall_min', 'diagnosis']


def _cell(v):
    if v is None:
        return 'not_measured'
    return v


def diagnose(s):
    """A starting classification of a run's stall/quality signal (never a verdict)."""
    stop = s.get('stop_reason')
    d = s.get('decisions') or {}
    if stop in ('action_error', 'engine_failure', 'contract_error', 'wall_timeout'):
        return 'tool/adapter failure: read godot.log and the last events'
    if d.get('invalid_options'):
        return 'adapter contract problem: invalid options were offered'
    total = max(1, d.get('decisions', 0))
    rejected = (d.get('by_status') or {}).get('rejected', 0)
    if rejected / total > 0.3:
        return 'policy/adapter problem: many actions rejected by the game'
    secs = d.get('activity_seconds') or {}
    act = max(1.0, s.get('active_seconds') or 0)
    if secs.get('none', 0) / act > 0.2:
        return 'policy/adapter problem: no activity offered for long stretches'
    stall = (s.get('longest_stall') or {}).get('seconds', 0)
    if stall >= 1800:
        refusals = d.get('refusals') or {}
        gated = sum(v for k, v in refusals.items() if k.endswith('|not_ready') or k.endswith('|unaffordable'))
        if gated >= sum(refusals.values()) * 0.5:
            return 'possible gameplay bottleneck: progress waited on readiness/affordability gates (check the game, then the adapter signals)'
        return 'stall of unclear cause: inspect trace/events in that window'
    return 'no stall signal'


def report_row(s, folder):
    d = s.get('decisions') or {}
    g = s.get('generic') or {}
    act = s.get('active_seconds') or 0
    secs = d.get('activity_seconds') or {}
    econ = g.get('economy')
    if isinstance(econ, dict):
        econ_txt = ' '.join(f'{k}:{(v.get("spent", 0) / v["earned"]):.2f}' if v.get('earned') else f'{k}:not_measured' for k, v in sorted(econ.items()))
    else:
        econ_txt = econ or 'not_measured'
    ms = g.get('milestones') or []
    integ = s.get('integration') or {}
    return {
        'run': Path(folder).name, 'profile': s.get('profile'), 'seed': s.get('seed'), 'game': integ.get('game'),
        'strategy': integ.get('strategy_version'), 'profile_sha': (s.get('profile_sha256') or '')[:12], 'until': s.get('until'),
        'active_h': round(act / 3600, 3), 'offline_h': round((s.get('offline_seconds') or 0) / 3600, 3),
        'calendar_h': round((s.get('calendar_seconds') or 0) / 3600, 3), 'sessions': g.get('sessions'), 'stop': s.get('stop_reason'),
        'decisions': d.get('decisions'), 'decisions_per_active_h': g.get('decisions_per_active_hour'),
        'deliberations_per_active_h': g.get('deliberations_per_active_hour'), 'mistakes': d.get('mistakes'), 'switches': d.get('switches'),
        'holds': d.get('holds'), 'urgent_interrupts': d.get('urgent_interrupts'), 'save_for_goal': d.get('save_for_goal'),
        'rejected': (d.get('by_status') or {}).get('rejected', 0), 'failed_activities': (d.get('by_status') or {}).get('activity_failed', 0),
        'invalid_options': d.get('invalid_options'), 'unsupported_intents': ' '.join(d.get('unsupported_intents') or []) or '-',
        'time_share_by_intent': ' '.join(f'{k}:{v / act:.2f}' for k, v in sorted(secs.items(), key=lambda kv: -kv[1]) if act and v / act >= 0.01),
        'decisions_by_intent': ' '.join(f'{k}:{v}' for k, v in sorted((d.get('by_intent') or {}).items(), key=lambda kv: -kv[1])),
        'milestones': len(ms), 'first_milestones': ', '.join(f'{m["key"]}@{m["t"] / 60:.1f}m' for m in ms[:4]) or '-',
        'economy_spent_share': econ_txt, 'automation_owned': g.get('automation_owned', 'not_measured'),
        'longest_stall_min': round(((s.get('longest_stall') or {}).get('seconds') or 0) / 60, 1), 'diagnosis': diagnose(s)}


def framework_report(folder):
    folder = Path(folder)
    rows = []
    for path in sorted(folder.glob('*/summary.json')):
        s = json.loads(path.read_text(encoding='utf-8'))
        if str(s.get('schema', '')).startswith('player-profiles.summary/'):
            rows.append(report_row(s, path.parent))
    if not rows:
        return None
    with open(folder / 'framework_comparison.csv', 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=REPORT_COLUMNS, lineterminator='\n')
        w.writeheader()
        for r in rows:
            w.writerow({k: _cell(r[k]) for k in REPORT_COLUMNS})
    short = ['run', 'until', 'active_h', 'offline_h', 'calendar_h', 'sessions', 'stop', 'decisions_per_active_h', 'mistakes', 'switches',
             'save_for_goal', 'failed_activities', 'unsupported_intents', 'time_share_by_intent', 'economy_spent_share', 'automation_owned',
             'longest_stall_min', 'diagnosis']
    md = ['# Player Profiles: generic comparison', '',
          'Framework metrics with a stable schema across games (player-profiles.summary/1). `not_measured` = not recorded; '
          '`unsupported` = the game declared that capability absent (never a zero). Active, offline and calendar hours are '
          'separate: runs with a calendar horizon give profiles the same days but very different play time; compare like '
          'with like. These are simulated behaviour presets, not player populations, and say nothing about UI comprehension or fun. '
          'The diagnosis column is a starting point, not a verdict.', '',
          '| ' + ' | '.join(short) + ' |', '|' + '---|' * len(short)]
    for r in rows:
        md.append('| ' + ' | '.join(str(_cell(r[c])) for c in short) + ' |')
    md += ['', 'Decisions by intent per run:', '']
    for r in rows:
        md.append(f"- {r['run']} ({r['game']}, {r['strategy']}, profile {r['profile_sha']}): {r['decisions_by_intent']}; first milestones: {r['first_milestones']}")
    (folder / 'framework_comparison.md').write_bytes(('\n'.join(md) + '\n').encode())
    return len(rows)


def cmd_report(a):
    n = framework_report(a.runs)
    print(f'report: {n or 0} framework runs -> framework_comparison.md/.csv in {a.runs}')
    return bool(n)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('command', choices=['manifest', 'verify', 'install', 'status', 'isolation', 'selftest', 'run', 'report'])
    ap.add_argument('--package'); ap.add_argument('--source'); ap.add_argument('--project'); ap.add_argument('--overwrite', action='store_true')
    ap.add_argument('--forbid'); ap.add_argument('--godot', default=os.environ.get('GODOT', 'godot')); ap.add_argument('--blank', action='store_true')
    ap.add_argument('--integration'); ap.add_argument('--batch', default='pp'); ap.add_argument('--profiles', default='active,casual,idle,beginner,collector,speedrunner,completionist')
    ap.add_argument('--seeds', default='1'); ap.add_argument('--timeout', type=float, default=900); ap.add_argument('--runs')
    argv = sys.argv[1:]
    extra = []
    if '--' in argv:
        i = argv.index('--'); extra = argv[i + 1:]; argv = argv[:i]
    a = ap.parse_args(argv)
    fn = {'manifest': cmd_manifest, 'verify': cmd_verify, 'install': cmd_install, 'status': cmd_status, 'isolation': cmd_isolation,
          'selftest': cmd_selftest, 'report': cmd_report}.get(a.command)
    ok = cmd_run(a, extra) if a.command == 'run' else fn(a)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
