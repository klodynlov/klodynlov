"""Petit langage de dessin pour les pages de l'Atelier de coloriage (Suite Éveil).

Une page est un empilement d'éléments, du fond vers l'avant — le même modèle que
`Sketch` dans l'app (eveil/ios/Sources/ColoringUI/Sketch.swift) :

- une ZONE (`zone(...)`) est une forme pleine : elle cache ce qui est derrière, et son
  contour n'est tracé que là où il se voit ; chaque aire fermée devient une zone à remplir ;
- un DÉTAIL (`detail(...)`) est une petite zone VOULUE (œil, bouton) : la seule qui peut
  faire moins de 0,3 % de la page ;
- un TRAIT (`trait(...)`) est une ligne (sourire, moustaches…) : il ne cache rien, et les
  formes posées devant lui le coupent ;
- une ENCRE (`encre(...)`) est un aplat de la couleur du trait (pupille, truffe) : rien ne
  doit la recouvrir.

Repère : carré 1000 × 1000, y vers le bas (comme SwiftUI) — c'est l'échelle de travail
de `Sketch` (× 1000 du carré unité). Toute forme est réduite à quatre commandes
absolues — M, L, C, Z — que `G.data` relit à l'identique dans l'app.

Les traits visibles sont calculés ici (`traits.py`, même algorithme que `LineClipper`)
et la carte des zones est simulée (`zones.py`, même règles que `ZoneMap`). Stdlib uniquement.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

Point = tuple[float, float]

K = 0.5522847498  # courbe de Bézier ≈ quart de cercle
TRAIT = 0.012     # épaisseur du trait affiché, en unité de page (ColoringPage.lineWidth par défaut)


# ---------------------------------------------------------------------------
# Contours
# ---------------------------------------------------------------------------

@dataclass
class Contour:
    """Suite de segments depuis `start` : ("L", p) ou ("C", c1, c2, p)."""
    start: Point
    segs: list = field(default_factory=list)
    closed: bool = True

    def map(self, f) -> Contour:
        segs = [("L", f(s[1])) if s[0] == "L" else ("C", f(s[1]), f(s[2]), f(s[3])) for s in self.segs]
        return Contour(f(self.start), segs, self.closed)

    def end(self) -> Point:
        return self.segs[-1][-1] if self.segs else self.start

    def reversed(self) -> Contour:
        pts = [self.start] + [s[-1] for s in self.segs]
        segs = []
        for i in range(len(self.segs) - 1, -1, -1):
            s, a = self.segs[i], pts[i]
            segs.append(("L", a) if s[0] == "L" else ("C", s[2], s[1], a))
        return Contour(self.end(), segs, self.closed)

    def sample(self, n: int = 10) -> list[Point]:
        """Polyligne approchée (n points par courbe)."""
        out, p = [self.start], self.start
        for s in self.segs:
            if s[0] == "L":
                out.append(s[1])
            else:
                c1, c2, q = s[1], s[2], s[3]
                for i in range(1, n + 1):
                    t = i / n
                    u = 1 - t
                    out.append((u**3 * p[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t**3 * q[0],
                                u**3 * p[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t**3 * q[1]))
            p = s[-1]
        return out

    def area(self) -> float:
        """Aire signée (y vers le bas : positive = sens horaire à l'écran)."""
        pts = self.sample()
        return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))

    def d(self) -> str:
        parts = [f"M {_n(self.start[0])} {_n(self.start[1])}"]
        for s in self.segs:
            if s[0] == "L":
                parts.append(f"L {_n(s[1][0])} {_n(s[1][1])}")
            else:
                parts.append("C " + " ".join(f"{_n(v[0])} {_n(v[1])}" for v in s[1:]))
        if self.closed:
            parts.append("Z")
        return " ".join(parts)


def _n(v: float) -> str:
    r = round(v, 1)
    return str(int(r)) if r == int(r) else f"{r:.1f}"


def _outer(c: Contour) -> Contour:
    """Oriente un contour fermé dans le sens « plein » (aire positive)."""
    return c if c.area() >= 0 else c.reversed()


Forme = list  # list[Contour]


# ---------------------------------------------------------------------------
# Primitives (toutes renvoient une liste de contours)
# ---------------------------------------------------------------------------

