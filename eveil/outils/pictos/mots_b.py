"""Les pictos des MOTS des livres des sons (lot B) : un nom par picto (`mot.<id>`).

Les livres des sons (un livre par son, comme OrthoPicto) ont besoin de mots dessinés pour
chaque son : ceux-ci complètent les dessins du petit train et du train des phrases. Même
style que `WordArt` : un seul objet ou animal, bien centré, formes pleines et arrondies,
couleurs vives mais accordées, pas de contour noir, ombre douce au sol ; les animaux ont
les yeux de la mascotte (`oeil`). Liste des mots : `eveil/outils/livres/mots.py`.

Lot B (29 mots) : dauphin, coq, canard, clé, camion, crocodile, cadeau, sac, zèbre, rose,
vase, ciseaux, nez, nuage, nid, banane, lune, pomme, pain, papillon, parapluie, lapin,
soupe, moto, mouton, plume, araignée, champignon, peigne.

Conventions propres à ce lot :
- les animaux de profil regardent vers la GAUCHE ;
- un sujet BLANC (mouton, zèbre) porte un liseré gris-bleu (`LISERE`), tracé sous les
  aplats : il ne reste visible qu'autour de la silhouette (comme l'oie de `WordArt`) ;
- un animal au visage sombre (mouton, araignée, papillon) a le blanc de l'œil (`oeil_clair`),
  sinon l'œil de la mascotte ne se verrait pas ;
- `decoupe` sert de « pochoir » : rayures du zèbre, ventre du dauphin, rabat du sac…
  (la partie d'une forme qui tombe dans une forme CONVEXE).
"""
from __future__ import annotations

import math

from coloriages.dessin import (Contour, arc, cercle, corde, courbe, deplace, ellipse, etoile, goutte, ligne, lisse,
                               poly, rect, relire, tourne, trou, tube)

from .accessoires import goutte_eau, onde
from .peinture import ENCRE, Picto, joue, oeil, ombre

Point = tuple[float, float]

LISERE = "#C3CCDB"        # liseré gris-bleu des sujets blancs (blanc sur carte blanche)
BLANC = "#FFFFFF"
ROUGE = "#E8414B"
ROUGE_FONCE = "#C62F3E"
JAUNE = "#FFD23F"
JAUNE_FONCE = "#F2B61E"
ORANGE = "#FF9A2E"
VERT = "#5CBF60"
VERT_FONCE = "#3F9E57"
PNEU = "#3A3F5C"
JANTE = "#C8CDE0"
MOYEU = "#8A90A6"


# ---------------------------------------------------------------------------
# Aides de dessin
# ---------------------------------------------------------------------------

def _sens_plein(c: Contour) -> Contour:
    """Oriente un contour fermé dans le sens « plein » (celui de toutes les formes de `dessin`)."""
    return c if c.area() >= 0 else c.reversed()


def _polygone(c: Contour, n: int = 8) -> list[Point]:
    """Les sommets d'un contour fermé (courbes échantillonnées), sans répéter le premier."""
    pts = c.sample(n)
    if len(pts) > 1 and math.dist(pts[0], pts[-1]) < 1e-6:
        pts = pts[:-1]
    return pts


def _aire(pts: list[Point]) -> float:
    return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))


def _garde(pts: list[Point], a: Point, b: Point) -> list[Point]:
    """Une étape de Sutherland–Hodgman : la partie de `pts` du côté intérieur de la droite a → b."""
    def cote(q: Point) -> float:
        return (b[0] - a[0]) * (q[1] - a[1]) - (b[1] - a[1]) * (q[0] - a[0])

    out: list[Point] = []
    for i, cur in enumerate(pts):
        prev = pts[i - 1]
        fc, fp = cote(cur), cote(prev)
        if (fc >= 0) != (fp >= 0):
            t = fp / (fp - fc)
            out.append((prev[0] + t * (cur[0] - prev[0]), prev[1] + t * (cur[1] - prev[1])))
        if fc >= 0:
            out.append(cur)
    return out


def decoupe(forme, gabarit, n: int = 8):
    """La partie de `forme` qui tombe dans `gabarit` (un contour CONVEXE) : un pochoir.

    Rayures du zèbre, ventre du dauphin, rabat du sac… Découpage de Sutherland–Hodgman sur
    les contours échantillonnés (`n` points par courbe) ; le résultat est un polygone dont
    les bords suivent ceux des deux formes.
    """
    clip = _polygone(gabarit[0], n)
    if _aire(clip) < 0:
        clip.reverse()
    out = []
    for c in forme:
        pts = _polygone(c, n)
        for i in range(len(clip)):
            pts = _garde(pts, clip[i], clip[(i + 1) % len(clip)])
            if len(pts) < 3:
                break
        propres = [q for k, q in enumerate(pts) if k == 0 or math.dist(q, pts[k - 1]) > 0.05]
        if len(propres) >= 3 and abs(_aire(propres)) > 0.5:
            out += poly(propres)
    return out


def feuille(base: Point, bout: Point, largeur: float, courbure: float = 0.0):
    """Une feuille en amande de `base` à `bout` (deux pointes), `largeur` au milieu.

    `courbure` (−1…1) aplatit un côté et bombe l'autre (feuille qui se courbe, nageoire, pétale).
    """
    (x0, y0), (x1, y1) = base, bout
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln, dx / ln
    k1 = largeur / 1.5 * (1 + courbure)
    k2 = largeur / 1.5 * (1 - courbure)
    c = Contour(base, [
        ("C", (x0 + dx / 3 + nx * k1, y0 + dy / 3 + ny * k1), (x0 + 2 * dx / 3 + nx * k1, y0 + 2 * dy / 3 + ny * k1),
         bout),
        ("C", (x0 + 2 * dx / 3 - nx * k2, y0 + 2 * dy / 3 - ny * k2), (x0 + dx / 3 - nx * k2, y0 + dy / 3 - ny * k2),
         base),
    ])
    return [_sens_plein(c)]


def oeil_clair(p: Picto, x: float, y: float, r: float, blanc: str = BLANC) -> None:
    """L'œil de la mascotte sur un visage sombre : un blanc d'œil autour de l'ovale sombre."""
    p.plein(blanc, ellipse(x, y, r * 1.28, r * 1.42))
    oeil(p, x, y + r * 0.12, r)


def roue(p: Picto, x: float, y: float, r: float) -> None:
    """Une roue : pneu sombre, jante claire, moyeu."""
    p.plein(PNEU, cercle(x, y, r))
    p.plein(JANTE, cercle(x, y, r * 0.46))
    p.plein(MOYEU, cercle(x, y, r * 0.17))


def _pt(o: Point, angle: float, r: float) -> Point:
    a = math.radians(angle)
    return (o[0] + math.cos(a) * r, o[1] + math.sin(a) * r)


def _transforme(s: float, deg: float, centre: Point, dxy: Point = (0.0, 0.0)):
    """Échelle `s` et rotation `deg` autour de `centre`, puis translation `dxy`.

    Renvoie deux fonctions : l'une pour les formes, l'autre pour les points (œil, joue…),
    pour pencher ou agrandir un sujet dessiné « droit » sans refaire ses coordonnées.
    """
    cx, cy = centre
    ca, sa = math.cos(math.radians(deg)), math.sin(math.radians(deg))

    def point(q: Point) -> Point:
        x, y = (q[0] - cx) * s, (q[1] - cy) * s
        return (cx + x * ca - y * sa + dxy[0], cy + x * sa + y * ca + dxy[1])

    def forme(f):
        return [c.map(point) for c in f]

    return forme, point


