"""Les pictos des MOTS des livres des sons (lot A) : un nom par picto (`mot.<id>`).

Les livres des sons (un livre par son, comme OrthoPicto) ont besoin de mots dessinés pour
chaque son : ceux-ci complètent les dessins du petit train et du train des phrases. Même
style que `WordArt` : un seul objet ou animal, bien centré, formes pleines et arrondies,
couleurs vives mais accordées, pas de contour noir, ombre douce au sol ; les animaux ont
les yeux de la mascotte (`oeil`). Liste des mots : `eveil/outils/livres/mots.py`.

Lot A (28 mots) : fleur, feu, fée, fusée, fraise, fourchette, phoque, girafe, vélo, verre,
valise, vague, cheval, jupe, genou, orange, neige, cage, gâteau, gomme, guitare, gant,
grenouille, bague, dragon, dent, dinosaure, dé.

Repère : carré 200 × 200, y vers le bas ; le sujet tient dans 16…184, ombre au sol vers
y ≈ 179. Les animaux de profil regardent vers la GAUCHE. Les objets blancs (dent, dé,
fusée, neige) gardent un bord bleu-gris très pâle pour se détacher du fond blanc des cartes.
"""
from __future__ import annotations

import math

from coloriages.dessin import (Contour, arc, cercle, coeur, courbe, deplace, echelle, ellipse, etoile, goutte, lisse,
                               poly, rect, tourne, trou, tube)

from .accessoires import BOIS, BOIS_CLAIR, BOIS_FONCE
from .peinture import ENCRE, Picto, joue, oeil, ombre

Point = tuple[float, float]

# Palette commune (vive mais accordée, celle des dessins de l'app).
ROUGE = "#EF4452"
ROUGE_FONCE = "#D32F41"
JAUNE = "#FFD23F"
VERT = "#4CB963"
VERT_FONCE = "#3A9A50"
BLEU = "#3FA7F5"
BLANC = "#FFFFFF"
BLANC_OMBRE = "#DCE4EF"     # l'ombre des objets blancs
BORD_PALE = "#C4D0E0"       # le bord très pâle des objets blancs (pas un contour noir)
METAL = "#BAC5D4"
METAL_FONCE = "#98A5B9"
METAL_CLAIR = "#EEF2F7"
PEAU_LOU = "#B8784E"        # la peau de Lou (figure.PEAU)


# ---------------------------------------------------------------------------
# Petits outils de forme
# ---------------------------------------------------------------------------

def _pt(o: Point, angle: float, r: float) -> Point:
    a = math.radians(angle)
    return (o[0] + math.cos(a) * r, o[1] + math.sin(a) * r)


def _plein(c: Contour) -> list[Contour]:
    """Oriente un contour fermé dans le sens « plein » (aire positive) : pas de trou par mégarde."""
    return [c if c.area() >= 0 else c.reversed()]


def chemin(depart: Point, *segs) -> list[Contour]:
    """Contour fermé tracé à la main : segments ("L", p) ou ("C", c1, c2, p)."""
    return _plein(Contour(depart, list(segs)))


def feuille(a: Point, b: Point, largeur: float, courbure: float = 0.0) -> list[Contour]:
    """Une feuille en amande de `a` à `b` (pointes aux deux bouts), `largeur` au plus large.

    `courbure` décale le milieu de la feuille sur le côté (feuille qui se cambre).
    """
    (x0, y0), (x1, y1) = a, b
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln, dx / ln
    h = largeur / 1.5          # une cubique dont les deux points de contrôle sont décalés de h s'écarte de 0,75 h

    def c(t: float, k: float) -> Point:
        return (x0 + dx * t + nx * k, y0 + dy * t + ny * k)
    k1, k2 = h + courbure, -h + courbure
    return chemin(a, ("C", c(1 / 3, k1), c(2 / 3, k1), b), ("C", c(2 / 3, k2), c(1 / 3, k2), a))


def flamme(cx: float, cy: float, r: float, h: float, angle: float = 0.0) -> list[Contour]:
    """Une langue de feu : une goutte (pointe en haut) penchée de `angle` degrés autour de son rond."""
    f = goutte(cx, cy, r, h)
    return tourne(f, angle, cx, cy) if angle else f


def _coupe(p0: Point, c1: Point, c2: Point, p3: Point, t: float):
    """Coupe une cubique en `t` (de Casteljau) : (moitié avant, moitié arrière), chacune (p0, c1, c2, p3)."""
    def m(a, b):
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    ab, bc, cd = m(p0, c1), m(c1, c2), m(c2, p3)
    abc, bcd = m(ab, bc), m(bc, cd)
    mil = m(abc, bcd)
    return (p0, ab, abc, mil), (mil, bcd, cd, p3)


def _t_a_hauteur(p0: Point, c1: Point, c2: Point, p3: Point, y: float) -> float:
    """Le paramètre t où une cubique monotone en y passe à la hauteur `y` (dichotomie)."""
    def yy(t):
        u = 1 - t
        return u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p3[1]
    lo, hi = 0.0, 1.0
    croissant = yy(1) > yy(0)
    for _ in range(50):
        mil = (lo + hi) / 2
        if (yy(mil) < y) == croissant:
            lo = mil
        else:
            hi = mil
    return (lo + hi) / 2


def _bez(p0: Point, c1: Point, c2: Point, p3: Point, t: float) -> Point:
    """Le point de paramètre t d'une cubique."""
    u = 1 - t
    return (u ** 3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p3[0],
            u ** 3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p3[1])


def _pointe(base: Point, normale: Point, h: float, demi: float) -> list[Contour]:
    """Une pointe (crête, corne) qui sort d'un bord : base enfoncée de 3, hauteur h, demi-largeur `demi`."""
    nx, ny = normale
    n = math.hypot(nx, ny)
    nx, ny = nx / n, ny / n
    bx, by = base[0] - nx * 3, base[1] - ny * 3
    return poly([(bx + ny * demi, by - nx * demi), (base[0] + nx * h, base[1] + ny * h),
                 (bx - ny * demi, by + nx * demi)], r=[2, 2.5, 2])


# ---------------------------------------------------------------------------
# Le son [f] : fleur, feu, fée, fusée, fraise, fourchette, phoque, girafe
# ---------------------------------------------------------------------------

def fleur() -> Picto:
    """Une fleur rouge à cœur jaune : tige, deux feuilles, une corolle de pétales ronds."""
    p = Picto("mot.fleur")
    ombre(p, 100, 179, 34, 6)
    p.plein(VERT_FONCE, tube([(100, 177), (96, 146), (99, 114), (100, 92)], 8))
    p.plein(VERT, feuille((98, 152), (52, 124), 26, -5), feuille((99, 138), (148, 112), 26, 5))
    p.trait(VERT_FONCE, 2.2, courbe([(92, 148), (74, 136), (62, 130)]), courbe([(106, 134), (124, 122), (138, 117)]))
    c = (100, 66)
    p.plein(ROUGE_FONCE, *[cercle(*_pt(c, -60 + i * 60, 31), 16) for i in range(6)])
    p.plein(ROUGE, *[cercle(*_pt(c, -90 + i * 60, 28), 20) for i in range(6)])
    p.plein(JAUNE, cercle(c[0], c[1], 17))
    p.plein("#F5A623", *[cercle(*_pt(c, 30 + a, 8.5), 2.3) for a in range(0, 360, 72)], cercle(c[0], c[1], 2.3))
    return p


def feu() -> Picto:
    """Un feu de camp : flammes orange et jaunes sur deux bûches croisées, deux étincelles."""
    p = Picto("mot.feu")
    ombre(p, 100, 179, 74, 7)
    # Les flammes, derrière les bûches : orange, puis jaune, puis le cœur jaune pâle.
    p.plein("#FF7A1F", flamme(100, 124, 36, 104), flamme(64, 138, 22, 62, -24), flamme(136, 138, 22, 62, 24))
    p.plein("#FFB31F", flamme(100, 132, 26, 76), flamme(71, 144, 14, 42, -20), flamme(129, 144, 14, 42, 20))
    p.plein("#FFE66B", flamme(100, 142, 15, 46))
    # Deux bûches croisées : celle de derrière plus sombre ; le bout coupé (cernes) se voit.
    p.plein(BOIS_FONCE, tube([(30, 140), (170, 168)], 22))
    p.plein(BOIS_CLAIR, ellipse(31, 140, 8, 11, rot=11))
    p.trait(BOIS, 1.8, ellipse(31, 140, 4, 5.5, rot=11))
    p.plein(BOIS, tube([(30, 168), (170, 140)], 22))
    p.trait(BOIS_FONCE, 2.2, courbe([(56, 160), (80, 155)]), courbe([(116, 151), (146, 145)]))
    p.plein(BOIS_CLAIR, ellipse(169, 140, 8, 11, rot=-11))
    p.trait(BOIS, 1.8, ellipse(169, 140, 4, 5.5, rot=-11))
    # Étincelles.
    p.plein("#FFB31F", flamme(58, 62, 3.5, 9, -15), flamme(146, 50, 3, 8, 20), flamme(128, 26, 2.6, 7, 10))
    return p


