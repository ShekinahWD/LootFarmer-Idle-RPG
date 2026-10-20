#!/usr/bin/env python3
"""Reusable Godot marketing capture & FFmpeg composer. Python 3.10+.

Development tool, NOT an Android SDK. Never alters saved games, repo identity,
engine config or player data. See README for the adapter safety contract.

Commands: check, install, status, record, screenshots, video, pipeline,
verify, analyze, fonts. Every command fails rather than overwriting work unless
--overwrite is given.
"""
from __future__ import annotations

import argparse
import functools
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from argparse import Namespace
from contextlib import contextmanager
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOLKIT = HERE.parent
VERSION = (TOOLKIT / "VERSION").read_text(encoding="utf-8").strip()
ADDONS = ("store_screenshot_capture", "marketing_capture")
LOCK_NAME = "marketing_capture_toolkit.lock.json"
# Files Godot generates next to the addon's sources: never managed, never compared.
UNMANAGED_SUFFIXES = (".uid", ".import")
GODOT_RUNNER = "res://addons/marketing_capture/capture_runner.tscn"
# override.cfg written for one capture run (Movie Maker records at the project's
# window size, not --resolution: Godot 4.7.2). Recognised and removed by this line.
OVERRIDE_MARKER = "; marketing_capture: temporary window override for one capture run, deleted afterwards"
PROFILES = {
    "play_store": (1920, 1080, 30),
    "youtube": (1920, 1080, 30),
    "tiktok": (1080, 1920, 30),
    "shorts": (1080, 1920, 30),
    "reels": (1080, 1920, 30),
    "square": (1080, 1080, 30),
}
# Vertical short-form profiles: the platform's own UI covers the top (tabs),
# the bottom (caption, sound) and the right edge (like/comment/share), so their
# text stays inside these margins (shares of the height / width) unless the
# manifest's or the video's style sets "safe_area".
SOCIAL_PROFILES = ("tiktok", "shorts", "reels")
SOCIAL_SAFE_AREA = {"top": 0.08, "bottom": 0.22, "left": 0.06, "right": 0.12}
# What fills a reframed shot above and below its picture when its source
# window is wider than the video's aspect ratio (see reframe_window()).
REFRAME_FILLS = ("blur", "black")
SUPPORTED_LOCALES = (
    "en-US", "es-419", "es-ES", "pt-BR", "fr-FR", "de-DE", "it-IT", "nl-NL",
    "pl-PL", "ru-RU", "uk-UA", "tr-TR", "id-ID", "vi-VN", "th-TH", "hi-IN",
    "ja-JP", "ko-KR", "zh-CN", "zh-TW",
)
DEFAULT_STYLE = {
    "text_color": "#FFFFFF",       # headline and card title
    "subtitle_color": "#FFFFFF",   # card subtitle
    "accent_color": "",            # card rule between title and subtitle ("" = none)
    "band_color": "#000000",       # headline band behind text on gameplay
    "band_opacity": 0.66,
    "card_color": "#000000",
    "card_safe_width": 0.75,       # share of the width a card line may take
    # Margins (shares of the height / width) that headlines and card text keep
    # clear of; 0 = the whole frame. Vertical social profiles default to
    # SOCIAL_SAFE_AREA.
    "safe_area": {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0},
    "text_fade": 0.25,             # seconds a headline / card text takes to fade in or out
    # Layout: the author's lines may shrink to keep_lines_scale of the start
    # size, then the text is re-wrapped (balanced lines) at full size again;
    # nothing is set below min_text_scale of its start size (refused instead).
    "keep_lines_scale": 0.85,
    "min_text_scale": 0.5,
    # Reading time: every headline or card text stays fully visible (fades
    # excluded) for at least text_min_hold seconds, longer when its reading
    # units / reading_cps is more (see reading_units()).
    "text_min_hold": 3.0,
    "reading_cps": 15.0,
}
# Luma of a downscaled grey frame (0-255): a frame is black when its brightest
# sample is at most this (limited-range black decodes to about 16).
BLACK_MAX = 22
TRANSITIONS = ("cut", "fade", "crossfade")
# Final H.264 encode. 'high' is the default and the one for store delivery;
# the others write <name>_<locale>_<quality>.mp4, so a quick preview never
# replaces a final. A manifest's "quality_presets" may adjust or add presets.
QUALITY_PRESETS = {
    "preview": {"crf": 26, "x264_preset": "veryfast"},
    "standard": {"crf": 21, "x264_preset": "medium"},
    "high": {"crf": 18, "x264_preset": "slow"},
}
DEFAULT_QUALITY = "high"
X264_PRESETS = ("ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow")
# Text renderers (see TextEngine) and the Godot scripts the 'godot' one runs.
TEXT_RENDERERS = ("auto", "pillow", "godot")
GODOT_TEXT_SCRIPTS = ("marketing_fonts.gd", "text_renderer.gd")
# Fonts shipped with the toolkit (Noto, SIL OFL 1.1): manifest paths 'toolkit:<file>'.
TOOLKIT_FONTS = TOOLKIT / "assets" / "fonts"
FONT_LOCK = TOOLKIT_FONTS / "font_manifest.json"
# Glyph, shaping and line-breaking test strings per locale (never marketing copy).
SCRIPT_SAMPLES = TOOLKIT_FONTS / "script_samples.json"
# The toolkit's faces for a locale the manifest's "fonts" maps neither itself
# nor through "default": Noto Sans for the 14 Latin/Cyrillic locales; for Thai
# and Devanagari the script's face first (it carries basic Latin) and Noto Sans
# after it for anything else; the CJK faces (Latin included) alone. All at a
# headline weight; a manifest maps a locale (or "default") to change it.
TOOLKIT_FONT_WEIGHT = 700
NOTO_SANS = "toolkit:NotoSans[wdth,wght].ttf"
TOOLKIT_LOCALE_FONTS = {
    "th-TH": ("toolkit:NotoSansThai[wdth,wght].ttf", NOTO_SANS),
    "hi-IN": ("toolkit:NotoSansDevanagari[wdth,wght].ttf", NOTO_SANS),
    "ja-JP": ("toolkit:NotoSansJP[wght].ttf",),
    "ko-KR": ("toolkit:NotoSansKR[wght].ttf",),
    "zh-CN": ("toolkit:NotoSansSC[wght].ttf",),
    "zh-TW": ("toolkit:NotoSansTC[wght].ttf",),
}


class MarketingError(Exception):
    pass


# ================================================================ processes

def run(args: list, *, log: Path | None = None, show: tuple[str, ...] = ()) -> None:
    """Run a command. With `log`, everything goes to that file and only lines
    containing one of `show` (or an error) are echoed."""
    args = [str(s) for s in args]
    print("$", " ".join(args), flush=True)
    if log is None:
        result = subprocess.run(args, check=False)
        if result.returncode:
            raise MarketingError(f"Command failed with exit {result.returncode}")
        return
    log.parent.mkdir(parents=True, exist_ok=True)
    tail: list[str] = []
    with log.open("w", encoding="utf-8") as fh, subprocess.Popen(
            args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace") as proc:
        assert proc.stdout is not None
        for line in proc.stdout:
            fh.write(line)
            tail = (tail + [line.rstrip()])[-25:]
            if any(s in line for s in show) or "ERROR" in line:
                print("  " + line.rstrip(), flush=True)
        code = proc.wait()
    if code:
        print("\n".join("  | " + t for t in tail))
        raise MarketingError(f"Command failed with exit {code} (full log: {log})")


def probe(path: Path) -> dict:
    p = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)],
                       check=False, text=True, capture_output=True)
    if p.returncode:
        raise MarketingError(f"ffprobe failed for {path}: {p.stderr}")
    return json.loads(p.stdout)


def assert_tool(name: str) -> None:
    if not shutil.which(name):
        raise MarketingError(f"Missing required executable: {name}")


def check(args) -> None:
    for item in ("ffmpeg", "ffprobe"):
        assert_tool(item)
        res = subprocess.run([item, "-version"], capture_output=True, text=True, check=True)
        print(res.stdout.splitlines()[0])
    try:
        from PIL import features
        print("Pillow available; complex-script shaping (Raqm):", "yes" if features.check("raqm") else
              "no (needed only by text_renderer 'pillow' for shaped scripts; 'auto' and 'godot' set them with Godot)")
    except ImportError:
        print("Pillow absent: install 'Pillow' for screenshot headlines and video cards")
    godot = godot_executable(getattr(args, "godot", None))
    if godot:
        res = subprocess.run([godot, "--version"], capture_output=True, text=True, check=False)
        print("Godot", res.stdout.strip() or res.stderr.strip(), "(text renderer for shaped scripts and font fallbacks)")
    else:
        print("Godot: not given (--godot or MARKETING_GODOT): Thai, Devanagari, CJK and font fallback chains need it")
    print("Toolkit", VERSION)


# ================================================================ manifest

def load_manifest(path: Path) -> dict:
    if not path.is_file():
        raise MarketingError(f"Manifest not found: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError) as e:
        raise MarketingError(f"Manifest could not be read: {e}") from e
    if not isinstance(data, dict):
        raise MarketingError("Manifest root must be an object")
    return data


def source_path(raw: str, manifest: Path) -> Path:
    p = Path(raw)
    return p if p.is_absolute() else (manifest.parent / p).resolve()


def unique_destination(path: Path, overwrite: bool) -> None:
    if path.exists() and not overwrite:
        raise MarketingError(f"Refusing to overwrite existing output: {path}; use --overwrite explicitly")
    path.parent.mkdir(parents=True, exist_ok=True)


def ensure_output_root(conf: dict, manifest: Path) -> None:
    """Generated media inside a Godot project must never be imported as game
    assets: the manifest's output_root gets a .gdignore."""
    root = conf.get("output_root")
    if not root:
        return
    path = source_path(str(root), manifest)
    path.mkdir(parents=True, exist_ok=True)
    marker = path / ".gdignore"
    if not marker.exists():
        marker.write_text("# Generated marketing media: never imported by Godot.\n", encoding="utf-8")


def style_of(conf: dict, video: dict | None = None) -> dict:
    style = dict(DEFAULT_STYLE)
    if video and video.get("profile") in SOCIAL_PROFILES:
        style["safe_area"] = dict(SOCIAL_SAFE_AREA)
    style.update(conf.get("style", {}))
    if video:
        style.update(video.get("style", {}))
    return style


def safe_area_px(style: dict, size: tuple[int, int]) -> tuple[int, int, int]:
    """style.safe_area in pixels: (top, bottom, side). Text is centred, so it
    keeps the larger of the left and right margins on both sides."""
    area = style.get("safe_area") or {}
    if not isinstance(area, dict) or set(area) - {"top", "bottom", "left", "right"}:
        raise MarketingError("style.safe_area: an object with top, bottom, left, right (shares of the frame)")
    v = {k: float(area.get(k, 0)) for k in ("top", "bottom", "left", "right")}
    if any(not 0 <= x < 0.5 for x in v.values()) or v["top"] + v["bottom"] >= 0.8:
        raise MarketingError("style.safe_area: each margin 0 to < 0.5, top + bottom < 0.8")
    width, height = size
    return round(v["top"] * height), round(v["bottom"] * height), round(max(v["left"], v["right"]) * width)


# ================================================================ install / status

def _managed_files(root: Path) -> dict[str, Path]:
    return {f.relative_to(root).as_posix(): f for f in sorted(root.rglob("*"))
            if f.is_file() and not f.name.endswith(UNMANAGED_SUFFIXES)}


def _sha(path: Path) -> str:
    # Line endings normalised: a Git checkout may convert them.
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def install(args) -> None:
    project = args.project.resolve()
    if not (project / "project.godot").exists():
        raise MarketingError(f"Not a Godot project: {project}")
    for name in ADDONS:
        if not (TOOLKIT / "addons" / name).is_dir():
            raise MarketingError(f"Toolkit package incomplete: {TOOLKIT / 'addons' / name} is missing")
        target = project / "addons" / name
        if target.exists() and not args.overwrite:
            raise MarketingError(f"Destination exists, refusing to replace: {target} (review, then use --overwrite)")
    digests = {}
    for name in ADDONS:
        source, target = TOOLKIT / "addons" / name, project / "addons" / name
        src_files, old_files = _managed_files(source), (_managed_files(target) if target.exists() else {})
        for rel, f in src_files.items():
            dest = target / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            digests[f"addons/{name}/{rel}"] = _sha(f)
        for rel, f in old_files.items():
            if rel not in src_files:
                f.unlink()
                print("Removed (no longer in the toolkit):", f)
        # A Godot .uid left without its script would point at nothing.
        for uid in target.rglob("*.uid"):
            if not uid.with_suffix("").exists():
                uid.unlink()
        print("Installed", target)
    lock = {"toolkit": "Godot-Marketing-Toolkit", "version": VERSION,
            "status": ("prerelease" if ("draft" in VERSION or "rc" in VERSION) else "released"),
            "file_sha256": digests}
    (project / LOCK_NAME).write_text(json.dumps(lock, indent=2) + "\n", encoding="utf-8")
    print("Pinned toolkit version:", VERSION)
    print("NEXT: a game-owned adapter extending addons/marketing_capture/scenario_adapter.gd and a manifest (see README).")
    print("Exclude addons/marketing_capture/, the adapter and the manifest from release exports.")


def status(args) -> None:
    """The installed addons match the lock (no local drift) and the toolkit
    source this script belongs to (no unreleased toolkit change)."""
    project = args.project.resolve()
    lock_path = project / LOCK_NAME
    if not lock_path.is_file():
        raise MarketingError(f"No {LOCK_NAME} in {project}: run install first")
    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    problems = []
    if lock.get("version") != VERSION:
        problems.append(f"lock pins {lock.get('version')}, this toolkit is {VERSION}")
    locked = lock.get("file_sha256", {})
    installed = {}
    for name in ADDONS:
        root = project / "addons" / name
        installed.update({f"addons/{name}/{rel}": f for rel, f in (_managed_files(root) if root.exists() else {}).items()})
    for rel, digest in locked.items():
        f = project / rel
        if not f.is_file():
            problems.append(f"missing: {rel}")
        elif _sha(f) != digest:
            problems.append(f"changed in the project since install: {rel}")
        src = TOOLKIT / rel
        if not src.is_file():
            problems.append(f"not in the toolkit source: {rel}")
        elif _sha(src) != digest:
            problems.append(f"toolkit source differs from the pinned file: {rel}")
    for rel in installed:
        if rel not in locked:
            problems.append(f"unmanaged file inside a toolkit addon: {rel}")
    for name in ADDONS:
        for rel in _managed_files(TOOLKIT / "addons" / name):
            if f"addons/{name}/{rel}" not in locked:
                problems.append(f"toolkit file not installed: addons/{name}/{rel}")
    if problems:
        raise MarketingError("Toolkit install drift:\n  " + "\n  ".join(problems))
    print(f"Toolkit {VERSION}: {len(locked)} files installed, identical to the lock and the toolkit source.")


# ================================================================ record

@contextmanager
def window_override(project: Path, width: int, height: int):
    """Godot Movie Maker records at the project's window size (it ignores
    --resolution), and the game must lay itself out at the target size from its
    first frame: a temporary override.cfg sets the window size for one run. A
    game's own override.cfg is never touched."""
    cfg = project / "override.cfg"
    if cfg.exists() and OVERRIDE_MARKER not in cfg.read_text(encoding="utf-8", errors="replace"):
        raise MarketingError(f"{cfg} exists and is not ours: remove it (or merge the window override by hand)")
    cfg.write_text(f"{OVERRIDE_MARKER}\n[display]\n\nwindow/size/window_width_override={width}\n"
                   f"window/size/window_height_override={height}\n", encoding="utf-8")
    try:
        yield
    finally:
        cfg.unlink(missing_ok=True)


def count_frames(path: Path) -> int:
    r = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
                        "-show_entries", "stream=nb_read_frames", "-of", "csv=p=0", str(path)],
                       capture_output=True, text=True)
    if r.returncode:
        raise MarketingError("ffprobe could not count recorded frames")
    return int(r.stdout.strip().strip(","))


