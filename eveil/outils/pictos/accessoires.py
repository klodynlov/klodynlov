"""Accessoires et signes des pictos de verbes : ballon, notes, Zzz, traits de vitesse, gouttes, bulles…

Tous dans le repère 200 × 200, sans contour noir. Les SIGNES (mouvement, son, sommeil,
parfum) sont en bleu-gris doux (`SIGNE`) ou dans la couleur de l'objet ; ils restent
épais (≥ 3,5) pour se lire quand le picto est affiché en 90 × 90 points.
"""
from __future__ import annotations

import math

from coloriages.dessin import (cercle, corde, courbe, ellipse, goutte, ligne, nuage, poly, rect, secteur,
                               tourne, tube)

from .peinture import Picto

SIGNE = "#8CAADC"          # bleu-gris doux des signes de mouvement
SIGNE_FONCE = "#6F8FCC"    # le même, un cran plus soutenu (notes, Z : petites formes pleines)
EAU = "#5DB4EE"
EAU_CLAIRE = "#A8D8F7"
MOUSSE = "#FFFFFF"
BULLE = "#D9EFFF"
BULLE_BORD = "#86C3EE"
NUAGE = "#E3ECF8"
NUAGE_OMBRE = "#CFDCEF"
BOIS = "#D39556"
BOIS_FONCE = "#A86B32"
BOIS_CLAIR = "#E8B77E"
CARTON = "#D9A066"
CARTON_FONCE = "#B97D45"
CARTON_CLAIR = "#EDC08E"


def _pt(o, angle, r):
    a = math.radians(angle)
    return (o[0] + math.cos(a) * r, o[1] + math.sin(a) * r)


# ---------------------------------------------------------------------------
# Signes
# ---------------------------------------------------------------------------

def traits(p: Picto, segments, couleur: str = SIGNE, largeur: float = 4.5) -> None:
    """Traits de mouvement : une liste de ((x0, y0), (x1, y1)) (bouts ronds)."""
    p.trait(couleur, largeur, *[ligne(a, b) for a, b in segments])


def vitesse(p: Picto, x: float, y: float, longueurs=(26, 34, 22), ecart: float = 13, sens: int = -1,
            couleur: str = SIGNE, largeur: float = 4.5) -> None:
    """Traits de vitesse horizontaux qui partent de (x, y) vers l'arrière (`sens` −1 = vers la gauche)."""
    n = len(longueurs)
    segs = []
    for i, lg in enumerate(longueurs):
        yy = y + (i - (n - 1) / 2) * ecart
        segs.append(((x, yy), (x + sens * lg, yy)))
    traits(p, segs, couleur, largeur)


def zzz(p: Picto, x: float, y: float, s: float, couleur: str = SIGNE_FONCE, largeur: float = 3.6) -> None:
    """Un « Z » de sommeil, coin haut gauche en (x, y), de côté `s` (le seul texte permis)."""
    p.trait(couleur, largeur, ligne((x, y), (x + s, y), (x, y + s), (x + s, y + s)))


def note(p: Picto, x: float, y: float, s: float, couleur: str = SIGNE_FONCE, double: bool = False,
         angle: float = 0.0) -> None:
    """Une note de musique dessinée (croche, ou deux croches liées si `double`) ; (x, y) = tête de note."""
    formes_pleines, formes_traits = [], []
    tetes = [(x, y)] + ([(x + s * 1.05, y - s * 0.22)] if double else [])
    for tx, ty in tetes:
        formes_pleines.append(ellipse(tx, ty, s * 0.44, s * 0.33, rot=-22))
        formes_traits.append(ligne((tx + s * 0.36, ty - s * 0.1), (tx + s * 0.36, ty - s * 1.25)))
    if double:
        (x0, y0), (x1, y1) = tetes
        a, b = (x0 + s * 0.36, y0 - s * 1.25), (x1 + s * 0.36, y1 - s * 1.25)
        formes_pleines.append(poly([(a[0] - s * 0.08, a[1] - s * 0.02), (b[0] + s * 0.08, b[1] - s * 0.02),
                                    (b[0] + s * 0.08, b[1] + s * 0.26), (a[0] - s * 0.08, a[1] + s * 0.26)],
                                   r=s * 0.06))
    else:
        top = (x + s * 0.36, y - s * 1.25)
        crochet = [top, (top[0] + s * 0.42, top[1] + s * 0.32), (top[0] + s * 0.36, top[1] + s * 0.72)]
        formes_traits.append(courbe(crochet))
    if angle:
        formes_pleines = [tourne(f, angle, x, y) for f in formes_pleines]
        formes_traits = [tourne(f, angle, x, y) for f in formes_traits]
    p.plein(couleur, *formes_pleines)
    p.trait(couleur, max(2.4, s * 0.16), *formes_traits)


