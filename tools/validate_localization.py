"""Structural check of LootFarmer's translation catalogs against the canonical English source
(Localization Batch 01, Change 38; Playbook 132.5 mechanical checks).

For every catalog of the validated batches named in scripts/autoload/localization_service.gd (TEST_BATCHES):
  - the exact English key set, in the English order, each key once;
  - a nonempty msgstr, no fuzzy flag, no msgctxt/plural forms the source does not have;
  - the same placeholder sequence (%s %d %.1f %02d %% ... in the same order: GDScript's % has no positional
    arguments), the same number of \\n and the same fixed symbols (^ × → ✓ • ‹);
  - no raw semantic key and no msgstr equal to its English text unless tools/localization_allowlist.json names it;
  - no common English function words left in the text (a copy-through heuristic);
  - a Language header naming the catalog's locale.
It also checks the English catalog itself (unique keys, every scene-text key present) and that project.godot
still registers only en.po (the other catalogs ship only after the global 20-language gate).

This proves structure only. It cannot judge wording; the batch report records the linguistic review separately.
Usage: python tools/validate_localization.py [--json report.json]
"""
from pathlib import Path
import json, re, sys

ROOT = Path(__file__).resolve().parents[1]
LOC = ROOT / 'localization'
PLACEHOLDER = re.compile(r'%(?:[-+0#]*\d*(?:\.\d+)?[sdif]|%)')
SYMBOLS = ['^', '×', '→', '✓', '•', '‹', '\\n']
ENGLISH_WORDS = re.compile(r"\b(?:the|and|your|you|with|from|this|that|when|then|every|each|until|before|after|while|will|have|can't|couldn't)\b", re.I)
BRANDS = re.compile(r'LootFarmer|Google Play|itch\.io|Pixel Plains|SnowHex|Kenney Fantasy UI Borders|CC0')
GODOT_LOCALE = {'es_419': 'es', 'es_ES': 'es_ES', 'pt_BR': 'pt_BR', 'fr_FR': 'fr_FR', 'de_DE': 'de_DE'}


def read_po(path):
    """Ordered entries [(key, value, flags)] and the header of a single-line-msgid catalog (the project
    format). Line based: Godot accepts an entry that directly follows the previous msgstr, and so do we."""
    text = path.read_bytes().decode('utf-8')
    assert '\r' not in text, f'{path.name}: CRLF line endings'
    entries, header, flags, key, value, field = [], '', [], None, None, None
    for line in text.split('\n') + ['']:
        if line.startswith(('msgctxt', 'msgid_plural', 'msgstr[')):
            raise ValueError(f'{path.name}: context or plural entries are not used by the English source')
        if field == 'str' and not line.startswith('"'):
            if key == '':
                header = value
            else:
                entries.append((key, value, flags))
            key, field, flags = None, None, []
        if line.startswith('msgid "'):
            key, value, field = line[7:-1], '', 'id'
        elif line.startswith('msgstr "'):
            value, field = line[8:-1], 'str'
        elif line.startswith('"') and field == 'str':
            value += line[1:-1]
        elif line.startswith('#,'):
            flags.append(line[3:])
    return entries, header


def batches():
    source = (ROOT / 'scripts/autoload/localization_service.gd').read_text(encoding='utf-8')
    block = re.search(r'const TEST_BATCHES: Dictionary = \{(.*?)\n\}', source, re.S).group(1)
    return {name: re.findall(r'"([a-z]{2}_\w+)"', langs) for name, langs in re.findall(r'"(\w+)": \[(.*?)\]', block)}


def check_english(problems):
    entries, _ = read_po(LOC / 'en.po')
    keys = [k for k, _, _ in entries]
    if len(keys) != len(set(keys)):
        problems.append('en.po: duplicate keys')
    for k, v, _ in entries:
        if not v:
            problems.append(f'en.po {k}: empty English text')
    scene_keys = set()
    for scene in (ROOT / 'scenes').rglob('*.tscn'):
        scene_keys.update(re.findall(r'^(?:text|tooltip_text|title) = "([A-Z][A-Z0-9_]+)"$', scene.read_text(encoding='utf-8'), re.M))
    for k in sorted(scene_keys - set(keys)):
        problems.append(f'en.po: scene text key {k} missing')
    return entries


