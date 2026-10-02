"""Les mots des livres des sons : les mots déjà dessinés, et les nouveaux (à dessiner).

Chaque mot : son dessin (`mot.<id>` pour les nouveaux, sinon le dessin du petit train ou
du train des phrases), en français (genre, mot, API avec points de syllabe, wagons) et en
anglais (mot, API, wagons). Les wagons sont les syllabes ORALES écrites (« gi · rafe ») ;
l'API donne une syllabe par wagon (vérifié). Propositions à valider avec le panel (§ 8).
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Mot:
    id: str
    dessin: str
    genre: str            # m | f | pl (les) | p (nom propre)
    fr: str
    fr_api: str
    fr_wagons: tuple
    en: str
    en_api: str
    en_wagons: tuple
    nouveau: bool = False  # à dessiner (outils/pictos, famille « mot. »)


def _m(id_, genre, fr, fr_api, fr_wagons, en, en_api, en_wagons, dessin=None):
    return Mot(id_, dessin or f"mot.{id_}", genre, fr, fr_api, tuple(fr_wagons.split("-")), en, en_api,
               tuple(en_wagons.split("-")), nouveau=dessin is None)


# Les nouveaux mots, choisis pour que chaque son ait son livre (familiers à 3-5 ans, dessinables).
NOUVEAUX = (
    _m("fleur", "f", "fleur", "flœʁ", "fleur", "flower", "ˈflaʊ.ɚ", "flow-er"),
    _m("feu", "m", "feu", "fø", "feu", "fire", "faɪɚ", "fire"),
    _m("fee", "f", "fée", "fe", "fée", "fairy", "ˈfɛɹ.i", "fair-y"),
    _m("fusee", "f", "fusée", "fy.ze", "fu-sée", "rocket", "ˈɹɑk.ɪt", "rock-et"),
    _m("fraise", "f", "fraise", "fʁɛz", "fraise", "strawberry", "ˈstɹɔ.bɛ.ɹi", "straw-ber-ry"),
    _m("fourchette", "f", "fourchette", "fuʁ.ʃɛt", "four-chette", "fork", "fɔɹk", "fork"),
    _m("phoque", "m", "phoque", "fɔk", "phoque", "seal", "sil", "seal"),
    _m("girafe", "f", "girafe", "ʒi.ʁaf", "gi-rafe", "giraffe", "dʒə.ˈɹæf", "gi-raffe"),
    _m("velo", "m", "vélo", "ve.lo", "vé-lo", "bike", "baɪk", "bike"),
    _m("verre", "m", "verre", "vɛʁ", "verre", "glass", "ɡlæs", "glass"),
    _m("valise", "f", "valise", "va.liz", "va-lise", "suitcase", "ˈsut.keɪs", "suit-case"),
    _m("vague", "f", "vague", "vaɡ", "vague", "wave", "weɪv", "wave"),
    _m("cheval", "m", "cheval", "ʃə.val", "che-val", "horse", "hɔɹs", "horse"),
    _m("jupe", "f", "jupe", "ʒyp", "jupe", "skirt", "skɝt", "skirt"),
    _m("genou", "m", "genou", "ʒə.nu", "ge-nou", "knee", "ni", "knee"),
    _m("orange", "f", "orange", "ɔ.ʁɑ̃ʒ", "o-range", "orange", "ˈɔɹ.ɪndʒ", "or-ange"),
    _m("neige", "f", "neige", "nɛʒ", "neige", "snow", "snoʊ", "snow"),
    _m("cage", "f", "cage", "kaʒ", "cage", "cage", "keɪdʒ", "cage"),
    _m("gateau", "m", "gâteau", "ɡa.to", "gâ-teau", "cake", "keɪk", "cake"),
    _m("gomme", "f", "gomme", "ɡɔm", "gomme", "eraser", "ɪ.ˈɹeɪ.sɚ", "e-ra-ser"),
    _m("guitare", "f", "guitare", "ɡi.taʁ", "gui-tare", "guitar", "ɡɪ.ˈtɑɹ", "gui-tar"),
    _m("gant", "m", "gant", "ɡɑ̃", "gant", "glove", "ɡlʌv", "glove"),
    _m("grenouille", "f", "grenouille", "ɡʁə.nuj", "gre-nouille", "frog", "fɹɔɡ", "frog"),
    _m("bague", "f", "bague", "baɡ", "bague", "ring", "ɹɪŋ", "ring"),
    _m("dragon", "m", "dragon", "dʁa.ɡɔ̃", "dra-gon", "dragon", "ˈdɹæ.ɡən", "dra-gon"),
    _m("dent", "f", "dent", "dɑ̃", "dent", "tooth", "tuθ", "tooth"),
    _m("dinosaure", "m", "dinosaure", "di.no.zɔʁ", "di-no-saure", "dinosaur", "ˈdaɪ.nə.sɔɹ", "di-no-saur"),
    _m("de", "m", "dé", "de", "dé", "dice", "daɪs", "dice"),
    _m("dauphin", "m", "dauphin", "do.fɛ̃", "dau-phin", "dolphin", "ˈdɑl.fɪn", "dol-phin"),
    _m("coq", "m", "coq", "kɔk", "coq", "rooster", "ˈɹus.tɚ", "roos-ter"),
    _m("canard", "m", "canard", "ka.naʁ", "ca-nard", "duck", "dʌk", "duck"),
    _m("cle", "f", "clé", "kle", "clé", "key", "ki", "key"),
    _m("camion", "m", "camion", "ka.mjɔ̃", "ca-mion", "truck", "tɹʌk", "truck"),
    _m("crocodile", "m", "crocodile", "kʁɔ.kɔ.dil", "cro-co-dile", "crocodile", "ˈkɹɑ.kə.daɪl", "cro-co-dile"),
    _m("cadeau", "m", "cadeau", "ka.do", "ca-deau", "gift", "ɡɪft", "gift"),
    _m("sac", "m", "sac", "sak", "sac", "bag", "bæɡ", "bag"),
    _m("zebre", "m", "zèbre", "zɛbʁ", "zèbre", "zebra", "ˈzi.bɹə", "ze-bra"),
    _m("rose", "f", "rose", "ʁoz", "rose", "rose", "ɹoʊz", "rose"),
    _m("vase", "m", "vase", "vaz", "vase", "vase", "veɪs", "vase"),
    _m("ciseaux", "pl", "ciseaux", "si.zo", "ci-seaux", "scissors", "ˈsɪ.zɚz", "scis-sors"),
    _m("nez", "m", "nez", "ne", "nez", "nose", "noʊz", "nose"),
    _m("nuage", "m", "nuage", "nɥaʒ", "nuage", "cloud", "klaʊd", "cloud"),
    _m("nid", "m", "nid", "ni", "nid", "nest", "nɛst", "nest"),
    _m("banane", "f", "banane", "ba.nan", "ba-nane", "banana", "bə.ˈnæ.nə", "ba-na-na"),
    _m("lune", "f", "lune", "lyn", "lune", "moon", "mun", "moon"),
    _m("pomme", "f", "pomme", "pɔm", "pomme", "apple", "ˈæ.pəl", "ap-ple"),
    _m("pain", "m", "pain", "pɛ̃", "pain", "bread", "bɹɛd", "bread"),
    _m("papillon", "m", "papillon", "pa.pi.jɔ̃", "pa-pi-llon", "butterfly", "ˈbʌ.tɚ.flaɪ", "but-ter-fly"),
    _m("parapluie", "m", "parapluie", "pa.ʁa.plɥi", "pa-ra-pluie", "umbrella", "ʌm.ˈbɹɛ.lə", "um-brel-la"),
    _m("lapin", "m", "lapin", "la.pɛ̃", "la-pin", "rabbit", "ˈɹæ.bɪt", "rab-bit"),
    _m("soupe", "f", "soupe", "sup", "soupe", "soup", "sup", "soup"),
    _m("moto", "f", "moto", "mo.to", "mo-to", "motorbike", "ˈmoʊ.tɚ.baɪk", "mo-tor-bike"),
    _m("mouton", "m", "mouton", "mu.tɔ̃", "mou-ton", "sheep", "ʃip", "sheep"),
    _m("plume", "f", "plume", "plym", "plume", "feather", "ˈfɛ.ðɚ", "fea-ther"),
    _m("araignee", "f", "araignée", "a.ʁɛ.ɲe", "a-rai-gnée", "spider", "ˈspaɪ.dɚ", "spi-der"),
    _m("champignon", "m", "champignon", "ʃɑ̃.pi.ɲɔ̃", "cham-pi-gnon", "mushroom", "ˈmʌʃ.ɹum", "mush-room"),
    _m("peigne", "m", "peigne", "pɛɲ", "peigne", "comb", "koʊm", "comb"),
)


# Les noms du train des phrases (déjà dessinés) : leurs wagons, et l'API anglaise découpée.
# (Ceux qui sont aussi des mots du petit train — princesse, limace… — viennent du lexique du train.)
PHRASES = (
    # id du train des phrases, dessin, genre, fr, api fr, wagons fr, en, api en, wagons en
    _m("chat", "m", "chat", "ʃa", "chat", "cat", "kæt", "cat", dessin="fr.minouche"),
    _m("chien", "m", "chien", "ʃjɛ̃", "chien", "dog", "dɔɡ", "dog", dessin="fr.caniche"),
    _m("oiseau", "m", "oiseau", "wa.zo", "oi-seau", "bird", "bɝd", "bird", dessin="fr.perruche"),
    _m("souris", "f", "souris", "su.ʁi", "sou-ris", "mouse", "maʊs", "mouse", dessin="en.mouse"),
    _m("poisson", "m", "poisson", "pwa.sɔ̃", "pois-son", "fish", "fɪʃ", "fish", dessin="en.fish"),
    _m("oie", "f", "oie", "wa", "oie", "goose", "ɡus", "goose", dessin="en.goose"),
    _m("elan", "m", "élan", "e.lɑ̃", "é-lan", "moose", "mus", "moose", dessin="en.moose"),
    _m("vache", "f", "vache", "vaʃ", "vache", "cow", "kaʊ", "cow", dessin="fr.vache"),
    _m("biche", "f", "biche", "biʃ", "biche", "deer", "dɪɹ", "deer", dessin="fr.biche"),
    _m("autruche", "f", "autruche", "o.tʁyʃ", "au-truche", "ostrich", "ˈɑs.tɹɪtʃ", "os-trich", dessin="fr.autruche"),
    _m("radis", "m", "radis", "ʁa.di", "ra-dis", "radish", "ˈɹæ.dɪʃ", "ra-dish", dessin="en.radish"),
    _m("jus", "m", "jus", "ʒy", "jus", "juice", "dʒus", "juice", dessin="en.juice"),
    _m("assiette", "f", "assiette", "a.sjɛt", "a-ssiette", "plate", "pleɪt", "plate", dessin="en.dish"),
    _m("balle", "f", "balle", "bal", "balle", "ball", "bɔl", "ball", dessin="en.tennis"),
    _m("bus", "m", "bus", "bys", "bus", "bus", "bʌs", "bus", dessin="en.bus"),
    _m("peche", "f", "pêche", "pɛʃ", "pêche", "peach", "pitʃ", "peach", dessin="fr.peche"),
    _m("saucisse", "f", "saucisse", "so.sis", "sau-cisse", "sausage", "ˈsɔ.sɪdʒ", "sau-sage", dessin="fr.saucisse"),
    _m("glace", "f", "glace", "ɡlas", "glace", "ice cream", "ˈaɪs.kɹim", "ice-cream", dessin="fr.glace"),
    _m("os", "m", "os", "ɔs", "os", "bone", "boʊn", "bone", dessin="fr.os"),
    _m("tasse", "f", "tasse", "tas", "tasse", "cup", "kʌp", "cup", dessin="fr.tasse"),
    _m("brosse", "f", "brosse", "bʁɔs", "brosse", "brush", "bɹʌʃ", "brush", dessin="fr.brosse"),
    _m("cloche", "f", "cloche", "klɔʃ", "cloche", "bell", "bɛl", "bell", dessin="fr.cloche"),
    _m("trousse", "f", "trousse", "tʁus", "trousse", "pencil case", "ˈpɛn.səl.keɪs", "pen-cil-case",
       dessin="fr.trousse"),
    _m("fleche", "f", "flèche", "flɛʃ", "flèche", "arrow", "ˈæ.ɹoʊ", "ar-row", dessin="fr.fleche"),
    _m("buche", "f", "bûche", "byʃ", "bûche", "log", "lɔɡ", "log", dessin="fr.buche"),
    _m("carrosse", "m", "carrosse", "ka.ʁɔs", "ca-rrosse", "carriage", "ˈkæ.ɹɪdʒ", "car-riage",
       dessin="fr.carrosse"),
    _m("princesse", "f", "princesse", "pʁɛ̃.sɛs", "prin-cesse", "princess", "ˈpɹɪn.sɛs", "prin-cess",
       dessin="fr.princesse"),
    _m("limace", "f", "limace", "li.mas", "li-mace", "slug", "slʌɡ", "slug", dessin="fr.limace"),
    _m("mouche", "f", "mouche", "muʃ", "mouche", "fly", "flaɪ", "fly", dessin="fr.mouche"),
    _m("lou", "p", "Lou", "lu", "Lou", "Lou", "lu", "Lou", dessin="perso.lou"),
    _m("boite", "f", "boîte", "bwat", "boîte", "box", "bɑks", "box", dessin="lieu.boite"),
    _m("niche", "f", "niche", "niʃ", "niche", "doghouse", "ˈdɔɡ.haʊs", "dog-house", dessin="lieu.niche"),
    _m("maison", "f", "maison", "mɛ.zɔ̃", "mai-son", "house", "haʊs", "house", dessin="lieu.maison"),
    _m("table", "f", "table", "tabl", "table", "table", "ˈteɪ.bəl", "ta-ble", dessin="lieu.table"),
    _m("lit", "m", "lit", "li", "lit", "bed", "bɛd", "bed", dessin="lieu.lit"),
    _m("arbre", "m", "arbre", "aʁbʁ", "arbre", "tree", "tɹi", "tree", dessin="lieu.arbre"),
    _m("baignoire", "f", "baignoire", "bɛ.ɲwaʁ", "bai-gnoire", "bathtub", "ˈbæθ.tʌb", "bath-tub",
       dessin="lieu.baignoire"),
    _m("voiture", "f", "voiture", "vwa.tyʁ", "voi-ture", "car", "kɑɹ", "car", dessin="lieu.voiture"),
    # D'autres dessins du petit train.
    _m("douche", "f", "douche", "duʃ", "douche", "shower", "ˈʃaʊ.ɚ", "show-er", dessin="fr.douche"),
    _m("bouche", "f", "bouche", "buʃ", "bouche", "mouth", "maʊθ", "mouth", dessin="fr.bouche"),
    _m("ruche", "f", "ruche", "ʁyʃ", "ruche", "beehive", "ˈbi.haɪv", "bee-hive", dessin="fr.ruche"),
    _m("police", "f", "police", "pɔ.lis", "po-lice", "police car", "pə.ˈlis.kɑɹ", "po-lice-car", dessin="fr.police"),
    _m("cactus", "m", "cactus", "kak.tys", "cac-tus", "cactus", "ˈkæk.təs", "cac-tus", dessin="fr.cactus"),
    _m("cirque", "m", "cirque", "siʁk", "cirque", "circus", "ˈsɝ.kəs", "cir-cus", dessin="en.circus"),
    _m("glacon", "m", "glaçon", "ɡla.sɔ̃", "gla-çon", "ice", "aɪs", "ice", dessin="en.ice"),
    _m("puzzle", "m", "puzzle", "pœzl", "puzzle", "puzzle", "ˈpʌ.zəl", "puz-zle", dessin="en.piece"),
)

TOUS = NOUVEAUX + PHRASES
