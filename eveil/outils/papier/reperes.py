"""Retrouver les quatre repères sur la photo d'une page coloriée.

La photo vient du scanner de documents d'iPadOS (la feuille détectée, redressée, recadrée) : elle
montre la page à peu près entière, mais recadrée et déformée d'un peu. Les repères sont des carrés
pleins, noirs, hors du dessin. On cherche, près de l'endroit où chacun devrait être, la tache
sombre la plus proche qui a l'allure d'un carré plein :
- sombre : moins de 45 % de la clarté du papier (le 90e centile de la photo) ;
- carrée : boîte presque carrée, remplie à plus de 80 % (une lettre du titre, un œil rond, un trait
  ne le sont pas) ;
- de la bonne taille : entre 0,4 et 2,5 fois le côté attendu.
Un coin de dessin colorié tout noir par l'enfant pourrait passer ces tests : c'est pourquoi on
prend la candidate la plus PROCHE de la place attendue (les repères sont hors du dessin).

La feuille peut être photographiée de côté ou à l'envers (l'enfant assis en face de l'adulte) :
`quarts` dit de combien de quarts de tour (sens des aiguilles d'une montre) il faudrait tourner la
photo pour que la page soit droite ; les places attendues sont alors ramenées sur la photo telle
qu'elle est (`depuis_droite`), sans tourner un seul pixel.
"""
from __future__ import annotations

from collections import deque

from . import mise_en_page as mp
from .image import Image

CIBLE = 900          # on cherche sur une photo réduite à ~900 px de haut


def _centile(valeurs: list[float], q: float) -> float:
    h = [0] * 256
    for v in valeurs:
        h[min(255, int(v))] += 1
    seuil = q * len(valeurs)
    s = 0
    for k, n in enumerate(h):
        s += n
        if s >= seuil:
            return float(k)
    return 255.0


def depuis_droite(x: float, y: float, quarts: int, W: int, H: int) -> tuple[float, float]:
    """Un point de la page DROITE (la photo tournée de `quarts` quarts de tour) ramené sur la photo
    telle qu'elle est (W × H)."""
    q = quarts % 4
    if q == 1:
        return (y, H - x)
    if q == 2:
        return (W - x, H - y)
    if q == 3:
        return (W - y, x)
    return (x, y)


class Taches:
    """La photo réduite (~900 px de haut, page droite) et ses pixels sombres : moins de 45 % de la
    clarté du papier (le 90e centile de la photo)."""

    def __init__(self, img: Image, quarts: int = 0):
        haut = img.W if quarts % 2 else img.H
        self.f = max(1, round(haut / CIBLE))
        petit = img.reduire(self.f)
        self.W, self.H = petit.W, petit.H
        L = petit.luma()
        seuil = 0.45 * _centile(L, 0.90)
        self.sombre = bytearray(1 if v < seuil else 0 for v in L)


def trouver(img: Image, quarts: int = 0, taches: Taches | None = None) -> list[tuple[float, float]] | None:
    """Centres des repères (haut-gauche, haut-droit, bas-droit, bas-gauche DE LA PAGE) en pixels de
    `img`, ou None s'il en manque un. `taches` : celles de la photo, si on les a déjà (même `quarts`
    à un demi-tour près)."""
    t = taches or Taches(img, quarts)
    f, W, H, sombre = t.f, t.W, t.H, t.sombre
    uw, uh = (H, W) if quarts % 2 else (W, H)          # la page droite, en pixels réduits
    kx, ky = uw / mp.PAGE_L, uh / mp.PAGE_H
    cote = mp.REPERE * (kx + ky) / 2
    rayon = 0.10 * uw
    out = []
    vu = bytearray(W * H)
    for cx, cy in mp.reperes_page():
        ex, ey = depuis_droite(cx * kx, cy * ky, quarts, W, H)
        x0, x1 = max(0, int(ex - rayon)), min(W, int(ex + rayon) + 1)
        y0, y1 = max(0, int(ey - rayon)), min(H, int(ey + rayon) + 1)
        meilleur = None
        for y in range(y0, y1):
            for x in range(x0, x1):
                i = y * W + x
                if not sombre[i] or vu[i]:
                    continue
                # Une tache sombre : sa taille, sa boîte, son centre.
                vu[i] = 1
                q = deque([i])
                n = sx = sy = 0
                bx0, by0, bx1, by1 = x, y, x, y
                while q:
                    k = q.popleft()
                    kx_, ky_ = k % W, k // W
                    n += 1
                    sx += kx_
                    sy += ky_
                    bx0, bx1 = min(bx0, kx_), max(bx1, kx_)
                    by0, by1 = min(by0, ky_), max(by1, ky_)
                    for nx, ny in ((kx_ + 1, ky_), (kx_ - 1, ky_), (kx_, ky_ + 1), (kx_, ky_ - 1)):
                        if 0 <= nx < W and 0 <= ny < H:
                            j = ny * W + nx
                            if sombre[j] and not vu[j]:
                                vu[j] = 1
                                q.append(j)
                w, h = bx1 - bx0 + 1, by1 - by0 + 1
                if not (0.4 * cote <= w <= 2.5 * cote and 0.4 * cote <= h <= 2.5 * cote):
                    continue
                if not (0.6 <= w / h <= 1 / 0.6) or n < 0.8 * w * h:
                    continue
                mx, my = sx / n + 0.5, sy / n + 0.5
                d = (mx - ex) ** 2 + (my - ey) ** 2
                if d <= rayon ** 2 and (meilleur is None or d < meilleur[0]):
                    meilleur = (d, mx, my)
        if meilleur is None:
            return None
        out.append((meilleur[1] * f, meilleur[2] * f))
    return out


def sans_reperes(img: Image, quarts: int = 0) -> list[tuple[float, float]]:
    """Faute de repères (coin coupé, photo floue) : la photo est prise pour la page entière."""
    uw, uh = (img.H, img.W) if quarts % 2 else (img.W, img.H)
    kx, ky = uw / mp.PAGE_L, uh / mp.PAGE_H
    return [depuis_droite(x * kx, y * ky, quarts, img.W, img.H) for x, y in mp.reperes_page()]
