"""LootFarmer brand composition (Change 27): Google Play icon, Android launcher/adaptive icon layers and
the Google Play feature graphic, composed only from existing game sprites/tiles (Pixel Plains) and the
toolkit's Noto Sans (SIL OFL 1.1) for the wordmark. Pixel art is scaled by whole numbers with
nearest-neighbour sampling; nothing is painted, generated or filtered.

Usage (from the project root):
    python marketing/brand/compose_brand.py            # writes runtime icons + store branding + previews
    python marketing/brand/compose_brand.py --check    # validates the written files only

Outputs
    assets/branding/launcher_192.png               runtime (Android main icon, project icon)
    assets/branding/adaptive_foreground_432.png    runtime (adaptive foreground, transparent)
    assets/branding/adaptive_background_432.png    runtime (adaptive background, opaque)
    assets/branding/adaptive_monochrome_432.png    runtime (Android 13 themed icon, white on transparent)
    store_assets/branding/play_icon_512.png        Google Play icon, 32-bit RGBA, <= 1024 KB
    store_assets/branding/review/*.png             small-size previews for the human review
Edit marketing/brand/brand_config.json to move or rescale elements.

Change 28: the feature graphic moved to marketing/brand/feature_graphic/ (layered compositions). This
script no longer writes it, so re-running it for the icons cannot restore the rejected Change 27 graphic;
`feature()` and the `feature` config block stay as the record of that version.
"""
from __future__ import annotations

import hashlib
import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((Path(__file__).with_name('brand_config.json')).read_text(encoding='utf-8'))
CATALOG = json.loads((ROOT / 'data/game/catalog.json').read_text(encoding='utf-8'))
RUNTIME = ROOT / 'assets/branding'
STORE = ROOT / 'store_assets/branding'


def source(key: str) -> Image.Image:
    return Image.open(ROOT / CONFIG['sources'][key]).convert('RGBA')


def region(sheet: Image.Image, box) -> Image.Image:
    x, y, w, h = box
    return sheet.crop((x, y, x + w, y + h))


def trim(im: Image.Image) -> Image.Image:
    box = im.getbbox()
    return im.crop(box) if box else im


def up(im: Image.Image, k: int) -> Image.Image:
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def item(name: str) -> Image.Image:
    box = CONFIG['regions'][name]
    if box == 'catalog':
        box = CATALOG['items'][name]['icon']
    return trim(region(source('items'), box))


def idle(key: str) -> Image.Image:
    return trim(region(source(key), CONFIG['regions']['idle']))


def tinted(im: Image.Image, tint) -> Image.Image:
    # The game's helper look: the sprite modulated by EnemyAbilityRules.helper_tint.
    r, g, b, a = im.split()
    r = r.point(lambda v: int(v * tint[0]))
    g = g.point(lambda v: int(v * tint[1]))
    b = b.point(lambda v: int(v * tint[2]))
    return Image.merge('RGBA', (r, g, b, a))


def paste_center(canvas: Image.Image, im: Image.Image, at, bottom=False) -> None:
    x = int(at[0] * canvas.width - im.width / 2)
    y = int(at[1] * canvas.height - (im.height if bottom else im.height / 2))
    canvas.alpha_composite(im, (x, y))


def grass(width: int, height: int, scale: int, seed: int, light_band=None) -> Image.Image:
    tiles = source('tiles')
    rng = random.Random(seed)
    t = 16 * scale
    canvas = Image.new('RGBA', (width, height))
    for ty in range(0, height + t, t):
        for tx in range(0, width + t, t):
            key = 'grass_dark'
            if light_band and light_band[0] <= ty / height <= light_band[1]:
                key = 'grass_light'
            x, y = rng.choice(CONFIG['regions'][key])
            canvas.alpha_composite(up(tiles.crop((x, y, x + 16, y + 16)), scale), (tx, ty))
    return canvas