def ellipse(cx: float, cy: float, rx: float, ry: float | None = None, rot: float = 0.0) -> Forme:
    ry = rx if ry is None else ry
    pts = [(cx + rx, cy), (cx, cy + ry), (cx - rx, cy), (cx, cy - ry)]
    ctl = [((cx + rx, cy + K * ry), (cx + K * rx, cy + ry)),
           ((cx - K * rx, cy + ry), (cx - rx, cy + K * ry)),
           ((cx - rx, cy - K * ry), (cx - K * rx, cy - ry)),
           ((cx + K * rx, cy - ry), (cx + rx, cy - K * ry))]
    c = Contour(pts[0], [("C", ctl[i][0], ctl[i][1], pts[(i + 1) % 4]) for i in range(4)])
    return tourne([c], rot, cx, cy) if rot else [c]


def cercle(cx: float, cy: float, r: float) -> Forme:
    return ellipse(cx, cy, r, r)


def rect(x: float, y: float, w: float, h: float, r: float = 0.0) -> Forme:
    r = max(0.0, min(r, w / 2, h / 2))
    if r == 0:
        return poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])
    k = K * r
    c = Contour((x + r, y), [
        ("L", (x + w - r, y)), ("C", (x + w - r + k, y), (x + w, y + r - k), (x + w, y + r)),
        ("L", (x + w, y + h - r)), ("C", (x + w, y + h - r + k), (x + w - r + k, y + h), (x + w - r, y + h)),
        ("L", (x + r, y + h)), ("C", (x + r - k, y + h), (x, y + h - r + k), (x, y + h - r)),
        ("L", (x, y + r)), ("C", (x, y + r - k), (x + r - k, y), (x + r, y)),
    ])
    return [c]


def poly(pts: list[Point], r: float | list[float] = 0.0) -> Forme:
    """Polygone fermé ; `r` arrondit les coins (un rayon, ou un par sommet)."""
    n = len(pts)
    rs = [r] * n if isinstance(r, (int, float)) else list(r)
    if all(v <= 0 for v in rs):
        return [_outer(Contour(pts[0], [("L", p) for p in pts[1:]]))]
    corners = []
    for i in range(n):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
        la, lb = _dist(p0, p1), _dist(p1, p2)
        rr = min(rs[i], 0.45 * la, 0.45 * lb)
        a = _lerp(p1, p0, rr / la)
        b = _lerp(p1, p2, rr / lb)
        corners.append((a, p1, b, rr))
    start = corners[-1][2]
    segs = []
    for a, p, b, rr in corners:
        segs.append(("L", a))
        if rr > 0:
            segs.append(("C", _lerp(a, p, 2 / 3), _lerp(b, p, 2 / 3), b))
    return [_outer(Contour(start, segs))]


def arche(x: float, y: float, w: float, h: float) -> Forme:
    """Rectangle surmonté d'un demi-cercle (porte, fenêtre) ; (x, y) = coin haut gauche."""
    r = w / 2
    a = arc(x + r, y + r, r, 180, 360)[0]
    c = Contour((x, y + h), [("L", (x, y + r))] + a.segs + [("L", (x + w, y + h))])
    return [_outer(c)]


def lisse(pts: list[Point], tension: float = 1.0) -> Forme:
    """Courbe fermée douce passant par tous les points (Catmull-Rom)."""
    n = len(pts)
    t = tension / 6
    segs = []
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) * t, p1[1] + (p2[1] - p0[1]) * t)
        c2 = (p2[0] - (p3[0] - p1[0]) * t, p2[1] - (p3[1] - p1[1]) * t)
        segs.append(("C", c1, c2, p2))
    return [_outer(Contour(pts[0], segs))]


def courbe(pts: list[Point], tension: float = 1.0) -> Forme:
    """Ligne ouverte douce passant par les points (pour les traits)."""
    t = tension / 6
    ext = [pts[0]] + list(pts) + [pts[-1]]
    segs = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        c1 = (p1[0] + (p2[0] - p0[0]) * t, p1[1] + (p2[1] - p0[1]) * t)
        c2 = (p2[0] - (p3[0] - p1[0]) * t, p2[1] - (p3[1] - p1[1]) * t)
        segs.append(("C", c1, c2, p2))
    return [Contour(pts[0], segs, closed=False)]


def ligne(*pts: Point) -> Forme:
    return [Contour(pts[0], [("L", p) for p in pts[1:]], closed=False)]


