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


class TestVerbes(unittest.TestCase):
    """Les pictos des verbes, et les réglages de Lou ajoutés pour eux."""

    VERBES = ("dormir", "sauter", "danser", "courir", "chanter", "nager", "voler", "tourner", "rire", "se_cacher",
              "manger", "boire", "pousser", "porter", "lancer", "laver", "attraper", "lecher", "sentir", "tirer")

    def test_un_picto_par_verbe_et_lou(self):
        from .verbes import PICTOS
        attendus = {"perso.lou"} | {f"verbe.{v}" for v in self.VERBES}
        self.assertEqual(sorted(p.id for p in PICTOS), sorted(attendus))

    def test_rien_ne_colle_au_bord_de_la_carte(self):
        # Courbes échantillonnées, épaisseur des traits comprise (plus strict que `problemes`).
        from coloriages.dessin import relire

        from .verbes import PICTOS
        for p in PICTOS:
            for k, op in enumerate(p.ops):
                m = op.largeur / 2 if op.genre == "trait" else 0
                for c in relire(op.d):
                    for x, y in c.sample(8):
                        self.assertTrue(8 <= x - m and x + m <= 192 and 12 <= y - m and y + m <= 190,
                                        f"{p.id}#{k} en ({x:.1f}, {y:.1f})")

    def test_lou_sujet_centre_et_pieds_au_sol(self):
        from .peinture import boite_englobante
        from .verbes import PICTOS
        sujet = next(p for p in PICTOS if p.id == "perso.lou")
        x0, _, x1, y1 = boite_englobante(sujet)
        self.assertAlmostEqual((x0 + x1) / 2, 100, delta=2)
        self.assertLessEqual(y1, 188)
        j = articulations(Pose())
        self.assertAlmostEqual(j["pied_g"][1], 176, delta=1)

    def test_taille_reduit_lou_sans_decoller_les_pieds(self):
        droit = dict(jambe_g=(90, 90), jambe_d=(90, 90))
        j1, j2 = articulations(Pose(**droit)), articulations(Pose(taille=0.5, **droit))
        self.assertAlmostEqual(j2["pied_d"][1], 176, delta=0.01)
        self.assertAlmostEqual(j1["pied_d"][1], 176, delta=0.01)
        self.assertAlmostEqual(176 - j2["tete"][1], (176 - j1["tete"][1]) * 0.5, delta=0.01)
        p1, p2 = Picto("perso.essai"), Picto("perso.essai")
        lou(p1, Pose())
        lou(p2, Pose(taille=0.5))
        self.assertEqual(len(p1.ops), len(p2.ops))
        self.assertEqual(problemes(p2), [])

    def test_atteindre_pose_la_main_ou_le_pied_sur_la_cible(self):
        from .figure import BRAS, AVANT_BRAS, atteindre
        for membre, cible, pli, taille in (("bras_d", (124, 84), 1, 1.0), ("bras_g", (80, 128), 1, 1.0),
                                          ("bras_d", (110, 118), -1, 1.0), ("jambe_g", (80, 170), 1, 1.0),
                                          ("bras_g", (70, 90), 1, 0.8)):
            pose = Pose(taille=taille, penche=10)
            setattr(pose, membre, atteindre(pose, membre, cible, pli))
            bout = articulations(pose)[("main_" if membre.startswith("bras") else "pied_") + membre[-1]]
            self.assertAlmostEqual(bout[0], cible[0], delta=0.01, msg=membre)
            self.assertAlmostEqual(bout[1], cible[1], delta=0.01, msg=membre)
        # Trop loin : le bras se tend vers la cible, sans s'allonger.
        pose = Pose()
        pose.bras_d = atteindre(pose, "bras_d", (195, 90))
        j = articulations(pose)
        e, m = j["epaule_d"], j["main_d"]
        self.assertAlmostEqual(((m[0] - e[0]) ** 2 + (m[1] - e[1]) ** 2) ** 0.5, BRAS + AVANT_BRAS, delta=0.01)

    def test_bras_devant_passe_par_dessus_la_tete(self):
        from .figure import PEAU
        p = Picto("perso.essai")
        lou(p, Pose(bras_d=(-60, -150), devant=("bras_d",)))
        self.assertEqual(p.ops[-1].couleur, PEAU, "la main est peinte en dernier")
        q = Picto("perso.essai")
        lou(q, Pose())
        self.assertNotEqual(q.ops[-1].couleur, PEAU, "par défaut, la bouche est peinte en dernier")

    def test_bouche_suit_la_tete(self):
        from .figure import bouche
        for pose in (Pose(), Pose(penche=20, tete=10, vers=0.5), Pose(taille=0.8, penche=88, cou=-30, tete=-76)):
            b, c = bouche(pose), articulations(pose)["tete"]
            self.assertLess(((b[0] - c[0]) ** 2 + (b[1] - c[1]) ** 2) ** 0.5, 23 * pose.taille, pose)


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
            self.assertIn(genre, ("verbe", "lieu", "perso", "mot"), p.id)
            if genre == "lieu":
                self.assertTrue(p.ancres, p.id)


if __name__ == "__main__":
    unittest.main()