def shadow_under(canvas: Image.Image, sprite: Image.Image, at, scale: int) -> None:
    # The game's 17x6 actor shadow (Shadow.png), under the feet at half opacity like the world view.
    sh = up(source('shadow'), max(1, scale * 3 // 4))
    sh.putalpha(sh.split()[3].point(lambda v: v * 55 // 100))
    feet = at[1] * canvas.height + sprite.height / 2
    canvas.alpha_composite(sh, (int(at[0] * canvas.width - sh.width / 2), int(feet - sh.height * 0.6)))


def darken(im: Image.Image, factor: float) -> Image.Image:
    r, g, b, a = im.split()
    return Image.merge('RGBA', tuple(c.point(lambda v: int(v * factor)) for c in (r, g, b)) + (a,))


def hero(canvas: Image.Image, spec: dict) -> None:
    """The player in the Sprout outfit holding the Emerald Sword (its in-game icon)."""
    player = up(idle('player'), spec['player_scale'])
    sword = up(item('emerald_sword'), spec['sword_scale'])
    shadow_under(canvas, player, spec['player_at'], spec['player_scale'])
    # The sword's handle (bottom-left of its icon) rests at the player's right hand.
    px = spec['player_at'][0] * canvas.width; py = spec['player_at'][1] * canvas.height
    hand = (px + player.width * spec.get('hand', [0.42, 0.12])[0], py + player.height * spec.get('hand', [0.42, 0.12])[1])
    canvas.alpha_composite(player, (int(px - player.width / 2), int(py - player.height / 2)))
    canvas.alpha_composite(sword, (int(hand[0] - sword.width * 0.18), int(hand[1] - sword.height * 0.82)))


def icon_layer(spec: dict, background=True, foreground=True) -> Image.Image:
    size = spec['size']
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if background:
        canvas = darken(grass(size, size, spec['tile_scale'], 7), spec.get('background_darken', 0.82))
    if foreground:
        hero(canvas, spec)
    return canvas


def monochrome(foreground: Image.Image) -> Image.Image:
    alpha = foreground.split()[3]
    white = Image.new('RGBA', foreground.size, (255, 255, 255, 0))
    white.putalpha(alpha)
    return white


def wordmark(text: str, size: int, weight: int) -> Image.Image:
    font = ImageFont.truetype(str(ROOT / CONFIG['sources']['font']), size)
    # Axis order comes from the font (Noto Sans: Weight, Width); fail loudly rather than set the wrong face.
    axes = [a['name'] for a in font.get_variation_axes()]
    font.set_variation_by_axes([weight if name == b'Weight' else 100 for name in axes])
    stroke = max(4, size // 14)
    probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    box = probe.textbbox((0, 0), text, font=font, stroke_width=stroke)
    im = Image.new('RGBA', (box[2] - box[0] + 12, box[3] - box[1] + 12 + stroke * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Drop shadow and outline in the game's own dark UI outline colour, gold fill from the HUD coin.
    d.text((6 - box[0], 6 - box[1] + stroke), text, font=font, fill=(26, 28, 44, 255), stroke_width=stroke, stroke_fill=(26, 28, 44, 255))
    d.text((6 - box[0], 6 - box[1]), text, font=font, fill=(255, 214, 92, 255), stroke_width=stroke, stroke_fill=(32, 34, 52, 255))
    return im


def feature() -> Image.Image:
    spec = CONFIG['feature']
    w, h = spec['width'], spec['height']
    canvas = grass(w, h, spec['tile_scale'], spec['seed'], light_band=(0.45, 1.0))
    trees = source('trees')
    for name, x, y, k in spec['trees']:
        paste_center(canvas, up(region(trees, CONFIG['regions'][name]), k), (x, y))
    for name, x, y, k in spec['loot']:
        paste_center(canvas, up(item(name), k), (x, y))
    boss = up(idle('sunflower'), spec['boss_scale'])
    shadow_under(canvas, boss, spec['boss_at'], spec['boss_scale'])
    paste_center(canvas, boss, spec['boss_at'])
    for x, y, k in spec['helpers']:
        helper = up(tinted(idle('helper'), CONFIG['helper_tint']), k)
        shadow_under(canvas, helper, (x, y), k)
        paste_center(canvas, helper, (x, y))
    hero(canvas, spec)
    mark = wordmark(spec['wordmark'], spec['wordmark_size'], spec['wordmark_weight'])
    canvas.alpha_composite(mark, ((w - mark.width) // 2, spec['wordmark_y']))
    return canvas.convert('RGB')


def save(im: Image.Image, path: Path) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)
    return hashlib.sha256(path.read_bytes()).hexdigest()


def previews(play_icon: Image.Image, fg: Image.Image, bg: Image.Image) -> None:
    out = STORE / 'review'
    out.mkdir(parents=True, exist_ok=True)
    # Icon at the sizes it is seen (store grid, launcher, notification) on a light and a dark row.
    sizes = [512, 192, 96, 64, 48, 32]
    sheet = Image.new('RGB', (sum(sizes) + 20 * (len(sizes) + 1), 2 * 512 + 60), (240, 240, 240))
    x = 20
    for s in sizes:
        small = play_icon.resize((s, s), Image.LANCZOS if s < 512 else Image.NEAREST)
        mask = Image.new('L', (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, s - 1, s - 1), radius=int(s * 0.2), fill=255)
        sheet.paste(small.convert('RGB'), (x, 20), mask)
        dark = Image.new('RGB', (s + 20, s + 20), (32, 33, 36))
        dark.paste(small.convert('RGB'), (10, 10), mask)
        sheet.paste(dark, (x - 10, 532))
        x += s + 20
    sheet.save(out / 'play_icon_sizes.png')
    # Adaptive icon under the common launcher masks (circle, squircle, rounded square).
    full = bg.copy(); full.alpha_composite(fg)
    masks = Image.new('RGB', (3 * 252 + 40, 272), (240, 240, 240))
    for i, kind in enumerate(['circle', 'squircle', 'rounded']):
        crop = full.crop((54, 54, 378, 378)).resize((216, 216), Image.LANCZOS)  # 66% safe zone shown at 216 px
        m = Image.new('L', (216, 216), 0); d = ImageDraw.Draw(m)
        if kind == 'circle': d.ellipse((0, 0, 215, 215), fill=255)
        elif kind == 'squircle': d.rounded_rectangle((0, 0, 215, 215), radius=70, fill=255)
        else: d.rounded_rectangle((0, 0, 215, 215), radius=36, fill=255)
        masks.paste(crop.convert('RGB'), (20 + i * 252, 28), m)
    masks.save(out / 'adaptive_masks.png')


def check() -> list[str]:
    problems = []
    def need(path: Path, size, mode):
        if not path.exists():
            problems.append(f'missing {path}'); return None
        im = Image.open(path)
        if im.size != size: problems.append(f'{path.name}: size {im.size} != {size}')
        if im.mode != mode: problems.append(f'{path.name}: mode {im.mode} != {mode}')
        return im
    icon = need(STORE / 'play_icon_512.png', (512, 512), 'RGBA')
    if icon is not None and (STORE / 'play_icon_512.png').stat().st_size > 1024 * 1024: problems.append('play icon > 1024 KB')
    need(STORE / 'feature_graphic_1024x500.png', (1024, 500), 'RGB')
    need(RUNTIME / 'launcher_192.png', (192, 192), 'RGBA')
    bg = need(RUNTIME / 'adaptive_background_432.png', (432, 432), 'RGBA')
    fg = need(RUNTIME / 'adaptive_foreground_432.png', (432, 432), 'RGBA')
    mono = need(RUNTIME / 'adaptive_monochrome_432.png', (432, 432), 'RGBA')
    if bg is not None and bg.split()[3].getextrema() != (255, 255): problems.append('adaptive background must be opaque')
    for name, im in (('foreground', fg), ('monochrome', mono)):
        if im is None: continue
        a = im.split()[3]
        if a.getextrema()[0] != 0: problems.append(f'adaptive {name} must have transparency')
        # Content inside the 66% safe zone (Android adaptive icon: 72 of 108 dp).
        box = a.getbbox()
        if box and (box[0] < 72 or box[1] < 72 or box[2] > 360 or box[3] > 360): problems.append(f'adaptive {name} content {box} leaves the 288 px safe zone')
    return problems


def main() -> int:
    if '--check' in sys.argv:
        problems = check()
        print('BRAND CHECK', 'PASS' if not problems else 'FAIL', *problems, sep='\n  ')
        return 1 if problems else 0
    hashes = {}
    play_icon = icon_layer(CONFIG['icon'])
    hashes['store_assets/branding/play_icon_512.png'] = save(play_icon, STORE / 'play_icon_512.png')
    hashes['assets/branding/launcher_192.png'] = save(icon_layer(CONFIG['launcher']), RUNTIME / 'launcher_192.png')
    a = CONFIG['adaptive']
    fg = icon_layer(a, background=False)
    bg = icon_layer(a, foreground=False)
    hashes['assets/branding/adaptive_foreground_432.png'] = save(fg, RUNTIME / 'adaptive_foreground_432.png')
    hashes['assets/branding/adaptive_background_432.png'] = save(bg, RUNTIME / 'adaptive_background_432.png')
    hashes['assets/branding/adaptive_monochrome_432.png'] = save(monochrome(fg), RUNTIME / 'adaptive_monochrome_432.png')
    previews(play_icon, fg, bg)
    record = {'sources': CONFIG['sources'], 'outputs': hashes,
              'note': 'Composed from existing Pixel Plains sprites/tiles (licence record REL-02 pending) and Noto Sans (SIL OFL 1.1).'}
    (STORE / 'branding_manifest.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8', newline='\n')
    problems = check()
    print('BRAND', 'PASS' if not problems else 'FAIL', *problems, sep='\n  ')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