def _decale(p: Picto, dx: float, dy: float = 0.0) -> Picto:
    """Recentre un picto fini : décale tous ses tracés (ombre comprise) de (dx, dy)."""
    for op in p.ops:
        op.d = " ".join(c.map(lambda q: (q[0] + dx, q[1] + dy)).d() for c in relire(op.d))
    return p


# ---------------------------------------------------------------------------
# Les mots
# ---------------------------------------------------------------------------

def dauphin() -> Picto:
    """Un dauphin bleu qui saute au-dessus d'une petite vague (de profil, vers la gauche)."""
    p = Picto("mot.dauphin")
    bleu, nageoire, ventre = "#4F97E3", "#3B7FCC", "#CFE9FB"
    eau, eau_fonce = "#8FD3F7", "#62BDF0"
    # La vague : une bande d'eau à crêtes rondes, un fond plus soutenu, un peu d'écume.
    p.plein(eau, poly([(20, 176), (20, 156), (38, 146), (57, 156), (76, 146), (95, 156), (114, 146), (133, 156),
                       (152, 146), (171, 156), (180, 152), (180, 176)],
                      r=[6, 4, 9, 9, 9, 9, 9, 9, 9, 9, 3, 6]))
    p.plein(eau_fonce, rect(20, 164, 160, 12, r=6))
    p.plein(BLANC, ellipse(38, 150, 7, 3), ellipse(114, 150, 7, 3), ellipse(152, 150, 6, 2.6))
    # Les gouttes qui retombent de la queue.
    for x, y, r in ((160, 136, 3.4), (172, 130, 3), (178, 142, 2.6)):
        goutte_eau(p, x, y, r, couleur=eau_fonce)
    # Le dauphin est dessiné « à plat », puis penché nez en l'air (il bondit hors de l'eau).
    T, P = _transforme(1.0, 14, (100, 90), (0, 6))
    p.plein(nageoire, T(poly([(96, 62), (124, 30), (134, 60)], r=[3, 5, 3])))
    p.plein(nageoire, T(feuille((166, 97), (183, 80), 13, 0.3)), T(feuille((166, 99), (181, 118), 13, -0.3)))
    corps = lisse([(22, 108), (34, 99), (48, 88), (60, 72), (84, 58), (114, 54), (142, 62), (162, 80), (172, 95),
                   (164, 101), (146, 90), (122, 84), (94, 86), (70, 96), (52, 106), (36, 111)])
    p.plein(bleu, T(corps))
    p.plein(ventre, T(decoupe(corps, ellipse(92, 132, 96, 48))))
    p.plein(nageoire, T(poly([(64, 96), (86, 92), (90, 118)], r=[3, 3, 5])))
    # Visage : œil, sourire, joue.
    oeil(p, *P((52, 88)), 5.2)
    p.trait(ENCRE, 2.4, T(courbe([(28, 106), (40, 107), (50, 102)])))
    joue(p, *P((60, 99)), 5)
    return p


def coq() -> Picto:
    """Un coq de profil (vers la gauche) : crête et barbillons rouges, queue en faucilles colorées."""
    p = Picto("mot.coq")
    corps_c, cou_c, aile_c, patte = "#E08A3C", "#F7BE4C", "#C46A2C", "#FFC83D"
    ombre(p, 108, 179, 50, 6)
    # La queue : trois faucilles, de la plus lointaine à la plus proche.
    p.plein("#2E8F6E", tube([(130, 104), (146, 62), (164, 42), (180, 56)], [18, 16, 11, 5]))
    p.plein("#3F7FD6", tube([(138, 112), (160, 82), (176, 84), (180, 104)], [16, 13, 9, 4]))
    p.plein("#46B37E", tube([(126, 100), (132, 62), (146, 38), (162, 34)], [16, 13, 9, 4]))
    # Les pattes (derrière le corps) et les doigts tournés vers l'avant.
    for x in (96, 118):
        p.plein(patte, tube([(x, 140), (x - 2, 168)], 6))
        p.trait(patte, 4, ligne((x - 2, 168), (x - 14, 174)), ligne((x - 2, 168), (x - 5, 176)),
                ligne((x - 2, 168), (x + 7, 174)))
    # Le corps, l'aile.
    p.plein(corps_c, ellipse(106, 118, 42, 33))
    p.plein(aile_c, ellipse(116, 118, 26, 16, rot=-12))
    p.trait(corps_c, 3, courbe([(104, 122), (118, 124), (134, 118)]))
    # Le cou doré (camail) : pointes qui retombent sur le corps.
    p.plein(cou_c, tube([(88, 104), (76, 82), (70, 64)], [34, 30, 26]),
            poly([(70, 92), (78, 118), (86, 104), (94, 120), (100, 104), (106, 112), (104, 90)], r=3))
    # La crête (derrière la tête), la tête, le bec, le barbillon.
    p.plein(ROUGE, cercle(58, 44, 8), cercle(68, 39, 9), cercle(79, 43, 8))
    p.plein(cou_c, cercle(68, 60, 19))
    p.plein(patte, poly([(52, 54), (33, 61), (52, 68)], r=[2, 3, 2]))
    p.plein(ROUGE, goutte(55, 80, 6, 13))
    oeil(p, 65, 56, 4.6)
    joue(p, 74, 66, 4)
    return _decale(p, -5)


def canard() -> Picto:
    """Un canard jaune de profil (vers la gauche), bec et pattes orange."""
    p = Picto("mot.canard")
    jaune, jaune_fonce = "#FFD84D", "#F2BE22"
    ombre(p, 108, 179, 52, 6)
    # Pattes (derrière le corps) et pieds palmés.
    for x in (98, 122):
        p.plein(ORANGE, tube([(x, 150), (x - 2, 168)], 6))
        p.plein(ORANGE, poly([(x - 2, 164), (x - 19, 176), (x + 7, 176)], r=[2, 3, 3]))
    # Corps (queue relevée en pointe), cou, tête.
    p.plein(jaune, lisse([(70, 108), (100, 112), (140, 108), (174, 90), (168, 118), (150, 146), (116, 158),
                          (80, 154), (58, 134)]))
    p.plein(jaune, tube([(76, 96), (82, 118)], 30), cercle(72, 80, 26))
    p.plein(jaune_fonce, ellipse(120, 128, 28, 16, rot=-14))
    # Le bec plat.
    p.plein(ORANGE, poly([(56, 78), (27, 85), (27, 94), (56, 97)], r=[2, 7, 7, 2]))
    p.trait("#E6781A", 2, ligne((34, 90), (52, 90)))
    oeil(p, 70, 74, 5.5)
    joue(p, 82, 90, 5)
    return p


