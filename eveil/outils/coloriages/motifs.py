"""Motifs communs aux pages : sol, soleil, nuages, roues, yeux, fleurs, feuilles…

Chaque motif renvoie une liste d'éléments, du fond vers l'avant. Les yeux ont une
pupille d'ENCRE (pas une zone de plus à colorier) ; les petites zones voulues sont
des DÉTAILS.
"""
from __future__ import annotations

import math

from .dessin import (
    Contour, Element, arc, cercle, courbe, detail, ellipse, encre, goutte, ligne, miroir, poly, rect,
    trait, zone,
)


def sol(y: float = 800, vague: float = 16, bosses: int = 4) -> Element:
    """Prairie jusqu'en bas, bord supérieur doucement ondulé."""
    top = [(1000 * i / bosses, y + (vague if i % 2 else -vague)) for i in range(bosses + 1)]
    c = courbe(top)[0]
    return zone([Contour(c.start, c.segs + [("L", (1000, 1000)), ("L", (0, 1000))])])


def vagues(y: float, amp: float = 16, n: int = 10) -> Element:
    """Mer jusqu'en bas, crête en vaguelettes."""
    top = [(1000 * i / n, y + (amp if i % 2 else -amp)) for i in range(n + 1)]
    c = courbe(top)[0]
    return zone([Contour(c.start, c.segs + [("L", (1000, 1000)), ("L", (0, 1000))])])


def bande_sol(y: float) -> Element:
    """Sol plat (table, carrelage, route) de y jusqu'en bas."""
    return zone(rect(0, y, 1000, 1000 - y))


def soleil(cx: float, cy: float, r: float, rayons: int = 10, visage: bool = True) -> list:
    tris = []
    for i in range(rayons):
        a = math.radians(360 * i / rayons - 90)
        da = math.radians(180 / rayons * 0.55)
        base1 = (cx + 0.92 * r * math.cos(a - da), cy + 0.92 * r * math.sin(a - da))
        base2 = (cx + 0.92 * r * math.cos(a + da), cy + 0.92 * r * math.sin(a + da))
        tip = (cx + 1.55 * r * math.cos(a), cy + 1.55 * r * math.sin(a))
        tris += poly([base1, tip, base2], r=[0, r * 0.12, 0])
    els = [detail(tris), zone(cercle(cx, cy, r))]
    if visage:
        els.append(trait(arc(cx - 0.35 * r, cy - 0.1 * r, 0.16 * r, 200, 340),
                         arc(cx + 0.35 * r, cy - 0.1 * r, 0.16 * r, 200, 340),
                         arc(cx, cy + 0.05 * r, 0.42 * r, 25, 155)))
    return els


def nuage(cx: float, cy: float, rx: float, ry: float, bosses: int = 7, hauteur: float = 0.8) -> Element:
    from .dessin import nuage as _nuage
    return zone(_nuage(cx, cy, rx, ry, bosses=bosses, hauteur=hauteur))


def roue(cx: float, cy: float, r: float, rayons: int = 0, moyeu: float = 0.2) -> list:
    """Roue : pneu d'une zone, rayons (traits qui ne ferment rien), moyeu d'encre."""
    els = [zone(cercle(cx, cy, r))]
    if rayons:
        spokes = [ligne((cx + (moyeu + 0.14) * r * math.cos(a), cy + (moyeu + 0.14) * r * math.sin(a)),
                        (cx + 0.72 * r * math.cos(a), cy + 0.72 * r * math.sin(a)))
                  for a in (2 * math.pi * (i + 0.5) / rayons for i in range(rayons))]
        els.append(trait(*spokes))
    els.append(encre(cercle(cx, cy, moyeu * r)))
    return els


def oeil(cx: float, cy: float, r: float, dx: float = 0.0, dy: float = 0.0, p: float = 0.5,
         ry: float | None = None, grand: bool = False) -> list:
    """Œil : un blanc (détail, ou zone s'il est grand) et une pupille d'encre avec son reflet."""
    ry = r if ry is None else ry
    blanc = (zone if grand else detail)(ellipse(cx, cy, r, ry))
    px, py = cx + dx, cy + dy
    return [blanc, encre(ellipse(px, py, p * r, p * ry))]


def yeux_fermes(cx: float, cy: float, r: float) -> Element:
    """Œil fermé, content (arc)."""
    return trait(arc(cx, cy + 0.3 * r, r, 200, 340))


def sourire(cx: float, cy: float, r: float, a0: float = 25, a1: float = 155) -> Element:
    return trait(arc(cx, cy, r, a0, a1))


def fleur(cx: float, cy: float, r: float, petales: int = 6, tige: float = 0.0) -> list:
    """Fleur : une corolle festonnée d'un seul contour (comme `flower` dans l'app) et son cœur.

    Petite fleur de décor (r < 55) : corolle et cœur sont des détails voulus.
    """
    from .dessin import nuage as _nuage
    els = []
    if tige:
        els.append(zone(rect(cx - 0.13 * r, cy, 0.26 * r, tige, r=0.1 * r)))
    corolle = _nuage(cx, cy, 0.74 * r, 0.74 * r, bosses=petales, hauteur=1.0)
    els.append((zone if r >= 55 else detail)(corolle))
    els.append(detail(cercle(cx, cy, 0.36 * r)))
    return els


