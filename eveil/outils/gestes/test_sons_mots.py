"""Les gestes de Lou pour un mot, syllabe par syllabe (mêmes cas que `LouSoundsTests.swift`)."""
from __future__ import annotations

import json
import unittest
from pathlib import Path

from .gestes import TOUS, par_son
from .sons_mots import gestes_de_syllabe, gestes_du_mot

CAS = {
    "ʒy": [["j", "u"]],
    "po": [["p", "o"]],
    "vwa.tyʁ": [["v", "oi"], ["t", "u", "r"]],
    "ʒi.ʁaf": [["j", "i"], ["r", "a", "f"]],
    "nɥaʒ": [["n", "ui", "a", "j"]],
    "ʃjɛ̃": [["ch", "ill", "in"]],
    "ɡʁə.nuj": [["g", "r", "e"], ["n", "ou", "ill"]],
    "flœʁ": [["f", "l", "eu ouvert", "r"]],
    "ʃə.val": [["ch", "e"], ["v", "a", "l"]],
    "bwat": [["b", "oi", "t"]],
    "kwɛ̃": [["k", "oin"]],
    "ˈwi": [["i"]],                       # /w/ seul : pas de geste à lui
}


class TestSonsMots(unittest.TestCase):
    def test_cas(self):
        for api, attendu in CAS.items():
            self.assertEqual(gestes_du_mot(api), attendu, api)

    def test_chaque_son_des_mots_du_train_a_son_geste_ou_sa_bouche(self):
        lexique = Path(__file__).resolve().parents[2] / "lexique" / "fr-FR.json"
        for w in json.loads(lexique.read_text(encoding="utf-8"))["words"]:
            syllabes = gestes_du_mot(w["ipa"])
            self.assertEqual(len(syllabes), len(w["wagons"]), w["text"])
            for s in syllabes:
                self.assertTrue(s, f"{w['text']} : une syllabe sans geste")
                for cle in s:
                    self.assertIn(cle, {g.son for g in TOUS}, cle)

    def test_la_syllabe_vide(self):
        self.assertEqual(gestes_de_syllabe(""), [])
        self.assertIsNotNone(par_son("ʃ"))


if __name__ == "__main__":
    unittest.main()