def arc(cx: float, cy: float, rx: float, a0: float, a1: float, ry: float | None = None) -> Forme:
    """Arc ouvert d'ellipse, angles en degrés (0 = droite, 90 = bas)."""
    ry = rx if ry is None else ry
    n = max(1, math.ceil(abs(a1 - a0) / 90))
    step = (a1 - a0) / n
    segs, start = [], None
    for i in range(n):
        t1, t2 = math.radians(a0 + i * step), math.radians(a0 + (i + 1) * step)
        k = 4 / 3 * math.tan((t2 - t1) / 4)
        p1 = (cx + rx * math.cos(t1), cy + ry * math.sin(t1))
        p2 = (cx + rx * math.cos(t2), cy + ry * math.sin(t2))
        c1 = (p1[0] - k * rx * math.sin(t1), p1[1] + k * ry * math.cos(t1))
        c2 = (p2[0] + k * rx * math.sin(t2), p2[1] - k * ry * math.cos(t2))
        start = start or p1
        segs.append(("C", c1, c2, p2))
    return [Contour(start, segs, closed=False)]


def secteur(cx: float, cy: float, rx: float, a0: float, a1: float, ry: float | None = None) -> Forme:
    """Part de disque/ellipse fermée (arc + deux rayons)."""
    a = arc(cx, cy, rx, a0, a1, ry)[0]
    c = Contour((cx, cy), [("L", a.start)] + a.segs)
    return [_outer(c)]


def corde(cx: float, cy: float, rx: float, a0: float, a1: float, ry: float | None = None) -> Forme:
    """Segment de disque fermé par sa corde (dôme, demi-lune)."""
    a = arc(cx, cy, rx, a0, a1, ry)[0]
    return [_outer(Contour(a.start, a.segs + [("L", a.start)]))]


def nuage(cx: float, cy: float, rx: float, ry: float, bosses: int = 7, hauteur: float = 0.8,
          depart: float = 0.0) -> Forme:
    """Nuage d'un seul contour : des bosses posées sur une ellipse (pas de traits intérieurs)."""
    base = [(cx + rx * math.cos(math.radians(depart + 360 * i / bosses)),
             cy + ry * math.sin(math.radians(depart + 360 * i / bosses))) for i in range(bosses)]
    segs = []
    for i in range(bosses):
        p, q = base[i], base[(i + 1) % bosses]
        m = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
        vx, vy = q[0] - p[0], q[1] - p[1]
        ln = math.hypot(vx, vy)
        nx, ny = vy / ln, -vx / ln
        if nx * (m[0] - cx) + ny * (m[1] - cy) < 0:
            nx, ny = -nx, -ny
        h = 4 / 3 * (ln / 2) * hauteur
        segs.append(("C", (p[0] + nx * h, p[1] + ny * h), (q[0] + nx * h, q[1] + ny * h), q))
    return [_outer(Contour(base[0], segs))]


def etoile(cx: float, cy: float, r: float, ri: float | None = None, n: int = 5, coins: float = 10.0,
           rot: float = -90.0) -> Forme:
    ri = r * 0.46 if ri is None else ri
    pts = []
    for i in range(2 * n):
        a = math.radians(rot + 180 * i / n)
        rr = r if i % 2 == 0 else ri
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return poly(pts, r=coins)


def coeur(cx: float, cy: float, s: float) -> Forme:
    """Cœur de largeur ≈ 2 s, pointe en bas."""
    top = (cx, cy - 0.45 * s)
    bottom = (cx, cy + 0.95 * s)
    c = Contour(top, [
        ("C", (cx + 0.1 * s, cy - 1.05 * s), (cx + 1.1 * s, cy - 0.95 * s), (cx + 1.0 * s, cy - 0.15 * s)),
        ("C", (cx + 0.95 * s, cy + 0.35 * s), (cx + 0.4 * s, cy + 0.6 * s), bottom),
        ("C", (cx - 0.4 * s, cy + 0.6 * s), (cx - 0.95 * s, cy + 0.35 * s), (cx - 1.0 * s, cy - 0.15 * s)),
        ("C", (cx - 1.1 * s, cy - 0.95 * s), (cx - 0.1 * s, cy - 1.05 * s), top),
    ])
    return [_outer(c)]


