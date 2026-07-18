#!/usr/bin/env python3
"""
objectifs.py — Suivi local de tes ambitions et de leur avancement.

Tu écris tes ambitions dans un simple fichier texte (voir objectifs.exemple.txt) :
chaque ambition a un titre, un horizon facultatif, une description et une liste
de jalons cochables. Le script calcule l'avancement, met en avant les prochaines
échéances et génère un rapport lisible (Markdown ou dashboard HTML autonome).

    python3 objectifs.py mes-objectifs.txt                 # rapport Markdown au terminal
    python3 objectifs.py mes-objectifs.txt --out road.md   # écrit le Markdown
    python3 objectifs.py mes-objectifs.txt --html road.html  # dashboard visuel (SVG)

Aucune dépendance externe : uniquement la bibliothèque standard Python 3.8+.
Le script ne modifie que les fichiers de sortie que TU demandes — il lit ton
fichier d'ambitions et n'écrit rien d'autre.

Format du fichier d'ambitions (tout est optionnel sauf le titre) :

    # Titre de l'ambition
    horizon: 2026-12-31            # échéance globale (AAAA-MM-JJ ou AAAA-MM)
    statut: en cours              # libre : en cours, en pause, bloqué…
    > Une ou plusieurs lignes de description, préfixées par « > ».
    - [x] Jalon déjà atteint
    - [ ] Jalon à faire @2026-08          # « @date » = échéance du jalon
    - [ ] Jalon prioritaire ! @2026-09    # « ! » = jalon prioritaire

Les lignes vides et celles commençant par « // » (commentaires) sont ignorées.
"""

from __future__ import annotations

import argparse
import re
import sys
from datetime import date, datetime
from pathlib import Path


# --------------------------------------------------------------------------- #
#  Lecture du fichier d'ambitions
# --------------------------------------------------------------------------- #
_RE_JALON = re.compile(r"^-\s*\[(?P<coche>[ xX])\]\s*(?P<texte>.*)$")
_RE_ECHEANCE = re.compile(r"@(\d{4}-\d{2}(?:-\d{2})?)")


def parse_date(val: str) -> date | None:
    """Accepte AAAA-MM-JJ ou AAAA-MM (ramené au 1er du mois)."""
    val = (val or "").strip()
    for fmt in ("%Y-%m-%d", "%Y-%m"):
        try:
            return datetime.strptime(val, fmt).date()
        except ValueError:
            continue
    return None


def lire_ambitions(chemin: Path) -> list[dict]:
    """Parse le fichier texte en une liste d'ambitions structurées."""
    ambitions: list[dict] = []
    courante: dict | None = None

    def cloturer():
        if courante is not None:
            courante["description"] = " ".join(courante["_desc"]).strip()
            del courante["_desc"]
            ambitions.append(courante)

    for brut in chemin.read_text(encoding="utf-8").splitlines():
        ligne = brut.strip()
        if not ligne or ligne.startswith("//"):
            continue

        # Nouveau titre d'ambition.
        if ligne.startswith("#"):
            cloturer()
            courante = {
                "titre": ligne.lstrip("#").strip(),
                "horizon": None,
                "statut": None,
                "_desc": [],
                "jalons": [],
            }
            continue

        if courante is None:
            # Contenu avant tout titre : on l'ignore proprement.
            continue

        # Métadonnées « clé: valeur ».
        bas = ligne.lower()
        if bas.startswith("horizon:"):
            courante["horizon"] = parse_date(ligne.split(":", 1)[1])
            continue
        if bas.startswith("statut:"):
            courante["statut"] = ligne.split(":", 1)[1].strip()
            continue

        # Ligne de description.
        if ligne.startswith(">"):
            courante["_desc"].append(ligne.lstrip(">").strip())
            continue

        # Jalon cochable.
        m = _RE_JALON.match(ligne)
        if m:
            texte = m.group("texte").strip()
            prioritaire = texte.endswith("!") or " !" in f" {texte}"
            echeance = None
            me = _RE_ECHEANCE.search(texte)
            if me:
                echeance = parse_date(me.group(1))
                texte = _RE_ECHEANCE.sub("", texte).strip()
            texte = texte.rstrip("!").strip()
            courante["jalons"].append({
                "fait": m.group("coche").lower() == "x",
                "texte": texte,
                "echeance": echeance,
                "prioritaire": prioritaire,
            })
            continue

    cloturer()
    return ambitions


