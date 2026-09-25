"""Album « Le petit train » : la locomotive, le fourgon, la gare, le serpent qui fait « sss ».

(Le petit train entier et le chat chef de gare sont dessinés à la main dans l'app :
PagesClassics.swift.)
"""
from __future__ import annotations

from .dessin import arc, arche, cercle, detail, ellipse, encre, ligne, page, poly, rect, trait, tube, zone
from .motifs import nuage, oeil, roue, sol, soleil


def _voie() -> list:
    """Voie en perspective vers le bas de la page : deux grandes traverses, puis les rails."""
    return [
        zone(poly([(320, 1000), (680, 1000), (627, 940), (373, 940)]),
             poly([(412, 895), (588, 895), (548, 850), (452, 850)])),
        zone(poly([(290, 1000), (350, 1000), (474, 835), (458, 835)]),
             poly([(650, 1000), (710, 1000), (542, 835), (526, 835)])),
    ]


LOCOMOTIVE = page(
    "locomotive", "train", "La locomotive", "The engine",
    nuage(180, 150, 110, 55),
    nuage(800, 120, 95, 48),
    sol(820, vague=8),
    *_voie(),
    # cabine derrière la chaudière
    zone(rect(215, 300, 570, 330, r=26)),
    zone(rect(195, 268, 610, 56, r=22)),
    zone(rect(250, 350, 120, 110, r=18), rect(630, 350, 120, 110, r=18)),
    # cheminée
    zone(poly([(430, 115), (570, 115), (548, 300), (452, 300)], r=10)),
    zone(rect(410, 88, 180, 50, r=18)),
    # chaudière vue de face, avec son visage
    zone(cercle(500, 470, 215)),
    zone(cercle(500, 470, 170)),
    *oeil(435, 425, 44, dx=6, dy=8),
    *oeil(565, 425, 44, dx=-6, dy=8),
    detail(cercle(398, 518, 30), cercle(602, 518, 30)),
    trait(arc(500, 500, 80, 25, 155)),
    # traverse avant, tampons, lanternes
    zone(rect(150, 640, 700, 90, r=18)),
    detail(cercle(222, 685, 32), cercle(778, 685, 32)),
    zone(rect(326, 650, 74, 72, r=12), rect(600, 650, 74, 72, r=12)),
    zone(poly([(390, 730), (610, 730), (570, 810), (430, 810)], r=12)),
    *roue(250, 790, 60, rayons=6), *roue(750, 790, 60, rayons=6),
)


FOURGON = page(
    "fourgon", "train", "Le fourgon", "The caboose",
    *soleil(130, 120, 58),
    nuage(760, 130, 120, 55),
    zone(rect(0, 790, 1000, 210)),                          # ballast
    zone(rect(0, 762, 1000, 38)),                           # rail
    zone(rect(360, 250, 280, 150, r=18)),                   # lanterneau
    zone(rect(335, 222, 330, 46, r=18)),
    zone(rect(395, 285, 90, 80, r=14), rect(515, 285, 90, 80, r=14)),
    zone(rect(120, 600, 760, 80, r=14)),                    # châssis
    zone(rect(110, 380, 780, 250, r=24)),                   # caisse
    zone(rect(80, 352, 840, 56, r=22)),                     # toit
    zone(arche(440, 450, 120, 170)),                        # porte
    detail(cercle(535, 545, 12)),                           # poignée
    zone(rect(170, 450, 150, 110, r=18), rect(680, 450, 150, 110, r=18)),
    trait(ligne((245, 452), (245, 558)), ligne((755, 452), (755, 558))),
    zone(rect(20, 428, 80, 114, r=16)),                     # lanterne
    detail(cercle(60, 485, 24)),
    detail(rect(84, 560, 34, 80, r=8), rect(882, 560, 34, 80, r=8)),   # marchepieds
    *roue(200, 712, 56, rayons=6), *roue(380, 712, 56, rayons=6),
    *roue(620, 712, 56, rayons=6), *roue(800, 712, 56, rayons=6),
)


GARE = page(
    "gare", "train", "La gare", "The station",
    *soleil(110, 100, 50, visage=False),
    nuage(830, 110, 110, 50),
    zone(rect(0, 740, 1000, 260)),                            # quai
    zone(rect(0, 836, 1000, 28)),                             # ligne jaune
    zone(rect(0, 912, 1000, 30)),                             # rail
    # tour de l'horloge
    zone(poly([(395, 185), (605, 185), (500, 70)], r=[8, 8, 10])),
    zone(rect(420, 175, 160, 140, r=6)),
    zone(cercle(500, 250, 56)),
    trait(ligne((500, 250), (500, 212)), ligne((500, 250), (532, 250))),
    encre(cercle(500, 250, 8)),
    # bâtiment
    zone(poly([(150, 420), (850, 420), (740, 300), (260, 300)], r=12)),
    trait(ligne((205, 380), (795, 380)), ligne((242, 340), (758, 340))),
    zone(rect(190, 410, 620, 332)),
    zone(rect(390, 436, 220, 60, r=14)),                      # enseigne
    zone(arche(440, 520, 120, 222)),                          # porte
    trait(ligne((500, 580), (500, 742))),
    zone(arche(226, 500, 144, 176), arche(630, 500, 144, 176)),
    trait(ligne((298, 500), (298, 676)), ligne((226, 594), (370, 594)),
          ligne((702, 500), (702, 676)), ligne((630, 594), (774, 594))),
    nuage(128, 712, 80, 40, bosses=6), nuage(824, 712, 80, 40, bosses=6),   # buissons
    # banc et lampadaire
    detail(rect(114, 766, 28, 42, r=5), rect(218, 766, 28, 42, r=5)),
    zone(rect(96, 742, 168, 34, r=10)),
    zone(rect(926, 480, 28, 280, r=8)),
    zone(poly([(888, 488), (992, 488), (970, 404), (910, 404)], r=8)),
)


SERPENT = page(
    "serpent", "train", "Le serpent qui fait « sss »", "The snake that goes “sss”",
    nuage(800, 130, 115, 52),
    sol(780, vague=12),
    nuage(880, 760, 80, 40, bosses=6),
    zone(tube([(880, 905), (730, 930), (560, 915), (420, 860), (360, 760), (420, 660), (570, 610),
               (660, 520), (630, 410), (500, 360), (390, 330)],
              [16, 44, 80, 110, 125, 130, 130, 125, 118, 110, 104])),
    detail(ellipse(470, 876, 40, 26, rot=25), ellipse(372, 752, 40, 26, rot=85),
           ellipse(520, 628, 40, 26, rot=-18), ellipse(646, 480, 40, 26, rot=-80)),
    detail(poly([(215, 326), (146, 330), (100, 298), (128, 342), (98, 386), (148, 356), (215, 360)],
                r=[0, 8, 4, 4, 4, 8, 0])),
    zone(ellipse(318, 330, 140, 108, rot=-8)),
    *oeil(282, 282, 38, dx=-8, dy=4, p=0.5),
    *oeil(372, 272, 38, dx=-8, dy=4, p=0.5),
    trait(arc(262, 350, 52, 25, 115)),
)


PAGES = [LOCOMOTIVE, FOURGON, GARE, SERPENT]
