"""Les gestes de Lou, ANIMÉS : une chronologie par son, tirée de la planche validée.

Décision de l'utilisateur (06/10/2026) : Lou montre les gestes de Borel-Maisonny en mouvement (un
geste s'apprend en le voyant faire). Cette référence (stdlib) dit, pour chaque son de
`dessins.SCENES`, OÙ est la main et QUELLE forme elle a à chaque instant ; l'app (Swift,
`EveilDesign/LouGesture*.swift`) relit ces chronologies générées (`generer.py`) et calcule le bras
et la main à chaque image.

Rien n'est inventé au-delà de la scène validée :
- les poses = les bras posés de la scène (poignet, coude dessiné, direction, forme, pouce, taille) ;
- les flèches = la trajectoire : le bout de l'index suit le tracé (« s », « z ») ; ailleurs la main
  se déplace du vecteur de la flèche, vers la pose dessinée (« j », « k », « g », « l », « b »,
  « m » qui appuie) ou depuis elle (« f », « ill », « ou ») ; « gn » va et vient sur le nez ;
- les vignettes = les temps successifs (formes de main) ;
- les gestes sans mouvement : la main ARRIVE depuis le repos (0,35 s), tient la pose, puis repart.
Chaque chronologie commence et finit AU REPOS (bras invisible sous le cadre, comme sur la
planche ; bouche « neutre », souriante), pour enchaîner plusieurs sons. Pas de flèche ni de texte.

Choix de dessin (à revoir avec l'orthophoniste, aucun ne change une pose validée) :
- au repos, la main est descendue sous le cadre (le coude avec elle) ; elle monte sans tourner, et
  le bras apparaît en fondu (le bras au repos de la planche n'est pas dessiné : sans fondu, le haut
  du bras surgirait sur le t-shirt) ;
- quand la main se déplace, le coude suit de moitié (`SUIVI_COUDE`) ;
- « s », « z » : l'index penche vers la tête (−74° au lieu de −96°) pour que la main tienne dans
  le cadre en haut du tracé, et le coude reste sur le côté (`COUDE_TRACE`) : l'avant-bras pivote ;
- « d » : l'autre bras passe derrière le dos (on ne voit que le coude dépasser, sans texte), le long
  de la flèche en tirets de la planche ;
- « p », « b » : les lèvres pressées s'ouvrent avec la main (`bouche_source` de la planche) ;
- « k », « g » : la bouche s'ouvre « au moment du k » (fin de l'avancée de l'index) ;
- « m » : la table apparaît avec la main, la bouche se ferme quand les doigts appuient ;
- « f » : la main finit à moitié hors du cadre (la flèche est longue) ; sa pose tenue est la pose
  dessinée.

Interpolation (la même en Swift) : entre deux clés, `x` = part du temps écoulé, adoucie par
`lisse(x)` = x²(3 − 2x) si la clé d'arrivée est `douce`, sinon linéaire. Coude, poignet, direction
de la main (déroulée d'une clé à l'autre), présence (fondu), tête levée, table : interpolés. Le coude
de chaque clé est celui de la scène (déplacé avec la main) : pas d'IK image par image (elle faisait
sauter le coude de 180 px quand la main frôlait l'épaule), ni d'angles interpolés (le bras de « é »,
« è » partait en arc hors du cadre).
Deux formes de main différentes : on interpole les chemins des doigts (rééchantillonnés) ; un doigt
replié devient un moignon caché sous sa phalange repliée, qui apparaît en fondu. La bouche et « la
gorge vibre » changent d'un coup à la clé (valeur de la dernière clé passée).

    cd eveil/outils && python3 -m gestes.animation            # résumé des durées
"""
from __future__ import annotations

import math
import sys
from dataclasses import dataclass, replace

from coloriages.dessin import courbe, ligne

from .dessins import SCENES, Bras, vibre
from .gestes import TOUS, Geste
from .lou_portrait import BASE, EPAULE_D, EPAULE_G, FORMES, REP, Main

