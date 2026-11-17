"""« Le dessin prend vie » : les parties nommées bougent avec les couleurs de l'enfant.

Choix de l'utilisateur (28/09/2026) pour la suite de l'atelier. Quand l'enfant touche « J'ai fini ! »
(mode interactif), les parties d'un dessin bougent quelques secondes, avec SES couleurs : les roues
tournent, le soleil bat, la queue remue, les ailes battent, le feuillage se balance, les nuages
glissent (docs/EVEIL.md § 6.4 : les couleurs de l'enfant habillent un pantin préparé d'avance ;
ni IA, ni tirage au hasard).

Ce module est la RÉFÉRENCE de l'algorithme de l'app (ColoringUI/LivingDrawing.swift) et son banc
d'essai visuel (`python3 -m coloriages.vivant --planche DOSSIER`) :

1. **Le mouvement d'une partie** vient de son nom (table `MOUVEMENTS`, corrigée page par page si
   besoin : la queue d'un avion ne remue pas) et part dans PagesDessins.swift avec la partie.
2. **Les pièces** : les zones d'une partie qui se touchent (de part et d'autre d'un trait) forment
   une pièce ; s'y ajoutent les zones sans nom qui ne tiennent qu'à elle (le bout de la queue) et
   tout ce qu'elle enferme (taches, yeux, encre) : sa silhouette.
3. **L'attache** d'une pièce qui se balance : le milieu de son contact avec le reste du dessin (ni
   le fond, ni l'herbe, ni le ciel, ni une autre pièce qui bouge) ; faute de contact, le milieu de
   son bas (un buisson se balance sur le sol). Tourner et battre se font autour du centre.
4. **Le rendu** : la pièce est découpée (ses couleurs, ses traits) ; dessous, son emplacement est
   rebouché avec les couleurs voisines, sans traits ; la pièce bouge par-dessus. Battre ne fait
   que grandir (jamais plus petit qu'au repos) : rien ne se découvre.

Stdlib uniquement.
"""
from __future__ import annotations

import argparse
import math
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path

from . import analyse, catalogue, zones
from .apercu import ENCRE_RGB, _masque, ecrire_png
from .dessin import PALETTE_RGB
from .zones import COIN

# Le fond : jamais une attache, jamais une pièce.
SOL = frozenset({"le ciel", "l'herbe", "la mer", "l'eau", "le sable"})

