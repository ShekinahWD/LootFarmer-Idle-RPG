"""Player-profile playtest runner (non-gating, Playbook 60.1: one Godot process at a time).

Runs res://tests/playtest/player_profile_run.tscn headless (the real LootSimulation played by a player profile from a
fresh isolated profile), under a hard process timeout, and builds the comparison sheets from what the game recorded.
Python never computes a game outcome: it only starts runs, checks them and summarizes their files.

Policy sets (--policy-set): `framework` (default) = the reusable Player Profiles package (addons/player_profiles/,
seven universal profiles: active, casual, idle, beginner, collector, speedrunner, completionist) through the LootFarmer
integration (tests/playtest/lootfarmer/); `legacy` = the frozen Phase 1/2 policies active-1, casual-1, idle-1 (historical
baseline; folders get a `legacy-` label prefix). Framework runs accept --override trait=value,... (per-run, never a
preset edit).

  python tools/player_profile_run.py run --batch <id> [--player-profile active[,casual,idle,...]] [--seeds 1,2,3]
         [--policy-set framework|legacy] [--override attention=0.4,weight.explore=0.9]
         [--active-minutes 60                                   (active-time horizon)
          | --until calendar --calendar-hours 24 [--max-active-minutes N]   (calendar horizon, Phase 2)
          | --until first-prestige --max-active-minutes 240 [--max-calendar-hours N]]
         [--schedule default|continuous|calendar] [--session-minutes 16-24] [--slots 8.5,13@0.5,20]
         [--jitter-minutes N] [--min-gap-minutes N] [--grace-seconds N] [--return-mode cold|warm]
         [--max-wall-seconds 600] [--stall-minutes N] [--trace] [--label name]
  python tools/player_profile_run.py determinism --batch <id> [same run options, one profile, one seed]
  python tools/player_profile_run.py report --batch <id>

Runs are sequential: profiles in the order given, seeds in order within each profile.
Outputs (git-ignored): tests/tmp/player_profiles/<batch>/<profile>_s<seed>_<label>/{events.jsonl, summary.json,
trace.jsonl, godot.log} and, per batch: comparison.csv/.md (one row per run), profile_comparison.md (profiles side by
side per horizon, active vs calendar time), findings.md (automatic progression-problem candidates with evidence)
and measurements.md (per-run timelines), plus framework_comparison.md/.csv (the package's generic, cross-game metrics:
decisions by intent, time share by intent, mistakes, switches, unsupported intents, diagnosis) for framework runs.
A run is accepted only when Godot exits 0, prints no SCRIPT ERROR and ends with the PLAYTEST_RESULT line.
Exit code: 0 when every requested run was sound (a stall or a spent time budget is a finding, not a failure) and,
for `determinism`, both digests match; 1 otherwise.
Environment: GODOT = Godot 4.7 console executable (same default as tools/run_probes.py).
"""
from pathlib import Path
import argparse, csv, json, os, re, statistics, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
BASE = ROOT / 'tests/tmp/player_profiles'
SCENE = 'res://tests/playtest/player_profile_run.tscn'
sys.path.insert(0, str(ROOT / 'addons' / 'player_profiles' / 'tools'))
import player_profiles as pp_package  # noqa: E402  (the package's generic report)
PROFILE_ORDER = ['active', 'casual', 'idle', 'collector', 'speedrunner', 'beginner', 'completionist']
COLUMNS = ['profile', 'policy_set', 'policy_version', 'profile_sha256', 'seed', 'label', 'horizon', 'target_active_hours', 'actual_active_hours', 'offline_hours',
           'calendar_hours', 'sessions', 'stop_reason', 'final_map', 'highest_stage_unlocked', 'player_level',
           'first_boss_time_min', 'first_boss_calendar_h', 'first_prestige_ready_time_min',
           'first_prestige_completed_time_min', 'first_prestige_calendar_h', 'prestiges', 'cards', 'deaths',
           'boss_attempts', 'boss_wins', 'kills', 'upgrades_bought', 'automation_levels', 'gear_progress',
           'gear_identities', 'merge_levels', 'coins_earned', 'coins_spent', 'gems_earned', 'gems_spent',
           'offline_claims', 'offline_coins_earned', 'offline_coins_claimed', 'offline_gems_earned', 'offline_gems_claimed',
           'offline_items_earned', 'offline_items_claimed', 'offline_capped_hours', 'offline_share_coins', 'offline_share_gems',
           'mission_claims', 'longest_stall_minutes', 'no_progress_active_minutes', 'wall_seconds', 'speed_x',
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
            f'--output={out.as_posix()}', f'--policy-set={a.policy_set}']
    if a.override:
        args += [f'--override={a.override}']
    if a.stall_minutes is not None:
        args += [f'--stall-minutes={a.stall_minutes}']
    if a.until == 'duration':
        args += [f'--active-minutes={a.active_minutes}']
    elif a.until == 'calendar':
        args += ['--until=calendar', f'--calendar-hours={a.calendar_hours}']
        if a.max_active_minutes_set:
            args += [f'--max-active-minutes={a.max_active_minutes}']
    else:
        args += [f'--until={a.until}', f'--max-active-minutes={a.max_active_minutes}']
        if a.max_calendar_hours:
            args += [f'--max-calendar-hours={a.max_calendar_hours}']
    for option in ['schedule', 'session_minutes', 'slots', 'jitter_minutes', 'min_gap_minutes', 'grace_seconds', 'return_mode']:
        value = getattr(a, option)
        if value is not None:
            args += [f'--{option.replace("_", "-")}={value}']
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
            'requested': {'policy_set': a.policy_set, 'override': a.override, 'until': a.until, 'active_minutes': a.active_minutes, 'calendar_hours': a.calendar_hours,
                          'max_active_minutes': a.max_active_minutes, 'max_calendar_hours': a.max_calendar_hours,
                          'max_wall_seconds': a.max_wall_seconds, 'stall_minutes': a.stall_minutes, 'trace': a.trace,
                          'schedule_overrides': {k: getattr(a, k) for k in ['schedule', 'session_minutes', 'slots', 'jitter_minutes',
                                                                            'min_gap_minutes', 'grace_seconds', 'return_mode'] if getattr(a, k) is not None}},
            'game_version': git_state()}
    if summary is None:
        summary = {'profile': profile, 'seed': seed, 'stop_reason': status, 'ok': False}
    summary['runner'] = meta
    write(summary_path, json.dumps(summary, indent=2) + '\n')
    line = sentinel[-1] if sentinel else '(no PLAYTEST_RESULT line)'
    print(f'{out.name:34s} {"OK  " if ok else "FAIL"} {status:26s} {wall:6.1f}s  {line[:170]}', flush=True)
    if not ok:
        for l in [l for l in output.splitlines() if 'SCRIPT ERROR' in l or l.startswith('ERROR:')][:8]:
            print('    ' + l[:200])
    return ok, summary, out