ARRIVEE = 0.35          # du repos à la première pose (s)
DEPART = 0.35           # de la dernière pose au repos (s)
TENUE = 0.9             # geste immobile : la pose tenue (s)
BOUCHE_SEULE = 1.0      # un son sans geste (« ui ») : la bouche seule (s)
REPOS_BOUCHE = "neutre"
N_DOIGT = 10            # points d'un doigt rééchantillonné (interpolation des formes)
POUCE_REPLIE = ((0.32, 0.44), (0.55, 0.40), (0.74, 0.18), (0.78, -0.06))   # le pouce replié de `main()`
REPOS_Y = 420.0         # au repos, la main est descendue sous le cadre (300) : bras invisible
SUIVI_COUDE = 0.5       # quand la main se déplace, le coude suit de moitié
COUDE_TRACE = (254.0, 236.0)  # « s », « z » : le coude sur le côté, l'avant-bras levé (la main dessine en l'air)
DIRECTION_TRACE = -74.0 # « s », « z » : l'index penche vers la tête (dessinée à −96°, la main sortait du cadre)
# « d » : l'autre bras derrière le dos (coude qui dépasse sur le côté, main cachée par le buste).
DERRIERE_COUDE = (18.0, 274.0)
DERRIERE_POIGNET = (86.0, 300.0)

PAR_SON = {g.son: g for g in TOUS}


# ---------------------------------------------------------------------------
# Données
# ---------------------------------------------------------------------------

def _r(v: float, nd: int = 4) -> float:
    """Arrondi des données émises (Python et Swift lisent exactement les mêmes nombres)."""
    r = round(v, nd)
    return 0.0 if r == 0 else r


def _rp(p) -> tuple[float, float]:
    return (_r(p[0], 3), _r(p[1], 3))


@dataclass(frozen=True)
class BrasFixe:
    """Ce qui ne change pas pendant un geste, pour un bras."""
    cote: str               # « d » (épaule à droite de l'image) ou « g »
    pouce: int
    taille: float
    derriere: bool = False  # bras caché derrière le buste (« d »)

    @property
    def epaule(self) -> tuple[float, float]:
        return EPAULE_D if self.cote == "d" else EPAULE_G


@dataclass(frozen=True)
class PoseCle:
    poignet: tuple
    direction: float
    forme: str
    coude: tuple            # le coude de la clé (celui de la scène, déplacé avec la main)
    presence: float = 1.0   # 0 = au repos (invisible), 1 = là


@dataclass(frozen=True)
class Articulation:
    """Un bras à une clé : coude, poignet, direction de la main (degrés, déroulée d'une clé à l'autre :
    jamais de demi-tour), forme, présence."""
    coude: tuple
    poignet: tuple
    direction: float
    forme: str
    presence: float


@dataclass(frozen=True)
class Cle:
    t: float
    poses: tuple            # une Articulation par bras (même ordre que `Chronologie.bras`)
    bouche: str             # à partir de cette clé
    vibre: bool             # à partir de cette clé
    leve: float = 0.0       # tête levée (« è »)
    table: float = 0.0      # opacité de la table (« m »)
    douce: bool = True      # le segment qui ARRIVE à cette clé est adouci


@dataclass(frozen=True)
class Chronologie:
    son: str
    duree: float
    bras: tuple             # BrasFixe
    cles: tuple             # Cle
    t_pose: float           # l'instant « pose » (rendus ; « Réduire les animations » : pose tenue)
    geste: bool = True      # False : la bouche seule


# ---------------------------------------------------------------------------
# Géométrie
# ---------------------------------------------------------------------------

def lisse(x: float) -> float:
    return x * x * (3 - 2 * x)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _lerpp(p, q, t: float) -> tuple[float, float]:
    return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)