def record(args) -> None:
    manifest = args.manifest.resolve()
    conf = load_manifest(manifest)
    jobs = [j for j in conf.get("capture_jobs", []) if j.get("id") == args.job]
    if len(jobs) != 1:
        raise MarketingError(f"Expected one capture_jobs entry with id={args.job!r}, got {len(jobs)}")
    job = jobs[0]
    project = args.project.resolve()
    if not (project / "project.godot").exists() or not (project / "addons/marketing_capture/capture_runner.tscn").exists():
        raise MarketingError("Install the toolkit in a Godot project first")
    kind = job.get("kind")
    if kind not in ("video", "screenshot"):
        raise MarketingError("capture job kind must be video or screenshot")
    width, height = int(job.get("width", 0)), int(job.get("height", 0))
    fps = int(job.get("fps", 30))
    if min(width, height) < 320 or not (1 <= fps <= 120):
        raise MarketingError("Invalid capture resolution/fps")
    # Found before anything is replaced: a missing Godot never costs a master.
    godot = godot_executable(args.godot)
    if not godot:
        raise MarketingError(f"Godot not found ({args.godot or 'no --godot'}): pass --godot <console exe> "
                             "or set MARKETING_GODOT")
    out = source_path(str(job.get("output", "")), manifest)
    if kind == "screenshot" and out.suffix.lower() != ".png":
        raise MarketingError("Screenshot output must be .png")
    if kind == "video" and out.suffix.lower() != ".avi":
        raise MarketingError("Automatic record supports AVI output; PNG sequences may be captured manually with Godot Movie Maker")
    unique_destination(out, args.overwrite)
    # Godot writes a partial file next to the master; only a capture that
    # passes every check below replaces the master (a failed re-take keeps it).
    partial = out.with_name(f"{out.stem}.partial{out.suffix}")
    partial.unlink(missing_ok=True)
    ensure_output_root(conf, manifest)
    frames = 0
    if kind == "video":
        duration = float(job.get("duration", 0))
        frames = round(duration * fps)
        if frames <= 0 or abs(frames / fps - duration) > 0.00001:
            raise MarketingError("Video job duration must be a positive exact frame multiple")
    user_switches = [*conf.get("godot_user_args", []), *job.get("godot_user_args", [])]
    if any(not isinstance(a, str) or not a.startswith("--") for a in user_switches):
        raise MarketingError("godot_user_args must be a list of --flags parsed by the game")
    # Godot reads the manifest; the runner writes its raw PNG to the absolute
    # path in the job. Relative outputs resolve through an expanded copy, and
    # this job's output is the partial file.
    expanded = dict(conf)
    expanded["capture_jobs"] = [dict(j, output=str(partial if j is job else source_path(str(j.get("output", "")), manifest)))
                                for j in conf["capture_jobs"]]
    try:
        with tempfile.TemporaryDirectory(prefix="marketing_capture_") as td:
            expanded_path = Path(td) / "job.json"
            expanded_path.write_text(json.dumps(expanded, ensure_ascii=False, indent=2), encoding="utf-8")
            command = [godot, "--path", str(project), "--resolution", f"{width}x{height}", "--fixed-fps", str(fps)]
            if kind == "video":
                command += ["--write-movie", str(partial), "--quit-after", str(frames)]
            # The game's isolated-test-save switches reach every autoload before the
            # runner instantiates the main scene. Games own the switches.
            command += [GODOT_RUNNER, "--", "--marketing-capture", f"--manifest={expanded_path}", f"--job={args.job}", *user_switches]
            with window_override(project, width, height):
                run(command, log=out.with_suffix(out.suffix + ".log"), show=("MARKETING_CAPTURE", *conf.get("log_show", [])))
        _check_capture(partial, kind, width, height, fps, frames)
    except (MarketingError, OSError, ValueError) as exc:
        partial.unlink(missing_ok=True)
        kept = f"; the existing {out.name} is unchanged" if out.exists() else ""
        raise MarketingError(f"Capture {args.job} failed: {exc}{kept}") from exc
    os.replace(partial, out)
    print("RAW CAPTURE OK:", out)


def _check_capture(path: Path, kind: str, width: int, height: int, fps: int, frames: int) -> None:
    """A fresh capture is what the job asked for: an AVI's size, fps and exact
    frame count, or a PNG's exact size."""
    if not path.exists() or path.stat().st_size == 0:
        raise MarketingError(f"Godot did not produce {path}")
    if kind == "video":
        info = probe(path)
        videos = [s for s in info.get("streams", []) if s.get("codec_type") == "video"]
        if not videos or int(videos[0]["width"]) != width or int(videos[0]["height"]) != height:
            got = f"{videos[0]['width']}x{videos[0]['height']}" if videos else "no video"
            raise MarketingError(f"Recorded AVI is {got}, not {width}x{height}")
        a, b = map(int, videos[0].get("avg_frame_rate", "0/1").split("/"))
        if not b or abs(a / b - fps) > 0.01:
            raise MarketingError("Recorded AVI does not have the requested FPS")
        count = count_frames(path)
        if count != frames:
            raise MarketingError(f"Recorded AVI has {count} frames, expected {frames}")
    else:
        Image = _pil()[0]
        try:
            with Image.open(path) as im:
                size = im.size
        except OSError as exc:
            raise MarketingError(f"Recorded screenshot is not a readable PNG: {exc}") from exc
        if size != (width, height):
            raise MarketingError(f"Recorded screenshot is {size}, not {(width, height)}")


# ================================================================ fonts

def _pil():
    try:
        from PIL import Image, ImageDraw, ImageFont
        return Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise MarketingError("Install Pillow: python -m pip install Pillow") from exc


def _has_raqm() -> bool:
    try:
        from PIL import features
        return bool(features.check("raqm"))
    except ImportError:
        return False


def _face_path(raw: str, base: Path) -> Path:
    """A font file: 'toolkit:<path>' is inside this toolkit's assets/fonts (the
    bundled Noto faces, shared by every game without a copy); otherwise
    absolute or relative to the manifest."""
    if raw.startswith("toolkit:"):
        p = TOOLKIT_FONTS / raw[len("toolkit:"):]
    else:
        p = Path(raw)
        p = p if p.is_absolute() else base / p
    if not p.is_file():
        raise MarketingError(f"Font file not found: {p}")
    return p.resolve()


def toolkit_font_spec(locale: str) -> list[dict]:
    """The toolkit's own Noto chain for a locale (TOOLKIT_LOCALE_FONTS)."""
    return [{"file": f, "weight": TOOLKIT_FONT_WEIGHT} for f in TOOLKIT_LOCALE_FONTS.get(locale, (NOTO_SANS,))]


def font_chain(conf: dict, locale: str, base: Path) -> list[dict] | str:
    """The locale's faces, primary first, then its fallbacks in order
    (manifest 'fonts': locale or 'default' -> a file, {"file", "weight",
    "width"}, or a list of those; neither: the toolkit's Noto chain).
    'builtin:pillow' (tests) is returned as is."""
    fonts = conf.get("fonts") or {}
    spec = fonts.get(locale, fonts.get("default"))
    if spec is None:
        spec = toolkit_font_spec(locale)
    if not spec:
        raise MarketingError(f"Empty font mapping for {locale} in the manifest's 'fonts' "
                             "(map it to licensed files, or leave it out for the toolkit's Noto faces)")
    if spec == "builtin:pillow":
        return spec
    chain = []
    for item in spec if isinstance(spec, list) else [spec]:
        item = {"file": item} if isinstance(item, str) else dict(item)
        if not isinstance(item.get("file"), str) or item["file"] == "builtin:pillow":
            raise MarketingError(f"Font entry for {locale} needs a 'file' ('builtin:pillow' only alone): {item}")
        unknown = set(item) - {"file", "weight", "width"}
        if unknown:
            raise MarketingError(f"Font entry for {locale}: unknown keys {sorted(unknown)}")
        chain.append({"path": _face_path(item["file"], base), "weight": item.get("weight"), "width": item.get("width")})
    return chain


# Scripts whose text needs shaping (reordering, conjuncts, stacked marks) or
# dictionary/kinsoku line breaking: (first, last, name).
COMPLEX_SCRIPTS = (
    (0x0590, 0x08FF, "Hebrew/Arabic (right-to-left shaping)"),
    (0x0900, 0x097F, "Devanagari (shaping)"),
    (0x0980, 0x0DFF, "Indic (shaping)"),
    (0x0E00, 0x0E7F, "Thai (shaping and word breaking)"),
    (0x0E80, 0x0EFF, "Lao (shaping and word breaking)"),
    (0x0F00, 0x0FFF, "Tibetan (shaping)"),
    (0x1000, 0x109F, "Myanmar (shaping and word breaking)"),
    (0x1780, 0x17FF, "Khmer (shaping and word breaking)"),
)
LINE_BREAK_SCRIPTS = (
    (0x3040, 0x30FF, "Kana (line breaking)"),
    (0x3400, 0x9FFF, "Han (line breaking)"),
    (0xF900, 0xFAFF, "Han (line breaking)"),
    (0xFF00, 0xFFEF, "full-width forms (line breaking)"),
)
# Scripts written without spaces between words: Pillow never breaks inside
# their words (no dictionary), Godot breaks them with ICU's.
UNSPACED_SCRIPTS = ((0x0E00, 0x0EFF), (0x1000, 0x109F), (0x1780, 0x17FF))
# Kinsoku: characters a line may not start with (Pillow's CJK wrap).
NO_LINE_START = set("、。，．・：；！？）」』】〉》〕］｝ー々ゝゞぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ,.!?:;)]}%")


def needs_godot(chain, text: str) -> str:
    """Why this text in this font chain needs Godot's text server, or ''."""
    if isinstance(chain, list) and len(chain) > 1:
        return "a font fallback chain"
    for c in text:
        o = ord(c)
        for lo, hi, name in COMPLEX_SCRIPTS + LINE_BREAK_SCRIPTS:
            if lo <= o <= hi:
                return name
        if unicodedata.category(c) in ("Mn", "Mc", "Me"):
            return "combining marks (shaping)"
    return ""


def _shaping_reason(text: str) -> str:
    for c in text:
        for lo, hi, name in COMPLEX_SCRIPTS:
            if lo <= ord(c) <= hi:
                return name
        if unicodedata.category(c) in ("Mn", "Mc", "Me"):
            return "combining marks"
    return ""


def godot_executable(value: str | None) -> str | None:
    """A runnable Godot (the console exe on Windows): --godot, else the
    MARKETING_GODOT environment variable; None when neither is runnable."""
    value = value or os.environ.get("MARKETING_GODOT")
    if not value:
        return None
    if Path(value).is_file():
        return str(Path(value))
    return shutil.which(value)


# ================================================================ text blocks

class Block:
    """One piece of text set to fit: a coverage mask (white = ink), the text's
    width and height in it, the margin around them, and how it was set."""

    def __init__(self, mask, width: int, height: int, pad: int = 0, info: dict | None = None):
        self.mask, self.width, self.height, self.pad, self.info = mask, width, height, pad, info or {}


