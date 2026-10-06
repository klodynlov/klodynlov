"""La planche des gestes de Lou, à montrer à une orthophoniste (document de travail).

    cd eveil/outils && python3 -m gestes.planche            # PNG + PDF dans docs/ui/eveil-app/
    python3 -m gestes.planche --html DOSSIER                # seulement les pages HTML (sans navigateur)

Sorties : `docs/ui/eveil-app/11-gestes-lou.png` (toutes les cartes, voyelles puis consonnes) et
`11-gestes-lou.pdf` (A4 imprimable, 6 cartes par page). Chaque carte : Lou en buste qui fait le
geste avec la bouche du son, la main de près (ou ses « temps », numérotés), le son, un mot du jeu,
main / place / mouvement (repris de `gestes.py`), la bouche (citée, ou « proposition »), la source
et le statut. Une bande montre Lou dans chaque couleur de peau (au choix de l'adulte) et une
légende montre les 10 bouches. **Aucun de ces gestes n'est dans l'app** : ils attendent la
validation d'une orthophoniste.

Rendu : Google Chrome local sans écran (`rendu.py`) ; sans navigateur, les pages HTML autonomes
restent lisibles telles quelles. Stdlib uniquement, sortie déterministe.
"""
from __future__ import annotations

import html
import sys
from pathlib import Path

from coloriages.dessin import arc, rect

from . import rendu
from .dessins import SCENES, portrait, vibre, vignettes
from .gestes import A_TROUVER, A_TROUVER_SONS, BOUCHES, CONSONNES, LOE1, PROPOSITION, TLDM, VOYELLES, Geste
from .lou_portrait import C, FLECHE, PEAU, PEAUX, VIBRE, Main, Toile, main, tete

RACINE = Path(__file__).resolve().parents[3]
SORTIE = RACINE / "docs" / "ui" / "eveil-app"
NOM = "11-gestes-lou"
DATE = "06/10/2026"
TITRE = "Les gestes de Lou — méthode phonétique et gestuelle de Borel-Maisonny"
MENTION = "Document de travail — gestes à valider par une orthophoniste ; aucun n'est dans l'app."

PNG_COLONNES = 5
PNG_LARGEUR = 1780
CARTE_PNG = (340, 730)        # largeur, hauteur d'une carte (PNG)


def court(source: str) -> str:
    return source.replace(LOE1, "Borel-Maisonny, LOE I").replace(TLDM, "Borel-Maisonny, TLDM")


def ligne_bouche(g: Geste) -> str:
    desc = BOUCHES[g.bouche]
    if g.bouche_source == PROPOSITION:
        return f"{desc} <span class='prop'>proposition, à valider</span>"
    return f"{html.escape(desc)} <span class='cite'>({html.escape(court(g.bouche_source))})</span>"


# ---------------------------------------------------------------------------
# Les morceaux de la planche
# ---------------------------------------------------------------------------

def _gros_plan(g: Geste, peau: str) -> Toile | None:
    """La main de près (geste d'un seul temps)."""
    sc = SCENES.get(g.son)
    if sc is None:
        return None
    t = Toile()
    mains = [b.main for b in sc.bras]
    if len(mains) == 2:     # le V des deux mains
        main(t, Main((48, 92), -122, mains[0].forme, 1, 26), peau)
        main(t, Main((54, 92), -58, mains[1].forme, -1, 26), peau)
        return t
    m = mains[0]
    horiz = abs(abs(m.direction) - 180) < 40
    vers_bas = 45 < m.direction < 135
    poignet = (88, 52) if horiz else ((50, 8) if vers_bas else (50, 94))
    direction = 180.0 if horiz else (90.0 if vers_bas else -90.0)
    pouce = m.pouce if not horiz else (1 if m.direction > 0 or m.direction < -170 else m.pouce)
    main(t, Main(poignet, direction, m.forme, pouce, 30), peau)
    return t


