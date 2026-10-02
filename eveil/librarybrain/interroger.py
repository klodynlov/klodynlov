"""Poser les 33 questions de `questions.md` à LibraryBrain, comme le feraient ses pages.

Applique la phase 1 du protocole (COMPARAISON.md) dans des conditions identiques pour
chaque question :

- `/ask`       → `GET /api/ask/stream?q=…&format=explication` (ce qu'envoie la page `/ask` :
                 format par défaut, sans catégorie ni niveau, un fil neuf par question) ;
- `/consensus` → `POST /api/consensus {"query": …, "category": null}` (onglet Consensus
                 de `/studio`, catégorie « toutes »).

L'API ne renvoie que titre, auteur et page des sources, pas le texte : le script relit donc
les **passages** dans la base de LibraryBrain, ouverte en LECTURE SEULE (`mode=ro`), pour la
page de chaque source et pour chaque page citée dans la réponse (`[Titre, p.N]`). C'est
d'après ces passages que l'on code (phase 2), jamais d'après le résumé généré.

    python3 eveil/librarybrain/interroger.py --passe P0
    python3 eveil/librarybrain/interroger.py --passe P1 --questions 1-18
    python3 eveil/librarybrain/interroger.py --passe P0b      # contrôle après redémarrage, avant P1

Sorties LOCALES, jamais poussées (extraits d'ouvrages sous droits, dépôt public) :
`resultats/reponses.jsonl` (une ligne par question × passe ; la dernière fait foi) et
`resultats/<passe>-meta.json` (version, modèle et réglages de LibraryBrain, taille de l'index).
Relancer reprend là où l'on s'était arrêté : une question déjà répondue sans erreur n'est
pas reposée.

Le jeton d'API est lu dans la configuration de LibraryBrain au moment de l'appel ; il n'est
ni affiché ni écrit, et n'est envoyé qu'à une adresse de bouclage (127.0.0.1, localhost).
Chaque question posée est journalisée par LibraryBrain (`query_log`), comme depuis le
navigateur : c'est ce qui alimente la page `/gaps`. Stdlib uniquement.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sqlite3
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
QUESTIONS = HERE / "questions.md"
RESULTATS = HERE / "resultats"
LB_CONFIG = Path.home() / "library-brain" / "config.yaml"
BOUCLAGE = {"127.0.0.1", "localhost", "::1"}

# Réglages relevés dans le rapport (liste blanche : le jeton n'en fait jamais partie).
REGLAGES = (
    "llm_provider", "llm_base_url", "ollama_model", "code_model", "embed_provider",
    "embed_st_model", "rerank_model", "rag_top_k", "rag_min_books", "rag_min_rerank",
    "rag_min_relevance", "rag_cross_lingual", "rag_query_lang", "rag_query_rewrite",
    "book_routing", "book_routing_k", "llm_num_predict", "llm_timeout", "web_search_enabled",
)


# ── Questions ────────────────────────────────────────────────────────────────

def lire_questions(texte: str) -> list[dict]:
    """Les lignes `| n | … |` de questions.md, avec la page de leur section ou de leur colonne."""
    out, page_section = [], None
    for ligne in texte.splitlines():
        if ligne.startswith("## "):
            m = re.search(r"`(/ask|/consensus)`", ligne)
            page_section = m.group(1) if m else None
            continue
        if not re.match(r"^\| \d+ \|", ligne):
            continue
        cells = [c.strip() for c in ligne.strip().strip("|").split("|")]
        if len(cells) == 5:                    # témoin : # | Page | Question | Proposition | Id
            num, page, question, proposition, ids = cells
            page = page.strip("`")
        elif len(cells) == 3:                  # # | Question (ou Thème) | Ferme
            (num, question, ids), page, proposition = cells, page_section, None
        else:
            raise ValueError(f"ligne de question inattendue : {ligne!r}")
        if page not in ("/ask", "/consensus"):
            raise ValueError(f"Q{num} : page inconnue {page!r}")
        out.append({"q": int(num), "page": page, "question": question,
                    "proposition": proposition, "ids": re.findall(r"\b[A-F]\d+[a-z]?\b", ids)})
    return out


def selection(spec: str | None, nums: list[int]) -> list[int]:
    """« 1-18 », « 3,7,19-21 » ou rien (toutes)."""
    if not spec:
        return nums
    voulu: set[int] = set()
    for part in spec.split(","):
        a, _, b = part.strip().partition("-")
        voulu.update(range(int(a), int(b or a) + 1))
    return [n for n in nums if n in voulu]


# ── Configuration de LibraryBrain ────────────────────────────────────────────

def lire_reglage(config: str, cle: str) -> str | None:
    """Valeur scalaire d'une clé de premier niveau du config.yaml (sans dépendance YAML)."""
    m = re.search(rf"^{re.escape(cle)}:[ \t]*(.*?)[ \t]*(?:#.*)?$", config, re.M)
    if not m:
        return None
    return m.group(1).strip().strip("'\"") or None