# --------------------------------------------------------------------------- #
#  Calculs d'avancement
# --------------------------------------------------------------------------- #
def avancement(ambition: dict) -> tuple[int, int, float]:
    """(jalons faits, total, ratio 0..1). Ratio = 0 si aucun jalon."""
    jalons = ambition["jalons"]
    total = len(jalons)
    faits = sum(1 for j in jalons if j["fait"])
    return faits, total, (faits / total if total else 0.0)


def prochaines_echeances(ambitions: list[dict], aujourdhui: date) -> list[dict]:
    """Jalons non faits ayant une échéance, triés du plus urgent au plus lointain."""
    items = []
    for a in ambitions:
        for j in a["jalons"]:
            if not j["fait"] and j["echeance"]:
                items.append({
                    "ambition": a["titre"],
                    "texte": j["texte"],
                    "echeance": j["echeance"],
                    "prioritaire": j["prioritaire"],
                    "en_retard": j["echeance"] < aujourdhui,
                    "jours": (j["echeance"] - aujourdhui).days,
                })
    return sorted(items, key=lambda x: x["echeance"])


# --------------------------------------------------------------------------- #
#  Rapport Markdown
# --------------------------------------------------------------------------- #
def barre_texte(ratio: float, largeur: int = 20) -> str:
    plein = round(ratio * largeur)
    return "█" * plein + "░" * (largeur - plein)


def fmt_echeance(d: date | None, aujourdhui: date) -> str:
    if not d:
        return "—"
    jours = (d - aujourdhui).days
    if jours < 0:
        return f"{d:%Y-%m-%d} ⚠️ en retard ({-jours} j)"
    if jours == 0:
        return f"{d:%Y-%m-%d} · aujourd'hui"
    return f"{d:%Y-%m-%d} · dans {jours} j"


def rapport_markdown(ambitions: list[dict], aujourdhui: date) -> str:
    out: list[str] = []
    A = out.append

    total_jalons = sum(len(a["jalons"]) for a in ambitions)
    faits_jalons = sum(sum(1 for j in a["jalons"] if j["fait"]) for a in ambitions)
    ratio_global = faits_jalons / total_jalons if total_jalons else 0.0

    A("# 🎯 Mes ambitions — feuille de route\n")
    A(f"*{len(ambitions)} ambitions · {faits_jalons}/{total_jalons} jalons atteints "
      f"· {ratio_global*100:.0f} % · au {aujourdhui:%Y-%m-%d}*\n")
    A(f"`{barre_texte(ratio_global, 28)}` **{ratio_global*100:.0f} %**\n")

    # --- Détail par ambition ---
    for a in ambitions:
        faits, total, ratio = avancement(a)
        entete = f"## {a['titre']}"
        A(entete + "\n")
        meta = []
        if a["statut"]:
            meta.append(f"statut : **{a['statut']}**")
        if a["horizon"]:
            meta.append(f"horizon : {fmt_echeance(a['horizon'], aujourdhui)}")
        meta.append(f"{faits}/{total} jalons")
        A(" · ".join(meta) + "\n")
        A(f"`{barre_texte(ratio)}` {ratio*100:.0f} %\n")
        if a["description"]:
            A(f"> {a['description']}\n")
        if a["jalons"]:
            for j in a["jalons"]:
                case = "x" if j["fait"] else " "
                bout = []
                if j["prioritaire"] and not j["fait"]:
                    bout.append("⭐")
                if j["echeance"] and not j["fait"]:
                    bout.append(fmt_echeance(j["echeance"], aujourdhui))
                suffixe = ("  — " + " · ".join(bout)) if bout else ""
                A(f"- [{case}] {j['texte']}{suffixe}")
            A("")

    # --- Prochaines échéances ---
    ech = prochaines_echeances(ambitions, aujourdhui)
    A("## 📅 Prochaines échéances\n")
    if ech:
        A("| Échéance | Ambition | Jalon |")
        A("|---|---|---|")
        for e in ech[:15]:
            marque = "⭐ " if e["prioritaire"] else ""
            A(f"| {fmt_echeance(e['echeance'], aujourdhui)} | {e['ambition']} "
              f"| {marque}{e['texte']} |")
    else:
        A("*Aucun jalon daté à venir.*")
    A("")

    return "\n".join(out)


# --------------------------------------------------------------------------- #
#  Dashboard HTML autonome (SVG en ligne, thème clair/sombre, sans dépendance)
# --------------------------------------------------------------------------- #
#  Même langage visuel que classer_sessions.py (palette validée CVD-safe).
S_LIGHT = ["#2a78d6", "#1baf7a", "#eda100", "#4a3aa7", "#e34948"]
S_DARK = ["#3987e5", "#199e70", "#c98500", "#9085e9", "#e66767"]


