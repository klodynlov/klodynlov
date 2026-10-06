"""Génère le Swift des gestes animés de Lou (`EveilDesign/LouGesture{Art,Data}.swift`) et les vecteurs
de parité (`Tests/EveilDesignTests/LouGestureVectors.swift`).

    cd eveil/outils && python3 -m gestes.generer            # écrit les trois fichiers
    python3 -m gestes.generer --check                       # échoue si un fichier n'est pas à jour

- `LouGestureArt.swift` : les parties FIXES du portrait (buste, tête, yeux, 11 bouches, table, signes
  de vibration), enregistrées depuis `lou_portrait.py` en commandes M/L/C/Z ; les couleurs de peau sont
  des JETONS (`.skin`, `.shade` = `ombre_de`, `.lips` = `levres_de`, `.lipsInk`), retrouvés en rendant
  la tête dans deux peaux ; ce qui monte quand la tête se lève (« è ») porte son déplacement par unité
  de `leve`. Plus les peaux (`PEAUX`) et les formes de main (`FORMES`, `BASE`…), relues par le Swift
  qui CALCULE la main et le bras à chaque image.
- `LouGestureData.swift` : les chronologies de `animation.py` (une fonction par son).
- `LouGestureVectors.swift` : bout de l'index, poignet, coude… à quelques instants (parité Python ↔ Swift).
Règle du projet : jamais de gros littéral d'un seul tenant (débordement de pile en Debug) → une
fonction par élément.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from pictos.peinture import ENCRE

from . import animation
from .animation import ARRIVEE, chronologie, etat
from .dessins import SCENES
from .lou_portrait import (BASE, C, EPAULE_D, EPAULE_G, FORMES, H, LARGE, LONG, PAUME, PAUME_PTS, PEAU, PEAUX,
                           PHALANGES, REP, TSHIRT, TSHIRT_OMBRE, W, K, Toile, _d, bouche, buste, levres_de, melange,
                           ombre_de, table, tete, vibration)
from .gestes import BOUCHES

RACINE = Path(__file__).resolve().parents[2]          # eveil/
ART = RACINE / "ios" / "Sources" / "EveilDesign" / "LouGestureArt.swift"
DATA = RACINE / "ios" / "Sources" / "EveilDesign" / "LouGestureData.swift"
VECTEURS = RACINE / "ios" / "Tests" / "EveilDesignTests" / "LouGestureVectors.swift"

PEAU_B = "#FCDCC0"           # deuxième peau pour reconnaître les couleurs qui en dépendent
LEVE = 1.2                   # tête levée de « è » (mesure du déplacement des yeux, du nez, de la bouche)
IDS_PEAUX = ("claire", "doree", "lou", "brune", "foncee")
NOMS_EN = {"claire": "light skin", "doree": "golden skin", "lou": "Lou's skin", "brune": "brown skin",
           "foncee": "dark skin"}
DOIGTS_SWIFT = {"index": "index", "majeur": "middle", "annulaire": "ring", "auriculaire": "little", "pouce": "thumb"}
JETONS = {
    "skin": lambda p: p,
    "shade": ombre_de,
    "lips": levres_de,
    "lipsInk": lambda p: melange(levres_de(p), ENCRE, 0.4),
}
ENTETE = "// {nom} — FICHIER GÉNÉRÉ par eveil/outils/gestes/generer.py : ne pas modifier à la main."


# ---------------------------------------------------------------------------
# Enregistrer ce que peint `lou_portrait`
# ---------------------------------------------------------------------------

class Enregistreur(Toile):
    """Une toile qui garde les opérations (au lieu du SVG)."""

    def __init__(self):
        super().__init__()
        self.ops: list[tuple] = []          # (genre, couleur #RRGGBB, alpha 0-255, d, largeur)

    def plein(self, couleur, *formes, calque="fond", opacite=1.0):
        a = (int(couleur[7:9], 16) if len(couleur) == 9 else 255) * opacite
        self.ops.append(("plein", couleur[:7].upper(), round(a), _d(formes), 0.0))
        return self

    def trait(self, couleur, largeur, *formes, calque="fond", tirets=""):
        if tirets:
            raise ValueError("pas de tirets dans le portrait animé")
        a = int(couleur[7:9], 16) if len(couleur) == 9 else 255
        self.ops.append(("trait", couleur[:7].upper(), a, _d(formes), float(largeur)))
        return self

    def texte(self, *a, **k):
        raise ValueError("pas de texte dans le portrait animé")


def _enregistre(dessin, peau: str) -> list[tuple]:
    t = Enregistreur()
    dessin(t, peau)
    return t.ops


def _jeton(ca: str, cb: str) -> str:
    """La couleur Swift : fixe, ou un jeton de peau (reconnu dans les deux peaux)."""
    if ca == cb:
        return f".fixed(0x{ca[1:]})"
    for nom, f in JETONS.items():
        if f(PEAU).upper() == ca and f(PEAU_B).upper() == cb:
            return f".{nom}"
    raise ValueError(f"couleur qui dépend de la peau mais d'aucun jeton connu : {ca} / {cb}")


_PREMIER = re.compile(r"^M (-?[\d.]+) (-?[\d.]+)")


def _y0(d: str) -> tuple[float, float]:
    m = _PREMIER.match(d)
    return float(m.group(1)), float(m.group(2))


def _n(v: float) -> str:
    r = round(float(v), 4)
    if r == int(r):
        return str(int(r))
    return repr(r)


def _ops_swift(ops_a, ops_b, ops_leve=None) -> list[str]:
    if len(ops_a) != len(ops_b) or (ops_leve is not None and len(ops_leve) != len(ops_a)):
        raise ValueError("les deux rendus n'ont pas le même nombre d'opérations")
    out = []
    for i, (oa, ob) in enumerate(zip(ops_a, ops_b)):
        genre, ca, alpha, d, largeur = oa
        if ob[2] != alpha or ob[0] != genre:
            raise ValueError("opérations différentes d'une peau à l'autre")
        lift = ""
        if ops_leve is not None:
            (xa, ya), (xb, yb) = _y0(d), _y0(ops_leve[i][3])
            if abs(xa - xb) > 0.11:
                raise ValueError("la tête levée ne doit déplacer que verticalement")
            if abs(yb - ya) > 0.05:
                # Les tracés sont arrondis au dixième : on reconnaît le déplacement exact de `tete`
                # (le visage monte de K par unité de `leve` ; le reflet des yeux, en plus, de 2,5 px).
                mesure = (yb - ya) / LEVE
                exacts = [v for v in (-K, -K - 2.5 / LEVE) if abs(v - mesure) < 0.2]
                if not exacts:
                    raise ValueError(f"déplacement inconnu quand la tête se lève : {mesure:.3f}")
                lift = f", lift: {_n(exacts[0])}"
        couleur = _jeton(ca, ob[1])
        if genre == "plein":
            out.append(f'        s.fill({couleur}, 0x{alpha:02X}, "{d}"{lift})')
        else:
            out.append(f'        s.stroke({couleur}, 0x{alpha:02X}, {_n(largeur)}, "{d}"{lift})')
    return out


def _fonction(nom: str, lignes: list[str]) -> list[str]:
    return [f"    private static func {nom}() -> LouShape {{", "        var s = LouShape()", *lignes,
            "        return s", "    }", ""]


def _nom_bouche(cle: str) -> str:
    return "mouth" + "".join(w.capitalize() for w in cle.split("_"))


def _point(p) -> str:
    return f"CGPoint(x: {_n(p[0])}, y: {_n(p[1])})"


def _spec(spec) -> str:
    if spec == REP:
        return ".folded"
    if spec[0] == "t":
        _, angle, plis = spec
        return f".straight({_n(angle)}, [{', '.join(_n(p) for p in plis)}])"
    return f".path([{', '.join(_point(p) for p in spec[1])}])"


def source_art() -> str:
    bouche_xy = (C[0], C[1] + 12.6 * K)
    L = [ENTETE.format(nom="LouGestureArt.swift"), "//",
         "// Lou en grand (`eveil/outils/gestes/lou_portrait.py`) : les parties fixes en commandes absolues",
         "// M, L, C, Z dans le cadre 260 × 300 ; couleurs fixes 0xRRGGBB ou jetons de peau ; `lift` = déplacement",
         "// vertical par unité de tête levée. Les formes de main (`FORMES`) pour la main calculée en Swift.",
         "", "#if canImport(SwiftUI)", "import SwiftUI", "", "extension LouSkin {",
         "    /// Les cinq peaux de `PEAUX` (la palette du coloriage, puis la peau de Lou), dans le même ordre.",
         "    public static let allCases: [LouSkin] = ["]
    for id_, (nom, hexa) in zip(IDS_PEAUX, PEAUX):
        L.append(f'        LouSkin(id: "{id_}", hex: "{hexa.upper()}", french: "{nom}", english: "{NOMS_EN[id_]}"),')
    L += ["    ]", "}", "", "extension LouArt {",
          f"    static let frame = CGSize(width: {_n(W)}, height: {_n(H)})",
          f"    static let shoulderRight = {_point(EPAULE_D)}",
          f"    static let shoulderLeft = {_point(EPAULE_G)}",
          f"    static let shirt: UInt32 = 0x{TSHIRT[1:].upper()}",
          f"    static let shirtShade: UInt32 = 0x{TSHIRT_OMBRE[1:].upper()}",
          f"    /// Déplacement vertical de la bouche par unité de tête levée.",
          f"    static let mouthLift: CGFloat = {_n(-K)}",
          f"    static let mouthKeys: [String] = [{', '.join(repr(k).replace(chr(39), chr(34)) for k in ['neutre', *BOUCHES])}]",
          "    static let bust: LouShape = bustShape()",
          "    static let head: LouShape = headShape()",
          "    static let table: LouShape = tableShape()",
          "    static let vibration: LouShape = vibrationShape()",
          "    static let mouths: [String: LouShape] = ["]
    for cle in ["neutre", *BOUCHES]:
        L.append(f'        "{cle}": {_nom_bouche(cle)}(),')
    L += ["    ]", ""]
    # Le buste, la table, les signes de vibration (sans tête levée).
    L += _fonction("bustShape", _ops_swift(_enregistre(buste, PEAU), _enregistre(buste, PEAU_B)))
    L += _fonction("tableShape", _ops_swift(_enregistre(lambda t, p: table(t), PEAU),
                                            _enregistre(lambda t, p: table(t), PEAU_B)))
    L += _fonction("vibrationShape", _ops_swift(_enregistre(lambda t, p: vibration(t), PEAU),
                                                _enregistre(lambda t, p: vibration(t), PEAU_B)))
    # La tête sans la bouche (la bouche « neutre » est la fin de `tete`).
    n_bouche = len(_enregistre(lambda t, p: bouche(t, p, "neutre", bouche_xy), PEAU))
    tete_a = _enregistre(lambda t, p: tete(t, p, "neutre"), PEAU)[:-n_bouche]
    tete_b = _enregistre(lambda t, p: tete(t, p, "neutre"), PEAU_B)[:-n_bouche]
    tete_l = _enregistre(lambda t, p: tete(t, p, "neutre", leve=LEVE), PEAU)[:-n_bouche]
    L += _fonction("headShape", _ops_swift(tete_a, tete_b, tete_l))
    for cle in ["neutre", *BOUCHES]:
        L += _fonction(_nom_bouche(cle), _ops_swift(_enregistre(lambda t, p: bouche(t, p, cle, bouche_xy), PEAU),
                                                    _enregistre(lambda t, p: bouche(t, p, cle, bouche_xy), PEAU_B)))
    L[-1:] = ["}", ""]
    # La main.
    L += ["extension LouHandModel {",
          f"    static let palmLength: CGFloat = {_n(PAUME)}",
          f"    static let samples = {animation.N_DOIGT}",
          "    static let base: [LouFinger: CGPoint] = ["]
    L += [f"        .{DOIGTS_SWIFT[d]}: {_point(BASE[d])}," for d in DOIGTS_SWIFT]
    L += ["    ]", "    static let length: [LouFinger: CGFloat] = ["]
    L += [f"        .{DOIGTS_SWIFT[d]}: {_n(LONG[d])}," for d in DOIGTS_SWIFT]
    L += ["    ]", "    static let width: [LouFinger: CGFloat] = ["]
    L += [f"        .{DOIGTS_SWIFT[d]}: {_n(LARGE[d])}," for d in DOIGTS_SWIFT]
    L += ["    ]",
          f"    static let phalanges: [CGFloat] = [{', '.join(_n(p) for p in PHALANGES)}]",
          f"    static let palm: [CGPoint] = [{', '.join(_point(p) for p in PAUME_PTS)}]",
          f"    static let foldedThumb: [CGPoint] = [{', '.join(_point(p) for p in animation.POUCE_REPLIE)}]",
          "    static let forms: [String: LouHandForm] = ["]
    noms = {forme: f"form{i:02d}" for i, forme in enumerate(FORMES)}
    L += [f'        "{forme}": {noms[forme]}(),' for forme in FORMES]
    L += ["    ]", ""]
    for forme, spec in FORMES.items():
        devant = ", ".join(f".{DOIGTS_SWIFT[d]}" for d in spec.get("ordre", ()))
        L += [f"    private static func {noms[forme]}() -> LouHandForm {{   // {forme}",
              f"        LouHandForm(index: {_spec(spec['index'])},",
              f"                    middle: {_spec(spec['majeur'])},",
              f"                    ring: {_spec(spec['annulaire'])},",
              f"                    little: {_spec(spec['auriculaire'])},",
              f"                    thumb: {_spec(spec['pouce'])},",
              f"                    front: [{devant}])",
              "    }", ""]
    L[-1:] = ["}", "#endif", ""]
    return "\n".join(L)


# ---------------------------------------------------------------------------
# Les chronologies
# ---------------------------------------------------------------------------

def _swift_chrono(nom: str, ch) -> list[str]:
    L = [f"    private static func {nom}() -> LouChronology {{   // {ch.son}",
         f'        var c = LouChronology(key: "{ch.son}", duration: {_n(ch.duree)}, posed: {_n(ch.t_pose)}, '
         f'gesture: {"true" if ch.geste else "false"})']
    for f in ch.bras:
        cote = ".right" if f.cote == "d" else ".left"
        L.append(f"        c.arm({cote}, thumb: {f.pouce}, size: {_n(f.taille)}, behind: {'true' if f.derriere else 'false'})")
    for k in ch.cles:
        joints = "".join(f", J({_n(a.coude[0])}, {_n(a.coude[1])}, {_n(a.poignet[0])}, {_n(a.poignet[1])}, "
                         f"{_n(a.direction)}, \"{a.forme}\", {_n(a.presence)})" for a in k.poses)
        L.append(f'        c.key({_n(k.t)}, "{k.bouche}", {"true" if k.vibre else "false"}, {_n(k.leve)}, '
                 f'{_n(k.table)}, {"true" if k.douce else "false"}{joints})')
    L += ["        return c", "    }", ""]
    return L


def source_data() -> str:
    gestes = animation.toutes()
    seules = animation.sans_geste()
    L = [ENTETE.format(nom="LouGestureData.swift"), "//",
         "// Les chronologies des gestes animés de Lou (`eveil/outils/gestes/animation.py`) : une par son,",
         "// du repos au repos. Clé : instant (s), bouche, gorge qui vibre, tête levée, table, segment adouci,",
         "// puis un bras par `J(coude x, y, poignet x, y, direction de la main, forme, présence)` (direction en",
         "// degrés, déroulée d'une clé à l'autre).",
         "", "#if canImport(SwiftUI)", "import SwiftUI", "", "extension LouChronology {",
         "    /// Les sons qui ont un geste, dans l'ordre de la planche.",
         f"    static let gestureKeys: [String] = [{', '.join(chr(34) + s + chr(34) for s in gestes)}]",
         "    static let gestures: [String: LouChronology] = ["]
    noms = {son: f"gesture{i:02d}" for i, son in enumerate(gestes)}
    L += [f'        "{son}": {noms[son]}(),' for son in gestes]
    L += ["    ]", "    /// Les sons relevés sans geste : la bouche seule.", "    static let mouthOnly: [String: LouChronology] = ["]
    noms_b = {son: f"mouthOnly{i:02d}" for i, son in enumerate(seules)}
    L += [f'        "{son}": {noms_b[son]}(),' for son in seules]
    L += ["    ]", ""]
    for son, ch in gestes.items():
        L += _swift_chrono(noms[son], ch)
    for son, ch in seules.items():
        L += _swift_chrono(noms_b[son], ch)
    L[-1:] = ["}", "#endif", ""]
    return "\n".join(L)


# ---------------------------------------------------------------------------
# Vecteurs de parité
# ---------------------------------------------------------------------------

SONS_PARITE = ("a", "ou", "é", "s", "z", "oi", "oin", "f", "v", "p", "b", "d", "m", "gn", "ill", "ui")


def instants(ch) -> list[float]:
    ts = [ARRIVEE * 0.5, ARRIVEE, ch.t_pose, (ch.t_pose + ch.duree) / 2, ch.duree - 0.1]
    ts += [ch.cles[len(ch.cles) // 2].t + 0.013]
    return sorted({round(t, 4) for t in ts if 0 <= t <= ch.duree})


def source_vecteurs() -> str:
    L = [ENTETE.format(nom="LouGestureVectors.swift"), "//",
         "// Vecteurs de parité Python → Swift des gestes animés de Lou (`animation.etat`) : à quelques",
         "// instants, pour chaque bras, poignet, coude, direction de la main, bout de l'index, présence ;",
         "// et la bouche, la gorge qui vibre, la tête levée, la table.", "",
         "import CoreGraphics", "", "struct LouVectorArm {", "    let wrist: CGPoint", "    let elbow: CGPoint",
         "    let direction: Double", "    let indexTip: CGPoint", "    let presence: Double", "}", "",
         "struct LouVector {", "    let key: String", "    let t: Double", "    let mouth: String",
         "    let vibrate: Bool", "    let lift: Double", "    let table: Double", "    let arms: [LouVectorArm]", "}",
         "", "enum LouGestureVectors {",
         "    static var all: [LouVector] { " + " + ".join(f"v{i:02d}()" for i in range(len(SONS_PARITE))) + " }",
         "    static let durations: [String: Double] = ["]
    for son, ch in {**animation.toutes(), **animation.sans_geste()}.items():
        L.append(f'        "{son}": {_n(ch.duree)},')
    L += ["    ]", ""]
    for i, son in enumerate(SONS_PARITE):
        ch = chronologie(son)
        L += [f"    private static func v{i:02d}() -> [LouVector] {{   // {son}", "        ["]
        for t in instants(ch):
            e = etat(ch, t)
            bras = ", ".join(
                f"LouVectorArm(wrist: {_point(b.poignet)}, elbow: {_point(b.coude)}, direction: {_n(b.direction)}, "
                f"indexTip: {_point(b.bout('index'))}, presence: {_n(b.presence)})" for b in e.bras)
            L.append(f'            LouVector(key: "{son}", t: {_n(t)}, mouth: "{e.bouche}", vibrate: '
                     f'{"true" if e.vibre else "false"}, lift: {_n(e.leve)}, table: {_n(e.table)}, arms: [{bras}]),')
        L += ["        ]", "    }", ""]
    L[-1:] = ["}", ""]
    return "\n".join(L)


def sorties() -> dict[Path, str]:
    return {ART: source_art(), DATA: source_data(), VECTEURS: source_vecteurs()}


def main(argv: list[str]) -> int:
    fichiers = sorties()
    if "--check" in argv:
        faux = [p.name for p, s in fichiers.items() if not p.exists() or p.read_text(encoding="utf-8") != s]
        if faux:
            print(f"✗ pas à jour : {', '.join(faux)} → python3 -m gestes.generer")
            return 1
        print(f"✓ {len(fichiers)} fichiers à jour ({len(SCENES)} gestes).")
        return 0
    for p, s in fichiers.items():
        p.write_text(s, encoding="utf-8")
        print(f"✓ {p.relative_to(RACINE.parent)} ({len(s) // 1024} Ko)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
