"""Poser à LibraryBrain les questions sur la méthode de Borel-Maisonny (gestes, progression).

Conseil d'une orthophoniste (06/10/2026) : s'appuyer sur la méthode phonétique et gestuelle de
Borel-Maisonny (un geste par son) et commencer par les mots d'une syllabe. Ce script pose, par
`/ask` (comme la page du même nom), les questions de `QUESTIONS` et consigne, pour chacune, la
réponse générée ET le texte des pages citées, relu en lecture seule dans la base (l'API ne rend
pas le texte des passages ; cf. `interroger.py`, dont on reprend les outils).

    python3 eveil/librarybrain/borel.py              # les questions pas encore répondues
    python3 eveil/librarybrain/borel.py --refaire    # toutes, de nouveau

Sorties LOCALES, jamais poussées (œuvres sous droits, dépôt public) :
`resultats/borel/ask.jsonl`. Ce qui entre dans le dépôt est REFORMULÉ dans nos mots, avec
seulement le livre et la page (`docs/EVEIL-BOREL-MAISONNY.md`). Stdlib uniquement.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sqlite3
import sys
import time
import urllib.error
from pathlib import Path

from interroger import LB_CONFIG, RESULTATS, lire_reglage, passages, poser_ask, verifier_bouclage

SORTIE = RESULTATS / "borel" / "ask.jsonl"

QUESTIONS = (
    ("gestes-voyelles", "Méthode phonétique et gestuelle de Borel-Maisonny : quel geste de la main pour "
     "chaque voyelle (a, o, ou, i, u, é, è, eu, an, on, in, oi, oin) ? Forme de la main, place, mouvement."),
    ("gestes-constrictives", "Méthode phonétique et gestuelle de Borel-Maisonny : quel geste de la main pour "
     "les consonnes ch, s, z, j, f, v ? Forme de la main, place par rapport au visage, mouvement."),
    ("gestes-occlusives", "Méthode phonétique et gestuelle de Borel-Maisonny : quel geste de la main pour "
     "les consonnes p, b, t, d, k, g ? Forme de la main, place, mouvement."),
    ("gestes-sonantes", "Méthode phonétique et gestuelle de Borel-Maisonny : quel geste de la main pour "
     "m, n, gn, l, r et ill ? Forme de la main, place, mouvement."),
    ("ordre-sons", "Selon Borel-Maisonny, dans quel ordre présenter les sons à l'enfant : quelles consonnes "
     "et quelles voyelles d'abord, et pourquoi ?"),
    ("ordre-syllabes", "Selon Borel-Maisonny, comment progresser des syllabes simples aux syllabes inverses, "
     "aux groupes de consonnes et aux mots de plusieurs syllabes ?"),
    ("abandon-gestes", "Selon Borel-Maisonny, à quoi servent les gestes symboliques, dans quel sens les faire "
     "devant l'enfant, et quand les abandonner ?"),
    ("parole-retard", "Selon Borel-Maisonny, chez l'enfant qui a un retard de parole, par quels sons et quels "
     "mots commencer l'éducation de l'articulation ?"),
)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--base", default="http://127.0.0.1:8765")
    p.add_argument("--config", type=Path, default=LB_CONFIG)
    p.add_argument("--timeout", type=float, default=900.0)
    p.add_argument("--refaire", action="store_true", help="reposer aussi les questions déjà répondues")
    a = p.parse_args(argv)

    verifier_bouclage(a.base)
    config = a.config.read_text(encoding="utf-8")
    jeton = lire_reglage(config, "api_token") or ""
    db = lire_reglage(config, "db_path") or str(Path.home() / "library_brain.db")
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=60)
    SORTIE.parent.mkdir(parents=True, exist_ok=True)
    faites = set()
    if SORTIE.exists() and not a.refaire:
        for ligne in SORTIE.read_text(encoding="utf-8").splitlines():
            r = json.loads(ligne)
            if not r.get("erreur"):
                faites.add(r["id"])

    for ident, question in QUESTIONS:
        if ident in faites:
            continue
        t0 = time.monotonic()
        try:
            r = poser_ask(a.base, jeton, question, a.timeout)
        except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
            r = {"reponse": None, "found": False, "confidence": None, "sources_api": [],
                 "explication": None, "types": None, "erreur": f"{type(exc).__name__}: {exc}"}
        ligne = {"id": ident, "question": question, **r,
                 "citations": passages(conn, r["sources_api"], r["reponse"]),
                 "horodatage": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
                 "duree_s": round(time.monotonic() - t0, 1)}
        with SORTIE.open("a", encoding="utf-8") as f:
            f.write(json.dumps(ligne, ensure_ascii=False) + "\n")
        etat = "ERREUR " + r["erreur"][:80] if r["erreur"] else ("trouvé" if r["found"] else "non trouvé")
        titres = sorted({(s.get("title") or "?")[:40] for s in r["sources_api"]})
        print(f"  {ident:<22} {ligne['duree_s']:>6.1f} s  {etat}  {titres}", flush=True)
        time.sleep(3)
    return 0


if __name__ == "__main__":
    sys.exit(main())
