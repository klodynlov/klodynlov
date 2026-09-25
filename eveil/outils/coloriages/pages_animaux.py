"""Album « Les animaux » : les bêtes des mots du petit train, et d'autres.

(La vache et le poisson sont dessinés à la main dans l'app : PagesAnimals.swift.)
"""
from __future__ import annotations


from .dessin import (
    Contour, arc, cercle, coeur, courbe, detail, ellipse, encre, goutte, ligne, lisse, miroir, page, poly,
    rect, tourne, trait, tube, zone,
)
from .motifs import feuille, fleur, nuage, oeil, sapin, sol, soleil

MINOUCHE = page(
    "minouche", "animaux", "Minouche la chatte", "Minouche the cat",
    zone(rect(0, 870, 1000, 130)),
    zone(tube([(610, 852), (760, 846), (832, 760), (802, 652), (742, 612)], [40, 44, 44, 40, 34])),
    zone(lisse([(500, 470), (615, 530), (665, 690), (630, 840), (500, 872), (370, 840), (335, 690),
                (385, 530)])),
    zone(ellipse(500, 712, 86, 112)),
    zone(ellipse(438, 864, 58, 30), ellipse(562, 864, 58, 30)),
    zone(poly([(336, 400), (326, 130), (490, 268)], r=[16, 28, 16]),
         poly([(664, 400), (674, 130), (510, 268)], r=[16, 28, 16])),
    detail(poly([(358, 330), (352, 192), (436, 262)], r=[10, 16, 10]),
           poly([(642, 330), (648, 192), (564, 262)], r=[10, 16, 10])),
    zone(ellipse(500, 382, 178, 150)),
    *oeil(438, 370, 36, dy=5, p=0.5, ry=42), *oeil(562, 370, 36, dy=5, p=0.5, ry=42),
    encre(poly([(474, 428), (526, 428), (500, 458)], r=[8, 8, 6])),
    trait(ligne((500, 458), (500, 474)), arc(481, 474, 19, 0, 180), arc(519, 474, 19, 0, 180)),
    trait(ligne((420, 452), (300, 430)), ligne((420, 468), (296, 474)),
          ligne((580, 452), (700, 430)), ligne((580, 468), (704, 474))),
    zone(tube([(398, 502), (500, 524), (602, 502)], 30)),
    detail(cercle(500, 556, 26)),
    zone(cercle(206, 786, 100)),
    trait(arc(206, 786, 70, 200, 330), arc(206, 786, 42, 190, 320), courbe([(150, 752), (206, 786), (226, 846)])),
)


BICHE = page(
    "biche", "animaux", "La biche", "The doe",
    zone(rect(96, 470, 72, 360, r=12)),
    nuage(132, 330, 96, 118, bosses=8),
    zone(rect(846, 500, 64, 330, r=12)),
    nuage(878, 372, 84, 100, bosses=7),
    sol(820, vague=12),
    zone(rect(292, 590, 38, 250, r=16), rect(540, 590, 38, 250, r=16)),
    detail(ellipse(258, 498, 40, 24, rot=-30)),
    zone(tube([(575, 525), (628, 420), (656, 318)], [100, 82, 70])),
    zone(ellipse(440, 540, 200, 105)),
    detail(*[ellipse(x, y, 20, 14) for x, y in [(370, 486), (436, 468), (500, 478), (404, 530),
                                                  (470, 522)]]),
    zone(rect(372, 605, 38, 245, r=16), rect(612, 600, 38, 250, r=16)),
    detail(rect(292, 812, 38, 34, r=8), rect(540, 812, 38, 34, r=8),
           rect(372, 820, 38, 34, r=8), rect(612, 820, 38, 34, r=8)),
    zone(tourne(goutte(626, 204, 34, 100), -34, 626, 204)),
    zone(tourne(goutte(694, 194, 34, 100), 12, 694, 194)),
    zone(lisse([(630, 252), (700, 226), (752, 262), (798, 330), (790, 374), (744, 384), (690, 352), (636, 312)])),
    encre(ellipse(780, 358, 16, 12)),
    *oeil(690, 286, 20, dx=3, dy=2, p=0.55),
    trait(arc(750, 366, 26, 60, 130)),
)


