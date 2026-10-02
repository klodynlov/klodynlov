"""Les pictos des VERBES du train des phrases : Lou fait l'action.

Un picto par verbe (identifiant `verbe.<infinitif>`, `_` pour l'espace), lisible par un
enfant de 3 ans en 90 × 90 points : une seule action, un accessoire au plus, des signes
de mouvement (traits, notes, Z, bulles) en bleu-gris doux. Plus `perso.lou` : Lou debout,
de face, qui sert de SUJET dans les scènes.

Niveau 1 et 3 (sans complément) : dormir, sauter, danser, courir, chanter, nager, voler,
tourner, rire, se cacher. Niveau 2 (avec complément) : manger, boire, pousser, porter,
lancer, laver, attraper, lécher, sentir, tirer — l'objet dessiné reste générique (le
complément a son propre picto).
"""
from __future__ import annotations

from coloriages.dessin import arc, cercle, courbe, ellipse, ligne, poly, rect, tube

from .accessoires import (BOIS, BOIS_FONCE, EAU, EAU_CLAIRE, SIGNE, ballon, bol, bulle, caisse, carton,
                          eclats, eponge, fleche_arc, fleur, goutte_eau, mousse, note, onde, petit_nuage, traits,
                          vitesse, zzz)
from .figure import PEAU, PEAU_OMBRE, Pose, atteindre, bouche, langue, lou, main, tete
from .peinture import Picto, ombre


# ---------------------------------------------------------------------------
# Lou, le sujet
# ---------------------------------------------------------------------------

def perso_lou() -> Picto:
    """Lou debout, de face, souriant, bras détendus (sans accessoire) : le SUJET des scènes."""
    p = Picto("perso.lou")
    ombre(p, 100, 180, 42, 6)
    lou(p, Pose(bras_g=(112, 98), bras_d=(68, 82)))
    return p


# ---------------------------------------------------------------------------
# Niveaux 1 et 3 : verbes sans complément
# ---------------------------------------------------------------------------

def dormir() -> Picto:
    """Lou couché dans son lit (vu de côté), la tête sur l'oreiller, les yeux fermés, « Z z z »."""
    p = Picto("verbe.dormir")
    ombre(p, 100, 180, 86, 6)
    # Le lit : tête de lit haute à gauche, pied de lit plus bas à droite, matelas, cadre.
    p.plein(BOIS, rect(16, 84, 23, 94, r=11), rect(163, 116, 21, 62, r=10))
    p.plein("#F4F7FC", rect(33, 124, 134, 26, r=9))
    p.plein(BOIS_FONCE, rect(31, 146, 138, 12, r=5))
    # L'oreiller, puis la tête posée dessus.
    p.plein("#DCE6F4", ellipse(56, 127, 27, 11))
    p.plein("#FFFFFF", ellipse(55, 123, 26, 11))
    tete(p, (58, 104), Pose(tete=-28, yeux="fermes", bouche="sourire"))
    # La couverture : épaule, hanche, pieds dessous ; elle retombe sur le côté du lit.
    couverture = [(72, 122), (84, 107), (108, 115), (128, 105), (146, 114), (158, 106), (168, 116),
                  (170, 157), (72, 157), (68, 134)]
    p.plein("#45B8A0", poly(couverture, r=[6, 12, 14, 14, 10, 8, 6, 6, 6, 6]))
    p.plein("#37A38C", rect(72, 149, 98, 8, r=4))
    # « Z z z » qui montent.
    for x, y, s in [(84, 72, 10), (104, 50, 13), (130, 24, 17)]:
        zzz(p, x, y, s)
    return p


def sauter() -> Picto:
    """Lou en l'air, bras levés, jambes pliées, petits traits dessous, ombre plus petite."""
    p = Picto("verbe.sauter")
    ombre(p, 100, 180, 32, 5)
    lou(p, Pose(sol=158, taille=0.88, bras_g=(-128, -112), bras_d=(-52, -68), jambe_g=(125, 55),
                jambe_d=(55, 125), bouche="ouverte"))
    traits(p, [((84, 164), (80, 174)), ((100, 166), (100, 176)), ((116, 164), (120, 174))])
    return p


