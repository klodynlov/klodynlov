"""Album « À la maison » : la salle de bains, la chambre, les objets du quotidien.

(La maison et la niche sont dessinées à la main dans l'app : PagesClassics.swift,
PagesThings.swift.)
"""
from __future__ import annotations

import math

from .dessin import (
    Contour, arc, cercle, coeur, detail, ellipse, encre, etoile, goutte, ligne, lisse, page, poly,
    rect, tourne, trait, trou, tube, zone,
)
from .motifs import fleur, groupe, nuage, oeil, soleil


def canard(cx: float, cy: float) -> list:
    """Petit canard de bain, tourné vers la droite."""
    return [
        zone(lisse([(cx - 86, cy - 20), (cx - 40, cy - 40), (cx + 40, cy - 36), (cx + 84, cy), (cx + 50, cy + 44),
                    (cx - 50, cy + 46), (cx - 96, cy + 10)])),
        zone(poly([(cx + 60, cy - 88), (cx + 124, cy - 72), (cx + 62, cy - 50)], r=[6, 10, 6])),
        zone(cercle(cx + 36, cy - 76, 46)),
        encre(cercle(cx + 50, cy - 86, 9)),
        trait(arc(cx - 16, cy - 2, 44, 20, 150)),
    ]


def bulles(pts: list[tuple[float, float, float]], petites: bool = True) -> list:
    """Bulles : les grosses sont des zones, les petites des détails ; un reflet (trait) chacune."""
    grosses = [cercle(x, y, r) for x, y, r in pts if r >= 40]
    mini = [cercle(x, y, r) for x, y, r in pts if r < 40]
    els = []
    if grosses:
        els.append(zone(*grosses))
    if mini:
        els.append(detail(*mini))
    reflets = [arc(x, y, 0.62 * r, 200, 250) for x, y, r in pts if r >= 28]
    if reflets:
        els.append(trait(*reflets))
    return els


DOUCHE = page(
    "douche", "maison", "La douche", "The shower",
    # carrelage (le mur), sol
    trait(*[ligne((0, y), (1000, y)) for y in (230, 460)], *[ligne((x, 0), (x, 700)) for x in (250, 500, 750)]),
    zone(rect(0, 700, 1000, 300)),
    trait(ligne((0, 850), (1000, 850))),
    # tuyau (sur un joint du carrelage), pommeau
    zone(tube([(750, 700), (750, 260), (724, 160), (640, 124), (548, 160)], 40)),
    zone(poly([(466, 174), (602, 174), (648, 252), (420, 252)], r=[10, 10, 6, 6])),
    zone(rect(404, 244, 260, 34, r=15)),
    # la pluie
    detail(*[goutte(x, y, 19) for x, y in [(450, 350), (534, 364), (618, 350), (486, 466), (570, 480), (650, 460),
                                            (452, 580), (540, 596), (628, 578)]]),
    # le receveur, le tapis, la serviette
    zone(rect(330, 660, 560, 60, r=20)),
    zone(rect(80, 760, 320, 124, r=26)),
    trait(*[ligne((x, 772), (x, 872)) for x in (150, 220, 290, 350)]),
    detail(rect(100, 120, 26, 66, r=8)),
    zone(poly([(46, 180), (180, 180), (190, 520), (36, 520)], r=[10, 10, 14, 14])),
    zone(rect(36, 436, 154, 44)),
    # le savon et ses bulles
    zone(rect(214, 626, 128, 64, r=26)),
    *bulles([(284, 540, 30), (340, 500, 20), (220, 520, 18)]),
)


MOUSSE = page(
    "mousse", "maison", "Le bain moussant", "The bubble bath",
    zone(rect(0, 880, 1000, 120)),
    # les grosses bulles qui s'envolent
    *bulles([(160, 170, 70), (300, 90, 44), (820, 150, 80), (700, 60, 34), (520, 120, 48), (900, 340, 30),
             (90, 380, 36)]),
    # le tas de mousse, le canard dedans
    nuage(500, 470, 330, 190, bosses=11, hauteur=0.85),
    trait(arc(380, 440, 60, 200, 300), arc(620, 400, 70, 200, 300), arc(520, 540, 50, 200, 300)),
    *canard(640, 560),
    # la baignoire à pattes
    zone(poly([(90, 600), (910, 600), (850, 820), (150, 820)], r=[20, 20, 90, 90])),
    zone(rect(60, 580, 880, 50, r=25)),
    zone(rect(170, 812, 60, 76, r=18), rect(770, 812, 60, 76, r=18)),
    zone(etoile(500, 720, 62, coins=8)),
)


