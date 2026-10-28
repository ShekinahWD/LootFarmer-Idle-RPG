"""LootFarmer Google Play feature graphic (Change 28): layered, reproducible composition.

Every picture element is existing licensed game art (Pixel Plains characters, items, tiles, trees,
sparks and Animation Pack swings; Kenney Fantasy UI slot panel, CC0), placed by the JSON files in
`compositions/`. Pixel art is only ever scaled by whole numbers with nearest-neighbour sampling;
the treatments (darken/tint, 1-pixel rim outline, soft glow, vignette, gradient sky) are colour
operations, never new drawing. The wordmark is Lilita One (SIL OFL 1.1, embedded licence).

Truthfulness: an `actor` layer names a catalog outfit and weapon, and a `slot` names a catalog item;
when a layer says `from_group`, the script fails unless that enemy group really carries/drops it.

Usage (project root):
    python marketing/brand/feature_graphic/compose_feature_graphic.py            # all compositions
    python marketing/brand/feature_graphic/compose_feature_graphic.py final      # one composition
    python marketing/brand/feature_graphic/compose_feature_graphic.py --check    # validate outputs
Outputs: store_assets/branding/ (ignored by git); see README.md beside this script.
"""
from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
COMPONENTS = json.loads((HERE / 'components.json').read_text(encoding='utf-8'))
CATALOG = json.loads((ROOT / 'data/game/catalog.json').read_text(encoding='utf-8'))
STORE = ROOT / 'store_assets/branding'
_sheets: dict[str, Image.Image] = {}


def sheet(path: str) -> Image.Image:
    if path not in _sheets:
        _sheets[path] = Image.open(ROOT / path.replace('res://', '')).convert('RGBA')
    return _sheets[path]


def crop(path: str, box) -> Image.Image:
    x, y, w, h = box
    return sheet(path).crop((x, y, x + w, y + h))


def up(im: Image.Image, k: int) -> Image.Image:
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def rgb(c) -> tuple:
    if isinstance(c, str):
        c = c.lstrip('#')
        return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    return tuple(c) + ((255,) if len(c) == 3 else ())


def multiply(im: Image.Image, color, amount: float = 1.0) -> Image.Image:
    """Multiplies RGB by `color` (0..255 per channel), blended by `amount`; alpha is kept."""
    r, g, b, a = im.split()
    out = []
    for ch, k in zip((r, g, b), rgb(color)[:3]):
        f = 1 - amount + amount * k / 255
        out.append(ch.point(lambda v, f=f: min(255, int(v * f))))
    return Image.merge('RGBA', out + [a])


def opacity(im: Image.Image, alpha: float) -> Image.Image:
    if alpha >= 1:
        return im
    r, g, b, a = im.split()
    return Image.merge('RGBA', (r, g, b, a.point(lambda v: int(v * alpha))))


def rim(im: Image.Image, color, px: int = 1) -> Image.Image:
    """A `px`-pixel outline in source-pixel units behind the sprite (applied before upscaling)."""
    pad = Image.new('RGBA', (im.width + 2 * px, im.height + 2 * px))
    pad.alpha_composite(im, (px, px))
    mask = pad.split()[3].point(lambda v: 255 if v > 0 else 0).filter(ImageFilter.MaxFilter(2 * px + 1))
    out = Image.new('RGBA', pad.size, rgb(color))
    out.putalpha(mask)
    out.alpha_composite(pad)
    return out


def glow(w: int, h: int, color, strength: float) -> Image.Image:
    """Soft elliptical light, a colour treatment behind a focal element."""
    # radial_gradient is the distance from the centre (128 at the edge midpoints): rescale so the
    # light reaches zero at the ellipse edge, with a smooth falloff and no visible box.
    g = Image.radial_gradient('L').resize((w, h), Image.BILINEAR)
    g = g.point(lambda v: int(255 * max(0.0, 1 - v / 128) ** 2 * strength))
    out = Image.new('RGBA', (w, h), rgb(color))
    out.putalpha(g)
    return out


def treat(im: Image.Image, spec: dict) -> Image.Image:
    if 'tint' in spec:
        im = multiply(im, spec['tint'], spec.get('tint_amount', 1.0))
    if 'darken' in spec:
        im = multiply(im, [int(255 * spec['darken'])] * 3)
    if 'opacity' in spec:
        im = opacity(im, spec['opacity'])
    return im