def _esc(s) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def _barre_svg(ratio: float, teinte: str) -> str:
    """Barre de progression arrondie (rail + remplissage)."""
    pct = max(0.0, min(1.0, ratio)) * 100
    return (
        "<svg viewBox='0 0 100 8' class='pbar' preserveAspectRatio='none' "
        "role='img'>"
        "<rect x='0' y='0' width='100' height='8' rx='4' fill='var(--rail)'/>"
        f"<rect x='0' y='0' width='{pct:.2f}' height='8' rx='4' "
        f"fill='{teinte}'/></svg>")


def _tile(valeur, label: str) -> str:
    return (f"<div class='tile'><div class='tile-v'>{_esc(valeur)}</div>"
            f"<div class='tile-l'>{_esc(label)}</div></div>")


def generer_html(ambitions: list[dict], aujourdhui: date) -> str:
    total_jalons = sum(len(a["jalons"]) for a in ambitions)
    faits_jalons = sum(sum(1 for j in a["jalons"] if j["fait"]) for a in ambitions)
    ratio_global = faits_jalons / total_jalons if total_jalons else 0.0
    ech = prochaines_echeances(ambitions, aujourdhui)
    en_retard = sum(1 for e in ech if e["en_retard"])
    prochaine = ech[0]["echeance"] if ech else None

    # Cartes d'ambitions.
    cartes = []
    for i, a in enumerate(ambitions):
        faits, total, ratio = avancement(a)
        teinte = f"var(--s{i % len(S_LIGHT)})"
        meta = []
        if a["statut"]:
            meta.append(f"<span class='badge'>{_esc(a['statut'])}</span>")
        if a["horizon"]:
            meta.append(f"<span class='hz'>⌛ {a['horizon']:%Y-%m-%d}</span>")
        jalons_html = []
        for j in a["jalons"]:
            cls = "j done" if j["fait"] else "j"
            coche = "✓" if j["fait"] else "○"
            extra = []
            if not j["fait"] and j["prioritaire"]:
                extra.append("<span class='star'>⭐</span>")
            if not j["fait"] and j["echeance"]:
                rc = "due late" if j["echeance"] < aujourdhui else "due"
                extra.append(f"<span class='{rc}'>{j['echeance']:%d/%m/%y}</span>")
            jalons_html.append(
                f"<li class='{cls}'><span class='box'>{coche}</span>"
                f"<span class='jt'>{_esc(j['texte'])}</span>"
                f"{''.join(extra)}</li>")
        cartes.append(f"""
<article class="card">
  <div class="card-h">
    <h3>{_esc(a['titre'])}</h3>
    <span class="pct">{ratio*100:.0f}%</span>
  </div>
  <div class="meta">{' '.join(meta)}<span class="count">{faits}/{total} jalons</span></div>
  {_barre_svg(ratio, teinte)}
  {f'<p class="desc">{_esc(a["description"])}</p>' if a['description'] else ''}
  <ul class="jalons">{''.join(jalons_html)}</ul>
</article>""")

    # Tableau des échéances.
    lignes_ech = []
    for e in ech[:12]:
        cls = "late" if e["en_retard"] else ""
        quand = (f"en retard ({-e['jours']} j)" if e["en_retard"]
                 else ("aujourd'hui" if e["jours"] == 0 else f"dans {e['jours']} j"))
        star = "⭐ " if e["prioritaire"] else ""
        lignes_ech.append(
            f"<tr class='{cls}'><td class='d'>{e['echeance']:%d/%m/%Y}</td>"
            f"<td class='w'>{_esc(quand)}</td><td>{_esc(e['ambition'])}</td>"
            f"<td>{star}{_esc(e['texte'])}</td></tr>")
    tableau_ech = ("".join(lignes_ech) if lignes_ech
                   else "<tr><td colspan='4' class='vide'>Aucun jalon daté à venir.</td></tr>")

    palette = "".join(f"--s{i}:{c};" for i, c in enumerate(S_LIGHT))
    palette_d = "".join(f"--s{i}:{c};" for i, c in enumerate(S_DARK))

    return f"""<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mes ambitions — feuille de route</title>
<style>
:root {{
  --plane:#f9f9f7; --surface:#fcfcfb; --ink:#0b0b0b; --ink2:#52514e;
  --muted:#898781; --border:rgba(11,11,11,.10); --rail:#e6e5df;
  --late:#e34948; {palette}
}}
:root[data-theme="dark"], html[data-theme="dark"] {{
  --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
  --muted:#898781; --border:rgba(255,255,255,.10); --rail:#2c2c2a;
  --late:#e66767; {palette_d}
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
    --muted:#898781; --border:rgba(255,255,255,.10); --rail:#2c2c2a;
    --late:#e66767; {palette_d}
  }}
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--plane); color:var(--ink);
  font-family:system-ui,-apple-system,"Segoe UI",sans-serif; line-height:1.5; }}
.wrap {{ max-width:940px; margin:0 auto; padding:32px 20px 64px; }}
header {{ display:flex; align-items:baseline; justify-content:space-between;
  gap:16px; flex-wrap:wrap; }}
h1 {{ font-size:22px; margin:0; }}
.sub {{ color:var(--ink2); font-size:14px; }}
.toggle {{ border:1px solid var(--border); background:var(--surface);
  color:var(--ink2); border-radius:8px; padding:6px 12px; font:inherit;
  font-size:13px; cursor:pointer; }}
.tiles {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr));
  gap:12px; margin:20px 0 8px; }}
.tile {{ background:var(--surface); border:1px solid var(--border);
  border-radius:12px; padding:16px 18px; }}
.tile-v {{ font-size:28px; font-weight:600; font-variant-numeric:tabular-nums; }}
.tile-l {{ color:var(--ink2); font-size:13px; margin-top:2px; }}
.pbar {{ width:100%; height:8px; display:block; margin:6px 0 2px; }}
.hero {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:18px 22px; margin-top:14px; }}
.hero .pct-big {{ font-size:15px; font-weight:600; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr));
  gap:16px; margin-top:18px; }}
.card {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:18px 20px; }}
.card-h {{ display:flex; justify-content:space-between; align-items:baseline;
  gap:10px; }}
.card-h h3 {{ font-size:15.5px; margin:0; }}
.pct {{ font-size:15px; font-weight:600; font-variant-numeric:tabular-nums; }}
.meta {{ display:flex; gap:8px; align-items:center; flex-wrap:wrap;
  margin:6px 0 2px; }}
.badge {{ font-size:11.5px; background:var(--rail); color:var(--ink2);
  border-radius:20px; padding:2px 9px; }}
.hz {{ font-size:12px; color:var(--muted); }}
.count {{ font-size:12px; color:var(--muted); margin-left:auto;
  font-variant-numeric:tabular-nums; }}
.desc {{ color:var(--ink2); font-size:13px; margin:8px 0 4px; }}
.jalons {{ list-style:none; margin:10px 0 0; padding:0; }}
.j {{ display:flex; align-items:center; gap:8px; padding:3px 0; font-size:13.5px; }}
.j .box {{ color:var(--muted); flex:0 0 auto; }}
.j.done .box {{ color:var(--s1); }}
.j.done .jt {{ color:var(--muted); text-decoration:line-through; }}
.jt {{ flex:1; }}
.star {{ font-size:12px; }}
.due {{ font-size:11.5px; color:var(--muted); font-variant-numeric:tabular-nums; }}
.due.late {{ color:var(--late); font-weight:600; }}
section {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:20px 22px; margin-top:18px; }}
h2 {{ font-size:15px; margin:0 0 14px; font-weight:600; }}
table {{ width:100%; border-collapse:collapse; font-size:13.5px; }}
th, td {{ text-align:left; padding:7px 10px; border-bottom:1px solid var(--border); }}
th {{ color:var(--muted); font-weight:600; font-size:12px; }}
td.d {{ font-variant-numeric:tabular-nums; white-space:nowrap; }}
td.w {{ color:var(--ink2); white-space:nowrap; }}
tr.late td.w, tr.late td.d {{ color:var(--late); font-weight:600; }}
.vide {{ color:var(--muted); text-align:center; }}
footer {{ color:var(--muted); font-size:12px; margin-top:28px; text-align:center; }}
code {{ font-size:12px; }}
</style></head><body><div class="wrap">
<header>
  <div><h1>🎯 Mes ambitions</h1>
  <div class="sub">feuille de route · au {aujourdhui:%d/%m/%Y}</div></div>
  <button class="toggle" onclick="tt()">◐ Thème</button>
</header>
<div class="tiles">
  {_tile(len(ambitions), "ambitions")}
  {_tile(f"{faits_jalons}/{total_jalons}", "jalons atteints")}
  {_tile(f"{en_retard}", "jalons en retard")}
  {_tile(prochaine.strftime('%d/%m/%y') if prochaine else "—", "prochaine échéance")}
</div>
<div class="hero">
  <div class="pct-big">Avancement global · {ratio_global*100:.0f} %</div>
  {_barre_svg(ratio_global, "var(--s0)")}
</div>
<div class="grid">{''.join(cartes)}</div>
<section>
  <h2>📅 Prochaines échéances</h2>
  <table><thead><tr><th>Date</th><th>Délai</th><th>Ambition</th><th>Jalon</th></tr></thead>
  <tbody>{tableau_ech}</tbody></table>
</section>
<footer>Généré par <code>objectifs.py</code> · données locales, 100 % hors-ligne</footer>
</div>
<script>
function tt(){{
  var r=document.documentElement;
  var cur=r.getAttribute('data-theme');
  if(!cur){{cur=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}}
  r.setAttribute('data-theme', cur==='dark'?'light':'dark');
}}
</script>
</body></html>"""


