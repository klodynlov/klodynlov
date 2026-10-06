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
6. Répétitions (demande de l'utilisateur, 28/09/2026 : « afficher un décompte pour le
   nombre de fois que l'enfant doit répéter ») : l'adulte choisit combien de fois le
   mot est redit (1 à 5, 3 par défaut). Seul un verdict COMPLET fait avancer le
   décompte ; un essai incomplet ne le fait jamais reculer, et la règle 4 s'applique
   à chaque répétition : on ne reste jamais bloqué sur un mot.
7. Étoiles (demande de l'utilisateur, 28/09/2026 : « plus c'est bien répété, plus le
   user a des points ») : des étoiles de JEU, pas un score de langage (docs/EVEIL.md
   § 7.3). Mot entier : 3 ; toutes les syllabes sans la fin : 2 ; détecteur pas sûr :
   2 aussi (asymétrie : l'incertitude ne coûte rien de plus qu'une fin manquée) ;
   syllabe en moins : 1 (l'essai compte) ; rien entendu : 0. On n'en perd jamais.
8. Progression « quand il réussit » (conseil d'une orthophoniste, d'après la méthode de
   Borel-Maisonny : les mots d'une syllabe d'abord, puis deux, et ainsi de suite ; décision
   de l'utilisateur, 06/10/2026). L'enfant commence au niveau 1 (une syllabe). Quand il a dit
   `UNLOCK_WORDS` mots DIFFÉRENTS du niveau en entier (verdict complet : le fourgon
   s'accroche), ou tous s'il y en a moins, le niveau suivant s'ouvre à la séance SUIVANTE :
   2 syllabes, puis groupes de consonnes, puis tous les mots mêlés. Le niveau ne redescend
   jamais tout seul ; l'adulte le règle (et le compte repart de zéro). Rien n'est compté en
   démo ni en « Essai par un adulte ». Aucun nombre n'est montré : ce n'est pas un score.
"""
from __future__ import annotations

from dataclasses import dataclass, field

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
REPETITIONS = range(1, 6)            # réglage de l'adulte : combien de fois on redit le mot
DEFAULT_REPETITIONS = 3

MESSAGES = {
    "fr-FR": {
        "bravo": "Bravo ! Tout le train est parti !",
        "hook_caboose": "Oh, le petit fourgon est resté en gare ! On l'accroche avec « chhh » ?",
        "model_slowly": "Écoute bien le train : on le dit doucement, ensemble.",
        "listen_again": "Je n'ai pas bien entendu. On le redit ensemble ?",
        "invite": "À toi ! Dis le mot au petit train.",
        "effort_next": "Merci d'avoir bien essayé ! On va voir le mot suivant.",
        "again": "Bravo ! Encore une fois !",
    },
    "en-US": {
        "bravo": "Hooray! The whole train is leaving!",
        "hook_caboose": "Oh, the little caboose stayed at the station! Let's hook it with \"shhh\"?",
        "model_slowly": "Listen to the train: let's say it slowly, together.",
        "listen_again": "I didn't hear it well. Shall we say it again together?",
        "invite": "Your turn! Tell the word to the little train.",
        "effort_next": "Thanks for trying so hard! Let's see the next word.",
        "again": "Great! One more time!",
    },
}


def feedback_for(verdict: Verdict, wagons: int, has_caboose: bool, attempt: int,
                 repetitions_left: int = 0, max_attempts: int = MAX_ATTEMPTS) -> Feedback:
    """`attempt` commence à 1 pour la première tentative (de CETTE répétition).

    `repetitions_left` : répétitions encore demandées APRÈS celle-ci si elle est
    réussie (0 = c'était la dernière). Il ne change que le verdict COMPLET : la
    fête a lieu, mais le train attend la répétition suivante au lieu de partir.
    """
    last_try = attempt >= max_attempts
    all_lit = tuple([True] * wagons)
    none_lit = tuple([False] * wagons)
    waiting = "waiting" if has_caboose else "none"
    k = verdict.kind

    if k is VerdictKind.COMPLETE:
        more = repetitions_left > 0
        return Feedback(all_lit, "hooked" if has_caboose else "none", "celebrate",
                        "again" if more else "bravo", advance=not more, counts_as_attempt=True)
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


STARS = {
    VerdictKind.COMPLETE: 3,
    VerdictKind.MISSING_FINAL_CONSONANT: 2,
    VerdictKind.UNSURE: 2,
    VerdictKind.FEWER_SYLLABLES: 1,
    VerdictKind.NO_SPEECH: 0,
}
MAX_STARS = 3


def stars_for(verdict: Verdict, has_caboose: bool = True) -> int:
    """Étoiles gagnées par un essai (jamais négatif ; le mot entier en vaut le plus).

    Un mot sans fourgon ne peut pas « manquer sa fin » : un tel verdict vaut alors
    comme un doute (2), jamais moins.
    """
    kind = verdict.kind
    if kind is VerdictKind.MISSING_FINAL_CONSONANT and not has_caboose:
        return STARS[VerdictKind.UNSURE]
    return STARS.get(kind, STARS[VerdictKind.UNSURE])


def clamp_repetitions(n: int) -> int:
    return min(REPETITIONS[-1], max(REPETITIONS[0], int(n)))


@dataclass
class RepetitionPlan:
    """Le décompte d'un mot : combien de fois encore l'enfant le redit."""

    target: int = DEFAULT_REPETITIONS
    done: int = 0

    def __post_init__(self) -> None:
        self.target = clamp_repetitions(self.target)
        self.done = min(self.target, max(0, self.done))

    @property
    def remaining(self) -> int:
        return self.target - self.done

    @property
    def is_complete(self) -> bool:
        return self.done >= self.target

    def left_after_success(self) -> int:
        """Ce qu'il resterait si l'essai en cours réussit (paramètre de `feedback_for`)."""
        return max(0, self.remaining - 1)

    def record_success(self) -> None:
        self.done = min(self.target, self.done + 1)


def again_text(remaining: int, locale: str) -> str:
    """Après une réussite, le décompte : « Bravo ! Encore 2 fois ! »."""
    fr = locale.startswith("fr")
    if remaining <= 1:
        return MESSAGES["fr-FR" if fr else "en-US"]["again"]
    return f"Bravo ! Encore {remaining} fois !" if fr else f"Great! {remaining} more times!"


def invite_text(count: int, locale: str) -> str:
    """L'invitation du début de mot, avec le nombre de répétitions demandées."""
    fr = locale.startswith("fr")
    if count <= 1:
        return MESSAGES["fr-FR" if fr else "en-US"]["invite"]
    return (f"À toi ! Dis-le {count} fois au petit train." if fr
            else f"Your turn! Say it {count} times to the little train.")


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


# ---------------------------------------------------------------------------
# 8. Les niveaux du petit train : une syllabe d'abord, puis on avance quand il réussit
# ---------------------------------------------------------------------------

LEVELS = (1, 2, 3, 4)                 # 1 syllabe · 2 syllabes · groupes de consonnes · tous mêlés
MIXED_LEVEL = 4
UNLOCK_WORDS = 6
MIX_PATTERN = (1, 1, 2, 1, 3, 2)      # niveau 4 : deux faciles, un plus long…


def clamp_level(n: int) -> int:
    return min(LEVELS[-1], max(LEVELS[0], int(n)))


def _level_of(word) -> int:
    return max(1, int(getattr(word, "level", 1) or 1))


def level_words(words, level: int) -> list:
    """Les mots d'un niveau (niveau 4 : tous), dans l'ordre du lexique."""
    if level >= MIXED_LEVEL:
        return list(words)
    return [w for w in words if _level_of(w) == level]


def mixed(words) -> list:
    """Tous les mots, niveaux entremêlés selon `MIX_PATTERN`, chaque mot une fois, sans hasard.

    Le niveau voulu s'il reste des mots, sinon le plus proche qui en a encore (à égalité,
    le plus facile)."""
    queues: dict[int, list] = {}
    for w in words:
        queues.setdefault(_level_of(w), []).append(w)
    out, step = [], 0
    while any(queues.values()):
        wanted = MIX_PATTERN[step % len(MIX_PATTERN)]
        step += 1
        level = min((lv for lv, q in queues.items() if q), key=lambda lv: (abs(lv - wanted), lv))
        out.append(queues[level].pop(0))
    return out


def deck(words, level: int) -> list:
    """Les mots d'une séance au niveau `level` : ceux du niveau, dans l'ordre du lexique ;
    au niveau 4 (ou si le niveau n'a aucun mot), tous les mots mêlés."""
    level = clamp_level(level)
    own = level_words(words, level) if level < MIXED_LEVEL else []
    return own or mixed(words)


def unlock_target(words, level: int) -> int:
    """Combien de mots différents dire en entier pour ouvrir le niveau suivant."""
    return min(UNLOCK_WORDS, len(level_words(words, level)))


def next_level(words, level: int) -> int:
    """Le niveau qui suit `level` et qui a des mots (le niveau 4 en a toujours)."""
    for lv in LEVELS:
        if lv > level and (lv == MIXED_LEVEL or level_words(words, lv)):
            return lv
    return MIXED_LEVEL


@dataclass
class LevelProgress:
    """Où en est l'enfant : son niveau, et les mots de ce niveau déjà dits en entier.

    Le niveau ne change qu'en début de séance (`start_session`) ou par l'adulte
    (`set_by_adult`) ; à chaque changement, le compte repart de zéro.
    """

    level: int = 1
    said: set = field(default_factory=set)

    def __post_init__(self) -> None:
        self.level = clamp_level(self.level)
        self.said = set(self.said)

    def record(self, word, kind: VerdictKind, counted: bool = True) -> None:
        """Un essai au petit train. Seul un verdict COMPLET d'un mot du niveau compte, et
        jamais en démo ni en « Essai par un adulte » (`counted=False`)."""
        if counted and kind is VerdictKind.COMPLETE and self.level < MIXED_LEVEL \
                and _level_of(word) == self.level:
            self.said.add(word.id)

    def ready(self, words) -> bool:
        """Le niveau suivant s'ouvrira à la prochaine séance."""
        if self.level >= MIXED_LEVEL:
            return False
        own = {w.id for w in level_words(words, self.level)}
        target = unlock_target(words, self.level)
        return target > 0 and len(self.said & own) >= target

    def start_session(self, words) -> int:
        """Début de séance : ouvre le niveau suivant s'il est gagné. Rend le niveau à jouer."""
        if self.ready(words):
            self.level = next_level(words, self.level)
            self.said = set()
        return self.level

    def set_by_adult(self, level: int) -> None:
        """L'adulte choisit le niveau (espace des grands) : le compte repart de zéro."""
        self.level = clamp_level(level)
        self.said = set()
