"""Integrate one batch of a targeted translation package into the shipped catalogs (Playbook 132.4-132.5;
first used for the progression update, Changes 50-55, Localization Batch 01 of that package).

  python tools/integrate_translation_batch.py <package.zip> --batch=batch01            (dry run: verify only)
  python tools/integrate_translation_batch.py <package.zip> --batch=batch01 --write    (write the catalogs)
  python tools/integrate_translation_batch.py <package.zip> --batch=batch01 --check --baseline-rev=HEAD

The package (a ZIP from the translator; read in place, never extracted into the project) holds complete catalogs
plus change_scope.json (the IDs this update covers, the batch manifest and the English hash) and
translation_validation.json (per-file hashes). A complete catalog is a convenience, not permission: only the
scoped IDs are taken from it. For every locale of the batch the tool

  1. checks the current English catalog hash against the package and the package files against their hashes;
  2. checks the scope equals the keys in tools/localization_pending.json (the handoff the translator received);
  3. requires every non-scoped package entry to equal the current catalog's value, byte for byte, with the same
     key set (a package that rewrote an approved translation is refused, not merged);
  4. inserts each scoped entry into the CURRENT catalog at its English position (the validator requires the
     English order); every other byte of the current file is kept, header included;
  5. proves it: removing the scoped entries from the result gives back the original file exactly, and the
     result has the English key set in the English order;
  6. with --write, writes the catalogs and records the locales in each pending key's "translated" list, which
     makes tools/validate_localization.py require those keys in those catalogs from now on.

--corrections=<file.json> applies reviewed corrections to scoped values ({"batch": ..., "corrections": {locale: {key:
{"value": final msgstr, "reasons": [...]}}}}): misplaced translations, terminology, register, typography. A correction
for a key outside the scope or a locale outside the batch is refused, so the approved entries stay protected.

--check compares the working-tree catalogs with a git revision instead (after --write, before the commit): every
key present at that revision keeps its exact value, only scoped keys were added, and each added value equals the
package's (or its correction). Prints one line per locale: unchanged, changed, added, corrected.
"""
from pathlib import Path
import hashlib, json, re, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from validate_localization import read_po
LOC = ROOT / 'localization'
MANIFEST = ROOT / 'tools/localization_pending.json'
ENTRY = re.compile(r'^msgid "((?:[^"\\]|\\.)*)"$', re.M)


def blocks(text):
    """Split a catalog into its header block and {key: entry text}, keeping each entry's exact bytes
    (comments, flags and continuation lines included). Entries are separated by one blank line."""
    parts = text.rstrip('\n').split('\n\n')
    header, entries, order = parts[0], {}, []
    for part in parts[1:]:
        m = ENTRY.search(part)
        if not m:
            raise ValueError('unparsed block: %r' % part[:80])
        if m.group(1) in entries:
            raise ValueError('duplicate key %s' % m.group(1))
        entries[m.group(1)] = part
        order.append(m.group(1))
    return header, entries, order


def join(header, entries, order):
    return '\n\n'.join([header] + [entries[k] for k in order]) + '\n'


def digits(text):
    """The numbers a message states, ignoring placeholders and digit grouping/decimal separators."""
    text = re.sub(r'%[-+0#]*\d*(?:\.\d+)?[sdif]', ' ', text)
    return sorted(re.findall(r'\d+', re.sub(r'[.,   ]', '|', text)))