# --------------------------------------------------------------------------- #
#  Mode portfolio (--index) : agrège plusieurs projets en un seul tableau
# --------------------------------------------------------------------------- #
#  Chaque fichier *.objectifs.txt est vu comme UN PROJET ; ses « # » sont ses
#  jalons, leurs cases à cocher ses sous-tâches. Le nom du projet vient d'une
#  ligne « projet: … » en tête de fichier, sinon il est déduit du nom de fichier.
def deriver_nom_projet(chemin: Path) -> str:
    nom = chemin.name
    for suf in (".objectifs.txt", ".txt"):
        if nom.endswith(suf):
            nom = nom[: -len(suf)]
            break
    return nom.replace("-", " ").replace("_", " ").strip() or chemin.name


def lire_projet(chemin: Path) -> dict:
    """Lit un fichier comme un projet : nom + ses ambitions (= jalons)."""
    nom = None
    for brut in chemin.read_text(encoding="utf-8").splitlines():
        ligne = brut.strip()
        if not ligne or ligne.startswith("//"):
            continue
        if ligne.startswith("#"):
            break  # fin de l'en-tête : on passe aux jalons
        if ligne.lower().startswith("projet:"):
            nom = ligne.split(":", 1)[1].strip()
            break
    return {
        "nom": nom or deriver_nom_projet(chemin),
        "fichier": str(chemin),
        "ambitions": lire_ambitions(chemin),
    }


