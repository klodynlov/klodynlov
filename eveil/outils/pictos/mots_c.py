"""Les pictos des MOTS des livres des sons (lot C) : un nom par picto (`mot.<id>`).

Demande de l'utilisateur (06/10/2026), d'après le conseil d'une orthophoniste : commencer le
petit train par des mots d'une syllabe « comme mur, vert », sans se limiter aux fins en « ch »
et « s ». Même style que les lots A et B (formes pleines et arrondies, pas de contour noir,
ombre douce au sol). Liste des mots : `eveil/outils/livres/mots.py`.

Lot C (2 mots) : mur, vert.

Repère : carré 200 × 200, y vers le bas ; le sujet tient dans 16…184, ombre au sol vers y ≈ 179.
"""
from __future__ import annotations

from coloriages.dessin import cercle, ellipse, goutte, lisse, poly, rect

from .peinture import Picto, ombre

BRIQUE = "#E2724A"
BRIQUE_CLAIRE = "#EE8D63"
BRIQUE_FONCEE = "#C65A36"
JOINT = "#F4E3CF"
HERBE = "#4CB963"
HERBE_FONCEE = "#3A9A50"
VERT = "#3DBB5C"
VERT_CLAIR = "#7AD98F"
VERT_FONCE = "#2A9446"
METAL = "#BAC5D4"
METAL_FONCE = "#98A5B9"


def mur() -> Picto:
    """Un petit mur de briques, rangs décalés, joints clairs, touffes d'herbe au pied."""
    p = Picto("mot.mur")
    ombre(p, 100, 178, 78, 6)
    x0, x1, y0, y1 = 24, 176, 54, 172
    # Le mortier (le fond du mur), puis les briques rang par rang, décalées d'une demi-brique.
    p.plein(JOINT, rect(x0, y0, x1 - x0, y1 - y0, r=4))
    rangs, larg, joint = 5, 38, 4
    haut = (y1 - y0 - joint * (rangs + 1)) / rangs
    for k in range(rangs):
        y = y0 + joint + k * (haut + joint)
        x = x0 + joint - (larg / 2 if k % 2 else 0)
        n = 0
        while x < x1 - joint:
            a, b = max(x, x0 + joint), min(x + larg, x1 - joint)
            if b - a > 6:
                teinte = (BRIQUE, BRIQUE_CLAIRE, BRIQUE_FONCEE)[(k * 2 + n) % 3]
                p.plein(teinte, rect(a, y, b - a, haut, r=2.5))
                p.plein("#FFFFFF33", rect(a + 3, y + 3, b - a - 6, 3.5, r=1.7))
            x += larg + joint
            n += 1
    # Des touffes d'herbe au pied du mur.
    for cx in (34, 92, 150):
        for dx, h, rot in ((-7, 14, -18), (0, 19, 0), (7, 13, 20)):
            p.plein(HERBE if dx else HERBE_FONCEE,
                    poly([(cx + dx - 3, 176), (cx + dx + rot * 0.25, 176 - h), (cx + dx + 3, 176)], r=[1, 2, 1]))
    return p


def vert() -> Picto:
    """Le vert : un pot de peinture verte qui déborde, et une grosse tache verte à côté."""
    p = Picto("mot.vert")
    ombre(p, 96, 178, 74, 6)
    # La grosse tache verte, posée au sol à gauche (bord ondulé, éclaboussures).
    tache = lisse([(18, 168), (30, 150), (52, 146), (62, 136), (80, 150), (92, 148), (98, 166), (84, 176),
                   (60, 172), (44, 180), (26, 178)])
    p.plein(VERT, tache)
    p.plein(VERT, cercle(20, 142, 5), cercle(40, 130, 3.5), cercle(104, 146, 3))
    p.plein(VERT_CLAIR, ellipse(52, 158, 12, 4, rot=-10))
    # Le pot : corps métallique, étiquette verte, bord, peinture qui déborde et coule.
    p.plein(METAL, rect(92, 78, 82, 96, r=8))
    p.plein(METAL_FONCE, rect(158, 82, 12, 88, r=6))
    p.plein(VERT, rect(92, 108, 82, 42, r=2))
    p.plein(VERT_CLAIR, rect(100, 114, 40, 7, r=3.5))
    p.plein(METAL_FONCE, ellipse(133, 78, 43, 10))
    p.plein(VERT_FONCE, ellipse(133, 78, 38, 7.5))
    p.plein(VERT, ellipse(133, 76, 34, 5.5))
    # Les coulures sur le bord avant du pot.
    for x, h in ((104, 26), (122, 16), (146, 34)):
        p.plein(VERT, rect(x - 4.5, 80, 9, h, r=4.5), goutte(x, 80 + h + 2, 6))
    p.plein("#FFFFFF66", rect(97, 88, 6, 16, r=3))
    return p


PICTOS: list[Picto] = [mur(), vert()]
