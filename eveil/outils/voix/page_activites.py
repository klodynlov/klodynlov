"""Page d'écoute des phrases douteuses des activités (coloriage, jeux d'écoute, train des phrases, livres).

Après `generer.py` : Whisper a jugé chaque phrase (`rendu/asr_activites.json`).
- « Sans fichier » : Whisper ne l'a pas retrouvée, même avec 4 prises et d'autres lectures ; l'app la dit avec la
  voix de l'iPad (et une phrase libre qui contient ce wagon aussi, entière). Bien dite ? → `generer.VALIDES_A_L_OREILLE`
  (clé → (texte lu, prise), donnés sur la ligne) puis relancer `generer.py`.
- « Gardées de justesse » : gardées avec un WER > 0 (≤ `SEUIL_WER`) : on vérifie à l'oreille.
- « Lues autrement » : quelques phrases lues avec un petit suspense (« Le chat dort… où ? ») pour Supertonic.
La page et ses fichiers vont dans le dossier donné (par défaut `rendu/activites/`). Stdlib uniquement.

    python3 eveil/outils/voix/page_activites.py [dossier]
"""
from __future__ import annotations

import html
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from voix.generer import ASR, REJETS, SORTIE, Enonce, activites, LOCALES  # noqa: E402


def _ligne(i: int, e: Enonce, src: str, note: str, choix: tuple[str, str]) -> str:
    return (f"<tr><td>{i}</td><td><b>{html.escape(e.text)}</b> <small>· {e.locale[:2]} · {html.escape(note)}</small></td>"
            f"<td><audio controls preload=none src='{src}'></audio></td>"
            f"<td><label><input type=radio name=q{i} value=O>{choix[0]}</label> "
            f"<label><input type=radio name=q{i} value=N>{choix[1]}</label></td></tr>")


def main(dossier: Path) -> int:
    asr = json.loads(ASR.read_text(encoding="utf-8")) if ASR.exists() else {}
    rejets = json.loads(REJETS.read_text(encoding="utf-8"))["rejets"] if REJETS.exists() else []
    manifeste = json.loads((SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
    activite = {Enonce(loc, "sentence", t, "").cle: a for loc in LOCALES for t, a in activites(loc)}
    dossier.mkdir(parents=True, exist_ok=True)
    (dossier / "audio").mkdir(exist_ok=True)

    def copie(source: Path) -> str:
        shutil.copy2(source, dossier / "audio" / source.name)
        return f"audio/{source.name}"

    sections, n = [], 0
    lignes = []
    for x in rejets:
        if x["cle"] not in activite:
            continue
        loc, pace, text, ipa = x["cle"].split("|", 3)
        e = Enonce(loc, pace, text, ipa)
        a = asr.get(e.cle, {})
        n += 1
        lignes.append(_ligne(n, e, copie(REJETS.parent / "rejets" / e.fichier),
                             f"{activite[e.cle]} · Whisper a entendu « {a.get('entendu', '?')} » (WER {a.get('wer', '?')})"
                             f" · lu « {a.get('texte', text)} », prise {a.get('prise', 0)}", ("bien dit", "non")))
    sections.append(("Sans fichier (voix de l'iPad)", lignes))
    lignes = []
    for cle, a in sorted(asr.items()):
        if cle in activite and cle in manifeste and a["wer"] > 0:
            loc, pace, text, ipa = cle.split("|", 3)
            e = Enonce(loc, pace, text, ipa)
            n += 1
            lignes.append(_ligne(n, e, copie(SORTIE / manifeste[cle]),
                                 f"{activite[cle]} · entendu « {a['entendu']} » (WER {a['wer']})", ("juste", "faux")))
    sections.append(("Gardées de justesse", lignes))
    lignes = []
    autrement = [(c, a) for c, a in sorted(asr.items()) if c in activite and c in manifeste
                 and a["texte"] != c.split("|", 3)[2]]
    for cle, a in autrement[:: max(1, len(autrement) // 12)][:12]:
        loc, pace, text, ipa = cle.split("|", 3)
        e = Enonce(loc, pace, text, ipa)
        n += 1
        lignes.append(_ligne(n, e, copie(SORTIE / manifeste[cle]), f"lu « {a['texte']} »", ("naturel", "bizarre")))
    sections.append((f"Lues autrement ({len(autrement)} en tout, 12 témoins)", lignes))

    corps = "".join(f"<h2>{html.escape(t)} — {len(l)}</h2><table>{''.join(l)}</table>" for t, l in sections)
    page = f"""<!doctype html><html lang=fr><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Voix des activités : à écouter</title>
<style>:root{{--bg:#fbfaf7;--fg:#1d1d1f;--line:#e3e1dc;--mut:#6b6b70}}@media(prefers-color-scheme:dark){{:root{{--bg:#151517;--fg:#eee;--line:#333;--mut:#a0a0a8}}}}
body{{background:var(--bg);color:var(--fg);font:15px -apple-system,system-ui,sans-serif;max-width:960px;margin:auto;padding:16px}}
p,small{{color:var(--mut)}} td{{border-bottom:1px solid var(--line);padding:6px}} audio{{width:170px;height:32px}}
#r{{font:15px monospace;padding:10px;border:1px solid var(--line);margin-top:12px;word-break:break-all}}</style>
<h1>Voix des activités (Supertonic F5) : à écouter</h1>
<p>Coloriage, jeux d'écoute, train des phrases, livres des sons. Whisper (large-v3-turbo) a écouté chaque phrase.
Coche, puis recopie la ligne du bas dans la conversation.</p>{corps}<div id=r>—</div>
<script>const n={n};function up(){{let s=[];for(let i=1;i<=n;i++){{const c=document.querySelector('input[name=q'+i+']:checked');s.push(i+(c?c.value:'?'))}}document.getElementById('r').textContent=s.join(' ')}}document.addEventListener('change',up);up()</script></html>"""
    (dossier / "index.html").write_text(page, encoding="utf-8")
    print(dossier / "index.html", f"({n} à écouter)")
    return 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else ASR.parent / "activites"))
