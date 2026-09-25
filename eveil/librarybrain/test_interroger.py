"""Tests de `interroger.py` : lecture des questions, flux SSE, citations, garde-fous (sans réseau)."""
from __future__ import annotations

import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from interroger import (QUESTIONS, evenements_sse, lire_questions, lire_reglage,  # noqa: E402
                        pages_citees, passages, resume_flux, selection, verifier_bouclage)


class TestQuestions(unittest.TestCase):
    def test_les_33_questions_et_leur_page(self):
        qs = lire_questions(QUESTIONS.read_text(encoding="utf-8"))
        self.assertEqual([q["q"] for q in qs], list(range(1, 34)))
        pages = {q["q"]: q["page"] for q in qs}
        self.assertTrue(all(pages[n] == "/ask" for n in range(1, 14)))
        self.assertTrue(all(pages[n] == "/consensus" for n in range(14, 19)))
        self.assertEqual({n for n in range(19, 34) if pages[n] == "/consensus"}, {20, 23, 30, 32})
        self.assertTrue(all(q["ids"] for q in qs))
        self.assertTrue(all(q["proposition"] for q in qs if q["q"] >= 19))
        self.assertTrue(all(q["proposition"] is None for q in qs if q["q"] < 19))

    def test_selection(self):
        self.assertEqual(selection("3,19-21", list(range(1, 34))), [3, 19, 20, 21])
        self.assertEqual(selection(None, [1, 2]), [1, 2])


class TestConfigEtGardeFous(unittest.TestCase):
    def test_lire_reglage(self):
        cfg = "rag_top_k: 5   # commentaire\nollama_model: 'x/y'\nvide:\n"
        self.assertEqual(lire_reglage(cfg, "rag_top_k"), "5")
        self.assertEqual(lire_reglage(cfg, "ollama_model"), "x/y")
        self.assertIsNone(lire_reglage(cfg, "vide"))
        self.assertIsNone(lire_reglage(cfg, "absente"))

    def test_jeton_seulement_en_bouclage(self):
        verifier_bouclage("http://127.0.0.1:8765")
        verifier_bouclage("http://localhost:8765")
        with self.assertRaises(SystemExit):
            verifier_bouclage("http://192.168.1.10:8765")


class TestFlux(unittest.TestCase):
    def test_reponse_trouvee(self):
        lignes = [b'data: {"type": "phase", "phase": "retrieval"}\n', b"\n",
                  b'data: {"type": "meta", "found": true, "sources": [{"book_id": 7, "page": 3}],'
                  b' "confidence": {"level": "high"}}\n',
                  'data: {"type": "token", "text": "Bon"}\n'.encode(), b'data: {"type": "token", "text": "jour"}\n',
                  b'data: {"type": "done", "tokens_used": 2}\n']
        r = resume_flux(evenements_sse(lignes))
        self.assertEqual(r["reponse"], "Bonjour")
        self.assertTrue(r["found"])
        self.assertEqual(r["sources_api"], [{"book_id": 7, "page": 3}])
        self.assertIsNone(r["erreur"])

    def test_refus_et_erreur(self):
        r = resume_flux(evenements_sse(['data: {"type": "meta", "found": false, "sources": []}',
                                        'data: {"type": "not_found", "reason": "missing_info"}']))
        self.assertFalse(r["found"])
        self.assertIsNone(r["reponse"])
        r = resume_flux(evenements_sse(['data: {"type": "error", "reason": "timeout"}']))
        self.assertIn("timeout", r["erreur"])


class TestPassages(unittest.TestCase):
    def test_pages_citees(self):
        rep = ("Vers 3 ans [Speech Sound Disorders, Bowen, p.12] puis [Autre livre, p. 40-41] "
               "et [Source 1, p.71 ; Source 3, p.72].")
        self.assertEqual(pages_citees(rep), [("Speech Sound Disorders, Bowen", 12), ("Autre livre", 40),
                                             ("Source 1", 71), ("Source 3", 72)])
        self.assertEqual(pages_citees(None), [])

    def test_passages_de_la_source_et_des_pages_citees(self):
        conn = sqlite3.connect(":memory:")
        conn.execute("CREATE TABLE books (id, title, author, year, file_path)")
        conn.execute("CREATE TABLE chunks (id, book_id, chunk_index, text, page)")
        conn.execute("INSERT INTO books VALUES (7, 'Speech Sound Disorders', 'Bowen', 2015, '/x.pdf')")
        conn.execute("INSERT INTO books VALUES (8, 'Autre', 'X', 2020, '/y.pdf')")
        conn.executemany("INSERT INTO chunks VALUES (?, ?, ?, ?, ?)",
                         [(1, 7, 0, "page trois", 3), (2, 7, 1, "page douze", 12), (3, 7, 2, "ailleurs", 99),
                          (4, 8, 0, "autre p5", 5), (5, 8, 1, "autre p8", 8), (6, 8, 2, "autre p99", 99)])
        src = [{"book_id": 7, "title": "Speech Sound Disorders", "page": 3},
               {"book_id": 8, "title": "Autre", "page": 5}]
        rep = "Voir [Speech Sound Disorders, Bowen, p.12], [Source 4, p.5 ; Source 1, p.8] et [Source 2, p.99]."
        out = passages(conn, src, rep)
        # p.12 nomme son livre ; p.5 = page API du livre 8 ; p.8 : seul le livre 8 a un passage
        # à ≤ 10 pages de sa page API ; p.99 : trop loin de toute page API → non résolu, rien.
        self.assertEqual([(c["book_id"], c["page"], c["role"]) for c in out],
                         [(7, 3, "source"), (8, 5, "source"), (7, 12, "citée"), (8, 8, "citée-proche")])
        self.assertEqual(out[2]["passages"][0]["texte"], "page douze")


if __name__ == "__main__":
    unittest.main()