def coude_ik(epaule, poignet, a: float, b: float, plie: int) -> tuple[float, float]:
    """Le coude : deux segments de longueurs a, b (étirés si la main est trop loin)."""
    dx, dy = poignet[0] - epaule[0], poignet[1] - epaule[1]
    d = math.hypot(dx, dy)
    if d > a + b:
        f = d / (a + b)
        a, b = a * f, b * f
    d = max(d, abs(a - b) + 1.0)
    th = math.atan2(dy, dx)
    al = math.acos(max(-1.0, min(1.0, (a * a + d * d - b * b) / (2 * a * d))))
    return (epaule[0] + a * math.cos(th + plie * al), epaule[1] + a * math.sin(th + plie * al))


def chemin_local(forme: str, doigt: str) -> list[tuple[float, float]]:
    """Le chemin d'un doigt dans le repère de la main ; replié : un moignon caché sous la phalange."""
    spec = FORMES[forme][doigt]
    if spec == REP:
        if doigt == "pouce":
            return list(POUCE_REPLIE)
        return [BASE[doigt], (1.10, BASE[doigt][1])]
    return Main((0.0, 0.0), 0.0, forme).chemins()[doigt]


def reechantillonne(pts, n: int = N_DOIGT) -> list[tuple[float, float]]:
    """`n` points également espacés le long de la ligne brisée (les deux bouts gardés)."""
    cum = [0.0]
    for p, q in zip(pts, pts[1:]):
        cum.append(cum[-1] + math.hypot(q[0] - p[0], q[1] - p[1]))
    total = cum[-1]
    out = []
    j = 0
    for i in range(n):
        s = total * i / (n - 1)
        while j < len(pts) - 2 and cum[j + 1] < s:
            j += 1
        seg = cum[j + 1] - cum[j]
        u = 0.0 if seg <= 0 else (s - cum[j]) / seg
        out.append(_lerpp(pts[j], pts[j + 1], max(0.0, min(1.0, u))))
    out[-1] = tuple(pts[-1])
    return out


@dataclass(frozen=True)
class EtatBras:
    fixe: BrasFixe
    poignet: tuple
    coude: tuple
    direction: float
    forme_a: str
    forme_b: str
    melange: float          # 0 = forme_a, 1 = forme_b
    presence: float

    def main(self, forme: str | None = None) -> Main:
        f = forme or (self.forme_a if self.melange < 0.5 else self.forme_b)
        return Main(self.poignet, self.direction, f, self.fixe.pouce, self.fixe.taille)

    def bout(self, doigt: str = "index") -> tuple[float, float]:
        """Le bout d'un doigt à l'écran (formes mêlées : les bouts sont interpolés)."""
        q = _lerpp(chemin_local(self.forme_a, doigt)[-1], chemin_local(self.forme_b, doigt)[-1], self.melange)
        return self.main().ecran(q)


@dataclass(frozen=True)
class Etat:
    bras: tuple             # EtatBras
    bouche: str
    vibre: bool
    leve: float
    table: float


def etat(ch: Chronologie, t: float) -> Etat:
    """L'image à l'instant `t` (bornée à [0, durée])."""
    t = max(0.0, min(ch.duree, t))
    cles = ch.cles
    i = 0
    while i + 1 < len(cles) and cles[i + 1].t <= t:
        i += 1
    k0 = cles[i]
    k1 = cles[i + 1] if i + 1 < len(cles) else k0
    span = k1.t - k0.t
    x = 1.0 if span <= 0 else (t - k0.t) / span
    e = lisse(x) if k1.douce else x
    bras = []
    for f, p0, p1 in zip(ch.bras, k0.poses, k1.poses):
        # Coude et poignet interpolés à l'écran (le coude de chaque clé est donné) : ni coude qui
        # saute (une IK image par image le faisait passer de l'autre côté quand la main frôlait
        # l'épaule), ni bras qui part en arc hors du cadre (angles interpolés : « é », « è »).
        coude = _lerpp(p0.coude, p1.coude, e)
        poignet = _lerpp(p0.poignet, p1.poignet, e)
        if p0.forme == p1.forme:
            fa, fb, m = p0.forme, p0.forme, 0.0
        else:
            fa, fb, m = p0.forme, p1.forme, e
        bras.append(EtatBras(f, poignet, coude, _lerp(p0.direction, p1.direction, e), fa, fb, m,
                             _lerp(p0.presence, p1.presence, e)))
    return Etat(tuple(bras), k0.bouche, k0.vibre, _lerp(k0.leve, k1.leve, e), _lerp(k0.table, k1.table, e))


