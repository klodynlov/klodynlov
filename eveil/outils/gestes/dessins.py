"""Un portrait de Lou par geste : où est la main, quelle forme, quel mouvement.

Chaque mise en scène suit la description de `gestes.py` (main, place, mouvement) et RIEN
d'autre ; ce qui n'y est pas dit (quelle main, l'angle exact) est un choix de dessin, à
corriger avec l'orthophoniste. Une règle de dessin : la main ne cache jamais la bouche (c'est
elle qui montre comment dire le son) ; quand le livre met la main « devant la bouche », on la
pose juste à côté.

Repère : celui du portrait (`lou_portrait`, 260 × 300, tête de centre (130, 128), rayon 56 ;
yeux y ≈ 132, nez (130, 143), bouche (130, 159), joues (96 | 164, 149), cou (130, 190)).
Les « temps » d'un geste (deux temps, trois temps) sont des vignettes numérotées : la main
seule, dans l'ordre.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .gestes import Geste
from .lou_portrait import (FLECHE, PAUME, Main, Toile, bras, bras_au_repos, buste, fleche, main, numero, table, tete,
                           vibration)

NEZ = (130.0, 143.0)
BOUCHE = (130.0, 159.0)
JOUE_G, JOUE_D = (98.0, 152.0), (162.0, 152.0)


@dataclass
class Bras:
    main: Main
    epaule: str = "d"          # « g » / « d » (côté de l'image), ou "" : le bras ne se voit pas
    plie: int = 1              # côté où le coude se plie
    coude: tuple | None = None # coude imposé (sinon calculé)


@dataclass
class Fleche:
    pts: tuple
    numero: str = ""           # « 1 → 2 » : un numéro au départ
    deux_bouts: bool = False
    tirets: str = ""


@dataclass
class Scene:
    bras: list = field(default_factory=list)
    fleches: list = field(default_factory=list)
    vignettes: tuple = ()      # formes de main successives (« temps »)
    vignette_dir: float = -90.0
    vignette_pouce: int = -1
    leve: float = 0.0          # tête un peu levée (è)
    table: bool = False
    note: str = ""             # une étiquette dans le dessin (ex. « l'autre main dans le dos »)
    note_xy: tuple = (0.0, 0.0)


def _devant(forme: str, **kw) -> Bras:
    """La main devant soi, à hauteur de poitrine, côté droit de l'image (vers l'enfant)."""
    return Bras(Main(kw.pop("poignet", (202, 298)), kw.pop("direction", -100), forme, pouce=-1, taille=44, **kw),
                coude=(236, 330))


def _a(forme: str, direction: float, pouce: int, quoi, cible, taille: float = PAUME) -> Main:
    """Une main posée pour que `quoi` (bout d'un doigt, ou point (u, v) de la main) touche `cible`."""
    return Main((0.0, 0.0), direction, forme, pouce, taille).posee(quoi, cible)


SCENES = {
    # --- voyelles -------------------------------------------------------------------------
    # Bras levé, main ouverte à hauteur de la tête, loin du corps, immobile.
    "a": Scene([Bras(Main((224, 182), -86, "ouverte", pouce=-1), coude=(250, 240))]),
    # Pouce et index joints en rond, devant soi.
    "o": Scene([_devant("rond_o")]),
    # Trois temps sur un son tenu, le bras s'allonge.
    "ou": Scene([_devant("rond_o")], fleches=[Fleche(((226, 214), (244, 180), (246, 140)), numero="")],
                vignettes=("rond_o", "deux_serres", "deux_ecartes")),
    # L'index seul dressé, avant-bras levé, coude contre le corps.
    "i": Scene([Bras(Main((212, 220), -92, "index", pouce=-1), coude=(226, 300))]),
    # Index et majeur dressés et écartés, devant soi, main levée.
    "u": Scene([Bras(Main((212, 220), -92, "deux_ecartes", pouce=-1), coude=(226, 300))]),
    # Main à plat, doigts serrés, posée sur le front, penchée vers l'avant (comme l'accent aigu).
    "é": Scene([Bras(Main((80, 112), -54, "plate", pouce=1, taille=36), epaule="g", coude=(22, 170))]),
    # Main à plat sur le sommet de la tête, rejetée en arrière (l'accent grave) ; tête un peu levée.
    "è": Scene([Bras(Main((176, 66), -128, "plate", pouce=-1, taille=36), coude=(250, 130))], leve=1.2),
    # L'index croisé sur le pouce, devant soi.
    "eu": Scene([_devant("croise")]),
    "eu ouvert": Scene([_devant("croise")]),
    "e": Scene([_devant("croise")]),
    # La main ouverte du a, portée sur le nez.
    "an": Scene([Bras(_a("ouverte", -158, 1, "auriculaire", (137, 144), 36), coude=(250, 240))]),
    # Le rond du o (doigts tendus) au contact du nez.
    "on": Scene([Bras(_a("rond_o_tendu", -132, -1, (1.26, 0.66), (149, 148), 30), coude=(240, 260))]),
    # L'index du i, poing fermé, devant le nez, au contact.
    "in": Scene([Bras(_a("index", -164, 1, "index", (138, 140), 32), coude=(252, 250))]),
    # Main fermée puis ouverte d'un coup, devant soi : deux temps.
    "oi": Scene([_devant("poing")], vignettes=("poing", "ouverte")),
    # Pouce, index, majeur en bec : il se ferme, s'ouvre, se referme.
    "oin": Scene([Bras(Main((240, 270), -168, "bec_ferme", pouce=-1), coude=(262, 330))],
                 vignettes=("bec_ferme", "bec_ouvert", "bec_ferme"), vignette_dir=-170.0, vignette_pouce=-1),
    # --- consonnes ------------------------------------------------------------------------
    # Pouce et index écartés en pince, posés sur les deux joues ; on garde la pose.
    "ch": Scene([Bras(Main((130, 232), -90, "pince_ch", pouce=-1, taille=40), coude=(200, 320))]),
    # L'index tendu, devant soi, sur le côté ; dessine lentement un grand s en l'air.
    "s": Scene([Bras(Main((218, 240), -96, "index", pouce=-1), coude=(232, 310))],
               fleches=[Fleche(((248, 60), (224, 48), (206, 66), (224, 88), (244, 108), (228, 130), (204, 124)))]),
    # L'index tendu, devant soi : un zigzag rapide, comme un éclair.
    "z": Scene([Bras(Main((218, 240), -96, "index", pouce=-1), coude=(232, 310))],
               fleches=[Fleche(((206, 56), (248, 62), (208, 100), (250, 106), (212, 142)))]),
    # L'index tendu contre la joue : il s'avance vers la joue comme pour la piquer.
    "j": Scene([Bras(_a("index", -150, 1, "index", (176, 156)), coude=(250, 270))],
               fleches=[Fleche(((214, 126), (184, 140)))]),
    # Main à plat, partant du milieu du corps : tout le bras glisse vers l'extérieur.
    "f": Scene([Bras(Main((184, 258), -178, "plate", pouce=1), coude=(232, 320))],
               fleches=[Fleche(((140, 290), (196, 290), (252, 290)))]),
    # Les deux mains, poignets joints, paumes ouvertes écartées en V, devant soi.
    "v": Scene([Bras(Main((126, 298), -122, "plate", pouce=1, taille=36), epaule="g", coude=(70, 330)),
                Bras(Main((134, 298), -58, "plate", pouce=-1, taille=36), epaule="d", coude=(190, 330))]),
    # Le poing fermé, avant-bras levé, devant soi en hauteur ; il s'ouvre d'un coup au « p ».
    "p": Scene([Bras(Main((214, 206), -92, "poing", pouce=-1), coude=(228, 290))], vignettes=("poing", "ouverte")),
    # La main à moitié fermée, en bas ; le bras vient de l'extérieur vers le milieu ; elle s'ouvre au « b ».
    "b": Scene([Bras(Main((222, 300), -152, "mi_fermee", pouce=1, taille=36), coude=(262, 330))],
               fleches=[Fleche(((256, 246), (214, 248), (166, 262)))], vignettes=("mi_fermee", "ouverte")),
    # Pouce et index qui pincent puis relâchent, en l'air, à hauteur de l'épaule.
    "t": Scene([Bras(Main((228, 268), -96, "pince_fermee", pouce=-1), coude=(244, 330))],
               vignettes=("pince_fermee", "pince_ouverte")),
    # Le même pincement ; l'autre main, fermée, dans le bas du dos.
    "d": Scene([Bras(Main((228, 268), -96, "pince_fermee", pouce=-1), coude=(244, 330))],
               fleches=[Fleche(((50, 244), (22, 266), (28, 298)), tirets="2 7")],
               vignettes=("pince_fermee", "pince_ouverte"), note="autre main : poing dans le dos",
               note_xy=(4, 236)),
    # L'index tendu vers la bouche entrouverte : il s'avance au moment du « k ».
    "k": Scene([Bras(_a("index", -172, 1, "index", (154, 160)), coude=(250, 250))],
               fleches=[Fleche(((208, 140), (172, 150)))]),
    # Comme k, et le pouce : l'index vers la bouche, le pouce vers la gorge.
    "g": Scene([Bras(_a("pouce_index", -172, -1, "index", (154, 156)), coude=(250, 250))],
               fleches=[Fleche(((200, 134), (166, 142)))]),
    # Pouce, index, majeur tendus, bouts posés à plat sur une table : on appuie tant que dure le « mmm ».
    "m": Scene([Bras(_a("trois_doigts", 90, 1, "majeur", (190, 264)), coude=(250, 230))], table=True,
               fleches=[Fleche(((236, 190), (236, 246))), Fleche(((252, 246), (252, 190)))]),
    # Index et majeur à cheval sur le nez.
    "n": Scene([Bras(_a("deux_ecartes", 112, 1, (1.62, 0.13), (131, 140), 36), coude=(254, 120))]),
    # L'index posé sur le nez, qui glisse d'un côté du nez à l'autre.
    "gn": Scene([Bras(_a("index", -174, 1, "index", (132, 142)), coude=(250, 250))],
                fleches=[Fleche(((114, 120), (146, 120)), deux_bouts=True)]),
    # L'index tendu vers le haut, devant la bouche (posé à côté pour la laisser voir) : il monte.
    "l": Scene([Bras(_a("index", -92, -1, "index", (154, 128)), coude=(214, 320))],
               fleches=[Fleche(((202, 176), (202, 132)))]),
    # L'index replié touche le côté du cou, sous la mâchoire.
    "r": Scene([Bras(_a("crochet", -164, 1, "index", (152, 186)), coude=(252, 280))]),
    # L'index tendu à l'horizontale devant la bouche : il s'avance, comme le souffle.
    "ill": Scene([Bras(_a("index", 180, 1, "index", (152, 160)), coude=(250, 250))],
                 fleches=[Fleche(((202, 144), (246, 144)))]),
}


def vibre(g: Geste) -> bool:
    """« la gorge vibre » (ou « la gorge qui vibre ») dans ce que le geste évoque."""
    return "gorge vibre" in g.evoque or "gorge qui vibre" in g.evoque


def portrait(g: Geste, peau: str, bouche: str | None = None, avec_geste: bool = True) -> Toile:
    """Lou en buste : la bouche du son, et (si le geste est connu) la main qui le fait."""
    t = Toile()
    sc = SCENES.get(g.son) if avec_geste else None
    cotes = {b.epaule for b in sc.bras} if sc else set()
    buste(t, peau)
    for cote in ("g", "d"):
        if cote not in cotes:
            bras_au_repos(t, peau, cote)
    tete(t, peau, bouche or g.bouche, leve=sc.leve if sc else 0.0)
    if sc is None:
        return t
    if sc.table:
        table(t)
    if vibre(g):
        vibration(t)
    for b in sc.bras:
        if b.epaule:
            from .lou_portrait import EPAULE_D, EPAULE_G
            bras(t, peau, EPAULE_G if b.epaule == "g" else EPAULE_D, b.main.poignet, plie=b.plie, coude=b.coude)
        main(t, b.main, peau)
    for f in sc.fleches:
        fleche(t, f.pts, deux_bouts=f.deux_bouts, tirets=f.tirets)
        if f.numero:
            numero(t, f.pts[0][0], f.pts[0][1], f.numero)
    if sc.note:
        t.texte(sc.note_xy[0], sc.note_xy[1], sc.note, taille=10.5, couleur=FLECHE, ancre="start")
    return t


def vignettes(g: Geste, peau: str) -> list[Toile]:
    """Les temps du geste : la main seule, numérotée (vide si le geste est d'un seul temps)."""
    sc = SCENES.get(g.son)
    if not sc or not sc.vignettes:
        return []
    out = []
    for k, forme in enumerate(sc.vignettes, 1):
        t = Toile()
        horiz = abs(abs(sc.vignette_dir) - 180) < 30
        poignet = (88, 50) if horiz else (54, 92)
        main(t, Main(poignet, sc.vignette_dir, forme, pouce=sc.vignette_pouce, taille=30), peau)
        numero(t, 12, 12, k, r=10)
        out.append(t)
    return out


__all__ = ["SCENES", "Scene", "portrait", "vibre", "vignettes"]