# Mouvement d'une partie d'après son nom : (genre, amplitude).
# - « roule » : une roue tourne, un tour en PERIODES["roule"] secondes ; seul le disque intérieur
#   tourne (rayons, moyeu, coups de pinceau) : un bord uni ne montre rien, et une roue entamée par
#   le sol n'a pas d'encoche ;
# - « tourne » : toute la pièce tourne sur elle-même (le tee-shirt dans la machine) ;
# - « bat » : grandit de `amplitude` (0,12 = +12 %) puis revient, jamais plus petit ;
# - « balance » : se balance de ± `amplitude` degrés autour de son attache ; un troisième terme la
#   précise : « suspendue » (depuis son haut, comme une serviette à son crochet, quand le contact ne
#   dit rien : un mur carrelé) ou le nom de la partie qui la porte (le feuillage tient au tronc, pas
#   à la tête de la biche qui le frôle) ;
# - « glisse » / « flotte » : va et vient de ± `amplitude` (unité de page), en largeur / en hauteur.
MOUVEMENTS = {
    "la roue": ("roule", 1.0), "les roues": ("roule", 1.0),
    "le soleil": ("bat", 0.12), "la lune": ("bat", 0.08), "le cœur": ("bat", 0.14), "l'étoile": ("bat", 0.14),
    "la fleur": ("bat", 0.10), "la marguerite": ("bat", 0.08), "la tulipe": ("bat", 0.08),
    "la cerise": ("bat", 0.12), "la balle": ("bat", 0.12), "le nœud": ("bat", 0.10), "la couronne": ("bat", 0.08),
    "le gyrophare": ("bat", 0.18), "l'étoile de mer": ("bat", 0.10), "le jaune de l'œuf": ("bat", 0.10),
    "la queue": ("balance", 14.0), "les ailes": ("balance", 14.0), "les ailes du haut": ("balance", 10.0),
    "les ailes du bas": ("balance", 8.0), "les oreilles": ("balance", 8.0), "la flamme": ("balance", 7.0),
    "les feuilles": ("balance", 6.0, "le tronc"), "le sapin": ("balance", 5.0, "le tronc"),
    "le buisson": ("balance", 6.0),
    "les buissons": ("balance", 6.0),
    "le nuage": ("glisse", 0.02), "les ballons": ("flotte", 0.018), "le canard": ("flotte", 0.012),
    "le ballon": ("bat", 0.10), "la tache": ("bat", 0.10), "le savon": ("bat", 0.08), "la mousse": ("bat", 0.05),
    "les os": ("bat", 0.08), "le poussin": ("bat", 0.08), "les lèvres": ("bat", 0.08),
    "la feuille": ("balance", 8.0), "la serviette": ("balance", 6.0, "suspendue"), "le dentifrice": ("bat", 0.08),
    "les saucisses": ("bat", 0.06), "les bougies": ("bat", 0.08),
}
# Les corrections d'une page : la queue de l'avion ne remue pas ; la coccinelle respire
# (et sa feuille, qui la porte, ne bouge pas) ; le tee-shirt tourne dans la machine ; la flèche
# vibre dans la cible.
PAR_PAGE = {
    "avion": {"la queue": None},
    "coccinelle": {"la coccinelle": ("bat", 0.08), "la feuille": None},
    "machine": {"le tee-shirt": ("tourne", 1.0)},
    "fleche": {"la flèche": ("balance", 5.0)},
}
# Périodes (secondes) : assez lent pour qu'un petit suive des yeux. Une roue fait 3 tours pendant
# la fête, le tee-shirt 2 : un nombre entier de tours, pour se reposer là où elle était (sans saut).
PERIODES = {"roule": 1.8, "tourne": 2.7, "bat": 0.7, "balance": 0.8, "glisse": 3.0, "flotte": 1.4}
DUREE = 6.0           # la fête dure 6 s : montée 0,4 s, descente 0,8 s
MONTEE, DESCENTE = 0.4, 0.8


def mouvement(page, fr: str):
    """Le mouvement d'une partie (None : elle ne bouge pas seule) ; une page peut corriger la table."""
    if fr in SOL:
        return None
    propre = PAR_PAGE.get(page.id, {})
    return propre[fr] if fr in propre else MOUVEMENTS.get(fr)


SWIFT = {"roule": ".roll", "tourne": ".spin", "bat": ".pulse", "balance": ".sway", "glisse": ".drift",
         "flotte": ".float"}


def swift(m) -> str:
    """Le mouvement en Swift (`PartMotion`), tel qu'il part dans PagesDessins.swift."""
    genre, amplitude = m[0], m[1]
    if genre in ("roule", "tourne"):
        return SWIFT[genre]
    if genre == "balance" and len(m) > 2:
        attache = ".top" if m[2] == "suspendue" else f'.part("{m[2]}")'
        return f"{SWIFT[genre]}({amplitude:g}, pivot: {attache})"
    return f"{SWIFT[genre]}({amplitude:g})"


# ---------------------------------------------------------------------------
# Le temps : une enveloppe douce, et les transformations (fonctions pures)
# ---------------------------------------------------------------------------

def enveloppe(t: float) -> float:
    """0 → 1 en MONTEE s, 1, puis 1 → 0 sur les DESCENTE dernières secondes (0 hors de la fête)."""
    if t <= 0 or t >= DUREE:
        return 0.0
    return min(1.0, t / MONTEE, (DUREE - t) / DESCENTE)


def _tours(t: float) -> float:
    """Chemin parcouru par une roue (intégrale de l'enveloppe) : elle démarre et s'arrête en douceur."""
    t = min(max(t, 0.0), DUREE)
    b = DUREE - DESCENTE
    if t <= MONTEE:
        return t * t / (2 * MONTEE)
    s = MONTEE / 2 + (min(t, b) - MONTEE)
    if t > b:
        u = t - b
        s += u - u * u / (2 * DESCENTE)
    return s