def fee() -> Picto:
    """Une petite fée : robe rose, ailes transparentes, baguette à étoile, visage souriant."""
    p = Picto("mot.fee")
    peau, cheveux = "#F1C39D", "#9A4B2B"
    robe, robe_fonce = "#FF6FAE", "#E4529A"
    aile, aile_bord = "#BFE6FFB3", "#8FCDF2"
    ombre(p, 100, 179, 32, 5)
    # Les ailes, derrière le dos.
    ailes = [ellipse(71, 92, 28, 16, rot=35), ellipse(129, 92, 28, 16, rot=-35),
             ellipse(78, 124, 19, 11, rot=-23), ellipse(122, 124, 19, 11, rot=23)]
    p.plein(aile, *ailes)
    p.trait(aile_bord, 2.4, *ailes)
    # Jambes et chaussons.
    p.plein(peau, tube([(93, 146), (91, 169)], 9), tube([(107, 146), (109, 169)], 9))
    p.plein("#B266D9", ellipse(88, 172, 8.5, 5), ellipse(112, 172, 8.5, 5))
    # Bras (côté gauche de l'image) qui pend.
    p.plein(peau, tube([(88, 98), (76, 114), (71, 127)], 8.5), cercle(71, 128, 5.5))
    # La robe : bustier, jupe évasée à festons, ceinture, manches bouffantes.
    jupe = poly([(88, 110), (112, 110), (136, 150), (64, 150)], r=[6, 6, 4, 4])
    p.plein(robe, rect(86, 90, 28, 30, r=10), jupe, *[cercle(x, 150, 7.5) for x in range(68, 134, 13)])
    p.plein(robe_fonce, rect(86, 106, 28, 6, r=3), cercle(87, 97, 7.5), cercle(113, 97, 7.5))
    # Le bras levé, la baguette et son étoile.
    p.plein(peau, tube([(113, 97), (128, 91), (136, 74)], 8.5))
    p.plein("#F5B82E", tube([(137, 78), (151, 44)], 4.2))
    p.plein(JAUNE, etoile(153, 38, 16, 7.5, coins=2.5, rot=-80))
    p.plein(peau, cercle(136, 73, 5.8))
    p.plein("#FFC83D", etoile(178, 56, 6, 2.2, n=4, coins=0.8), etoile(132, 22, 5, 1.9, n=4, coins=0.8),
            etoile(172, 20, 4, 1.5, n=4, coins=0.6))
    # La tête : cheveux (carré + chignon), visage, frange.
    p.plein(cheveux, cercle(100, 62, 25), ellipse(80, 78, 8, 13), ellipse(120, 78, 8, 13), cercle(100, 34, 10))
    p.plein(peau, rect(96, 82, 8, 12, r=3), cercle(100, 68, 21))
    haut = arc(100, 68, 22.6, 190, 350)[0]
    p.plein(cheveux, chemin(haut.start, *haut.segs, ("C", (117, 57), (107, 55), (100, 61)),
                            ("C", (93, 55), (83, 57), haut.start)))
    oeil(p, 92, 71, 4.2)
    oeil(p, 108, 71, 4.2)
    joue(p, 86, 79, 3.8)
    joue(p, 114, 79, 3.8)
    p.trait(ENCRE, 2.2, courbe([(95, 80), (100, 83.5), (105, 80)]))
    return p


def fusee() -> Picto:
    """Une fusée blanche et rouge : pointe, hublot, ailerons, flammes dessous."""
    p = Picto("mot.fusee")

    def bas(f, cy):
        """Une goutte retournée (la pointe en bas) autour de la hauteur cy."""
        return echelle(f, 1, -1, 100, cy)
    # Les flammes, sous la tuyère.
    p.plein("#FF7A1F", bas(goutte(100, 153, 15, 29), 153), tourne(bas(goutte(88, 150, 8, 18), 150), 22, 88, 142),
            tourne(bas(goutte(112, 150, 8, 18), 150), -22, 112, 142))
    p.plein(JAUNE, bas(goutte(100, 150, 9, 20), 150))
    # Les ailerons, derrière le corps.
    aileron = poly([(76, 102), (52, 124), (50, 152), (76, 136)], r=[3, 9, 5, 3])
    p.plein(ROUGE, aileron, echelle(aileron, -1, 1, 100, 100))
    # Le corps : ogive posée sur un cylindre à fond arrondi.
    t, droite_haut = (100, 18), ((118, 30), (128, 56), (128, 86))
    gauche_haut = ((72, 56), (82, 30), t)
    corps = chemin(t, ("C", *droite_haut), ("L", (128, 126)), ("C", (128, 135), (122, 140), (114, 140)),
                   ("L", (86, 140)), ("C", (78, 140), (72, 135), (72, 126)), ("L", (72, 86)), ("C", *gauche_haut))
    p.plein("#F6F8FC", corps)
    ombre_d = chemin(t, ("C", *droite_haut), ("L", (128, 126)), ("C", (128, 135), (122, 140), (114, 140)),
                     ("L", (110, 140)), ("C", (115, 136), (116, 130), (116, 124)), ("L", (116, 86)),
                     ("C", (116, 58), (110, 34), t))
    p.plein(BLANC_OMBRE, ombre_d)
    p.trait(BORD_PALE, 2.2, corps)
    # La pointe rouge : le haut de l'ogive, coupé à y = 52.
    tr = _t_a_hauteur(t, *droite_haut, 52)
    av_d, _ = _coupe(t, *droite_haut, tr)
    tl = _t_a_hauteur((72, 86), *gauche_haut, 52)
    _, ar_g = _coupe((72, 86), *gauche_haut, tl)
    xr, xl = av_d[3][0], ar_g[0][0]
    p.plein(ROUGE, chemin(t, ("C", av_d[1], av_d[2], av_d[3]), ("C", (xr - 6, 58), (xl + 6, 58), ar_g[0]),
                          ("C", ar_g[1], ar_g[2], t)))
    # Bande rouge et hublot.
    p.plein(ROUGE, rect(72, 114, 56, 10))
    p.plein(BORD_PALE, cercle(100, 84, 17))
    p.plein("#5DB4EE", cercle(100, 84, 12.5))
    p.plein("#FFFFFFCC", ellipse(95, 79, 5, 3.5, rot=-35))
    # La tuyère.
    p.plein("#7C879B", poly([(86, 139), (114, 139), (119, 150), (81, 150)], r=2.5))
    return p


def fraise() -> Picto:
    """Une grosse fraise rouge : graines jaunes, collerette de feuilles vertes, petite queue."""
    p = Picto("mot.fraise")
    ombre(p, 100, 180, 44, 6)
    corps = chemin((100, 64), ("C", (126, 52), (162, 58), (161, 94)), ("C", (160, 130), (126, 170), (100, 176)),
                   ("C", (74, 170), (40, 130), (39, 94)), ("C", (38, 58), (74, 52), (100, 64)))
    p.plein(ROUGE, corps)
    p.plein("#FFFFFF66", ellipse(62, 100, 6, 14, rot=22))
    graines = [(62, 88), (138, 88), (50, 110), (76, 106), (100, 102), (124, 106), (150, 110), (64, 128), (88, 124),
               (112, 124), (136, 128), (78, 146), (100, 144), (122, 146), (90, 162), (110, 162)]
    p.plein("#FFE27A", *[ellipse(x, y, 2.6, 4, rot=(x - 100) * 0.4) for x, y in graines])
    # La collerette : six feuilles pointues autour de la queue.
    c = (100, 62)
    p.plein(VERT_FONCE, *[feuille(c, _pt(c, a, 30), 15) for a in (200, 250, 290, 340)])
    p.plein(VERT, *[feuille(c, _pt(c, a, 32), 16) for a in (160, 130, 20, 50, 95)])
    p.plein(VERT_FONCE, tube([(100, 62), (103, 44), (110, 30)], [7, 6, 5]))
    return p