def minutes(value):
    return None if value is None else round(float(value) / 60.0, 2)


def hours(value):
    return None if value is None else round(float(value) / 3600.0, 2)


def ratio(part, whole):
    return None if not whole else round(float(part) / float(whole), 3)


def horizon_of(summary):
    req = (summary.get('runner') or {}).get('requested', {})
    until = req.get('until')
    if until == 'calendar':
        return f"{req.get('calendar_hours'):g}h calendar"
    if until == 'duration':
        return f"{float(req.get('active_minutes')) / 60.0:g}h active"
    return f"{until} (max {req.get('max_active_minutes'):g} active min)" if until else 'unknown'


def milestone(g, key):
    return (g.get('milestones') or {}).get(key)


def row_of(summary, out):
    g = summary.get('game') or {}
    cur = g.get('currency') or {}
    eq = g.get('equipment') or {}
    off = g.get('offline') or {}
    attempts = g.get('boss_attempts') or []
    first_boss = min((g.get('boss_first_kill_times_s') or {}).values(), default=None)
    boss_cal = [v['c'] for k, v in (g.get('milestones') or {}).items() if k.startswith('boss_defeated:')]
    p1 = milestone(g, 'prestige:1')
    requested = summary.get('runner', {}).get('requested', {})
    target = requested.get('active_minutes') if requested.get('until') == 'duration' else requested.get('max_active_minutes')
    coins_earned = (cur.get('coins') or {}).get('earned_total')
    gems_earned = (cur.get('gems') or {}).get('earned_total')
    claimed = off.get('claimed') or {}
    earned = off.get('earned') or {}
    paid = off.get('paid_at_prestige') or {}

    def gear():
        if not eq:
            return None
        w, o = eq.get('weapon', {}), eq.get('outfit', {})
        return f"{w.get('id') or 'none'}^{w.get('merge', 0)} T{w.get('tier', 0)} | {o.get('id') or 'none'}^{o.get('merge', 0)} T{o.get('tier', 0)}"

    gaps = summary.get('progress_gaps') or []
    return {
        'profile': summary.get('profile'), 'policy_set': summary.get('policy_set', 'legacy'), 'policy_version': summary.get('policy_version'),
        'profile_sha256': (summary.get('profile_sha256') or summary.get('policy_sha256') or '')[:16] or None, 'seed': summary.get('seed'),
        'label': summary.get('runner', {}).get('label'), 'horizon': horizon_of(summary),
        'target_active_hours': None if target is None or requested.get('until') == 'calendar' else round(float(target) / 60.0, 3),
        'actual_active_hours': None if 'active_seconds' not in summary else round(summary['active_seconds'] / 3600.0, 3),
        'offline_hours': None if 'offline_seconds' not in summary else round(summary['offline_seconds'] / 3600.0, 3),
        'calendar_hours': None if 'calendar_seconds' not in summary else round(summary['calendar_seconds'] / 3600.0, 3),
        'sessions': summary.get('session_count', 1 if g else None),
        'stop_reason': summary.get('stop_reason'), 'final_map': g.get('stage'),
        'highest_stage_unlocked': g.get('highest_stage_unlocked'), 'player_level': g.get('player_level'),
        'first_boss_time_min': minutes(first_boss), 'first_boss_calendar_h': hours(min(boss_cal)) if boss_cal else None,
        'first_prestige_ready_time_min': minutes(g.get('first_prestige_ready_time_s')),
        'first_prestige_completed_time_min': minutes(g.get('first_prestige_completed_time_s')),
        'first_prestige_calendar_h': hours(p1['c']) if p1 else None,
        'prestiges': g.get('prestiges'), 'cards': ' '.join(g.get('cards') or []) if g else None,
        'deaths': g.get('deaths'), 'boss_attempts': len(attempts) if g else None,
        'boss_wins': sum(1 for x in attempts if x.get('outcome') == 'win') if g else None,
        'kills': g.get('kills_total'), 'upgrades_bought': g.get('upgrades_bought'),
        'automation_levels': sum((g.get('automation_upgrades') or {}).values()) if g else None,
        'gear_progress': gear(), 'gear_identities': eq.get('identities_owned'), 'merge_levels': eq.get('merge_levels_total'),
        'coins_earned': coins_earned, 'coins_spent': (cur.get('coins') or {}).get('spent_total'),
        'gems_earned': gems_earned, 'gems_spent': (cur.get('gems') or {}).get('spent_total'),
        'offline_claims': off.get('claims') if off else None,
        'offline_coins_earned': round(earned.get('coins', 0.0), 1) if off else None,
        'offline_coins_claimed': round(claimed.get('coins', 0.0) + paid.get('coins', 0.0), 1) if off else None,
        'offline_gems_earned': round(earned.get('gems', 0.0), 2) if off else None,
        'offline_gems_claimed': round(claimed.get('gems', 0.0) + paid.get('gems', 0.0), 2) if off else None,
        'offline_items_earned': earned.get('items') if off else None, 'offline_items_claimed': claimed.get('items') if off else None,
        'offline_capped_hours': hours(off.get('capped_seconds')) if off else None,
        'offline_share_coins': ratio(claimed.get('coins', 0.0) + paid.get('coins', 0.0), coins_earned) if off else None,
        'offline_share_gems': ratio(claimed.get('gems', 0.0) + paid.get('gems', 0.0), gems_earned) if off else None,
        'mission_claims': (g.get('counts') or {}).get('mission_claims'),
        'longest_stall_minutes': None if 'longest_stall' not in summary else round(summary['longest_stall']['seconds'] / 60.0, 2),
        'no_progress_active_minutes': round(sum(x['to_t'] - x['from_t'] for x in gaps) / 60.0, 1) if 'progress_gaps' in summary else None,
        'wall_seconds': (summary.get('process') or {}).get('wall_seconds'), 'speed_x': (summary.get('process') or {}).get('speed_x'),
        'events_sha256': (summary.get('events_sha256') or '')[:16] or None, 'state_sha256': (summary.get('state_sha256') or '')[:16] or None,
        'evidence_file': out.relative_to(ROOT).as_posix() + '/summary.json',
    }


