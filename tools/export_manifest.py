"""Dependency-verified export allowlist for the paid full game (Change 26, audit REL-06).

Closes the reviewed roots in tools/export_rules.json (plus the main scene, autoloads, icon and
translations from project.godot) over real dependencies: scene/resource ext_resources, literal
res:// paths in scripts/resources/data, class_name references, shader includes and the dynamic
families (stage scenes, item art indices, skill effect sheets, catalog paths). Fails closed: a
missing file, an unregistered non-literal load site, a stale rule, a forbidden path or an imported
asset without its .import file is an error, never a warning.

Usage:
  python tools/export_manifest.py            regenerate tools/export_manifest.json and the preset's export_files
  python tools/export_manifest.py --check    verify both are current (maintained suite step; no writes)
  python tools/export_manifest.py --why PATH print why a res:// path ships
  --catalog PATH  enumerate data families from another catalog (future Stage 16 demo generator; with
                  --manifest OUT it writes only that manifest and never touches export_presets.cfg)
"""
from pathlib import Path
import argparse, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / 'tools/export_rules.json'
MANIFEST = ROOT / 'tools/export_manifest.json'
PRESETS = ROOT / 'export_presets.cfg'
SKIP_DIRS = {'.godot', '.git', 'android', 'builds'}
IMPORTED = {'.png', '.svg', '.wav', '.ogg', '.mp3', '.ttf', '.otf', '.jpg', '.webp'}
LOAD_CALL = re.compile(r'(?<![\w.])(preload|load)\(|ResourceLoader\.(load|exists|load_threaded_request|load_threaded_get|load_threaded_get_status)\(')
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')

errors = []


def fail(message):
    errors.append(message)


def fs(res):
    return ROOT / res.removeprefix('res://')


def project_files():
    """Every res:// file the editor sees (directories with .gdignore are skipped, as Godot does)."""
    found = set()
    def walk(d):
        if (d / '.gdignore').exists():
            return
        for p in d.iterdir():
            if p.is_dir():
                if p.name not in SKIP_DIRS:
                    walk(p)
            else:
                found.add('res://' + p.relative_to(ROOT).as_posix())
    walk(ROOT)
    return found


def uid_paths(files):
    """uid://... -> res:// path, from the .import (uid="...") and .uid sidecars Godot writes next to each file."""
    out = {}
    for f in files:
        if f.endswith('.import'):
            m = re.search(r'^uid="(uid://[a-z0-9]+)"', fs(f).read_text(encoding='utf-8', errors='replace'), re.M)
            if m:
                out[m.group(1)] = f[:-len('.import')]
        elif f.endswith('.uid'):
            out[fs(f).read_text(encoding='utf-8', errors='replace').strip()] = f[:-len('.uid')]
    return out


def strip_comment(line):
    """GDScript line without its # comment (a # inside a string literal is kept)."""
    quote = None
    for i, ch in enumerate(line):
        if quote:
            if ch == '\\':
                continue
            if ch == quote:
                quote = None
        elif ch in '"\'':
            quote = ch
        elif ch == '#':
            return line[:i]
    return line


def call_arg(text, start):
    """First top-level argument of the call whose '(' ends at text[start-1]."""
    depth, quote, i = 0, None, start
    while i < len(text):
        ch = text[i]
        if quote:
            if ch == '\\':
                i += 1
            elif ch == quote:
                quote = None
        elif ch in '"\'':
            quote = ch
        elif ch in '([{':
            depth += 1
        elif ch in ')]}':
            if depth == 0:
                return text[start:i].strip()
            depth -= 1
        elif ch == ',' and depth == 0:
            return text[start:i].strip()
        i += 1
    return text[start:].strip()


def ints(text):
    return [int(x) for x in re.findall(r'(?<![\w.])\d+(?![\w.])', text)]


def catalog_values(catalog, dotted):
    values = [catalog]
    for key in dotted.split('.'):
        nxt = []
        for v in values:
            if key == '*':
                nxt.extend(v.values() if isinstance(v, dict) else v)
            elif isinstance(v, dict) and key in v:
                nxt.append(v[key])
        values = nxt
    return values


def res_strings(text):
    return [s for s in STRING.findall(text) if s.startswith('res://')]


