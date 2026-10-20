"""Offline smoke tests. Synthetic visuals only; NEVER use these as store art.

Run from the toolkit root: python -m unittest discover -s tests -v
Needs ffmpeg/ffprobe on PATH and Pillow. Fonts: Pillow's bundled font
("builtin:pillow", ASCII only) and the toolkit's bundled Noto faces, so the
tests run on any OS without system fonts. GodotTextTests (shaping, line
breaking, fallbacks) run when MARKETING_GODOT names a Godot 4 console exe.
"""
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from io import BytesIO
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / "tools" / "marketing.py"
SPEC = importlib.util.spec_from_file_location("marketing", MODULE)
marketing = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(marketing)

FF = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]


def make_clip(path: Path, colour: str, seconds: float, *, second_colour: str | None = None, tone: int | None = None):
    """A 320x180 30 fps MJPEG AVI (as Movie Maker writes), optionally switching
    colour halfway and carrying a sine tone."""
    if second_colour:
        src = (f"color=c={colour}:s=320x180:r=30:d={seconds / 2}[a];color=c={second_colour}:s=320x180:r=30:d={seconds / 2}[b];"
               "[a][b]concat=n=2:v=1:a=0[v]")
        cmd = FF + ["-f", "lavfi", "-i", "nullsrc", "-filter_complex", src, "-map", "[v]"]
    else:
        cmd = FF + ["-f", "lavfi", "-i", f"color=c={colour}:s=320x180:r=30:d={seconds}"]
    if tone:
        cmd += ["-f", "lavfi", "-i", f"sine=frequency={tone}:sample_rate=48000:duration={seconds}", "-map",
                "[v]" if second_colour else "0:v", "-map", "1:a", "-c:a", "pcm_s16le"]
    cmd += ["-c:v", "mjpeg", "-q:v", "3", "-t", str(seconds), str(path)]
    subprocess.run(cmd, check=True)


