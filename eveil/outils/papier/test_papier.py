"""Tests du mode papier sur des photos simulées : la mise en page, l'homographie, les repères (même en
perspective, sous une lumière chaude, avec un coin du dessin colorié en noir, feuille de côté ou à
l'envers), l'accord avec la page, et les coups de crayon retrouvés.

    cd eveil/outils && python3 -m unittest papier.test_papier -v
"""
from __future__ import annotations

import unittest

from coloriages import zones

from . import mise_en_page as mp, recaler, reperes
from .homographie import appliquer, homographie, inverse
from .image import Image
from .planche import scenario


class TestMiseEnPage(unittest.TestCase):
    def test_reperes_imprimables_et_hors_du_dessin(self):
        s = mp.REPERE / 2
        for x, y in mp.reperes_page():
            self.assertGreaterEqual(min(x - s, y - s, mp.PAGE_L - x - s, mp.PAGE_H - y - s), mp.MARGE_IMPRIMABLE)
            u, v = mp.page_vers_unite(x, y)
            self.assertTrue(u < 0 or u > 1 or v < 0 or v > 1)
        self.assertLess(mp.TITRE_Y, mp.Y0 - mp.ECART - s)       # le titre au-dessus des repères du haut

    def test_aller_retour(self):
        for p in ((0, 0), (0.3, 0.7), (1, 1)):
            self.assertAlmostEqual(mp.page_vers_unite(*mp.unite_vers_page(*p))[0], p[0])


class TestHomographie(unittest.TestCase):
    def test_retrouve_la_transformation(self):
        H = [[1.02, 0.05, 12.0], [-0.03, 0.98, 20.0], [0.0001, 0.00005, 1.0]]
        src = [(0, 0), (595, 0), (595, 842), (0, 842)]
        H2 = homographie(src, [appliquer(H, p) for p in src])
        for p in ((100, 100), (300, 500), (590, 20)):
            a, b = appliquer(H, p), appliquer(H2, p)
            self.assertAlmostEqual(a[0], b[0], places=6)
            self.assertAlmostEqual(a[1], b[1], places=6)
            c = appliquer(inverse(H2), b)
            self.assertAlmostEqual(c[0], p[0], places=6)
            self.assertAlmostEqual(c[1], p[1], places=6)

    def test_points_alignes_refuses(self):
        with self.assertRaises(ValueError):
            homographie([(0, 0), (1, 1), (2, 2), (3, 3)], [(0, 0), (1, 0), (1, 1), (0, 1)])


class TestPhoto(unittest.TestCase):
    """Une page coloriée, imprimée puis photographiée de travers, dans les conditions de l'app : photo
    à 1,6 px par point, carré redressé à la taille de la carte des zones (1024) (≈ 25 s)."""

    @classmethod
    def setUpClass(cls):
        (cls.a, cls.photo, cls.trouves, cls.vrais, cls.rect, cls.paint, cls.cn,
         cls.couleurs, cls.c) = scenario("locomotive", res=1.6, n=1024)

    def test_reperes_retrouves(self):
        self.assertIsNotNone(self.trouves)
        for (tx, ty), (vx, vy) in zip(self.trouves, self.vrais):
            self.assertLess(((tx - vx) ** 2 + (ty - vy) ** 2) ** 0.5, 0.005 * self.photo.W)

    def test_la_bonne_page_et_pas_une_autre(self):
        self.assertGreater(recaler.accord(self.rect, self.cn.labels), 0.8)
        self.assertGreater(recaler.accord(self.rect, self.cn.labels), recaler.ACCORD_MIN)
        from coloriages import analyse, catalogue
        autre = analyse.analyser(next(p for p in catalogue.PAGES if p.id == "minouche"), variantes=False)
        labels = zones.carte(autre.traits, taille=self.rect.W).labels
        self.assertLess(recaler.accord(self.rect, labels), 0.35)

    def test_les_coups_de_crayon(self):
        """Chaque zone coloriée ressort de sa couleur (balance des blancs faite) ; une zone blanche reste
        transparente ; aucun trait n'est peint."""
        n = self.rect.W
        k = self.c.W / n
        # Les pixels du carré n × n, rangés par zone de la page imprimée (carte au côté du carré imprimé).
        total, peints = {}, {}
        for i in range(n * n):
            if not self.cn.labels[i]:
                continue
            z = self.c.labels[int((i // n + 0.5) * k) * self.c.W + int((i % n + 0.5) * k)]
            total[z] = total.get(z, 0) + 1
            if self.paint[i]:
                peints.setdefault(z, []).append(self.paint[i])
        for z, rgb in self.couleurs.items():
            if total.get(z, 0) < 30:
                continue
            p = peints.get(z, [])
            self.assertGreater(len(p) / total[z], 0.6, f"zone {z}")
            med = [sorted(q[c] for q in p)[len(p) // 2] for c in range(3)]
            self.assertLess(max(abs(med[c] - rgb[c]) for c in range(3)), 60, f"zone {z} : {med} ≠ {rgb}")
        blanches = [z for z in range(1, self.c.zones + 1) if z not in self.couleurs and self.c.part(z) > 0.01]
        for z in blanches:
            if total.get(z):
                self.assertLess(len(peints.get(z, [])) / total[z], 0.08, f"zone blanche {z}")
        self.assertFalse(any(self.paint[i] for i in range(n * n) if self.cn.labels[i] == 0))


class TestSens(unittest.TestCase):
    """Une feuille photographiée de côté ou à l'envers (l'enfant assis en face de l'adulte) se lit
    dans le bon sens, sans tourner la photo : les places attendues des repères sont ramenées dessus."""

    def test_quarts_de_tour_coherents(self):
        img = Image(3, 2, bytearray(range(18)))
        for q in range(4):
            t = img.tourner(q)
            for y in range(t.H):
                for x in range(t.W):
                    sx, sy = reperes.depuis_droite(x + 0.5, y + 0.5, q, img.W, img.H)
                    self.assertEqual(t.get(x, y), img.get(int(sx), int(sy)), f"{q} quart(s), ({x}, {y})")

    def test_feuille_de_cote_ou_a_l_envers(self):
        _, photo, _, _, _, _, cn, _, _ = scenario("locomotive")
        for q in (0, 1, 2, 3):
            a, sens, rep, _ = recaler.lire(photo.tourner(q), cn.labels, cn.W)
            self.assertEqual(sens, (4 - q) % 4, f"photo tournée de {q} quart(s)")
            self.assertGreater(a, 0.8, f"photo tournée de {q} quart(s)")


class TestPiegesDePhoto(unittest.TestCase):
    def test_un_coin_colorie_en_noir_ne_trompe_pas(self):
        _, photo, trouves, vrais, *_ = scenario("minouche", noir_au_coin=True)
        self.assertIsNotNone(trouves)
        for (tx, ty), (vx, vy) in zip(trouves, vrais):
            self.assertLess(((tx - vx) ** 2 + (ty - vy) ** 2) ** 0.5, 0.005 * photo.W)

    def test_repere_coupe(self):
        """Un coin coupé : pas de repères ; la page entière sert de repère (la photo du scanner l'est)."""
        img = Image(300, 424)
        self.assertIsNone(reperes.trouver(img))
        coins = reperes.sans_reperes(img)
        self.assertAlmostEqual(coins[0][0], mp.reperes_page()[0][0] * 300 / mp.PAGE_L)


if __name__ == "__main__":
    unittest.main()
