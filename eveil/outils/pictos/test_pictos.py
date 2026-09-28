"""Tests des pictos du train des phrases : format, cadre, ancres, génération Swift."""
from __future__ import annotations

import unittest

from coloriages.dessin import cercle, rect, trou

from .figure import Pose, articulations, lou
from .generer import SORTIE, swift_source, tous, verifier
from .peinture import Picto, points, problemes


class TestPeinture(unittest.TestCase):
    def test_un_picto_sain(self):
        p = Picto("lieu.essai").plein("#FF0000", cercle(100, 100, 40))
        p.plein("#00FF0080", rect(60, 120, 80, 40, r=6), calque="devant")
        p.ancre("dans", 100, 150, 0.5, "dedans")
        self.assertEqual(problemes(p), [])

    def test_les_defauts_sont_vus(self):
        p = Picto("Mauvais Id").plein("rouge", cercle(100, 100, 40)).trait("#000000", 0, cercle(10, 10, 30))
        p.ancre("a_cote", 100, 150, 3, "partout")
        pbs = " ".join(problemes(p))
        for attendu in ("identifiant", "couleur", "épaisseur", "sort du cadre", "préposition", "ordre", "taille"):
            self.assertIn(attendu, pbs)

    def test_dedans_exige_un_calque_devant(self):
        p = Picto("lieu.essai").plein("#FF0000", cercle(100, 100, 40)).ancre("dans", 100, 150, 0.5, "dedans")
        self.assertTrue(any("calque" in pb for pb in problemes(p)))

    def test_un_trou_se_dessine_en_sens_inverse(self):
        # Mur avec une porte : le trou (contour retourné) laisse voir le personnage (règle non nulle).
        mur = rect(40, 80, 120, 100) + trou(rect(80, 120, 40, 60))
        p = Picto("lieu.essai").plein("#CC8844", mur, calque="devant").ancre("dans", 100, 180, 0.4, "dedans")
        self.assertEqual(problemes(p), [])
        self.assertEqual(len(points(p.ops[0].d)), 8)
        self.assertLess(mur[0].area() * mur[1].area(), 0, "le trou tourne en sens inverse du mur")


class TestFigure(unittest.TestCase):
    def test_lou_debout_tient_dans_le_cadre(self):
        p = Picto("perso.essai")
        lou(p, Pose())
        self.assertEqual(problemes(p), [])
        j = articulations(Pose())
        self.assertAlmostEqual(j["pied_g"][1], 176, delta=6)
        self.assertLess(j["tete"][1], j["haut"][1])


class TestCatalogue(unittest.TestCase):
    def test_tous_les_pictos_sont_sains(self):
        self.assertEqual(verifier(tous()), [])

    def test_le_swift_est_a_jour(self):
        attendu = swift_source(tous())
        self.assertTrue(SORTIE.exists(), "python3 -m pictos.generer")
        self.assertEqual(SORTIE.read_text(encoding="utf-8"), attendu, "python3 -m pictos.generer")

    def test_identifiants(self):
        for p in tous():
            genre = p.id.split(".")[0]
            self.assertIn(genre, ("verbe", "lieu", "perso"), p.id)
            if genre == "lieu":
                self.assertTrue(p.ancres, p.id)


if __name__ == "__main__":
    unittest.main()
