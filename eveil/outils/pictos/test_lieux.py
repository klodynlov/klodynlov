"""Tests des LIEUX du train des phrases : prépositions, ordres de dessin, mise en scène lisible."""
from __future__ import annotations

import unittest

from coloriages.dessin import arche, rect, trou

from . import lieux
from .peinture import Picto, problemes
from .scene import haut, pieds, problemes_scene, scene

# Ce que chaque lieu doit accepter (le contrat avec l'app : l'enfant ne peut choisir que ces cartes).
ATTENDU = {
    "lieu.boite": {"dans", "sur", "devant", "derriere"},
    "lieu.niche": {"dans", "sur", "devant", "derriere"},
    "lieu.maison": {"dans", "sur", "devant", "derriere"},
    "lieu.table": {"sur", "sous", "devant", "derriere"},
    "lieu.lit": {"dans", "sur", "sous", "devant"},
    "lieu.arbre": {"dans", "sous", "devant", "derriere"},
    "lieu.baignoire": {"dans", "devant", "derriere"},
    "lieu.voiture": {"dans", "sur", "devant", "derriere"},
}
ORDRES = {"dans": {"dedans"}, "sur": {"devant"}, "devant": {"devant"}, "derriere": {"derriere"},
          "sous": {"devant", "dedans"}}


class TestLieux(unittest.TestCase):
    def test_chaque_lieu_accepte_ses_prepositions(self):
        self.assertEqual({p.id: set(p.ancres) for p in lieux.PICTOS}, ATTENDU)

    def test_les_ordres_de_dessin(self):
        for p in lieux.PICTOS:
            for prep, a in p.ancres.items():
                self.assertIn(a.ordre, ORDRES[prep], f"{p.id} « {prep} »")

    def test_les_lieux_sont_sains(self):
        for p in lieux.PICTOS:
            self.assertEqual(problemes(p), [], p.id)

    def test_chaque_phrase_se_lit(self):
        # Jamais entièrement caché ; « dans » : quelque chose passe devant ; « sur » : posé ;
        # « sous » : abrité ; « devant » : plus bas et il cache un peu le lieu ; « derrière » : caché en partie.
        for p in lieux.PICTOS:
            self.assertEqual(problemes_scene(p), [], p.id)

    def test_le_personnage_garde_sa_taille_d_une_preposition_a_l_autre(self):
        # Plus grand devant (plus près), plus petit dessous ou derrière — mais jamais du simple au double.
        for p in lieux.PICTOS:
            tailles = [a.taille for a in p.ancres.values()]
            self.assertLessEqual(max(tailles) / min(tailles), 2.0, p.id)

    def test_devant_il_est_plus_bas_que_derriere(self):
        for p in lieux.PICTOS:
            if {"devant", "derriere"} <= set(p.ancres):
                self.assertGreater(pieds(p.ancres["devant"]), pieds(p.ancres["derriere"]) + 20, p.id)

    def test_sur_il_est_plus_haut_que_dessous(self):
        for p in lieux.PICTOS:
            if {"sur", "sous"} <= set(p.ancres):
                self.assertLess(pieds(p.ancres["sur"]), haut(p.ancres["sous"]), p.id)


class TestScene(unittest.TestCase):
    """Le module de mise en scène sur des lieux d'essai."""

    def _niche(self) -> Picto:
        # Un mur (y 60…180) percé d'une porte en arche au-dessus d'un seuil (y 90…150), le noir derrière.
        p = Picto("lieu.essai").plein("#000000", rect(60, 86, 80, 70))              # le dedans (fond)
        p.plein("#CC8844", rect(30, 60, 140, 120), trou(arche(70, 90, 60, 60)), calque="devant")
        return p

    def test_dans_l_embrasure_on_voit_la_tete(self):
        p = self._niche()
        p.ancre("dans", 100, 185, 0.5, "dedans")
        s = scene(p, "dans")
        self.assertGreater(s.tete_visible, 0.9)
        self.assertGreater(s.cache, 0.1)             # le mur cache ses épaules
        self.assertEqual(problemes_scene(p), [])

    def test_entierement_cache_est_refuse(self):
        p = self._niche()
        p.ancre("derriere", 100, 185, 0.4, "derriere")    # derrière un mur plus grand que lui
        s = scene(p, "derriere")
        self.assertLess(s.tete_visible, 0.05)
        self.assertTrue(any("tête" in pb for pb in problemes_scene(p)))

    def test_en_l_air_est_refuse(self):
        p = self._niche()
        p.ancre("sur", 100, 30, 0.3, "devant")            # pieds en y ≈ 24 : 36 au-dessus du toit
        self.assertTrue(any("reposent sur rien" in pb for pb in problemes_scene(p)))
        p.ancre("sur", 100, 60 + 21 * 0.3 + 1, 0.3, "devant")
        self.assertEqual(problemes_scene(p), [])

    def test_devant_doit_etre_plus_bas_que_le_lieu(self):
        p = self._niche()
        p.ancre("devant", 100, 150, 0.5, "devant")
        self.assertTrue(any("plus haut que le pied" in pb for pb in problemes_scene(p)))

    def test_hors_du_cadre_est_refuse(self):
        p = self._niche()
        p.ancre("sur", 100, 60 + 21 * 1.1 + 1, 1.1, "devant")
        self.assertTrue(any("cadre" in pb for pb in problemes_scene(p)))


if __name__ == "__main__":
    unittest.main()