def cell(value):
    return 'not_measured' if value is None else str(value)


AGGREGATE = ['actual_active_hours', 'offline_hours', 'calendar_hours', 'sessions', 'player_level', 'highest_stage_unlocked',
             'first_boss_time_min', 'first_boss_calendar_h', 'first_prestige_ready_time_min', 'first_prestige_completed_time_min',
             'first_prestige_calendar_h', 'prestiges', 'deaths', 'boss_attempts', 'boss_wins', 'kills', 'upgrades_bought',
             'automation_levels', 'gear_identities', 'merge_levels', 'coins_earned', 'coins_spent', 'gems_earned', 'gems_spent',
             'offline_claims', 'offline_coins_earned', 'offline_coins_claimed', 'offline_gems_earned', 'offline_gems_claimed',
             'offline_items_earned', 'offline_items_claimed', 'offline_capped_hours', 'offline_share_coins', 'offline_share_gems',
             'mission_claims', 'longest_stall_minutes', 'no_progress_active_minutes', 'wall_seconds', 'speed_x']


def aggregate(members, column):
    values = [m[column] for m in members if isinstance(m[column], (int, float))]
    if not values:
        return None
    missing = len(members) - len(values)
    text = f'{statistics.median(values):g}' if len(values) == 1 else f'{statistics.median(values):g} [{min(values):g}..{max(values):g}]'
    return text + (f' ({missing} of {len(members)} not reached)' if missing else '')


def load(batch):
    folder = BASE / batch
    rows, summaries = [], []
    for path in sorted(folder.glob('*/summary.json')):
        summary = json.loads(path.read_text(encoding='utf-8'))
        summaries.append((summary, path.parent))
        rows.append(row_of(summary, path.parent))
    order = {p: i for i, p in enumerate(PROFILE_ORDER)}
    pairs = sorted(zip(rows, summaries), key=lambda rs: (rs[0]['horizon'], order.get(rs[0]['profile'], 99), str(rs[0]['label']), rs[0]['seed'] or 0))
    return [p[0] for p in pairs], [p[1] for p in pairs]


