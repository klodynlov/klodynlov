"""La carte des zones d'une page, simulée comme `ZoneMap` dans l'app (1024 × 1024).

Mêmes règles que eveil/ios/Sources/ColoringUI/ZoneMap.swift :
- les traits sont rastérisés SANS anticrénelage (un pixel est « trait » si son centre est
  à moins d'une demi-épaisseur du tracé : bouts et jointures ronds), avec une épaisseur
  de max(3, min(0,8 × e, e − 3)) pixels pour un trait affiché de e pixels ; les aplats
  d'encre sont remplis (règle non nulle) ;
- chaque composante 4-connexe de pixels hors trait est une zone ; les miettes (< 0,02 %
  de la page) rejoignent la zone voisine majoritaire, de l'autre côté du trait.

Sert à placer les points-témoins (le pixel le plus éloigné des traits, au cœur de
chaque zone) et à vérifier ce que testent `ColoringPagesTests` : aucun témoin sur un
trait, dans le fond du coin, ni dans la zone d'un autre ; zones minuscules toutes
voulues ; 6 à 80 zones. On vérifie aussi que le résultat tient si le trait rastérisé
est un peu plus fin, un peu plus épais, ou décalé d'une fraction de pixel : la
rastérisation de CoreGraphics ne peut pas le faire basculer. Stdlib uniquement.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from .traits import Traits, aplatir, polylignes

TAILLE = 1024
MIETTE = 0.0002        # ZoneMap.crumbFraction
PETITE = 0.003         # sous ce seuil, une zone doit être un détail voulu
COIN = (0.004, 0.004)  # le « fond » : la zone du coin haut gauche
ZONES_MIN, ZONES_MAX = 6, 80


def largeur_raster(trait: float, taille: int = TAILLE) -> float:
    """Épaisseur du trait rastérisé, en pixels (ZoneMap.rasterize)."""
    shown = trait * taille
    return max(3.0, min(shown * 0.8, shown - 3))


# ---------------------------------------------------------------------------
# Rastérisation
# ---------------------------------------------------------------------------

def _capsule(masque: bytearray, W: int, H: int, ax: float, ay: float, bx: float, by: float, r: float,
             uns: bytes):
    """Pixels dont le centre est à ≤ r du segment [A, B] (trait à bouts ronds)."""
    dx, dy = bx - ax, by - ay
    l2 = dx * dx + dy * dy
    y_lo = max(0, math.ceil(min(ay, by) - r - 0.5))
    y_hi = min(H - 1, math.floor(max(ay, by) + r - 0.5))
    r2 = r * r
    ln = math.sqrt(l2)
    for j in range(y_lo, y_hi + 1):
        yc = j + 0.5
        lo, hi = math.inf, -math.inf
        for cx, cy in ((ax, ay), (bx, by)):
            h = yc - cy
            if h * h <= r2:
                s = math.sqrt(r2 - h * h)
                lo = min(lo, cx - s)
                hi = max(hi, cx + s)
        if l2 > 1e-12:
            # 0 ≤ (P−A)·d ≤ l2 et |(P−A)×d| ≤ r·|d|, avec P = (x, yc) : intervalles en x.
            a_lo, a_hi = -math.inf, math.inf
            ok = True
            for coef, const, lo_b, hi_b in (
                (dx, (yc - ay) * dy - ax * dx, 0.0, l2),                  # projection
                (dy, -(yc - ay) * dx - ax * dy, -r * ln, r * ln),          # distance au support
            ):
                # coef·x + const ∈ [lo_b, hi_b]
                if abs(coef) < 1e-12:
                    if not (lo_b <= const <= hi_b):
                        ok = False
                        break
                    continue
                x1, x2 = (lo_b - const) / coef, (hi_b - const) / coef
                if x1 > x2:
                    x1, x2 = x2, x1
                a_lo, a_hi = max(a_lo, x1), min(a_hi, x2)
            if ok and a_lo <= a_hi:
                lo, hi = min(lo, a_lo), max(hi, a_hi)
        if lo > hi:
            continue
        i0 = max(0, math.ceil(lo - 0.5))
        i1 = min(W - 1, math.floor(hi - 0.5))
        if i1 >= i0:
            base = j * W
            masque[base + i0:base + i1 + 1] = uns[:i1 - i0 + 1]


def _remplir(masque: bytearray, W: int, H: int, polys: list[list[tuple[float, float]]], uns: bytes,
             valeur: int | None = None, proprio: list | None = None):
    """Remplissage non nul (centres de pixels) ; `proprio` : écrit `valeur` dans ce tableau."""
    aretes = []
    for pts in polys:
        if math.dist(pts[0], pts[-1]) > 1e-9:
            pts = pts + [pts[0]]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            if y0 != y1:
                aretes.append((x0, y0, x1, y1))
    if not aretes:
        return
    y_lo = max(0, math.floor(min(min(e[1], e[3]) for e in aretes)))
    y_hi = min(H - 1, math.ceil(max(max(e[1], e[3]) for e in aretes)))
    for j in range(y_lo, y_hi + 1):
        yc = j + 0.5
        xs = []
        for x0, y0, x1, y1 in aretes:
            if (y0 <= yc < y1) or (y1 <= yc < y0):
                x = x0 + (yc - y0) * (x1 - x0) / (y1 - y0)
                xs.append((x, 1 if y1 > y0 else -1))
        if not xs:
            continue
        xs.sort()
        w = 0
        for k in range(len(xs) - 1):
            w += xs[k][1]
            if w != 0:
                i0 = max(0, math.ceil(xs[k][0] - 0.5))
                i1 = min(W - 1, math.ceil(xs[k + 1][0] - 0.5) - 1)
                if i1 >= i0:
                    base = j * W
                    if proprio is None:
                        masque[base + i0:base + i1 + 1] = uns[:i1 - i0 + 1]
                    else:
                        proprio[base + i0:base + i1 + 1] = [valeur] * (i1 - i0 + 1)


def masque_traits(t: Traits, taille: int = TAILLE, delta: float = 0.0, decalage: tuple[float, float] = (0, 0)
                  ) -> tuple[bytearray, float]:
    """Masque des traits (1 = trait) : ce que `ZoneMap.rasterize` produit.

    `delta` épaissit (ou affine) le trait rastérisé, `decalage` déplace le dessin (en pixels) :
    pour éprouver la robustesse de la carte.
    """
    W = H = taille
    k = taille / 1000.0
    r = (largeur_raster(t.page.trait, taille) + delta) / 2
    masque = bytearray(W * H)
    uns = b"\x01" * W
    ox, oy = decalage
    lignes = polylignes(t.lignes) + [aplatir(c, 0.2) + ([c.start] if c.closed else []) for c in t.encres]
    for pts in lignes:
        q = [(x * k + ox, y * k + oy) for x, y in pts]
        if len(q) == 1:
            q = q * 2
        for (ax, ay), (bx, by) in zip(q, q[1:]):
            _capsule(masque, W, H, ax, ay, bx, by, r, uns)
    if t.encres:
        polys = [[(x * k + ox, y * k + oy) for x, y in aplatir(c, 0.2)] for c in t.encres]
        _remplir(masque, W, H, polys, uns)
    return masque, 2 * r


# ---------------------------------------------------------------------------
# Étiquetage (ZoneMap.init)
# ---------------------------------------------------------------------------

@dataclass
class Carte:
    W: int
    H: int
    labels: list          # zone de chaque pixel (0 = trait)
    zones: int
    aires: list           # aires[z] en pixels
    raster: float

    def zone(self, u: tuple[float, float]) -> int:
        x = min(max(int(u[0] * self.W), 0), self.W - 1)
        y = min(max(int(u[1] * self.H), 0), self.H - 1)
        return self.labels[y * self.W + x]

    def part(self, z: int) -> float:
        return self.aires[z] / (self.W * self.H)


def etiqueter(masque: bytearray, W: int, H: int, raster: float, miette: float = MIETTE) -> Carte:
    # 1. Segments hors trait, ligne par ligne.
    row_first = [0] * (H + 1)
    x0s: list[int] = []
    x1s: list[int] = []
    for y in range(H):
        row_first[y] = len(x0s)
        row = masque[y * W:(y + 1) * W]
        x = 0
        while x < W:
            nxt = row.find(b"\x00", x)
            if nxt < 0:
                break
            end = row.find(b"\x01", nxt)
            if end < 0:
                end = W
            x0s.append(nxt)
            x1s.append(end)
            x = end
    row_first[H] = len(x0s)
    n_runs = len(x0s)

    # 2. Union-find (4-connexité : chevauchement en x de segments de lignes voisines).
    parent = list(range(n_runs))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for y in range(1, H):
        a, a_end = row_first[y - 1], row_first[y]
        b, b_end = a_end, row_first[y + 1]
        while a < a_end and b < b_end:
            if x1s[a] <= x0s[b]:
                a += 1
                continue
            if x1s[b] <= x0s[a]:
                b += 1
                continue
            ra, rb = find(a), find(b)
            if ra < rb:
                parent[rb] = ra
            elif rb < ra:
                parent[ra] = rb
            if x1s[a] < x1s[b]:
                a += 1
            else:
                b += 1

    # 3. Identifiants provisoires, dans l'ordre de lecture.
    run_id = [0] * n_runs
    prov_area = [0]
    for r in range(n_runs):
        root = find(r)
        if root == r:
            prov_area.append(0)
            run_id[r] = len(prov_area) - 1
        else:
            run_id[r] = run_id[root]
        prov_area[run_id[r]] += x1s[r] - x0s[r]
    n_prov = len(prov_area) - 1

    # 4. Les miettes rejoignent la zone voisine majoritaire, de l'autre côté du trait.
    target = list(range(n_prov + 1))
    limite = int(miette * W * H)
    miettes = [False] * (n_prov + 1)
    if n_prov > 1:
        for i in range(1, n_prov + 1):
            if prov_area[i] < limite:
                miettes[i] = True
    if any(miettes):
        max_step = max(8, int(raster * 4))

        def id_at(x: int, y: int) -> int:
            lo, hi = row_first[y], row_first[y + 1] - 1
            while lo <= hi:
                mid = (lo + hi) // 2
                if x1s[mid] <= x:
                    lo = mid + 1
                elif x0s[mid] > x:
                    hi = mid - 1
                else:
                    return run_id[mid]
            return 0

        def across(x: int, y: int, dx: int, dy: int) -> int:
            x, y, steps = x + dx, y + dy, 0
            while 0 <= x < W and 0 <= y < H and steps < max_step:
                if masque[y * W + x] == 0:
                    return id_at(x, y)
                x += dx
                y += dy
                steps += 1
            return 0

        votes: dict[int, dict[int, int]] = {}
        for y in range(H):
            for r in range(row_first[y], row_first[y + 1]):
                i = run_id[r]
                if not miettes[i]:
                    continue
                x0, x1 = x0s[r], x1s[r] - 1
                xm = (x0 + x1) // 2
                for found in (across(x0, y, -1, 0), across(x1, y, 1, 0), across(xm, y, 0, -1),
                              across(xm, y, 0, 1), across(x0, y, -1, -1), across(x1, y, 1, 1),
                              across(x0, y, -1, 1), across(x1, y, 1, -1)):
                    if found != 0 and found != i and not miettes[found]:
                        t = votes.setdefault(i, {})
                        t[found] = t.get(found, 0) + 1
        for crumb, tally in votes.items():
            best = max(tally.items(), key=lambda kv: (kv[1], -kv[0]))
            target[crumb] = best[0]

    # 5. Numéros définitifs, dans l'ordre de lecture.
    final = [0] * (n_prov + 1)
    zones = 0
    for i in range(1, n_prov + 1):
        if target[i] == i:
            zones += 1
            final[i] = zones
    for i in range(1, n_prov + 1):
        if target[i] != i:
            final[i] = final[target[i]]

    # 6. Étiquettes par pixel et aires.
    labels = [0] * (W * H)
    aires = [0] * (zones + 1)
    for y in range(H):
        base = y * W
        for r in range(row_first[y], row_first[y + 1]):
            z = final[run_id[r]]
            a, b = base + x0s[r], base + x1s[r]
            labels[a:b] = [z] * (b - a)
            aires[z] += b - a
    aires[0] = W * H - sum(aires[1:])
    return Carte(W, H, labels, zones, aires, raster)


def carte(t: Traits, taille: int = TAILLE, delta: float = 0.0, decalage: tuple[float, float] = (0, 0)) -> Carte:
    m, raster = masque_traits(t, taille, delta, decalage)
    return etiqueter(m, taille, taille, raster)


# ---------------------------------------------------------------------------
# Témoins : le cœur de chaque zone
# ---------------------------------------------------------------------------

def distances(c: Carte) -> list[int]:
    """Distance (chanfrein 3-4, en tiers de pixel) de chaque pixel au trait ou au bord le plus proche."""
    W, H = c.W, c.H
    big = 1 << 30
    d = [0 if v == 0 else big for v in c.labels]
    for y in range(H):
        base = y * W
        for x in range(W):
            i = base + x
            v = d[i]
            if v == 0:
                continue
            best = 3 if (x == 0 or y == 0 or x == W - 1 or y == H - 1) else v
            if y > 0:
                up = i - W
                t = d[up] + 3
                if t < best:
                    best = t
                if x > 0:
                    t = d[up - 1] + 4
                    if t < best:
                        best = t
                if x < W - 1:
                    t = d[up + 1] + 4
                    if t < best:
                        best = t
            if x > 0:
                t = d[i - 1] + 3
                if t < best:
                    best = t
            d[i] = best
    for y in range(H - 1, -1, -1):
        base = y * W
        for x in range(W - 1, -1, -1):
            i = base + x
            best = d[i]
            if best == 0:
                continue
            if y < H - 1:
                dn = i + W
                t = d[dn] + 3
                if t < best:
                    best = t
                if x > 0:
                    t = d[dn - 1] + 4
                    if t < best:
                        best = t
                if x < W - 1:
                    t = d[dn + 1] + 4
                    if t < best:
                        best = t
            if x < W - 1:
                t = d[i + 1] + 3
                if t < best:
                    best = t
            d[i] = best
    return d


@dataclass
class Temoins:
    temoins: list = field(default_factory=list)   # [(x, y)] en unité, zones ≥ 0,3 %
    details: list = field(default_factory=list)   # [(x, y)] en unité, petites zones voulues
    profondeur: dict = field(default_factory=dict)  # zone → distance du témoin au trait (pixels)


def placer(c: Carte, voulus: set | frozenset = frozenset()) -> Temoins:
    """Un point au cœur de chaque zone (sauf le fond du coin) : témoin, ou détail si < 0,3 %.

    `voulus` : zones d'un élément `detail` (œil, bouton…), déclarées détails quelle que soit leur
    taille — un détail n'a pas de taille minimale, ce qui évite les zones au bord du seuil.
    """
    d = distances(c)
    best: dict[int, tuple[int, int]] = {}
    labels = c.labels
    for i, z in enumerate(labels):
        if z and (z not in best or d[i] > best[z][0]):
            best[z] = (d[i], i)
    coin = c.zone(COIN)
    out = Temoins()
    for z in sorted(best):
        if z == coin:
            continue
        dist, i = best[z]
        x, y = i % c.W, i // c.W
        u = (round((x + 0.5) / c.W, 4), round((y + 0.5) / c.H, 4))
        (out.temoins if c.part(z) >= PETITE and z not in voulus else out.details).append(u)
        out.profondeur[z] = dist / 3
    return out


def verifier(c: Carte, tem: Temoins, marge: float = 1.0) -> list[str]:
    """Ce que vérifient `ColoringPagesTests` (témoins, détails, zones minuscules, nombre de zones).

    `marge` : exigence sur la part des zones-témoins (1,0 = le seuil du test ; 1,05 = 5 % de marge).
    """
    err = []
    coin = c.zone(COIN)
    if coin == 0:
        err.append("le coin de la page est sur un trait")
    owner: dict[int, str] = {}
    for genre, pts in (("témoin", tem.temoins), ("détail", tem.details)):
        for p in pts:
            z = c.zone(p)
            nom = f"{genre} {p}"
            if z == 0:
                err.append(f"{nom} est sur un trait")
                continue
            if z == coin:
                err.append(f"{nom} fuit dans le fond")
            if z in owner:
                err.append(f"{nom} partage sa zone avec {owner[z]}")
            owner[z] = nom
            if genre == "témoin" and c.part(z) < PETITE * marge:
                err.append(f"{nom} : zone de {100 * c.part(z):.3f} % — un détail ?")
    declares = {c.zone(p) for p in tem.details}
    for z in range(1, c.zones + 1):
        if c.part(z) < PETITE and z not in declares:
            err.append(f"zone {z} de {100 * c.part(z):.3f} % non voulue, vers {centre(c, z)}")
    if not (ZONES_MIN <= c.zones <= ZONES_MAX):
        err.append(f"{c.zones} zones")
    return err


def centre(c: Carte, z: int) -> tuple[float, float]:
    sx = sy = n = 0
    for i, v in enumerate(c.labels):
        if v == z:
            sx += i % c.W
            sy += i // c.W
            n += 1
    return (round(sx / n / c.W, 3), round(sy / n / c.H, 3)) if n else (-1, -1)


# ---------------------------------------------------------------------------
# À qui appartient chaque zone (pour distinguer un détail voulu d'une miette de dessin)
# ---------------------------------------------------------------------------

def proprietaires(t: Traits, taille: int = TAILLE) -> list[int]:
    """Pour chaque pixel : l'indice (dans la page) de l'élément plein le plus en avant, ou −1."""
    W = H = taille
    k = taille / 1000.0
    owner = [-1] * (W * H)
    for idx, el in enumerate(t.page.elements):
        if el.genre not in ("zone", "detail", "encre"):
            continue
        polys = [[(x * k, y * k) for x, y in aplatir(c, 0.3)] for c in el.contours]
        _remplir(bytearray(0), W, H, polys, b"", valeur=idx, proprio=owner)
    return owner


def proprietaire_des_zones(c: Carte, owner: list[int]) -> dict[int, int]:
    """Zone → élément majoritaire parmi ses pixels (−1 = le fond)."""
    comptes: dict[int, dict[int, int]] = {}
    for z, o in zip(c.labels, owner):
        if z:
            t = comptes.setdefault(z, {})
            t[o] = t.get(o, 0) + 1
    return {z: max(t.items(), key=lambda kv: kv[1])[0] for z, t in comptes.items()}
