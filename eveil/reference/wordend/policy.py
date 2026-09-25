"""Politique de feedback et de séance — la pédagogie, séparée de l'acoustique.

Le détecteur *mesure* ; cette couche *décide quoi montrer* à un enfant de 3 ans.
Règles encodées (et testées) :

1. On ne **montre du doigt** une partie manquante (le fourgon décroché) que sur
   un verdict MISSING_FINAL_CONSONANT — jamais sur INCERTAIN.
2. INCERTAIN / AUCUNE PAROLE ⇒ messages **neutres** (« on le redit ensemble ? »),
   jamais « ce n'est pas ça ».
3. Syllabe(s) manquante(s) ⇒ on **ne désigne pas** de wagon précis : en français,
   l'enfant tronque souvent la syllabe *initiale* (« nane » pour « banane »),
   donc « allumer le premier wagon » serait souvent faux. On **remodèle** le mot
   entier, wagon par wagon.
4. Pas de boucle d'échec : au-delà de `max_attempts`, on félicite l'effort et on
   passe au mot suivant.
5. Séances courtes, fin ritualisée, budget quotidien réglable par le parent.
"""
from __future__ import annotations

from dataclasses import dataclass

from .detector import Verdict, VerdictKind


@dataclass(frozen=True)
class Feedback:
    lit_wagons: tuple[bool, ...]     # wagons (syllabes) allumés
    caboose: str                     # hooked | pointed | waiting | none (mot sans fourgon)
    mascot: str                      # celebrate | point_caboose | model_word | listen_again | invite
    message_key: str                 # clé de texte localisée (FR/EN), cf. MESSAGES
    advance: bool                    # passer au mot suivant
    counts_as_attempt: bool


# Clés autorisées quand le détecteur n'est PAS sûr : aucune ne désigne d'erreur.
NEUTRAL_KEYS = frozenset({"listen_again", "invite", "effort_next", "model_slowly"})
MAX_ATTEMPTS = 3

MESSAGES = {
    "fr-FR": {
        "bravo": "Bravo ! Tout le train est parti !",
        "hook_caboose": "Oh, le petit fourgon est resté en gare ! On l'accroche avec « chhh » ?",
        "model_slowly": "Écoute bien le train : on le dit doucement, ensemble.",
        "listen_again": "Je n'ai pas bien entendu. On le redit ensemble ?",
        "invite": "À toi ! Dis le mot au petit train.",
        "effort_next": "Merci d'avoir bien essayé ! On va voir le mot suivant.",
    },
    "en-US": {
        "bravo": "Hooray! The whole train is leaving!",
        "hook_caboose": "Oh, the little caboose stayed at the station! Let's hook it with \"shhh\"?",
        "model_slowly": "Listen to the train: let's say it slowly, together.",
        "listen_again": "I didn't hear it well. Shall we say it again together?",
        "invite": "Your turn! Tell the word to the little train.",
        "effort_next": "Thanks for trying so hard! Let's see the next word.",
    },
}


def feedback_for(verdict: Verdict, wagons: int, has_caboose: bool, attempt: int,
                 max_attempts: int = MAX_ATTEMPTS) -> Feedback:
    """`attempt` commence à 1 pour la première tentative sur ce mot."""
    last_try = attempt >= max_attempts
    all_lit = tuple([True] * wagons)
    none_lit = tuple([False] * wagons)
    waiting = "waiting" if has_caboose else "none"
    k = verdict.kind

    if k is VerdictKind.COMPLETE:
        return Feedback(all_lit, "hooked" if has_caboose else "none", "celebrate", "bravo",
                        advance=True, counts_as_attempt=True)
    if k is VerdictKind.MISSING_FINAL_CONSONANT and has_caboose:
        if last_try:
            return Feedback(all_lit, "waiting", "model_word", "effort_next",
                            advance=True, counts_as_attempt=True)
        return Feedback(all_lit, "pointed", "point_caboose", "hook_caboose",
                        advance=False, counts_as_attempt=True)
    if k is VerdictKind.FEWER_SYLLABLES:
        return Feedback(none_lit, waiting, "model_word",
                        "effort_next" if last_try else "model_slowly",
                        advance=last_try, counts_as_attempt=True)
    if k is VerdictKind.NO_SPEECH:
        return Feedback(none_lit, waiting, "invite",
                        "effort_next" if last_try else "invite",
                        advance=last_try, counts_as_attempt=True)
    # INCERTAIN (et tout cas imprévu) : neutre, rien de désigné.
    return Feedback(none_lit, waiting, "listen_again",
                    "effort_next" if last_try else "listen_again",
                    advance=last_try, counts_as_attempt=True)


@dataclass(frozen=True)
class SessionPolicy:
    """Durées par défaut prudentes (cf. recommandations écrans, docs/EVEIL.md §7)."""

    words_per_session: int = 6
    max_session_s: int = 8 * 60
    daily_budget_s: int = 15 * 60        # réglable dans l'espace parent

    def next_step(self, words_done: int, session_s: float, today_s: float) -> str:
        """`continue` | `end_session` (rituel de fin) | `rest_today` (à demain)."""
        if today_s >= self.daily_budget_s:
            return "rest_today"
        if words_done >= self.words_per_session or session_s >= self.max_session_s:
            return "end_session"
        return "continue"
