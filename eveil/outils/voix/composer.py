"""La phrase libre du train des phrases, composée des fichiers de ses wagons (miroir de `ClipJoiner.swift`).

Demande de l'utilisateur (17/11/2026) : la voix du petit train pour toutes les activités. Le train des phrases
libre compte ≈ 10 400 phrases par langue (30 sujets × verbes × compléments ou lieux) : on ne les rend pas.
Chaque wagon (« le chat », « mange », « la pêche ») a son fichier ; l'app enchaîne ces fichiers en coupant le
silence de début et de fin de chacun et en posant une courte pause (`ClipJoiner`, mêmes constantes qu'ici :
`test_generer` vérifie qu'elles sont identiques).

Ce module sert aussi à MESURER la composition (`mesurer`, à lancer dans l'environnement de Supertonic, après
`generer.py`) : sur un échantillon de phrases libres, il compare
  A  la phrase composée des wagons (ce que fait l'app),
  B  « sujet + verbe » rendu d'un bloc, puis le complément (une autre option, non retenue par défaut),
  W  la phrase rendue entière (la référence, impossible à livrer pour toutes),
avec Whisper (WER), la durée, et une page d'écoute à l'aveugle dans le dossier donné.

    ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/composer.py <dossier de la page>
"""
from __future__ import annotations

import math
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

# Mêmes valeurs que `eveil/ios/Sources/WordEndAudio/ClipJoiner.swift`.
TRAME = 0.010
SEUIL = 0.012
AVANT = 0.020
APRES = 0.040
PAUSE = 0.040
FONDU = 0.004


def zone_parlee(x: list[float], rate: float) -> tuple[int, int]:
    """La partie parlée d'un morceau, avec ses marges (indices d'échantillons) : comme `voicedRange`."""
    pas = max(1, int(rate * TRAME))
    n = len(x) // pas
    if n < 3:
        return 0, len(x)
    energie = [math.sqrt(sum(v * v for v in x[f * pas:(f + 1) * pas]) / pas) for f in range(n)]
    plancher = max(max(energie) * SEUIL, 1e-4)
    actives = [f for f, e in enumerate(energie) if e > plancher]
    if not actives:
        return 0, len(x)
    debut = max(0, actives[0] * pas - int(rate * AVANT))
    fin = min(len(x), (actives[-1] + 1) * pas + int(rate * APRES))
    return debut, fin


def composer(morceaux: list[list[float]], rate: float, pause: float = PAUSE) -> list[float]:
    """Les morceaux à la suite, chacun réduit à sa partie parlée, fondu aux coupures, `pause` entre deux."""
    silence = [0.0] * int(rate * pause)
    rampe = max(1, int(rate * FONDU))
    out: list[float] = []
    for k, m in enumerate(morceaux):
        a, b = zone_parlee(m, rate)
        part = list(m[a:b])
        n = min(rampe, len(part) // 2)
        for i in range(n):
            g = i / n
            part[i] *= g
            part[-1 - i] *= g
        if k:
            out += silence
        out += part
    return out


def lire(chemin: Path) -> tuple[list[float], int]:
    """Un fichier audio (m4a compris : `afconvert` le décode) en échantillons mono."""
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16", str(chemin), str(wav)], check=True,
                       capture_output=True)
        with wave.open(str(wav)) as w:
            rate, n, canaux = w.getframerate(), w.getnframes(), w.getnchannels()
            brut = struct.unpack(f"<{n * canaux}h", w.readframes(n))
    return [v / 32768 for v in brut[::canaux]], rate


