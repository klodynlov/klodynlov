"""Redresser la photo sur le carré du dessin, puis y lire les coups de crayon de l'enfant.

1. Redresser : l'homographie des repères (centres connus sur la page → retrouvés sur la photo)
   envoie chaque pixel du carré du dessin sur la photo ; on y lit la couleur (bilinéaire).
2. Accord : la photo est-elle bien CETTE page ? La part des pixels de trait de la page qui sont
   sombres sur la photo redressée (la bonne page : presque tous ; une autre : peu).
3. Les couleurs : la balance des blancs d'après le papier (le 95e centile de clarté des zones) ;
   un pixel est colorié s'il est coloré (saturation) ou sombre (crayon noir, marron, gris) ; près
   d'un trait (erreur de recalage, bord du trait imprimé), seule une vraie couleur compte. Le reste
   est transparent : les grains blancs du crayon se voient, comme sur la feuille. Les traits, l'app
   les dessine par-dessus, nets.
"""
from __future__ import annotations

from collections import deque

from . import mise_en_page as mp
from .homographie import appliquer, homographie
from .image import Image

CHROMA = 45          # une couleur franche
CHROMA_PRES = 70     # près d'un trait
SOMBRE = 150         # crayon sombre (clarté après balance des blancs)
PRES = 0.006         # « près d'un trait » : 0,6 % du côté du dessin
ENCRE_CLARTE = 0.4   # l'encre : moins de 40 % de la clarté du papier…
ENCRE_CHROMA = 60    # … et presque sans couleur
ACCORD_MIN = 0.5     # sous ce seuil, ce n'est pas cette page


def redresser(img: Image, reperes, n: int) -> Image:
    """Le carré du dessin (n × n pixels) lu sur la photo."""
    H = homographie(mp.reperes_unite(), reperes)
    out = Image(n, n)
    for y in range(n):
        v = (y + 0.5) / n
        for x in range(n):
            out.put(x, y, img.bilineaire(*appliquer(H, ((x + 0.5) / n, v))))
    return out


def _pres_des_traits(labels: list[int], n: int, r: int) -> bytearray:
    """1 = à moins de `r` pixels (4-connexité) d'un pixel de trait."""
    d = bytearray(n * n)
    q = deque()
    for i, z in enumerate(labels):
        if z == 0:
            d[i] = 1
            q.append((i, 0))
    while q:
        i, k = q.popleft()
        if k >= r:
            continue
        x, y = i % n, i // n
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < n and 0 <= ny < n:
                j = ny * n + nx
                if not d[j]:
                    d[j] = 1
                    q.append((j, k + 1))
    return d


def accord(rect: Image, labels: list[int]) -> float:
    """Part des pixels de trait (loin du bord) qui sont de l'ENCRE sur la photo redressée : un gris
    foncé presque sans couleur (un ciel colorié en rouge, sombre lui aussi, n'en est pas)."""
    n = rect.W
    L = rect.luma()
    zones = sorted(L[i] for i, z in enumerate(labels) if z)
    papier = zones[int(0.95 * (len(zones) - 1))] if zones else 255
    m = max(2, n // 50)
    encre = total = 0
    for y in range(m, n - m):
        for x in range(m, n - m):
            i = y * n + x
            if labels[i] == 0:
                total += 1
                r, g, b = rect.px[3 * i], rect.px[3 * i + 1], rect.px[3 * i + 2]
                if L[i] < ENCRE_CLARTE * papier and max(r, g, b) - min(r, g, b) < ENCRE_CHROMA:
                    encre += 1
    return encre / total if total else 0.0


def peinture(rect: Image, labels: list[int]) -> list:
    """Pour chaque pixel du carré : la couleur de l'enfant (r, g, b), ou None (papier, trait)."""
    n = rect.W
    L = rect.luma()
    # Le papier : la couleur moyenne des pixels de zone les plus clairs.
    zones = sorted((L[i], i) for i, z in enumerate(labels) if z)
    if not zones:
        return [None] * (n * n)
    haut = zones[int(0.95 * (len(zones) - 1))][0]
    clairs = [i for v, i in zones if v >= haut - 6]
    papier = [sum(rect.px[3 * i + c] for i in clairs) / len(clairs) for c in range(3)]
    gain = [min(3.0, max(0.8, 255 / max(1.0, p))) for p in papier]
    pres = _pres_des_traits(labels, n, max(1, round(PRES * n)))
    out = [None] * (n * n)
    for i, z in enumerate(labels):
        if not z:
            continue
        r = min(255, round(rect.px[3 * i] * gain[0]))
        g = min(255, round(rect.px[3 * i + 1] * gain[1]))
        b = min(255, round(rect.px[3 * i + 2] * gain[2]))
        chroma = max(r, g, b) - min(r, g, b)
        clarte = 0.299 * r + 0.587 * g + 0.114 * b
        if pres[i]:
            ok = chroma >= CHROMA_PRES
        else:
            ok = chroma >= CHROMA or clarte <= SOMBRE
        if ok:
            out[i] = (r, g, b)
    return out