# ---------------------------------------------------------------------------
# Construction d'une chronologie
# ---------------------------------------------------------------------------

def _angle(p, q) -> float:
    return math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))


def _pres_de(a: float, ref: float) -> float:
    """`a` à un tour près, le plus près de `ref` (pas de demi-tour de la main en route)."""
    while a - ref > 180:
        a -= 360
    while a - ref < -180:
        a += 360
    return a


def _fixe(b: Bras) -> tuple[BrasFixe, PoseCle]:
    m = b.main
    epaule = EPAULE_D if b.epaule == "d" else EPAULE_G
    coude = b.coude or coude_ik(epaule, m.poignet, 64.0, 60.0, b.plie)
    f = BrasFixe(b.epaule, m.pouce, _r(m.taille, 3))
    return f, PoseCle(_rp(m.poignet), _r(m.direction, 3), m.forme, _rp(coude))


def _derriere() -> tuple[BrasFixe, PoseCle]:
    """« d » : l'autre bras (épaule à gauche de l'image), main dans le bas du dos."""
    b = Bras(Main(DERRIERE_POIGNET, 10.0, "poing", pouce=1), epaule="g", coude=DERRIERE_COUDE)
    f, p = _fixe(b)
    return replace(f, derriere=True), p


def repos(f: BrasFixe, p: PoseCle) -> PoseCle:
    """Le bras au repos qui correspond à la pose `p` : la même main descendue sous le cadre (le coude
    avec elle), invisible ; en arrivant, elle monte sans tourner."""
    dy = REPOS_Y - p.poignet[1]
    return PoseCle(_rp((p.poignet[0], REPOS_Y)), p.direction, p.forme, _rp((p.coude[0], p.coude[1] + dy)), 0.0)


class _Fil:
    """Accumule les clés d'une chronologie."""

    def __init__(self, g: Geste, fixes: list[BrasFixe], poses: list[PoseCle]):
        self.g, self.fixes = g, fixes
        self.t = 0.0
        self._poses = tuple(repos(f, p) for f, p in zip(fixes, poses))
        self.cles: list[Cle] = [Cle(0.0, self._articulations(self._poses, None), REPOS_BOUCHE, False, douce=False)]
        self.bouche, self.vibre, self.leve, self.table = REPOS_BOUCHE, False, 0.0, 0.0
        self.t_pose: float | None = None

    @property
    def poses(self) -> tuple:
        return self._poses

    def _articulations(self, poses, avant) -> tuple:
        """Les poses d'une clé ; la direction déroulée depuis la clé d'avant."""
        out = []
        for k, p in enumerate(poses):
            d = p.direction if avant is None else _pres_de(p.direction, avant[k].direction)
            out.append(Articulation(_rp(p.coude), _rp(p.poignet), _r(d, 3), p.forme, _r(p.presence)))
        return tuple(out)

    def cle(self, dt: float, poses, douce: bool = True, **etat) -> _Fil:
        for k, v in etat.items():
            setattr(self, k, v)
        self.t += dt
        self._poses = tuple(poses)
        self.cles.append(Cle(_r(self.t), self._articulations(poses, self.cles[-1].poses), self.bouche, self.vibre,
                             _r(self.leve), _r(self.table), douce))
        return self

    def arrivee(self, poses, **etat) -> _Fil:
        etat.setdefault("bouche", self.g.bouche)
        etat.setdefault("vibre", vibre(self.g))
        return self.cle(ARRIVEE, [replace(p, presence=1.0) for p in poses], **etat)

    def tenir(self, dt: float, **etat) -> _Fil:
        return self.cle(dt, self.poses, douce=False, **etat)

    def marque(self, t: float | None = None) -> _Fil:
        self.t_pose = _r(self.t if t is None else t)
        return self

    def depart(self) -> Chronologie:
        """La dernière clé ferme la bouche ; puis le bras repart au repos."""
        last = self.cles[-1]
        self.cles[-1] = replace(last, bouche=REPOS_BOUCHE, vibre=False)
        self.t += DEPART
        fin = tuple(repos(f, p) for f, p in zip(self.fixes, self._poses))
        self.cles.append(Cle(_r(self.t), self._articulations(fin, last.poses), REPOS_BOUCHE, False, 0.0, 0.0, True))
        if self.t_pose is None:
            self.marque(self.t - DEPART)
        return Chronologie(self.g.son, _r(self.t), tuple(self.fixes), tuple(self.cles), self.t_pose)


