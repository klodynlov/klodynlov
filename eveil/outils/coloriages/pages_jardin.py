"""Album « Le jardin » : petites bêtes, fleurs, fruits et légumes.

(La mouche, la ruche, le papillon, les fleurs et l'escargot sont dessinés à la main
dans l'app : PagesAnimals.swift, PagesThings.swift.)
"""
from __future__ import annotations


from .dessin import (
    arc, cercle, corde, courbe, detail, ellipse, encre, goutte, ligne, lisse, page, poly, rect, tourne,
    trait, tube, zone,
)
from .motifs import feuille, fleur, herbe, nuage, oeil, sol, soleil

COCCINELLE = page(
    "coccinelle", "jardin", "La coccinelle", "The ladybug",
    zone(feuille((110, 910), (910, 140), 600)),
    trait(ligne((160, 852), (852, 198))),
    trait(ligne((330, 470), (250, 430)), ligne((310, 560), (220, 560)), ligne((330, 650), (250, 700)),
          ligne((670, 470), (750, 430)), ligne((690, 560), (780, 560)), ligne((670, 650), (750, 700))),
    trait(courbe([(476, 250), (460, 214), (446, 198)]), courbe([(524, 250), (540, 214), (554, 198)])),
    encre(cercle(442, 194, 16), cercle(558, 194, 16)),
    zone(cercle(500, 326, 104)),
    zone(cercle(500, 540, 210)),
    trait(ligne((500, 335), (500, 748))),
    detail(cercle(410, 450, 42), cercle(380, 594, 38), cercle(446, 682, 32),
           cercle(590, 450, 42), cercle(620, 594, 38), cercle(554, 682, 32)),
    *oeil(462, 284, 30, dy=2, p=0.5), *oeil(538, 284, 30, dy=2, p=0.5),
)


TORTUE = page(
    "tortue", "jardin", "La tortue", "The turtle",
    *soleil(870, 120, 52),
    nuage(210, 140, 110, 48),
    sol(735, vague=8),
    zone(rect(280, 600, 84, 128, r=36)), zone(rect(418, 606, 84, 124, r=36)),
    zone(rect(556, 606, 84, 124, r=36)), zone(rect(684, 600, 84, 128, r=36)),
    detail(poly([(800, 586), (878, 620), (800, 638)], r=6)),
    zone(tube([(300, 560), (215, 520), (175, 452)], 74)),
    zone(ellipse(160, 420, 86, 68)),
    *oeil(168, 400, 20, dx=-3, dy=2, p=0.55),
    trait(arc(126, 438, 28, 30, 130)),
    zone(corde(520, 610, 290, 180, 360, ry=250)),
    zone(poly([(440, 400), (600, 400), (640, 480), (400, 480)], r=16)),
    zone(poly([(292, 586), (330, 500), (410, 500), (400, 586)], r=14),
         poly([(425, 586), (440, 500), (600, 500), (615, 586)], r=14),
         poly([(640, 586), (630, 500), (710, 500), (748, 586)], r=14)),
    zone(rect(215, 592, 610, 46, r=23)),
    *fleur(120, 900, 44), *fleur(880, 900, 44),
)


def champignon(cx: float, y: float, w: float, h: float) -> list:
    return [
        zone(rect(cx - 0.2 * w, y - 0.56 * h, 0.4 * w, 0.56 * h, r=0.1 * w)),
        zone(corde(cx, y - 0.5 * h, w / 2, 180, 360, ry=0.5 * h)),
        detail(cercle(cx - 0.22 * w, y - 0.7 * h, 0.09 * w), cercle(cx + 0.14 * w, y - 0.82 * h, 0.1 * w),
               cercle(cx + 0.3 * w, y - 0.62 * h, 0.06 * w)),
    ]


CHAMPIGNONS = page(
    "champignons", "jardin", "Les champignons", "The mushrooms",
    *soleil(870, 120, 52),
    sol(840, vague=10),
    *champignon(720, 860, 270, 310),
    *champignon(400, 850, 380, 440),
    *champignon(170, 880, 180, 200),
    herbe([(574, 884), (872, 900)]),
)


POMMIER = page(
    "pommier", "jardin", "Le pommier", "The apple tree",
    sol(860, vague=10),
    zone(poly([(430, 880), (470, 560), (530, 560), (570, 880)], r=[10, 0, 0, 10])),
    nuage(500, 380, 320, 240, bosses=11, hauteur=0.7),
    detail(*[cercle(x, y, 38) for x, y in [(330, 300), (480, 250), (640, 290), (280, 460), (430, 420),
                                          (590, 450), (720, 420), (380, 560), (650, 570)]]),
    trait(*[ligne((x, y - 38), (x + 8, y - 56)) for x, y in [(330, 300), (480, 250), (640, 290), (280, 460),
                                                            (430, 420), (590, 450), (720, 420), (380, 560),
                                                            (650, 570)]]),
    detail(cercle(300, 900, 40)),
    detail(cercle(765, 756, 34)),
    detail(cercle(724, 800, 36)),
    detail(cercle(806, 796, 36)),
    zone(corde(770, 820, 118, 0, 180, ry=82)),
    zone(rect(646, 804, 248, 32, r=15)),
)