def danser() -> Picto:
    """Lou sur une jambe, bras qui ondulent, notes de musique autour."""
    p = Picto("verbe.danser")
    ombre(p, 96, 180, 36, 5)
    lou(p, Pose(x=96, penche=-6, tete=10, bras_g=(-160, -95), bras_d=(15, -45), jambe_g=(93, 90),
                jambe_d=(20, 100), bouche="sourire"))
    note(p, 152, 50, 14, double=True)
    note(p, 34, 104, 12)
    return p


def courir() -> Picto:
    """Lou en pleine course : penché en avant, bras et jambes opposés, traits de vitesse derrière."""
    p = Picto("verbe.courir")
    ombre(p, 106, 180, 40, 5)
    lou(p, Pose(x=106, sol=168, penche=16, vers=0.6, bouche="ouverte", bras_g=(150, 95), bras_d=(30, -60),
                jambe_g=(30, 95), jambe_d=(130, 200)))
    vitesse(p, 50, 100, longueurs=(24, 30, 20), ecart=16)
    return p


def chanter() -> Picto:
    """Lou bouche ouverte, bras ouverts, des notes qui sortent de sa bouche."""
    p = Picto("verbe.chanter")
    ombre(p, 92, 180, 40, 6)
    pose = Pose(x=92, tete=-6, vers=0.4, bouche="ouverte", bras_g=(130, 175), bras_d=(50, 5))
    lou(p, pose)
    b = bouche(pose)
    # La voix qui sort : deux petits arcs contre la bouche, puis les notes qui s'envolent.
    p.trait(SIGNE, 3.4, arc(b[0], b[1], 22, -32, 28), arc(b[0], b[1], 29, -30, 26))
    note(p, b[0] + 44, b[1] - 4, 10)
    note(p, b[0] + 56, b[1] - 30, 13, double=True)
    return p


def nager() -> Picto:
    """Lou dans l'eau (vagues devant son corps), un bras hors de l'eau, des gouttes."""
    p = Picto("verbe.nager")
    # Lou à plat dans l'eau, la tête hors de l'eau (de face), le bras du dessus levé.
    pose = Pose(x=78, sol=170, taille=0.9, penche=88, cou=-30, tete=-76, bouche="sourire",
                bras_g=(-115, -60), bras_d=(150, 170), jambe_g=(182, 204), jambe_d=(178, 168))
    j = lou(p, pose)
    # L'eau par-dessus le corps : bord en vagues sous le menton.
    vagues = [(12, 124), (31, 118), (50, 124), (69, 118), (88, 124), (108, 119), (128, 128), (149, 123),
              (170, 127), (188, 121), (188, 168), (12, 168)]
    p.plein(EAU, poly(vagues, r=[4, 10, 10, 10, 10, 10, 10, 10, 10, 4, 10, 10]))
    p.plein(EAU_CLAIRE, *[rect(x, y, w, 5, r=2.5) for x, y, w in [(28, 138, 30), (84, 150, 36), (138, 140, 28)]])
    mousse(p, [(24, 120, 7), (36, 116, 6), (48, 121, 5)])
    m = j["main_g"]
    for dx, dy, r, a in [(-8, -10, 3.2, -25), (4, -14, 2.8, 15), (-16, 2, 2.8, -60)]:
        goutte_eau(p, m[0] + dx, m[1] + dy, r, angle=a)
    for x, y, a in [(18, 104, -30), (32, 100, 5)]:
        goutte_eau(p, x, y, 3, angle=a)
    return p


def voler() -> Picto:
    """L'idée de VOLER : deux ailes déployées, traits de vent, petits nuages."""
    p = Picto("verbe.voler")
    petit_nuage(p, 44, 160, 24)
    petit_nuage(p, 158, 152, 20)
    for sens in (1, -1):
        def m(pt, sens=sens):
            return (100 + sens * (pt[0] - 100), pt[1])
        # Cinq rémiges qui raccourcissent vers le corps (bord de fuite festonné), puis les
        # couvertures qui cachent leur départ le long du bord d'attaque.
        plumes = [((114, 100), (143, 42)), ((118, 104), (161, 53)), ((122, 108), (172, 70)),
                  ((124, 112), (171, 90)), ((124, 116), (160, 107))]
        for k, (a, b) in enumerate(plumes):
            p.plein(("#7DB1F0", "#9FC7F5")[k % 2], tube([m(a), m(b)], [26, 21]))
        p.plein("#CFE2FA", tube([m((116, 104)), m((127, 80)), m((141, 54))], [26, 20, 11]))
        # Battement : deux arcs le long du bout des plumes.
        a0, a1 = (-70, -30) if sens > 0 else (210, 250)
        p.trait(SIGNE, 4.2, arc(100 + sens * 16, 106, 79, a0, a1))
    onde(p, (72, 136), (128, 136), amplitude=4, bosses=4)
    return p


