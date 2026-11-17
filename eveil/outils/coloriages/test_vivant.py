"""Tests du dessin qui prend vie : le temps (repos, douceur, jamais plus petit), la table des
mouvements, les pièces des pages (attaches au bon endroit) et ce qui part en Swift.

    cd eveil/outils && python3 -m unittest coloriages.test_vivant -v
"""
from __future__ import annotations

import math
import unittest
from concurrent.futures import ProcessPoolExecutor

from . import analyse, catalogue, vivant, zones

GENRES = (("roule", 1.0), ("tourne", 1.0), ("bat", 0.12), ("balance", 14.0), ("glisse", 0.02), ("flotte", 0.018))
# Les pages où rien ne bouge seul (le dessin entier danse quand même).
IMMOBILES = {"cirque"}
COTE = 256


def _instants(n: int = 600):
    return [k * vivant.DUREE / n for k in range(n + 1)]


class TestTemps(unittest.TestCase):
    def test_repos_hors_de_la_fete(self):
        for genre, a in GENRES:
            for t in (-1.0, 0.0, vivant.DUREE, vivant.DUREE + 1):
                self.assertEqual(vivant.transformation(genre, a, t, phase=0.7), (0.0, 1.0, 0.0, 0.0), genre)

    def test_bat_ne_rapetisse_jamais(self):
        """Battre ne fait que grandir : rien ne se découvre sous la pièce."""
        for t in _instants():
            _, e, _, _ = vivant.transformation("bat", 0.12, t, phase=1.3)
            self.assertGreaterEqual(e, 1.0)
            self.assertLessEqual(e, 1.12 + 1e-9)

    def test_balance_bornee_et_symetrique(self):
        for t in _instants():
            a, _, _, _ = vivant.transformation("balance", 14.0, t, phase=0.4, signe=1.0)
            b, _, _, _ = vivant.transformation("balance", 14.0, t, phase=0.4, signe=-1.0)
            self.assertLessEqual(abs(a), math.radians(14) + 1e-9)
            self.assertAlmostEqual(a, -b)

    def test_la_roue_avance_sans_a_coup(self):
        """Une roue démarre et s'arrête en douceur, sans jamais reculer, et finit sur un nombre entier
        de tours : au repos, elle est là où elle était (pas de saut à la fin de la fête)."""
        for genre in ("roule", "tourne"):
            avant = 0.0
            for t in _instants()[:-1]:
                ang, _, _, _ = vivant.transformation(genre, 1.0, t)
                self.assertGreaterEqual(ang + 1e-12, avant)
                self.assertLess(ang - avant, 0.05)     # 1/100 de s : pas de saut
                avant = ang
            tours = vivant._tours(vivant.DUREE) / vivant.PERIODES[genre]
            self.assertAlmostEqual(tours, round(tours), places=9, msg=genre)
            self.assertGreaterEqual(round(tours), 2)

    def test_flotter_monte_puis_revient(self):
        for t in _instants():
            _, _, dx, dy = vivant.transformation("flotte", 0.018, t, phase=2.0)
            self.assertEqual(dx, 0.0)
            self.assertLessEqual(dy, 0.0)
            self.assertGreaterEqual(dy, -0.018 - 1e-9)

    def test_en_swift(self):
        self.assertEqual(vivant.swift(("roule", 1.0)), ".roll")
        self.assertEqual(vivant.swift(("tourne", 1.0)), ".spin")
        self.assertEqual(vivant.swift(("bat", 0.12)), ".pulse(0.12)")
        self.assertEqual(vivant.swift(("balance", 14.0)), ".sway(14)")
        self.assertEqual(vivant.swift(("balance", 6.0, "suspendue")), ".sway(6, pivot: .top)")
        self.assertEqual(vivant.swift(("balance", 6.0, "le tronc")), '.sway(6, pivot: .part("le tronc"))')
        self.assertEqual(vivant.swift(("glisse", 0.02)), ".drift(0.02)")
        self.assertEqual(vivant.swift(("flotte", 0.018)), ".float(0.018)")


