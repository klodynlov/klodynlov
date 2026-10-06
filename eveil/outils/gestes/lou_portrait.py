"""Lou en grand, en portrait (buste de face) : la bouche qui dit le son, la main qui fait le geste.

Document de travail pour une orthophoniste (planche `planche.py`) : RIEN de ceci n'est dans l'app.

Repère du portrait : 260 × 300 (y vers le bas). Tête de centre `C`, rayon `R` ; épaules en bas.
Le style est celui de Lou (`pictos/figure.py`) : formes pleines et arrondies, cheveux bouclés
foncés, t-shirt jaune, yeux ovales avec reflet, joues roses — mais la peau est un PARAMÈTRE
(l'adulte la choisit, on ne l'impose jamais) et le visage, vu en grand, a un petit nez et une
vraie bouche (lèvres, dents, langue) pour montrer comment dire le son.

La main a cinq doigts. Elle est décrite dans SON repère : `u` va du poignet vers le bout des
doigts (1 = longueur de la paume), `v` va vers le côté du pouce. `main()` la pose à un poignet,
dans une direction (degrés, 0 = droite, −90 = haut), avec le pouce d'un côté ou de l'autre de
l'écran (`pouce` = +1 : à droite quand les doigts montent ; −1 : à gauche). Chaque doigt est
tendu (angle, plis), replié (on voit la phalange repliée sur la paume, comme dans un poing) ou
suit un chemin donné (le rond du « o », la pince du « ch », le bec du « oin »…).
Stdlib uniquement.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from coloriages.dessin import PALETTE_RGB, arc, cercle, courbe, ellipse, ligne, lisse, poly, rect, tourne, tube
from pictos.figure import CHEVEUX, LANGUE, PEAU, TSHIRT, TSHIRT_OMBRE
from pictos.peinture import ENCRE

# ---------------------------------------------------------------------------
# Couleurs
# ---------------------------------------------------------------------------

# Les quatre couleurs de peau de la palette du coloriage (ColoringView.palette,
# coloriages/dessin.PALETTE_RGB), puis la peau actuelle de Lou (pictos/figure.PEAU).
def _hex(nom: str) -> str:
    return "#" + "".join(f"{v:02X}" for v in PALETTE_RGB[nom])


PEAUX = (
    ("peau claire", _hex("peau claire")),     # #FCDCC0
    ("peau dorée", _hex("peau dorée")),       # #E4AC7A
    ("peau de Lou", PEAU),                    # #B8784E
    ("peau brune", _hex("peau brune")),       # #A66C44
    ("peau foncée", _hex("peau foncée")),     # #623C26
)
FLECHE = "#E6007E"         # le mouvement : magenta vif (lisible sur toutes les peaux et sur le jaune)
VIBRE = "#1E88E5"          # la gorge qui vibre : bleu
INTERIEUR = "#4A1424"      # l'intérieur de la bouche
DENTS = "#FFFFFF"
TABLE = "#B07A4A"
FOND = "#FFFFFF"

W, H = 260.0, 300.0        # le cadre du portrait
C = (130.0, 128.0)         # centre de la tête
R = 56.0                   # rayon du visage
K = R / 23.0               # échelle par rapport à la tête de `figure.py` (visage de rayon 23)
EPAULE_G = (60.0, 224.0)   # épaule à gauche de l'image (bras droit de Lou)
EPAULE_D = (200.0, 224.0)  # épaule à droite de l'image (bras gauche de Lou)
BRAS, AVANT_BRAS = 64.0, 60.0
PAUME = 40.0               # longueur de la paume (l'unité de la main)


def _rgb(h: str) -> tuple[int, int, int]:
    return int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)


def melange(a: str, b: str, t: float) -> str:
    """Couleur entre `a` (t = 0) et `b` (t = 1)."""
    ra, rb = _rgb(a), _rgb(b)
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(ra, rb))


def ombre_de(peau: str) -> str:
    return melange(peau, "#2A1208", 0.28)


def levres_de(peau: str) -> str:
    return melange(peau, "#B8344A", 0.45)


# ---------------------------------------------------------------------------
# La toile : une liste d'éléments SVG, peints du fond vers l'avant
# ---------------------------------------------------------------------------

def _d(formes) -> str:
    return " ".join(c.d() for f in formes for c in f)


@dataclass
class Toile:
    elements: list = field(default_factory=list)

    # Mêmes signatures que `pictos.peinture.Picto` (pour réutiliser `oeil`, `joue`).
    def plein(self, couleur: str, *formes, calque: str = "fond", opacite: float = 1.0) -> Toile:
        col, alpha = couleur[:7], (int(couleur[7:9], 16) / 255 if len(couleur) == 9 else 1.0) * opacite
        op = "" if alpha >= 0.999 else f' fill-opacity="{alpha:.3f}"'
        self.elements.append(f'<path d="{_d(formes)}" fill="{col}"{op}/>')
        return self

    def trait(self, couleur: str, largeur: float, *formes, calque: str = "fond", tirets: str = "") -> Toile:
        t = f' stroke-dasharray="{tirets}"' if tirets else ""
        self.elements.append(f'<path d="{_d(formes)}" fill="none" stroke="{couleur}" stroke-width="{largeur:g}" '
                             f'stroke-linecap="round" stroke-linejoin="round"{t}/>')
        return self

    def contour(self, couleur: str, ombre: str, largeur: float, *formes) -> Toile:
        """Aplat avec un liseré (l'ombre de la peau) : sépare les doigts serrés."""
        self.plein(couleur, *formes)
        return self.trait(ombre, largeur, *formes)

    def texte(self, x: float, y: float, s: str, taille: float = 14, couleur: str = ENCRE, gras: bool = True,
              ancre: str = "middle") -> Toile:
        from html import escape
        poids = ' font-weight="700"' if gras else ""
        self.elements.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{taille:g}" fill="{couleur}" '
                             f'text-anchor="{ancre}" font-family="-apple-system, Helvetica, Arial, sans-serif"'
                             f'{poids}>{escape(s)}</text>')
        return self

    def svg(self, vue: tuple = (0, 0, W, H), largeur: float | None = None, fond: str | None = FOND) -> str:
        x, y, w, h = vue
        largeur = largeur or w
        hauteur = largeur * h / w
        bg = f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" fill="{fond}"/>' if fond else ""
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x:g} {y:g} {w:g} {h:g}" '
                f'width="{largeur:.0f}" height="{hauteur:.0f}">{bg}{"".join(self.elements)}</svg>')


