"""Review sheets for the Change 28 feature graphic, built from the actual rendered files.

    python marketing/brand/feature_graphic/make_review.py

Writes to store_assets/branding/review/ (ignored) and copies the evidence set to docs/Change_28_Evidence/:
    feature_graphic_concepts.png       the three concepts + the refined final, with rubric scores
    feature_graphic_before_after.png   the rejected Change 27 graphic above the new one
    feature_graphic_small_sizes.png    the final at the sizes it is seen (desktop/YouTube-like, mobile card, thumbnails)
    feature_graphic_overlay_check.png  simulated video play button and assumed cutoff bands
"""
from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
STORE = ROOT / 'store_assets/branding'
REVIEW = STORE / 'review'
EVIDENCE = ROOT / 'docs/Change_28_Evidence'
OLD = ROOT / 'docs/Change_27_Evidence/feature_graphic_1024x500.png'  # the rejected graphic, tracked since Change 27
FONT = ROOT / 'Godot-Marketing-Toolkit/assets/fonts/NotoSans[wdth,wght].ttf'
RUBRIC = json.loads((HERE / 'concept_scores.json').read_text(encoding='utf-8'))
INK, PAPER, MUTED = (28, 27, 46), (245, 243, 238), (96, 96, 110)


def font(size: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([weight if a['name'] == b'Weight' else 100 for a in f.get_variation_axes()])
    return f


def concepts() -> Image.Image:
    entries = [(c['title'], c['thesis'], STORE / c['file'], c['score'], c.get('selected', False)) for c in RUBRIC['concepts']]
    w, h = 1024, 500
    pad, label = 28, 96
    sheet = Image.new('RGB', (2 * w + 3 * pad, 2 * (h + label) + 3 * pad + 40), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 14), 'LootFarmer feature graphic: concepts (Change 28). Rubric: mechanic 30, readability 25, polish 20, art fidelity 15, portrait reuse 10.', font=font(22, 600), fill=INK)
    for i, (title, thesis, path, score, selected) in enumerate(entries):
        x = pad + (i % 2) * (w + pad)
        y = 40 + pad + (i // 2) * (h + label + pad)
        d.text((x, y), f'{title}   score {score:g} / 10' + ('   SELECTED, refined below' if selected else ''), font=font(24, 700), fill=(170, 60, 40) if selected else INK)
        d.text((x, y + 34), thesis, font=font(17), fill=MUTED)
        im = Image.open(path).convert('RGB')
        sheet.paste(im, (x, y + label - 8))
        if selected or 'final' in path.name:
            d.rectangle((x - 4, y + label - 12, x + w + 3, y + label + h - 5), outline=(170, 60, 40), width=4)
    return sheet


def before_after() -> Image.Image:
    old = Image.open(OLD).convert('RGB')
    new = Image.open(STORE / 'feature_graphic_1024x500.png').convert('RGB')
    pad = 28
    sheet = Image.new('RGB', (1024 + 2 * pad, 2 * 500 + 3 * pad + 2 * 44), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, pad), 'BEFORE: Change 27 feature graphic (rejected: generic green scene, mechanic unclear)', font=font(22, 700), fill=INK)
    sheet.paste(old, (pad, pad + 40))
    y = 2 * pad + 500 + 44
    d.text((pad, y), 'AFTER: Change 28, enemy loot becomes your look', font=font(22, 700), fill=(170, 60, 40))
    sheet.paste(new, (pad, y + 40))
    return sheet


def small_sizes() -> Image.Image:
    """Downscaled the way stores and players show it (LANCZOS, like a browser/launcher), light and dark."""
    final = Image.open(STORE / 'feature_graphic_1024x500.png').convert('RGB')
    old = Image.open(OLD).convert('RGB')
    widths = [(512, 'desktop / YouTube-like preview 512 px'), (360, 'mobile store card 360 px'), (240, 'small card 240 px'), (160, 'thumbnail 160 px')]
    pad = 24
    row_h = 250 + 60
    sheet = Image.new('RGB', (2 * (sum(w for w, _ in widths) + pad * (len(widths) + 1)), 2 * row_h + 70), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 12), 'Readability at real sizes: new (top) and old (bottom), light and dark surroundings', font=font(22, 700), fill=INK)
    half = sheet.width // 2
    for r, (img, tag) in enumerate(((final, 'NEW'), (old, 'OLD'))):
        for side, bg in enumerate((PAPER, (32, 33, 36))):
            ox = side * half
            y = 50 + r * row_h
            if side:
                d.rectangle((ox, y - 6, sheet.width, y + row_h - 10), fill=bg)
            x = ox + pad
            for w, name in widths:
                h = round(w * 500 / 1024)
                small = img.resize((w, h), Image.LANCZOS)
                mask = Image.new('L', (w, h), 0)
                ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=max(6, w // 40), fill=255)
                sheet.paste(small, (x, y + 30), mask)
                d.text((x, y + 4), f'{tag} {name}', font=font(15, 600), fill=(220, 220, 225) if side else INK)
                x += w + pad
    return sheet


def overlays() -> Image.Image:
    """SIMULATED store overlays. Google asks for the focal point toward the centre, key elements out of
    'cutoff zones' and notes a play button over the graphic when a preview video exists, but publishes no
    measurements; the 10%/8% bands and the 88 px button here are a conservative assumption, not Google's spec."""
    final = Image.open(STORE / 'feature_graphic_1024x500.png').convert('RGBA')
    sim = final.copy()
    shade = Image.new('RGBA', sim.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shade)
    mx, my = int(1024 * 0.10), int(500 * 0.08)
    for box in ((0, 0, mx, 500), (1024 - mx, 0, 1024, 500), (mx, 0, 1024 - mx, my), (mx, 500 - my, 1024 - mx, 500)):
        d.rectangle(box, fill=(220, 30, 30, 90))
    d.ellipse((512 - 44, 250 - 44, 512 + 44, 250 + 44), fill=(0, 0, 0, 150))
    d.polygon([(500, 228), (500, 272), (536, 250)], fill=(255, 255, 255, 235))
    sim.alpha_composite(shade)
    pad = 24
    sheet = Image.new('RGB', (1024 + 2 * pad, 500 + 2 * pad + 70), PAPER)
    t = ImageDraw.Draw(sheet)
    t.text((pad, 12), 'SIMULATED: video play button and assumed cutoff bands (10% sides, 8% top/bottom)', font=font(20, 700), fill=INK)
    t.text((pad, 40), 'Google publishes no measurements for these; this is a conservative check, not the store UI.', font=font(17), fill=MUTED)
    sheet.paste(sim.convert('RGB'), (pad, 70 + pad))
    return sheet


def main() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    outputs = {'feature_graphic_concepts.png': concepts(), 'feature_graphic_before_after.png': before_after(),
               'feature_graphic_small_sizes.png': small_sizes(), 'feature_graphic_overlay_check.png': overlays()}
    for name, im in outputs.items():
        im.save(REVIEW / name, optimize=True)
    # Tracked evidence: the finished graphic, the review sheets, the portrait preview and the build manifest.
    copies = ['feature_graphic_1024x500.png', 'feature_graphic_manifest.json'] + [f'review/{n}' for n in outputs] + \
             ['review/feature_graphic_portrait_endcard_preview.png'] + [f'review/concepts/{c["file"].split("/")[-1]}' for c in RUBRIC['concepts'] if 'concepts/' in c['file']]
    for rel in copies:
        shutil.copyfile(STORE / rel, EVIDENCE / Path(rel).name)
        print('evidence', EVIDENCE.relative_to(ROOT) / Path(rel).name)


if __name__ == '__main__':
    main()
