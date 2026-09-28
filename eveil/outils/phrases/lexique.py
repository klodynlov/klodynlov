"""Le lexique du train des phrases : qui ? fait quoi ? quoi ? où ?

Demande de l'utilisateur (28/09/2026) : une app « au niveau d'OrthoPicto, voire plus ».
Le cœur d'OrthoPicto (orthophoniste, Symbolicone) : l'enfant construit une phrase
simple — sujet, verbe, complément — avec des pictos, et l'image s'anime. Ici, la
phrase est un TRAIN : la locomotive porte « qui ? », puis un wagon par morceau
(« fait quoi ? », « quoi ? », « où ? »), et la scène joue la phrase construite —
n'importe laquelle, même « la vache nage dans la tasse » (on rit, on ne se trompe pas).

Les noms réutilisent les dessins vivants du petit train (`WordArt`) ; les verbes, les
lieux et Lou sont dessinés dans `outils/pictos`. Chaque nom porte :
  - son dessin, et le sens où il regarde (la scène le retourne vers l'objet) ;
  - en français : genre (m, f, ou p = nom propre) et API ; en anglais : mot et API ;
  - ses rôles : qui (sujet), quoi (complément), où (lieu).
Les listes sont des PROPOSITIONS, à valider avec le panel (docs/EVEIL.md § 8), comme
les lexiques du petit train. Stdlib uniquement.
"""
from __future__ import annotations

from dataclasses import dataclass

PREPOSITIONS = ("dans", "sur", "sous", "devant", "derriere")
PREP_FR = {"dans": "dans", "sur": "sur", "sous": "sous", "devant": "devant", "derriere": "derrière"}
PREP_EN = {"dans": "in", "sur": "on", "sous": "under", "devant": "in front of", "derriere": "behind"}


@dataclass(frozen=True)
class Nom:
    id: str
    dessin: str
    genre: str              # m | f | p (nom propre : pas d'article)
    fr: str
    fr_api: str
    en: str
    en_api: str
    roles: frozenset
    regarde: str = "face"   # gauche | droite | face : le sens du dessin
    prepositions: tuple = ()  # lieux : les prépositions dessinées (ancres du picto)


@dataclass(frozen=True)
class Verbe:
    id: str
    fr: str                 # 3e personne du singulier (« mange », « se cache »)
    fr_api: str
    en: str                 # « eats »
    en_api: str
    transitif: bool         # niveau 2 : avec un « quoi ? »
    absolu: bool = False    # aussi sans complément au niveau 1 (« Le chat mange. »)
    objets: tuple = ()      # compléments naturels (niveau 2), dans l'ordre du plateau
    prepositions: tuple = ()  # niveau 3 : prépositions naturelles avec ce verbe
    lieux: tuple = ()       # niveau 3 : lieux permis (vide = tous ceux qui ont la préposition)


def _nom(id_, dessin, genre, fr, fr_api, en, en_api, roles, regarde="face", prepositions=()):
    return Nom(id_, dessin, genre, fr, fr_api, en, en_api, frozenset(roles.split()), regarde, tuple(prepositions))


