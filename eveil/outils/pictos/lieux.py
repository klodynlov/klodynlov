"""Les pictos des LIEUX (« où ? ») du train des phrases, avec leurs ancres.

Chaque lieu (identifiant `lieu.<nom>`) dit où poser le personnage pour chaque
préposition qu'il accepte : point bas-milieu, taille, et ordre de dessin
(devant / dedans / derrière). Pour « dedans », les parties qui passent DEVANT le
personnage (bord de la boîte, eau du bain) sont peintes dans le calque « devant ».
"""
from __future__ import annotations

from coloriages.dessin import poly, rect

from .peinture import Picto, ombre


def boite() -> Picto:
    p = Picto("lieu.boite")
    ombre(p, 100, 180, 78, 7)
    p.plein("#C98B4E", poly([(40, 96), (160, 96), (150, 70), (50, 70)]))          # rabat du fond
    p.plein("#A8703C", rect(36, 92, 128, 18, r=4))                                 # intérieur (fond)
    p.plein("#D99A5B", rect(30, 104, 140, 74, r=6), calque="devant")               # face avant
    p.plein("#E8B27A", poly([(30, 104), (6, 128), (40, 132), (52, 104)]), calque="devant")   # rabat gauche
    p.plein("#E8B27A", poly([(170, 104), (194, 128), (160, 132), (148, 104)]), calque="devant")
    p.trait("#B77B45", 3, rect(84, 124, 32, 22, r=3), calque="devant")            # étiquette
    p.ancre("dans", 100, 128, 0.62, "dedans")
    p.ancre("sur", 100, 72, 0.6, "devant")
    p.ancre("devant", 100, 196, 0.66, "devant")
    p.ancre("derriere", 128, 112, 0.66, "derriere")
    return p


PICTOS = [boite()]
