"""Album « Miam ! » : ce qui se mange et se boit.

(La glace est dessinée à la main dans l'app : PagesThings.swift.)
"""
from __future__ import annotations

import math

from .dessin import (
    Contour, arc, cercle, coeur, courbe, detail, ellipse, encre, goutte, ligne, lisse, page, poly, rect,
    tourne, trait, trou, tube, zone,
)
from .motifs import feuille, nuage, soleil


def fourchette(x: float, y: float, longueur: float, angle: float) -> list:
    """Fourchette debout, manche en (x, y), inclinée de `angle` degrés."""
    def t(f):
        return tourne(f, angle, x, y)
    h = y - longueur
    return [
        detail(t(tube([(x - 26, h + 104), (x - 26, h)], 18))),
        detail(t(tube([(x, h + 104), (x, h)], 18))),
        detail(t(tube([(x + 26, h + 104), (x + 26, h)], 18))),
        zone(t(rect(x - 44, h + 84, 88, 84, r=30))),
        zone(t(tube([(x, h + 150), (x, y)], 36))),
    ]


SAUCISSE = page(
    "saucisse", "miam", "La saucisse", "The sausage",
    trait(*[ligne((x, 0), (x, 1000)) for x in (250, 500, 750)], *[ligne((0, y), (1000, y)) for y in (250, 500, 870)]),
    zone(ellipse(470, 600, 410, 200)),
    zone(ellipse(470, 590, 305, 136)),
    zone(tube([(270, 540), (380, 500), (540, 500), (660, 536)], 86)),
    zone(tube([(300, 634), (430, 598), (580, 604), (690, 640)], 86)),
    trait(ligne((460, 480), (440, 520)), ligne((520, 482), (500, 522)), ligne((580, 490), (560, 530))),
    trait(courbe([(370, 616), (420, 600), (470, 614), (520, 600), (570, 616)])),
    *fourchette(930, 975, 390, -6),
)


TASSE = page(
    "tasse", "miam", "La tasse de chocolat", "The cup of cocoa",
    zone(rect(0, 820, 1000, 180)),
    zone(ellipse(470, 822, 330, 72)),
    zone(ellipse(470, 812, 200, 38)),
    zone(ellipse(742, 560, 104, 122), trou(ellipse(742, 560, 52, 70))),
    zone(poly([(240, 420), (700, 420), (645, 792), (295, 792)], r=[10, 10, 100, 100])),
    zone(ellipse(470, 420, 232, 50)),
    zone(ellipse(470, 428, 200, 36)),
    zone(coeur(470, 600, 76)),
    trait(courbe([(400, 350), (380, 300), (410, 250), (390, 200)]),
          courbe([(470, 340), (450, 290), (480, 240), (460, 190)]),
          courbe([(540, 350), (520, 300), (550, 250), (530, 200)])),
    zone(cercle(840, 860, 80)),
    encre(cercle(812, 832, 13), cercle(862, 862, 13), cercle(820, 894, 12), cercle(872, 818, 11)),
)


def glacage(x0: float, x1: float, y0: float, yb: float, gouttes: int = 7) -> list:
    """Nappage : bord haut droit, gouttes en bas."""
    pts = [(x1 + 8, yb)]
    for i in range(1, 2 * gouttes):
        x = x1 + 8 - (x1 - x0 + 16) * i / (2 * gouttes)
        pts.append((x, yb + (42 if i % 2 else 0)))
    pts.append((x0 - 8, yb))
    c = courbe(pts)[0]
    return [Contour((x0 - 8, y0 - 8), [("L", (x1 + 8, y0 - 8)), ("L", c.start)] + c.segs)]


