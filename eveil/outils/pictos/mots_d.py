"""Les pictos des MOTS des livres des sons (lot D) : un nom par picto (`mot.<id>`).

Demande de l'utilisateur (06/10/2026) : « des mots avec 1 syllabe comme jus, peau » pour le
petit train et les livres des sons. Même style que les lots A, B et C : un seul objet ou
animal, bien centré, formes pleines et arrondies, couleurs vives mais accordées, pas de
contour noir, ombre douce au sol ; les animaux ont les yeux de la mascotte (`oeil`) et, de
profil, regardent vers la GAUCHE. Liste des mots : `eveil/outils/livres/mots.py`.

Lot D (14 mots) : peau, seau, riz, roue, lait, loup, main, pied, chou, bol, pull, poule,
toit, lion.

Choix de dessin : « peau » se montre par une PEAU DE BANANE ouverte en étoile ; « toit » par
une petite maison où le grand toit de tuiles domine ; la main et le pied ont la peau de Lou
(`figure.PEAU`). Les objets blancs (riz, lait) gardent un bord bleu-gris très pâle.

Repère : carré 200 × 200, y vers le bas ; le sujet tient dans 16…184, ombre au sol vers y ≈ 179.
"""
from __future__ import annotations

import math

from coloriages.dessin import (arc, cercle, corde, courbe, ellipse, etoile, goutte, ligne, lisse, poly, rect,
                               relire, tube)

from .figure import PEAU, PEAU_OMBRE
from .mots_b import decoupe, feuille
from .peinture import ENCRE, Picto, joue, oeil, ombre

Point = tuple[float, float]

ROUGE = "#EF4452"
ROUGE_FONCE = "#D32F41"
JAUNE = "#FFD23F"
BLEU = "#3FA7F5"
BLEU_FONCE = "#2B86D0"
BLANC = "#FFFFFF"
BLANC_OMBRE = "#E6ECF4"     # l'ombre des objets blancs
BORD_PALE = "#C4D0E0"       # le bord très pâle des objets blancs (pas un contour noir)
ONGLE = "#E8B49A"           # ongles, plus clairs que la peau


def _pt(o: Point, angle: float, r: float) -> Point:
    a = math.radians(angle)
    return (o[0] + math.cos(a) * r, o[1] + math.sin(a) * r)


def _decale(p: Picto, dx: float, dy: float = 0.0) -> Picto:
    """Recentre un picto fini : décale tous ses tracés (ombre comprise) de (dx, dy)."""
    for op in p.ops:
        op.d = " ".join(c.map(lambda q: (q[0] + dx, q[1] + dy)).d() for c in relire(op.d))
    return p


# ---------------------------------------------------------------------------
# Les mots
# ---------------------------------------------------------------------------

def peau() -> Picto:
    """Une peau de banane posée au sol : la queue dressée, quatre lanières ouvertes en étoile, bouts bruns."""
    p = Picto("mot.peau")
    jaune, fonce, creme, brun = "#FFDB4D", "#F2B829", "#FFF3C2", "#7A5A2A"
    ombre(p, 100, 174, 80, 8)
    # Les deux lanières du fond, relevées puis retombées : on en voit l'intérieur crème.
    for sens in (-1, 1):
        chemin_ = [(100, 116), (100 + 26 * sens, 98), (100 + 54 * sens, 104), (100 + 70 * sens, 132)]
        p.plein(fonce, tube(chemin_, [18, 26, 24, 12]))
        p.plein(creme, tube([(100 + 6 * sens, 112), (100 + 26 * sens, 103), (100 + 50 * sens, 108),
                             (100 + 63 * sens, 128)], [8, 16, 14, 5]))
        p.plein(brun, cercle(100 + 71 * sens, 135, 6))
    # Le haut de la peau, dressé, et la queue brune.
    p.plein(jaune, tube([(100, 132), (100, 100), (103, 74)], [26, 18, 12]))
    p.plein("#8A6A2F", tube([(103, 78), (106, 56)], [10, 8]))
    p.plein("#5E4520", cercle(106.5, 54, 4.5))
    # Les deux lanières de devant, couchées au sol (dessus jaune, nervure, bouts bruns).
    for sens in (-1, 1):
        p.plein(jaune, tube([(100, 124), (100 + 22 * sens, 136), (100 + 48 * sens, 156), (100 + 74 * sens, 166)],
                            [24, 28, 24, 13]))
        p.plein(fonce, tube([(100 + 24 * sens, 144), (100 + 48 * sens, 160), (100 + 66 * sens, 166)], [4, 6, 4]))
        p.plein(brun, cercle(100 + 77 * sens, 166, 7))
    p.plein(jaune, ellipse(100, 128, 18, 14))
    p.plein("#FFF0A6", tube([(97, 84), (96, 112)], 4.5))
    return p