def tourner() -> Picto:
    """Lou sur la pointe des pieds, bras écartés, des flèches courbes qui tournent autour."""
    p = Picto("verbe.tourner")
    ombre(p, 100, 180, 30, 5)
    # Deux flèches qui se suivent autour des pieds (celle de derrière passe sous Lou),
    # et la traînée des mains qui balaient l'air.
    fleche_arc(p, 100, 170, 48, 10, 200, 340, SIGNE, 5.5, 11)
    lou(p, Pose(pointes=True, sol=163, taille=0.9, bras_g=(192, 205), bras_d=(-12, -25), jambe_g=(93, 90),
                jambe_d=(87, 90), bouche="sourire", tete=6))
    fleche_arc(p, 100, 170, 48, 10, 20, 160, SIGNE, 5.5, 11)
    p.trait(SIGNE, 4.5, arc(100, 88, 70, 136, 170, 26), arc(100, 88, 70, -44, -10, 26))
    return p


def rire() -> Picto:
    """Lou rit aux éclats, se tient le ventre, petits traits de joie autour de la tête."""
    p = Picto("verbe.rire")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(penche=-3, tete=-8, yeux="rieurs", bouche="rire", devant=("bras_g", "bras_d"))
    pose.bras_g = atteindre(pose, "bras_g", (90, 118), pli=1)
    pose.bras_d = atteindre(pose, "bras_d", (110, 118), pli=-1)
    j = lou(p, pose)
    c = j["tete"]
    eclats(p, c[0], c[1], 35, 45, [-172, -150, -128, -52, -30, -8])
    return p


def se_cacher() -> Picto:
    """Lou caché derrière un buisson : seuls le haut de la tête, les yeux et deux mains dépassent."""
    p = Picto("verbe.se_cacher")
    ombre(p, 100, 180, 82, 6)
    tete(p, (100, 84), Pose(regard=(1.4, 0.2)))
    fonce, clair = "#3F9E57", "#57B96A"
    # Le buisson : bosses hautes sur les côtés, dessus plus bas au milieu (sous les yeux).
    p.plein(fonce, cercle(44, 132, 28), cercle(156, 132, 28), cercle(60, 104, 22), cercle(140, 104, 22),
            rect(70, 94, 60, 40, r=10), rect(18, 118, 164, 60, r=24))
    p.plein(clair, cercle(49, 140, 22), cercle(151, 140, 22), cercle(65, 112, 16), cercle(135, 112, 16),
            rect(78, 104, 44, 30, r=10), rect(28, 132, 144, 44, r=18))
    # Deux mains agrippées au bord, doigts marqués.
    for x in (69, 131):
        p.plein(PEAU, ellipse(x, 91, 9, 7))
        p.trait(PEAU_OMBRE, 1.5, ligne((x - 3, 87), (x - 3, 92)), ligne((x + 1.5, 87), (x + 1.5, 92)))
    return p


# ---------------------------------------------------------------------------
# Niveau 2 : verbes avec complément
# ---------------------------------------------------------------------------

def manger() -> Picto:
    """Lou porte une cuillère à sa bouche, un bol dans l'autre main."""
    p = Picto("verbe.manger")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(bouche="o", vers=0.15)
    pose.bras_d = atteindre(pose, "bras_d", (126, 86), pli=1)
    pose.bras_g = atteindre(pose, "bras_g", (80, 128), pli=1)
    lou(p, pose)
    bol(p, 80, 112, 22, "#4FA3E8", "#F5A742")
    main(p, (80, 128))
    b = bouche(pose)
    p.plein("#B9C4D4", tube([(126, 86), (b[0] + 8, b[1] + 3)], [4.5, 3.5]))
    p.plein("#B9C4D4", ellipse(b[0] + 3, b[1] + 1, 6.5, 4.5, rot=-30))
    p.plein("#F5A742", ellipse(b[0] + 3, b[1] - 0.5, 4.5, 2.5, rot=-30))
    main(p, (126, 86))
    return p