NOMS = (
    # --- qui ? (et parfois quoi ?) : les animaux des dessins du petit train, la princesse, Lou.
    _nom("chat", "fr.minouche", "m", "chat", "ʃa", "cat", "kæt", "qui quoi"),
    _nom("chien", "fr.caniche", "m", "chien", "ʃjɛ̃", "dog", "dɔɡ", "qui quoi", "gauche"),
    _nom("vache", "fr.vache", "f", "vache", "vaʃ", "cow", "kaʊ", "qui quoi", "gauche"),
    _nom("biche", "fr.biche", "f", "biche", "biʃ", "deer", "dɪɹ", "qui", "gauche"),
    _nom("mouche", "fr.mouche", "f", "mouche", "muʃ", "fly", "flaɪ", "qui quoi"),
    _nom("oiseau", "fr.perruche", "m", "oiseau", "wazo", "bird", "bɝd", "qui quoi", "gauche"),
    _nom("limace", "fr.limace", "f", "limace", "limas", "slug", "slʌɡ", "qui", "gauche"),
    _nom("autruche", "fr.autruche", "f", "autruche", "otʁyʃ", "ostrich", "ˈɑstɹɪtʃ", "qui", "gauche"),
    _nom("poisson", "en.fish", "m", "poisson", "pwasɔ̃", "fish", "fɪʃ", "qui quoi", "gauche"),
    _nom("oie", "en.goose", "f", "oie", "wa", "goose", "ɡus", "qui", "gauche"),
    _nom("elan", "en.moose", "m", "élan", "elɑ̃", "moose", "mus", "qui"),
    _nom("souris", "en.mouse", "f", "souris", "suʁi", "mouse", "maʊs", "qui quoi", "gauche"),
    _nom("princesse", "fr.princesse", "f", "princesse", "pʁɛ̃sɛs", "princess", "ˈpɹɪnsɛs", "qui"),
    _nom("lou", "perso.lou", "p", "Lou", "lu", "Lou", "lu", "qui"),
    # --- quoi ? : les objets des dessins du petit train.
    _nom("peche", "fr.peche", "f", "pêche", "pɛʃ", "peach", "pitʃ", "quoi"),
    _nom("saucisse", "fr.saucisse", "f", "saucisse", "sosis", "sausage", "ˈsɔsɪdʒ", "quoi"),
    _nom("glace", "fr.glace", "f", "glace", "ɡlas", "ice cream", "ˈaɪs kɹim", "quoi"),
    _nom("os", "fr.os", "m", "os", "ɔs", "bone", "boʊn", "quoi"),
    _nom("radis", "en.radish", "m", "radis", "ʁadi", "radish", "ˈɹædɪʃ", "quoi"),
    _nom("jus", "en.juice", "m", "jus", "ʒy", "juice", "dʒus", "quoi"),
    _nom("tasse", "fr.tasse", "f", "tasse", "tas", "cup", "kʌp", "quoi"),
    _nom("assiette", "en.dish", "f", "assiette", "asjɛt", "plate", "pleɪt", "quoi"),
    _nom("brosse", "fr.brosse", "f", "brosse", "bʁɔs", "brush", "bɹʌʃ", "quoi"),
    _nom("cloche", "fr.cloche", "f", "cloche", "klɔʃ", "bell", "bɛl", "quoi"),
    _nom("trousse", "fr.trousse", "f", "trousse", "tʁus", "pencil case", "ˈpɛnsəl keɪs", "quoi"),
    _nom("fleche", "fr.fleche", "f", "flèche", "flɛʃ", "arrow", "ˈæɹoʊ", "quoi"),
    _nom("buche", "fr.buche", "f", "bûche", "byʃ", "log", "lɔɡ", "quoi"),
    _nom("balle", "en.tennis", "f", "balle", "bal", "ball", "bɔl", "quoi"),
    _nom("bus", "en.bus", "m", "bus", "bys", "bus", "bʌs", "quoi"),
    _nom("carrosse", "fr.carrosse", "m", "carrosse", "kaʁɔs", "carriage", "ˈkæɹɪdʒ", "quoi"),
    # --- où ? : les lieux dessinés pour le train des phrases (outils/pictos/lieux.py).
    _nom("boite", "lieu.boite", "f", "boîte", "bwat", "box", "bɑks", "ou",
         prepositions=("dans", "sur", "devant", "derriere")),
    _nom("niche", "lieu.niche", "f", "niche", "niʃ", "doghouse", "ˈdɔɡhaʊs", "ou",
         prepositions=("dans", "sur", "devant", "derriere")),
    _nom("maison", "lieu.maison", "f", "maison", "mɛzɔ̃", "house", "haʊs", "ou",
         prepositions=("dans", "sur", "devant", "derriere")),
    _nom("table", "lieu.table", "f", "table", "tabl", "table", "ˈteɪbəl", "ou",
         prepositions=("sur", "sous", "devant", "derriere")),
    _nom("lit", "lieu.lit", "m", "lit", "li", "bed", "bɛd", "ou",
         prepositions=("dans", "sur", "sous", "devant")),
    _nom("arbre", "lieu.arbre", "m", "arbre", "aʁbʁ", "tree", "tɹi", "ou",
         prepositions=("dans", "sous", "devant", "derriere")),
    _nom("baignoire", "lieu.baignoire", "f", "baignoire", "bɛɲwaʁ", "bathtub", "ˈbæθtʌb", "ou",
         prepositions=("dans", "devant", "derriere")),
    _nom("voiture", "lieu.voiture", "f", "voiture", "vwatyʁ", "car", "kɑɹ", "ou",
         prepositions=("dans", "sur", "devant", "derriere")),
)