BOUCHE = page(
    "bouche", "maison", "La bouche", "The mouth",
    zone(coeur(150, 190, 70), coeur(860, 800, 64)),
    zone(lisse([(250, 484), (380, 458), (500, 468), (620, 458), (750, 484), (660, 580), (500, 620), (340, 580)])),
    zone(lisse([(290, 430), (500, 420), (710, 430), (700, 510), (500, 536), (300, 510)])),
    trait(ligne((400, 440), (400, 524)), ligne((500, 440), (500, 534)), ligne((600, 440), (600, 524))),
    zone(lisse([(370, 580), (500, 548), (630, 580), (600, 650), (500, 670), (400, 650)])),
    trait(ligne((500, 564), (500, 612))),
    zone(lisse([(160, 480), (250, 392), (380, 348), (500, 392), (620, 348), (750, 392), (840, 480),
                (750, 612), (620, 676), (500, 696), (380, 676), (250, 612)]),
         trou(lisse([(250, 484), (380, 458), (500, 468), (620, 458), (750, 484), (660, 580), (500, 620),
                     (340, 580)]))),
    trait(arc(300, 440, 40, 200, 260), arc(700, 440, 40, 280, 340)),
)


def _brosse_a_dents() -> list:
    els = [
        zone(rect(670, 395, 160, 80, r=10)),
        zone(lisse([(660, 380), (700, 345), (740, 372), (780, 342), (820, 372), (850, 395), (760, 405)])),
        zone(tube([(160, 510), (660, 510)], 62)),
        zone(rect(640, 470, 210, 78, r=34)),
    ]
    return groupe(els, lambda f: tourne(f, -28, 500, 500))


BROSSE_A_DENTS = page(
    "brosse-a-dents", "maison", "La brosse à dents", "The toothbrush",
    *bulles([(160, 180, 44), (250, 100, 26), (860, 810, 30), (930, 740, 18)]),
    zone(rect(0, 880, 1000, 120)),
    *_brosse_a_dents(),
    zone(poly([(114, 790), (180, 756), (180, 874), (114, 840)], r=[6, 0, 0, 6])),
    zone(rect(170, 752, 380, 124, r=46)),
    zone(rect(256, 782, 210, 66, r=24)),
    zone(rect(548, 778, 80, 72, r=14)),
    zone(lisse([(700, 560), (760, 520), (820, 542), (880, 520), (942, 560), (930, 660), (905, 780), (880, 802),
                (855, 740), (820, 720), (785, 740), (760, 802), (735, 780), (712, 660)])),
    *oeil(790, 616, 18, dy=3, p=0.6), *oeil(852, 616, 18, dy=3, p=0.6),
    trait(arc(821, 650, 34, 30, 150)),
)


BROSSE_A_CHEVEUX = page(
    "brosse-a-cheveux", "maison", "La brosse à cheveux", "The hairbrush",
    zone(rect(0, 880, 1000, 120)),
    # le nœud à cheveux
    zone(lisse([(190, 250), (80, 156), (44, 260), (80, 364), (190, 292)])),
    zone(lisse([(250, 250), (360, 156), (396, 260), (360, 364), (250, 292)])),
    zone(tube([(200, 300), (160, 430)], 50)), zone(tube([(240, 300), (280, 430)], 50)),
    zone(ellipse(220, 270, 44, 50)),
    # la brosse : manche, dos, coussin et ses picots à boules
    *groupe([
        zone(tube([(500, 880), (560, 620)], 96)),
        zone(ellipse(610, 410, 200, 250)),
        zone(ellipse(610, 410, 158, 206)),
        encre(*[cercle(610 + dx, 410 + dy, 13) for dx, dy in
                [(-90, -120), (-30, -150), (30, -150), (90, -120), (-120, -50), (-60, -70), (0, -80), (60, -70),
                 (120, -50), (-120, 30), (-60, 10), (0, 0), (60, 10), (120, 30), (-90, 100), (-30, 80), (30, 80),
                 (90, 100), (-40, 160), (40, 160)]]),
    ], lambda f: tourne(f, 12, 560, 620)),
    detail(etoile(840, 820, 52), etoile(150, 700, 46)),
)