def stats_projet(projet: dict) -> dict:
    """Agrège les sous-tâches d'un projet : nb jalons, faits/total, ratio."""
    sous = [j for a in projet["ambitions"] for j in a["jalons"]]
    total = len(sous)
    faits = sum(1 for j in sous if j["fait"])
    return {
        "n_jalons": len(projet["ambitions"]),
        "total": total,
        "faits": faits,
        "ratio": faits / total if total else 0.0,
    }


def echeances_portfolio(projets: list[dict], aujourdhui: date) -> list[dict]:
    """Toutes les échéances à venir, tous projets confondus, triées par date."""
    items = []
    for p in projets:
        for e in prochaines_echeances(p["ambitions"], aujourdhui):
            items.append({**e, "projet": p["nom"]})
    return sorted(items, key=lambda x: x["echeance"])


def rapport_markdown_index(projets: list[dict], aujourdhui: date) -> str:
    out: list[str] = []
    A = out.append

    stats = [stats_projet(p) for p in projets]
    sous_total = sum(s["total"] for s in stats)
    sous_faits = sum(s["faits"] for s in stats)
    ratio = sous_faits / sous_total if sous_total else 0.0
    n_jalons = sum(s["n_jalons"] for s in stats)

    A("# 🎛️ Portfolio — feuille de route\n")
    A(f"*{len(projets)} projets · {n_jalons} jalons · {sous_faits}/{sous_total} "
      f"sous-tâches · {ratio*100:.0f} % · au {aujourdhui:%Y-%m-%d}*\n")
    A(f"`{barre_texte(ratio, 28)}` **{ratio*100:.0f} %**\n")

    A("## 📦 Par projet\n")
    A("| Projet | Jalons | Sous-tâches | Avancement | Prochaine échéance |")
    A("|---|--:|--:|--:|---|")
    for p, s in zip(projets, stats):
        ech = prochaines_echeances(p["ambitions"], aujourdhui)
        prochaine = fmt_echeance(ech[0]["echeance"], aujourdhui) if ech else "—"
        A(f"| {p['nom']} | {s['n_jalons']} | {s['faits']}/{s['total']} "
          f"| {s['ratio']*100:.0f} % | {prochaine} |")
    A("")

    ech = echeances_portfolio(projets, aujourdhui)
    A("## 📅 Prochaines échéances (tous projets)\n")
    if ech:
        A("| Échéance | Projet | Jalon | Sous-tâche |")
        A("|---|---|---|---|")
        for e in ech[:20]:
            marque = "⭐ " if e["prioritaire"] else ""
            A(f"| {fmt_echeance(e['echeance'], aujourdhui)} | {e['projet']} "
              f"| {e['ambition']} | {marque}{e['texte']} |")
    else:
        A("*Aucun jalon daté à venir.*")
    A("")
    return "\n".join(out)


