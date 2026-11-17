"""Les gestes de la méthode phonétique et gestuelle de Borel-Maisonny, et la bouche de Lou.

Conseil d'une orthophoniste qui a vu l'app (06/10/2026) : un geste par son, montré par un
avatar qui fait aussi voir comment dire le son. Décision de l'utilisateur : l'avatar est Lou
(l'enfant du train des phrases), en grand, en portrait ; sa bouche montre comment dire le son,
sa main à cinq doigts fait le geste ; l'adulte choisit la couleur de peau.

**Validés par l'orthophoniste le 06/10/2026, tels que dessinés sur la planche** (choix ouverts
compris : gn = geste de l'atlas, Lou fait les gestes face à l'enfant sans les inverser, d avec
l'autre main dans le dos, un seul geste pour o/ɔ et eu/œ, bouches « proposition » acceptées, « ui »
reste sans geste). Décision de l'utilisateur : Lou les montre, ANIMÉS, dans les livres des sons et
dans le petit train.

Règles de rédaction (les livres sont sous droits, le dépôt est public) :
- tout est REFORMULÉ dans nos mots ; on ne cite que le livre, la page et la figure ;
- rien n'est inventé : un geste non trouvé dans les livres reste `A_TROUVER` ;
- les pages sont celles IMPRIMÉES dans le livre (l'index de LibraryBrain compte les pages du
  PDF : page imprimée + 2 pour LOE1) ;
- la bouche : quand le livre la décrit, on le cite ; sinon c'est une PROPOSITION tirée de la
  phonétique courante du français, à valider elle aussi (`bouche_source = PROPOSITION`).

Sources (relevées dans LibraryBrain le 06/10/2026, réponses brutes dans
`eveil/librarybrain/resultats/borel/`, gitignoré) :
- LOE1 : S. Borel-Maisonny, *Langage oral et écrit, I. Pédagogie des notions de base*,
  Delachaux et Niestlé, 8e éd., 1985 — méthode et leçons p. 16-41, « Atlas des gestes » p. 60-90.
- TLDM : S. Borel-Maisonny, *Les troubles du langage dans la déficience mentale et leur
  rééducation* (extrait, p. 133-155).
"""
from __future__ import annotations

from dataclasses import dataclass

LOE1 = "Borel-Maisonny, Langage oral et écrit I (1985)"
TLDM = "Borel-Maisonny, Les troubles du langage dans la déficience mentale"
A_TROUVER = "à trouver"
RELEVE = "relevé, validé (06/10/2026)"
PROPOSITION = "proposition (phonétique courante), validée (06/10/2026)"

# Les formes de bouche que l'on dessine (vues de face).
BOUCHES = {
    "fermee": "lèvres jointes",
    "dents_levre": "dents du haut posées sur la lèvre du bas",
    "avancee": "lèvres arrondies et poussées en avant, dents presque jointes",
    "petite_ronde": "lèvres très arrondies, petite ouverture",
    "ronde": "lèvres arrondies, ouverture moyenne",
    "etiree": "lèvres étirées, dents presque jointes",
    "grande": "bouche grande ouverte",
    "mi_ouverte": "bouche à moitié ouverte, lèvres détendues",
    "langue_haut": "bouche entrouverte, pointe de la langue derrière les dents du haut",
    "fond": "bouche entrouverte, langue en arrière (rien ne se voit à l'avant)",
}


@dataclass(frozen=True)
class Geste:
    son: str              # l'étiquette (« ch »)
    api: str              # le son en API (« ʃ »)
    exemple: str          # un mot du jeu qui le contient (vide : aucun)
    main: str = A_TROUVER         # forme de la main
    place: str = A_TROUVER        # place par rapport au visage, au corps
    mouvement: str = A_TROUVER
    evoque: str = A_TROUVER       # ce que le geste évoque (le son, la lettre, une scène)
    source: str = ""              # livre, page, figure
    statut: str = A_TROUVER
    bouche: str = "mi_ouverte"    # clé de BOUCHES
    bouche_source: str = PROPOSITION
    remarque: str = ""