def cle() -> Picto:
    """Une clé dorée, penchée : anneau, tige, deux dents (une tranche plus foncée donne l'épaisseur)."""
    p = Picto("mot.cle")
    or_, or_fonce, or_clair = "#F5C03A", "#D99A1E", "#FFE59A"
    ombre(p, 100, 177, 60, 6)

    def t(f):
        return tourne(f, -32, 100, 100)

    formes = [cercle(56, 100, 32) + trou(cercle(56, 100, 14)), rect(80, 92, 96, 17, r=7),
              rect(140, 104, 11, 21, r=3), rect(157, 104, 11, 29, r=3)]
    p.plein(or_fonce, *[deplace(t(f), 1.5, 4.5) for f in formes])
    p.plein(or_, *[t(f) for f in formes])
    p.trait(or_clair, 4.5, t(arc(56, 100, 23, 195, 285)))
    p.trait(or_clair, 3.5, t(ligne((94, 97.5), (160, 97.5))))
    return p


def camion() -> Picto:
    """Un camion à benne (vers la gauche) : cabine rouge, benne jaune à côtes, roues noires."""
    p = Picto("mot.camion")
    ombre(p, 100, 177, 80, 6)
    # Châssis.
    p.plein("#4A4F63", rect(26, 124, 150, 16, r=6))
    # La benne : caisse jaune, rebord clair, côtes plus foncées.
    p.plein(JAUNE, poly([(82, 72), (178, 66), (172, 126), (88, 126)], r=6))
    p.plein("#FFE38A", poly([(82, 72), (178, 66), (177, 76), (83, 81)], r=3))
    p.trait(JAUNE_FONCE, 5, ligne((110, 84), (111, 118)), ligne((134, 82), (134, 118)), ligne((158, 80), (156, 118)))
    # La cabine : pare-brise, portière, phare, pare-chocs.
    p.plein(ROUGE, poly([(20, 128), (20, 98), (32, 78), (78, 78), (78, 128)], r=[4, 8, 10, 6, 4]))
    p.plein("#BFE4FB", poly([(30, 100), (39, 86), (64, 86), (64, 100)], r=[3, 4, 3, 3]))
    p.plein(ROUGE_FONCE, rect(56, 108, 12, 4, r=2))
    p.plein(JAUNE, cercle(24, 116, 5))
    p.plein(JANTE, rect(14, 122, 22, 10, r=4))
    # Les roues.
    roue(p, 54, 150, 20)
    roue(p, 146, 150, 20)
    return _decale(p, 3)


def crocodile() -> Picto:
    """Un crocodile vert qui sourit, de profil (vers la gauche) : gentil, bouche fermée."""
    p = Picto("mot.crocodile")
    vert, fonce, ventre = "#5DBB63", "#3F9E57", "#D4EDA0"
    ombre(p, 102, 179, 82, 6)
    # Pattes du côté lointain (plus foncées).
    p.plein(fonce, rect(90, 132, 16, 36, r=7), rect(142, 132, 16, 36, r=7))
    # Les écailles du dos : des bosses peintes avant le corps (seul leur dessus dépasse).
    corps = ellipse(110, 124, 48, 26)
    bosses = []
    for x in (86, 100, 114, 128, 142):
        y = 124 - 26 * math.sqrt(max(0.0, 1 - ((x - 110) / 48) ** 2))
        bosses.append(cercle(x, y + 1, 6))
    bosses += [cercle(163, 114, 4.8), cercle(175, 104, 3.6)]
    p.plein(fonce, *bosses)
    # La queue qui remonte, le corps, le ventre clair, quelques écailles.
    p.plein(vert, tube([(144, 124), (166, 126), (178, 112), (181, 96)], [34, 22, 11, 4]))
    p.plein(vert, corps)
    p.plein(ventre, decoupe(corps, rect(40, 136, 140, 30)))
    p.plein(fonce, ellipse(106, 118, 6.5, 4.2), ellipse(124, 110, 5.5, 3.6), ellipse(140, 122, 5.5, 3.6))
    # Pattes du côté proche, pieds tournés vers l'avant.
    for x in (72, 126):
        p.plein(vert, rect(x, 134, 17, 34, r=7), ellipse(x + 5, 168, 12.5, 5.5))
    # La tête : bosse de l'œil lointain, museau, bosse des narines, bosse de l'œil.
    p.plein(fonce, cercle(54, 98, 10))
    p.plein(vert, rect(16, 100, 72, 38, r=17), ellipse(86, 118, 22, 20), cercle(24, 102, 8), cercle(70, 95, 13.5))
    p.plein(fonce, cercle(21, 99, 2.2), cercle(28, 99, 2.2))
    # Le sourire, trois petites dents rondes, l'œil, la joue.
    bouche = [(22, 124), (48, 129), (72, 125), (85, 113)]
    p.plein(BLANC, *[poly([(x - 3.4, y - 0.5), (x + 3.4, y - 0.5), (x, y + 5)], r=1.2)
                     for x, y in ((34, 127), (46, 128.5), (58, 128))])
    p.trait(ENCRE, 2.8, courbe(bouche))
    oeil(p, 70, 93, 6.8)
    joue(p, 74, 113, 5.5)
    return p


def cadeau() -> Picto:
    """Un paquet cadeau : boîte à pois, couvercle, ruban croisé et gros nœud."""
    p = Picto("mot.cadeau")
    boite, couvercle = "#4F9BEA", "#3F86D6"
    ruban, ruban_fonce = "#FF5E7E", "#D9436A"
    ombre(p, 100, 179, 66, 6)
    p.plein(boite, rect(42, 100, 116, 76, r=6))
    p.plein("#FFFFFFB0", cercle(60, 124, 5), cercle(74, 154, 5), cercle(132, 122, 5), cercle(144, 156, 5),
            cercle(58, 164, 3.5), cercle(146, 138, 3.5))
    p.plein(couvercle, rect(34, 80, 132, 26, r=6))
    p.plein(ruban, rect(90, 80, 20, 96))
    p.plein(ruban_fonce, rect(90, 104, 20, 4))
    # Le nœud : deux boucles (creux plus foncé), deux pans, le nœud central.
    p.plein(ruban, tube([(98, 78), (84, 104)], 9), tube([(102, 78), (116, 104)], 9))
    p.plein(ruban, ellipse(76, 60, 28, 16, rot=25), ellipse(124, 60, 28, 16, rot=-25))
    p.plein(ruban_fonce, ellipse(78, 61, 13, 6.5, rot=25), ellipse(122, 61, 13, 6.5, rot=-25))
    p.plein(ruban, rect(90, 64, 20, 18, r=7))
    return p


def sac() -> Picto:
    """Un sac à dos d'enfant (de face) : bretelles, rabat, poche avant, petite étoile."""
    p = Picto("mot.sac")
    bleu, fonce, poche, poche_fonce = "#4F8FE8", "#3A74C9", "#FFC83D", "#E8A91F"
    ombre(p, 100, 179, 58, 6)
    # Poignée et bretelles (derrière le sac : seules leurs boucles dépassent).
    p.trait(fonce, 7, courbe([(84, 50), (100, 30), (116, 50)]))
    p.plein(fonce, tube([(62, 54), (40, 96), (46, 156)], 11), tube([(138, 54), (160, 96), (154, 156)], 11))
    corps = rect(46, 44, 108, 132, r=38)
    p.plein(bleu, corps)
    p.plein(fonce, decoupe(corps, ellipse(100, 50, 72, 48)))
    p.plein(poche, rect(92, 86, 16, 14, r=4))
    # Poche avant, fermeture éclair et tirette, étoile.
    p.plein(poche, rect(62, 116, 76, 50, r=16))
    p.trait(poche_fonce, 3, ligne((72, 126), (128, 126)))
    p.plein(poche_fonce, rect(117, 124, 7, 14, r=3))
    p.plein("#FF5E5B", etoile(100, 148, 11, coins=3))
    return p


