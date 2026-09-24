"""Tests du relais LibraryBrain (sans réseau : le téléchargement est simulé)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from recuperer_sources import is_pdf, load_manifest, run  # noqa: E402


class TestManifest(unittest.TestCase):
    def test_manifest_is_sound(self):
        m = load_manifest()
        ids = [s["id"] for s in m["sources"]]
        self.assertEqual(len(ids), len(set(ids)))
        for s in m["sources"]:
            self.assertIn(s["kind"], {"pdf", "page"})
            self.assertTrue(s["url"].startswith("https://"), s["id"])
            self.assertIn(s["axis"], set("ABCDEF"))


class TestRun(unittest.TestCase):
    def test_only_real_pdfs_are_kept_and_never_refetched(self):
        self.assertTrue(is_pdf("application/pdf", b"%PDF-"))
        self.assertFalse(is_pdf("text/html", b"%PDF-"))
        self.assertFalse(is_pdf("application/pdf", b"<html"))   # page d'erreur servie en 200
        manifest = {"sources": [
            {"id": "bon", "axis": "A", "kind": "pdf", "url": "https://x/bon.pdf", "title": "t"},
            {"id": "faux", "axis": "A", "kind": "pdf", "url": "https://x/faux.pdf", "title": "t"},
            {"id": "page", "axis": "B", "kind": "page", "url": "https://x/p", "title": "t"},
        ]}
        calls = []

        def fake(url):
            calls.append(url)
            if "faux" in url:
                raise ValueError("pas un PDF")
            return b"%PDF-1.7 contenu"

        with tempfile.TemporaryDirectory() as d:
            dest = Path(d)
            rep = run(dest, manifest, fetch=fake, pause=0.0)
            self.assertEqual([s["id"] for s in rep["ok"]], ["bon"])
            self.assertEqual(len(rep["echec"]), 1)
            self.assertEqual(len(rep["manuel"]), 1)
            self.assertTrue((dest / "bon.pdf").exists())
            self.assertFalse((dest / "faux.pdf").exists())
            rep2 = run(dest, manifest, fetch=fake, pause=0.0)
            self.assertEqual([s["id"] for s in rep2["present"]], ["bon"])
        self.assertEqual(calls.count("https://x/bon.pdf"), 1)       # jamais retéléchargé


if __name__ == "__main__":
    unittest.main()
