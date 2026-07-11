#!/usr/bin/env python3
"""
classer_sessions.py — Classe tes sessions Claude Code par catégories.

À lancer EN LOCAL sur ta machine (là où vivent tes sessions) :

    python3 classer_sessions.py                 # rapport Markdown dans le terminal
    python3 classer_sessions.py --out rapport.md     # écrit le rapport Markdown
    python3 classer_sessions.py --html rapport.html  # rapport visuel (graphiques SVG)
    python3 classer_sessions.py --csv sessions.csv   # export CSV en plus

Aucune dépendance externe : uniquement la bibliothèque standard Python 3.8+.
Le script ne modifie RIEN — il lit seulement ~/.claude/projects/.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path


# --------------------------------------------------------------------------- #
#  Correspondance de mots-clés
# --------------------------------------------------------------------------- #
#  Cache des regex « mot entier » pour les mots-clés purement alphanumériques.
_MOT_RE_CACHE: dict = {}


def contient_motcle(texte: str, motcle: str) -> bool:
    """Vrai si `motcle` apparaît dans `texte` (supposé déjà en minuscules).

    - mot purement alphanumérique (« ci », « add », « test », « débug »)
      → correspondance « mot entier » délimitée, pour éviter les faux positifs
      (« ci » dans « merci », « add » dans « adresse », « test » dans « latest »).
    - mot avec espace / ponctuation (« best-of-n », « .py », « rag local »)
      → simple sous-chaîne, car les bornes de mot n'ont pas de sens ici.
    """
    if motcle.isalnum():
        rx = _MOT_RE_CACHE.get(motcle)
        if rx is None:
            rx = re.compile(rf"(?<![0-9a-zà-ÿ]){re.escape(motcle)}(?![0-9a-zà-ÿ])")
            _MOT_RE_CACHE[motcle] = rx
        return rx.search(texte) is not None
    return motcle in texte

# --------------------------------------------------------------------------- #
#  Catégorisation par THÈME (heuristique sur le 1er prompt utilisateur)
# --------------------------------------------------------------------------- #
THEMES = {
    "🐛 Debug / correction": [
        "bug", "erreur", "error", "fix", "corrige", "corriger", "plante",
        "crash", "fail", "casse", "marche pas", "ne fonctionne", "traceback",
        "exception", "débug", "debug",
    ],
    "✨ Nouvelle fonctionnalité": [
        "ajoute", "ajouter", "implémente", "implémenter", "crée", "créer",
        "add", "implement", "nouvelle", "feature", "fonctionnalité", "build",
        "génère", "construire", "mettre en place",
    ],
    "♻️ Refactor / nettoyage": [
        "refactor", "refacto", "nettoie", "nettoyer", "simplifie", "réorganise",
        "clean", "renomme", "restructure", "améliore", "optimise", "optimize",
        "dette technique",
    ],
    "📝 Documentation": [
        "documente", "documentation", "readme", "docstring", "commentaire",
        "doc ", "explique dans", "rédige", "changelog",
    ],
    "🧪 Tests": [
        "test", "tests", "pytest", "couverture", "coverage", "unittest",
        "mock", "assertion",
    ],
    "❓ Question / explication": [
        "comment", "pourquoi", "explique", "explique-moi", "c'est quoi",
        "what", "why", "how", "peux-tu m'expliquer", "à quoi sert", "différence",
    ],
    "⚙️ Config / infra / CI": [
        "config", "configuration", "ci", "docker", "déploie", "deploy",
        "pipeline", "github action", "workflow", "install", "setup", "env",
        "environnement", "makefile",
    ],
    "🔒 Sécurité": [
        "sécurité", "security", "vuln", "cve", "audit", "ssrf", "injection",
        "secret", "sandbox", "durcir",
    ],
}


def theme_de(prompt: str) -> str:
    """Devine le thème d'une session à partir de son premier prompt."""
    p = (prompt or "").lower()
    scores = Counter()
    for theme, mots in THEMES.items():
        for m in mots:
            if contient_motcle(p, m):
                scores[theme] += 1
    if not scores:
        return "🗂️  Autre / non classé"
    return scores.most_common(1)[0][0]