def transformation(genre: str, amplitude: float, t: float, phase: float = 0.0, signe: float = 1.0):
    """(angle en radians, échelle, dx, dy) d'une pièce à l'instant t (repos : (0, 1, 0, 0))."""
    e = enveloppe(t)
    if e == 0:
        return (0.0, 1.0, 0.0, 0.0)
    p = PERIODES[genre]
    if genre in ("roule", "tourne"):
        return (2 * math.pi * _tours(t) / p, 1.0, 0.0, 0.0)
    if genre == "bat":
        return (0.0, 1 + amplitude * e * (0.5 - 0.5 * math.cos(2 * math.pi * t / p + phase)), 0.0, 0.0)
    onde = math.sin(2 * math.pi * t / p + phase)
    if genre == "balance":
        return (math.radians(amplitude) * e * onde * signe, 1.0, 0.0, 0.0)
    if genre == "glisse":
        return (0.0, 1.0, amplitude * e * onde, 0.0)
    if genre == "flotte":
        return (0.0, 1.0, 0.0, -amplitude * e * abs(onde))
    raise ValueError(genre)


# ---------------------------------------------------------------------------
# Les pièces : zones voisines, silhouettes, attaches
# ---------------------------------------------------------------------------

@dataclass
class Voisinage:
    """Qui touche qui, de part et d'autre d'un trait, et où (somme des pixels de contact)."""
    voisins: dict = field(default_factory=dict)     # zone → {zones voisines}
    contacts: dict = field(default_factory=dict)    # (zone, voisine) → [Σx, Σy, n] côté `zone`


def voisinage(c: zones.Carte, portee: int) -> Voisinage:
    """Pour chaque pixel de bord d'une zone, on traverse le trait (au plus `portee` px) tout droit."""
    W, H, lab = c.W, c.H, c.labels
    v = Voisinage()
    for i, z in enumerate(lab):
        if not z:
            continue
        x, y = i % W, i // W
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < W and 0 <= ny < H) or lab[ny * W + nx]:
                continue
            for _ in range(portee):
                nx += dx
                ny += dy
                if not (0 <= nx < W and 0 <= ny < H):
                    break
                z2 = lab[ny * W + nx]
                if z2:
                    if z2 != z:
                        v.voisins.setdefault(z, set()).add(z2)
                        s = v.contacts.setdefault((z, z2), [0, 0, 0])
                        s[0] += x
                        s[1] += y
                        s[2] += 1
                    break
    return v


@dataclass
class Piece:
    partie: str
    genre: str
    amplitude: float
    zones: set
    boite: tuple                  # (x0, y0, x1, y1) en pixels, x1/y1 exclus
    silhouette: bytearray         # 1 = dans la silhouette (sur la boîte)
    centre: tuple                 # centre de la silhouette (pixels)
    attache: tuple                # pivot (pixels)
    rayon: float = 0.0            # « roule » : rayon du disque intérieur (centre = `attache`)
    suspendue: bool = False       # « balance » depuis le haut de la pièce
    porteur: str | None = None    # « balance » : la partie qui la porte (le tronc)
    signe: float = 1.0
    phase: float = 0.0


def _boites(c: zones.Carte) -> dict:
    b = {}
    W = c.W
    for i, z in enumerate(c.labels):
        if z:
            x, y = i % W, i // W
            if z in b:
                q = b[z]
                q[0], q[1], q[2], q[3] = min(q[0], x), min(q[1], y), max(q[2], x + 1), max(q[3], y + 1)
            else:
                b[z] = [x, y, x + 1, y + 1]
    return b


def _silhouette(c: zones.Carte, zs: set, boite: tuple) -> bytearray:
    """Les zones `zs` et tout ce qu'elles enferment (trous bouchés), sur la boîte."""
    x0, y0, x1, y1 = boite
    w, h = x1 - x0, y1 - y0
    lab, W = c.labels, c.W
    dedans = bytearray(w * h)
    for y in range(h):
        base = (y0 + y) * W + x0
        for x in range(w):
            if lab[base + x] in zs:
                dedans[y * w + x] = 1
    # Dehors = ce qu'on atteint depuis le bord de la boîte sans traverser les zones.
    dehors = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if not dedans[y * w + x] and not dehors[y * w + x]:
                dehors[y * w + x] = 1
                q.append(y * w + x)
    for y in range(h):
        for x in (0, w - 1):
            if not dedans[y * w + x] and not dehors[y * w + x]:
                dehors[y * w + x] = 1
                q.append(y * w + x)
    while q:
        k = q.popleft()
        x, y = k % w, k // w
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                j = ny * w + nx
                if not dedans[j] and not dehors[j]:
                    dehors[j] = 1
                    q.append(j)
    return bytearray(0 if dehors[k] else 1 for k in range(w * h))