ELAN = page(
    "elan", "animaux", "L'élan", "The moose",
    *sapin(150, 880, 440), *sapin(850, 880, 400),
    sol(850, vague=8),
    zone(poly([(210, 1000), (250, 850), (340, 752), (500, 730), (660, 752), (750, 850), (790, 1000)],
              r=[0, 70, 80, 60, 80, 70, 0])),
    zone(poly([(440, 330), (330, 352), (240, 340), (160, 270), (150, 210), (200, 245), (212, 165), (252, 222),
               (285, 140), (318, 218), (362, 165), (378, 240), (430, 270)], r=12)),
    zone(miroir(poly([(440, 330), (330, 352), (240, 340), (160, 270), (150, 210), (200, 245), (212, 165),
                      (252, 222), (285, 140), (318, 218), (362, 165), (378, 240), (430, 270)], r=12))),
    zone(ellipse(345, 392, 74, 34, rot=-25), ellipse(655, 392, 74, 34, rot=25)),
    zone(goutte(500, 850, 38, 96)),
    zone(lisse([(500, 290), (585, 330), (615, 450), (598, 590), (575, 720), (500, 770), (425, 720), (402, 590),
                (385, 450), (415, 330)])),
    zone(ellipse(500, 690, 110, 80)),
    encre(ellipse(462, 698, 18, 13), ellipse(538, 698, 18, 13)),
    *oeil(446, 452, 28, dy=4), *oeil(554, 452, 28, dy=4),
    trait(arc(500, 718, 34, 40, 140)),
)


PERRUCHE = page(
    "perruche", "animaux", "La perruche", "The budgie",
    nuage(800, 150, 110, 50),
    zone(tube([(60, 740), (400, 722), (700, 736), (960, 716)], 44)),
    zone(tourne(goutte(236, 694, 36, 96), -60, 236, 694), tourne(goutte(836, 694, 36, 96), 55, 836, 694)),
    zone(tube([(560, 640), (652, 790), (722, 935)], [92, 58, 24])),
    zone(lisse([(420, 380), (545, 405), (618, 522), (592, 652), (500, 702), (408, 650), (370, 520)])),
    zone(lisse([(478, 470), (572, 482), (602, 580), (562, 660), (505, 640), (484, 560)])),
    trait(arc(530, 520, 40, 20, 160, ry=18), arc(540, 568, 44, 20, 160, ry=18), arc(545, 616, 38, 20, 160, ry=16)),
    detail(ellipse(460, 712, 30, 15), ellipse(524, 716, 30, 15)),
    zone(cercle(432, 360, 100)),
    detail(poly([(356, 332), (296, 360), (316, 402), (354, 388)], r=[6, 14, 8, 6])),
    *oeil(420, 326, 24, dx=-5, dy=2, p=0.55),
)


OIE = page(
    "oie", "animaux", "L'oie", "The goose",
    *soleil(870, 120, 55),
    sol(760, vague=10),
    zone(ellipse(640, 885, 330, 78)),
    trait(courbe([(460, 885), (520, 872), (580, 885)]), courbe([(700, 905), (760, 892), (820, 905)])),
    detail(tube([(866, 770), (876, 610)], 18), tube([(944, 786), (952, 666)], 18)),
    zone(ellipse(876, 590, 28, 58), ellipse(952, 642, 28, 58)),
    detail(rect(450, 640, 26, 125, r=10), rect(600, 640, 26, 125, r=10)),
    detail(poly([(420, 794), (500, 794), (464, 754)], r=6), poly([(578, 794), (658, 794), (616, 754)], r=6)),
    zone(tube([(420, 582), (358, 470), (344, 360), (370, 282)], [96, 74, 64, 60])),
    zone(lisse([(380, 560), (520, 500), (700, 520), (805, 460), (792, 580), (690, 680), (500, 706), (390, 652)])),
    zone(lisse([(520, 562), (640, 540), (732, 562), (702, 632), (600, 652), (530, 622)])),
    trait(arc(600, 590, 44, 20, 160, ry=18), arc(660, 600, 40, 20, 160, ry=16)),
    zone(poly([(300, 226), (128, 272), (298, 322)], r=[6, 10, 6])),
    zone(ellipse(352, 262, 72, 56)),
    *oeil(350, 244, 18, dx=-3, dy=2, p=0.55),
)


def _coquille_bas() -> list:
    zig = [(285, 650), (320, 600), (370, 650), (420, 600), (470, 650), (520, 600), (570, 650), (620, 600), (670, 650),
           (715, 650)]
    a = arc(500, 650, 215, 0, 180, ry=210)[0]
    return [Contour(zig[0], [("L", q) for q in zig[1:]] + a.segs)]


