"""Inspects a real exported Android artifact (AAB or APK) against the export allowlist (Change 26, REL-05/06).

Reads the archive itself, not the project: the Godot files under the asset pack (AAB
assetPackInstallTime/assets/ or base/assets/, APK assets/), the sparse PCK directory Godot writes
there (assets.sparsepck: every path, size and MD5, checked against the stored files), the native
libraries per ABI and the package size. Each packed Godot file is mapped back to its source path
(X.import / X.remap / X.gdc / raw X) and compared with tools/export_manifest.json:
  missing     a manifest file (or its imported/remapped target) is not in the package
  unexpected  a packed source path the manifest does not list
  forbidden   tests, tools, docs, marketing, addons, keys, credentials, saves, Git data, excluded packs
  abis        lib/<abi> directories differ from the reviewed ABIs
Any of these fails the check (exit 1). Non-gating in the suite: it needs an exported artifact.
Change 40: a Godot .pck (godot --export-pack "<preset>" out.pck, e.g. the Windows itch.io preset) is read
directly from its file directory; it has no native libraries or Android manifest, so ABIs and identity are skipped.

Usage: python tools/verify_export.py builds/LootFarmerIdleRPG.26.aab [--baseline OLD.aab] [--report OUT.json]
       python tools/verify_export.py tests/tmp/export/windows.pck
The JSON report defaults to tests/tmp/export/<artifact>.json (ignored by Git).
"""
from pathlib import Path
import argparse, collections, hashlib, json, re, struct, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIXES = ['assetPackInstallTime/assets/', 'base/assets/', 'assets/']
ENGINE = {'project.binary', 'assets.sparsepck', '_cl_', '.godot/uid_cache.bin', '.godot/global_script_class_cache.cfg'}
FORBIDDEN = re.compile(r'(^|/)(tests|tools|docs|marketing|addons|Godot-Marketing-Toolkit|\.git|builds|store_assets|recordings)/'
                       r'|\.(keystore|jks|p12|pfx|env|save|bak)$|export_credentials|override\.cfg|(^|/)\.env')


def godot_root(names):
    for prefix in PREFIXES + ['']:
        if prefix + 'project.binary' in names:
            return prefix
    raise SystemExit('no Godot project.binary in the archive (not a Godot Android export?)')


def sparse_index(data):
    """Directory of a Godot 4 PCK (sparse or not): {path: (size, md5hex)}."""
    if data[:4] != b'GDPC':
        raise ValueError('not a PCK')
    fmt, major, minor, patch, flags = struct.unpack_from('<5I', data, 4)
    dir_offset = struct.unpack_from('<Q', data, 32)[0]
    pos = dir_offset if fmt >= 3 else 4 + 20 + 16 * 4
    count = struct.unpack_from('<I', data, pos)[0]
    pos += 4
    out = {}
    for _ in range(count):
        length = struct.unpack_from('<I', data, pos)[0]
        pos += 4
        path = data[pos:pos + length].rstrip(b'\0').decode('utf-8')
        pos += length
        offset, size = struct.unpack_from('<QQ', data, pos)
        pos += 16
        md5 = data[pos:pos + 16].hex()
        pos += 16 + 4
        out[path.removeprefix('res://')] = (size, md5)
    return out, '%d.%d.%d' % (major, minor, patch), fmt


def source_of(name):
    """Source res:// path a packed Godot file stands for, or None for engine/imported targets."""
    if name in ENGINE or name.startswith('.godot/'):
        return None
    for suffix in ('.import', '.remap'):
        if name.endswith(suffix):
            return name[:-len(suffix)]
    if name.endswith('.gdc'):
        return name[:-4] + '.gd'
    return name


def group_of(path):
    parts = path.split('/')
    if parts[0] == 'assets' and len(parts) > 2:
        return '/'.join(parts[:2 if parts[1] in ('Audio', 'Fonts', 'sounds') else 3])
    return parts[0] if len(parts) > 1 else path


class PckInfo:
    def __init__(self, filename, offset, size):
        self.filename, self.offset, self.file_size, self.compress_size = filename, offset, size, size

    def is_dir(self):
        return False