def carte(g: Geste, peau: str = PEAU, largeur: int = 300, vign: int = 104) -> str:
    """Une carte : le portrait, la main de près ou ses temps, puis le texte."""
    a_trouver = g.statut == A_TROUVER or g.son not in SCENES
    svg = portrait(g, peau, avec_geste=not a_trouver).svg(largeur=largeur)
    bas = ""
    if a_trouver:
        bas = "<div class='trouver'>geste à trouver</div>"
    else:
        temps = vignettes(g, peau)
        if temps:
            fl = "<span class='fl'>→</span>"
            bas = ("<div class='vign'><span class='lab'>en " + {2: "deux", 3: "trois"}.get(len(temps), str(len(temps)))
                   + " temps</span>" + fl.join(v.svg((0, 0, 100, 100), vign) for v in temps) + "</div>")
        else:
            gp = _gros_plan(g, peau)
            bas = ("<div class='vign'><span class='lab'>la main de près</span>"
                   + gp.svg((0, 0, 100, 100), vign) + "</div>") if gp else ""
    signes = []
    if vibre(g):
        signes.append("<span class='vibre'>))) la gorge vibre</span>")
    exemple = html.escape(g.exemple) if g.exemple else "<i>aucun mot du jeu</i>"
    if a_trouver:
        corps = (f"<p><b>Main, place, mouvement :</b> à trouver (rien dans les livres relevés).</p>"
                 f"<p><b>Bouche :</b> {ligne_bouche(g)}</p>")
    else:
        corps = (f"<p><b>Main :</b> {html.escape(g.main)}.</p>"
                 f"<p><b>Place :</b> {html.escape(g.place)}.</p>"
                 f"<p><b>Mouvement :</b> {html.escape(g.mouvement)}.</p>"
                 f"<p><b>Évoque :</b> {html.escape(g.evoque)}.</p>"
                 f"<p><b>Bouche :</b> {ligne_bouche(g)}</p>")
    source = f"<p class='src'>{html.escape(court(g.source))}</p>" if g.source else ""
    remarque = f"<p class='rem'>{html.escape(g.remarque)}</p>" if g.remarque else ""
    return (f"<section class='carte{' atrouver' if a_trouver else ''}'>"
            f"<div class='img'>{svg}</div>{bas}"
            f"<h3><span class='son'>{html.escape(g.son)}</span> <span class='api'>/{html.escape(g.api)}/</span>"
            f" <span class='ex'>{exemple}</span>{''.join(signes)}</h3>"
            f"{corps}{source}<p class='statut'>Statut : {html.escape(g.statut)}</p>{remarque}</section>")


def bande_peaux(largeur: int = 150) -> str:
    cases = []
    for nom, couleur in PEAUX:
        t = portrait(Geste("·", "", ""), couleur, bouche="neutre", avec_geste=False)
        cases.append(f"<figure>{t.svg(largeur=largeur)}<figcaption>{html.escape(nom)}</figcaption></figure>")
    return ("<div class='bloc'><h2>Couleur de peau : au choix de l'adulte</h2>"
            "<p class='aide'>On ne l'impose jamais : l'adulte choisit la peau de Lou (les quatre peaux de la palette "
            "du coloriage, et la peau actuelle de Lou).</p><div class='peaux'>" + "".join(cases) + "</div></div>")


def legende_bouches(largeur: int = 140) -> str:
    cases = []
    vue = (C[0] - 40, 138, 80, 50)
    for cle, desc in BOUCHES.items():
        t = Toile()
        tete(t, PEAU, cle)
        cases.append(f"<figure>{t.svg(vue, largeur)}<figcaption><b>{html.escape(cle)}</b><br>"
                     f"{html.escape(desc)}</figcaption></figure>")
    return ("<div class='bloc'><h2>Les 10 bouches de Lou (vues de face)</h2>"
            "<p class='aide'>Quand le livre décrit la bouche, la carte cite la page ; sinon la bouche est une "
            "<span class='prop'>proposition, à valider</span> tirée de la phonétique courante du français.</p>"
            "<div class='bouches'>" + "".join(cases) + "</div></div>")


def legende_signes() -> str:
    fl = Toile()
    from .lou_portrait import fleche, numero
    fleche(fl, ((6, 20), (54, 20)))
    num = Toile()
    numero(num, 14, 20, 1)
    numero(num, 44, 20, 2)
    vib = Toile()
    vib.plein(PEAU, rect(23, 2, 14, 40, r=5))
    for i, r in enumerate((11, 16, 21)):
        for a0 in (-35, 145):
            vib.trait(VIBRE, 2.4 - i * 0.3, arc(30, 22, r, a0, a0 + 70))
    return ("<div class='signes'>"
            f"<span>{fl.svg((0, 0, 60, 40), 48, None)} le mouvement</span>"
            f"<span>{num.svg((0, 0, 60, 40), 48, None)} les temps du geste, dans l'ordre</span>"
            f"<span>{vib.svg((0, 0, 60, 40), 48, None)} la gorge vibre</span>"
            "<span><span class='prop'>proposition</span> bouche non décrite par le livre</span>"
            "<span><b>LOE I</b> : <i>Langage oral et écrit I</i> (1985), page imprimée</span></div>")


