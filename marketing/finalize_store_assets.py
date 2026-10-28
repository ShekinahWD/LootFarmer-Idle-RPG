"""Change 27 store-asset finalizer and validator (run after the toolkit's record/video steps and
marketing/brand/compose_brand.py).

    python marketing/finalize_store_assets.py            # copy, validate, write manifest + review sheets
    python marketing/finalize_store_assets.py --check    # validate what is on disk, write nothing

- Screenshots: each raw master store_assets/raw/screenshots/<Device>/<Device>_NN.png (the untouched
  Godot capture) is copied byte for byte to store_assets/screenshots/<Device>/<Device>_NN.png. Both
  must be 24-bit RGB PNG without alpha, exactly 9:16 portrait, the device class's target size, each side
  320..3840 px and <= 8 MB (Google Play screenshot rules checked 2026-10-28; recheck before upload).
- Trailer: ffprobe checks H.264 yuv420p 1080x1920 30 fps, 30.0 s, AAC audio, faststart.
- Icon / feature graphic: re-checked through compose_brand.check().
- Writes store_assets/store_assets_manifest.json (paths, sizes, SHA-256, scenario, options, device),
  store_assets/review/screenshots_contact_sheet.png and copies a small review set to
  docs/Change_27_Evidence/ (tracked; the bulky outputs stay in the ignored store_assets/).
"""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'marketing'))
sys.path.insert(0, str(ROOT / 'marketing' / 'brand'))
import make_manifest  # noqa: E402
import compose_brand  # noqa: E402

STORE = ROOT / 'store_assets'
EVIDENCE = ROOT / 'docs' / 'Change_27_Evidence'
TRAILER = STORE / 'video' / 'LootFarmer_Play_Trailer_en-US.mp4'
MAX_BYTES = 8 * 1024 * 1024

# Alt-text drafts (<= 140 characters) per concept, for review at listing time; never drawn on images.
ALT_TEXT = {
    '01': 'A Sunflower boss calls two Sprout helpers while the hero fights back with skills in Spring II.',
    '02': 'A defeated Bee boss leaves a Diamond Axe, a Recovery Salve and a Heal skill on the ground.',
    '03': 'Item details for the equipped Emerald Sword, with Merge ready to combine a duplicate copy.',
    '04': 'The hero fights a crowded pack of Spring II enemies with auto-attacks and skills.',
    '05': 'The Spring II world panel lists camps to travel to or unlock above the explored map.',
    '06': 'The Prestige panel shows two ready opportunities that will award permanent cards.',
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_png(path: Path, size: tuple[int, int]) -> list[str]:
    problems = []
    with Image.open(path) as im:
        if im.format != 'PNG': problems.append(f'{path.name}: not PNG')
        if im.mode != 'RGB': problems.append(f'{path.name}: mode {im.mode}, need 24-bit RGB without alpha')
        if im.size != size: problems.append(f'{path.name}: {im.size}, need {size}')
        w, h = im.size
        if w * 16 != h * 9: problems.append(f'{path.name}: not exactly 9:16')
        if not (320 <= min(w, h) and max(w, h) <= 3840): problems.append(f'{path.name}: side outside 320..3840')
    if path.stat().st_size > MAX_BYTES: problems.append(f'{path.name}: {path.stat().st_size} bytes > 8 MB')
    return problems


def probe_trailer() -> tuple[dict, list[str]]:
    if not TRAILER.exists():
        return {}, [f'missing {TRAILER}']
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries',
                          'format=duration,format_name:stream=codec_type,codec_name,pix_fmt,width,height,r_frame_rate,nb_frames,sample_rate,channels',
                          '-of', 'json', str(TRAILER)], capture_output=True, text=True, check=True)
    info = json.loads(out.stdout)
    video = next(s for s in info['streams'] if s['codec_type'] == 'video')
    audio = [s for s in info['streams'] if s['codec_type'] == 'audio']
    problems = []
    if video['codec_name'] != 'h264' or video['pix_fmt'] != 'yuv420p': problems.append(f'video {video["codec_name"]} {video["pix_fmt"]}')
    if (video['width'], video['height']) != (1080, 1920): problems.append(f'video size {video["width"]}x{video["height"]}')
    if video['r_frame_rate'] != '30/1': problems.append(f'fps {video["r_frame_rate"]}')
    if int(video.get('nb_frames', 0)) != 900: problems.append(f'frames {video.get("nb_frames")}')
    duration = float(info['format']['duration'])
    if abs(duration - 30.0) > 0.05: problems.append(f'duration {duration}')
    if not audio or audio[0]['codec_name'] != 'aac': problems.append('AAC audio missing')
    head = TRAILER.read_bytes()[:4096]
    if head.find(b'moov') < 0 or (head.find(b'mdat') >= 0 and head.find(b'moov') > head.find(b'mdat')): problems.append('moov atom not at the start (faststart)')
    summary = {'path': str(TRAILER.relative_to(ROOT)).replace('\\', '/'), 'bytes': TRAILER.stat().st_size, 'sha256': sha(TRAILER),
               'duration_s': duration, 'video': f'{video["codec_name"]} {video["pix_fmt"]} {video["width"]}x{video["height"]} {video["r_frame_rate"]} {video.get("nb_frames")} frames',
               'audio': f'{audio[0]["codec_name"]} {audio[0]["sample_rate"]} Hz {audio[0]["channels"]} ch' if audio else 'none'}
    return summary, problems


