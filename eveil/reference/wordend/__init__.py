"""wordend — détecteur de fin de mot (référence Python stdlib de la suite Éveil).

Détecte, sur l'appareil et sans modèle opaque, si un jeune enfant a produit la
fin d'un mot connu à l'avance (noyaux syllabiques + consonne finale fricative),
avec un principe d'asymétrie : ne jamais affirmer « il manque la fin » sans
preuve d'absence. Voir `eveil/README.md` et `docs/EVEIL.md`.
"""
from .detector import (Analysis, DetectorConfig, Shape, Verdict, VerdictKind, analyze,
                       detect, evaluate)
from .lexicon import TargetWord, custom_word, load, load_locale
from .policy import Feedback, SessionPolicy, feedback_for
from .streaming import StreamingTracker

__all__ = [
    "Analysis", "DetectorConfig", "Shape", "Verdict", "VerdictKind", "analyze", "detect",
    "evaluate", "TargetWord", "custom_word", "load", "load_locale", "Feedback",
    "SessionPolicy", "feedback_for", "StreamingTracker",
]