def zebre() -> Picto:
    """Un zèbre de profil (vers la gauche) : blanc à rayures noires, crinière et museau sombres."""
    p = Picto("mot.zebre")
    noir, loin = "#34343F", "#EEF0F5"
    ombre(p, 118, 179, 60, 6)
    corps = ellipse(124, 104, 44, 27)
    cou = poly([(80, 118), (54, 66), (76, 44), (108, 86)], r=10)
    tete = ellipse(50, 66, 25, 14, rot=-55)
    oreille = poly([(58, 50), (61, 25), (71, 45)], r=[2, 4, 2])
    oreille_loin = poly([(66, 48), (75, 28), (79, 48)], r=[2, 4, 2])
    pattes_loin = [rect(104, 114, 12, 56, r=5), rect(142, 114, 12, 56, r=5)]
    pattes_pres = [rect(88, 116, 12, 54, r=5), rect(154, 114, 12, 56, r=5)]

    def rayures(partie, bandes):
        p.plein(noir, *[decoupe(b, partie) for b in bandes])

    def jambe(pa, couleur):
        x0 = pa[0].start[0] - 5
        p.plein(couleur, pa)
        rayures(pa, [tube([(x0 - 4, y), (x0 + 16, y - 2)], 5) for y in (128, 140, 151)])
        p.plein(noir, decoupe(pa, rect(x0 - 2, 161, 16, 12)))

    # La queue (derrière), puis le liseré de toute la silhouette blanche.
    p.trait(noir, 4, courbe([(164, 96), (172, 108), (174, 124)]))
    p.plein(noir, goutte(174, 131, 5, 13))
    p.trait(LISERE, 5, *pattes_loin, corps, *pattes_pres, cou, tete, oreille, oreille_loin)
    for pa in pattes_loin:
        jambe(pa, loin)
    p.plein(BLANC, corps)
    rayures(corps, [tube([(98, 72), (94, 104), (98, 136)], [9, 8, 4]),
                    tube([(114, 72), (110, 104), (114, 136)], [10, 9, 5]),
                    tube([(130, 72), (128, 104), (130, 136)], [10, 9, 5]),
                    tube([(144, 74), (146, 96), (160, 118)], [9, 8, 4]),
                    tube([(158, 78), (160, 92), (170, 104)], [8, 7, 4])])
    for pa in pattes_pres:
        jambe(pa, BLANC)
    # La crinière (le cou la recouvre à moitié), le cou et ses rayures.
    p.plein(noir, tube([(66, 40), (84, 58), (104, 82)], 12))
    p.plein(BLANC, cou)
    base, haut = (94, 102), (65, 55)
    ux, uy = haut[0] - base[0], haut[1] - base[1]
    ln = math.hypot(ux, uy)
    vx, vy = -uy / ln, ux / ln
    bandes = []
    for t in (0.2, 0.42, 0.64):
        cx, cy = base[0] + ux * t, base[1] + uy * t
        bandes.append(tube([(cx - vx * 34, cy - vy * 34), (cx + vx * 34, cy + vy * 34)], 7))
    rayures(cou, bandes)
    # Les oreilles, la tête, ses rayures, le museau sombre.
    p.plein(loin, oreille_loin)
    p.plein(BLANC, oreille)
    p.plein(noir, decoupe(oreille, cercle(61, 25, 8)), decoupe(oreille_loin, cercle(75, 28, 8)))
    p.plein(BLANC, tete)
    rayures(tete, [tube([(30, 60), (58, 80)], 5), tube([(36, 52), (64, 72)], 4)])
    p.plein(noir, decoupe(tete, cercle(35, 88, 13)))
    oeil(p, 55, 58, 5)
    joue(p, 50, 73, 4)
    return _decale(p, -3)


def rose() -> Picto:
    """Une rose rouge : fleur en coupe (cœur en spirale), sépales, tige et deux feuilles."""
    p = Picto("mot.rose")
    fonce, rouge, clair = "#C62F42", "#E84A5F", "#F26D7F"
    ombre(p, 100, 179, 30, 5)
    # La tige et les feuilles.
    p.plein(VERT_FONCE, tube([(100, 92), (104, 130), (98, 174)], 7))
    for base, bout in (((102, 136), (70, 124)), ((102, 116), (136, 102))):
        p.plein(VERT, feuille(base, bout, 15, 0.2))
        p.trait(VERT_FONCE, 2, ligne(base, ((base[0] + bout[0]) / 2, (base[1] + bout[1]) / 2)))
    # Les sépales sous la fleur.
    p.plein(VERT, feuille((100, 90), (80, 104), 9), feuille((100, 90), (120, 104), 9))
    # La fleur : coupe du fond, cœur en spirale, deux pétales de devant.
    p.plein(fonce, lisse([(62, 56), (70, 32), (100, 22), (130, 32), (138, 56), (126, 84), (100, 96), (74, 84)]))
    p.plein(rouge, ellipse(100, 42, 27, 15))
    p.trait(fonce, 3.2, courbe([(100, 42), (110, 40), (108, 33), (96, 32), (86, 40), (92, 50), (108, 51),
                                (120, 44)]))
    p.plein(rouge, lisse([(62, 50), (80, 54), (100, 70), (98, 96), (74, 86)]))
    p.plein(clair, lisse([(138, 50), (120, 54), (98, 72), (102, 96), (126, 86)]))
    return p


def vase() -> Picto:
    """Un vase bleu (panse ronde, col étroit, bord évasé) d'où sort une fleur rose."""
    p = Picto("mot.vase")
    bleu, fonce, clair = "#3F8FE0", "#2A62AE", "#8CC4F5"
    ombre(p, 100, 179, 42, 6)
    panse = ellipse(100, 140, 40, 32)
    p.plein(bleu, panse, rect(86, 100, 28, 34, r=4), ellipse(100, 100, 22, 7), rect(78, 164, 44, 11, r=4))
    p.plein(clair, decoupe(tube([(56, 140), (80, 132), (100, 142), (120, 132), (144, 140)], 8), panse))
    p.plein("#FFFFFF70", ellipse(80, 132, 6, 13, rot=20))
    p.plein(fonce, ellipse(100, 99, 15, 4))
    # La fleur qui sort du vase : tige, feuille, corolle.
    p.plein(VERT_FONCE, tube([(100, 99), (98, 74), (101, 52)], 6))
    p.plein(VERT, feuille((99, 86), (124, 72), 12, 0.2))
    p.plein("#FF7EB6", *[cercle(*_pt((101, 46), -90 + i * 72, 15), 12.5) for i in range(5)])
    p.plein(JAUNE, cercle(101, 46, 10))
    return p


