"""Le petit personnage des verbes : Lou, un enfant d'environ 4 ans, en couleur.

Un seul personnage pour tous les verbes (on reconnaît l'ACTION, pas la personne) :
tête ronde, cheveux bouclés foncés, peau brune dorée, t-shirt jaune, short bleu,
baskets rouges. Il est posé par des ANGLES (degrés, 0 = vers la droite, 90 = vers le
bas, sens de l'écran) : `Pose` → une liste de formes peintes dans l'ordre (bras et
jambe de derrière, corps, jambe et bras de devant, tête).

    p = Picto("verbe.saute")
    lou(p, Pose(x=100, sol=150, bras_g=(-120, -20), bras_d=(-60, 20), jambe_g=(110, 30), jambe_d=(70, -30)))

Membres : `bras_*` = (épaule → coude, coude → main), `jambe_*` = (hanche → genou,
genou → pied) ; « g » = côté gauche de l'image, « d » = côté droit.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

from coloriages.dessin import cercle, courbe, ellipse, rect, tourne, tube

from .peinture import ENCRE, Picto, joue, oeil

PEAU = "#B8784E"
PEAU_OMBRE = "#9C6440"
CHEVEUX = "#2B1D16"
TSHIRT = "#FFC83D"
TSHIRT_OMBRE = "#E8A91F"
SHORT = "#3E7BD6"
BASKET = "#E8414B"
SEMELLE = "#FFFFFF"
BOUCHE = "#8C2F45"

# Proportions (repère 200 × 200, personnage debout de 150 environ).
TETE_R = 25
COU = 8
BUSTE_H = 40
BUSTE_L = 38
CUISSE = 26
MOLLET = 24
BRAS = 22
AVANT_BRAS = 20
MEMBRE = 12        # épaisseur des bras
JAMBE = 14         # épaisseur des jambes


@dataclass
class Pose:
    x: float = 100.0                  # milieu du bassin (x)
    sol: float = 176.0                # y des pieds quand les jambes sont droites (saut : plus haut)
    penche: float = 0.0               # buste penché (degrés, + = vers la droite)
    bras_g: tuple = (110.0, 95.0)     # bras au repos, le long du corps
    bras_d: tuple = (70.0, 85.0)
    jambe_g: tuple = (95.0, 90.0)
    jambe_d: tuple = (85.0, 90.0)
    tete: float = 0.0                 # tête penchée (degrés)
    yeux: str = "ouverts"             # ouverts | fermes | rieurs
    bouche: str = "sourire"           # sourire | ouverte | rire | o | langue | fermee
    regard: tuple = (0.0, 0.0)        # décalage des reflets (on regarde un peu à gauche, à droite…)


def _pt(o: tuple[float, float], angle: float, longueur: float) -> tuple[float, float]:
    a = math.radians(angle)
    return (o[0] + math.cos(a) * longueur, o[1] + math.sin(a) * longueur)


def articulations(pose: Pose) -> dict[str, tuple[float, float]]:
    """Les points clés du personnage (repère 200 × 200)."""
    bassin = (pose.x, pose.sol - CUISSE - MOLLET)
    # Le buste part du bassin, penché de `penche` degrés depuis la verticale.
    haut = _pt(bassin, -90 + pose.penche, BUSTE_H)
    cou = _pt(haut, -90 + pose.penche, COU)
    tete = _pt(cou, -90 + pose.penche + pose.tete * 0.3, TETE_R - 2)
    dx, dy = math.cos(math.radians(pose.penche)), math.sin(math.radians(pose.penche))
    ep_g = (haut[0] - dx * (BUSTE_L / 2 - 4), haut[1] - dy * (BUSTE_L / 2 - 4) + 4)
    ep_d = (haut[0] + dx * (BUSTE_L / 2 - 4), haut[1] + dy * (BUSTE_L / 2 - 4) + 4)
    ha_g = (bassin[0] - 8, bassin[1])
    ha_d = (bassin[0] + 8, bassin[1])
    coude_g = _pt(ep_g, pose.bras_g[0], BRAS)
    main_g = _pt(coude_g, pose.bras_g[1], AVANT_BRAS)
    coude_d = _pt(ep_d, pose.bras_d[0], BRAS)
    main_d = _pt(coude_d, pose.bras_d[1], AVANT_BRAS)
    genou_g = _pt(ha_g, pose.jambe_g[0], CUISSE)
    pied_g = _pt(genou_g, pose.jambe_g[1], MOLLET)
    genou_d = _pt(ha_d, pose.jambe_d[0], CUISSE)
    pied_d = _pt(genou_d, pose.jambe_d[1], MOLLET)
    return dict(bassin=bassin, haut=haut, cou=cou, tete=tete, epaule_g=ep_g, epaule_d=ep_d, hanche_g=ha_g,
                hanche_d=ha_d, coude_g=coude_g, main_g=main_g, coude_d=coude_d, main_d=main_d, genou_g=genou_g,
                pied_g=pied_g, genou_d=genou_d, pied_d=pied_d)


def _bras(p: Picto, epaule, coude, main, manche: bool = True) -> None:
    p.plein(PEAU, tube([epaule, coude, main], MEMBRE))
    if manche:
        p.plein(TSHIRT, tube([epaule, _milieu(epaule, coude, 0.55)], MEMBRE + 5))
    p.plein(PEAU, cercle(main[0], main[1], MEMBRE * 0.62))


def _jambe(p: Picto, hanche, genou, pied, vers: float) -> None:
    p.plein(PEAU, tube([hanche, genou, pied], JAMBE))
    p.plein(SHORT, tube([hanche, _milieu(hanche, genou, 0.62)], JAMBE + 5))
    # Basket : un ovale allongé dans le sens du pied (vers la droite ou la gauche).
    p.plein(BASKET, ellipse(pied[0] + 5 * vers, pied[1] + 2, 12, 7))
    p.plein(SEMELLE, rect(pied[0] + 5 * vers - 12, pied[1] + 5, 24, 3.5, r=1.7))


def _milieu(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def lou(p: Picto, pose: Pose, calque: str = "fond") -> dict:
    """Peint Lou dans `p` ; renvoie ses articulations (pour poser un objet dans sa main…)."""
    j = articulations(pose)
    _bras(p, j["epaule_g"], j["coude_g"], j["main_g"])
    _jambe(p, j["hanche_g"], j["genou_g"], j["pied_g"], -1)
    _jambe(p, j["hanche_d"], j["genou_d"], j["pied_d"], 1)
    # Buste : un t-shirt arrondi, penché.
    b, h = j["bassin"], j["haut"]
    buste = tourne(rect(b[0] - BUSTE_L / 2, b[1] - BUSTE_H - 4, BUSTE_L, BUSTE_H + 10, r=13),
                   pose.penche, b[0], b[1])
    p.plein(TSHIRT, buste)
    p.plein(SHORT, tourne(rect(b[0] - BUSTE_L / 2 + 1, b[1] - 6, BUSTE_L - 2, 14, r=6), pose.penche, b[0], b[1]))
    _bras(p, j["epaule_d"], j["coude_d"], j["main_d"])
    _tete(p, j["tete"], pose)
    return j


def _tete(p: Picto, c: tuple[float, float], pose: Pose) -> None:
    x, y = c
    a = pose.penche + pose.tete
    # Cheveux derrière (boucles), visage, oreilles, puis la frange de boucles.
    boucles = [cercle(x + 22 * math.cos(math.radians(t)), y - 4 + 20 * math.sin(math.radians(t)), 9)
               for t in range(160, 385, 25)]
    for f in boucles:
        p.plein(CHEVEUX, tourne(f, a, x, y))
    p.plein(PEAU, cercle(x - TETE_R + 2, y + 2, 5.5), cercle(x + TETE_R - 2, y + 2, 5.5))
    p.plein(PEAU, cercle(x, y, TETE_R - 2))
    frange = [cercle(x + dx, y - 17 + abs(dx) * 0.18, 7.5) for dx in (-15, -5, 5, 15)]
    for f in frange:
        p.plein(CHEVEUX, tourne(f, a, x, y))
    # Visage (tourné avec la tête).
    def rt(q):
        ang = math.radians(a)
        dx, dy = q[0] - x, q[1] - y
        return (x + dx * math.cos(ang) - dy * math.sin(ang), y + dx * math.sin(ang) + dy * math.cos(ang))
    og, od = rt((x - 8.5, y + 1)), rt((x + 8.5, y + 1))
    ferme, rieur = pose.yeux == "fermes", pose.yeux == "rieurs"
    oeil(p, og[0], og[1], 4.2, ferme=ferme, rieur=rieur, regard=pose.regard)
    oeil(p, od[0], od[1], 4.2, ferme=ferme, rieur=rieur, regard=pose.regard)
    jg, jd = rt((x - 14, y + 8)), rt((x + 14, y + 8))
    joue(p, jg[0], jg[1], 4)
    joue(p, jd[0], jd[1], 4)
    b = rt((x, y + 11))
    if pose.bouche == "sourire":
        p.trait(ENCRE, 2.2, courbe([rt((x - 5, y + 10)), rt((x, y + 13.5)), rt((x + 5, y + 10))]))
    elif pose.bouche == "fermee":
        p.trait(ENCRE, 2.0, courbe([rt((x - 3.5, y + 11.5)), rt((x + 3.5, y + 11.5))]))
    elif pose.bouche == "o":
        p.plein(BOUCHE, ellipse(b[0], b[1] + 1, 3.5, 4.2))
    elif pose.bouche == "langue":
        p.plein(BOUCHE, ellipse(b[0], b[1], 5, 4))
        p.plein("#F58CA0", ellipse(b[0], b[1] + 4, 4, 4.5))
    else:   # ouverte, rire
        h = 6.5 if pose.bouche == "rire" else 5.5
        p.plein(BOUCHE, tourne(courbe_fermee(b[0], b[1] - 1.5, 6.5, h), a, b[0], b[1]))


def courbe_fermee(cx: float, cy: float, demi_l: float, h: float):
    """Bouche ouverte en « D » couché : haut plat, bas arrondi."""
    from coloriages.dessin import Contour, K
    return [Contour((cx - demi_l, cy), [
        ("L", (cx + demi_l, cy)),
        ("C", (cx + demi_l, cy + h * K * 1.2), (cx + demi_l * K, cy + h), (cx, cy + h)),
        ("C", (cx - demi_l * K, cy + h), (cx - demi_l, cy + h * K * 1.2), (cx - demi_l, cy)),
    ])]


__all__ = ["BASKET", "CHEVEUX", "PEAU", "Pose", "SHORT", "TSHIRT", "articulations", "lou"]
