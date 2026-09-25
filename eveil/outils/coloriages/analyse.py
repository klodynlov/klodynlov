"""Analyse complète d'une page : traits visibles, carte des zones, témoins, contrôles.

Les contrôles reprennent ceux de `ColoringPagesTests` (Swift) et en ajoutent pour la
propreté du dessin :
- chaque zone ≥ 0,3 % reçoit un témoin, chaque zone plus petite est un DÉTAIL VOULU
  (un élément `detail` : œil, bouton…) — sinon c'est une miette de dessin, à corriger ;
- la carte tient si le trait rastérisé est 1 px plus fin, 1 px plus épais, ou décalé
  d'une fraction de pixel (CoreGraphics ne rastérise pas exactement comme nous) ;
- aucune encre n'est recouverte (l'app la dessine sous les traits, sans rien devant) ;
- les contours des formes pleines sont fermés, ne se croisent pas, restent dans la page.
Stdlib uniquement.
"""
from __future__ import annotations

from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass

from . import traits, zones
from .dessin import Element, Page, bornes, croisements
from .zones import COIN, PETITE, Carte, Temoins

# Épreuves de robustesse : (épaisseur en plus, en px ; décalage en px).
VARIANTES = ((-1.0, (0.0, 0.0)), (1.0, (0.0, 0.0)), (0.0, (0.37, 0.61)))
MARGE_TEMOINS = 1.05   # une zone-témoin doit dépasser le seuil de 0,3 % d'au moins 5 %
# Un détail doit avoir un cœur d'au moins 4 px (distance au trait le plus proche) : le blanc de
# l'œil du caniche, un croissant de 3,7 px (0,026 %), passait ici mais CoreGraphics en faisait une
# miette rattachée à la tête (premier `swift test` sur le Mac, 25/09/2026). Les détails validés
# sur le Mac ont tous 4 px ou plus.
PROFONDEUR_DETAIL = 4.0


@dataclass
class Analyse:
    page: Page
    traits: traits.Traits
    carte: Carte
    temoins: Temoins
    erreurs: list
    remarques: list

    @property
    def lignes(self) -> str:
        return traits.donnees_lignes(self.traits.lignes)

    @property
    def encres(self) -> str:
        return traits.donnees_contours(self.traits.encres)


def geometrie(p: Page) -> list[str]:
    err = []
    for i, el in enumerate(p.elements):
        x0, y0, x1, y1 = bornes(el)
        if not (-0.5 <= x0 and -0.5 <= y0 and x1 <= 1000.5 and y1 <= 1000.5):
            err.append(f"élément {i} ({el.genre}) hors de la page : {x0:.0f},{y0:.0f} → {x1:.0f},{y1:.0f}")
        if el.genre == "trait":
            continue
        if not all(c.closed for c in el.contours):
            err.append(f"élément {i} ({el.genre}) : contour ouvert")
        x = croisements(el.contours)
        if x:
            err.append(f"élément {i} ({el.genre}) : contours qui se croisent vers {tuple(round(v) for v in x[0])}")
    return err


def analyser(p: Page, variantes: bool = True) -> Analyse:
    t = traits.calculer(p)
    c = zones.carte(t)
    owner = zones.proprietaires(t)
    own = zones.proprietaire_des_zones(c, owner)
    voulus = {z for z, o in own.items() if o >= 0 and p.elements[o].genre == "detail"}
    tem = zones.placer(c, voulus)
    err = geometrie(p)
    err += zones.verifier(c, tem, marge=MARGE_TEMOINS)
    rem = []
    coin = c.zone(COIN)
    if own.get(coin, -1) != -1:
        rem.append(f"le coin de la page est dans l'élément {own[coin]} (pas dans le ciel)")
    for z in range(1, c.zones + 1):
        if z == coin or c.part(z) >= PETITE:
            continue
        o = own.get(z, -1)
        if o < 0 or p.elements[o].genre != "detail":
            quoi = "le fond" if o < 0 else f"élément {o} ({p.elements[o].genre})"
            err.append(f"miette de {100 * c.part(z):.3f} % vers {zones.centre(c, z)} — {quoi}")
        elif tem.profondeur.get(z, 0) < PROFONDEUR_DETAIL:
            err.append(f"détail trop mince ({tem.profondeur.get(z, 0):.1f} px) vers {zones.centre(c, z)} : "
                       "CoreGraphics peut le fondre dans sa voisine")
    for i, el in enumerate(p.elements):
        if el.genre != "encre":
            continue
        devant = {o for o in owner_in(el, owner) if o > i and p.elements[o].genre != "encre"}
        if devant:
            err.append(f"encre {i} recouverte par l'élément {min(devant)}")
    if variantes:
        for delta, dec in VARIANTES:
            c2 = zones.carte(t, delta=delta, decalage=dec)
            err += [f"[trait {delta:+g} px, décalage {dec}] {e}" for e in zones.verifier(c2, tem)]
    return Analyse(p, t, c, tem, err, rem)


def owner_in(el: Element, owner: list[int], taille: int = zones.TAILLE) -> set[int]:
    """Propriétaires des pixels couverts par un élément."""
    m = bytearray(taille * taille)
    k = taille / 1000.0
    polys = [[(x * k, y * k) for x, y in traits.aplatir(c, 0.3)] for c in el.contours]
    zones._remplir(m, taille, taille, polys, b"\x01" * taille)
    return {owner[i] for i, v in enumerate(m) if v}


def _une(p: Page) -> Analyse:
    return analyser(p)


def analyser_tout(pages: list[Page], processus: int = 4) -> list[Analyse]:
    if processus <= 1 or len(pages) < 2:
        return [analyser(p) for p in pages]
    with ProcessPoolExecutor(max_workers=processus) as ex:
        return list(ex.map(_une, pages))
