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

Les AUTRES activités (demande de l'utilisateur, 17/11/2026 : « le moteur de voix du petit train pour toutes
les autres activités ») : atelier de coloriage, jeux d'écoute, train des phrases, phrases des livres des sons.
Leur inventaire n'est PAS recopié ici : l'app l'exporte (`VoiceInventoryTests`, Swift) dans
`inventaire_activites.json`, lu par `activites()`. Débit « phrase ». Le train des phrases libre (≈ 10 400 phrases
par langue) n'est pas rendu entier : ses wagons (morceaux) le sont, et l'app enchaîne leurs fichiers
(`ClipJoiner`, miroir `composer.py`). Contrôle des phrases : Whisper (`mlx_whisper`, large-v3-turbo, WER
normalisé, plusieurs prises) ; ce qui reste mauvais n'a pas de fichier et va à l'écoute (`page_activites.py`).

Clé d'un fichier (identique côté Swift, `VoiceClips.key`) : « langue|débit|texte|API » (NFC).

Moteur : Supertonic 3 (Supertone), ONNX, révision HF `aafc6e3`, poids OpenRAIL-M ; environnement et
poids de Klody Pocket (`~/KlodyPocket/build/voice-eval/`).

    ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/generer.py          # tout rendre
    python3 eveil/outils/voix/generer.py --check                                            # inventaire ↔ manifeste