# --------------------------------------------------------------------------- #
#  Reconnaissance de TES projets (adapté à klodynlov)
# --------------------------------------------------------------------------- #
#  Pour chaque projet : des indices de CHEMIN (nom de dossier / repo) et des
#  mots-clés de CONTENU (repérés dans le 1er prompt si le chemin ne suffit pas).
#  Ajoute/retire librement des entrées ici.
PROJETS_CONNUS = {
    "🧠 Klody Code AI": {
        "chemins": ["klody-code-ai", "klody_code_ai", "klodycode", "klody-code"],
        "mots": ["klody code", "klody-code", "agent de code local", "routeur adaptatif",
                 "react loop", "best-of-n", "mlx-lm", "orchestration adaptative"],
    },
    "🖥️ klody-ui (desktop)": {
        "chemins": ["klody-ui", "klody_ui", "klodyui"],
        "mots": ["klody-ui", "tauri", "thème clair/sombre", "frontend desktop"],
    },
    "🌍 Dream × World": {
        "chemins": ["dream-x-world", "dream_x_world", "dreamxworld", "dream-world"],
        "mots": ["dream x world", "dream × world", "canon engine", "monde persistant",
                 "mondes ia", "anti-contradiction", "simulation temporelle"],
    },
    "📚 LibraryBrain": {
        "chemins": ["librarybrain", "library-brain", "library_brain"],
        "mots": ["librarybrain", "library brain", "rag local", "rag de livres",
                 "sqlite-vec", "retrieval de livres"],
    },
    "🎙️ VocalBrain": {
        "chemins": ["vocalbrain", "vocal-brain", "vocal_brain"],
        "mots": ["vocalbrain", "vocal brain", "voix", "audio", "transcription", "tts", "stt"],
    },
    "👤 Profil GitHub (klodynlov)": {
        "chemins": ["klodynlov"],
        "mots": ["readme de profil", "profil github", "badge shields"],
    },
}


def projet_connu(cwd: str, prompt: str) -> str:
    """Identifie un de TES projets via le chemin, sinon via le 1er prompt."""
    chemin = (cwd or "").lower()
    # 1) Le chemin du dossier est le signal le plus fiable.
    for label, regles in PROJETS_CONNUS.items():
        if any(ind in chemin for ind in regles["chemins"]):
            return label
    # 2) Repli sur le contenu du premier prompt.
    p = (prompt or "").lower()
    for label, regles in PROJETS_CONNUS.items():
        if any(contient_motcle(p, m) for m in regles["mots"]):
            return label
    return "🗂️  Hors projet connu"


# --------------------------------------------------------------------------- #
#  Catégorisation par TECHNO (mots-clés dans le 1er prompt)
# --------------------------------------------------------------------------- #
TECHNOS = {
    "Python": ["python", "pytest", "fastapi", ".py", "django", "flask"],
    "Rust": ["rust", "cargo", ".rs", "tauri"],
    "TypeScript/JS": ["typescript", "javascript", ".ts", ".tsx", ".js", "react", "node", "npm"],
    "MCP": ["mcp", "model context protocol", "serveur mcp", "connecteur"],
    "SQL/DB": ["sql", "sqlite", "postgres", "base de données", "database", "requête"],
    "Shell/DevOps": ["bash", "shell", "docker", "kubernetes", "ci/cd", "github action"],
}


def technos_de(prompt: str) -> list[str]:
    p = (prompt or "").lower()
    trouves = [t for t, mots in TECHNOS.items()
               if any(contient_motcle(p, m) for m in mots)]
    return trouves or ["—"]


# --------------------------------------------------------------------------- #
#  Lecture des sessions
# --------------------------------------------------------------------------- #
def decode_project_dir(name: str) -> str:
    """~/.claude/projects encode le chemin en remplaçant / par -."""
    # Heuristique : le nom est le chemin absolu avec '/' -> '-'
    return name.replace("-", "/") if name.startswith("-") else name


