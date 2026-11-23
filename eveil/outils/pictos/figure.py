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

Réglages de `Pose` ajoutés pour les verbes (leurs valeurs par défaut redonnent le dessin
d'origine) : `taille` (échelle de tout le personnage autour de (x, sol), pour laisser de
la place à un objet), `vers` (visage de trois quarts, −1 gauche … +1 droite), `devant`
(bras peints PAR-DESSUS la tête : main à la bouche, sur le ventre), `pointes` (sur la
pointe des pieds), `nez` (un petit nez, pour sentir), yeux « plisses » (effort).

Aides : `atteindre` (angles d'un membre pour poser la main ou le pied sur un point),
`point_visage` (où sont la bouche, le nez… dans le repère du dessin), `main` (repeindre
une main par-dessus l'objet qu'elle tient), `langue` (repeindre la langue par-dessus une
glace), `tete` (la tête seule : Lou couché sous sa couverture, caché derrière un buisson).
"""
from __future__ import annotations

import math
from dataclasses import dataclass

from coloriages.dessin import cercle, courbe, echelle, ellipse, ligne, rect, tourne, tube

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
LANGUE = "#F58CA0"

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
    yeux: str = "ouverts"             # ouverts | fermes | rieurs | plisses
    bouche: str = "sourire"           # sourire | ouverte | rire | o | langue | fermee
    regard: tuple = (0.0, 0.0)        # décalage des reflets (on regarde un peu à gauche, à droite…)
    taille: float = 1.0               # échelle de tout le personnage autour de (x, sol)
    vers: float = 0.0                 # visage tourné : −1 (de trois quarts vers la gauche) … +1 (droite)
    devant: tuple = ()                # bras peints par-dessus la tête : ("bras_d",), ("bras_g", "bras_d")
    pointes: bool = False             # sur la pointe des pieds
    nez: bool = False                 # un petit nez (sentir une fleur)
    cou: float | None = None          # direction de la tête sur les épaules (degrés, défaut : 0,3 × tete)


def _pt(o: tuple[float, float], angle: float, longueur: float) -> tuple[float, float]:
    a = math.radians(angle)
    return (o[0] + math.cos(a) * longueur, o[1] + math.sin(a) * longueur)


def _articulations(pose: Pose) -> dict[str, tuple[float, float]]:
    """Les points clés à l'échelle 1 (avant `taille`)."""
    bassin = (pose.x, pose.sol - CUISSE - MOLLET)
    # Le buste part du bassin, penché de `penche` degrés depuis la verticale.
    haut = _pt(bassin, -90 + pose.penche, BUSTE_H)
    cou = _pt(haut, -90 + pose.penche, COU)
    tete = _pt(cou, -90 + pose.penche + (pose.tete * 0.3 if pose.cou is None else pose.cou), TETE_R - 2)
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


def articulations(pose: Pose) -> dict[str, tuple[float, float]]:
    """Les points clés du personnage (repère 200 × 200), `taille` comprise."""
    j = _articulations(pose)
    t = pose.taille
    if t == 1:
        return j
    return {k: (pose.x + (v[0] - pose.x) * t, pose.sol + (v[1] - pose.sol) * t) for k, v in j.items()}


class _Echelle:
    """Peint dans un picto en mettant chaque forme à l'échelle `t` autour de `centre`."""

    def __init__(self, p: Picto, t: float, centre: tuple[float, float]):
        self.p, self.t, self.c = p, t, centre

    def _f(self, formes):
        return [echelle(f, self.t, self.t, self.c[0], self.c[1]) for f in formes]

    def plein(self, couleur: str, *formes, calque: str = "fond"):
        self.p.plein(couleur, *self._f(formes), calque=calque)
        return self

    def trait(self, couleur: str, largeur: float, *formes, calque: str = "fond"):
        self.p.trait(couleur, largeur * self.t, *self._f(formes), calque=calque)
        return self


def _peintre(p: Picto, t: float, centre: tuple[float, float]):
    return p if t == 1 else _Echelle(p, t, centre)


def _bras(p: Picto, epaule, coude, main, manche: bool = True) -> None:
    p.plein(PEAU, tube([epaule, coude, main], MEMBRE))
    if manche:
        p.plein(TSHIRT, tube([epaule, _milieu(epaule, coude, 0.55)], MEMBRE + 5))
    p.plein(PEAU, cercle(main[0], main[1], MEMBRE * 0.62))


def _jambe(p: Picto, hanche, genou, pied, vers: float, pointes: bool = False) -> None:
    p.plein(PEAU, tube([hanche, genou, pied], JAMBE))
    p.plein(SHORT, tube([hanche, _milieu(hanche, genou, 0.62)], JAMBE + 5))
    if pointes:
        # Sur la pointe : la basket se dresse (vue de face : plus haute que large), le bout touche le sol.
        p.plein(BASKET, ellipse(pied[0] + 1.5 * vers, pied[1] + 4, 7.5, 10))
        p.plein(SEMELLE, ellipse(pied[0] + 1.5 * vers, pied[1] + 12.5, 5, 2.2))
        return
    # Basket : un ovale allongé dans le sens du pied (vers la droite ou la gauche).
    p.plein(BASKET, ellipse(pied[0] + 5 * vers, pied[1] + 2, 12, 7))
    p.plein(SEMELLE, rect(pied[0] + 5 * vers - 12, pied[1] + 5, 24, 3.5, r=1.7))


def _milieu(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def lou(p: Picto, pose: Pose, calque: str = "fond") -> dict:
    """Peint Lou dans `p` ; renvoie ses articulations (pour poser un objet dans sa main…)."""
    j = _articulations(pose)
    q = _peintre(p, pose.taille, (pose.x, pose.sol))
    devant = set(pose.devant)
    if "bras_g" not in devant:
        _bras(q, j["epaule_g"], j["coude_g"], j["main_g"])
    _jambe(q, j["hanche_g"], j["genou_g"], j["pied_g"], -1, pose.pointes)
    _jambe(q, j["hanche_d"], j["genou_d"], j["pied_d"], 1, pose.pointes)
    # Buste : un t-shirt arrondi, penché.
    b = j["bassin"]
    buste = tourne(rect(b[0] - BUSTE_L / 2, b[1] - BUSTE_H - 4, BUSTE_L, BUSTE_H + 10, r=13),
                   pose.penche, b[0], b[1])
    q.plein(TSHIRT, buste)
    q.plein(SHORT, tourne(rect(b[0] - BUSTE_L / 2 + 1, b[1] - 6, BUSTE_L - 2, 14, r=6), pose.penche, b[0], b[1]))
    if "bras_d" not in devant:
        _bras(q, j["epaule_d"], j["coude_d"], j["main_d"])
    _tete(q, j["tete"], pose)
    for cote in ("g", "d"):
        if f"bras_{cote}" in devant:
            _bras(q, j[f"epaule_{cote}"], j[f"coude_{cote}"], j[f"main_{cote}"])
    return articulations(pose)


def tete(p: Picto, centre: tuple[float, float], pose: Pose) -> None:
    """La tête seule de Lou (cheveux, visage), centrée sur `centre`, à l'échelle `pose.taille`."""
    _tete(_peintre(p, pose.taille, centre), centre, pose)


def main(p: Picto, point: tuple[float, float], pose: Pose | None = None) -> None:
    """Une main de Lou, repeinte PAR-DESSUS l'objet qu'elle tient (anse, manche, corde…)."""
    t = pose.taille if pose else 1.0
    p.plein(PEAU, cercle(point[0], point[1], MEMBRE * 0.62 * t))


def _decalages(vers: float):
    """Décalages horizontaux (repère du visage) des traits quand la tête est de trois quarts."""
    s = 6.0 * vers
    if s >= 0:
        return s, s * 0.6, s, s * 0.3, s * 0.9      # œil g, œil d, joue g, joue d, bouche
    return s * 0.6, s, s * 0.3, s, s * 0.9


def point_visage(pose: Pose, dx: float, dy: float, centre: tuple[float, float] | None = None):
    """Un point du visage, du repère de la tête (0, 0 = centre ; y vers le bas) au repère du dessin.

    Repères utiles : bouche `bouche(pose)`, nez (décalage, 6), yeux (±8,5, 1). `centre` : celui
    passé à `tete()` (sinon la tête de `lou()`). Tient compte de la tête penchée et de `taille`.
    """
    t = pose.taille
    if centre is None:
        c0 = _articulations(pose)["tete"]
        c = (pose.x + (c0[0] - pose.x) * t, pose.sol + (c0[1] - pose.sol) * t)
    else:
        c = centre
    a = math.radians(pose.penche + pose.tete)
    return (c[0] + t * (dx * math.cos(a) - dy * math.sin(a)), c[1] + t * (dx * math.sin(a) + dy * math.cos(a)))


def bouche(pose: Pose, centre: tuple[float, float] | None = None):
    """Le milieu de la bouche (pour une cuillère, une paille…)."""
    return point_visage(pose, _decalages(pose.vers)[4], 11, centre)


def langue(p: Picto, pose: Pose, centre: tuple[float, float] | None = None, longueur: float = 1.0,
           angle: float = 90.0) -> None:
    """Une langue tirée depuis la bouche, peinte par-dessus un objet (elle touche la glace).

    `angle` : direction de la langue (degrés, 90 = vers le bas comme la bouche « langue ») ;
    `longueur` : 1 = la langue de la bouche « langue ».
    """
    b = bouche(pose, centre)
    t = pose.taille
    demi = 4.5 * t * longueur
    ux, uy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    c = (b[0] + ux * (demi - 0.5 * t), b[1] + uy * (demi - 0.5 * t))
    p.plein(LANGUE, ellipse(c[0], c[1], demi, 4 * t, rot=angle))


def atteindre(pose: Pose, membre: str, cible: tuple[float, float], pli: int = 1) -> tuple[float, float]:
    """Angles (degrés) de `membre` (« bras_g », « jambe_d »…) pour que la main ou le pied touche `cible`.

    `pli` = +1 ou −1 : de quel côté le coude (le genou) se plie. Si la cible est trop loin,
    le membre se tend vers elle. `taille` comprise.
    """
    j = articulations(pose)
    genre, cote = membre.split("_")
    o = j[("epaule_" if genre == "bras" else "hanche_") + cote]
    t = pose.taille
    a, b = ((BRAS, AVANT_BRAS) if genre == "bras" else (CUISSE, MOLLET))
    a, b = a * t, b * t
    dx, dy = cible[0] - o[0], cible[1] - o[1]
    d = min(max(math.hypot(dx, dy), abs(a - b) + 1e-6), a + b - 1e-6)
    theta = math.atan2(dy, dx)
    alpha = math.acos((a * a + d * d - b * b) / (2 * a * d))
    c1 = theta + pli * alpha
    coude = (o[0] + a * math.cos(c1), o[1] + a * math.sin(c1))
    fin = (o[0] + d * math.cos(theta), o[1] + d * math.sin(theta))
    c2 = math.atan2(fin[1] - coude[1], fin[0] - coude[0])
    return (math.degrees(c1), math.degrees(c2))


def _tete(p: Picto, c: tuple[float, float], pose: Pose) -> None:
    x, y = c
    a = pose.penche + pose.tete
    eg, ed, jg_, jd_, sb = _decalages(pose.vers)

    def rt(q):
        ang = math.radians(a)
        dx, dy = q[0] - x, q[1] - y
        return (x + dx * math.cos(ang) - dy * math.sin(ang), y + dx * math.sin(ang) + dy * math.cos(ang))

    # Cheveux derrière (boucles), oreilles, visage, puis la frange de boucles.
    boucles = [cercle(x + 22 * math.cos(math.radians(t)), y - 4 + 20 * math.sin(math.radians(t)), 9)
               for t in range(160, 385, 25)]
    for f in boucles:
        p.plein(CHEVEUX, tourne(f, a, x, y))
    # Oreilles (tournées avec la tête) ; de trois quarts, celle du côté regardé passe derrière.
    og_, od_ = rt((x - TETE_R + 2, y + 2)), rt((x + TETE_R - 2, y + 2))
    oreilles = [cercle(og_[0], og_[1], 5.5)] if pose.vers <= 0.25 else []
    oreilles += [cercle(od_[0], od_[1], 5.5)] if pose.vers >= -0.25 else []
    p.plein(PEAU, *oreilles)
    p.plein(PEAU, cercle(x, y, TETE_R - 2))
    frange = [cercle(x + dx, y - 17 + abs(dx) * 0.18, 7.5) for dx in (-15, -5, 5, 15)]
    for f in frange:
        p.plein(CHEVEUX, tourne(f, a, x, y))
    # Visage (tourné avec la tête).
    og, od = rt((x - 8.5 + eg, y + 1)), rt((x + 8.5 + ed, y + 1))
    if pose.yeux == "plisses":
        # Effort : deux chevrons « > < » serrés, tournés avec la tête.
        for (ex, ey), sens in ((og, 1), (od, -1)):
            pts = [(ex - sens * 3.6, ey - 3.2), (ex + sens * 2.8, ey), (ex - sens * 3.6, ey + 3.2)]
            p.trait(ENCRE, 1.9, ligne(*[_rt(px, py, ex, ey, a) for px, py in pts]))
    else:
        ferme, rieur = pose.yeux == "fermes", pose.yeux == "rieurs"
        oeil(p, og[0], og[1], 4.2, ferme=ferme, rieur=rieur, regard=pose.regard)
        oeil(p, od[0], od[1], 4.2, ferme=ferme, rieur=rieur, regard=pose.regard)
    jg, jd = rt((x - 14 + jg_, y + 8)), rt((x + 14 + jd_, y + 8))
    joue(p, jg[0], jg[1], 4)
    joue(p, jd[0], jd[1], 4)
    if pose.nez:
        n = rt((x + sb * 1.05, y + 5.5))
        p.plein(PEAU_OMBRE, ellipse(n[0], n[1], 3, 2.3))
    b = rt((x + sb, y + 11))
    if pose.bouche == "sourire":
        p.trait(ENCRE, 2.2, courbe([rt((x - 5 + sb, y + 10)), rt((x + sb, y + 13.5)), rt((x + 5 + sb, y + 10))]))
    elif pose.bouche == "fermee":
        p.trait(ENCRE, 2.0, courbe([rt((x - 3.5 + sb, y + 11.5)), rt((x + 3.5 + sb, y + 11.5))]))
    elif pose.bouche == "o":
        p.plein(BOUCHE, ellipse(b[0], b[1] + 1, 3.5, 4.2))
    elif pose.bouche == "langue":
        p.plein(BOUCHE, ellipse(b[0], b[1], 5, 4))
        p.plein(LANGUE, ellipse(b[0], b[1] + 4, 4, 4.5))
    else:   # ouverte, rire
        h = 6.5 if pose.bouche == "rire" else 5.5
        p.plein(BOUCHE, tourne(courbe_fermee(b[0], b[1] - 1.5, 6.5, h), a, b[0], b[1]))


def _rt(px: float, py: float, cx: float, cy: float, deg: float):
    """Tourne le point (px, py) de `deg` degrés autour de (cx, cy)."""
    ang = math.radians(deg)
    dx, dy = px - cx, py - cy
    return (cx + dx * math.cos(ang) - dy * math.sin(ang), cy + dx * math.sin(ang) + dy * math.cos(ang))


def courbe_fermee(cx: float, cy: float, demi_l: float, h: float):
    """Bouche ouverte en « D » couché : haut plat, bas arrondi."""
    from coloriages.dessin import Contour, K
    return [Contour((cx - demi_l, cy), [
        ("L", (cx + demi_l, cy)),
        ("C", (cx + demi_l, cy + h * K * 1.2), (cx + demi_l * K, cy + h), (cx, cy + h)),
        ("C", (cx - demi_l * K, cy + h), (cx - demi_l, cy + h * K * 1.2), (cx - demi_l, cy)),
    ])]


__all__ = ["BASKET", "CHEVEUX", "LANGUE", "PEAU", "PEAU_OMBRE", "Pose", "SHORT", "TSHIRT", "articulations",
           "atteindre", "bouche", "langue", "lou", "main", "point_visage", "tete"]