def seau() -> Picto:
    """Un seau de plage rouge à bord bleu, anse jaune, une étoile de mer peinte ; un petit tas de sable."""
    p = Picto("mot.seau")
    sable, sable_fonce = "#F3D18A", "#E2B866"
    ombre(p, 100, 178, 70, 6)
    # Le sable au pied du seau.
    p.plein(sable, lisse([(24, 176), (40, 160), (66, 156), (100, 162), (136, 156), (164, 160), (178, 176)]))
    p.plein(sable_fonce, cercle(44, 168, 2.2), cercle(150, 166, 2.2), cercle(162, 172, 1.8), cercle(34, 173, 1.8))
    # L'anse (derrière), le corps évasé, le bord bleu, l'ouverture.
    p.trait("#F5B82E", 7, arc(100, 64, 52, 190, 350, 44))
    corps = poly([(50, 64), (150, 64), (134, 170), (66, 170)], r=[4, 4, 10, 10])
    p.plein(ROUGE, corps)
    p.plein(ROUGE_FONCE, decoupe(corps, poly([(122, 60), (160, 60), (160, 180), (112, 180)])))
    p.plein("#FF7A84", rect(64, 84, 9, 64, r=4.5))
    p.plein(BLEU, rect(44, 56, 112, 22, r=8))
    p.plein(BLEU_FONCE, ellipse(100, 59, 52, 6))
    p.plein("#8FD0F8", rect(52, 70, 40, 4, r=2))
    # Les attaches de l'anse, l'étoile de mer.
    p.plein("#F5B82E", cercle(50, 68, 6), cercle(150, 68, 6))
    p.plein(JAUNE, etoile(100, 122, 22, 10, coins=4))
    p.plein("#F5B82E", cercle(100, 122, 4))
    return p


def riz() -> Picto:
    """Un bol bleu plein de riz blanc en dôme (grains visibles), deux baguettes posées dessus."""
    p = Picto("mot.riz")
    ombre(p, 100, 178, 58, 6)
    # Le bol : pied, paroi bleue, bandeau blanc à vagues, le bord du fond.
    p.plein(BLEU_FONCE, rect(74, 156, 52, 16, r=5))
    paroi = corde(100, 106, 70, 0, 180, 58)
    p.plein(BLEU, paroi)
    p.plein(BLANC, decoupe(rect(20, 122, 160, 14), paroi))
    p.trait(BLEU, 3, courbe([(40, 129), (52, 124), (64, 129), (76, 134), (88, 129), (100, 124), (112, 129),
                             (124, 134), (136, 129), (148, 124), (160, 129)]))
    p.plein("#8FD0F8", ellipse(100, 106, 70, 9))
    # Le dôme de riz posé dans le bol (bord pâle, ombre en bas à droite), les grains.
    dome = corde(100, 108, 64, 180, 360, 54)
    p.trait(BORD_PALE, 4, dome)
    p.plein(BLANC, dome)
    p.plein(BLANC_OMBRE, decoupe(dome, ellipse(124, 112, 42, 26)))
    grains = [(70, 96, 20), (84, 82, 70), (100, 74, -30), (118, 86, 40), (132, 98, -60), (94, 96, 10),
              (110, 102, 80), (80, 104, -40), (122, 70, 10), (66, 80, 50), (138, 84, -20), (104, 88, 60),
              (88, 66, -70), (54, 102, 20), (148, 102, 30)]
    for x, y, rot in grains:
        p.trait(BORD_PALE, 2, ellipse(x, y, 5, 2.6, rot=rot))
    # Le bord avant du bol passe devant le riz.
    p.plein(BLEU, decoupe(paroi, rect(20, 106, 160, 8)))
    p.plein("#8FD0F8", decoupe(ellipse(100, 106, 70, 9), rect(20, 106, 160, 10)))
    # Les baguettes, posées en travers du riz.
    p.plein("#C8834A", tube([(54, 64), (158, 38)], [6, 4]), tube([(60, 78), (166, 60)], [6, 4]))
    p.plein("#A9683A", tube([(54, 64), (70, 60)], 6.5), tube([(60, 78), (76, 75)], 6.5))
    return p