def parse_ts(val) -> datetime | None:
    if not val:
        return None
    try:
        # Formats ISO type "2026-07-09T06:43:00.000Z"
        s = str(val)
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        dt = datetime.fromisoformat(s)
    except Exception:
        return None
    # Toujours renvoyer un datetime « aware » (UTC par défaut) : mélanger des
    # datetimes naïfs et aware ferait planter les tris / min / max plus loin.
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def lire_session(path: Path) -> dict | None:
    """Extrait un résumé d'une session .jsonl."""
    premier_prompt = ""
    n_msgs = 0
    n_user = 0
    n_assistant = 0
    t_debut = None
    t_fin = None
    cwd = ""

    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                # Entrées internes de Claude Code (caveats, sorties de commande…)
                # : ni comptées, ni utilisées pour deviner le thème.
                if obj.get("isMeta"):
                    continue

                ts = parse_ts(obj.get("timestamp"))
                if ts:
                    t_debut = ts if t_debut is None else min(t_debut, ts)
                    t_fin = ts if t_fin is None else max(t_fin, ts)

                if not cwd and obj.get("cwd"):
                    cwd = obj["cwd"]

                role = obj.get("type") or obj.get("role")
                msg = obj.get("message") or {}
                if isinstance(msg, dict):
                    role = role or msg.get("role")

                if role in ("user", "human"):
                    n_user += 1
                    n_msgs += 1
                    if not premier_prompt:
                        txt = extraire_texte(msg).strip()
                        # On saute les wrappers de commandes (<command-name>…,
                        # <local-command-stdout>…) et les blocs vides / tool_result.
                        if txt and not txt.startswith("<"):
                            premier_prompt = txt
                elif role in ("assistant", "ai"):
                    n_assistant += 1
                    n_msgs += 1
    except Exception as e:
        print(f"  ⚠️  illisible: {path.name} ({e})", file=sys.stderr)
        return None

    if n_msgs == 0:
        return None

    duree = None
    if t_debut and t_fin:
        duree = (t_fin - t_debut).total_seconds()

    return {
        "session_id": path.stem,
        "fichier": str(path),
        "projet": cwd or decode_project_dir(path.parent.name),
        "premier_prompt": premier_prompt.strip()[:200],
        "n_messages": n_msgs,
        "n_user": n_user,
        "n_assistant": n_assistant,
        "debut": t_debut,
        "fin": t_fin,
        "duree_s": duree,
        "projet_connu": projet_connu(cwd or decode_project_dir(path.parent.name), premier_prompt),
        "theme": theme_de(premier_prompt),
        "technos": technos_de(premier_prompt),
    }


def extraire_texte(msg: dict) -> str:
    """Récupère le texte d'un message (contenu string ou liste de blocs)."""
    if not isinstance(msg, dict):
        return str(msg)
    content = msg.get("content", "")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        morceaux = []
        for bloc in content:
            if isinstance(bloc, dict) and bloc.get("type") == "text":
                morceaux.append(bloc.get("text", ""))
            elif isinstance(bloc, str):
                morceaux.append(bloc)
        return " ".join(morceaux)
    return ""


# --------------------------------------------------------------------------- #
#  Mise en forme
# --------------------------------------------------------------------------- #
def fmt_duree(s: float | None) -> str:
    if not s:
        return "—"
    if s < 60:
        return f"{int(s)}s"
    if s < 3600:
        return f"{int(s // 60)}min"
    return f"{s / 3600:.1f}h"


def fmt_date(dt: datetime | None) -> str:
    return dt.astimezone().strftime("%Y-%m-%d %H:%M") if dt else "—"


def nom_projet(chemin: str) -> str:
    return Path(chemin).name or chemin


