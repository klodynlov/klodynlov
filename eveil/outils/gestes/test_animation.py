"""Tests des gestes animés de Lou (`animation.py`) et du Swift généré (`generer.py`).

    cd eveil/outils && python3 -m unittest gestes.test_animation
"""
from __future__ import annotations

import math
import unittest

from . import animation, generer
from .animation import ARRIVEE, DEPART, REPOS_BOUCHE, chronologie, etat, toutes, trace
from .dessins import SCENES, vibre
from .gestes import TOUS
from .lou_portrait import FORMES, PEAUX

PAR_SON = {g.son: g for g in TOUS}


def _pas(ch, n_par_s: int = 120):
    """Les instants, image par image."""
    n = int(ch.duree * n_par_s)
    return [ch.duree * i / n for i in range(n + 1)]


class TestChronologies(unittest.TestCase):
    def test_chaque_son_de_la_planche_a_une_chronologie(self):
        self.assertEqual(set(toutes()), set(SCENES))
        for son, ch in toutes().items():
            with self.subTest(son=son):
                self.assertTrue(ch.geste)
                self.assertGreaterEqual(len(ch.cles), 4)
                self.assertEqual([k.t for k in ch.cles], sorted(k.t for k in ch.cles))
                self.assertEqual(ch.cles[0].t, 0.0)
                self.assertEqual(ch.cles[-1].t, ch.duree)
                for k in ch.cles:
                    self.assertEqual(len(k.poses), len(ch.bras))
                    for p in k.poses:
                        self.assertIn(p.forme, FORMES)

    def test_deterministe(self):
        self.assertEqual(toutes(), toutes())
        self.assertEqual(generer.sorties(), generer.sorties())

    def test_durees(self):
        for son, ch in toutes().items():
            with self.subTest(son=son):
                self.assertGreaterEqual(ch.duree, 0.6)
                self.assertLessEqual(ch.duree, 2.5)
        self.assertGreater(chronologie("s").duree, chronologie("z").duree)
        # « s » : le tracé lent dure ~1,6 s ; « z » : ~0,7 s.
        self.assertAlmostEqual(chronologie("s").duree - ARRIVEE - DEPART, 1.7, places=6)

    def test_debut_et_fin_au_repos(self):
        for son, ch in {**toutes(), **animation.sans_geste()}.items():
            with self.subTest(son=son):
                for t in (0.0, ch.duree):
                    e = etat(ch, t)
                    self.assertEqual(e.bouche, REPOS_BOUCHE)
                    self.assertFalse(e.vibre)
                    self.assertEqual((e.leve, e.table), (0.0, 0.0))
                    for b in e.bras:
                        self.assertEqual(b.presence, 0.0)
                        self.assertGreater(b.poignet[1], 300, "au repos, la main est sous le cadre")

    def test_la_pose_dessinee_est_tenue(self):
        """Les gestes immobiles passent EXACTEMENT par la pose de la planche (poignet, coude, direction)."""
        for son, ch in toutes().items():
            if son in animation.PROGRAMMES:
                continue
            with self.subTest(son=son):
                e = etat(ch, ch.t_pose)
                for b, sb in zip(e.bras, SCENES[son].bras):
                    self.assertLess(math.dist(b.poignet, sb.main.poignet), 0.01)
                    self.assertLess(math.dist(b.coude, sb.coude), 0.01)
                    self.assertAlmostEqual((b.direction - sb.main.direction) % 360, 0.0, places=2)
                    self.assertEqual(b.forme_a, sb.main.forme)
                self.assertEqual(e.bouche, PAR_SON[son].bouche)
                self.assertEqual(e.vibre, vibre(PAR_SON[son]))

    def test_la_main_arrive_en_0_35_s(self):
        for son, ch in toutes().items():
            with self.subTest(son=son):
                self.assertEqual(ch.cles[1].t, ARRIVEE)
                self.assertTrue(all(p.presence == 1.0 for p in ch.cles[1].poses))
                self.assertAlmostEqual(ch.duree - ch.cles[-2].t, DEPART, places=6)

    def test_les_temps_sont_les_vignettes(self):
        for son, sc in SCENES.items():
            if not sc.vignettes:
                continue
            with self.subTest(son=son):
                formes = []
                for k in chronologie(son).cles[1:-1]:
                    f = k.poses[0].forme
                    if not formes or formes[-1] != f:
                        formes.append(f)
                self.assertEqual(tuple(formes), sc.vignettes)

    def test_trajectoire_par_les_points_des_fleches(self):
        """« s », « z » : le bout de l'index passe par chaque point de la flèche ; les autres
        flèches : la main se déplace exactement du vecteur de la flèche (à un décalage près)."""
        for son in ("s", "z"):
            ch = chronologie(son)
            bouts = [etat(ch, k.t).bras[0].bout() for k in ch.cles]
            for p in SCENES[son].fleches[0].pts:
                with self.subTest(son=son, point=p):
                    self.assertLess(min(math.dist(p, q) for q in bouts), 0.02)
        for son in ("j", "k", "g", "l", "f", "ill", "ou", "b", "m", "gn"):
            ch = chronologie(son)
            pts = SCENES[son].fleches[0].pts
            bouts = [etat(ch, k.t).bras[0].bout() for k in ch.cles[1:-1]]
            ecart = (pts[-1][0] - pts[0][0], pts[-1][1] - pts[0][1])
            with self.subTest(son=son):
                # La main parcourt (au moins) la longueur de la flèche, dans sa direction.
                xs = [q[0] for q in bouts]
                ys = [q[1] for q in bouts]
                self.assertGreaterEqual(max(xs) - min(xs) + 0.05, abs(ecart[0]))
                self.assertGreaterEqual(max(ys) - min(ys) + 0.05, abs(ecart[1]))
        # Le tracé suivi est celui que dessine la flèche (courbe passant par ses points).
        for son in ("s", "z", "ou", "b"):
            dense = trace(SCENES[son].fleches[0].pts)
            for p in SCENES[son].fleches[0].pts:
                self.assertLess(min(math.dist(p, q) for q in dense), 1e-6)

    def test_rien_ne_saute(self):
        """À 120 images/s, la main avance de moins de 15 px par image (1 800 px/s) ; le bras garde une allure de bras."""
        for son, ch in toutes().items():
            with self.subTest(son=son):
                avant = None
                for t in _pas(ch):
                    e = etat(ch, t)
                    for i, b in enumerate(e.bras):
                        fore = math.dist(b.coude, b.poignet)
                        self.assertGreater(fore, 25)
                        self.assertLess(fore, 140)
                        if avant is not None and b.presence > 0.3:
                            self.assertLess(math.dist(b.poignet, avant.bras[i].poignet), 15, f"à {t:.3f} s")
                    avant = e

    def test_d_l_autre_main_dans_le_dos(self):
        ch = chronologie("d")
        self.assertEqual([f.derriere for f in ch.bras], [False, True])

    def test_sans_geste_la_bouche_seule(self):
        ch = chronologie("ui")
        self.assertFalse(ch.geste)
        self.assertEqual(ch.bras, ())
        self.assertEqual(etat(ch, 0.5).bouche, PAR_SON["ui"].bouche)
        self.assertIsNone(chronologie("xyz"))


