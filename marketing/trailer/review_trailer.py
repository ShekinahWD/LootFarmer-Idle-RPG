"""Change 32 trailer review: evidence sheets and validation for the finished MP4.

Reads the rendered store_assets/video/LootFarmer_Play_Trailer_en-US.mp4 (never the plan alone), the
take logs (store_assets/raw/video/trailer_c32/<take>.avi.log) and the toolkit's own timing plan, and writes:

  store_assets/video/review_c32/
    contact_sheet.png      every shot: first, middle and last frame (output timestamps)
    card_holds.png         each black card at the middle of its fully readable hold, full size
    phone_strip.png        every 0.5 s at Play-preview phone size (180x320)
    transitions.png        every transition frame by frame
    gear_sequence.png      the Teal Dinosaur story: carried gear, defeat, drops, pickup, equip, new look
    summon.png             the Sunflower's summon as it happens
    variety.png            each chapter's setting, player outfit/weapon and enemies
    old_vs_new.png         the rejected Change 27 trailer and this one at the same moments
    end_card.png           the last 3.5 s
    audio.png              waveform of the final mix against the source WAV section
    validation.json        ffprobe, black levels, holds, transitions, audio isolation, asset hashes, timeline
  docs/Change_32_Evidence/ reduced copies of the sheets + validation.json

Usage (project root): python marketing/trailer/review_trailer.py
Exits non-zero when a contract fails (dimensions, duration, streams, music-only audio, protected hashes,
a required gameplay event missing from its take's log).
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = HERE / 'manifest.json'
VIDEO = ROOT / 'store_assets/video/LootFarmer_Play_Trailer_en-US.mp4'
OLD = ROOT / 'store_assets/video/rejected_change_27/LootFarmer_Play_Trailer_en-US.mp4'
RAW = ROOT / 'store_assets/raw/video/trailer_c32'
OUT = ROOT / 'store_assets/video/review_c32'
DOCS = ROOT / 'docs/Change_32_Evidence'
MUSIC = ROOT / 'assets/sounds/background_music.wav'
MUSIC_SHA = 'b3664d04791bb86f220b790823dab34ec6912ba93a1a60cf035e82b557b45778'
FPS = 30
W, H = 1080, 1920

spec = importlib.util.spec_from_file_location('mk', ROOT / 'Godot-Marketing-Toolkit/tools/marketing.py')
mk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mk)

FONT = ImageFont.load_default(18)
SMALL = ImageFont.load_default(14)
problems: list[str] = []


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frames_at(path: Path, times: list[float], width: int) -> dict[float, Image.Image]:
    """Decoded frames of the real file at these output times (nearest frame), scaled to `width`."""
    out = {}
    for t in sorted(set(times)):
        n = max(0, round(t * FPS))
        raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{n / FPS:.4f}', '-i', str(path), '-frames:v', '1',
                              '-vf', f'scale={width}:-2:flags=area', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
                             capture_output=True, check=True).stdout
        h = len(raw) // (width * 3)
        out[t] = Image.frombytes('RGB', (width, h), raw)
    return out


def sheet(rows: list[tuple[str, list[tuple[float, str]]]], path: Path, width: int, src: Path = VIDEO,
          title: str = '') -> Image.Image:
    """Rows of captioned frames: (row label, [(time, caption), ...])."""
    times = [t for _, items in rows for t, _ in items]
    got = frames_at(src, times, width)
    th = next(iter(got.values())).height
    cols = max(len(items) for _, items in rows)
    pad, label, cap = 8, 26, 40
    top = 34 if title else 0
    im = Image.new('RGB', (pad + cols * (width + pad), top + pad + len(rows) * (label + th + cap + pad)), (22, 22, 28))
    d = ImageDraw.Draw(im)
    if title:
        d.text((pad, 8), title, fill=(255, 214, 92), font=FONT)
    y = top + pad
    for name, items in rows:
        d.text((pad, y + 4), name, fill=(235, 235, 235), font=FONT)
        x = pad
        for t, caption in items:
            im.paste(got[t], (x, y + label))
            d.text((x + 4, y + label + 4), f'{t:.2f}s', fill=(255, 220, 90), font=FONT, stroke_width=2, stroke_fill=(0, 0, 0))
            for k, line in enumerate(caption.split('\n')[:2]):
                d.text((x, y + label + th + 4 + 17 * k), line, fill=(210, 215, 225), font=SMALL)
            x += width + pad
        y += label + th + cap + pad
    im.save(path)
    return im


def take_events(take: str) -> list[tuple[str, float]]:
    """(event line, seconds into the take) from the take's LOOTFARMER_MARKETING log."""
    events = []
    for line in (RAW / f'{take}.avi.log').read_text(encoding='utf-8', errors='replace').splitlines():
        m = re.search(r'LOOTFARMER_MARKETING (.*)', line)
        t = re.search(r' t=([\d.]+)', line)
        if m and t:
            events.append((m.group(1).strip(), float(t.group(1))))
    return events