def frame_at(path: Path, frame: int):
    from PIL import Image
    raw = subprocess.run(FF + ["-i", str(path), "-vf", f"select=eq(n\\,{frame})", "-frames:v", "1",
                               "-f", "image2pipe", "-vcodec", "png", "-"], capture_output=True, check=True).stdout
    return Image.open(BytesIO(raw)).convert("RGB")


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "ffmpeg/ffprobe required")
class MarketingSmokeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="godot_marketing_test_")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        from PIL import Image
        Image.new("RGB", (320, 180), (42, 65, 85)).save(self.root / "raw.png")
        make_clip(self.root / "one.avi", "0x50A050", 6.0, tone=440)
        make_clip(self.root / "two.avi", "0xA05050", 6.0, second_colour="0x5050C0")
        self.m = {
            "fonts": {"en-US": "builtin:pillow", "es-419": "builtin:pillow"},
            "strings": {"en-US": {"A": "Defend!", "B": "Build your world", "S": "SUB"},
                        # Pillow's bundled font is ASCII only (test_missing_glyph_fails_closed).
                        "es-419": {"A": "Defiende!", "B": "Construye tu mundo", "S": "SUB"}},
            "screenshots": [
                {"id": "battle", "raw": "raw.png", "output": "output/name.png", "headline_key": "A"},
                {"id": "clean", "raw": "raw.png", "output": "output/name.png", "headline": False},
            ],
            # Frames at 30 fps: battle 117 (its headline readable 92 >= 90), the
            # card "auto" 9 + 8 + 90 + 8 + 9 = 124 from frame 108, "second" fills
            # the rest of the 9.0 s: 270 + 18 - 117 - 124 = 47 from frame 223.
            "video": {"profile": "custom", "width": 320, "height": 180, "fps": 30,
                      "target_duration": 9.0, "output": "output/marketing.mp4",
                      "shots": [
                          {"id": "battle", "kind": "clip", "source": "one.avi", "duration": 3.9, "headline_key": "A"},
                          {"id": "title", "kind": "card", "duration": "auto", "headline_key": "B", "subtitle_key": "S",
                           "transition_in": {"type": "fade", "duration": 0.3}},
                          {"id": "second", "kind": "clip", "source": "two.avi", "start": 2.0, "duration": "fill",
                           "transition_in": {"type": "fade", "duration": 0.3}},
                      ]}}
        self.manifest = self.root / "manifest.json"
        self.save()

    def save(self):
        self.manifest.write_text(json.dumps(self.m, ensure_ascii=False), encoding="utf-8")

    def call(self, *args, ok=True):
        result = subprocess.run([sys.executable, str(MODULE), *args], text=True, capture_output=True)
        if ok and result.returncode:
            self.fail(f"Command error: {result.stdout}\n{result.stderr}")
        if not ok:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def test_images_headlines_and_raw_preservation(self):
        sha_before = hashlib.sha256((self.root / "raw.png").read_bytes()).digest()
        self.call("screenshots", "--manifest", str(self.manifest), "--locales", "en-US", "es-419")
        self.assertEqual(sha_before, hashlib.sha256((self.root / "raw.png").read_bytes()).digest())
        self.assertEqual((self.root / "raw.png").read_bytes(), (self.root / "output/clean_en-US.png").read_bytes())
        self.assertNotEqual((self.root / "raw.png").read_bytes(), (self.root / "output/battle_en-US.png").read_bytes())

    def test_screenshots_are_language_neutral_by_default(self):
        # No headline asked for: the master is copied as is, and no copy is
        # needed for any locale (es-419 and en-US have no "neutral" string).
        self.m["screenshots"] = [{"id": "neutral", "raw": "raw.png", "output": "output/name.png"}]
        self.m["strings"] = {"en-US": {}, "es-419": {}}
        self.save()
        result = self.call("screenshots", "--manifest", str(self.manifest), "--locales", "en-US", "es-419")
        self.assertEqual(result.stdout.count("(copy)"), 2, result.stdout)  # never sent through the text renderer
        for locale in ("en-US", "es-419"):
            self.assertEqual((self.root / "raw.png").read_bytes(), (self.root / f"output/neutral_{locale}.png").read_bytes())

    def test_fades_go_through_black_and_card_text_waits_for_black(self):
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        p = self.root / "output/marketing_en-US.mp4"
        marketing.verify_video_file(p, 320, 180, 30, 9.0, False)
        report = json.loads((self.root / "output/marketing_en-US_review.json").read_text())
        self.assertEqual(report["frames"], 270)
        self.assertEqual(report["transitions_ok"], 2, report["transitions"])
        for t in report["transitions"]:
            self.assertLessEqual(t["black_level"], marketing.BLACK_MAX)
            self.assertGreaterEqual(t["intermediate"], 3)
        self.assertEqual([c for c in report["abrupt_changes"] if c["dark"]], [])
        self.assertTrue((self.root / "output/marketing_en-US_review.png").is_file())
        # Card starts at frame 108 (117 - 9); its fade from gameplay ends on frame 117,
        # which must be pure black (the text is held back), the middle shows text.
        self.assertLessEqual(max(frame_at(p, 117).convert("L").tobytes()), marketing.BLACK_MAX)
        self.assertGreater(max(frame_at(p, 170).convert("L").tobytes()), 200)
        mid_fade = frame_at(p, 112).getpixel((10, 10))
        self.assertTrue(10 < mid_fade[1] < 150, mid_fade)  # part-way between the green clip and black

    def test_card_text_is_readable_for_three_seconds_by_default(self):
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        report = json.loads((self.root / "output/marketing_en-US_review.json").read_text())
        clip, card = report["text_holds"]
        self.assertEqual(report["text_holds_ok"], 2, report["text_holds"])
        self.assertEqual((card["shot"], card["required_s"], card["planned_s"]), ("title", 3.0, 3.0))
        # Measured in the encoded frames: full text brightness for 3 s (fades excluded).
        self.assertGreaterEqual(card["measured_s"], 3.0)
        self.assertLess(card["measured_s"], 3.2)
        self.assertEqual((clip["shot"], clip["required_s"]), ("battle", 3.0))
        self.assertGreaterEqual(clip["planned_s"], 3.0)

    def test_longer_and_localized_text_get_longer_cards_at_the_same_total(self):
        # About 4.3 s of reading at 15 characters/s: the 9.0 s video has no room for it.
        self.m["strings"]["es-419"]["B"] = "Construye tu mundo, defiendelo y miralo crecer cada temporada"
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", "es-419", ok=False)
        self.assertIn("es-419: video video: target_duration leaves", out.stderr)
        self.assertIn("drop a title card", out.stderr)
        self.assertFalse((self.root / "output/marketing_en-US.mp4").exists())  # fails before any output
        self.m["video"]["target_duration"] = 11.0
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", "es-419")
        cards = {}
        for loc in ("en-US", "es-419"):
            marketing.verify_video_file(self.root / f"output/marketing_{loc}.mp4", 320, 180, 30, 11.0, False)
            report = json.loads((self.root / f"output/marketing_{loc}_review.json").read_text())
            self.assertEqual(report["frames"], 330)
            cards[loc] = report["text_holds"][1]
        self.assertEqual(cards["en-US"]["required_s"], 3.0)
        long_text = self.m["strings"]["es-419"]["B"] + "SUB"
        self.assertAlmostEqual(cards["es-419"]["required_s"], len(long_text) / 15, delta=0.04)
        self.assertGreaterEqual(cards["es-419"]["measured_s"], cards["es-419"]["required_s"])

    def test_in_point_starts_the_clip_later(self):
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        last = frame_at(self.root / "output/marketing_en-US.mp4", 269).getpixel((10, 10))
        self.assertGreater(last[2], last[0], last)  # the clip's second (blue) half, not its red start

    def test_crossfade_and_dip_between_clips(self):
        self.m["video"]["shots"] = [
            {"id": "a", "kind": "clip", "source": "one.avi", "duration": 1.0},
            {"id": "b", "kind": "clip", "source": "two.avi", "duration": 1.0, "transition_in": {"type": "fade", "duration": 0.4}},
            {"id": "c", "kind": "clip", "source": "one.avi", "duration": 1.0, "transition_in": {"type": "crossfade", "duration": 0.4}},
        ]
        self.m["video"]["target_duration"] = 2.2
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        report = json.loads((self.root / "output/marketing_en-US_review.json").read_text())
        dip, cross = report["transitions"]
        self.assertTrue(dip["ok"] and cross["ok"], report["transitions"])
        self.assertLessEqual(dip["black_level"], marketing.BLACK_MAX)  # 'fade' dips to black between clips
        self.assertNotIn("black_level", cross)  # 'crossfade' blends directly

    def test_cut_before_a_fade(self):
        # concat (a cut) feeding a later xfade (a fade): FFmpeg 8 refused the
        # mismatched timebases until concat's output was set back to 1/fps.
        self.m["video"]["shots"] = [
            {"id": "a", "kind": "clip", "source": "one.avi", "duration": 1.0},
            {"id": "b", "kind": "clip", "source": "two.avi", "duration": 1.0, "transition_in": {"type": "cut"}},
            {"id": "c", "kind": "clip", "source": "one.avi", "duration": 1.0, "transition_in": {"type": "fade", "duration": 0.4}},
        ]
        self.m["video"]["target_duration"] = 2.6
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        marketing.verify_video_file(self.root / "output/marketing_en-US.mp4", 320, 180, 30, 2.6, False)
        report = json.loads((self.root / "output/marketing_en-US_review.json").read_text())
        self.assertTrue(all(t["ok"] for t in report["transitions"]), report["transitions"])

    def test_game_audio_and_music_mix(self):
        subprocess.run(FF + ["-f", "lavfi", "-i", "sine=frequency=220:sample_rate=44100:duration=1.0", str(self.root / "music.wav")], check=True)
        self.m["video"].update({"game_audio": True, "music": "music.wav", "music_volume": 0.5, "fade_out": 0.3})
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        p = self.root / "output/marketing_en-US.mp4"
        marketing.verify_video_file(p, 320, 180, 30, 9.0, True)
        audio = json.loads((self.root / "output/marketing_en-US_review.json").read_text())["audio"]
        self.assertLess(audio["max_volume"], -0.5)  # limited, never clipping
        self.assertGreater(audio["quietest_window_db"], -40)  # the looped music never drops out

    def test_analyze_flags_hard_cut_to_black_card(self):
        # The old failure mode: gameplay, then a black card with its text on in one frame.
        clip = self.root / "cut.mp4"
        subprocess.run(FF + ["-f", "lavfi", "-i", "color=c=0x80C080:s=320x180:r=30:d=1", "-f", "lavfi", "-i",
                             "color=c=black:s=320x180:r=30:d=1", "-filter_complex",
                             "[1:v]drawbox=x=100:y=80:w=120:h=20:color=white:t=fill[c];[0:v][c]concat=n=2:v=1:a=0[v]",
                             "-map", "[v]", "-pix_fmt", "yuv420p", str(clip)], check=True)
        out = self.call("analyze", "--file", str(clip), "--strict", ok=False)
        self.assertIn("Hard cuts", out.stderr)

    def test_missing_translation_fails_no_output(self):
        del self.m["strings"]["es-419"]["A"]
        self.save()
        self.call("screenshots", "--manifest", str(self.manifest), "--locales", "en-US", "es-419", ok=False)
        self.assertFalse((self.root / "output/battle_en-US.png").exists())

    def test_invalid_transition_duration_fails(self):
        self.m["video"]["shots"][2].update(duration=1.0, transition_in={"type": "fade", "duration": 1.2})
        del self.m["video"]["target_duration"]
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("Transition exceeds the duration of shot second", out.stderr)

    def test_card_too_short_for_readable_text_fails(self):
        # The 0.3.0 timing (a 2 s card): its text was fully visible for under a second.
        self.m["video"]["shots"][1]["duration"] = 2.0
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("card title: its text would be readable for 0.87s, it needs 3.00s", out.stderr)
        self.assertIn('make its duration "auto"', out.stderr)
        # A headline over gameplay needs its reading time too.
        self.m["video"]["shots"][1]["duration"] = "auto"
        self.m["video"]["shots"][0]["duration"] = 2.5
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("clip battle: its text would be readable for", out.stderr)
        # A shorter hold is a deliberate, per-shot (or style) setting.
        self.m["video"]["shots"][0]["text_min_hold"] = 1.5
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")

    def test_timing_mismatch_fails(self):
        self.m["video"]["shots"][2]["duration"] = 1.5  # no "fill" clip: 268 frames, not 270
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("timing mismatch", out.stderr)


    def test_missing_glyph_fails_closed(self):
        # Pillow's bundled font has no '¡': never a tofu box in store art.
        self.m["strings"]["es-419"]["A"] = "¡Defiende!"
        self.save()
        out = self.call("screenshots", "--manifest", str(self.manifest), "--locales", "en-US", "es-419", ok=False)
        self.assertIn("no glyph for U+00A1", out.stderr)
        self.assertFalse((self.root / "output/battle_en-US.png").exists())

    def test_quality_presets(self):
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        final = self.root / "output/marketing_en-US.mp4"
        report = json.loads((self.root / "output/marketing_en-US_review.json").read_text())
        self.assertEqual(report["quality"], {"name": "high", "crf": 18, "x264_preset": "slow"})
        self.assertIn(b"crf=18.0", final.read_bytes())  # x264's own record of its settings
        for name, crf in (("preview", 26), ("standard", 21)):
            self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", "--quality", name)
            # A preview or standard encode never replaces the final.
            out = self.root / f"output/marketing_en-US_{name}.mp4"
            self.assertIn(f"crf={crf}.0".encode(), out.read_bytes())
            marketing.verify_video_file(out, 320, 180, 30, 9.0, False)
        self.assertIn(b"crf=18.0", final.read_bytes())
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", "--quality", "ultra", ok=False)
        # The manifest may pick the default and adjust a preset.
        self.m.update({"quality": "standard", "quality_presets": {"standard": {"crf": 23}}})
        self.save()
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", "--overwrite")
        self.assertIn(b"crf=23.0", (self.root / "output/marketing_en-US_standard.mp4").read_bytes())

    def _social(self, shots: list[dict], seconds: float):
        """A 180x320 vertical video (a small stand-in for 1080x1920) from the
        320x180 landscape clips, with the social text margins."""
        self.m["video"] = {"profile": "custom", "width": 180, "height": 320, "fps": 30, "target_duration": seconds,
                           "output": "output/social.mp4", "style": {"safe_area": marketing.SOCIAL_SAFE_AREA},
                           "shots": shots}
        self.save()

    def test_landscape_footage_in_a_vertical_video_needs_an_explicit_reframe(self):
        self._social([{"id": "a", "kind": "clip", "source": "one.avi", "duration": 1.0}], 1.0)
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn('"reframe"', out.stderr)
        self.m["video"]["shots"][0]["reframe"] = {"x": 0.5, "zoom": 2}
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("reframe: an object with x, y, width, fill", out.stderr)
        self.assertFalse((self.root / "output/social_en-US.mp4").exists())

    def test_reframe_crops_on_the_action_and_fills_a_wider_window(self):
        # Left half red, right half blue: the window's centre picks the side.
        halves = self.root / "halves.avi"
        subprocess.run(FF + ["-f", "lavfi", "-i", "color=c=0xC03030:s=320x180:r=30:d=2", "-vf",
                             "drawbox=x=160:y=0:w=160:h=180:color=0x3030C0:t=fill",
                             "-c:v", "mjpeg", "-q:v", "3", str(halves)], check=True)
        self.assertEqual(marketing.reframe_window({}, (320, 180), (180, 320)), (102, 180, 109, 0))  # full height
        self.assertEqual(marketing.reframe_window({"x": 1.0}, (320, 180), (180, 320))[2], 218)  # kept inside
        self._social([
            {"id": "left", "kind": "clip", "source": "halves.avi", "duration": 1.0, "reframe": {"x": 0.2}},
            {"id": "right", "kind": "clip", "source": "halves.avi", "duration": 1.0, "reframe": {"x": 0.8},
             "headline_key": "A", "position": "top", "text_min_hold": 0.5},
            {"id": "wide", "kind": "clip", "source": "halves.avi", "duration": 1.0, "reframe": {"width": 1.0}},
            {"id": "boxed", "kind": "clip", "source": "halves.avi", "duration": 1.0,
             "reframe": {"width": 1.0, "fill": "black"}},
        ], 4.0)
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        p = self.root / "output/social_en-US.mp4"
        marketing.verify_video_file(p, 180, 320, 30, 4.0, False)
        left, right = frame_at(p, 15), frame_at(p, 45)
        for frame, (red, blue) in ((left, (True, False)), (right, (False, True))):
            r, g, b = frame.getpixel((90, 250))  # full-height crop: one colour, top to bottom
            self.assertEqual((r > b + 60, b > r + 60), (red, blue), (r, g, b))
        # The headline sits inside the top margin's edge, never in the platform's top bar.
        top = round(marketing.SOCIAL_SAFE_AREA["top"] * 320)
        self.assertGreater(max(right.crop((0, top, 180, 110)).convert("L").tobytes()), 200)
        self.assertLess(max(right.crop((60, 0, 120, top - 12)).convert("L").tobytes()), 90)
        # The whole 16:9 frame (scaled to 180x102), centred: blue right / red left,
        # blurred footage (not black) above and below; or black when asked.
        wide, boxed = frame_at(p, 75), frame_at(p, 105)
        self.assertGreater(wide.getpixel((20, 160))[0], wide.getpixel((20, 160))[2] + 60)
        self.assertGreater(wide.getpixel((160, 160))[2], wide.getpixel((160, 160))[0] + 60)
        self.assertGreater(max(wide.getpixel((90, 30))), 40)
        self.assertLess(max(boxed.getpixel((90, 30))), 25)

    def test_full_landscape_in_black_bands_keeps_text_off_the_gameplay(self):
        # The whole 320x180 frame in a 180x320 video: footage in rows 109-211,
        # black above and below; the headlines go in those bands, never on it.
        halves = self.root / "halves.avi"
        subprocess.run(FF + ["-f", "lavfi", "-i", "color=c=0xC03030:s=320x180:r=30:d=2", "-vf",
                             "drawbox=x=160:y=0:w=160:h=180:color=0x3030C0:t=fill",
                             "-c:v", "mjpeg", "-q:v", "3", str(halves)], check=True)
        full = {"width": 1.0, "fill": "black"}
        self.assertEqual(marketing.reframe_picture(full, (320, 180), (180, 320)), (109, 102))
        self.assertEqual(marketing.reframe_picture({}, (320, 180), (180, 320)), (0, 320))
        self._social([
            {"id": "hook", "kind": "clip", "source": "halves.avi", "duration": 1.0, "reframe": full,
             "headline_key": "A", "position": "top", "text_min_hold": 0.5},
            {"id": "feature", "kind": "clip", "source": "halves.avi", "duration": 1.0, "reframe": full,
             "headline_key": "A", "position": "bottom", "text_min_hold": 0.5, "transition_in": {"type": "cut"}},
        ], 2.0)
        self.call("video", "--manifest", str(self.manifest), "--locales", "en-US")
        p = self.root / "output/social_en-US.mp4"
        marketing.verify_video_file(p, 180, 320, 30, 2.0, False)
        safe_top, safe_bottom = round(0.08 * 320), 320 - round(0.22 * 320)
        for n, (lo, hi) in ((15, (safe_top, 109)), (45, (211, safe_bottom))):
            grey = frame_at(p, n).convert("L")
            self.assertGreater(max(grey.crop((0, lo, 180, hi)).tobytes()), 200)  # the text, in its band
            outside = (0, 0, 180, lo) if n == 15 else (0, hi, 180, 320)
            self.assertLess(max(grey.crop(outside).tobytes()), 25)  # black beyond it (no translucent strip)
            # The footage is untouched: pure red / blue, no text or band on it.
            frame = frame_at(p, n)
            for x, (r, g, b) in ((20, frame.getpixel((20, 160))), (160, frame.getpixel((160, 160)))):
                self.assertLess(g, 90, (n, x, r, g, b))
        # Copy that cannot fit the band below, or a centred headline, is refused before any output.
        self.m["strings"]["en-US"]["A"] = "A headline far too long for the narrow band below the footage"
        self.m["video"]["shots"][0].update(position="bottom", reading_cps=200)
        self.m["video"]["shots"][1]["reading_cps"] = 200
        self.save()
        p.unlink()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("does not fit the black band below the picture", out.stderr)
        self.m["video"]["shots"][0]["position"] = "center"
        self.save()
        out = self.call("video", "--manifest", str(self.manifest), "--locales", "en-US", ok=False)
        self.assertIn("never over the picture", out.stderr)
        self.assertFalse(p.exists())

    def test_vertical_social_profiles_keep_text_out_of_the_platform_ui(self):
        style = marketing.style_of({}, {"profile": "tiktok"})
        self.assertEqual(style["safe_area"], marketing.SOCIAL_SAFE_AREA)
        self.assertEqual(marketing.style_of({}, {"profile": "play_store"})["safe_area"]["bottom"], 0.0)
        self.assertEqual(marketing.style_of({"style": {"safe_area": {"top": 0.1}}}, {"profile": "reels"})["safe_area"],
                         {"top": 0.1})  # the manifest's own margins win
        self.assertEqual(marketing.PROFILES["reels"], (1080, 1920, 30))
        engine = marketing.TextEngine(json.loads(self.manifest.read_text()), self.manifest, None, self.root)
        img = marketing.text_image((360, 640), "Defend!", "bottom", "en-US", engine, style)
        box = img.getbbox()  # band and text
        self.assertLessEqual(box[3], 640 - round(0.22 * 640))
        wide = dict(style, card_safe_width=0.98)
        card = marketing.card_image((360, 640), "DEFENDYOURCASTLENOWANDFOREVERMORE", "SUB", None, "en-US", engine, wide).getbbox()
        self.assertGreaterEqual(card[0], round(0.12 * 360))
        self.assertLessEqual(card[2], 360 - round(0.12 * 360))
        # Without the margins the same card uses the width the side buttons cover.
        bare = marketing.card_image((360, 640), "DEFENDYOURCASTLENOWANDFOREVERMORE", "SUB", None, "en-US", engine,
                                    dict(wide, safe_area={})).getbbox()
        self.assertLess(bare[0], min(card[0] - 20, round(0.12 * 360)))
        with self.assertRaises(marketing.MarketingError):
            marketing.safe_area_px({"safe_area": {"top": 0.5}}, (360, 640))

    def test_shaped_script_needs_a_shaping_renderer(self):
        self.m["fonts"]["th-TH"] = "toolkit:NotoSansThai[wdth,wght].ttf"
        self.m["strings"]["th-TH"] = {"A": "ทดสอบ", "B": "ทดสอบ", "S": "ทดสอบ"}  # "test"
        self.save()
        env = {k: v for k, v in os.environ.items() if k != "MARKETING_GODOT"}
        r = subprocess.run([sys.executable, str(MODULE), "screenshots", "--manifest", str(self.manifest),
                            "--locales", "th-TH"], text=True, capture_output=True, env=env)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("needs Godot's text server (Thai", r.stderr)
        if not marketing._has_raqm():
            self.m["text_renderer"] = "pillow"
            self.save()
            r = subprocess.run([sys.executable, str(MODULE), "screenshots", "--manifest", str(self.manifest),
                                "--locales", "th-TH"], text=True, capture_output=True, env=env)
            self.assertIn("would render unshaped", r.stderr)
        self.assertFalse((self.root / "output/battle_th-TH.png").exists())


