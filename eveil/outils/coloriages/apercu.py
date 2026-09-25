"""Aperçus des pages : PNG (traits, carte des zones) et SVG, pour relire chaque dessin à l'œil.

- `png_traits` : la page telle que l'enfant la voit (traits à l'épaisseur affichée,
  aplats d'encre), rastérisée ici avec suréchantillonnage ;
- `png_zones` : une teinte par zone, témoins en rouge et détails en bleu (comme les
  planches `-2-zones` des tests Swift) ;
- `svg` : les mêmes traits en vectoriel (planches contact rendues par un navigateur).
Stdlib uniquement (PNG écrit avec zlib).
"""
from __future__ import annotations

import struct
import zlib

from .dessin import ENCRE
from .traits import Traits, aplatir, donnees_contours, donnees_lignes, polylignes
from .zones import Carte, Temoins, _capsule, _remplir

ENCRE_RGB = (0x2E, 0x33, 0x4A)


def ecrire_png(chemin, W: int, H: int, rgb: bytes | bytearray):
    raw = b"".join(b"\x00" + bytes(rgb[y * W * 3:(y + 1) * W * 3]) for y in range(H))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    with open(chemin, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))


def _masque(t: Traits, taille: int, largeur_px: float) -> bytearray:
    k = taille / 1000.0
    W = H = taille
    m = bytearray(W * H)
    uns = b"\x01" * W
    r = largeur_px / 2
    for pts in polylignes(t.lignes) + [aplatir(c, 0.2) for c in t.encres]:
        q = [(x * k, y * k) for x, y in pts]
        if len(q) == 1:
            q = q * 2
        for (ax, ay), (bx, by) in zip(q, q[1:]):
            _capsule(m, W, H, ax, ay, bx, by, r, uns)
    if t.encres:
        _remplir(m, W, H, [[(x * k, y * k) for x, y in aplatir(c, 0.2)] for c in t.encres], uns)
    return m


def png_traits(t: Traits, chemin, taille: int = 512, sur: int = 3, fond=(255, 255, 255)):
    """La page telle qu'affichée (traits à l'épaisseur de la page), suréchantillonnée ×`sur`."""
    grand = taille * sur
    m = _masque(t, grand, t.page.trait * grand)
    rgb = bytearray(taille * taille * 3)
    n = sur * sur
    for y in range(taille):
        for x in range(taille):
            s = 0
            for j in range(sur):
                base = (y * sur + j) * grand + x * sur
                s += sum(m[base:base + sur])
            a = s / n
            i = (y * taille + x) * 3
            for c in range(3):
                rgb[i + c] = round(fond[c] * (1 - a) + ENCRE_RGB[c] * a)
    ecrire_png(chemin, taille, taille, rgb)


def _teinte(z: int) -> tuple[int, int, int]:
    h = (z * 0.61803398875) % 1.0
    # HSV → RGB, saturation et valeur modérées (pastels lisibles)
    s, v = 0.45, 0.97
    i = int(h * 6)
    f = h * 6 - i
    p, q, u = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    r, g, b = [(v, u, p), (q, v, p), (p, v, u), (p, q, v), (u, p, v), (v, p, q)][i % 6]
    return round(r * 255), round(g * 255), round(b * 255)


def png_zones(c: Carte, tem: Temoins, chemin, coin_blanc: bool = True):
    """Une teinte par zone ; témoins en rouge, détails en bleu (le fond du coin reste blanc)."""
    W, H = c.W, c.H
    rgb = bytearray(W * H * 3)
    coin = c.zone((0.004, 0.004))
    couleurs = {0: ENCRE_RGB, coin: (255, 255, 255)} if coin_blanc else {0: ENCRE_RGB}
    for i, z in enumerate(c.labels):
        col = couleurs.get(z)
        if col is None:
            col = couleurs[z] = _teinte(z)
        rgb[3 * i:3 * i + 3] = bytes(col)
    for pts, col in ((tem.temoins, (230, 25, 25)), (tem.details, (25, 75, 240))):
        for u in pts:
            cx, cy = int(u[0] * W), int(u[1] * H)
            for dy in range(-5, 6):
                for dx in range(-5, 6):
                    if dx * dx + dy * dy <= 25 and 0 <= cx + dx < W and 0 <= cy + dy < H:
                        i = ((cy + dy) * W + cx + dx) * 3
                        rgb[i:i + 3] = bytes(col)
    ecrire_png(chemin, W, H, rgb)


def svg(t: Traits, px: int = 500) -> str:
    """Les traits en SVG (épaisseur affichée, bouts ronds) — comme `LineArtView`."""
    w = t.page.trait * 1000
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="{px}" height="{px}">',
           '<rect width="1000" height="1000" fill="#fff"/>']
    if t.encres:
        out.append(f'<path d="{donnees_contours(t.encres)}" fill="{ENCRE}" stroke="{ENCRE}" stroke-width="{w:g}" '
                   'stroke-linejoin="round" stroke-linecap="round"/>')
    out.append(f'<path d="{donnees_lignes(t.lignes)}" fill="none" stroke="{ENCRE}" stroke-width="{w:g}" '
               'stroke-linejoin="round" stroke-linecap="round"/>')
    out.append("</svg>")
    return "\n".join(out)


def png_revue(a, chemin, cote: int = 512):
    """Planche de relecture d'une page : les traits (à gauche) et la carte des zones (à droite)."""
    t, c, tem = a.traits, a.carte, a.temoins
    # traits, suréchantillonnés
    grand = cote * 3
    m = _masque(t, grand, t.page.trait * grand)
    W = 2 * cote + 8
    rgb = bytearray(W * cote * 3)
    for i in range(0, len(rgb), 3):
        rgb[i:i + 3] = b"\xf0\xeb\xe0"
    for y in range(cote):
        for x in range(cote):
            s = 0
            for j in range(3):
                base = (y * 3 + j) * grand + x * 3
                s += m[base] + m[base + 1] + m[base + 2]
            a_ = s / 9
            i = (y * W + x) * 3
            for k in range(3):
                rgb[i + k] = round(255 * (1 - a_) + ENCRE_RGB[k] * a_)
    # zones, réduites de moitié (plus proche voisin)
    coin = c.zone((0.004, 0.004))
    couleurs = {0: ENCRE_RGB, coin: (255, 255, 255)}
    f = c.W // cote
    for y in range(cote):
        for x in range(cote):
            z = c.labels[(y * f) * c.W + x * f]
            col = couleurs.get(z)
            if col is None:
                col = couleurs[z] = _teinte(z)
            i = (y * W + cote + 8 + x) * 3
            rgb[i:i + 3] = bytes(col)
    for pts, col in ((tem.temoins, (230, 25, 25)), (tem.details, (25, 75, 240))):
        for u in pts:
            cx, cy = int(u[0] * cote), int(u[1] * cote)
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if dx * dx + dy * dy <= 9 and 0 <= cx + dx < cote and 0 <= cy + dy < cote:
                        i = ((cy + dy) * W + cote + 8 + cx + dx) * 3
                        rgb[i:i + 3] = bytes(col)
    ecrire_png(chemin, W, cote, rgb)
