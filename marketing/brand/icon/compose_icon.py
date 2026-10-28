"""LootFarmer app icon (Change 30): one layered composition renders the Google Play icon and every
Android launcher layer, all from existing licensed game art.

A composition is drawn on a 32 x 32 **unit grid** (the Play icon / the launcher's visible viewport);
one unit is one source pixel of the game art. Each target renders the same grid at a whole-number
scale, so pixel art is never resampled by a fraction:

    play       512 px   16 px per unit   the full grid (Google Play masks the corners itself)
    launcher   192 px    6 px per unit   legacy icon (Android 7.x and the project/window icon)
    adaptive   432 px    9 px per unit   108 dp layers = the grid plus 8 units of bleed per side;
                                         the 72 dp viewport is the grid, the 66 dp safe zone is
                                         the circle of radius 14.67 units around (16, 16)

Layers are `back` (background plane) or `front` (foreground plane). The Play and legacy icons
composite all of them; the adaptive background is the back plane, the foreground is the front
plane, and the monochrome (themed) layer is the front plane's alpha with the dark outline pixels
cut out so the face and the sword stay readable when the launcher tints it.

Game art is drawn by the feature graphic's engine (marketing/brand/feature_graphic/), so an actor
is the exact body + attack-frame layout of scenes/game/actor.tscn, and `from_group` refuses an
outfit or weapon that enemy does not really carry or drop. Treatments (glow, rays, gradient,
vignette) are colour operations behind the art; nothing is painted or generated.

Usage (project root):
    python marketing/brand/icon/compose_icon.py            # concepts + final + review sheets
    python marketing/brand/icon/compose_icon.py final      # one composition (+ review sheets)
    python marketing/brand/icon/compose_icon.py --check    # validate the written icons, re-render, compare bytes
See README.md beside this script.
"""
from __future__ import annotations

import hashlib
import io
import json
import math
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'feature_graphic'))
import compose_feature_graphic as fg  # noqa: E402  (shared game-art engine)

ROOT = HERE.parents[2]
STORE = ROOT / 'store_assets/branding'
RUNTIME = ROOT / 'assets/branding'
REVIEW = STORE / 'review/icon'
EVIDENCE = ROOT / 'docs/Change_30_Evidence'
BUILD_ORDER = ['concept_a_costume_hero', 'concept_b_loot_drop', 'concept_c_close_up', 'final']
GRID = 32
TARGETS = {'play': (512, 16, 0), 'launcher': (192, 6, 0), 'adaptive': (432, 9, 8)}  # size, px/unit, bleed units
SAFE_RADIUS = 33 / 36 * GRID / 2  # 66 dp safe zone inside the 72 dp viewport, in units
BACK_TYPES = {'fill', 'gradient', 'glow', 'rays', 'vignette'}
FONT = ROOT / 'Godot-Marketing-Toolkit/assets/fonts/NotoSans[wdth,wght].ttf'
OLD_ICON = ROOT / 'docs/Change_27_Evidence/play_icon_512.png'  # the rejected Change 27 icon


# ----------------------------------------------------------------------------------------------- layers

class Target:
    def __init__(self, name: str):
        self.name = name
        self.size, self.k, self.bleed = TARGETS[name]

    def x(self, u: float) -> int:
        return int(round((u + self.bleed) * self.k))

    def at(self, p) -> list[int]:
        return [self.x(p[0]), self.x(p[1])]


def unit_field(t: Target, fn, pixel: bool = False) -> Image.Image:
    """An L image of fn(ux, uy) (numpy arrays in grid units). Smooth per output pixel by default;
    `pixel` evaluates once per unit cell and enlarges with nearest-neighbour (crisp unit steps)."""
    n = t.size // t.k if pixel else t.size
    step = t.k if pixel else 1
    c = (np.arange(n) + 0.5) * step / t.k - t.bleed
    ux, uy = np.meshgrid(c, c)
    v = np.clip(fn(ux, uy), 0, 255).astype(np.uint8)
    im = Image.fromarray(v, 'L')
    return im.resize((t.size, t.size), Image.NEAREST) if pixel else im


def solid(t: Target, color, alpha: Image.Image | None = None) -> Image.Image:
    im = Image.new('RGBA', (t.size, t.size), fg.rgb(color))
    if alpha is not None:
        im.putalpha(alpha)
    return im


