"""Builds LootFarmer's Japanese, Korean and Chinese UI fonts (Localization Batch 04, Change 43).

Source: the OFL 1.1 Noto Sans JP/KR/SC/TC variable fonts vendored in Godot-Marketing-Toolkit/assets/fonts/
(hashes in its font_manifest.json; this script refuses a source whose hash differs). Same procedure as
EverFort's tools/localization/build_font_subsets.py (fontTools instancer + subsetter), with two LootFarmer rules:

  * weight 400, matching the regular weight of the theme font (DejaVu Sans Book);
  * each locale font holds only the characters of that locale's catalog that DejaVu Sans lacks (kana, kanji,
    Hangul, Han, full-width punctuation), plus Simplified Chinese quotation marks, so in the locale chain
    (Noto first, DejaVu second) CJK text and CJK punctuation come from the regional Noto face while Latin
    letters, digits and UI symbols keep the theme font's shapes;
  * four tiny endonym fonts (日本語, 한국어, 简体中文, 繁體中文) for the language dropdown, each cut from its own
    regional face so every name keeps its own region's glyph forms in every UI language.

Each regional face is a separate font: Japanese text draws with Noto Sans JP, Simplified Chinese with SC,
Traditional with TC, so a Han character shared by the locales takes its locale's form. Re-run after changing
ja_JP.po, ko_KR.po, zh_CN.po or zh_TW.po; localization_batch04_probe fails when a catalog character is missing.

Usage: python tools/build_cjk_fonts.py [--check]   (--check: rebuild in memory and compare with the files)
"""
from pathlib import Path
import hashlib, io, json, re, sys, unicodedata

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'Godot-Marketing-Toolkit' / 'assets' / 'fonts'
OUT = ROOT / 'assets' / 'Fonts'
LOC = ROOT / 'localization'
# locale -> (source file, output file)
FACES = {
    'ja_JP': ('NotoSansJP[wght].ttf', 'NotoSansJP-LootFarmer.ttf'),
    'ko_KR': ('NotoSansKR[wght].ttf', 'NotoSansKR-LootFarmer.ttf'),
    'zh_CN': ('NotoSansSC[wght].ttf', 'NotoSansSC-LootFarmer.ttf'),
    'zh_TW': ('NotoSansTC[wght].ttf', 'NotoSansTC-LootFarmer.ttf'),
}
ENDONYMS = {'ja_JP': '日本語', 'ko_KR': '한국어', 'zh_CN': '简体中文', 'zh_TW': '繁體中文'}
# Chinese typography sets quotation marks full width; DejaVu's would be narrow Latin quotes.
EXTRA = {'zh_CN': '“”‘’'}
WEIGHT = 400


def catalog_text(locale):
    text = (LOC / f'{locale}.po').read_bytes().decode('utf-8')
    return ''.join(re.findall(r'^msgstr "(.*)"$', text, re.M)).replace('\\n', '')


def dejavu_cmap():
    return set(TTFont(OUT / 'DejaVuSans.ttf').getBestCmap())


def check_source(name):
    manifest = json.loads((SRC / 'font_manifest.json').read_text(encoding='utf-8'))
    entry = next(f for f in manifest['fonts'] if f['font_filename'] == name)
    digest = hashlib.sha256((SRC / name).read_bytes()).hexdigest()
    if digest != entry['font_sha256']:
        sys.exit(f'{name}: SHA-256 {digest} does not match font_manifest.json')


def build(source, text):
    font = TTFont(SRC / source)
    font = instancer.instantiateVariableFont(font, {'wght': WEIGHT})
    options = subset.Options()
    options.layout_features = ['*']
    options.name_IDs = ['*']
    options.name_languages = ['*']
    # An empty .notdef: Godot draws glyph 0 for a word joiner (U+2060) where a Korean word meets a DejaVu run
    # ("2.5<U+2060>초"); a boxed .notdef would show there. A real missing character still falls back to DejaVu first.
    options.notdef_outline = False
    options.drop_tables += ['DSIG']
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes={ord(c) for c in text})
    subsetter.subset(font)
    data = io.BytesIO()
    font.save(data)
    return data.getvalue()


def plan():
    latin = dejavu_cmap()
    files = {}
    for locale, (source, target) in FACES.items():
        check_source(source)
        # Format characters (the Korean word joiners, tools/korean_keep_all.py) draw nothing and need no glyph.
        chars = {c for c in catalog_text(locale) + ENDONYMS[locale] if ord(c) not in latin and unicodedata.category(c) != 'Cf'} | set(EXTRA.get(locale, ''))
        files[target] = (source, ''.join(sorted(chars)))
        files[target.replace('-LootFarmer', '-Endonym')] = (source, ENDONYMS[locale])
    return files


def main():
    files = plan()
    stale = []
    for target, (source, text) in files.items():
        data = build(source, text)
        if '--check' in sys.argv:
            # fontTools output is deterministic for the same inputs; compare the glyph sets, not timestamps.
            have = TTFont(OUT / target) if (OUT / target).exists() else None
            if have is None or set(have.getBestCmap()) != {ord(c) for c in text}:
                stale.append(target)
            continue
        (OUT / target).write_bytes(data)
        print(f'{target}: {len(text)} characters, {len(data) // 1024} KB')
    if '--check' in sys.argv:
        print('stale: ' + ', '.join(stale) if stale else 'CJK fonts up to date')
        sys.exit(1 if stale else 0)


if __name__ == '__main__':
    main()