def ciseaux() -> Picto:
    """Des ciseaux d'enfant entrouverts, bouts ronds, poignées en plastique coloré."""
    p = Picto("mot.ciseaux")
    lame, lame_clair, plastique, plastique_fonce = "#BCC4D4", "#E6EAF2", "#FF7043", "#E0552B"
    ombre(p, 100, 179, 50, 6)
    pivot = (100, 104)
    for anneau, bout in (((66, 150), (130, 26)), ((134, 150), (70, 26))):
        # La lame (du pivot au bout rond), son reflet, puis la poignée qui cache le talon.
        dx, dy = bout[0] - pivot[0], bout[1] - pivot[1]
        talon = (pivot[0] - dx * 0.16, pivot[1] - dy * 0.16)
        p.plein(lame, tube([talon, pivot, bout], [15, 15, 10]))
        p.trait(lame_clair, 3, ligne((pivot[0] + dx * 0.15 + 3, pivot[1] + dy * 0.15),
                                     (pivot[0] + dx * 0.8 + 2, pivot[1] + dy * 0.8)))
        p.plein(plastique, tube([anneau, (pivot[0] + (anneau[0] - pivot[0]) * 0.28,
                                          pivot[1] + (anneau[1] - pivot[1]) * 0.28)], 14))
        p.plein(plastique, ellipse(anneau[0], anneau[1], 23, 18) + trou(ellipse(anneau[0], anneau[1], 12, 8)))
        p.plein(plastique_fonce, decoupe(ellipse(anneau[0], anneau[1], 23, 18),
                                         rect(anneau[0] - 30, anneau[1] + 8, 60, 20)))
    p.plein(JANTE, cercle(*pivot, 7))
    p.plein(MOYEU, cercle(*pivot, 3))
    return p


def nez() -> Picto:
    """Un visage d'enfant tout simple, de face (la peau de Lou), avec un gros nez rond bien en valeur."""
    p = Picto("mot.nez")
    peau, cheveux = "#B8784E", "#2B1D16"
    c = (100, 94)
    r = 56
    # Épaules (t-shirt jaune de Lou) et cou.
    p.plein("#FFC83D", poly([(36, 184), (42, 167), (72, 154), (128, 154), (158, 167), (164, 184)],
                            r=[0, 12, 14, 14, 12, 0]))
    p.plein(peau, rect(86, 138, 28, 26, r=6), ellipse(100, 157, 16, 7))
    # Cheveux de derrière, oreilles, visage, frange de boucles.
    for a in range(160, 386, 25):
        p.plein(cheveux, cercle(c[0] + (r - 2) * math.cos(math.radians(a)),
                                c[1] - 8 + (r - 9) * math.sin(math.radians(a)), 19))
    p.plein(peau, cercle(c[0] - r + 2, c[1] + 8, 12), cercle(c[0] + r - 2, c[1] + 8, 12))
    p.plein(peau, cercle(c[0], c[1], r))
    p.plein(cheveux, *[cercle(c[0] + dx, c[1] - 42 + abs(dx) * 0.2, 17) for dx in (-36, -12, 12, 36)])
    # Les yeux, les joues, le sourire (plus discrets que le nez).
    oeil(p, c[0] - 23, c[1] - 2, 7.5)
    oeil(p, c[0] + 23, c[1] - 2, 7.5)
    joue(p, c[0] - 37, c[1] + 22, 8)
    joue(p, c[0] + 37, c[1] + 22, 8)
    p.trait(ENCRE, 3.2, courbe([(c[0] - 11, c[1] + 45), (c[0], c[1] + 50), (c[0] + 11, c[1] + 45)]))
    # LE NEZ : une grosse boule plus claire et rosée que la peau, son ombre portée, deux reflets.
    p.plein("#8A5232", ellipse(c[0] + 1.5, c[1] + 27, 19, 15.5))
    p.plein("#D9936B", ellipse(c[0], c[1] + 22, 19, 16))
    p.plein("#C27A52", decoupe(ellipse(c[0], c[1] + 22, 19, 16), ellipse(c[0] + 6, c[1] + 34, 22, 12)))
    p.plein("#F6CBA8", ellipse(c[0] - 7, c[1] + 14, 7, 4.8, rot=-18))
    p.plein("#FFFFFFC0", cercle(c[0] - 9.5, c[1] + 13, 2.2))
    return p


def un_nuage() -> Picto:
    """Un nuage blanc et bleu clair dans un bout de ciel."""
    p = Picto("mot.nuage")
    ciel, ciel_fonce = "#BFE3FA", "#9CCFF3"
    p.plein(ciel, rect(20, 32, 160, 136, r=34))
    forme = [cercle(58, 112, 20), cercle(86, 92, 28), cercle(118, 86, 32), cercle(146, 106, 22),
             cercle(78, 124, 17), cercle(106, 128, 18), cercle(134, 124, 17), rect(58, 100, 88, 28, r=14)]
    p.plein(ciel_fonce, *[deplace(f, 3, 6) for f in forme])
    p.plein(BLANC, *forme)
    p.plein("#E2EEFA", *[decoupe(f, ellipse(102, 160, 70, 40)) for f in forme])
    p.plein(BLANC, cercle(44, 58, 5), cercle(158, 146, 4))
    return p


def nid() -> Picto:
    """Un nid de brindilles avec trois œufs bleus."""
    p = Picto("mot.nid")
    brun, brun_fonce, brun_clair = "#B07A3E", "#7E5226", "#D9A45E"
    oeuf, tache = "#8FD3F4", "#5FB3E0"
    ombre(p, 100, 178, 66, 6)
    # Le creux du nid, les œufs (celui du fond d'abord), puis la coque de brindilles.
    p.plein(brun_fonce, ellipse(100, 118, 62, 18))
    for x, y, a in ((100, 88, 0), (72, 98, -18), (128, 98, 18)):
        p.plein(oeuf, ellipse(x, y, 19, 25, rot=a))
        p.plein(tache, cercle(x + 6, y + 5, 2.6), cercle(x - 5, y + 11, 2.1), cercle(x + 8, y - 8, 1.9))
        p.plein("#FFFFFFB0", ellipse(x - 7, y - 10, 4, 7, rot=a - 20))
    p.plein(brun, corde(100, 118, 66, 0, 180, 46))
    p.plein(brun_clair, tube([(36, 118), (68, 129), (100, 132), (132, 129), (164, 118)], 14))
    p.trait(brun_fonce, 3, courbe([(46, 132), (78, 150), (116, 150)]), courbe([(88, 140), (124, 146), (156, 130)]),
            courbe([(62, 150), (92, 160), (132, 156)]), ligne((30, 114), (20, 106)), ligne((168, 112), (180, 104)))
    p.trait(brun_clair, 3, courbe([(52, 144), (84, 146), (110, 140)]), courbe([(100, 154), (130, 150), (146, 142)]),
            ligne((36, 124), (24, 128)), ligne((164, 124), (178, 128)))
    return p