def _coquille_haut() -> list:
    a = arc(500, 330, 110, 180, 360, ry=90)[0]
    zig = [(580, 365), (550, 335), (520, 365), (490, 335), (460, 365), (430, 335)]
    return [Contour(a.start, a.segs + [("L", q) for q in zig])]


POUSSIN = page(
    "poussin", "animaux", "Le poussin", "The chick",
    sol(850, vague=8),
    zone(feuille((340, 520), (262, 436), 74)), zone(feuille((660, 520), (738, 436), 74)),
    zone(cercle(500, 480, 175)),
    *oeil(445, 440, 30, dy=4), *oeil(555, 440, 30, dy=4),
    detail(cercle(408, 508, 26), cercle(592, 508, 26)),
    detail(poly([(466, 490), (534, 490), (500, 538)], r=[6, 6, 6])),
    zone(_coquille_haut()),
    zone(_coquille_bas()),
    *fleur(110, 900, 38), *fleur(890, 900, 38),
)


LAPIN = page(
    "lapin", "animaux", "Le lapin", "The bunny",
    sol(850, vague=10),
    zone(ellipse(420, 205, 50, 150, rot=-12)), zone(ellipse(580, 205, 50, 150, rot=12)),
    zone(ellipse(422, 215, 26, 110, rot=-12)), zone(ellipse(578, 215, 26, 110, rot=12)),
    zone(lisse([(500, 460), (620, 520), (660, 680), (610, 830), (500, 862), (390, 830), (340, 680), (380, 520)])),
    zone(ellipse(500, 700, 90, 112)),
    zone(ellipse(428, 852, 64, 32), ellipse(572, 852, 64, 32)),
    zone(tourne(goutte(640, 650, 36, 150), 205, 640, 650)),
    zone(feuille((662, 616), (748, 500), 70)), zone(feuille((662, 616), (800, 596), 70)),
    zone(ellipse(604, 640, 50, 36)),
    zone(ellipse(500, 400, 160, 136)),
    *oeil(445, 380, 30, dy=4), *oeil(555, 380, 30, dy=4),
    detail(cercle(408, 440, 26), cercle(592, 440, 26)),
    detail(rect(484, 474, 32, 30, r=5)),
    encre(coeur(500, 440, 18)),
    trait(ligne((500, 456), (500, 474))),
    trait(ligne((356, 460), (272, 446)), ligne((358, 474), (272, 488)), ligne((644, 460), (728, 446)),
          ligne((642, 474), (728, 488))),
)


def _pompon(cx: float, cy: float, rx: float, ry: float, bosses: int = 7) -> list:
    """Touffe frisée de caniche : un nuage d'un seul contour."""
    from .dessin import nuage as _nuage
    return _nuage(cx, cy, rx, ry, bosses=bosses, hauteur=0.9)


CANICHE = page(
    "caniche", "animaux", "Le caniche", "The poodle",
    *soleil(870, 120, 55),
    sol(850, vague=10),
    # patte arrière du fond, queue et son pompon
    zone(tube([(712, 560), (720, 700), (716, 800)], 42)),
    zone(_pompon(716, 804, 50, 36, bosses=6)),
    detail(tube([(676, 470), (740, 376), (762, 330)], 32)),
    zone(_pompon(778, 296, 64, 56)),
    # patte avant du fond
    zone(tube([(474, 600), (480, 700), (478, 800)], 42)),
    zone(_pompon(478, 804, 50, 36, bosses=6)),
    # taille rasée, pompon des hanches
    zone(tube([(420, 520), (660, 520)], 100)),
    zone(_pompon(662, 505, 100, 84)),
    # pattes du devant de l'image
    zone(tube([(632, 580), (628, 700), (632, 820)], 44)),
    zone(_pompon(632, 824, 54, 38, bosses=6)),
    zone(tube([(390, 600), (384, 700), (390, 820)], 44)),
    zone(_pompon(390, 824, 54, 38, bosses=6)),
    # le gros pompon de la poitrine, le cou
    zone(_pompon(404, 494, 128, 124, bosses=8)),
    # le museau, la tête, le toupet, l'oreille
    zone(ellipse(176, 306, 76, 40, rot=6)),
    zone(ellipse(272, 272, 94, 76)),
    encre(ellipse(108, 298, 20, 17)),
    trait(arc(170, 330, 34, 40, 130)),
    zone(_pompon(292, 186, 86, 56)),
    zone(_pompon(348, 342, 52, 90, bosses=6)),
    # Œil : la pupille ne doit pas manger le blanc — un croissant trop fin (< 0,02 % de la page)
    # est rattaché à la tête par la carte des zones de l'app (vu au premier swift test sur le Mac).
    *oeil(232, 264, 26, dx=-3, dy=2, p=0.48),
)


