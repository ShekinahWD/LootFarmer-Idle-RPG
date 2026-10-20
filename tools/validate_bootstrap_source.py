#!/usr/bin/env python3
"""Static checks only. Does not substitute for Godot import/probe or an Android test."""
from pathlib import Path
import ast
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
errors = []

def check(condition, message):
    if not condition:
        errors.append(message)

project = (ROOT / 'project.godot').read_text()
check('config/name="LootFarmer - Idle RPG"' in project, 'game identity')
check('window/handheld/orientation=1' in project, 'portrait orientation')
check(project.index('BootContext=') < project.index('SaveService='), 'save namespace initialization order')
check('locale/fallback="en"' in project, 'English fallback')
presets = (ROOT / 'export_presets.cfg').read_text()
check(presets.count('package/signed=true') == 2, 'both exports must be signed')
check(presets.count('permissions/internet=false') == 2, 'internet disabled')
check('keystore/release_password=' not in presets, 'no embedded signing password')
check(presets.count('version/name=""') == 2, 'Godot application version source')
for key in ['addons/marketing_capture/*', 'addons/store_screenshot_capture/*', 'tests/*', 'docs/*', 'tools/*']:
    check(presets.count(key) == 2, f'export exclusion: {key}')
for path in list((ROOT / 'scripts').rglob('*.gd')) + list((ROOT / 'scenes').rglob('*.tscn')) + [ROOT / 'ui/bootstrap_theme.tres', ROOT / 'project.godot']:
    for resource in re.findall(r'(?:\*?)res://([^"\n]+)', path.read_text()):
        check((ROOT / resource).is_file(), f'missing resource {resource}')
scene = (ROOT / 'scenes/main.tscn').read_text()
check(scene.count('disabled = true') == 19, '19 disabled locales')
check(len(re.findall(r'parent="SafeArea/Scroll/Content/Languages"', scene)) == 21, '20 languages plus Automatic')
catalog = (ROOT / 'localization/en.po').read_text()
keys = set(re.findall(r'^msgid "([A-Z][A-Z0-9_]+)"$', catalog, re.M))
for path in [ROOT / 'scenes/main.tscn', ROOT / 'scripts/main.gd']:
    for key in re.findall(r'"((?:APP|BOOT|UI|LANG|SETTINGS)_[A-Z0-9_]+)"', path.read_text()):
        check(key in keys, f'missing English key {key}')
for path in (ROOT / 'tools').glob('*.py'):
    ast.parse(path.read_text(), filename=str(path))
lock = json.loads((ROOT / 'marketing_capture_toolkit.lock.json').read_text())
check('1.0.2' in json.dumps(lock), 'toolkit pin')
manifest = ROOT / 'Godot-Marketing-Toolkit/PACKAGE_FILES.sha256'
for line in manifest.read_text().splitlines():
    if not line.strip():
        continue
    digest, relative = line.split(maxsplit=1)
    path = manifest.parent / relative.lstrip('* ')
    check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == digest, f'toolkit package integrity: {relative}')
for path in ROOT.rglob('*'):
    if path.is_file() and path.suffix in ('.keystore', '.jks', '.p12', '.pfx'):
        errors.append(f'signing key inside project: {path.name}')
if errors:
    raise SystemExit('\n'.join('FAIL: ' + value for value in errors))
print('STATIC_BOOTSTRAP_SOURCE PASS')
print('Godot parser, runtime, Android export/signature and physical-device validation NOT run.')