def values(text, name):
    tmp = ROOT / '.godot' / ('_integrate_%s.po' % name)
    tmp.write_bytes(text.encode('utf-8'))
    try:
        entries, header = read_po(tmp)
    finally:
        tmp.unlink()
    return {k: v for k, v, _ in entries}, [k for k, _, _ in entries], header


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    opts = dict(a[2:].split('=', 1) if '=' in a else (a[2:], True) for a in sys.argv[1:] if a.startswith('--'))
    if len(args) != 1 or 'batch' not in opts:
        print(__doc__); sys.exit(2)
    package = Path(args[0]).resolve()
    if LOC.resolve() in package.parents:
        sys.exit('the package must stay outside localization/ (Playbook 132.5)')
    problems = []
    with zipfile.ZipFile(package) as z:
        scope = json.loads(z.read('change_scope.json').decode('utf-8'))
        hashes = json.loads(z.read('translation_validation.json').decode('utf-8'))
        langs = scope['batches'][opts['batch']]
        package_text = {lang: z.read('localization/%s.po' % lang) for lang in langs}
    english_bytes = (LOC / 'en.po').read_bytes()
    english_sha = hashlib.sha256(english_bytes).hexdigest()
    if english_sha != scope['english_catalog_sha256'] or english_sha != hashes['english_sha256']:
        sys.exit('STOP: localization/en.po is %s; the package was made from %s' % (english_sha, scope['english_catalog_sha256']))
    english, english_order, _ = values(english_bytes.decode('utf-8'), 'en')
    ids = list(scope['new_keys']) + list(scope['changed_meaning_keys'])
    retired = list(scope.get('retired_already_absent', []))
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    if set(ids) != set(manifest['keys']) or len(ids) != len(set(ids)):
        problems.append('scope (%d IDs) differs from tools/localization_pending.json (%d keys)' % (len(ids), len(manifest['keys'])))
    if set(retired) != set(manifest.get('retired', {})):
        problems.append('retired list differs from the manifest')
    missing_en = [k for k in ids if k not in english]
    if missing_en:
        problems.append('scoped keys not in en.po: %s' % missing_en[:5])
    corrections, digit_exceptions = {}, {}
    if 'corrections' in opts:
        data = json.loads(Path(opts['corrections']).read_text(encoding='utf-8'))
        digit_exceptions = data.get('digit_exceptions', {})
        if data.get('batch') != opts['batch']:
            problems.append('corrections file is for %s, not %s' % (data.get('batch'), opts['batch']))
        for lang, entries in data['corrections'].items():
            if lang not in langs:
                problems.append('correction for %s, which is not in %s' % (lang, opts['batch']))
            for key, entry in entries.items():
                if key not in ids:
                    problems.append('%s %s: correction outside the scope (approved entries are protected)' % (lang, key))
                if '"' in entry['value'].replace('\\"', '') or '\n' in entry['value']:
                    problems.append('%s %s: correction is not a single escaped msgstr line' % (lang, key))
            corrections[lang] = {k: e['value'] for k, e in entries.items()}
    print('english sha256 %s keys %d; scope %d (%d new, %d changed meaning); retired %d; batch %s %s' % (
        english_sha, len(english), len(ids), len(scope['new_keys']), len(scope['changed_meaning_keys']),
        len(retired), opts['batch'], ','.join(langs)))
    results = {}
    for lang in langs:
        raw = package_text[lang]
        if hashlib.sha256(raw).hexdigest() != hashes['languages'][lang]['sha256']:
            problems.append('%s: package file hash differs from translation_validation.json' % lang)
        if 'check' in opts:
            rev = opts.get('baseline-rev', 'HEAD')
            base_text = subprocess.run(['git', 'show', '%s:localization/%s.po' % (rev, lang)], cwd=ROOT,
                                       capture_output=True, check=True).stdout.decode('utf-8')
        else:
            base_text = (LOC / ('%s.po' % lang)).read_bytes().decode('utf-8')
        pkg_text = raw.decode('utf-8')
        base_vals, base_order, base_header = values(base_text, lang + '_base')
        pkg_vals, _, _ = values(pkg_text, lang + '_pkg')
        # 3. the package may differ from the approved catalog only in scoped keys.
        outside = [k for k in set(base_vals) | set(pkg_vals) if k not in ids and base_vals.get(k) != pkg_vals.get(k)]
        if outside:
            problems.append('%s: package changes %d approved entries outside the scope, e.g. %s' % (lang, len(outside), sorted(outside)[:5]))
        if [k for k in ids if k not in pkg_vals]:
            problems.append('%s: package lacks scoped keys' % lang)
        if [k for k in retired if k in pkg_vals]:
            problems.append('%s: package reintroduces retired keys' % lang)
        fixed = corrections.get(lang, {})
        expected = {k: fixed.get(k, pkg_vals.get(k)) for k in ids}
        # A translation filed under the wrong key usually carries the wrong numbers (Batch 01: ten Expedition and
        # Collection descriptions were shifted). Every scoped value must carry the English numbers unless the
        # corrections file names the key with a reason.
        for k in ids:
            if expected.get(k) is not None and digits(expected[k]) != digits(english[k]) and k not in digit_exceptions.get(lang, {}):
                problems.append('%s %s: numbers %s differ from English %s (misplaced translation?)' % (lang, k, digits(expected[k]), digits(english[k])))
        if 'check' in opts:
            cur_text = (LOC / ('%s.po' % lang)).read_bytes().decode('utf-8')
            cur_vals, cur_order, cur_header = values(cur_text, lang + '_cur')
            unchanged = sum(1 for k in base_vals if cur_vals.get(k) == base_vals[k])
            changed = [k for k in base_vals if k in cur_vals and cur_vals[k] != base_vals[k]]
            removed = [k for k in base_vals if k not in cur_vals]
            added = [k for k in cur_vals if k not in base_vals]
            if changed or removed or set(added) - set(ids) or cur_header != base_header:
                problems.append('%s: %d changed, %d removed, extra %s, header %s' % (lang, len(changed), len(removed), sorted(set(added) - set(ids))[:5], cur_header == base_header))
            bad = [k for k in added if cur_vals[k] != expected.get(k)]
            if bad:
                problems.append('%s: added values differ from the package and its corrections: %s' % (lang, bad[:5]))
            if cur_order != english_order:
                problems.append('%s: key order differs from English' % lang)
            results[lang] = {'baseline': len(base_vals), 'unchanged': unchanged, 'changed': len(changed), 'removed': len(removed), 'added': len(added), 'corrected': len(fixed), 'total': len(cur_vals)}
            continue
        # 4. insert the scoped entries into the current file at their English positions.
        header, base_blocks, _ = blocks(base_text)
        _, pkg_blocks, _ = blocks(pkg_text)
        already = [k for k in ids if k in base_blocks]
        for k in already:
            if base_vals[k] != expected[k]:
                problems.append('%s: %s is already present with a different value' % (lang, k))
        merged = dict(base_blocks)
        for k in ids:
            merged.setdefault(k, 'msgid "%s"\nmsgstr "%s"' % (k, fixed[k]) if k in fixed else pkg_blocks[k])
        out = join(header, merged, english_order)
        # 5. prove the result: original bytes outside the scope, English key set and order, package values in scope.
        stripped = dict(merged)
        for k in ids:
            if k not in base_blocks:
                stripped.pop(k)
        if join(header, stripped, [k for k in english_order if k in stripped]) != base_text.rstrip('\n') + '\n':
            problems.append('%s: the result does not reduce to the original file outside the scope' % lang)
        out_vals, out_order, _ = values(out, lang + '_out')
        if out_order != english_order:
            problems.append('%s: result key order differs from English' % lang)
        if any(out_vals[k] != base_vals[k] for k in base_vals):
            problems.append('%s: an approved value changed' % lang)
        if any(out_vals[k] != expected[k] for k in ids):
            problems.append('%s: a scoped value differs from the package and its corrections' % lang)
        results[lang] = {'baseline': len(base_vals), 'unchanged': sum(1 for k in base_vals if out_vals[k] == base_vals[k]),
                         'changed': 0, 'added': len(ids) - len(already), 'corrected': len(fixed), 'total': len(out_vals), 'text': out}
    for lang, r in results.items():
        print(lang, ' '.join('%s=%s' % (k, v) for k, v in r.items() if k != 'text'))
    for p in problems:
        print('PROBLEM', p)
    if problems:
        sys.exit(1)
    if 'write' in opts and 'check' not in opts:
        for lang, r in results.items():
            (LOC / ('%s.po' % lang)).write_bytes(r['text'].encode('utf-8'))
        package_order = [l for batch in scope['batches'].values() for l in batch]
        for k in ids:
            entry = manifest['keys'][k]
            done = set(entry.get('translated', [])) | set(langs)
            entry['translated'] = [l for l in package_order if l in done]
        MANIFEST.write_bytes((json.dumps(manifest, ensure_ascii=False, indent=1) + '\n').encode('utf-8'))
        print('wrote %d catalogs; manifest records %s as translated for %d keys' % (len(results), ','.join(langs), len(ids)))
    print('INTEGRATE_TRANSLATION_BATCH %s locales=%d problems=0%s' % (opts['batch'], len(results), '' if 'write' in opts or 'check' in opts else ' (dry run)'))


if __name__ == '__main__':
    main()