class ExampleManifestTests(unittest.TestCase):
    def test_example_videos_plan_with_their_capture_jobs(self):
        # Every example video (the trailer and the vertical social cut derived
        # from the same landscape footage) plans for every locale it has copy
        # for, its reframes fit the capture jobs' size and its clips their footage.
        path = MODULE.parents[1] / "examples" / "marketing_manifest.example.json"
        conf = json.loads(path.read_text(encoding="utf-8"))
        jobs = {(path.parent / j["output"]).resolve(): j for j in conf["capture_jobs"]}
        for video in marketing.videos_of(conf):
            width, height, fps = marketing._profile(video)
            style = marketing.style_of(conf, video)
            footage = {}
            for i, shot in enumerate(video["shots"]):
                if shot["kind"] != "clip":
                    continue
                job = jobs[(path.parent / shot["source"]).resolve()]
                footage[i] = job["duration"] - shot.get("start", 0)
                if (job["width"], job["height"]) != (width, height):
                    self.assertIn("reframe", shot, f"{video['id']}: {shot['id']} needs a reframe")
                    marketing.reframe_window(shot["reframe"], (job["width"], job["height"]), (width, height))
            for locale in conf["strings"]:
                texts = [marketing.shot_texts(conf, s, locale) for s in video["shots"]]
                plan = marketing.plan_video(video, fps, style, texts, footage, locale)
                self.assertEqual(plan["total"], round(video["target_duration"] * fps))
        self.assertEqual(marketing.style_of(conf, {"profile": "tiktok"})["safe_area"], marketing.SOCIAL_SAFE_AREA)


