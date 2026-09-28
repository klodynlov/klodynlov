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


def trouver(img: Image) -> list[tuple[float, float]] | None:
    """Centres des repères (haut-gauche, haut-droit, bas-droit, bas-gauche) en pixels de `img`,
    ou None s'il en manque un."""
    f = max(1, round(img.H / CIBLE))
    petit = img.reduire(f)
    W, H = petit.W, petit.H
    L = petit.luma()
    papier = _centile(L, 0.90)
    seuil = 0.45 * papier
    sombre = bytearray(1 if v < seuil else 0 for v in L)
    kx, ky = W / mp.PAGE_L, H / mp.PAGE_H
    cote = mp.REPERE * (kx + ky) / 2
    rayon = 0.10 * W
    out = []
    vu = bytearray(W * H)
    for cx, cy in mp.reperes_page():
        ex, ey = cx * kx, cy * ky
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


def sans_reperes(img: Image) -> list[tuple[float, float]]:
    """Faute de repères (coin coupé, photo floue) : la photo est prise pour la page entière."""
    kx, ky = img.W / mp.PAGE_L, img.H / mp.PAGE_H
    return [(x * kx, y * ky) for x, y in mp.reperes_page()]