def fourchette() -> Picto:
    """Une fourchette d'enfant à quatre dents, manche bleu, posée en biais."""
    p = Picto("mot.fourchette")
    ombre(p, 100, 179, 50, 6)
    a = -28   # dessinée droite, puis penchée autour du centre

    def r(f):
        return tourne(f, a, 100, 100)
    dents = [rect(x, 18, 7.5, 54, r=3.75) for x in (79, 90.5, 102, 113.5)]
    tete = chemin((79, 58), ("L", (121, 58)), ("L", (121, 70)), ("C", (121, 86), (107, 88), (105, 102)),
                  ("L", (95, 102)), ("C", (93, 88), (79, 86), (79, 70)))
    p.plein(METAL, *[r(f) for f in dents], r(tete), r(rect(95, 98, 10, 20, r=3)))
    p.plein(METAL_CLAIR, r(rect(82, 30, 2.5, 38, r=1.2)), r(rect(84, 72, 4, 10, r=2)))
    p.plein(METAL_FONCE, r(rect(116, 30, 3, 40, r=1.5)))
    manche = chemin((93, 112), ("L", (107, 112)), ("C", (113, 138), (116, 162), (113, 175)),
                    ("C", (111, 184), (89, 184), (87, 175)), ("C", (84, 162), (87, 138), (93, 112)))
    p.plein(BLEU, r(manche))
    p.plein("#7CC6FA", r(rect(92, 124, 4, 40, r=2)))
    return p


def phoque() -> Picto:
    """Un phoque gris couché sur le ventre, tête levée (regarde à gauche), nageoires, moustaches."""
    p = Picto("mot.phoque")
    gris, gris_fonce, ventre, museau = "#9EA9BA", "#7C889D", "#D4DBE6", "#E6EBF2"
    ombre(p, 104, 179, 76, 6)
    # La queue en éventail, derrière.
    p.plein(gris_fonce, ellipse(170, 142, 12.5, 6.5, rot=-40), ellipse(171, 158, 12.5, 6.5, rot=25))
    # Le corps (une goutte couchée), le ventre plus clair.
    corps = lisse([(60, 100), (94, 112), (130, 128), (158, 140), (172, 150), (158, 162), (124, 172), (88, 174),
                   (56, 166), (40, 138)])
    p.plein(gris, corps)
    p.plein(ventre, lisse([(48, 146), (80, 158), (118, 162), (150, 154), (124, 169), (88, 171), (58, 164)]))
    p.plein(gris_fonce, cercle(110, 128, 3.2), cercle(128, 138, 2.6), cercle(140, 146, 3), cercle(118, 146, 2.4))
    # La nageoire avant.
    p.plein(gris_fonce, ellipse(86, 166, 17, 8, rot=20))
    # La tête : ronde, museau clair, truffe, moustaches, sourire.
    p.plein(gris, cercle(58, 82, 27))
    p.plein(museau, ellipse(39, 95, 16, 12))
    p.plein(ENCRE, ellipse(30, 89, 5.5, 4.2))
    p.plein(ENCRE, cercle(40, 94, 1.5), cercle(46, 97, 1.5), cercle(40, 100, 1.5))
    p.trait(ENCRE, 2.2, courbe([(27, 99), (32, 104), (38, 104)]))
    oeil(p, 58, 76, 6.5)
    joue(p, 62, 93, 5)
    return p


def _tache(cx: float, cy: float, r: float, k: int = 0) -> list[Contour]:
    """Une tache irrégulière (girafe) : hexagone aux coins très arrondis, rayons fixes (rien d'aléatoire)."""
    rayons = (1.0, 0.82, 1.08, 0.86, 1.0, 0.78)
    pts = [_pt((cx, cy), k * 23 + i * 60, r * rayons[(i + k) % 6]) for i in range(6)]
    return poly(pts, r=r * 0.45)


def girafe() -> Picto:
    """Une girafe entière de profil (regarde à gauche) : long cou, taches, crinière, petites cornes."""
    p = Picto("mot.girafe")
    robe, robe_fonce, tache, criniere = "#F7C652", "#E4AC3C", "#D8883A", "#B8652C"
    sabot = "#7A5033"
    ombre(p, 116, 179, 60, 6)
    # Pattes de l'autre côté (plus sombres), queue.
    p.plein(robe_fonce, tube([(104, 114), (106, 172)], 11), tube([(150, 112), (148, 172)], 11))
    p.plein(sabot, rect(100.5, 167, 11, 9, r=3), rect(142.5, 167, 11, 9, r=3))
    p.trait(criniere, 3.4, courbe([(162, 102), (170, 114), (173, 130)]))
    p.plein(criniere, ellipse(173.5, 135, 4.5, 7))
    # Le corps, les pattes de ce côté.
    p.plein(robe, lisse([(86, 100), (106, 88), (140, 88), (162, 97), (165, 112), (148, 123), (112, 125),
                         (88, 120)]))
    p.plein(robe, tube([(92, 110), (90, 172)], 12), tube([(140, 110), (138, 172)], 12))
    p.plein(sabot, rect(84, 167, 12, 9, r=3), rect(132, 167, 12, 9, r=3))
    # Le cou et sa crinière (la crinière dépasse derrière).
    p.plein(criniere, tube([(110, 100), (92.5, 74), (77, 48)], 8))
    p.plein(robe, tube([(98, 106), (84, 78), (70, 52)], [30, 22, 17]))
    # Les taches.
    p.plein(tache, _tache(104, 101, 7, 0), _tache(125, 97, 7.5, 1), _tache(147, 102, 6.5, 2),
            _tache(115, 114, 6, 3), _tache(137, 115, 6, 4), _tache(157, 110, 4.5, 5), _tache(91, 92, 5.5, 1),
            _tache(83, 75, 5, 2), _tache(75, 60, 3.8, 3), _tache(92, 164, 3.2, 4), _tache(140, 160, 3.2, 5))
    # La tête : oreille, cornes, museau clair, œil, sourire.
    p.plein(robe, ellipse(80, 37, 9, 4.5, rot=-20))
    p.plein(robe_fonce, tube([(64, 33), (62, 23)], 4.5), tube([(71, 34), (72, 24)], 4.5))
    p.plein(criniere, cercle(62, 22, 3.8), cercle(72, 23, 3.8))
    p.plein(robe, ellipse(60, 44, 20, 13.5, rot=-25))
    p.plein("#FBE2A2", ellipse(45, 51, 11, 9.5, rot=-25))
    p.plein(ENCRE, ellipse(39, 47.5, 1.9, 1.5))
    p.trait(ENCRE, 2.0, courbe([(39, 55), (44, 57.5), (49, 55.5)]))
    oeil(p, 61, 39, 5.2)
    joue(p, 64, 50, 4)
    return p


# ---------------------------------------------------------------------------
# Le son [v] : vélo, verre, valise, vague, cheval
# ---------------------------------------------------------------------------

def velo() -> Picto:
    """Un vélo d'enfant de profil (roue avant à gauche) : cadre corail, garde-boue, selle, guidon."""
    p = Picto("mot.velo")
    cadre, cadre_clair, pneu, jante, gris = "#FF5E5B", "#FF8F8C", "#3A3F5C", "#C8CDE0", "#8A94A8"
    av, ar, pedalier = (50, 144), (150, 144), (102, 148)
    ombre(p, 100, 180, 82, 6)
    for c in (av, ar):
        p.trait(pneu, 8, cercle(c[0], c[1], 30))
        p.trait(jante, 2.4, cercle(c[0], c[1], 25))
        p.trait(jante, 1.6, *[courbe([c, _pt(c, a, 25)]) for a in range(0, 360, 45)])
        p.plein(gris, cercle(c[0], c[1], 4.5))
    # Garde-boue.
    p.trait(cadre, 5, arc(av[0], av[1], 37, 212, 300), arc(ar[0], ar[1], 37, 235, 325))
    # Le cadre : fourche, tubes, bases arrière.
    p.trait(cadre, 7, courbe([(60, 100), (56, 118), av]), courbe([(62, 104), pedalier]),
            courbe([(118, 96), (64, 100)]), courbe([pedalier, (122, 92)]), courbe([pedalier, ar]),
            courbe([(120, 100), ar]))
    p.plein(cadre_clair, tube([(104, 150), (150, 146)], 10))
    # Pédalier, manivelle, pédale.
    p.plein(gris, cercle(pedalier[0], pedalier[1], 9))
    p.trait(gris, 4.5, courbe([pedalier, (110, 163)]))
    p.plein(pneu, rect(102, 161, 17, 6, r=3))
    # Selle, guidon et poignée.
    p.trait(gris, 4.5, courbe([(122, 92), (124, 82)]))
    p.plein(pneu, chemin((110, 78), ("C", (116, 72), (136, 72), (142, 78)), ("C", (144, 84), (132, 86), (124, 85)),
                         ("C", (116, 84), (108, 83), (110, 78))))
    p.trait(gris, 4.5, courbe([(60, 100), (62, 80)]), courbe([(62, 80), (72, 74), (82, 76)]))
    p.plein(pneu, tube([(80, 75.5), (92, 79)], 8))
    return p