def fleur_petales(cx: float, cy: float, r: float, petales: int = 5) -> list:
    """Grande fleur à pétales séparés (ellipses), cœur par-dessus."""
    pet = []
    for i in range(petales):
        a = 360 * i / petales - 90
        rad = math.radians(a)
        pet += ellipse(cx + 0.95 * r * math.cos(rad), cy + 0.95 * r * math.sin(rad), 0.55 * r,
                       0.95 * r * math.sin(math.pi / petales) * 0.8, rot=a)
    return [zone(pet), zone(cercle(cx, cy, 0.52 * r))]


def feuille(a: tuple, b: tuple, w: float) -> list:
    """Feuille en amande, pointue aux deux bouts, de a à b, largeur w."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln * w * 0.66, dx / ln * w * 0.66
    c = Contour(a, [
        ("C", (a[0] + dx * 0.25 + nx, a[1] + dy * 0.25 + ny), (a[0] + dx * 0.75 + nx, a[1] + dy * 0.75 + ny), b),
        ("C", (a[0] + dx * 0.75 - nx, a[1] + dy * 0.75 - ny), (a[0] + dx * 0.25 - nx, a[1] + dy * 0.25 - ny), a),
    ])
    return [c if c.area() > 0 else c.reversed()]


def refleter(els: list, x: float) -> list:
    """Éléments retournés gauche-droite autour de la verticale x."""
    return [Element(e.genre, miroir(e.contours, x)) for e in els]


def groupe(els: list, f) -> list:
    """Applique une transformation de formes (ex. `lambda c: tourne(c, 20)`) à des éléments."""
    return [Element(e.genre, f(e.contours)) for e in els]


def oiseau(x: float, y: float, s: float = 1.0) -> list:
    """Oiseau lointain en « v » arrondi (deux arcs)."""
    return [arc(x - 22 * s, y, 22 * s, 200, 340)[0], arc(x + 22 * s, y, 22 * s, 200, 340)[0]]


def herbe(pts: list[tuple[float, float]]) -> Element:
    """Touffes d'herbe (petits « v » ouverts)."""
    out = []
    for x, y in pts:
        out += ligne((x - 22, y - 28), (x - 6, y), (x, y - 34), (x + 6, y), (x + 22, y - 28))
    return trait(out)


def sapin(x: float, y: float, h: float) -> list:
    """Sapin à trois étages ; (x, y) = pied du tronc. Le tronc se voit bien entre sol et branches."""
    w = 0.62 * h
    return [
        zone(rect(x - 0.08 * h, y - 0.3 * h, 0.16 * h, 0.3 * h)),
        zone(poly([(x - w / 2, y - 0.26 * h), (x + w / 2, y - 0.26 * h), (x, y - 0.66 * h)], r=[10, 10, 8])),
        zone(poly([(x - w * 0.4, y - 0.48 * h), (x + w * 0.4, y - 0.48 * h), (x, y - 0.84 * h)], r=[10, 10, 8])),
        zone(poly([(x - w * 0.3, y - 0.68 * h), (x + w * 0.3, y - 0.68 * h), (x, y - h)], r=[8, 8, 8])),
    ]


def arbre(x: float, y: float, h: float, largeur: float | None = None) -> list:
    """Arbre rond : tronc et feuillage d'un seul contour."""
    from .dessin import nuage as _nuage
    w = largeur or 0.7 * h
    return [
        zone(poly([(x - 0.07 * h, y), (x - 0.05 * h, y - 0.45 * h), (x + 0.05 * h, y - 0.45 * h), (x + 0.07 * h, y)],
                  r=[4, 0, 0, 4])),
        zone(_nuage(x, y - 0.66 * h, w / 2, 0.3 * h, bosses=8, hauteur=0.7)),
    ]


def goutte_eau(cx: float, cy: float, r: float) -> list:
    return goutte(cx, cy, r)


def spirale(cx: float, cy: float, r0: float, r1: float, tours: float, pas: int = 14) -> list:
    n = int(tours * pas)
    pts = [(cx + (r0 + (r1 - r0) * i / n) * math.cos(2 * math.pi * tours * i / n),
            cy + (r0 + (r1 - r0) * i / n) * math.sin(2 * math.pi * tours * i / n)) for i in range(n + 1)]
    return courbe(pts)


def etoiles_scintillantes(pts: list[tuple[float, float, float]]) -> Element:
    """Petites étincelles (quatre traits en croix) : ne ferment rien."""
    out = []
    for x, y, s in pts:
        out += ligne((x - s, y), (x + s, y)) + ligne((x, y - s), (x, y + s))
    return trait(out)

