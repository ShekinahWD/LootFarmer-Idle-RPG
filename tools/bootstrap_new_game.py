#!/usr/bin/env python3
from pathlib import Path
import argparse
import json
import re


def slugify(name: str) -> str:
    value = re.sub(r"[^A-Za-z0-9]+", "", name)
    return value or "NewGame"


def replace_setting(text: str, key: str, value: str) -> str:
    pattern = rf'(?m)^{re.escape(key)}=.*$'
    replacement = f'{key}={value}'
    new_text, count = re.subn(pattern, replacement, text)
    if count < 1:
        raise RuntimeError(f"Expected setting for {key}, found {count}")
    return new_text


def main() -> None:
    parser = argparse.ArgumentParser(description="Configure the reusable Godot starter for a new game.")
    parser.add_argument("--name", required=True, help="Player-facing game name")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--version-code", type=int, default=1)
    parser.add_argument("--orientation", choices=["landscape", "portrait"], default="landscape")
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--internet", action="store_true", help="Enable Android INTERNET permission")
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    project_path = project_root / "project.godot"
    export_path = project_root / "export_presets.cfg"

    width = args.width or (1920 if args.orientation == "landscape" else 1080)
    height = args.height or (1080 if args.orientation == "landscape" else 1920)
    slug = slugify(args.name)
    package_id = f"com.shekinahwelefuldesigns.{slug.lower()}"

    project = project_path.read_text(encoding="utf-8")
    project = replace_setting(project, 'config/name', f'"{args.name}"')
    project = replace_setting(project, 'config/version', f'"{args.version}"')
    project = replace_setting(project, 'window/size/viewport_width', str(width))
    project = replace_setting(project, 'window/size/viewport_height', str(height))
    project = replace_setting(project, 'window/handheld/orientation', '1' if args.orientation == 'portrait' else '0')
    project_path.write_text(project, encoding="utf-8")

    preset = export_path.read_text(encoding="utf-8")
    preset = re.sub(r'(?m)^export_path="[^"]+\.(aab|apk)"$', lambda match: f'export_path="builds/{slug}.{args.version}.{match.group(1)}"', preset)
    preset = replace_setting(preset, 'version/code', str(args.version_code))
    preset = replace_setting(preset, 'version/name', '""')
    preset = replace_setting(preset, 'package/unique_name', f'"{package_id}"')
    preset = replace_setting(preset, 'package/name', f'"{args.name}"')
    preset = replace_setting(preset, 'permissions/internet', 'true' if args.internet else 'false')
    export_path.write_text(preset, encoding="utf-8")

    layout_path = project_root / "scripts/autoload/layout_service.gd"
    layout = layout_path.read_text(encoding="utf-8")
    layout = re.sub(r"const REFERENCE_SIZE := Vector2\([^\n]+\)",
                    f"const REFERENCE_SIZE := Vector2({width}.0, {height}.0)", layout)
    layout_path.write_text(layout, encoding="utf-8")
    manifest_path = project_root / "bootstrap_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["application_name"] = args.name
    manifest["package_id"] = package_id
    manifest["defaults"]["reference_resolution"] = [width, height]
    manifest["defaults"]["orientation"] = args.orientation
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print("Configured starter project:")
    print(f"  Name:         {args.name}")
    print(f"  Package:      {package_id}")
    print(f"  Version:      {args.version}")
    print(f"  Version code: {args.version_code}")
    print(f"  Orientation:  {args.orientation} ({width}x{height})")
    print(f"  Internet:     {'enabled' if args.internet else 'disabled'}")
    print("\nStill intentionally per-game: icons, release signing/keystore, store listing/pricing, privacy disclosures, and game-specific permissions. No AdMob, IAP, Analytics or Crashlytics.")


if __name__ == "__main__":
    main()