class TextEngine:
    """Sets every text block of one composition, per locale with Pillow or
    Godot's text server (manifest 'text_renderer'):

    - 'pillow': Pillow/FreeType, one face per locale. Shaped scripts need
      Pillow built with Raqm; words without spaces (Thai) are never broken.
    - 'godot': Godot's text server (HarfBuzz shaping, ICU line breaking, font
      fallback chains), headless, through addons/marketing_capture.
    - 'auto' (default): Godot for the locales that need it (a fallback chain,
      a shaped script, Han/Kana line breaking: needs_godot()), Pillow for the
      others, so Latin/Cyrillic copy needs no Godot.

    Godot blocks are batched: callers make every block once with
    `collecting` on (placeholders, requests recorded), `flush()` renders them
    in one Godot run, then the real pass gets the results."""

    def __init__(self, conf: dict, manifest: Path, godot: str | None, work: Path):
        self.conf, self.base, self.work = conf, manifest.parent, work
        self.godot = godot_executable(godot)
        self.mode = conf.get("text_renderer", "auto")
        if self.mode not in TEXT_RENDERERS:
            raise MarketingError(f"text_renderer must be one of {', '.join(TEXT_RENDERERS)}")
        self.collecting = False
        self.pending: dict[tuple, dict] = {}
        self.done: dict[tuple, Block] = {}
        self._chains: dict[str, object] = {}
        self._renderers: dict[str, str] = {}
        self._pillow_fonts: dict[tuple, object] = {}
        self._missing_cache: dict[tuple, bool] = {}
        # When a list, block() appends every key it is asked for (the fonts
        # proof reports which blocks each layout used).
        self.trace: list[tuple] | None = None

    def chain(self, locale: str):
        if locale not in self._chains:
            self._chains[locale] = font_chain(self.conf, locale, self.base)
        return self._chains[locale]

    def renderer(self, locale: str, text: str = "") -> str:
        """The locale's renderer, decided once, on the first call, from all of
        its approved copy (plus `text`: copy outside the manifest, such as the
        fonts proof's test strings)."""
        if locale in self._renderers:
            return self._renderers[locale]
        chain = self.chain(locale)
        copy = "\n".join(v for v in self.conf.get("strings", {}).get(locale, {}).values() if isinstance(v, str)) + text
        reason = needs_godot(chain, copy)
        if chain == "builtin:pillow":
            if self.mode == "godot":
                raise MarketingError("builtin:pillow is a Pillow font: text_renderer 'godot' needs real font files")
            name = "pillow"
        elif self.mode == "godot" or (self.mode == "auto" and reason):
            if not self.godot:
                raise MarketingError(
                    f"{locale} needs Godot's text server ({reason or 'text_renderer: godot'}): pass --godot <console exe> "
                    "(or set MARKETING_GODOT)" + ("" if self.mode == "godot" else
                                                    ", or set text_renderer to 'pillow' (one face, Raqm for shaped scripts)"))
            name = "godot"
        else:
            if isinstance(chain, list) and len(chain) > 1:
                raise MarketingError(f"{locale}: font fallback chains need the Godot renderer (text_renderer auto or godot)")
            shaped = _shaping_reason(copy)
            if shaped and not _has_raqm():
                raise MarketingError(f"{locale}: {shaped} would render unshaped: this Pillow has no Raqm. "
                                     "Use text_renderer 'auto' or 'godot' with --godot")
            name = "pillow"
        self._renderers[locale] = name
        return name

    def block(self, text: str, locale: str, start_size: int, max_width: int, max_height: int, min_size: int = 16,
              keep_scale: float = DEFAULT_STYLE["keep_lines_scale"]) -> Block:
        """`text` set at the largest size from start_size down that fits
        max_width x max_height: the author's lines kept whole while the size
        stays at or above keep_scale x start_size, then re-wrapped from
        start_size down (balanced lines: wrapping is preferred to shrinking)."""
        keep_floor = max(min_size, round(start_size * float(keep_scale)))
        key = (locale, text, start_size, max_width, max_height, min_size, keep_floor)
        if self.trace is not None:
            self.trace.append(key)
        if key in self.done:
            return self.done[key]
        if self.renderer(locale, text) == "pillow":
            reason = needs_godot(self.chain(locale), text)
            if reason and self.mode == "auto":
                raise MarketingError(f"{locale}: {text!r} needs Godot's text server ({reason}), "
                                     "but the locale's other copy was set with Pillow")
            block = self._pillow_block(*key)
            self.done[key] = block
            return block
        if not self.collecting:
            raise MarketingError("Internal: a Godot text block was not collected before rendering")
        self.pending[key] = {"locale": locale}
        return Block(_pil()[0].new("L", (1, 1)), 1, 1)

    def flush(self) -> None:
        """Renders every collected Godot block in one headless run."""
        self.collecting = False
        if not self.pending:
            return
        Image = _pil()[0]
        project = self.work / "godot_text"
        out = project / "out"
        out.mkdir(parents=True, exist_ok=True)
        # A throwaway project: the game's own (with its autoloads) never runs.
        (project / "project.godot").write_text('config_version=5\n\n[application]\n\nconfig/name="marketing_text"\n',
                                               encoding="utf-8")
        for name in GODOT_TEXT_SCRIPTS:
            shutil.copy2(TOOLKIT / "addons" / "marketing_capture" / name, project / name)
        fonts, requests, keys = {}, [], {}
        for k, (key, meta) in enumerate(self.pending.items()):
            locale, text, start, max_w, max_h, min_size, keep_floor = key
            fonts[locale] = [{"path": f["path"].as_posix(), "weight": f["weight"], "width": f["width"]}
                             for f in self.chain(locale)]
            rid = f"b{k}"
            keys[rid] = key
            requests.append({"id": rid, "text": text, "font": locale, "language": locale.replace("-", "_"),
                             "start_size": start, "min_size": min_size, "keep_floor": keep_floor,
                             "max_width": max_w, "max_height": max_h, "out": (out / f"{rid}.png").as_posix()})
        job = project / "job.json"
        report_path = project / "report.json"
        job.write_text(json.dumps({"fonts": fonts, "requests": requests, "report": report_path.as_posix()},
                                  ensure_ascii=False, indent=1), encoding="utf-8")
        run([self.godot, "--headless", "--path", project, "--script", "res://text_renderer.gd", "--",
             f"--job={job.as_posix()}"], log=project / "godot_text.log", show=("MARKETING_TEXT",))
        if not report_path.is_file():
            raise MarketingError(f"Godot's text renderer wrote no report (log: {project / 'godot_text.log'})")
        report = json.loads(report_path.read_text(encoding="utf-8"))
        if not report.get("line_breaking"):
            print("WARNING: this Godot has no ICU line-breaking data: Thai/CJK breaks are not dictionary based")
        errors = []
        for rid, key in keys.items():
            res = report["results"].get(rid, {"ok": False, "error": "no result"})
            if not res.get("ok"):
                errors.append(f"{key[0]} {key[1]!r}: {res.get('error')}")
                continue
            with Image.open(out / f"{rid}.png") as im:
                mask = im.getchannel("A").copy()
            pad = int(res["pad"])
            res["renderer"] = "godot"
            self.done[key] = Block(mask, mask.width - 2 * pad, mask.height - 2 * pad, pad, res)
        self.pending.clear()
        if errors:
            raise MarketingError("Text could not be set:\n  " + "\n  ".join(errors))

    # ---------------------------------------------------------- Pillow

    def _pillow_font(self, chain, size: int):
        """Pillow faces by (chain, size); a variable face at its weight/width."""
        key = (str(chain), size)
        if key in self._pillow_fonts:
            return self._pillow_fonts[key]
        _, _, ImageFont = _pil()
        if chain == "builtin:pillow":
            # Pillow's bundled font: synthetic tests and previews only (Latin).
            font = ImageFont.load_default(size)
        else:
            face = chain[0]
            font = ImageFont.truetype(str(face["path"]), size)
            wanted = {"weight": face.get("weight"), "width": face.get("width")}
            if any(v is not None for v in wanted.values()):
                try:
                    axes = font.get_variation_axes()
                except OSError:
                    axes = []
                values, found = [], set()
                for axis in axes:
                    name = axis["name"].decode() if isinstance(axis["name"], bytes) else str(axis["name"])
                    name = name.lower()
                    if name in wanted and wanted[name] is not None:
                        values.append(float(wanted[name]))
                        found.add(name)
                    else:
                        values.append(axis["default"])
                lacking = [k for k, v in wanted.items() if v is not None and k not in found]
                if lacking:
                    raise MarketingError(f"{face['path'].name} has no {', '.join(lacking)} axis (a static face: choose the file of that weight)")
                font.set_variation_by_axes(values)
        self._pillow_fonts[key] = font
        return font

    def _pillow_missing(self, chain, font, text: str) -> list[str]:
        """Characters the face draws as its missing-glyph box (compared with a
        code point no font maps)."""
        Image, ImageDraw, _ = _pil()

        def picture(c: str) -> tuple:
            box = font.getbbox(c)
            im = Image.new("L", (max(1, box[2] - box[0]), max(1, box[3] - box[1])))
            ImageDraw.Draw(im).text((-box[0], -box[1]), c, font=font, fill=255)
            return box, im.tobytes()

        notdef = picture("\U000FFFFD")
        out = []
        for c in dict.fromkeys(text):
            if c.isspace() or unicodedata.category(c) in ("Cf", "Zs"):
                continue
            key = (str(chain), c)
            if key not in self._missing_cache:
                self._missing_cache[key] = picture(c) == notdef
            if self._missing_cache[key]:
                out.append(f"U+{ord(c):04X} {c}")
        return out

    def _pillow_block(self, locale, text, start_size, max_width, max_height, min_size, keep_floor) -> Block:
        Image, ImageDraw, _ = _pil()
        chain = self.chain(locale)
        shaped = _shaping_reason(text)
        if shaped and not _has_raqm():
            raise MarketingError(f"{locale}: {shaped} would render unshaped: this Pillow has no Raqm")
        missing = self._pillow_missing(chain, self._pillow_font(chain, start_size), text)
        if missing:
            raise MarketingError(f"{locale}: the font has no glyph for {', '.join(missing)} in {text!r}")
        scratch = ImageDraw.Draw(Image.new("L", (1, 1)))
        attempts = [(size, False) for size in range(start_size, keep_floor - 1, -2)] + \
                   [(size, True) for size in range(start_size, min_size - 1, -2)]
        for font_size, wrap in attempts:
            font = self._pillow_font(chain, font_size)
            gap = max(3, round(font_size * 0.17))
            lines = (_balanced_wrap(scratch, text, font, max_width) if wrap else text.splitlines()) or [""]
            boxes = [scratch.textbbox((0, 0), s, font=font) for s in lines]
            height = sum(b[3] - b[1] for b in boxes) + gap * (len(lines) - 1)
            widths = [b[2] - b[0] for b in boxes]
            if height <= max_height and all(w <= max_width for w in widths):
                width = max(widths)
                mask = Image.new("L", (max(1, width), max(1, height)), 0)
                draw = ImageDraw.Draw(mask)
                y = 0
                for s, b in zip(lines, boxes):
                    draw.text(((width - (b[2] - b[0])) // 2 - b[0], y - b[1]), s, font=font, fill=255)
                    y += b[3] - b[1] + gap
                return Block(mask, width, height, 0, {"renderer": "pillow", "font_size": font_size,
                                                      "wrap": "words" if wrap else "authored",
                                                      "lines": [{"text": s} for s in lines]})
        raise MarketingError(f"{locale}: text does not fit {max_width}x{max_height} even at {min_size} px "
                             f"(style.min_text_scale): {text!r}; shorten the copy")


def _clusters(value: str) -> list[str]:
    """Grapheme-like wrap units for Pillow: a base character with its marks
    (any Unicode mark category: Thai vowels and tones above/below are marks
    with combining class 0), joiners, variation selectors, and Indic
    consonants joined by a virama."""
    parts: list[str] = []
    for char in value:
        joins = parts and (unicodedata.category(char) in ("Mn", "Mc", "Me")
                           or char in ("‍", "‌", "︎", "️")
                           or parts[-1][-1] == "‍"
                           or unicodedata.combining(parts[-1][-1]) == 9)  # after a virama
        if joins:
            parts[-1] += char
        else:
            parts.append(char)
    return parts


def _unspaced(word: str) -> bool:
    return any(lo <= ord(c) <= hi for c in word for lo, hi in UNSPACED_SCRIPTS)


def _wrap_text(draw, paragraph: str, font, max_width: int) -> list[str]:
    """Pillow's wrap: at spaces and U+200B (an author's break hint); a long
    token breaks between clusters (CJK, kinsoku kept), except in scripts
    written without spaces (Thai...), which Pillow cannot segment: such a
    line shrinks instead (or use the Godot renderer)."""
    lines: list[str] = []
    current = ""
    for word in paragraph.replace("​", " ").split(" "):
        candidate = (current + " " + word).strip() if current else word
        if draw.textbbox((0, 0), candidate, font=font)[2] <= max_width:
            current = candidate
            continue
        if current:
            lines.append(current)
            current = ""
        if _unspaced(word):
            current = word
            continue
        for group in _clusters(word):
            attempt = current + group
            if current and draw.textbbox((0, 0), attempt, font=font)[2] > max_width:
                if group[0] in NO_LINE_START and len(current) > 1:
                    # Kinsoku: the previous character moves down with it.
                    lines.append(current[:-1])
                    current = current[-1] + group
                else:
                    lines.append(current)
                    current = group
            else:
                current = attempt
    if current:
        lines.append(current)
    return lines


def _balanced_wrap(draw, text: str, font, max_width: int) -> list[str]:
    """Every paragraph wrapped, with lines of even length: the narrowest
    width that still gives the line count of a plain wrap at max_width (no
    orphan word on a last line)."""
    def wrap(width: int) -> list[str]:
        return [line for paragraph in text.splitlines() for line in _wrap_text(draw, paragraph, font, width)]

    lines = wrap(max_width)
    lo, hi = max_width // 3, max_width
    while hi - lo > 2:
        mid = (lo + hi) // 2
        trial = wrap(mid)
        if len(trial) <= len(lines) and all(draw.textbbox((0, 0), s, font=font)[2] <= max_width for s in trial):
            hi = mid
        else:
            lo = mid
    return wrap(hi)


# ================================================================ reading time

# Reading units per character cluster: a Han or Kana character carries about
# two Latin letters' worth of reading, a Hangul syllable about one and a half.
# Everything else (Latin, Cyrillic, Thai, Devanagari clusters, spaces) is 1.
READING_WEIGHTS = ((0x3040, 0x30FF, 2.0), (0x3400, 0x9FFF, 2.0), (0xF900, 0xFAFF, 2.0),
                   (0x1100, 0x11FF, 1.5), (0x3130, 0x318F, 1.5), (0xAC00, 0xD7AF, 1.5))


def reading_units(text: str) -> float:
    """How much reading `text` takes, in Latin-letter units: grapheme
    clusters (a base with its marks counts once), runs of whitespace as one."""
    units = 0.0
    for cluster in _clusters(" ".join(text.split())):
        o = ord(cluster[0])
        units += next((w for lo, hi, w in READING_WEIGHTS if lo <= o <= hi), 1.0)
    return units


def reading_seconds(texts: list[str], style: dict) -> float:
    """The time text must stay fully visible: text_min_hold, or longer when
    its reading units at reading_cps take more (title and subtitle together)."""
    units = sum(reading_units(t) for t in texts if t)
    cps = float(style["reading_cps"])
    if cps <= 0 or float(style["text_min_hold"]) < 0:
        raise MarketingError("style.reading_cps must be positive and style.text_min_hold not negative")
    return max(float(style["text_min_hold"]), units / cps)


# ================================================================ text and images

def _rgba(value: str, alpha: float = 1.0) -> tuple[int, int, int, int]:
    v = value.lstrip("#")
    if len(v) != 6:
        raise MarketingError(f"Colours are #RRGGBB, got {value!r}")
    return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16), round(255 * alpha)


def localized_text(conf: dict, key: str, locale: str) -> str:
    if not key:
        return ""
    value = conf.get("strings", {}).get(locale, {}).get(key)
    if not isinstance(value, str) or not value.strip():
        raise MarketingError(f"Missing marketing translation for {locale!r}, key {key!r}; never silently fall back to English")
    return value


def _paint(out, block: Block, y: int, colour: tuple[int, int, int, int]) -> None:
    """The block's text centred horizontally on `out`, its top at y."""
    Image = _pil()[0]
    alpha = block.mask if colour[3] == 255 else block.mask.point(lambda v: v * colour[3] // 255)
    ink = Image.new("RGBA", block.mask.size, colour[:3] + (0,))
    ink.putalpha(alpha)
    layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
    layer.paste(ink, ((out.width - block.width) // 2 - block.pad, y - block.pad))
    out.alpha_composite(layer)


def _styled_block(engine: TextEngine, style: dict, text: str, locale: str, start: int, max_width: int,
                  max_height: int, min_size: int) -> Block:
    """A block under the style's layout limits: authored lines shrink to
    keep_lines_scale, nothing goes below min_text_scale of the start size."""
    keep, low = float(style["keep_lines_scale"]), float(style["min_text_scale"])
    if not 0 < low <= keep <= 1:
        raise MarketingError("style: 0 < min_text_scale <= keep_lines_scale <= 1")
    return engine.block(text, locale, start, max_width, max_height, max(min_size, round(start * low)), keep)


def text_image(size: tuple[int, int], text: str, position: str, locale: str, engine: TextEngine,
               style: dict | None = None, picture: tuple[int, int] | None = None):
    """A headline over gameplay: centred text on a translucent band. With
    `picture` (the rows (top, bottom) of a black-letterboxed shot's footage),
    the text is set in the black band above (top) or below (bottom) the
    picture, inside the safe area, and never covers the gameplay."""
    Image, ImageDraw, _ = _pil()
    style = style or DEFAULT_STYLE
    width, height = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    if not text:
        return out
    if position not in ("top", "bottom", "center"):
        raise MarketingError("headline position must be top, bottom, or center")
    top, bottom, side = safe_area_px(style, size)
    start, max_width = max(24, round(min(width, height) * 0.065)), min(int(width * 0.88), width - 2 * side)
    if picture:
        if position == "center":
            raise MarketingError("a headline on a black-letterboxed shot sits in a band: position top or bottom, "
                                 "never over the picture")
        lo, hi = (top, picture[0]) if position == "top" else (picture[1], height - bottom)
        gap = max(4, round(height * 0.0125))
        try:
            block = _styled_block(engine, style, text, locale, start, max_width,
                                  min(int(height * 0.27), hi - lo - 2 * gap), 16)
        except MarketingError as exc:
            raise MarketingError(f"{position} headline does not fit the black band {position == 'top' and 'above' or 'below'} "
                                 f"the picture inside the safe area (rows {lo}-{hi}): shorten the copy, move it to the "
                                 f"other band or narrow the reframe. {exc}") from None
        # The band is already black: no translucent strip, the text is centred in it.
        _paint(out, block, lo + (hi - lo - block.height) // 2, _rgba(style["text_color"]))
        return out
    block = _styled_block(engine, style, text, locale, start, max_width, int(height * 0.27), 16)
    pad = max(12, round(height * 0.027))
    y = top + pad if position == "top" else (
        height - bottom - block.height - pad if position == "bottom" else (top + height - bottom - block.height) // 2)
    band_pad = round(height * 0.025)
    ImageDraw.Draw(out).rectangle([0, max(0, y - band_pad), width, min(height, y + block.height + band_pad)],
                                  fill=_rgba(style["band_color"], float(style["band_opacity"])))
    _paint(out, block, y, _rgba(style["text_color"]))
    return out


def card_image(size: tuple[int, int], title: str, subtitle: str, logo: Path | None, locale: str,
               engine: TextEngine, style: dict):
    """A title card's text layer (transparent; the card's colour is drawn under
    it): optional logo, the title, an optional accent rule and subtitle, centred
    inside the safe width."""
    Image, ImageDraw, _ = _pil()
    width, height = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(out)
    unit = min(width, height) / 1080.0
    top, bottom, side = safe_area_px(style, size)
    safe = min(int(width * float(style["card_safe_width"])), width - 2 * side)
    parts = []  # (height, painter)
    if logo:
        with Image.open(logo) as im:
            art = im.convert("RGBA")
        # Sized by its artwork, not its transparent margin (app icons carry a wide one).
        if art.getbbox():
            art = art.crop(art.getbbox())
        k = round(260 * unit) / max(art.size)
        # Pixel art stays crisp when enlarged; a reduction is filtered.
        art = art.resize((round(art.width * k), round(art.height * k)),
                         Image.Resampling.NEAREST if k >= 1 else Image.Resampling.LANCZOS)
        parts.append((art.height, lambda y, a=art: out.alpha_composite(a, ((width - a.width) // 2, y))))
    if title:
        tb = _styled_block(engine, style, title, locale, round(112 * unit), safe, int(height * 0.5), round(40 * unit))
        parts.append((tb.height, lambda y: _paint(out, tb, y, _rgba(style["text_color"]))))
    if subtitle:
        if style.get("accent_color"):
            rule_w, rule_h = round(520 * unit), max(2, round(5 * unit))
            parts.append((rule_h, lambda y: draw.rectangle([(width - rule_w) // 2, y, (width + rule_w) // 2, y + rule_h - 1],
                                                           fill=_rgba(style["accent_color"]))))
        sb = _styled_block(engine, style, subtitle, locale, round(58 * unit), safe, int(height * 0.2), round(24 * unit))
        parts.append((sb.height, lambda y: _paint(out, sb, y, _rgba(style["subtitle_color"]))))
    spacing = round(22 * unit)
    total = sum(h for h, _ in parts) + spacing * max(0, len(parts) - 1)
    y = (top + height - bottom - total) // 2
    for h, paint in parts:
        paint(y)
        y += h + spacing
    return out


def select_locales(requested: list[str]) -> list[str]:
    selected = list(SUPPORTED_LOCALES) if requested == ["all"] else requested
    if len(set(selected)) != len(selected) or any(x not in SUPPORTED_LOCALES for x in selected):
        raise MarketingError("Locales must be unique and within the approved 20. Use --locales all for production.")
    return selected


def screenshot_has_headline(job: dict) -> bool:
    """Store screenshots are language-neutral by default: a master is copied
    byte for byte unless its entry asks for a headline (`headline_key`, or
    `headline: true`), the same rule as a video shot's headline."""
    return bool(job.get("headline", bool(job.get("headline_key"))))


def compose_screenshots(args) -> None:
    manifest = args.manifest.resolve()
    conf = load_manifest(manifest)
    locales = select_locales(args.locales)
    jobs = [j for j in conf.get("screenshots", []) if not args.shot or j["id"] == args.shot]
    # Preflight all copy before creating any files.
    for job in jobs:
        for locale in locales:
            if screenshot_has_headline(job):
                localized_text(conf, job.get("headline_key", ""), locale)
    ensure_output_root(conf, manifest)
    style = style_of(conf)
    Image = _pil()[0]
    with tempfile.TemporaryDirectory(prefix="marketing_text_") as td:
        engine = TextEngine(conf, manifest, getattr(args, "godot", None), Path(td))
        sizes = {}
        for job in jobs:
            raw = source_path(job["raw"], manifest)
            if not raw.is_file():
                raise MarketingError(f"Gameplay master missing: {raw}")
            with Image.open(raw) as im:
                sizes[job["id"]] = im.size
        # Every headline is set (and checked) before any file is written.
        engine.collecting = True
        for job in jobs:
            for locale in locales:
                if screenshot_has_headline(job):
                    text_image(sizes[job["id"]], localized_text(conf, job.get("headline_key", ""), locale),
                               job.get("position", "top"), locale, engine, style)
        engine.flush()
        for job in jobs:
            raw = source_path(job["raw"], manifest)
            for locale in locales:
                out = source_path(job["output"], manifest).with_name(f"{job['id']}_{locale}.png")
                unique_destination(out, args.overwrite)
                if not screenshot_has_headline(job):
                    shutil.copy2(raw, out)
                else:
                    text = localized_text(conf, job.get("headline_key", ""), locale)
                    with Image.open(raw) as im:
                        original = im.convert("RGBA")
                    original.alpha_composite(text_image(original.size, text, job.get("position", "top"), locale,
                                                        engine, style))
                    original.convert("RGB").save(out, "PNG")
                with Image.open(out) as check_im, Image.open(raw) as raw_im:
                    if check_im.size != raw_im.size:
                        raise MarketingError(f"{out} is {check_im.size}, its master {raw_im.size}")
                print("SCREENSHOT:", out, f"(text: {engine.renderer(locale)})" if screenshot_has_headline(job) else "(copy)")


# ================================================================ video plan

def _profile(video: dict) -> tuple[int, int, int]:
    name = video.get("profile", "play_store")
    if name not in PROFILES and name != "custom":
        raise MarketingError(f"Unknown video profile: {name}")
    default = PROFILES.get(name, (0, 0, 0))
    result = (int(video.get("width", default[0])), int(video.get("height", default[1])), int(video.get("fps", default[2])))
    if min(result) <= 0 or result[2] > 120:
        raise MarketingError("Invalid video width/height/fps")
    return result


def _frames(value: float, fps: int, what: str, allow_zero: bool = False) -> int:
    n = round(value * fps)
    if abs(n / fps - value) > 0.00002 or n < 0 or (n == 0 and not allow_zero):
        raise MarketingError(f"{what} ({value}) must be a {'non-negative' if allow_zero else 'positive'} whole number of frames at {fps} fps")
    return n


def videos_of(conf: dict) -> list[dict]:
    videos = conf.get("videos")
    if videos is None:
        videos = [dict(conf["video"], id=conf["video"].get("id", "video"))] if conf.get("video") else []
    ids = [v.get("id") for v in videos]
    if any(not i for i in ids) or len(set(ids)) != len(ids):
        raise MarketingError("Every video needs a unique id")
    return videos


def shot_texts(conf: dict, shot: dict, locale: str) -> list[str]:
    """The copy a shot shows in this locale: a clip's headline, or a card's
    title and subtitle."""
    title = localized_text(conf, shot.get("headline_key", ""), locale) \
        if shot.get("headline", bool(shot.get("headline_key"))) else ""
    subtitle = localized_text(conf, shot.get("subtitle_key", ""), locale) \
        if shot.get("kind") == "card" and shot.get("subtitle_key") else ""
    return [t for t in (title, subtitle) if t]


def _share(total: int, bounds: list[tuple[int, int]]) -> list[int]:
    """`total` frames split as evenly as the (min, max) bounds allow: each
    gets one common level clamped to its bounds (the caller has checked
    sum(min) <= total <= sum(max)); leftover frames go to the first clips
    still free to grow."""
    def at(level: int) -> list[int]:
        return [min(max(level, lo), hi) for lo, hi in bounds]

    a, b = 0, max(max(lo for lo, _ in bounds), total)
    while a < b:  # the highest level that does not exceed total
        mid = (a + b + 1) // 2
        a, b = (mid, b) if sum(at(mid)) <= total else (a, mid - 1)
    out, rest = at(a), total - sum(at(a))
    for j, (lo, hi) in enumerate(bounds):
        if rest and lo <= a < hi:
            out[j] += 1
            rest -= 1
    if rest:
        raise MarketingError("Internal: fill clips could not share the time")
    return out


def plan_video(video: dict, fps: int, style: dict, texts: list[list[str]] | None = None,
               footage: dict[int, float] | None = None, locale: str = "") -> dict:
    """Timing in whole frames, for one locale: each shot's length, the
    transition that opens it (overlapping the previous shot), its start in the
    output, and the windows in which its text is fully faded in. Transitions
    overlap their two shots, so total = sum(shots) - sum(transitions).

    A shot's duration is seconds, "auto" (a card: its transitions, text fades
    and its text's reading time) or "fill" (a clip: the time target_duration
    leaves, shared between the fill clips, each at least its min_duration and
    its own text's reading time, at most its footage after `start`).
    `texts[i]` is the copy shot i shows (shot_texts()); every text must stay
    fully visible, fades excluded, for its reading_seconds()."""
    shots = video.get("shots") or []
    where = f"{locale + ': ' if locale else ''}video {video.get('id')}"
    if not shots:
        raise MarketingError(f"{where} has no shots")
    texts = texts if texts is not None else [[] for _ in shots]
    # Cosmetic: rounded to whole frames (0.25 s is 7.5 frames at 30 fps).
    text_fade = max(0, round(float(style["text_fade"]) * fps))
    fade = max(1, text_fade)  # as _alpha_fade renders it
    kinds, trans = [], []
    for i, shot in enumerate(shots):
        if shot.get("kind") not in ("clip", "card"):
            raise MarketingError(f"Unknown shot kind {shot.get('kind')!r}")
        tr = dict(shot.get("transition_in") or {})
        if i == 0:
            if tr and tr.get("type", "cut") != "cut":
                raise MarketingError("The first shot has no transition in: use video.fade_in for a fade from black")
            kinds.append("cut"); trans.append(0)
            continue
        if not tr and (shot["kind"] == "card" or shots[i - 1]["kind"] == "card"):
            tr = {"type": "fade", "duration": 0.4}
        t = tr.get("type", "cut")
        if t not in TRANSITIONS:
            raise MarketingError(f"Invalid transition {t!r} (use {', '.join(TRANSITIONS)})")
        d = 0 if t == "cut" else _frames(float(tr.get("duration", 0.4)), fps, f"shot {shot.get('id')} transition")
        kinds.append(t if d else "cut"); trans.append(d)
    fade_in = _frames(float(video.get("fade_in", 0)), fps, "fade_in", allow_zero=True)
    fade_out = _frames(float(video.get("fade_out", 0)), fps, "fade_out", allow_zero=True)
    last = len(shots) - 1

    def lead(i: int) -> int:
        """Frames before shot i's text is fully visible: its transition in, the text's fade."""
        return (trans[i] if i else fade_in) + fade

    def tail(i: int) -> int:
        """Frames after its text's last fully visible moment: the text's fade
        and the next transition; the last shot's text stays up through the
        video's fade_out, and a cut takes the text with it."""
        if i < last:
            return trans[i + 1] + fade if trans[i + 1] else 0
        return fade_out

    # Reading time per shot with text, in whole frames.
    need: list[int | None] = []
    reading: list[dict | None] = []
    for i, shot in enumerate(shots):
        if not texts[i]:
            need.append(None); reading.append(None)
            continue
        shot_style = dict(style, **{k: shot[k] for k in ("text_min_hold", "reading_cps") if k in shot})
        seconds = reading_seconds(texts[i], shot_style)
        need.append(math.ceil(seconds * fps - 1e-6))
        reading.append({"units": round(sum(reading_units(t) for t in texts[i]), 1),
                        "reading_cps": float(shot_style["reading_cps"]),
                        "text_min_hold": float(shot_style["text_min_hold"])})
    lengths, fills = [], []
    for i, shot in enumerate(shots):
        d = shot.get("duration")
        if d == "auto":
            if shot["kind"] != "card":
                raise MarketingError(f"Shot {shot.get('id')}: only a card's duration may be \"auto\" (a clip may \"fill\")")
            hold = need[i] if need[i] is not None else math.ceil(float(style["text_min_hold"]) * fps - 1e-6)
            lengths.append(lead(i) + hold + tail(i))
        elif d == "fill":
            if shot["kind"] != "clip":
                raise MarketingError(f"Shot {shot.get('id')}: only a clip's duration may be \"fill\" (a card may be \"auto\")")
            lengths.append(0); fills.append(i)
        elif isinstance(d, (int, float)) and not isinstance(d, bool):
            lengths.append(_frames(float(d), fps, f"shot {shot.get('id')} duration"))
        else:
            raise MarketingError(f"Shot {shot.get('id')}: duration must be seconds, \"auto\" (card) or \"fill\" (clip)")
    if fills:
        if video.get("target_duration") is None:
            raise MarketingError(f"{where}: \"fill\" clips need the video's target_duration")
        free = _frames(float(video["target_duration"]), fps, "target_duration") + sum(trans) - sum(lengths)
        bounds = []
        for i in fills:
            lo = max(_frames(float(shots[i].get("min_duration", 1.0)), fps, f"shot {shots[i].get('id')} min_duration"),
                     lead(i) + tail(i) + 1)
            if need[i] is not None:
                lo = max(lo, lead(i) + need[i] + tail(i))
            hi = math.floor(footage[i] * fps + 1e-6) if footage and i in footage else 10 ** 9
            bounds.append((lo, hi))
        if free < sum(b[0] for b in bounds):
            raise MarketingError(
                f"{where}: target_duration leaves {free / fps:.2f}s for the \"fill\" clips, they need "
                f"{sum(b[0] for b in bounds) / fps:.2f}s (min_duration and their headlines' reading time): "
                "drop a title card, shorten its copy, or lengthen target_duration (text is never made unreadable)")
        if free > sum(b[1] for b in bounds):
            raise MarketingError(
                f"{where}: the \"fill\" clips must cover {free / fps:.2f}s, their footage gives "
                f"{sum(b[1] for b in bounds) / fps:.2f}s after its in-points: record longer clips, "
                "add a shot, or shorten target_duration")
        for i, n in zip(fills, _share(free, bounds)):
            lengths[i] = n
    starts, text_windows, holds = [], [], []
    for i, n in enumerate(lengths):
        starts.append(0 if i == 0 else starts[i - 1] + lengths[i - 1] - trans[i])
        t_in = trans[i] if i else fade_in
        # The last shot's text stays up through the video's own fade_out.
        t_out = trans[i + 1] if i < last else 0
        if t_in + (t_out or (fade_out if i == last else 0)) >= n:
            raise MarketingError(f"Shot {shots[i].get('id')} is too short for its transitions")
        if i < last and trans[i + 1] >= lengths[i + 1]:
            raise MarketingError(f"Transition exceeds the duration of shot {shots[i + 1].get('id')}")
        # Text on black appears only once the picture is black, and is gone
        # before the next transition starts: fades to and from black never show
        # text popping or the next scene through the words.
        text_windows.append((t_in, n - t_out, text_fade))
        if need[i] is None:
            continue
        hold = n - tail(i) - lead(i)
        holds.append({"index": i, "shot": shots[i].get("id"), "kind": shots[i]["kind"], "required_frames": need[i],
                      "required_s": round(need[i] / fps, 3), "planned_s": round(hold / fps, 3), **reading[i]})
        if hold < need[i]:
            fix = (f"make its duration \"auto\" (here {(lead(i) + need[i] + tail(i)) / fps:.2f}s)"
                   if shots[i]["kind"] == "card" else
                   f"lengthen the clip to {(lead(i) + need[i] + tail(i)) / fps:.2f}s or let it \"fill\"")
            raise MarketingError(
                f"{where}: {shots[i]['kind']} {shots[i].get('id')}: its text would be readable for {hold / fps:.2f}s, "
                f"it needs {need[i] / fps:.2f}s ({reading[i]['units']:g} reading units at {reading[i]['reading_cps']:g}/s, "
                f"at least text_min_hold {reading[i]['text_min_hold']:g}s, fades excluded): {fix}, shorten the copy, "
                "or drop a title card")
    total = starts[-1] + lengths[-1]
    if fade_in + fade_out >= total:
        raise MarketingError("fade_in + fade_out exceed the video")
    expected = total / fps
    target = float(video.get("target_duration", expected))
    if abs(target - expected) > 1.01 / fps:
        raise MarketingError(f"Storyboard timing mismatch in {where}: shots and transitions give {expected:.3f}s, "
                             f"target {target:.3f}s (a \"fill\" clip takes up the difference)")
    return {"shots": shots, "lengths": lengths, "kinds": kinds, "trans": trans, "starts": starts,
            "text": text_windows, "holds": holds, "fade_in": fade_in, "fade_out": fade_out, "total": total, "fps": fps}


# ================================================================ video segments

# A linear dip through black for xfade (P runs 1 -> 0): picture A down to
# black over the first half, black up to picture B over the second, with
# limited-range YUV black (16, 128, 128). FFmpeg's own 'fadeblack' is not
# usable: it drops to black within two frames and then fades in slowly.
DIP_EXPR = (r"if(eq(PLANE\,0)\,16\,128)+(if(gt(P\,0.5)\,A\,B)-if(eq(PLANE\,0)\,16\,128))"
            r"*if(gt(P\,0.5)\,2*P-1\,1-2*P)")


def _xfade(plan: dict, i: int) -> str:
    """'fade' goes through black: next to a card (whose edge is black because
    its text is held back) a plain blend does it; between two clips, the
    picture dips to black. 'crossfade' blends the two pictures directly."""
    shots = plan["shots"]
    if plan["kinds"][i] == "crossfade" or "card" in (shots[i]["kind"], shots[i - 1]["kind"]):
        return "transition=fade"
    return f"transition=custom:expr='{DIP_EXPR}'"


def _alpha_fade(window: tuple[int, int, int], fps: int, n: int) -> str:
    """Filters fading an RGBA overlay in at the window's start and out at its end."""
    start, end, fade = window
    fade = max(1, fade)  # text_fade 0: the text switches within one frame, still only on black
    parts = [f"fade=t=in:st={start / fps:.6f}:d={fade / fps:.6f}:alpha=1"]
    if end < n:
        parts.append(f"fade=t=out:st={(end - fade) / fps:.6f}:d={fade / fps:.6f}:alpha=1")
    return ",".join(parts)


def _shot_overlay(plan: dict, i: int, conf: dict, manifest: Path, locale: str, size: tuple[int, int], style: dict,
                  engine: TextEngine):
    """A shot's text layer (headline band or card text), or None."""
    shot = plan["shots"][i]
    title = localized_text(conf, shot.get("headline_key", ""), locale) if shot.get("headline", bool(shot.get("headline_key"))) else ""
    subtitle = localized_text(conf, shot.get("subtitle_key", ""), locale) if shot.get("subtitle_key") else ""
    if shot["kind"] == "card" and (title or subtitle or shot.get("image")):
        logo = source_path(shot["image"], manifest) if shot.get("image") else None
        return card_image(size, title, subtitle, logo, locale, engine, style)
    if title:
        return text_image(size, title, shot.get("position", "top"), locale, engine, style,
                          letterbox_picture(shot, manifest, size))
    return None


def letterbox_picture(shot: dict, manifest: Path, size: tuple[int, int]) -> tuple[int, int] | None:
    """The rows (top, bottom) a clip's footage covers when its reframe is
    letterboxed with black (e.g. the whole landscape frame in a 9:16 video),
    else None (no reframe, a blur fill, or a window at the video's aspect)."""
    reframe = shot.get("reframe")
    if shot.get("kind") != "clip" or not reframe or reframe.get("fill", "blur") != "black":
        return None
    top, rows = reframe_picture(reframe, _video_size(source_path(shot["source"], manifest)), size)
    return None if rows >= size[1] else (top, top + rows)


@functools.lru_cache(maxsize=None)
def _video_size(path: Path) -> tuple[int, int]:
    stream = next((s for s in probe(path).get("streams", []) if s.get("codec_type") == "video"), None)
    if not stream:
        raise MarketingError(f"Clip has no video stream: {path}")
    return int(stream["width"]), int(stream["height"])


def _even(value: float) -> int:
    return max(2, int(round(value / 2)) * 2)


def reframe_window(reframe: dict, source: tuple[int, int], size: tuple[int, int]) -> tuple[int, int, int, int]:
    """The source window (w, h, x, y) a reframed clip shows, e.g. landscape
    footage in a 9:16 video. `x`/`y` (0-1, default 0.5) centre it on the
    action; `width` (share of the source width) sets how much it shows: by
    default the widest window at the video's aspect ratio (a full-height crop,
    no fill). A wider window keeps the full height and is letterboxed with
    `fill` ("blur": a blurred, darkened copy of the same footage; "black")."""
    if not isinstance(reframe, dict) or set(reframe) - {"x", "y", "width", "fill"}:
        raise MarketingError("reframe: an object with x, y, width, fill")
    if reframe.get("fill", "blur") not in REFRAME_FILLS:
        raise MarketingError(f"reframe.fill must be one of {', '.join(REFRAME_FILLS)}")
    (sw, sh), (w, h) = source, size
    x, y = float(reframe.get("x", 0.5)), float(reframe.get("y", 0.5))
    if not (0 <= x <= 1 and 0 <= y <= 1):
        raise MarketingError("reframe.x and reframe.y are shares of the source (0 to 1)")
    full = min(sw, sh * w / h)
    if reframe.get("width") is None:
        cw = full
    else:
        share = float(reframe["width"])
        if not 0 < share <= 1:
            raise MarketingError("reframe.width is a share of the source width (above 0, at most 1)")
        cw = share * sw
    cw = min(_even(cw), sw - sw % 2)
    ch = min(_even(cw * h / w), sh - sh % 2)
    cx = min(max(0, round(x * sw - cw / 2)), sw - cw)
    cy = min(max(0, round(y * sh - ch / 2)), sh - ch)
    return cw, ch, cx, cy


def reframe_picture(reframe: dict, source: tuple[int, int], size: tuple[int, int]) -> tuple[int, int]:
    """(top row, rows) the reframed footage covers in the video: (0, height)
    when the window has the video's aspect, else centred with fill above and below."""
    width, height = size
    cw, ch, _, _ = reframe_window(reframe, source, size)
    fh = min(height, _even(ch * width / cw))
    return (0, height) if fh >= height - 2 else ((height - fh) // 2, fh)


def _clip_frames(shot: dict, source: tuple[int, int], size: tuple[int, int], fps: int) -> str:
    """Filters from the clip's input [0:v] to [frame] at the video's size."""
    width, height = size
    reframe = shot.get("reframe")
    if not reframe:
        return f"[0:v]fps={fps},scale={width}:{height}:flags=lanczos:out_range=tv[frame]"
    cw, ch, cx, cy = reframe_window(reframe, source, size)
    top, fh = reframe_picture(reframe, source, size)
    fg = f"crop={cw}:{ch}:{cx}:{cy},scale={width}:{fh}:flags=lanczos:out_range=tv"
    if fh == height:  # the window has the video's aspect ratio: no fill
        return f"[0:v]fps={fps},crop={cw}:{ch}:{cx}:{cy},scale={width}:{height}:flags=lanczos:out_range=tv[frame]"
    if reframe.get("fill", "blur") == "black":
        return f"[0:v]fps={fps},{fg},pad={width}:{height}:0:{top}:black[frame]"
    # Blur fill: the same moment, widest aspect-correct window around the same
    # centre, blurred small and darkened so the sharp picture reads as the subject.
    bw, bh, bx, by = reframe_window({"x": reframe.get("x", 0.5), "y": reframe.get("y", 0.5)}, source, size)
    return (f"[0:v]fps={fps},split=2[fgsrc][bgsrc];"
            f"[bgsrc]crop={bw}:{bh}:{bx}:{by},scale={max(2, width // 8)}:{max(2, height // 8)},gblur=sigma=3,"
            f"scale={width}:{height}:flags=bicubic:out_range=tv,eq=brightness=-0.12:saturation=0.85[bg];"
            f"[fgsrc]{fg}[fg];[bg][fg]overlay=0:{top}[frame]")


def _encode_segment(plan: dict, i: int, conf: dict, manifest: Path, locale: str, folder: Path,
                    size: tuple[int, int], style: dict, engine: TextEngine) -> Path:
    shot, n, fps = plan["shots"][i], plan["lengths"][i], plan["fps"]
    seconds = n / fps
    segment = folder / f"seg_{i:02d}_{locale}.mp4"
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    if shot["kind"] == "clip":
        file = source_path(shot["source"], manifest)
        if not file.is_file():
            raise MarketingError(f"Recorded footage missing for {shot['id']}: {file}")
        inf = probe(file)
        streams = [s for s in inf.get("streams", []) if s.get("codec_type") == "video"]
        if not streams:
            raise MarketingError(f"Clip has no video stream: {file}")
        w, h = int(streams[0]["width"]), int(streams[0]["height"])
        if abs(w / h - size[0] / size[1]) > 0.02 and not shot.get("reframe"):
            raise MarketingError(f"Clip {file} has wrong aspect ratio ({w}x{h}) for {size[0]}x{size[1]}: re-record "
                                 "in the target aspect, or give the shot an explicit \"reframe\" (a reviewed crop "
                                 "window on the action); footage is never stretched or cropped implicitly.")
        start = float(shot.get("start", 0))
        available = float(inf.get("format", {}).get("duration") or 0) - start
        if available < seconds - 1.2 / fps:
            raise MarketingError(f"Clip {file} has {available:.3f}s after its start {start}s, the shot needs {seconds:.3f}s")
        cmd += ["-ss", f"{start:.6f}", "-t", f"{seconds + 2 / fps:.6f}", "-i", str(file)]
        # tpad: a recording that ends a frame early still fills the shot exactly.
        base = (_clip_frames(shot, (w, h), size, fps) + ";[frame]setsar=1,tpad=stop_mode=clone:stop=3,"
                f"trim=end_frame={n},setpts=PTS-STARTPTS[base]")
    else:
        cmd += ["-f", "lavfi", "-i", f"color=c={style['card_color'].replace('#', '0x')}:s={size[0]}x{size[1]}:r={fps}:d={seconds:.6f}"]
        base = f"[0:v]tpad=stop_mode=clone:stop=3,trim=end_frame={n},setpts=PTS-STARTPTS,setsar=1[base]"
    overlay = _shot_overlay(plan, i, conf, manifest, locale, size, style, engine)
    if overlay is not None:
        png = folder / f"seg_{i:02d}_{locale}.png"
        overlay.save(png)
        cmd += ["-loop", "1", "-framerate", str(fps), "-t", f"{seconds:.6f}", "-i", str(png)]
        filt = (base + f";[1:v]format=rgba,{_alpha_fade(plan['text'][i], fps, n)}[ov]"
                ";[base][ov]overlay=0:0:shortest=1:format=auto,format=yuv420p[v]")
    else:
        filt = base + ";[base]format=yuv420p[v]"
    # Lossless intermediate: only the final encode is lossy.
    cmd += ["-filter_complex", filt, "-map", "[v]", "-an", "-frames:v", str(n), "-r", str(fps),
            "-c:v", "libx264", "-preset", "ultrafast", "-qp", "0", "-pix_fmt", "yuv420p", str(segment)]
    run(cmd)
    return segment


def _game_audio(plan: dict, manifest: Path, folder: Path) -> Path:
    """The clips' own recorded audio (Movie Maker's game mix), silence under
    cards, crossfaded with the same overlaps as the pictures."""
    fps = plan["fps"]
    parts = []
    for i, shot in enumerate(plan["shots"]):
        seconds = plan["lengths"][i] / fps
        wav = folder / f"aud_{i:02d}.wav"
        source = source_path(shot["source"], manifest) if shot["kind"] == "clip" and shot.get("audio", "game") == "game" else None
        has_audio = source is not None and any(s.get("codec_type") == "audio" for s in probe(source).get("streams", []))
        if has_audio:
            cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", f"{float(shot.get('start', 0)):.6f}",
                   "-t", f"{seconds:.6f}", "-i", str(source), "-vn", "-af",
                   f"aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,apad,atrim=duration={seconds:.6f}"]
        else:
            cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i",
                   "anullsrc=r=48000:cl=stereo", "-t", f"{seconds:.6f}"]
        run(cmd + ["-ar", "48000", "-ac", "2", "-c:a", "pcm_s16le", str(wav)])
        parts.append(wav)
    out = folder / "game_audio.wav"
    if len(parts) == 1:
        shutil.copy2(parts[0], out)
        return out
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    for p in parts:
        cmd += ["-i", str(p)]
    ops, active = [], "0:a"
    for i in range(1, len(parts)):
        nxt = f"a{i}"
        if plan["trans"][i]:
            ops.append(f"[{active}][{i}:a]acrossfade=d={plan['trans'][i] / fps:.6f}:c1=tri:c2=tri[{nxt}]")
        else:
            ops.append(f"[{active}][{i}:a]concat=n=2:v=0:a=1[{nxt}]")
        active = nxt
    run(cmd + ["-filter_complex", ";".join(ops), "-map", f"[{active}]", "-c:a", "pcm_s16le", str(out)])
    return out


def compose_video(args) -> None:
    assert_tool("ffmpeg"); assert_tool("ffprobe")
    manifest = args.manifest.resolve()
    conf = load_manifest(manifest)
    videos = [v for v in videos_of(conf) if not getattr(args, "video_id", None) or v["id"] == args.video_id]
    if not videos:
        raise MarketingError("No video matches")
    locales = select_locales(args.locales)
    with tempfile.TemporaryDirectory(prefix="marketing_text_") as td:
        _compose_videos(args, conf, manifest, videos, locales,
                        TextEngine(conf, manifest, getattr(args, "godot", None), Path(td)))


def _footage(video: dict, manifest: Path) -> dict[int, float]:
    """Seconds of recorded footage after each clip's in-point (by shot index)."""
    out, lengths = {}, {}
    for i, shot in enumerate(video.get("shots") or []):
        if shot.get("kind") != "clip":
            continue
        if not shot.get("source"):
            raise MarketingError(f"Clip {shot.get('id')} has no source")
        file = source_path(shot["source"], manifest)
        if not file.is_file():
            raise MarketingError(f"Recorded footage missing for {shot.get('id')}: {file}")
        if file not in lengths:
            lengths[file] = float(probe(file).get("format", {}).get("duration") or 0)
        out[i] = lengths[file] - float(shot.get("start", 0))
    return out


def _compose_videos(args, conf: dict, manifest: Path, videos: list[dict], locales: list[str], engine: TextEngine) -> None:
    plans = []
    engine.collecting = True
    for video in videos:  # preflight everything before writing anything
        width, height, fps = _profile(video)
        style = style_of(conf, video)
        base_dest = source_path(video["output"], manifest)
        if base_dest.suffix.lower() != ".mp4":
            raise MarketingError("video output must be .mp4")
        footage = _footage(video, manifest)
        for shot in video.get("shots") or []:
            if shot.get("kind") == "clip" and shot.get("reframe"):
                stream = next(s for s in probe(source_path(shot["source"], manifest))["streams"] if s.get("codec_type") == "video")
                reframe_window(shot["reframe"], (int(stream["width"]), int(stream["height"])), (width, height))
        # One plan per locale: its copy sets each text's reading time, so cards
        # and "fill" clips may differ by locale; the total never does.
        by_locale = {locale: plan_video(video, fps, style, [shot_texts(conf, s, locale) for s in video.get("shots") or []],
                                        footage, locale) for locale in locales}
        music = args.music or video.get("music")
        music_path = source_path(str(music), manifest) if music else None
        if music_path and not music_path.is_file():
            raise MarketingError(f"Music file missing: {music_path}")
        quality = quality_of(conf, video, getattr(args, "quality", None))
        # Every text layer is set (and its glyphs checked) before any file is written.
        for locale, plan in by_locale.items():
            for i in range(len(plan["shots"])):
                _shot_overlay(plan, i, conf, manifest, locale, (width, height), style, engine)
        plans.append((video, (width, height), fps, style, by_locale, base_dest, music_path, quality))
    engine.flush()
    ensure_output_root(conf, manifest)
    for item in plans:
        _render_video(args, conf, manifest, locales, engine, *item)


def quality_of(conf: dict, video: dict, requested: str | None) -> dict:
    """The final encode's preset: --quality, else the video's or the
    manifest's "quality", else 'high'. The manifest's "quality_presets" may
    change a preset's crf / x264_preset or add one."""
    presets = {k: dict(v) for k, v in QUALITY_PRESETS.items()}
    for name, values in conf.get("quality_presets", {}).items():
        if not isinstance(values, dict) or set(values) - {"crf", "x264_preset"}:
            raise MarketingError(f"quality_presets.{name}: only crf and x264_preset")
        presets.setdefault(name, dict(QUALITY_PRESETS[DEFAULT_QUALITY])).update(values)
    name = requested or video.get("quality") or conf.get("quality") or DEFAULT_QUALITY
    if name not in presets:
        raise MarketingError(f"Unknown quality {name!r}: {', '.join(presets)}")
    preset = presets[name]
    crf = preset["crf"]
    if isinstance(crf, bool) or not isinstance(crf, (int, float)) or not 0 <= crf <= 51 \
            or preset["x264_preset"] not in X264_PRESETS:
        raise MarketingError(f"Quality {name}: crf 0-51 and an x264 preset ({', '.join(X264_PRESETS)})")
    return {"name": name, "crf": crf, "x264_preset": preset["x264_preset"]}


def output_name(base_dest: Path, locale: str, quality: dict) -> Path:
    """<stem>_<locale>.mp4 at the default (final) quality, else
    <stem>_<locale>_<quality>.mp4: a preview never replaces a final."""
    suffix = "" if quality["name"] == DEFAULT_QUALITY else f"_{quality['name']}"
    return base_dest.with_name(f"{base_dest.stem}_{locale}{suffix}.mp4")


def _render_video(args, conf: dict, manifest: Path, locales: list[str], engine: TextEngine, video: dict,
                  size: tuple[int, int], fps: int, style: dict, plans: dict[str, dict], base_dest: Path,
                  music_path: Path | None, quality: dict) -> None:
    game_audio = bool(video.get("game_audio", False))
    with tempfile.TemporaryDirectory(prefix="marketing_compose_") as td:
        work = Path(td)
        # The clips' sound follows each plan's timing (locales may differ).
        game_wavs: dict[tuple, Path] = {}
        for locale in locales:
            plan = plans[locale]
            total = plan["total"] / fps
            timing = (tuple(plan["lengths"]), tuple(plan["trans"]))
            if game_audio and timing not in game_wavs:
                folder = work / f"audio_{len(game_wavs)}"
                folder.mkdir()
                game_wavs[timing] = _game_audio(plan, manifest, folder)
            game_wav = game_wavs.get(timing)
            final = output_name(base_dest, locale, quality)
            unique_destination(final, args.overwrite)
            segments = [_encode_segment(plan, i, conf, manifest, locale, work, size, style, engine)
                        for i in range(len(plan["shots"]))]
            cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
            for p in segments:
                cmd += ["-i", str(p)]
            # One timebase for every input: xfade refuses mismatched links.
            ops = [f"[{i}:v]fps={fps},settb=1/{fps},setpts=PTS-STARTPTS,format=yuv420p[in{i}]" for i in range(len(segments))]
            active = "in0"
            for i in range(1, len(segments)):
                nxt = f"v{i}"
                if plan["trans"][i]:
                    ops.append(f"[{active}][in{i}]xfade={_xfade(plan, i)}:duration={plan['trans'][i] / fps:.6f}"
                               f":offset={plan['starts'][i] / fps:.6f}[{nxt}]")
                else:
                    # concat outputs a 1/1000000 timebase; a later xfade (a cut
                    # before a fade) refuses it unless it is set back to 1/fps.
                    ops.append(f"[{active}][in{i}]concat=n=2:v=1:a=0,settb=1/{fps}[{nxt}]")
                active = nxt
            edge = []
            if plan["fade_in"]:
                edge.append(f"fade=t=in:st=0:d={plan['fade_in'] / fps:.6f}")
            if plan["fade_out"]:
                edge.append(f"fade=t=out:st={(plan['total'] - plan['fade_out']) / fps:.6f}:d={plan['fade_out'] / fps:.6f}")
            # Delivery is standard limited-range 4:2:0 (Movie Maker's MJPEG is full range).
            ops.append(f"[{active}]{','.join(edge + ['scale=out_range=tv', 'format=yuv420p'])}[vout]")
            audio_inputs = []
            if game_wav:
                cmd += ["-i", str(game_wav)]
                audio_inputs.append((len(segments) + len(audio_inputs), float(video.get("game_volume", 1.0)), None))
            if music_path:
                # music_start: an in-point into the track (a fuller section than its intro).
                cmd += ["-stream_loop", "-1", "-ss", f"{float(video.get('music_start', 0)):.6f}", "-i", str(music_path)]
                audio_inputs.append((len(segments) + len(audio_inputs), float(video.get("music_volume", 1.0)), "music"))
            if audio_inputs:
                labels = []
                for idx, volume, role in audio_inputs:
                    chain = f"[{idx}:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,atrim=duration={total:.6f},asetpts=PTS-STARTPTS,volume={volume}"
                    if role == "music":
                        fade_in = float(video.get("music_fade_in", 0))
                        fade_out = float(video.get("music_fade_out", max(0.35, plan["fade_out"] / fps)))
                        if fade_in:
                            chain += f",afade=t=in:st=0:d={fade_in:.6f}"
                        chain += f",afade=t=out:st={total - fade_out:.6f}:d={fade_out:.6f}"
                    ops.append(chain + f"[m{idx}]")
                    labels.append(f"[m{idx}]")
                mix = f"{''.join(labels)}amix=inputs={len(labels)}:duration=longest:normalize=0," if len(labels) > 1 else f"{labels[0]}"
                ops.append(f"{mix}alimiter=limit=0.89:level=false,apad,atrim=duration={total:.6f}[aout]")
            cmd += ["-filter_complex", ";".join(ops), "-map", "[vout]"]
            if audio_inputs:
                cmd += ["-map", "[aout]", "-c:a", "aac", "-b:a", "192k", "-ar", "48000"]
            cmd += ["-c:v", "libx264", "-preset", quality["x264_preset"], "-crf", str(quality["crf"]),
                    "-pix_fmt", "yuv420p", "-color_range", "tv", "-r", str(fps),
                    "-frames:v", str(plan["total"]), "-movflags", "+faststart", str(final)]
            run(cmd)
            verify_video_file(final, size[0], size[1], fps, total, bool(audio_inputs))
            report = review(final, plan, size, bool(audio_inputs),
                            {"quality": quality, "text_renderer": engine.renderer(locale)})
            print(f"VIDEO OK: {final} ({total:.3f} s, {size[0]}x{size[1]}, {fps} fps, "
                  f"{quality['name']}: crf {quality['crf']}, {quality['x264_preset']}); "
                  f"transitions {report['transitions_ok']}/{len(report['transitions'])} smooth; text readable long enough "
                  f"{report['text_holds_ok']}/{len(report['text_holds'])}; review: {report['sheet']}")


# ================================================================ verification

def verify_video_file(path: Path, width: int, height: int, fps: int, seconds: float, needs_audio: bool) -> None:
    inf = probe(path)
    streams = inf.get("streams", [])
    videos = [s for s in streams if s.get("codec_type") == "video"]
    audios = [s for s in streams if s.get("codec_type") == "audio"]
    if len(videos) != 1:
        raise MarketingError("Expected one video stream")
    v = videos[0]
    if (v["codec_name"], v["pix_fmt"], int(v["width"]), int(v["height"])) != ("h264", "yuv420p", width, height):
        raise MarketingError(f"Wrong codec/pixel format/resolution: {v['codec_name']} {v['pix_fmt']} {v['width']}x{v['height']}")
    a, b = map(int, v.get("avg_frame_rate", "0/1").split("/"))
    if b == 0 or abs(a / b - fps) > 0.01:
        raise MarketingError(f"Wrong video FPS: {v.get('avg_frame_rate')}, expected {fps}")
    count = v.get("nb_frames")
    if count and count != "N/A" and abs(int(count) - round(seconds * fps)) > 1:
        raise MarketingError(f"MP4 frame count {count}, expected {round(seconds * fps)}")
    dur = float(inf.get("format", {}).get("duration") or 0)
    if abs(dur - seconds) > max(0.12, 2.5 / fps):
        raise MarketingError(f"Wrong duration: {dur}, expected {seconds}")
    if needs_audio:
        if not audios:
            raise MarketingError("Audio requested but the output has none")
        adur = float(audios[0].get("duration") or dur)
        if abs(adur - seconds) > 0.1:
            raise MarketingError(f"Audio lasts {adur:.3f}s, the video {seconds:.3f}s")
    if path.stat().st_size < 500:
        raise MarketingError("Output is unexpectedly small")


def luma_series(path: Path) -> list[tuple[float, int]]:
    """(mean, max) full-range grey level (black 0, white 255) of every frame,
    from a 64x36 average of its luma plane. The Y plane is read as is and
    expanded from limited range here: swscale's YUV-to-grey conversion during
    a large downscale is biased at dark levels and not consistent from frame
    to frame (a smooth fade on a dark card measured as a one-frame jump)."""
    w, h = 64, 36
    stream = next((s for s in probe(path).get("streams", []) if s.get("codec_type") == "video"), {})
    full = stream.get("color_range") == "pc" or str(stream.get("pix_fmt", "")).startswith("yuvj")
    p = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path), "-vf",
                        f"extractplanes=y,scale={w}:{h}:flags=area", "-pix_fmt", "gray", "-f", "rawvideo", "-"],
                       capture_output=True)
    if p.returncode:
        raise MarketingError(f"Could not decode {path}")
    levels = bytes(range(256)) if full else bytes(min(255, max(0, round((v - 16) * 255 / 219))) for v in range(256))
    data, size = p.stdout.translate(levels), w * h
    return [(sum(data[k:k + size]) / size, max(data[k:k + size])) for k in range(0, len(data) - size + 1, size)]


def _smoothness(series, a: int, b: int) -> dict:
    """How a picture changes across frames a..b: the largest one-frame step in
    mean luma against the whole change, and how many frames lie in between."""
    a, b = max(0, a), min(len(series) - 1, b)
    means = [m for m, _ in series[a:b + 1]]
    if len(means) < 2:
        return {"range": 0.0, "max_step": 0.0, "intermediate": 0}
    lo, hi = min(means), max(means)
    rng = hi - lo
    steps = [abs(means[k + 1] - means[k]) for k in range(len(means) - 1)]
    inter = sum(1 for m in means if lo + 0.1 * rng < m < hi - 0.1 * rng) if rng > 1 else 0
    return {"range": round(rng, 1), "max_step": round(max(steps), 1), "intermediate": inter}


def check_transitions(series, plan: dict) -> list[dict]:
    """Every rendered transition really animates: no single-frame jump across
    it, frames in between, and a fade through black reaches black. Hard cuts
    (type 'cut') are reported, not judged."""
    results = []
    shots, fps = plan["shots"], plan["fps"]
    edges = []
    if plan["fade_in"]:
        edges.append(("start", "fade_in", 0, plan["fade_in"], 0))
    for i in range(1, len(shots)):
        edges.append((f"{shots[i - 1].get('id')} -> {shots[i].get('id')}", plan["kinds"][i], plan["starts"][i], plan["trans"][i], i))
    if plan["fade_out"]:
        edges.append(("end", "fade_out", plan["total"] - plan["fade_out"], plan["fade_out"], len(shots)))
    for name, kind, start, d, i in edges:
        r = {"at": name, "type": kind, "start_s": round(start / fps, 3), "duration_s": round(d / fps, 3)}
        if kind == "cut":
            r.update(_smoothness(series, start - 1, start), ok=True, note="hard cut by design")
            results.append(r)
            continue
        r.update(_smoothness(series, start - 1, start + d))
        black_at = None
        if kind == "fade_in":
            black_at = 0
        elif kind == "fade_out":
            black_at = plan["total"] - 1
        elif kind == "fade":
            if shots[i]["kind"] == "card":
                black_at = start + d  # the card's held-back text: black when the fade ends
            elif shots[i - 1]["kind"] == "card":
                black_at = start  # the card's text has faded out when the fade starts
            else:
                black_at = start + d // 2  # a dip between clips
        if black_at is not None:
            black_at = min(black_at, len(series) - 1)
            window = series[max(0, black_at - 1):black_at + 2]
            r["black_level"] = min(mx for _, mx in window)
        smooth = r["range"] < 4 or (r["max_step"] <= max(4.0, 0.34 * r["range"]) and r["intermediate"] >= max(1, d // 3))
        reaches_black = black_at is None or r["black_level"] <= BLACK_MAX
        r["ok"] = smooth and reaches_black
        if not r["ok"]:
            r["note"] = ("a jump of %.1f in a change of %.1f" % (r["max_step"], r["range"]) if not smooth else "") + \
                        ("" if reaches_black else " never reaches black (level %d)" % r["black_level"])
        results.append(r)
    return results


def check_text_holds(series, plan: dict) -> list[dict]:
    """Every headline's and card's reading time: planned, and for a card
    (text on a plain colour, so its brightness is the text's) measured too:
    the longest run of frames at full text brightness, which must last the
    required time (one frame of tolerance for the encoder)."""
    fps, out = plan["fps"], []
    for h in plan["holds"]:
        i = h["index"]
        r = {k: v for k, v in h.items() if k not in ("index", "required_frames")}
        r["ok"] = h["planned_s"] >= h["required_s"]
        if plan["shots"][i]["kind"] != "card":
            r["measured"] = "planned only (text over moving gameplay)"
            out.append(r)
            continue
        s = plan["starts"][i]
        t_in, end, _ = plan["text"][i]
        means = [m for m, _ in series[s + t_in:s + end]]
        low, high = (min(means), max(means)) if means else (0.0, 0.0)
        if high - low < 1.0:
            r["measured"] = "too little ink to measure"
            out.append(r)
            continue
        run = best = 0
        for m in means:
            run = run + 1 if m - low >= 0.95 * (high - low) else 0
            best = max(best, run)
        r["measured_s"] = round(best / fps, 3)
        r["ok"] = r["ok"] and best >= h["required_frames"] - 1
        out.append(r)
    return out


def black_edges(series) -> list[dict]:
    """Plan-free check of any video: every switch to or from a black picture,
    and whether it ramps (a fade) or jumps in one frame (a hard cut)."""
    out = []
    black = [mx <= BLACK_MAX for _, mx in series]
    k = 0
    while k < len(black):
        if not black[k]:
            k += 1
            continue
        s = k
        while k < len(black) and black[k]:
            k += 1
        e = k - 1
        for side, j, ref in (("into black", s - 1, range(max(0, s - 16), s)), ("out of black", e + 1, range(e + 1, min(len(series), e + 17)))):
            if 0 <= j < len(series) and len(ref):
                level = max(series[r][0] for r in ref)
                if level > 8:
                    out.append({"frame": s if side == "into black" else e + 1, "edge": side,
                                "abrupt": series[j][0] > 0.5 * level, "neighbour_level": round(series[j][0], 1),
                                "scene_level": round(level, 1)})
    return out


def abrupt_changes(series) -> list[dict]:
    """Plan-free: every one-frame jump in overall brightness (a hard cut). A
    cut to or from a dark frame (a black card, even one with its text already
    on it) is marked 'dark'."""
    out = []
    means = [m for m, _ in series]
    for k in range(1, len(means)):
        a, b = means[k - 1], means[k]
        # Judged against the change around it: one frame of a fade is a small
        # share of the fade's whole change; a cut is nearly all of it.
        near = means[max(0, k - 7):k + 6]
        if abs(b - a) > max(12.0, 0.5 * (max(near) - min(near))):
            out.append({"frame": k, "from": round(a, 1), "to": round(b, 1), "dark": min(a, b) <= 14.0})
    return out


def audio_stats(path: Path, total: float) -> dict:
    """Peak and mean level, and the quietest 100 ms window before the last
    second: continuous music or game sound never drops out."""
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-vn", "-af",
                        "volumedetect", "-f", "null", "-"], capture_output=True, text=True)
    stats = {}
    for key in ("max_volume", "mean_volume"):
        m = re.search(key + r": (-?[\d.]+|-inf) dB", p.stderr)
        stats[key] = float(m.group(1)) if m and m.group(1) != "-inf" else None
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-vn", "-af",
                        "aresample=48000,asetnsamples=n=4800:p=0,astats=metadata=1:reset=1,"
                        "ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-", "-f", "null", "-"],
                       capture_output=True, text=True)
    levels = [float(v) if v not in ("-inf", "inf") else -120.0
              for v in re.findall(r"RMS_level=(-?[\d.]+|-inf|inf)", p.stdout)]
    body = levels[:max(1, int((total - 1.0) * 10))]
    stats["quietest_window_db"] = round(min(body), 1) if body else None
    # Reported, not judged: a rest in the supplied music is the composer's.
    stats["quiet_windows_s"] = [round(k / 10, 1) for k, v in enumerate(body) if v < -45.0]
    stats["windows"] = len(levels)
    return stats


def review(path: Path, plan: dict, size: tuple[int, int], has_audio: bool, extra: dict | None = None) -> dict:
    """Checks the encoded video frame by frame and writes, next to it, a JSON
    report and a review sheet (each shot's first/middle/last frame, then every
    transition frame by frame) for the human visual check."""
    series = luma_series(path)
    if abs(len(series) - plan["total"]) > 1:
        raise MarketingError(f"{path} decodes to {len(series)} frames, the plan has {plan['total']}")
    transitions = check_transitions(series, plan)
    holds = check_text_holds(series, plan)
    report = {"file": path.name, "frames": len(series), "seconds": round(len(series) / plan["fps"], 3),
              "transitions": transitions, "transitions_ok": sum(1 for t in transitions if t["ok"]),
              "text_holds": holds, "text_holds_ok": sum(1 for h in holds if h["ok"]),
              "black_edges": black_edges(series), "abrupt_changes": abrupt_changes(series), **(extra or {})}
    if has_audio:
        report["audio"] = audio_stats(path, plan["total"] / plan["fps"])
    report["sheet"] = str(_review_sheet(path, plan, size))
    path.with_name(path.stem + "_review.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    bad = [t for t in transitions if not t["ok"]]
    if bad:
        raise MarketingError("Transitions failed the frame check: " + "; ".join(f"{t['at']} ({t.get('note', '')})" for t in bad))
    short = [h for h in holds if not h["ok"]]
    if short:
        raise MarketingError("Text is not readable long enough: " + "; ".join(
            f"{h['kind']} {h['shot']}: {h.get('measured_s', h['planned_s'])}s fully visible, needs {h['required_s']}s"
            for h in short))
    audio = report.get("audio")
    if audio and (audio["max_volume"] is None or audio["max_volume"] > -0.05):
        raise MarketingError(f"Audio clips or is silent: peak {audio['max_volume']} dB")
    return report


def _review_sheet(path: Path, plan: dict, size: tuple[int, int]) -> Path:
    Image, ImageDraw, ImageFont = _pil()
    fps, shots = plan["fps"], plan["shots"]
    rows: list[tuple[str, list[int]]] = []
    for i, shot in enumerate(shots):
        s, n = plan["starts"][i], plan["lengths"][i]
        rows.append((f"shot {shot.get('id')} ({n / fps:.2f}s)", [s, s + n // 2, s + n - 1]))
    for i in range(1, len(shots)):
        d = plan["trans"][i]
        if d:
            s = plan["starts"][i]
            rows.append((f"{plan['kinds'][i]} {d / fps:.2f}s into {shots[i].get('id')}",
                         sorted({s - 1 + round(k * (d + 1) / 6) for k in range(7)})))
    if plan["fade_out"]:
        s = plan["total"] - plan["fade_out"]
        rows.append((f"fade_out {plan['fade_out'] / fps:.2f}s", sorted({s - 1 + round(k * plan['fade_out'] / 6) for k in range(7)})))
    wanted = sorted({max(0, min(plan["total"] - 1, f)) for _, fr in rows for f in fr})
    thumb_w = 240
    thumb_h = round(thumb_w * size[1] / size[0])
    with tempfile.TemporaryDirectory(prefix="marketing_review_") as td:
        sel = "+".join(f"eq(n\\,{f})" for f in wanted)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(path), "-vf",
                        f"select='{sel}',scale={thumb_w}:{thumb_h}", "-fps_mode", "passthrough",
                        str(Path(td) / "f_%04d.png")], check=True)
        frames = {f: Image.open(Path(td) / f"f_{k + 1:04d}.png").convert("RGB") for k, f in enumerate(wanted)
                  if (Path(td) / f"f_{k + 1:04d}.png").exists()}
        label_h, pad = 22, 6
        cols = max(len(fr) for _, fr in rows)
        sheet = Image.new("RGB", (pad + cols * (thumb_w + pad), pad + len(rows) * (thumb_h + label_h + pad)), (24, 24, 28))
        draw = ImageDraw.Draw(sheet)
        font = ImageFont.load_default(14)
        y = pad
        for label, fr in rows:
            draw.text((pad, y + 3), label, fill=(230, 230, 230), font=font)
            x = pad
            for f in fr:
                f = max(0, min(plan["total"] - 1, f))
                if f in frames:
                    sheet.paste(frames[f], (x, y + label_h))
                    draw.text((x + 4, y + label_h + 4), f"{f / fps:.2f}s", fill=(255, 220, 90), font=font)
                x += thumb_w + pad
            y += thumb_h + label_h + pad
        out = path.with_name(path.stem + "_review.png")
        sheet.save(out)
    return out


# ================================================================ fonts command

def verify_toolkit_fonts() -> list[dict]:
    """The bundled faces and their licences against assets/fonts/font_manifest.json
    (source URL, size, SHA-256): what a game uses is what was downloaded."""
    if not FONT_LOCK.is_file():
        raise MarketingError(f"Missing {FONT_LOCK}")
    lock = json.loads(FONT_LOCK.read_text(encoding="utf-8"))
    problems, faces = [], []
    for entry in lock.get("fonts", []):
        face = TOOLKIT_FONTS / entry["font_filename"]
        lic = TOOLKIT_FONTS / entry["license_file"]
        if not face.is_file():
            problems.append(f"missing: {face.name}")
        else:
            data = face.read_bytes()
            if len(data) != entry["font_bytes"] or hashlib.sha256(data).hexdigest() != entry["font_sha256"]:
                problems.append(f"differs from the recorded download: {face.name}")
        if not lic.is_file():
            problems.append(f"licence missing: {entry['license_file']}")
        elif hashlib.sha256(lic.read_bytes()).hexdigest() != entry["license_sha256"]:
            # Licence texts may be checked out with converted line endings.
            if hashlib.sha256(lic.read_bytes().replace(b"\r\n", b"\n")).hexdigest() != entry["license_sha256"]:
                problems.append(f"licence differs from the recorded download: {entry['license_file']}")
        faces.append({"locale": entry["locale"], "family": entry["family"], "file": f"toolkit:{entry['font_filename']}",
                      "license": entry["license"]})
    if problems:
        raise MarketingError("Bundled fonts:\n  " + "\n  ".join(problems))
    return faces


def fonts(args) -> None:
    """Checks the bundled fonts; with a manifest, renders every locale's
    test strings (assets/fonts/script_samples.json: pangrams and the 'I can
    eat glass' sentences, never marketing copy) through the real headline and
    card composition, with the locale's font chain and renderer, and sets every
    approved string of the manifest too: proof sheets + a JSON report."""
    for face in verify_toolkit_fonts():
        print(f"FONT OK: {face['file']} ({face['family']}, {face['license']}) for {face['locale']}")
    if not args.manifest:
        return
    manifest = args.manifest.resolve()
    conf = load_manifest(manifest)
    locales = select_locales(args.locales)
    samples = json.loads(SCRIPT_SAMPLES.read_text(encoding="utf-8"))["samples"]
    missing = [loc for loc in locales if loc not in samples]
    if missing:
        raise MarketingError(f"No test strings for {missing} in {SCRIPT_SAMPLES}")
    out_dir = source_path(args.out, manifest) if args.out else \
        source_path(str(conf.get("output_root", ".")), manifest) / "fonts_proof"
    sheet_path = out_dir / "fonts_proof.png"
    unique_destination(sheet_path, args.overwrite)
    style = style_of(conf)
    Image, ImageDraw, ImageFont = _pil()
    land, port = (1920, 1080), (1080, 1920)
    with tempfile.TemporaryDirectory(prefix="marketing_fonts_") as td:
        engine = TextEngine(conf, manifest, args.godot, Path(td))
        copy = {loc: {k: v for k, v in conf.get("strings", {}).get(loc, {}).items() if isinstance(v, str) and v.strip()}
                for loc in locales}

        def layers(loc: str, used: dict | None = None) -> dict:
            """Each layout's layer; `used` receives the text blocks each one set."""
            s = samples[loc]
            builders = {"headline": lambda: text_image(land, s["headline"], "top", loc, engine, style),
                        "card": lambda: card_image(land, s["title"], s["subtitle"], None, loc, engine, style),
                        "portrait": lambda: text_image(port, s["headline"], "center", loc, engine, style),
                        **{f"copy:{k}": (lambda v=v: text_image(land, v, "top", loc, engine, style))
                           for k, v in copy[loc].items()}}
            out = {}
            for name, build in builders.items():
                engine.trace = []
                out[name] = build()
                if used is not None:
                    used[name] = list(dict.fromkeys(engine.trace))
            engine.trace = None
            return out

        engine.collecting = True
        for loc in locales:
            s = samples[loc]
            engine.renderer(loc, "\n".join([s["headline"], s["title"], s["subtitle"]]))
            layers(loc)
        engine.flush()
        report = {"note": "Test strings only (assets/fonts/script_samples.json): never marketing copy.", "locales": {}}
        rows = []
        label_font = ImageFont.load_default(22)
        for loc in locales:
            used: dict[str, list[tuple]] = {}
            built = layers(loc, used)
            chain = engine.chain(loc)
            # Per layout, only the blocks it set (a landscape and a portrait
            # headline share their text, not their size or lines).
            blocks = {name: [{k: v for k, v in engine.done[key].info.items() if k in ("renderer", "font_size", "wrap", "lines")}
                             for key in keys] for name, keys in used.items()}
            report["locales"][loc] = {
                "renderer": engine.renderer(loc),
                "fonts": chain if chain == "builtin:pillow" else
                [{"file": f["path"].name, "weight": f["weight"], "width": f["width"]} for f in chain],
                "approved_copy_keys": sorted(copy[loc]), "blocks": blocks}
            # One row: landscape headline, card, portrait headline, on a
            # neutral gameplay stand-in (a gradient), at half size.
            row = []
            for name, size in (("headline", land), ("card", land), ("portrait", port)):
                bg = Image.linear_gradient("L").resize(size).convert("RGBA")
                bg = Image.blend(bg, Image.new("RGBA", size, (52, 92, 70, 255)), 0.55) if name != "card" else \
                    Image.new("RGBA", size, _rgba(style["card_color"]))
                bg.alpha_composite(built[name])
                row.append(bg.convert("RGB").resize((size[0] * 540 // size[1], 540), Image.Resampling.LANCZOS))
            width = sum(r.width for r in row) + 10 * (len(row) + 1)
            canvas = Image.new("RGB", (width, 540 + 50), (24, 24, 28))
            ImageDraw.Draw(canvas).text((10, 12), f"{loc}  |  {engine.renderer(loc)}  |  " + ", ".join(
                f["file"] + (f" wght {f['weight']}" if f["weight"] else "") for f in report["locales"][loc]["fonts"])
                if isinstance(report["locales"][loc]["fonts"], list) else f"{loc}  |  pillow  |  builtin",
                fill=(235, 235, 235), font=label_font)
            x = 10
            for r in row:
                canvas.paste(r, (x, 45))
                x += r.width + 10
            path = out_dir / f"fonts_{loc}.png"
            unique_destination(path, args.overwrite)
            canvas.save(path)
            rows.append(canvas)
            print(f"FONT PROOF: {path} ({engine.renderer(loc)}; approved copy checked: {len(copy[loc])} strings)")
        scale = 0.5
        thumbs = [r.resize((round(r.width * scale), round(r.height * scale)), Image.Resampling.LANCZOS) for r in rows]
        sheet = Image.new("RGB", (max(t.width for t in thumbs), sum(t.height for t in thumbs)), (24, 24, 28))
        y = 0
        for t in thumbs:
            sheet.paste(t, (0, y))
            y += t.height
        sheet.save(sheet_path)
        (out_dir / "fonts_proof.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"FONT PROOF SHEET: {sheet_path}; report: {out_dir / 'fonts_proof.json'}. Look at every script before approving.")


# ================================================================ commands

def pipeline(args) -> None:
    """One command: every real-game capture job, then the screenshots and every
    video. --reuse-raw recomposes saved recordings without opening Godot."""
    config = load_manifest(args.manifest)
    jobs = [j for j in config.get("capture_jobs", []) if not args.jobs or j["id"] in args.jobs]
    if not args.reuse_raw:
        if not jobs:
            raise MarketingError("No capture_jobs selected; use --reuse-raw for composition from existing footage")
        for job in jobs:
            record(Namespace(manifest=args.manifest, project=args.project, godot=args.godot,
                             job=job["id"], overwrite=args.overwrite))
    else:
        print("REUSING RAW CAPTURES: no Godot run")
    if config.get("screenshots"):
        compose_screenshots(Namespace(manifest=args.manifest, locales=args.locales, shot=None, overwrite=args.overwrite,
                                      godot=args.godot))
    if videos_of(config):
        compose_video(Namespace(manifest=args.manifest, locales=args.locales, music=args.music,
                                overwrite=args.overwrite, video_id=None, godot=args.godot, quality=args.quality))
    print("PIPELINE COMPLETE; inspect the actual artwork, review sheets and footage before store publication.")


def verify(args) -> None:
    verify_video_file(args.file, args.width, args.height, args.fps, args.duration, args.audio)
    print("MP4 metadata verification OK:", args.file)


def analyze(args) -> None:
    """Any video (an older take too): its switches to and from black."""
    series = luma_series(args.file)
    edges = black_edges(series)
    cuts = abrupt_changes(series)
    dark = [c for c in cuts if c["dark"]]
    print(json.dumps({"file": str(args.file), "frames": len(series), "black_edges": edges, "abrupt_changes": cuts}, indent=2))
    print(f"{len(edges)} edges to or from black ({sum(1 for e in edges if e['abrupt'])} abrupt); "
          f"{len(cuts)} one-frame jumps in brightness, {len(dark)} of them to or from a dark frame (a hard cut to black)")
    if dark and args.strict:
        raise MarketingError("Hard cuts to or from black")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    chk = sub.add_parser("check", help="Check FFmpeg/ffprobe, Pillow (and Godot with --godot)")
    chk.add_argument("--godot")
    chk.set_defaults(func=check)
    inst = sub.add_parser("install", help="Copy the toolkit's addons into a Godot project and pin the version")
    inst.add_argument("--project", type=Path, required=True)
    inst.add_argument("--overwrite", action="store_true")
    inst.set_defaults(func=install)
    st = sub.add_parser("status", help="Check the installed addons against the lock and this toolkit")
    st.add_argument("--project", type=Path, required=True)
    st.set_defaults(func=status)
    cap = sub.add_parser("record", help="Record one declared real-game scenario with Godot")
    cap.add_argument("--project", type=Path, required=True)
    cap.add_argument("--manifest", type=Path, required=True)
    cap.add_argument("--job", required=True)
    cap.add_argument("--godot", help="Godot executable (the Windows console exe; else MARKETING_GODOT)")
    cap.add_argument("--overwrite", action="store_true")
    cap.set_defaults(func=record)
    sc = sub.add_parser("screenshots", help="Create localized, optionally headlined images from real PNGs")
    sc.add_argument("--manifest", required=True, type=Path)
    sc.add_argument("--locales", nargs="+", required=True, help="Locale codes or all (20)")
    sc.add_argument("--shot", help="Optional screenshot id filter")
    sc.add_argument("--godot", help="Godot console exe for the text renderer (else MARKETING_GODOT)")
    sc.add_argument("--overwrite", action="store_true")
    sc.set_defaults(func=compose_screenshots)
    vid = sub.add_parser("video", help="Compose clips, cards, transitions, game audio and music into MP4")
    vid.add_argument("--manifest", required=True, type=Path)
    vid.add_argument("--locales", nargs="+", required=True, help="Locale codes or all (20)")
    vid.add_argument("--video", dest="video_id", help="Only this video id")
    vid.add_argument("--music", help="Supplied WAV/MP3 path for every video (relative to the manifest)")
    vid.add_argument("--quality", help="MP4 quality preset: preview (CRF 26), standard (CRF 21), high (CRF 18, default)")
    vid.add_argument("--godot", help="Godot console exe for the text renderer (else MARKETING_GODOT)")
    vid.add_argument("--overwrite", action="store_true")
    vid.set_defaults(func=compose_video)
    all_cmd = sub.add_parser("pipeline", help="Record every capture job, then make localized images and every MP4")
    all_cmd.add_argument("--project", type=Path, required=True)
    all_cmd.add_argument("--manifest", type=Path, required=True)
    all_cmd.add_argument("--godot", help="Godot console exe: captures and the text renderer (else MARKETING_GODOT)")
    all_cmd.add_argument("--locales", nargs="+", required=True, help="Locale codes or all (20)")
    all_cmd.add_argument("--jobs", nargs="+", help="Only these capture job ids")
    all_cmd.add_argument("--music", help="Supplied audio path for every video")
    all_cmd.add_argument("--quality", help="MP4 quality preset: preview, standard, high (default)")
    all_cmd.add_argument("--reuse-raw", action="store_true", help="No capture run: recompose saved footage")
    all_cmd.add_argument("--overwrite", action="store_true")
    all_cmd.set_defaults(func=pipeline)
    val = sub.add_parser("verify", help="Probe an MP4's codec, dimensions, fps, duration, audio")
    val.add_argument("--file", type=Path, required=True)
    val.add_argument("--width", type=int, required=True)
    val.add_argument("--height", type=int, required=True)
    val.add_argument("--fps", type=int, required=True)
    val.add_argument("--duration", type=float, required=True)
    val.add_argument("--audio", action="store_true")
    val.set_defaults(func=verify)
    ana = sub.add_parser("analyze", help="List a video's switches to and from black (fades or hard cuts)")
    ana.add_argument("--file", type=Path, required=True)
    ana.add_argument("--strict", action="store_true", help="Fail on an abrupt switch")
    ana.set_defaults(func=analyze)
    fo = sub.add_parser("fonts", help="Verify the bundled fonts; with --manifest, proof every locale's fonts with test strings")
    fo.add_argument("--manifest", type=Path)
    fo.add_argument("--locales", nargs="+", default=["all"], help="Locale codes or all (20)")
    fo.add_argument("--godot", help="Godot console exe for the text renderer (else MARKETING_GODOT)")
    fo.add_argument("--out", help="Proof folder (default <output_root>/fonts_proof), relative to the manifest")
    fo.add_argument("--overwrite", action="store_true")
    fo.set_defaults(func=fonts)
    args = ap.parse_args(argv)
    for name in ("manifest", "project"):
        if isinstance(getattr(args, name, None), Path):
            setattr(args, name, getattr(args, name).resolve())
    try:
        args.func(args)
        return 0
    except (MarketingError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print("ERROR:", exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
