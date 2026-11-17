"""Les pictos des LIEUX (« où ? ») du train des phrases, avec leurs ancres.

Chaque lieu (identifiant `lieu.<nom>`) dit où poser le personnage pour chaque
préposition qu'il accepte : point bas-milieu du carré du personnage, taille, et ordre
de dessin (devant / dedans / derrière). Pour « dedans », les parties qui passent
DEVANT le personnage (bord de la boîte, mur percé de la niche, couverture, eau du
bain…) sont peintes dans le calque « devant » ; le reste du lieu est au « fond ».

Le personnage vit dans un carré 200 × 200 : il occupe à peu près 16…184 et ses pieds
sont vers y ≈ 179, soit 21 unités au-dessus du bas du carré. Posé à l'ancre
(x, y, taille t), ses pieds tombent donc en y − 21·t et le haut de sa tête vers
y − 170·t (chat assis) : `_pose` calcule l'ancre à partir de l'endroit où il pose
les pieds. Règles de lecture (un enfant de 3 ans doit « voir » la préposition) :
  - sur : pieds posés sur le dessus, rien ne le cache ;
  - sous : entièrement à l'abri sous le lieu, plus petit, le dessous juste au-dessus
    de sa tête ;
  - dans : le lieu l'entoure (fond derrière lui, bord devant) ; sa tête reste visible ;
  - devant : plus bas (plus près de nous) et un peu plus grand, il cache une partie
    du lieu ;
  - derrière : plus haut (plus loin), le lieu en cache une bonne partie ; on voit
    encore sa tête qui dépasse, au-dessus ou sur le côté.
Ces règles sont mesurées par `scene.problemes_scene` (le générateur refuse une scène qui
ne se lit pas) ; la planche (`generer --apercu`) pose le personnage type à chaque ancre.
Les lieux sont VIDES : c'est l'enfant qui y met un personnage.
"""
from __future__ import annotations

from coloriages.dessin import (
    Contour, arche, cercle, courbe, ellipse, lisse, ligne, nuage, poly, rect, trou, tube,
)

from .peinture import Picto, ombre

PIEDS = 21.0     # hauteur des pieds au-dessus du bas du carré du personnage (repère 200)


def _pose(p: Picto, preposition: str, x: float, pieds: float, taille: float, ordre: str,
          enfonce: float = 1.0) -> None:
    """Ancre dont le personnage pose les pieds en (x, pieds) — un peu enfoncés (`enfonce`)."""
    p.ancre(preposition, round(x, 1), round(pieds + PIEDS * taille + enfonce, 1), taille, ordre)


# ---------------------------------------------------------------------------
# La boîte en carton
# ---------------------------------------------------------------------------

def boite() -> Picto:
    """Boîte en carton ouverte, rabats écartés (« dans » : seule la tête dépasse du bord)."""
    p = Picto("lieu.boite")
    ombre(p, 100, 180, 78, 7)
    p.plein("#C98B4E", poly([(40, 96), (160, 96), (150, 70), (50, 70)]))          # rabat du fond
    p.plein("#A8703C", rect(36, 92, 128, 18, r=4))                                 # intérieur (fond)
    p.plein("#D99A5B", rect(30, 104, 140, 74, r=6), calque="devant")               # face avant
    p.plein("#EDBB86", rect(30, 102, 140, 6, r=3), calque="devant")                # tranche du carton
    p.plein("#E8B27A", poly([(30, 104), (6, 128), (40, 132), (52, 104)]), calque="devant")   # rabat gauche
    p.plein("#E8B27A", poly([(170, 104), (194, 128), (160, 132), (148, 104)]), calque="devant")
    p.trait("#B77B45", 3, rect(84, 124, 32, 22, r=3), calque="devant")            # étiquette
    _pose(p, "dans", 100, 136, 0.58, "dedans")
    _pose(p, "sur", 100, 104, 0.56, "devant")
    _pose(p, "devant", 100, 184, 0.64, "devant")
    _pose(p, "derriere", 126, 100, 0.54, "derriere")
    return p


# ---------------------------------------------------------------------------
# La niche
# ---------------------------------------------------------------------------

BOIS = "#E9A45B"
BOIS_FONCE = "#CF8840"
PLANCHE = "#CF884099"      # rainure des planches (bois foncé à 60 %)
TOIT = "#E8414B"
TOIT_FONCE = "#C22F3B"
TROU = "#5A3522"


