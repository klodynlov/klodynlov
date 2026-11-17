"""Des photos de pages coloriées, simulées : pour tester le mode papier sans iPad ni imprimante.

La page imprimée (titre, dessin, repères), coloriée « au crayon » (des zones de la page, avec du
grain blanc), puis photographiée : perspective, lumière chaude qui baisse vers les bords, grain.
Tout est déterministe (le grain vient d'un hachage des coordonnées, rien n'est tiré au hasard).
"""
from __future__ import annotations

from coloriages import analyse, apercu, zones

from . import mise_en_page as mp
from .homographie import appliquer, inverse
from .image import Image

ENCRE = apercu.ENCRE_RGB


def _hache(x: int, y: int) -> int:
    return ((x * 73856093) ^ (y * 19349663) ^ 0x5BD1E995) & 0xFFFF


def page_imprimee(a: analyse.Analyse, res: float = 1.0, couleurs: dict | None = None,
                  grain: int = 15) -> tuple[Image, list[int], int]:
    """La page A4 à `res` px par point, coloriée : (image, zones du carré, côté du carré en px).
    `couleurs` : zone (de la carte au côté du carré) → (r, g, b) ; `grain` : % de grains blancs."""
    W, H = round(mp.PAGE_L * res), round(mp.PAGE_H * res)
    img = Image(W, H)
    cote = round(mp.COTE * res)
    ox, oy = round(mp.X0 * res), round(mp.Y0 * res)
    c = zones.carte(a.traits, taille=cote)
    for y in range(cote):
        for x in range(cote):
            z = c.labels[y * cote + x]
            if couleurs and z in couleurs and _hache(x, y) % 100 >= grain:
                img.put(ox + x, oy + y, couleurs[z])
    traits = apercu._masque(a.traits, cote, a.page.trait * cote)
    for y in range(cote):
        for x in range(cote):
            if traits[y * cote + x]:
                img.put(ox + x, oy + y, ENCRE)
    # Le titre : de fausses lettres (des traits épais), pour que les repères aient des voisins.
    for k in range(9):
        lx = round((mp.X0 + 110 + 30 * k) * res)
        for y in range(round((mp.TITRE_Y - 26) * res), round(mp.TITRE_Y * res)):
            for x in range(lx, lx + max(2, round(6 * res))):
                img.put(x, y, ENCRE)
        for x in range(lx, lx + round(18 * res)):
            for y in range(round((mp.TITRE_Y - 26) * res), round((mp.TITRE_Y - 20) * res)):
                img.put(x, y, ENCRE)
    # Les repères.
    s = mp.REPERE * res / 2
    for cx, cy in mp.reperes_page():
        for y in range(round(cy * res - s), round(cy * res + s)):
            for x in range(round(cx * res - s), round(cx * res + s)):
                img.put(x, y, (20, 20, 24))
    return img, c.labels, cote


def photographier(page: Image, H_page_photo, W: int, H: int, lumiere=(0.97, 0.92, 0.80),
                  vignette: float = 0.15, bruit: int = 6, table=(96, 84, 72)) -> Image:
    """La photo : chaque pixel lu sur la page à travers l'homographie inverse, puis la lumière."""
    Hi = inverse(H_page_photo)
    out = Image(W, H)
    for y in range(H):
        for x in range(W):
            px, py = appliquer(Hi, (x + 0.5, y + 0.5))
            if 0 <= px < page.W and 0 <= py < page.H:
                c = page.bilineaire(px, py)
            else:
                c = table
            dx, dy = (x + 0.5) / W - 0.5, (y + 0.5) / H - 0.5
            k = 1 - vignette * 2 * (dx * dx + dy * dy)
            b = _hache(x, y) % (2 * bruit + 1) - bruit
            out.put(x, y, tuple(max(0, min(255, round(c[i] * lumiere[i] * k + b))) for i in range(3)))
    return out
