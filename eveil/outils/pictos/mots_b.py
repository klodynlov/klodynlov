"""Les pictos des MOTS des livres des sons (lot B) : un nom par picto (`mot.<id>`).

Les livres des sons (un livre par son, comme OrthoPicto) ont besoin de mots dessinés pour
chaque son : ceux-ci complètent les dessins du petit train et du train des phrases. Même
style que `WordArt` : un seul objet ou animal, bien centré, formes pleines et arrondies,
couleurs vives mais accordées, pas de contour noir, ombre douce au sol ; les animaux ont
les yeux de la mascotte (`oeil`). Liste des mots : `eveil/outils/livres/mots.py`.
"""
from __future__ import annotations

from .peinture import Picto

PICTOS: list[Picto] = []
