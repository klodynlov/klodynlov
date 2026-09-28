"""Les pictos des VERBES du train des phrases : Lou fait l'action.

Un picto par verbe (identifiant `verbe.<infinitif>`), lisible par un enfant de 3 ans :
une seule action, un accessoire au plus, des signes de mouvement (traits, notes, Zzz).
"""
from __future__ import annotations

from .figure import Pose, lou
from .peinture import Picto, ombre


def dormir() -> Picto:
    """Exemple provisoire (à redessiner : Lou couché dans son lit)."""
    p = Picto("verbe.dormir")
    ombre(p)
    lou(p, Pose(yeux="fermes", bouche="fermee", tete=14))
    for x, y, s in [(132, 64, 10), (150, 46, 13), (170, 24, 16)]:
        p.trait("#7C8CD6", 3.2, *_z(x - 6, y - 4, s * 0.7))
    return p


def _z(x: float, y: float, s: float):
    from coloriages.dessin import ligne
    return [ligne((x, y), (x + s, y), (x, y + s), (x + s, y + s))]


PICTOS = [dormir()]