def generer_html_index(projets: list[dict], aujourdhui: date) -> str:
    stats = [stats_projet(p) for p in projets]
    sous_total = sum(s["total"] for s in stats)
    sous_faits = sum(s["faits"] for s in stats)
    ratio_global = sous_faits / sous_total if sous_total else 0.0
    n_jalons = sum(s["n_jalons"] for s in stats)
    ech = echeances_portfolio(projets, aujourdhui)
    en_retard = sum(1 for e in ech if e["en_retard"])
    prochaine = ech[0]["echeance"] if ech else None

    cartes = []
    for i, (p, s) in enumerate(zip(projets, stats)):
        teinte = f"var(--s{i % len(S_LIGHT)})"
        jl = []
        for a in p["ambitions"]:
            f_, t_, _r = avancement(a)
            complet = " done" if t_ and f_ == t_ else ""
            jl.append(f"<li class='ml{complet}'><span class='ml-t'>{_esc(a['titre'])}</span>"
                      f"<span class='ml-c'>{f_}/{t_}</span></li>")
        pech = prochaines_echeances(p["ambitions"], aujourdhui)
        if pech:
            e0 = pech[0]
            rc = "next late" if e0["en_retard"] else "next"
            prochaine_html = (f"<div class='{rc}'>⌛ {e0['echeance']:%d/%m/%y} — "
                              f"{_esc(e0['texte'])}</div>")
        else:
            prochaine_html = "<div class='next'>✓ aucune échéance à venir</div>"
        cartes.append(f"""
<article class="card">
  <div class="card-h"><h3>{_esc(p['nom'])}</h3><span class="pct">{s['ratio']*100:.0f}%</span></div>
  <div class="meta"><span class="count">{s['n_jalons']} jalons · {s['faits']}/{s['total']} sous-tâches</span></div>
  {_barre_svg(s['ratio'], teinte)}
  <ul class="mls">{''.join(jl)}</ul>
  {prochaine_html}
</article>""")

    lignes = []
    for e in ech[:14]:
        cls = "late" if e["en_retard"] else ""
        quand = (f"en retard ({-e['jours']} j)" if e["en_retard"]
                 else ("aujourd'hui" if e["jours"] == 0 else f"dans {e['jours']} j"))
        star = "⭐ " if e["prioritaire"] else ""
        lignes.append(f"<tr class='{cls}'><td class='d'>{e['echeance']:%d/%m/%Y}</td>"
                      f"<td class='w'>{_esc(quand)}</td><td>{_esc(e['projet'])}</td>"
                      f"<td>{star}{_esc(e['texte'])}</td></tr>")
    tableau = ("".join(lignes) if lignes
               else "<tr><td colspan='4' class='vide'>Aucun jalon daté à venir.</td></tr>")

    palette = "".join(f"--s{i}:{c};" for i, c in enumerate(S_LIGHT))
    palette_d = "".join(f"--s{i}:{c};" for i, c in enumerate(S_DARK))

    return f"""<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Portfolio — feuille de route</title>
<style>
:root {{
  --plane:#f9f9f7; --surface:#fcfcfb; --ink:#0b0b0b; --ink2:#52514e;
  --muted:#898781; --border:rgba(11,11,11,.10); --rail:#e6e5df;
  --late:#e34948; {palette}
}}
:root[data-theme="dark"], html[data-theme="dark"] {{
  --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
  --muted:#898781; --border:rgba(255,255,255,.10); --rail:#2c2c2a;
  --late:#e66767; {palette_d}
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
    --muted:#898781; --border:rgba(255,255,255,.10); --rail:#2c2c2a;
    --late:#e66767; {palette_d}
  }}
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--plane); color:var(--ink);
  font-family:system-ui,-apple-system,"Segoe UI",sans-serif; line-height:1.5; }}
.wrap {{ max-width:1000px; margin:0 auto; padding:32px 20px 64px; }}
header {{ display:flex; align-items:baseline; justify-content:space-between;
  gap:16px; flex-wrap:wrap; }}
h1 {{ font-size:22px; margin:0; }}
.sub {{ color:var(--ink2); font-size:14px; }}
.toggle {{ border:1px solid var(--border); background:var(--surface);
  color:var(--ink2); border-radius:8px; padding:6px 12px; font:inherit;
  font-size:13px; cursor:pointer; }}
.tiles {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr));
  gap:12px; margin:20px 0 8px; }}
.tile {{ background:var(--surface); border:1px solid var(--border);
  border-radius:12px; padding:16px 18px; }}
.tile-v {{ font-size:28px; font-weight:600; font-variant-numeric:tabular-nums; }}
.tile-l {{ color:var(--ink2); font-size:13px; margin-top:2px; }}
.pbar {{ width:100%; height:8px; display:block; margin:6px 0 2px; }}
.hero {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:18px 22px; margin-top:14px; }}
.hero .pct-big {{ font-size:15px; font-weight:600; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr));
  gap:16px; margin-top:18px; }}
.card {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:18px 20px; }}
.card-h {{ display:flex; justify-content:space-between; align-items:baseline; gap:10px; }}
.card-h h3 {{ font-size:15.5px; margin:0; }}
.pct {{ font-size:15px; font-weight:600; font-variant-numeric:tabular-nums; }}
.meta {{ margin:6px 0 2px; }}
.count {{ font-size:12px; color:var(--muted); font-variant-numeric:tabular-nums; }}
.mls {{ list-style:none; margin:10px 0 0; padding:0; }}
.ml {{ display:flex; align-items:center; gap:8px; padding:2px 0; font-size:12.5px; }}
.ml-t {{ flex:1; color:var(--ink2); }}
.ml.done .ml-t {{ color:var(--muted); }}
.ml-c {{ font-variant-numeric:tabular-nums; color:var(--muted); font-size:12px; }}
.ml.done .ml-c {{ color:var(--s1); font-weight:600; }}
.next {{ margin-top:10px; font-size:12px; color:var(--muted);
  border-top:1px solid var(--border); padding-top:8px; }}
.next.late {{ color:var(--late); font-weight:600; }}
section {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:20px 22px; margin-top:18px; }}
h2 {{ font-size:15px; margin:0 0 14px; font-weight:600; }}
table {{ width:100%; border-collapse:collapse; font-size:13.5px; }}
th, td {{ text-align:left; padding:7px 10px; border-bottom:1px solid var(--border); }}
th {{ color:var(--muted); font-weight:600; font-size:12px; }}
td.d {{ font-variant-numeric:tabular-nums; white-space:nowrap; }}
td.w {{ color:var(--ink2); white-space:nowrap; }}
tr.late td.w, tr.late td.d {{ color:var(--late); font-weight:600; }}
.vide {{ color:var(--muted); text-align:center; }}
footer {{ color:var(--muted); font-size:12px; margin-top:28px; text-align:center; }}
code {{ font-size:12px; }}
</style></head><body><div class="wrap">
<header>
  <div><h1>🎛️ Portfolio — feuille de route</h1>
  <div class="sub">{len(projets)} projets · au {aujourdhui:%d/%m/%Y}</div></div>
  <button class="toggle" onclick="tt()">◐ Thème</button>
</header>
<div class="tiles">
  {_tile(len(projets), "projets")}
  {_tile(f"{sous_faits}/{sous_total}", "sous-tâches faites")}
  {_tile(f"{en_retard}", "sous-tâches en retard")}
  {_tile(prochaine.strftime('%d/%m/%y') if prochaine else "—", "prochaine échéance")}
</div>
<div class="hero">
  <div class="pct-big">Avancement global du portfolio · {ratio_global*100:.0f} %</div>
  {_barre_svg(ratio_global, "var(--s0)")}
</div>
<div class="grid">{''.join(cartes)}</div>
<section>
  <h2>📅 Prochaines échéances · tous projets</h2>
  <table><thead><tr><th>Date</th><th>Délai</th><th>Projet</th><th>Sous-tâche</th></tr></thead>
  <tbody>{tableau}</tbody></table>
</section>
<footer>Généré par <code>objectifs.py --index</code> · données locales, 100 % hors-ligne</footer>
</div>
<script>
function tt(){{
  var r=document.documentElement;
  var cur=r.getAttribute('data-theme');
  if(!cur){{cur=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}}
  r.setAttribute('data-theme', cur==='dark'?'light':'dark');
}}
</script>
</body></html>"""


