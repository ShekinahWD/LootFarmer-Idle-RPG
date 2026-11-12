"""Frame compositor for the LootFarmer social masters (marketing/social/build_social.py).

Reads recorded takes through FFmpeg (raw RGB frames), frames each shot (crop window, slow push, speed),
stacks split screens, applies cuts / flashes / crossfades, draws the text overlays with Pillow (Lilita One,
the game's title face) inside the platform-safe area, and pipes the frames to one H.264 encode with the
audio. No footage is generated here: every picture is a recorded take, a recorded older-build take, or the
approved end card.
"""
import json
import math
import subprocess
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
W, H, FPS = 1080, 1920, 30
# Platform-safe text box (Playbook 133.5): clear of the top 8%, bottom 22% and right 12%; left 5.5%.
SAFE = (60, 154, 950, 1497)
FONT = ROOT / 'assets/GUIPackCartoon/Demo/Fonts/LilitaOne - Regular.ttf'
MUSIC = ROOT / 'assets/sounds/background_music.wav'
BEAT = 60.0 / 145.0          # the track's beat (measured); downbeats fall at 0.42 s + k * 2 beats
INK = (24, 20, 46)
GOLD = (255, 205, 64)
WHITE = (255, 255, 255)
RED = (255, 96, 88)
GREEN = (120, 235, 130)


def music_in(k: int) -> float:
    """Start time in the track of its k-th two-beat downbeat."""
    return 0.42 + k * 2 * BEAT


def ease(u: float) -> float:
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size)


def decode(path: Path, start: float, n: int, speed: float = 1.0):
    """Yields n RGB frames (numpy, source size) from `start` seconds at `speed`."""
    vf = (f'setpts=PTS/{speed},' if speed != 1.0 else '') + f'fps={FPS}'
    cmd = ['ffmpeg', '-v', 'error', '-ss', f'{start:.4f}', '-i', str(path), '-an', '-vf', vf, '-frames:v', str(n),
           '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-']
    probe = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height',
                            '-of', 'csv=p=0', str(path)], capture_output=True, text=True).stdout.strip().split(',')
    sw, sh = int(probe[0]), int(probe[1])
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    size = sw * sh * 3
    last = None
    try:
        for _ in range(n):
            buf = proc.stdout.read(size)
            if len(buf) < size:
                if last is None:
                    raise RuntimeError(f'no frames from {path} at {start}')
                yield last          # a take that ends a frame early holds its last frame
                continue
            last = np.frombuffer(buf, np.uint8).reshape(sh, sw, 3)
            yield last
    finally:
        proc.stdout.close()
        proc.kill()


def framed(frame: np.ndarray, view, out_w: int, out_h: int) -> Image.Image:
    """Crop window centred on (cx, cy) source px with `zoom` (1 = the whole width for a full-height region)."""
    sh, sw = frame.shape[:2]
    cx, cy, zoom = view
    bw = sw / zoom
    bh = bw * out_h / out_w
    left = min(max(0.0, cx - bw / 2), sw - bw)
    top = min(max(0.0, cy - bh / 2), sh - bh)
    img = Image.fromarray(frame)
    if zoom == 1.0 and out_w == sw and out_h == sh:
        return img
    return img.resize((out_w, out_h), Image.BICUBIC, box=(left, top, left + bw, top + bh))