AUTRUCHE = page(
    "autruche", "animaux", "L'autruche", "The ostrich",
    *soleil(130, 120, 56),
    nuage(420, 150, 110, 48),
    sol(860, vague=10),
    nuage(900, 830, 80, 44, bosses=6),
    # pattes (roses), doigts
    zone(tube([(452, 560), (430, 700), (452, 842)], 34)),
    zone(tube([(560, 560), (596, 690), (580, 842)], 34)),
    detail(ellipse(480, 852, 42, 17), ellipse(608, 852, 42, 17)),
    # plumes de la queue, corps, aile
    zone(lisse([(330, 430), (236, 318), (196, 400), (240, 490), (330, 520)])),
    zone(lisse([(330, 470), (180, 462), (178, 560), (290, 590), (360, 540)])),
    zone(lisse([(300, 440), (420, 380), (590, 390), (680, 450), (660, 560), (520, 610), (380, 590), (300, 530)])),
    zone(lisse([(420, 440), (530, 420), (610, 470), (580, 540), (470, 550), (400, 510)])),
    trait(arc(500, 470, 60, 20, 160, ry=26), arc(510, 510, 56, 20, 160, ry=22)),
    # long cou, bec, tête
    zone(tube([(640, 440), (664, 320), (690, 200)], [72, 56, 48])),
    detail(poly([(724, 138), (868, 172), (724, 208)], r=[10, 14, 10])),
    zone(ellipse(694, 162, 64, 52)),
    *oeil(706, 150, 25, dx=5, dy=2, p=0.55),
    trait(ligne((690, 122), (684, 98)), ligne((706, 120), (708, 96)), ligne((722, 124), (732, 102))),
)


SOURIS = page(
    "souris", "animaux", "La souris", "The mouse",
    zone(rect(0, 860, 1000, 140)),
    # la queue
    zone(tube([(600, 840), (760, 846), (860, 770), (850, 660), (790, 620)], [26, 24, 22, 18, 14])),
    # le fromage
    zone(poly([(90, 862), (90, 742), (300, 700), (300, 862)], r=[6, 10, 10, 6])),
    zone(poly([(90, 742), (300, 700), (230, 660)], r=[6, 10, 8])),
    detail(cercle(150, 800, 26), cercle(240, 780, 20), cercle(250, 836, 14)),
    # corps, ventre, pattes
    zone(lisse([(500, 500), (610, 560), (650, 700), (610, 830), (500, 862), (390, 830), (350, 700), (390, 560)])),
    zone(ellipse(500, 712, 90, 110)),
    zone(ellipse(440, 866, 58, 28), ellipse(560, 866, 58, 28)),
    detail(ellipse(418, 626, 42, 30, rot=-30), ellipse(582, 626, 42, 30, rot=30)),
    # oreilles
    zone(cercle(330, 300, 108), cercle(670, 300, 108)),
    zone(cercle(336, 306, 66), cercle(664, 306, 66)),
    # tête
    zone(lisse([(500, 290), (610, 320), (660, 400), (610, 480), (500, 530), (390, 480), (340, 400), (390, 320)])),
    *oeil(452, 396, 30, dy=5), *oeil(548, 396, 30, dy=5),
    detail(cercle(418, 462, 24), cercle(582, 462, 24)),
    encre(ellipse(500, 470, 22, 16)),
    trait(ligne((500, 486), (500, 500)), arc(484, 500, 16, 0, 160), arc(516, 500, 16, 20, 180)),
    trait(ligne((372, 454), (282, 434)), ligne((372, 472), (280, 478)),
          ligne((628, 454), (718, 434)), ligne((628, 472), (720, 478))),
)


PAGES = [MINOUCHE, CANICHE, BICHE, ELAN, AUTRUCHE, PERRUCHE, OIE, POUSSIN, LAPIN, SOURIS]