"""
from __future__ import annotations

import hashlib
import json
import re
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
# Écoute du 17/11/2026 : 34 validés sur 37 (non : la syllabe « lit », le mot « loup », la syllabe « rro » de carrosse).
VALIDES_A_L_OREILLE: dict[str, tuple[str, int]] = {
    "fr-FR|syllable|roue|ʁu": ("roue", 0),
    "fr-FR|word|lit|li": ("lit", 0),
    "fr-FR|syllable|bague|baɡ": ("bague", 0),
    "fr-FR|syllable|douch|duʃ": ("douch", 0),
    "fr-FR|syllable|dou|du": ("dou", 0),
    "fr-FR|word|vague|vaɡ": ("vague", 0),
    "fr-FR|syllable|vague|vaɡ": ("vague", 0),
    "fr-FR|syllable|rose|ʁoz": ("rose", 0),
    "fr-FR|syllable|vase|vaz": ("vase", 0),
    "fr-FR|syllable|verre|vɛʁ": ("verre", 0),
    "fr-FR|syllable|vert|vɛʁ": ("vert", 0),
    "fr-FR|syllable|deau|do": ("deau", 0),
    "fr-FR|syllable|vé|ve": ("vé", 0),
    "fr-FR|syllable|dis|di": ("dis", 0),
    "fr-FR|syllable|lise|liz": ("lise", 0),
    "fr-FR|syllable|gui|ɡi": ("gui", 0),
    "fr-FR|syllable|rrosse|ʁɔs": ("rrosse", 0),
    "fr-FR|word|dragon|dʁaɡɔ̃": ("dragon", 0),
    "fr-FR|syllable|dra|dʁa": ("dra", 0),
    "fr-FR|word|arbre|aʁbʁ": ("arbre", 0),
    "fr-FR|syllable|arbre|aʁbʁ": ("arbre", 0),
    "fr-FR|word|crocodile|kʁɔkɔdil": ("crocodile", 0),
    "fr-FR|syllable|dile|dil": ("dile", 0),
    "fr-FR|word|table|tabl": ("table", 0),
    "fr-FR|syllable|table|tabl": ("table", 0),
    "fr-FR|syllable|gre|ɡʁə": ("gre", 0),
    "fr-FR|word|brosse|bʁɔs": ("brosse", 0),
    "fr-FR|syllable|brosse|bʁɔs": ("brosse", 0),
    "fr-FR|syllable|bro|bʁɔ": ("bro", 0),
    "fr-FR|syllable|di|di": ("di", 0),
    "fr-FR|word|Lou|lu": ("Lou", 0),
    "en-US|word|wash|wɑʃ": ("wash", 0),
    "en-US|syllable|cket|kɪt": ("cket", 0),
    "en-US|syllable|splash|splæʃ": ("splash", 0),
}

PHRASES = {
    "fr-FR": [("Encore !", "word"),
              ("Bonjour ! Je suis la voix du petit train. Mi… nou… minouche !", "sentence")],
    "en-US": [("Again!", "word"), ("Hello! I am the voice of the little train. Fi… fish!", "sentence")],
}

# La bulle, dite à voix haute (demande de l'utilisateur, 17/11/2026 : « ce que Lou dit dans la bulle,
# énonce-le : l'enfant peut avoir des difficultés à lire »). Mêmes textes que `PracticeView.bubbleText`
# (messages de `policy.py`, invitation et décompte pour 1 à 5 répétitions).
# Le petit train : « Écoute bien le train… » (une fois par séance), « Bravo ! » quand le mot est réussi
# (décision utilisateur 17/11 : court, le sifflet du train suffit au départ).
BULLE_EN_PLUS = {"fr-FR": ["Écoute bien le train…", "Bravo !"],
                 "en-US": ["Listen to the train…", "Well done!"]}

# Ce qu'on fait LIRE à Supertonic quand le texte affiché le ferait trébucher (la clé reste le texte affiché).
DIRE = {"fr-FR": {"« chhh »": "chhhhhh"}, "en-US": {'"shhh"': "shhhhhh"}}

# ── Les autres activités (17/11/2026) ───────────────────────────────────────
# Écrit par l'app (`eveil/ios/Tests/EveilTrainTests/VoiceInventoryTests.swift`) : activité → textes, par langue.
INVENTAIRE_ACTIVITES = ICI / "inventaire_activites.json"
ASR = ICI / "rendu" / "asr_activites.json"
# Les phrases des activités SANS fichier, et pourquoi (versionné ; lu par `VoiceInventoryTests` : la seule liste
# d'exceptions admise). Clé : « langue|texte ».
EXCEPTIONS = ICI / "exceptions_activites.json"
WHISPER = "mlx-community/whisper-large-v3-turbo"
# Une phrase est gardée si Whisper la retrouve : WER normalisé (casse, accents, ponctuation) ≤ SEUIL_WER ; une
# phrase courte (moins de 5 mots) doit donc être retrouvée exactement. Sinon d'autres prises ; puis à l'écoute.
SEUIL_WER = 0.2
# Débit AAC : les mots et syllabes restent à 64 kbit/s (la fin du mot s'y joue) ; les phrases des activités
# (≈ 3 000 fichiers) passent à 32 kbit/s, en 24 kHz, pour tenir la taille de l'app (voir README).
DEBIT_AAC = {"word": ("aac", 64000), "syllable": ("aac", 64000), "sentence": ("aac@24000", 32000)}


# Ce que Supertonic LIT pour une phrase des activités (la clé reste le texte de l'app). Mesuré le 17/11/2026 sur
# 15 questions (Whisper, 1 prise) : « Le chat dort où ? » tel quel ne passe qu'une fois sur 15 (le « où » final se
# colle au verbe : « d'orot », « volo ») ; « Le chat dort… où ? » 7/15, « Le chat dort, où ? » 4/15. Le petit
# suspense est d'ailleurs une façon naturelle de questionner un enfant de 3 ans. « os » se lit « o » : « osse ».
# « rit » se lit « ré » ou « rite » (12 prises, 3 sujets : 0 phrase retrouvée) ; « ri » : 9 sur 12.
DIRE_PHRASES = {"fr-FR": [(r"\bl'os\b", "l'osse"), (r"\brit\b", "ri"), (r" où \?$", "… où ?")], "en-US": []}
# D'autres façons de le lire, essayées (avec leurs prises) si la première ne passe pas Whisper. « Lou » seul se lit
# « l'eau » ; « Lou ! » passe derrière 3 verbes sur 3 (une prise sur 3).
AUTRES_LECTURES = {"fr-FR": [(r"… où \?$", ", où ?"), (r" quoi \?$", "… quoi ?"), (r"^Lou$", "Lou !")], "en-US": []}
# Ce que Whisper ne peut pas distinguer à l'oreille (même son ; un mot seul n'a pas de contexte) : rendu identique
# des deux côtés avant le WER (motifs sur le texte normalisé). Relevé sur le rendu du 17/11/2026 : « dort » entendu
# « d'or », « boit » → « bois », « vole » → « vol », « Colorie » → « Coloris », « sent » → « sans », « l'oie » → « loi »…
HOMOPHONES = {
    "fr-FR": [(r"\bloup\b", "lou"), (r"\bd or\b", "dort"), (r"\bbois\b", "boit"), (r"\bvol\b", "vole"),
              (r"\bcoloris\b", "colorie"), (r"\bsans\b", "sent"), (r"\bverre\b", "vert"), (r"\blois?\b", "l oie"),
              (r"\bdense\b", "danse"), (r"\b(riz|ri)\b", "rit"), (r"\b(sang|cent)\b", "sent")],
    # « That's sleeps » (le picto touché n'est pas le bon) : le s de « that's » se fond dans le mot suivant.
    "en-US": [(r"\bgray\b", "grey"), (r"\bdoghouse\b", "dog house"), (r"\bdough\b", "doe"), (r"\bmousse\b", "moose"),
              (r"\b(lew|lu)\b", "lou"), (r"\bthat s\b", "that")],
}


def lectures_phrase(locale: str, texte: str) -> list[str]:
    """Les textes à faire lire à Supertonic pour une phrase, dans l'ordre d'essai."""
    t = a_dire(locale, texte)
    for motif, dit in DIRE_PHRASES.get(locale, []):
        t = re.sub(motif, dit, t)
    out = [t]
    for motif, dit in AUTRES_LECTURES.get(locale, []):
        v = re.sub(motif, dit, t)
        if v not in out:
            out.append(v)
    return out


def sans_bourrage(chemin: Path) -> int:
    """Retire l'atome `free` qu'afconvert laisse entre `moov` et `mdat` (≈ 3 Ko de remplissage par fichier : le tiers
    d'une phrase à 32 kbit/s) ; les décalages de `stco`/`co64` reculent d'autant. Le son ne change pas (mêmes paquets
    AAC, même `elst`). Rend le nombre d'octets gagnés (0 si rien à faire)."""
    import struct
    d = bytearray(chemin.read_bytes())
    atomes, i = [], 0
    while i + 8 <= len(d):
        n, t = struct.unpack(">I4s", d[i:i + 8])
        if n < 8 or i + n > len(d):
            return 0                                          # format inattendu : on ne touche à rien
        atomes.append((t, i, n))
        i += n
    noms = [t for t, _, _ in atomes]
    if i != len(d) or b"free" not in noms or b"mdat" not in noms or b"moov" not in noms:
        return 0
    _, f0, fn = atomes[noms.index(b"free")]
    if f0 > atomes[noms.index(b"mdat")][1]:
        return 0

    def corriger(debut: int, fin: int) -> None:
        j = debut
        while j + 8 <= fin:
            n, t = struct.unpack(">I4s", d[j:j + 8])
            if n < 8:
                return
            if t in (b"trak", b"mdia", b"minf", b"stbl"):
                corriger(j + 8, j + n)
            elif t in (b"stco", b"co64"):
                k = struct.unpack(">I", d[j + 12:j + 16])[0]
                taille, fmt = (4, ">I") if t == b"stco" else (8, ">Q")
                for e in range(k):
                    p = j + 16 + e * taille
                    v = struct.unpack(fmt, d[p:p + taille])[0]
                    if v > f0:
                        d[p:p + taille] = struct.pack(fmt, v - fn)
            j += n

    _, m0, mn = atomes[noms.index(b"moov")]
    corriger(m0 + 8, m0 + mn)
    del d[f0:f0 + fn]
    chemin.write_bytes(bytes(d))
    return fn


def activites(locale: str) -> list[tuple[str, str]]:
    """(texte, activité) de toutes les activités hors petit train, dans l'ordre du fichier (activités triées)."""
    if not INVENTAIRE_ACTIVITES.exists():
        return []
    d = json.loads(INVENTAIRE_ACTIVITES.read_text(encoding="utf-8"))
    out: list[tuple[str, str]] = []
    for activite in sorted(d.get(locale, {})):
        out += [(t, activite) for t in d[locale][activite]]
    return out


def mots_wer(texte: str, locale: str = "") -> list[str]:
    """Normalisation pour le WER : minuscules, sans accents ni ponctuation, apostrophes et traits d'union = espace,
    homophones confondus (« loup » = « Lou »)."""
    s = unicodedata.normalize("NFKD", texte.lower().replace("’", "'"))
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^\w' -]", " ", s).replace("-", " ").replace("'", " ")
    s = " ".join(s.split())
    for motif, meme in HOMOPHONES.get(locale, []):
        s = re.sub(motif, meme, s)
    return s.split()


def wer(reference: str, hypothese: str, locale: str = "") -> float:
    r, h = mots_wer(reference, locale), mots_wer(hypothese, locale)
    if not r:
        return 0.0 if not h else 1.0
    d = list(range(len(h) + 1))
    for i in range(1, len(r) + 1):
        p, d[0] = d[0], i
        for j in range(1, len(h) + 1):
            p, d[j] = d[j], min(d[j] + 1, d[j - 1] + 1, p + (r[i - 1] != h[j - 1]))
    return d[-1] / len(r)


def ecouter(w, rate: int, locale: str) -> str:
    """Ce que Whisper entend (large-v3-turbo, MLX, hors ligne : le modèle est dans le cache)."""
    import mlx_whisper
    import numpy as np
    import soxr
    audio = soxr.resample(np.asarray(w, dtype=np.float32), rate, 16000).astype(np.float32)
    return mlx_whisper.transcribe(audio, path_or_hf_repo=WHISPER, language=LANGUE[locale],
                                  condition_on_previous_text=False)["text"].strip()


def bulles(locale: str) -> list[str]:
    from wordend.policy import MESSAGES, REPETITIONS, again_text, invite_text
    out = list(MESSAGES[locale].values()) + BULLE_EN_PLUS[locale]
    out += [invite_text(n, locale) for n in REPETITIONS] + [again_text(n, locale) for n in REPETITIONS]
    return list(dict.fromkeys(out))


def a_dire(locale: str, texte: str) -> str:
    for affiche, dit in DIRE.get(locale, {}).items():
        texte = texte.replace(affiche, dit)
    return texte


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
        for texte in bulles(locale):
            ajoute(Enonce(locale, "sentence", texte, ""))
        for texte, _ in activites(locale):
            ajoute(Enonce(locale, "sentence", texte, ""))
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


# Un wagon seul (« rit », « saute », « Lou ») n'a aucun contexte : Whisper l'entend mal (« ré », « sout », « l'eau »)
# même quand il est bien dit. Un wagon que Whisper refuse seul est donc réécouté LÀ OÙ L'APP LE JOUE : enchaîné
# (`composer`, comme `ClipJoiner`) après un sujet préparé (« le chat rit »), ou, pour un sujet, avant un verbe
# préparé (« Lou dort »). Gardé si Whisper retrouve alors la phrase exactement.
# Trois porteurs de chaque côté : un « rit » mal dit passait derrière « le chat » mais pas derrière « le poisson ».
PORTEURS = {"fr-FR": (("le chat", "le poisson", "la biche"), ("dort", "mange", "danse")),
            "en-US": (("the cat", "the fish", "the deer"), ("sleeps", "eats", "dances"))}


def _sujets(locale: str) -> set[str]:
    """Les wagons « qui ? », lus dans les questions « Que fait le chat ? » de l'inventaire (pas de recopie)."""
    debut, fin = ("Que fait ", " ?") if locale.startswith("fr") else ("What does ", " do?")
    return {t[len(debut):-len(fin)] for t, a in activites(locale)
            if a == "phrases_questions" and t.startswith(debut) and t.endswith(fin)}


def _en_contexte(w, rate: int, e: Enonce) -> tuple[float, str] | None:
    """Le wagon `w` réécouté dans des phrases (un porteur préparé avant, ou après pour un sujet) : (pire WER, ce
    que Whisper entend), ou None s'il manque un porteur préparé."""
    import numpy as np
    import soxr
    from voix import composer
    avants, apres = PORTEURS[e.locale]
    sujet = e.text in _sujets(e.locale)
    clips = json.loads((SORTIE / "manifest.json").read_text(encoding="utf-8"))["clips"]
    pire, entendu = 0.0, []
    for porteur in (apres if sujet else avants):
        f = clips.get(Enonce(e.locale, "sentence", porteur, "").cle)
        if not f or porteur == e.text:
            return None
        x, r = composer.lire(SORTIE / f)
        x = list(map(float, soxr.resample(np.asarray(x, dtype=np.float32), r, rate)))
        morceaux = [list(map(float, w)), x] if sujet else [x, list(map(float, w))]
        phrase = f"{e.text} {porteur}" if sujet else f"{porteur} {e.text}"
        hyp = ecouter(composer.composer(morceaux, rate), rate, e.locale)
        pire = max(pire, wer(phrase, hyp, e.locale))
        entendu.append(hyp)
        if pire > 0:
            break
    return pire, " / ".join(entendu)


def _prises_phrase(tts, style, rate: int, e: Enonce, essais: list[str], asr: dict):
    """Une phrase : des prises (graines différentes) jusqu'à ce que Whisper la retrouve mot pour mot ; sinon
    la meilleure si son WER ≤ SEUIL_WER ; sinon rien (voix de l'iPad, à l'écoute). Supertonic puis Whisper,
    l'un après l'autre (jamais deux calculs lourds en même temps)."""
    import numpy as np
    meilleure, dernier = None, None
    for texte in essais:
        for prise in range(PRISES):
            np.random.seed(_graine(e.cle + "|" + texte, prise))
            wav, dur = tts(texte, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
            w = _rogner(wav[0, : int(rate * dur[0].item())], rate)
            hyp = ecouter(w, rate, e.locale)
            score = wer(e.text, hyp, e.locale)
            dernier = (texte, prise, f"wer {score:.2f} : {hyp}")
            if meilleure is None or score < meilleure[0]:
                meilleure = (score, w, texte, prise, hyp)
            if score == 0:
                break
        if meilleure and meilleure[0] == 0:
            break
    score, w, texte, prise, hyp = meilleure
    asr[e.cle] = {"wer": round(score, 3), "entendu": hyp, "prise": prise, "texte": texte}
    if score > SEUIL_WER and e.text in {t for t, a in activites(e.locale) if a == "phrases_morceaux"}:
        # Un wagon refusé seul : réécouté dans sa phrase, prise après prise.
        for texte in essais:
            for prise in range(PRISES):
                np.random.seed(_graine(e.cle + "|" + texte, prise))
                wav, dur = tts(texte, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                w = _rogner(wav[0, : int(rate * dur[0].item())], rate)
                ctx = _en_contexte(w, rate, e)
                if ctx and ctx[0] == 0:
                    asr[e.cle] = {"wer": round(score, 3), "entendu": hyp, "prise": prise, "texte": texte,
                                  "en_contexte": ctx[1]}
                    return (w, texte, prise), True, (texte, prise, f"en contexte : {ctx[1]}")
                dernier = (texte, prise, f"wer {score:.2f} : {hyp} ; en contexte : {ctx[1] if ctx else '—'}")
    return (w, texte, prise), score <= SEUIL_WER, dernier


def rendre(enonces: list[Enonce]) -> int:
    import numpy as np
    sys.path.insert(0, str(CODE_PY))
    import soundfile as sf
    from helper import load_text_to_speech, load_voice_style

    tts = load_text_to_speech(str(MODELE / "onnx"), False)
    style = load_voice_style([str(MODELE / "voice_styles" / f"{STYLE}.json")])
    rate = tts.sample_rate
    SORTIE.mkdir(parents=True, exist_ok=True)
    ancien, deja, m_ancien = {}, {}, {}
    if (SORTIE / "manifest.json").exists():
        m_ancien = json.loads((SORTIE / "manifest.json").read_text(encoding="utf-8"))
        ancien, deja = m_ancien.get("empreintes", {}), m_ancien.get("clips", {})
    tout = "--tout" in sys.argv
    manifeste = {"voix": f"Supertonic 3, style {STYLE}", "revision": REVISION, "licence": "OpenRAIL-M",
                 "clips": {}, "empreintes": {}}
    rejets, retouches = [], []
    asr = json.loads(ASR.read_text(encoding="utf-8")) if ASR.exists() else {}
    with tempfile.TemporaryDirectory() as tmp:
        for i, e in enumerate(enonces):
            # Déjà rendu (même clé, fichier présent) : on garde tel quel ; `--tout` pour tout refaire.
            if not tout and e.cle in deja and e.cle in ancien and (SORTIE / deja[e.cle]).exists():
                manifeste["clips"][e.cle] = deja[e.cle]
                manifeste["empreintes"][e.cle] = ancien[e.cle]
                continue
            essais = [a_dire(e.locale, e.text)] + (REECRIRE.get(e.locale, {}).get(e.text, []) if e.pace == "word" else [])
            garde, dernier = None, None
            if e.cle in VALIDES_A_L_OREILLE:
                texte, prise = VALIDES_A_L_OREILLE[e.cle]
                np.random.seed(_graine(e.cle + "|" + texte, prise))
                wav, dur = tts(texte, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                garde = (_rogner(wav[0, : int(rate * dur[0].item())], rate), texte, prise)
                essais = []
            meilleure_phrase = None
            if e.pace == "sentence" and essais:
                essais = lectures_phrase(e.locale, e.text)
                meilleure_phrase, bonne, dernier = _prises_phrase(tts, style, rate, e, essais, asr)
                garde = meilleure_phrase if bonne else None
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
                # (Une phrase : sa meilleure prise selon Whisper.)
                if meilleure_phrase is not None:
                    w_ecoute = meilleure_phrase[0]
                else:
                    np.random.seed(_graine(e.cle + "|" + e.text, 0))
                    wav, dur = tts(e.text, LANGUE[e.locale], style, PAS, VITESSE[e.pace])
                    w_ecoute = _rogner(wav[0, : int(rate * dur[0].item())], rate)
                REJETS.parent.joinpath("rejets").mkdir(parents=True, exist_ok=True)
                brut = Path(tmp) / "r.wav"
                sf.write(str(brut), w_ecoute, rate, subtype="PCM_16")
                subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", str(brut),
                                str(REJETS.parent / "rejets" / e.fichier)], check=True, capture_output=True)
                continue
            w, texte, prise = garde
            if texte != e.text or prise:
                retouches.append({"cle": e.cle, "texte": texte, "prise": prise})
            # L'encodeur AAC ne rend pas les mêmes octets deux fois : on ne réencode que si le SON a changé
            # (empreinte du PCM), pour ne pas réécrire 600 fichiers identiques à chaque rendu.
            pcm = (np.clip(w, -1, 1) * 32767).astype("<i2").tobytes()
            empreinte = hashlib.sha1(pcm).hexdigest()[:16]
            if ancien.get(e.cle) != empreinte or not (SORTIE / e.fichier).exists():
                brut = Path(tmp) / "x.wav"
                sf.write(str(brut), w, rate, subtype="PCM_16")
                codec, debit = DEBIT_AAC[e.pace]
                subprocess.run(["afconvert", "-f", "m4af", "-d", codec, "-b", str(debit), str(brut),
                                str(SORTIE / e.fichier)], check=True, capture_output=True)
                if e.pace == "sentence":
                    sans_bourrage(SORTIE / e.fichier)
            manifeste["clips"][e.cle] = e.fichier
            manifeste["empreintes"][e.cle] = empreinte
            if i % 50 == 0:
                print(f"{i}/{len(enonces)}", flush=True)
            if len(manifeste["clips"]) % 200 == 0:
                # Point d'étape (un long rendu de phrases peut être interrompu) : l'ancien manifeste, complété.
                etape = {**manifeste, "clips": {**deja, **manifeste["clips"]},
                         "empreintes": {**ancien, **manifeste["empreintes"]}}
                (SORTIE / "manifest.json").write_text(json.dumps(etape, ensure_ascii=False, indent=0, sort_keys=True),
                                                      encoding="utf-8")
                ASR.parent.mkdir(parents=True, exist_ok=True)
                ASR.write_text(json.dumps(asr, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
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
    ASR.write_text(json.dumps(asr, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    ecrire_exceptions(rejets, asr)
    print(f"✓ {len(manifeste['clips'])} fichiers ; {len(rejets)} sans fichier (voix de l'iPad) ; "
          f"{len(retouches)} retouchés (autre prise ou réécriture)")
    return 0


def ecrire_exceptions(rejets: list[dict], asr: dict) -> None:
    """Les phrases des activités restées sans fichier, avec ce que Whisper a entendu (justification)."""
    des_activites = {Enonce(loc, "sentence", t, "").cle for loc in LOCALES for t, _ in activites(loc)}
    out = {}
    for x in rejets:
        if x["cle"] not in des_activites:
            continue
        loc, _, texte, _ = x["cle"].split("|", 3)
        a = asr.get(x["cle"], {})
        out[f"{loc}|{texte}"] = (f"Whisper entend « {a.get('entendu', '?')} » (WER {a.get('wer', '?')}) après "
                                 f"{len(lectures_phrase(loc, texte))} lecture(s) × {PRISES} prises : voix de l'iPad, "
                                 f"à écouter (page_activites.py)")
    EXCEPTIONS.write_text(json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")


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
