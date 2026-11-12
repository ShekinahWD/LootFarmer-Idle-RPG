"""Technical validation and review sheets for the ten social masters (store_assets/video/social/).

    python marketing/social/review_social.py

Writes store_assets/video/social/review/: validation.json, one contact sheet per video (a frame every second),
overview.png (the whole set, phone-size frames) and overview_first_frames.png. Exits non-zero when a contract
fails. Contracts: 1080x1920, 30 fps, 450 frames, 15.000 s, H.264 High yuv420p (TV range), one AAC 48 kHz stereo
stream, faststart, no black frame, every cut on the planned frame, text inside the platform-safe box, audio peak
below -0.9 dBFS without a dropout, music videos carrying only the developer's track, and every earlier approved
medium byte-identical to its hash taken before this work.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_social as B  # noqa: E402
import social_engine as E  # noqa: E402

ROOT = E.ROOT
OUT = B.OUT
REVIEW = OUT / 'review'


def probe(path: Path) -> dict:
    r = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format', '-of', 'json', str(path)],
                       capture_output=True, text=True)
    return json.loads(r.stdout)


def faststart(path: Path) -> bool:
    data = path.read_bytes()[:4_000_000]
    return 0 <= data.find(b'moov') < data.find(b'mdat')


def luma(path: Path, w=54, h=96) -> np.ndarray:
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-vf', f'scale={w}:{h}:flags=area,format=gray', '-f', 'rawvideo', '-'],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, h, w).astype(np.float32)


def audio(path: Path, start=None, seconds=None) -> np.ndarray:
    cmd = ['ffmpeg', '-v', 'error']
    if start is not None:
        cmd += ['-ss', f'{start:.4f}', '-t', f'{seconds:.4f}']
    cmd += ['-i', str(path), '-vn', '-ac', '2', '-ar', '48000', '-f', 'f32le', '-']
    # Both channels (FFmpeg's float mono downmix is not normalised, so peaks are read per channel).
    return np.frombuffer(subprocess.run(cmd, capture_output=True).stdout, np.float32).reshape(-1, 2)


def db(x: float) -> float:
    return round(20 * np.log10(max(x, 1e-9)), 2)


def frame(path: Path, t: float, w: int, h: int) -> Image.Image:
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{t:.3f}', '-i', str(path), '-frames:v', '1', '-vf', f'scale={w}:{h}:flags=lanczos',
                          '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], capture_output=True).stdout
    return Image.frombytes('RGB', (w, h), raw)


def label(img: Image.Image, txt: str, xy=(6, 4), size=20) -> None:
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(str(E.FONT), size)
    d.text(xy, txt, font=f, fill=(255, 235, 120), stroke_width=3, stroke_fill=(10, 10, 20))


def check(n: int) -> dict:
    path = B.output(n)
    tl = json.loads((OUT / 'timelines' / f'{n:02d}_{B.VIDEOS[n][0]}.json').read_text(encoding='utf-8'))
    p = probe(path)
    v = [s for s in p['streams'] if s['codec_type'] == 'video']
    a = [s for s in p['streams'] if s['codec_type'] == 'audio']
    fails = []

    def need(ok, msg):
        if not ok:
            fails.append(msg)

    need(len(v) == 1 and len(a) == 1, 'one video and one audio stream')
    vs, au = v[0], a[0]
    need(vs['codec_name'] == 'h264' and vs.get('profile') == 'High', 'H.264 High')
    need(vs['pix_fmt'] == 'yuv420p' and vs.get('color_range') == 'tv', 'yuv420p TV range')
    need((vs['width'], vs['height']) == (1080, 1920), '1080x1920')
    want = float(tl['duration'])
    need(vs['r_frame_rate'] == '30/1' and int(vs['nb_read_frames']) == round(want * 30), f'30 fps, {round(want * 30)} frames')
    dur = float(p['format']['duration'])
    need(abs(dur - want) <= 0.05, f'duration {dur} (planned {want})')
    need(au['codec_name'] == 'aac' and au['sample_rate'] == '48000' and int(au['channels']) == 2, 'AAC 48 kHz stereo')
    need(faststart(path), 'faststart')
    # picture
    y = luma(path)
    means = y.mean(axis=(1, 2))
    need(float(means.min()) > 10.0, f'black frame at {int(means.argmin())} (luma {means.min():.1f})')
    diff = np.abs(np.diff(y, axis=0)).mean(axis=(1, 2))
    planned = sorted({round(s['start'] * 30) for s in tl['shots'] if s['start'] > 0})
    missing = [f for f in planned if diff[f - 1] < 1.2 and not any(isinstance(s['into'], list) for s in tl['shots'] if round(s['start'] * 30) == f)]
    need(not missing, f'planned cuts not visible at frames {missing}')
    # text
    sx0, sy0, sx1, sy1 = E.SAFE
    for o in tl['overlays']:
        b = o['box']
        need(b[0] >= sx0 - 40 and b[2] <= sx1 + 40 and b[1] >= sy0 and b[3] <= sy1, f"text outside the safe box: {o['text']}")
    texts = [{'text': o['text'], 't0': o['t0'], 't1': o['t1'], 'seconds': round(o['t1'] - o['t0'], 2), 'label': o.get('label', False),
              'chars_per_second': round(len(o['text'].replace(' / ', ' ')) / (o['t1'] - o['t0']), 1)} for o in tl['overlays']]
    # Reading time (revision 2): a caption stays at least 1.4 s and asks for at most 14 characters per second.
    for x in texts:
        if not x['label']:
            need(x['seconds'] >= 1.4 and x['chars_per_second'] <= 14.0, f"caption too fast: {x['text']} ({x['seconds']} s, {x['chars_per_second']} cps)")
    # sound
    stereo = audio(path)
    peak = float(np.abs(stereo).max())
    x = stereo.mean(axis=1)
    need(peak <= 10 ** (-0.9 / 20) + 1e-3, f'audio peak {db(peak)} dBFS')
    win = 4800
    rms = np.sqrt(np.add.reduceat(x ** 2, np.arange(0, len(x) - win, win)) / win)
    quiet = [round(i * 0.1, 1) for i, r in enumerate(rms[:int((want - 0.8) * 10)]) if r < 10 ** (-50 / 20)]
    sound = {'peak_dbfs': db(peak), 'rms_dbfs': db(float(np.sqrt((x ** 2).mean()))), 'quiet_windows_below_-50dB_before_fade': quiet,
             'kind': tl['audio']['kind']}
    if tl['audio']['kind'] == 'music only':
        need(not quiet, f'audio dropout at {quiet[:5]}')
        src = audio(Path(tl['audio']['source']), tl['audio']['start'], want).mean(axis=1) * tl['audio']['volume']
        # AAC adds a priming delay: align by cross-correlation over a short search, then compare 1 s..13 s.
        seg = slice(48000, int(want - 2) * 48000)
        best, lag = -1.0, 0
        for step, span in ((16, 4000), (1, 20)):
            centre = lag
            for k in range(centre - span, centre + span + 1, step):
                c = float(np.dot(x[seg], src[seg.start + k:seg.stop + k]))
                if c > best:
                    best, lag = c, k
        ref = src[seg.start + lag:seg.stop + lag]
        corr = float(np.dot(x[seg], ref) / (np.linalg.norm(x[seg]) * np.linalg.norm(ref) + 1e-9))
        sound.update(music_start=tl['audio']['start'], correlation_with_source=round(corr, 4), lag_samples=lag)
        need(corr > 0.97, f'audio is not only the music track (correlation {corr:.3f})')
    else:
        need(not quiet, f'audio dropout at {quiet[:5]}')
    return {'video': path.name, 'ok': not fails, 'failures': fails, 'bytes': path.stat().st_size,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'duration': dur, 'frames': int(vs['nb_read_frames']),
            'video_stream': {k: vs.get(k) for k in ('codec_name', 'profile', 'width', 'height', 'pix_fmt', 'color_range', 'r_frame_rate', 'bit_rate')},
            'audio_stream': {k: au.get(k) for k in ('codec_name', 'sample_rate', 'channels', 'bit_rate')},
            'faststart': faststart(path), 'min_frame_luma': round(float(means.min()), 1), 'cuts_planned': planned,
            'meta': tl['meta'], 'sound': sound, 'texts': texts, 'shots': tl['shots']}


def sheets(ids) -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    cw, ch = 162, 288
    fracs = [0.007, 0.09, 0.18, 0.27, 0.36, 0.45, 0.54, 0.63, 0.72, 0.81, 0.96]
    over = Image.new('RGB', (len(fracs) * cw + 150, len(ids) * (ch + 6) + 40), (16, 14, 30))
    label(over, 'LootFarmer social set (revision 2): eleven frames spread over each video (phone-size check)', (8, 8), 18)
    firsts = Image.new('RGB', (len(ids) * 270, 480 + 34), (16, 14, 30))
    for row, n in enumerate(ids):
        path = B.output(n)
        dur = float(json.loads((OUT / 'timelines' / f'{n:02d}_{B.VIDEOS[n][0]}.json').read_text(encoding='utf-8'))['duration'])
        times = [f * dur for f in fracs]
        label(over, f'{n:02d}', (10, 40 + row * (ch + 6) + 100), 40)
        label(over, f'{dur:.1f} s', (8, 40 + row * (ch + 6) + 176), 18)
        label(over, B.VIDEOS[n][0], (8, 40 + row * (ch + 6) + 150), 16)
        for col, t in enumerate(times):
            over.paste(frame(path, t, cw, ch), (150 + col * cw, 40 + row * (ch + 6)))
        firsts.paste(frame(path, 0.0, 270, 480), (row * 270, 34))
        label(firsts, f'{n:02d} first frame', (row * 270 + 6, 4), 20)
        count = int(dur)
        rows = -(-count // 6)
        sheet = Image.new('RGB', (6 * 270, rows * 480), (16, 14, 30))
        for i in range(count):
            f = frame(path, i + 0.5, 270, 480)
            label(f, f'{i + 0.5:.1f} s')
            sheet.paste(f, ((i % 6) * 270, (i // 6) * 480))
        sheet.save(REVIEW / f'{n:02d}_{B.VIDEOS[n][0]}_sheet.png')
    over.save(REVIEW / 'overview.png')
    firsts.save(REVIEW / 'overview_first_frames.png')


def approved_unchanged() -> dict:
    before = ROOT / 'store_assets/raw/video/social/approved_hashes_before.txt'
    changed, count = [], 0
    for line in before.read_text(encoding='utf-8').splitlines():
        digest, name = line.split(None, 1)
        name = name.lstrip('*')
        path = ROOT / 'store_assets' / name
        count += 1
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            changed.append(name)
    return {'files': count, 'changed': changed}


def main() -> int:
    ids = [int(a) for a in sys.argv[1:]] or list(B.VIDEOS)
    results = [check(n) for n in ids]
    sheets(ids)
    approved = approved_unchanged()
    firsts = {r['video']: r['sha256'] for r in results}
    ok = all(r['ok'] for r in results) and not approved['changed'] and len(set(firsts.values())) == len(firsts)
    E.save_json(REVIEW / 'validation.json', {'ok': ok, 'approved_media_unchanged': approved, 'videos': results})
    for r in results:
        print(('PASS ' if r['ok'] else 'FAIL ') + r['video'], r['duration'], r['frames'], r['sound']['peak_dbfs'], r['sound'].get('correlation_with_source', ''),
              r['failures'])
    print('approved media:', approved, '| all ok:', ok)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
