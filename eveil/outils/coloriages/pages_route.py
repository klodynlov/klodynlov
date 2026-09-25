"""Album « En route ! » : ce qui roule, vole ou avance.

(Le bateau et la fusée sont dessinés à la main dans l'app : PagesThings.swift.)
"""
from __future__ import annotations


from .dessin import (
    arc, arche, cercle, corde, detail, ellipse, encre, etoile, ligne, page,
    poly, rect, trait, tube, zone,
)
from .motifs import arbre, fleur, nuage, roue, sol, soleil


def route(y: float) -> list:
    """Route jusqu'en bas de la page et ses pointillés."""
    return [zone(rect(0, y, 1000, 1000 - y)),
            trait(*[ligne((x, y + 150), (min(x + 110, 1000), y + 150)) for x in range(40, 1000, 220)])]


BUS = page(
    "bus", "route", "Le bus", "The bus",
    *soleil(120, 110, 50),
    nuage(700, 120, 110, 48),
    *route(790),
    zone(rect(70, 300, 860, 432, r=50)),
    zone(rect(70, 572, 860, 46)),
    zone(rect(95, 340, 124, 200, r=22)),
    zone(rect(244, 340, 104, 360, r=14)),
    trait(ligne((296, 352), (296, 688))),
    zone(rect(376, 340, 130, 136, r=18), rect(526, 340, 130, 136, r=18), rect(676, 340, 130, 136, r=18),
         rect(826, 340, 84, 136, r=18)),
    zone(cercle(441, 424, 48)), zone(cercle(741, 424, 48)),
    trait(arc(441, 438, 20, 30, 150), arc(741, 438, 20, 30, 150)),
    encre(cercle(426, 414, 7), cercle(456, 414, 7), cercle(726, 414, 7), cercle(756, 414, 7)),
    zone(corde(250, 732, 104, 180, 360), corde(760, 732, 104, 180, 360)),
    *roue(250, 736, 82, rayons=6), *roue(760, 736, 82, rayons=6),
    detail(ellipse(96, 652, 22, 34)),
    detail(rect(46, 690, 78, 44, r=14)),
    detail(ellipse(56, 420, 22, 38)),
)


VOITURE = page(
    "voiture", "route", "La voiture", "The car",
    *soleil(130, 120, 56),
    nuage(560, 130, 110, 48),
    *arbre(880, 690, 400, 190),
    *route(665),
    zone(poly([(300, 422), (362, 300), (600, 300), (702, 422)], r=[10, 30, 30, 10])),
    zone(poly([(330, 418), (382, 330), (490, 330), (490, 418)], r=10)),
    zone(poly([(515, 418), (515, 330), (590, 330), (662, 418)], r=10)),
    zone(rect(150, 410, 700, 172, r=60)),
    trait(ligne((502, 426), (502, 562))),
    detail(rect(520, 442, 54, 18, r=9)),
    zone(corde(300, 582, 96, 180, 360), corde(700, 582, 96, 180, 360)),
    *roue(300, 590, 78, rayons=6), *roue(700, 590, 78, rayons=6),
    detail(ellipse(830, 470, 20, 30)),
    detail(rect(150, 446, 28, 48, r=8)),
    detail(rect(806, 540, 74, 38, r=14), rect(120, 540, 74, 38, r=14)),
)


AVION = page(
    "avion", "route", "L'avion", "The plane",
    *soleil(120, 120, 56),
    nuage(760, 150, 130, 55), nuage(230, 800, 150, 60, bosses=8), nuage(800, 830, 120, 50),
    zone(poly([(215, 470), (150, 285), (232, 285), (330, 452)], r=[10, 16, 16, 10])),
    zone(ellipse(872, 416, 22, 76)), zone(ellipse(872, 576, 22, 76)),
    zone(tube([(210, 496), (790, 496)], 150)),
    zone(rect(640, 440, 110, 54, r=22)),
    detail(cercle(330, 482, 26), cercle(410, 482, 26), cercle(490, 482, 26), cercle(570, 482, 26)),
    zone(poly([(420, 520), (570, 520), (505, 704), (430, 704)], r=[10, 10, 16, 16])),
    detail(cercle(868, 496, 34)),
    trait(ligne((60, 470), (130, 470)), ligne((40, 520), (120, 520))),
)