def verre() -> Picto:
    """Un verre d'eau vu de trois quarts : verre bleuté transparent, eau, reflets, petites bulles."""
    p = Picto("mot.verre")
    bord, verre_c, eau, eau_claire = "#9FD0F0", "#E8F5FD", "#7EC8F2", "#B6E1F8"
    ombre(p, 100, 178, 42, 5)
    # Le verre (pied épais), l'intérieur du bord.
    silhouette = chemin((62, 44), ("L", (70, 168)), ("C", (72, 178), (128, 178), (130, 168)), ("L", (138, 44)),
                        ("C", (138, 32), (62, 32), (62, 44)))
    p.plein(verre_c, silhouette)
    p.plein("#D4ECFA", ellipse(100, 160, 29, 7))
    # L'eau : corps, puis la surface.
    x0, x1 = 62 + (80 - 44) * 8 / 124, 138 - (80 - 44) * 8 / 124
    p.plein(eau, chemin((x0, 80), ("L", (69.3, 156)), ("C", (71, 165), (129, 165), (130.7, 156)), ("L", (x1, 80)),
                        ("C", (x1, 88), (x0, 88), (x0, 80))))
    p.plein(eau_claire, ellipse(100, 80, x1 - 100, 7.5))
    p.plein("#D8F0FF", cercle(88, 128, 3), cercle(112, 112, 2.4), cercle(104, 140, 2.2), cercle(118, 132, 3.2))
    # Reflets, bord du verre.
    p.plein("#FFFFFFB0", tube([(72, 58), (78, 150)], 6), tube([(126, 60), (123, 96)], 3.5))
    p.trait(bord, 2.8, silhouette, ellipse(100, 44, 38, 8))
    return p


def valise() -> Picto:
    """Une valise à roulettes : poignée télescopique, nervures, étiquette, deux roulettes."""
    p = Picto("mot.valise")
    coque, coque_fonce, coque_claire, gris, noir = "#1FB0A5", "#17938A", "#5CCFC5", "#A3AFC1", "#3A3F5C"
    ombre(p, 100, 180, 58, 6)
    # La poignée télescopique.
    p.plein(gris, rect(76, 24, 7, 48, r=2), rect(117, 24, 7, 48, r=2))
    p.plein(noir, rect(70, 18, 60, 13, r=6.5))
    # Roulettes.
    p.plein(noir, rect(60, 160, 16, 12, r=4), rect(124, 160, 16, 12, r=4))
    p.plein(noir, cercle(68, 173, 7), cercle(132, 173, 7))
    p.plein(gris, cercle(68, 173, 2.6), cercle(132, 173, 2.6))
    # La coque, ses nervures, les coins.
    p.plein(coque, rect(50, 62, 100, 106, r=16))
    p.plein(coque_fonce, rect(50, 154, 100, 14, r=8), rect(71, 72, 7, 78, r=3.5), rect(96.5, 72, 7, 78, r=3.5),
            rect(122, 72, 7, 78, r=3.5))
    p.plein(coque_claire, rect(56, 66, 88, 5, r=2.5))
    # Une étiquette jaune.
    p.plein("#FFD23F", rect(126, 98, 20, 26, r=4))
    p.plein("#F5A623", cercle(136, 104, 2.4))
    return p


def vague() -> Picto:
    """Une grosse vague bleue qui déferle vers la gauche : la lèvre retombe, écume blanche, mer dessous."""
    p = Picto("mot.vague")
    bleu, bleu_fonce, bleu_clair, ecume_ombre = "#3C9BE8", "#2A7FD0", "#8CCBF4", "#BFE0F8"
    # La vague : le dos monte de la mer jusqu'à la crête, la lèvre s'enroule vers la gauche et retombe ;
    # dessous, le creux (l'air) et la face de la vague qui redescend vers la mer.
    dos = ((180, 156), (184, 110), (170, 48), (124, 30))
    crete = ((124, 30), (88, 16), (42, 30), (30, 64))
    levre = ((30, 64), (24, 84), (32, 104), (50, 106))
    p.plein(bleu, chemin(dos[0], ("C", *dos[1:]), ("C", *crete[1:]), ("C", *levre[1:]),
                         ("C", (62, 106), (66, 94), (64, 86)), ("C", (62, 72), (82, 64), (98, 72)),
                         ("C", (114, 80), (118, 110), (108, 130)), ("C", (98, 148), (70, 152), (40, 156))))
    p.trait(bleu_clair, 5, courbe([(166, 146), (168, 104), (152, 62), (124, 44)]),
            courbe([(74, 72), (94, 66), (110, 78), (115, 104), (108, 128)]))
    # L'écume : des ronds blancs posés sur la crête et la lèvre (ombre bleu pâle dessous), des embruns.
    ronds = [(_bez(*dos, t), 7 + 3 * t) for t in (0.62, 0.82)]
    ronds += [(_bez(*crete, t), 10 - 3 * t) for t in (0, 0.18, 0.36, 0.54, 0.72, 0.88, 1)]
    ronds += [(_bez(*levre, t), 6 - 1.5 * t) for t in (0.35, 0.7, 1)]
    p.plein(ecume_ombre, *[cercle(x + 1, y + 3, r) for (x, y), r in ronds])
    p.plein(BLANC, *[cercle(x, y, r) for (x, y), r in ronds])
    p.plein(ecume_ombre, cercle(21, 92, 3.5), cercle(27, 118, 3), cercle(40, 126, 2.6), cercle(174, 58, 3.5))
    # La mer, devant, bord en vaguelettes ; trois reflets.
    p.plein(bleu_fonce, chemin((16, 152), ("C", (40, 144), (60, 158), (84, 152)),
                               ("C", (108, 146), (130, 158), (154, 152)), ("C", (168, 148), (178, 150), (184, 152)),
                               ("L", (184, 170)), ("C", (184, 176), (180, 178), (174, 178)), ("L", (26, 178)),
                               ("C", (20, 178), (16, 176), (16, 170))))
    p.plein("#FFFFFF90", *[ellipse(x, 164, w, 2.6) for x, w in ((50, 11), (108, 15), (160, 9))])
    return p


def cheval() -> Picto:
    """Un cheval marron de profil (regarde à gauche) : crinière et queue foncées, museau clair."""
    p = Picto("mot.cheval")
    robe, robe_fonce, crins, museau, sabot = "#C8834A", "#A9683A", "#6B3F22", "#E6B07E", "#4A3A30"
    ombre(p, 106, 179, 66, 6)
    # Pattes de l'autre côté, queue.
    p.plein(robe_fonce, tube([(70, 116), (66, 170)], 12), tube([(140, 114), (144, 170)], 12))
    p.plein(sabot, rect(59, 166, 14, 9, r=3), rect(137, 166, 14, 9, r=3))
    p.plein(crins, tube([(150, 94), (166, 108), (172, 134), (166, 156)], [12, 15, 12, 5]))
    # Corps et pattes de ce côté.
    p.plein(robe, ellipse(110, 106, 48, 24))
    p.plein(robe, tube([(82, 114), (80, 170)], 13), tube([(146, 112), (152, 170)], 13))
    p.plein(sabot, rect(72.5, 166, 15, 9, r=3), rect(144.5, 166, 15, 9, r=3))
    # L'encolure et sa crinière.
    p.plein(crins, tube([(96, 90), (80, 60), (66, 38)], [13, 12, 10]))
    p.plein(robe, tube([(84, 106), (70, 74), (60, 54)], [34, 27, 22]))
    p.plein(crins, *[cercle(x, y, 6.5) for x, y in ((92, 86), (86, 72), (79, 58), (72, 46))])
    # La tête : oreilles, tête allongée vers le bas, museau, toupet.
    p.plein(robe_fonce, feuille((66, 44), (72, 22), 10))
    p.plein(robe, feuille((58, 44), (60, 20), 11))
    p.plein(robe, ellipse(46, 60, 26, 14.5, rot=-50))
    p.plein(museau, ellipse(33, 78, 12.5, 10.5, rot=-30))
    p.plein(crins, ellipse(55, 40, 9, 5, rot=-30))
    p.plein(ENCRE, ellipse(28, 76, 2.2, 1.7, rot=-30))
    p.trait(ENCRE, 2.0, courbe([(28, 85), (33, 88), (39, 86)]))
    oeil(p, 51, 52, 5.5)
    joue(p, 50, 66, 4.5)
    return p


