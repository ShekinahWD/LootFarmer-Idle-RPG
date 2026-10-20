import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("play_store_listing", HERE.parent / "tools" / "play_store_listing.py")
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)


class PlayStoreListingTests(unittest.TestCase):
    def package(self, locales=None):
        return {
            "format": "game-google-play-localization-ai-import-v1",
            "source_locale": "en-US",
            "localizations": [
                {"locale": loc, "language": loc, "title": "Game", "short_description": "Short", "full_description": "Full"}
                for loc in (MOD.EXPECTED_LOCALES if locales is None else locales)
            ],
            "field_limits": {"title_max_characters": 30, "short_description_max_characters": 80, "full_description_max_characters": 4000},
        }

    def write(self, data):
        td = tempfile.TemporaryDirectory()
        path = Path(td.name) / "listing.json"
        path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        return td, path

    def test_complete_play_facing_package_passes(self):
        td, path = self.write(self.package())
        try:
            result = MOD.load_and_validate(path)
            self.assertEqual(len(result["localizations"]), 20)
        finally:
            td.cleanup()

    def test_example_map_matches_current_baseline(self):
        sample = HERE.parent / "examples" / "play_locale_map.example.json"
        self.assertEqual(MOD.load_locale_map(sample), MOD.PLAY_LOCALE_BY_RUNTIME)

    def test_known_runtime_play_mapping(self):
        self.assertEqual({runtime: MOD.PLAY_LOCALE_BY_RUNTIME[runtime] for runtime in ("uk-UA", "id-ID", "vi-VN", "th-TH")},
                         {"uk-UA": "uk", "id-ID": "id", "vi-VN": "vi", "th-TH": "th"})
        self.assertEqual(len(set(MOD.EXPECTED_LOCALES)), 20)
        for runtime in ("uk-UA", "id-ID", "vi-VN", "th-TH"):
            self.assertNotIn(runtime, MOD.EXPECTED_LOCALES)

    def test_legacy_runtime_tags_rejected_with_actionable_error(self):
        td, path = self.write(self.package(list(MOD.PLAY_LOCALE_BY_RUNTIME.keys())))
        try:
            with self.assertRaises(MOD.ValidationError) as ctx:
                MOD.load_and_validate(path)
            err = str(ctx.exception)
            for tag in ("uk", "id", "vi", "th", "uk-UA", "id-ID", "vi-VN", "th-TH"):
                self.assertIn(tag, err)
        finally:
            td.cleanup()

    def test_missing_play_locale_fails(self):
        data = self.package()
        data["localizations"] = [x for x in data["localizations"] if x["locale"] != "uk"]
        td, path = self.write(data)
        try:
            with self.assertRaises(MOD.ValidationError) as ctx:
                MOD.load_and_validate(path)
            self.assertIn("missing Play locales: uk", str(ctx.exception))
        finally:
            td.cleanup()

    def test_duplicate_play_locale_fails(self):
        data = self.package()
        data["localizations"][-1]["locale"] = "uk"
        td, path = self.write(data)
        try:
            with self.assertRaises(MOD.ValidationError) as ctx:
                MOD.load_and_validate(path)
            self.assertIn("duplicate locale uk", str(ctx.exception))
        finally:
            td.cleanup()

    def test_field_limit_fails(self):
        data = self.package()
        data["localizations"][0]["title"] = "X" * 31
        td, path = self.write(data)
        try:
            with self.assertRaises(MOD.ValidationError) as ctx:
                MOD.load_and_validate(path)
            self.assertIn("max 30", str(ctx.exception))
        finally:
            td.cleanup()

    def test_explicit_console_override_map_works(self):
        mapping = dict(MOD.PLAY_LOCALE_BY_RUNTIME)
        mapping["uk-UA"] = "uk-UA"  # future Console surface, if confirmed
        td, path = self.write(self.package(list(mapping.values())))
        try:
            self.assertEqual(len(MOD.load_and_validate(path, mapping)["localizations"]), 20)
            with self.assertRaises(MOD.ValidationError):
                MOD.load_and_validate(path)
        finally:
            td.cleanup()

    def test_incomplete_locale_map_rejected(self):
        mapping = dict(MOD.PLAY_LOCALE_BY_RUNTIME)
        mapping.pop("th-TH")
        with self.assertRaisesRegex(MOD.ValidationError, "missing runtime locales: th-TH"):
            MOD.validate_locale_map(mapping)

    def test_colliding_locale_map_rejected(self):
        mapping = dict(MOD.PLAY_LOCALE_BY_RUNTIME)
        mapping["uk-UA"] = "ru-RU"
        with self.assertRaisesRegex(MOD.ValidationError, "duplicate Play tags: ru-RU"):
            MOD.validate_locale_map(mapping)

    def test_source_override_rejected(self):
        mapping = dict(MOD.PLAY_LOCALE_BY_RUNTIME)
        mapping["en-US"] = "en"
        with self.assertRaisesRegex(MOD.ValidationError, 'English source must map to "en-US"'):
            MOD.validate_locale_map(mapping)

    def test_cli_explicit_json_mapping(self):
        mapping = dict(MOD.PLAY_LOCALE_BY_RUNTIME)
        mapping["uk-UA"] = "uk-UA"
        with tempfile.TemporaryDirectory() as td:
            td = Path(td)
            listing = td / "listing.json"
            custom_map = td / "console-tags.json"
            listing.write_text(json.dumps(self.package(list(mapping.values()))), encoding="utf-8")
            custom_map.write_text(json.dumps(mapping), encoding="utf-8")
            self.assertEqual(MOD.main(["validate", str(listing), "--locale-map", str(custom_map)]), 0)
            self.assertEqual(MOD.main(["validate", str(listing)]), 1)


if __name__ == "__main__":
    unittest.main()
