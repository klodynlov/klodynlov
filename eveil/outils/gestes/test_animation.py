"""Tests des gestes animés de Lou (`animation.py`) et du Swift généré (`generer.py`).

    cd eveil/outils && python3 -m unittest gestes.test_animation
"""
from __future__ import annotations

import math
import unittest

from . import animation, generer
from .animation import (ARRIVEE, DEPART, FONDU, REPOS_BOUCHE, TRANSITION, adoucir, chronologie, enchainer,
                        etat, toutes, trace)
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

    def test_la_main_arrive_depuis_le_repos(self):
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


class TestSuites(unittest.TestCase):
    """Une suite de sons (17/11/2026) : enchaînés sans repasser par le repos."""

    SUITES = (("j", "u"), ("v", "oi"), ("ch", "ui", "ou"), ("a", "é", "d", "s"), ("s", "z"), ("p", "xyz", "l"))

    def test_un_seul_son_est_sa_chronologie(self):
        for son in ("a", "s", "ui"):
            self.assertEqual(enchainer([son]).chronologie, chronologie(son))
        self.assertEqual(enchainer([]).duree, 0.0)

    def test_duree_exacte(self):
        """Entre deux gestes : départ + arrivée remplacés par une transition."""
        for a, b in (("j", "u"), ("v", "oi"), ("s", "z")):
            self.assertAlmostEqual(enchainer([a, b]).duree,
                                   chronologie(a).duree + chronologie(b).duree - DEPART - ARRIVEE + TRANSITION, places=9)
        for sons in self.SUITES:
            su = enchainer(sons)
            self.assertEqual(su.duree, su.chronologie.cles[-1].t)
            self.assertEqual(len(su.debuts), len(sons))

    def test_debut_et_fin_au_repos(self):
        for sons in self.SUITES:
            ch = enchainer(sons).chronologie
            with self.subTest(sons=sons):
                for t in (0.0, ch.duree):
                    e = etat(ch, t)
                    self.assertEqual((e.bouche, e.vibre, e.leve, e.table), (REPOS_BOUCHE, False, 0.0, 0.0))
                    self.assertTrue(all(b.presence == 0.0 for b in e.bras))

    def test_la_main_ne_redescend_pas_entre_deux_sons(self):
        ch = enchainer(["j", "u"]).chronologie
        t = ARRIVEE + 0.01
        while t < ch.duree - DEPART:
            self.assertEqual(etat(ch, t).bras[0].presence, 1.0, f"à {t:.2f} s")
            t += 0.01

    def test_un_bras_qui_ne_sert_plus_part_en_fondu(self):
        su = enchainer(["v", "oi"])
        cotes = [f.cote for f in su.chronologie.bras]
        fin = etat(su.chronologie, su.duree - DEPART - 0.05)
        gauche = fin.bras[cotes.index("g")]
        self.assertEqual(gauche.presence, 0.0)
        self.assertGreater(gauche.poignet[1], 300)

    def test_rien_ne_saute_ni_ne_tourne(self):
        for sons in self.SUITES:
            ch = enchainer(sons).chronologie
            with self.subTest(sons=sons):
                avant = None
                for t in _pas(ch):
                    e = etat(ch, t)
                    self.assertTrue(0.0 <= e.fondu <= 1.0)
                    if avant is not None:
                        for a, b in zip(e.bras, avant.bras):
                            if a.presence > 0.3:
                                self.assertLess(math.dist(a.poignet, b.poignet), 15, f"à {t:.3f} s")
                                self.assertLess(abs(a.direction - b.direction), 12, f"à {t:.3f} s : la main tourne")
                    avant = e

    def test_bouche_en_fondu(self):
        ch = enchainer(["j", "u"]).chronologie
        changements = [k for a, k in zip(ch.cles, ch.cles[1:]) if a.bouche != k.bouche]
        self.assertTrue(changements)
        for k in changements:
            debut = etat(ch, k.t)
            self.assertEqual(debut.fondu, 0.0)
            milieu = etat(ch, k.t + FONDU / 2)
            self.assertAlmostEqual(milieu.fondu, 0.5, places=6)
            self.assertNotEqual(milieu.bouche_avant, milieu.bouche)
            self.assertEqual(etat(ch, k.t + FONDU + 0.001).fondu, 1.0)

    def test_adoucir(self):
        self.assertEqual((adoucir(0.0), adoucir(1.0)), (0.0, 1.0))
        self.assertAlmostEqual(adoucir(0.5), 0.5)
        h = 1e-6     # vitesse nulle aux bouts
        self.assertLess(adoucir(h) / h, 1e-6)
        self.assertLess((1 - adoucir(1 - h)) / h, 1e-6)

    def test_pas_d_arret_au_milieu_d_un_trace(self):
        """« s », « z » : le bout de l'index ne s'arrête pas entre deux clés du tracé."""
        for son in ("s", "z"):
            ch = chronologie(son)
            debut, fin = ch.cles[1].t, ch.t_pose
            n = 200
            pts = [etat(ch, debut + (fin - debut) * i / n).bras[0].bout() for i in range(n + 1)]
            vit = [math.dist(a, b) for a, b in zip(pts, pts[1:])]
            milieu = vit[n // 4: -n // 4]          # (aux bouts, le tracé démarre et finit en douceur)
            self.assertGreater(min(milieu), 0.3 * max(milieu), son)


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
                if "static " in ligne or ligne.startswith(("struct ", "enum ", "extension ")):
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
            self.assertIn(f'keys: ["{son}"]', vec)
        for sons in generer.SUITES_PARITE:
            self.assertIn("keys: [" + ", ".join(f'"{s}"' for s in sons) + "]", vec)


if __name__ == "__main__":
    unittest.main()
