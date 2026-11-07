"""Structural check of LootFarmer's translation catalogs against the canonical English source
(Localization Batches 01-04, Changes 38, 39, 42 and 43; progressive activation, Change 40; Playbook 132.5).

For every catalog a player build enables (ENABLED_LANGUAGES in scripts/autoload/localization_service.gd) and every
validated test batch (TEST_BATCHES):
  - the exact English key set, in the English order, each key once;
  - a nonempty msgstr, no fuzzy flag, no msgctxt/plural forms the source does not have;
  - the same value placeholders (%s %d %.1f %02d ... in the same order: GDScript's % has no positional
    arguments), the same number of %% (it may move: Turkish writes the percent sign first, "%12"), the same
    number of \\n and the same fixed symbols (^ × → ✓ • ‹);
  - no raw semantic key and no msgstr equal to its English text unless tools/localization_allowlist.json names it;
  - no common English function words left in the text (a copy-through heuristic);
  - Polish, Russian, Ukrainian (Batch 02) and Hindi (Batch 03): no number placeholder directly followed by a
    noun whose form depends on the count (the source has no plural forms, so those catalogs use count-neutral
    wording);
  - Japanese, Simplified and Traditional Chinese (Batch 04): every CJK character belongs to the region's own
    character set (CP932, GB2312, Big5), so no Traditional glyph slips into zh_CN, no Simplified one into zh_TW
    or ja_JP; Korean: no particle whose form depends on the preceding syllable (을/를, 이/가, 은/는, 와/과, (으)로)
    is attached to a placeholder, and every Korean word carries its word joiners (tools/korean_keep_all.py) so
    lines wrap between words;
  - a Language header naming the catalog's locale.
It also checks the English catalog itself (unique keys, every scene-text key present), that project.godot
registers only en.po (LocalizationService loads the enabled catalogs on first use), and the readiness table:
every enabled locale is a target locale with a Godot locale and a native name, and the 20-language certification
flag stays false while any target locale is not enabled. Draft catalogs are not checked (they are not shipped).

Pending translations (Change 50+, Playbook 132.3-132.4): English keys added during gameplay batches after the
19 catalogs were delivered are listed in tools/localization_pending.json with their frozen English text and
placeholders. A non-English catalog may omit a pending key (players see the English fallback); a catalog that
already has it is checked normally. Every pending key must exist in en.po with exactly the listed text and
placeholders, so a later English edit without a handoff update fails. The summary line counts them.

This proves structure only. It cannot judge wording; the batch report records the linguistic review separately.
Usage: python tools/validate_localization.py [--json report.json]
"""
from pathlib import Path
import json, re, sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from korean_keep_all import keep_all
LOC = ROOT / 'localization'
PLACEHOLDER = re.compile(r'%(?:[-+0#]*\d*(?:\.\d+)?[sdif]|%)')
SYMBOLS = ['^', '×', '→', '✓', '•', '‹', '\\n']
ENGLISH_WORDS = re.compile(r"\b(?:the|and|your|you|with|from|this|that|when|then|every|each|until|before|after|while|will|have|can't|couldn't)\b", re.I)
BRANDS = re.compile(r'LootFarmer|Google Play|itch\.io|Pixel Plains|SnowHex|Kenney Fantasy UI Borders|CC0')
# Batch 02: the English source has no gettext plurals, so Polish, Russian and Ukrainian use count-neutral
# wording ("Монеты: %s", "Połączone kopie: %d"). A number placeholder may only be followed directly by a
# unit, an abbreviation, a preposition or a mass noun whose form does not change with the number.
COUNT_FOLLOWERS = {
    'pl_PL': {'s', 'min', 'godz', 'pkt', 'jedn', 'PŻ', 'PD', 'obrony', 'do', 'z', 'na', 'od', 'lub', 'więcej', 'jeszcze'},
    'ru_RU': {'с', 'мин', 'ч', 'п', 'ед', 'ОЗ', 'опыта', 'урона', 'к', 'из', 'на', 'до', 'от', 'ещё'},
    'uk_UA': {'с', 'хв', 'год', 'в', 'од', 'ОЗ', 'досвіду', 'шкоди', 'до', 'з', 'на', 'від', 'ще'},
    # Batch 03: Hindi -ā nouns change in the direct plural (1 सिक्का, 2 सिक्के; 1 घंटा, 2 घंटे) and feminine
    # plurals add -ẽ/-yā̃ (पोशाकें, प्रतियाँ). After a number: abbreviations, postpositions and invariant nouns only.
    # Words that follow a name placeholder (verbs, अभी) are listed too: they never change with a number either.
    'hi_IN': {'से', 'मि', 'घं', 'सेकंड', 'मिनट', 'HP', 'XP', 'अंक', 'बार', 'रत्न', 'यूनिट', 'दुश्मन', 'कार्ड', 'प्रकार',
              'स्थान', 'लेवल', 'बॉस', 'कैंप', 'स्लॉट', 'उपयोग', 'रक्षा', 'डैमेज', 'दिशा', 'उपाधि', 'की', 'का', 'के', 'को',
              'तक', 'पर', 'में', 'या', 'और', 'बाकी', 'अभी', 'पूरा', 'तय', 'चुनें', 'हराएँ', 'अनलॉक', 'स्वचालित'},
}
# Batch 04: the region's own character set. A character outside it is a glyph from the other script variant
# (or a rare form that needs a deliberate decision).
REGION_CHARSET = {'ja_JP': 'cp932', 'zh_CN': 'gb2312', 'zh_TW': 'big5'}
# Korean particles choose their form from the final consonant of the word before them, which a placeholder hides.
# (A word joiner, U+2060, may sit between them: tools/korean_keep_all.py.)
KOREAN_PARTICLE = re.compile(r'%(?:\.\d)?[sd]\u2060?(을|를|이|가|은|는|와|과|으로|로)(?![가-힣])')
COUNT_WORD = re.compile(r'%(?:\.\d)?[ds](?: | )([^\s\d%·•()/:,.;!?×\-−→+^—।]+)')


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