# ----------------------------------------------------------------------------------------------- game art

def actor_image(comp: dict) -> tuple[Image.Image, tuple[int, int]]:
    """Body (+ swing) exactly as LootActorView lays them out, in source pixels.

    Returns the image and the feet origin inside it. actor.tscn: Body at (0,-10), centred 24x24;
    Attack at (0,-14), centred 64x32; swing frame f with the row-3 effort face is the in-game frame.
    """
    items = CATALOG['items']
    if comp.get('outfit'):
        body_path = items[comp['outfit']]['texture']
    else:
        body_path = COMPONENTS['player_body']
    row, col = comp.get('frame', [0, 0])
    body = crop(body_path, [col * 24, row * 24, 24, 24])
    canvas = Image.new('RGBA', (64, 36))
    ox, oy = 32, 32  # feet origin
    canvas.alpha_composite(body, (ox - 12, oy - 10 - 12))
    swing = comp.get('swing')
    if swing is not None and comp.get('weapon'):
        # Attack sprite above the body, as in actor.tscn, with the weapon's attack_tint.
        w = items[comp['weapon']]
        tint = [int(255 * t) for t in w.get('attack_tint', [1, 1, 1])]
        canvas.alpha_composite(multiply(crop(w['attack'], [swing * 64, 0, 64, 32]), tint), (ox - 32, oy - 14 - 16))
    box = canvas.getbbox()
    canvas = canvas.crop(box)
    origin = (ox - box[0], oy - box[1])
    if comp.get('facing', 1) < 0:
        canvas = canvas.transpose(Image.FLIP_LEFT_RIGHT)
        origin = (canvas.width - origin[0], origin[1])
    return canvas, origin


def item_icon(item_id: str) -> Image.Image:
    it = CATALOG['items'][item_id]
    icon = crop(it['texture'], it['icon'])
    box = icon.getbbox()
    return icon.crop(box) if box else icon


def verify_loot(comp: dict, what: str, item_id: str) -> None:
    gid = comp.get('from_group')
    if not gid:
        return
    group = next(g for g in CATALOG['groups'] if g['id'] == gid)
    art = CATALOG['items'][item_id].get('art_id', item_id)
    owned = {group['weapon'], group['body']} | set(group['loot'])
    owned_art = {CATALOG['items'][i].get('art_id', i) for i in owned}
    if item_id not in owned and art not in owned_art:
        raise SystemExit(f'{what} {item_id} is not carried or dropped by {gid} (has {sorted(owned)})')