def eclats(p: Picto, cx: float, cy: float, r0: float, r1: float, angles, couleur: str = "#F5A623",
           largeur: float = 4.0) -> None:
    """Petits traits qui rayonnent autour de (cx, cy) (joie, surprise) entre les rayons r0 et r1."""
    traits(p, [(_pt((cx, cy), a, r0), _pt((cx, cy), a, r1)) for a in angles], couleur, largeur)


def onde(p: Picto, depart, arrivee, amplitude: float = 4.0, bosses: int = 3, couleur: str = SIGNE,
         largeur: float = 3.6) -> None:
    """Un trait ondulé et doux de `depart` à `arrivee`, en `bosses` demi-vagues (parfum, vent, vapeur)."""
    (x0, y0), (x1, y1) = depart, arrivee
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln, dx / ln
    pts = [depart]
    for i in range(bosses):
        t = (i + 0.5) / bosses
        k = amplitude if i % 2 == 0 else -amplitude
        pts.append((x0 + dx * t + nx * k, y0 + dy * t + ny * k))
    pts.append(arrivee)
    p.trait(couleur, largeur, courbe(pts))


def fleche_arc(p: Picto, cx: float, cy: float, rx: float, ry: float, a0: float, a1: float,
               couleur: str = SIGNE, largeur: float = 5.0, pointe: float = 9.0) -> None:
    """Un arc d'ellipse (angles en degrés, 0 = droite, 90 = bas) terminé par une pointe de flèche en a1."""
    from coloriages.dessin import arc
    p.trait(couleur, largeur, arc(cx, cy, rx, a0, a1, ry))
    if pointe <= 0:
        return
    t = math.radians(a1)
    fin = (cx + rx * math.cos(t), cy + ry * math.sin(t))
    sens = 1 if a1 > a0 else -1
    tx, ty = -rx * math.sin(t) * sens, ry * math.cos(t) * sens
    ln = math.hypot(tx, ty)
    tx, ty = tx / ln, ty / ln
    nx, ny = -ty, tx
    bout = (fin[0] + tx * pointe, fin[1] + ty * pointe)
    g = (fin[0] - tx * pointe * 0.25 + nx * pointe * 0.8, fin[1] - ty * pointe * 0.25 + ny * pointe * 0.8)
    d = (fin[0] - tx * pointe * 0.25 - nx * pointe * 0.8, fin[1] - ty * pointe * 0.25 - ny * pointe * 0.8)
    p.plein(couleur, poly([bout, g, d], r=1.5))


# ---------------------------------------------------------------------------
# Eau, savon, air
# ---------------------------------------------------------------------------

def goutte_eau(p: Picto, x: float, y: float, r: float, angle: float = 0.0, couleur: str = EAU) -> None:
    """Une goutte (pointe en haut, ou tournée de `angle` degrés : éclaboussure)."""
    f = goutte(x, y, r, 2.3 * r)
    p.plein(couleur, tourne(f, angle, x, y) if angle else f)


def bulle(p: Picto, x: float, y: float, r: float) -> None:
    """Une bulle de savon : bleu très pâle, liseré bleu, reflet blanc."""
    p.plein(BULLE, cercle(x, y, r))
    p.trait(BULLE_BORD, max(1.6, r * 0.16), cercle(x, y, r))
    p.plein("#FFFFFF", ellipse(x - r * 0.38, y - r * 0.4, r * 0.28, r * 0.2, rot=-35))


def mousse(p: Picto, ronds, ombre: str = "#CFE6F8") -> None:
    """De la mousse (savon, écume) : des ronds blancs, soulignés d'une ombre bleu pâle ; ronds = [(x, y, r)]."""
    p.plein(ombre, *[cercle(x + r * 0.08, y + r * 0.22, r) for x, y, r in ronds])
    p.plein(MOUSSE, *[cercle(x, y, r) for x, y, r in ronds])