# --------------------------------------------------------------------------- #
#  Main
# --------------------------------------------------------------------------- #
def _run_simple(args) -> int:
    if len(args.fichiers) > 1:
        print("ℹ️  Plusieurs fichiers fournis sans --index : seul le premier "
              "est utilisé.", file=sys.stderr)
        print("   Utilise --index pour un tableau de bord de portfolio.",
              file=sys.stderr)
    chemin = Path(args.fichiers[0]).expanduser()
    if not chemin.exists():
        print(f"❌ Fichier introuvable : {chemin}", file=sys.stderr)
        return 1

    ambitions = lire_ambitions(chemin)
    if not ambitions:
        print(f"❌ Aucune ambition trouvée dans {chemin}.", file=sys.stderr)
        print("   Un titre commence par « # ». Voir objectifs.exemple.txt.",
              file=sys.stderr)
        return 1

    aujourdhui = date.today()
    rapport = rapport_markdown(ambitions, aujourdhui)

    if args.out:
        Path(args.out).write_text(rapport, encoding="utf-8")
        print(f"✅ Rapport Markdown écrit dans {args.out}", file=sys.stderr)
    else:
        print(rapport)

    if args.html:
        Path(args.html).write_text(generer_html(ambitions, aujourdhui),
                                   encoding="utf-8")
        print(f"✅ Dashboard HTML écrit dans {args.html}", file=sys.stderr)
    return 0