def niche() -> Picto:
    """Niche en bois au toit rouge, porte en arche sombre (celle de `fr.niche`, sans le chien)."""
    p = Picto("lieu.niche")
    ombre(p, 100, 179, 80, 7)
    # Le dedans : l'ombre de la porte (un peu plus grande que le trou, pour ne laisser aucun jour).
    p.plein(TROU, arche(66, 94, 68, 70))
    p.plein("#462817", ellipse(100, 112, 30, 16))
    # Le mur percé (calque « devant ») : le personnage « dans la niche » paraît dans l'embrasure.
    mur = poly([(38, 177), (38, 118), (100, 74), (162, 118), (162, 177)], r=[3, 0, 0, 0, 3])
    porte = arche(70, 98, 60, 62)
    p.plein(BOIS, mur, trou(porte), calque="devant")
    for y in (126, 142):
        p.trait(PLANCHE, 2.5, ligne((44, y), (64, y)), ligne((136, y), (156, y)), calque="devant")
    p.trait(PLANCHE, 2.5, ligne((44, 168), (156, 168)), calque="devant")
    p.trait(BOIS_FONCE, 5, arche(70, 98, 60, 62), calque="devant")                # cadre de la porte
    # Le toit : deux pans arrondis et le faîte.
    p.plein(TOIT, tube([(100, 62), (24, 124)], 22), tube([(100, 62), (176, 124)], 22), calque="devant")
    p.plein(TOIT_FONCE, cercle(100, 60, 12), calque="devant")
    _pose(p, "dans", 100, 172, 0.5, "dedans")
    _pose(p, "sur", 100, 50, 0.48, "devant")
    _pose(p, "devant", 84, 194, 0.56, "devant")
    _pose(p, "derriere", 152, 124, 0.46, "derriere")
    return p


# ---------------------------------------------------------------------------
# La maison
# ---------------------------------------------------------------------------

MUR = "#FFD98A"
MUR_OMBRE = "#F2BE5C"
TOIT_BLEU = "#4F86E8"
TOIT_BLEU_FONCE = "#3A6BC9"
VITRE = "#BFE3FF"
BLANC = "#FFFFFF"


def maison() -> Picto:
    """Petite maison : murs jaunes, toit bleu, cheminée, porte rouge, grande fenêtre."""
    p = Picto("lieu.maison")
    ombre(p, 100, 179, 76, 7)
    # Derrière la fenêtre : la vitre claire et un reflet (vus seulement par la fenêtre).
    p.plein(VITRE, rect(96, 109, 52, 49, r=4))
    p.plein("#FFFFFF99", poly([(104, 152), (130, 112), (140, 112), (114, 152)]))
    # La cheminée (derrière le toit).
    p.plein("#D9674A", rect(126, 42, 18, 40, r=2), calque="devant")
    p.plein("#B9503A", rect(122, 38, 26, 9, r=3), calque="devant")
    # Le mur percé de la fenêtre, la porte, le toit.
    mur = rect(40, 98, 120, 79, r=3)
    fenetre = rect(98, 111, 48, 45, r=3)
    p.plein(MUR, mur, trou(fenetre), calque="devant")
    p.plein(MUR_OMBRE, rect(40, 104, 120, 7), calque="devant")                      # ombre sous le toit
    p.trait(BLANC, 5, fenetre, calque="devant")                                     # cadre de la fenêtre
    p.plein(BLANC, rect(92, 154, 60, 8, r=3), calque="devant")                      # appui
    p.plein("#E8414B", arche(54, 122, 30, 55), calque="devant")                     # porte
    p.plein("#FFD35A", cercle(76, 152, 3.2), calque="devant")                       # poignée
    p.plein(TOIT_BLEU, poly([(26, 106), (100, 40), (174, 106)], r=[8, 10, 8]), calque="devant")
    p.plein(TOIT_BLEU_FONCE, rect(28, 100, 144, 8, r=4), calque="devant")           # bord du toit
    _pose(p, "dans", 122, 170, 0.38, "dedans")
    _pose(p, "sur", 100, 46, 0.4, "devant")
    _pose(p, "devant", 104, 192, 0.46, "devant")
    _pose(p, "derriere", 163, 164, 0.4, "derriere")
    return p


# ---------------------------------------------------------------------------
# La table
# ---------------------------------------------------------------------------