# ---------------------------------------------------------------------------
# Le son [ʒ] : jupe, genou, orange, neige, cage
# ---------------------------------------------------------------------------

def jupe() -> Picto:
    """Une jupe violette à trois volants et pois blancs, ceinture et petit nœud rose."""
    p = Picto("mot.jupe")
    tissu, pli, ceinture = "#A56CF0", "#8752D6", "#7A45C8"
    ombre(p, 100, 179, 64, 6)

    def volant(y0, y1, l0, l1):
        """Un volant : trapèze de demi-largeurs l0 (haut) et l1 (bas), bas en festons."""
        n = max(5, round(2 * l1 / 16))
        pas = 2 * l1 / n
        forme = poly([(100 - l0, y0), (100 + l0, y0), (100 + l1, y1), (100 - l1, y1)], r=4)
        festons = [cercle(100 - l1 + pas * (i + 0.5), y1, pas * 0.56) for i in range(n)]
        return [forme] + festons

    for y0, y1, l0, l1 in ((120, 162, 52, 66), (84, 126, 42, 54), (50, 90, 34, 44)):
        p.plein(pli, *volant(y0 + 5, y1 + 5, l0, l1))
        p.plein(tissu, *volant(y0, y1, l0, l1))
    pois = ((84, 66), (110, 72), (96, 80), (122, 62), (78, 104), (100, 112), (124, 104), (64, 114), (138, 116),
            (70, 144), (92, 150), (114, 142), (136, 152), (54, 152), (148, 138))
    p.plein(BLANC, *[cercle(x, y, 3.2) for x, y in pois])
    p.plein(ceinture, rect(64, 40, 72, 14, r=6))
    p.plein("#FF6FAE", poly([(118, 47), (134, 38), (134, 56)], r=3), poly([(118, 47), (102, 38), (102, 56)], r=3))
    p.plein("#E4529A", cercle(118, 47, 5))
    return p


def genou() -> Picto:
    """Une jambe d'enfant pliée, vue de côté (même peau que Lou) : le genou en haut, un pansement dessus.

    L'enfant est assis (à droite, en short), le pied posé au sol à gauche, le genou levé.
    """
    p = Picto("mot.genou")
    peau, peau_ombre, short, short_fonce = PEAU_LOU, "#A56A43", "#3E7BD6", "#2F66BA"
    ombre(p, 102, 179, 80, 6)
    k, cheville, hanche = (100, 62), (64, 150), (150, 142)
    # Le mollet (galbe à l'arrière), la cuisse, le genou arrondi.
    p.plein(peau_ombre, ellipse(94, 106, 12, 24, rot=21))
    p.plein(peau, tube([k, (84, 102), cheville], [34, 30, 23]), tube([k, hanche], [36, 42]))
    p.plein(peau, cercle(k[0], k[1], 18))
    # Le short (l'enfant assis), son ourlet en travers de la cuisse.
    p.plein(short, poly([(104, 121), (149, 91), (178, 114), (183, 158), (171, 174), (126, 174)],
                        r=[3, 3, 24, 14, 10, 8]))
    p.plein(short_fonce, tube([(106, 120), (148, 93)], 8))
    # Chaussette et basket (le pied posé au sol, pointe vers la gauche).
    p.plein("#F4F6FA", tube([(66, 140), (62, 154)], 25))
    p.trait(BORD_PALE, 2, courbe([(51, 146), (62, 150), (75, 149)]))
    p.plein(ROUGE, chemin((26, 164), ("C", (26, 152), (40, 148), (50, 148)), ("L", (76, 148)),
                          ("C", (82, 148), (84, 154), (84, 162)), ("L", (84, 168)), ("L", (26, 168))))
    p.plein("#EEF1F6", rect(22, 166, 66, 9, r=4.5))
    p.trait(BLANC, 2.2, courbe([(52, 154), (58, 151)]), courbe([(58, 158), (64, 154)]))
    # Le pansement, en travers du genou : bande beige, compresse au milieu, petits trous.

    def pose(f):
        return tourne(f, -24, k[0] + 1, k[1] + 1)
    p.plein("#F6DDB8", pose(rect(k[0] - 16, k[1] - 6, 34, 14, r=7)))
    p.plein("#E4B884", pose(rect(k[0] - 5.5, k[1] - 4.5, 13, 11, r=3)))
    p.plein("#D9A870", *[pose(cercle(x, y, 1)) for x in (k[0] - 11, k[0] - 7, k[0] + 9, k[0] + 13)
                         for y in (k[1] - 1.5, k[1] + 3.5)])
    return p


def orange() -> Picto:
    """Une orange bien ronde, un reflet, et sa feuille."""
    p = Picto("mot.orange")
    ombre(p, 100, 179, 50, 6)
    p.plein("#F2850A", cercle(100, 112, 62))
    p.plein("#FF9F1C", cercle(97, 109, 57.5))
    p.plein("#FFC56B", ellipse(72, 86, 13, 8, rot=-40))
    pores = ((120, 88), (132, 104), (110, 126), (84, 138), (128, 142), (66, 116), (100, 100), (146, 124), (96, 156))
    p.plein("#F59418", *[cercle(x, y, 1.7) for x, y in pores])
    p.plein(VERT_FONCE, ellipse(102, 52, 6.5, 4))
    p.plein(VERT, feuille((104, 51), (148, 30), 22, -4))
    p.trait(VERT_FONCE, 2, courbe([(110, 48), (126, 40), (142, 33)]))
    return p


def _flocon(p: Picto, x: float, y: float, r: float, couleur: str) -> None:
    """Un flocon à six branches (et leurs petits V)."""
    formes = []
    for k in range(6):
        a = 90 + 60 * k
        bout = _pt((x, y), a, r)
        formes.append(courbe([(x, y), bout]))
        m = _pt((x, y), a, r * 0.58)
        formes.append(courbe([_pt(m, a + 50, r * 0.32), m, _pt(m, a - 50, r * 0.32)]))
    p.trait(couleur, max(2.2, r * 0.2), *formes)


def neige() -> Picto:
    """De la neige : des flocons qui tombent sur un sol enneigé, un petit tas de neige."""
    p = Picto("mot.neige")
    flocon, neige_ombre, neige_bord = "#6FAEE8", "#D2E4F7", "#A9C9EC"
    # Le sol enneigé.
    dessus = (("C", (48, 140), (82, 150), (110, 150)), ("C", (140, 150), (164, 140), (184, 148)))
    p.plein(neige_ombre, chemin((16, 152), *dessus, ("L", (184, 170)), ("C", (184, 176), (180, 178), (174, 178)),
                                ("L", (26, 178)), ("C", (20, 178), (16, 176), (16, 170))))
    p.plein("#EEF5FD", chemin((16, 152), *dessus, ("L", (184, 160)), ("C", (150, 156), (60, 164), (16, 162))))
    p.trait(neige_bord, 2.4, courbe([(17, 152), (48, 142), (82, 150), (110, 150), (140, 150), (164, 142),
                                     (183, 148)]))
    # Le petit tas : une bosse ronde, ombrée à droite.
    tas = lisse([(56, 156), (60, 136), (74, 122), (90, 120), (100, 108), (118, 106), (134, 118), (146, 132),
                 (150, 156)])
    p.plein("#F1F7FE", tas)
    p.plein(BLANC, ellipse(96, 118, 16, 6, rot=-12), ellipse(70, 132, 8, 4, rot=-40))
    p.plein(neige_ombre, chemin((134, 118), ("C", (142, 126), (150, 140), (150, 156)), ("L", (124, 157)),
                                ("C", (138, 148), (140, 132), (134, 118))), ellipse(100, 154, 46, 5))
    p.trait(neige_bord, 2.4, courbe([(57, 150), (60, 136), (74, 122), (90, 120), (100, 108), (118, 106),
                                     (134, 118), (146, 132), (149, 150)]))
    # Les flocons qui tombent.
    for x, y, r in ((44, 50, 15), (104, 32, 11), (158, 62, 15), (74, 94, 9), (146, 108, 8), (30, 112, 7)):
        _flocon(p, x, y, r, flocon)
    points = ((80, 58), (128, 40), (122, 84), (24, 80), (178, 98), (50, 130), (170, 128))
    p.plein(flocon, *[cercle(x, y, 2.6) for x, y in points])
    return p