def boire() -> Picto:
    """Lou boit à un verre avec une paille."""
    p = Picto("verbe.boire")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(bouche="o", vers=0.25, regard=(0.6, 0.8))
    pose.bras_d = atteindre(pose, "bras_d", (128, 104), pli=1)
    lou(p, pose)
    b = bouche(pose)
    p.plein("#FF6B8B", tube([(136, 96), (b[0] + 2, b[1] + 1)], 4))
    p.plein("#DDEFFC", poly([(114, 80), (142, 80), (138, 116), (118, 116)], r=3))
    p.plein("#FFA53D", poly([(116, 90), (140, 90), (138, 114), (118, 114)], r=2))
    p.plein("#FFFFFFAA", rect(119, 84, 4, 26, r=2))
    main(p, (128, 106))
    return p


def pousser() -> Picto:
    """Lou penché en avant pousse une grosse caisse ; traits de mouvement."""
    p = Picto("verbe.pousser")
    ombre(p, 104, 180, 80, 6)
    pose = Pose(x=62, taille=0.9, penche=30, vers=0.55, yeux="plisses", bouche="fermee",
                jambe_g=(125, 122), jambe_d=(72, 100))
    pose.bras_g = atteindre(pose, "bras_g", (116, 104), pli=-1)
    pose.bras_d = atteindre(pose, "bras_d", (116, 120), pli=1)
    lou(p, pose)
    caisse(p, 116, 98, 68, 80)
    main(p, (118, 104), pose)
    main(p, (118, 120), pose)
    vitesse(p, 36, 72, longueurs=(12, 16, 12), ecart=13)
    return p


def porter() -> Picto:
    """Lou porte un carton dans ses bras."""
    p = Picto("verbe.porter")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(bouche="sourire", jambe_g=(100, 92), jambe_d=(80, 88))
    pose.bras_g = atteindre(pose, "bras_g", (70, 134), pli=1)
    pose.bras_d = atteindre(pose, "bras_d", (130, 134), pli=-1)
    lou(p, pose)
    carton(p, 66, 90, 68, 48)
    main(p, (70, 134))
    main(p, (130, 134))
    return p


def lancer() -> Picto:
    """Lou lance un ballon : bras levé vers l'avant, pointillés de la trajectoire."""
    p = Picto("verbe.lancer")
    ombre(p, 74, 180, 40, 6)
    pose = Pose(x=70, penche=8, vers=0.6, bouche="ouverte", regard=(1, -0.6), bras_g=(160, 150),
                bras_d=(-40, -50), jambe_g=(112, 95), jambe_d=(62, 98))
    j = lou(p, pose)
    m = j["main_d"]
    for t in (0.22, 0.42, 0.62):
        x = m[0] + (160 - m[0]) * t
        y = m[1] + (40 - m[1]) * t - 18 * (1 - (2 * t - 1) ** 2)
        p.plein(SIGNE, cercle(x, y, 3.2))
    ballon(p, 164, 40, 16)
    return p


def laver() -> Picto:
    """Une éponge qui frotte, de la mousse, des bulles de savon et des gouttes d'eau."""
    p = Picto("verbe.laver")
    ombre(p, 100, 180, 66, 6)
    mousse(p, [(56, 150, 17), (80, 142, 21), (108, 140, 22), (134, 146, 19), (150, 156, 14), (94, 158, 18),
               (68, 162, 13), (124, 162, 14)])
    eponge(p, 100, 118, 82, 46, angle=-10)
    # Frotter : de petits arcs de part et d'autre de l'éponge.
    p.trait(SIGNE, 4.2, arc(100, 118, 56, 160, 200, 34), arc(100, 118, 56, -20, 20, 34))
    for x, y, r in [(46, 80, 10), (66, 52, 14), (142, 70, 12), (160, 40, 8), (100, 30, 7), (34, 112, 6)]:
        bulle(p, x, y, r)
    for x, y, r in [(170, 108, 4), (176, 128, 3.5), (26, 150, 3.5)]:
        goutte_eau(p, x, y, r)
    return p