class TestGenere(unittest.TestCase):
    def test_fichiers_swift_a_jour(self):
        for chemin, source in generer.sorties().items():
            with self.subTest(fichier=chemin.name):
                self.assertTrue(chemin.exists(), "python3 -m gestes.generer")
                self.assertEqual(chemin.read_text(encoding="utf-8"), source, "python3 -m gestes.generer")

    def test_jamais_un_litteral_geant(self):
        """Une fonction par élément : aucune fonction générée de plus de 80 lignes."""
        for chemin, source in generer.sorties().items():
            longueur, plus_long = 0, 0
            for ligne in source.splitlines():
                if "static func" in ligne:
                    longueur = 0
                longueur += 1
                plus_long = max(plus_long, longueur)
            with self.subTest(fichier=chemin.name):
                self.assertLess(plus_long, 80)

    def test_couleurs_de_peau_en_jetons(self):
        art = generer.source_art()
        for jeton in (".skin", ".shade", ".lips"):
            self.assertIn(jeton, art)
        # Aucune couleur de peau écrite en dur dans les parties fixes.
        for _, hexa in PEAUX:
            self.assertNotIn(f".fixed(0x{hexa[1:].upper()})", art)

    def test_vecteurs_de_parite(self):
        vec = generer.source_vecteurs()
        for son in generer.SONS_PARITE:
            self.assertIn(f'key: "{son}"', vec)


if __name__ == "__main__":
    unittest.main()
