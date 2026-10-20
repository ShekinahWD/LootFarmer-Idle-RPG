#!/usr/bin/env python3
"""Validate a Google Play 20-language store-listing JSON handoff.

Game/runtime language IDs and Play Console locale tags are distinct. The
baseline mapping reflects the tags verified for the shared 20-language plan;
when Play Console requires a different spelling, supply an explicitly reviewed
complete mapping via --locale-map. Validation does NOT prove Console import.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

# Keys = the project's 20 logical languages (runtime/translation IDs).
# Values = corresponding tags for the Google Play listing import surface.
# Do not reuse these Play-facing tags for Godot runtime catalog registration.
PLAY_LOCALE_BY_RUNTIME = {
    "en-US": "en-US",
    "es-419": "es-419",
    "es-ES": "es-ES",
    "pt-BR": "pt-BR",
    "fr-FR": "fr-FR",
    "de-DE": "de-DE",
    "it-IT": "it-IT",
    "nl-NL": "nl-NL",
    "pl-PL": "pl-PL",
    "ru-RU": "ru-RU",
    "uk-UA": "uk",
    "tr-TR": "tr-TR",
    "id-ID": "id",
    "vi-VN": "vi",
    "th-TH": "th",
    "hi-IN": "hi-IN",
    "ja-JP": "ja-JP",
    "ko-KR": "ko-KR",
    "zh-CN": "zh-CN",
    "zh-TW": "zh-TW",
}
EXPECTED_LOCALES = list(PLAY_LOCALE_BY_RUNTIME.values())
LIMITS = {"title": 30, "short_description": 80, "full_description": 4000}
REQUIRED_FIELDS = ("locale", "language", "title", "short_description", "full_description")


class ValidationError(Exception):
    pass


def validate_locale_map(mapping: object) -> dict[str, str]:
    """Fail closed on incomplete/ambiguous runtime-to-Play mappings."""
    if not isinstance(mapping, dict):
        raise ValidationError("locale map must be a JSON object of runtime IDs to Play tags")
    required = set(PLAY_LOCALE_BY_RUNTIME)
    if set(mapping) != required:
        missing = sorted(required - set(mapping))
        extra = sorted(set(mapping) - required)
        issues = []
        if missing:
            issues.append("missing runtime locales: " + ", ".join(missing))
        if extra:
            issues.append("unexpected runtime locales: " + ", ".join(extra))
        raise ValidationError("locale map: " + "; ".join(issues))
    for runtime, play in mapping.items():
        if not isinstance(play, str) or not play.strip() or play != play.strip():
            raise ValidationError(f"locale map: {runtime} must map to a non-empty Play tag without surrounding whitespace")
    if mapping["en-US"] != "en-US":
        raise ValidationError('locale map: English source must map to "en-US"')
    play_tags = list(mapping.values())
    if len(set(play_tags)) != len(play_tags):
        duplicates = sorted({tag for tag in play_tags if play_tags.count(tag) > 1})
        raise ValidationError("locale map: duplicate Play tags: " + ", ".join(duplicates))
    return dict(mapping)


def load_locale_map(path: Path) -> dict[str, str]:
    try:
        mapping = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot read locale map as UTF-8 JSON: {exc}") from exc
    return validate_locale_map(mapping)


def load_and_validate(path: Path, locale_map: dict[str, str] | None = None) -> dict:
    mapping = validate_locale_map(PLAY_LOCALE_BY_RUNTIME if locale_map is None else locale_map)
    expected_locales = list(mapping.values())
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot read valid UTF-8 JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise ValidationError("top level must be a JSON object")
    if data.get("source_locale") != mapping["en-US"]:
        raise ValidationError(f'source_locale must be "{mapping["en-US"]}"')
    rows = data.get("localizations")
    if not isinstance(rows, list):
        raise ValidationError("localizations must be a list")
    seen: dict[str, int] = {}
    problems: list[str] = []
    for i, row in enumerate(rows, 1):
        if not isinstance(row, dict):
            problems.append(f"entry {i}: must be an object")
            continue
        for field in REQUIRED_FIELDS:
            value = row.get(field)
            if not isinstance(value, str) or not value.strip():
                problems.append(f"entry {i}: {field} must be a non-empty string")
        locale = row.get("locale")
        if isinstance(locale, str):
            if locale in seen:
                problems.append(f"duplicate locale {locale} (entries {seen[locale]} and {i})")
            else:
                seen[locale] = i
        for field, limit in LIMITS.items():
            value = row.get(field)
            if isinstance(value, str) and len(value) > limit:
                problems.append(f"{locale or 'entry '+str(i)}: {field} is {len(value)} chars; max {limit}")
    missing = [x for x in expected_locales if x not in seen]
    extra = [x for x in seen if x not in expected_locales]
    if missing:
        problems.append("missing Play locales: " + ", ".join(missing))
    if extra:
        problems.append("unexpected Play locales: " + ", ".join(extra))
    if len(rows) != len(expected_locales):
        problems.append(f"localizations has {len(rows)} entries; expected {len(expected_locales)}")
    if problems:
        raise ValidationError("\n".join(problems))
    return data


def cmd_validate(path: Path, locale_map_path: Path | None = None) -> int:
    try:
        mapping = load_locale_map(locale_map_path) if locale_map_path else None
        data = load_and_validate(path, mapping)
    except ValidationError as exc:
        print("INVALID Google Play localization package:", file=sys.stderr)
        print(exc, file=sys.stderr)
        return 1
    print(f"VALID: {len(data['localizations'])}/20 Play-facing locales")
    print("Source: en-US; expected translated locales in Play Console: 19")
    print("Field limits: title <= 30, short_description <= 80, full_description <= 4000")
    print("After import, verify actual language detection in Play Console; this is not API validation.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("validate", help="validate a 20-language Google Play listing JSON package")
    p.add_argument("file", type=Path)
    p.add_argument("--locale-map", type=Path, help="reviewed complete JSON map of 20 runtime IDs to Play-facing tags")
    args = parser.parse_args(argv)
    if args.command == "validate":
        return cmd_validate(args.file, args.locale_map)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