class Manifest:
    def __init__(self, rules, catalog_path):
        self.rules = rules
        self.files = project_files()
        self.catalog = json.loads(fs(catalog_path).read_text(encoding='utf-8'))
        self.catalog_path = catalog_path
        self.why = {}
        self.queue = []
        self.sites_used = set()
        self.family_values = {name: set() for name in rules['families']}
        self.family_sites = {name: [] for name in rules['families']}
        self.classes = {}
        for f in sorted(self.files):
            if f.endswith('.gd'):
                m = re.search(r'^class_name\s+(\w+)', fs(f).read_text(encoding='utf-8'), re.M)
                if m:
                    self.classes[m.group(1)] = f

    def add(self, path, why):
        if path in self.why:
            return
        if path not in self.files:
            fail('missing dependency %s (%s)' % (path, why))
            return
        for prefix in self.rules['forbidden_prefixes']:
            if path.startswith(prefix):
                fail('forbidden path reached: %s (%s)' % (path, why))
        if Path(path).suffix.lower() in IMPORTED and path + '.import' not in self.files:
            fail('imported asset without .import (editor never imported it): %s' % path)
        self.why[path] = why
        self.queue.append(path)

    def site(self, file, **match):
        for i, s in enumerate(self.rules['sites']):
            if s['file'] == file and all(s.get(k) == v for k, v in match.items()) and set(match) >= {k for k in ('arg', 'literal', 'call') if k in s}:
                self.sites_used.add(i)
                return s
        return None

    def scan_script(self, path):
        lines = fs(path).read_text(encoding='utf-8').splitlines()
        code = [strip_comment(l) for l in lines]
        text = '\n'.join(code)
        consts = dict(re.findall(r'^const\s+(\w+)\s*(?::\s*\w+)?\s*:?=\s*"(res://[^"]*)"', text, re.M))
        for lit in res_strings(text):
            if '%' in lit or lit not in self.files:
                s = self.site(path, literal=lit)
                if s is None:
                    fail('%s: unaccounted res:// literal "%s" (missing file or dynamic pattern; register it in export_rules.json sites)' % (path, lit))
                elif '%' in lit and self.rules['families'][s['family']].get('pattern') != lit:
                    fail('%s: literal "%s" does not equal family %s pattern' % (path, lit, s['family']))
                continue
            self.add(lit, 'literal in ' + path)
        for n, line in enumerate(code):
            for m in LOAD_CALL.finditer(line):
                arg = call_arg(line, m.end())
                if re.fullmatch(r'"[^"]*"', arg) or arg in consts:
                    continue
                s = self.site(path, arg=arg)
                if s is None:
                    fail('%s:%d: unaccounted dynamic load site %s(%s)' % (path, n + 1, m.group(0)[:-1], arg))
                    continue
                self.use_site(s, line, arg)
            for name, wrapper in self.rules['wrappers'].items():
                for m in re.finditer(r'(?<![\w])' + re.escape(name) + r'\(', line):
                    if re.search(r'func\s+$', line[:m.start()]):
                        continue
                    arg = call_arg(line, m.end())
                    if re.fullmatch(r'\d+', arg):
                        self.family_values[wrapper['family']].add(int(arg))
                        continue
                    s = self.site(path, call=name, arg=arg)
                    if s is None:
                        fail('%s:%d: unaccounted %s(%s) (register the site and how its values are enumerated)' % (path, n + 1, name, arg))
                        continue
                    self.use_site(s, line, arg)
        bare = re.sub(r'"(?:[^"\\]|\\.)*"', '""', text)
        for cls in sorted(set(re.findall(r'\b([A-Z]\w*)\b', bare)) & set(self.classes)):
            if self.classes[cls] != path:
                self.add(self.classes[cls], 'class_name %s used by %s' % (cls, path))

    def use_site(self, s, line, arg):
        family = s['family']
        self.family_sites[family].append('%s: %s' % (s['file'], arg))
        if s.get('values') == 'line_ints':
            self.family_values[family].update(ints(line))
        elif s.get('values') == 'arg_ints':
            self.family_values[family].update(ints(arg))
        elif s.get('values') == 'const_strings':
            # Change 40: a one-line const list of names (the enabled language catalogs), minus 'skip'.
            for ref in s['consts']:
                file, name = ref.rsplit(':', 1)
                m = re.search(r'^const\s+' + name + r'\b[^\n]*', fs(file).read_text(encoding='utf-8'), re.M)
                if m is None:
                    fail('%s: const %s not found' % (file, name))
                else:
                    self.family_values[family].update(v for v in STRING.findall(m.group(0).split('=', 1)[1]) if v not in s.get('skip', []))
            return
        for ref in s.get('consts', []):
            file, name = ref.rsplit(':', 1)
            m = re.search(r'^const\s+' + name + r'\b[^\n]*', fs(file).read_text(encoding='utf-8'), re.M)
            if m is None:
                fail('%s: const %s not found' % (file, name))
            else:
                self.family_values[family].update(ints(m.group(0).split('=', 1)[1]))
        if self.rules['families'][family].get('concat'):
            parts = STRING.findall(arg)
            self.family_values[family].update(parts[0] + p for p in parts[1:] if p.endswith('.png'))

    def scan(self, path):
        suffix = Path(path).suffix
        if suffix == '.gd':
            self.scan_script(path)
            return
        if suffix not in ('.tscn', '.tres', '.gdshader', '.gdshaderinc', '.json'):
            return
        text = fs(path).read_text(encoding='utf-8')
        found = set(re.findall(r'\[ext_resource[^\]]*?path="([^"]+)"', text)) | set(res_strings(text))
        found |= set(re.findall(r'#include\s+"(res://[^"]+)"', text))
        for dep in sorted(found):
            self.add(dep, 'dependency of ' + path)

    def project_roots(self):
        text = (ROOT / 'project.godot').read_text(encoding='utf-8')
        main = re.search(r'^run/main_scene="([^"]+)"', text, re.M)
        self.add(main.group(1), 'project.godot main scene')
        for name, path in re.findall(r'^(\w+)="\*?(res://[^"]+)"', text.split('[autoload]', 1)[1].split('\n[', 1)[0], re.M):
            self.add(path, 'project.godot autoload ' + name)
        for path in res_strings(text):
            self.add(path, 'project.godot setting')
        # The editor may rewrite a setting as a uid:// reference (config/icon, Change 43 investigation); it names the
        # same file, recorded in that file's .import or .uid sidecar.
        uids = uid_paths(self.files)
        for uid in re.findall(r'"(uid://[a-z0-9]+)"', text):
            if uid not in uids:
                fail('project.godot references unknown %s' % uid)
            else:
                self.add(uids[uid], 'project.godot setting')

    def families(self):
        fams = self.rules['families']
        for name, fam in fams.items():
            if not self.family_sites[name]:
                fail('family %s has no load site in the code (stale rule)' % name)
            for dotted in fam.get('catalog', []):
                self.family_values[name].update(catalog_values(self.catalog, dotted))
            if fam.get('catalog_res_strings'):
                self.family_values[name].update(res_strings(json.dumps(self.catalog)))
        out = {}
        for name, fam in fams.items():
            values = sorted(self.family_values[name], key=lambda v: (str(type(v)), v))
            paths = []
            for v in values:
                if 'pattern' in fam:
                    paths.append(fam['pattern'] % ((v,) * fam['pattern'].count('%')))
                else:
                    paths.append(v)
            for p in paths:
                self.add(p, 'family ' + name)
            out[name] = {'pattern': fam.get('pattern', ''), 'why': fam['why'], 'values': values,
                         'sites': sorted(set(self.family_sites[name])), 'paths': sorted(set(paths))}
        return out

    def build(self):
        self.project_roots()
        for root in self.rules['roots']:
            self.add(root['path'], 'root: ' + root['why'])
        if self.catalog_path not in self.why:
            self.add(self.catalog_path, 'catalog')
        # Scripts are scanned first so every load site is seen before families are expanded.
        while self.queue:
            self.scan(self.queue.pop())
        families = self.families()
        while self.queue:
            self.scan(self.queue.pop())
        for i, s in enumerate(self.rules['sites']):
            if i not in self.sites_used:
                fail('stale site rule (not found in code): %s %s' % (s['file'], s.get('arg', s.get('literal'))))
        for group in self.rules['excluded_groups']:
            hit = [p for p in self.why if p.startswith(group['prefix'])]
            if hit:
                fail('excluded group %s is reached: %s' % (group['prefix'], hit[:3]))
        stages = sorted(p for p in self.why if p.startswith('res://scenes/game/stages/'))
        if len(stages) != len(self.catalog['stages']):
            fail('stage scenes %d != catalog stages %d' % (len(stages), len(self.catalog['stages'])))
        return {
            '_doc': 'Generated by tools/export_manifest.py from tools/export_rules.json. Do not edit by hand.',
            'preset': self.rules['preset'],
            'catalog': self.catalog_path,
            'abis': self.rules['abis'],
            'mirror_presets': self.rules.get('mirror_presets', []),
            'store_tags': self.rules.get('store_tags', {}),
            'counts': {'files': len(self.why), 'stages': len(stages),
                       'imported': sum(1 for p in self.why if p + '.import' in self.files)},
            'families': families,
            'files': dict(sorted(self.why.items())),
        }


