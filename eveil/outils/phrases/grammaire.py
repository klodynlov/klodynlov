"""La grammaire du train des phrases : groupes nominaux, morceaux (wagons), phrase entière.

Français : article défini accordé (le / la / les), ÉLIDÉ devant une voyelle (« l'autruche »,
« l'os » ; jamais « les ») ; pas d'article devant un nom propre (« Lou ») ; verbe au présent, 3e personne ;
lieu = préposition + groupe nominal (« dans la boîte », « derrière l'arbre »).
Anglais : « the » + nom ; « Lou » ; verbe en -s ; « in / on / under / in front of / behind ».
La phrase commence par une majuscule et finit par un point. Chaque MORCEAU est le texte
d'un wagon : ["le chat", "mange", "la pêche"] → « Le chat mange la pêche. »
Portée ligne à ligne en Swift (`PhraseGrammar`), vecteurs de parité : `generer.py`.
"""
from __future__ import annotations

from dataclasses import dataclass

from .lexique import PAR_ID, PREP_EN, PREP_FR, VERBE_PAR_ID, Nom

VOYELLES = set("aàâeéèêëiîïoôuûüyœh")   # h : aucun mot du lexique à h aspiré (à vérifier si on en ajoute)


@dataclass(frozen=True)
class Carte:
    """Un picto du plateau : un rôle (qui, verbe, quoi, ou), un identifiant, une préposition (où)."""
    role: str
    id: str
    preposition: str = ""


def francais(locale: str) -> bool:
    return locale.startswith("fr")


def groupe_nominal(n: Nom, locale: str) -> str:
    if francais(locale):
        if n.genre == "p":
            return n.fr
        if n.genre == "pl":
            return "les " + n.fr
        if n.fr[0].lower() in VOYELLES:
            return "l'" + n.fr
        return ("le " if n.genre == "m" else "la ") + n.fr
    return n.en if n.genre == "p" else "the " + n.en


def morceau(c: Carte, locale: str) -> str:
    """Le texte d'un wagon."""
    if c.role == "verbe":
        v = VERBE_PAR_ID[c.id]
        return v.fr if francais(locale) else v.en
    n = PAR_ID[c.id]
    gn = groupe_nominal(n, locale)
    if c.role == "ou":
        prep = PREP_FR[c.preposition] if francais(locale) else PREP_EN[c.preposition]
        return f"{prep} {gn}"
    return gn


def phrase(cartes: list[Carte], locale: str) -> str:
    """La phrase entière : majuscule au début, point à la fin."""
    texte = " ".join(morceau(c, locale) for c in cartes)
    return texte[:1].upper() + texte[1:] + "."