# ---------------------------------------------------------------------------
# Le buste et la tête
# ---------------------------------------------------------------------------

def _f(dx: float, dy: float, leve: float = 0.0) -> tuple[float, float]:
    """Un point du visage, en unités de la tête de `figure.py` (rayon 23), tête un peu levée si `leve`."""
    return (C[0] + dx * K, C[1] + (dy - leve) * K)


def buste(t: Toile, peau: str) -> None:
    """Le t-shirt (épaules), le cou."""
    # T-shirt : épaules arrondies, coupé par le bas du cadre.
    t.plein(TSHIRT, rect(24, 196, 212, 160, r=58))
    # Cou (l'ombre du menton en haut), puis l'encolure.
    t.plein(peau, rect(C[0] - 19, 160, 38, 48, r=10))
    t.plein(ombre_de(peau) + "60", ellipse(C[0], 182, 19, 7))
    t.trait(TSHIRT_OMBRE, 5, arc(C[0], 196, 30, 15, 165, 16))


def bras_au_repos(t: Toile, peau: str, cote: str) -> None:
    """Le bras qui ne fait rien : il descend le long du corps (hors du cadre)."""
    # Le buste est coupé sous les épaules : le bras qui pend reste sous le cadre.
    _ = (t, peau, cote)


def tete(t: Toile, peau: str, bouche_cle: str, leve: float = 0.0) -> None:
    """La tête de Lou en grand (cheveux, oreilles, visage, nez, yeux, joues, bouche)."""
    x, y = C
    # Boucles derrière (comme `figure._tete`), oreilles, visage, frange.
    for a in range(160, 385, 25):
        t.plein(CHEVEUX, cercle(x + 22 * K * math.cos(math.radians(a)), y - 4 * K + 20 * K * math.sin(math.radians(a)),
                                9 * K))
    for s in (-1, 1):
        t.plein(peau, cercle(x + s * (R - 1), y + 2 * K, 5.5 * K))
        t.plein(ombre_de(peau) + "70", cercle(x + s * (R + 1), y + 2 * K, 2.6 * K))
    t.plein(peau, cercle(x, y, R))
    for dx in (-15, -5, 5, 15):
        t.plein(CHEVEUX, cercle(x + dx * K, y - 17 * K + abs(dx) * 0.18 * K, 7.5 * K))
    # Yeux (regard un peu vers le haut si la tête est levée), joues, nez.
    from pictos.peinture import joue, oeil
    for s in (-1, 1):
        ex, ey = _f(s * 8.5, 1.5, leve)
        oeil(t, ex, ey, 4.2 * K * 0.9, regard=(0, -2.5 if leve else 0))
        jx, jy = _f(s * 14, 8.5, leve)
        joue(t, jx, jy, 4 * K)
    nx, ny = _f(0, 6.2, leve)
    t.plein(ombre_de(peau) + "B0", ellipse(nx, ny, 2.6 * K * 0.95, 1.7 * K))
    bouche(t, peau, bouche_cle, _f(0, 12.6, leve))