def report(batch):
    folder = BASE / batch
    rows, summaries = load(batch)
    if not rows:
        print('no runs in', folder)
        return False
    # Aggregate rows: same profile, policy and requested horizon, several seeds. Median and range of these bot runs
    # only: never a distribution of real players.
    groups = {}
    for r in rows:
        if r['label'] and r['label'].startswith('repeat'):
            continue
        groups.setdefault((r['profile'], r['policy_version'], r['label'], r['horizon']), []).append(r)
    aggregates = []
    for (profile, version, label, horizon), members in groups.items():
        if len({m['seed'] for m in members}) < 2:
            continue
        agg = {c: None for c in COLUMNS}
        agg.update({'profile': profile, 'policy_version': version, 'seed': 'median[min..max] of seeds ' + ','.join(str(m['seed']) for m in members),
                    'label': label, 'horizon': horizon, 'stop_reason': '/'.join(sorted({str(m['stop_reason']) for m in members})),
                    'evidence_file': 'aggregate of the rows above (bot runs, not a player distribution)'})
        for c in AGGREGATE:
            agg[c] = aggregate(members, c)
        aggregates.append(agg)
    with open(folder / 'comparison.csv', 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator='\n')
        w.writeheader()
        for r in rows + aggregates:
            w.writerow({c: cell(r[c]) for c in COLUMNS})
    version = summaries[0][0].get('runner', {}).get('game_version', {})
    head = [f"Game commit `{version.get('commit', '?')}`" + (' with uncommitted tracked changes: ' + ', '.join(version.get('dirty_files', [])) if version.get('dirty_worktree') else '') + '.',
            f"Content fingerprint `{(summaries[0][0].get('content_fingerprint') or '?')[:16]}`.", '']
    md = [f'# Player-profile comparison: batch `{batch}`', '',
          'Objective measurements recorded by the game during natural fresh-save playthroughs. One row per run; '
          'aggregate rows give the median and range across seeds of the same bot policy and are not a distribution of real players. '
          '`not_measured` means the run did not reach or record that value. Times: `_min` columns are **active** minutes, '
          '`_h` columns are **calendar** hours since the first launch.', ''] + head
    short = ['profile', 'seed', 'horizon', 'actual_active_hours', 'calendar_hours', 'sessions', 'stop_reason', 'highest_stage_unlocked',
             'player_level', 'first_boss_time_min', 'first_boss_calendar_h', 'first_prestige_completed_time_min', 'first_prestige_calendar_h',
             'prestiges', 'deaths', 'boss_attempts', 'boss_wins', 'upgrades_bought', 'automation_levels', 'coins_earned', 'gems_earned',
             'offline_coins_claimed', 'offline_share_coins', 'longest_stall_minutes', 'wall_seconds', 'speed_x']
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
    write(folder / 'profile_comparison.md', profile_comparison(batch, rows, summaries, head))
    write(folder / 'findings.md', findings(batch, summaries))
    framework_runs = pp_package.framework_report(folder) or 0
    print(f'report: {(folder / "comparison.md").relative_to(ROOT).as_posix()} ({len(rows)} runs, {len(aggregates)} aggregate rows), '
          f'profile_comparison.md, findings.md, measurements.md' + (f', framework_comparison.md ({framework_runs} framework runs)' if framework_runs else ''))
    return True


def fmt(seconds):
    return 'not reached' if seconds is None else f'{float(seconds) / 60.0:.1f} min'


def both(m):
    """A milestone as 'active min / calendar h'."""
    return '-' if not m else f"{m['t'] / 60.0:.0f} min / {m['c'] / 3600.0:.1f} h"


COMPARE = [
    ('Active gameplay time (h)', 'actual_active_hours'), ('Offline time (h)', 'offline_hours'), ('Calendar time (h)', 'calendar_hours'),
    ('Sessions', 'sessions'), ('Player level', 'player_level'), ('Highest map unlocked', 'highest_stage_unlocked'),
    ('First boss defeat: active min', 'first_boss_time_min'), ('First boss defeat: calendar h', 'first_boss_calendar_h'),
    ('First Prestige: active min', 'first_prestige_completed_time_min'), ('First Prestige: calendar h', 'first_prestige_calendar_h'),
    ('Total Prestiges', 'prestiges'), ('Boss attempts', 'boss_attempts'), ('Boss victories', 'boss_wins'), ('Deaths', 'deaths'),
    ('Gear identities owned', 'gear_identities'), ('Merge levels (total)', 'merge_levels'),
    ('Coins earned', 'coins_earned'), ('Coins spent', 'coins_spent'), ('Gems earned', 'gems_earned'), ('Gems spent', 'gems_spent'),
    ('Upgrade levels bought', 'upgrades_bought'), ('Automation/offline upgrade levels owned', 'automation_levels'),
    ('Offline claims', 'offline_claims'), ('Offline Coins earned (settled)', 'offline_coins_earned'),
    ('Offline Coins claimed (incl. paid by Prestige)', 'offline_coins_claimed'), ('Offline Gems earned', 'offline_gems_earned'),
    ('Offline Gems claimed', 'offline_gems_claimed'), ('Offline item copies earned', 'offline_items_earned'),
    ('Offline item copies claimed', 'offline_items_claimed'), ('Offline hours past the cap (unpaid)', 'offline_capped_hours'),
    ('Offline share of Coins earned', 'offline_share_coins'), ('Offline share of Gems earned', 'offline_share_gems'),
    ('Mission claims', 'mission_claims'), ('Longest interval without progression (active min)', 'longest_stall_minutes'),
    ('Active minutes in no-progress gaps >= 10 min', 'no_progress_active_minutes'),
    ('Wall seconds', 'wall_seconds'), ('Speed (x real time)', 'speed_x')]