def banane() -> Picto:
    """Une banane jaune bien courbée : pédoncule vert-brun, bout sombre, un reflet."""
    p = Picto("mot.banane")
    jaune, fonce, clair = "#FFDB4D", "#F2B829", "#FFF0A6"
    ombre(p, 102, 178, 64, 6)
    # Dessinée « en U », puis penchée : le bout sombre en bas à gauche, la queue en haut à droite.
    T, _ = _transforme(1.0, -20, (100, 118), (0, 4))
    corps = tube([(36, 90), (62, 128), (100, 144), (140, 132), (164, 102)], [8, 28, 34, 28, 14])
    p.plein(jaune, T(corps))
    p.plein(fonce, T(decoupe(corps, ellipse(100, 200, 100, 56))))
    p.trait(clair, 4, T(courbe([(58, 112), (80, 128), (106, 134), (128, 128)])))
    p.plein("#8A6A2F", T(tube([(163, 106), (170, 76)], [12, 9])))
    p.plein("#5E4520", T(cercle(170, 74, 4.5)), T(cercle(36, 90, 4.5)))
    return _decale(p, 6)


def lune() -> Picto:
    """Un croissant de lune jaune qui dort (œil fermé, sourire), et quelques étoiles."""
    p = Picto("mot.lune")
    jaune, fonce = "#FFD23F", "#F2B61E"
    c, rr = (118, 100), 50
    angles = [292, 255, 218, 180, 142, 105, 68]
    largeurs = [5, 24, 36, 40, 36, 24, 5]
    arc_pts = [_pt(c, a, rr) for a in angles]
    croissant = tube(arc_pts, largeurs)
    p.plein(fonce, deplace(croissant, 2, 4))
    p.plein(jaune, croissant)
    oeil(p, 76, 92, 6, ferme=True)
    p.trait(ENCRE, 2.8, courbe([(80, 114), (88, 120), (96, 116)]))
    joue(p, 72, 108, 6)
    for x, y, r in ((152, 64, 13), (162, 118, 9), (136, 146, 7)):
        p.plein(JAUNE_FONCE, etoile(x, y, r, coins=r * 0.25))
    p.plein(JAUNE, cercle(172, 86, 3), cercle(140, 36, 3), cercle(40, 156, 2.6))
    return _decale(p, -4)


def pomme() -> Picto:
    """Une pomme rouge : tige, feuille, reflet."""
    p = Picto("mot.pomme")
    ombre(p, 100, 178, 50, 6)
    corps = lisse([(100, 62), (124, 50), (150, 64), (160, 102), (144, 148), (120, 166), (100, 160), (80, 166),
                   (56, 148), (40, 102), (50, 64), (76, 50)])
    p.plein("#8B5A2B", tube([(100, 66), (102, 48), (108, 34)], [7, 6, 5]))
    p.plein(ROUGE, corps)
    p.plein("#D3343F", decoupe(corps, ellipse(130, 156, 46, 30)))
    p.plein("#FF8080", ellipse(68, 88, 9, 17, rot=20))
    p.plein("#FFC2C2", cercle(70, 70, 4))
    p.plein(VERT, feuille((106, 46), (142, 30), 14, 0.25))
    p.trait(VERT_FONCE, 2, ligne((110, 44), (132, 35)))
    return p


def pain() -> Picto:
    """Une baguette de pain dorée, en diagonale, avec ses entailles."""
    p = Picto("mot.pain")
    croute, fonce, grigne = "#E3A24F", "#C4822F", "#F7D595"
    ombre(p, 100, 176, 72, 6)
    a, b = (32, 146), (168, 64)
    corps = tube([a, (78, 118), (122, 92), b], [26, 36, 36, 26])
    p.plein(croute, corps)
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dy)
    ux, uy = dx / ln, dy / ln
    nx, ny = -uy, ux            # normale vers le bas-droite
    q = [(a[0] + nx * 6 - ux * 40, a[1] + ny * 6 - uy * 40), (b[0] + nx * 6 + ux * 40, b[1] + ny * 6 + uy * 40),
         (b[0] + nx * 60 + ux * 40, b[1] + ny * 60 + uy * 40), (a[0] + nx * 60 - ux * 40, a[1] + ny * 60 - uy * 40)]
    p.plein(fonce, decoupe(corps, poly(q)))
    angle = math.degrees(math.atan2(dy, dx))
    for t in (0.16, 0.33, 0.5, 0.67, 0.84):
        x, y = a[0] + dx * t - nx * 3, a[1] + dy * t - ny * 3
        p.plein(grigne, ellipse(x, y, 13, 4.2, rot=angle - 28))
    return p


def papillon() -> Picto:
    """Un papillon vu de face, ailes roses et orange à pois, antennes, yeux de la mascotte."""
    p = Picto("mot.papillon")
    haut, bas, pois, corps_c = "#FF6FA3", "#FFA93D", "#FFE574", "#4A3F6B"
    ombre(p, 100, 180, 36, 5)
    for s in (1, -1):
        def m(q, s=s):
            return (100 + s * (q[0] - 100), q[1])
        p.plein(bas, lisse([m(q) for q in [(104, 108), (140, 106), (164, 124), (160, 152), (136, 164), (112, 146)]]))
        p.plein(haut, lisse([m(q) for q in [(104, 96), (116, 56), (146, 34), (174, 42), (180, 72), (164, 98),
                                            (124, 108)]]))
        p.plein(pois, cercle(*m((148, 62)), 12), cercle(*m((166, 86)), 6), cercle(*m((138, 138)), 9))
        p.trait(corps_c, 3.4, courbe([m((96, 62)), m((88, 44)), m((78, 34))]))
        p.plein(corps_c, cercle(*m((77, 33)), 4.6))
    p.plein(corps_c, ellipse(100, 116, 9, 36), cercle(100, 72, 16))
    oeil_clair(p, 94, 70, 3.7)
    oeil_clair(p, 106, 70, 3.7)
    p.trait("#F2B6C0", 2.2, courbe([(96, 80), (100, 82.5), (104, 80)]))
    return p


def parapluie() -> Picto:
    """Un parapluie ouvert, rayé rouge et jaune (six pans festonnés), manche en crosse."""
    p = Picto("mot.parapluie")
    metal, bois = "#5A5F73", "#A86B32"
    ombre(p, 94, 179, 34, 5)
    cx, bas, haut, rx, n = 100.0, 104.0, 32.0, 80.0, 6
    xs = [cx - rx + i * 2 * rx / n for i in range(n + 1)]

    def baleine(xb: float, k: int = 12) -> list[Point]:
        """Une baleine, du sommet au bord (un quart d'ellipse : la toile est un dôme)."""
        return [(cx + (xb - cx) * math.sin(t / k * math.pi / 2), bas - (bas - haut) * math.cos(t / k * math.pi / 2))
                for t in range(k + 1)]

    def feston(x0: float, x1: float, k: int = 8, creux: float = 9.0) -> list[Point]:
        return [(x0 + (x1 - x0) * t / k, bas - creux * 4 * (t / k) * (1 - t / k)) for t in range(1, k)]

    # La hampe et la crosse.
    p.plein(metal, tube([(cx, bas - 6), (cx, 152)], 6))
    p.plein(bois, tube([(cx, 146), (cx, 162), (cx - 8, 171), (cx - 17, 167), (cx - 18, 158)], 9))
    # La toile : six pans, un sur deux rouge.
    for i in range(n):
        pts = baleine(xs[i]) + feston(xs[i], xs[i + 1]) + baleine(xs[i + 1])[::-1]
        p.plein((ROUGE, JAUNE)[i % 2], poly(pts[:-1]))
    # Le bout pointu et les embouts des baleines.
    p.plein(metal, tube([(cx, haut + 4), (cx, haut - 12)], [6, 4]))
    p.plein(metal, *[cercle(x, bas, 3.2) for x in xs])
    return p