# ---------------------------------------------------------------------------
# Les bouches (vues de face), centrées sur `b` ; échelle : le portrait
# ---------------------------------------------------------------------------

def _levres(t: Toile, peau: str, b, demi_l: float, demi_h: float, epaisseur: float) -> None:
    """Un anneau de lèvres (ellipse pleine) ; l'intérieur est peint ensuite."""
    t.plein(levres_de(peau), ellipse(b[0], b[1], demi_l + epaisseur, demi_h + epaisseur))


def _ouverture(t: Toile, b, demi_l: float, demi_h: float, dents_haut: float = 0.0, dents_bas: float = 0.0,
               langue: float = 0.0, langue_haut: bool = False) -> None:
    """L'intérieur sombre, les dents (hauteur visible), la langue (hauteur visible en bas)."""
    t.plein(INTERIEUR, ellipse(b[0], b[1], demi_l, demi_h))
    # Pas de découpe : chaque élément est dessiné assez petit pour rester dans l'ouverture.
    if langue:
        if langue_haut:
            # La pointe de la langue monte derrière les dents du haut.
            x, y, dl, dh = b[0], b[1], demi_l, demi_h
            t.plein(LANGUE, lisse([(x - dl * 0.75, y + dh * 0.55), (x - dl * 0.3, y - dh * 0.1), (x, y - dh * 0.62),
                                   (x + dl * 0.3, y - dh * 0.1), (x + dl * 0.75, y + dh * 0.55), (x, y + dh * 0.92)]))
            t.trait(melange(LANGUE, INTERIEUR, 0.35), 1.2, ligne((x, y - dh * 0.3), (x, y + dh * 0.5)))
        else:
            t.plein(LANGUE, ellipse(b[0], b[1] + demi_h * (1 - langue * 0.5), demi_l * 0.72, demi_h * langue * 0.62))
    if dents_haut:
        t.plein(DENTS, _dans_ellipse(b, demi_l, demi_h, haut=True, h=dents_haut))
    if dents_bas:
        t.plein(DENTS, _dans_ellipse(b, demi_l, demi_h, haut=False, h=dents_bas))


def _dans_ellipse(b, a: float, bb: float, haut: bool, h: float):
    """La bande haute (ou basse) d'une ellipse, de hauteur `h` : les dents."""
    s = -1 if haut else 1
    yc = b[1] + s * (bb - h)          # la ligne qui coupe l'ellipse
    pts = []
    for k in range(73):
        ang = math.radians(k * 5)
        p = (b[0] + a * math.cos(ang), b[1] + bb * math.sin(ang))
        if (p[1] <= yc) if haut else (p[1] >= yc):
            pts.append(p)
    # Ramène le polygone dans l'ordre le long de l'arc (de gauche à droite) puis ferme par la corde.
    pts.sort(key=lambda p: p[0])
    dy = (yc - b[1]) / bb
    demi = a * math.sqrt(max(0.0, 1 - dy * dy))
    return poly([(b[0] - demi, yc)] + pts + [(b[0] + demi, yc)])