def tube(pts: list[Point], largeur: float | list[float], tension: float = 1.0) -> Forme:
    """Boudin d'un seul contour autour d'une ligne douce (tuyau, queue, cou, serpent…).

    `largeur` : épaisseur constante, ou une par point (pour effiler). Bouts arrondis.
    """
    n = len(pts)
    ws = [largeur] * n if isinstance(largeur, (int, float)) else list(largeur)
    normals = []
    for i in range(n):
        a, b = pts[max(0, i - 1)], pts[min(n - 1, i + 1)]
        tx, ty = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(tx, ty)
        normals.append((-ty / ln, tx / ln))
    left = [(p[0] + nx * w / 2, p[1] + ny * w / 2) for p, (nx, ny), w in zip(pts, normals, ws)]
    right = [(p[0] - nx * w / 2, p[1] - ny * w / 2) for p, (nx, ny), w in zip(pts, normals, ws)]
    segs = courbe(left, tension)[0].segs
    segs += _bout(pts[-1], normals[-1], ws[-1] / 2, (pts[-1][0] - pts[-2][0], pts[-1][1] - pts[-2][1]))
    segs += courbe(right[::-1], tension)[0].segs
    segs += _bout(pts[0], (-normals[0][0], -normals[0][1]), ws[0] / 2,
                  (pts[0][0] - pts[1][0], pts[0][1] - pts[1][1]))
    return [_outer(Contour(left[0], segs))]


def _bout(c: Point, n: Point, r: float, t: Point) -> list:
    """Demi-cercle de c + n·r à c − n·r, bombé dans la direction t."""
    a0 = math.degrees(math.atan2(n[1], n[0]))
    sweep = 180 if (-n[1]) * t[0] + n[0] * t[1] > 0 else -180
    return arc(c[0], c[1], r, a0, a0 + sweep)[0].segs


def goutte(cx: float, cy: float, r: float, h: float | None = None) -> Forme:
    """Goutte d'eau, pointe en haut ; (cx, cy) = centre du rond, `h` = hauteur de la pointe."""
    h = 2.2 * r if h is None else h
    tip = (cx, cy - h)
    c = Contour(tip, [
        ("C", (cx + 0.35 * r, cy - 0.6 * h), (cx + r, cy - 0.55 * r), (cx + r, cy)),
        ("C", (cx + r, cy + K * r), (cx + K * r, cy + r), (cx, cy + r)),
        ("C", (cx - K * r, cy + r), (cx - r, cy + K * r), (cx - r, cy)),
        ("C", (cx - r, cy - 0.55 * r), (cx - 0.35 * r, cy - 0.6 * h), tip),
    ])
    return [_outer(c)]


# ---------------------------------------------------------------------------
# Transformations
# ---------------------------------------------------------------------------

def deplace(f: Forme, dx: float, dy: float) -> Forme:
    return [c.map(lambda p: (p[0] + dx, p[1] + dy)) for c in f]


def echelle(f: Forme, sx: float, sy: float | None = None, cx: float = 500, cy: float = 500) -> Forme:
    sy = sx if sy is None else sy
    out = [c.map(lambda p: (cx + (p[0] - cx) * sx, cy + (p[1] - cy) * sy)) for c in f]
    return [c.reversed() for c in out] if sx * sy < 0 else out


def tourne(f: Forme, deg: float, cx: float = 500, cy: float = 500) -> Forme:
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    return [c.map(lambda p: (cx + (p[0] - cx) * ca - (p[1] - cy) * sa,
                             cy + (p[0] - cx) * sa + (p[1] - cy) * ca)) for c in f]


def miroir(f: Forme, x: float = 500) -> Forme:
    """Symétrique par rapport à la verticale x (orientation conservée)."""
    return echelle(f, -1, 1, cx=x)


def trou(f: Forme) -> Forme:
    """Contour(s) retourné(s) : percent la zone qui les contient."""
    return [c.reversed() if c.area() > 0 else c for c in f]


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

@dataclass
class Element:
    genre: str            # "zone" | "detail" | "trait" | "encre"
    contours: list


def zone(*formes: Forme) -> Element:
    return Element("zone", [c for f in formes for c in f])


def detail(*formes: Forme) -> Element:
    """Petite zone voulue (œil, bouton…) : permise sous 0,3 % de la page."""
    return Element("detail", [c for f in formes for c in f])


def trait(*formes: Forme) -> Element:
    return Element("trait", [c for f in formes for c in f])


fin = trait  # (ancien nom : dans l'app, tous les traits ont l'épaisseur de la page)


def encre(*formes: Forme) -> Element:
    """Aplat de la couleur du trait (pupille, truffe) ; rien ne doit passer devant."""
    return Element("encre", [c for f in formes for c in f])


PLEINS = ("zone", "detail", "encre")   # éléments qui cachent ce qui est derrière

# Les albums du choix des pages (identifiants partagés avec ColoringAlbums.swift).
ALBUMS = ("train", "animaux", "jardin", "maison", "miam", "route", "fete")