def profile_comparison(batch, rows, summaries, head):
    out = [f'# Player-profile comparison: batch `{batch}`', '',
           'Side-by-side measurements per horizon. Each cell is the median and [range] across the seeds run for that profile and horizon '
           '(bot runs, not a distribution of players). An **active-time horizon** gives each profile the same hours of play, which spread over '
           'very different calendar spans; a **calendar horizon** gives each profile the same days, in which they play very different amounts. '
           'Neither comparison is "fair" on its own: read the active and calendar rows together. Offline rewards exist only for profiles that '
           'leave the game; a continuous run has none by construction. Framework profiles (policy_set `framework`) and the frozen '
           'Phase 1/2 policies (`legacy`, versions active-1/casual-1/idle-1) are different policy versions: compare them only as '
           'labelled baseline vs new, never as the same profile.', ''] + head
    by_horizon = {}
    for r, (s, folder) in zip(rows, summaries):
        if r['label'] and str(r['label']).startswith('repeat'):
            continue
        by_horizon.setdefault(r['horizon'], {}).setdefault(r['profile'], []).append((r, s))
    order = {p: i for i, p in enumerate(PROFILE_ORDER)}
    for horizon in sorted(by_horizon):
        profiles = sorted(by_horizon[horizon], key=lambda p: order.get(p, 99))
        out += [f'## {horizon}', '', '| metric | ' + ' | '.join(f"{p} (seeds {','.join(str(x[0]['seed']) for x in by_horizon[horizon][p])})" for p in profiles) + ' |',
                '|---|' + '---|' * len(profiles)]
        for name, column in COMPARE:
            out.append(f'| {name} | ' + ' | '.join(cell(aggregate([x[0] for x in by_horizon[horizon][p]], column)) for p in profiles) + ' |')
        out += ['', 'Milestones per run, as **active minutes / calendar hours** since the first launch:', '',
                '| run | first boss | map 2 | map 3 | map 4 | map 5 | level 10 | level 20 | level 30 | Prestige ready | Prestige 1 | Prestige 2 | Prestige 3 |',
                '|---|' + '---|' * 12]
        for p in profiles:
            for r, s in by_horizon[horizon][p]:
                g = s.get('game') or {}
                ms = g.get('milestones') or {}
                boss = sorted((v for k, v in ms.items() if k.startswith('boss_defeated:')), key=lambda v: v['t'])
                cols = [both(boss[0] if boss else None)] + [both(ms.get(f'stage_unlocked:{n}')) for n in (2, 3, 4, 5)] + \
                       [both(ms.get(f'level:{n}')) for n in (10, 20, 30)] + [both(ms.get('prestige_ready'))] + [both(ms.get(f'prestige:{n}')) for n in (1, 2, 3)]
                out.append(f"| {p} s{r['seed']} | " + ' | '.join(cols) + ' |')
        out += ['', 'Boss outcomes per profile (all seeds): wins / attempts per boss.', '']
        for p in profiles:
            tally = {}
            for r, s in by_horizon[horizon][p]:
                for x in (s.get('game') or {}).get('boss_attempts') or []:
                    t = tally.setdefault(x['boss'], [0, 0])
                    t[1] += 1
                    t[0] += x['outcome'] == 'win'
            out.append(f"- {p}: " + (', '.join(f'{b} {w}/{n}' for b, (w, n) in sorted(tally.items())) or 'no attempts'))
        out.append('')
    return '\n'.join(out) + '\n'


def events_of(folder):
    path = folder / 'events.jsonl'
    if not path.exists():
        return []
    return [json.loads(l) for l in path.read_text(encoding='utf-8').splitlines() if l.strip()]