def rapport_markdown(sessions: list[dict]) -> str:
    out: list[str] = []
    A = out.append

    A("# 🗂️  Tes sessions Claude Code — classées\n")
    A(f"*{len(sessions)} sessions analysées · généré le "
      f"{datetime.now().astimezone().strftime('%Y-%m-%d %H:%M')}*\n")

    # --- Vue d'ensemble ---
    total_msgs = sum(s["n_messages"] for s in sessions)
    A("## 📊 Vue d'ensemble\n")
    A(f"- **Sessions** : {len(sessions)}")
    A(f"- **Messages au total** : {total_msgs}")
    dts = [s["debut"] for s in sessions if s["debut"]]
    if dts:
        A(f"- **Période** : {min(dts).astimezone():%Y-%m-%d} → {max(dts).astimezone():%Y-%m-%d}")
    A("")

    # --- Par projet CONNU (tes projets) ---
    A("## 🚀 Par projet (les tiens)\n")
    par_connu: dict[str, list[dict]] = defaultdict(list)
    for s in sessions:
        par_connu[s["projet_connu"]].append(s)
    A("| Projet | Sessions | Messages | Dernière activité |")
    A("|---|--:|--:|---|")
    for proj, grp in sorted(par_connu.items(), key=lambda kv: -len(kv[1])):
        derniere = max((x["debut"] for x in grp if x["debut"]), default=None)
        A(f"| {proj} | {len(grp)} | {sum(x['n_messages'] for x in grp)} "
          f"| {fmt_date(derniere)} |")
    A("")

    # --- Par dossier brut ---
    A("## 📁 Par dossier de travail\n")
    par_projet: dict[str, list[dict]] = defaultdict(list)
    for s in sessions:
        par_projet[nom_projet(s["projet"])].append(s)
    A("| Dossier | Sessions | Messages |")
    A("|---|--:|--:|")
    for proj, grp in sorted(par_projet.items(), key=lambda kv: -len(kv[1])):
        A(f"| `{proj}` | {len(grp)} | {sum(x['n_messages'] for x in grp)} |")
    A("")

    # --- Par thème ---
    A("## 🎯 Par thème d'activité\n")
    par_theme: dict[str, list[dict]] = defaultdict(list)
    for s in sessions:
        par_theme[s["theme"]].append(s)
    A("| Thème | Sessions |")
    A("|---|--:|")
    for theme, grp in sorted(par_theme.items(), key=lambda kv: -len(kv[1])):
        A(f"| {theme} | {len(grp)} |")
    A("")

    # --- Par techno ---
    A("## 🛠️  Par techno\n")
    compte_tech: Counter = Counter()
    for s in sessions:
        for t in s["technos"]:
            if t != "—":
                compte_tech[t] += 1
    if compte_tech:
        A("| Techno | Sessions |")
        A("|---|--:|")
        for t, n in compte_tech.most_common():
            A(f"| {t} | {n} |")
    else:
        A("*(aucune techno détectée dans les prompts)*")
    A("")

    # --- Détail chronologique ---
    A("## 🕑 Détail (des plus récentes aux plus anciennes)\n")
    A("| Date | Projet | Thème | Msgs | Durée | Premier prompt |")
    A("|---|---|---|--:|--:|---|")
    for s in sorted(sessions, key=lambda x: x["debut"] or datetime.min.replace(tzinfo=timezone.utc), reverse=True):
        prompt = s["premier_prompt"].replace("|", "\\|").replace("\n", " ")
        if len(prompt) > 70:
            prompt = prompt[:67] + "…"
        A(f"| {fmt_date(s['debut'])} | {s['projet_connu']} | {s['theme']} "
          f"| {s['n_messages']} | {fmt_duree(s['duree_s'])} | {prompt} |")
    A("")

    return "\n".join(out)


# --------------------------------------------------------------------------- #
#  Rapport HTML autonome (SVG en ligne, thème clair/sombre, sans dépendance)
# --------------------------------------------------------------------------- #
#  Palette catégorielle validée CVD-safe (cf. skill dataviz). 8 teintes, en
#  ordre fixe ; le 9e cas (« Autre ») retombe sur un gris neutre.
CAT_LIGHT = ["#2a78d6", "#1baf7a", "#eda100", "#008300",
             "#4a3aa7", "#e34948", "#e87ba4", "#eb6834"]
CAT_DARK = ["#3987e5", "#199e70", "#c98500", "#008300",
            "#9085e9", "#e66767", "#d55181", "#d95926"]

# Chaque thème garde une teinte fixe (la couleur suit l'entité, pas le rang).
THEME_SLOT = {theme: i for i, theme in enumerate(THEMES)}


def _esc(s: str) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def _rect_droite_arrondie(x: float, y: float, w: float, h: float, r: float) -> str:
    """Rectangle au coin-données (droit) arrondi, carré au départ (baseline)."""
    r = min(r, w, h / 2)
    if w <= 0:
        return ""
    return (f"M{x:.1f},{y:.1f} H{x + w - r:.1f} Q{x + w:.1f},{y:.1f} "
            f"{x + w:.1f},{y + r:.1f} V{y + h - r:.1f} "
            f"Q{x + w:.1f},{y + h:.1f} {x + w - r:.1f},{y + h:.1f} "
            f"H{x:.1f} Z")


