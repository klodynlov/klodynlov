"""Génère les pages dessinées de l'Atelier de coloriage (PagesDessins.swift) et leurs aperçus.

    cd eveil/outils
    python3 -m coloriages.generer                   # analyse, vérifie, réécrit PagesDessins.swift
    python3 -m coloriages.generer --check           # échoue si PagesDessins.swift est périmé
    python3 -m coloriages.generer --apercu DOSSIER  # planche.html (+ une image traits/zones par page)

Chaque page est analysée (analyse.py) : traits visibles, carte des zones 1024², témoins et
détails, contrôles de propreté et de robustesse. Une seule erreur, et rien n'est écrit.
Les dessins vivent dans pages_*.py ; PagesDessins.swift ne se modifie jamais à la main.
Stdlib uniquement.
"""
from __future__ import annotations

import argparse
import html
import sys
from pathlib import Path

from . import analyse, apercu, catalogue
from .dessin import ALBUMS, TRAIT

SWIFT = catalogue.COLORING / "PagesDessins.swift"


RESERVES = {"os": "osDuChien"}   # « os » est aussi le nom d'un module d'Apple


def nom_swift(pid: str) -> str:
    """« brosse-a-dents » → « brosseADents »."""
    if pid in RESERVES:
        return RESERVES[pid]
    parts = pid.replace(".", "-").split("-")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def _q(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _points(pts) -> str:
    return " ".join(f"{x:.4f} {y:.4f}" for x, y in pts)


def swift_source(analyses: list[analyse.Analyse]) -> str:
    out = [
        "// PagesDessins.swift — GÉNÉRÉ par eveil/outils/coloriages",
        "// (cd eveil/outils && python3 -m coloriages.generer).",
        "// NE PAS MODIFIER À LA MAIN : les dessins vivent dans eveil/outils/coloriages/pages_*.py.",
        "//",
        f"// {len(analyses)} pages, dessinées comme les autres : des formes pleines empilées du fond vers l'avant.",
        "// L'outil en a déjà tiré les traits VISIBLES (même algorithme que `LineClipper`), les aplats",
        "// d'encre, et un point au cœur de chaque zone d'après la carte des zones simulée comme `ZoneMap`",
        "// (mêmes règles de rastérisation et d'étiquetage, et robuste à ± 1 px de trait). Chaque page",
        "// n'est donc ici qu'un trait, ses encres et ses témoins (cf. SketchPathData.swift).",
        "",
        "#if canImport(CoreGraphics)",
        "import CoreGraphics",
        "",
        "/// Les pages dessinées avec eveil/outils/coloriages, rangées par album (cf. ColoringAlbums.swift).",
        "enum DrawnPages {",
        "    static let byAlbum: [String: [ColoringPage]] = [",
    ]
    for album in ALBUMS:
        noms = [nom_swift(a.page.id) for a in analyses if a.page.album == album]
        if noms:
            out.append(f'        "{album}": [{", ".join(noms)}],')
    out.append("    ]")
    for a in analyses:
        p = a.page
        largeur = "" if abs(p.trait - TRAIT) < 1e-9 else f", lineWidth: {p.trait:g}"
        out.append("")
        out.append(f'    static let {nom_swift(p.id)} = ColoringPage("{_q(p.id)}", fr: "{_q(p.fr)}", '
                   f'en: "{_q(p.en)}"{largeur}) {{ s in')
        if a.traits.encres:
            out.append(f'        s.ink(G.data("{a.encres}"))')
        out.append(f'        s.line(G.data("{a.lignes}"))')
        out.append(f'        s.expectAll("{_points(a.temoins.temoins)}")')
        if a.temoins.details:
            out.append(f'        s.expectDetails("{_points(a.temoins.details)}")')
        out.append("    }")
    out += ["}", "#endif", ""]
    return "\n".join(out)


def planche(analyses: list[analyse.Analyse], px: int = 230) -> str:
    """Planche contact HTML : toutes les pages générées, par album, telles que l'enfant les voit."""
    parts = ["<!doctype html><meta charset='utf-8'><title>Atelier de coloriage — planche</title>",
             "<style>body{font-family:system-ui,sans-serif;margin:24px;background:#faf6ee;color:#2E334A}"
             "h2{margin:22px 0 10px;font-size:22px}.g{display:flex;flex-wrap:wrap;gap:14px}"
             "figure{margin:0;background:#fff;border-radius:14px;padding:6px;box-shadow:0 2px 6px #0002}"
             "figcaption{text-align:center;font-size:14px;margin-top:2px}</style>"]
    for album in ALBUMS:
        groupe = [a for a in analyses if a.page.album == album]
        if not groupe:
            continue
        titre = catalogue.TITRES_ALBUMS[album][0]
        parts.append(f"<h2>{html.escape(titre)} — {len(groupe)} nouvelles pages</h2><div class='g'>")
        for a in groupe:
            parts.append(f"<figure>{apercu.svg(a.traits, px)}"
                         f"<figcaption>{html.escape(a.page.fr)}</figcaption></figure>")
        parts.append("</div>")
    return "\n".join(parts)


def tout_analyser() -> tuple[list[analyse.Analyse], list[str]]:
    analyses = analyse.analyser_tout(catalogue.PAGES)
    erreurs = [f"{a.page.id} : {e}" for a in analyses for e in a.erreurs] + catalogue.verifier_catalogue()
    return analyses, erreurs


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="échouer si PagesDessins.swift est périmé")
    ap.add_argument("--apercu", type=Path, help="écrire planche.html et une image par page dans ce dossier")
    args = ap.parse_args(argv)
    analyses, erreurs = tout_analyser()
    if erreurs:
        print("\n".join(erreurs), file=sys.stderr)
        print(f"{len(erreurs)} erreur(s) : rien n'est écrit.", file=sys.stderr)
        return 1
    src = swift_source(analyses)
    if args.check:
        if not SWIFT.exists() or SWIFT.read_text(encoding="utf-8") != src:
            print("PagesDessins.swift est périmé : cd eveil/outils && python3 -m coloriages.generer", file=sys.stderr)
            return 1
        print(f"à jour ({len(analyses)} pages)")
        return 0
    if args.apercu:
        args.apercu.mkdir(parents=True, exist_ok=True)
        for a in analyses:
            apercu.png_revue(a, args.apercu / f"{a.page.id}.png")
        (args.apercu / "planche.html").write_text(planche(analyses), encoding="utf-8")
        print(f"{len(analyses)} aperçus dans {args.apercu}")
        return 0
    SWIFT.write_text(src, encoding="utf-8")
    zones_total = sum(a.carte.zones for a in analyses)
    print(f"{len(analyses)} pages ({zones_total} zones) → {SWIFT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
