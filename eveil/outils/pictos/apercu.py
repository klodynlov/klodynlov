"""Planches des pictos, rendues par le Chromium sans écran de la machine (PNG à relire).

    python3 -m pictos.apercu DOSSIER      # planche.png : tous les pictos, et chaque lieu avec ses ancres
"""
from __future__ import annotations

import html
import subprocess
import sys
from pathlib import Path

from .peinture import Picto, svg, svg_scene

CHROMIUM = Path("/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell")


def page_html(pictos: list[Picto], colonnes: int = 6, taille: int = 200) -> str:
    cases = []
    for p in pictos:
        cases.append(f'<figure>{svg(p, taille)}<figcaption>{html.escape(p.id)}</figcaption></figure>')
        for prep in p.ancres:
            cases.append(f'<figure>{svg_scene(p, prep, taille)}<figcaption>{html.escape(p.id)} · '
                         f'{prep} ({p.ancres[prep].ordre})</figcaption></figure>')
    return ("<!doctype html><meta charset='utf-8'><style>body{margin:12px;font:13px sans-serif;background:#eee}"
            f"main{{display:grid;grid-template-columns:repeat({colonnes},{taille}px);gap:10px}}"
            "figure{margin:0;background:#fff;padding:4px;border-radius:8px}"
            "figcaption{text-align:center;color:#333;padding-top:2px}</style><main>"
            + "".join(cases) + "</main>")


def rendre(html_text: str, png: Path, largeur: int, hauteur: int) -> None:
    source = png.with_suffix(".html")
    source.write_text(html_text, encoding="utf-8")
    subprocess.run([str(CHROMIUM), "--headless", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                    f"--window-size={largeur},{hauteur}", f"--screenshot={png}", source.as_uri()],
                   check=True, capture_output=True, timeout=120)


def planche(pictos: list[Picto], png: Path, colonnes: int = 6, taille: int = 200) -> Path:
    cases = sum(1 + len(p.ancres) for p in pictos)
    lignes = (cases + colonnes - 1) // colonnes
    rendre(page_html(pictos, colonnes, taille), png, colonnes * (taille + 18) + 30,
           lignes * (taille + 60) + 40)
    return png


if __name__ == "__main__":
    from .generer import tous
    dossier = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    dossier.mkdir(parents=True, exist_ok=True)
    print(planche(tous(), dossier / "planche.png"))
