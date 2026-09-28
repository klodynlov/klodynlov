"""Les livres des sons : un livre par son, ses mots rangés par place, une idée de jeu.

Demande de l'utilisateur (28/09/2026) : « au niveau d'OrthoPicto, voire plus ». OrthoPicto
propose un livre par son (les plus difficiles : ch, j, g, r, k, b, f… 21 sons) et des
conseils. Ici, chaque livre est CALCULÉ à partir des mots dessinés : tous ceux qui
contiennent le son, au début, au milieu, à la fin — le wagon du son s'allume, ses lettres
se colorent. Les idées de jeu sont des PROPOSITIONS, à valider par des orthophonistes
(panel, docs/EVEIL.md § 8) : des images sonores et des jeux, jamais une rééducation.
"""
from __future__ import annotations

from dataclasses import dataclass

# Le son, ses lettres (les plus longues d'abord, pour colorer « ch » plutôt que « c »), son
# étiquette, son image sonore et une idée de jeu pour l'adulte.


@dataclass(frozen=True)
class Son:
    api: str
    etiquette: str
    lettres: tuple
    image: str          # l'image sonore (« le serpent : sss ! »)
    jeu: str            # une idée de jeu, hors écran


SONS_FR = (
    Son("ʃ", "ch", ("ch", "sh"), "Le train à vapeur : chhh ! Les lèvres en avant, comme pour un bisou.",
        "Jouez au train à vapeur au bain : chhh ! Puis cherchez dans la maison trois choses qui font « ch »."),
    Son("s", "s", ("ss", "sc", "ç", "s", "c", "x"), "Le serpent : sss ! Les dents presque fermées, on siffle.",
        "Faites le serpent qui glisse sur le tapis : sss ! Qui trouvera le plus de « s » dans la cuisine ?"),
    Son("z", "z", ("zz", "z", "s"), "L'abeille : zzz ! Comme le serpent, mais la gorge vibre (posez la main dessus).",
        "L'abeille vole de fleur en fleur : zzz… et se pose sur le nez de quelqu'un !"),
    Son("ʒ", "j", ("j", "ge", "g"), "La moto au ralenti : jjj ! Comme « chhh », mais la gorge vibre.",
        "Faites rouler une petite moto : jjj ! Accélérez, ralentissez, en gardant le son."),
    Son("f", "f", ("ph", "ff", "f"), "La bougie qu'on souffle : fff ! Les dents du haut sur la lèvre du bas.",
        "Soufflez ensemble sur une plume ou une petite boule de papier : fff ! Qui la fait aller le plus loin ?"),
    Son("v", "v", ("v", "w"), "L'avion : vvv ! Comme « fff », mais la gorge vibre.",
        "Faites voler un avion en papier en faisant vvv tant qu'il vole."),
    Son("p", "p", ("pp", "p"), "Les bulles qui éclatent : p, p, p ! Les lèvres fermées, puis pouf !",
        "Faites des bulles de savon et éclatez-les en disant « p ! » à chaque fois."),
    Son("b", "b", ("bb", "b"), "Le poisson qui fait des bulles : b, b, b ! Les lèvres fermées, la gorge vibre.",
        "Faites le poisson : joues gonflées, puis b, b, b !"),
    Son("t", "t", ("tt", "th", "t"), "L'horloge : tic-tac ! Le bout de la langue tape derrière les dents du haut.",
        "Jouez à l'horloge : tic-tac, en balançant les bras, de plus en plus vite."),
    Son("d", "d", ("dd", "d"), "Le tambour : dum, dum ! Comme « t », mais la gorge vibre.",
        "Tapez sur une casserole en disant « dum, dum, dum »."),
    Son("k", "k", ("qu", "ck", "c", "k", "q"), "La poule : cot, cot, codec ! Le fond de la langue se ferme, puis s'ouvre.",
        "Jouez à la poule qui cherche ses œufs : cot cot ! Cachez un objet, cot cot quand on s'en approche."),
    Son("ɡ", "g", ("gu", "gg", "g"), "La grenouille : gre, gre ! Comme « k », mais la gorge vibre.",
        "Sautez comme des grenouilles en disant « gre, gre » à chaque saut."),
    Son("m", "m", ("mm", "m"), "C'est bon : mmm ! Les lèvres fermées, ça chatouille.",
        "Au repas, dites « mmm » après chaque bouchée préférée."),
    Son("n", "n", ("nn", "n"), "Le nez qui vibre : nnn ! La langue derrière les dents, l'air passe par le nez.",
        "Pincez-vous doucement le nez en faisant nnn : ça s'arrête ! Qu'est-ce qui se passe ?"),
    Son("l", "l", ("ll", "l"), "On chante « la, la, la » : la langue se lève derrière les dents du haut.",
        "Chantez une comptine sur « la, la, la », puis « lo, lo, lo », « li, li, li »."),
    Son("ʁ", "r", ("rr", "r"), "Le lion qui grogne : rrr ! Au fond de la gorge.",
        "Jouez au lion qui se réveille : rrr doucement, puis plus fort."),
    Son("ɲ", "gn", ("gn",), "Comme dans « champignon » : gn ! La langue s'appuie sur le palais.",
        "Cherchez des champignons imaginaires dans le jardin : gn, gn, en voilà un !"),
)