def roue() -> Picto:
    """Une roue debout : gros pneu sombre à crampons, jante claire à cinq rayons, moyeu."""
    p = Picto("mot.roue")
    pneu, pneu_fonce, pneu_clair = "#3A3F5C", "#2C3048", "#565C7A"
    jante, jante_fonce, moyeu = "#D7DCEA", "#AEB5CA", "#8A90A6"
    cx, cy, r = 100, 100, 76
    ombre(p, 100, 178, 62, 6)
    # Le pneu, ses crampons sur le bord, un reflet.
    p.plein(pneu, cercle(cx, cy, r))
    for k in range(20):
        a = k * 18 + 9
        x, y = _pt((cx, cy), a, r - 7)
        p.plein(pneu_fonce, ellipse(x, y, 7, 3.2, rot=a + 90))
    p.trait(pneu_clair, 5, arc(cx, cy, r - 18, 200, 250))
    # La jante, les rayons, le moyeu et ses boulons.
    p.plein(jante_fonce, cercle(cx, cy, 44))
    p.plein(jante, cercle(cx, cy, 40))
    p.plein(jante_fonce, cercle(cx, cy, 30))
    for k in range(5):
        a = -90 + k * 72
        p.plein(jante, tube([_pt((cx, cy), a, 8), _pt((cx, cy), a, 34)], [14, 10]))
    p.plein(moyeu, cercle(cx, cy, 14))
    p.plein(jante, cercle(cx, cy, 6))
    for k in range(5):
        p.plein(jante_fonce, cercle(*_pt((cx, cy), -54 + k * 72, 10), 1.8))
    return p