def _main(f: BrasFixe, p: PoseCle) -> Main:
    return Main(p.poignet, p.direction, p.forme, f.pouce, f.taille)


def _decale(f: BrasFixe, p: PoseCle, dx: float, dy: float) -> PoseCle:
    """La main déplacée de (dx, dy) ; le coude suit à moitié (le bras garde une allure de bras :
    avec le coude dessiné, souvent sous le cadre, le haut du bras est très long)."""
    return replace(p, poignet=(p.poignet[0] + dx, p.poignet[1] + dy),
                   coude=(p.coude[0] + SUIVI_COUDE * dx, p.coude[1] + SUIVI_COUDE * dy))


def _bout_en(f: BrasFixe, p: PoseCle, cible, doigt: str = "index") -> PoseCle:
    q = _main(f, p).ecran(chemin_local(p.forme, doigt)[-1])
    return _decale(f, p, cible[0] - q[0], cible[1] - q[1])


# --- suivre une flèche -------------------------------------------------------

def trace(pts) -> list[tuple[float, float]]:
    """La ligne de la flèche (celle que dessine `fleche`), échantillonnée finement ; les points de la
    flèche y sont aux indices multiples de 24."""
    c = courbe(list(pts))[0] if len(pts) > 2 else ligne(*pts)[0]
    if len(pts) <= 2:
        return [_lerpp(pts[0], pts[1], i / 24) for i in range(25)]
    return c.sample(24)


def _longueurs(dense) -> list[float]:
    cum = [0.0]
    for p, q in zip(dense, dense[1:]):
        cum.append(cum[-1] + math.dist(p, q))
    return cum


def _au_long(dense, cum, s: float) -> tuple[float, float]:
    s = max(0.0, min(cum[-1], s))
    j = 0
    while j < len(dense) - 2 and cum[j + 1] < s:
        j += 1
    seg = cum[j + 1] - cum[j]
    return _lerpp(dense[j], dense[j + 1], 0.0 if seg <= 0 else (s - cum[j]) / seg)


def _inverse_lisse(y: float) -> float:
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if lisse(mid) < y:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def suivre(pts, duree: float, par_seconde: float = 30.0) -> list[tuple[float, tuple[float, float]]]:
    """(instant, point) le long de la flèche : départ et arrivée adoucis, et les points de la flèche
    eux-mêmes parmi les clés (la trajectoire passe exactement par eux)."""
    dense = trace(pts)
    cum = _longueurs(dense)
    L = cum[-1]
    n = max(6, round(duree * par_seconde))
    temps = {round(duree * i / n, 4) for i in range(1, n + 1)}
    if len(pts) > 2:
        for k in range(1, len(pts) - 1):
            temps.add(round(duree * _inverse_lisse(cum[24 * k] / L), 4))
    out = []
    for tau in sorted(temps):
        out.append((tau, _au_long(dense, cum, L * lisse(tau / duree))))
    # Les points de la flèche : exacts (et pas seulement à l'arrondi du temps près).
    for k in range(1, len(pts) - 1):
        tk = round(duree * _inverse_lisse(cum[24 * k] / L), 4)
        out = [(tau, tuple(pts[k]) if tau == tk else p) for tau, p in out]
    out[-1] = (out[-1][0], tuple(pts[-1]))
    return out


