#!/usr/bin/env python3
"""
classer_sessions.py — Classe tes sessions Claude Code par catégories.

À lancer EN LOCAL sur ta machine (là où vivent tes sessions) :

    python3 classer_sessions.py                 # rapport Markdown dans le terminal
    python3 classer_sessions.py --csv sessions.csv   # export CSV en plus
    python3 classer_sessions.py --out rapport.md     # écrit le rapport dans un fichier

Aucune dépendance externe : uniquement la bibliothèque standard Python 3.8+.
Le script ne modifie RIEN — il lit seulement ~/.claude/projects/.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

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
            if m in p:
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
        if any(m in p for m in regles["mots"]):
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
    trouves = [t for t, mots in TECHNOS.items() if any(m in p for m in mots)]
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
        s = str(val).replace("Z", "+00:00")
        return datetime.fromisoformat(s)
    except Exception:
        return None


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
                        premier_prompt = extraire_texte(msg)
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
    ap.add_argument("--dir", default=str(Path.home() / ".claude" / "projects"),
                    help="Dossier des projets Claude Code (défaut: ~/.claude/projects)")
    ap.add_argument("--csv", metavar="FICHIER", help="Exporte aussi un CSV")
    ap.add_argument("--out", metavar="FICHIER", help="Écrit le rapport Markdown dans un fichier")
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

    if args.csv:
        ecrire_csv(sessions, args.csv)
        print(f"✅ CSV écrit dans {args.csv}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