CSS = f"""
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: #FFFFFF; color: #292B3D;
  font-family: -apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif; }}
h1 {{ font-size: 26px; margin: 0 0 4px; }}
h2 {{ font-size: 19px; margin: 14px 0 4px; }}
.mention {{ display: inline-block; background: #FFF1D6; border: 2px solid #E8A91F; border-radius: 8px;
  padding: 4px 10px; font-weight: 700; font-size: 14px; }}
.date {{ color: #666; font-size: 13px; margin-left: 10px; }}
.aide {{ margin: 0 0 6px; font-size: 13px; color: #444; }}
.prop {{ background: #FFE3F1; color: #A0005A; border-radius: 5px; padding: 0 5px; font-size: .9em;
  font-weight: 600; white-space: nowrap; }}
.cite {{ color: #555; }}
.peaux, .bouches {{ display: flex; flex-wrap: wrap; gap: 8px; }}
figure {{ margin: 0; text-align: center; font-size: 12px; }}
.bouches figure {{ width: 162px; }}
.bouches svg {{ border-radius: 10px; border: 1px solid #ddd; }}
.signes {{ display: flex; flex-wrap: wrap; gap: 4px 18px; align-items: center; font-size: 13px; margin: 6px 0; }}
.signes span {{ display: inline-flex; align-items: center; gap: 4px; }}
.grille {{ display: grid; gap: 10px; }}
.carte {{ border: 1.5px solid #E2E2E8; border-radius: 12px; padding: 6px 8px; overflow: hidden; background: #fff; }}
.carte.atrouver {{ border: 2px dashed {FLECHE}; }}
.carte .img {{ text-align: center; line-height: 0; }}
.carte .img svg {{ border-radius: 8px; }}
.vign {{ display: flex; align-items: center; justify-content: center; gap: 2px; margin: 2px 0; }}
.vign svg {{ border: 1px solid #E2E2E8; border-radius: 8px; }}
.vign .lab {{ font-size: 11px; color: #666; writing-mode: vertical-rl; transform: rotate(180deg); margin-right: 2px; }}
.vign .fl {{ color: {FLECHE}; font-weight: 800; }}
.trouver {{ text-align: center; color: {FLECHE}; font-weight: 800; font-size: 18px; margin: 6px 0; }}
.carte h3 {{ margin: 4px 0 3px; font-size: 15px; font-weight: 600; }}
.carte .son {{ font-size: 30px; font-weight: 800; }}
.carte .api {{ color: #666; }}
.carte .ex {{ font-style: italic; }}
.vibre {{ color: {VIBRE}; font-weight: 700; font-size: 12px; margin-left: 6px; white-space: nowrap; }}
.carte p {{ margin: 1px 0; font-size: 12.5px; line-height: 1.3; }}
.carte .src {{ color: #555; margin-top: 3px; }}
.carte .statut {{ font-weight: 700; color: #1C763A; }}
.carte.atrouver .statut {{ color: {FLECHE}; }}
.carte .rem {{ font-style: italic; color: #555; font-size: 11.5px; }}
"""

CSS_PNG = f"""
body {{ padding: 18px 20px; width: {PNG_LARGEUR}px; }}
.grille {{ grid-template-columns: repeat({PNG_COLONNES}, {CARTE_PNG[0]}px); }}
.carte {{ height: {CARTE_PNG[1]}px; }}
"""

CSS_PDF = """
@page { size: A4; margin: 9mm 9mm 10mm; }
body { font-size: 11px; }
.page { page-break-after: always; break-after: page; }
.page:last-child { page-break-after: auto; break-after: auto; }
.tete { display: flex; flex-wrap: wrap; gap: 0 14px; justify-content: space-between; align-items: baseline;
  border-bottom: 1.5px solid #E8A91F; padding-bottom: 3px; margin-bottom: 5px; font-size: 9.5px; }
.tete b { font-size: 11px; }
.tete .m { color: #A0005A; font-weight: 700; }
h1 { font-size: 21px; }
h2 { font-size: 15px; margin-top: 8px; }
.mention { font-size: 12.5px; }
.aide { font-size: 11px; }
.signes { font-size: 11px; }
.bouches figure { width: 128px; font-size: 10.5px; }
.grille { grid-template-columns: repeat(3, 1fr); gap: 7px; }
.carte { height: 500px; padding: 4px 6px; }
.carte .son { font-size: 22px; }
.carte h3 { font-size: 12px; }
.carte p { font-size: 9.3px; line-height: 1.22; }
.carte .rem { font-size: 8.6px; }
.vibre { font-size: 9.5px; }
.vign .lab { font-size: 9px; }
.trouver { font-size: 14px; }
.pied { text-align: right; font-size: 9.5px; color: #777; margin-top: 4px; }
"""


