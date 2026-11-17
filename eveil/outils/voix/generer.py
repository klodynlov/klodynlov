"""La voix du jeu, préparée à l'avance avec Supertonic 3, style F5 (décision de l'utilisateur, 17/11/2026).

L'utilisateur a essayé Supertonic 3 pour la voix modèle, choisi le style F5 (mesures + écoute à l'aveugle,
10 contre 6 face à F3) et retenu l'intégration « préparée à l'avance » : tout ce que le petit train et les
livres des sons font dire est rendu ICI, sur le Mac, en petits fichiers audio livrés avec l'app
(`ios/Sources/WordEndAudio/Resources/voix/`). Pas de modèle dans l'app, rien sur le réseau ; ce qui n'a pas
de fichier garde la voix de l'iPad (repli de `ModelVoicePlayer`).

Ce que l'app fait dire (mêmes textes, même découpage que `PracticeView` / `ModelVoicePlayer`) :
- le mot entier (débit « mot »), avec son API sans points ;
- les syllabes du mot modèle (`voice_segments`, débit « syllabe ») et celles des wagons touchés
  (`wagon_segments`) ;
- « Encore ! » / « Again! » ; la phrase d'essai de l'espace des grands.
Pas les sons seuls (fourgon « ch », geste du livre) : Supertonic lit des lettres, pas l'API, et un son
isolé sort faux → voix de l'iPad, et les bruitages du train (« chhh », « sss ») restent.

Contrôle : chaque mot entier passe dans NOTRE détecteur (réglages par défaut, garde « voix d'adulte »
levée : c'est une voix adulte de synthèse) ; un mot à fourgon doit sortir COMPLET (la consonne finale
s'entend), un mot sans fourgon aussi (le bon nombre de syllabes ; un mot de plusieurs syllabes dit d'une
traite peut sortir « syllabe en moins » : accepté si sa consonne finale s'entend). Sinon on essaie d'autres prises (graine
différente), puis les réécritures de `REECRIRE` ; si rien ne passe, pas de fichier (voix de l'iPad) et
le mot va dans `rendu/rejets.json`, à écouter. Les syllabes : une syllabe entendue (pas zéro, pas deux).

Clé d'un fichier (identique côté Swift, `VoiceClips.key`) : « langue|débit|texte|API » (NFC).

Moteur : Supertonic 3 (Supertone), ONNX, révision HF `aafc6e3`, poids OpenRAIL-M ; environnement et
poids de Klody Pocket (`~/KlodyPocket/build/voice-eval/`).

    ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/generer.py          # tout rendre
    python3 eveil/outils/voix/generer.py --check                                            # inventaire ↔ manifeste
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path

ICI = Path(__file__).resolve().parent
EVEIL = ICI.parents[1]
sys.path.insert(0, str(EVEIL / "reference"))
sys.path.insert(0, str(EVEIL / "outils"))

from wordend.lexicon import TargetWord, load_locale, voice_segments, wagon_segments  # noqa: E402

SORTIE = EVEIL / "ios" / "Sources" / "WordEndAudio" / "Resources" / "voix"
REJETS = ICI / "rendu" / "rejets.json"
POCKET = Path.home() / "KlodyPocket" / "build" / "voice-eval"
MODELE = POCKET / "models" / "supertonic-3"
CODE_PY = POCKET / "src" / "supertonic" / "py"
STYLE = "F5"
REVISION = "aafc6e3"
PAS = 8
VITESSE = {"word": 0.95, "syllable": 0.85, "sentence": 1.0}
PRISES = 4
LOCALES = ("fr-FR", "en-US")
LANGUE = {"fr-FR": "fr", "en-US": "en"}

# Réécritures pour Supertonic (il lit des lettres) : texte → essais, dans l'ordre. Pour le mot entier
# seulement ; la clé reste le texte d'origine (c'est ce que l'app demande).
REECRIRE = {
    "fr-FR": {"os": ["osse"], "jus": ["ju"], "vert": ["vèr"], "mur": ["mure"], "tasse": ["tasse."],
              "peau": ["pô"], "chat": ["cha"], "lune": ["lune."]},
    "en-US": {},
}

# Validés À L'OREILLE par l'utilisateur (page `rendu/rejets.html`) : le détecteur hésitait, l'écoute tranche.
# Clé → (texte rendu, prise).
VALIDES_A_L_OREILLE: dict[str, tuple[str, int]] = {}

PHRASES = {
    "fr-FR": [("Encore !", "word"),
              ("Bonjour ! Je suis la voix du petit train. Mi… nou… minouche !", "sentence")],
    "en-US": [("Again!", "word"), ("Hello! I am the voice of the little train. Fi… fish!", "sentence")],
}


@dataclass(frozen=True)
class Enonce:
    locale: str
    pace: str             # word | syllable | sentence (ModelVoicePlayer.Pace)
    text: str
    ipa: str              # « » : sans API
    noyaux: int | None = None    # contrôle : nombre de syllabes attendu (None : pas de contrôle)
    coda: str | None = None

    @property
    def cle(self) -> str:
        return unicodedata.normalize("NFC", f"{self.locale}|{self.pace}|{self.text}|{self.ipa}")

    @property
    def fichier(self) -> str:
        return hashlib.sha1(self.cle.encode("utf-8")).hexdigest()[:16] + ".m4a"


def _mots_des_livres(locale: str) -> list[TargetWord]:
    from livres.mots import TOUS
    fr = locale.startswith("fr")
    out = []
    for m in TOUS:
        texte, api, wagons = (m.fr, m.fr_api, m.fr_wagons) if fr else (m.en, m.en_api, m.en_wagons)
        out.append(TargetWord(id=m.dessin, text=texte, locale=locale, wagons=tuple(wagons), caboose=None,
                              nuclei=len(wagons), coda=None, ipa=api))
    return out


def inventaire() -> list[Enonce]:
    """Tout ce que le petit train et les livres font dire, sans doublon (ordre stable)."""
    vus, out = set(), []

    def ajoute(e: Enonce):
        if e.cle not in vus:
            vus.add(e.cle)
            out.append(e)

    for locale in LOCALES:
        mots = list(load_locale(locale).words) + _mots_des_livres(locale)
        for w in mots:
            if w.ipa:
                ajoute(Enonce(locale, "word", w.text, w.ipa.replace(".", ""), len(w.wagons), w.coda))
            segs = voice_segments(w)
            for k, s in enumerate(segs):
                coda = w.coda if (k == len(segs) - 1 and w.caboose) else None
                ajoute(Enonce(locale, "syllable", s.text, s.ipa or "", 1, coda))
            for s in wagon_segments(w):
                ajoute(Enonce(locale, "syllable", s.text, s.ipa or "", 1, None))
        for texte, pace in PHRASES[locale]:
            ajoute(Enonce(locale, pace, texte, ""))
    return out


# ── Rendu (environnement de Supertonic) ─────────────────────────────────────

def _graine(cle: str, prise: int) -> int:
    return int(hashlib.sha1(f"{cle}#{prise}".encode()).hexdigest()[:8], 16)


def _rogner(w, rate: int):
    """Retire le silence (et le petit souffle) avant et après la voix ; garde 50 ms / 80 ms de marge."""
    import numpy as np
    pas = int(rate * 0.01)
    if len(w) < pas * 3:
        return w
    trames = np.sqrt(np.mean(w[: len(w) // pas * pas].reshape(-1, pas) ** 2, axis=1))
    seuil = max(trames.max() * 0.012, 1e-4)
    actives = np.nonzero(trames > seuil)[0]
    if len(actives) == 0:
        return w
    debut = max(0, actives[0] * pas - int(rate * 0.05))
    fin = min(len(w), (actives[-1] + 1) * pas + int(rate * 0.08))
    w = w[debut:fin].copy()
    crete = float(np.abs(w).max()) or 1.0
    return w * (0.89 / crete)                     # crête à −1 dBFS


def _verdict(w, rate: int, e: Enonce) -> str:
    from wordend.detector import DetectorConfig, Shape, detect
    if e.noyaux is None:
        return "complete"
    cfg = DetectorConfig(adult_f0_max_hz=0.0)    # voix adulte de synthèse : la garde n'a pas lieu d'être
    v = detect([float(x) for x in w], Shape(nuclei=e.noyaux, coda=e.coda), rate=rate, cfg=cfg)
    # Un mot de plusieurs syllabes, dit d'une traite par une voix adulte (voyelles réduites), sort souvent
    # « syllabe en moins » : le détecteur est réglé pour un enfant qui parle lentement. Le découpage est
    # montré syllabe par syllabe juste avant ; on garde le mot si sa consonne finale (fourgon) s'entend.
    if (v.kind.value == "fewer_syllables" and e.pace == "word" and e.noyaux >= 2
            and (e.coda is None or v.coda_heard)):
        return "complete"
    return v.kind.value


def rendre(enonces: list[Enonce]) -> int:
    import numpy as np
    sys.path.insert(0, str(CODE_PY))
    import soundfile as sf
    from helper import load_text_to_speech, load_voice_style

    tts = load_text_to_speech(str(MODELE / "onnx"), False)
    style = load_voice_style([str(MODELE / "voice_styles" / f"{STYLE}.json")])
    rate = tts.sample_rate
    SORTIE.mkdir(parents=True, exist_ok=True)
    manifeste = {"voix": f"Supertonic 3, style {STYLE}", "revision": REVISION, "licence": "OpenRAIL-M",
                 "clips": {}}
    rejets, retouches = [], []
    with tempfile.TemporaryDirectory() as tmp:
        for i, e in enumerate(enonces):
            essais = [e.text] + (REECRIRE.get(e.locale, {}).get(e.text, []) if e.pace == "word" else [])
            garde, dernier = None, None
            if e.cle in VALIDES_A_L_OREILLE:
                texte, prise = VALIDES_A_L_OREILLE[e.cle]
                np.random.seed(_graine(e.cle + "|" + texte, prise))
                wav, dur = tts(texte, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                garde = (_rogner(wav[0, : int(rate * dur[0].item())], rate), texte, prise)
                essais = []
            for texte in essais:
                for prise in range(PRISES):
                    np.random.seed(_graine(e.cle + "|" + texte, prise))
                    wav, dur = tts(texte, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                    w = _rogner(wav[0, : int(rate * dur[0].item())], rate)
                    v = _verdict(w, rate, e)
                    dernier = (texte, prise, v)
                    if v == "complete":
                        garde = (w, texte, prise)
                        break
                if garde:
                    break
            if not garde:
                rejets.append({"cle": e.cle, "dernier": dernier})
                # La première prise du texte d'origine, pour l'écoute (`rendu/rejets.html`).
                np.random.seed(_graine(e.cle + "|" + e.text, 0))
                wav, dur = tts(e.text, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                REJETS.parent.joinpath("rejets").mkdir(parents=True, exist_ok=True)
                brut = Path(tmp) / "r.wav"
                sf.write(str(brut), _rogner(wav[0, : int(rate * dur[0].item())], rate), rate, subtype="PCM_16")
                subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", str(brut),
                                str(REJETS.parent / "rejets" / e.fichier)], check=True, capture_output=True)
                continue
            w, texte, prise = garde
            if texte != e.text or prise:
                retouches.append({"cle": e.cle, "texte": texte, "prise": prise})
            brut = Path(tmp) / "x.wav"
            sf.write(str(brut), w, rate, subtype="PCM_16")
            subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", str(brut),
                            str(SORTIE / e.fichier)], check=True, capture_output=True)
            manifeste["clips"][e.cle] = e.fichier
            if i % 50 == 0:
                print(f"{i}/{len(enonces)}", flush=True)
    # Les fichiers d'un ancien rendu qui ne servent plus.
    gardes = set(manifeste["clips"].values())
    for f in SORTIE.glob("*.m4a"):
        if f.name not in gardes:
            f.unlink()
    (SORTIE / "manifest.json").write_text(json.dumps(manifeste, ensure_ascii=False, indent=0, sort_keys=True),
                                          encoding="utf-8")
    REJETS.parent.mkdir(parents=True, exist_ok=True)
    REJETS.write_text(json.dumps({"rejets": rejets, "retouches": retouches}, ensure_ascii=False, indent=1),
                      encoding="utf-8")
    print(f"✓ {len(manifeste['clips'])} fichiers ; {len(rejets)} sans fichier (voix de l'iPad) ; "
          f"{len(retouches)} retouchés (autre prise ou réécriture)")
    return 0


def verifier() -> int:
    """Chaque clé du manifeste est dans l'inventaire et son fichier existe (les rejets n'ont pas de fichier)."""
    m = json.loads((SORTIE / "manifest.json").read_text(encoding="utf-8"))
    cles = {e.cle for e in inventaire()}
    hors = [k for k in m["clips"] if k not in cles]
    absents = [f for f in m["clips"].values() if not (SORTIE / f).exists()]
    if hors or absents:
        print(f"✗ manifeste périmé ({len(hors)} clés hors inventaire, {len(absents)} fichiers absents)")
        return 1
    print(f"✓ manifeste à jour : {len(m['clips'])} fichiers sur {len(cles)} énoncés")
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(verifier())
    sys.exit(rendre(inventaire()))