class PckArchive:
    """The zipfile calls inspect() and main() use, over a plain (non-encrypted) Godot 4 PCK."""
    def __init__(self, path):
        self.data = Path(path).read_bytes()
        if self.data[:4] != b'GDPC':
            raise SystemExit('%s is not a Godot PCK' % path)
        fmt = struct.unpack_from('<I', self.data, 4)[0]
        base = struct.unpack_from('<Q', self.data, 24)[0] if fmt >= 2 else 0
        pos = struct.unpack_from('<Q', self.data, 32)[0] if fmt >= 3 else 4 + 20 + 16 * 4
        count = struct.unpack_from('<I', self.data, pos)[0]
        pos += 4
        self.infos = []
        for _ in range(count):
            length = struct.unpack_from('<I', self.data, pos)[0]
            pos += 4
            name = self.data[pos:pos + length].rstrip(b'\0').decode('utf-8').removeprefix('res://')
            pos += length
            offset, size = struct.unpack_from('<QQ', self.data, pos)
            pos += 16 + 16 + 4
            self.infos.append(PckInfo(name, base + offset, size))

    def infolist(self):
        return self.infos

    def read(self, info):
        return self.data[info.offset:info.offset + info.file_size]


def inspect(artifact):
    z = PckArchive(artifact) if Path(artifact).suffix.lower() == '.pck' else zipfile.ZipFile(artifact)
    infos = {i.filename: i for i in z.infolist() if not i.is_dir()}
    root = godot_root(infos)
    packed = {n[len(root):]: i for n, i in infos.items() if n.startswith(root)}
    abis = collections.Counter()
    abi_bytes = collections.Counter()
    for n, i in infos.items():
        m = re.match(r'(?:base/)?lib/([^/]+)/', n)
        if m:
            abis[m.group(1)] += 1
            abi_bytes[m.group(1)] += i.compress_size
    return z, infos, root, packed, abis, abi_bytes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('artifact')
    parser.add_argument('--manifest', default=str(ROOT / 'tools/export_manifest.json'))
    parser.add_argument('--baseline')
    parser.add_argument('--report')
    args = parser.parse_args()
    artifact = Path(args.artifact)
    manifest = json.loads(Path(args.manifest).read_text(encoding='utf-8'))
    z, infos, root, packed, abis, abi_bytes = inspect(artifact)
    problems = collections.defaultdict(list)

    # Sparse PCK directory = the files Godot will mount; every one must be stored, byte-identical.
    index, engine_version, pck_format = {}, '', 0
    if 'assets.sparsepck' in packed:
        index, engine_version, pck_format = sparse_index(z.read(packed['assets.sparsepck']))
        for path, (size, md5) in index.items():
            info = packed.get(path)
            if info is None:
                problems['index_without_file'].append(path)
            elif info.file_size != size or hashlib.md5(z.read(info)).hexdigest() != md5:
                problems['index_mismatch'].append(path)
        for path in packed:
            if path not in index and path not in ENGINE:
                problems['file_not_in_index'].append(path)

    sources = collections.defaultdict(list)
    for name in packed:
        src = source_of(name)
        if src is not None:
            sources[src].append(name)
    expected = {p.removeprefix('res://') for p in manifest['files']}
    for path in sorted(expected):
        names = sources.get(path)
        if not names:
            problems['missing'].append(path)
            continue
        # The remap/import must point at a target that is really packed.
        for name in names:
            if name.endswith(('.import', '.remap')):
                text = z.read(packed[name]).decode('utf-8', 'replace')
                for target in re.findall(r'^path(?:\.[\w]+)?="res://([^"]+)"', text, re.M):
                    if target not in packed:
                        problems['missing_target'].append('%s -> %s' % (name, target))
    for path in sorted(set(sources) - expected):
        problems['unexpected'].append(path)
    for name in sorted(infos):
        rel = name[len(root):] if name.startswith(root) else name
        if FORBIDDEN.search(rel):
            problems['forbidden'].append(name)
    excluded = [g['prefix'].removeprefix('res://') for g in json.loads((ROOT / 'tools/export_rules.json').read_text(encoding='utf-8'))['excluded_groups']]
    for src in sources:
        if any(src.startswith(e) for e in excluded):
            problems['excluded_group_present'].append(src)
    stages = sorted(s for s in sources if re.fullmatch(r'scenes/game/stages/stage_\d+\.tscn', s))
    if len(stages) != manifest['counts']['stages']:
        problems['stages'].append('%d stage scenes packed, manifest has %d' % (len(stages), manifest['counts']['stages']))
    if not isinstance(z, PckArchive) and set(abis) != set(manifest['abis']):
        problems['abis'].append('packed %s, reviewed %s' % (sorted(abis), manifest['abis']))

    by_group = collections.Counter()
    for src, names in sources.items():
        for name in names:
            by_group[group_of(src)] += packed[name].compress_size
            text = z.read(packed[name]).decode('utf-8', 'replace') if name.endswith(('.import', '.remap')) else ''
            for target in re.findall(r'^path(?:\.[\w]+)?="res://([^"]+)"', text, re.M):
                if target in packed:
                    by_group[group_of(src)] += packed[target].compress_size
    # Identity from the compiled manifest (AAB protobuf or APK binary XML: the attribute values follow
    # their names as short strings, so a byte search is enough for a report line).
    identity = {}
    for name in ('base/manifest/AndroidManifest.xml', 'AndroidManifest.xml'):
        if name in infos:
            raw = z.read(infos[name])
            for key in ('versionCode', 'versionName', 'package', 'minSdkVersion', 'targetSdkVersion'):
                m = re.search(key.encode() + rb'.([\w.]+)', raw)
                if m:
                    identity[key] = m.group(1).decode('ascii', 'replace')
            break
    size = artifact.stat().st_size
    report = {
        'identity': identity,
        'artifact': artifact.name, 'bytes': size,
        'sha256': hashlib.sha256(artifact.read_bytes()).hexdigest(),
        'godot_root': root, 'pck_engine': engine_version, 'pck_format': pck_format,
        'entries': len(infos), 'godot_files': len(packed), 'index_entries': len(index),
        'sources': len(sources), 'manifest_files': len(expected), 'stages': stages,
        'abis': {a: {'files': abis[a], 'compressed_bytes': abi_bytes[a]} for a in sorted(abis)},
        'godot_content_bytes': sum(i.compress_size for i in packed.values()),
        'groups_compressed_bytes': dict(by_group.most_common()),
        'problems': {k: v for k, v in problems.items() if v},
    }
    if args.baseline:
        bz, binfos, broot, bpacked, babis, bbytes = inspect(Path(args.baseline))
        bsources = {s for s in (source_of(n) for n in bpacked) if s}
        report['baseline'] = {
            'artifact': Path(args.baseline).name, 'bytes': Path(args.baseline).stat().st_size,
            'entries': len(binfos), 'godot_files': len(bpacked), 'sources': len(bsources),
            'abis': sorted(babis), 'godot_content_bytes': sum(i.compress_size for i in bpacked.values()),
            'removed_source_groups': dict(collections.Counter(group_of(s) for s in bsources - set(sources)).most_common()),
            'added_sources': sorted(set(sources) - bsources),
        }
    out = Path(args.report) if args.report else ROOT / 'tests/tmp/export' / (artifact.name + '.json')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes((json.dumps(report, indent=1) + '\n').encode('utf-8'))
    print('%s  %.2f MB  sha256 %s' % (artifact.name, size / 1e6, report['sha256'][:16]))
    print('Identity: %s' % ', '.join('%s=%s' % kv for kv in identity.items()))
    print('ABIs: %s' % ', '.join('%s (%.2f MB)' % (a, abi_bytes[a] / 1e6) for a in sorted(abis)))
    print('Godot files %d (index %d, PCK %s), sources %d / manifest %d, stages %d, Godot content %.2f MB' % (
        len(packed), len(index), engine_version, len(sources), len(expected), len(stages), report['godot_content_bytes'] / 1e6))
    if args.baseline:
        b = report['baseline']
        print('Baseline %s  %.2f MB, ABIs %s, sources %d, Godot content %.2f MB' % (
            b['artifact'], b['bytes'] / 1e6, ','.join(b['abis']), b['sources'], b['godot_content_bytes'] / 1e6))
    for kind, items in report['problems'].items():
        print('  %s: %d  %s' % (kind, len(items), items[:5]))
    print('VERIFY_EXPORT %s  report %s' % ('FAIL' if report['problems'] else 'PASS', out.relative_to(ROOT) if out.is_relative_to(ROOT) else out))
    sys.exit(1 if report['problems'] else 0)


if __name__ == '__main__':
    main()
