"""Player-profile playtest runner (Phase 1; non-gating, Playbook 60.1: one Godot process at a time).

Runs res://tests/playtest/player_profile_run.tscn headless (the real LootSimulation played by a policy from a
fresh isolated profile), under a hard process timeout, and builds the comparison sheet from what the game recorded.
Python never computes a game outcome: it only starts runs, checks them and summarizes their files.

  python tools/player_profile_run.py run --batch <id> [--player-profile active] [--seeds 1,2,3]
         [--active-minutes 60 | --until first-prestige --max-active-minutes 240]
         [--max-wall-seconds 600] [--stall-minutes 30] [--trace] [--label name]
  python tools/player_profile_run.py determinism --batch <id> [same run options, one seed]
  python tools/player_profile_run.py report --batch <id>

Outputs (git-ignored): tests/tmp/player_profiles/<batch>/<profile>_s<seed>_<label>/{events.jsonl, summary.json,
trace.jsonl, godot.log} and, per batch, comparison.csv, comparison.md and measurements.md.
A run is accepted only when Godot exits 0, prints no SCRIPT ERROR and ends with the PLAYTEST_RESULT line.
Exit code: 0 when every requested run was sound (a stall or a spent time budget is a finding, not a failure) and,
for `determinism`, both digests match; 1 otherwise.
Environment: GODOT = Godot 4.7 console executable (same default as tools/run_probes.py).
"""
from pathlib import Path
import argparse, csv, hashlib, json, os, re, statistics, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
BASE = ROOT / 'tests/tmp/player_profiles'
SCENE = 'res://tests/playtest/player_profile_run.tscn'
COLUMNS = ['profile', 'policy_version', 'seed', 'label', 'target_active_hours', 'actual_active_hours', 'offline_hours',
           'stop_reason', 'final_map', 'highest_stage_unlocked', 'player_level', 'first_boss_time_min',
           'first_prestige_ready_time_min', 'first_prestige_completed_time_min', 'prestiges', 'cards', 'deaths',
           'boss_attempts', 'boss_wins', 'kills', 'upgrades_bought', 'gear_progress', 'coins_earned', 'coins_spent',
           'gems_earned', 'gems_spent', 'mission_claims', 'longest_stall_minutes', 'wall_seconds', 'speed_x',
           'events_sha256', 'state_sha256', 'evidence_file']


def git_state():
    def git(*a):
        return subprocess.run(['git', *a], cwd=ROOT, capture_output=True, text=True).stdout
    dirty = git('status', '--porcelain', '--untracked-files=no')
    return {'commit': git('rev-parse', 'HEAD').strip(), 'dirty_worktree': bool(dirty.strip()),
            'dirty_files': [l[3:] for l in dirty.splitlines() if l.strip()]}


def write(path, text):
    path.write_bytes(text.encode('utf-8'))


