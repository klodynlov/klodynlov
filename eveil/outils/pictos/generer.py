"""Génère `eveil/ios/Sources/EveilDesign/PictoDessins.swift` : les pictos dessinés en Python.

    python3 -m pictos.generer            # écrit le fichier Swift (refuse s'il y a un problème)
    python3 -m pictos.generer --check    # échoue si le fichier Swift n'est pas à jour
    python3 -m pictos.generer --apercu DOSSIER   # + planche PNG (Chromium sans écran)
"""
from __future__ import annotations

import sys
from pathlib import Path

from . import lieux, mots_a, mots_b, verbes
from .peinture import Picto, problemes

RACINE = Path(__file__).resolve().parents[2]
SORTIE = RACINE / "ios" / "Sources" / "EveilDesign" / "PictoDessins.swift"
ORDRES_SWIFT = {"devant": "front", "dedans": "inside", "derriere": "behind"}
PREPOSITIONS_SWIFT = {"dans": "dans", "sur": "sur", "sous": "sous", "devant": "devant", "derriere": "derriere"}


def tous() -> list[Picto]:
    return list(verbes.PICTOS) + list(lieux.PICTOS) + list(mots_a.PICTOS) + list(mots_b.PICTOS)


def verifier(pictos: list[Picto]) -> list[str]:
    out = [pb for p in pictos for pb in problemes(p)]
    ids = [p.id for p in pictos]
    out += [f"{i}: identifiant en double" for i in sorted({i for i in ids if ids.count(i) > 1})]
    for p in pictos:
        if p.id.startswith("lieu.") and not p.ancres:
            out.append(f"{p.id}: un lieu sans ancre")
        if p.id.startswith(("verbe.", "mot.")) and p.ancres:
            out.append(f"{p.id}: seul un lieu a des ancres")
    return out


def _rgba(couleur: str) -> str:
    c = couleur.lstrip("#").upper()
    return "0x" + (c if len(c) == 8 else c + "FF")


def _nom(id_: str) -> str:
    genre, nom = id_.split(".", 1)
    parts = nom.split("_")
    return genre + "".join(w.capitalize() for w in parts)


def _n(v: float) -> str:
    r = round(v, 2)
    return str(int(r)) if r == int(r) else f"{r:g}"


def swift_source(pictos: list[Picto]) -> str:
    lignes = [
        "// PictoDessins.swift — FICHIER GÉNÉRÉ par eveil/outils/pictos/generer.py : ne pas modifier à la main.",
        "//",
        "// Les pictos du train des phrases dessinés en Python (verbes : Lou fait l'action ; lieux :",
        "// avec leurs ancres « dans / sur / sous / devant / derrière »), relus sur planche PNG.",
        "// Format : commandes absolues M, L, C, Z dans le carré 200 × 200 (celui de `WordArt`) ;",
        "// couleurs 0xRRGGBBAA ; `front: true` = calque qui passe DEVANT le personnage.",
        "",
        "#if canImport(SwiftUI)",
        "import SwiftUI",
        "",
        "extension PictoLibrary {",
        "    /// Les pictos dessinés en Python, par identifiant.",
        "    static let drawn: [String: PictoDrawing] = [",
    ]
    for p in pictos:
        lignes.append(f'        "{p.id}": {_nom(p.id)}(),')
    lignes += ["    ]", ""]
    for p in pictos:
        lignes.append(f"    private static func {_nom(p.id)}() -> PictoDrawing {{")
        lignes.append("        var p = PictoDrawing()")
        for op in p.ops:
            front = ", front: true" if op.calque == "devant" else ""
            if op.genre == "plein":
                lignes.append(f'        p.fill({_rgba(op.couleur)}, "{op.d}"{front})')
            else:
                lignes.append(f'        p.stroke({_rgba(op.couleur)}, {_n(op.largeur)}, "{op.d}"{front})')
        for prep, a in p.ancres.items():
            lignes.append(f"        p.anchor(.{PREPOSITIONS_SWIFT[prep]}, x: {_n(a.x)}, y: {_n(a.y)}, "
                          f"size: {_n(a.taille)}, order: .{ORDRES_SWIFT[a.ordre]})")
        lignes += ["        return p", "    }", ""]
    lignes[-1:] = ["}", "#endif", ""]
    return "\n".join(lignes)


def main(argv: list[str]) -> int:
    pictos = tous()
    pbs = verifier(pictos)
    if pbs:
        print("\n".join(pbs))
        print(f"✗ {len(pbs)} problème(s) : rien n'est écrit.")
        return 1
    source = swift_source(pictos)
    if "--check" in argv:
        actuel = SORTIE.read_text(encoding="utf-8") if SORTIE.exists() else ""
        if actuel != source:
            print(f"✗ {SORTIE.name} n'est pas à jour : python3 -m pictos.generer")
            return 1
        print(f"✓ {SORTIE.name} à jour ({len(pictos)} pictos).")
        return 0
    SORTIE.write_text(source, encoding="utf-8")
    print(f"✓ {SORTIE.relative_to(RACINE.parent)} : {len(pictos)} pictos.")
    if "--apercu" in argv:
        from .apercu import planche
        dossier = Path(argv[argv.index("--apercu") + 1])
        dossier.mkdir(parents=True, exist_ok=True)
        print(planche(pictos, dossier / "planche.png"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