def svg_barres(rows: list, couleur_var: str) -> str:
    """Barres horizontales de magnitude (une seule teinte). rows: (label, valeur)."""
    if not rows:
        return "<p class='vide'>—</p>"
    larg, lab_w, pad = 660, 190, 8
    bar_h, gap = 20, 14
    aire = larg - lab_w - 56
    vmax = max(v for _, v in rows) or 1
    haut = pad * 2 + len(rows) * bar_h + (len(rows) - 1) * gap
    parts = [f"<svg viewBox='0 0 {larg} {haut}' class='chart' role='img' "
             f"preserveAspectRatio='xMinYMin meet'>"]
    y = pad
    for label, val in rows:
        w = aire * (val / vmax)
        parts.append(
            f"<text x='{lab_w - 10}' y='{y + bar_h / 2:.1f}' class='ylab' "
            f"text-anchor='end' dominant-baseline='central'>{_esc(label)}</text>")
        parts.append(f"<path d='{_rect_droite_arrondie(lab_w, y, w, bar_h, 4)}' "
                     f"fill='var({couleur_var})'/>")
        parts.append(
            f"<text x='{lab_w + w + 8:.1f}' y='{y + bar_h / 2:.1f}' class='val' "
            f"dominant-baseline='central'>{val}</text>")
        y += bar_h + gap
    parts.append("</svg>")
    return "".join(parts)


def svg_donut(rows: list) -> str:
    """Donut catégoriel. rows: (label, valeur, slot|None) ; slot None -> gris."""
    total = sum(v for _, v, _ in rows) or 1
    r, cx, cy, sw = 70, 90, 90, 26
    circo = 2 * 3.141592653589793 * r
    seg = [f"<svg viewBox='0 0 180 180' class='donut' role='img'>",
           f"<g transform='rotate(-90 {cx} {cy})'>"]
    cumul = 0.0
    for label, val, slot in rows:
        frac = val / total
        longueur = frac * circo
        couleur = (f"var(--s{slot})" if slot is not None else "var(--muted-fill)")
        # petit espace de surface entre segments (2px)
        dash = max(longueur - 2, 0.1)
        seg.append(
            f"<circle cx='{cx}' cy='{cy}' r='{r}' fill='none' "
            f"stroke='{couleur}' stroke-width='{sw}' "
            f"stroke-dasharray='{dash:.2f} {circo - dash:.2f}' "
            f"stroke-dashoffset='{-cumul:.2f}'/>")
        cumul += longueur
    seg.append("</g>")
    seg.append(f"<text x='{cx}' y='{cy - 6}' class='donut-num' "
               f"text-anchor='middle'>{total}</text>")
    seg.append(f"<text x='{cx}' y='{cy + 14}' class='donut-lab' "
               f"text-anchor='middle'>sessions</text>")
    seg.append("</svg>")
    return "".join(seg)