def layer_fill(canvas, spec, t):
    canvas.alpha_composite(solid(t, spec['color']))


def layer_gradient(canvas, spec, t):
    """Vertical gradient between grid rows y0 and y1 (clamped outside), stepped per unit row."""
    y0, y1 = spec.get('rows', [0, GRID])
    top, bottom = fg.rgb(spec['top']), fg.rgb(spec['bottom'])
    mix = unit_field(t, lambda ux, uy: 255 * np.clip((uy - y0) / (y1 - y0), 0, 1), spec.get('pixel', False))
    canvas.alpha_composite(Image.composite(solid(t, bottom), solid(t, top), mix))


def layer_glow(canvas, spec, t):
    """Radial light: `radius` units, `strength` 0..1, `steps` > 0 quantises it into flat bands."""
    cx, cy = spec['at']
    r = spec['radius']
    steps = spec.get('steps', 0)

    def f(ux, uy):
        v = np.clip(1 - np.hypot(ux - cx, (uy - cy) * spec.get('aspect', 1)) / r, 0, 1) ** spec.get('falloff', 2)
        if steps:
            v = np.ceil(v * steps) / steps
        return 255 * v * spec.get('strength', 1)
    canvas.alpha_composite(solid(t, spec['color'], unit_field(t, f, spec.get('pixel', False))))


def layer_rays(canvas, spec, t):
    """Sun rays from `at`: `count` wedges, each `width` of its period lit, fading out by `radius`."""
    cx, cy = spec['at']
    n, width, rot = spec['count'], spec.get('width', 0.5), math.radians(spec.get('rotation', 0))

    def f(ux, uy):
        a = (np.arctan2(uy - cy, ux - cx) - rot) / (2 * math.pi) * n
        lit = (a - np.floor(a)) < width
        fade = np.clip(1 - np.hypot(ux - cx, uy - cy) / spec['radius'], 0, 1) ** spec.get('falloff', 1)
        return 255 * spec.get('strength', 0.3) * fade * lit
    canvas.alpha_composite(solid(t, spec['color'], unit_field(t, f, spec.get('pixel', False))))


def layer_vignette(canvas, spec, t):
    """Darkens toward the grid corners from `start` units away from the centre."""
    s, e = spec.get('start', 12), spec.get('end', 23)

    def f(ux, uy):
        d = np.hypot(ux - GRID / 2, uy - GRID / 2)
        return 255 * spec.get('strength', 0.7) * np.clip((d - s) / (e - s), 0, 1)
    canvas.alpha_composite(solid(t, spec.get('color', [12, 8, 20]), unit_field(t, f, spec.get('pixel', False))))


def layer_actor(canvas, spec, t):
    fg.layer_actor(canvas, {**spec, 'at': t.at(spec['at']), 'scale': spec.get('scale', 1) * t.k,
                            'shadow_dx': spec.get('shadow_dx', 0) * t.k})


def layer_item(canvas, spec, t):
    fg.layer_item(canvas, {**spec, 'at': t.at(spec['at']), 'scale': spec.get('scale', 1) * t.k})


def layer_spark(canvas, spec, t):
    items = [[t.x(e[0]), t.x(e[1]), e[2], (e[3] if len(e) > 3 else spec.get('scale', 1)) * t.k] for e in spec['items']]
    fg.layer_spark(canvas, {**spec, 'items': items})


def layer_sparkle(canvas, spec, t):
    """One twinkle cut from a frame of the game's loot sparkle sheet: `box` [x, y, w, h] in that
    frame, items = [[x, y, scale], ...]. The whole frames scatter several twinkles (see `spark`)."""
    s = fg.COMPONENTS['spark']
    x, y, w, h = spec.get('box', [3, 6, 3, 5])
    f = spec.get('frame', 0) * s['w']
    im = fg.crop(s['sheet'], [f + x, y, w, h])
    if spec.get('rim'):
        im = fg.rim(im, spec['rim'])
    for e in spec['items']:
        fg.place(canvas, fg.treat(fg.up(im, e[2] * t.k), spec), t.at(e[:2]))