def lait() -> Picto:
    """Une brique de lait : toit pointu, face blanche et bleue, une grosse goutte de lait et une vache."""
    p = Picto("mot.lait")
    ombre(p, 104, 178, 56, 6)
    # Le côté (ombré), puis la face ; le toit en pignon et sa languette.
    p.trait(BORD_PALE, 4, poly([(126, 66), (150, 52), (150, 162), (126, 174)]))
    p.plein(BLANC_OMBRE, poly([(126, 66), (150, 52), (150, 162), (126, 174)]))
    p.plein("#2B86D0", poly([(126, 120), (150, 108), (150, 162), (126, 174)]))
    face = rect(56, 66, 70, 108, r=3)
    p.trait(BORD_PALE, 4, face)
    p.plein(BLANC, face)
    p.trait(BORD_PALE, 4, poly([(56, 66), (91, 34), (126, 66)]), poly([(91, 34), (126, 66), (150, 52), (117, 22)]))
    p.plein(BLANC_OMBRE, poly([(91, 34), (126, 66), (150, 52), (117, 22)]))
    p.plein(BLANC, poly([(56, 66), (91, 34), (126, 66)]))
    p.plein(BLEU, poly([(84, 30), (91, 24), (120, 14), (118, 22)], r=1.5))
    # Le bas de la face en bleu, bord en vague ; la goutte de lait blanche.
    bleu = lisse([(56, 116), (70, 110), (84, 116), (98, 122), (112, 116), (126, 110), (126, 174), (56, 174)],
                 tension=0.6)
    p.plein(BLEU, decoupe(bleu, face))
    p.trait(BORD_PALE, 3, goutte(91, 142, 15, 24))
    p.plein(BLANC, goutte(91, 142, 15, 24))
    p.plein(BLANC_OMBRE, ellipse(96, 148, 6, 7))
    # La petite tête de vache sur le haut de la face.
    p.plein(BLANC, ellipse(91, 88, 17, 14))
    p.trait("#4E4760", 2, ellipse(91, 88, 17, 14))
    p.plein("#4E4760", ellipse(98, 82, 7, 5, rot=20))
    p.plein("#F7A9B9", ellipse(91, 96, 11, 6))
    p.plein("#4E4760", ellipse(74, 82, 6, 3.5, rot=-20), ellipse(108, 82, 6, 3.5, rot=20))
    oeil(p, 85, 86, 3)
    oeil(p, 97, 86, 3)
    p.plein("#D9849A", cercle(87, 96, 1.6), cercle(95, 96, 1.6))
    return p


def loup() -> Picto:
    """Un loup gris assis, de profil (vers la gauche) : long museau, oreilles pointues, queue touffue."""
    p = Picto("mot.loup")
    gris, gris_fonce, gris_loin, creme = "#8E98AE", "#6F7891", "#7C8599", "#EEF0F5"
    ombre(p, 108, 179, 60, 6)
    # La queue touffue posée au sol derrière, bout clair.
    queue = tube([(138, 158), (164, 154), (178, 132), (178, 110)], [18, 24, 22, 10])
    p.plein(gris_fonce, queue)
    p.plein(creme, decoupe(queue, ellipse(180, 104, 16, 16)))
    # La patte avant lointaine, le corps assis (en poire), la cuisse, le pied arrière.
    p.plein(gris_loin, tube([(90, 120), (92, 166)], 12), ellipse(91, 169, 9, 5.5))
    corps = lisse([(78, 96), (110, 92), (138, 112), (152, 146), (142, 170), (100, 172), (76, 160), (70, 122)])
    p.plein(gris, corps)
    p.plein(gris_fonce, decoupe(corps, ellipse(118, 84, 40, 22, rot=30)))
    p.plein(gris_fonce, ellipse(128, 146, 26, 23))
    p.plein(gris, ellipse(126, 144, 23, 20), ellipse(120, 169, 28, 7))
    # Le poitrail crème, la patte avant proche.
    p.plein(creme, lisse([(64, 104), (80, 100), (86, 128), (80, 150), (70, 140)]))
    p.plein(gris, tube([(78, 124), (76, 166)], 13), ellipse(74, 169, 11, 6))
    # La tête : oreilles pointues, crâne, long museau crème, truffe.
    p.plein(gris_fonce, poly([(78, 66), (90, 34), (96, 70)], r=[3, 4, 3]))
    p.plein(gris, ellipse(74, 82, 26, 22))
    p.plein(gris, poly([(84, 92), (100, 104), (90, 108), (96, 116), (78, 108)], r=2))
    p.plein(gris, poly([(60, 66), (66, 32), (82, 64)], r=[3, 4, 3]))
    p.plein("#F2B8C4", poly([(66, 62), (68, 42), (77, 62)], r=[2, 3, 2]))
    p.plein(gris, lisse([(60, 78), (36, 86), (24, 94), (30, 102), (60, 104)]))
    p.plein(creme, lisse([(56, 92), (32, 96), (28, 101), (40, 106), (66, 108), (80, 102)]))
    p.plein(ENCRE, ellipse(26, 92, 5.5, 4.5))
    p.trait(ENCRE, 2, courbe([(30, 102), (38, 104), (44, 101)]))
    oeil(p, 64, 78, 5.4)
    joue(p, 70, 94, 4.5)
    return p