def findings(batch, summaries):
    """Automatic progression-problem candidates. Each is a measurement with a suggested reading, never a verdict."""
    rows = []

    def add(kind, summary, when, evidence, cause, action, severity):
        rows.append({'kind': kind, 'run': f"{summary.get('profile')} s{summary.get('seed')} {summary.get('runner', {}).get('label')}",
                     'when': when, 'evidence': evidence, 'cause': cause, 'action': action, 'severity': severity})

    for summary, folder in summaries:
        g = summary.get('game')
        if not g:
            add('run_failed', summary, '-', f"stop `{summary.get('stop_reason')}`", 'testing-system defect', 'read godot.log', 1)
            continue
        if summary.get('runner', {}).get('label', '').startswith('repeat'):
            continue
        ev = events_of(folder)
        stage, level = 1, 1
        state_at = {}
        for e in ev:
            if e['type'] == 'stage_unlocked':
                stage = max(stage, e['stage'])
            if e['type'] == 'level_up':
                level = e['level']
            state_at[e['n']] = (stage, level)
        # 1. long gaps without progression
        for gap in summary.get('progress_gaps') or []:
            span = (gap['to_t'] - gap['from_t']) / 60.0
            if span >= 20:
                st = max((v for k, v in (g.get('stage_unlock_times_s') or {}).items() if v <= gap['from_t']), default=None)
                add('no_progress', summary, f"{gap['from_t'] / 60:.0f}-{gap['to_t'] / 60:.0f} active min ({gap['from_c'] / 3600:.1f}-{gap['to_c'] / 3600:.1f} calendar h)",
                    f'{span:.0f} active min without a level, gear, upgrade, boss, map or Prestige change',
                    'unknown: read trace (bot loop vs wall)', 'inspect trace.jsonl and mode events in that window', 2)
        # 2. stuck on a map: longest active interval between map unlocks / boss wins
        marks = sorted([0.0] + [e['t'] for e in ev if e['type'] in ('stage_unlocked', 'boss_defeated', 'prestige_completed')])
        end = summary.get('active_seconds', 0.0)
        marks.append(end)
        longest = max(((b - a, a, b) for a, b in zip(marks, marks[1:])), default=(0, 0, 0))
        if longest[0] >= 45 * 60:
            add('stuck_on_map', summary, f'{longest[1] / 60:.0f}-{longest[2] / 60:.0f} active min',
                f"{longest[0] / 60:.0f} active min without a new boss defeat or Prestige; end state map {g['stage']} (highest {g['highest_stage_unlocked']}), "
                f"level {g['player_level']}, damage {g['stats']['damage']}, HP {g['stats']['hp']}",
                'game balance or policy (boss margin rule): compare the boss margin trace with the attempts', 'read boss_margin/boss_need in trace; try the boss ladder', 2)
        # 3. repeated deaths
        deaths = g.get('death_log') or []
        if len(deaths) >= 3:
            by = {}
            for d in deaths:
                by.setdefault((d['stage'], tuple(d.get('attackers') or [])), []).append(d)
            worst = max(by.items(), key=lambda kv: len(kv[1]))
            add('repeated_deaths', summary, f"{worst[1][0]['t'] / 60:.0f}-{worst[1][-1]['t'] / 60:.0f} active min",
                f"{len(deaths)} deaths in total; {len(worst[1])} on map {worst[0][0]} to {', '.join(worst[0][1]) or 'unknown'} (levels {worst[1][0]['level']}-{worst[1][-1]['level']})",
                'policy (no resting / farm choice) unless deaths continue with resting', 'compare with the same map in the Active and Casual runs', 2 if len(deaths) >= 8 else 3)
        # 4. boss losses
        losses = {}
        for x in g.get('boss_attempts') or []:
            if x['outcome'] != 'win':
                losses.setdefault(x['boss'], []).append(x)
        for boss, xs in losses.items():
            if len(xs) >= 2:
                add('boss_losses', summary, ', '.join(f"{x['started_t'] / 60:.0f} min" for x in xs[:6]),
                    f"{len(xs)} lost attempts at {boss} (levels {xs[0]['level']}-{xs[-1]['level']}, outcomes {', '.join(sorted({x['outcome'] for x in xs}))})",
                    'game balance or the margin estimate', 'boss-readiness ladder (Playbook 112.2) at the levels recorded', 2)
        # 5. long purchase waits
        for w in (g.get('purchase_waits') or []) + [dict(x, open=True) for x in g.get('open_wants') or []]:
            act = w.get('waited_active_s', w.get('open_active_s', 0))
            cal = w.get('waited_calendar_s', w.get('open_calendar_s', 0))
            if act >= 30 * 60 or cal >= 24 * 3600:
                add('unaffordable_upgrade', summary, f"{'open at the end' if w.get('open') else 'closed'}",
                    f"saving for `{w['want']}` for {act / 60:.0f} active min / {cal / 3600:.1f} calendar h",
                    'game balance (price vs income) or policy (savings order)', 'compare price with measured income at that point', 3)
        # 6. automation timing
        for upgrade, first in sorted((g.get('automation_first_purchase') or {}).items(), key=lambda kv: kv[1]['t']):
            if upgrade in ('focus', 'collect', 'offline_cap', 'mission_claim', 'auto_use') and (first['t'] >= 60 * 60 or first['c'] >= 48 * 3600):
                add('automation_late', summary, both(first), f'first `{upgrade}` level bought at {both(first)} (active / calendar)',
                    'game balance (price/income) or policy order', 'check the Gem income before that purchase', 3)
        # 7. offline contribution
        off = g.get('offline') or {}
        if off.get('settlements'):
            coins = g['currency']['coins']['earned_total'] or 1
            claimed = off['claimed']['coins'] + off['paid_at_prestige']['coins']
            share = claimed / coins
            away = off.get('away_seconds') or 1
            capped = off.get('capped_seconds', 0) / away
            add('offline_contribution', summary, f"{off['settlements']} settlements",
                f"offline paid {claimed:.0f} of {coins:.0f} Coins ({share:.0%}), {off['claimed']['gems'] + off['paid_at_prestige']['gems']:.1f} Gems, "
                f"{off['claimed']['items']} item copies; {capped:.0%} of the time away was past the cap (unpaid)",
                'measurement (no defect implied)', 'decide whether this share matches the offline design intent', 4)
        # 8. Prestige ready but not taken / never ready
        ms = g.get('milestones') or {}
        if ms.get('prestige_ready') and not ms.get('prestige:1'):
            add('prestige_not_taken', summary, both(ms['prestige_ready']), 'an opportunity was ready but no Prestige completed by the end',
                'policy (Prestige rule) or game (gate)', 'read prestige_skipped events', 3)
        if not ms.get('prestige_ready') and summary.get('active_seconds', 0) >= 3600:
            add('prestige_never_ready', summary, '-', f"no Prestige opportunity ready in {summary['active_seconds'] / 60:.0f} active min",
                'game balance or policy', 'list discovered opportunities and their goals', 2)
        # 9. policy quality: rejected actions and stuck movement
        rejections = g.get('rejections') or {}
        for key, n in sorted(rejections.items(), key=lambda kv: -kv[1])[:3]:
            if n >= 50:
                add('policy_rejections', summary, '-', f'{n} rejected `{key}` actions', 'player-policy behaviour', 'fix the policy check before that call', 3)
        stuck = sum(1 for e in ev if e['type'] == 'stuck')
        if stuck >= 20:
            add('policy_stuck', summary, '-', f'{stuck} stuck-movement events', 'player-policy behaviour (steering)', 'inspect positions in stuck events', 3)
        if summary.get('stop_reason') in ('wall_timeout', 'action_error', 'engine_failure'):
            add('run_incomplete', summary, f"{summary.get('active_seconds', 0) / 60:.0f} active min", f"stop `{summary['stop_reason']}`",
                'testing-system defect', 'read godot.log and the last events', 1)
    rows.sort(key=lambda r: (r['severity'], r['kind'], r['run']))
    out = [f'# Automatic progression-problem candidates: batch `{batch}`', '',
           'Generated from the recorded events and summaries by fixed thresholds. Each row is a **candidate** with its evidence and a '
           'suggested reading (game balance, player-policy behaviour or testing-system defect); the classification is a starting '
           'point for investigation, not a verdict. Severity: 1 tool failure, 2 likely progression problem, 3 friction, 4 measurement only.', '',
           '| sev | kind | run | when | evidence | suggested cause | next step |', '|---|---|---|---|---|---|---|']
    for r in rows:
        out.append(f"| {r['severity']} | {r['kind']} | {r['run']} | {r['when']} | {r['evidence']} | {r['cause']} | {r['action']} |")
    return '\n'.join(out) + '\n'