def _doc(css: str, corps: str) -> str:
    return ("<!doctype html><html lang='fr'><head><meta charset='utf-8'>"
            f"<title>{html.escape(TITRE)}</title><style>{CSS}{css}</style></head><body>{corps}</body></html>")


def _entete() -> str:
    return (f"<h1>{html.escape(TITRE)}</h1><div><span class='mention'>{html.escape(MENTION)}</span>"
            f"<span class='date'>Suite Éveil · {DATE}</span></div>"
            "<p class='aide' style='margin-top:6px'>Lou, l'enfant du train des phrases, montre chaque son : <b>sa bouche</b> "
            "montre comment le dire, <b>sa main</b> fait le geste. Les gestes sont REFORMULÉS d'après les livres de "
            "S. Borel-Maisonny (page imprimée citée) et dessinés ici, sans reprendre leurs figures ; ce que le texte ne "
            "dit pas (quelle main, l'angle exact) est un choix de dessin, à corriger. La main ne cache jamais la bouche : "
            "quand le livre la met « devant la bouche », elle est posée juste à côté.</p>")


def cartes() -> list[Geste]:
    return list(VOYELLES) + list(CONSONNES) + list(A_TROUVER_SONS)


def html_png() -> str:
    """La planche entière, pour l'image PNG."""
    v = "".join(carte(g) for g in VOYELLES)
    c = "".join(carte(g) for g in CONSONNES)
    t = "".join(carte(g) for g in A_TROUVER_SONS)
    corps = (_entete() + legende_signes() + bande_peaux() + legende_bouches()
             + f"<h2>Les voyelles ({len(VOYELLES)})</h2><div class='grille'>{v}</div>"
             + f"<h2>Les consonnes ({len(CONSONNES)})</h2><div class='grille'>{c}</div>"
             + f"<h2>Geste à trouver ({len(A_TROUVER_SONS)})</h2><div class='grille'>{t}</div>")
    return _doc(CSS_PNG, corps)


def hauteur_png() -> int:
    """Hauteur de la page PNG (les cartes ont une hauteur fixe)."""
    lignes = sum(-(-len(x) // PNG_COLONNES) for x in (VOYELLES, CONSONNES, A_TROUVER_SONS))
    entete = 640       # titre, signes, peaux, bouches
    return entete + lignes * (CARTE_PNG[1] + 10) + 3 * 48 + 30


def html_pdf(par_page: int = 6) -> str:
    """Le document A4 : une page d'accueil (titre, signes, peaux, bouches), puis 6 cartes par page."""
    liste = cartes()
    n_pages = 1 + -(-len(liste) // par_page)

    def tete_page(k: int) -> str:
        return (f"<div class='tete'><span><b>Les gestes de Lou</b> · Borel-Maisonny</span>"
                f"<span class='m'>{html.escape(MENTION)}</span><span>{DATE} · page {k}/{n_pages}</span></div>")

    pages = [f"<div class='page'>{_entete()}{legende_signes()}{bande_peaux(122)}{legende_bouches(118)}"
             f"<div class='pied'>page 1/{n_pages}</div></div>"]
    for k in range(0, len(liste), par_page):
        lot = "".join(carte(g, largeur=200, vign=58) for g in liste[k:k + par_page])
        pages.append(f"<div class='page'>{tete_page(len(pages) + 1)}<div class='grille'>{lot}</div></div>")
    return _doc(CSS_PDF, "".join(pages))


def ecrire(dossier: Path = SORTIE, avec_rendu: bool = True) -> list[Path]:
    dossier.mkdir(parents=True, exist_ok=True)
    out = []
    import tempfile
    with tempfile.TemporaryDirectory(prefix="gestes-lou-") as tmp:
        tmp = Path(tmp)
        page_png, page_pdf = tmp / f"{NOM}.html", tmp / f"{NOM}-a4.html"
        page_png.write_text(html_png(), encoding="utf-8")
        page_pdf.write_text(html_pdf(), encoding="utf-8")
        if not avec_rendu or rendu.navigateur() is None:
            for p in (page_png, page_pdf):
                cible = dossier / p.name
                cible.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
                out.append(cible)
            return out
        out.append(rendu.png(page_png, dossier / f"{NOM}.png", PNG_LARGEUR + 40, hauteur_png()))
        out.append(rendu.pdf(page_pdf, dossier / f"{NOM}.pdf"))
    return out


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--html":
        for p in ecrire(Path(sys.argv[2]), avec_rendu=False):
            print(p)
    else:
        for p in ecrire():
            print(p)