def cage() -> Picto:
    """Une cage à oiseau ronde et vide : barreaux dorés en dôme, anneau en haut, socle rouge, perchoir."""
    p = Picto("mot.cage")
    dore, dore_fonce, socle, socle_fonce = "#EBA82C", "#C98B22", "#E8414B", "#C53340"
    ombre(p, 100, 180, 64, 6)
    cx, bas, epaule, sommet, rx = 100, 156, 98, 42, 54
    # L'anneau du haut et son bouton.
    p.trait(dore_fonce, 4.5, cercle(cx, 28, 8.5))
    # Le perchoir (derrière les barreaux de devant).
    p.plein("#B97D45", rect(66, 124, 68, 5.5, r=2.75))
    p.trait(dore_fonce, 2.4, courbe([(70, 126), (70, 104)]), courbe([(130, 126), (130, 104)]))
    # Les barreaux : droits jusqu'à l'épaule, puis en méridiens jusqu'au sommet.
    barreaux = []
    for s in (-1.0, -0.8, -0.45, 0.0, 0.45, 0.8, 1.0):
        x = cx + s * rx
        if s == 0:
            barreaux.append(courbe([(x, bas), (x, sommet)]))
            continue
        a = arc(cx, epaule, abs(s) * rx, 180 if s < 0 else 0, 270 if s < 0 else -90, epaule - sommet)[0]
        barreaux.append([Contour((x, bas), [("L", (x, epaule))] + a.segs, closed=False)])
    p.trait(dore, 3.6, *barreaux)
    p.trait(dore, 3.6, ellipse(cx, epaule, rx, 8), ellipse(cx, 128, rx, 8))
    p.plein(dore, cercle(cx, sommet - 1, 6.5))
    # Le socle.
    p.plein(socle_fonce, rect(60, 166, 80, 8, r=4))
    p.plein(socle, rect(38, 150, 124, 18, r=7))
    p.plein("#FF7A84", rect(44, 153, 112, 4, r=2))
    return p


# ---------------------------------------------------------------------------
# Le son [g] : gâteau, gomme, guitare, gant, grenouille, bague, dragon
# ---------------------------------------------------------------------------

def gateau() -> Picto:
    """Un gâteau d'anniversaire rond : génoise rose, crème qui coule, trois bougies allumées."""
    p = Picto("mot.gateau")
    rose, rose_fonce, creme, creme_ombre = "#F58CB8", "#E0709F", "#FFF7EE", "#F3DFCF"
    ombre(p, 100, 179, 76, 6)
    # L'assiette.
    p.plein("#C9DEF3", ellipse(100, 166, 82, 13))
    p.plein("#E4F0FB", ellipse(100, 164, 76, 10))
    # La génoise (cylindre de trois quarts), ombrée à droite, et sa couche de crème au milieu.
    p.plein(rose, rect(34, 104, 132, 54), ellipse(100, 158, 66, 12))
    p.plein(rose_fonce, chemin((140, 104), ("L", (166, 104)), ("L", (166, 158)),
                               ("C", (166, 162), (156, 166), (140, 168))))
    couche = Contour((34, 128), arc(100, 128, 66, 180, 0, 12)[0].segs + [("L", (166, 136))]
                     + arc(100, 136, 66, 0, 180, 12)[0].segs)
    p.plein(creme, _plein(couche))
    # La crème du dessus, qui coule sur le bord.

    def bord(x):
        """Le bas du bord du dessus (ellipse 66 × 16) à l'abscisse x."""
        return 104 + 16 * math.sqrt(max(0.0, 1 - ((x - 100) / 66) ** 2))
    gouttes = ((44, 8), (60, 16), (80, 10), (100, 18), (120, 9), (140, 15), (157, 7))
    coulures = [tube([(x, bord(x) - 2), (x, bord(x) + lg)], 11) for x, lg in gouttes]
    rebord = Contour((34, 104), arc(100, 104, 66, 180, 0, 16)[0].segs + [("L", (166, 110))]
                     + arc(100, 110, 66, 0, 180, 16)[0].segs)
    p.plein(creme_ombre, *[deplace(c, 0, 2) for c in coulures])
    p.plein(creme, ellipse(100, 104, 66, 16), _plein(rebord), *coulures)
    # Vermicelles de couleur sur le dessus.
    for (x, y, a), c in zip(((58, 104, 30), (84, 96, -20), (118, 96, 40), (142, 106, -30), (96, 112, 10),
                             (72, 112, 70), (128, 112, -60)),
                            ("#FFD23F", "#3FA7F5", "#4CB963", "#FF7A1F", "#3FA7F5", "#FF7A1F", "#FFD23F")):
        p.plein(c, tourne(rect(x - 4.5, y - 1.6, 9, 3.2, r=1.6), a, x, y))
    # Les bougies, leur mèche et leur flamme.
    for x, y, c, raie in ((70, 100, "#5DB4EE", "#BFE3FA"), (100, 108, "#FFD23F", "#FFF0A8"),
                          (130, 100, "#4CB963", "#B6E6BE")):
        p.plein(c, rect(x - 4.5, y - 32, 9, 34, r=3))
        p.plein(raie, *[tourne(rect(x - 4.5, y - 26 + k * 10, 9, 3.2), -25, x, y - 24 + k * 10) for k in range(3)])
        p.trait(ENCRE, 1.8, courbe([(x, y - 32), (x, y - 37)]))
        p.plein("#FF8A1F", flamme(x, y - 42, 5.5, 13))
        p.plein("#FFE36B", flamme(x, y - 41, 3, 7))
    return p


def gomme() -> Picto:
    """Une gomme rose et bleue vue de trois quarts (un peu penchée), quelques miettes."""
    p = Picto("mot.gomme")
    rose, rose_clair = "#FF8DB0", "#FFB6CC"
    bleu, bleu_clair, bleu_fonce = "#4D9DE0", "#86C0F0", "#377FC2"
    ombre(p, 104, 176, 76, 6)

    def r(f):
        return tourne(f, -8, 100, 130)
    x0, xm, x1, y0, y1, dx, dy = 34, 104, 154, 112, 160, 24, -28
    # Face de dessus, face de devant (rose puis bleue), côté droit (bleu foncé).
    p.plein(rose_clair, r(poly([(x0, y0), (xm, y0), (xm + dx, y0 + dy), (x0 + dx, y0 + dy)], r=[5, 0, 0, 5])))
    p.plein(bleu_clair, r(poly([(xm, y0), (x1, y0), (x1 + dx, y0 + dy), (xm + dx, y0 + dy)], r=[0, 0, 5, 0])))
    p.plein(bleu_fonce, r(poly([(x1, y0), (x1 + dx, y0 + dy), (x1 + dx, y1 + dy), (x1, y1)], r=[0, 5, 5, 5])))
    p.plein(rose, r(poly([(x0, y0), (xm, y0), (xm, y1), (x0, y1)], r=[5, 0, 0, 5])))
    p.plein(bleu, r(poly([(xm, y0), (x1, y0), (x1, y1), (xm, y1)], r=[0, 0, 5, 0])))
    p.plein("#FFFFFF55", r(rect(x0 + 6, y0 + 6, xm - x0 - 12, 5, r=2.5)))
    # Des miettes de gomme.
    p.plein(rose, ellipse(30, 170, 4.5, 3, rot=20), ellipse(44, 176, 3.5, 2.4, rot=-15),
            ellipse(23, 160, 3, 2.2, rot=40))
    return p