def _g(son, api, exemple, main, place, mouvement, evoque, source, bouche, bouche_source=PROPOSITION,
       remarque=""):
    return Geste(son, api, exemple, main, place, mouvement, evoque, source, RELEVE, bouche, bouche_source,
                 remarque)


VOYELLES = (
    _g("a", "a", "vache", "main ouverte, doigts écartés, paume tournée vers l'enfant",
       "bras levé, la main à hauteur de la tête, loin du corps", "on la tient immobile",
       "la bouche grande ouverte", f"{LOE1}, p. 18, 24 ; atlas p. 61, fig. 2",
       "grande", f"{LOE1}, p. 18 (la main ouverte rappelle la bouche ouverte)"),
    _g("o", "o", "vélo", "pouce et index joints en rond, les autres doigts serrés contre eux",
       "devant soi, tourné vers l'enfant", "aucun",
       "la forme de la lettre o (et le son)", f"{LOE1}, p. 18, 24 ; atlas p. 63, fig. 4 (bas)",
       "ronde", remarque="« au » et « eau » ont le même geste (p. 26). Le livre ne distingue pas le o fermé "
       "(pot) du o ouvert (os, brosse) : un seul geste."),
    _g("ou", "u", "douche", "d'abord le rond du o, puis deux doigts, puis la main qui rappelle le u",
       "devant soi, le bras s'allonge pendant le son", "geste lent en trois temps sur un seul son tenu",
       "les deux lettres o et u ; le hurlement du loup", f"{LOE1}, p. 25 ; atlas p. 69, fig. 10",
       "petite_ronde"),
    _g("i", "i", "niche", "l'index seul dressé, les autres doigts repliés",
       "avant-bras levé, coude contre le corps", "aucun", "la forme de la lettre i",
       f"{LOE1}, p. 24 ; atlas p. 68, fig. 9", "etiree"),
    _g("u", "y", "ruche", "index et majeur dressés et écartés, les autres repliés",
       "devant soi, main levée", "aucun", "la forme de la lettre u (d'après la figure ; le texte ne le dit pas)",
       f"{LOE1}, atlas p. 67, fig. 8", "petite_ronde"),
    _g("é", "e", "fée", "main ouverte, doigts serrés, inclinée vers l'avant",
       "posée sur le front, ou levée au-dessus de la tête, pointée en avant", "aucun",
       "l'accent aigu, penché vers l'avant", f"{LOE1}, p. 24 ; atlas p. 65, fig. 6", "etiree"),
    _g("è", "ɛ", "pêche", "main ouverte, doigts serrés",
       "sur le sommet de la tête, rejetée en arrière ; la tête un peu levée", "aucun",
       "l'accent grave, penché vers l'arrière", f"{LOE1}, p. 26 ; atlas p. 66, fig. 7",
       "mi_ouverte", f"{LOE1}, p. 26 (tête levée, bouche ouverte)",
       remarque="Même geste pour ai, ei, ê (p. 26)."),
    _g("eu", "ø", "feu", "l'index croisé sur le pouce", "devant soi", "aucun",
       "la forme de la lettre œ", f"{LOE1}, p. 24, 28 ; atlas p. 63, fig. 4 (haut)", "ronde",
       remarque="Un seul geste pour le eu fermé (feu) et le eu ouvert (fleur) ; le livre signale aux "
       "enfants le changement de timbre (p. 28)."),
    _g("eu ouvert", "œ", "fleur", "l'index croisé sur le pouce", "devant soi", "aucun",
       "la forme de la lettre œ", f"{LOE1}, p. 28 ; atlas p. 63, fig. 4 (haut)", "ronde"),
    _g("e", "ə", "cheval", "l'index croisé sur le pouce (geste du eu)", "devant soi", "aucun",
       "le geste du eu", f"{LOE1}, p. 29 (leçon IX)", "ronde"),
    _g("an", "ɑ̃", "orange", "la main ouverte du a", "portée sur le nez", "aucun ; on accentue le son du nez",
       "le a qui passe par le nez", f"{LOE1}, p. 24 ; atlas p. 62, fig. 3", "grande",
       remarque="« en », « em » : même geste (p. 33)."),
    _g("on", "ɔ̃", "maison", "le rond du o, doigts tendus pour bien montrer le cercle", "au contact du nez",
       "aucun", "le o qui passe par le nez", f"{LOE1}, p. 24 ; atlas p. 64, fig. 5", "ronde"),
    _g("in", "ɛ̃", "princesse", "l'index du i dressé, poing fermé", "devant le nez, au contact", "aucun",
       "le i qui passe par le nez", f"{LOE1}, p. 26 ; atlas p. 64 (remarque de la fig. 5)", "mi_ouverte",
       remarque="Le livre présente « in » comme le i nasal (et non le é nasal) pour éviter des confusions "
       "de lettres (p. 26)."),
    _g("oi", "wa", "poisson", "main fermée, puis ouverte d'un coup", "devant soi",
       "deux temps, au rythme d'un aboiement, sur une seule syllabe", "la gueule du chien qui aboie ; "
       "le son qui finit comme un a (main ouverte)", f"{LOE1}, p. 19, 24 ; atlas p. 70, fig. 11", "ronde"),
    _g("oin", "wɛ̃", "", "pouce, index et majeur allongés en bec", "devant soi",
       "le bec se ferme, s'ouvre, se referme (deux ou trois fois)", "le bec du canard",
       f"{LOE1}, p. 24 ; atlas p. 71, fig. 12", "ronde"),
)

