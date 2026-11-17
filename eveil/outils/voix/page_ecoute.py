"""Page d'écoute de l'essai Supertonic 3 (rendu/ecoute.html) : chaque texte dans chaque voix, côte à côte.

Pas une écoute à l'aveugle : il s'agit de CHOISIR une voix féminine et de juger si Supertonic dit bien
les syllabes seules, les sons seuls et la consonne finale ; la voix système (Flo, Thomas) sert de repère
pour les mots. Sous chaque mot, le verdict de notre détecteur (`verifier_fins.py`). Stdlib uniquement.

    python3 eveil/outils/voix/page_ecoute.py eveil/outils/voix/rendu
"""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path

FAMILLES = {"mot": "Mots entiers (la fin doit s'entendre)", "syllabe": "Syllabes seules (les wagons)",
            "son": "Sons seuls (fourgon, livres des sons)", "phrase": "Phrases du jeu"}
MOTS_APPLE = ["douche", "mouche", "tasse", "os", "jus", "peau", "mur", "vert", "minouche", "saucisse",
              "glace", "princesse", "chat", "lune"]
VERDICT = {"complete": ("✓ fin entendue", "ok"), "unsure": ("? pas sûr", "doute"),
           "fewer_syllables": ("syllabe en moins", "doute"), "missing_final_consonant": ("✗ fin absente", "ko")}


def main(argv: list[str]) -> int:
    d = Path(argv[0])
    m = json.loads((d / "manifeste.json").read_text(encoding="utf-8"))
    fins = json.loads((d / "fins.json").read_text(encoding="utf-8")) if (d / "fins.json").exists() else {}
    styles = sorted({f["style"] for f in m["fichiers"]})
    autres = {s: {t: k for t, k, _ in v["autres"]} for s, v in fins.items()}
    par = {(f["style"], f["famille"], f["texte"]): f for f in m["fichiers"]}
    corps = []
    for fam, titre in FAMILLES.items():
        textes = list(dict.fromkeys(f["texte"] for f in m["fichiers"] if f["famille"] == fam))
        apple = fam == "mot"
        tete = "".join(f"<th>{s}</th>" for s in styles) + ("<th>Flo (système)</th><th>Thomas (système)</th>" if apple else "")
        lignes = []
        for i, t in enumerate(textes):
            cases = []
            for s in styles:
                f = par.get((s, fam, t))
                if not f:
                    cases.append("<td></td>")
                    continue
                v = ""
                if fam == "mot" and s in fins:
                    k = autres[s].get(t, "complete")
                    lab, cls = VERDICT.get(k, (k, "doute"))
                    v = f"<div class='v {cls}'>{lab}</div>"
                src = "m4a/" + f["fichier"].replace(".wav", ".m4a")
                cases.append(f"<td><audio controls preload='none' src='{src}'></audio>{v}</td>")
            if apple:
                j = MOTS_APPLE.index(t)
                for tag in ("Flo", "Thomas"):
                    cases.append(f"<td><audio controls preload='none' src='m4a/{tag}_mot_{j:02d}.m4a'></audio></td>")
            lignes.append(f"<tr><th class='t'>{html.escape(t)}</th>{''.join(cases)}</tr>")
        corps.append(f"<h2>{titre}</h2><div class='scroll'><table><tr><th></th>{tete}</tr>{''.join(lignes)}</table></div>")
    page = f"""<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Essai voix Supertonic 3</title>
<style>
:root{{--bg:#fbfaf7;--fg:#1d1d1f;--mut:#6b6b70;--line:#e3e1dc;--ok:#1e7a3c;--doute:#a35d00;--ko:#b3261e}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151517;--fg:#f2f2f2;--mut:#a0a0a8;--line:#2e2e33;--ok:#5ccf83;--doute:#f0a640;--ko:#ff7a70}}}}
body{{background:var(--bg);color:var(--fg);font:15px/1.45 -apple-system,system-ui,sans-serif;margin:0 auto;max-width:1400px;padding:16px}}
h1{{font-size:22px}} h2{{font-size:17px;margin-top:28px}} p{{color:var(--mut);max-width:900px}}
.scroll{{overflow-x:auto}} table{{border-collapse:collapse}} th,td{{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}}
th.t{{white-space:nowrap}} audio{{width:150px;height:32px}} .v{{font-size:12px;margin-top:2px}} .ok{{color:var(--ok)}} .doute{{color:var(--doute)}} .ko{{color:var(--ko)}}
</style>
<h1>Essai de la voix Supertonic 3 pour le petit train</h1>
<p>Supertonic 3 (ONNX, révision aafc6e3), 5 styles féminins F1–F5, vitesse 0,95, 8 pas ; rendu sur le Mac, rien n'est dans l'app.
Les mots sont aussi dits par deux voix système (Flo, Thomas, avec la prononciation imposée par l'API, comme l'app aujourd'hui).
Sous chaque mot Supertonic : le verdict de notre détecteur de fin de mot (Thomas, voix grave d'adulte, est écarté exprès par le détecteur ;
Flo : 14/14 fins entendues). À écouter surtout : les syllabes seules, les sons seuls, et si la fin des mots (« dou-ch », « ta-ss ») s'entend.</p>
{''.join(corps)}
</html>"""
    (d / "ecoute.html").write_text(page, encoding="utf-8")
    print(d / "ecoute.html")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
