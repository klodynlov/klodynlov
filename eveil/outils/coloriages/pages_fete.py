"""Album « La fête » : jeux, spectacles, ciel en fête.

(La cloche est dessinée à la main dans l'app : PagesThings.swift.)
"""
from __future__ import annotations

import math

from .dessin import (
    Contour, arc, arche, cercle, coeur, courbe, deplace, detail, ellipse, encre, etoile, goutte, ligne,
    lisse, page, poly, rect, tourne, trait, trou, tube, zone,
)
from .dessin import nuage as bosses
from .motifs import etoiles_scintillantes, feuille, nuage, oeil, oiseau, roue, sol, soleil


def ballon(cx: float, cy: float, rx: float, ry: float) -> list:
    return lisse([(cx, cy - ry), (cx + 0.8 * rx, cy - 0.6 * ry), (cx + rx, cy), (cx + 0.68 * rx, cy + 0.7 * ry),
                  (cx, cy + ry), (cx - 0.68 * rx, cy + 0.7 * ry), (cx - rx, cy), (cx - 0.8 * rx, cy - 0.6 * ry)])


BALLONS = page(
    "ballons", "fete", "Les ballons", "The balloons",
    nuage(170, 150, 100, 45), nuage(860, 520, 90, 40),
    trait(courbe([(330, 488), (380, 640), (470, 790), (500, 900)]),
          courbe([(680, 458), (620, 620), (540, 780), (500, 900)]),
          courbe([(500, 588), (480, 720), (500, 900)])),
    zone(ballon(330, 330, 118, 142)),
    detail(poly([(312, 492), (348, 492), (330, 464)], r=4)),
    zone(ballon(680, 300, 118, 142)),
    detail(poly([(662, 462), (698, 462), (680, 434)], r=4)),
    zone(ballon(500, 430, 122, 148)),
    detail(poly([(482, 596), (518, 596), (500, 570)], r=4)),
    trait(arc(300, 290, 60, 200, 260), arc(650, 260, 60, 200, 260), arc(470, 390, 62, 200, 260)),
    detail(ellipse(456, 900, 48, 26, rot=20)), detail(ellipse(544, 900, 48, 26, rot=-20)),
    detail(cercle(500, 902, 22)),
)


SOLEIL = page(
    "soleil", "fete", "Le soleil", "The sun",
    *soleil(500, 430, 190, rayons=12, visage=False),
    *oeil(435, 395, 36, dy=6, p=0.55), *oeil(565, 395, 36, dy=6, p=0.55),
    detail(cercle(388, 482, 34), cercle(612, 482, 34)),
    trait(arc(500, 450, 90, 25, 155)),
    nuage(170, 820, 140, 60, bosses=8), nuage(820, 860, 150, 62, bosses=8),
    trait(oiseau(160, 170), oiseau(260, 120, 0.8), oiseau(820, 150), oiseau(900, 210, 0.7)),
)


def croissant(ax: float, ay: float, ar: float, bx: float, by: float, br: float) -> list:
    """Lune en croissant : disque A privé du disque B (un seul contour)."""
    dx, dy = bx - ax, by - ay
    dd = math.hypot(dx, dy)
    a = (ar * ar - br * br + dd * dd) / (2 * dd)
    h = math.sqrt(ar * ar - a * a)
    mx, my = ax + a * dx / dd, ay + a * dy / dd
    p1 = (mx + h * dy / dd, my - h * dx / dd)
    p2 = (mx - h * dy / dd, my + h * dx / dd)

    def ang(c, p):
        return math.degrees(math.atan2(p[1] - c[1], p[0] - c[0]))
    a1, a2 = ang((ax, ay), p1), ang((ax, ay), p2)
    b1, b2 = ang((bx, by), p1), ang((bx, by), p2)
    base = math.degrees(math.atan2(dy, dx))
    sa = (a2 - a1) % 360
    mid = a1 + sa / 2
    if abs(((mid - base + 180) % 360) - 180) < 90:
        sa -= 360
    outer = arc(ax, ay, ar, a1, a1 + sa)[0]
    sb = (b1 - b2) % 360
    midb = b2 + sb / 2
    if abs(((midb - base - 180 + 180) % 360) - 180) > 90:
        sb -= 360
    inner = arc(bx, by, br, b2, b2 + sb)[0]
    c = Contour(outer.start, outer.segs + inner.segs)
    return [c if c.area() > 0 else c.reversed()]


