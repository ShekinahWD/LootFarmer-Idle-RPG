"""Records social takes with the pinned toolkit, one after another (the toolkit's temporary override.cfg
allows one capture at a time), then prints each take's event summary and writes a contact sheet.

    python marketing/social/record_takes.py --draft [take ids...]     # 540x960 staging checks
    python marketing/social/record_takes.py [take ids...]             # 1080x1920 masters
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
GODOT = 'D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
TOOL = ROOT / 'Godot-Marketing-Toolkit/tools/marketing.py'


def sheet(avi: Path, out: Path, step: float = 0.5, cols: int = 8, width: int = 216) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(avi)],
                               capture_output=True, text=True).stdout.strip())
    n = int(dur / step)
    rows = -(-n // cols)
    vf = (f"fps=1/{step},scale={width}:-1,drawtext=text='%{{pts\\:hms}}':x=4:y=4:fontsize=18:fontcolor=yellow:box=1:boxcolor=black@0.6,"
          f"tile={cols}x{rows}")
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(avi), '-vf', vf, '-frames:v', '1', str(out)], check=True)


def summary(log: Path) -> None:
    hits = crits = 0
    for line in log.read_text(encoding='utf-8', errors='replace').splitlines():
        if 'LOOTFARMER_MARKETING' not in line and 'ERROR' not in line:
            continue
        text = line.split('LOOTFARMER_MARKETING', 1)[-1].strip()
        if text.startswith('HIT '):
            if ' t=0.0' in text and 'crit' in text and not text.startswith('HIT player'):
                pass
            if not text.startswith('HIT player'):
                hits += 1
                if 'crit=true' in text:
                    crits += 1
                    print('     ', text)
            continue
        if text.startswith('EVENT ') and re.search(r'EVENT (PICKUP|COLLECT|LOOT|ITEM_FOUND)', text):
            continue
        print('     ', text[:230])
    print(f'      hits on enemies={hits} crits={crits}')


def main() -> int:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--draft', action='store_true')
    p.add_argument('--manifest', default='')
    p.add_argument('--project', default=str(ROOT))
    p.add_argument('--no-record', action='store_true')
    p.add_argument('ids', nargs='*')
    a = p.parse_args()
    manifest = Path(a.manifest) if a.manifest else HERE / ('manifest_draft.json' if a.draft else 'manifest.json')
    conf = json.loads(manifest.read_text(encoding='utf-8'))
    failed = []
    for job in conf['capture_jobs']:
        if a.ids and job['id'] not in a.ids:
            continue
        out = (manifest.parent / job['output']).resolve()
        print(f"== {job['id']} ({job['duration']} s) -> {out}", flush=True)
        if not a.no_record:
            r = subprocess.run([sys.executable, str(TOOL), 'record', '--project', a.project, '--manifest', str(manifest),
                                '--job', job['id'], '--godot', GODOT, '--overwrite'], capture_output=True, text=True, encoding='utf-8', errors='replace',
                               env={**__import__('os').environ, 'PYTHONUTF8': '1', 'PYTHONIOENCODING': 'utf-8'})
            if r.returncode != 0:
                failed.append(job['id'])
                print('   FAILED', (r.stdout + r.stderr)[-600:])
        log = out.with_suffix('.avi.log')
        if log.exists():
            summary(log)
        if out.exists() and job['id'] not in failed:
            sheet(out, out.parent / 'sheets' / f"{job['id']}.png")
    print('failed:', failed)
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