class TestTable(unittest.TestCase):
    def test_le_fond_ne_bouge_jamais(self):
        page = catalogue.PAGES[0]
        for nom in vivant.SOL:
            self.assertIsNone(vivant.mouvement(page, nom))

    def test_genres_connus(self):
        for nom, m in list(vivant.MOUVEMENTS.items()) + [(n, m) for d in vivant.PAR_PAGE.values()
                                                         for n, m in d.items()]:
            if m is not None:
                self.assertIn(m[0], vivant.PERIODES, nom)

    def test_corrections_sur_de_vraies_parties(self):
        """Une correction de page vise une page et une partie qui existent (pas de faute de frappe)."""
        par_id = {p.id: p for p in catalogue.PAGES}
        for pid, noms in vivant.PAR_PAGE.items():
            self.assertIn(pid, par_id)
            a = analyse.analyser(par_id[pid], variantes=False)
            parties = {q.fr for q in a.parties}
            for nom in noms:
                self.assertIn(nom, parties, f"{pid} : « {nom} »")


def _pieces(p):
    a = analyse.analyser(p, variantes=False)
    c = zones.carte(a.traits, taille=COTE)
    return p.id, [(pc.partie, pc.genre, pc.attache, pc.boite, pc.rayon, pc.signe) for pc in vivant.pieces(a, c)]


class TestPieces(unittest.TestCase):
    """Toutes les pages générées, à 256 px (≈ 15 s sur 4 cœurs)."""

    @classmethod
    def setUpClass(cls):
        with ProcessPoolExecutor(4) as ex:
            cls.par_page = dict(ex.map(_pieces, catalogue.PAGES))

    def test_chaque_page_bouge(self):
        immobiles = {pid for pid, ps in self.par_page.items() if not ps}
        self.assertEqual(immobiles, IMMOBILES)

    def test_attaches_dans_la_page_et_dans_leur_boite(self):
        for pid, ps in self.par_page.items():
            for nom, genre, (x, y), (x0, y0, x1, y1), _, _ in ps:
                self.assertTrue(0 <= x <= COTE and 0 <= y <= COTE, f"{pid} : « {nom} »")
                if genre in ("balance", "roule"):
                    m = 6       # une attache est au bord de sa pièce, à un trait près
                    self.assertTrue(x0 - m <= x <= x1 + m and y0 - m <= y <= y1 + m, f"{pid} : « {nom} »")

    def test_la_queue_de_minouche_tient_au_corps(self):
        [(nom, genre, (x, y), _, _, _)] = self.par_page["minouche"]
        self.assertEqual((nom, genre), ("la queue", "balance"))
        self.assertAlmostEqual(x / COTE, 0.69, delta=0.04)
        self.assertAlmostEqual(y / COTE, 0.86, delta=0.04)

    def test_les_oreilles_du_lapin_battent_en_miroir(self):
        oreilles = [(x, s) for nom, _, (x, _), _, _, s in self.par_page["lapin"] if nom == "les oreilles"]
        self.assertEqual(len(oreilles), 2)
        (xa, sa), (xb, sb) = sorted(oreilles)
        self.assertAlmostEqual((xa + xb) / 2 / COTE, 0.5, delta=0.02)
        self.assertEqual((sa, sb), (-1.0, 1.0))

    def test_les_roues_tournent_sur_leur_axe(self):
        roues = [(a, b, r) for nom, g, a, b, r, _ in self.par_page["locomotive"] if g == "roule"]
        self.assertEqual(len(roues), 2)
        for (x, y), (x0, y0, x1, y1), r in roues:
            self.assertGreater(r, 0.25 * (x1 - x0))
            self.assertAlmostEqual(x, (x0 + x1) / 2, delta=0.1 * (x1 - x0))

    def test_la_serviette_pend_a_son_crochet(self):
        [(nom, _, (x, y), (x0, y0, x1, y1), _, _)] = self.par_page["douche"]
        self.assertEqual(nom, "la serviette")
        self.assertEqual(y, y0)
        self.assertAlmostEqual(x, (x0 + x1) / 2)


if __name__ == "__main__":
    unittest.main()
