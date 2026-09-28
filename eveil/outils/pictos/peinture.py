"""Pictogrammes en couleur pour le train des phrases (Suite Éveil).

Un picto est une liste d'opérations peintes du fond vers l'avant, dans un carré
200 × 200 (y vers le bas) — le repère des dessins des mots (`WordArt` dans l'app) :

- `plein(couleur, *formes)` : aplat (règle non nulle) ;
- `trait(couleur, largeur, *formes)` : trait à bouts et jointures ronds.

Les formes sont celles de `coloriages.dessin` (cercle, ellipse, rect, poly, courbe,
tube, arc, ligne, goutte, coeur, etoile…), réduites à quatre commandes absolues
M, L, C, Z que l'app relit à l'identique (`PictoPath` en Swift).

Style commun (celui de `WordArt`) : formes pleines et arrondies, couleurs vives mais
accordées, pas de contour noir ; le sujet tient dans 16…184 ; une ombre douce au sol
(y ≈ 179) ; les yeux comme ceux du chat chef de gare (ovale sombre + reflet blanc).

Un LIEU (« la niche », « la table »…) porte en plus des ANCRES : où poser un
personnage « dans », « sur », « sous », « devant », « derrière » — le point bas-milieu du
personnage, sa taille (fraction du carré du lieu) et l'ordre de dessin :
  - `devant` : le lieu, puis le personnage ;
  - `dedans` : le calque « fond » du lieu, le personnage, puis le calque « devant »
    (le bord de la boîte, l'eau du bain passent devant lui) ;
  - `derriere` : le personnage, puis le lieu (il dépasse à peine).
Stdlib uniquement.
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from coloriages.dessin import Contour  # noqa: E402

TAILLE = 200.0
ENCRE = "#292B3D"          # l'encre des yeux et des petits traits (WordArtPaint.ink)
JOUE = "#FA8599"           # joues roses (WordArtPaint.blush), posées à 50 %
OMBRE = "#00000017"        # ombre au sol : noir à 9 %
PREPOSITIONS = ("dans", "sur", "sous", "devant", "derriere")
ORDRES = ("devant", "dedans", "derriere")
CALQUES = ("fond", "devant")

Forme = list  # liste de Contour


@dataclass
class Op:
    genre: str            # "plein" | "trait"
    couleur: str          # "#RRGGBB" ou "#RRGGBBAA"
    d: str                # données de chemin M/L/C/Z absolues, repère 200 × 200
    largeur: float = 0.0  # épaisseur d'un trait
    calque: str = "fond"  # lieux : "fond" (derrière le personnage) ou "devant"


@dataclass
class Ancre:
    x: float              # point bas-milieu du personnage, repère du lieu (200 × 200)
    y: float
    taille: float         # hauteur du personnage / côté du lieu (0,2 … 1,2)
    ordre: str            # "devant" | "dedans" | "derriere"


@dataclass
class Picto:
    id: str
    ops: list = field(default_factory=list)
    ancres: dict = field(default_factory=dict)   # préposition → Ancre (lieux seulement)

    # --- peindre -------------------------------------------------------------
    def plein(self, couleur: str, *formes: Forme, calque: str = "fond") -> Picto:
        self.ops.append(Op("plein", couleur, _d(formes), calque=calque))
        return self

    def trait(self, couleur: str, largeur: float, *formes: Forme, calque: str = "fond") -> Picto:
        self.ops.append(Op("trait", couleur, _d(formes), largeur=largeur, calque=calque))
        return self

    def ancre(self, preposition: str, x: float, y: float, taille: float, ordre: str) -> Picto:
        self.ancres[preposition] = Ancre(x, y, taille, ordre)
        return self


def _d(formes) -> str:
    return " ".join(c.d() for f in formes for c in f)


# ---------------------------------------------------------------------------
# Motifs communs (ceux de WordArtKit)
# ---------------------------------------------------------------------------

def ombre(p: Picto, cx: float = 100, cy: float = 179, rx: float = 70, ry: float = 7) -> None:
    from coloriages.dessin import ellipse
    p.plein(OMBRE, ellipse(cx, cy, rx, ry))


def oeil(p: Picto, x: float, y: float, r: float, ferme: bool = False, rieur: bool = False,
         regard: tuple[float, float] = (0, 0), calque: str = "fond") -> None:
    """L'œil de la famille de la mascotte : ovale sombre + reflet ; fermé : paupière ; rieur : ^."""
    from coloriages.dessin import courbe, ellipse
    if ferme:
        p.trait(ENCRE, max(1.6, r * 0.42), courbe([(x - r * 0.95, y), (x, y + r * 0.5), (x + r * 0.95, y)]),
                calque=calque)
    elif rieur:
        p.trait(ENCRE, max(1.6, r * 0.42),
                courbe([(x - r * 0.95, y + r * 0.35), (x, y - r * 0.55), (x + r * 0.95, y + r * 0.35)]), calque=calque)
    else:
        p.plein(ENCRE, ellipse(x, y, r * 0.84, r), calque=calque)
        p.plein("#FFFFFF", ellipse(x - r * 0.3 + regard[0], y - r * 0.38 + regard[1], r * 0.34, r * 0.34),
                calque=calque)


def joue(p: Picto, x: float, y: float, r: float, calque: str = "fond") -> None:
    from coloriages.dessin import cercle
    p.plein(JOUE + "80", cercle(x, y, r), calque=calque)


# ---------------------------------------------------------------------------
# Contrôles
# ---------------------------------------------------------------------------

