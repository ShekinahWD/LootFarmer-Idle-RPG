"""English-first strings for a gameplay batch after the 19 catalogs were delivered (Playbook 132.3-132.4).

  python tools/localization_handoff.py add <strings.json> --change=change-N
  python tools/localization_handoff.py change <strings.json> --change=change-N
  python tools/localization_handoff.py retire KEY [KEY ...] --change=change-N
  python tools/localization_handoff.py export <out.json>

add     writes every {key: English} entry into localization/en.po (tools/po_set.py: replaced in place or
        appended) and records it in tools/localization_pending.json with its frozen English text, its
        placeholders and the change that introduced it. Non-English catalogs are not touched: players see the
        English fallback until the translations are delivered. A key whose English meaning changes gets a
        NEW key (never an edit of a translated key), so no catalog keeps a stale, now-false translation.
change  for a key whose English meaning changed and whose key is fixed by code (e.g. built from an index):
        writes the new English, removes the now-false translation from every non-English catalog (players
        see the correct English until the new translation arrives) and records it as pending ("changed").
retire  removes obsolete keys from en.po and from every non-English catalog (a removal, not a translation),
        and from the manifest; the manifest keeps a retired list for the handoff.
export  writes the translator handoff: every pending key with English text, placeholders and change.
tools/validate_localization.py lets a catalog omit a pending key and fails if the English text drifts.
tools/integrate_translation_batch.py records each locale a batch delivered in the key's "translated" list (the
validator then requires the key in that catalog); add and change rewrite the entry, so "translated" starts empty.
"""
from pathlib import Path
import json, re, sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from po_set import write
LOC = ROOT / 'localization'
MANIFEST = ROOT / 'tools/localization_pending.json'
PLACEHOLDER = re.compile(r'%(?:[-+0#]*\d*(?:\.\d+)?[sdif]|%)')


def load():
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text(encoding='utf-8'))
    return {'_about': 'English keys awaiting translation into the 19 enabled non-English catalogs (Playbook 132.4 '
                      'handoff). Written by tools/localization_handoff.py; read by tools/validate_localization.py.',
            'keys': {}, 'retired': {}}


def save(data):
    MANIFEST.write_bytes((json.dumps(data, ensure_ascii=False, indent=1) + '\n').encode('utf-8'))


def remove(po, keys):
    text = po.read_bytes().decode('utf-8')
    n = 0
    for key in keys:
        pattern = re.compile(r'\n*^msgid "%s"\nmsgstr ".*"$' % re.escape(key), re.M)
        text, k = pattern.subn('', text, count=1)
        n += k
    po.write_bytes((text.rstrip('\n') + '\n').encode('utf-8'))
    return n


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    options = dict(a[2:].split('=', 1) for a in sys.argv[1:] if a.startswith('--') and '=' in a)
    if not args:
        print(__doc__); sys.exit(2)
    data = load()
    if args[0] == 'add':
        entries = json.loads(Path(args[1]).read_text(encoding='utf-8'))
        print('en.po', write(LOC / 'en.po', entries))
        for key, english in entries.items():
            data['keys'][key] = {'en': english, 'placeholders': PLACEHOLDER.findall(english),
                                 'change': options.get('change', '')}
        save(data)
    elif args[0] == 'change':
        entries = json.loads(Path(args[1]).read_text(encoding='utf-8'))
        print('en.po', write(LOC / 'en.po', entries))
        for po in sorted(LOC.glob('*.po')):
            if po.name != 'en.po':
                remove(po, list(entries))
        for key, english in entries.items():
            data['keys'][key] = {'en': english, 'placeholders': PLACEHOLDER.findall(english),
                                 'change': options.get('change', ''), 'status': 'changed'}
        save(data)
    elif args[0] == 'retire':
        for po in sorted(LOC.glob('*.po')):
            print(po.name, 'removed', remove(po, args[1:]))
        for key in args[1:]:
            data['keys'].pop(key, None)
            data['retired'][key] = options.get('change', '')
        save(data)
    elif args[0] == 'export':
        Path(args[1]).write_bytes((json.dumps(data, ensure_ascii=False, indent=1) + '\n').encode('utf-8'))
    else:
        print(__doc__); sys.exit(2)


if __name__ == '__main__':
    main()