def table() -> Picto:
    """Table en bois à quatre pieds, vue de face et un peu d'en haut."""
    p = Picto("lieu.table")
    ombre(p, 100, 179, 82, 7)
    # Au fond : les deux pieds de derrière (plus sombres, plus courts).
    p.plein("#A96A34", rect(52, 112, 10, 50, r=3), rect(138, 112, 10, 50, r=3))
    # Devant le personnage « sous la table » : le plateau et les pieds de devant.
    p.plein("#C98244", rect(28, 112, 14, 67, r=4), rect(158, 112, 14, 67, r=4), calque="devant")
    p.plein(BOIS_FONCE, rect(20, 104, 160, 16, r=6), calque="devant")               # chant du plateau
    p.plein(BOIS, poly([(44, 90), (156, 90), (180, 108), (20, 108)], r=6), calque="devant")
    p.plein("#F4BD7E", poly([(58, 94), (142, 94), (150, 100), (50, 100)], r=3), calque="devant")
    _pose(p, "sur", 100, 100, 0.45, "devant")
    _pose(p, "sous", 100, 172, 0.34, "dedans")
    _pose(p, "devant", 100, 192, 0.62, "devant")
    _pose(p, "derriere", 100, 112, 0.45, "derriere")
    return p


# ---------------------------------------------------------------------------
# Le lit
# ---------------------------------------------------------------------------

LIT = "#8C6FE0"
LIT_FONCE = "#7155C8"
COUVERTURE = "#4F8FEA"
COUVERTURE_FONCEE = "#3B75D0"
DRAP = "#F4F8FF"
DRAP_BORD = "#C9DDF2"


def lit() -> Picto:
    """Lit vu de côté : tête de lit à gauche, oreiller, couverture bleue au drap retourné."""
    p = Picto("lieu.lit")
    ombre(p, 100, 179, 86, 7)
    # Au fond : la tête de lit, le matelas, l'oreiller.
    p.plein(LIT, arche(14, 50, 28, 129))                                            # tête de lit
    p.plein(LIT_FONCE, arche(20, 60, 16, 50))
    p.plein(DRAP_BORD, rect(36, 92, 128, 26, r=9))                                  # matelas
    p.plein(DRAP, rect(37, 93, 126, 23, r=8))
    p.plein(DRAP_BORD, rect(42, 72, 50, 30, r=14))                                  # oreiller (liseré)
    p.plein(BLANC, rect(44, 73, 46, 26, r=13))
    # Devant le personnage « dans le lit » : la couverture et son drap retourné, le cadre, le pied de lit.
    p.plein(COUVERTURE, poly([(52, 90), (166, 90), (166, 124), (52, 124)], r=[7, 4, 6, 6]), calque="devant")
    p.plein(COUVERTURE_FONCEE, rect(52, 116, 114, 8, r=4), calque="devant")
    for x, y in ((96, 101), (124, 110), (152, 100), (110, 116), (140, 118), (82, 114)):
        p.plein("#FFFFFF66", cercle(x, y, 3.4), calque="devant")
    p.plein(DRAP, rect(50, 89, 22, 35, r=7), calque="devant")                      # drap retourné
    p.plein(DRAP_BORD, rect(68, 90, 4, 33), calque="devant")
    p.plein(LIT, rect(34, 118, 134, 14, r=6), calque="devant")                     # côté du lit
    p.plein(LIT, arche(158, 84, 28, 95), calque="devant")                          # pied de lit
    p.plein(LIT_FONCE, arche(164, 92, 16, 28), calque="devant")
    _pose(p, "dans", 70, 114, 0.4, "dedans")
    _pose(p, "sur", 124, 94, 0.42, "devant")
    _pose(p, "sous", 100, 175, 0.31, "dedans")
    _pose(p, "devant", 100, 194, 0.56, "devant")
    return p


# ---------------------------------------------------------------------------
# L'arbre
# ---------------------------------------------------------------------------

FEUILLE = "#5DBB4F"
FEUILLE_CLAIRE = "#8FD06F"
FEUILLE_FONCEE = "#3E9A3A"
ECORCE = "#8B5A36"
ECORCE_FONCEE = "#6E4428"


