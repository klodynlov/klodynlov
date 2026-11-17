"""Mise en scène d'un personnage sur un lieu : où il tombe, ce qui le cache (contrôles des ancres).

Le personnage type est celui des planches (`SILHOUETTE_*` de peinture.py) : une tête ronde et un
corps dans son carré 200 × 200, les pieds en y = 179. Posé à une ancre (x, y, taille t), un point
(u, v) de son carré tombe en (x + (u − 100)·t, y + (v − 200)·t) dans le repère du lieu.

On échantillonne sa silhouette et l'on regarde, point par point, si un aplat OPAQUE du lieu peint
APRÈS lui le recouvre (ordre `devant` : rien ; `dedans` : le calque « devant » ; `derriere` : tout
le lieu). De là, les règles de lecture d'une préposition (`problemes_scene`) :
  - jamais entièrement caché : on voit au moins un tiers de sa tête ;
  - dans (dedans) : quelque chose passe vraiment devant lui ;
  - derrière : le lieu en cache une bonne partie, et il a les pieds plus haut que le pied du lieu ;
  - sur : ses pieds reposent sur le lieu (pas en l'air, pas enfoncés dedans) ;
  - sous : le lieu est juste au-dessus de sa tête, et rien du lieu ne le cache ou presque ;
  - devant : ses pieds sont au moins aussi bas que le pied du lieu, et il en cache une partie ;
  - toujours dans le cadre des planches (−20…220 × −40…220).
Stdlib uniquement.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

from coloriages.dessin import relire

from .peinture import SILHOUETTE_CORPS, SILHOUETTE_TETE, Ancre, Op, Picto

PIEDS = 179.0                       # y des pieds dans le carré du personnage
CADRE = (-20.0, -40.0, 220.0, 220.0)  # cadre des scènes des planches (viewBox de svg_scene)
OPAQUE = 0x80                       # un aplat plus transparent (ombre au sol, reflet) ne cache rien


def vers_lieu(a: Ancre, u: float, v: float) -> tuple[float, float]:
    """Point (u, v) du carré du personnage → repère du lieu."""
    return a.x + (u - 100) * a.taille, a.y + (v - 200) * a.taille


def pieds(a: Ancre) -> float:
    """y des pieds du personnage, repère du lieu."""
    return vers_lieu(a, 100, PIEDS)[1]


def haut(a: Ancre) -> float:
    """y du haut de la tête du personnage type, repère du lieu."""
    cx, cy, r = SILHOUETTE_TETE
    return vers_lieu(a, cx, cy - r)[1]


def _dans_silhouette(u: float, v: float) -> str | None:
    cx, cy, r = SILHOUETTE_TETE
    if (u - cx) ** 2 + (v - cy) ** 2 <= r * r:
        return "tete"
    x, y, w, h, rx = SILHOUETTE_CORPS
    if not (x <= u <= x + w and y <= v <= y + h):
        return None
    # coins arrondis du corps
    qx = min(max(u, x + rx), x + w - rx)
    qy = min(max(v, y + rx), y + h - rx)
    return "corps" if (u - qx) ** 2 + (v - qy) ** 2 <= rx * rx else None


def silhouette(a: Ancre, pas: float = 2.5) -> list[tuple[float, float, str]]:
    """Points de la silhouette posée à l'ancre (repère du lieu), environ un tous les `pas`."""
    du = pas / a.taille
    out = []
    v = 34.0 + du / 2
    while v < PIEDS:
        u = 58.0 + du / 2
        while u < 142:
            partie = _dans_silhouette(u, v)
            if partie:
                x, y = vers_lieu(a, u, v)
                out.append((x, y, partie))
            u += du
        v += du
    return out


@dataclass
class _Aplat:
    """Un aplat opaque du lieu, prêt pour « ce point est-il dedans ? » (règle non nulle)."""
    aretes: list
    boite: tuple[float, float, float, float]
    calque: str

    def couvre(self, x: float, y: float) -> bool:
        x0, y0, x1, y1 = self.boite
        if not (x0 <= x <= x1 and y0 <= y <= y1):
            return False
        tours = 0
        for (ax, ay), (bx, by) in self.aretes:
            if ay <= y < by:
                if (bx - ax) * (y - ay) - (x - ax) * (by - ay) > 0:
                    tours += 1
            elif by <= y < ay:
                if (bx - ax) * (y - ay) - (x - ax) * (by - ay) < 0:
                    tours -= 1
        return tours != 0


@dataclass
class _Trait:
    segments: list
    demi: float
    boite: tuple[float, float, float, float]
    calque: str

    def couvre(self, x: float, y: float) -> bool:
        x0, y0, x1, y1 = self.boite
        if not (x0 - self.demi <= x <= x1 + self.demi and y0 - self.demi <= y <= y1 + self.demi):
            return False
        return any(_distance_segment(x, y, a, b) <= self.demi for a, b in self.segments)


def _distance_segment(x: float, y: float, a, b) -> float:
    vx, vy = b[0] - a[0], b[1] - a[1]
    n = vx * vx + vy * vy
    t = 0.0 if n == 0 else max(0.0, min(1.0, ((x - a[0]) * vx + (y - a[1]) * vy) / n))
    return math.hypot(x - a[0] - t * vx, y - a[1] - t * vy)


def _alpha(op: Op) -> int:
    return int(op.couleur[7:9], 16) if len(op.couleur) == 9 else 255