def bouche(t: Toile, peau: str, cle: str, b) -> None:
    lev = levres_de(peau)
    if cle == "neutre":
        t.trait(lev, 3.4, courbe([(b[0] - 11, b[1] - 1), (b[0], b[1] + 3.5), (b[0] + 11, b[1] - 1)]))
    elif cle == "fermee":
        # Lèvres jointes, un peu pincées : deux lèvres pleines et la ligne entre elles.
        t.plein(lev, ellipse(b[0], b[1], 13, 6.2))
        t.trait(INTERIEUR, 2.0, courbe([(b[0] - 12, b[1] + 0.5), (b[0], b[1] - 0.5), (b[0] + 12, b[1] + 0.5)]))
    elif cle == "dents_levre":
        # Les dents du haut posées sur la lèvre du bas (la lèvre du bas rentre un peu).
        t.plein(lev, ellipse(b[0], b[1] + 2, 14, 7.5))
        t.plein(INTERIEUR, ellipse(b[0], b[1] - 0.5, 11, 3.6))
        t.plein(DENTS, rect(b[0] - 9, b[1] - 3.2, 18, 6.2, r=2))
        t.trait(melange(DENTS, ENCRE, 0.35), 0.8, ligne((b[0], b[1] - 3), (b[0], b[1] + 2.8)))
        t.plein(lev, rect(b[0] - 11, b[1] - 8.5, 22, 5.5, r=2.7))          # lèvre du haut relevée
    elif cle == "avancee":
        # Lèvres arrondies poussées en avant (épaisses), dents presque jointes.
        _levres(t, peau, b, 7.5, 6.5, 5.5)
        t.plein(INTERIEUR, ellipse(b[0], b[1], 7.5, 6.5))
        t.plein(DENTS, rect(b[0] - 6, b[1] - 4.2, 12, 3.6, r=1.4))
        t.plein(DENTS, rect(b[0] - 5.5, b[1] + 0.9, 11, 3.2, r=1.4))
        t.trait(melange(lev, ENCRE, 0.4), 1.0, arc(b[0], b[1], 11.5, 200, 340, 10.5))
    elif cle == "petite_ronde":
        _levres(t, peau, b, 4.2, 5.2, 5.5)
        t.plein(INTERIEUR, ellipse(b[0], b[1], 4.2, 5.2))
    elif cle == "ronde":
        _levres(t, peau, b, 7.8, 10, 4.6)
        _ouverture(t, b, 7.8, 10, langue=0.55)
    elif cle == "etiree":
        # Lèvres étirées, dents presque jointes : un large sourire de dents.
        t.plein(lev, ellipse(b[0], b[1], 19, 6.5))
        t.plein(INTERIEUR, ellipse(b[0], b[1], 16, 4.2))
        t.plein(DENTS, _dans_ellipse(b, 16, 4.2, haut=True, h=3.6))
        t.plein(DENTS, _dans_ellipse(b, 16, 4.2, haut=False, h=3.2))
    elif cle == "grande":
        _levres(t, peau, (b[0], b[1] + 4), 12, 15, 3.6)
        _ouverture(t, (b[0], b[1] + 4), 12, 15, dents_haut=3.4, langue=0.6)
    elif cle == "mi_ouverte":
        _levres(t, peau, (b[0], b[1] + 1), 11.5, 7.5, 3.4)
        _ouverture(t, (b[0], b[1] + 1), 11.5, 7.5, dents_haut=2.6, langue=0.7)
    elif cle == "langue_haut":
        _levres(t, peau, (b[0], b[1] + 1), 11, 8, 3.4)
        _ouverture(t, (b[0], b[1] + 1), 11, 8, dents_haut=2.4, langue=1, langue_haut=True)
    elif cle == "fond":
        # Entrouverte, la langue en arrière : à l'avant, on ne voit que le sombre (et les dents du haut).
        _levres(t, peau, (b[0], b[1] + 1), 10, 7, 3.4)
        _ouverture(t, (b[0], b[1] + 1), 10, 7, dents_haut=2.4)
        t.plein(melange(LANGUE, INTERIEUR, 0.55), ellipse(b[0], b[1] + 5.4, 6, 2))
    else:
        raise KeyError(cle)


