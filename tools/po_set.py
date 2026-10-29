"""Set or add English strings in localization/en.po from a JSON object {msgid: msgstr}.
Usage: python tools/po_set.py strings.json   (UTF-8 JSON). Existing ids are replaced in place;
new ids are appended. Keeps LF endings and the file's existing order.
Change 41: --po=localization/<locale>.po writes into another catalog the same way, and
--translations={locale: {msgid: msgstr}} JSON writes every listed catalog: appending in the JSON's key
order keeps each catalog in the English key order the validator expects."""
from pathlib import Path
import json, re, sys

PO = Path(__file__).resolve().parents[1] / 'localization/en.po'


def escape(text):
    return text.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    options = dict(a[2:].split('=', 1) for a in sys.argv[1:] if a.startswith('--') and '=' in a)
    if 'translations' in options:
        table = json.loads(Path(options['translations']).read_text(encoding='utf-8'))
        for lang, entries in table.items():
            print(lang, write(PO.parent / f'{lang}.po', entries))
        return
    entries = json.loads(Path(args[0]).read_text(encoding='utf-8'))
    target = Path(options['po']) if 'po' in options else PO
    print(json.dumps(write(target, entries)))


def write(po, entries):
    text = po.read_bytes().decode('utf-8')
    added = replaced = 0
    for key, value in entries.items():
        pattern = re.compile(r'^msgid "%s"\nmsgstr ".*"$' % re.escape(key), re.M)
        line = 'msgid "%s"\nmsgstr "%s"' % (key, escape(value))
        if pattern.search(text):
            text = pattern.sub(lambda _m: line, text, count=1)
            replaced += 1
        else:
            text = text.rstrip('\n') + '\n\n' + line + '\n'
            added += 1
    po.write_bytes(text.encode('utf-8'))
    return {'replaced': replaced, 'added': added}


if __name__ == '__main__':
    main()
