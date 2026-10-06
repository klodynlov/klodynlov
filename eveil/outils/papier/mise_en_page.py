"""La page à imprimer : A4 portrait, en points (1 pt = 1/72 de pouce).

Le dessin occupe un carré centré ; quatre repères (des carrés pleins) l'encadrent, hors du dessin,
dans la partie imprimable de la feuille (à plus de 18 pt du bord) ; le titre est au-dessus. Ce sont
les repères qui recalent la photo : leurs centres, connus sur la page, retrouvés sur la photo,
donnent la transformation (homographie) de la page vers la photo.

Les mêmes nombres sont dans ColoringUI/PaperMode.swift (`PaperLayout`).
"""
from __future__ import annotations

PAGE_L, PAGE_H = 595.2756, 841.8898   # A4
COTE = 480.0                          # côté du carré du dessin
X0 = (PAGE_L - COTE) / 2              # coin haut-gauche du dessin
Y0 = 150.0
REPERE = 26.0                         # côté d'un repère
ECART = 26.0                          # son centre : à ECART du coin du dessin, en x et en y, vers l'extérieur
TITRE_Y = 96.0                        # ligne de base du titre
TITRE_TAILLE = 34.0
MARGE_IMPRIMABLE = 18.0


def reperes_page() -> list[tuple[float, float]]:
    """Centres des repères en points : haut-gauche, haut-droit, bas-droit, bas-gauche."""
    return [(X0 - ECART, Y0 - ECART), (X0 + COTE + ECART, Y0 - ECART),
            (X0 + COTE + ECART, Y0 + COTE + ECART), (X0 - ECART, Y0 + COTE + ECART)]


def reperes_unite() -> list[tuple[float, float]]:
    """Les mêmes centres dans le repère du dessin (0…1 sur le carré)."""
    return [page_vers_unite(x, y) for x, y in reperes_page()]


def page_vers_unite(x: float, y: float) -> tuple[float, float]:
    return ((x - X0) / COTE, (y - Y0) / COTE)


def unite_vers_page(u: float, v: float) -> tuple[float, float]:
    return (X0 + u * COTE, Y0 + v * COTE)
