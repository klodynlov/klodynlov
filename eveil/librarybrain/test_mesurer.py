"""Tests de `mesurer.py` sur des données factices (aucun verdict réel lu)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mesurer import accord, changements, couverture, fermes, fermes_par_librarybrain  # noqa: E402


class TestMesures(unittest.TestCase):
    def test_couverture_compte_source_et_partiel(self):
        codes = [{"couverture": c} for c in ("SOURCÉ", "PARTIEL", "NON TROUVÉ", "NON TROUVÉ")]
        k, n, (lo, hi) = couverture(codes)
        self.assertEqual((k, n), (2, 4))
        self.assertLess(lo, 0.5)
        self.assertGreater(hi, 0.5)

    def test_accord_strict_et_souple(self):
        verdicts = {"X1": "CONFIRMÉ", "X2": "NUANCÉ", "X3": "RÉFUTÉ", "X4": "CONFIRMÉ"}
        temoins = [{"ids": ["X1"], "position": "SOUTIENT"},
                   {"ids": ["X2"], "position": "SOUTIENT"},     # désaccord strict, accord souple
                   {"ids": ["X3"], "position": "CONTREDIT"},
                   {"ids": ["X4"], "position": "NON TROUVÉ"}]   # hors calcul
        strict = accord(temoins, verdicts)
        self.assertEqual(strict["n"], 3)
        self.assertAlmostEqual(strict["accord"], 2 / 3)
        self.assertEqual(strict["matrice"][("CONFIRMÉ", "NUANCÉ")], 1)
        souple = accord(temoins, verdicts, souple=True)
        self.assertEqual(souple["accord"], 1.0)
        self.assertEqual(souple["kappa"], 1.0)
        self.assertEqual(accord([], verdicts)["n"], 0)
        # Une seule classe des deux côtés : κ non défini, pas 1,0.
        self.assertIsNone(accord(temoins[:2], verdicts, souple=True)["kappa"])

    def test_fermes_exige_une_cible_non_verifiee(self):
        verdicts = {"A22": "NON VÉRIFIÉ", "A2": "NUANCÉ"}
        codes = [{"q": 1, "ids": ["A22"], "couverture": "SOURCÉ", "verifie": "oui"},
                 {"q": 18, "ids": ["A2"], "couverture": "SOURCÉ", "verifie": "oui"},       # cible déjà tranchée
                 {"q": 2, "ids": ["A22"], "couverture": "SOURCÉ", "verifie": "à faire"}]   # non vérifiée
        self.assertEqual(fermes(codes, verdicts), [1])

    def test_fermetures_librarybrain_reconnues(self):
        texte = ("| A21 | x | NON VÉRIFIÉ | — |\n"
                 "| A22 | y | CONFIRMÉ — *LibraryBrain, vérifié dans le texte* (25/09/2026) | A[22] |\n"
                 "| A6 | z | CONFIRMÉ | A[9] |")
        self.assertEqual(fermes_par_librarybrain(texte), {"A22"})

    def test_changements(self):
        der = {("P0", 1): {"couverture": "PARTIEL", "position": None},
               ("P1", 1): {"couverture": "SOURCÉ", "position": None},
               ("P0", 2): {"couverture": "NON TROUVÉ", "position": None},
               ("P1", 2): {"couverture": "NON TROUVÉ", "position": None}}
        self.assertEqual(changements(der, "P0", "P1"), [1])


if __name__ == "__main__":
    unittest.main()