COULEUR = re.compile(r"^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$")
NOMBRE = re.compile(r"-?\d+(?:\.\d+)?")


def points(d: str) -> list[tuple[float, float]]:
    nums = [float(v) for v in NOMBRE.findall(d)]
    return list(zip(nums[0::2], nums[1::2]))


def problemes(p: Picto, marge: float = 2.0) -> list[str]:
    """Contrôles d'un picto (vides = sain) : couleurs, chemins, cadre, ancres."""
    out = []
    if not re.match(r"^[a-z]+\.[a-z0-9_]+$", p.id):
        out.append(f"{p.id}: identifiant attendu « genre.nom » (minuscules)")
    if not p.ops:
        out.append(f"{p.id}: aucun tracé")
    for k, op in enumerate(p.ops):
        if op.genre not in ("plein", "trait"):
            out.append(f"{p.id}#{k}: genre {op.genre!r}")
        if not COULEUR.match(op.couleur):
            out.append(f"{p.id}#{k}: couleur {op.couleur!r}")
        if op.calque not in CALQUES:
            out.append(f"{p.id}#{k}: calque {op.calque!r}")
        if not op.d or not op.d.startswith("M"):
            out.append(f"{p.id}#{k}: chemin vide ou sans M")
        if set(re.sub(r"[-\d.\s]", "", op.d)) - set("MLCZ"):
            out.append(f"{p.id}#{k}: commandes hors M/L/C/Z")
        if op.genre == "trait" and not 0.5 <= op.largeur <= 40:
            out.append(f"{p.id}#{k}: épaisseur {op.largeur}")
        m = op.largeur / 2 if op.genre == "trait" else 0
        for x, y in points(op.d):
            if not (-marge <= x - m and x + m <= TAILLE + marge and -marge <= y - m and y + m <= TAILLE + marge):
                out.append(f"{p.id}#{k}: sort du cadre en ({x:.1f}, {y:.1f})")
                break
    for prep, a in p.ancres.items():
        if prep not in PREPOSITIONS:
            out.append(f"{p.id}: préposition {prep!r}")
        if a.ordre not in ORDRES:
            out.append(f"{p.id}: ordre {a.ordre!r} pour {prep}")
        if not (0 <= a.x <= TAILLE and 0 <= a.y <= TAILLE + 20):
            out.append(f"{p.id}: ancre {prep} hors du lieu")
        if not 0.15 <= a.taille <= 1.2:
            out.append(f"{p.id}: taille {a.taille} pour {prep}")
        if a.ordre == "dedans" and not any(op.calque == "devant" for op in p.ops):
            out.append(f"{p.id}: « {prep} » dedans, mais aucun calque « devant »")
    return out


# ---------------------------------------------------------------------------
# Aperçu SVG (planches à relire)
# ---------------------------------------------------------------------------

def _op_svg(op: Op) -> str:
    col, alpha = op.couleur[:7], (int(op.couleur[7:9], 16) / 255 if len(op.couleur) == 9 else 1)
    if op.genre == "plein":
        return f'<path d="{op.d}" fill="{col}" fill-opacity="{alpha:.3f}"/>'
    return (f'<path d="{op.d}" fill="none" stroke="{col}" stroke-opacity="{alpha:.3f}" '
            f'stroke-width="{op.largeur}" stroke-linecap="round" stroke-linejoin="round"/>')


def svg(p: Picto, taille: int = 200) -> str:
    """Le picto en SVG, sur fond blanc (planches à relire)."""
    corps = "".join(_op_svg(op) for op in p.ops)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="{taille}" height="{taille}">'
            f'<rect width="200" height="200" fill="#FFFFFF"/>{corps}</svg>')


def svg_scene(lieu: Picto, preposition: str, taille: int = 200) -> str:
    """Le lieu avec une silhouette posée à l'ancre de `preposition`, dans le bon ordre."""
    a = lieu.ancres[preposition]
    h = a.taille * 200
    w = h * 0.62
    x0, y0 = a.x - w / 2, a.y - h
    perso = (f'<g opacity="0.9"><rect x="{x0:.1f}" y="{y0 + h * 0.34:.1f}" width="{w:.1f}" height="{h * 0.66:.1f}" '
             f'rx="{w * 0.3:.1f}" fill="#FF5FA2"/><circle cx="{a.x:.1f}" cy="{y0 + h * 0.2:.1f}" r="{h * 0.2:.1f}" '
             f'fill="#FF5FA2"/></g>')

    def ops(calques):
        return "".join(_op_svg(op) for op in lieu.ops if op.calque in calques)
    if a.ordre == "devant":
        corps = ops(CALQUES) + perso
    elif a.ordre == "derriere":
        corps = perso + ops(CALQUES)
    else:
        corps = ops(("fond",)) + perso + ops(("devant",))
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-20 -40 240 260" width="{taille}" '
            f'height="{int(taille * 260 / 240)}"><rect x="-20" y="-40" width="240" height="260" fill="#FFFFFF"/>'
            f'{corps}</svg>')


def boite_englobante(p: Picto) -> tuple[float, float, float, float]:
    pts = [pt for op in p.ops for pt in points(op.d)]
    xs, ys = [x for x, _ in pts], [y for _, y in pts]
    return min(xs), min(ys), max(xs), max(ys)


def distance(a: tuple[float, float], b: tuple[float, float]) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


__all__ = ["Ancre", "Contour", "ENCRE", "JOUE", "OMBRE", "Op", "Picto", "boite_englobante", "joue", "oeil",
           "ombre", "problemes", "svg", "svg_scene"]