def run_one(batch, profile, seed, label, a):
    out = BASE / batch / f'{profile}_s{seed}_{label}'
    out.mkdir(parents=True, exist_ok=True)
    (BASE / '.gdignore').touch()
    for name in ['events.jsonl', 'summary.json', 'trace.jsonl', 'godot.log']:
        if (out / name).exists():
            (out / name).unlink()
    save_profile = re.sub(r'[^a-z0-9-]', '-', f'probe-pp-{batch}-{profile}-s{seed}-{label}'.lower())[:64]
    args = [GODOT, '--headless', '--path', str(ROOT), SCENE, '--', '--probe', '--no-autosave', f'--profile={save_profile}',
            f'--player-profile={profile}', f'--seed={seed}', f'--max-wall-seconds={a.max_wall_seconds}',
            f'--stall-minutes={a.stall_minutes}', f'--output={out.as_posix()}']
    if a.until == 'duration':
        args += [f'--active-minutes={a.active_minutes}']
    else:
        args += [f'--until={a.until}', f'--max-active-minutes={a.max_active_minutes}']
    if a.trace:
        args += ['--trace']
    start = time.time()
    timed_out = False
    try:
        r = subprocess.run(args, capture_output=True, text=True, encoding='utf-8', errors='replace',
                           timeout=a.max_wall_seconds + 120)
        output, code = r.stdout + r.stderr, r.returncode
    except subprocess.TimeoutExpired as e:
        output = (e.stdout or b'').decode('utf-8', 'replace') if isinstance(e.stdout, bytes) else (e.stdout or '')
        code, timed_out = -1, True
    wall = time.time() - start
    write(out / 'godot.log', output)
    script_errors = len(re.findall(r'SCRIPT ERROR', output))
    sentinel = [l for l in output.splitlines() if l.startswith('PLAYTEST_RESULT')]
    summary_path = out / 'summary.json'
    summary = json.loads(summary_path.read_text(encoding='utf-8')) if summary_path.exists() else None
    if script_errors:
        status = 'script_error'
    elif timed_out:
        status = 'wall_timeout'
    elif not sentinel or summary is None:
        status = 'engine_failure'
    else:
        status = summary['stop_reason']
    ok = script_errors == 0 and not timed_out and bool(sentinel) and summary is not None and code == 0
    meta = {'run_id': f'{batch}/{out.name}', 'batch': batch, 'label': label, 'runner_status': status, 'runner_ok': ok,
            'exit_code': code, 'script_errors': script_errors, 'process_wall_seconds': round(wall, 2),
            'requested': {'until': a.until, 'active_minutes': a.active_minutes, 'max_active_minutes': a.max_active_minutes,
                          'max_wall_seconds': a.max_wall_seconds, 'stall_minutes': a.stall_minutes, 'trace': a.trace},
            'game_version': git_state()}
    if summary is None:
        summary = {'profile': profile, 'seed': seed, 'stop_reason': status, 'ok': False}
    summary['runner'] = meta
    write(summary_path, json.dumps(summary, indent=2) + '\n')
    line = sentinel[-1] if sentinel else '(no PLAYTEST_RESULT line)'
    print(f'{out.name:34s} {"OK  " if ok else "FAIL"} {status:26s} {wall:6.1f}s  {line[:150]}')
    if not ok:
        for l in [l for l in output.splitlines() if 'SCRIPT ERROR' in l or l.startswith('ERROR:')][:8]:
            print('    ' + l[:200])
    return ok, summary, out


def minutes(value):
    return None if value is None else round(float(value) / 60.0, 2)


def row_of(summary, out):
    g = summary.get('game') or {}
    cur = g.get('currency') or {}
    eq = g.get('equipment') or {}
    attempts = g.get('boss_attempts') or []
    first_boss = min((g.get('boss_first_kill_times_s') or {}).values(), default=None)
    requested = summary.get('runner', {}).get('requested', {})
    target = requested.get('active_minutes') if requested.get('until') == 'duration' else requested.get('max_active_minutes')

    def gear():
        if not eq:
            return None
        w, o = eq.get('weapon', {}), eq.get('outfit', {})
        return f"{w.get('id') or 'none'}^{w.get('merge', 0)} T{w.get('tier', 0)} | {o.get('id') or 'none'}^{o.get('merge', 0)} T{o.get('tier', 0)}"

    return {
        'profile': summary.get('profile'), 'policy_version': summary.get('policy_version'), 'seed': summary.get('seed'),
        'label': summary.get('runner', {}).get('label'),
        'target_active_hours': None if target is None else round(float(target) / 60.0, 3),
        'actual_active_hours': None if 'active_seconds' not in summary else round(summary['active_seconds'] / 3600.0, 3),
        'offline_hours': None if 'offline_seconds' not in summary else round(summary['offline_seconds'] / 3600.0, 3),
        'stop_reason': summary.get('stop_reason'), 'final_map': g.get('stage'),
        'highest_stage_unlocked': g.get('highest_stage_unlocked'), 'player_level': g.get('player_level'),
        'first_boss_time_min': minutes(first_boss),
        'first_prestige_ready_time_min': minutes(g.get('first_prestige_ready_time_s')),
        'first_prestige_completed_time_min': minutes(g.get('first_prestige_completed_time_s')),
        'prestiges': g.get('prestiges'), 'cards': ' '.join(g.get('cards') or []) if g else None,
        'deaths': g.get('deaths'), 'boss_attempts': len(attempts) if g else None,
        'boss_wins': sum(1 for x in attempts if x.get('outcome') == 'win') if g else None,
        'kills': g.get('kills_total'), 'upgrades_bought': g.get('upgrades_bought'), 'gear_progress': gear(),
        'coins_earned': (cur.get('coins') or {}).get('earned_total'), 'coins_spent': (cur.get('coins') or {}).get('spent_total'),
        'gems_earned': (cur.get('gems') or {}).get('earned_total'), 'gems_spent': (cur.get('gems') or {}).get('spent_total'),
        'mission_claims': (g.get('counts') or {}).get('mission_claims'),
        'longest_stall_minutes': None if 'longest_stall' not in summary else round(summary['longest_stall']['seconds'] / 60.0, 2),
        'wall_seconds': (summary.get('process') or {}).get('wall_seconds'), 'speed_x': (summary.get('process') or {}).get('speed_x'),
        'events_sha256': (summary.get('events_sha256') or '')[:16] or None, 'state_sha256': (summary.get('state_sha256') or '')[:16] or None,
        'evidence_file': out.relative_to(ROOT).as_posix() + '/summary.json',
    }


