"""Tests des gestes de Lou : données relevées, couverture des sons du jeu, planche déterministe.

    cd eveil/outils && python3 -m unittest gestes.test_gestes
"""
from __future__ import annotations

import html
import json
import re
import tempfile
import unittest
from pathlib import Path

from livres.livres import livres
from livres.mots import TOUS as MOTS_DES_LIVRES
from livres.sons import phonemes

from . import planche
from .dessins import SCENES, portrait, vibre, vignettes
from .gestes import A_TROUVER, A_TROUVER_SONS, BOUCHES, CONSONNES, PROPOSITION, RELEVE, TOUS, VOYELLES, par_son
from .lou_portrait import FORMES, PEAU, PEAUX, Main, Toile, main

LEXIQUE = Path(__file__).resolve().parents[2] / "lexique" / "fr-FR.json"
PAGE = re.compile(r"p\. \d+")

# Sons du jeu sans `Geste` à eux, couverts par le geste d'un autre son (dit pourquoi).
COUVERTS = {
    "ɔ": "o",      # o ouvert (os, brosse) : le livre ne distingue pas o fermé / o ouvert (remarque de « o »)
    "w": "oi",     # /w/ n'existe que dans « oi » (/wa/) et « oin » (/wɛ̃/) : gestes de tout le groupe
}


def couvert(api: str) -> bool:
    return par_son(api) is not None or (api in COUVERTS and any(g.son == COUVERTS[api] for g in TOUS))


class TestDonnees(unittest.TestCase):
    def test_chaque_geste_releve_a_une_source_avec_une_page(self):
        for g in VOYELLES + CONSONNES:
            with self.subTest(son=g.son):
                self.assertEqual(g.statut, RELEVE)
                self.assertRegex(g.source, PAGE)
                for champ in (g.main, g.place, g.mouvement, g.evoque):
                    self.assertNotEqual(champ, A_TROUVER)

    def test_chaque_bouche_existe_et_sa_source_est_dite(self):
        for g in TOUS:
            with self.subTest(son=g.son):
                self.assertIn(g.bouche, BOUCHES)
                self.assertTrue(g.bouche_source == PROPOSITION or PAGE.search(g.bouche_source),
                                "bouche : citée avec une page, ou « proposition »")
        self.assertEqual(len(BOUCHES), 10)

    def test_les_sons_a_trouver_n_ont_pas_de_geste(self):
        for g in A_TROUVER_SONS:
            with self.subTest(son=g.son):
                self.assertEqual(g.statut, A_TROUVER)
                self.assertEqual(g.main, A_TROUVER)

    def test_un_geste_par_son(self):
        apis = [g.api for g in TOUS]
        self.assertEqual(len(apis), len(set(apis)))


class TestCouverture(unittest.TestCase):
    def test_chaque_son_des_livres_a_un_geste(self):
        livres_fr = livres("fr-FR")
        self.assertGreaterEqual(len(livres_fr), 16)
        for livre in livres_fr:
            with self.subTest(son=livre.son.api):
                self.assertIsNotNone(par_son(livre.son.api))

    def test_chaque_phoneme_des_mots_du_train_est_couvert(self):
        mots = json.loads(LEXIQUE.read_text(encoding="utf-8"))["words"]
        manquants = {p: m["text"] for m in mots for p, _ in phonemes(m["ipa"], "fr-FR") if not couvert(p)}
        self.assertEqual(manquants, {})

    def test_chaque_phoneme_des_mots_des_livres_est_couvert(self):
        manquants = {p: m.fr for m in MOTS_DES_LIVRES for p, _ in phonemes(m.fr_api, "fr-FR") if not couvert(p)}
        self.assertEqual(manquants, {})


class TestDessins(unittest.TestCase):
    def test_chaque_geste_releve_a_son_dessin_et_rien_d_autre(self):
        releves = {g.son for g in VOYELLES + CONSONNES}
        self.assertEqual(set(SCENES), releves)

    def test_les_cartes_a_trouver_n_ont_pas_de_main(self):
        for g in A_TROUVER_SONS:
            with self.subTest(son=g.son):
                self.assertNotIn(g.son, SCENES)
                self.assertEqual(portrait(g, PEAU).svg(), portrait(g, PEAU, avec_geste=False).svg())
                self.assertEqual(vignettes(g, PEAU), [])
                c = planche.carte(g)
                self.assertIn("geste à trouver", c)
                self.assertNotIn("la main de près", c)

    def test_une_main_a_cinq_doigts(self):
        for nom, forme in FORMES.items():
            with self.subTest(forme=nom):
                self.assertEqual({k for k in forme if k != "ordre"},
                                 {"pouce", "index", "majeur", "annulaire", "auriculaire"})
                t = Toile()
                main(t, Main((50, 90), -90, nom), PEAU)
                self.assertTrue(t.elements)

    def test_la_main_change_le_dessin(self):
        g = par_son("ʃ")
        self.assertNotEqual(portrait(g, PEAU).svg(), portrait(g, PEAU, avec_geste=False).svg())

    def test_la_gorge_vibre_seulement_quand_le_livre_le_dit(self):
        vibrent = {g.son for g in TOUS if vibre(g)}
        self.assertEqual(vibrent, {"z", "j", "v", "b", "d", "g"})

    def test_les_temps_sont_numerotes(self):
        for son, n in (("ou", 3), ("oi", 2), ("oin", 3), ("p", 2), ("b", 2), ("t", 2), ("d", 2)):
            with self.subTest(son=son):
                self.assertEqual(len(vignettes(next(g for g in TOUS if g.son == son), PEAU)), n)

    def test_la_peau_est_un_parametre(self):
        g = par_son("a")
        svgs = {portrait(g, couleur).svg() for _, couleur in PEAUX}
        self.assertEqual(len(svgs), len(PEAUX))
        for _, couleur in PEAUX:
            self.assertIn(couleur.upper(), portrait(g, couleur).svg().upper())
        self.assertIn(PEAU, dict(PEAUX).values())


class TestPlanche(unittest.TestCase):
    def test_la_generation_est_deterministe(self):
        self.assertEqual(planche.html_png(), planche.html_png())
        self.assertEqual(planche.html_pdf(), planche.html_pdf())
        for g in TOUS:
            self.assertEqual(portrait(g, PEAU).svg(), portrait(g, PEAU).svg())

    def test_la_planche_contient_toutes_les_cartes_et_la_mention(self):
        h = planche.html_png()
        self.assertEqual(h.count("<section class='carte"), len(TOUS))
        self.assertTrue(html.escape(planche.MENTION) in h, "la mention « document de travail »")
        self.assertTrue(planche.DATE in h, "la date")
        p = planche.html_pdf()
        self.assertEqual(p.count("<section class='carte"), len(TOUS))
        self.assertEqual(p.count("class='page'"), 1 + -(-len(TOUS) // 6))
        self.assertTrue(html.escape(planche.MENTION) in p, "la mention sur chaque page du PDF")

    def test_voyelles_puis_consonnes(self):
        h = planche.html_png()
        rangs = [h.index(f"<span class='son'>{g.son}</span>") for g in VOYELLES + CONSONNES]
        self.assertEqual(rangs, sorted(rangs))

    def test_sans_navigateur_on_ecrit_les_pages_html(self):
        with tempfile.TemporaryDirectory() as d:
            sorties = planche.ecrire(Path(d), avec_rendu=False)
            self.assertEqual([p.suffix for p in sorties], [".html", ".html"])
            self.assertTrue(all(p.stat().st_size > 10_000 for p in sorties))


if __name__ == "__main__":
    unittest.main()