def aplats(lieu: Picto) -> list:
    """Les tracés OPAQUES du lieu, dans l'ordre de peinture."""
    out = []
    for op in lieu.ops:
        if _alpha(op) < OPAQUE:
            continue
        lignes = []
        for c in relire(op.d):
            pts = c.sample(8)
            if c.closed or op.genre == "plein":
                pts = pts + [pts[0]]
            lignes.append(pts)
        segs = [(p, q) for pts in lignes for p, q in zip(pts, pts[1:])]
        xs = [p[0] for pts in lignes for p in pts]
        ys = [p[1] for pts in lignes for p in pts]
        boite = (min(xs), min(ys), max(xs), max(ys))
        if op.genre == "plein":
            out.append(_Aplat(segs, boite, op.calque))
        else:
            out.append(_Trait(segs, op.largeur / 2, boite, op.calque))
    return out


def devant_le_personnage(lieu: Picto, a: Ancre) -> list:
    """Les tracés opaques peints APRÈS le personnage posé à `a`."""
    tous = aplats(lieu)
    if a.ordre == "devant":
        return []
    if a.ordre == "dedans":
        return [t for t in tous if t.calque == "devant"]
    return tous


@dataclass
class Scene:
    """Ce que l'on voit du personnage posé à une ancre."""
    cache: float          # part de la silhouette recouverte par le lieu (0…1)
    tete_visible: float   # part de la tête que l'on voit (0…1)
    recouvre: float       # part de la silhouette posée SUR le lieu (elle en cache une partie)
    boite: tuple[float, float, float, float]


def scene(lieu: Picto, preposition: str) -> Scene:
    a = lieu.ancres[preposition]
    pts = silhouette(a)
    avant = devant_le_personnage(lieu, a)
    tous = aplats(lieu)
    caches = [any(t.couvre(x, y) for t in avant) for x, y, _ in pts]
    tete = [c for c, (_, _, partie) in zip(caches, pts) if partie == "tete"]
    sur_lieu = sum(1 for x, y, _ in pts if any(t.couvre(x, y) for t in tous))
    xs, ys = [x for x, _, _ in pts], [y for _, y, _ in pts]
    return Scene(cache=sum(caches) / len(pts), tete_visible=1 - sum(tete) / max(1, len(tete)),
                 recouvre=sur_lieu / len(pts), boite=(min(xs), min(ys), max(xs), max(ys)))


def base(lieu: Picto) -> float:
    """y du pied du lieu : le plus bas de ses aplats opaques (l'ombre au sol n'en est pas)."""
    return max(t.boite[3] for t in aplats(lieu) if isinstance(t, _Aplat))


def _matiere(lieu: Picto, x: float, y0: float, y1: float, pas: float = 1.0) -> list[float]:
    """Les y de [y0, y1] où, à l'abscisse x, un aplat opaque du lieu est présent."""
    tous = [t for t in aplats(lieu) if isinstance(t, _Aplat)]
    out, y = [], y0
    while y <= y1:
        if any(t.couvre(x, y) for t in tous):
            out.append(y)
        y += pas
    return out


def problemes_scene(lieu: Picto) -> list[str]:
    """Les règles de lecture de chaque ancre du lieu (vide = la phrase se lit)."""
    out = []
    for prep, a in lieu.ancres.items():
        nom = f"{lieu.id} « {prep} »"
        s = scene(lieu, prep)
        x0, y0, x1, y1 = s.boite
        if x0 < CADRE[0] or y0 < CADRE[1] or x1 > CADRE[2] or y1 > CADRE[3]:
            out.append(f"{nom} : le personnage sort du cadre de la scène {tuple(round(v) for v in s.boite)}")
        if s.tete_visible < 0.34:
            out.append(f"{nom} : on ne voit que {s.tete_visible:.0%} de sa tête")
        yp = pieds(a)
        if a.ordre == "dedans" and prep == "dans" and s.cache < 0.1:
            out.append(f"{nom} : rien ne passe devant lui ({s.cache:.0%} caché)")
        if prep == "derriere":
            if s.cache < 0.2:
                out.append(f"{nom} : le lieu ne le cache presque pas ({s.cache:.0%})")
            if yp > base(lieu) - 4:
                out.append(f"{nom} : ses pieds ({yp:.0f}) ne sont pas plus haut que le pied du lieu")
        if prep == "sur":
            if not _matiere(lieu, a.x, yp - 3, yp + 6):
                out.append(f"{nom} : ses pieds ({a.x:.0f}, {yp:.0f}) ne reposent sur rien")
        if prep == "sous":
            dessus = _matiere(lieu, a.x, haut(a) - 40, haut(a) + 4)
            if not dessus:
                out.append(f"{nom} : rien du lieu au-dessus de sa tête")
            if s.cache > 0.12:
                out.append(f"{nom} : trop caché pour être « sous » ({s.cache:.0%})")
        if prep == "devant":
            if yp < base(lieu) - 2:
                out.append(f"{nom} : ses pieds ({yp:.0f}) sont plus haut que le pied du lieu ({base(lieu):.0f})")
            if s.recouvre < 0.15:
                out.append(f"{nom} : il ne cache presque rien du lieu ({s.recouvre:.0%})")
    return out


__all__ = ["CADRE", "Scene", "base", "haut", "pieds", "problemes_scene", "scene", "silhouette", "vers_lieu"]