def _main(cx: float, cy: float, s: float, rot: float, miroir: bool = False) -> list:
    """Une main en moufle : le pouce (derrière), la paume aux doigts serrés, trois traits de doigts."""
    k = -1 if miroir else 1

    def place(f):
        f = [c.map(lambda p: (cx + s * k * p[0], cy + s * p[1])) for c in f]
        if miroir:
            f = [c.reversed() for c in f]
        return tourne(f, rot, cx, cy)
    return [
        zone(place(tube([(-40, 36), (-92, -20)], 40))),
        zone(place(rect(-52, -96, 104, 200, r=50))),
        trait(*[place(ligne((x, -90 + (50 - math.sqrt(50 ** 2 - x ** 2))), (x, -36))) for x in (-22, 0, 22)]),
    ]


LAVER = page(
    "laver", "maison", "Se laver les mains", "Washing hands",
    # le robinet, sa poignée et l'eau
    zone(rect(440, 50, 140, 70, r=24)),
    zone(rect(470, 110, 80, 100)),
    zone(tube([(510, 200), (560, 240), (640, 250)], 64)),
    zone(rect(606, 206, 100, 90, r=26)),
    detail(cercle(510, 50, 34)),
    zone(rect(624, 290, 62, 210)),
    # les mains qui se frottent sous l'eau
    *_main(572, 560, 1.25, 18),
    *_main(740, 574, 1.25, -18, miroir=True),
    # le lavabo, le savon, les bulles
    zone(poly([(160, 700), (860, 700), (780, 910), (240, 910)], r=[20, 20, 60, 60])),
    zone(rect(120, 680, 780, 52, r=26)),
    zone(rect(170, 596, 176, 86, r=32)),
    trait(arc(258, 638, 44, 200, 340, ry=18)),
    *bulles([(240, 470, 46), (340, 390, 30), (160, 380, 26), (880, 380, 44), (930, 480, 24), (400, 480, 22)]),
)


MACHINE = page(
    "machine", "maison", "La machine à laver", "The washing machine",
    zone(rect(0, 880, 1000, 120)),
    *bulles([(140, 250, 44), (95, 370, 28), (872, 200, 40), (922, 310, 24), (160, 120, 24)]),
    zone(rect(220, 160, 560, 722, r=40)),
    zone(rect(250, 190, 500, 110, r=20)),
    detail(cercle(310, 245, 32)),
    zone(rect(380, 220, 170, 50, r=12)),
    detail(cercle(620, 245, 20), cercle(684, 245, 20)),
    # le hublot : le verre, l'eau, le linge, puis l'anneau de la porte par-dessus
    zone(cercle(500, 570, 170)),
    zone([Contour((300, 610), [("C", (360, 580), (400, 580), (440, 612)), ("C", (480, 640), (520, 640), (560, 610)),
                               ("C", (600, 580), (640, 580), (700, 610)), ("L", (620, 750)), ("L", (380, 750))])]),
    zone(tube([(420, 470), (430, 556), (500, 598)], 50)),
    zone(poly([(470, 600), (540, 560), (610, 600), (590, 632), (570, 622), (570, 700), (500, 700), (500, 622),
               (480, 632)], r=6)),
    zone(cercle(500, 570, 220), trou(cercle(500, 570, 170))),
    detail(rect(704, 530, 34, 84, r=12)),
    detail(rect(262, 878, 60, 24, r=6), rect(678, 878, 60, 24, r=6)),
)