# ---------------------------------------------------------------------------
# La main à cinq doigts
# ---------------------------------------------------------------------------

DOIGTS = ("index", "majeur", "annulaire", "auriculaire")
BASE = {"index": (0.97, 0.37), "majeur": (1.0, 0.12), "annulaire": (0.97, -0.13), "auriculaire": (0.89, -0.36),
        "pouce": (0.32, 0.44)}
LONG = {"index": 0.86, "majeur": 0.95, "annulaire": 0.88, "auriculaire": 0.70, "pouce": 0.80}
LARGE = {"index": 0.29, "majeur": 0.30, "annulaire": 0.285, "auriculaire": 0.25, "pouce": 0.32}
PHALANGES = (0.46, 0.30, 0.24)
PAUME_PTS = [(-0.02, 0.30), (0.30, 0.50), (0.80, 0.50), (1.02, 0.30), (1.03, -0.20), (0.92, -0.47),
             (0.45, -0.46), (-0.02, -0.30)]


def T(angle: float, *plis: float):
    """Doigt tendu : angle (degrés, + vers le pouce) depuis l'axe des doigts, plis aux articulations."""
    return ("t", angle, plis)


REP = ("r",)            # replié sur la paume (on voit la phalange repliée, comme dans un poing)


def P(*pts):
    """Doigt qui suit un chemin (repère de la main)."""
    return ("p", pts)


