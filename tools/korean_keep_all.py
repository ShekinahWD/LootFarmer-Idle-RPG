"""Korean word wrapping for localization/ko_KR.po (Localization Batch 04, Change 43).

Korean UI text wraps at the spaces between words (CSS word-break: keep-all). Godot 4.7 breaks lines with ICU's
default rules, which allow a break between any two Hangul syllables, so a title could wrap as "즐기 / 고". Godot
ignores ICU's "@lw=keepall" locale keyword, and Label has no keep-all option. A WORD JOINER (U+2060, line-break
class WJ) between two characters forbids that break; HarfBuzz drops it, so it draws nothing and changes no width.

Rule (the keep-all definition): a joiner goes between two adjacent characters when both are Hangul, digits, Latin
letters or Han and at least one is Hangul ("3개", "^100까지", "%d개" stay whole). Breaks at spaces and around
punctuation are untouched, and a word wider than its label still wraps (Godot's AUTOWRAP_WORD_SMART).

Usage: python tools/korean_keep_all.py          rewrite ko_KR.po (idempotent: existing joiners are recomputed)
       python tools/korean_keep_all.py --check  fail if a Korean word lacks a joiner (validate_localization runs this)
"""
from pathlib import Path
import re, sys

PO = Path(__file__).resolve().parents[1] / 'localization/ko_KR.po'
WJ = '\u2060'


def hangul(c):
    return '\uac00' <= c <= '\ud7a3' or '\u1100' <= c <= '\u11ff' or '\u3130' <= c <= '\u318f'


def word_char(c):
    return hangul(c) or c.isascii() and c.isalnum() or '\u4e00' <= c <= '\u9fff'


def keep_all(text):
    """Text with a joiner inside every Korean word (text is unescaped: real newlines)."""
    text = text.replace(WJ, '')
    out = []
    for i, c in enumerate(text):
        if i and word_char(text[i - 1]) and word_char(c) and (hangul(text[i - 1]) or hangul(c)):
            out.append(WJ)
        out.append(c)
    return ''.join(out)


def unescape(s):
    return re.sub(r'\\(.)', lambda m: {'n': '\n', '"': '"', '\\': '\\'}[m.group(1)], s)


def escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')


def process(po_text):
    def fix(m):
        return 'msgstr "%s"' % escape(keep_all(unescape(m.group(1))))
    # The header entry (msgid "") is followed by a multi-line msgstr "" and is left alone.
    return re.sub(r'^msgstr "((?:[^"\\]|\\.)+)"$', fix, po_text, flags=re.M)


def main():
    text = PO.read_bytes().decode('utf-8')
    fixed = process(text)
    if '--check' in sys.argv:
        missing = sum(1 for a, b in zip(text.split('\n'), fixed.split('\n')) if a != b)
        print('KOREAN_KEEP_ALL ' + ('PASS' if not missing else 'FAIL: %d lines need joiners (run python tools/korean_keep_all.py)' % missing))
        sys.exit(1 if missing else 0)
    PO.write_bytes(fixed.encode('utf-8'))
    print('ko_KR.po: %d word joiners' % fixed.count(WJ))


if __name__ == '__main__':
    main()