class FontTests(unittest.TestCase):
    def test_bundled_fonts_match_their_record(self):
        faces = marketing.verify_toolkit_fonts()
        self.assertEqual({f["locale"] for f in faces}, {"default", "th-TH", "hi-IN", "ja-JP", "ko-KR", "zh-CN", "zh-TW"})
        self.assertIn("toolkit:NotoSans[wdth,wght].ttf", {f["file"] for f in faces})
        self.assertEqual({f["license"] for f in faces}, {"SIL OFL 1.1"})

    def test_script_samples_cover_every_locale(self):
        samples = json.loads(marketing.SCRIPT_SAMPLES.read_text(encoding="utf-8"))["samples"]
        self.assertEqual(set(samples), set(marketing.SUPPORTED_LOCALES))

    def test_font_chain_resolution(self):
        base = Path(tempfile.gettempdir())
        conf = {"fonts": {"default": "toolkit:NotoSansJP[wght].ttf",
                          "th-TH": ["toolkit:NotoSansThai[wdth,wght].ttf",
                                    {"file": "toolkit:NotoSansJP[wght].ttf", "weight": 700}]}}
        chain = marketing.font_chain(conf, "th-TH", base)
        self.assertEqual([f["path"].name for f in chain], ["NotoSansThai[wdth,wght].ttf", "NotoSansJP[wght].ttf"])
        self.assertEqual(chain[1]["weight"], 700)
        self.assertEqual(marketing.font_chain(conf, "de-DE", base)[0]["path"].name, "NotoSansJP[wght].ttf")
        for bad in ({"de-DE": {"file": "toolkit:NotoSansJP[wght].ttf", "bold": True}},
                    {"de-DE": "toolkit:missing.ttf"}, {"de-DE": []}):
            with self.assertRaises(marketing.MarketingError):
                marketing.font_chain({"fonts": bad}, "de-DE", base)
        self.assertEqual(marketing.needs_godot(chain, "abc"), "a font fallback chain")
        self.assertIn("Thai", marketing.needs_godot(chain[:1], "ทดสอบ"))
        self.assertIn("Devanagari", marketing.needs_godot(chain[:1], "हिन्दी"))
        self.assertIn("Han", marketing.needs_godot(chain[:1], "天地"))
        # Precomposed Latin, Cyrillic and Vietnamese need no shaping.
        self.assertEqual(marketing.needs_godot(chain[:1], "Zażółć gęślą jaźń Съешь ặ"), "")

    def test_toolkit_noto_faces_are_the_default(self):
        base = Path(tempfile.gettempdir())
        names = lambda conf, loc: [(f["path"].name, f["weight"]) for f in marketing.font_chain(conf, loc, base)]
        for loc in ("en-US", "pl-PL", "tr-TR", "uk-UA", "ru-RU", "vi-VN", "nl-NL"):
            self.assertEqual(names({}, loc), [("NotoSans[wdth,wght].ttf", 700)])
        self.assertEqual(names({}, "th-TH"), [("NotoSansThai[wdth,wght].ttf", 700), ("NotoSans[wdth,wght].ttf", 700)])
        self.assertEqual(names({}, "hi-IN"), [("NotoSansDevanagari[wdth,wght].ttf", 700), ("NotoSans[wdth,wght].ttf", 700)])
        self.assertEqual(names({}, "zh-TW"), [("NotoSansTC[wght].ttf", 700)])
        # A manifest's own mapping (the locale, else its "default") always wins.
        conf = {"fonts": {"default": {"file": "toolkit:NotoSans[wdth,wght].ttf", "weight": 600}}}
        self.assertEqual(names(conf, "de-DE"), [("NotoSans[wdth,wght].ttf", 600)])
        self.assertEqual(names(conf, "ja-JP"), [("NotoSans[wdth,wght].ttf", 600)])

    def test_default_fonts_cover_every_locale(self):
        # Every character of every locale's test strings is in some face of
        # the toolkit's default chain for that locale (no tofu box anywhere).
        samples = json.loads(marketing.SCRIPT_SAMPLES.read_text(encoding="utf-8"))["samples"]
        with tempfile.TemporaryDirectory() as td:
            engine = marketing.TextEngine({"text_renderer": "pillow"}, Path(td) / "m.json", None, Path(td))
            for loc in marketing.SUPPORTED_LOCALES:
                text = "".join(samples[loc].values())
                missing = None
                for face in marketing.font_chain({}, loc, Path(td)):
                    single = [face]
                    lacking = set(engine._pillow_missing(single, engine._pillow_font(single, 40), text))
                    missing = lacking if missing is None else missing & lacking
                self.assertEqual(missing, set(), loc)

    def test_wrapping_is_preferred_to_shrinking(self):
        # A portrait headline (1080 wide: start 70 px, 950 px of line) wraps at
        # full size into balanced lines instead of shrinking to one line.
        text = "Test headline: build a whole village of tiny roads and trees"
        with tempfile.TemporaryDirectory() as td:
            engine = marketing.TextEngine({"text_renderer": "pillow"}, Path(td) / "m.json", None, Path(td))
            block = engine.block(text, "en-US", 70, 950, 518, 35)
            self.assertEqual((block.info["font_size"], block.info["wrap"]), (70, "words"))
            font = engine._pillow_font(engine.chain("en-US"), 70)
            draw = marketing._pil()[1].Draw(marketing._pil()[0].new("L", (1, 1)))
            width = lambda line: draw.textbbox((0, 0), line, font=font)[2]
            greedy = marketing._wrap_text(draw, text, font, 950)
            lines = [line["text"] for line in block.info["lines"]]
            self.assertEqual(len(lines), len(greedy))
            self.assertLess(min(map(width, greedy)) / max(map(width, greedy)), 0.6)  # an orphaned last line
            self.assertGreater(min(map(width, lines)) / max(map(width, lines)), 0.8)  # balanced
            # The author's lines may shrink a little (85%) before a re-wrap...
            authored = engine.block("Grow your village\nevery season", "en-US", 70, 560, 518, 35)
            self.assertEqual(authored.info["wrap"], "authored")
            self.assertGreaterEqual(authored.info["font_size"], 60)
            # ...and nothing is set below the floor: too long copy is refused.
            with self.assertRaises(marketing.MarketingError) as err:
                engine.block(text * 6, "en-US", 70, 950, 200, 35)
            self.assertIn("shorten the copy", str(err.exception))

    def test_reading_time(self):
        style = dict(marketing.DEFAULT_STYLE)
        self.assertEqual(marketing.reading_seconds(["Defend!"], style), 3.0)
        self.assertEqual(marketing.reading_seconds(["x" * 90], style), 6.0)
        # A Han or Kana character reads as two letters, a Hangul syllable as 1.5;
        # whitespace runs count once, Thai marks belong to their cluster.
        self.assertEqual(marketing.reading_units("天地玄黄"), 8)
        self.assertEqual(marketing.reading_units("나는 유리"), 7)
        self.assertEqual(marketing.reading_units("a  \n b"), 3)
        self.assertEqual(marketing.reading_units("เป็น"), 3)  # เ | ป็ | น
        self.assertEqual(marketing.reading_units("ปี่"), 1)
        self.assertEqual(marketing.reading_seconds(["天" * 30], style), 4.0)
        self.assertEqual(marketing.reading_seconds(["Defend!"], dict(style, text_min_hold=2.0)), 2.0)

    def test_fill_clips_share_the_time_and_keep_headlines_readable(self):
        style = dict(marketing.DEFAULT_STYLE)
        video = {"id": "p", "target_duration": 11.0, "fade_in": 0.3, "fade_out": 0.5, "shots": [
            {"id": "top", "kind": "clip", "duration": "fill"},
            {"id": "card", "kind": "card", "duration": "auto", "transition_in": {"type": "fade", "duration": 0.4}},
            {"id": "plaza", "kind": "clip", "duration": "fill", "transition_in": {"type": "fade", "duration": 0.4}}]}
        texts = [[], ["TOOLKIT TEST CARD", "Art: Pixel Plains by SnowHex"], ["TEST CAPTION: ASSETS, NOT GAMEPLAY"]]
        plan = marketing.plan_video(video, 30, style, texts)
        # The card: 12 + 8 + 90 + 8 + 12; the headline clip gets its 12 + 8 + 90 + 15 first.
        self.assertEqual(plan["lengths"], [99, 130, 125])
        self.assertEqual(plan["total"], 330)
        self.assertEqual([h["planned_s"] for h in plan["holds"]], [3.0, 3.0])
        # Footage caps a clip; the other takes the rest.
        plan = marketing.plan_video(video, 30, style, texts, {0: 3.0, 2: 9.0})
        self.assertEqual(plan["lengths"], [90, 130, 134])
        with self.assertRaises(marketing.MarketingError) as err:
            marketing.plan_video(video, 30, style, texts, {0: 2.0, 2: 3.0})
        self.assertIn("record longer clips", str(err.exception))
        with self.assertRaises(marketing.MarketingError) as err:
            marketing.plan_video(dict(video, target_duration=8.0), 30, style, texts)
        self.assertIn("drop a title card", str(err.exception))

    def test_pillow_clusters_keep_marks_with_their_base(self):
        # Thai vowels and tones above/below are marks of combining class 0.
        self.assertEqual(marketing._clusters("ปี่ก"), ["ปี่", "ก"])
        # A virama joins the conjunct; the vowel sign stays with its base.
        self.assertEqual(marketing._clusters("क्षि"), ["क्षि"])

    def test_pillow_variable_weight(self):
        conf = {"fonts": {"ja-JP": {"file": "toolkit:NotoSansJP[wght].ttf", "weight": 700},
                          "ko-KR": "toolkit:NotoSansJP[wght].ttf"}}
        with tempfile.TemporaryDirectory() as td:
            engine = marketing.TextEngine(dict(conf, text_renderer="pillow"), Path(td) / "m.json", None, Path(td))
            bold = engine.block("日本", "ja-JP", 80, 1000, 400)
            regular = engine.block("日本", "ko-KR", 80, 1000, 400)
            ink = lambda b: sum(b.mask.tobytes())
            self.assertGreater(ink(bold), ink(regular) * 1.2)