LAYERS = {'fill': layer_fill, 'gradient': layer_gradient, 'glow': layer_glow, 'rays': layer_rays,
          'vignette': layer_vignette, 'actor': layer_actor, 'item': layer_item, 'spark': layer_spark,
          'sparkle': layer_sparkle}


def plane(spec: dict) -> str:
    return spec.get('plane', 'back' if spec['type'] in BACK_TYPES else 'front')


def load(name: str) -> dict:
    comp = json.loads((HERE / 'compositions' / f'{name}.json').read_text(encoding='utf-8'))
    planes = [plane(s) for s in comp['layers'] if not s.get('skip')]
    if planes != sorted(planes):  # 'back' < 'front': the adaptive split must equal the full icon
        raise SystemExit(f'{name}: every back-plane layer must come before the front-plane layers')
    return comp


def render(comp: dict, target: str, which=('back', 'front'), only=None) -> Image.Image:
    t = Target(target)
    canvas = Image.new('RGBA', (t.size, t.size))
    for spec in comp['layers']:
        if spec.get('skip') or plane(spec) not in which or (only and not only(spec)):
            continue
        LAYERS[spec['type']](canvas, spec, t)
    return canvas


def monochrome(comp: dict) -> Image.Image:
    """Themed-icon layer, white on transparent: the front plane's solid silhouette with its *interior*
    dark pixels (eyes, mouth, part lines) carved out. Dark pixels within `edge` units of the outside
    stay filled, so the outer outline keeps the shape whole instead of breaking it into fragments."""
    m = comp.get('monochrome', {})
    front = render(comp, 'adaptive', ('front',), lambda s: s.get('name') not in m.get('exclude', []))
    k = TARGETS['adaptive'][1]
    silhouette = front.split()[3].point(lambda v: 255 if v >= 128 else 0)
    inner = silhouette.filter(ImageFilter.MinFilter(2 * m.get('edge', 2) * k + 1))
    dark = front.convert('L').point(lambda v: 255 if v < m.get('cut', 70) else 0)
    carve = ImageChops.multiply(dark, inner)
    out = Image.new('RGBA', front.size, (255, 255, 255, 0))
    out.putalpha(ImageChops.subtract(silhouette, carve))
    return out


def outputs(comp: dict) -> dict[str, Image.Image]:
    return {'play': render(comp, 'play'), 'launcher': render(comp, 'launcher'),
            'background': render(comp, 'adaptive', ('back',)), 'foreground': render(comp, 'adaptive', ('front',)),
            'monochrome': monochrome(comp),
            'key': render(comp, 'adaptive', ('front',), lambda s: s.get('key'))}


# ----------------------------------------------------------------------------------------------- files

FINAL_FILES = {'play': STORE / 'play_icon_512.png', 'launcher': RUNTIME / 'launcher_192.png',
               'background': RUNTIME / 'adaptive_background_432.png',
               'foreground': RUNTIME / 'adaptive_foreground_432.png',
               'monochrome': RUNTIME / 'adaptive_monochrome_432.png'}


def png_bytes(im: Image.Image) -> bytes:
    buf = io.BytesIO()
    im.save(buf, 'PNG', optimize=True)
    return buf.getvalue()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT)).replace('\\', '/')


def build(name: str) -> dict:
    comp = load(name)
    out = outputs(comp)
    record = {'composition': rel(HERE / 'compositions' / f'{name}.json'), 'files': {}}
    if name == 'final':
        files = FINAL_FILES
        layers_dir = STORE / 'source_layers/icon_final'
        layers_dir.mkdir(parents=True, exist_ok=True)
        for old in layers_dir.glob('*.png'):
            old.unlink()
        for i, spec in enumerate(comp['layers']):  # every layer alone at Play size, for later editing
            alone = render(comp, 'play', (plane(spec),), lambda s, spec=spec: s is spec)
            alone.save(layers_dir / f'{i:02d}_{spec.get("name", spec["type"])}.png')
    else:
        d = REVIEW / 'concepts' / name
        files = {k: d / f'{k}.png' for k in ('play', 'background', 'foreground', 'monochrome')}
    for key, path in files.items():
        data = png_bytes(out[key])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        record['files'][key] = {'path': rel(path), 'bytes': len(data), 'sha256': sha(data)}
    record['safe_zone'] = safe_zone(out['foreground'], out['key'])
    return record


