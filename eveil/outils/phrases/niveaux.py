"""Les trois niveaux du train des phrases, et ce que montre le plateau de pictos.

Niveau 1 « deux wagons » : qui ? + fait quoi ?        → « Le chat dort. »
Niveau 2 « trois wagons » : qui ? + fait quoi ? + quoi ? → « Le chat mange la pêche. »
Niveau 3 « et où ? »    : qui ? + fait quoi ? + où ?   → « Le chat dort dans la boîte. »

Le plateau propose au plus 6 pictos à la fois (un enfant de 3 ans choisit mieux parmi
peu) ; d'une phrase à l'autre il TOURNE dans un ordre fixe (`tour`) : rien n'est tiré au
hasard (docs/EVEIL.md § 4.6). Le « quoi ? » et le « où ? » suivent le verbe choisi
(on mange une pêche ; on nage dans la baignoire).
"""
from __future__ import annotations

from .grammaire import Carte
from .lexique import VERBES, VERBE_PAR_ID, noms

NIVEAUX = {1: ("qui", "verbe"), 2: ("qui", "verbe", "quoi"), 3: ("qui", "verbe", "ou")}
TAILLE_PLATEAU = 6


def roles(niveau: int) -> tuple:
    return NIVEAUX[niveau]


def verbes_du_niveau(niveau: int) -> list:
    if niveau == 1:
        return [v for v in VERBES if not v.transitif or v.absolu]
    if niveau == 2:
        return [v for v in VERBES if v.transitif]
    return [v for v in VERBES if not v.transitif and paires_ou(v.id)]


def paires_ou(verbe_id: str) -> list[Carte]:
    """Les cartes « où ? » d'un verbe, lieu après lieu (tous différents d'abord)."""
    v = VERBE_PAR_ID[verbe_id]
    lieux = [n for n in noms("ou") if not v.lieux or n.id in v.lieux]
    par_lieu = [[Carte("ou", n.id, p) for p in v.prepositions if p in n.prepositions] for n in lieux]
    out = []
    k = 0
    while any(k < len(groupe) for groupe in par_lieu) and k <= 8:
        for groupe in par_lieu:
            if k < len(groupe):
                out.append(groupe[k])
        k += 1
    return out


def _tourne(cartes: list[Carte], decalage: int, taille: int) -> list[Carte]:
    if not cartes:
        return []
    d = decalage % len(cartes)
    tournees = cartes[d:] + cartes[:d]
    return tournees[:taille]


def plateau(role: str, niveau: int, tour: int = 0, verbe: str = "", taille: int = TAILLE_PLATEAU) -> list[Carte]:
    """Les pictos proposés pour un wagon, au tour `tour` (0, 1, 2… une phrase après l'autre)."""
    if role == "qui":
        return _tourne([Carte("qui", n.id) for n in noms("qui")], 3 * tour, taille)
    if role == "verbe":
        return _tourne([Carte("verbe", v.id) for v in verbes_du_niveau(niveau)], 2 * tour, taille)
    if role == "quoi":
        return _tourne([Carte("quoi", o) for o in VERBE_PAR_ID[verbe].objets], tour, taille)
    if role == "ou":
        return _tourne(paires_ou(verbe), 2 * tour, taille)
    raise ValueError(role)
