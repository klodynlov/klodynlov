"""Tests du train des phrases : grammaire FR/EN, lexique, niveaux et plateaux."""
from __future__ import annotations

import unittest

from .generer import GOLDEN, SWIFT, golden_text, swift_source
from .grammaire import Carte, groupe_nominal, morceau, phrase
from .lexique import NOMS, PAR_ID, VERBES, noms
from .niveaux import NIVEAUX, TAILLE_PLATEAU, paires_ou, plateau, verbes_du_niveau
from .verifier import problemes


class TestGrammaire(unittest.TestCase):
    def test_articles_et_elision(self):
        attendus = {"chat": "le chat", "vache": "la vache", "autruche": "l'autruche", "os": "l'os",
                    "oie": "l'oie", "elan": "l'élan", "arbre": "l'arbre", "assiette": "l'assiette", "lou": "Lou"}
        for i, gn in attendus.items():
            self.assertEqual(groupe_nominal(PAR_ID[i], "fr-FR"), gn)
        self.assertEqual(groupe_nominal(PAR_ID["chat"], "en-US"), "the cat")
        self.assertEqual(groupe_nominal(PAR_ID["lou"], "en-US"), "Lou")

    def test_phrases(self):
        C = Carte
        cas = [
            ([C("qui", "chat"), C("verbe", "manger"), C("quoi", "peche")],
             "Le chat mange la pêche.", "The cat eats the peach."),
            ([C("qui", "autruche"), C("verbe", "dormir"), C("ou", "arbre", "derriere")],
             "L'autruche dort derrière l'arbre.", "The ostrich sleeps behind the tree."),
            ([C("qui", "lou"), C("verbe", "se_cacher"), C("ou", "table", "sous")],
             "Lou se cache sous la table.", "Lou hides under the table."),
            ([C("qui", "oiseau"), C("verbe", "chanter")], "L'oiseau chante.", "The bird sings."),
            ([C("qui", "souris"), C("verbe", "sauter"), C("ou", "lit", "sur")],
             "La souris saute sur le lit.", "The mouse jumps on the bed."),
            ([C("qui", "chien"), C("verbe", "courir"), C("ou", "maison", "devant")],
             "Le chien court devant la maison.", "The dog runs in front of the house."),
        ]
        for cartes, fr, en in cas:
            self.assertEqual(phrase(cartes, "fr-FR"), fr)
            self.assertEqual(phrase(cartes, "en-US"), en)

    def test_un_wagon_par_morceau(self):
        cartes = [Carte("qui", "vache"), Carte("verbe", "laver"), Carte("quoi", "bus")]
        self.assertEqual([morceau(c, "fr-FR") for c in cartes], ["la vache", "lave", "le bus"])
        self.assertEqual(phrase(cartes, "fr-FR"), "La vache lave le bus.")


class TestLexique(unittest.TestCase):
    def test_lexique_sain(self):
        # Les pictos manquants (en cours de dessin) sont vérifiés à part : test_pictos_dessines.
        self.assertEqual([p for p in problemes(verifier_pictos=False)], [])

    def test_pictos_dessines(self):
        self.assertEqual(problemes(verifier_pictos=True), [])

    def test_assez_de_choix(self):
        self.assertGreaterEqual(len(noms("qui")), 12)
        self.assertGreaterEqual(len(noms("quoi")), 16)
        self.assertGreaterEqual(len(noms("ou")), 8)
        for v in VERBES:
            if v.transitif:
                self.assertGreaterEqual(len(v.objets), 1, v.id)

    def test_listes_concues_par_langue(self):
        for n in NOMS:
            self.assertTrue(n.fr and n.en, n.id)


class TestNiveaux(unittest.TestCase):
    def test_trois_niveaux(self):
        self.assertEqual(NIVEAUX[1], ("qui", "verbe"))
        self.assertEqual(NIVEAUX[2], ("qui", "verbe", "quoi"))
        self.assertEqual(NIVEAUX[3], ("qui", "verbe", "ou"))
        for n in NIVEAUX:
            self.assertGreaterEqual(len(verbes_du_niveau(n)), 6, n)
        self.assertTrue(all(v.transitif for v in verbes_du_niveau(2)))
        self.assertTrue(all(not v.transitif for v in verbes_du_niveau(3)))

    def test_plateau_petit_et_sans_hasard(self):
        for n in NIVEAUX:
            for tour in range(5):
                for role in ("qui", "verbe"):
                    a, b = plateau(role, n, tour), plateau(role, n, tour)
                    self.assertEqual(a, b)
                    self.assertLessEqual(len(a), TAILLE_PLATEAU)
                    self.assertEqual(len(set(a)), len(a), "pas de doublon")

    def test_le_plateau_tourne(self):
        vus = set()
        for tour in range(6):
            vus |= {c.id for c in plateau("qui", 1, tour)}
        self.assertEqual(vus, {n.id for n in noms("qui")}, "en quelques phrases, tout le monde passe")

    def test_ou_suit_le_verbe(self):
        self.assertEqual({c.id for c in paires_ou("nager")}, {"baignoire"})
        for c in paires_ou("dormir"):
            self.assertIn(c.preposition, ("dans", "sur", "sous"))
            self.assertIn(c.preposition, PAR_ID[c.id].prepositions)
        premiers = [c.id for c in paires_ou("rire")[:6]]
        self.assertEqual(len(set(premiers)), 6, "d'abord des lieux tous différents")


class TestGeneration(unittest.TestCase):
    def test_fichiers_a_jour(self):
        self.assertEqual(SWIFT.read_text(encoding="utf-8"), swift_source(), "python3 -m phrases.generer")
        self.assertEqual(GOLDEN.read_text(encoding="utf-8"), golden_text(), "python3 -m phrases.generer")


if __name__ == "__main__":
    unittest.main()
