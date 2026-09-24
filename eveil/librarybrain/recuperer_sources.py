"""Déposer les sources en accès libre de la Suite Éveil dans la bibliothèque LibraryBrain.

À lancer EN LOCAL (sur le Mac qui héberge LibraryBrain) : le watcher de
LibraryBrain indexe ensuite automatiquement les PDF et le Markdown déposés.

    python3 eveil/librarybrain/recuperer_sources.py --list
    python3 eveil/librarybrain/recuperer_sources.py --dest "/Volumes/MonDisque/Livres/Santé/Orthophonie/Suite Éveil"
    python3 eveil/librarybrain/recuperer_sources.py --dest … --avec-notes   # + blueprint et état de l'art (Markdown)

Garde-fous (mêmes principes que `fetch_medical_fr.py` de LibraryBrain) :
- un fichier n'est accepté que si le serveur renvoie VRAIMENT un PDF
  (Content-Type `application/pdf` ET signature `%PDF-`) — une page d'erreur HTML
  servie en HTTP 200 ne doit jamais entrer dans la base ;
- un fichier déjà présent n'est jamais retéléchargé ;
- politesse : 1 requête par seconde, User-Agent explicite.
Stdlib uniquement.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "sources.json"
NOTES = [HERE.parents[1] / "docs" / "EVEIL.md", HERE.parents[1] / "docs" / "EVEIL-SOURCES.md"]
USER_AGENT = "LibraryBrain-SuiteEveil/1.0 (usage personnel, indexation locale)"


def load_manifest(path: Path = MANIFEST) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def is_pdf(content_type: str, head: bytes) -> bool:
    return "application/pdf" in content_type.lower() and head.startswith(b"%PDF-")


def fetch_pdf(url: str, timeout: float = 30.0) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()
        ctype = resp.headers.get("Content-Type", "")
    if not is_pdf(ctype, data[:5]):
        raise ValueError(f"pas un PDF (Content-Type « {ctype} »)")
    return data


def run(dest: Path, manifest: dict, fetch=fetch_pdf, pause: float = 1.0) -> dict:
    dest.mkdir(parents=True, exist_ok=True)
    report = {"ok": [], "present": [], "manuel": [], "echec": []}
    for src in manifest["sources"]:
        target = dest / f"{src['id']}.pdf"
        if src["kind"] != "pdf":
            report["manuel"].append(src)
            continue
        if target.exists():
            report["present"].append(src)
            continue
        try:
            target.write_bytes(fetch(src["url"]))
            report["ok"].append(src)
        except (urllib.error.URLError, ValueError, TimeoutError, OSError) as exc:
            report["echec"].append({**src, "erreur": str(exc)})
        time.sleep(pause)
    return report


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--dest", type=Path, help="dossier surveillé par LibraryBrain")
    p.add_argument("--list", action="store_true", help="inventorier sans rien télécharger")
    p.add_argument("--avec-notes", action="store_true", help="copier aussi docs/EVEIL*.md (Markdown indexé)")
    args = p.parse_args(argv)
    manifest = load_manifest()
    if args.list or not args.dest:
        for s in manifest["sources"]:
            print(f"[{s['axis']}] {s['kind']:4s}  {s['id']:40s}  {s['url']}")
        print(f"\n{len(manifest['sources'])} sources — dossier suggéré : {manifest['suggested_folder']}")
        return 0
    report = run(args.dest, manifest)
    if args.avec_notes:
        for note in NOTES:
            shutil.copy2(note, args.dest / note.name)
    print(f"✓ {len(report['ok'])} téléchargées · {len(report['present'])} déjà présentes · "
          f"{len(report['manuel'])} pages à ouvrir à la main · {len(report['echec'])} échecs")
    for s in report["manuel"]:
        print(f"  à ouvrir : {s['title']} — {s['url']}")
    for s in report["echec"]:
        print(f"  échec : {s['id']} — {s['erreur']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