SONS_EN = (
    Son("ʃ", "sh", ("sh", "ti", "ci"), "The steam train: shhh! Lips forward, like a kiss.",
        "Play steam trains in the bath: shhh! Then find three things at home with “sh”."),
    Son("s", "s", ("ss", "sc", "s", "c", "x"), "The snake: sss! Teeth almost closed, a gentle hiss.",
        "Be snakes sliding on the rug: sss! Who finds the most “s” things in the kitchen?"),
    Son("z", "z", ("zz", "z", "s"), "The bee: zzz! Like the snake, but the throat buzzes (feel it with a hand).",
        "The bee flies from flower to flower: zzz… and lands on someone's nose!"),
    Son("tʃ", "ch", ("tch", "ch"), "The train: choo-choo!",
        "March like a train around the room: ch-ch-ch, choo-choo!"),
    Son("dʒ", "j", ("dge", "j", "g"), "Jump and say: j-j-j! Like “ch” with a buzz.",
        "Jump on the spot, saying “j” at each jump."),
    Son("f", "f", ("ph", "ff", "f"), "Blow out the candle: fff! Top teeth on the bottom lip.",
        "Blow a feather or a paper ball together: fff! Who makes it go furthest?"),
    Son("v", "v", ("v",), "The car engine: vvv! Like “fff”, but the throat buzzes.",
        "Drive a toy car around, going vvv as long as it moves."),
    Son("p", "p", ("pp", "p"), "Popping bubbles: p, p, p! Lips closed, then pop!",
        "Blow soap bubbles and pop each one with a “p!”."),
    Son("b", "b", ("bb", "b"), "The fish blowing bubbles: b, b, b! Lips closed, throat buzzing.",
        "Be fish: puffed cheeks, then b, b, b!"),
    Son("t", "t", ("tt", "t"), "The clock: tick-tock! The tongue tip taps behind the top teeth.",
        "Play clocks: tick-tock, swinging your arms, faster and faster."),
    Son("d", "d", ("dd", "d"), "The drum: dum, dum! Like “t”, but the throat buzzes.",
        "Tap a pot like a drum: dum, dum, dum."),
    Son("k", "k", ("ck", "c", "k", "q", "x"), "The crow: caw, caw! The back of the tongue closes, then opens.",
        "Hide a toy; say “caw caw” louder as someone gets closer."),
    Son("ɡ", "g", ("gg", "g"), "The frog: ribbit… g-g-g! Like “k”, but the throat buzzes.",
        "Hop like frogs, saying “g” at each hop."),
    Son("m", "m", ("mm", "m"), "Yummy: mmm! Lips closed, it tickles.",
        "At mealtime, say “mmm” after each favourite bite."),
    Son("n", "n", ("nn", "kn", "n"), "The buzzing nose: nnn! Tongue behind the teeth, air through the nose.",
        "Gently pinch your nose while saying nnn: it stops! What happened?"),
    Son("l", "l", ("ll", "l"), "Sing “la, la, la”: the tongue lifts behind the top teeth.",
        "Sing a nursery rhyme on “la, la, la”, then “lo, lo, lo”."),
    Son("ɹ", "r", ("rr", "wr", "r"), "The lion's growl: rrr (lips a little round).",
        "Be lions waking up: a soft rrr, then louder."),
    Son("θ", "th", ("th",), "The tongue peeks out between the teeth: th!",
        "Look in a mirror together: tongue peeking out, th!"),
)


# ---------------------------------------------------------------------------
# Construire les livres
# ---------------------------------------------------------------------------

import unicodedata  # noqa: E402

from .mots import TOUS, Mot  # noqa: E402
from .sons import ou_est  # noqa: E402

PLACES = ("debut", "milieu", "fin")
MIN_MOTS = 5


@dataclass(frozen=True)
class Page:
    mot: Mot
    wagon: int          # le wagon (syllabe) où est le son
    position: str       # debut | milieu | fin
    lettres: str        # les lettres à colorer dans ce wagon (« ch »), vide si introuvables


@dataclass(frozen=True)
class Livre:
    son: Son
    pages: tuple


def _plier(texte: str) -> str:
    nfd = unicodedata.normalize("NFD", texte.lower())
    return "".join(ch for ch in nfd if not unicodedata.combining(ch))


def lettres_du_son(son: Son, wagon: str) -> str:
    """Les lettres du wagon qui écrivent le son (la première graphie trouvée, telle qu'écrite)."""
    plie = _plier(wagon)
    for g in son.lettres:
        k = plie.find(_plier(g))
        if k >= 0:
            return wagon[k:k + len(g)]
    return ""


def livres(locale: str, mots: tuple = TOUS) -> list[Livre]:
    """Les livres d'une langue : un par son qui a au moins `MIN_MOTS` mots (parmi `mots`)."""
    fr = locale.startswith("fr")
    out = []
    for son in (SONS_FR if fr else SONS_EN):
        pages = []
        for m in mots:
            api, wagons = (m.fr_api, m.fr_wagons) if fr else (m.en_api, m.en_wagons)
            ici = ou_est(son.api, api, locale)
            if ici is None:
                continue
            pages.append(Page(m, ici.syllabe, ici.position, lettres_du_son(son, wagons[ici.syllabe])))
        pages.sort(key=lambda pg: (PLACES.index(pg.position), _plier(pg.mot.fr if fr else pg.mot.en)))
        if len(pages) >= MIN_MOTS:
            out.append(Livre(son, tuple(pages)))
    return out