def lapin() -> Picto:
    """Un lapin assis, de profil (vers la gauche) : longues oreilles, queue en pompon."""
    p = Picto("mot.lapin")
    poil, poil_fonce, creme, rose_ = "#D9A877", "#C4905E", "#F8EBDA", "#F7A9B9"
    ombre(p, 112, 179, 54, 6)
    # L'oreille lointaine, la queue, le corps (en poire), la cuisse, le pied arrière.
    p.plein(poil_fonce, ellipse(94, 46, 9, 25, rot=18))
    p.trait("#E6D3BD", 4, cercle(158, 146, 11))
    p.plein(creme, cercle(158, 146, 11))
    p.plein(poil, lisse([(86, 90), (116, 86), (144, 106), (156, 140), (146, 168), (104, 172), (78, 160), (72, 124)]))
    p.plein(poil_fonce, ellipse(130, 144, 25, 23))
    p.plein(poil, ellipse(128, 142, 22, 20), ellipse(122, 168, 29, 8))
    # Les pattes avant (la lointaine plus foncée), le poitrail crème.
    p.plein(poil_fonce, tube([(96, 140), (95, 163)], 11), ellipse(97, 167, 8.5, 5.5))
    p.plein(creme, ellipse(86, 128, 13, 24))
    p.plein(poil, tube([(82, 142), (80, 163)], 12), ellipse(79, 167, 9.5, 6))
    # La tête, le museau crème, l'oreille proche (intérieur rose).
    p.plein(poil, ellipse(70, 94, 28, 24))
    p.plein(poil, ellipse(80, 44, 10, 27, rot=8))
    p.plein(rose_, ellipse(80, 47, 5, 19, rot=8))
    p.plein(creme, ellipse(52, 103, 14, 11))
    # Nez, bouche, moustaches, œil, joue.
    p.plein("#F48FA5", ellipse(41, 98, 4.5, 3.4))
    p.trait(ENCRE, 2, courbe([(41, 101), (42, 106), (47, 108)]))
    p.trait("#A77E5A", 1.6, ligne((36, 104), (22, 101)), ligne((36, 107), (23, 110)))
    oeil(p, 62, 88, 5.6)
    joue(p, 66, 104, 5)
    return p


def soupe() -> Picto:
    """Un bol de soupe fumante, une cuillère plongée dedans."""
    p = Picto("mot.soupe")
    bol_c, bol_fonce, bol_clair = "#3FA7F5", "#2B86D0", "#8FD0F8"
    soupe_c, soupe_fonce = "#F59E42", "#E0842A"
    ombre(p, 100, 178, 54, 6)
    # La vapeur.
    for x in (68, 92, 116):
        onde(p, (x, 92), (x - 2, 44), amplitude=4.5, bosses=3, couleur="#B9C7DC", largeur=4.5)
    # Le pied, la paroi, le bord, la soupe.
    p.plein(bol_fonce, rect(74, 156, 52, 14, r=5))
    paroi = corde(100, 108, 70, 0, 180, 56)
    p.plein(bol_c, paroi)
    p.plein(BLANC, *[decoupe(cercle(x, 134, 4.5), paroi) for x in (58, 82, 106, 130, 150)])
    p.plein(bol_clair, ellipse(100, 108, 70, 18))
    p.plein(soupe_c, ellipse(100, 110, 62, 13))
    p.trait(soupe_fonce, 1.8, ellipse(100, 113, 55, 8.5))
    p.plein(VERT, cercle(78, 108, 2.6), cercle(94, 114, 2.2), cercle(70, 115, 2), cercle(106, 106, 2.2))
    p.plein("#FFD06B", cercle(86, 106, 3.2), cercle(132, 112, 3))
    # La cuillère : son manche sort de la soupe.
    p.plein(soupe_fonce, ellipse(126, 106, 10, 4))
    p.plein("#B9C4D4", tube([(124, 106), (150, 70), (164, 52)], [7, 8, 10]))
    p.plein("#E1E6EE", tube([(146, 72), (160, 54)], 3))
    return p


def moto() -> Picto:
    """Une moto rouge de profil (vers la gauche) : réservoir, selle, phare, pot d'échappement."""
    p = Picto("mot.moto")
    gris, gris_fonce = "#8A90A6", "#5A5F73"
    ombre(p, 100, 178, 80, 6)
    # Les roues, le garde-boue avant, la fourche avant, le bras arrière.
    roue(p, 46, 146, 25)
    roue(p, 154, 146, 25)
    p.trait(ROUGE, 7, arc(46, 146, 32, 212, 322))
    p.plein(gris, tube([(46, 146), (64, 92)], 8), tube([(154, 146), (118, 124)], 9))
    # Le moteur (ailettes), le pot d'échappement.
    p.plein(gris_fonce, rect(86, 110, 42, 32, r=9))
    p.trait(gris, 3, ligne((94, 119), (120, 119)), ligne((94, 127), (120, 127)), ligne((94, 135), (120, 135)))
    p.plein(JANTE, tube([(104, 138), (134, 124), (176, 120)], [8, 9, 10]))
    # Garde-boue arrière et coque sous la selle, réservoir, selle.
    p.plein(ROUGE, poly([(122, 98), (172, 96), (180, 108), (170, 116), (132, 114)], r=[3, 6, 5, 4, 3]))
    p.plein(ROUGE, lisse([(68, 94), (96, 84), (126, 92), (132, 108), (102, 114), (74, 110)]))
    p.plein("#FF7A80", ellipse(94, 93, 14, 4.5, rot=-8))
    p.plein(PNEU, rect(118, 86, 50, 13, r=6.5))
    # Guidon, phare.
    p.trait(PNEU, 5, ligne((64, 90), (78, 76)), ligne((78, 76), (86, 76)))
    p.plein(gris_fonce, cercle(58, 94, 10))
    p.plein(JAUNE, cercle(56, 94, 7))
    return _decale(p, 2)