def cell(value):
    return 'not_measured' if value is None else str(value)


AGGREGATE = ['player_level', 'first_boss_time_min', 'first_prestige_ready_time_min', 'first_prestige_completed_time_min',
             'deaths', 'kills', 'upgrades_bought', 'coins_earned', 'coins_spent', 'gems_earned', 'gems_spent',
             'longest_stall_minutes', 'wall_seconds', 'speed_x']


def report(batch):
    folder = BASE / batch
    rows, summaries = [], []
    for path in sorted(folder.glob('*/summary.json')):
        summary = json.loads(path.read_text(encoding='utf-8'))
        summaries.append((summary, path.parent))
        rows.append(row_of(summary, path.parent))
    if not rows:
        print('no runs in', folder)
        return False
    # Aggregate rows: same profile, policy and requested horizon, several seeds. Median and range of these bot runs
    # only: never a distribution of real players.
    groups = {}
    for r in rows:
        if r['label'] and r['label'].startswith('repeat'):
            continue
        groups.setdefault((r['profile'], r['policy_version'], r['label'], r['target_active_hours']), []).append(r)
    aggregates = []
    for (profile, version, label, target), members in groups.items():
        if len({m['seed'] for m in members}) < 2:
            continue
        agg = {c: None for c in COLUMNS}
        agg.update({'profile': profile, 'policy_version': version, 'seed': 'median[min..max] of seeds ' + ','.join(str(m['seed']) for m in members),
                    'label': label, 'target_active_hours': target, 'stop_reason': '/'.join(sorted({str(m['stop_reason']) for m in members})),
                    'evidence_file': 'aggregate of the rows above (bot runs, not a player distribution)'})
        for c in AGGREGATE:
            values = [m[c] for m in members if isinstance(m[c], (int, float))]
            if values:
                missing = len(members) - len(values)
                agg[c] = f'{statistics.median(values):g} [{min(values):g}..{max(values):g}]' + (f' ({missing} not reached)' if missing else '')
        aggregates.append(agg)
    with open(folder / 'comparison.csv', 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator='\n')
        w.writeheader()
        for r in rows + aggregates:
            w.writerow({c: cell(r[c]) for c in COLUMNS})
    version = summaries[0][0].get('runner', {}).get('game_version', {})
    md = [f'# Player-profile comparison: batch `{batch}`', '',
          'Objective measurements recorded by the game during natural fresh-save playthroughs. One row per run; '
          'aggregate rows give the median and range across seeds of the same bot policy and are not a distribution of real players. '
          '`not_measured` means the run did not reach or record that value.', '',
          f"Game commit `{version.get('commit', '?')}`" + (' with uncommitted tracked changes: ' + ', '.join(version.get('dirty_files', [])) if version.get('dirty_worktree') else '') + '.',
          f"Content fingerprint `{(summaries[0][0].get('content_fingerprint') or '?')[:16]}`.", '']
    short = ['profile', 'policy_version', 'seed', 'label', 'actual_active_hours', 'stop_reason', 'final_map', 'highest_stage_unlocked',
             'player_level', 'first_boss_time_min', 'first_prestige_ready_time_min', 'first_prestige_completed_time_min', 'prestiges',
             'deaths', 'boss_attempts', 'boss_wins', 'kills', 'upgrades_bought', 'coins_earned', 'coins_spent', 'gems_earned',
             'gems_spent', 'longest_stall_minutes', 'wall_seconds', 'speed_x']
    md.append('| ' + ' | '.join(short) + ' |')
    md.append('|' + '---|' * len(short))
    for r in rows + aggregates:
        md.append('| ' + ' | '.join(cell(r[c]) for c in short) + ' |')
    md += ['', '## Gear at the end of each run', '', '| run | gear (weapon ^merge tier | outfit ^merge tier) | cards | evidence |', '|---|---|---|---|']
    for r in rows:
        md.append(f"| {r['profile']} s{r['seed']} {r['label']} | {cell(r['gear_progress'])} | {cell(r['cards']) or '-'} | `{r['evidence_file']}` |")
    md += ['', 'All columns, including digests, are in `comparison.csv`.', '']
    write(folder / 'comparison.md', '\n'.join(md))
    write(folder / 'measurements.md', measurements(batch, summaries))
    print(f'report: {(folder / "comparison.md").relative_to(ROOT).as_posix()} ({len(rows)} runs, {len(aggregates)} aggregate rows)')
    return True


