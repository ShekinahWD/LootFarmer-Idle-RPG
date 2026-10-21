"""Set or add English strings in localization/en.po from a JSON object {msgid: msgstr}.
Usage: python tools/po_set.py strings.json   (UTF-8 JSON). Existing ids are replaced in place;
new ids are appended. Keeps LF endings and the file's existing order."""
from pathlib import Path
import json, re, sys

PO = Path(__file__).resolve().parents[1] / 'localization/en.po'


def escape(text):
    return text.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')


def main():
    entries = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
    text = PO.read_bytes().decode('utf-8')
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
    PO.write_bytes(text.encode('utf-8'))
    print(json.dumps({'replaced': replaced, 'added': added}))


if __name__ == '__main__':
    main()