def preset_block(text, name):
    m = re.search(r'^\[preset\.(\d+)\]\n(?:(?!^\[).*\n)*?name="%s"' % re.escape(name), text, re.M)
    if not m:
        raise SystemExit('preset %s not found' % name)
    idx = m.group(1)
    start = text.index('[preset.%s]' % idx)
    end = text.index('[preset.%s.options]' % idx)
    return idx, start, end


def preset_text(text, manifest):
    # Change 35: the itch.io presets (mirror_presets) ship exactly the same allowlist.
    for name in [manifest['preset']] + manifest.get('mirror_presets', []):
        text = one_preset_text(text, name, manifest)
    return text


def one_preset_text(text, name, manifest):
    idx, start, end = preset_block(text, name)
    block = text[start:end]
    files = 'PackedStringArray(%s)' % ', '.join('"%s"' % p for p in manifest['files'])
    block = re.sub(r'^export_filter=.*$', 'export_filter="resources"', block, flags=re.M)
    block = re.sub(r'^export_files=.*\n', '', block, flags=re.M)
    block = re.sub(r'^(export_filter=.*)$', lambda m: m.group(1) + '\nexport_files=' + files, block, flags=re.M)
    block = re.sub(r'^include_filter=.*$', 'include_filter=""', block, flags=re.M)
    return text[:start] + block + text[end:]


