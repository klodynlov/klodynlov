"""Les traits VISIBLES d'une page : élimination des parties cachées, comme `LineClipper`.

Même algorithme que `Sketch.lineArt` dans l'app (eveil/ios/Sources/ColoringUI/Sketch.swift) :
on parcourt l'empilement de l'AVANT vers le fond en accumulant les formes pleines
déjà vues ; chaque courbe est échantillonnée tous les 4 ‰ de la page, chaque passage
visible/caché est affiné par dichotomie (14 pas), et l'on garde les sous-courbes de
Bézier exactes (de Casteljau). Un point est caché s'il est dans une forme de devant
(règle non nulle, celle de `CGPath.contains`).

Les traits ainsi obtenus sont ce que l'app affiche : `generer.py` les écrit tels quels
(`s.line(G.data(…))`), l'app n'a plus rien à cacher. Stdlib uniquement.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

from .dessin import Contour, Element, Page

PAS = 4.0          # pas d'échantillonnage (repère 1000), comme LineClipper.step
DICHOTOMIE = 14    # affinage d'un passage visible/caché
BANDE = 8.0        # hauteur des bandes de l'index des arêtes (test d'appartenance)

Point = tuple[float, float]


@dataclass
class Morceau:
    """Un bout de trait : segment droit (p0, p3) ou courbe cubique (p0, p1, p2, p3)."""
    droit: bool
    p0: Point
    p1: Point
    p2: Point
    p3: Point


# ---------------------------------------------------------------------------
# Courbes
# ---------------------------------------------------------------------------

def _lerp(a: Point, b: Point, t: float) -> Point:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _point(m: Morceau, t: float) -> Point:
    u = 1 - t
    a, b, c, d = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
    return (a * m.p0[0] + b * m.p1[0] + c * m.p2[0] + d * m.p3[0],
            a * m.p0[1] + b * m.p1[1] + c * m.p2[1] + d * m.p3[1])


def _split(m: Morceau, t: float) -> tuple[Morceau, Morceau]:
    p01, p12, p23 = _lerp(m.p0, m.p1, t), _lerp(m.p1, m.p2, t), _lerp(m.p2, m.p3, t)
    p012, p123 = _lerp(p01, p12, t), _lerp(p12, p23, t)
    mid = _lerp(p012, p123, t)
    return Morceau(m.droit, m.p0, p01, p012, mid), Morceau(m.droit, mid, p123, p23, m.p3)


def _piece(m: Morceau, a: float, b: float) -> Morceau:
    """La portion de la courbe entre les paramètres a et b (de Casteljau), comme Cubic.piece."""
    left = _split(m, b)[0]
    if a > 0:
        left = _split(left, a / b)[1]
    return left


def _longueur(m: Morceau) -> float:
    return math.dist(m.p0, m.p1) + math.dist(m.p1, m.p2) + math.dist(m.p2, m.p3)


def morceaux(c: Contour) -> list[Morceau]:
    """Les segments d'un contour, en cubiques (un segment droit a ses contrôles alignés)."""
    out, cur = [], c.start
    for s in c.segs:
        if s[0] == "L":
            out.append(Morceau(True, cur, _lerp(cur, s[1], 1 / 3), _lerp(cur, s[1], 2 / 3), s[1]))
        else:
            out.append(Morceau(False, cur, s[1], s[2], s[3]))
        cur = s[-1]
    if c.closed and math.dist(cur, c.start) > 0.001:
        out.append(Morceau(True, cur, _lerp(cur, c.start, 1 / 3), _lerp(cur, c.start, 2 / 3), c.start))
    return out


def aplatir(c: Contour, tol: float = 0.25) -> list[Point]:
    """Polyligne d'un contour (écart à la courbe ≲ `tol`)."""
    pts = [c.start]
    for m in morceaux(c):
        if m.droit:
            pts.append(m.p3)
            continue
        n = max(2, math.ceil(math.sqrt(_longueur(m) / (8 * tol)) * 1.5))
        pts += [_point(m, k / n) for k in range(1, n + 1)]
    return pts


# ---------------------------------------------------------------------------
# Formes pleines : appartenance d'un point (règle non nulle), indexée par bandes
# ---------------------------------------------------------------------------

