"""Page d'écoute des cas douteux de la voix préparée (`rendu/rejets.html`).

- Les énoncés que le détecteur n'a pas acceptés (aucun fichier : voix de l'iPad) : on les écoute ; ceux qui
  sont bien dits vont dans `generer.VALIDES_A_L_OREILLE` (puis on relance `generer.py`).
- Les mots RÉÉCRITS pour Supertonic (« osse » pour « os ») : le détecteur juge les syllabes et la fin, pas
  les voyelles : on vérifie qu'ils sonnent juste.
Stdlib uniquement.  python3 eveil/outils/voix/page_rejets.py
"""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from voix.generer import REJETS, SORTIE, Enonce  # noqa: E402


def _enonce(cle: str) -> Enonce:
    locale, pace, text, ipa = cle.split("|", 3)
    return Enonce(locale, pace, text, ipa)


def main() -> int:
    r = json.loads(REJETS.read_text(encoding="utf-8"))
    lignes = []
    for i, x in enumerate(r["rejets"], 1):
        e = _enonce(x["cle"])
        lignes.append(f"<tr><td>{i}</td><td><b>{html.escape(e.text)}</b> <small>/{html.escape(e.ipa)}/ · "
                      f"{'mot' if e.pace == 'word' else 'syllabe'} · {e.locale[:2]}</small></td>"
                      f"<td><audio controls preload=none src='rejets/{e.fichier}'></audio></td>"
                      f"<td><label><input type=radio name=q{i} value=O>bien dit</label> "
                      f"<label><input type=radio name=q{i} value=N>non</label></td></tr>")
    n = len(r["rejets"])
    reecrits = [x for x in r["retouches"] if x["cle"].split("|")[2] != x["texte"]]
    lignes2 = []
    for j, x in enumerate(reecrits, n + 1):
        e = _enonce(x["cle"])
        src = Path("..") / ".." / ".." / "ios" / "Sources" / "WordEndAudio" / "Resources" / "voix" / e.fichier
        lignes2.append(f"<tr><td>{j}</td><td><b>{html.escape(e.text)}</b> <small>/{html.escape(e.ipa)}/ · "
                       f"écrit « {html.escape(x['texte'])} » pour Supertonic</small></td>"
                       f"<td><audio controls preload=none src='{src.as_posix()}'></audio></td>"
                       f"<td><label><input type=radio name=q{j} value=O>juste</label> "
                       f"<label><input type=radio name=q{j} value=N>faux</label></td></tr>")
    total = n + len(reecrits)
    page = f"""<!doctype html><html lang=fr><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Voix du train : cas douteux</title>
<style>:root{{--bg:#fbfaf7;--fg:#1d1d1f;--line:#e3e1dc;--mut:#6b6b70}}@media(prefers-color-scheme:dark){{:root{{--bg:#151517;--fg:#eee;--line:#333;--mut:#a0a0a8}}}}
body{{background:var(--bg);color:var(--fg);font:15px -apple-system,system-ui,sans-serif;max-width:900px;margin:auto;padding:16px}}
p{{color:var(--mut)}} td{{border-bottom:1px solid var(--line);padding:6px}} audio{{width:170px;height:32px}}
#r{{font:15px monospace;padding:10px;border:1px solid var(--line);margin-top:12px;word-break:break-all}}</style>
<h1>Voix du train (Supertonic F5) : les cas douteux</h1>
<p>{n} énoncés que notre détecteur n'a pas acceptés : sans ton accord, le jeu les dit avec la voix de l'iPad
(et tout le mot avec, pour garder une seule voix). Coche « bien dit » si c'est juste pour un enfant de 3 ans.
Puis {len(reecrits)} mots réécrits pour Supertonic : vérifie qu'ils sonnent juste. Recopie la ligne du bas dans la conversation.</p>
<h2>Sans fichier</h2><table>{''.join(lignes)}</table>
<h2>Réécrits</h2><table>{''.join(lignes2)}</table><div id=r>—</div>
<script>const n={total};function up(){{let s=[];for(let i=1;i<=n;i++){{const c=document.querySelector('input[name=q'+i+']:checked');s.push(i+(c?c.value:'?'))}}document.getElementById('r').textContent=s.join(' ')}}document.addEventListener('change',up);up()</script></html>"""
    sortie = REJETS.parent / "rejets.html"
    sortie.write_text(page, encoding="utf-8")
    print(sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
