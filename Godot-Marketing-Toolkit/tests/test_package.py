"""Package integrity: PACKAGE_FILES.sha256 must verify on a fresh clone.

Run from the toolkit root: python -m unittest discover -s tests -v
Needs nothing but Python; the clone tests also need git on PATH.

1.0.0 shipped a manifest hashed from a Windows working tree in which three text
files had CRLF line endings, while the repository (and so every fresh clone)
holds them with LF: `sha256sum -c` failed on a clean checkout. The manifest now
hashes the canonical bytes (LF text, binaries as they are), `.gitattributes`
makes every checkout produce exactly those bytes, and these tests clone the
package under each line-ending configuration a contributor may have.
"""
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

TOOLKIT = Path(__file__).resolve().parents[1]
MANIFEST = "PACKAGE_FILES.sha256"
GIT = shutil.which("git")

# A contributor's git may be set up any of these ways; every clone must verify.
CLONE_CONFIGS = {
    "windows_default": ["core.autocrlf=true"],
    "no_conversion": ["core.autocrlf=false"],
    "input": ["core.autocrlf=input"],
    "crlf_checkout": ["core.autocrlf=false", "core.eol=crlf"],
}


def package_files(root: Path) -> list[str]:
    """Every file of the package except the manifest itself, Python caches and
    a clone's .git."""
    return sorted(p.relative_to(root).as_posix() for p in root.rglob("*")
                  if p.is_file() and p.name != MANIFEST
                  and not {"__pycache__", ".git"} & set(p.relative_to(root).parts))


def read_manifest(text: str) -> dict[str, str]:
    entries = {}
    for line in text.splitlines():
        digest, path = line.split("  ", 1)
        entries[path] = digest
    return entries


def mismatches(root: Path, entries: dict[str, str]) -> list[str]:
    """`sha256sum -c` in Python, plus files the manifest does not list."""
    problems = []
    for rel, digest in entries.items():
        f = root / rel
        if not f.is_file():
            problems.append(f"missing: {rel}")
        elif hashlib.sha256(f.read_bytes()).hexdigest() != digest:
            problems.append(f"hash differs: {rel}")
    problems += [f"not in {MANIFEST}: {rel}" for rel in package_files(root) if rel not in entries]
    return problems


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.raw = (TOOLKIT / MANIFEST).read_bytes()
        self.entries = read_manifest(self.raw.decode("utf-8"))

    def test_manifest_format_is_sha256sum_compatible(self):
        self.assertNotIn(b"\r", self.raw)
        self.assertTrue(self.raw.endswith(b"\n"))
        self.assertEqual(list(self.entries), sorted(self.entries), "entries sorted by path")
        for rel, digest in self.entries.items():
            self.assertRegex(digest, r"^[0-9a-f]{64}$", rel)
            self.assertNotIn("\\", rel)

    def test_text_files_are_canonical_lf(self):
        for rel in self.entries:
            data = (TOOLKIT / rel).read_bytes()
            if b"\0" not in data:  # text (the fonts are the only binaries)
                self.assertNotIn(b"\r", data, f"{rel}: CRLF/CR line endings; the package is LF only")

    def test_working_copy_matches_the_manifest(self):
        self.assertEqual(mismatches(TOOLKIT, self.entries), [])


@unittest.skipUnless(GIT, "git required")
class FreshCloneTests(unittest.TestCase):
    """Commit the package's current bytes to a throwaway repository, then clone
    it under each configuration: what a fresh clone receives must verify."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="godot_marketing_package_")
        root = Path(cls.tmp.name)
        # Only the toolkit's own .gitattributes may decide: no user/system config.
        empty = root / "empty.gitconfig"
        empty.write_text("", encoding="utf-8")
        cls.env = dict(os.environ, GIT_CONFIG_GLOBAL=str(empty), GIT_CONFIG_NOSYSTEM="1")
        src = root / "src"
        for rel in package_files(TOOLKIT) + [MANIFEST]:
            (src / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(TOOLKIT / rel, src / rel)
        cls.git(src.parent, "-c", "init.defaultBranch=main", "init", "-q", "src")
        cls.git(src, "add", "-A")
        cls.git(src, "-c", "user.name=package test", "-c", "user.email=test@example.invalid",
                "commit", "-q", "-m", "package")
        cls.clones = {}
        for name, config in CLONE_CONFIGS.items():
            dest = root / name
            args = [a for kv in config for a in ("-c", kv)]
            cls.git(root, "clone", "-q", *args, str(src), str(dest))
            cls.clones[name] = dest

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    @classmethod
    def git(cls, cwd: Path, *args):
        return subprocess.run([GIT, *args], cwd=cwd, env=cls.env, check=True, capture_output=True, text=True).stdout

    def test_every_fresh_clone_verifies(self):
        for name, clone in self.clones.items():
            with self.subTest(clone=name):
                entries = read_manifest((clone / MANIFEST).read_text(encoding="utf-8"))
                self.assertEqual(mismatches(clone, entries), [])

    def test_repository_stores_lf_text_and_untouched_binaries(self):
        clone = self.clones["no_conversion"]
        for line in self.git(clone, "ls-files", "--eol").splitlines():
            info, rel = line.split("\t", 1)
            index, _work, attr = info.split(None, 2)
            with self.subTest(file=rel):
                self.assertIn(index, ("i/lf", "i/none", "i/-text"))
                if index == "i/-text":
                    self.assertIn("-text", attr)  # .gitattributes marks it binary
                else:
                    self.assertIn("eol=lf", attr)

    def test_a_manifest_hashed_over_crlf_bytes_is_caught(self):
        # The 1.0.0 defect: a text file hashed as a CRLF checkout had it.
        clone = self.clones["windows_default"]
        entries = {rel: hashlib.sha256((clone / rel).read_bytes()).hexdigest() for rel in package_files(clone)}
        self.assertEqual(mismatches(clone, entries), [])
        rel = "tests/test_toolkit.py"
        entries[rel] = hashlib.sha256((clone / rel).read_bytes().replace(b"\n", b"\r\n")).hexdigest()
        self.assertEqual(mismatches(clone, entries), [f"hash differs: {rel}"])


if __name__ == "__main__":
    unittest.main()