def _run_index(args) -> int:
    # Un dossier est développé en ses fichiers *.objectifs.txt ; un fichier est
    # pris tel quel. On déduplique en gardant l'ordre d'apparition.
    chemins: list[Path] = []
    for f in args.fichiers:
        p = Path(f).expanduser()
        if p.is_dir():
            trouves = sorted(p.glob("*.objectifs.txt"))
            if not trouves:
                print(f"⚠️  Aucun *.objectifs.txt dans {p}", file=sys.stderr)
            chemins.extend(trouves)
        elif p.exists():
            chemins.append(p)
        else:
            print(f"❌ Introuvable, ignoré : {p}", file=sys.stderr)

    vus, uniques = set(), []
    for p in chemins:
        cle = str(p.resolve())
        if cle not in vus:
            vus.add(cle)
            uniques.append(p)

    projets = []
    for p in uniques:
        projet = lire_projet(p)
        if projet["ambitions"]:
            projets.append(projet)
        else:
            print(f"⚠️  Ignoré (aucune ambition) : {p}", file=sys.stderr)

    if not projets:
        print("❌ Aucun projet exploitable.", file=sys.stderr)
        return 1

    aujourdhui = date.today()
    rapport = rapport_markdown_index(projets, aujourdhui)

    if args.out:
        Path(args.out).write_text(rapport, encoding="utf-8")
        print(f"✅ Rapport Markdown écrit dans {args.out}", file=sys.stderr)
    else:
        print(rapport)

    if args.html:
        Path(args.html).write_text(generer_html_index(projets, aujourdhui),
                                   encoding="utf-8")
        print(f"✅ Dashboard HTML écrit dans {args.html}", file=sys.stderr)

    print(f"✅ {len(projets)} projet(s) agrégé(s).", file=sys.stderr)
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description="Suivi local de tes ambitions et de leur avancement.")
    ap.add_argument("fichiers", nargs="+",
                    help="Sans --index : un fichier d'ambitions "
                         "(voir objectifs.exemple.txt). Avec --index : un ou "
                         "plusieurs fichiers et/ou dossiers de projets.")
    ap.add_argument("--index", action="store_true",
                    help="Mode portfolio : agrège plusieurs fichiers "
                         "*.objectifs.txt (un par projet) en un seul tableau de bord.")
    ap.add_argument("--out", metavar="FICHIER",
                    help="Écrit le rapport Markdown dans un fichier")
    ap.add_argument("--html", metavar="FICHIER",
                    help="Génère un dashboard HTML autonome (SVG)")
    args = ap.parse_args(argv)

    return _run_index(args) if args.index else _run_simple(args)


if __name__ == "__main__":
    raise SystemExit(main())