def _suivre_cles(fil: _Fil, pts, duree: float, poses_en) -> None:
    """Ajoute les clés (linéaires entre elles) d'un parcours ; `poses_en(point)` → poses."""
    avant = 0.0
    for tau, p in suivre(pts, duree):
        fil.cle(tau - avant, poses_en(p), douce=False)
        avant = tau


# ---------------------------------------------------------------------------
# Les mouvements, son par son
# ---------------------------------------------------------------------------

def _immobile(fil: _Fil, sc, F, P) -> None:
    tenue = 1.1 if fil.g.son == "ch" else TENUE       # « ch » : on garde la pose tout le temps du souffle
    fil.arrivee(P, leve=sc.leve, table=1.0 if sc.table else 0.0)
    fil.marque(fil.t + tenue / 2)
    fil.tenir(tenue)


def _temps(fil: _Fil, sc, F, P, tenues, bascules, bouches=None) -> None:
    """Les vignettes, l'une après l'autre : tenue, bascule rapide vers la suivante, …"""
    formes = sc.vignettes
    fil.arrivee([replace(P[0], forme=formes[0])] + list(P[1:]), bouche=(bouches or [fil.g.bouche])[0])
    for k, forme in enumerate(formes[1:], 1):
        fil.tenir(tenues[k - 1], **({"bouche": bouches[k]} if bouches else {}))
        fil.cle(bascules[k - 1], [replace(fil.poses[0], forme=forme)] + list(fil.poses[1:]))
    fil.marque()
    fil.tenir(tenues[-1])


def _s_z(fil: _Fil, sc, F, P, duree: float, fin: float) -> None:
    """Le bout de l'index dessine la flèche (« s » lent, « z » rapide)."""
    pts = sc.fleches[0].pts
    p = replace(P[0], direction=DIRECTION_TRACE)

    def en(q):      # le bout de l'index sur le tracé ; le coude reste sur le côté (le bras pivote)
        return replace(_bout_en(F[0], p, q), coude=COUDE_TRACE)

    fil.arrivee([en(pts[0])])
    _suivre_cles(fil, pts, duree, lambda q: [en(q)])
    fil.marque()
    fil.tenir(fin)


def _vers_la_pose(fil: _Fil, sc, F, P, avance: float, tenue: float, bouche_au_bout: bool = False) -> None:
    """La main avance du vecteur de la flèche et finit sur la pose dessinée (« j », « k », « g », « l »)."""
    a, b = sc.fleches[0].pts[0], sc.fleches[0].pts[-1]
    debut = _decale(F[0], P[0], a[0] - b[0], a[1] - b[1])
    if bouche_au_bout:
        fil.arrivee([debut], bouche=REPOS_BOUCHE, vibre=False)
        fil.cle(avance, P, bouche=fil.g.bouche, vibre=vibre(fil.g))
    else:
        fil.arrivee([debut])
        fil.cle(avance, P)
    fil.marque()
    fil.tenir(tenue)