def svg_timeline(sessions: list) -> str:
    """Colonnes : nombre de sessions par jour (ou par semaine si période longue)."""
    jours = [s["debut"].astimezone().date() for s in sessions if s["debut"]]
    if not jours:
        return "<p class='vide'>Pas de dates exploitables.</p>"
    from datetime import timedelta
    d0, d1 = min(jours), max(jours)
    span = (d1 - d0).days
    pas = 7 if span > 120 else 1  # agrège par semaine si > ~4 mois
    from collections import Counter as _C
    if pas == 7:
        cnt = _C(d - timedelta(days=d.weekday()) for d in jours)
        debut = d0 - timedelta(days=d0.weekday())
        buckets, cur = [], debut
        while cur <= d1:
            buckets.append((cur, cnt.get(cur, 0)))
            cur += timedelta(days=7)
    else:
        cnt = _C(jours)
        buckets, cur = [], d0
        while cur <= d1:
            buckets.append((cur, cnt.get(cur, 0)))
            cur += timedelta(days=1)
    vmax = max(v for _, v in buckets) or 1
    col = min(22, max(6, int(620 / max(len(buckets), 1))))
    ecart = max(2, col // 4)
    larg = len(buckets) * (col + ecart) + 40
    haut = 150
    base_y, aire_h = haut - 26, haut - 40
    parts = [f"<svg viewBox='0 0 {larg} {haut}' height='{haut}' "
             f"class='timeline' role='img'>"]
    parts.append(f"<line x1='20' y1='{base_y}' x2='{larg - 10}' y2='{base_y}' "
                 f"class='axe'/>")
    x = 24
    n = len(buckets)
    for i, (jour, val) in enumerate(buckets):
        h = aire_h * (val / vmax)
        if val:
            parts.append(
                f"<rect x='{x:.1f}' y='{base_y - h:.1f}' width='{col}' "
                f"height='{h:.1f}' rx='3' fill='var(--s0)'/>")
        # étiquettes de dates : première, dernière, et quelques intermédiaires
        if i == 0 or i == n - 1 or (n > 4 and i == n // 2):
            parts.append(
                f"<text x='{x + col / 2:.1f}' y='{base_y + 16}' class='xlab' "
                f"text-anchor='middle'>{jour:%d/%m}</text>")
        x += col + ecart
    parts.append("</svg>")
    unite = "semaine" if pas == 7 else "jour"
    return (f"<p class='note'>1 colonne = 1 {unite} · pic à {vmax} "
            f"session{'s' if vmax > 1 else ''}</p>" + "".join(parts))


def _tile(valeur, label: str) -> str:
    return (f"<div class='tile'><div class='tile-v'>{_esc(valeur)}</div>"
            f"<div class='tile-l'>{_esc(label)}</div></div>")


def _legende(rows: list) -> str:
    """Légende thèmes : pastille + libellé + compte (identité jamais couleur-seule)."""
    li = []
    for label, val, slot in rows:
        c = (f"var(--s{slot})" if slot is not None else "var(--muted-fill)")
        li.append(f"<li><span class='dot' style='background:{c}'></span>"
                  f"<span class='lg-lab'>{_esc(label)}</span>"
                  f"<span class='lg-val'>{val}</span></li>")
    return "<ul class='legende'>" + "".join(li) + "</ul>"


def generer_html(sessions: list) -> str:
    total_msgs = sum(s["n_messages"] for s in sessions)
    dts = [s["debut"] for s in sessions if s["debut"]]
    periode = (f"{min(dts).astimezone():%d/%m/%Y} → {max(dts).astimezone():%d/%m/%Y}"
               if dts else "—")

    # --- agrégations ---
    par_connu: dict = defaultdict(list)
    for s in sessions:
        par_connu[s["projet_connu"]].append(s)
    rows_proj = sorted(((p, len(g)) for p, g in par_connu.items()),
                       key=lambda kv: -kv[1])

    par_theme: dict = defaultdict(int)
    for s in sessions:
        par_theme[s["theme"]] += 1
    rows_theme = sorted(par_theme.items(), key=lambda kv: -kv[1])
    donut_rows = [(t, n, THEME_SLOT.get(t)) for t, n in rows_theme]

    compte_tech: Counter = Counter()
    for s in sessions:
        for t in s["technos"]:
            if t != "—":
                compte_tech[t] += 1
    rows_tech = compte_tech.most_common()

    nb_projets = len([p for p in par_connu if not p.startswith("🗂️")])

    doc = [f"""<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sessions Claude Code — classées</title>
<style>
:root {{
  --plane:#f9f9f7; --surface:#fcfcfb; --ink:#0b0b0b; --ink2:#52514e;
  --muted:#898781; --grid:#e1e0d9; --axis:#c3c2b7; --border:rgba(11,11,11,.10);
  --muted-fill:#c3c2b7;
  --s0:{CAT_LIGHT[0]}; --s1:{CAT_LIGHT[1]}; --s2:{CAT_LIGHT[2]}; --s3:{CAT_LIGHT[3]};
  --s4:{CAT_LIGHT[4]}; --s5:{CAT_LIGHT[5]}; --s6:{CAT_LIGHT[6]}; --s7:{CAT_LIGHT[7]};
}}
:root[data-theme="dark"], html[data-theme="dark"] {{
  --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
  --muted:#898781; --grid:#2c2c2a; --axis:#383835; --border:rgba(255,255,255,.10);
  --muted-fill:#54534e;
  --s0:{CAT_DARK[0]}; --s1:{CAT_DARK[1]}; --s2:{CAT_DARK[2]}; --s3:{CAT_DARK[3]};
  --s4:{CAT_DARK[4]}; --s5:{CAT_DARK[5]}; --s6:{CAT_DARK[6]}; --s7:{CAT_DARK[7]};
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --plane:#0d0d0d; --surface:#1a1a19; --ink:#fff; --ink2:#c3c2b7;
    --muted:#898781; --grid:#2c2c2a; --axis:#383835; --border:rgba(255,255,255,.10);
    --muted-fill:#54534e;
    --s0:{CAT_DARK[0]}; --s1:{CAT_DARK[1]}; --s2:{CAT_DARK[2]}; --s3:{CAT_DARK[3]};
    --s4:{CAT_DARK[4]}; --s5:{CAT_DARK[5]}; --s6:{CAT_DARK[6]}; --s7:{CAT_DARK[7]};
  }}
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--plane); color:var(--ink);
  font-family:system-ui,-apple-system,"Segoe UI",sans-serif; line-height:1.5; }}
.wrap {{ max-width:900px; margin:0 auto; padding:32px 20px 64px; }}
header {{ display:flex; align-items:baseline; justify-content:space-between;
  gap:16px; flex-wrap:wrap; margin-bottom:4px; }}
h1 {{ font-size:22px; margin:0; }}
.sub {{ color:var(--ink2); font-size:14px; }}
.toggle {{ border:1px solid var(--border); background:var(--surface);
  color:var(--ink2); border-radius:8px; padding:6px 12px; font:inherit;
  font-size:13px; cursor:pointer; }}
.tiles {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr));
  gap:12px; margin:20px 0 8px; }}
.tile {{ background:var(--surface); border:1px solid var(--border);
  border-radius:12px; padding:16px 18px; }}
.tile-v {{ font-size:28px; font-weight:600; }}
.tile-l {{ color:var(--ink2); font-size:13px; margin-top:2px; }}
section {{ background:var(--surface); border:1px solid var(--border);
  border-radius:14px; padding:20px 22px; margin-top:18px; }}
h2 {{ font-size:15px; margin:0 0 14px; font-weight:600; }}
.chart {{ width:100%; height:auto; }}
.scroll {{ overflow-x:auto; }}
.timeline {{ display:block; min-width:100%; }}
.ylab {{ fill:var(--ink2); font-size:12.5px; }}
.val {{ fill:var(--ink); font-size:12.5px; font-weight:600;
  font-variant-numeric:tabular-nums; }}
.xlab {{ fill:var(--muted); font-size:11px; font-variant-numeric:tabular-nums; }}
.axe {{ stroke:var(--axis); stroke-width:1; }}
.donut-num {{ fill:var(--ink); font-size:26px; font-weight:600; }}
.donut-lab {{ fill:var(--muted); font-size:11px; }}
.split {{ display:flex; gap:24px; align-items:center; flex-wrap:wrap; }}
.donut {{ width:180px; height:180px; flex:0 0 auto; }}
.legende {{ list-style:none; margin:0; padding:0; flex:1 1 240px;
  min-width:220px; }}
.legende li {{ display:flex; align-items:center; gap:10px; padding:3px 0;
  font-size:13.5px; }}
.dot {{ width:11px; height:11px; border-radius:3px; flex:0 0 auto; }}
.lg-lab {{ flex:1; color:var(--ink2); }}
.lg-val {{ font-weight:600; font-variant-numeric:tabular-nums; }}
.note {{ color:var(--muted); font-size:12px; margin:0 0 8px; }}
.vide {{ color:var(--muted); font-size:13px; }}
footer {{ color:var(--muted); font-size:12px; margin-top:28px; text-align:center; }}
a {{ color:var(--s0); }}
</style></head><body><div class="wrap">
<header>
  <div><h1>🗂️ Tes sessions Claude Code</h1>
  <div class="sub">{_esc(periode)} · généré le {datetime.now().astimezone():%d/%m/%Y %H:%M}</div></div>
  <button class="toggle" onclick="tt()">◐ Thème</button>
</header>
<div class="tiles">
  {_tile(len(sessions), "sessions")}
  {_tile(total_msgs, "messages")}
  {_tile(nb_projets, "projets actifs")}
  {_tile(len(rows_theme), "thèmes")}
</div>

<section>
  <h2>🚀 Sessions par projet</h2>
  {svg_barres(rows_proj, "--s0")}
</section>

<section>
  <h2>🎯 Répartition par thème</h2>
  <div class="split">{svg_donut(donut_rows)}{_legende(donut_rows)}</div>
</section>

<section>
  <h2>🛠️ Sessions par techno</h2>
  {svg_barres(rows_tech, "--s1") if rows_tech else "<p class='vide'>Aucune techno détectée.</p>"}
</section>

<section>
  <h2>🕑 Activité dans le temps</h2>
  <div class="scroll">{svg_timeline(sessions)}</div>
</section>

<footer>Généré par <code>classer_sessions.py</code> · données locales, 100 % hors-ligne</footer>
</div>
<script>
function tt(){{
  var r=document.documentElement;
  var cur=r.getAttribute('data-theme');
  if(!cur){{cur=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}}
  r.setAttribute('data-theme', cur==='dark'?'light':'dark');
}}
</script>
</body></html>"""]
    return "".join(doc)


def ecrire_csv(sessions: list[dict], chemin: str) -> None:
    champs = ["session_id", "projet_connu", "projet", "theme", "technos",
              "n_messages", "n_user", "n_assistant", "debut", "fin", "duree_s",
              "premier_prompt", "fichier"]
    with open(chemin, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=champs)
        w.writeheader()
        for s in sessions:
            ligne = dict(s)
            ligne["technos"] = ", ".join(s["technos"])
            ligne["debut"] = fmt_date(s["debut"])
            ligne["fin"] = fmt_date(s["fin"])
            w.writerow({k: ligne.get(k, "") for k in champs})


# --------------------------------------------------------------------------- #
#  Main
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="Classe tes sessions Claude Code par catégories.")
    # Claude Code respecte CLAUDE_CONFIG_DIR pour relocaliser ~/.claude.
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
    defaut_dir = (Path(config_dir) if config_dir else Path.home() / ".claude") / "projects"
    ap.add_argument("--dir", default=str(defaut_dir),
                    help="Dossier des projets Claude Code "
                         "(défaut: $CLAUDE_CONFIG_DIR/projects ou ~/.claude/projects)")
    ap.add_argument("--csv", metavar="FICHIER", help="Exporte aussi un CSV")
    ap.add_argument("--out", metavar="FICHIER", help="Écrit le rapport Markdown dans un fichier")
    ap.add_argument("--html", metavar="FICHIER",
                    help="Génère un rapport HTML autonome avec graphiques (SVG)")
    args = ap.parse_args()

    base = Path(args.dir).expanduser()
    if not base.exists():
        print(f"❌ Dossier introuvable : {base}", file=sys.stderr)
        print("   Lance ce script sur la machine où tu utilises Claude Code.", file=sys.stderr)
        return 1

    fichiers = sorted(base.glob("**/*.jsonl"))
    if not fichiers:
        print(f"❌ Aucune session (.jsonl) trouvée dans {base}", file=sys.stderr)
        return 1

    print(f"🔎 {len(fichiers)} fichier(s) de session trouvé(s)…", file=sys.stderr)
    sessions = [s for s in (lire_session(p) for p in fichiers) if s]

    if not sessions:
        print("❌ Aucune session exploitable.", file=sys.stderr)
        return 1

    rapport = rapport_markdown(sessions)

    if args.out:
        Path(args.out).write_text(rapport, encoding="utf-8")
        print(f"✅ Rapport écrit dans {args.out}", file=sys.stderr)
    else:
        print(rapport)

    if args.html:
        Path(args.html).write_text(generer_html(sessions), encoding="utf-8")
        print(f"✅ Rapport HTML écrit dans {args.html}", file=sys.stderr)

    if args.csv:
        ecrire_csv(sessions, args.csv)
        print(f"✅ CSV écrit dans {args.csv}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