@dataclass
class Page:
    id: str
    album: str
    fr: str
    en: str
    elements: list
    trait: float = TRAIT


def page(id: str, album: str, fr: str, en: str, *elements: Element, trait: float = TRAIT) -> Page:
    assert album in ALBUMS, album
    return Page(id, album, fr, en, list(elements), trait)


def d(el: Element) -> str:
    return " ".join(c.d() for c in el.contours)


def relire(data: str) -> list[Contour]:
    """Relit un tracé émis — même algorithme que `PathData.path` côté Swift."""
    out: list[Contour] = []
    cmd, nums, cur = "M", [], None
    for tok in data.split(" "):
        if tok and tok[0].isalpha():
            cmd, nums = tok, []
            if tok == "Z" and cur is not None:
                cur.closed = True
            continue
        nums.append(float(tok))
        if cmd == "M" and len(nums) == 2:
            cur = Contour((nums[0], nums[1]), [], closed=False)
            out.append(cur)
            cmd, nums = "L", []
        elif cmd == "L" and len(nums) == 2:
            cur.segs.append(("L", (nums[0], nums[1])))
            nums = []
        elif cmd == "C" and len(nums) == 6:
            cur.segs.append(("C", (nums[0], nums[1]), (nums[2], nums[3]), (nums[4], nums[5])))
            nums = []
    return out


# ---------------------------------------------------------------------------
# Contrôles géométriques (utilisés par les tests)
# ---------------------------------------------------------------------------

def aire(el: Element) -> float:
    """Aire remplie d'une zone (règle non nulle ≈ somme des aires signées, trous déduits)."""
    return sum(c.area() for c in el.contours)


def croisements(contours: list[Contour], n: int = 10) -> list[Point]:
    """Points où des contours d'une même zone se coupent (eux-mêmes ou entre eux)."""
    segs = []
    for ci, c in enumerate(contours):
        pts = c.sample(n)
        if c.closed:
            pts = pts + [pts[0]]
        for j in range(len(pts) - 1):
            if _dist(pts[j], pts[j + 1]) > 1e-6:
                segs.append((ci, j, len(pts) - 1, pts[j], pts[j + 1]))
    grid: dict[tuple[int, int], list[int]] = {}
    cell = 25.0
    for k, (_, _, _, a, b) in enumerate(segs):
        for gx in range(int(min(a[0], b[0]) // cell), int(max(a[0], b[0]) // cell) + 1):
            for gy in range(int(min(a[1], b[1]) // cell), int(max(a[1], b[1]) // cell) + 1):
                grid.setdefault((gx, gy), []).append(k)
    found, seen = [], set()
    for ids in grid.values():
        for x in range(len(ids)):
            for y in range(x + 1, len(ids)):
                i, j = ids[x], ids[y]
                if (i, j) in seen:
                    continue
                seen.add((i, j))
                ci, ji, ni, a, b = segs[i]
                cj, jj, nj, c, e = segs[j]
                if ci == cj and (abs(ji - jj) <= 1 or {ji, jj} == {0, ni - 1}):
                    continue  # segments voisins d'un même contour
                p = _intersect(a, b, c, e)
                if p is not None:
                    found.append(p)
    return found


def bornes(el: Element) -> tuple[float, float, float, float]:
    xs, ys = [], []
    for c in el.contours:
        for p in c.sample(6):
            xs.append(p[0])
            ys.append(p[1])
    return min(xs), min(ys), max(xs), max(ys)


def _intersect(a: Point, b: Point, c: Point, d_: Point) -> Point | None:
    """Intersection propre (les deux segments se traversent strictement)."""
    r = (b[0] - a[0], b[1] - a[1])
    s = (d_[0] - c[0], d_[1] - c[1])
    den = r[0] * s[1] - r[1] * s[0]
    if abs(den) < 1e-9:
        return None
    t = ((c[0] - a[0]) * s[1] - (c[1] - a[1]) * s[0]) / den
    u = ((c[0] - a[0]) * r[1] - (c[1] - a[1]) * r[0]) / den
    eps = 1e-6
    if eps < t < 1 - eps and eps < u < 1 - eps:
        return (a[0] + t * r[0], a[1] + t * r[1])
    return None


def _dist(a: Point, b: Point) -> float:
    return math.hypot(b[0] - a[0], b[1] - a[1])


def _lerp(a: Point, b: Point, t: float) -> Point:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)

ENCRE = "#2E334A"   # EveilPalette.ink