def _depuis_la_pose(fil: _Fil, sc, F, P, avant: float, glisse: float, tenue: float,
                    pose_au_debut: bool = False) -> None:
    """La main part de la pose dessinée et suit le vecteur de la flèche (« f », « ill »).
    `pose_au_debut` : l'instant « pose » est la pose dessinée (« f » finit la main à moitié hors du cadre)."""
    pts = sc.fleches[0].pts
    fil.arrivee(P)
    if pose_au_debut:
        fil.marque(fil.t + avant / 2)
    fil.tenir(avant)
    _suivre_cles(fil, pts, glisse, lambda q: [_decale(F[0], P[0], q[0] - pts[0][0], q[1] - pts[0][1])])
    if not pose_au_debut:
        fil.marque()
    fil.tenir(tenue)


def _ou(fil: _Fil, sc, F, P) -> None:
    """Trois temps sur un son tenu, le bras s'allonge le long de la flèche."""
    pts = sc.fleches[0].pts
    o, deux, ecartes = sc.vignettes
    total = 1.3
    chemin = suivre(pts, total)
    # (instant de bascule, forme d'arrivée) : deux bascules rapides de 0,15 s.
    bascules = ((0.40, 0.55, deux), (0.85, 1.00, ecartes))

    def forme_a(tau):
        f = o
        for _, fin, nouvelle in bascules:
            if tau >= fin - 1e-9:
                f = nouvelle
        return f

    fil.arrivee(P)
    instants = sorted({tau for tau, _ in chemin} | {b[0] for b in bascules} | {b[1] for b in bascules})
    dense = trace(pts)
    cum = _longueurs(dense)
    avant = 0.0
    for tau in instants:
        q = _au_long(dense, cum, cum[-1] * lisse(tau / total))
        if tau == total:
            q = pts[-1]
        dans_bascule = any(b0 < tau < b1 for b0, b1, _ in bascules)
        forme = forme_a(tau)
        if dans_bascule:       # pas de clé au milieu d'une bascule : la forme s'interpole d'un bout à l'autre
            continue
        fil.cle(tau - avant, [replace(_decale(F[0], P[0], q[0] - pts[0][0], q[1] - pts[0][1]), forme=forme)],
                douce=False)
        avant = tau
    fil.marque()
    fil.tenir(0.1)


def _m(fil: _Fil, sc, F, P) -> None:
    """Les trois doigts descendent sur la table, appuient tant que dure le « mmm », puis se lèvent."""
    a, b = sc.fleches[0].pts
    haut = _decale(F[0], P[0], a[0] - b[0], a[1] - b[1])
    fil.arrivee([haut], bouche=REPOS_BOUCHE, table=1.0)
    fil.cle(0.25, P, bouche=fil.g.bouche)
    fil.marque(fil.t + 0.35)
    fil.tenir(0.7, bouche=REPOS_BOUCHE)
    fil.cle(0.25, [haut])


def _gn(fil: _Fil, sc, F, P) -> None:
    """L'index posé sur le nez glisse d'un côté à l'autre (deux allers-retours)."""
    a, b = sc.fleches[0].pts
    m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    bout = _main(F[0], P[0]).ecran(chemin_local(P[0].forme, "index")[-1])
    dx, dy = bout[0] - m[0], bout[1] - m[1]          # la flèche, ramenée sur le bout de l'index
    gauche = _bout_en(F[0], P[0], (a[0] + dx, a[1] + dy))
    droite = _bout_en(F[0], P[0], (b[0] + dx, b[1] + dy))
    fil.arrivee(P)
    fil.marque()
    fil.cle(0.2, [gauche]).cle(0.3, [droite]).cle(0.3, [gauche]).cle(0.3, [droite]).cle(0.15, P)


def _b(fil: _Fil, sc, F, P) -> None:
    """Le bras vient de l'extérieur vers le milieu du corps ; la main s'ouvre au « b »."""
    a, b = sc.fleches[0].pts[0], sc.fleches[0].pts[-1]
    pts = sc.fleches[0].pts
    debut = _decale(F[0], P[0], a[0] - b[0], a[1] - b[1])
    fil.arrivee([debut], bouche="fermee")
    _suivre_cles(fil, pts, 0.5, lambda q: [_decale(F[0], P[0], q[0] - b[0], q[1] - b[1])])
    fil.tenir(0.12, bouche="mi_ouverte")
    fil.cle(0.1, [replace(fil.poses[0], forme=sc.vignettes[1])])
    fil.marque()
    fil.tenir(0.4)