def radis(cx: float, cy: float, r: float, penche: float = 0.0) -> list:
    """Un radis rond (pointe en bas, racine) et ses trois fanes."""
    tip = (cx, cy + 1.9 * r)
    els = [
        zone(feuille((cx - 0.1 * r, cy - 0.6 * r), (cx - 0.9 * r, cy - 2.5 * r), 0.62 * r)),
        zone(feuille((cx + 0.1 * r, cy - 0.6 * r), (cx + 0.9 * r, cy - 2.5 * r), 0.62 * r)),
        zone(feuille((cx, cy - 0.6 * r), (cx, cy - 2.8 * r), 0.66 * r)),
        trait(ligne((cx - 0.12 * r, cy - 0.8 * r), (cx - 0.72 * r, cy - 2.2 * r)),
              ligne((cx + 0.12 * r, cy - 0.8 * r), (cx + 0.72 * r, cy - 2.2 * r)),
              ligne((cx, cy - 0.8 * r), (cx, cy - 2.45 * r))),
        zone(tourne(goutte(cx, cy, r, 1.9 * r), 180, cx, cy)),
        trait(courbe([tip, (tip[0] + 8, tip[1] + 22), (tip[0] - 4, tip[1] + 44)])),
    ]
    return els


RADIS = page(
    "radis", "jardin", "Les radis", "The radishes",
    *soleil(870, 110, 50),
    zone(rect(0, 830, 1000, 170)),
    *radis(200, 600, 104), *radis(500, 560, 116), *radis(800, 600, 104),
    herbe([(350, 870), (660, 880)]),
)


LIMACE = page(
    "limace", "jardin", "La limace", "The slug",
    *soleil(870, 120, 52),
    sol(800, vague=10),
    # un champignon derrière
    zone(rect(172, 640, 76, 170, r=14)),
    zone(corde(210, 650, 130, 180, 360, ry=120)),
    detail(cercle(170, 590, 20), cercle(250, 570, 24)),
    # les cornes (yeux au bout)
    detail(tube([(668, 470), (636, 350)], 22), tube([(724, 474), (758, 356)], 22)),
    zone(cercle(630, 326, 48)), zone(cercle(764, 332, 48)),
    encre(cercle(640, 330, 20), cercle(770, 336, 20)),
    # le corps, couché, la tête relevée à droite
    zone(lisse([(170, 790), (320, 740), (500, 700), (610, 600), (660, 470), (740, 452), (800, 510),
                (790, 640), (740, 760), (640, 820), (420, 830), (220, 820)])),
    zone(lisse([(470, 700), (560, 640), (660, 610), (730, 650), (710, 740), (600, 770), (500, 760)])),
    detail(cercle(660, 690, 20), cercle(560, 716, 16), cercle(718, 698, 12)),
    trait(arc(736, 540, 34, 30, 150)),
    trait(courbe([(160, 850), (260, 862), (380, 850)]), courbe([(120, 900), (230, 912), (330, 900)])),
    *fleur(880, 880, 50),
)


BUCHE = page(
    "buche", "jardin", "La bûche", "The log",
    *soleil(130, 120, 56),
    nuage(760, 140, 120, 52),
    sol(760, vague=10),
    # le rameau feuillu
    detail(tube([(420, 520), (410, 420), (380, 330)], 22)),
    zone(feuille((380, 334), (290, 236), 78)), zone(feuille((388, 344), (484, 244), 78)),
    zone(feuille((408, 420), (310, 380), 66)),
    # la bûche couchée : écorce, puis la face coupée et ses cernes
    zone(rect(150, 500, 640, 250, r=60)),
    trait(courbe([(230, 560), (330, 552), (430, 566), (520, 556)]),
          courbe([(260, 640), (380, 632), (500, 646), (600, 636)]),
          courbe([(220, 700), (320, 694), (420, 704)])),
    detail(ellipse(560, 700, 30, 18)),
    zone(ellipse(790, 625, 110, 128)),
    zone(ellipse(790, 625, 80, 96)),
    zone(ellipse(790, 625, 50, 62)),
    detail(ellipse(790, 625, 22, 28)),
    *fleur(90, 880, 44), *fleur(900, 890, 46),
    herbe([(300, 880), (560, 900)]),
)


PAGES = [COCCINELLE, TORTUE, CHAMPIGNONS, POMMIER, RADIS, LIMACE, BUCHE]