BROUETTE = page(
    "brouette", "route", "La brouette du jardinier", "The gardener's wheelbarrow",
    *soleil(860, 130, 60),
    nuage(300, 140, 110, 50),
    sol(800, vague=12),
    detail(rect(330, 612, 30, 180, r=10)),
    zone(tube([(620, 646), (560, 636), (300, 606), (120, 592)], 38)),
    detail(rect(66, 570, 96, 44, r=20)),
    # ce qu'elle transporte : des choux et des carottes
    zone(cercle(440, 368, 60)), zone(cercle(566, 368, 60)),
    zone(cercle(360, 440, 64)), zone(cercle(496, 420, 66)), zone(cercle(630, 440, 64)),
    trait(arc(496, 420, 38, 200, 340), arc(360, 436, 36, 200, 340), arc(630, 436, 36, 200, 340)),
    zone(poly([(250, 470), (730, 470), (662, 652), (320, 652)], r=[14, 14, 24, 24])),
    zone(rect(232, 452, 516, 40, r=16)),
    *roue(740, 700, 90, rayons=6),
    *fleur(110, 890, 46), *fleur(910, 900, 44),
)


POLICE = page(
    "police", "route", "La voiture de police", "The police car",
    *soleil(120, 110, 50),
    nuage(760, 130, 120, 50),
    *route(700),
    # le gyrophare et ses éclats
    trait(ligne((470, 176), (452, 140)), ligne((530, 176), (548, 140)), ligne((500, 170), (500, 128)),
          ligne((440, 206), (396, 196)), ligne((560, 206), (604, 196))),
    zone(rect(436, 188, 128, 70, r=24)),
    detail(rect(420, 240, 160, 30, r=10)),
    # la cabine, les vitres, la carrosserie, la bande bleue
    zone(poly([(270, 440), (350, 266), (650, 266), (770, 440)], r=[10, 36, 36, 10])),
    zone(poly([(304, 432), (370, 294), (488, 294), (488, 432)], r=12)),
    zone(poly([(512, 432), (512, 294), (630, 294), (730, 432)], r=12)),
    zone(rect(110, 424, 780, 200, r=64)),
    zone(rect(110, 484, 780, 50)),
    trait(ligne((500, 436), (500, 484))),
    detail(rect(520, 446, 54, 18, r=9), rect(426, 446, 54, 18, r=9)),
    detail(ellipse(862, 468, 22, 30), ellipse(136, 468, 20, 30)),
    zone(corde(290, 624, 100, 180, 360), corde(710, 624, 100, 180, 360)),
    *roue(290, 632, 80, rayons=5), *roue(710, 632, 80, rayons=5),
    detail(rect(80, 588, 76, 40, r=14), rect(844, 588, 76, 40, r=14)),
    # un cône de chantier
    zone(poly([(870, 910), (960, 910), (924, 760), (906, 760)], r=[6, 6, 8, 8])),
    zone(rect(846, 900, 138, 36, r=10)),
)


CARROSSE = page(
    "carrosse", "route", "Le carrosse", "The golden coach",
    detail(etoile(130, 150, 54), etoile(880, 130, 48), etoile(900, 420, 38), etoile(90, 440, 40)),
    sol(850, vague=10),
    # l'essieu, les roues
    zone(tube([(260, 764), (740, 764)], 34)),
    *roue(260, 760, 110, rayons=8, moyeu=0.16), *roue(740, 760, 110, rayons=8, moyeu=0.16),
    # la caisse en citrouille : deux côtes, puis celle du milieu, devant
    zone(ellipse(372, 506, 140, 200)),
    zone(ellipse(628, 506, 140, 200)),
    zone(ellipse(500, 502, 150, 214)),
    zone(arche(436, 430, 128, 222)),
    zone(arche(456, 452, 88, 100)),
    detail(cercle(526, 592, 17)),
    # la couronne
    zone(poly([(410, 316), (410, 230), (450, 266), (500, 206), (550, 266), (590, 230), (590, 316)],
              r=[6, 8, 8, 8, 8, 8, 6])),
    zone(rect(396, 296, 208, 40, r=14)),
    detail(cercle(500, 250, 16)),
    detail(rect(206, 690, 76, 30, r=12), rect(718, 690, 76, 30, r=12)),
)


PAGES = [BUS, VOITURE, AVION, BROUETTE, POLICE, CARROSSE]