class Shot:
    """One timeline shot. spec keys: src (path), t (source seconds), d (output seconds), speed, view / view2
    (cx, cy, zoom; view2 = end of a slow move), dim (0..1 brightness), into ('cut' | 'flash' | ('xfade', frames)),
    split ([spec, spec] stacked top/bottom), card ((r, g, b) solid colour), fx (callable(frame_array, local_i))."""

    def __init__(self, spec: dict, region=(W, H)):
        self.spec = spec
        self.region = region
        self.n = round(float(spec['d']) * FPS)
        self.parts = [Shot(dict(s, d=spec['d']), (W, H // 2 - 3)) for s in spec['split']] if 'split' in spec else []
        self.gen = None
        self.i = 0

    def frame(self) -> Image.Image:
        s = self.spec
        w, h = self.region
        if self.parts:
            img = Image.new('RGB', (W, H), INK)
            img.paste(self.parts[0].frame(), (0, 0))
            img.paste(self.parts[1].frame(), (0, H // 2 + 3))
        elif 'card' in s:
            img = Image.new('RGB', (w, h), tuple(s['card']))
        else:
            if self.gen is None:
                self.gen = decode(Path(s['src']), float(s.get('t', 0.0)), self.n, float(s.get('speed', 1.0)))
            arr = next(self.gen)
            if 'fx' in s:
                arr = s['fx'](arr, self.i)
            v0 = s.get('view', (arr.shape[1] / 2, arr.shape[0] / 2, 1.0))
            v1 = s.get('view2', v0)
            u = ease(self.i / max(1, self.n - 1)) if s.get('ease', True) else self.i / max(1, self.n - 1)
            view = tuple(a + (b - a) * u for a, b in zip(v0, v1))
            img = framed(arr, view, w, h)
        dim = float(s.get('dim', 1.0))
        if dim != 1.0:
            img = Image.eval(img, lambda p: int(p * dim))
        self.i += 1
        return img


def text_layer(lines, size=96, color=WHITE, stroke=None, spacing=1.08, plate=None, max_w=SAFE[2] - SAFE[0]):
    """RGBA image of centred lines. A line is a str or (str, colour) or (str, colour, size)."""
    rows = []
    for ln in lines:
        txt, col, sz = (ln, color, size) if isinstance(ln, str) else (ln[0], ln[1], ln[2] if len(ln) > 2 else size)
        f = font(sz)
        while f.getlength(txt) > max_w and sz > 30:
            sz -= 2
            f = font(sz)
        rows.append((txt, col, f, sz))
    sw = stroke if stroke is not None else max(6, size // 9)
    widths = [f.getlength(t) for t, _, f, _ in rows]
    heights = [int(sz * spacing) for _, _, _, sz in rows]
    pad = sw + 14
    tw, th = int(max(widths)) + 2 * pad, sum(heights) + 2 * pad
    px = 34 if plate else 0
    img = Image.new('RGBA', (tw + 2 * px, th + (20 if plate else 0)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if plate:
        d.rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius=36, fill=tuple(plate))
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ds = ImageDraw.Draw(shadow)
    y = pad + (10 if plate else 0)
    for (txt, col, f, sz), wd, hh in zip(rows, widths, heights):
        x = (img.width - wd) / 2
        ds.text((x, y + 8), txt, font=f, fill=(0, 0, 0, 150), stroke_width=sw, stroke_fill=(0, 0, 0, 150))
        y += hh
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(4)))
    d = ImageDraw.Draw(img)
    y = pad + (10 if plate else 0)
    for (txt, col, f, sz), wd, hh in zip(rows, widths, heights):
        x = (img.width - wd) / 2
        d.text((x, y), txt, font=f, fill=tuple(col) + (255,), stroke_width=sw, stroke_fill=INK + (255,))
        y += hh
    return img


class Overlay:
    """A text/label layer on the timeline. t0..t1 output seconds; (cx, cy) centre; anim 'pop' | 'fade' | 'slam'."""

    def __init__(self, t0, t1, layer: Image.Image, cx=(SAFE[0] + SAFE[2]) // 2, cy=420, anim='pop', safe=True, name=''):
        self.t0, self.t1, self.layer, self.cx, self.cy, self.anim, self.name = t0, t1, layer, cx, cy, anim, name
        self.box = (cx - layer.width // 2, cy - layer.height // 2, cx + layer.width // 2, cy + layer.height // 2)
        if safe and (self.box[0] < SAFE[0] - 40 or self.box[2] > SAFE[2] + 40 or self.box[1] < SAFE[1] or self.box[3] > SAFE[3]):
            raise ValueError(f'overlay {name!r} leaves the safe area: {self.box} vs {SAFE}')

    def draw(self, img: Image.Image, t: float) -> None:
        if not (self.t0 <= t < self.t1):
            return
        age, left = t - self.t0, self.t1 - t
        alpha, scale = 1.0, 1.0
        if self.anim == 'pop':
            u = min(1.0, age / 0.2)
            scale = 0.6 + 0.4 * (1 - (1 - u) ** 3) + 0.08 * math.sin(math.pi * u)
            alpha = min(1.0, age / 0.1)
        elif self.anim == 'slam':
            u = min(1.0, age / 0.14)
            scale = 1.9 - 0.9 * (1 - (1 - u) ** 3)
            alpha = min(1.0, age / 0.07)
        elif self.anim == 'fade':
            alpha = min(1.0, age / 0.2)
        alpha *= min(1.0, left / 0.12)
        layer = self.layer
        if abs(scale - 1.0) > 0.004:
            layer = layer.resize((max(1, int(layer.width * scale)), max(1, int(layer.height * scale))), Image.BILINEAR)
        if alpha < 0.999:
            a = layer.getchannel('A').point(lambda p: int(p * alpha))
            layer = layer.copy()
            layer.putalpha(a)
        img.paste(layer, (self.cx - layer.width // 2, self.cy - layer.height // 2), layer)


def text(t0, t1, lines, cy=420, size=96, color=WHITE, anim='pop', plate=None, cx=None, **kw) -> Overlay:
    layer = text_layer(list(lines), size=size, color=color, plate=plate, **kw)
    return Overlay(t0, t1, layer, cx=cx if cx is not None else (SAFE[0] + SAFE[2]) // 2, cy=cy, anim=anim,
                   name=' / '.join(l if isinstance(l, str) else l[0] for l in lines))


def tag(t0, t1, label, cy, color=WHITE, fill=(24, 20, 46, 225), size=54, cx=None, anim='fade') -> Overlay:
    layer = text_layer([label], size=size, color=color, stroke=4, plate=fill)
    cy = max(cy, SAFE[1] + layer.height // 2 + 2)   # a tag never rises above the safe box
    return Overlay(t0, t1, layer, cx=cx if cx is not None else SAFE[0] + layer.width // 2 + 6, cy=cy, anim=anim, name=label)


def render(video: dict, out: Path, audio_wav: Path) -> dict:
    """video: {shots: [spec...], overlays: [Overlay...], duration}. Returns the timeline record."""
    shots = [Shot(s) for s in video['shots']]
    starts, at = [], 0
    for sh in shots:
        into = sh.spec.get('into', 'cut')
        if isinstance(into, (tuple, list)) and into[0] == 'xfade':
            at -= int(into[1])
        starts.append(at)
        at += sh.n
    total = at
    want = round(float(video['duration']) * FPS)
    if total != want:
        raise ValueError(f"{video['id']}: timeline is {total} frames, wanted {want}")
    out.parent.mkdir(parents=True, exist_ok=True)
    enc = subprocess.Popen(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
         '-i', str(audio_wav),
         '-vf', 'scale=in_range=full:out_range=tv:out_color_matrix=bt709:flags=accurate_rnd+full_chroma_int,format=yuv420p',
         '-c:v', 'libx264', '-profile:v', 'high', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p',
         '-color_range', 'tv', '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709',
         '-c:a', 'aac', '-b:a', '192k', '-ar', '48000', '-ac', '2', '-shortest', '-movflags', '+faststart', str(out)],
        stdin=subprocess.PIPE)
    prev = None
    for i in range(total):
        t = i / FPS
        active = [(sh, st) for sh, st in zip(shots, starts) if st <= i < st + sh.n]
        img = None
        for sh, st in active:
            f = sh.frame()
            into = sh.spec.get('into', 'cut')
            local = i - st
            if img is None:
                img = f
            elif isinstance(into, (tuple, list)) and into[0] == 'xfade':
                img = Image.blend(img, f, ease((local + 1) / (int(into[1]) + 1)))
            else:
                img = f
            if into == 'flash' and local < 6:
                img = Image.blend(img, Image.new('RGB', img.size, (255, 255, 255)), 0.85 * (1 - local / 6) ** 2)
        if img is None:
            img = prev
        img = img.copy() if img is prev else img
        for ov in video.get('overlays', []):
            ov.draw(img, t)
        prev = img
        enc.stdin.write(img.tobytes())
    enc.stdin.close()
    if enc.wait() != 0:
        raise RuntimeError(f'encode failed: {out}')
    return {'id': video['id'], 'frames': total,
            'shots': [{'start': st / FPS, 'end': (st + sh.n) / FPS, 'src': str(sh.spec.get('src', sh.spec.get('split', 'card'))) if 'split' not in sh.spec else [p.spec['src'] for p in sh.parts],
                       't': sh.spec.get('t'), 'speed': sh.spec.get('speed', 1.0), 'into': sh.spec.get('into', 'cut'),
                       'note': sh.spec.get('note', '')} for sh, st in zip(shots, starts)],
            'overlays': [{'t0': o.t0, 't1': o.t1, 'text': o.name, 'box': o.box} for o in video.get('overlays', [])]}


# ---------------------------------------------------------------- audio

def music_track(out: Path, start: float, seconds: float, volume=0.85, fade_out=1.2, ceiling=0.80) -> None:
    """One continuous section of the developer's track. The gain is constant (no limiter pumping): the
    section is scaled so its sample peak sits at `ceiling` at most, which leaves room for AAC overshoot."""
    out.parent.mkdir(parents=True, exist_ok=True)
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{start:.4f}', '-t', f'{seconds:.4f}', '-i', str(MUSIC), '-vn',
                          '-ac', '2', '-ar', '48000', '-f', 'f32le', '-'], capture_output=True).stdout
    a = np.frombuffer(raw, np.float32).reshape(-1, 2).copy()
    n = int(seconds * 48000)
    a = np.pad(a[:n], ((0, max(0, n - len(a))), (0, 0)))
    gain = min(volume, ceiling / max(1e-6, float(np.abs(a).max())))
    a *= gain
    k = int(0.03 * 48000)
    a[:k] *= np.linspace(0, 1, k, dtype=np.float32)[:, None]
    k = int(fade_out * 48000)
    a[-k:] *= np.linspace(1, 0, k, dtype=np.float32)[:, None]
    with wave.open(str(out), 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(48000)
        w.writeframes((np.clip(a, -1, 1) * 32767).astype(np.int16).tobytes())
    return gain


def game_audio_track(out: Path, parts: list, seconds: float, volume=1.0, fade=0.012, bed=None) -> None:
    """The takes' own recorded game sound, cut exactly like the picture. parts: [(path, src_t, dur)] in order.
    bed = (track start seconds, level) adds the game's background music quietly underneath."""
    sr = 48000
    mix = np.zeros((int(seconds * sr) + sr, 2), np.float32)
    pos = 0
    for path, t, dur in parts:
        n = int(round(dur * sr))
        if path is not None:
            raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{t:.4f}', '-t', f'{dur:.4f}', '-i', str(path), '-vn',
                                  '-ac', '2', '-ar', str(sr), '-f', 'f32le', '-'], capture_output=True).stdout
            a = np.frombuffer(raw, np.float32).reshape(-1, 2)[:n]
            a = np.pad(a, ((0, n - len(a)), (0, 0))).copy()
            k = int(fade * sr)
            ramp = np.linspace(0, 1, k, dtype=np.float32)[:, None]
            a[:k] *= ramp
            a[-k:] *= ramp[::-1]
            mix[pos:pos + n] += a * volume
        pos += n
    mix = mix[:int(seconds * sr)]
    if bed:
        # The game's own background music under its effects, as in play (the takes mute it so cuts never restart it).
        start, level = bed
        raw = subprocess.run(['ffmpeg', '-v', 'error', '-ss', f'{start:.4f}', '-t', f'{seconds:.4f}', '-i', str(MUSIC), '-vn',
                              '-ac', '2', '-ar', str(sr), '-f', 'f32le', '-'], capture_output=True).stdout
        m = np.frombuffer(raw, np.float32).reshape(-1, 2)[:len(mix)]
        mix[:len(m)] += m * level
    k = int(0.5 * sr)
    mix[-k:] *= np.linspace(1, 0, k, dtype=np.float32)[:, None]
    peak = float(np.abs(mix).max())
    if peak > 0.80:
        mix *= 0.80 / peak
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((np.clip(mix, -1, 1) * 32767).astype(np.int16).tobytes())


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes((json.dumps(data, indent=2, default=str) + chr(10)).encode('utf-8'))