# ----------------------------------------------------------------------------------------------- checks

def safe_zone(foreground: Image.Image, key: Image.Image) -> dict:
    """Key layers inside the 66 dp safe circle; everything in front inside the 72 dp viewport."""
    k, b = TARGETS['adaptive'][1], TARGETS['adaptive'][2]
    c = (b + GRID / 2) * k
    ys, xs = np.nonzero(np.asarray(key.split()[3]))
    worst = float(np.hypot(xs + 0.5 - c, ys + 0.5 - c).max()) if len(xs) else 0.0
    box = foreground.split()[3].getbbox()
    view = (b * k, b * k, (b + GRID) * k, (b + GRID) * k)
    return {'key_max_radius_units': round(worst / k, 2), 'safe_radius_units': round(SAFE_RADIUS, 2),
            'key_inside_safe_zone': worst / k <= SAFE_RADIUS,
            'front_bbox_px': list(box) if box else None,
            'front_inside_viewport': bool(box) and box[0] >= view[0] and box[1] >= view[1] and box[2] <= view[2] and box[3] <= view[3]}


def check() -> list[str]:
    problems = []
    spec = {'play': ((512, 512), True), 'launcher': ((192, 192), True), 'background': ((432, 432), True),
            'foreground': ((432, 432), False), 'monochrome': ((432, 432), False)}
    fresh = outputs(load('final'))
    for key, path in FINAL_FILES.items():
        if not path.exists():
            problems.append(f'missing {rel(path)}'); continue
        data = path.read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n':
            problems.append(f'{path.name}: not a PNG signature')
        im = Image.open(path)
        size, opaque = spec[key]
        if im.format != 'PNG' or im.size != size or im.mode != 'RGBA':
            problems.append(f'{path.name}: {im.format} {im.size} {im.mode}, want PNG {size} RGBA (32-bit)')
        lo, hi = im.split()[3].getextrema()
        if opaque and lo != 255:
            problems.append(f'{path.name}: must be fully opaque (alpha min {lo})')
        if not opaque and lo != 0:
            problems.append(f'{path.name}: must have transparent areas')
        if 'icc_profile' in im.info:
            problems.append(f'{path.name}: carries an ICC profile (Play wants plain sRGB)')
        if png_bytes(fresh[key]) != data:
            problems.append(f'{path.name}: differs from a fresh render of compositions/final.json')
    if FINAL_FILES['play'].exists() and FINAL_FILES['play'].stat().st_size > 1024 * 1024:
        problems.append('play icon larger than 1024 KB')
    zone = safe_zone(fresh['foreground'], fresh['key'])
    if not zone['key_inside_safe_zone']:
        problems.append(f'key art reaches {zone["key_max_radius_units"]} units from centre (safe zone {zone["safe_radius_units"]})')
    if not zone['front_inside_viewport']:
        problems.append(f'foreground {zone["front_bbox_px"]} leaves the 72 dp viewport')
    return problems


# ----------------------------------------------------------------------------------------------- review

LIGHT, DARK = (248, 249, 250), (32, 33, 36)


def font(size: int, weight: int = 600) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([weight if a['name'] == b'Weight' else 100 for a in f.get_variation_axes()])
    return f