def check_catalog(lang, english, allow, problems):
    entries, header = read_po(LOC / f'{lang}.po')
    report = {'keys': len(entries), 'fuzzy': 0, 'empty': 0, 'placeholder_errors': 0, 'symbol_errors': 0,
              'english_copies': 0, 'allowlisted_copies': 0, 'english_words': 0, 'raw_keys': 0}
    m = re.search(r'Language: ([\w-]+)\\n', header)
    if not m or m.group(1) != lang:
        problems.append(f'{lang}: Language header {m.group(1) if m else None}')
    if [k for k, _, _ in entries] != [k for k, _, _ in english]:
        have, want = {k for k, _, _ in entries}, {k for k, _, _ in english}
        problems.append(f'{lang}: key set/order differs (missing {sorted(want - have)[:5]}, extra {sorted(have - want)[:5]})')
    source = {k: v for k, v, _ in english}
    translated = {k: v for k, v, _ in entries}
    for key, value, flags in entries:
        if key not in source:
            continue
        en = source[key]
        if any('fuzzy' in f for f in flags):
            report['fuzzy'] += 1
            problems.append(f'{lang} {key}: fuzzy')
        if not value.strip():
            report['empty'] += 1
            problems.append(f'{lang} {key}: empty')
            continue
        if PLACEHOLDER.findall(value) != PLACEHOLDER.findall(en):
            report['placeholder_errors'] += 1
            problems.append(f'{lang} {key}: placeholders {PLACEHOLDER.findall(value)} != {PLACEHOLDER.findall(en)}')
        for symbol in SYMBOLS:
            if value.count(symbol) != en.count(symbol):
                report['symbol_errors'] += 1
                problems.append(f'{lang} {key}: "{symbol}" count {value.count(symbol)} != {en.count(symbol)}')
        if re.fullmatch(r'[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+', value) and value != en:
            report['raw_keys'] += 1
            problems.append(f'{lang} {key}: raw key {value}')
        if value == en and re.search(r'[A-Za-z]{2,}', en):
            if key in allow.get(lang, {}):
                report['allowlisted_copies'] += 1
            else:
                report['english_copies'] += 1
                problems.append(f'{lang} {key}: identical to English and not allowlisted')
        if ENGLISH_WORDS.search(BRANDS.sub('', value)):
            report['english_words'] += 1
            problems.append(f'{lang} {key}: English word in "{value[:60]}"')
    for key in allow.get(lang, {}):
        if translated.get(key) != source.get(key):
            problems.append(f'{lang}: allowlist entry {key} is stale (no longer identical)')
    return report


def main():
    problems = []
    english = check_english(problems)
    allow = {k: v for k, v in json.loads((ROOT / 'tools/localization_allowlist.json').read_text(encoding='utf-8')).items() if not k.startswith('_')}
    validated = [lang for langs in batches().values() for lang in langs]
    reports = {lang: check_catalog(lang, english, allow, problems) for lang in validated}
    registered = re.findall(r'res://localization/(\w+)\.po', (ROOT / 'project.godot').read_text(encoding='utf-8'))
    if registered != ['en']:
        problems.append(f'project.godot registers {registered}; only en.po ships until the global 20-language gate')
    for lang in validated:
        if lang not in GODOT_LOCALE:
            problems.append(f'{lang}: no Godot locale mapping')
    summary = {'english_keys': len(english), 'catalogs': reports, 'problems': problems}
    if '--json' in sys.argv:
        out = Path(sys.argv[sys.argv.index('--json') + 1])
        out.write_bytes((json.dumps(summary, ensure_ascii=False, indent=1) + '\n').encode('utf-8'))
    for lang, r in reports.items():
        print(lang, json.dumps(r))
    for p in problems:
        print('PROBLEM', p)
    print('LOCALIZATION_VALIDATION english_keys=%d catalogs=%d problems=%d' % (len(english), len(reports), len(problems)))
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