def verifier_bouclage(base: str) -> None:
    hote = urllib.parse.urlsplit(base).hostname
    if hote not in BOUCLAGE:
        raise SystemExit(f"refus : {base} n'est pas une adresse de bouclage, le jeton n'y sera pas envoyé")


# ── Appels HTTP ──────────────────────────────────────────────────────────────

def evenements_sse(lignes) -> list[dict]:
    """Les événements `data: {…}` d'un flux SSE (lignes en bytes ou str)."""
    out = []
    for brute in lignes:
        ligne = brute.decode("utf-8") if isinstance(brute, bytes) else brute
        ligne = ligne.strip()
        if ligne.startswith("data:"):
            try:
                out.append(json.loads(ligne[5:].strip()))
            except json.JSONDecodeError:
                out.append({"type": "illisible", "brut": ligne[5:].strip()})
    return out


def resume_flux(evts: list[dict]) -> dict:
    meta = next((e for e in evts if e.get("type") == "meta"), {})
    erreurs = [e for e in evts if e.get("type") == "error"]
    reponse = "".join(e.get("text", "") for e in evts if e.get("type") == "token")
    return {
        "reponse": reponse or None,
        "found": bool(meta.get("found")) and not any(e.get("type") == "not_found" for e in evts),
        "confidence": meta.get("confidence"),
        "sources_api": meta.get("sources", []),
        "explication": meta.get("explanation"),
        "types": [e.get("type") for e in evts if e.get("type") != "token"],
        "erreur": json.dumps(erreurs[0], ensure_ascii=False) if erreurs else None,
    }


