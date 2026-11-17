"""Essai de la voix Supertonic 3 pour le mot modèle de la Suite Éveil (demande de l'utilisateur, 17/11/2026).

Rend, hors de l'app, ce que la voix du jeu doit dire : des mots entiers (avec leur consonne finale),
les syllabes des wagons (« mi », « nouch »), les sons seuls (fourgon, livres) et quelques phrases,
dans les styles féminins F1 à F5 (choix produit du 28/09 : une voix féminine naturelle). On
écoute ensuite (`ecoute.html`) et on vérifie la consonne finale avec notre propre détecteur
(`verifier_fins.py`).

Moteur : Supertonic 3 (Supertone), ONNX, révision HF `aafc6e3`, poids OpenRAIL-M (voir
`README.md`) ; on réutilise l'environnement et les poids déjà installés pour Klody Pocket
(`~/KlodyPocket/build/voice-eval/`). Rien ne part sur le réseau.

    ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/supertonic_essai.py SORTIE [--styles F1,F2]
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

POCKET = Path.home() / "KlodyPocket" / "build" / "voice-eval"
MODELE = POCKET / "models" / "supertonic-3"
CODE_PY = POCKET / "src" / "supertonic" / "py"

# Ce que le jeu fait dire, par famille (le texte tel qu'on le donne au moteur).
TEXTES = {
    "mot": ["douche", "mouche", "tasse", "os", "jus", "peau", "mur", "vert", "minouche", "saucisse",
            "glace", "princesse", "chat", "lune"],
    "syllabe": ["mi", "nouch", "dou", "sau", "cisse", "prin", "cesse", "pe", "ru"],
    "son": ["ch", "chhh", "s", "sss", "f", "fff", "r", "rrr", "m", "mmm"],
    "phrase": ["À toi ! Dis le mot au petit train.", "Bravo ! Tout le train est parti !",
               "Oh, le petit fourgon est resté en gare ! On l'accroche avec « chhh » ?",
               "Le chat mange la pomme.", "Encore !"],
}


def main(argv: list[str]) -> int:
    sortie = Path(argv[0])
    styles = ["F1", "F2", "F3", "F4", "F5"]
    vitesse, pas = 0.95, 8
    for a in argv[1:]:
        if a.startswith("--styles="):
            styles = a.split("=", 1)[1].split(",")
        if a.startswith("--vitesse="):
            vitesse = float(a.split("=", 1)[1])
    sys.path.insert(0, str(CODE_PY))
    import soundfile as sf
    from helper import load_text_to_speech, load_voice_style

    sortie.mkdir(parents=True, exist_ok=True)
    tts = load_text_to_speech(str(MODELE / "onnx"), False)
    manifeste = {"moteur": "Supertonic 3", "revision": "aafc6e3", "vitesse": vitesse, "pas": pas,
                 "frequence": tts.sample_rate, "fichiers": []}
    for st in styles:
        style = load_voice_style([str(MODELE / "voice_styles" / f"{st}.json")])
        tts("Bonjour.", "fr", style, pas, vitesse)          # chauffe
        for famille, textes in TEXTES.items():
            for i, texte in enumerate(textes):
                t0 = time.perf_counter()
                wav, dur = tts(texte, "fr", style, pas, vitesse)
                calcul = time.perf_counter() - t0
                w = wav[0, : int(tts.sample_rate * dur[0].item())]
                nom = f"{st}_{famille}_{i:02d}.wav"
                sf.write(str(sortie / nom), w, tts.sample_rate, subtype="PCM_16")
                manifeste["fichiers"].append({"style": st, "famille": famille, "texte": texte, "fichier": nom,
                                              "duree_s": round(len(w) / tts.sample_rate, 3),
                                              "calcul_s": round(calcul, 3)})
        print(st, "rendu", flush=True)
    (sortie / "manifeste.json").write_text(json.dumps(manifeste, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