GATEAU = page(
    "gateau", "miam", "Le gâteau d'anniversaire", "The birthday cake",
    zone(ellipse(500, 872, 400, 56)),
    zone(rect(200, 620, 600, 250, r=24)),
    zone(glacage(200, 800, 620, 680)),
    detail(*[cercle(x, 796, 22) for x in (270, 370, 470, 570, 670, 740)]),
    zone(rect(310, 440, 380, 200, r=24)),
    zone(glacage(310, 690, 440, 490, gouttes=5)),
    zone(coeur(500, 576, 48)),
    *[e for x in (400, 500, 600) for e in (
        zone(rect(x - 23, 318, 46, 128, r=10)),
        trait(ligne((x, 318), (x, 298))),
        detail(goutte(x, 276, 21, 54)),
    )],
    trait(ligne((110, 180), (150, 220)), ligne((150, 180), (110, 220)), ligne((850, 200), (890, 240)),
          ligne((890, 200), (850, 240)), ligne((180, 420), (220, 420)), ligne((200, 400), (200, 440)),
          ligne((780, 380), (820, 380)), ligne((800, 360), (800, 400))),
)


GLACONS = page(
    "glacons", "miam", "Les glaçons", "The ice cubes",
    *soleil(130, 120, 56),
    zone(rect(0, 860, 1000, 140)),
    zone(poly([(300, 300), (700, 300), (660, 862), (340, 862)], r=[6, 6, 36, 36])),
    zone(poly([(318, 432), (682, 432), (646, 844), (354, 844)], r=[0, 0, 26, 26])),
    zone(tube([(560, 760), (600, 330), (650, 212), (730, 172)], 38)),
    zone(tourne(rect(350, 356, 128, 128, r=24), -14, 414, 420)),
    zone(tourne(rect(504, 390, 122, 122, r=24), 12, 565, 451)),
    zone(tourne(rect(418, 522, 118, 118, r=24), 6, 477, 581)),
    zone(cercle(690, 300, 76)),
    zone(cercle(690, 300, 58)),
    trait(*[ligne((690 + 14 * math.cos(math.radians(a)), 300 + 14 * math.sin(math.radians(a))),
                  (690 + 50 * math.cos(math.radians(a)), 300 + 50 * math.sin(math.radians(a))))
            for a in range(0, 360, 60)]),
    zone(tourne(rect(756, 750, 108, 108, r=22), 10, 810, 804)),
    zone(tourne(rect(152, 764, 100, 100, r=20), -8, 202, 814)),
)


ASSIETTE = page(
    "assiette", "miam", "L'assiette", "The dish",
    zone(rect(40, 140, 920, 720, r=50)),
    trait(ligne((40, 210), (960, 210)), ligne((40, 790), (960, 790))),
    zone(cercle(500, 500, 300)),
    zone(cercle(500, 500, 225)),
    zone(lisse([(330, 420), (380, 340), (470, 328), (532, 380), (522, 462), (450, 522), (362, 510)])),
    zone(cercle(440, 422, 52)),
    zone(tourne(rect(346, 576, 156, 42, r=20), 18, 424, 597)),
    zone(tourne(rect(366, 640, 150, 42, r=20), -12, 441, 661)),
    detail(cercle(560, 598, 24), cercle(612, 620, 24), cercle(580, 658, 23)),
    detail(rect(622, 430, 42, 80, r=10)),
    nuage(643, 408, 66, 46, bosses=6),
    *fourchette(130, 800, 520, 0),
    zone(poly([(852, 580), (852, 300), (880, 288), (908, 330), (892, 580)], r=[0, 12, 20, 20, 0])),
    zone(rect(846, 560, 52, 240, r=22)),
)


PECHE = page(
    "peche", "miam", "La pêche", "The peach",
    zone(rect(0, 820, 1000, 180)),
    zone(ellipse(430, 830, 330, 60)),
    # la tige et sa feuille
    detail(tube([(430, 296), (446, 206)], 30)),
    zone(feuille((446, 214), (590, 118), 104)),
    trait(ligne((462, 206), (570, 132))),
    # la grosse pêche
    zone(lisse([(430, 300), (520, 262), (620, 300), (680, 420), (660, 580), (560, 700), (430, 730), (300, 700),
                (200, 580), (180, 420), (240, 300), (340, 262)])),
    trait(courbe([(430, 306), (380, 420), (380, 560), (430, 690)])),
    # une moitié de pêche et son noyau
    zone(cercle(800, 740, 130)),
    zone(cercle(800, 740, 100)),
    zone(lisse([(800, 676), (842, 712), (846, 770), (800, 806), (754, 770), (758, 712)])),
    trait(courbe([(800, 690), (790, 740), (800, 792)])),
)