def main() -> Picto:
    """Une main ouverte, paume vers nous : cinq doigts bien séparés, une manche à rayures."""
    p = Picto("mot.main")
    ombre(p, 100, 179, 40, 5)
    # La manche (poignet) au pied de la main.
    p.plein(BLEU, rect(72, 150, 56, 30, r=8))
    p.plein("#8FD0F8", rect(72, 156, 56, 6, r=3), rect(72, 168, 56, 6, r=3))
    # Les doigts (du petit à l'index), le pouce, la paume.
    doigts = [((80, 104), (62, 62), 17), ((92, 98), (86, 38), 18), ((106, 98), (110, 30), 18.5),
              ((119, 102), (134, 44), 17.5)]
    for base, bout, lg in doigts:
        p.plein(PEAU, tube([base, bout], [lg, lg * 0.92]))
    p.plein(PEAU, tube([(116, 136), (142, 118), (158, 98)], [26, 20, 16]))
    p.plein(PEAU, rect(70, 92, 62, 66, r=26))
    # Les plis : à la base des doigts, autour du pouce, au creux de la paume.
    for base, bout, lg in doigts:
        dx, dy = bout[0] - base[0], bout[1] - base[1]
        ln = math.hypot(dx, dy)
        x, y = base[0] + dx / ln * 22, base[1] + dy / ln * 22
        nx, ny = -dy / ln * lg * 0.28, dx / ln * lg * 0.28
        p.trait(PEAU_OMBRE, 2, ligne((x - nx, y - ny), (x + nx, y + ny)))
    p.trait(PEAU_OMBRE, 2.4, courbe([(80, 116), (96, 120), (112, 114)]))
    return p


def pied() -> Picto:
    """Un pied nu vu de dessus, talon en bas : cinq orteils serrés, du gros au petit, ongles clairs."""
    p = Picto("mot.pied")
    ombre(p, 102, 179, 46, 6)
    # Les orteils (derrière le bord du pied) : le gros à gauche, puis de plus en plus petits.
    orteils = [(78, 56, 15, -8), (102, 47, 10.5, -2), (120, 51, 9.5, 6), (135, 61, 8.5, 14), (147, 75, 7.5, 24)]
    for x, y, r, rot in orteils:
        p.plein(PEAU, ellipse(x, y, r, r * 1.35, rot=rot))
    # Le pied : large à l'avant, creux de la voûte à gauche, talon rond en bas.
    p.plein(PEAU, lisse([(66, 74), (92, 62), (122, 64), (144, 76), (152, 92), (144, 118), (132, 142), (126, 164),
                         (110, 178), (90, 176), (82, 158), (84, 132), (70, 108)]))
    for x, y, r, rot in orteils:
        p.plein(ONGLE, ellipse(x, y - r * 0.55, r * 0.6, r * 0.52, rot=rot))
    # Les petits plis à la racine des orteils.
    p.trait(PEAU_OMBRE, 2.2, courbe([(70, 74), (80, 72), (90, 70)]), courbe([(96, 64), (104, 62), (112, 63)]),
            courbe([(116, 66), (124, 67)]), courbe([(130, 72), (138, 76)]))
    return p


