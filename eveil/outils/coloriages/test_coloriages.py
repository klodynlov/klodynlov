"""Tests de l'Atelier de coloriage : chaque image du petit train a son dessin, les tracés sont propres,
et PagesDessins.swift est exactement ce que l'outil calcule.

    cd eveil/outils && python3 -m unittest coloriages.test_coloriages -v
"""
from __future__ import annotations

import json
import math
import unittest
from pathlib import Path

from . import analyse, catalogue, generer, traits, zones
from .dessin import Element, aire, cercle, croisements, detail, ellipse, encre, miroir, page, rect, relire, trou, \
    tube, zone

EVEIL = Path(__file__).resolve().parents[2]


def _mots(locale: str) -> list[str]:
    data = json.loads((EVEIL / "lexique" / f"{locale}.json").read_text(encoding="utf-8"))
    return [w["id"] for w in (data["words"] if isinstance(data, dict) else data)]


class TestCatalogue(unittest.TestCase):
    def test_chaque_mot_du_petit_train_a_son_dessin(self):
        for locale in ("fr-FR", "en-US"):
            for mot in _mots(locale):
                self.assertIn(mot, catalogue.MOTS, f"pas de page à colorier pour {mot}")

    def test_atelier_entier_coherent(self):
        """Identifiants et titres uniques, albums de 12 pages au plus, un dessin par mot (pages Swift comprises)."""
        self.assertEqual(catalogue.verifier_catalogue(), [])
        self.assertGreaterEqual(len(catalogue.PAGES) + len(catalogue.pages_dessinees_a_la_main()), 60)

    def test_noms_swift(self):
        noms = [generer.nom_swift(p.id) for p in catalogue.PAGES]
        self.assertEqual(len(set(noms)), len(noms))
        self.assertEqual(generer.nom_swift("brosse-a-dents"), "brosseADents")
        for n in noms:
            self.assertTrue(n.isidentifier() and n[0].islower(), n)


class TestPages(unittest.TestCase):
    """Toutes les pages, analysées une fois (≈ 15 s sur 4 cœurs)."""

    @classmethod
    def setUpClass(cls):
        cls.analyses = analyse.analyser_tout(catalogue.PAGES)

    def test_aucune_erreur(self):
        """Zones fermées et robustes, témoins et détails à leur place, encres dégagées, tracés propres."""
        for a in self.analyses:
            self.assertEqual(a.erreurs, [], a.page.id)

    def test_zones_pour_petits(self):
        for a in self.analyses:
            self.assertTrue(zones.ZONES_MIN <= a.carte.zones <= zones.ZONES_MAX, a.page.id)
            self.assertTrue(a.temoins.temoins, a.page.id)

    def test_swift_a_jour(self):
        self.assertTrue(generer.SWIFT.exists())
        self.assertEqual(generer.SWIFT.read_text(encoding="utf-8"), generer.swift_source(self.analyses),
                         "PagesDessins.swift périmé : cd eveil/outils && python3 -m coloriages.generer")

    def test_relecture_fidele(self):
        """Ce que G.data relit dans l'app est ce que l'outil a calculé (même format M/L/C/Z)."""
        for a in self.analyses[:10]:
            lu = relire(a.lignes)
            self.assertEqual(len(lu), len(a.traits.lignes), a.page.id)
            self.assertEqual(sum(len(c.segs) for c in lu), sum(len(s) for s in a.traits.lignes), a.page.id)
            if a.traits.encres:
                self.assertEqual(len(relire(a.encres)), len(a.traits.encres), a.page.id)