def static_preset_checks(text, manifest):
    for name in [manifest['preset']] + manifest.get('mirror_presets', []):
        idx, start, end = preset_block(text, name)
        if re.search(r'^platform="Android"$', text[start:end], re.M):
            android_preset_checks(text, name, manifest)
    store_checks(text, manifest)


def store_checks(text, manifest):
    """Change 35: each release preset declares exactly its reviewed store tag; other presets none."""
    tags = manifest.get('store_tags', {})
    for name, features in re.findall(r'^name="([^"]*)"\n(?:(?!^\[).*\n)*?custom_features="([^"]*)"', text, re.M):
        store = [f for f in features.replace(' ', '').split(',') if f.startswith('store_')]
        if name in tags:
            if store != [tags[name]]:
                fail('preset %s store tags %s != reviewed [%s]' % (name, store, tags[name]))
        elif store:
            fail('preset %s is not a reviewed release preset but declares store tags %s' % (name, store))
    for name in tags:
        if not re.search(r'^name="%s"$' % re.escape(name), text, re.M):
            fail('reviewed store preset %s missing from export_presets.cfg' % name)


def android_preset_checks(text, name, manifest):
    idx, start, end = preset_block(text, name)
    options = text[end:].split('\n[preset.', 1)[0]
    abis = {a for a, on in re.findall(r'^architectures/([\w-]+)=(\w+)$', options, re.M) if on == 'true'}
    if abis != set(manifest['abis']):
        fail('preset architectures %s != reviewed ABIs %s' % (sorted(abis), manifest['abis']))
    code = re.search(r'^version/code=(\d+)$', options, re.M).group(1)
    version = re.search(r'^config/version="([^"]*)"', (ROOT / 'project.godot').read_text(encoding='utf-8'), re.M).group(1)
    if code != version:
        fail('%s version/code %s != project config/version %s' % (name, code, version))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--why')
    parser.add_argument('--catalog')
    parser.add_argument('--manifest')
    args = parser.parse_args()
    rules = json.loads(RULES.read_text(encoding='utf-8'))
    catalog = args.catalog or rules['catalog']
    if catalog != rules['catalog'] and not args.manifest:
        raise SystemExit('--catalog needs --manifest OUT (the paid preset always uses the full catalog)')
    manifest = Manifest(rules, catalog).build()
    rendered = json.dumps(manifest, indent=1, ensure_ascii=False) + '\n'
    if args.why:
        print(manifest['files'].get(args.why, 'not exported'))
        return
    out = Path(args.manifest) if args.manifest else MANIFEST
    presets = PRESETS.read_bytes().decode('utf-8')
    if not args.manifest:
        static_preset_checks(presets, manifest)
    # Change 65: a stale allowlist is reported even when another error exists. A pending version-code
    # error once hid that three new scripts were missing from export_files (the Android build closed at
    # start because game_ui.gd could not preload them).
    if args.check and not args.manifest and preset_text(presets, manifest) != presets:
        fail('stale: export_presets.cfg export_files (run python tools/export_manifest.py)')
    if args.check and (not out.exists() or out.read_bytes().decode('utf-8') != rendered):
        fail('stale: %s (run python tools/export_manifest.py)' % out.relative_to(ROOT))
    if errors:
        print('EXPORT_MANIFEST FAIL %d error(s)' % len(errors))
        for e in errors:
            print('  ' + e)
        sys.exit(1)
    if args.check:
        stale = []
        if not out.exists() or out.read_bytes().decode('utf-8') != rendered:
            stale.append(str(out.relative_to(ROOT)))
        if preset_text(presets, manifest) != presets:
            stale.append('export_presets.cfg export_files')
        if stale:
            print('EXPORT_MANIFEST FAIL stale: %s (run python tools/export_manifest.py)' % ', '.join(stale))
            sys.exit(1)
    else:
        out.write_bytes(rendered.encode('utf-8'))
        if not args.manifest:
            PRESETS.write_bytes(preset_text(presets, manifest).encode('utf-8'))
    c = manifest['counts']
    print('EXPORT_MANIFEST PASS files=%d imported=%d stages=%d families=%s' % (
        c['files'], c['imported'], c['stages'], ','.join('%s:%d' % (k, len(v['paths'])) for k, v in manifest['families'].items())))


if __name__ == '__main__':
    main()