def guitare() -> Picto:
    """Une guitare en bois, penchée : caisse, rosace, chevalet, manche, tête à clés, cordes."""
    p = Picto("mot.guitare")
    bois, bois_fonce, touche, tete_c, cle = "#EDAE5F", "#C98236", "#5E3A20", "#9A6232", "#F4E3C3"
    ombre(p, 76, 180, 54, 6)

    def r(f):
        return tourne(f, 40, 100, 100)
    caisse = lisse([(100, 90), (122, 94), (128, 110), (121, 127), (134, 139), (136, 160), (123, 176), (100, 181),
                    (77, 176), (64, 160), (66, 139), (79, 127), (72, 110), (78, 94)])
    p.plein(bois_fonce, r(caisse))
    p.plein(bois, r(echelle(caisse, 0.9, 0.93, 100, 138)))
    # Manche, touche, frettes ; tête et clés.
    p.plein(cle, *[r(cercle(x, y, 3.4)) for x in (88.6, 111.4) for y in (22, 31)])
    p.plein(tete_c, r(poly([(91, 16), (109, 16), (107, 38), (93, 38)], r=3)))
    p.plein(tete_c, r(rect(94, 34, 12, 64, r=2)))
    p.plein(touche, r(rect(95.5, 36, 9, 60, r=1.5)))
    p.trait("#D9C2A0", 1.2, *[r(courbe([(95.5, y), (104.5, y)])) for y in (46, 56, 66, 76, 86)])
    # Rosace, chevalet, cordes.
    p.plein(bois_fonce, r(cercle(100, 126, 14.5)))
    p.plein("#4A2E1A", r(cercle(100, 126, 11)))
    p.plein(touche, r(rect(86, 155, 28, 7, r=3.5)))
    p.trait("#FFF3DC", 1.1, *[r(courbe([(x, 158), (x, 36)])) for x in (96.7, 98.9, 101.1, 103.3)])
    return p


def gant() -> Picto:
    """Un gant de laine à cinq doigts (le dos de la main), poignet côtelé, petit cœur brodé."""
    p = Picto("mot.gant")
    laine, laine_fonce, laine_clair, cote = "#F0543C", "#C93B2A", "#FF8A73", "#B02F23"
    ombre(p, 106, 179, 44, 6)
    # Les doigts (le pouce à gauche), puis la paume.
    doigts = [((83, 96), (78, 42), 19), ((101, 92), (101, 30), 19.5), ((119, 94), (122, 38), 19),
              ((134, 102), (141, 58), 16.5)]
    p.plein(laine, *[tube([a, b], w) for a, b, w in doigts], tube([(76, 128), (54, 100), (48, 86)], [22, 19, 18]))
    p.plein(laine, rect(68, 80, 78, 72, r=24))
    p.plein(laine_clair, *[ellipse(b[0], b[1] + 3, 4, 6) for _, b, _ in doigts], ellipse(49, 89, 4, 5.5, rot=-40))
    # Le poignet côtelé.
    p.plein(laine_fonce, rect(70, 138, 74, 38, r=9))
    p.trait(cote, 2.4, *[courbe([(x, 144), (x, 170)]) for x in range(78, 142, 8)])
    # Le petit cœur brodé.
    p.plein("#FFE3D6", coeur(107, 110, 11))
    return p


def grenouille() -> Picto:
    """Une grenouille verte assise, de face : gros yeux de la mascotte, grand sourire, ventre clair."""
    p = Picto("mot.grenouille")
    vert, vert_fonce, ventre = "#5DBB63", "#45A04C", "#D6EFA0"
    ombre(p, 100, 179, 66, 6)
    # Les pattes arrière repliées, les pieds palmés.
    p.plein(vert_fonce, ellipse(58, 148, 26, 19, rot=-20), ellipse(142, 148, 26, 19, rot=20))
    for x, sens in ((44, -1), (156, 1)):
        p.plein(vert_fonce, *[ellipse(x + sens * dx, 172 + dy, 6.5, 4.2, rot=sens * a)
                              for dx, dy, a in ((-10, 1, -30), (0, 3, 0), (10, 1, 30))])
    # Le corps, le ventre, les pattes avant et leurs doigts.
    p.plein(vert, ellipse(100, 132, 42, 40))
    p.plein(ventre, ellipse(100, 142, 27, 27))
    p.plein(vert, tube([(80, 130), (84, 168)], 13), tube([(120, 130), (116, 168)], 13))
    p.plein(vert, *[ellipse(x + dx, 172, 4.5, 3.6) for x in (84, 116) for dx in (-7, 0, 7)])
    # La tête : large, deux bosses pour les yeux.
    p.plein(vert, ellipse(100, 88, 54, 34), cercle(70, 60, 20), cercle(130, 60, 20))
    p.plein(vert_fonce, cercle(96, 76, 1.8), cercle(104, 76, 1.8))
    oeil(p, 70, 59, 10.5)
    oeil(p, 130, 59, 10.5)
    p.plein("#FF9DB0E6", cercle(60, 98, 7), cercle(140, 98, 7))
    p.trait(ENCRE, 3, courbe([(70, 94), (100, 105), (130, 94)]))
    return p


def bague() -> Picto:
    """Une bague en or avec une pierre bleue taillée qui brille (petites étincelles)."""
    p = Picto("mot.bague")
    or_, or_fonce, or_clair = "#F5B82E", "#D9951E", "#FFE08A"
    ombre(p, 100, 179, 50, 6)
    # L'anneau : ellipse percée ; dans le trou, le dedans de l'anneau (plus sombre) en haut.
    p.plein(or_, ellipse(100, 128, 50, 44) + trou(ellipse(100, 131, 37, 31)))
    p.plein(or_fonce, ellipse(100, 131, 37, 31) + trou(ellipse(100, 137, 36, 26)))
    p.trait(or_clair, 4.5, arc(100, 128, 44, 150, 215, 38))
    p.trait(or_fonce, 4, arc(100, 128, 45, 20, 70, 39))
    # La monture et la pierre (table, couronne, pavillon en facettes).
    p.plein(or_fonce, poly([(84, 84), (116, 84), (110, 96), (90, 96)], r=3))
    p.plein("#8FDCFA", poly([(86, 58), (100, 58), (100, 74), (72, 74)], r=[2, 0, 0, 2]))
    p.plein("#3BAAE0", poly([(100, 58), (114, 58), (128, 74), (100, 74)], r=[0, 2, 2, 0]))
    p.plein("#B8ECFD", poly([(90, 58), (110, 58), (104, 70), (96, 70)], r=1))
    p.plein("#48B9EC", poly([(72, 74), (100, 74), (100, 104)], r=[2, 0, 3]))
    p.plein("#2E95D0", poly([(100, 74), (128, 74), (100, 104)], r=[0, 2, 3]))
    p.plein("#B8ECFD", poly([(84, 74), (100, 74), (100, 96)], r=1))
    # Étincelles.
    p.plein(JAUNE, etoile(144, 52, 11, 3.2, n=4, coins=1), etoile(56, 48, 7, 2.2, n=4, coins=0.8),
            etoile(150, 88, 6, 1.9, n=4, coins=0.7))
    return p