def crayon(x: float, y: float, longueur: float, w: float, angle: float) -> list:
    """Crayon debout, pied en (x, y), incliné de `angle` degrés."""
    def t(f):
        return tourne(f, angle, x, y)
    top = y - longueur
    return [
        zone(t(rect(x - w / 2, top, w, longueur))),
        detail(t(poly([(x - w / 2, top), (x + w / 2, top), (x, top - 1.3 * w)], r=[0, 0, 6]))),
        encre(t(poly([(x - w / 5, top - 0.9 * w), (x + w / 5, top - 0.9 * w), (x, top - 1.3 * w)], r=[0, 0, 4]))),
    ]


TROUSSE = page(
    "trousse", "maison", "La trousse", "The pencil case",
    zone(rect(0, 850, 1000, 150)),
    *crayon(360, 640, 380, 62, -18), *crayon(500, 640, 420, 62, 0), *crayon(640, 640, 380, 62, 18),
    zone(tourne(rect(700, 250, 76, 420, r=8), 26, 735, 620)),
    trait(*[tourne(ligne((700, y), (730, y)), 26, 735, 620) for y in range(300, 600, 60)]),
    zone(rect(160, 500, 680, 345, r=100)),
    trait(ligne((230, 548), (770, 548))),
    detail(rect(772, 526, 40, 64, r=12)),
    zone(etoile(500, 704, 72, coins=6)),
    zone(rect(14, 772, 116, 66, r=18)),
)


TACHE = page(
    "tache", "maison", "La tache de peinture", "The paint splat",
    zone(lisse([(500, 190), (560, 260), (650, 200), (660, 300), (780, 290), (720, 380), (820, 440), (720, 480),
                (770, 580), (660, 560), (640, 670), (560, 600), (480, 690), (440, 590), (330, 640), (360, 530),
                (230, 510), (330, 440), (240, 350), (360, 340), (360, 230), (440, 290)])),
    zone(cercle(200, 200, 46), cercle(850, 190, 42), cercle(880, 560, 50), cercle(160, 650, 48)),
    detail(cercle(290, 140, 22), cercle(600, 770, 22), cercle(110, 470, 20), cercle(930, 380, 22)),
    # le pot de peinture et le pinceau
    zone(poly([(640, 780), (900, 780), (880, 960), (660, 960)], r=[6, 6, 20, 20])),
    detail(ellipse(770, 780, 140, 38)),
    zone(ellipse(770, 780, 104, 20)),
    zone(tube([(80, 960), (380, 830)], 46)),
    detail(tourne(rect(372, 800, 64, 56, r=6), -23, 404, 828)),
    zone(tourne(goutte(470, 830, 40, 100), 67, 470, 830)),
)


CACTUS = page(
    "cactus", "maison", "Le cactus", "The cactus",
    *soleil(130, 120, 56),
    zone(rect(0, 860, 1000, 140)),
    # bras, corps (épines : petits traits qui ne ferment rien)
    zone(tube([(410, 560), (300, 560), (280, 470), (280, 390)], 84)),
    zone(tube([(590, 500), (700, 500), (722, 420), (722, 330)], 84)),
    zone(rect(410, 220, 180, 520, r=90)),
    trait(*[ligne((x, y), (x + dx, y - 14)) for x, y, dx in
            [(440, 300, -12), (560, 300, 12), (450, 420, -12), (550, 420, 12), (440, 540, -12), (560, 540, 12),
             (450, 650, -12), (550, 650, 12), (300, 440, -12), (700, 380, 12)]]),
    *oeil(460, 380, 24, dy=4), *oeil(540, 380, 24, dy=4),
    trait(arc(500, 424, 30, 30, 150)),
    *fleur(500, 216, 64),
    # le pot
    zone(poly([(330, 740), (670, 740), (630, 870), (370, 870)], r=[6, 6, 18, 18])),
    zone(rect(310, 700, 380, 64, r=16)),
    detail(coeur(500, 800, 30)),
)


PAGES = [DOUCHE, MOUSSE, BOUCHE, BROSSE_A_DENTS, BROSSE_A_CHEVEUX, LAVER, MACHINE, TROUSSE, TACHE, CACTUS]