def shape_mask(kind: str, s: int) -> Image.Image:
    """Launcher/store masks at 4x then reduced, so the preview edge is smooth like a real launcher."""
    S = s * 4
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    if kind == 'circle':
        d.ellipse((0, 0, S - 1, S - 1), fill=255)
    elif kind == 'play':  # Google Play: full square, corner radius 30% of the icon size (applied by Play)
        d.rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.30), fill=255)
    elif kind == 'rounded':
        d.rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.16), fill=255)
    elif kind == 'teardrop':
        d.rounded_rectangle((0, 0, S - 1, S - 1), radius=S // 2, fill=255)
        d.rectangle((S // 2, S // 2, S - 1, S - 1), fill=255)
    elif kind == 'squircle':  # superellipse |x|^4 + |y|^4 = 1
        pts = []
        for i in range(720):
            a = i / 720 * 2 * math.pi
            c, n = math.cos(a), math.sin(a)
            pts.append((S / 2 + S / 2 * math.copysign(abs(c) ** 0.5, c), S / 2 + S / 2 * math.copysign(abs(n) ** 0.5, n)))
        d.polygon(pts, fill=255)
    return m.resize((s, s), Image.LANCZOS)


def small(im: Image.Image, s: int) -> Image.Image:
    return im if im.width == s else im.convert('RGBA').resize((s, s), Image.LANCZOS)


def masked(im: Image.Image, kind: str, s: int) -> Image.Image:
    out = small(im, s).copy()
    out.putalpha(ImageChops.multiply(out.split()[3], shape_mask(kind, s)))
    return out


def launcher_view(o: dict) -> Image.Image:
    """What a launcher shows: background + foreground, the inner 72 dp (the grid) of the 108 dp layers."""
    full = o['background'].copy()
    full.alpha_composite(o['foreground'])
    b = 8 * 9
    return full.crop((b, b, b + 288, b + 288))


def themed(o: dict, bg, fg_color) -> Image.Image:
    b = 8 * 9
    mono = o['monochrome'].crop((b, b, b + 288, b + 288))
    out = Image.new('RGBA', mono.size, fg.rgb(bg))
    ink = Image.new('RGBA', mono.size, fg.rgb(fg_color))
    ink.putalpha(mono.split()[3])
    out.alpha_composite(ink)
    return out


def label(d, xy, text, size=18, color=(60, 64, 67), weight=600):
    d.text(xy, text, font=font(size, weight), fill=color)


def concept_card(title: str, o: dict, note: str = '') -> Image.Image:
    """One concept at Play size, 96 and 48 px on light and dark, and two launcher masks."""
    card = Image.new('RGB', (900, 640), LIGHT)
    d = ImageDraw.Draw(card)
    label(d, (24, 16), title, 26, (32, 33, 36), 800)
    if note:
        label(d, (24, 52), note, 16, (95, 99, 104), 500)
    card.paste(masked(o['play'], 'play', 512), (24, 96), masked(o['play'], 'play', 512))
    dark = Image.new('RGB', (330, 230), DARK)
    card.paste(dark, (560, 96))
    for i, (bg, y) in enumerate(((LIGHT, 106), (DARK, 216))):
        for s, x in ((96, 580), (48, 700)):
            ic = masked(o['play'], 'play', s)
            card.paste(ic, (x, y), ic)
        lv = launcher_view(o)
        for kind, x in (('circle', 772),):
            ic = masked(lv, kind, 96)
            card.paste(ic, (x, y), ic)
    label(d, (580, 330), 'Play 96 / 48 px, circle launcher 96 px', 14, (95, 99, 104), 500)
    lv = launcher_view(o)
    for j, kind in enumerate(('squircle', 'teardrop')):
        ic = masked(lv, kind, 120)
        card.paste(ic, (580 + j * 150, 370), ic)
    th = themed(o, (214, 227, 255), (16, 42, 92))
    ic = masked(th, 'circle', 96)
    card.paste(ic, (580, 520), ic)
    th = themed(o, (40, 48, 66), (196, 214, 255))
    ic = masked(th, 'circle', 96)
    card.paste(ic, (700, 520), ic)
    label(d, (580, 500), 'Themed (monochrome) light / dark', 14, (95, 99, 104), 500)
    return card


def sizes_sheet(play: Image.Image, title: str) -> Image.Image:
    sizes = [512, 192, 96, 64, 48, 32]
    w = sum(sizes) + 24 * (len(sizes) + 1)
    sheet = Image.new('RGB', (w, 2 * 572 + 60), LIGHT)
    d = ImageDraw.Draw(sheet)
    label(d, (24, 14), title, 22, (32, 33, 36), 800)
    sheet.paste(Image.new('RGB', (w, 572), DARK), (0, 60 + 572))
    x = 24
    for s in sizes:
        for y in (80, 80 + 572):
            ic = masked(play, 'play', s)
            sheet.paste(ic, (x, y), ic)
        label(d, (x, 80 + s + 6), f'{s} px', 14, (95, 99, 104), 500)
        x += s + 24
    return sheet


def masks_sheet(o: dict) -> Image.Image:
    """Adaptive icon: the full 108 dp layers with guides, five launcher masks on light/dark, themed, legacy."""
    sheet = Image.new('RGB', (1500, 980), LIGHT)
    d = ImageDraw.Draw(sheet)
    label(d, (24, 14), 'Adaptive icon (432 px layers = 108 dp): viewport 72 dp, safe zone 66 dp', 22, (32, 33, 36), 800)
    full = o['background'].copy()
    full.alpha_composite(o['foreground'])
    guide = full.convert('RGB')
    g = ImageDraw.Draw(guide)
    g.rectangle((72, 72, 359, 359), outline=(255, 255, 255), width=2)
    c, r = 216, SAFE_RADIUS * 9
    g.ellipse((c - r, c - r, c + r, c + r), outline=(255, 235, 59), width=2)
    sheet.paste(guide, (24, 60))
    label(d, (24, 500), 'white square = 72 dp viewport, yellow circle = 66 dp safe zone', 14, (95, 99, 104), 500)
    fgv = Image.new('RGB', (216, 216), (120, 120, 120))
    checker = Image.new('RGB', (216, 216), (200, 200, 200))
    cd = ImageDraw.Draw(checker)
    for yy in range(0, 216, 12):
        for xx in range(0, 216, 12):
            if (xx + yy) // 12 % 2:
                cd.rectangle((xx, yy, xx + 11, yy + 11), fill=(235, 235, 235))
    for j, (img, name) in enumerate(((o['foreground'], 'foreground'), (o['background'], 'background'), (o['monochrome'], 'monochrome'))):
        tile = checker.copy() if name != 'monochrome' else Image.new('RGB', (216, 216), (60, 64, 67))
        sm = img.resize((216, 216), Image.LANCZOS)
        tile.paste(sm, (0, 0), sm)
        sheet.paste(tile, (24 + j * 236, 530))
        label(d, (24 + j * 236, 752), name, 14, (95, 99, 104), 500)
    lv = launcher_view(o)
    kinds = ['circle', 'squircle', 'rounded', 'teardrop', 'play']
    names = ['circle', 'squircle', 'rounded square', 'teardrop', 'legacy / Play']
    sheet.paste(Image.new('RGB', (1500 - 500, 230), DARK), (500, 290))
    for i, kind in enumerate(kinds):
        x = 520 + i * 190
        src = lv if kind != 'play' else o['launcher']
        for y in (70, 310):
            ic = masked(src, kind, 160)
            sheet.paste(ic, (x, y), ic)
        label(d, (x, 236), names[i], 14, (95, 99, 104), 500)
        for j, s in enumerate((48,)):
            ic = masked(src, kind, s)
            sheet.paste(ic, (x + 56, 470), ic)
    label(d, (24, 790), 'Themed icons (Android 13+ tints the monochrome layer with the wallpaper colours)', 16, (60, 64, 67), 700)
    for i, (bg, ink) in enumerate((((214, 227, 255), (16, 42, 92)), ((255, 221, 210), (90, 30, 16)),
                                    ((40, 48, 66), (196, 214, 255)), ((52, 40, 36), (255, 206, 190)))):
        x = 24 + i * 370
        for j, kind in enumerate(('circle', 'squircle')):
            ic = masked(themed(o, bg, ink), kind, 120)
            sheet.paste(ic, (x + j * 134, 826), ic)
        ic = masked(themed(o, bg, ink), 'circle', 48)
        sheet.paste(ic, (x + 276, 862), ic)
    return sheet


def before_after(old: Image.Image, new: dict) -> Image.Image:
    sheet = Image.new('RGB', (1400, 760), LIGHT)
    d = ImageDraw.Draw(sheet)
    sheet.paste(Image.new('RGB', (1400, 160), DARK), (0, 600))
    for col, (title, play, lv) in enumerate((('BEFORE (Change 27)', old, None), ('AFTER (Change 30)', new['play'], launcher_view(new)))):
        x0 = 24 + col * 700
        label(d, (x0, 14), title, 24, (32, 33, 36), 800)
        ic = masked(play, 'play', 400)
        sheet.paste(ic, (x0, 60), ic)
        for j, s in enumerate((128, 96, 64, 48, 32)):
            ic = masked(play, 'play', s)
            sheet.paste(ic, (x0 + 420 + (0 if j < 2 else (j - 2) * 76), 60 + (j * 140 if j < 2 else 320)), ic)
        for j, s in enumerate((96, 48)):
            ic = masked(play, 'play', s)
            sheet.paste(ic, (x0 + j * 120, 624), ic)
        src = lv if lv is not None else play
        ic = masked(src, 'circle', 96)
        sheet.paste(ic, (x0 + 260, 624), ic)
        ic = masked(src, 'circle', 48)
        sheet.paste(ic, (x0 + 380, 648), ic)
        label(d, (x0, 470), 'Play mask (30% radius) at 400, 128, 96, 64, 48, 32 px', 14, (95, 99, 104), 500)
    label(d, (24, 572), 'On a dark surface: Play 96 / 48 px, launcher circle 96 / 48 px', 14, (95, 99, 104), 500)
    return sheet


def concepts_sheet(cards: list[Image.Image]) -> Image.Image:
    w = cards[0].width // 2
    sheet = Image.new('RGB', (w * 2, (cards[0].height // 2) * 2), LIGHT)
    for i, c in enumerate(cards):
        sheet.paste(c.resize((w, c.height // 2), Image.LANCZOS), ((i % 2) * w, (i // 2) * (c.height // 2)))
    return sheet


NOTES = {'concept_a_costume_hero': 'A. Costume hero: the player in the Teal Dinosaur outfit with its Iron Sword, full figure, sunset light',
         'concept_b_loot_drop': "B. Loot drop: the boss's two real drops, Iron Sword x2 behind the outfit portrait, sparkle burst",
         'concept_c_close_up': 'C. Close-up: the outfitted player at x2, cropped bust, eye contact, sword raised',
         'final': 'FINAL'}


def review(names: list[str]) -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    cards = []
    for name in BUILD_ORDER:
        if not (HERE / 'compositions' / f'{name}.json').exists():
            continue
        comp = load(name)
        o = outputs(comp)
        card = concept_card(comp.get('title', name), o, comp.get('note', ''))
        card.save(REVIEW / f'{name}_card.png')
        cards.append(card)
        if name == 'final':
            sizes_sheet(o['play'], 'Final Google Play icon at store and launcher sizes (Play applies the 30% corner radius)').save(REVIEW / 'icon_small_sizes.png')
            masks_sheet(o).save(REVIEW / 'icon_adaptive_masks.png')
            with Image.open(OLD_ICON) as old:
                before_after(old.convert('RGBA'), o).save(REVIEW / 'icon_before_after.png')
    concepts_sheet(cards).save(REVIEW / 'icon_concepts.png')
    if 'final' in names:
        EVIDENCE.mkdir(parents=True, exist_ok=True)
        for src, dst in ((STORE / 'play_icon_512.png', 'play_icon_512.png'),
                         (REVIEW / 'icon_concepts.png', 'icon_concepts.png'),
                         (REVIEW / 'icon_before_after.png', 'icon_before_after.png'),
                         (REVIEW / 'icon_small_sizes.png', 'icon_small_sizes.png'),
                         (REVIEW / 'icon_adaptive_masks.png', 'icon_adaptive_masks.png'),
                         (STORE / 'icon_manifest.json', 'icon_manifest.json')):
            shutil.copyfile(src, EVIDENCE / dst)
        for name in BUILD_ORDER[:-1]:
            shutil.copyfile(REVIEW / f'{name}_card.png', EVIDENCE / f'{name}.png')


def main() -> int:
    if '--check' in sys.argv:
        problems = check()
        print('ICON CHECK', 'PASS' if not problems else 'FAIL', *problems, sep='\n  ')
        return 1 if problems else 0
    names = [a for a in sys.argv[1:] if not a.startswith('-')] or BUILD_ORDER
    records = [build(n) for n in names]
    manifest = STORE / 'icon_manifest.json'
    old = json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else {}
    old.update({r['composition']: r for r in records})
    manifest.write_bytes((json.dumps(old, indent=2) + '\n').encode('utf-8'))
    for r in records:
        print(r['composition'], 'safe zone', r['safe_zone'])
        for k, f in r['files'].items():
            print(f"  {k:<10} {f['path']}  {f['bytes']} B  {f['sha256'][:12]}")
    if '--no-review' not in sys.argv:
        review(names)
    problems = check() if 'final' in names else []
    if 'final' in names:
        print('ICON', 'PASS' if not problems else 'FAIL', *problems, sep='\n  ')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