CONSONNES = (
    _g("ch", "ʃ", "douche", "pouce et index écartés en pince, la courbe entre eux dessine un c",
       "posés sur les deux joues", "on garde la pose tout le temps du souffle",
       "la lettre c (de ch)", f"{LOE1}, p. 23 ; atlas p. 76, fig. 16", "avancee"),
    _g("s", "s", "tasse", "l'index tendu", "devant soi, sur le côté",
       "lentement, on dessine un grand s en l'air tout le temps du sifflement",
       "le serpent qui siffle ; la lettre s", f"{LOE1}, p. 23 ; atlas p. 74-75, fig. 15", "etiree"),
    _g("z", "z", "fusée", "l'index tendu", "devant soi",
       "un zigzag rapide, comme un éclair", "le moustique en plein vol ; la lettre z ; la gorge vibre",
       f"{LOE1}, p. 18, 23 ; atlas p. 74-75, fig. 15", "etiree"),
    _g("j", "ʒ", "girafe", "l'index tendu", "contre la joue",
       "l'index s'avance vers la joue comme pour la piquer", "la forme de la lettre j ; la gorge vibre",
       f"{LOE1}, p. 23 ; atlas p. 77, fig. 17", "avancee"),
    _g("f", "f", "fée", "main à plat", "partant du milieu du corps",
       "tout le bras glisse vers l'extérieur pendant le souffle", "le souffle qui s'écoule ; la barre du f",
       f"{LOE1}, p. 19 ; atlas p. 72, fig. 13", "dents_levre"),
    _g("v", "v", "vache", "les deux mains, poignets joints, paumes ouvertes et écartées en V",
       "devant soi ; un pouce peut aller vers la gorge", "aucun",
       "la forme de la lettre v ; la gorge vibre", f"{LOE1}, p. 23 ; atlas p. 73, fig. 14", "dents_levre"),
    _g("p", "p", "pêche", "le poing fermé, avant-bras levé", "devant soi, en hauteur",
       "le poing s'ouvre d'un coup au moment du « p »", "la hampe et le rond de la lettre p ; l'explosion",
       f"{LOE1}, p. 25 ; atlas p. 81, fig. 20", "fermee",
       f"{LOE1}, atlas p. 81 (lèvres pressées, qui s'ouvrent avec la main ; gorge muette)"),
    _g("b", "b", "bouche", "la main se ferme à moitié", "en bas, presque à hauteur du ventre",
       "le bras vient de l'extérieur vers le milieu du corps ; la main s'ouvre au « b »",
       "le rond du b en bas de sa hampe ; la gorge vibre", f"{LOE1}, p. 26 ; atlas p. 82-83, fig. 21",
       "fermee", f"{LOE1}, atlas p. 83 (lèvres fermées, gorge qui vibre fort)"),
    _g("t", "t", "tasse", "pouce et index qui pincent puis relâchent", "en l'air, à hauteur de l'épaule",
       "pincer, relâcher", "pincer la barre du t", f"{LOE1}, p. 25 ; atlas p. 84-85, fig. 22",
       "langue_haut"),
    _g("d", "d", "douche", "le même pincement que t ; l'autre main fermée", "l'autre main dans le bas du dos",
       "pincer, relâcher", "le rond du d derrière sa hampe ; la gorge vibre",
       f"{LOE1}, p. 32 ; atlas p. 84-85, fig. 22", "langue_haut"),
    _g("k", "k", "cactus", "l'index tendu", "vers la bouche entrouverte",
       "l'index s'avance vers la bouche au moment du « k »", "la langue qui touche le fond du palais",
       f"{LOE1}, p. 25 ; atlas p. 86, fig. 23", "fond", f"{LOE1}, atlas p. 86 (bouche entrouverte)"),
    _g("g", "ɡ", "glace", "comme pour k, et le pouce", "l'index vers la bouche, le pouce vers la gorge",
       "comme pour k", "comme k, avec la gorge qui vibre", f"{LOE1}, p. 34 ; atlas p. 87, fig. 24", "fond"),
    _g("m", "m", "mouche", "pouce, index et majeur tendus, bouts posés à plat", "sur une table",
       "on appuie tant que dure le « mmm », on lève quand il s'arrête", "la forme de la lettre m",
       f"{LOE1}, p. 18, 23 ; atlas p. 78-79, fig. 18", "fermee", f"{LOE1}, atlas p. 79 (lèvres serrées)"),
    _g("n", "n", "niche", "index et majeur", "à cheval sur le nez", "aucun",
       "la forme de la lettre n ; le son qui passe par le nez", f"{LOE1}, p. 24 ; atlas p. 78-79, fig. 18",
       "langue_haut"),
    _g("gn", "ɲ", "champignon", "l'index", "posé sur le nez",
       "il glisse d'un côté du nez à l'autre", "le son qui passe par le nez",
       f"{LOE1}, atlas p. 80, fig. 19", "fond",
       remarque="Bouche : pour gn, c'est le dos de la langue qui touche le palais (aucune de nos 10 bouches ne "
       "le montre exactement). La leçon VII (p. 28) décrit un autre geste (celui du k, puis le nez, puis la gorge) : "
       "on retient l'atlas, à confirmer."),
    _g("l", "l", "limace", "l'index tendu vers le haut", "devant la bouche",
       "l'index monte, comme la pointe de la langue", "la pointe de la langue levée ; la forme du l",
       f"{LOE1}, p. 18, 24 ; atlas p. 89, fig. 26", "langue_haut",
       f"{LOE1}, atlas p. 89 (pointe de la langue relevée)"),
    _g("r", "ʁ", "ruche", "l'index replié", "touche le côté du cou, sous la mâchoire",
       "aucun : on sent la gorge qui gratte", "« la lettre qui gratte »",
       f"{LOE1}, p. 18, 24 ; atlas p. 88, fig. 25", "fond"),
    _g("ill", "j", "grenouille", "l'index tendu à l'horizontale", "devant la bouche",
       "il s'avance, comme le souffle qui sort", "le souffle du son", f"{LOE1}, atlas p. 90, fig. 27",
       "etiree"),
)

# Sons des mots du jeu dont le geste n'a pas été trouvé.
A_TROUVER_SONS = (
    Geste("ui", "ɥ", "nuage", remarque="Le livre traite oi et oin comme des tout ; rien sur « ui »."),
)

TOUS = VOYELLES + CONSONNES + A_TROUVER_SONS


def par_son(api: str) -> Geste | None:
    return next((g for g in TOUS if g.api == api), None)