class TestTraitsVisibles(unittest.TestCase):
    def test_une_forme_devant_cache_le_contour(self):
        p = page("essai", "fete", "Essai", "Test", zone(cercle(400, 500, 150)), zone(rect(450, 300, 300, 400)))
        t = traits.calculer(p)
        # aucun morceau du cercle ne passe dans le rectangle posé devant
        for sous in t.lignes:
            for m in sous:
                for k in range(11):
                    x, y = traits._point(m, k / 10)
                    self.assertFalse(455 < x < 745 and 305 < y < 695, (x, y))

    def test_trou_laisse_voir(self):
        p = page("essai", "fete", "Essai", "Test", zone(rect(300, 300, 400, 400)),
                 zone(cercle(500, 500, 250), trou(cercle(500, 500, 120))))
        t = traits.calculer(p)
        # le carré de derrière se voit dans le trou : 4 bords
        visibles = [m for s in t.lignes for m in s if m.droit]
        self.assertTrue(visibles)

    def test_encre_et_carte(self):
        p = page("essai", "fete", "Essai", "Test", zone(cercle(500, 500, 300)), detail(cercle(500, 500, 60)),
                 encre(cercle(500, 500, 25)))
        a = analyse.analyser(p)
        # (trop peu de zones pour une vraie page : seul ce défaut-là est signalé)
        self.assertTrue(a.erreurs and all(e.endswith("3 zones") for e in a.erreurs), a.erreurs)
        # fond, grand disque, anneau du détail (l'encre n'est pas une zone)
        self.assertEqual(a.carte.zones, 3)
        self.assertEqual(len(a.temoins.temoins), 1)
        self.assertEqual(len(a.temoins.details), 1)


class TestCarteDesZones(unittest.TestCase):
    def test_largeur_raster_comme_zonemap(self):
        # ZoneMap.rasterize : max(3, min(0,8 × e, e − 3)), e = trait affiché en pixels
        self.assertAlmostEqual(zones.largeur_raster(0.012, 1024), min(0.8 * 12.288, 12.288 - 3))
        self.assertEqual(zones.largeur_raster(0.002, 1024), 3)

    def test_etiquetage_et_miettes(self):
        W = H = 64
        m = bytearray(W * H)
        for i in range(W):                      # une croix de trait : 4 zones
            m[32 * W + i] = 1
            m[i * W + 32] = 1
        for y in range(5, 8):                   # une miette de 3 × 3 dans le coin haut gauche
            for x in range(5, 8):
                m[y * W + x] = 0
        for x in range(4, 9):
            m[4 * W + x] = m[8 * W + x] = 1
            m[x * W + 4] = m[x * W + 8] = 1
        c = zones.etiqueter(m, W, H, raster=3, miette=0.003)
        self.assertEqual(c.zones, 4)            # la miette a rejoint sa voisine
        self.assertEqual(c.zone((0.1, 0.1)), c.zone((0.4, 0.4)))
        self.assertNotEqual(c.zone((0.1, 0.1)), c.zone((0.9, 0.9)))


class TestPrimitives(unittest.TestCase):
    def test_aires(self):
        self.assertAlmostEqual(aire(zone(cercle(500, 500, 100))), math.pi * 100 ** 2, delta=0.01 * math.pi * 1e4)
        self.assertAlmostEqual(aire(zone(rect(0, 0, 200, 100))), 20000, delta=1)
        self.assertAlmostEqual(aire(zone(rect(0, 0, 200, 100, r=20))), 20000 - (4 - math.pi) * 400, delta=5)

    def test_trou_et_miroir(self):
        anneau = zone(ellipse(500, 500, 200, 150), trou(ellipse(500, 500, 100, 80)))
        self.assertAlmostEqual(aire(anneau), math.pi * (200 * 150 - 100 * 80), delta=0.01 * math.pi * 22000)
        self.assertGreater(aire(zone(miroir(ellipse(300, 400, 80, 40)))), 0)

    def test_tube_ferme_et_sans_croisement(self):
        t = tube([(100, 500), (300, 420), (500, 520), (700, 440)], [20, 60, 60, 30])
        self.assertTrue(t[0].closed)
        self.assertEqual(croisements(t), [])
        self.assertGreater(t[0].area(), 0)

    def test_croisement_detecte(self):
        huit = zone(cercle(400, 500, 100), cercle(520, 500, 100))
        self.assertTrue(croisements(huit.contours))
        self.assertTrue(analyse.geometrie(page("x", "fete", "X", "Y", huit)))

    def test_hors_page_detecte(self):
        self.assertTrue(analyse.geometrie(page("x", "fete", "X", "Y", zone(cercle(20, 500, 100)))))

    def test_element_vide_interdit(self):
        with self.assertRaises(Exception):
            analyse.geometrie(page("x", "fete", "X", "Y", Element("zone", [])))


if __name__ == "__main__":
    unittest.main()