SERVICE = ROOT / 'scripts/autoload/localization_service.gd'


def batches():
    source = SERVICE.read_text(encoding='utf-8')
    block = re.search(r'const TEST_BATCHES: Dictionary = \{(.*?)\n\}', source, re.S).group(1)
    return {name: re.findall(r'"([a-z]{2}_\w+)"', langs) for name, langs in re.findall(r'"(\w+)": \[(.*?)\]', block)}


def readiness():
    """The service's readiness table: target list, enabled list, certification flag, Godot locales, native names."""
    source = SERVICE.read_text(encoding='utf-8')
    def const_block(name):
        return re.search(r'^const ' + name + r'\b.*?=\s*([\[{].*?[\]}])\s*$', source, re.S | re.M).group(1)
    pairs = lambda block: dict(re.findall(r'"(\w+)": "([^"]*)"', block))
    return {
        'target': re.findall(r'"(\w+)"', const_block('RELEASE_LANGUAGES')),
        'enabled': re.findall(r'"(\w+)"', re.search(r'^const ENABLED_LANGUAGES\b[^\n]*', source, re.M).group(0).split('=', 1)[1]),
        'certified': re.search(r'^const ALL_LANGUAGES_CERTIFIED: bool = (\w+)', source, re.M).group(1) == 'true',
        'godot': pairs(const_block('GODOT_LOCALES')),
        'native': pairs(const_block('NATIVE_NAMES')),
    }


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


PENDING = ROOT / 'tools/localization_pending.json'


def pending_keys(english, problems):
    """Keys awaiting translation: listed in the handoff manifest, frozen against the current English text."""
    if not PENDING.exists():
        return {}
    data = json.loads(PENDING.read_text(encoding='utf-8'))
    source = {k: v for k, v, _ in english}
    keys = data.get('keys', {})
    for key, entry in keys.items():
        if key not in source:
            problems.append(f'pending {key}: not in en.po')
            continue
        if entry.get('en') != source[key]:
            problems.append(f'pending {key}: English text changed since the handoff manifest was written')
        if entry.get('placeholders') != [p for p in PLACEHOLDER.findall(source[key])]:
            problems.append(f'pending {key}: placeholder record {entry.get("placeholders")} != {PLACEHOLDER.findall(source[key])}')
    return keys