def chou() -> Picto:
    """Un chou vert : grosses feuilles ouvertes à nervures claires autour d'une pomme aux feuilles enroulées."""
    p = Picto("mot.chou")
    vert, vert_fonce, vert_clair, vert_moyen, nervure = "#5CBF60", "#3F9E57", "#A6DF94", "#4FB357", "#D2F2C4"
    ombre(p, 100, 178, 72, 7)
    # Les grandes feuilles extérieures, ouvertes vers les côtés.
    for base, bout, lg in (((100, 140), (26, 150), 46), ((100, 140), (174, 150), 46), ((100, 128), (32, 92), 42),
                           ((100, 128), (168, 92), 42)):
        p.plein(vert_fonce, feuille(base, bout, lg))
        p.trait(vert, 3, ligne(base, ((base[0] + bout[0] * 2) / 3, (base[1] + bout[1] * 2) / 3)))
    p.plein(vert_fonce, ellipse(100, 152, 58, 24))
    # La pomme : le cœur clair et ses plis, puis deux feuilles qui l'enroulent de chaque côté.
    p.plein(vert, cercle(100, 110, 52))
    p.plein(vert_clair, cercle(100, 102, 38))
    p.trait(vert, 3, arc(100, 116, 30, 205, 335), arc(100, 116, 18, 210, 330))
    p.trait(nervure, 2.6, courbe([(100, 136), (99, 116), (101, 92)]))
    for sens in (-1, 1):
        c = vert if sens < 0 else vert_moyen
        p.plein(c, lisse([(100 - 50 * sens, 118), (100 - 46 * sens, 84), (100 - 30 * sens, 64),
                          (100 - 20 * sens, 68), (100 - 26 * sens, 100), (100 - 18 * sens, 134),
                          (100 - 2 * sens, 160), (100 - 32 * sens, 152)]))
        p.trait(nervure, 3, courbe([(100 - 6 * sens, 154), (100 - 26 * sens, 128), (100 - 32 * sens, 96),
                                    (100 - 28 * sens, 72)]))
        p.trait(nervure, 2.2, courbe([(100 - 30 * sens, 118), (100 - 44 * sens, 110)]),
                courbe([(100 - 32 * sens, 98), (100 - 44 * sens, 90)]))
    p.trait("#FFFFFF77", 4, arc(100, 110, 44, 205, 235))
    return p


def bol() -> Picto:
    """Un bol vide orange vu de trois quarts : on voit le dedans, des pois blancs et un liseré."""
    p = Picto("mot.bol")
    orange, orange_fonce, dedans, dedans_fonce = "#FF9A2E", "#E87D1A", "#FFE2B8", "#F7C98A"
    ombre(p, 100, 176, 62, 7)
    p.plein(orange_fonce, rect(70, 152, 60, 18, r=6))
    paroi = corde(100, 90, 76, 0, 180, 72)
    p.plein(orange, paroi)
    p.plein(orange_fonce, decoupe(paroi, ellipse(170, 120, 40, 70)))
    p.plein(BLANC, *[decoupe(cercle(x, y, 7), paroi) for x, y in ((48, 112), (76, 124), (104, 128), (132, 122),
                                                                  (156, 108), (62, 140), (90, 148), (118, 146))])
    p.plein("#FFC266", decoupe(rect(20, 96, 160, 6), paroi))
    # Le bord et le dedans du bol (vide : fond plus sombre en bas).
    p.plein(orange_fonce, ellipse(100, 90, 76, 22))
    p.plein(dedans, ellipse(100, 91, 70, 18))
    p.plein(dedans_fonce, decoupe(ellipse(100, 91, 70, 18), ellipse(100, 112, 64, 18)))
    p.trait("#FFFFFFAA", 4, arc(100, 91, 60, 200, 250, 14))
    return p


