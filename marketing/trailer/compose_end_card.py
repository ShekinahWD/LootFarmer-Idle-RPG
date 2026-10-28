"""Change 32 trailer end card: the approved portrait restaging of the feature graphic, animated.

Renders every layer of marketing/brand/feature_graphic/compositions/portrait_endcard_preview.json
with the feature-graphic composer's own layer painters (no copy of its code, no new art), checks that
stacking the layers reproduces the composer's full render exactly, then animates them per
end_card.json and writes a lossless 1080x1920 30 fps master for the trailer cut.

Usage (project root):  python marketing/trailer/compose_end_card.py
Outputs (ignored store_assets/raw/video/trailer_c32/):
    end_card.mkv           FFV1 RGB master, used as the trailer's last clip
    end_card_layers/NN_<layer>.png   every layer alone, full canvas, transparent
    end_card_final.png     the last frame (equals the static study)
The approved store files in store_assets/branding/ are only read, never written.
"""
from __future__ import annotations

import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = ROOT / 'store_assets/raw/video/trailer_c32'
sys.path.insert(0, str(ROOT / 'marketing/brand/feature_graphic'))
import compose_feature_graphic as fg  # noqa: E402


def layers(comp: dict) -> list[tuple[str, Image.Image]]:
    w, h = comp['size']
    out = []
    for spec in comp['layers']:
        if spec.get('skip'):
            continue
        alone = Image.new('RGBA', (w, h))
        fg.LAYERS[spec['type']](alone, spec)
        out.append((spec.get('name', spec['type']), alone))
    return out


def ease_out(x: float) -> float:
    x = min(1.0, max(0.0, x))
    return 1 - (1 - x) ** 3


def with_alpha(im: Image.Image, a: float) -> Image.Image:
    if a >= 1:
        return im
    r, g, b, alpha = im.split()
    return Image.merge('RGBA', (r, g, b, alpha.point(lambda v: round(v * a))))


def shifted(im: Image.Image, dy: int) -> Image.Image:
    if dy == 0:
        return im
    out = Image.new('RGBA', im.size)
    out.paste(im, (0, dy))
    return out


def scaled(im: Image.Image, k: float, about) -> Image.Image:
    if abs(k - 1) < 1e-4:
        return im
    cx, cy = about
    # Inverse affine: output (x, y) samples input ((x - cx) / k + cx, (y - cy) / k + cy).
    return im.transform(im.size, Image.Transform.AFFINE, (1 / k, 0, cx - cx / k, 0, 1 / k, cy - cy / k),
                        resample=Image.Resampling.BICUBIC)


def frame(stack, motion: dict, t: float, end: float, background) -> Image.Image:
    canvas = Image.new('RGBA', stack[0][1].size, background)
    for name, im in stack:
        m = motion.get(name)
        if m:
            x = (t - m['at']) / max(1e-6, m.get('dur', 0.0)) if m.get('dur') else (1.0 if t >= m['at'] else 0.0)
            if x <= 0:
                continue
            kind = m['kind']
            if kind == 'pop':
                pass
            elif kind == 'fade':
                im = with_alpha(im, min(1.0, x))
            elif kind == 'drop':
                e = ease_out(x)
                im = with_alpha(shifted(im, round(m['dy'] * (1 - e))), min(1.0, x * 1.6))
            elif kind == 'grow':
                e = ease_out(x)
                im = with_alpha(scaled(im, m['scale'] + (1 - m['scale']) * e, m['about']), min(1.0, x))
            if m.get('twinkle') and x >= 1:
                # Pulses, always back to full at the card's last frame.
                im = with_alpha(im, 1 - m['twinkle'] * (0.5 - 0.5 * math.cos(2 * math.pi * (end - t) / 0.6)))
        canvas.alpha_composite(im)
    return canvas


def main() -> int:
    spec = json.loads((HERE / 'end_card.json').read_text(encoding='utf-8'))
    comp = json.loads((HERE / spec['composition']).resolve().read_text(encoding='utf-8'))
    stack = layers(comp)
    background = fg.rgb(comp.get('background', [0, 0, 0]))
    names = {n for n, _ in stack}
    motion = {m['layer']: m for m in spec['motion']}
    if set(motion) - names:
        raise SystemExit(f'end_card.json names unknown layers: {sorted(set(motion) - names)}')
    # The stacked layers must equal the composer's own render (the approved study).
    full = fg.render(comp)
    stacked = Image.new('RGBA', full.size, background)
    for _, im in stack:
        stacked.alpha_composite(im)
    diff = ImageChops.difference(full.convert('RGB'), stacked.convert('RGB')).getbbox()
    if diff:
        raise SystemExit(f'stacked layers differ from the study render in {diff}')
    (OUT / 'end_card_layers').mkdir(parents=True, exist_ok=True)
    for i, (name, im) in enumerate(stack):
        im.save(OUT / 'end_card_layers' / f'{i:02d}_{name}.png')
    fps, seconds = int(spec['fps']), float(spec['seconds'])
    n = round(fps * seconds)
    w, h = comp['size']
    master = OUT / 'end_card.mkv'
    enc = subprocess.Popen(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
                            '-s', f'{w}x{h}', '-r', str(fps), '-i', '-', '-c:v', 'ffv1', '-pix_fmt', 'bgr0', str(master)],
                           stdin=subprocess.PIPE)
    last = None
    for k in range(n):
        last = frame(stack, motion, k / fps, (n - 1) / fps, background).convert('RGB')
        enc.stdin.write(last.tobytes())
    enc.stdin.close()
    if enc.wait():
        raise SystemExit('ffmpeg failed')
    last.save(OUT / 'end_card_final.png')
    same = ImageChops.difference(last, full.convert('RGB')).getbbox() is None
    print(f'END CARD OK: {master} ({n} frames, {w}x{h}, {fps} fps); last frame == study: {same}')
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main())