def arbre() -> Picto:
    """Arbre rond : tronc, deux branches, grand feuillage ; des feuilles passent devant (« dans »)."""
    p = Picto("lieu.arbre")
    ombre(p, 100, 179, 76, 7)
    # Le tronc, évasé au pied.
    p.plein(ECORCE, lisse([(80, 178), (88, 150), (90, 118), (92, 96), (108, 96), (110, 118), (112, 150),
                           (120, 178)], tension=0.6))
    p.trait(ECORCE_FONCEE, 3, courbe([(96, 170), (98, 140), (97, 116)]))
    # Le feuillage, puis les branches qui y montent (on les voit entre les feuilles).
    p.plein(FEUILLE_FONCEE, nuage(100, 70, 80, 46, bosses=9, hauteur=0.6))
    p.plein(FEUILLE, nuage(100, 67, 77, 43, bosses=9, hauteur=0.6))
    p.plein(FEUILLE_CLAIRE, cercle(62, 46, 13), cercle(88, 32, 8), cercle(42, 74, 6))
    p.plein(ECORCE, tube([(95, 110), (84, 90), (66, 68)], [11, 8, 4.5]),
            tube([(105, 110), (117, 90), (136, 66)], [11, 8, 4.5]))
    # Devant le personnage « dans l'arbre » : une touffe de feuilles au creux des branches,
    # du vert du feuillage (arbre vide : on ne la distingue pas du reste).
    p.plein(FEUILLE, nuage(100, 97, 50, 16, bosses=8, hauteur=0.8), calque="devant")
    p.plein(FEUILLE_CLAIRE, cercle(74, 94, 5), cercle(118, 92, 6), calque="devant")
    _pose(p, "dans", 100, 98, 0.4, "dedans")
    _pose(p, "sous", 148, 178, 0.36, "devant")
    _pose(p, "devant", 100, 194, 0.54, "devant")
    _pose(p, "derriere", 120, 172, 0.36, "derriere")
    return p


# ---------------------------------------------------------------------------
# La baignoire
# ---------------------------------------------------------------------------

EMAIL = "#F7FBFF"
EMAIL_BORD = "#B8D4EC"
BAIN = "#4FC3D9"
BAIN_FONCE = "#36A8C0"
OR = "#F2B632"
OR_FONCE = "#D99A1E"
MOUSSE_BORD = "#9FC6EC"


def _mousse(p: Picto, bulles, calque: str) -> None:
    """Un tas de mousse : des bulles blanches unies, un seul liseré bleu autour."""
    formes = [cercle(x, y, r) for x, y, r in bulles]
    p.trait(MOUSSE_BORD, 4, *formes, calque=calque)
    p.plein(BLANC, *formes, calque=calque)


def _bas_de_stade(x: float, y: float, w: float, h: float) -> list:
    """Moitié basse d'un stade (rectangle aux bouts ronds) : de (x, y + h/2) à (x + w, y + h/2)."""
    r = h / 2
    k = 0.5522847498 * r
    cy = y + r
    return [("C", (x, cy + k), (x + r - k, y + h), (x + r, y + h)), ("L", (x + w - r, y + h)),
            ("C", (x + w - r + k, y + h), (x + w, cy + k), (x + w, cy))]