def poser_ask(base: str, jeton: str, question: str, timeout: float) -> dict:
    url = f"{base}/api/ask/stream?" + urllib.parse.urlencode({"q": question, "format": "explication"})
    req = urllib.request.Request(url, headers={"X-API-Token": jeton, "Accept": "text/event-stream"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resume_flux(evenements_sse(resp))


def poser_consensus(base: str, jeton: str, question: str, timeout: float) -> dict:
    corps = json.dumps({"query": question, "category": None}).encode("utf-8")
    req = urllib.request.Request(f"{base}/api/consensus", data=corps, method="POST",
                                 headers={"X-API-Token": jeton, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return {"reponse": data.get("answer"), "found": bool(data.get("found")),
            "confidence": data.get("confidence"), "sources_api": data.get("sources", []),
            "explication": None, "types": None, "erreur": None}


# ── Passages cités ───────────────────────────────────────────────────────────

CROCHETS = re.compile(r"\[([^\[\]]{2,400})\]")
PAGE = re.compile(r"p\.\s*(\d+)")


def pages_citees(reponse: str | None) -> list[tuple[str, int]]:
    """Les renvois `[Source 3, p.72 ; Titre, Auteur, p.N]` d'une réponse : (ce qui précède « p. », N).

    Le prompt de LibraryBrain numérote ses passages `[SOURCE i] "Titre" (p.X)` après les avoir
    réordonnés : « Source i » ne désigne donc pas la i-ème source de l'API, mais la page X est
    exactement celle du passage lu par le modèle.
    """
    out = []
    for m in CROCHETS.finditer(reponse or ""):
        for part in m.group(1).split(";"):
            pm = PAGE.search(part)
            if pm:
                out.append((part[:pm.start()].strip(" ,"), int(pm.group(1))))
    return out


def _norme(s: str) -> str:
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def source_de(citation: str, sources: list[dict]) -> dict | None:
    """La source dont le titre ouvre la citation (ou l'inverse, titres tronqués)."""
    c = _norme(citation)
    for s in sources:
        t = _norme(s.get("title") or "")
        if t and (c.startswith(t[:40]) or t.startswith(c[:40])):
            return s
    return None


def passages(conn: sqlite3.Connection, sources: list[dict], reponse: str | None) -> list[dict]:
    """Pour chaque source, et chaque page citée, le livre et le texte des passages de la page.

    Rôles : `source` (page de la source selon l'API) ; `citée` (renvoi nommant le livre, ou
    « Source i, p.X » quand une source de l'API est à la page X) ; `citée-proche` (sinon : livres
    sources dont la page API est à 10 pages au plus de X et qui ont un passage en X — l'API ne
    donne que le premier passage de chaque livre). Un renvoi que rien ne résout n'ajoute rien.
    """
    livres = [s for s in sources if s.get("book_id") is not None]
    voulu: list[tuple[int, int | None, str]] = [(s["book_id"], s.get("page"), "source") for s in livres]
    for texte, page in pages_citees(reponse):
        s = source_de(texte, livres)
        exactes = [s] if s else [c for c in livres if c.get("page") == page]
        if exactes:
            voulu.extend((c["book_id"], page, "citée") for c in exactes)
        else:
            voulu.extend((c["book_id"], page, "citée-proche") for c in livres
                         if c.get("page") is not None and abs(c["page"] - page) <= 10)
    out, vus = [], set()
    for book_id, page, role in voulu:
        if (book_id, page) in vus:
            continue
        if page is None:
            lignes = []
        else:
            lignes = conn.execute("SELECT id, chunk_index, text FROM chunks WHERE book_id = ? AND page = ? "
                                  "ORDER BY chunk_index", (book_id, page)).fetchall()
        if role == "citée-proche" and not lignes:
            continue
        vus.add((book_id, page))
        livre = conn.execute("SELECT title, author, year, file_path FROM books WHERE id = ?",
                             (book_id,)).fetchone()
        out.append({"book_id": book_id, "page": page, "role": role,
                    "titre": livre[0] if livre else None, "auteur": livre[1] if livre else None,
                    "annee": livre[2] if livre else None, "fichier": livre[3] if livre else None,
                    "passages": [{"chunk_id": i, "chunk_index": k, "texte": t} for i, k, t in lignes]})
    return out


# ── Relevé de version ────────────────────────────────────────────────────────

def _sortie(cmd: list[str]) -> str | None:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=20, check=True).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None


def releve(config_path: Path, config: str, conn: sqlite3.Connection, base: str) -> dict:
    depot = config_path.parent
    port = urllib.parse.urlsplit(base).port or 80
    pid = (_sortie(["lsof", "-t", f"-iTCP:{port}", "-sTCP:LISTEN"]) or "").split("\n")[0] or None
    porcelaine = _sortie(["git", "-C", str(depot), "status", "--porcelain"])
    return {
        "librarybrain_commit": _sortie(["git", "-C", str(depot), "rev-parse", "HEAD"]),
        "librarybrain_fichiers_modifies": None if porcelaine is None else len(porcelaine.splitlines()),
        "serveur_pid": pid,
        "serveur_demarre": _sortie(["ps", "-o", "lstart=", "-p", pid]) if pid else None,
        "reglages": {k: lire_reglage(config, k) for k in REGLAGES},
        "livres": conn.execute("SELECT COUNT(*) FROM books").fetchone()[0],
        "passages": conn.execute("SELECT COUNT(*) FROM chunks").fetchone()[0],
    }


# ── Programme ────────────────────────────────────────────────────────────────

def deja_repondues(sortie: Path, passe: str) -> set[int]:
    faites: dict[int, bool] = {}
    if sortie.exists():
        for ligne in sortie.read_text(encoding="utf-8").splitlines():
            r = json.loads(ligne)
            if r.get("passe") == passe:
                faites[r["q"]] = not r.get("erreur")       # la dernière ligne fait foi
    return {q for q, ok in faites.items() if ok}


def recalculer_citations(sortie: Path, passe: str, conn: sqlite3.Connection) -> int:
    """Recalcule le seul champ dérivé `citations` des lignes d'une passe, sans reposer de question."""
    lignes = [json.loads(ligne) for ligne in sortie.read_text(encoding="utf-8").splitlines()]
    n = 0
    for r in lignes:
        if r.get("passe") == passe:
            r["citations"] = passages(conn, r.get("sources_api") or [], r.get("reponse"))
            n += 1
    tmp = sortie.with_suffix(".tmp")
    tmp.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in lignes), encoding="utf-8")
    tmp.replace(sortie)
    return n


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--passe", required=True, choices=["P0", "P0b", "P1"],
                   help="P0 : bibliothèque telle quelle ; P0b : idem après redémarrage du serveur "
                        "(contrôle de l'effet du code, écart déclaré) ; P1 : + PDF de sources.json")
    p.add_argument("--questions", help="sélection, ex. « 1-18 » ou « 3,19-21 » (défaut : toutes)")
    p.add_argument("--base", default="http://127.0.0.1:8765")
    p.add_argument("--config", type=Path, default=LB_CONFIG, help="config.yaml de LibraryBrain")
    p.add_argument("--sortie", type=Path, default=RESULTATS / "reponses.jsonl")
    p.add_argument("--timeout", type=float, default=900.0, help="secondes sans octet reçu")
    p.add_argument("--pause", type=float, default=5.0, help="secondes entre deux questions")
    p.add_argument("--recalculer-citations", action="store_true",
                   help="relire les passages des réponses déjà consignées de la passe, sans rien reposer")
    a = p.parse_args(argv)

    verifier_bouclage(a.base)
    config = a.config.read_text(encoding="utf-8")
    jeton = lire_reglage(config, "api_token") or ""
    db = lire_reglage(config, "db_path") or str(Path.home() / "library_brain.db")
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=60)
    if a.recalculer_citations:
        print(f"{a.passe} : citations recalculées pour {recalculer_citations(a.sortie, a.passe, conn)} ligne(s)")
        return 0

    questions = lire_questions(QUESTIONS.read_text(encoding="utf-8"))
    a.sortie.parent.mkdir(parents=True, exist_ok=True)
    faites = deja_repondues(a.sortie, a.passe)
    a_poser = [q for q in questions if q["q"] in selection(a.questions, [x["q"] for x in questions])
               and q["q"] not in faites]

    meta_path = a.sortie.parent / f"{a.passe}-meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {"passe": a.passe, "lots": []}
    lot = {"debut": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
           "questions": [q["q"] for q in a_poser], **releve(a.config, config, conn, a.base)}
    print(f"{a.passe} : {len(a_poser)} question(s) à poser, {len(faites)} déjà faite(s) — "
          f"{lot['livres']} livres, {lot['passages']} passages indexés")

    for i, q in enumerate(a_poser):
        t0 = time.monotonic()
        try:
            poser = poser_ask if q["page"] == "/ask" else poser_consensus
            r = poser(a.base, jeton, q["question"], a.timeout)
        except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
            r = {"reponse": None, "found": False, "confidence": None, "sources_api": [],
                 "explication": None, "types": None, "erreur": f"{type(exc).__name__}: {exc}"}
        ligne = {
            "q": q["q"], "passe": a.passe, "page": q["page"], "question": q["question"],
            "proposition": q["proposition"], "ids": q["ids"], **r,
            "citations": passages(conn, r["sources_api"], r["reponse"]),
            # Phase 2 (codage), remplie plus tard d'après les passages :
            "couverture": None, "position": None, "sources": None, "verifie": None,
            "horodatage": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
            "duree_s": round(time.monotonic() - t0, 1),
        }
        with a.sortie.open("a", encoding="utf-8") as f:
            f.write(json.dumps(ligne, ensure_ascii=False) + "\n")
        etat = "ERREUR " + r["erreur"][:80] if r["erreur"] else ("trouvé" if r["found"] else "non trouvé")
        print(f"  Q{q['q']:>2} {q['page']:<10} {ligne['duree_s']:>6.1f} s  {etat}  "
              f"({len(r['sources_api'])} sources)", flush=True)
        if i + 1 < len(a_poser):
            time.sleep(a.pause)

    lot["fin"] = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    meta["lots"].append(lot)
    meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