def _d(fil: _Fil, sc, F, P) -> None:
    _temps(fil, sc, F, P, (0.35, 0.4), (0.12,))


PROGRAMMES = {
    "ou": _ou,
    "oi": lambda fil, sc, F, P: _temps(fil, sc, F, P, (0.3, 0.45), (0.1,)),
    "oin": lambda fil, sc, F, P: _temps(fil, sc, F, P, (0.25, 0.25, 0.3), (0.15, 0.15)),
    "s": lambda fil, sc, F, P: _s_z(fil, sc, F, P, 1.6, 0.1),
    "z": lambda fil, sc, F, P: _s_z(fil, sc, F, P, 0.7, 0.15),
    "j": lambda fil, sc, F, P: _vers_la_pose(fil, sc, F, P, 0.35, 0.35),
    "k": lambda fil, sc, F, P: _vers_la_pose(fil, sc, F, P, 0.2, 0.4, bouche_au_bout=True),
    "g": lambda fil, sc, F, P: _vers_la_pose(fil, sc, F, P, 0.2, 0.4, bouche_au_bout=True),
    "l": lambda fil, sc, F, P: _vers_la_pose(fil, sc, F, P, 0.4, 0.35),
    "f": lambda fil, sc, F, P: _depuis_la_pose(fil, sc, F, P, 0.3, 0.8, 0.1, pose_au_debut=True),
    "ill": lambda fil, sc, F, P: _depuis_la_pose(fil, sc, F, P, 0.15, 0.6, 0.15),
    "m": _m,
    "gn": _gn,
    "p": lambda fil, sc, F, P: _temps(fil, sc, F, P, (0.4, 0.4), (0.08,), bouches=("fermee", "mi_ouverte")),
    "b": _b,
    "t": lambda fil, sc, F, P: _temps(fil, sc, F, P, (0.35, 0.4), (0.12,)),
    "d": _d,
}


def chronologie(son: str) -> Chronologie | None:
    """La chronologie d'un son : son geste (s'il en a un), sinon sa bouche seule ; None si inconnu."""
    g = PAR_SON.get(son)
    if g is None:
        return None
    sc = SCENES.get(son)
    if sc is None:
        cles = (Cle(0.0, (), REPOS_BOUCHE, False, douce=False), Cle(0.2, (), g.bouche, False),
                Cle(0.8, (), REPOS_BOUCHE, False), Cle(BOUCHE_SEULE, (), REPOS_BOUCHE, False))
        return Chronologie(son, BOUCHE_SEULE, (), cles, 0.5, geste=False)
    fixes, poses = [], []
    for b in sc.bras:
        f, p = _fixe(b)
        fixes.append(f)
        poses.append(p)
    if son == "d":
        f, p = _derriere()
        fixes.append(f)
        poses.append(p)
    fil = _Fil(g, fixes, poses)
    PROGRAMMES.get(son, _immobile)(fil, sc, fixes, poses)
    return fil.depart()


def toutes() -> dict[str, Chronologie]:
    """Les sons qui ont un geste, dans l'ordre de la planche."""
    return {son: chronologie(son) for son in SCENES}


def sans_geste() -> dict[str, Chronologie]:
    """Les sons relevés sans geste (« ui ») : la bouche seule."""
    return {g.son: chronologie(g.son) for g in TOUS if g.son not in SCENES}


def main(argv: list[str]) -> int:
    for son, ch in toutes().items():
        print(f"{son:10s} {ch.duree:4.2f} s  {len(ch.cles):3d} clés  pose à {ch.t_pose:.2f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