def baignoire() -> Picto:
    """Baignoire à pieds, vue un peu d'en haut, pleine de mousse."""
    p = Picto("lieu.baignoire")
    ombre(p, 100, 179, 80, 7)
    # Pieds de derrière, robinet.
    p.plein(OR_FONCE, ellipse(60, 160, 8, 10), ellipse(140, 160, 8, 10))
    p.plein(OR, tube([(30, 92), (30, 70), (44, 64)], 7))
    # Le rebord (moitié arrière au fond), l'intérieur, l'eau et la mousse de derrière.
    p.plein(EMAIL_BORD, rect(18, 82, 164, 36, r=18))
    p.plein(EMAIL, rect(20, 83, 160, 33, r=16.5))
    p.plein("#9DD3FA", rect(28, 88, 144, 23, r=11.5))
    # (le bout droit reste dégagé : on y voit l'eau, et le rebord qui barre « derrière la baignoire »)
    _mousse(p, [(40, 94, 9), (54, 88, 12), (72, 82, 14), (92, 79, 15), (112, 81, 14), (128, 88, 11),
                (140, 95, 7)], "fond")
    p.trait(MOUSSE_BORD, 2, cercle(58, 60, 6), cercle(84, 44, 4.5), cercle(116, 50, 7.5))   # bulles qui s'envolent
    p.plein("#FFFFFFCC", cercle(56, 58, 2), cercle(83, 43, 1.5), cercle(113, 47, 2.5))
    # Devant le personnage « dans le bain » : la cuve, le rebord avant, la mousse du bord.
    cuve = poly([(20, 100), (180, 100), (168, 158), (32, 158)], r=[0, 0, 24, 24])
    p.plein(BAIN, cuve, calque="devant")
    p.plein(BAIN_FONCE, rect(40, 146, 120, 8, r=4), calque="devant")
    # Le rebord avant : entre la moitié basse du bord extérieur et celle de l'ouverture.
    ouverture = Contour((28, 99.5), _bas_de_stade(28, 88, 144, 23), closed=False).reversed()
    avant = Contour((20, 99.5), _bas_de_stade(20, 83, 160, 33) + [("L", ouverture.start)] + ouverture.segs)
    p.plein(EMAIL, [avant], calque="devant")
    _mousse(p, [(34, 106, 8), (48, 109, 11), (64, 105, 10), (80, 110, 12), (98, 106, 11), (116, 110, 12),
                (132, 106, 10), (146, 110, 8)], "devant")
    p.trait(MOUSSE_BORD, 1.6, cercle(58, 104, 3.5), cercle(106, 108, 4), cercle(130, 106, 3), calque="devant")
    p.plein(OR, ellipse(46, 164, 9, 12), ellipse(154, 164, 9, 12), calque="devant")  # pieds de devant
    _pose(p, "dans", 100, 124, 0.48, "dedans")
    _pose(p, "devant", 108, 194, 0.54, "devant")
    _pose(p, "derriere", 156, 110, 0.42, "derriere")
    return p


# ---------------------------------------------------------------------------
# La voiture
# ---------------------------------------------------------------------------

def voiture() -> Picto:
    """Petite voiture ronde vue de côté (elle roule vers la droite), deux vitres."""
    p = Picto("lieu.voiture")
    rouge, rouge_fonce = "#E8414B", "#C22F3B"
    ombre(p, 100, 176, 84, 6)
    # Derrière les vitres : le verre clair et le dossier du siège.
    p.plein(VITRE, rect(54, 60, 92, 42, r=10))
    p.plein("#8C5A9E", rect(72, 80, 20, 26, r=8), rect(110, 80, 20, 26, r=8))
    # La carrosserie percée de deux vitres (calque « devant »).
    habitacle = poly([(40, 104), (52, 66), (70, 52), (128, 52), (148, 66), (164, 104)], r=[0, 16, 20, 20, 16, 0])
    vitre_ar = poly([(60, 98), (68, 70), (80, 62), (96, 62), (96, 98)], r=[3, 8, 10, 4, 3])
    vitre_av = poly([(102, 98), (102, 62), (120, 62), (132, 70), (142, 98)], r=[3, 4, 10, 8, 3])
    p.plein(rouge, habitacle, trou(vitre_ar), trou(vitre_av), calque="devant")
    p.plein(rouge, rect(16, 96, 168, 54, r=24), calque="devant")
    p.plein(rouge_fonce, rect(16, 132, 168, 18, r=9), calque="devant")
    p.trait("#FFFFFF59", 3, courbe([(30, 110), (100, 106), (170, 110)]), calque="devant")
    p.plein("#FFD35A", ellipse(180, 112, 5, 8), calque="devant")                    # phare
    p.plein("#FF8A3D", ellipse(19, 112, 4, 7), calque="devant")                     # feu arrière
    p.plein("#FFFFFFB3", rect(108, 112, 12, 5, r=2.5), calque="devant")             # poignée
    for x in (56, 146):
        p.plein("#2E3440", cercle(x, 150, 22), calque="devant")
        p.plein("#C9D0DA", cercle(x, 150, 9), calque="devant")
    _pose(p, "dans", 120, 119, 0.4, "dedans")
    _pose(p, "sur", 100, 53, 0.4, "devant")
    _pose(p, "devant", 118, 194, 0.5, "devant")
    _pose(p, "derriere", 34, 118, 0.44, "derriere")
    return p


PICTOS = [boite(), niche(), maison(), table(), lit(), arbre(), baignoire(), voiture()]

__all__ = ["PICTOS", "arbre", "baignoire", "boite", "lit", "maison", "niche", "table", "voiture"]