def ecrire(chemin: Path, x: list[float], rate: int) -> None:
    with wave.open(str(chemin), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(struct.pack(f"<{len(x)}h", *(int(max(-1, min(1, v)) * 32767) for v in x)))


# ── Mesure (environnement de Supertonic + Whisper) ─────────────────────────────

def _phrases_libres(locale: str) -> list[dict]:
    """L'échantillon fixe de phrases libres exporté par l'app (`VoiceInventoryTests.compositionSample`) :
    niveau, phrase, morceaux, et « sujet + verbe » d'un bloc + le reste."""
    import json
    from voix.generer import INVENTAIRE_ACTIVITES
    return json.loads(INVENTAIRE_ACTIVITES.read_text(encoding="utf-8")).get("_composition", {}).get(locale, [])


def mesurer(dossier: Path) -> int:
    import html
    import json
    import numpy as np
    from voix import generer as g
    sys.path.insert(0, str(g.CODE_PY))
    from helper import load_text_to_speech, load_voice_style
    tts = load_text_to_speech(str(g.MODELE / "onnx"), False)
    style = load_voice_style([str(g.MODELE / "voice_styles" / f"{g.STYLE}.json")])
    rate = tts.sample_rate
    manifeste = json.loads((g.SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
    dossier.mkdir(parents=True, exist_ok=True)

    def rendu(texte: str, locale: str, graine: str) -> list[float]:
        np.random.seed(g._graine(graine, 0))
        wav, dur = tts(texte, g.LANGUE[locale], style, g.PAS, g.VITESSE["sentence"])
        return [float(v) for v in g._rogner(wav[0, : int(rate * dur[0].item())], rate)]

    def clip(locale: str, texte: str) -> list[float] | None:
        f = manifeste.get(g.Enonce(locale, "sentence", texte, "").cle)
        if not f:
            return None
        x, r = lire(g.SORTIE / f)
        if r != rate:                                   # les phrases sont en 24 kHz : on revient au taux du rendu
            import soxr
            x = [float(v) for v in soxr.resample(np.asarray(x, dtype=np.float32), r, rate)]
        return x

    lignes, resultats = [], []
    for locale in g.LOCALES:
        for i, x in enumerate(_phrases_libres(locale)):
            niveau, morceaux, phrase, bloc = x["niveau"], x["morceaux"], x["phrase"], x["bloc"]
            parts = [clip(locale, m) for m in morceaux]
            if any(p is None for p in parts):
                print("sans fichier :", phrase, [m for m, p in zip(morceaux, parts) if p is None])
                continue
            versions = {"A": composer(parts, rate)}
            # B : « Le chat mange » d'un bloc, puis le complément (niveau 1 : la phrase entière, d'un bloc).
            tete = rendu(bloc[0], locale, f"{locale}|bloc|{bloc[0]}")
            versions["B"] = composer([tete] + parts[2:], rate) if len(bloc) > 1 else tete
            versions["W"] = rendu(g.lectures_phrase(locale, phrase)[0], locale, f"{locale}|phrase|{phrase}")
            ligne = {"locale": locale, "niveau": niveau, "phrase": phrase}
            ordre = sorted(versions, key=lambda v: g._graine(phrase + v, 0))   # ordre d'écoute mélangé, fixe
            cellules = []
            for n, v in enumerate(ordre):
                nom = f"{locale[:2]}{i:02d}_{v}.wav"
                ecrire(dossier / nom, versions[v], rate)
                hyp = g.ecouter(np.asarray(versions[v], dtype=np.float32), rate, locale)
                ligne[v] = {"wer": round(g.wer(phrase, hyp, locale), 3), "entendu": hyp,
                            "duree": round(len(versions[v]) / rate, 2)}
                cellules.append(f"<td><audio controls preload=none src='{nom}'></audio><br><small>{'xyz'[n]}</small></td>")
            resultats.append(ligne)
            lignes.append(f"<tr><td>{html.escape(phrase)}</td>{''.join(cellules)}<td><input name=q{len(lignes)} "
                          f"placeholder='la plus naturelle : x, y ou z'></td></tr>")
            print(ligne, flush=True)
    (dossier / "mesures.json").write_text(json.dumps(resultats, ensure_ascii=False, indent=1), encoding="utf-8")
    page = f"""<!doctype html><html lang=fr><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Phrase libre : composée ou entière</title>
<style>:root{{--bg:#fbfaf7;--fg:#1d1d1f;--line:#e3e1dc}}@media(prefers-color-scheme:dark){{:root{{--bg:#151517;--fg:#eee;--line:#333}}}}
body{{background:var(--bg);color:var(--fg);font:15px -apple-system,system-ui,sans-serif;max-width:1000px;margin:auto;padding:16px}}
td{{border-bottom:1px solid var(--line);padding:6px;vertical-align:top}} audio{{width:150px;height:32px}}</style>
<h1>La phrase libre du train des phrases</h1>
<p>Trois versions par phrase, dans un ordre mélangé (x, y, z) : la phrase composée de ses wagons, « sujet + verbe »
d'un bloc puis le complément, et la phrase rendue entière. Écoute à l'aveugle ; la clé est dans <code>mesures.json</code>
(et l'ordre se retrouve avec <code>composer.py</code>), pas dans la page.</p>
<table>{''.join(lignes)}</table></html>"""
    (dossier / "index.html").write_text(page, encoding="utf-8")
    print(dossier / "index.html")
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    sys.exit(mesurer(Path(sys.argv[1]) if len(sys.argv) > 1 else Path("rendu/composition")))