def _disque_interieur(sil: bytearray, w: int, h: int) -> tuple[float, float, float]:
    """Le plus grand disque dans la silhouette : (x, y, rayon) dans la boîte (distance au dehors)."""
    INF = 1 << 30
    d = [0 if not v else INF for v in sil]
    # Deux passes (distance « chanfrein » 3-4, divisée par 3 : ≈ euclidienne).
    for y in range(h):
        for x in range(w):
            k = y * w + x
            if d[k]:
                a = d[k - 1] + 3 if x > 0 else 3
                b = d[k - w] + 3 if y > 0 else 3
                c = d[k - w - 1] + 4 if x > 0 and y > 0 else 4
                e = d[k - w + 1] + 4 if y > 0 and x < w - 1 else 4
                d[k] = min(d[k], a, b, c, e)
    for y in range(h - 1, -1, -1):
        for x in range(w - 1, -1, -1):
            k = y * w + x
            if d[k]:
                a = d[k + 1] + 3 if x < w - 1 else 3
                b = d[k + w] + 3 if y < h - 1 else 3
                c = d[k + w + 1] + 4 if x < w - 1 and y < h - 1 else 4
                e = d[k + w - 1] + 4 if y < h - 1 and x > 0 else 4
                d[k] = min(d[k], a, b, c, e)
    k = max(range(len(d)), key=lambda i: d[i])
    return (k % w + 0.5, k // w + 0.5, d[k] / 3)


def pieces(a: analyse.Analyse, c: zones.Carte | None = None) -> list[Piece]:
    """Les pièces qui bougent d'une page (sur la carte `c`, par défaut celle de l'analyse)."""
    c = c or a.carte
    coin = c.zone(COIN)
    portee = int(c.raster * 2) + 3
    v = voisinage(c, portee)
    zones_de = {q.fr: {c.zone(p) for p in q.points} - {0} for q in a.parties}
    nommees = set().union(*zones_de.values()) if zones_de else set()
    sol = {coin} | set().union(*(zones_de.get(n, set()) for n in SOL))
    # Une très grande zone sans nom est un fond (un mur, une table) ; une grande partie nommée
    # (le feuillage du pommier) reste une pièce.
    sujet = set().union(*(v for n, v in zones_de.items() if n not in SOL)) if zones_de else set()
    sol |= {z for z in range(1, c.zones + 1) if c.part(z) > 0.2 and z not in sujet}
    boites = _boites(c)
    out: list[Piece] = []
    animees: set = set()
    for q in a.parties:
        m = mouvement(a.page, q.fr)
        if not m or q.fr in SOL:
            continue
        zs = zones_de[q.fr] - sol
        # Les zones de la partie qui se touchent forment une pièce.
        restant = set(zs)
        while restant:
            z = restant.pop()
            groupe, pile = {z}, [z]
            while pile:
                for z2 in v.voisins.get(pile.pop(), ()):
                    if z2 in restant:
                        restant.discard(z2)
                        groupe.add(z2)
                        pile.append(z2)
            # Les zones sans nom qui ne tiennent qu'à elle (le bout de la queue).
            aire = sum(c.aires[z] for z in groupe)
            for z2 in sorted({n for z in groupe for n in v.voisins.get(z, ())}):
                if z2 in groupe or z2 in nommees or z2 in sol:
                    continue
                if v.voisins.get(z2, set()) <= groupe | sol and c.aires[z2] <= aire:
                    groupe.add(z2)
            bx = [boites[z] for z in groupe]
            boite = (min(b[0] for b in bx), min(b[1] for b in bx), max(b[2] for b in bx), max(b[3] for b in bx))
            sil = _silhouette(c, groupe, boite)
            x0, y0, x1, y1 = boite
            w = x1 - x0
            n = sum(sil)
            sx = sum(k % w for k in range(len(sil)) if sil[k])
            sy = sum(k // w for k in range(len(sil)) if sil[k])
            centre = (x0 + sx / n + 0.5, y0 + sy / n + 0.5)
            genre, amplitude = m[0], m[1]
            pc = Piece(q.fr, genre, amplitude, groupe, boite, sil, centre, centre)
            pc.suspendue = len(m) > 2 and m[2] == "suspendue"
            pc.porteur = m[2] if len(m) > 2 and m[2] != "suspendue" else None
            if genre == "roule":
                dx, dy, r = _disque_interieur(sil, w, y1 - y0)
                pc.attache, pc.rayon = (x0 + dx, y0 + dy), r
            out.append(pc)
            animees |= groupe
    # Les attaches (une fois toutes les pièces connues : une pièce ne s'attache pas à une autre
    # qui bouge, sauf s'il n'y a rien d'autre).
    for k, pc in enumerate(out):
        pc.phase = 0.9 * k
        if pc.genre != "balance":
            continue
        if pc.suspendue:
            x0, y0, x1, y1 = pc.boite
            pc.attache = ((x0 + x1) / 2, y0)
            pc.signe = 1.0
            continue
        porteur = zones_de.get(pc.porteur, set()) if pc.porteur else set()
        tout = set(range(1, c.zones + 1))
        # La partie qui la porte (sans contact : elle est posée dessus, on la balance depuis son bas) ;
        # sinon ce qui ne bouge pas ; sinon tout sauf le fond.
        essais = [tout - porteur] if pc.porteur else [sol | animees, sol]
        for interdites in essais:
            s = [0, 0, 0]
            for z in pc.zones:
                for z2 in v.voisins.get(z, ()):
                    if z2 not in pc.zones and z2 not in interdites:
                        t = v.contacts[(z, z2)]
                        s[0] += t[0]
                        s[1] += t[1]
                        s[2] += t[2]
            if s[2]:
                pc.attache = (s[0] / s[2] + 0.5, s[1] / s[2] + 0.5)
                break
        else:
            x0, y0, x1, y1 = pc.boite
            pc.attache = ((x0 + x1) / 2, y1)
        pc.signe = 1.0 if pc.centre[0] >= pc.attache[0] else -1.0
    return out


# ---------------------------------------------------------------------------
# Le rendu (banc d'essai : l'app fait de même avec CoreGraphics)
# ---------------------------------------------------------------------------

def _couleurs(a: analyse.Analyse, c: zones.Carte) -> dict:
    """Un coloriage d'enfant plausible : les parties dans leur couleur, le reste en pastel."""
    from .dessin import PALETTE
    rot = ["rouge", "bleu", "jaune", "vert", "orange", "violet", "rose", "marron"]
    out = {}
    k = 0
    for q in a.parties:
        nom = q.couleur if q.couleur in PALETTE else rot[k % len(rot)]
        k += 1
        for p in q.points:
            out[c.zone(p)] = PALETTE_RGB[nom]
    coin = c.zone(COIN)
    out.setdefault(coin, (214, 236, 250))
    for z in range(1, c.zones + 1):
        if z not in out:
            h = (z * 0.618) % 1
            r, g, b = (int(200 + 55 * math.sin(2 * math.pi * (h + o))) for o in (0, 1 / 3, 2 / 3))
            out[z] = (r, g, b)
    return out


def image_coloriee(a: analyse.Analyse, c: zones.Carte) -> tuple[list, bytearray]:
    """(pixels RGB du coloriage avec ses traits, masque des traits affichés)."""
    W = c.W
    coul = _couleurs(a, c)
    traits = _masque(a.traits, W, a.page.trait * W)
    img = []
    for i, z in enumerate(c.labels):
        img.append(ENCRE_RGB if traits[i] else coul.get(z, (255, 255, 255)))
    return img, traits


def _decoupe(pc: Piece, c: zones.Carte, traits: bytearray) -> tuple[tuple, bytearray]:
    """La pièce découpée : sa silhouette et ses traits (jusqu'à l'épaisseur du trait autour) ;
    une roue : son disque intérieur."""
    W, H = c.W, c.H
    if pc.genre == "roule":
        cx, cy = pc.attache
        r = max(0.0, pc.rayon - 0.5)
        X0, Y0 = max(0, int(cx - r) - 1), max(0, int(cy - r) - 1)
        X1, Y1 = min(W, int(cx + r) + 2), min(H, int(cy + r) + 2)
        w = X1 - X0
        m = bytearray(w * (Y1 - Y0))
        for j in range(len(m)):
            x, y = X0 + j % w + 0.5, Y0 + j // w + 0.5
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                m[j] = 1
        return (X0, Y0, X1, Y1), m
    marge = int(math.ceil(c.raster / 0.8)) + 2
    x0, y0, x1, y1 = pc.boite
    X0, Y0, X1, Y1 = max(0, x0 - marge), max(0, y0 - marge), min(W, x1 + marge), min(H, y1 + marge)
    w, h = X1 - X0, Y1 - Y0
    m = bytearray(w * h)
    q = deque()
    sw = x1 - x0
    for k, s in enumerate(pc.silhouette):
        if s:
            x, y = x0 + k % sw, y0 + k // sw
            j = (y - Y0) * w + (x - X0)
            m[j] = 1
            q.append((j, 0))
    # Les traits qui bordent la silhouette (au plus `marge` px), puis 1 px de plus.
    while q:
        j, d = q.popleft()
        if d >= marge:
            continue
        x, y = j % w, j // w
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                k = ny * w + nx
                if not m[k] and traits[(Y0 + ny) * W + X0 + nx]:
                    m[k] = 1
                    q.append((k, d + 1))
    plus = bytearray(m)
    for j in range(w * h):
        if m[j]:
            continue
        x, y = j % w, j // w
        if any(0 <= nx < w and 0 <= ny < h and m[ny * w + nx]
               for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
            plus[j] = 1
    return (X0, Y0, X1, Y1), plus


def rendre(a: analyse.Analyse, c: zones.Carte, ps: list[Piece], instants: list[float]) -> list[list]:
    """Une image par instant : le fond rebouché, puis chaque pièce transformée par-dessus."""
    W, H = c.W, c.H
    img, traits = image_coloriee(a, c)
    decoupes = [_decoupe(pc, c, traits) for pc in ps]
    # Le fond : chaque emplacement de pièce rebouché avec les couleurs voisines (hors traits).
    fond = list(img)
    trou = bytearray(W * H)
    for pc, ((X0, Y0, X1, Y1), m) in zip(ps, decoupes):
        if pc.genre == "roule":
            continue                  # le disque tourne sur lui-même : rien ne se découvre
        w = X1 - X0
        for j, v in enumerate(m):
            if v:
                trou[(Y0 + j // w) * W + X0 + j % w] = 1
    q = deque()
    fait = bytearray(W * H)
    for i in range(W * H):
        if trou[i] or traits[i]:
            continue
        x, y = i % W, i // W
        if any(0 <= nx < W and 0 <= ny < H and trou[ny * W + nx]
               for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
            fait[i] = 1
            q.append(i)
    while q:
        i = q.popleft()
        x, y = i % W, i // W
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < W and 0 <= ny < H:
                j = ny * W + nx
                if trou[j] and not fait[j]:
                    fait[j] = 1
                    fond[j] = fond[i]
                    q.append(j)
    images = []
    for t in instants:
        cadre = list(fond) if any(enveloppe(t) for _ in ps) else list(img)
        if enveloppe(t) == 0:
            images.append(list(img))
            continue
        for pc, ((X0, Y0, X1, Y1), m) in zip(ps, decoupes):
            ang, ech, dx, dy = transformation(pc.genre, pc.amplitude, t, pc.phase, pc.signe)
            px, py = pc.attache if pc.genre in ("balance", "roule") else pc.centre
            ca, sa = math.cos(ang), math.sin(ang)
            w = X1 - X0
            # Boîte de destination : les coins transformés.
            coins = []
            for cx, cy in ((X0, Y0), (X1, Y0), (X0, Y1), (X1, Y1)):
                ux, uy = (cx - px) * ech, (cy - py) * ech
                coins.append((px + ux * ca - uy * sa + dx * W, py + ux * sa + uy * ca + dy * H))
            bx0 = max(0, int(min(p[0] for p in coins)) - 1)
            bx1 = min(W, int(max(p[0] for p in coins)) + 2)
            by0 = max(0, int(min(p[1] for p in coins)) - 1)
            by1 = min(H, int(max(p[1] for p in coins)) + 2)
            for y in range(by0, by1):
                for x in range(bx0, bx1):
                    # Inverse : destination → source.
                    ux, uy = x + 0.5 - px - dx * W, y + 0.5 - py - dy * H
                    sx = (ux * ca + uy * sa) / ech + px
                    sy = (-ux * sa + uy * ca) / ech + py
                    ix, iy = int(math.floor(sx)), int(math.floor(sy))
                    if X0 <= ix < X1 and Y0 <= iy < Y1 and m[(iy - Y0) * w + ix - X0]:
                        cadre[y * W + x] = img[iy * W + ix]
        images.append(cadre)
    return images


def planche(ids: list[str], dossier: Path, cote: int = 384, instants=(0.0, 1.0, 1.2, 1.4)) -> Path:
    """Une rangée par page : l'instant 0 (repos) puis trois instants de la fête ; attaches en rouge."""
    dossier.mkdir(parents=True, exist_ok=True)
    pages = [p for p in catalogue.PAGES if p.id in ids] if ids else list(catalogue.PAGES)
    marge = 6
    rangees = []
    for p in pages:
        a = analyse.analyser(p, variantes=False)
        t = a.traits
        c = zones.carte(t, taille=cote)
        ps = pieces(a, c)
        imgs = rendre(a, c, ps, list(instants))
        # Les attaches sur l'image de repos : une croix rouge.
        for pc in ps:
            px, py = pc.attache if pc.genre in ("balance", "roule") else pc.centre
            for d in range(-4, 5):
                for x, y in ((int(px) + d, int(py)), (int(px), int(py) + d)):
                    if 0 <= x < cote and 0 <= y < cote:
                        imgs[0][y * cote + x] = (230, 30, 30)
        rangees.append((p.id, imgs, ps))
        print(f"{p.id}: " + ", ".join(f"{pc.partie} ({pc.genre})" for pc in ps))
    n = len(instants)
    W = n * cote + (n + 1) * marge
    H = len(rangees) * cote + (len(rangees) + 1) * marge
    rgb = bytearray(b"\xee" * (W * H * 3))
    for r, (_, imgs, _) in enumerate(rangees):
        for k, im in enumerate(imgs):
            ox, oy = marge + k * (cote + marge), marge + r * (cote + marge)
            for y in range(cote):
                base = ((oy + y) * W + ox) * 3
                row = im[y * cote:(y + 1) * cote]
                rgb[base:base + cote * 3] = bytes(v for px in row for v in px)
    chemin = dossier / "vivant.png"
    ecrire_png(chemin, W, H, rgb)
    return chemin


# Les attaches de référence pour les tests Swift (LivingDrawingTests) : calculées ici à 1024 px,
# la taille de la carte de l'app.
GOLDEN = ("minouche", "lapin", "perruche", "biche", "locomotive", "douche")


def golden() -> str:
    """Les attaches (et rayons des roues) de quelques pages, en Swift, pour la parité avec l'app."""
    lignes = []
    for p in (q for q in catalogue.PAGES if q.id in GOLDEN):
        a = analyse.analyser(p, variantes=False)
        for pc in sorted(pieces(a), key=lambda q: (q.partie, q.attache)):
            if pc.genre not in ("balance", "roule"):
                continue
            x, y = pc.attache
            n = a.carte.W
            lignes.append(f'        ("{p.id}", "{pc.partie}", {x / n:.4f}, {y / n:.4f}, {pc.rayon / n:.4f}),')
    return "\n".join(lignes)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--planche", type=Path, help="dossier où écrire la planche vivant.png")
    ap.add_argument("--golden", action="store_true", help="attaches de référence pour les tests Swift")
    ap.add_argument("pages", nargs="*", help="identifiants des pages (toutes par défaut)")
    ap.add_argument("--cote", type=int, default=384)
    args = ap.parse_args(argv)
    if args.planche:
        print(planche(args.pages, args.planche, args.cote))
    if args.golden:
        print(golden())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