def contact_sheet(path: Path) -> None:
    cell = (300, 533)
    sheet = Image.new('RGB', (6 * cell[0] + 7 * 8, 4 * cell[1] + 5 * 8), (24, 26, 34))
    for r, (device, _, _) in enumerate(make_manifest.DEVICES):
        for c, (number, *_rest) in enumerate(make_manifest.SCREENSHOTS):
            with Image.open(STORE / 'screenshots' / device / f'{device}_{number}.png') as im:
                sheet.paste(im.resize(cell, Image.LANCZOS), (8 + c * (cell[0] + 8), 8 + r * (cell[1] + 8)))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, optimize=True)


def main() -> int:
    write = '--check' not in sys.argv
    problems: list[str] = []
    shots = []
    for device, w, h in make_manifest.DEVICES:
        for number, scenario, options, frame in make_manifest.SCREENSHOTS:
            raw = STORE / 'raw' / 'screenshots' / device / f'{device}_{number}.png'
            final = STORE / 'screenshots' / device / f'{device}_{number}.png'
            if not raw.exists():
                problems.append(f'missing raw master {raw}'); continue
            problems += check_png(raw, (w, h))
            if write:
                final.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(raw, final)
            if not final.exists():
                problems.append(f'missing {final}'); continue
            if sha(final) != sha(raw): problems.append(f'{final.name}: differs from its raw master')
            shots.append({'file': f'store_assets/screenshots/{device}/{device}_{number}.png',
                          'raw_master': f'store_assets/raw/screenshots/{device}/{device}_{number}.png',
                          'device': device, 'size': [w, h], 'concept': number, 'scenario': scenario, 'options': options,
                          'capture_frame': frame, 'fps': 30, 'bytes': final.stat().st_size, 'sha256': sha(final),
                          'identical_to_raw': True})
    trailer, trailer_problems = probe_trailer()
    problems += trailer_problems
    problems += compose_brand.check()
    if write and not problems:
        record = {
            'change': 27, 'toolkit': 'Godot Marketing Capture Toolkit 1.0.2', 'manifest': 'marketing/manifest.json',
            'adapter': 'marketing/game_scenarios.gd', 'capture_profile': '--profile=capture-store --no-autosave --first-run-complete',
            'screenshots': shots, 'alt_text_drafts': ALT_TEXT,
            'trailer': trailer | {'raw_clips': [f'store_assets/raw/video/{c[0]}.avi' for c in make_manifest.CLIPS],
                                  'clips': [{'id': c[0], 'scenario': c[1], 'options': c[2], 'seconds': c[3]} for c in make_manifest.CLIPS],
                                  'review': 'store_assets/video/LootFarmer_Play_Trailer_en-US_review.png'},
            'branding': json.loads((STORE / 'branding' / 'branding_manifest.json').read_text(encoding='utf-8')),
            'publication': 'NOT approved or uploaded. Pixel Plains art and assets/sounds audio lack retained licence records (REL-02).',
        }
        (STORE / 'store_assets_manifest.json').write_bytes((json.dumps(record, indent=2) + '\n').encode('utf-8'))
        contact_sheet(STORE / 'review' / 'screenshots_contact_sheet.png')
        EVIDENCE.mkdir(parents=True, exist_ok=True)
        # Change 28: the feature graphic's evidence lives in docs/Change_28_Evidence/ (make_review.py);
        # docs/Change_27_Evidence/feature_graphic_1024x500.png stays the rejected original.
        for src, dst in [(STORE / 'review' / 'screenshots_contact_sheet.png', 'screenshots_contact_sheet.png'),
                         (STORE / 'branding' / 'play_icon_512.png', 'play_icon_512.png'),
                         (STORE / 'branding' / 'review' / 'play_icon_sizes.png', 'play_icon_sizes.png'),
                         (STORE / 'branding' / 'review' / 'adaptive_masks.png', 'adaptive_icon_masks.png'),
                         (STORE / 'video' / 'LootFarmer_Play_Trailer_en-US_review.json', 'trailer_review.json'),
                         (STORE / 'store_assets_manifest.json', 'store_assets_manifest.json')]:
            shutil.copyfile(src, EVIDENCE / dst)
        with Image.open(STORE / 'video' / 'LootFarmer_Play_Trailer_en-US_review.png') as im:
            im.convert('RGB').resize((im.width // 2, im.height // 2), Image.LANCZOS).save(EVIDENCE / 'trailer_review_half.jpg', quality=82)
    print('STORE ASSETS', 'PASS' if not problems else 'FAIL', f'screenshots={len(shots)}', f'trailer={trailer.get("duration_s")}s')
    for p in problems:
        print('  ' + p)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