def mouton() -> Picto:
    """Un mouton de profil (vers la gauche) : laine blanche en boules, tête et pattes sombres."""
    p = Picto("mot.mouton")
    sombre, sombre_loin, ombre_laine = "#4E4760", "#6E6682", "#E4E9F2"
    ombre(p, 108, 179, 58, 6)
    # Les pattes : les deux lointaines un peu plus claires.
    p.plein(sombre_loin, rect(84, 126, 11, 46, r=5), rect(134, 126, 11, 46, r=5))
    p.plein(sombre, rect(70, 128, 12, 44, r=5), rect(120, 128, 12, 44, r=5))
    # La laine : des boules sur une ellipse, un pompon de queue ; liseré puis blanc.
    laine = [ellipse(114, 108, 48, 28)]
    for k in range(11):
        a = math.radians(-90 + k * 360 / 11)
        laine.append(cercle(114 + 46 * math.cos(a), 108 + 27 * math.sin(a), 16))
    laine.append(cercle(164, 100, 10))
    p.trait(LISERE, 5, *laine)
    p.plein(BLANC, *laine)
    p.plein(ombre_laine, *[decoupe(f, ellipse(114, 158, 76, 38)) for f in laine])
    p.trait("#D5DDE9", 3, arc(100, 100, 7, 200, 340), arc(128, 94, 7, 200, 340), arc(116, 118, 6, 200, 340),
            arc(146, 110, 6, 200, 340), arc(84, 116, 6, 200, 340))
    # La tête sombre, l'oreille, la houppette de laine.
    p.plein(sombre, ellipse(80, 84, 13, 6, rot=28))
    p.plein("#F2A7B8", ellipse(80, 84, 7, 2.8, rot=28))
    p.plein(sombre, ellipse(56, 102, 19, 24, rot=22))
    houppe = [cercle(52, 80, 9), cercle(62, 77, 9.5), cercle(70, 84, 8)]
    p.trait(LISERE, 4, *houppe)
    p.plein(BLANC, *houppe)
    # Visage : blanc de l'œil, museau, joue.
    oeil_clair(p, 50, 98, 4.6)
    p.trait("#8C84A0", 2.2, courbe([(38, 116), (42, 119), (47, 117)]))
    joue(p, 60, 112, 4.2)
    return _decale(p, -6)


def plume() -> Picto:
    """Une plume légère et colorée, en diagonale : barbes bleues, pointe violette, duvet clair."""
    p = Picto("mot.plume")
    bleu, violet, duvet, tige, calamus = "#5CC8E8", "#8E7CF0", "#BDEBF7", "#F6EAD2", "#CDB182"
    ombre(p, 104, 179, 40, 5)
    q0, q1, q2 = (54, 172), (74, 100), (152, 30)

    def axe(s: float) -> Point:
        u = 1 - s
        return (u * u * q0[0] + 2 * u * s * q1[0] + s * s * q2[0], u * u * q0[1] + 2 * u * s * q1[1] + s * s * q2[1])

    def normale(s: float) -> Point:
        tx = 2 * (1 - s) * (q1[0] - q0[0]) + 2 * s * (q2[0] - q1[0])
        ty = 2 * (1 - s) * (q1[1] - q0[1]) + 2 * s * (q2[1] - q1[1])
        ln = math.hypot(tx, ty)
        return (-ty / ln, tx / ln)

    def demi(s: float, encoche: float) -> float:
        if s <= 0.2 or s >= 1:
            return 0.0
        w = 26 * math.sin(math.pi * (s - 0.2) / 0.8) ** 0.7 * (1.08 - 0.32 * s)
        return w * (1 - 0.55 * max(0.0, 1 - abs(s - encoche) / 0.035))

    ss = [0.2 + 0.8 * k / 48 for k in range(49)]
    cote_a = [(axe(s)[0] + normale(s)[0] * demi(s, 0.62), axe(s)[1] + normale(s)[1] * demi(s, 0.62)) for s in ss]
    cote_b = [(axe(s)[0] - normale(s)[0] * demi(s, 0.44), axe(s)[1] - normale(s)[1] * demi(s, 0.44)) for s in ss]
    barbes = lisse(cote_a + cote_b[::-1][1:-1])
    p.plein(bleu, barbes)
    p.plein(violet, decoupe(barbes, cercle(*q2, 46)))
    p.plein(duvet, decoupe(barbes, cercle(*axe(0.2), 30)))
    p.plein(calamus, tube([axe(0.0), axe(0.1), axe(0.22)], [5.5, 5, 4.6]))
    p.plein(tige, tube([axe(s) for s in (0.2, 0.45, 0.7, 0.95)], [4.4, 3.6, 2.6, 1.4]))
    return p


def araignee() -> Picto:
    """Une petite araignée ronde et gentille au bout de son fil : huit pattes, grands yeux."""
    p = Picto("mot.araignee")
    corps_c, patte = "#7B5CC8", "#6A4DB5"
    ombre(p, 100, 179, 40, 5)
    p.trait("#A8B0C2", 2, ligne((100, 18), (100, 80)))
    pattes = [((84, 96), (56, 72), (36, 84)), ((82, 106), (48, 98), (28, 114)), ((82, 116), (48, 124), (34, 144)),
              ((86, 126), (60, 146), (50, 166))]
    for s in (1, -1):
        p.trait(patte, 7, *[courbe([(100 + s * (x - 100), y) for x, y in jambe]) for jambe in pattes])
    p.plein(corps_c, cercle(100, 112, 36))
    p.plein("#9A7FE0", ellipse(88, 92, 12, 7, rot=-25))
    oeil_clair(p, 87, 106, 7)
    oeil_clair(p, 113, 106, 7)
    joue(p, 78, 126, 6)
    joue(p, 122, 126, 6)
    p.trait(ENCRE, 2.8, courbe([(92, 126), (100, 132), (108, 126)]))
    return p


def champignon() -> Picto:
    """Un champignon au chapeau rouge à pois blancs, pied crème."""
    p = Picto("mot.champignon")
    pied_c, pied_fonce, lamelles = "#F7E6CC", "#E5CBA5", "#EBD3B0"
    ombre(p, 100, 178, 50, 6)
    pied = lisse([(84, 104), (116, 104), (122, 140), (126, 168), (100, 174), (74, 168), (78, 140)])
    p.trait(pied_fonce, 3, pied)
    p.plein(pied_c, pied)
    p.plein(pied_fonce, decoupe(pied, rect(110, 96, 30, 90)))
    p.plein(lamelles, ellipse(100, 104, 62, 12))
    chapeau = lisse([(24, 104), (32, 70), (62, 42), (100, 32), (138, 42), (168, 70), (176, 104), (140, 112),
                     (100, 114), (60, 112)])
    p.plein(ROUGE, chapeau)
    p.plein(BLANC, cercle(68, 66, 11), cercle(106, 50, 9), cercle(140, 72, 12), cercle(100, 90, 8),
            cercle(48, 94, 6.5), cercle(156, 96, 6))
    p.plein("#FFFFFF60", ellipse(62, 56, 12, 5, rot=-35))
    return p


def peigne() -> Picto:
    """Un peigne rose un peu penché, ses dents bien séparées."""
    p = Picto("mot.peigne")
    rose_, fonce, clair = "#FF7EB6", "#E65C9A", "#FFB8D8"
    ombre(p, 100, 176, 66, 6)

    def t(f):
        return tourne(f, -10, 100, 100)

    dents = [rect(32 + i * 13.2, 84, 8, 54, r=4) for i in range(11)]
    p.plein(fonce, *[deplace(t(f), 1.5, 3.5) for f in dents + [rect(24, 62, 152, 32, r=14)]])
    p.plein(rose_, *[t(f) for f in dents])
    p.plein(rose_, t(rect(24, 62, 152, 32, r=14)))
    p.plein(clair, t(rect(34, 69, 132, 6, r=3)))
    return p


PICTOS: list[Picto] = [
    dauphin(), coq(), canard(), cle(), camion(), crocodile(), cadeau(), sac(), zebre(), rose(),
    vase(), ciseaux(), nez(), un_nuage(), nid(), banane(), lune(), pomme(), pain(), papillon(),
    parapluie(), lapin(), soupe(), moto(), mouton(), plume(), araignee(), champignon(), peigne(),
]
