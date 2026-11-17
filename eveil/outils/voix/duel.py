"""Face-à-face de deux voix Supertonic 3 (F3 / F5, 17/11/2026) sur les vrais contenus du niveau 1.

Rend les 62 mots du niveau 1, les syllabes des wagons (niveaux 1-2) et les sons des fourgons dans
deux styles, avec le même réglage que l'essai. Plan : `rendu/plan_f3f5.json` (fait depuis le lexique).

    ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/duel.py rendu/duel F3 F5
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from supertonic_essai import CODE_PY, MODELE


def main(argv: list[str]) -> int:
    sortie, styles = Path(argv[0]), argv[1:]
    plan = json.loads((Path(__file__).parent / "rendu" / "plan_f3f5.json").read_text(encoding="utf-8"))
    sys.path.insert(0, str(CODE_PY))
    import soundfile as sf
    from helper import load_text_to_speech, load_voice_style
    sortie.mkdir(parents=True, exist_ok=True)
    tts = load_text_to_speech(str(MODELE / "onnx"), False)
    fichiers = []
    for st in styles:
        style = load_voice_style([str(MODELE / "voice_styles" / f"{st}.json")])
        tts("Bonjour.", "fr", style, 8, 0.95)
        items = [("mot", m[0]) for m in plan["mots"]] + [("syllabe", s) for s in plan["syllabes"]] + \
                [("son", s) for s in plan["sons"]]
        for i, (fam, texte) in enumerate(items):
            wav, dur = tts(texte, "fr", style, 8, 0.95)
            w = wav[0, : int(tts.sample_rate * dur[0].item())]
            nom = f"{st}_{fam}_{i:03d}.wav"
            sf.write(str(sortie / nom), w, tts.sample_rate, subtype="PCM_16")
            fichiers.append({"style": st, "famille": fam, "texte": texte, "fichier": nom})
        print(st, len(items), flush=True)
    (sortie / "manifeste.json").write_text(json.dumps({"fichiers": fichiers}, ensure_ascii=False, indent=1),
                                           encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