GODOT = marketing.godot_executable(None)


@unittest.skipUnless(GODOT and shutil.which("ffmpeg"), "set MARKETING_GODOT to a Godot 4 console exe")
class GodotTextTests(unittest.TestCase):
    """Godot's text server: HarfBuzz shaping, ICU line breaking, fallback chains."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="godot_marketing_text_")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.conf = {"fonts": {
            "th-TH": {"file": "toolkit:NotoSansThai[wdth,wght].ttf", "weight": 700},
            "hi-IN": {"file": "toolkit:NotoSansDevanagari[wdth,wght].ttf", "weight": 700},
            "ja-JP": ["toolkit:NotoSansThai[wdth,wght].ttf", "toolkit:NotoSansJP[wght].ttf"],
            "ko-KR": "toolkit:NotoSansThai[wdth,wght].ttf"}}

    def blocks(self, conf, requests):
        engine = marketing.TextEngine(conf, self.root / "m.json", GODOT, self.root)
        engine.collecting = True
        for r in requests:
            engine.block(*r)
        engine.flush()
        return [engine.block(*r) for r in requests]

    def test_shaping_and_word_breaking(self):
        thai_am, conjunct, matra, words = self.blocks(self.conf, [
            ("กำ", "th-TH", 60, 1000, 400), ("क्ष", "hi-IN", 60, 1000, 400), ("कि", "hi-IN", 60, 1000, 400),
            ("เป็นมนุษย์สุดประเสริฐเลิศคุณค่า", "th-TH", 60, 330, 900)])
        self.assertEqual(thai_am.info["renderer"], "godot")
        # SARA AM decomposes (nikhahit + sara aa): three glyphs from two characters.
        self.assertEqual(thai_am.info["lines"][0]["glyphs"], 3)
        # Ka + virama + ssa form one conjunct glyph; unshaped they would be three.
        self.assertEqual(conjunct.info["lines"][0]["glyphs"], 1)
        self.assertEqual(matra.info["lines"][0]["glyphs"], 2)
        # Thai has no spaces: lines end only at dictionary word boundaries
        # (เป็น|มนุษย์|สุด|ประเสริฐ|เลิศ|คุณ|ค่า), never inside a word.
        lines = words.info["lines"]
        self.assertGreater(len(lines), 1)
        self.assertEqual(words.info["wrap"], "words")
        for line in lines:
            self.assertIn(line["end"], {4, 10, 13, 21, 25, 28, 31}, lines)

    def test_fallback_chain_and_missing_glyphs(self):
        mixed, = self.blocks(self.conf, [("ทดสอบ 日本語", "ja-JP", 60, 1000, 400)])
        self.assertEqual(mixed.info["lines"][0]["glyphs"], 9)  # 5 Thai, the space, 3 Han from the fallback
        with self.assertRaises(marketing.MarketingError) as err:
            self.blocks(self.conf, [("ทดสอบ 日本語", "ko-KR", 60, 1000, 400)])
        self.assertIn("U+65E5", str(err.exception))

    def test_video_and_screenshot_with_a_godot_set_locale(self):
        from PIL import Image
        Image.new("RGB", (640, 360), (42, 65, 85)).save(self.root / "raw.png")
        make_clip(self.root / "one.avi", "0x50A050", 5.0)
        test = "ทดสอบ"  # "test": a test string, not copy
        conf = dict(self.conf, strings={"th-TH": {"A": test, "B": test, "S": test}},
                    screenshots=[{"id": "s", "raw": "raw.png", "output": "out/s.png", "headline_key": "A"}],
                    video={"profile": "custom", "width": 640, "height": 360, "fps": 30,
                           "output": "out/v.mp4", "quality": "preview", "shots": [
                               {"id": "a", "kind": "clip", "source": "one.avi", "duration": 3.9, "headline_key": "A"},
                               {"id": "c", "kind": "card", "duration": "auto", "headline_key": "B", "subtitle_key": "S",
                                "transition_in": {"type": "fade", "duration": 0.3}}]})
        (self.root / "m.json").write_text(json.dumps(conf, ensure_ascii=False), encoding="utf-8")
        for cmd in ("screenshots", "video"):
            r = subprocess.run([sys.executable, str(MODULE), cmd, "--manifest", str(self.root / "m.json"),
                                "--locales", "th-TH", "--godot", GODOT], text=True, capture_output=True)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        report = json.loads((self.root / "out/v_th-TH_preview_review.json").read_text())
        self.assertEqual(report["text_renderer"], "godot")
        self.assertEqual(report["quality"]["crf"], 26)
        self.assertEqual(report["transitions_ok"], 1)
        # The Thai card: 9 + 8 + 90 frames (it ends the video: no fade out), 3 s readable.
        self.assertEqual(report["frames"], 117 + 107 - 9)
        self.assertEqual(report["text_holds_ok"], 2, report["text_holds"])
        self.assertGreaterEqual(report["text_holds"][1]["measured_s"], 3.0)
        shot = Image.open(self.root / "out/s_th-TH.png").convert("L")
        self.assertGreater(max(shot.crop((0, 0, 640, 60)).tobytes()), 200)  # the headline is drawn

    def test_balanced_wrap_at_full_size(self):
        # A portrait headline: start 70 px in 950 px of line; Godot wraps it at
        # full size into lines of even length (a plain wrap orphans "and trees").
        text = "Test headline: build a whole village of tiny roads and trees"
        block, = self.blocks({"text_renderer": "godot"}, [(text, "en-US", 70, 950, 518, 35)])
        self.assertEqual((block.info["font_size"], block.info["wrap"]), (70, "words"))
        widths = [line["width"] for line in block.info["lines"]]
        self.assertGreater(min(widths) / max(widths), 0.8, block.info["lines"])

    def test_fonts_proof_all_locales_with_the_toolkit_defaults(self):
        # No "fonts" in the manifest: the toolkit's Noto faces for all 20 locales.
        (self.root / "m.json").write_text("{}", encoding="utf-8")
        r = subprocess.run([sys.executable, str(MODULE), "fonts", "--manifest", str(self.root / "m.json"), "--locales",
                            "all", "--godot", GODOT, "--out", "proof"], text=True, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        report = json.loads((self.root / "proof/fonts_proof.json").read_text(encoding="utf-8"))["locales"]
        self.assertEqual(set(report), set(marketing.SUPPORTED_LOCALES))
        godot = {"th-TH", "hi-IN", "ja-JP", "zh-CN", "zh-TW"}
        for loc, entry in report.items():
            self.assertEqual(entry["renderer"], "godot" if loc in godot else "pillow", loc)
            if loc not in marketing.TOOLKIT_LOCALE_FONTS:
                self.assertEqual(entry["fonts"], [{"file": "NotoSans[wdth,wght].ttf", "weight": 700, "width": None}])

    def test_fonts_proof(self):
        conf = {"fonts": {"th-TH": self.conf["fonts"]["th-TH"], "hi-IN": self.conf["fonts"]["hi-IN"],
                          "ja-JP": {"file": "toolkit:NotoSansJP[wght].ttf", "weight": 700}}}
        (self.root / "m.json").write_text(json.dumps(conf), encoding="utf-8")
        r = subprocess.run([sys.executable, str(MODULE), "fonts", "--manifest", str(self.root / "m.json"), "--locales",
                            "th-TH", "hi-IN", "ja-JP", "--godot", GODOT, "--out", "proof"], text=True, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        report = json.loads((self.root / "proof/fonts_proof.json").read_text(encoding="utf-8"))
        self.assertEqual({v["renderer"] for v in report["locales"].values()}, {"godot"})
        self.assertTrue((self.root / "proof/fonts_proof.png").is_file())
        # Each layout reports its own block only: the landscape headline and the
        # portrait one share their text but not their layout.
        for loc in report["locales"].values():
            for name in ("headline", "portrait"):
                self.assertEqual(len(loc["blocks"][name]), 1, (name, loc["blocks"][name]))


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="godot_marketing_install_")
        self.addCleanup(self.tmp.cleanup)
        self.project = Path(self.tmp.name)
        (self.project / "project.godot").write_text("config_version=5\n", encoding="utf-8")

    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(MODULE), *args], text=True, capture_output=True)

    def test_record_without_godot_keeps_the_master(self):
        self.assertEqual(self.run_cli("install", "--project", str(self.project)).returncode, 0)
        master = self.project / "raw/shot.png"
        master.parent.mkdir()
        master.write_bytes(b"master")
        (self.project / "m.json").write_text(json.dumps({"capture_jobs": [
            {"id": "s", "kind": "screenshot", "width": 640, "height": 360, "output": "raw/shot.png"}]}))
        env = {k: v for k, v in os.environ.items() if k != "MARKETING_GODOT"}
        env["PATH"] = os.path.dirname(sys.executable)  # no Godot on it
        r = subprocess.run([sys.executable, str(MODULE), "record", "--project", str(self.project), "--manifest",
                            str(self.project / "m.json"), "--job", "s", "--overwrite"],
                           text=True, capture_output=True, env=env)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("MARKETING_GODOT", r.stderr)
        self.assertEqual(master.read_bytes(), b"master")

    def fake_godot(self) -> Path:
        """A stand-in Godot for `record`: FAKE_GODOT_MODE 'crash' writes half a
        file and fails, 'wrong_size' writes a 10x10 PNG, 'ok' the job's PNG."""
        script = self.project / "fake_godot.py"
        script.write_text(
            "import json, os, sys\nfrom pathlib import Path\nfrom PIL import Image\n"
            "args = sys.argv[1:]\nuser = args[args.index('--') + 1:]\n"
            "opt = {a.split('=', 1)[0]: a.split('=', 1)[1] for a in user if '=' in a}\n"
            "conf = json.loads(Path(opt['--manifest']).read_text(encoding='utf-8'))\n"
            "job = next(j for j in conf['capture_jobs'] if j['id'] == opt['--job'])\n"
            "out = Path(args[args.index('--write-movie') + 1] if '--write-movie' in args else job['output'])\n"
            "mode = os.environ['FAKE_GODOT_MODE']\n"
            "if mode == 'crash':\n    out.write_bytes(b'half a file')\n    sys.exit(1)\n"
            "size = (10, 10) if mode == 'wrong_size' else (job['width'], job['height'])\n"
            "Image.new('RGB', size, (1, 2, 3)).save(out, 'PNG')\n", encoding="utf-8")
        if os.name == "nt":
            exe = self.project / "godot.cmd"
            exe.write_text(f'@"{sys.executable}" "{script}" %*\r\n', encoding="utf-8")
        else:
            exe = self.project / "godot"
            exe.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{script}" "$@"\n', encoding="utf-8")
            exe.chmod(0o755)
        return exe

    def test_failed_record_keeps_the_existing_recording(self):
        self.assertEqual(self.run_cli("install", "--project", str(self.project)).returncode, 0)
        raw = self.project / "raw"
        raw.mkdir()
        (raw / "shot.png").write_bytes(b"approved master")
        (raw / "clip.avi").write_bytes(b"approved clip")
        (self.project / "m.json").write_text(json.dumps({"capture_jobs": [
            {"id": "s", "kind": "screenshot", "width": 640, "height": 360, "output": "raw/shot.png"},
            {"id": "v", "kind": "video", "width": 640, "height": 360, "fps": 30, "duration": 1.0,
             "output": "raw/clip.avi"}]}))
        godot = self.fake_godot()

        def record(job, mode):
            env = dict(os.environ, FAKE_GODOT_MODE=mode)
            return subprocess.run([sys.executable, str(MODULE), "record", "--project", str(self.project), "--manifest",
                                   str(self.project / "m.json"), "--job", job, "--godot", str(godot), "--overwrite"],
                                  text=True, capture_output=True, env=env)

        for job, mode, master in (("s", "crash", "shot.png"), ("s", "wrong_size", "shot.png"), ("v", "crash", "clip.avi")):
            r = record(job, mode)
            self.assertNotEqual(r.returncode, 0, (job, mode))
            self.assertIn(f"the existing {master} is unchanged", r.stderr)
            self.assertIn(b"approved", (raw / master).read_bytes())
            self.assertEqual(sorted(p.name for p in raw.iterdir() if ".partial" in p.name), [])
            self.assertFalse((self.project / "override.cfg").exists())
        # A capture that passes its checks replaces the master.
        r = record("s", "ok")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        from PIL import Image
        with Image.open(raw / "shot.png") as im:
            self.assertEqual(im.size, (640, 360))
        self.assertEqual(sorted(p.name for p in raw.iterdir() if ".partial" in p.name), [])

    def test_install_status_and_drift(self):
        r = self.run_cli("install", "--project", str(self.project))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue((self.project / "addons/marketing_capture/capture_runner.gd").is_file())
        self.assertTrue((self.project / "addons/store_screenshot_capture/viewport_capture.gd").is_file())
        lock = json.loads((self.project / marketing.LOCK_NAME).read_text())
        self.assertEqual(lock["version"], marketing.VERSION)
        self.assertEqual(self.run_cli("status", "--project", str(self.project)).returncode, 0)
        # A Godot .uid next to a script is not drift; an edited file is.
        (self.project / "addons/marketing_capture/capture_runner.gd.uid").write_text("uid://x\n")
        self.assertEqual(self.run_cli("status", "--project", str(self.project)).returncode, 0)
        with (self.project / "addons/marketing_capture/capture_runner.gd").open("a") as fh:
            fh.write("# local edit\n")
        r = self.run_cli("status", "--project", str(self.project))
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("changed in the project", r.stderr)
        # Reinstall refuses without --overwrite, repairs with it and keeps the .uid.
        self.assertNotEqual(self.run_cli("install", "--project", str(self.project)).returncode, 0)
        self.assertEqual(self.run_cli("install", "--project", str(self.project), "--overwrite").returncode, 0)
        self.assertEqual(self.run_cli("status", "--project", str(self.project)).returncode, 0)
        self.assertTrue((self.project / "addons/marketing_capture/capture_runner.gd.uid").is_file())

    def test_window_override_is_temporary_and_never_replaces_a_game_override(self):
        with marketing.window_override(self.project, 1080, 1920):
            text = (self.project / "override.cfg").read_text()
            self.assertIn("window_height_override=1920", text)
        self.assertFalse((self.project / "override.cfg").exists())
        (self.project / "override.cfg").write_text("[application]\n")
        with self.assertRaises(marketing.MarketingError):
            with marketing.window_override(self.project, 1080, 1920):
                pass
        self.assertEqual((self.project / "override.cfg").read_text(), "[application]\n")


if __name__ == "__main__":
    unittest.main()