def pull() -> Picto:
    """Un pull rouge à plat : manches écartées, côtes au col, aux poignets et en bas, un rang de cœurs."""
    p = Picto("mot.pull")
    laine, laine_fonce, cote, motif = "#EF4452", "#D32F41", "#C42A3B", "#FFD23F"
    ombre(p, 100, 179, 70, 6)
    # Les manches (derrière le corps) et leurs poignets.
    for sens in (-1, 1):
        p.plein(laine, tube([(100 + 40 * sens, 56), (100 + 64 * sens, 104), (100 + 72 * sens, 140)], [40, 32, 28]))
        p.plein(cote, tube([(100 + 71 * sens, 138), (100 + 73 * sens, 160)], 28))
        for k in range(-2, 3):
            p.trait(laine_fonce, 2, ligne((100 + (72 + k * 5) * sens, 142), (100 + (73 + k * 5) * sens, 160)))
    # Le corps, la bande du bas à côtes.
    p.plein(laine, rect(58, 44, 84, 120, r=14))
    p.plein(cote, rect(58, 150, 84, 26, r=8))
    for k in range(9):
        p.trait(laine_fonce, 2, ligne((64 + k * 9, 154), (64 + k * 9, 172)))
    # Le col rond à côtes.
    p.plein(cote, corde(100, 44, 26, 0, 180, 18))
    p.plein("#B02434", corde(100, 44, 16, 0, 180, 9))
    # Le motif tricoté : un rang de petits cœurs, des points de maille.
    from coloriages.dessin import coeur
    for x in (74, 100, 126):
        p.plein(motif, coeur(x, 104, 9))
    for y in (82, 128):
        for k in range(7):
            p.plein("#FF7A84", cercle(66 + k * 11.3, y, 2.4))
    return p


def poule() -> Picto:
    """Une poule rousse de profil (vers la gauche), posée au sol : petite crête rouge, queue courte."""
    p = Picto("mot.poule")
    plume, plume_fonce, aile, bec = "#D98A4A", "#BF6F35", "#B8642C", "#FFC83D"
    ombre(p, 104, 179, 58, 6)
    # Les pattes jaunes, courtes, et les doigts.
    for x in (92, 116):
        p.plein(bec, tube([(x, 150), (x - 1, 168)], 6))
        p.trait(bec, 4, ligne((x - 1, 168), (x - 12, 174)), ligne((x - 1, 168), (x - 4, 176)),
                ligne((x - 1, 168), (x + 7, 174)))
    # La queue courte relevée, le corps rond.
    p.plein(plume_fonce, poly([(130, 110), (162, 62), (176, 72), (168, 124)], r=[6, 10, 10, 8]))
    p.plein(plume, lisse([(60, 100), (92, 96), (130, 98), (160, 96), (164, 124), (142, 154), (104, 162), (70, 150),
                          (56, 126)]))
    # L'aile, ses plumes.
    p.plein(aile, ellipse(116, 124, 30, 19, rot=-8))
    p.trait(plume_fonce, 3, courbe([(98, 128), (116, 132), (138, 124)]), courbe([(104, 138), (120, 140), (136, 134)]))
    # La tête, la petite crête, le bec, le barbillon.
    p.plein(ROUGE, cercle(58, 46, 7), cercle(67, 42, 8), cercle(76, 47, 7))
    p.plein(plume, cercle(66, 66, 22), tube([(68, 76), (80, 104)], 30))
    p.plein(bec, poly([(46, 62), (28, 69), (46, 76)], r=[2, 3, 2]))
    p.plein(ROUGE, goutte(48, 86, 5, 11))
    oeil(p, 60, 61, 4.8)
    joue(p, 70, 74, 4.2)
    return p