def measurements(batch, summaries):
    """Per-run timelines copied from summary.json and events.jsonl: measurements only, no interpretation."""
    out = [f'# Measurements: batch `{batch}`', '', 'Copied from each run\'s `summary.json` and `events.jsonl`. No interpretation here. '
           'Milestones show active time; session runs also list calendar time.', '']
    for summary, folder in summaries:
        g = summary.get('game')
        out.append(f"## {folder.name}")
        out.append('')
        if not g:
            out += [f"Run did not produce game data: `{summary.get('stop_reason')}`.", '']
            continue
        p = summary.get('process', {})
        out += [f"- Stop: `{summary['stop_reason']}` after {summary['active_seconds'] / 60.0:.1f} active minutes, {summary['offline_seconds'] / 3600.0:.2f} offline hours, "
                f"{summary['calendar_seconds'] / 3600.0:.2f} calendar hours, {summary.get('session_count', 1)} session(s) "
                f"({p.get('wall_seconds')} s wall, {p.get('speed_x')}x real time).",
                f"- End state: map {g['stage']}, highest map unlocked {g['highest_stage_unlocked']}, level {g['player_level']}, "
                f"{g['prestiges']} Prestige, cards {g['cards'] or 'none'}, HP {g['stats']['hp']}, damage {g['stats']['damage']}.",
                f"- Gear: weapon {g['equipment']['weapon']}, outfit {g['equipment']['outfit']}, {g['equipment']['identities_owned']} identities, "
                f"{g['equipment']['merge_levels_total']} merge levels in total.",
                f"- Kills {g['kills_total']}, deaths {g['deaths']}, upgrades bought {g['upgrades_bought']}, counts {g['counts']}.",
                f"- Coins: earned {g['currency']['coins']['earned_total']} (kills {g['currency']['coins']['earned_from_kills']}, "
                f"by action {g['currency']['coins']['earned_by_action']}), spent {g['currency']['coins']['spent_total']} {g['currency']['coins']['spent_by_category']}.",
                f"- Gems: earned {g['currency']['gems']['earned_total']} (kills {g['currency']['gems']['earned_from_kills']}, "
                f"by action {g['currency']['gems']['earned_by_action']}), spent {g['currency']['gems']['spent_total']} {g['currency']['gems']['spent_by_category']}.",
                f"- Automation/offline upgrades owned: {g.get('automation_upgrades') or 'none'}.",
                f"- Longest interval without meaningful progression: {summary['longest_stall']['seconds'] / 60.0:.1f} min "
                f"(from {fmt(summary['longest_stall']['from_s'])} to {fmt(summary['longest_stall']['to_s'])}).", '']
        off = g.get('offline')
        if isinstance(off, dict) and summary.get('sessions'):
            out += [f"- Offline: {off['settlements']} settlements, {off['away_seconds'] / 3600:.1f} h away, {off['rewarded_seconds'] / 3600:.1f} h paid, "
                    f"{off['capped_seconds'] / 3600:.1f} h past the cap; earned {off['earned']}, claimed {off['claimed']} in {off['claims']} claims, "
                    f"paid by Prestige {off['paid_at_prestige']}, item copies refused {off['items_refused']}; pending at the end {g.get('offline_pending_at_end') or 'none'}.", '']
            out += ['| session | starts (calendar h) | away before (h) | active min | planned min |', '|---|---|---|---|---|']
            for s in summary['sessions']:
                out.append(f"| {s['n']} | {s['start_c'] / 3600:.2f} | {s['away_before_s'] / 3600:.2f} | {s['active_s'] / 60:.1f} | {s['planned_s'] / 60:.1f} |")
            out.append('')
        out += ['| milestone | active time | calendar h |', '|---|---|---|']
        ms = g.get('milestones') or {}

        def cal(key):
            return f"{ms[key]['c'] / 3600:.2f}" if key in ms else '-'
        firsts = g.get('first_times_s', {})
        for key in ['gear_pickup', 'equip', 'merge', 'upgrade', 'camp', 'offline_claim']:
            out.append(f'| first {key} | {fmt(firsts.get(key))} | {cal("first:" + key)} |')
        for level in ['5', '10', '15', '20', '25', '30', '40', '50']:
            if level in g.get('level_times_s', {}):
                out.append(f"| level {level} | {fmt(g['level_times_s'][level])} | {cal('level:' + level)} |")
        for boss, t in sorted(g.get('boss_found_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| {boss} found | {fmt(t)} | {cal("boss_found:" + boss)} |')
        for boss, t in sorted(g.get('boss_first_kill_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| {boss} first defeated | {fmt(t)} | {cal("boss_defeated:" + boss)} |')
        for st, t in sorted(g.get('stage_unlock_times_s', {}).items(), key=lambda kv: kv[1]):
            out.append(f'| map {st} unlocked (first time) | {fmt(t)} | {cal("stage_unlocked:" + st)} |')
        out.append(f"| first Prestige opportunity ready | {fmt(g.get('first_prestige_ready_time_s'))} | {cal('prestige_ready')} |")
        for i, t in enumerate(g.get('prestige_times_s') or []):
            out.append(f"| Prestige {i + 1} completed | {fmt(t)} | {cal(f'prestige:{i + 1}')} |")
        for upgrade, first in sorted((g.get('automation_first_purchase') or {}).items(), key=lambda kv: kv[1]['t']):
            out.append(f"| first {upgrade} level | {fmt(first['t'])} | {first['c'] / 3600:.2f} |")
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
    ap.add_argument('--player-profile', default='active', help='one profile or a comma list (run sequentially)')
    ap.add_argument('--seeds', default='1')
    ap.add_argument('--active-minutes', type=float, default=60)
    ap.add_argument('--until', default='duration', choices=['duration', 'calendar', 'first-prestige'])
    ap.add_argument('--calendar-hours', type=float, default=24)
    ap.add_argument('--max-active-minutes', type=float, default=None)
    ap.add_argument('--max-calendar-hours', type=float, default=None)
    ap.add_argument('--max-wall-seconds', type=float, default=600)
    ap.add_argument('--stall-minutes', type=float, default=None, help='default: 30 for continuous runs, record-only for session runs')
    for option in ['--schedule', '--session-minutes', '--slots', '--jitter-minutes', '--min-gap-minutes', '--grace-seconds', '--return-mode']:
        ap.add_argument(option, default=None)
    ap.add_argument('--trace', action='store_true')
    ap.add_argument('--label', default='')
    ap.add_argument('--policy-set', default='framework', choices=['framework', 'legacy'])
    ap.add_argument('--override', default=None, help='framework only: trait=value,... (also weight.<intent>=w, derived.<key>=v)')
    a = ap.parse_args()
    a.max_active_minutes_set = a.max_active_minutes is not None
    if a.max_active_minutes is None:
        a.max_active_minutes = 240
    if not re.fullmatch(r'[A-Za-z0-9_-]+', a.batch):
        sys.exit('batch id: letters, digits, - and _ only')
    if a.command == 'report':
        sys.exit(0 if report(a.batch) else 1)
    if a.until == 'duration':
        default_label = f'{a.active_minutes:g}m'
    elif a.until == 'calendar':
        default_label = f'{a.calendar_hours:g}h-cal'
    else:
        default_label = a.until
    if a.policy_set == 'legacy':
        default_label = 'legacy-' + default_label
        if a.override:
            sys.exit('--override applies to the framework policy set only')
    label = a.label or default_label
    seeds = [int(s) for s in a.seeds.split(',') if s]
    profiles = [p for p in a.player_profile.split(',') if p]
    ok = True
    if a.command == 'determinism':
        first_ok, first, _ = run_one(a.batch, profiles[0], seeds[0], label, a)
        second_ok, second, _ = run_one(a.batch, profiles[0], seeds[0], 'repeat-' + label, a)
        same_events = first.get('events_sha256') is not None and first.get('events_sha256') == second.get('events_sha256')
        same_state = first.get('state_sha256') is not None and first.get('state_sha256') == second.get('state_sha256')
        print(f'DETERMINISM events {"IDENTICAL" if same_events else "DIFFERENT"} ({first.get("events")} vs {second.get("events")} events), '
              f'state {"IDENTICAL" if same_state else "DIFFERENT"}')
        ok = first_ok and second_ok and same_events and same_state
    else:
        for profile in profiles:
            for seed in seeds:
                ok = run_one(a.batch, profile, seed, label, a)[0] and ok
    report(a.batch)
    print('PLAYER_PROFILE_RUN', 'PASS' if ok else 'FAIL')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
