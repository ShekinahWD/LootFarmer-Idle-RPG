"""Change 34 Google Play screenshot finalizer, validator and review-sheet builder.

    python marketing/screenshots/finalize_screenshots.py           # copy, validate, manifest, review sheets
    python marketing/screenshots/finalize_screenshots.py --check   # validate what is on disk, write nothing

- Each raw master store_assets/raw/screenshots/<Device>/<Device>_NN.png (the untouched Godot capture)
  is copied byte for byte to store_assets/screenshots/<Device>/<Device>_NN.png (the upload file).
- Play rules (checked against the live help page 2026-10-28; recheck before upload): PNG, 24-bit RGB
  without alpha, exactly 9:16 portrait, each side 320..3840 px, <= 8 MB, exactly six per device class.
- Raster checks: no blank or flat frame, no uniform border band, the four device renders of one scene
  match each other (same moment) and differ clearly from the other five scenes.
- Gameplay postconditions are read from each capture's .log (summon happened, gear dropped and worn,
  merge ^0 -> ^100, drops on the ground, exploration, Prestige card selected).
- Writes store_assets/screenshots/screenshots_manifest.json (provenance), review sheets in
  store_assets/review/change_34/ and reduced copies in docs/Change_34_Evidence/ (tracked).
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_screenshot_manifest as M  # noqa: E402

STORE = ROOT / 'store_assets'
RAW = STORE / 'raw' / 'screenshots'
FINAL = STORE / 'screenshots'
OLD = STORE / 'screenshots_change_27' / 'final'
REVIEW = STORE / 'review' / 'change_34'
EVIDENCE = ROOT / 'docs' / 'Change_34_Evidence'
MAX_BYTES = 8 * 1024 * 1024

# Log lines each scene must contain (regular expressions over the capture's .log).
POSTCONDITIONS = {
    '01': [r'SUMMON \S+ helpers=2', r'PLAYER_SKILL lightning'],
    '02': [r'GEAR collect iron_sword ok=true', r'GEAR collect boss-teal-dinosaur_outfit_t2 ok=true',
           r'GEAR worn weapon=iron_sword outfit=boss-teal-dinosaur_outfit_t2', r'GEAR respawn after \S+ alive=true',
           r'GEAR seed 3402 ok=true'],
    '03': [r"MERGE_ALL 'Merge 100 spare copies' unit-red-scarf_outfit \^0 -> \^100"],
    '04': [r'farm drops near=\[".+"\]'],
    '05': [r'explore stage 2 explored=\d+%'],
    '06': [r'PRESTIGE batch=\["challenge_o1"', r'PRESTIGE card selected challenge_c3'],
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def thumb(path: Path, size=(270, 480)) -> Image.Image:
    with Image.open(path) as im:
        return im.convert('RGB').resize(size, Image.BOX)


def diff(a: Image.Image, b: Image.Image) -> float:
    return sum(ImageStat.Stat(ImageChops.difference(a, b)).mean) / 3


def check_png(path: Path, size: tuple[int, int]) -> list[str]:
    problems = []
    with Image.open(path) as im:
        if im.format != 'PNG': problems.append(f'{path.name}: not PNG')
        if im.mode != 'RGB': problems.append(f'{path.name}: mode {im.mode}, need 24-bit RGB without alpha')
        if im.size != size: problems.append(f'{path.name}: {im.size}, need {size}')
        w, h = im.size
        if w * 16 != h * 9: problems.append(f'{path.name}: not exactly 9:16')
        if not (320 <= min(w, h) and max(w, h) <= 3840): problems.append(f'{path.name}: side outside 320..3840')
        rgb = im.convert('RGB')
        if max(ImageStat.Stat(rgb).stddev) < 20: problems.append(f'{path.name}: nearly flat frame')
        # An added frame or letterbox shows as uniform bands on every edge. One flat edge alone can be
        # real content (05's top edge is unexplored fog), so only all four together fail.
        band = max(4, w // 100)
        flat = [max(ImageStat.Stat(rgb.crop(box)).stddev) < 1.0 for box in
                [(0, 0, w, band), (0, h - band, w, h), (0, 0, band, h), (w - band, 0, w, h)]]
        if all(flat): problems.append(f'{path.name}: uniform border band on every edge (frame or letterbox)')
    if path.stat().st_size > MAX_BYTES: problems.append(f'{path.name}: {path.stat().st_size} bytes > 8 MB')
    return problems


def font(size: int):
    for name in ['arial.ttf', 'DejaVuSans.ttf']:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def label(draw: ImageDraw.ImageDraw, xy, text: str, size=22, fill=(235, 235, 235)) -> None:
    draw.text(xy, text, font=font(size), fill=fill)


def sheet_by_scene(path: Path, folder: Path, cell=(270, 480)) -> None:
    """Rows: the six scenes in store order; columns: the four device classes (review only)."""
    pad, head = 10, 34
    w = len(M.DEVICES) * (cell[0] + pad) + pad + 70
    h = len(M.SCENES) * (cell[1] + pad + head) + pad + 30
    sheet = Image.new('RGB', (w, h), (22, 24, 30))
    d = ImageDraw.Draw(sheet)
    for c, (device, dw, dh) in enumerate(M.DEVICES):
        label(d, (70 + pad + c * (cell[0] + pad), 6), f'{device} {dw}x{dh}', 20)
    for r, (number, _s, _o, _f, notes) in enumerate(M.SCENES):
        y = 30 + r * (cell[1] + pad + head)
        label(d, (10, y + 4), number, 34, (255, 214, 92))
        label(d, (70, y + 6), notes, 18, (200, 205, 215))
        for c, (device, _w, _h) in enumerate(M.DEVICES):
            sheet.paste(thumb(folder / device / f'{device}_{number}.png', cell), (70 + pad + c * (cell[0] + pad), y + head))
    sheet.save(path, optimize=True)


def sheet_device(path: Path, folder: Path, device: str, cell=(360, 640)) -> None:
    """One device class, six images in store order at store-card width (360 px)."""
    pad = 12
    sheet = Image.new('RGB', (6 * (cell[0] + pad) + pad, cell[1] + 2 * pad + 30), (22, 24, 30))
    d = ImageDraw.Draw(sheet)
    for i, (number, *_rest) in enumerate(M.SCENES):
        x = pad + i * (cell[0] + pad)
        label(d, (x, 6), f'{device}_{number}', 20)
        with Image.open(folder / device / f'{device}_{number}.png') as im:
            sheet.paste(im.convert('RGB').resize(cell, Image.LANCZOS), (x, 34))
    sheet.save(path, optimize=True)


def before_after(path: Path, number: str, cell=(540, 960)) -> None:
    pad = 14
    sheet = Image.new('RGB', (2 * cell[0] + 3 * pad, cell[1] + pad + 44), (22, 24, 30))
    d = ImageDraw.Draw(sheet)
    for i, (title, folder) in enumerate([(f'BEFORE  Change 27 Phone_{number}', OLD), (f'AFTER  Change 34 Phone_{number}', FINAL)]):
        x = pad + i * (cell[0] + pad)
        label(d, (x, 10), title, 24, (255, 140, 120) if i == 0 else (140, 235, 150))
        with Image.open(folder / 'Phone' / f'Phone_{number}.png') as im:
            sheet.paste(im.convert('RGB').resize(cell, Image.LANCZOS), (x, 44))
    sheet.save(path, optimize=True)


def before_after_overview(path: Path, cell=(240, 427)) -> None:
    pad = 8
    sheet = Image.new('RGB', (6 * (cell[0] + pad) + pad + 110, 2 * (cell[1] + pad) + pad), (22, 24, 30))
    d = ImageDraw.Draw(sheet)
    for r, (title, folder) in enumerate([('BEFORE\nChange 27', OLD), ('AFTER\nChange 34', FINAL)]):
        y = pad + r * (cell[1] + pad)
        label(d, (8, y + cell[1] // 2 - 24), title, 20, (255, 140, 120) if r == 0 else (140, 235, 150))
        for c, (number, *_rest) in enumerate(M.SCENES):
            with Image.open(folder / 'Phone' / f'Phone_{number}.png') as im:
                sheet.paste(im.convert('RGB').resize(cell, Image.LANCZOS), (110 + pad + c * (cell[0] + pad), y))
    sheet.save(path, optimize=True)


def main() -> int:
    write = '--check' not in sys.argv
    problems: list[str] = []
    shots = []
    thumbs: dict[tuple[str, str], Image.Image] = {}
    for device, w, h in M.DEVICES:
        pngs = sorted(p.name for p in (RAW / device).glob('*.png'))
        expected = [f'{device}_{n}.png' for n, *_rest in M.SCENES]
        if pngs != expected: problems.append(f'{device}: raw files {pngs}, expected {expected}')
        for number, scenario, options, frame, notes in M.SCENES:
            raw = RAW / device / f'{device}_{number}.png'
            final = FINAL / device / f'{device}_{number}.png'
            if not raw.exists():
                problems.append(f'missing raw master {raw}'); continue
            problems += check_png(raw, (w, h))
            log = Path(str(raw) + '.log')
            text = log.read_text(encoding='utf-8', errors='replace') if log.exists() else ''
            for pattern in POSTCONDITIONS[number]:
                if not re.search(pattern, text): problems.append(f'{raw.name}: log lacks {pattern!r}')
            if 'SCRIPT ERROR' in text: problems.append(f'{raw.name}: SCRIPT ERROR in capture log')
            if write:
                final.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(raw, final)
            if not final.exists():
                problems.append(f'missing {final}'); continue
            if sha(final) != sha(raw): problems.append(f'{final.name}: differs from its raw master')
            thumbs[(device, number)] = thumb(final)
            shots.append({'file': f'store_assets/screenshots/{device}/{device}_{number}.png',
                          'raw_master': f'store_assets/raw/screenshots/{device}/{device}_{number}.png',
                          'capture_log': f'store_assets/raw/screenshots/{device}/{device}_{number}.png.log',
                          'device': device, 'requested_size': [w, h], 'actual_size': list(Image.open(final).size),
                          'concept': number, 'scenario': scenario, 'options': options, 'capture_frame': frame, 'fps': 30,
                          'notes': notes, 'bytes': final.stat().st_size, 'sha256': sha(final), 'identical_to_raw': True,
                          'log_events': [l.strip() for l in text.splitlines() if 'LOOTFARMER_MARKETING' in l and not l.lstrip().startswith('|')]})
        extra = sorted(p.name for p in (FINAL / device).glob('*.png')) if (FINAL / device).exists() else []
        if extra != expected and not write: problems.append(f'{device}: delivered files {extra}')
    # Same moment on every device class; clearly different from every other scene.
    similarity = {}
    if len(thumbs) == 24:
        for number, *_rest in M.SCENES:
            same = max(diff(thumbs[('Phone', number)], thumbs[(d, number)]) for d, _w, _h in M.DEVICES)
            other = min(diff(thumbs[('Phone', number)], thumbs[('Phone', n)]) for n, *_r in M.SCENES if n != number)
            similarity[number] = {'max_diff_across_devices': round(same, 2), 'min_diff_to_other_scenes': round(other, 2)}
            if same > 12: problems.append(f'scene {number}: devices differ by {same:.1f} (not the same moment?)')
            if other < 2 * same + 10: problems.append(f'scene {number}: too close to another scene ({other:.1f})')
    for number, text in M.ALT_TEXT.items():
        if len(text) > 140: problems.append(f'alt text {number}: {len(text)} characters > 140')
    if write and not problems:
        record = {
            'change': 34, 'toolkit': 'Godot Marketing Capture Toolkit 1.0.2', 'manifest': 'marketing/screenshots/manifest.json',
            'generator': 'marketing/screenshots/make_screenshot_manifest.py', 'adapter': 'marketing/game_scenarios.gd',
            'capture_profile': '--profile=capture-store --no-autosave --first-run-complete',
            'replaces': 'store_assets/screenshots_change_27/ (Change 27 set, raw and final, kept)',
            'screenshots': shots, 'similarity': similarity, 'alt_text_drafts': M.ALT_TEXT,
            'publication': 'NOT approved or uploaded. Pixel Plains art and assets/sounds audio lack retained licence records (REL-02).',
        }
        (FINAL / 'screenshots_manifest.json').write_bytes((json.dumps(record, indent=2) + '\n').encode('utf-8'))
        REVIEW.mkdir(parents=True, exist_ok=True)
        sheet_by_scene(REVIEW / 'contact_sheet_24.png', FINAL)
        for device, *_rest in M.DEVICES:
            sheet_device(REVIEW / f'store_cards_{device}.png', FINAL, device)
        for number, *_rest in M.SCENES:
            before_after(REVIEW / f'before_after_{number}.png', number)
        before_after_overview(REVIEW / 'before_after_overview.png')
        EVIDENCE.mkdir(parents=True, exist_ok=True)
        for name in ['contact_sheet_24.png', 'before_after_overview.png', 'store_cards_Phone.png']:
            with Image.open(REVIEW / name) as im:
                scale = 1 if im.width <= 2400 else 2400 / im.width
                im.convert('RGB').resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS).save(EVIDENCE / name.replace('.png', '.jpg'), quality=86)
        for number, *_rest in M.SCENES:
            with Image.open(REVIEW / f'before_after_{number}.png') as im:
                im.convert('RGB').save(EVIDENCE / f'before_after_{number}.jpg', quality=86)
        shutil.copyfile(FINAL / 'screenshots_manifest.json', EVIDENCE / 'screenshots_manifest.json')
    print('SCREENSHOTS', 'PASS' if not problems else 'FAIL', f'files={len(shots)}')
    for p in problems:
        print('  ' + p)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