def petit_nuage(p: Picto, x: float, y: float, rx: float, ry: float | None = None) -> None:
    ry = rx * 0.55 if ry is None else ry
    p.plein(NUAGE_OMBRE, nuage(x + 1.5, y + 2.5, rx, ry, bosses=6, hauteur=0.75, depart=15))
    p.plein(NUAGE, nuage(x, y, rx, ry, bosses=6, hauteur=0.75, depart=15))


# ---------------------------------------------------------------------------
# Objets
# ---------------------------------------------------------------------------

def ballon(p: Picto, x: float, y: float, r: float) -> None:
    """Un ballon de plage à quartiers (rouge, jaune, bleu), reflet blanc."""
    couleurs = ["#FF5E5B", "#FFD23F", "#3FA7F5"] * 2
    for i, c in enumerate(couleurs):
        p.plein(c, secteur(x, y, r, -90 + i * 60, -30 + i * 60))
    p.plein("#FFFFFF", cercle(x, y, r * 0.22))
    p.plein("#FFFFFFB0", ellipse(x - r * 0.45, y - r * 0.5, r * 0.22, r * 0.14, rot=-40))


def fleur(p: Picto, x: float, y: float, r: float, petale: str = "#FF7EB6", coeur: str = "#FFD23F") -> None:
    """Une fleur à cinq pétales ronds (vue de face)."""
    p.plein(petale, *[cercle(*_pt((x, y), -90 + i * 72, r * 0.62), r * 0.5) for i in range(5)])
    p.plein(coeur, cercle(x, y, r * 0.42))


def caisse(p: Picto, x: float, y: float, w: float, h: float) -> None:
    """Une grosse caisse en bois : cadre foncé, planches, traverse en diagonale."""
    p.plein(BOIS_FONCE, rect(x, y, w, h, r=4))
    m = w * 0.13
    p.plein(BOIS, rect(x + m, y + m, w - 2 * m, h - 2 * m, r=2))
    p.plein(BOIS_FONCE, tube([(x + m * 1.2, y + h - m * 1.2), (x + w - m * 1.2, y + m * 1.2)], m * 0.95))
    p.plein(BOIS_CLAIR, rect(x + 2, y + 2, w - 4, m * 0.45, r=1.5))


def carton(p: Picto, x: float, y: float, w: float, h: float) -> None:
    """Un carton fermé : face kraft, ruban adhésif, rabat du dessus plus clair."""
    p.plein(CARTON, rect(x, y, w, h, r=3))
    p.plein(CARTON_CLAIR, rect(x, y, w, h * 0.2, r=3))
    p.plein(CARTON_FONCE, rect(x + w / 2 - w * 0.09, y, w * 0.18, h * 0.55, r=1.5))


def eponge(p: Picto, x: float, y: float, w: float, h: float, angle: float = 0.0) -> None:
    """Une éponge jaune à face verte (grattoir), trous plus foncés ; (x, y) = centre."""
    formes = [
        ("#FFD84D", rect(x - w / 2, y - h / 2 + h * 0.28, w, h * 0.72, r=h * 0.2)),
        ("#4CB963", rect(x - w / 2, y - h / 2, w, h * 0.34, r=h * 0.15)),
        ("#E8B92F", cercle(x - w * 0.25, y + h * 0.15, h * 0.09)),
        ("#E8B92F", cercle(x + w * 0.05, y + h * 0.3, h * 0.07)),
        ("#E8B92F", cercle(x + w * 0.3, y + h * 0.12, h * 0.08)),
    ]
    for c, f in formes:
        p.plein(c, tourne(f, angle, x, y) if angle else f)


def bol(p: Picto, x: float, y: float, r: float, couleur: str, contenu: str) -> None:
    """Un bol vu de trois quarts : contenu (ellipse) puis coque (demi-disque) ; (x, y) = milieu du bord."""
    p.plein(contenu, ellipse(x, y, r, r * 0.26))
    p.plein(couleur, corde(x, y, r, 0, 180, r * 0.82))


__all__ = ["BOIS", "CARTON", "EAU", "SIGNE", "SIGNE_FONCE", "ballon", "bol", "bulle", "caisse", "carton",
           "eclats", "eponge", "fleche_arc", "fleur", "goutte_eau", "mousse", "note", "onde", "petit_nuage",
           "traits", "vitesse", "zzz"]