VERBES = (
    # --- sans complément (niveaux 1 et 3)
    Verbe("dormir", "dort", "dɔʁ", "sleeps", "slips", False, prepositions=("dans", "sur", "sous")),
    Verbe("sauter", "saute", "sot", "jumps", "dʒʌmps", False, prepositions=("sur", "dans", "devant")),
    Verbe("danser", "danse", "dɑ̃s", "dances", "ˈdænsɪz", False, prepositions=("sur", "devant", "dans")),
    Verbe("courir", "court", "kuʁ", "runs", "ɹʌnz", False, prepositions=("devant", "derriere", "dans")),
    Verbe("chanter", "chante", "ʃɑ̃t", "sings", "sɪŋz", False, prepositions=("dans", "sur", "devant", "sous")),
    Verbe("nager", "nage", "naʒ", "swims", "swɪmz", False, prepositions=("dans",), lieux=("baignoire",)),
    Verbe("voler", "vole", "vɔl", "flies", "flaɪz", False, prepositions=("dans", "devant", "derriere", "sur")),
    Verbe("tourner", "tourne", "tuʁn", "spins", "spɪnz", False, prepositions=("sur", "devant", "dans")),
    Verbe("rire", "rit", "ʁi", "laughs", "læfs", False,
          prepositions=("dans", "sur", "sous", "devant", "derriere")),
    Verbe("se_cacher", "se cache", "sə kaʃ", "hides", "haɪdz", False, prepositions=("dans", "sous", "derriere")),
    # --- avec complément (niveau 2) ; « manger » et « boire » aussi seuls au niveau 1
    Verbe("manger", "mange", "mɑ̃ʒ", "eats", "its", True, absolu=True,
          objets=("peche", "saucisse", "glace", "os", "radis")),
    Verbe("boire", "boit", "bwa", "drinks", "dɹɪŋks", True, absolu=True, objets=("jus", "tasse")),
    Verbe("pousser", "pousse", "pus", "pushes", "ˈpʊʃɪz", True,
          objets=("bus", "carrosse", "buche", "trousse", "balle", "cloche")),
    Verbe("porter", "porte", "pɔʁt", "carries", "ˈkæɹiz", True,
          objets=("trousse", "buche", "os", "tasse", "cloche", "peche", "brosse")),
    Verbe("lancer", "lance", "lɑ̃s", "throws", "θɹoʊz", True,
          objets=("balle", "os", "peche", "fleche", "brosse", "trousse")),
    Verbe("laver", "lave", "lav", "washes", "ˈwɑʃɪz", True,
          objets=("tasse", "assiette", "chien", "vache", "bus", "brosse", "carrosse")),
    Verbe("attraper", "attrape", "atʁap", "catches", "ˈkætʃɪz", True,
          objets=("balle", "mouche", "os", "peche", "fleche")),
    Verbe("lecher", "lèche", "lɛʃ", "licks", "lɪks", True, objets=("glace", "os", "assiette", "chat")),
    Verbe("sentir", "sent", "sɑ̃", "smells", "smɛlz", True, objets=("peche", "saucisse", "glace", "radis", "jus")),
    Verbe("tirer", "tire", "tiʁ", "pulls", "pʊlz", True, objets=("carrosse", "bus", "buche", "trousse", "brosse")),
)

PAR_ID = {n.id: n for n in NOMS}
VERBE_PAR_ID = {v.id: v for v in VERBES}


def noms(role: str) -> list[Nom]:
    return [n for n in NOMS if role in n.roles]
