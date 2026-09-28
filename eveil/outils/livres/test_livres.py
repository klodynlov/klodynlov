"""Tests des livres des sons : phonèmes, place du son, lettres colorées, livres construits.

    cd eveil/outils && python3 -m unittest livres.test_livres
"""
from __future__ import annotations

import unittest

from .livres import MIN_MOTS, PLACES, SONS_EN, SONS_FR, _plier, lettres_du_son, livres
from .mots import NOUVEAUX, TOUS
from .sons import ou_est, phonemes
from .verifier import problemes


class TestPhonemes(unittest.TestCase):
    def test_une_syllabe_par_point(self):
        self.assertEqual(phonemes("ʒi.ʁaf", "fr-FR"), [("ʒ", 0), ("i", 0), ("ʁ", 1), ("a", 1), ("f", 1)])

    def test_la_voyelle_nasale_reste_entiere(self):
        self.assertEqual([p for p, _ in phonemes("ʃɑ̃.pi.ɲɔ̃", "fr-FR")], ["ʃ", "ɑ̃", "p", "i", "ɲ", "ɔ̃"])

    def test_diphtongues_et_affriquees_anglaises(self):
        self.assertEqual([p for p, _ in phonemes("keɪdʒ", "en-US")], ["k", "eɪ", "dʒ"])
        self.assertEqual([p for p, _ in phonemes("ˈsut.keɪs", "en-US")], ["s", "u", "t", "k", "eɪ", "s"])

    def test_en_francais_pas_d_affriquee(self):
        # « tʃ » n'existe pas dans les livres français : t puis ʃ.
        self.assertEqual([p for p, _ in phonemes("tʃa", "fr-FR")], ["t", "ʃ", "a"])


class TestPlaceDuSon(unittest.TestCase):
    def test_debut_milieu_fin(self):
        self.assertEqual((ou_est("ʃ", "ʃə.val", "fr-FR").syllabe, ou_est("ʃ", "ʃə.val", "fr-FR").position), (0, "debut"))
        self.assertEqual((ou_est("ʃ", "fuʁ.ʃɛt", "fr-FR").syllabe, ou_est("ʃ", "fuʁ.ʃɛt", "fr-FR").position), (1, "milieu"))
        self.assertEqual((ou_est("ʃ", "vaʃ", "fr-FR").syllabe, ou_est("ʃ", "vaʃ", "fr-FR").position), (0, "fin"))

    def test_absent(self):
        self.assertIsNone(ou_est("ʃ", "ʒi.ʁaf", "fr-FR"))

    def test_premiere_occurrence(self):
        # « sauce » /sos/ : le premier « s », au début.
        self.assertEqual(ou_est("s", "sos", "fr-FR").position, "debut")


class TestLettres(unittest.TestCase):
    def test_la_graphie_la_plus_longue_d_abord(self):
        son_s = next(s for s in SONS_FR if s.etiquette == "s")
        self.assertEqual(lettres_du_son(son_s, "trousse"), "ss")
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "chette"), "ch")

    def test_accents_ignores_mais_texte_garde(self):
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "bûche"), "ch")
        son_f = next(s for s in SONS_FR if s.etiquette == "f")
        self.assertEqual(lettres_du_son(son_f, "Fée"), "F")      # telles qu'écrites

    def test_introuvable(self):
        son_ch = next(s for s in SONS_FR if s.etiquette == "ch")
        self.assertEqual(lettres_du_son(son_ch, "gi"), "")

    def test_chaque_son_range_ses_graphies_des_plus_longues(self):
        # Une graphie contenue dans une autre doit venir APRÈS elle (« ss » avant « s »).
        for sons in (SONS_FR, SONS_EN):
            for son in sons:
                for i, a in enumerate(son.lettres):
                    for b in son.lettres[:i]:
                        self.assertFalse(a != b and b in a, f"{son.etiquette} : « {a} » après « {b} »")


class TestLivres(unittest.TestCase):
    def test_controles_sans_les_dessins(self):
        self.assertEqual(problemes(verifier_dessins=False), [])

    def test_chaque_livre_est_bien_forme(self):
        for loc in ("fr-FR", "en-US"):
            fr = loc.startswith("fr")
            books = livres(loc)
            self.assertGreaterEqual(len(books), 12, loc)
            for b in books:
                self.assertGreaterEqual(len(b.pages), MIN_MOTS, b.son.etiquette)
                ids = [pg.mot.id for pg in b.pages]
                self.assertEqual(len(ids), len(set(ids)), f"{loc} {b.son.etiquette} : mot en double")
                places = [PLACES.index(pg.position) for pg in b.pages]
                self.assertEqual(places, sorted(places), f"{loc} {b.son.etiquette} : début, milieu, fin")
                for pg in b.pages:
                    wagons = pg.mot.fr_wagons if fr else pg.mot.en_wagons
                    self.assertIn(pg.wagon, range(len(wagons)), pg.mot.id)
                    self.assertTrue(pg.lettres, f"{loc} {b.son.etiquette} {pg.mot.id}")
                    self.assertIn(_plier(pg.lettres), _plier(wagons[pg.wagon]), pg.mot.id)

    def test_un_son_sans_assez_de_mots_n_a_pas_de_livre(self):
        for loc, sons in (("fr-FR", SONS_FR), ("en-US", SONS_EN)):
            avec_livre = {b.son.etiquette for b in livres(loc)}
            for son in sons:
                if son.etiquette in avec_livre:
                    continue
                fr = loc.startswith("fr")
                n = sum(1 for m in TOUS if ou_est(son.api, m.fr_api if fr else m.en_api, loc) is not None)
                self.assertLess(n, MIN_MOTS, f"{loc} {son.etiquette} : {n} mots mais pas de livre")

    def test_les_nouveaux_mots_ont_leur_dessin_a_eux(self):
        for m in NOUVEAUX:
            self.assertEqual(m.dessin, f"mot.{m.id}")
            self.assertTrue(m.nouveau)
        for m in TOUS:
            if m not in NOUVEAUX:
                self.assertFalse(m.dessin.startswith("mot."), m.id)

    def test_rien_d_aleatoire(self):
        self.assertEqual(livres("fr-FR"), livres("fr-FR"))



class TestEnCours(unittest.TestCase):
    """`generer --en-cours` : seulement les mots déjà dessinés, jamais une image manquante."""

    def test_seulement_des_mots_dessines(self):
        from .verifier import dessins_connus, mots_dessines
        connus = dessins_connus()
        mots = mots_dessines()
        self.assertTrue(mots)
        self.assertTrue(all(m.dessin in connus for m in mots))
        for loc in ("fr-FR", "en-US"):
            for b in livres(loc, mots):
                self.assertGreaterEqual(len(b.pages), MIN_MOTS, b.son.etiquette)
                self.assertTrue(all(pg.mot in mots for pg in b.pages), b.son.etiquette)

    def test_l_entete_dit_si_c_est_en_cours(self):
        from .generer import swift_source
        self.assertNotIn("EN COURS", swift_source(TOUS))
        self.assertIn("EN COURS", swift_source(TOUS[:-1]))

if __name__ == "__main__":
    unittest.main()