def toit() -> Picto:
    """Une petite maison vue de face dont le grand toit rouge à tuiles domine : murs bas, porte, fenêtre."""
    p = Picto("mot.toit")
    tuile, tuile_fonce, tuile_claire = "#E5503F", "#C43B2E", "#F27A63"
    mur, mur_fonce = "#FFE1A8", "#F2C77E"
    ombre(p, 100, 178, 76, 6)
    # La cheminée (derrière le toit).
    p.plein("#B9774A", rect(132, 34, 18, 36, r=2))
    p.plein("#8E5733", rect(128, 30, 26, 8, r=2))
    # Les murs bas, la porte, la fenêtre.
    p.plein(mur, rect(44, 120, 112, 56, r=3))
    p.plein(mur_fonce, rect(44, 120, 112, 8))
    p.plein("#3FA7F5", rect(118, 134, 26, 22, r=3))
    p.trait(BLANC, 3, ligne((131, 134), (131, 156)), ligne((118, 145), (144, 145)))
    p.plein("#A86B32", rect(68, 132, 28, 44, r=12))
    p.plein(JAUNE, cercle(90, 156, 2.6))
    # Le grand toit : tuiles en écailles, rang par rang, puis la rive (la planche du bas).
    toit_ = poly([(100, 22), (184, 124), (16, 124)], r=[6, 4, 4])
    p.plein(tuile_fonce, toit_)
    for k, y in enumerate(range(40, 126, 14)):
        dx = 0 if k % 2 else 9
        for x in range(4 - 18 + dx, 200, 18):
            ecaille = decoupe(corde(x, y, 9.5, 0, 180, 11), toit_)
            if ecaille:
                p.plein(tuile if (x // 18 + k) % 3 else tuile_claire, ecaille)
    p.plein("#8E2E25", rect(12, 120, 176, 9, r=4.5))
    p.plein(tuile_fonce, cercle(100, 26, 6))
    return p


def lion() -> Picto:
    """Un lion assis, de face : grosse crinière orange, visage doré, museau clair, queue à pompon."""
    p = Picto("mot.lion")
    criniere, criniere_fonce, poil, poil_fonce, creme = "#E8862E", "#C96A1E", "#F6C04E", "#E2A53A", "#FFE9B0"
    ombre(p, 100, 179, 58, 6)
    # La queue à pompon (derrière), le corps assis, les pattes arrière.
    p.plein(poil_fonce, tube([(130, 160), (158, 156), (168, 132)], [9, 8, 7]))
    p.plein(criniere_fonce, cercle(168, 126, 9))
    p.plein(poil, ellipse(100, 140, 38, 36))
    p.plein(poil_fonce, ellipse(70, 160, 18, 14), ellipse(130, 160, 18, 14))
    p.plein(poil, ellipse(72, 158, 15, 12), ellipse(128, 158, 15, 12))
    p.plein(creme, ellipse(100, 140, 20, 26))
    # Les pattes avant.
    for x in (88, 112):
        p.plein(poil, rect(x - 10, 132, 20, 42, r=10))
        p.trait(poil_fonce, 2, ligne((x - 3, 168), (x - 3, 174)), ligne((x + 3, 168), (x + 3, 174)))
    # La crinière en pétales, puis la tête.
    cx, cy = 100, 76
    for k in range(14):
        a = k * 360 / 14
        x, y = _pt((cx, cy), a, 44)
        p.plein(criniere_fonce if k % 2 else criniere, cercle(x, y, 18))
    p.plein(criniere, cercle(cx, cy, 48))
    p.plein(poil, cercle(cx - 28, cy - 30, 10), cercle(cx + 28, cy - 30, 10))
    p.plein("#F3A35E", cercle(cx - 28, cy - 30, 5), cercle(cx + 28, cy - 30, 5))
    p.plein(poil, ellipse(cx, cy + 2, 34, 32))
    # Le museau, le nez, la bouche, les yeux, les joues.
    p.plein(creme, ellipse(cx - 9, cy + 16, 12, 10), ellipse(cx + 9, cy + 16, 12, 10))
    p.plein("#B4583A", poly([(cx - 8, cy + 4), (cx + 8, cy + 4), (cx, cy + 12)], r=[3, 3, 3]))
    p.trait(ENCRE, 2, courbe([(cx, cy + 12), (cx - 5, cy + 20), (cx - 10, cy + 18)]),
            courbe([(cx, cy + 12), (cx + 5, cy + 20), (cx + 10, cy + 18)]))
    oeil(p, cx - 14, cy - 8, 5.4)
    oeil(p, cx + 14, cy - 8, 5.4)
    joue(p, cx - 24, cy + 10, 5)
    joue(p, cx + 24, cy + 10, 5)
    return p


PICTOS: list[Picto] = [peau(), seau(), riz(), roue(), lait(), loup(), main(), pied(), chou(), bol(), pull(), poule(),
                       toit(), lion()]