def forme_os(xl: float, xr: float, cy: float, R: float, d: float, h: float) -> list:
    """Un os de dessin animé d'un seul contour : deux lobes à chaque bout, reliés par la tige."""
    s = math.sqrt(R * R - (d - h) ** 2)
    n = math.sqrt(R * R - d * d)
    tb = math.degrees(math.atan2(d - h, -s))          # angle du point de jonction haut, vu du lobe haut
    tc = math.degrees(math.atan2(d, n))                # angle de l'encoche, vu du lobe haut
    segs = [("L", (xr - s, cy - h))]
    segs += arc(xr, cy - d, R, tb, tc + 360)[0].segs
    segs += arc(xr, cy + d, R, -tc, 360 - tb)[0].segs
    segs += [("L", (xl + s, cy + h))]
    segs += arc(xl, cy + d, R, 180 - (360 - tb), 180 + tc)[0].segs
    segs += arc(xl, cy - d, R, 180 - tc, 180 + (360 - tb) - 360 + 360)[0].segs
    c = Contour((xl + s, cy - h), segs)
    return [c if c.area() > 0 else c.reversed()]


def patte(cx: float, cy: float, k: float = 1.0) -> list:
    """Empreinte de patte (encre) : un coussinet et quatre doigts."""
    return [ellipse(cx, cy, 36 * k, 28 * k)] + [cercle(cx + dx * k, cy + dy * k, 12 * k)
                                                 for dx, dy in [(-56, -46), (-20, -70), (20, -70), (56, -46)]]


OS = page(
    "os", "miam", "L'os du chien", "The dog's bone",
    zone(rect(0, 820, 1000, 180)),
    encre(*patte(160, 200), *patte(300, 120, 0.9), *patte(820, 170, 0.9)),
    # la gamelle
    zone(poly([(560, 700), (940, 700), (900, 850), (600, 850)], r=[10, 10, 30, 30])),
    zone(ellipse(750, 700, 190, 40)),
    zone(ellipse(750, 700, 160, 26)),
    # le gros os
    zone(tourne(forme_os(230, 690, 470, 70, 52, 34), -18, 460, 470)),
    trait(tourne(arc(250, 410, 40, 200, 260), -18, 460, 470)),
    # un petit os près de la gamelle
    zone(tourne(forme_os(170, 400, 760, 42, 30, 20), 8, 285, 760)),
)


JUS = page(
    "jus", "miam", "Le jus d'orange", "The orange juice",
    *soleil(870, 120, 52),
    zone(rect(0, 850, 1000, 150)),
    # la paille (derrière le verre), le verre, le jus (mêmes bords que le verre)
    zone(tube([(470, 760), (500, 300), (560, 180), (640, 160)], 40)),
    zone(poly([(290, 320), (650, 320), (610, 852), (330, 852)], r=[6, 6, 30, 30])),
    zone(poly([(290 + 40 * 100 / 532, 420), (650 - 40 * 100 / 532, 420), (610, 852), (330, 852)], r=[0, 0, 30, 30])),
    trait(courbe([(340, 470), (400, 456), (460, 470)]), courbe([(470, 520), (530, 506), (590, 520)])),
    # la rondelle d'orange sur le bord du verre
    zone(cercle(650, 316, 122)),
    zone(cercle(650, 316, 100)),
    trait(*[ligne((650, 316), (650 + 100 * math.cos(math.radians(a)), 316 + 100 * math.sin(math.radians(a))))
            for a in range(0, 360, 60)]),
    # une orange entière
    zone(cercle(840, 740, 110)),
    zone(feuille((840, 630), (920, 560), 64)),
    encre(cercle(840, 632, 9)),
)


PAGES = [SAUCISSE, TASSE, GATEAU, GLACONS, ASSIETTE, PECHE, OS, JUS]