def _rond(o, r, a0, a1, n=6):
    return [(o[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             o[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


_RING = ((1.26, 0.66), 0.34)
_INDEX_O = [BASE["index"]] + _rond(*_RING, -132, 112, 8)
_POUCE_O = [BASE["pouce"], (0.62, 0.72), (0.90, 0.92), (1.06, 0.98), (1.16, 0.98)]

# Les formes de main (doigt → T / REP / P ; « ordre » : ce qui est peint par-dessus en dernier).
FORMES = {
    "ouverte": dict(pouce=T(52, -10), index=T(14), majeur=T(3), annulaire=T(-8), auriculaire=T(-19)),
    "plate": dict(pouce=T(20, -6), index=T(2), majeur=T(0), annulaire=T(-2), auriculaire=T(-4)),
    "poing": dict(pouce=REP, index=REP, majeur=REP, annulaire=REP, auriculaire=REP),
    "index": dict(pouce=REP, index=T(0), majeur=REP, annulaire=REP, auriculaire=REP),
    "deux_serres": dict(pouce=REP, index=T(4), majeur=T(-2), annulaire=REP, auriculaire=REP),
    "deux_ecartes": dict(pouce=REP, index=T(17), majeur=T(-10), annulaire=REP, auriculaire=REP),
    "rond_o": dict(pouce=P(*_POUCE_O), index=P(*_INDEX_O), majeur=REP, annulaire=REP, auriculaire=REP),
    "rond_o_tendu": dict(pouce=P(*_POUCE_O), index=P(*_INDEX_O), majeur=T(-2), annulaire=T(-9),
                         auriculaire=T(-17)),
    # L'index croisé sur le pouce : un X bien visible (le pouce penche vers les doigts, l'index vers le pouce).
    "croise": dict(pouce=P(BASE["pouce"], (0.78, 0.62), (1.18, 0.52), (1.56, 0.30)),
                   index=P(BASE["index"], (1.18, 0.52), (1.42, 0.80), (1.62, 1.02)),
                   majeur=REP, annulaire=REP, auriculaire=REP, ordre=("pouce", "index")),
    "pince_fermee": dict(pouce=P(BASE["pouce"], (0.62, 0.68), (1.02, 0.80), (1.36, 0.74)),
                         index=P(BASE["index"], (1.22, 0.40), (1.40, 0.56), (1.42, 0.70)),
                         majeur=REP, annulaire=REP, auriculaire=REP),
    "pince_ouverte": dict(pouce=P(BASE["pouce"], (0.60, 0.78), (0.92, 1.02), (1.10, 1.14)),
                          index=P(BASE["index"], (1.26, 0.36), (1.52, 0.44), (1.68, 0.56)),
                          majeur=REP, annulaire=REP, auriculaire=REP),
    "bec_ferme": dict(pouce=P(BASE["pouce"], (0.78, 0.66), (1.34, 0.62), (1.78, 0.40)),
                      index=T(-2), majeur=T(-5), annulaire=REP, auriculaire=REP, ordre=("index", "majeur", "pouce")),
    "bec_ouvert": dict(pouce=P(BASE["pouce"], (0.74, 0.74), (1.22, 0.92), (1.58, 1.02)),
                       index=T(-14), majeur=T(-17), annulaire=REP, auriculaire=REP),
    "trois_doigts": dict(pouce=P(BASE["pouce"], (0.82, 0.70), (1.30, 0.66), (1.62, 0.52)),
                         index=P(BASE["index"], (1.30, 0.36), (1.64, 0.30)), majeur=P(BASE["majeur"], (1.34, 0.08),
                                                                                        (1.66, 0.02)),
                         annulaire=REP, auriculaire=REP),
    "crochet": dict(pouce=REP, index=T(4, 80, 75), majeur=REP, annulaire=REP, auriculaire=REP),
    "mi_fermee": dict(pouce=T(78, -40, -30), index=T(16, 38, 40), majeur=T(9, 38, 40), annulaire=T(1, 38, 40),
                      auriculaire=T(-7, 38, 40)),
    "pouce_index": dict(pouce=T(78, -4), index=T(4), majeur=REP, annulaire=REP, auriculaire=REP),
    # Le « ch » : pince grande ouverte, le pouce vers une joue, l'index vers l'autre (la courbe entre
    # eux dessine un c sous la bouche).
    "pince_ch": dict(pouce=P(BASE["pouce"], (0.80, 0.78), (1.30, 0.90), (1.74, 0.80)),
                     index=P(BASE["index"], (1.16, 0.06), (1.44, -0.44), (1.74, -0.72)),
                     majeur=REP, annulaire=REP, auriculaire=REP, ordre=("pouce", "index")),
}


def _chemin_tendu(doigt: str, spec) -> list:
    _, angle, plis = spec
    pts = [BASE[doigt]]
    a = angle
    longs = PHALANGES if doigt != "pouce" else (0.52, 0.48)
    for k, part in enumerate(longs):
        if k >= 1 and k - 1 < len(plis):
            a += plis[k - 1]
        p, lg = pts[-1], LONG[doigt] * part
        pts.append((p[0] + lg * math.cos(math.radians(a)), p[1] + lg * math.sin(math.radians(a))))
    return pts


@dataclass
class Main:
    """Une main posée : poignet (écran), direction des doigts (degrés), côté du pouce, forme, taille."""
    poignet: tuple
    direction: float
    forme: str
    pouce: int = -1
    taille: float = PAUME

    def ecran(self, q):
        d = math.radians(self.direction)
        ux, uy = math.cos(d), math.sin(d)
        px, py = -uy * self.pouce, ux * self.pouce
        s = self.taille
        return (self.poignet[0] + s * (q[0] * ux + q[1] * px), self.poignet[1] + s * (q[0] * uy + q[1] * py))

    def chemins(self) -> dict:
        """Chemins (repère de la main) des doigts non repliés."""
        out = {}
        for doigt, spec in FORMES[self.forme].items():
            if doigt == "ordre" or spec == REP:
                continue
            out[doigt] = _chemin_tendu(doigt, spec) if spec[0] == "t" else list(spec[1])
        return out

    def bout(self, doigt: str):
        """Le bout d'un doigt (écran), pour une flèche."""
        ch = self.chemins().get(doigt)
        if ch is None:
            return self.ecran((1.12, BASE[doigt][1]))
        return self.ecran(ch[-1])

    def milieu(self):
        return self.ecran((0.55, 0.0))

    def local(self, quoi) -> tuple:
        """Un point du repère de la main : le bout d'un doigt (« index »…) ou un point (u, v)."""
        if isinstance(quoi, str):
            ch = self.chemins().get(quoi)
            return ch[-1] if ch else (1.12, BASE[quoi][1])
        return quoi

    def posee(self, quoi, cible) -> Main:
        """La même main, déplacée pour que `quoi` (bout d'un doigt ou point (u, v)) touche `cible`."""
        q = self.ecran(self.local(quoi))
        return Main((self.poignet[0] + cible[0] - q[0], self.poignet[1] + cible[1] - q[1]), self.direction,
                    self.forme, self.pouce, self.taille)


def main(t: Toile, m: Main, peau: str) -> None:
    """Peint la main : doigts tendus derrière la paume, la paume, les doigts repliés, le pouce."""
    om = ombre_de(peau)
    s = m.taille
    lw = max(1.0, s * 0.04)
    forme = FORMES[m.forme]
    ch = m.chemins()
    ordre = forme.get("ordre", ())

    def doigt_tube(doigt):
        pts = [m.ecran(q) for q in ch[doigt]]
        w = LARGE[doigt] * s
        larg = [w * (1 - 0.12 * i / max(1, len(pts) - 1)) for i in range(len(pts))]
        t.contour(peau, om, lw, tube(pts, larg))
        # Un petit ongle clair au bout (on voit que c'est un bout de doigt).
        a, b = pts[-2], pts[-1]
        ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
        n = (b[0] - math.cos(math.radians(ang)) * w * 0.28, b[1] - math.sin(math.radians(ang)) * w * 0.28)
        t.plein(melange(peau, "#FFFFFF", 0.35), ellipse(n[0], n[1], w * 0.24, w * 0.19, rot=ang))

    # 1. Doigts tendus (sauf le pouce et ceux de « ordre ») : derrière la paume.
    for doigt in DOIGTS:
        if doigt in ch and doigt not in ordre:
            doigt_tube(doigt)
    # 2. La paume.
    t.contour(peau, om, lw, lisse([m.ecran(q) for q in PAUME_PTS], 0.9))
    t.trait(om + "90", lw, courbe([m.ecran((0.30, 0.30)), m.ecran((0.55, 0.05)), m.ecran((0.62, -0.25))]))
    # 3. Doigts repliés : la phalange repliée sur le haut de la paume (un poing vu de face).
    for doigt in DOIGTS:
        if forme[doigt] == REP:
            v = BASE[doigt][1]
            w = LARGE[doigt] * s * 1.12
            t.contour(peau, om, lw, tube([m.ecran((1.10, v)), m.ecran((0.66, v * 0.95))], w))
            t.trait(om, lw, ligne(m.ecran((0.80, v - LARGE[doigt] * 0.36)), m.ecran((0.80, v + LARGE[doigt] * 0.36))))
    # 4. Le pouce (replié : en travers des doigts repliés), puis les doigts de « ordre ».
    if forme["pouce"] == REP:
        pts = [m.ecran(q) for q in (BASE["pouce"], (0.55, 0.40), (0.74, 0.18), (0.78, -0.06))]
        t.contour(peau, om, lw, tube(pts, [LARGE["pouce"] * s, LARGE["pouce"] * s, LARGE["pouce"] * s * 0.92,
                                           LARGE["pouce"] * s * 0.86]))
    elif "pouce" not in ordre:
        doigt_tube("pouce")
    for doigt in ordre:
        doigt_tube(doigt)


def bras(t: Toile, peau: str, epaule, poignet, plie: int = 1, coude=None) -> None:
    """Le bras de l'épaule au poignet : le coude se plie du côté `plie` (ou est imposé) ; il
    s'étire si la main est loin. Une manche courte de t-shirt couvre le haut du bras."""
    if coude is None:
        dx, dy = poignet[0] - epaule[0], poignet[1] - epaule[1]
        d = math.hypot(dx, dy)
        a, b = BRAS, AVANT_BRAS
        if d > a + b - 4:
            f = d / (a + b - 4)
            a, b = a * f, b * f
        d = max(d, abs(a - b) + 1)
        th = math.atan2(dy, dx)
        al = math.acos(max(-1, min(1, (a * a + d * d - b * b) / (2 * a * d))))
        coude = (epaule[0] + a * math.cos(th + plie * al), epaule[1] + a * math.sin(th + plie * al))
    # Deux segments droits et un coude rond (un seul tube plié trop fort fait des pointes).
    om = ombre_de(peau) + "80"
    haut = tube([epaule, coude], [28, 25])
    avant = tube([coude, poignet], [25, 19])
    t.plein(peau, haut).trait(om, 1.2, haut)
    t.plein(peau, avant).trait(om, 1.2, avant)
    t.plein(peau, cercle(coude[0], coude[1], 11.6))
    m = (epaule[0] + (coude[0] - epaule[0]) * 0.42, epaule[1] + (coude[1] - epaule[1]) * 0.42)
    t.plein(TSHIRT, tube([epaule, m], [40, 36]))
    t.trait(TSHIRT_OMBRE, 1.6, ligne(*_bord_manche(epaule, m, 18)))


def _bord_manche(e, m, r):
    ang = math.atan2(m[1] - e[1], m[0] - e[0]) + math.pi / 2
    return [(m[0] + r * math.cos(ang), m[1] + r * math.sin(ang)), (m[0] - r * math.cos(ang), m[1] - r * math.sin(ang))]


# ---------------------------------------------------------------------------
# Signes : flèches, numéros, vibration de la gorge
# ---------------------------------------------------------------------------

def fleche(t: Toile, pts, couleur: str = FLECHE, largeur: float = 4.2, tete_l: float = 11.0,
           deux_bouts: bool = False, tirets: str = "") -> None:
    """Une flèche douce passant par `pts`, pointe au dernier point (et au premier si `deux_bouts`)."""
    t.trait(couleur, largeur, courbe(list(pts)) if len(pts) > 2 else ligne(*pts), tirets=tirets)
    _pointe(t, pts[-2], pts[-1], couleur, tete_l)
    if deux_bouts:
        _pointe(t, pts[1], pts[0], couleur, tete_l)


def _pointe(t: Toile, a, b, couleur: str, lg: float) -> None:
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    p1 = (b[0] - lg * math.cos(ang - 0.5), b[1] - lg * math.sin(ang - 0.5))
    p2 = (b[0] - lg * math.cos(ang + 0.5), b[1] - lg * math.sin(ang + 0.5))
    pointe = (b[0] + 2 * math.cos(ang), b[1] + 2 * math.sin(ang))
    t.plein(couleur, poly([pointe, p1, p2], r=1.5))


def numero(t: Toile, x: float, y: float, n: int | str, couleur: str = FLECHE, r: float = 9.5) -> None:
    t.plein(couleur, cercle(x, y, r))
    t.texte(x, y + r * 0.42, str(n), taille=r * 1.25, couleur="#FFFFFF")


def vibration(t: Toile) -> None:
    """La gorge vibre : trois petits arcs de chaque côté du cou."""
    cx, cy = C[0], 190.0
    for i, r in enumerate((26, 33, 40)):
        for a0 in (-28, 152):
            t.trait(VIBRE, 3.0 - i * 0.4, arc(cx, cy, r, a0, a0 + 56))


def table(t: Toile, y: float = 262) -> None:
    t.plein(TABLE, rect(-10, y, W + 20, 60))
    t.plein(melange(TABLE, "#FFFFFF", 0.3), rect(-10, y, W + 20, 6))


__all__ = ["BASE", "C", "EPAULE_D", "EPAULE_G", "FLECHE", "FORMES", "H", "Main", "PAUME", "PEAUX", "R",
           "Toile", "W", "bras", "bras_au_repos", "bouche", "buste", "fleche", "main", "numero", "table", "tete",
           "tourne", "vibration"]