def fmt(seconds):
    return 'not reached' if seconds is None else f'{float(seconds) / 60.0:.1f} min'


def measurements(batch, summaries):
    """Per-run timelines copied from summary.json and events.jsonl: measurements only, no interpretation."""
    out = [f'# Measurements: batch `{batch}`', '', 'Copied from each run\'s `summary.json` and `events.jsonl`. No interpretation here; '
           'see `active_evaluation.md` and `balance_assessment.md` for the labelled interpretation.', '']
    for summary, folder in summaries:
        g = summary.get('game')
        out.append(f"## {folder.name}")
        out.append('')
        if not g:
            out += [f"Run did not produce game data: `{summary.get('stop_reason')}`.", '']
            continue
        p = summary.get('process', {})
        out += [f"- Stop: `{summary['stop_reason']}` after {summary['active_seconds'] / 60.0:.1f} active minutes "
                f"({p.get('wall_seconds')} s wall, {p.get('speed_x')}x real time); offline {summary['offline_seconds']} s.",
                f"- End state: map {g['stage']}, highest map unlocked {g['highest_stage_unlocked']}, level {g['player_level']}, "
                f"{g['prestiges']} Prestige, cards {g['cards'] or 'none'}, HP {g['stats']['hp']}, damage {g['stats']['damage']}.",
                f"- Gear: weapon {g['equipment']['weapon']}, outfit {g['equipment']['outfit']}, {g['equipment']['identities_owned']} identities, "
                f"{g['equipment']['merge_levels_total']} merge levels in total.",
                f"- Kills {g['kills_total']}, deaths {g['deaths']}, upgrades bought {g['upgrades_bought']}, counts {g['counts']}.",
                f"- Coins: earned {g['currency']['coins']['earned_total']} (kills {g['currency']['coins']['earned_from_kills']}, "
                f"by action {g['currency']['coins']['earned_by_action']}), spent {g['currency']['coins']['spent_total']} {g['currency']['coins']['spent_by_category']}.",
                f"- Gems: earned {g['currency']['gems']['earned_total']} (kills {g['currency']['gems']['earned_from_kills']}, "
                f"by action {g['currency']['gems']['earned_by_action']}), spent {g['currency']['gems']['spent_total']} {g['currency']['gems']['spent_by_category']}.",
                f"- Longest interval without meaningful progression: {summary['longest_stall']['seconds'] / 60.0:.1f} min "
                f"(from {fmt(summary['longest_stall']['from_s'])} to {fmt(summary['longest_stall']['to_s'])}).", '']
        out += ['| milestone | active time |', '|---|---|']
        firsts = g.get('first_times_s', {})
        for key in ['gear_pickup', 'equip', 'merge', 'upgrade', 'camp']:
            out.append(f'| first {key} | {fmt(firsts.get(key))} |')
        for level in ['5', '10', '15', '20', '25', '30', '40', '50']:
            if level in g.get('level_times_s', {}):
                out.append(f"| level {level} | {fmt(g['level_times_s'][level])} |")
        for boss, t in sorted(g.get('boss_found_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| {boss} found | {fmt(t)} |')
        for boss, t in sorted(g.get('boss_first_kill_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| {boss} first defeated | {fmt(t)} |')
        for st, t in sorted(g.get('stage_unlock_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| map {st} unlocked (first time) | {fmt(t)} |')
        for st, t in sorted(g.get('stage_enter_times_s', {}).items(), key=lambda kv: kv[1]):
            if st != '1':
                out.append(f'| entered map {st} | {fmt(t)} |')
        out.append(f"| first Prestige opportunity ready | {fmt(g.get('first_prestige_ready_time_s'))} |")
        out.append(f"| first Prestige completed | {fmt(g.get('first_prestige_completed_time_s'))} |")
        out.append('')
        if g.get('boss_attempts'):
            out += ['| boss attempt | started | seconds | level | outcome |', '|---|---|---|---|---|']
            for x in g['boss_attempts']:
                out.append(f"| {x['boss']} | {fmt(x['started_t'])} | {x['seconds']} | {x['level']} | {x['outcome']} |")
            out.append('')
        if g.get('death_log'):
            out += ['| death | map | level | attackers |', '|---|---|---|---|']
            for d in g['death_log']:
                out.append(f"| {fmt(d['t'])} | {d['stage']} | {d['level']} | {', '.join(d['attackers']) or 'unknown'} |")
            out.append('')
        for i, diff in enumerate(g.get('prestige_field_diffs') or []):
            by = {}
            for field, cls in diff['fields'].items():
                by.setdefault(cls, []).append(field)
            out += [f'Prestige {i + 1} field diff (real transaction; KEPT = unchanged, RESET = equals a fresh profile, OTHER = changed otherwise):', '']
            for cls in ['KEPT', 'RESET', 'OTHER']:
                out.append(f"- {cls} ({len(by.get(cls, []))}): {', '.join(sorted(by.get(cls, [])))}")
            out += [f"- Facts: {json.dumps(diff['facts'])}", '']
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('command', choices=['run', 'determinism', 'report'])
    ap.add_argument('--batch', required=True)
    ap.add_argument('--player-profile', default='active')
    ap.add_argument('--seeds', default='1')
    ap.add_argument('--active-minutes', type=float, default=60)
    ap.add_argument('--until', default='duration', choices=['duration', 'first-prestige'])
    ap.add_argument('--max-active-minutes', type=float, default=240)
    ap.add_argument('--max-wall-seconds', type=float, default=600)
    ap.add_argument('--stall-minutes', type=float, default=30)
    ap.add_argument('--trace', action='store_true')
    ap.add_argument('--label', default='')
    a = ap.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_-]+', a.batch):
        sys.exit('batch id: letters, digits, - and _ only')
    if a.command == 'report':
        sys.exit(0 if report(a.batch) else 1)
    label = a.label or (f'{a.active_minutes:g}m' if a.until == 'duration' else a.until)
    seeds = [int(s) for s in a.seeds.split(',') if s]
    ok = True
    if a.command == 'determinism':
        first_ok, first, _ = run_one(a.batch, a.player_profile, seeds[0], label, a)
        second_ok, second, _ = run_one(a.batch, a.player_profile, seeds[0], 'repeat-' + label, a)
        same_events = first.get('events_sha256') is not None and first.get('events_sha256') == second.get('events_sha256')
        same_state = first.get('state_sha256') is not None and first.get('state_sha256') == second.get('state_sha256')
        print(f'DETERMINISM events {"IDENTICAL" if same_events else "DIFFERENT"} ({first.get("events")} vs {second.get("events")} events), '
              f'state {"IDENTICAL" if same_state else "DIFFERENT"}')
        ok = first_ok and second_ok and same_events and same_state
    else:
        for seed in seeds:
            ok = run_one(a.batch, a.player_profile, seed, label, a)[0] and ok
    report(a.batch)
    print('PLAYER_PROFILE_RUN', 'PASS' if ok else 'FAIL')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