def ninepatch(path: str, size, margin: int, scale: int) -> Image.Image:
    """Kenney panel drawn as a 9-patch at an integer pixel scale (StyleBoxTexture margins)."""
    src = sheet(path)
    w, h = size[0] // scale, size[1] // scale
    m = margin
    out = Image.new('RGBA', (w, h))
    sw, sh = src.size
    xs = [(0, m, 0, m), (m, sw - m, m, w - m), (sw - m, sw, w - m, w)]
    ys = [(0, m, 0, m), (m, sh - m, m, h - m), (sh - m, sh, h - m, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if dx1 > dx0 and dy1 > dy0:
                out.alpha_composite(src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST), (dx0, dy0))
    return up(out, scale)


# ----------------------------------------------------------------------------------------------- layers

def place(canvas: Image.Image, im: Image.Image, at, anchor='center', origin=None) -> None:
    x, y = at
    if anchor == 'feet' and origin is not None:
        pos = (x - origin[0], y - origin[1])
    elif anchor == 'bottom':
        pos = (x - im.width // 2, y - im.height)
    elif anchor == 'topleft':
        pos = (x, y)
    else:
        pos = (x - im.width // 2, y - im.height // 2)
    canvas.alpha_composite(im, (int(pos[0]), int(pos[1])))


def layer_sky(canvas, spec):
    w, h = canvas.size
    top, bottom = rgb(spec['top']), rgb(spec['bottom'])
    grad = Image.new('RGBA', (1, 256))
    for i in range(256):
        t = i / 255
        grad.putpixel((0, i), tuple(int(top[c] + (bottom[c] - top[c]) * t) for c in range(3)) + (255,))
    canvas.alpha_composite(grad.resize((w, h), Image.BILINEAR))


def layer_tiles(canvas, spec):
    rng = random.Random(spec.get('seed', 1))
    k = spec['scale']
    x0, y0, x1, y1 = spec.get('rect', [0, 0, canvas.width, canvas.height])
    t = 16 * k
    layer = Image.new('RGBA', canvas.size)
    for ty in range(y0, y1, t):
        for tx in range(x0, x1, t):
            sx, sy = rng.choice(spec['tiles'])
            layer.alpha_composite(up(crop(spec['sheet'], [sx, sy, 16, 16]), k), (tx, ty))
    layer = layer.crop((0, 0, canvas.width, canvas.height))
    mask = Image.new('L', canvas.size, 0)
    ImageDraw.Draw(mask).rectangle((x0, y0, x1 - 1, y1 - 1), fill=255)
    layer.putalpha(ImageChops.multiply(layer.split()[3], mask))
    canvas.alpha_composite(treat(layer, spec))


def layer_props(canvas, spec):
    """Rows of scenery (trees, props) from one sheet: items = [[box_name or box, x, y], ...]."""
    boxes = COMPONENTS['boxes']
    for entry in spec['items']:
        box, x, y = entry[0], entry[1], entry[2]
        k = entry[3] if len(entry) > 3 else spec['scale']
        flip = len(entry) > 4 and entry[4]
        im = crop(spec['sheet'], boxes[box] if isinstance(box, str) else box)
        if spec.get('rim'):
            im = rim(im, spec['rim'])
        im = up(im, k)
        if flip:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        place(canvas, treat(im, spec), (x, y), 'bottom')


def layer_actor(canvas, spec):
    comp = {**COMPONENTS['actors'][spec['actor']], **spec.get('override', {})}
    if comp.get('weapon'):
        verify_loot(comp, 'weapon', comp['weapon'])
    if comp.get('outfit'):
        verify_loot(comp, 'outfit', comp['outfit'])
    im, origin = actor_image(comp)
    k = spec.get('scale', comp.get('scale', 8))
    if spec.get('rim', comp.get('rim')):
        im = rim(im, spec.get('rim', comp.get('rim')))
        origin = (origin[0] + 1, origin[1] + 1)
    if spec.get('shadow', True):
        sh = up(sheet(COMPONENTS['shadow']), max(1, k))
        sh = opacity(sh, spec.get('shadow_opacity', 0.55))
        canvas.alpha_composite(sh, (int(spec['at'][0] - sh.width / 2 + (spec.get('shadow_dx', 0))), int(spec['at'][1] - sh.height * 0.55)))
    im = treat(up(im, k), spec)
    place(canvas, im, spec['at'], 'feet', (origin[0] * k, origin[1] * k))


def layer_glow(canvas, spec):
    w, h = spec['size']
    place(canvas, glow(w, h, spec['color'], spec.get('strength', 1.0)), spec['at'])


def layer_vignette(canvas, spec):
    w, h = canvas.size
    g = Image.radial_gradient('L').resize((w, h), Image.BILINEAR)
    g = g.point(lambda v: int(min(255, max(0, (v - spec.get('start', 110)) * spec.get('strength', 1.6)))))
    dark = Image.new('RGBA', (w, h), rgb(spec.get('color', [10, 12, 22])))
    dark.putalpha(g)
    canvas.alpha_composite(dark)


def layer_band(canvas, spec):
    """A flat or vertical-gradient translucent band (ground shade, title plate)."""
    x0, y0, x1, y1 = spec['rect']
    top, bottom = rgb(spec['top']), rgb(spec.get('bottom', spec['top']))
    a0, a1 = spec.get('alpha', [1, 1])
    band = Image.new('RGBA', (1, 256))
    for i in range(256):
        t = i / 255
        band.putpixel((0, i), tuple(int(top[c] + (bottom[c] - top[c]) * t) for c in range(3)) + (int(255 * (a0 + (a1 - a0) * t)),))
    canvas.alpha_composite(band.resize((x1 - x0, y1 - y0), Image.BILINEAR), (x0, y0))


def layer_slot(canvas, spec):
    """An inventory slot: Kenney panel tinted with the item's tier colour, the item icon inside."""
    s = COMPONENTS['slot']
    item_id = spec['item']
    verify_loot(spec, 'slot item', item_id)
    tier = int(CATALOG['items'][item_id]['tier'])
    color = rgb(CATALOG['progression']['tier_colors'][min(6, tier - 1)])
    size = spec.get('size', s['size'])
    panel = multiply(ninepatch(s['texture'], (size, size), s['margin'], s['pixel']), color)
    panel = lift(panel, spec.get('lift', 1.35))
    if spec.get('rim'):
        border = Image.new('RGBA', (panel.width + 2 * s['pixel'], panel.height + 2 * s['pixel']), rgb(spec['rim']))
        border.putalpha(Image.new('L', border.size, 0))
        m = panel.split()[3].point(lambda v: 255 if v else 0)
        mask = Image.new('L', border.size, 0)
        mask.paste(m, (s['pixel'], s['pixel']))
        mask = mask.filter(ImageFilter.MaxFilter(2 * s['pixel'] + 1))
        border.putalpha(mask)
        border.alpha_composite(panel, (s['pixel'], s['pixel']))
        panel = border
    icon = item_icon(item_id)
    k = spec.get('icon_scale', max(1, int((size * 0.62) // max(icon.size))))
    icon = up(rim(icon, spec.get('icon_rim', [24, 22, 36])), k)
    panel.alpha_composite(icon, ((panel.width - icon.width) // 2, (panel.height - icon.height) // 2))
    if spec.get('rotate'):
        panel = panel.rotate(spec['rotate'], Image.NEAREST, expand=True)
    place(canvas, treat(panel, spec), spec['at'])


def lift(im: Image.Image, f: float) -> Image.Image:
    r, g, b, a = im.split()
    return Image.merge('RGBA', [c.point(lambda v: min(255, int(v * f))) for c in (r, g, b)] + [a])


def layer_spark(canvas, spec):
    s = COMPONENTS['spark']
    for entry in spec['items']:
        x, y, frame = entry[0], entry[1], entry[2]
        k = entry[3] if len(entry) > 3 else spec.get('scale', 3)
        im = up(crop(s['sheet'], [frame * s['w'], 0, s['w'], s['h']]), k)
        place(canvas, treat(im, spec), (x, y))


def layer_item(canvas, spec):
    verify_loot(spec, 'item', spec['item'])
    im = item_icon(spec['item'])
    if spec.get('rim'):
        im = rim(im, spec['rim'])
    im = up(im, spec['scale'])
    if spec.get('rotate'):
        im = im.rotate(spec['rotate'], Image.NEAREST, expand=True)
    place(canvas, treat(im, spec), spec['at'])


def wordmark_image(spec: dict) -> Image.Image:
    w = {**COMPONENTS['wordmark'], **spec}
    font = ImageFont.truetype(str(ROOT / w['font']), w['size'])
    text = w['text']
    stroke = w['outline']
    probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    box = probe.textbbox((0, 0), text, font=font, stroke_width=stroke)
    depth = w.get('depth', 0)
    pad = stroke + depth + 4
    tw, th = box[2] - box[0] + 2 * pad, box[3] - box[1] + 2 * pad
    out = Image.new('RGBA', (tw, th))
    d = ImageDraw.Draw(out)
    org = (pad - box[0], pad - box[1] - depth // 2)
    dark = rgb(w['outline_color'])
    for i in range(depth, 0, -1):  # stepped extrusion, one pixel per step
        d.text((org[0], org[1] + i), text, font=font, fill=dark, stroke_width=stroke, stroke_fill=dark)
    d.text(org, text, font=font, fill=rgb(w['fill']), stroke_width=stroke, stroke_fill=dark)
    if w.get('fill_bottom'):
        # Two-tone fill: the lower part of the letters in a deeper gold (a flat band, no blur).
        glyphs = Image.new('L', out.size, 0)
        ImageDraw.Draw(glyphs).text(org, text, font=font, fill=255)
        band = Image.new('L', out.size, 0)
        cut = org[1] + int((box[3] - box[1]) * w.get('fill_split', 0.62)) + box[1]
        ImageDraw.Draw(band).rectangle((0, cut, out.width, out.height), fill=255)
        low = Image.new('RGBA', out.size, rgb(w['fill_bottom']))
        low.putalpha(ImageChops.multiply(glyphs, band))
        out.alpha_composite(low)
    if w.get('shine'):
        glyphs = Image.new('L', out.size, 0)
        ImageDraw.Draw(glyphs).text(org, text, font=font, fill=255)
        shifted = Image.new('L', out.size, 0)
        shifted.paste(glyphs, (0, w['shine'][1]))
        edge = ImageChops.subtract(glyphs, shifted)
        hi = Image.new('RGBA', out.size, rgb(w['shine'][0]))
        hi.putalpha(edge)
        out.alpha_composite(hi)
    if w.get('pixel', 1) > 1:
        k = w['pixel']
        small = out.resize((out.width // k, out.height // k), Image.BOX)
        small.putalpha(small.split()[3].point(lambda v: 255 if v > 110 else 0))
        out = up(small, k)
    return out


def layer_wordmark(canvas, spec):
    im = wordmark_image(spec)
    if spec.get('max_width') and im.width > spec['max_width']:
        raise SystemExit(f'wordmark {im.width}px exceeds max_width {spec["max_width"]}')
    place(canvas, im, spec['at'], spec.get('anchor', 'center'))


LAYERS = {'sky': layer_sky, 'tiles': layer_tiles, 'props': layer_props, 'actor': layer_actor,
          'glow': layer_glow, 'vignette': layer_vignette, 'band': layer_band, 'slot': layer_slot,
          'spark': layer_spark, 'item': layer_item, 'wordmark': layer_wordmark}


def render(comp: dict, layers_dir: Path | None = None) -> Image.Image:
    w, h = comp['size']
    canvas = Image.new('RGBA', (w, h), rgb(comp.get('background', [0, 0, 0])))
    for i, spec in enumerate(comp['layers']):
        if spec.get('skip'):
            continue
        if layers_dir is not None:
            alone = Image.new('RGBA', (w, h))
            LAYERS[spec['type']](alone, spec)
            alone.save(layers_dir / f'{i:02d}_{spec.get("name", spec["type"])}.png')
        LAYERS[spec['type']](canvas, spec)
    return canvas


# ----------------------------------------------------------------------------------------------- outputs

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(name: str) -> dict:
    comp = json.loads((HERE / 'compositions' / f'{name}.json').read_text(encoding='utf-8'))
    out = STORE / comp['output']
    out.parent.mkdir(parents=True, exist_ok=True)
    layers_dir = None
    if comp.get('export_layers'):
        layers_dir = STORE / 'source_layers' / name
        layers_dir.mkdir(parents=True, exist_ok=True)
        for old in layers_dir.glob('*.png'):
            old.unlink()
    im = render(comp, layers_dir).convert('RGB')
    im.save(out, optimize=True)
    return {'composition': f'marketing/brand/feature_graphic/compositions/{name}.json',
            'output': str(out.relative_to(ROOT)).replace('\\', '/'), 'size': list(im.size),
            'bytes': out.stat().st_size, 'sha256': sha(out)}


def check() -> list[str]:
    problems = []
    path = STORE / 'feature_graphic_1024x500.png'
    if not path.exists():
        return [f'missing {path}']
    im = Image.open(path)
    if im.size != (1024, 500):
        problems.append(f'size {im.size} != (1024, 500)')
    if im.mode != 'RGB':
        problems.append(f'mode {im.mode} != RGB (Play: 24-bit, no alpha)')
    if im.format != 'PNG':
        problems.append(f'format {im.format} != PNG')
    if path.stat().st_size > 15 * 1024 * 1024:
        problems.append('larger than 15 MB')
    return problems


def main() -> int:
    if '--check' in sys.argv:
        problems = check()
        print('FEATURE GRAPHIC CHECK', 'PASS' if not problems else 'FAIL', *problems, sep='\n  ')
        return 1 if problems else 0
    names = [a for a in sys.argv[1:] if not a.startswith('-')] or COMPONENTS['build_order']
    records = [build(n) for n in names]
    for r in records:
        print(f"{r['output']}  {r['size'][0]}x{r['size'][1]}  {r['bytes']} B  {r['sha256'][:12]}")
    manifest = STORE / 'feature_graphic_manifest.json'
    old = json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else {}
    old.update({r['composition']: r for r in records})
    manifest.write_text(json.dumps(old, indent=2) + '\n', encoding='utf-8', newline='\n')
    problems = check() if 'final' in names else []
    if problems:
        print('FEATURE GRAPHIC FAIL', *problems, sep='\n  ')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