def dragon() -> Picto:
    """Un petit dragon vert tout gentil, assis de profil (regarde à gauche) : crête, cornes, petite aile."""
    p = Picto("mot.dragon")
    vert, vert_fonce, ventre, crete = "#5CC26A", "#43A052", "#FBE38A", "#FF9F43"
    ombre(p, 108, 179, 64, 6)
    tete, corps = (78, 70), (110, 130)
    # La crête : des pointes orange posées sur le bord de la tête, du cou et du dos (derrière eux).
    pointes = [(_pt(tete, a, 28), _pt((0, 0), a, 1), h) for a, h in ((-70, 12), (-42, 12), (-14, 11))]
    pointes.append(((106, 92), (0.88, -0.47), 11))
    for t, h in ((-65, 11), (-38, 10), (-12, 9), (14, 8)):
        a = math.radians(t)
        pointes.append(((corps[0] + 38 * math.cos(a), corps[1] + 42 * math.sin(a)),
                        (math.cos(a) / 38, math.sin(a) / 42), h))
    p.plein(crete, *[_pointe(b, n, h, 6.5) for b, n, h in pointes])
    # Les cornes (jaunes), devant la crête.
    cornes = ((-122, -8), (-98, 2))   # (angle sur la tête, décalage de la direction de la corne)
    p.plein("#FFD84D", *[_pointe(_pt(tete, a, 27), _pt((0, 0), a + d, 1), 15, 5.5) for a, d in cornes])
    # La queue qui passe devant, bout en pointe de flèche.
    p.plein(crete, poly([(167, 134), (175, 115), (183, 134)], r=[3, 2.5, 3]))
    p.plein(vert, tube([(132, 158), (160, 166), (176, 152), (175, 134)], [28, 22, 14, 8]))
    # Le corps, le ventre à rayures.
    p.plein(vert, ellipse(corps[0], corps[1], 38, 42))
    p.plein(ventre, ellipse(95, 138, 20, 31, rot=12))
    p.trait("#EFC85A", 2.4, *[courbe([(79 + i * 1.5, 120 + i * 13), (99 + i * 1.5, 124 + i * 13)])
                              for i in range(4)])
    # La petite aile (trois doigts en éventail) sur l'épaule.
    epaule = (122, 108)
    bouts = [(146, 58), (166, 72), (166, 96)]
    p.plein("#FFC978", *[feuille(epaule, b, 22) for b in bouts])
    p.trait("#F59A3A", 2.6, *[courbe([epaule, b]) for b in bouts])
    # La patte arrière, le pied et ses griffes, la patte avant.
    p.plein(vert, ellipse(128, 156, 20, 16))
    p.plein(vert, ellipse(114, 172, 20, 7.5))
    p.plein("#FFF1C9", *[ellipse(x, 172, 2.6, 2) for x in (97, 103, 109)])
    p.plein(vert, tube([(94, 116), (80, 132), (74, 136)], 11))
    # La tête : cou, grosse tête ronde, museau, narines, œil, joue, sourire.
    p.plein(vert, tube([(100, 112), (86, 86)], 30), cercle(tete[0], tete[1], 28))
    p.plein(vert, ellipse(52, 82, 26, 17, rot=-8))
    p.plein(vert_fonce, cercle(34, 77, 2.3), cercle(42, 75, 2.3))
    oeil(p, 78, 63, 8)
    p.plein("#FF9DB0E6", cercle(82, 86, 6))
    p.trait(ENCRE, 2.6, courbe([(32, 88), (46, 94), (60, 92)]))
    return p


# ---------------------------------------------------------------------------
# Le son [d] : dent, dinosaure, dé
# ---------------------------------------------------------------------------

def dent() -> Picto:
    """Une dent de lait toute ronde, blanche et souriante, avec une petite étincelle."""
    p = Picto("mot.dent")
    ombre(p, 100, 179, 40, 5)
    forme = chemin((100, 44), ("C", (114, 30), (150, 30), (152, 64)), ("C", (154, 92), (146, 112), (142, 130)),
                   ("C", (138, 150), (136, 172), (123, 172)), ("C", (112, 172), (110, 150), (104, 140)),
                   ("C", (102, 136), (98, 136), (96, 140)), ("C", (90, 150), (88, 172), (77, 172)),
                   ("C", (64, 172), (62, 150), (58, 130)), ("C", (54, 112), (46, 92), (48, 64)),
                   ("C", (50, 30), (86, 30), (100, 44)))
    p.plein("#FBFDFF", forme)
    p.plein(BLANC_OMBRE, chemin((138, 58), ("C", (148, 70), (150, 92), (142, 120)),
                                ("C", (138, 140), (134, 166), (124, 170)), ("C", (130, 150), (134, 128), (136, 112)),
                                ("C", (140, 94), (144, 74), (138, 58))))
    p.plein(BLANC, ellipse(70, 56, 9, 6, rot=-30))
    p.trait(BORD_PALE, 2.6, forme)
    oeil(p, 84, 88, 7)
    oeil(p, 116, 88, 7)
    joue(p, 72, 104, 6.5)
    joue(p, 128, 104, 6.5)
    p.trait(ENCRE, 2.8, courbe([(90, 104), (100, 111), (110, 104)]))
    p.plein(JAUNE, etoile(160, 34, 10, 3, n=4, coins=0.9), etoile(40, 40, 6, 1.9, n=4, coins=0.7))
    return p


def dinosaure() -> Picto:
    """Un dinosaure à long cou, bleu et gentil, de profil (regarde à gauche)."""
    p = Picto("mot.dinosaure")
    bleu, bleu_fonce, ventre, taches = "#5AA9E6", "#4590D0", "#B4DDF8", "#3F86C8"
    ombre(p, 112, 179, 64, 6)
    # Pattes de l'autre côté, queue.
    p.plein(bleu_fonce, tube([(104, 136), (106, 167)], 18), tube([(146, 134), (150, 167)], 18))
    p.plein(bleu, tube([(146, 118), (166, 128), (177, 120), (180, 107)], [30, 20, 11, 5]))
    # Corps, ventre, pattes de ce côté et ongles.
    p.plein(bleu, ellipse(120, 122, 44, 30))
    p.plein(ventre, chemin((84, 132), ("C", (100, 150), (136, 152), (158, 132)),
                           ("C", (150, 148), (124, 156), (104, 154)), ("C", (94, 150), (86, 142), (84, 132))))
    p.plein(bleu, tube([(92, 136), (92, 166)], 20), tube([(136, 136), (138, 166)], 20))
    p.plein("#EAF4FC", *[ellipse(x, 171, 2.6, 2) for x in (86, 92, 98, 132, 138, 144)])
    # Le long cou et la petite tête.
    p.plein(bleu, tube([(94, 112), (72, 84), (62, 50)], [32, 22, 17]))
    p.plein(bleu, ellipse(52, 42, 21, 14, rot=-8))
    # Des taches sur le dos.
    p.plein(taches, cercle(112, 104, 5.5), cercle(130, 102, 4.5), cercle(146, 110, 4), cercle(122, 116, 3.5),
            cercle(82, 88, 3.5), cercle(72, 70, 3))
    oeil(p, 55, 36, 5.5)
    joue(p, 58, 48, 4.5)
    p.plein("#2E6FA8", cercle(36, 38, 1.6))
    p.trait(ENCRE, 2.2, courbe([(36, 47), (42, 50), (49, 49)]))
    return p


def de() -> Picto:
    """Un dé blanc à points noirs, vu de trois quarts : cinq sur le dessus, un et trois sur les côtés."""
    p = Picto("mot.de")
    ombre(p, 100, 178, 62, 6)
    haut, gauche, droite, milieu = (100, 26), (34, 60), (166, 60), (100, 94)
    bas_g, bas_d, bas = (34, 136), (166, 136), (100, 170)

    def face(o, u, v):
        """Le passage du carré unité (u, v) à la face de sommet o et d'arêtes u, v (une application affine)."""
        def f(q):
            return (o[0] + q[0] * u[0] + q[1] * v[0], o[1] + q[0] * u[1] + q[1] * v[1])
        return f

    def sur(f, forme):
        return [c.map(f) for c in forme]

    dessus = face(gauche, (haut[0] - gauche[0], haut[1] - gauche[1]), (milieu[0] - gauche[0], milieu[1] - gauche[1]))
    cote_g = face(gauche, (milieu[0] - gauche[0], milieu[1] - gauche[1]), (bas_g[0] - gauche[0], bas_g[1] - gauche[1]))
    cote_d = face(milieu, (droite[0] - milieu[0], droite[1] - milieu[1]), (bas[0] - milieu[0], bas[1] - milieu[1]))
    # La silhouette (bord pâle), puis les trois faces un peu en retrait : l'écart dessine les arêtes.
    p.plein(BORD_PALE, poly([haut, droite, bas_d, bas, bas_g, gauche], r=12))
    carre = rect(0.035, 0.035, 0.93, 0.93, r=0.16)
    p.plein(BLANC, sur(dessus, carre))
    p.plein("#EEF2F8", sur(cote_g, carre))
    p.plein("#DAE2ED", sur(cote_d, carre))
    # Les points.
    cinq = [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)]
    p.plein(ENCRE, *[sur(dessus, cercle(u, v, 0.1)) for u, v in cinq])
    p.plein(ENCRE, sur(cote_g, cercle(0.5, 0.5, 0.13)))
    p.plein(ENCRE, *[sur(cote_d, cercle(u, v, 0.1)) for u, v in ((0.25, 0.25), (0.5, 0.5), (0.75, 0.75))])
    return p


PICTOS: list[Picto] = [
    fleur(), feu(), fee(), fusee(), fraise(), fourchette(), phoque(),
    girafe(), velo(), verre(), valise(), vague(), cheval(), jupe(),
    genou(), orange(), neige(), cage(), gateau(), gomme(), guitare(),
    gant(), grenouille(), bague(), dragon(), dent(), dinosaure(), de(),
]