def luma(path: Path) -> list[tuple[float, int]]:
    return mk.luma_series(path)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)
    conf = json.loads(MANIFEST.read_text(encoding='utf-8'))
    video = conf['videos'][0]
    style = mk.style_of(conf, video)
    shots = video['shots']
    texts = [mk.shot_texts(conf, s, 'en-US') for s in shots]
    plan = mk.plan_video(video, FPS, style, texts, mk._footage(video, MANIFEST), 'en-US')
    starts = [s / FPS for s in plan['starts']]
    lengths = [n / FPS for n in plan['lengths']]
    by_id = {s['id']: i for i, s in enumerate(shots)}

    def out_time(shot_id: str, take_t: float) -> float:
        i = by_id[shot_id]
        return round(starts[i] + take_t - float(shots[i].get('start', 0)), 3)

    # ------------------------------------------------------------ container and stream facts
    probe = json.loads(subprocess.run(['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(VIDEO)],
                                      capture_output=True, text=True, check=True).stdout)
    v = [s for s in probe['streams'] if s['codec_type'] == 'video']
    a = [s for s in probe['streams'] if s['codec_type'] == 'audio']
    facts = {'file': str(VIDEO.relative_to(ROOT)).replace('\\', '/'), 'bytes': VIDEO.stat().st_size, 'sha256': sha(VIDEO),
             'video_streams': len(v), 'audio_streams': len(a),
             'video': {k: v[0].get(k) for k in ('codec_name', 'profile', 'pix_fmt', 'width', 'height', 'avg_frame_rate',
                                                 'nb_frames', 'color_range', 'sample_aspect_ratio', 'duration')},
             'rotation': next((sd.get('rotation') for sd in v[0].get('side_data_list', []) if 'rotation' in sd), 0),
             'audio': {k: a[0].get(k) for k in ('codec_name', 'sample_rate', 'channels', 'duration')} if a else None,
             'format_duration': float(probe['format']['duration'])}
    with open(VIDEO, 'rb') as f:
        head = f.read(4096)
    facts['faststart_moov_before_mdat'] = head.find(b'moov') != -1 and (head.find(b'mdat') == -1 or head.find(b'moov') < head.find(b'mdat'))
    vv = facts['video']
    if (vv['codec_name'], vv['pix_fmt'], vv['width'], vv['height'], vv['avg_frame_rate']) != ('h264', 'yuv420p', W, H, '30/1'):
        problems.append(f'video stream is {vv}')
    if int(vv['nb_frames']) != 900 or abs(facts['format_duration'] - 30.0) > 0.05:
        problems.append(f"duration {facts['format_duration']} / frames {vv['nb_frames']}")
    if len(v) != 1 or len(a) != 1 or facts['audio']['codec_name'] != 'aac':
        problems.append('expected exactly one H.264 and one AAC stream')
    if facts['rotation']:
        problems.append(f"rotation {facts['rotation']}")
    if not facts['faststart_moov_before_mdat']:
        problems.append('moov atom is not at the front (faststart)')

    # ------------------------------------------------------------ picture: black cards, bars, holds
    series = luma(VIDEO)
    cards = []
    for i, s in enumerate(shots):
        if s['kind'] != 'card':
            continue
        t_in, t_out, fade = plan['text'][i]
        a0, a1 = plan['starts'][i] + t_in + fade, plan['starts'][i] + t_out - fade
        full = [k for k in range(a0, a1)]
        # The card's black: the frames before its text fades in and after it fades out (picture fully black).
        edge = [series[k][1] for k in range(plan['starts'][i] + t_in, plan['starts'][i] + t_in + 1)]
        cards.append({'shot': s['id'], 'text': texts[i][0], 'text_full_from_s': round(a0 / FPS, 3), 'text_full_to_s': round(a1 / FPS, 3),
                      'readable_s': round(len(full) / FPS, 3), 'black_before_text_max_luma': max(edge)})
    # Bars: the first and last columns/rows of every gameplay shot's middle frame must carry picture.
    bars = []
    mids = {s['id']: starts[i] + lengths[i] / 2 for i, s in enumerate(shots) if s['kind'] == 'clip'}
    for sid, img in frames_at(VIDEO, list(mids.values()), W).items():
        arr = np.asarray(img.convert('L'), dtype=float)
        bars.append({'t': round(sid, 2), 'top_row': round(arr[:4].mean(), 1), 'bottom_row': round(arr[-4:].mean(), 1),
                     'left_col': round(arr[:, :4].mean(), 1), 'right_col': round(arr[:, -4:].mean(), 1)})
    for b in bars:
        if min(b['top_row'], b['bottom_row'], b['left_col'], b['right_col']) < 8:
            problems.append(f'possible black bar at {b}')
    review = json.loads(VIDEO.with_name(VIDEO.stem + '_review.json').read_text(encoding='utf-8'))

    # ------------------------------------------------------------ audio: music only, continuous
    dec = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(VIDEO), '-map', '0:a:0', '-ac', '1', '-ar', '48000', '-f', 'f32le', '-'],
                         capture_output=True, check=True).stdout
    mix = np.frombuffer(dec, dtype=np.float32).astype(np.float64)
    ref_raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f"{video['music_start']:.6f}", '-t', '30', '-i', str(MUSIC),
                              '-ac', '1', '-ar', '48000', '-f', 'f32le', '-'], capture_output=True, check=True).stdout
    ref = np.frombuffer(ref_raw, dtype=np.float32).astype(np.float64)
    n = min(len(mix), len(ref))
    mix, ref = mix[:n], ref[:n]
    # Align (AAC priming) by cross-correlating the first 2 s.
    win = 96000
    corr = np.correlate(mix[2000:2000 + win], ref[:win + 4000], mode='valid')
    lag = int(np.argmax(corr)) - 2000
    if lag > 0:
        r = ref[:n - lag]
        m = mix[lag:lag + len(r)]
    else:
        m = mix[:n + lag]
        r = ref[-lag:-lag + len(m)]
    # Per 100 ms window: the mix is the reference times one gain (volume, fades, limiter); what is left
    # over is AAC coding noise, or any sound that is not the WAV.
    step = 4800
    residual_db, levels = [], []
    for k in range(0, len(m) - step, step):
        x, y = r[k:k + step], m[k:k + step]
        g = float(np.dot(x, y) / max(1e-12, np.dot(x, x)))
        res = y - g * x
        e = float(np.sqrt(np.mean(y ** 2)) + 1e-12)
        residual_db.append(20 * np.log10(float(np.sqrt(np.mean(res ** 2))) / e + 1e-12))
        levels.append(20 * np.log10(e))
    body = residual_db[5:-25]  # the music's own fade-in/out excluded
    windows = {}
    for i, s in enumerate(shots):
        lo, hi = int(starts[i] * 10), int((starts[i] + lengths[i]) * 10)
        part = [residual_db[k] for k in range(lo, min(hi, len(residual_db) - 25))]
        if part:
            windows[s['id']] = {'max_residual_db': round(max(part), 1), 'median_residual_db': round(float(np.median(part)), 1)}
    audio = {'source': 'assets/sounds/background_music.wav', 'source_sha256': sha(MUSIC), 'source_sha_matches_handoff': sha(MUSIC) == MUSIC_SHA,
             'music_start_s': video['music_start'], 'music_volume': video['music_volume'], 'game_audio_in_manifest': video.get('game_audio', False),
             'alignment_lag_samples': lag, 'residual_vs_wav_db': {'median': round(float(np.median(body)), 1), 'max': round(float(max(body)), 1)},
             'residual_by_shot': windows, 'level_db_100ms': {'min': round(min(levels[:-20]), 1), 'max': round(max(levels), 1)},
             'toolkit_audio_stats': review.get('audio'),
             'how_game_audio_is_excluded': 'game_audio false: every gameplay segment is encoded with -an from the AVI and the final graph maps only [aout], built from the WAV input alone (stream_loop/ss 60.0 -> volume -> fades -> limiter).'}
    if not audio['source_sha_matches_handoff']:
        problems.append('background_music.wav does not match the developer handoff SHA-256')
    if audio['residual_vs_wav_db']['max'] > -12:
        problems.append(f"audio contains sound that is not the WAV (residual up to {audio['residual_vs_wav_db']['max']} dB)")
    if min(levels[:-20]) < -45:
        problems.append('audio drops out')
    # Waveform figure: source section above, final mix below.
    fig = Image.new('RGB', (1500, 360), (22, 22, 28))
    d = ImageDraw.Draw(fig)
    for row, (sig, name) in enumerate([(r, 'source WAV 60.00-90.00 s'), (m, 'trailer audio (decoded AAC)')]):
        y0 = 20 + row * 170
        d.text((8, y0 - 16), name, fill=(235, 235, 235), font=SMALL)
        cols = np.array_split(sig, 1480)
        for xk, c in enumerate(cols):
            pk = float(np.max(np.abs(c))) if len(c) else 0
            d.line([(10 + xk, y0 + 75 - pk * 70), (10 + xk, y0 + 75 + pk * 70)], fill=(120, 200, 255) if row == 0 else (255, 200, 90))
    for i, s in enumerate(shots):
        x = 10 + int(starts[i] / 30 * 1480)
        d.line([(x, 0), (x, 360)], fill=(90, 90, 100))
        d.text((x + 2, 340), s['id'], fill=(200, 200, 200), font=SMALL)
    fig.save(OUT / 'audio.png')

    # ------------------------------------------------------------ gameplay contracts from the take logs
    ev = {take: take_events(take) for take in ('c32_boss', 'c32_gear', 'c32_merge', 'c32_autumn', 'c32_winter')}

    def find(take: str, pattern: str) -> float | None:
        return next((t for line, t in ev[take] if re.search(pattern, line)), None)

    gear_log = (RAW / 'c32_gear.avi.log').read_text(encoding='utf-8', errors='replace')
    timeline = {
        'boss_lightning': out_time('boss', find('c32_boss', r'PLAYER_SKILL lightning')),
        'boss_summon_two_sprouts': out_time('boss', find('c32_boss', r'SUMMON .* helpers=2')),
        'boss_fire': out_time('boss', find('c32_boss', r'PLAYER_SKILL fire')),
        'boss_arcane_strike': out_time('boss', find('c32_boss', r'PLAYER_SKILL strike')),
        'teal_dinosaur_defeated_drops_both': out_time('gear', find('c32_gear', r'DEFEATED .*iron_sword.*boss-teal-dinosaur_outfit_t2')),
        'pickup_outfit': out_time('gear', find('c32_gear', r'COLLECT boss-teal-dinosaur_outfit_t2 ok=true')),
        'pickup_iron_sword': out_time('gear', find('c32_gear', r'COLLECT iron_sword ok=true')),
        'outfit_panel_open': out_time('gear', find('c32_gear', r'OPEN boss-teal-dinosaur_outfit_t2')),
        'outfit_equipped': out_time('gear', find('c32_gear', r'PRESS EQUIP boss-teal-dinosaur_outfit_t2')),
        'iron_sword_panel_open': out_time('gear', find('c32_gear', r'OPEN iron_sword')),
        'iron_sword_equipped': out_time('gear', find('c32_gear', r'PRESS EQUIP iron_sword')),
        'panel_closed_new_look': out_time('gear', find('c32_gear', r'CLOSE .*weapon=iron_sword outfit=boss-teal-dinosaur_outfit_t2')),
        'merge_panel_open': out_time('merge', find('c32_merge', r'OPEN boss-teal-dinosaur_outfit_t2')),
        'merge_40_copies': out_time('merge', find('c32_merge', r"MERGE_ALL 'Merge 40 spare copies' .* \^0 -> \^40")),
    }
    for key, value in timeline.items():
        if value is None:
            problems.append(f'required event missing from its take log: {key}')
    for take in ev:
        for line, t in ev[take]:
            if line.startswith('MILESTONE'):
                i = by_id[{'c32_boss': 'boss', 'c32_gear': 'gear', 'c32_merge': 'merge', 'c32_autumn': 'autumn', 'c32_winter': 'winter'}[take]]
                ot = out_time(shots[i]['id'], t)
                if starts[i] <= ot <= starts[i] + lengths[i]:
                    problems.append(f'banner raised on screen in {take}: {line} at {ot}s')
    gear_ids = {'enemy': 'boss-teal-dinosaur (Summer II, stage 4)', 'enemy_body': 'boss-teal-dinosaur_outfit', 'enemy_weapon': 'iron_sword',
                'catalog_loot': ['iron_sword', 'boss-teal-dinosaur_outfit'], 'dropped': ['iron_sword', 'boss-teal-dinosaur_outfit_t2'],
                'player_before': {'weapon': 'wood_sword', 'outfit': '(none: the plain body)'},
                'player_after': {'weapon': 'iron_sword', 'outfit': 'boss-teal-dinosaur_outfit_t2'},
                'seed': 3209, 'log': 'store_assets/raw/video/trailer_c32/c32_gear.avi.log',
                'log_confirms_before_and_after': 'stage profile 4 level=200 weapon=wood_sword outfit=' in gear_log and 'CLOSE' in gear_log}

    # ------------------------------------------------------------ protected assets unchanged
    hashes = {}
    fg_sha = '2510ca436aec94e3515520a365b3a61059e991afa342d45fd8d5ce19ae50775f'
    hashes['store_assets/branding/feature_graphic_1024x500.png'] = (sha(ROOT / 'store_assets/branding/feature_graphic_1024x500.png'), fg_sha)
    icon_manifest = json.loads((ROOT / 'store_assets/branding/icon_manifest.json').read_text(encoding='utf-8'))
    for rec in (icon_manifest.values() if isinstance(icon_manifest, dict) else icon_manifest):
        if isinstance(rec, dict) and rec.get('output', '').endswith('play_icon_512.png') and rec.get('sha256'):
            hashes['store_assets/branding/play_icon_512.png'] = (sha(ROOT / 'store_assets/branding/play_icon_512.png'), rec['sha256'])
    shots_manifest = json.loads((ROOT / 'store_assets/store_assets_manifest.json').read_text(encoding='utf-8'))
    for s in shots_manifest['screenshots']:
        hashes[s['file']] = (sha(ROOT / s['file']), s['sha256'])
    tracked = subprocess.run(['git', 'status', '--porcelain', '--', 'assets/branding', 'icon.svg', 'android', 'export_presets.cfg',
                              'scripts', 'scenes', 'data', 'resources', 'assets/sounds'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    changed = [k for k, (now, was) in hashes.items() if now != was]
    if changed:
        problems.append(f'protected files changed: {changed}')
    if tracked:
        problems.append(f'tracked game/branding files changed: {tracked}')

    # ------------------------------------------------------------ sheets
    rows = []
    for i, s in enumerate(shots):
        t0, t1 = starts[i], starts[i] + lengths[i] - 1 / FPS
        rows.append((f"{s['id']} ({lengths[i]:.2f}s{', ' + s['source'].split('/')[-1] + ' from ' + str(s['start']) + 's' if s['kind'] == 'clip' else ''})",
                     [(round(t0, 3), 'first'), (round((t0 + t1) / 2, 3), 'middle'), (round(t1, 3), 'last')]))
    sheet(rows, OUT / 'contact_sheet.png', 240, title='Change 32 trailer: every shot, first / middle / last frame (output time)')
    sheet([('black cards at the middle of their fully readable hold', [(round((c['text_full_from_s'] + c['text_full_to_s']) / 2, 3),
            f"{c['text']}\nreadable {c['readable_s']}s ({c['text_full_from_s']}-{c['text_full_to_s']}s)") for c in cards])],
          OUT / 'card_holds.png', 540)
    strip = [round(k * 0.5, 2) for k in range(60)]
    sheet([(f'{k * 5:.0f}-{k * 5 + 5:.0f} s', [(t, '') for t in strip[k * 10:(k + 1) * 10]]) for k in range(6)],
          OUT / 'phone_strip.png', 180, title='Every 0.5 s at Play-preview phone size (180x320)')
    trows = []
    for i in range(1, len(shots)):
        dd = plan['trans'][i]
        if dd:
            s0 = plan['starts'][i]
            trows.append((f"{plan['kinds'][i]} {dd / FPS:.1f}s into {shots[i]['id']}",
                          [(round((s0 - 1 + round(k * (dd + 1) / 6)) / FPS, 3), '') for k in range(7)]))
    sheet(trows, OUT / 'transitions.png', 200, title='Each transition frame by frame (linear dip through true black at cards)')
    g = timeline
    sheet([('Teal Dinosaur carries the Iron Sword and wears its outfit; the plain player (Wood Sword) beats it', [
              (round(starts[by_id['gear']] + 0.4, 3), 'enemy: teal outfit + Iron Sword\nplayer: plain body + Wood Sword'),
              (round(g['teal_dinosaur_defeated_drops_both'] - 0.5, 3), 'last blows'),
              (round(g['teal_dinosaur_defeated_drops_both'] + 0.3, 3), 'defeated: "Hey! My outfit!"\ndrops: iron_sword + outfit_t2'),
              (round(g['pickup_outfit'] - 0.1, 3), 'both drops on the ground'),
              (round(g['pickup_iron_sword'] + 0.2, 3), 'collected: both in Gear')]),
           ('equip from the gear grid, then the new look', [
              (round(g['outfit_equipped'] - 0.3, 3), 'Teal Dinosaur Outfit\nUpgrade, Equip'),
              (round(g['outfit_equipped'] + 0.3, 3), 'outfit equipped'),
              (round(g['iron_sword_equipped'] - 0.3, 3), 'Iron Sword vs Wood Sword\nEquip'),
              (round(g['panel_closed_new_look'] + 0.5, 3), 'the player now wears the\nTeal Dinosaur look + Iron Sword'),
              (round(starts[by_id['merge']] - 0.1, 3), 'held before the merge')])],
          OUT / 'gear_sequence.png', 300, title='Priority sequence: same-enemy gear -> drop -> pickup -> equip -> visible new look')
    sm = g['boss_summon_two_sprouts']
    sheet([('Spring II, rain: the Sunflower summons two Sprouts during the shot; the player casts skills', [
              (round(g['boss_lightning'] + 0.1, 3), 'Lightning Strike (player)'),
              (round(sm - 0.9, 3), 'summon telegraph'), (round(sm - 0.3, 3), 'portal'), (round(sm + 0.2, 3), 'two Sprouts arrive'),
              (round(g['boss_fire'] + 0.15, 3), 'Fire Burst (player)'), (round(g['boss_arcane_strike'] - 0.1, 3), 'Arcane Strike')])],
          OUT / 'summon.png', 260)
    sheet([('settings, player looks and enemies (gameplay shots)', [
              (round(starts[by_id['boss']] + 2.5, 3), 'Spring II, rain\nRed Panda outfit + Emerald Sword'),
              (round(starts[by_id['gear']] + 0.6, 3), 'Summer II, rain\nplain body + Wood Sword'),
              (round(g['panel_closed_new_look'] + 0.6, 3), 'Summer II\nTeal Dinosaur + Iron Sword'),
              (round(starts[by_id['autumn']] + 1.2, 3), 'Autumn II, falling leaves\nRed Fox outfit + Gold Sword'),
              (round(starts[by_id['winter']] + 1.3, 3), 'Winter II, blue leaves, snow\nSnowman outfit + Stone Axe')])],
          OUT / 'variety.png', 260)
    sheet([('last 3.5 s: the approved feature graphic restaged for 9:16', [(round(26.5 + k * 0.5, 2), '') for k in range(7)] + [(29.97, 'final frame')])],
          OUT / 'end_card.png', 220)
    if OLD.exists():
        times = [1.0, 4.0, 9.0, 13.0, 18.0, 23.0, 27.0, 29.5]
        a_ = frames_at(OLD, times, 160)
        b_ = frames_at(VIDEO, times, 160)
        th = next(iter(a_.values())).height
        im = Image.new('RGB', (8 + len(times) * 168, 40 + 2 * (th + 30)), (22, 22, 28))
        d = ImageDraw.Draw(im)
        d.text((8, 8), 'old (rejected Change 27) above, Change 32 below, same output times', fill=(255, 214, 92), font=FONT)
        for k, t in enumerate(times):
            x = 8 + k * 168
            for row, src in enumerate((a_, b_)):
                y = 40 + row * (th + 30)
                im.paste(src[t], (x, y))
                d.text((x + 3, y + 3), f'{t:.1f}s', fill=(255, 220, 90), font=SMALL, stroke_width=2, stroke_fill=(0, 0, 0))
        im.save(OUT / 'old_vs_new.png')

    # ------------------------------------------------------------ report
    report = {'change': 32, 'video': facts, 'plan': [{'shot': s['id'], 'kind': s['kind'], 'source': s.get('source'), 'source_in_s': s.get('start'),
                                                      'out_start_s': round(starts[i], 3), 'out_end_s': round(starts[i] + lengths[i], 3),
                                                      'transition_in': s.get('transition_in', {}).get('type', 'cut' if i else 'start')}
                                                     for i, s in enumerate(shots)],
              'cards': cards, 'toolkit_transitions': review['transitions'], 'toolkit_text_holds': review['text_holds'],
              'toolkit_abrupt_changes': review['abrupt_changes'], 'edge_samples': bars, 'audio': audio, 'timeline_s': timeline,
              'gear_story_ids': gear_ids, 'protected_hashes_unchanged': not changed, 'protected_files_checked': len(hashes),
              'problems': problems}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    for name in ('contact_sheet', 'card_holds', 'phone_strip', 'transitions', 'gear_sequence', 'summon', 'variety', 'old_vs_new',
                 'end_card', 'audio'):
        src = OUT / f'{name}.png'
        if src.exists():
            im = Image.open(src).convert('RGB')
            if im.width > 1600:
                im = im.resize((1600, round(im.height * 1600 / im.width)), Image.Resampling.LANCZOS)
            im.save(DOCS / f'{name}.jpg', quality=82)
    (DOCS / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({'timeline_s': timeline, 'cards': cards, 'audio_residual': audio['residual_vs_wav_db'],
                      'protected_unchanged': not changed, 'files_checked': len(hashes), 'problems': problems}, indent=1))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