def attraper() -> Picto:
    """Lou tend les bras vers un ballon qui arrive (traits derrière le ballon)."""
    p = Picto("verbe.attraper")
    ombre(p, 80, 180, 40, 6)
    pose = Pose(x=76, penche=6, vers=0.6, bouche="o", regard=(1.2, 0), jambe_g=(102, 95), jambe_d=(76, 85))
    pose.bras_g = atteindre(pose, "bras_g", (124, 94), pli=1)
    pose.bras_d = atteindre(pose, "bras_d", (130, 106), pli=1)
    lou(p, pose)
    ballon(p, 150, 96, 16)
    vitesse(p, 172, 96, longueurs=(8, 12, 8), ecart=11, sens=1)
    return p


def lecher() -> Picto:
    """Lou lèche une glace tenue à la main (langue tirée sur la boule)."""
    p = Picto("verbe.lecher")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(bouche="o", vers=0.45, regard=(1.0, 0.3))
    pose.bras_d = atteindre(pose, "bras_d", (128, 100), pli=1)
    lou(p, pose)
    # La glace tenue à côté du visage : cornet, boule, une coulure.
    p.plein("#E9A95B", poly([(116, 74), (140, 74), (128, 112)], r=[4, 4, 3]))
    p.trait("#C98433", 2, ligne((121, 82), (131, 100)), ligne((135, 82), (125, 100)))
    p.plein("#F7A1C4", cercle(128, 68, 13), ellipse(121, 78, 4.5, 6))
    main(p, (128, 100))
    langue(p, pose, longueur=1.5, angle=12)
    return p


def sentir() -> Picto:
    """Lou sent une fleur tenue près du nez, les yeux fermés de plaisir, ondes de parfum."""
    p = Picto("verbe.sentir")
    ombre(p, 100, 180, 42, 6)
    pose = Pose(yeux="fermes", bouche="sourire", nez=True, vers=0.35, tete=6)
    pose.bras_d = atteindre(pose, "bras_d", (135, 100), pli=1)
    lou(p, pose)
    p.trait("#4CAF50", 3.4, courbe([(135, 100), (134, 86), (130, 72)]))
    p.plein("#5CBF60", ellipse(140, 88, 7, 3.5, rot=-30))
    fleur(p, 129, 66, 13)
    main(p, (135, 100))
    # Le parfum qui monte de la fleur, à côté de la tête (pas sur les cheveux).
    for depart, arrivee in (((128, 49), (131, 21)), ((140, 52), (151, 27))):
        onde(p, depart, arrivee, amplitude=2.6, bosses=3, couleur="#E48BC0", largeur=3.2)
    return p


def tirer() -> Picto:
    """Lou penché en arrière tire une corde attachée à un petit chariot."""
    p = Picto("verbe.tirer")
    ombre(p, 100, 180, 84, 6)
    pose = Pose(x=136, taille=0.9, penche=18, vers=-0.6, yeux="plisses", bouche="fermee",
                jambe_g=(118, 108), jambe_d=(82, 96))
    pose.bras_g = atteindre(pose, "bras_g", (102, 116), pli=-1)
    pose.bras_d = atteindre(pose, "bras_d", (108, 114), pli=1)
    # Le chariot (à gauche) et sa corde tendue jusqu'aux mains.
    p.trait("#9C6B3F", 3, ligne((74, 142), (102, 116)))
    p.plein("#E8414B", rect(26, 126, 48, 28, r=5))
    p.plein("#C73340", rect(26, 126, 48, 7, r=3))
    p.plein("#3A3F5C", cercle(38, 160, 10), cercle(64, 160, 10))
    p.plein("#C8CDE0", cercle(38, 160, 4), cercle(64, 160, 4))
    lou(p, pose)
    main(p, (102, 116), pose)
    vitesse(p, 23, 140, longueurs=(7, 9, 7), ecart=10, sens=-1)
    return p


PICTOS = [
    perso_lou(),
    dormir(), sauter(), danser(), courir(), chanter(), nager(), voler(), tourner(), rire(), se_cacher(),
    manger(), boire(), pousser(), porter(), lancer(), laver(), attraper(), lecher(), sentir(), tirer(),
]