LUNE = page(
    "lune", "fete", "La lune et les étoiles", "The moon and the stars",
    zone(croissant(430, 430, 250, 560, 360, 215)),
    trait(arc(292, 410, 32, 20, 160), arc(300, 560, 40, 30, 140)),
    detail(cercle(252, 480, 28)),
    zone(etoile(760, 170, 70)),
    detail(etoile(880, 420, 50), etoile(640, 650, 46), etoile(110, 150, 40), etoile(820, 740, 38),
           etoile(450, 800, 34)),
    encre(cercle(560, 160, 10), cercle(930, 230, 10), cercle(700, 470, 10), cercle(90, 700, 10)),
    nuage(240, 880, 190, 52, bosses=9), nuage(770, 890, 190, 50, bosses=9),
)


def _cordes(cx: float, cy: float, rx: float, ry: float, rot: float, pas: float = 90, marge: float = 26) -> list:
    """Cordage d'une raquette : de grandes cases, et des traits qui s'arrêtent avant le cadre."""
    out = []
    k = -int(rx // pas) * pas
    while k <= rx:
        if abs(k) < rx - marge:
            h = ry * math.sqrt(1 - (k / rx) ** 2) - marge
            out += tourne(ligne((cx + k, cy - h), (cx + k, cy + h)), rot, cx, cy)
        k += pas
    k = -int(ry // pas) * pas
    while k <= ry:
        if abs(k) < ry - marge:
            w = rx * math.sqrt(1 - (k / ry) ** 2) - marge
            out += tourne(ligne((cx - w, cy + k), (cx + w, cy + k)), rot, cx, cy)
        k += pas
    return out


TENNIS = page(
    "tennis", "fete", "Le tennis", "Tennis",
    zone(rect(0, 870, 1000, 130)),
    trait(ligne((0, 935), (1000, 935))),
    zone(tube([(548, 581), (700, 846)], 46)),
    zone(tube([(622, 710), (705, 855)], 64)),
    trait(ligne((636, 752), (676, 736)), ligne((650, 778), (690, 762)), ligne((664, 804), (704, 788))),
    zone(ellipse(420, 360, 175, 225, rot=-30)),
    trait(_cordes(420, 360, 175, 225, -30)),
    zone(ellipse(420, 360, 205, 255, rot=-30), trou(ellipse(420, 360, 175, 225, rot=-30))),
    zone(cercle(790, 330, 110)),
    trait(arc(705, 330, 90, -58, 58), arc(875, 330, 90, 122, 238)),
    trait(ligne((880, 470), (930, 500)), ligne((850, 490), (880, 540))),
)


def bord(a: tuple, b: tuple, vers: tuple) -> Contour:
    """Bord de pièce de puzzle de a à b, tenon bombé du côté `vers`."""
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    nx, ny = -uy, ux
    if nx * vers[0] + ny * vers[1] < 0:
        nx, ny = -nx, -ny

    def P(q):
        return (a[0] + ux * q[0] * L + nx * q[1] * L, a[1] + uy * q[0] * L + ny * q[1] * L)
    knob = arc(0.5, 0.2, 0.12, 210, -30)[0]
    segs = [("L", P((0.38, 0))), ("C", P((0.42, 0.02)), P((0.43, 0.1)), P((0.396, 0.14)))]
    segs += [("C", P(s[1]), P(s[2]), P(s[3])) for s in knob.segs]
    segs += [("C", P((0.57, 0.1)), P((0.58, 0.02)), P((0.62, 0))), ("L", b)]
    return Contour(a, segs, closed=False)


def piece(*bords: Contour) -> list:
    return [Contour(bords[0].start, [s for e in bords for s in e.segs])]


def droit(a: tuple, b: tuple) -> Contour:
    return Contour(a, [("L", b)], closed=False)


E1 = bord((500, 150), (500, 500), (1, 0))
E2 = bord((500, 500), (500, 850), (-1, 0))
E3 = bord((150, 500), (500, 500), (0, 1))
E4 = bord((500, 500), (850, 500), (0, -1))


def _deplace_bd(f):
    return deplace(tourne(f, 10, 675, 675), 96, 88)


PUZZLE = page(
    "puzzle", "fete", "Les pièces du puzzle", "The puzzle pieces",
    zone(piece(droit((150, 150), (500, 150)), E1, E3.reversed(), droit((150, 500), (150, 150)))),
    zone(piece(droit((500, 150), (850, 150)), droit((850, 150), (850, 500)), E4.reversed(), E1.reversed())),
    zone(piece(E3, E2, droit((500, 850), (150, 850)), droit((150, 850), (150, 500)))),
    zone(etoile(310, 320, 86)),
    zone(coeur(690, 330, 70)),
    zone(cercle(310, 690, 76)),
    trait(arc(310, 700, 36, 30, 150)),
    encre(cercle(286, 668, 10), cercle(334, 668, 10)),
    zone(_deplace_bd(piece(E4, droit((850, 500), (850, 850)), droit((850, 850), (500, 850)), E2.reversed()))),
    zone(_deplace_bd(bosses(690, 690, 56, 56, bosses=6, hauteur=1.0))),
    detail(_deplace_bd(cercle(690, 690, 24))),
)


CIRQUE = page(
    "cirque", "fete", "Le cirque", "The circus",
    sol(800, vague=10),
    # le mât et son fanion
    detail(rect(492, 80, 16, 130, r=4)),
    zone(poly([(508, 82), (644, 122), (508, 164)], r=[4, 8, 4])),
    # les murs rayés, l'entrée
    zone(poly([(190, 500), (810, 500), (850, 830), (150, 830)], r=[0, 0, 10, 10])),
    trait(*[ligne((x, 500), (x + (x - 500) * 0.12, 830)) for x in (290, 390, 610, 710)]),
    zone(arche(426, 610, 148, 220)),
    trait(courbe([(430, 690), (470, 700), (500, 690)]), courbe([(500, 690), (530, 700), (570, 690)])),
    # le toit en pointe, ses bandes, le feston
    zone(poly([(500, 190), (860, 490), (140, 490)], r=[16, 16, 16])),
    trait(ligne((500, 196), (330, 500)), ligne((500, 196), (670, 500))),
    zone(bosses(500, 500, 372, 26, bosses=12, hauteur=0.6, depart=15)),
    detail(etoile(150, 190, 40), etoile(860, 250, 44), etoile(80, 420, 30), etoile(930, 600, 32)),
    detail(etoile(500, 330, 58)),
)


PRINCESSE = page(
    "princesse", "fete", "La princesse", "The princess",
    etoiles_scintillantes([(130, 180, 30), (870, 200, 34), (100, 560, 24), (900, 560, 26)]),
    # les cheveux, derrière
    zone(lisse([(500, 150), (680, 230), (740, 420), (760, 650), (660, 700), (500, 690), (340, 700), (240, 650),
                (260, 420), (320, 230)])),
    # la robe, les manches bouffantes, le cou
    zone(poly([(290, 1000), (300, 780), (390, 700), (610, 700), (700, 780), (710, 1000)], r=[0, 50, 30, 30, 50, 0])),
    zone(ellipse(300, 770, 90, 74)), zone(ellipse(700, 770, 90, 74)),
    zone(rect(456, 580, 88, 140, r=30)),
    zone(poly([(410, 700), (590, 700), (500, 800)], r=[10, 10, 16])),
    # le visage
    zone(ellipse(500, 470, 170, 180)),
    *oeil(440, 470, 32, dy=6, p=0.58, ry=38), *oeil(560, 470, 32, dy=6, p=0.58, ry=38),
    trait(ligne((412, 438), (400, 420)), ligne((426, 432), (420, 412)), ligne((588, 438), (600, 420)),
          ligne((574, 432), (580, 412))),
    detail(cercle(400, 540, 30), cercle(600, 540, 30)),
    trait(arc(500, 540, 50, 30, 150), arc(500, 500, 12, 20, 160)),
    # la frange
    zone(lisse([(330, 400), (360, 320), (440, 290), (500, 300), (560, 290), (640, 320), (670, 400), (600, 350),
                (500, 370), (400, 350)])),
    # la couronne et ses pierres
    zone(poly([(390, 300), (380, 180), (440, 236), (500, 150), (560, 236), (620, 180), (610, 300)],
              r=[8, 10, 8, 10, 8, 10, 8])),
    detail(cercle(500, 250, 20), coeur(420, 270, 16), coeur(580, 270, 16)),
    detail(coeur(500, 740, 22)),
)


FLECHE = page(
    "fleche", "fete", "La flèche et la cible", "The arrow and the target",
    sol(860, vague=8),
    # le pied de la cible
    zone(tube([(560, 700), (500, 900)], 36)), zone(tube([(760, 700), (820, 900)], 36)),
    # la cible
    zone(cercle(660, 470, 290)),
    zone(cercle(660, 470, 218)),
    zone(cercle(660, 470, 146)),
    zone(cercle(660, 470, 74)),
    # la flèche, plantée au centre, et son empennage
    zone(tube([(100, 330), (650, 468)], 26)),
    zone(feuille((160, 344), (40, 262), 72)),
    zone(feuille((160, 344), (70, 424), 72)),
    trait(ligne((40, 200), (140, 225)), ligne((70, 150), (170, 175)), ligne((20, 470), (110, 492))),
)


POUSSER = page(
    "pousser", "fete", "La caisse à jouets", "Pushing the toy box",
    zone(rect(0, 850, 1000, 150)),
    # ce qui dépasse de la caisse
    zone(cercle(500, 400, 110)),
    trait(arc(500, 400, 110, 250, 350, ry=40), courbe([(430, 318), (470, 400), (440, 490)])),
    detail(cercle(718, 350, 46), cercle(838, 350, 46)),
    zone(cercle(778, 410, 88)),
    *oeil(748, 394, 17, dy=3, p=0.62), *oeil(808, 394, 17, dy=3, p=0.62),
    encre(ellipse(778, 440, 17, 13)),
    trait(arc(778, 446, 22, 30, 150)),
    zone(tourne(rect(300, 360, 120, 120, r=14), -12, 360, 420)),
    detail(tourne(etoile(360, 420, 36), -12, 360, 420)),
    # la caisse en planches, sur roulettes
    zone(rect(260, 470, 640, 330, r=20)),
    trait(ligne((260, 580), (900, 580)), ligne((260, 690), (900, 690))),
    *roue(340, 820, 44), *roue(820, 820, 44),
    # le bras et la main qui poussent
    zone(rect(0, 585, 150, 110, r=0)),
    zone(rect(120, 560, 60, 140, r=22)),
    detail(tube([(196, 600), (236, 548)], 42)),
    zone(rect(170, 580, 120, 110, r=46)),
    trait(ligne((282, 604), (240, 604)), ligne((286, 634), (240, 634)), ligne((282, 664), (240, 664))),
    trait(ligne((40, 470), (110, 470)), ligne((20, 520), (100, 520))),
)


PLOUF = page(
    "plouf", "fete", "Plouf dans la flaque !", "Splash!",
    nuage(260, 130, 170, 70, bosses=9), nuage(760, 150, 150, 62, bosses=8),
    detail(*[goutte(x, y, 14, 34) for x, y in [(180, 280), (300, 330), (420, 270), (680, 300), (800, 270),
                                                (900, 330)]]),
    zone(rect(0, 820, 1000, 180)),
    zone(ellipse(500, 850, 400, 90)),
    # la botte
    zone(rect(410, 370, 170, 330, r=24)),
    zone(rect(390, 350, 210, 60, r=24)),
    zone(lisse([(410, 640), (580, 620), (700, 650), (720, 740), (640, 770), (420, 770)])),
    # la couronne d'eau qui jaillit, les gouttes
    zone(lisse([(250, 800), (230, 640), (300, 720), (330, 590), (380, 700), (440, 620), (500, 720),
                (560, 610), (620, 710), (680, 600), (720, 710), (780, 630), (770, 800), (500, 830)])),
    detail(cercle(170, 560, 32), cercle(840, 520, 32), cercle(300, 470, 28), cercle(700, 470, 22),
           cercle(120, 680, 22), cercle(900, 690, 24)),
)


PAGES = [BALLONS, CIRQUE, TENNIS, PUZZLE, PRINCESSE, FLECHE, POUSSER, PLOUF, SOLEIL, LUNE]