def check_catalog(lang, english, allow, problems, pending=()):
    entries, header = read_po(LOC / f'{lang}.po')
    present = {k for k, _, _ in entries}
    # A pending key (tools/localization_pending.json) may be absent until its translation is delivered.
    english = [e for e in english if e[0] not in pending or e[0] in present]
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
        values = lambda s: [p for p in PLACEHOLDER.findall(s) if p != '%%']
        if values(value) != values(en) or value.count('%%') != en.count('%%'):
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
        for word in COUNT_WORD.findall(value) if lang in COUNT_FOLLOWERS else []:
            if word not in COUNT_FOLLOWERS[lang]:
                report['count_agreement'] = report.get('count_agreement', 0) + 1
                problems.append(f'{lang} {key}: "{word}" after a number changes form with the count; use count-neutral wording')
        if lang in REGION_CHARSET:
            for ch in value:
                if ord(ch) >= 0x2E80:
                    try:
                        ch.encode(REGION_CHARSET[lang])
                    except UnicodeEncodeError:
                        report['charset_errors'] = report.get('charset_errors', 0) + 1
                        problems.append(f'{lang} {key}: "{ch}" is outside {REGION_CHARSET[lang]} (other script variant?)')
        if lang == 'ko_KR' and KOREAN_PARTICLE.search(value):
            report['particle_errors'] = report.get('particle_errors', 0) + 1
            problems.append(f'{lang} {key}: a batchim-dependent particle follows a placeholder in "{value[:60]}"')
        if lang == 'ko_KR':
            unescaped = value.replace('\\n', '\n')
            if keep_all(unescaped) != unescaped:
                report['keep_all_errors'] = report.get('keep_all_errors', 0) + 1
                problems.append(f'{lang} {key}: Korean word without word joiners (run python tools/korean_keep_all.py)')
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
    ready = readiness()
    validated = [lang for lang in ready['enabled'] if lang != 'en_US']
    validated += [lang for langs in batches().values() for lang in langs if lang not in validated]
    pending = pending_keys(english, problems)
    reports = {lang: check_catalog(lang, english, allow, problems, pending) for lang in validated}
    for lang, r in reports.items():
        r['pending_missing'] = len(pending) - (r['keys'] - (len(english) - len(pending)))
    registered = re.findall(r'res://localization/(\w+)\.po', (ROOT / 'project.godot').read_text(encoding='utf-8'))
    if registered != ['en']:
        problems.append(f'project.godot registers {registered}; only en.po (LocalizationService loads the enabled catalogs)')
    if not ready['enabled'] or ready['enabled'][0] != 'en_US':
        problems.append('ENABLED_LANGUAGES must start with the en_US fallback')
    if ready['enabled'] != [lang for lang in ready['target'] if lang in ready['enabled']]:
        problems.append(f'ENABLED_LANGUAGES {ready["enabled"]} is not a subset of the target list in its order')
    for lang in validated + ['en_US']:
        if lang not in ready['godot']:
            problems.append(f'{lang}: no Godot locale mapping')
        if lang in ready['enabled'] and not ready['native'].get(lang):
            problems.append(f'{lang}: enabled without a native name')
    if ready['certified'] and ready['enabled'] != ready['target']:
        problems.append('ALL_LANGUAGES_CERTIFIED is true while target languages are not enabled')
    drafts = [lang for lang in ready['target'] if lang not in ready['enabled']]
    summary = {'english_keys': len(english), 'pending_translation': len(pending), 'enabled': ready['enabled'], 'drafts_hidden': drafts,
               'certified': ready['certified'], 'catalogs': reports, 'problems': problems}
    if '--json' in sys.argv:
        out = Path(sys.argv[sys.argv.index('--json') + 1])
        out.write_bytes((json.dumps(summary, ensure_ascii=False, indent=1) + '\n').encode('utf-8'))
    for lang, r in reports.items():
        print(lang, json.dumps(r))
    for p in problems:
        print('PROBLEM', p)
    print('LOCALIZATION_VALIDATION english_keys=%d pending_translation=%d enabled=%d catalogs=%d drafts_hidden=%d problems=%d' % (
        len(english), len(pending), len(ready['enabled']), len(reports), len(drafts), len(problems)))
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