class Plein:
    """Une forme pleine posée devant : ses arêtes, rangées par bandes horizontales."""

    def __init__(self, contours: list[Contour]):
        self.aretes: list[tuple[float, float, float, float]] = []
        xs, ys = [], []
        for c in contours:
            pts = aplatir(c, 0.1)
            if math.dist(pts[0], pts[-1]) > 1e-9:
                pts.append(pts[0])
            for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
                if y0 != y1:
                    self.aretes.append((x0, y0, x1, y1))
            xs += [p[0] for p in pts]
            ys += [p[1] for p in pts]
        self.box = (min(xs), min(ys), max(xs), max(ys)) if xs else (0, 0, -1, -1)
        self.bandes: dict[int, list[tuple[float, float, float, float]]] = {}
        for e in self.aretes:
            lo, hi = min(e[1], e[3]), max(e[1], e[3])
            for b in range(int(math.floor(lo / BANDE)), int(math.floor(hi / BANDE)) + 1):
                self.bandes.setdefault(b, []).append(e)

    def contient(self, x: float, y: float) -> bool:
        x0, y0, x1, y1 = self.box
        if not (x0 <= x <= x1 and y0 <= y <= y1):
            return False
        w = 0
        for ax, ay, bx, by in self.bandes.get(int(math.floor(y / BANDE)), ()):
            if ay <= y:
                if by > y and (bx - ax) * (y - ay) - (x - ax) * (by - ay) > 0:
                    w += 1
            elif by <= y and (bx - ax) * (y - ay) - (x - ax) * (by - ay) < 0:
                w -= 1
        return w != 0


# ---------------------------------------------------------------------------
# Découpe (LineClipper)
# ---------------------------------------------------------------------------

class Decoupe:
    def __init__(self):
        self.devant: list[Plein] = []

    def cache(self, p: Point) -> bool:
        for o in self.devant:
            if o.contient(p[0], p[1]):
                return True
        return False

    def visibles(self, contours: list[Contour]) -> list[list[Morceau]]:
        """Les morceaux visibles de ces contours, en sous-tracés continus."""
        out: list[list[Morceau]] = []
        stylo = False          # le morceau précédent finissait au bout de sa courbe (penDown)

        def emettre(m: Morceau, a: float, b: float):
            nonlocal stylo
            if b <= a:
                return
            bout = _piece(m, a, b)
            if not (a == 0 and stylo) or not out:
                out.append([])
            out[-1].append(bout)
            stylo = b == 1

        for c in contours:
            stylo = False
            for m in morceaux(c):
                n = max(4, math.ceil(_longueur(m) / PAS))
                t0 = 0.0
                v0 = not self.cache(_point(m, 0))
                depuis = 0.0 if v0 else None
                if not v0:
                    stylo = False
                for k in range(1, n + 1):
                    t1 = k / n
                    v1 = not self.cache(_point(m, t1))
                    if v1 != v0:
                        lo, hi = t0, t1
                        for _ in range(DICHOTOMIE):
                            mid = (lo + hi) / 2
                            if (not self.cache(_point(m, mid))) == v0:
                                lo = mid
                            else:
                                hi = mid
                        coupe = (lo + hi) / 2
                        if depuis is not None:
                            emettre(m, depuis, coupe)
                            depuis = None
                        else:
                            depuis = coupe
                    t0, v0 = t1, v1
                if depuis is not None:
                    emettre(m, depuis, 1)
        return out


@dataclass
class Traits:
    """Ce que l'app affiche d'une page."""
    lignes: list[list[Morceau]]   # traits visibles (hors contours des encres)
    encres: list[Contour]         # aplats d'encre (leur contour est tracé par l'app)
    page: Page


def calculer(p: Page) -> Traits:
    """Traits visibles d'une page (parcours de l'avant vers le fond)."""
    dec = Decoupe()
    lignes: list[list[Morceau]] = []
    encres: list[Contour] = []
    for el in reversed(p.elements):
        if el.genre == "encre":
            encres = list(el.contours) + encres
            dec.devant.append(Plein(el.contours))
            continue
        vus = dec.visibles(el.contours)
        lignes = vus + lignes
        if el.genre in ("zone", "detail"):
            dec.devant.append(Plein(el.contours))
    return Traits(lignes, encres, p)


# ---------------------------------------------------------------------------
# Écriture (format lu par G.data dans l'app)
# ---------------------------------------------------------------------------

def _n(v: float) -> str:
    r = round(v, 1)
    return str(int(r)) if r == int(r) else f"{r:.1f}"


def _pt(p: Point) -> str:
    return f"{_n(p[0])} {_n(p[1])}"


def donnees_lignes(lignes: list[list[Morceau]]) -> str:
    parts = []
    for sous in lignes:
        parts.append("M " + _pt(sous[0].p0))
        for m in sous:
            if m.droit:
                parts.append("L " + _pt(m.p3))
            else:
                parts.append(f"C {_pt(m.p1)} {_pt(m.p2)} {_pt(m.p3)}")
    return " ".join(parts)


def donnees_contours(contours: list[Contour]) -> str:
    return " ".join(c.d() for c in contours)


def polylignes(lignes: list[list[Morceau]], tol: float = 0.2) -> list[list[Point]]:
    """Les traits en polylignes (pour la carte des zones et les aperçus)."""
    out = []
    for sous in lignes:
        pts = [sous[0].p0]
        for m in sous:
            if m.droit:
                pts.append(m.p3)
            else:
                n = max(2, math.ceil(math.sqrt(_longueur(m) / (8 * tol)) * 1.5))
                pts += [_point(m, k / n) for k in range(1, n + 1)]
        out.append(pts)
    return out


def element_contours(el: Element) -> list[Contour]:
    return el.contours
