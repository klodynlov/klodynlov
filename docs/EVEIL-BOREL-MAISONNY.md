# Suite Éveil — la méthode de Borel-Maisonny : gestes, bouches de Lou, progression

> **Gestes validés par l'orthophoniste le 06/10/2026, tels que dessinés sur la planche**
> (`docs/ui/eveil-app/11-gestes-lou.png`, `.pdf` à imprimer). Décision de l'utilisateur : Lou les montre,
> **animés**, dans les livres des sons et dans le petit train (français seulement) ; la planche reste
> consultable dans l'espace des grands (« La planche des gestes »).

## D'où ça vient

Une orthophoniste a vu l'app et a donné deux conseils :
1. s'appuyer sur la **méthode phonétique et gestuelle de Borel-Maisonny** (un geste par son), avec un avatar
   qui montre le geste et la façon de dire le son ;
2. **commencer par les mots d'une syllabe**, puis deux, et ainsi de suite.

Décisions de l'utilisateur : l'avatar est **Lou** (l'enfant du train des phrases), en grand, en portrait. Sa
bouche montre comment dire le son, sa main à cinq doigts fait le geste. **L'adulte choisit la couleur de peau**,
elle n'est jamais imposée.

## Sources et méthode

Les œuvres de Borel-Maisonny sont sous droits et ce dépôt est public. Tout ce qui suit est donc **reformulé
dans nos mots** : on ne cite que le livre et la page. Les pages sont celles **imprimées** dans le livre (l'index
de LibraryBrain compte les pages du PDF, soit page imprimée + 2 pour LOE I). Les réponses brutes et les extraits
restent en local, dans `eveil/librarybrain/resultats/borel/` (gitignoré).

| Abrév. | Œuvre | Ce qu'on y a trouvé |
|---|---|---|
| **LOE I** | S. Borel-Maisonny, *Langage oral et écrit, I. Pédagogie des notions de base*, Delachaux et Niestlé, 8ᵉ éd., 1985 | 30 leçons avec leurs gestes (p. 22-41) et un **atlas des gestes** dessinés (p. 60-90, fig. 2-27) |
| TLDM | S. Borel-Maisonny, *Les troubles du langage dans la déficience mentale et leur rééducation* (extrait, p. 133-155) | le rôle du geste (p. 146), le langage avant l'articulation (p. 141) |
| — | *Psychophysiologie du langage* (Pichon et Borel-Maisonny, 1939) | rien sur les gestes |
| — | *Analyse tomo-acoustique* et *Les dyslexies* (articles) | **illisibles** : PDF scannés sans texte (ils ne contiennent que le filigrane de téléchargement), à repasser à l'OCR |

**LibraryBrain** (`eveil/librarybrain/borel.py`, 8 questions par `/ask`, le 06/10/2026) a répondu « non
trouvé », ou n'a rien cité de Borel-Maisonny. La cause : le routage par livre garde en mémoire la liste des
vecteurs de livres depuis le démarrage du serveur (le 04/10). Les livres indexés le 05/10 y sont donc
invisibles tant que le serveur n'a pas redémarré (voir `klody_memory/retriever.py`). Leur texte est pourtant
bien dans l'index : on l'a relu directement, en lecture seule (passages et pages), et les figures de l'atlas
ont été lues sur les pages du PDF. On reposera les questions après un redémarrage, pour contrôle.

## Ce que dit Borel-Maisonny du geste (reformulé)

- Le geste sert d'**intermédiaire de mémoire** entre le son et la lettre. Il est attaché au son jusqu'à ce que
  l'enfant le dise sans réfléchir (LOE I, p. 18-19 ; TLDM, p. 146).
- Les gestes sont de **quatre sortes** : ceux qui dessinent la forme de la lettre (z, m, o), ceux qui rappellent
  l'articulation (r à la gorge, a main ouverte comme la bouche, l index dressé comme la langue), ceux qui
  montrent l'écoulement du son (f, le bras qui glisse), et de petites scènes (oi, le chien qui aboie)
  (LOE I, p. 18-19).
- **L'enfant refait le geste lui-même.** C'est la seule façon de vérifier qu'il l'a assimilé (LOE I, p. 22, 60).
- **On abandonne les gestes dès qu'ils ne servent plus** : quelques jours pour la plupart des enfants, plus
  longtemps pour les difficultés sévères (LOE I, p. 19, 33 ; à partir de la leçon XV, plus de nouveaux gestes).
- **Le sens compte.** Face à l'enfant, l'adulte enchaîne les gestes de sa droite vers sa gauche, pour que
  l'enfant les voie de gauche à droite, dans l'ordre de la lecture (LOE I, p. 19, 21, 30).
  → *Pour Lou, qui fait face à l'enfant à l'écran : à décider avec l'orthophoniste.*
- L'auteure insiste : une description ou un dessin ne suffit pas, **un geste s'apprend en le voyant faire**.
  L'atlas ne sert que d'aide-mémoire (LOE I, p. 60). → *C'est l'argument pour un Lou ANIMÉ plutôt qu'une image fixe.*

## Ce que dit Borel-Maisonny de la progression (reformulé)

- **Les consonnes qui se prolongent d'abord** (m, ch, s, l, v… : on peut les tenir), avec quelques voyelles,
  dès le premier jour. Les consonnes « instantanées » (p, t, k) viennent ensuite (leçons I et III, LOE I,
  p. 23, 25). Pour les enfants en difficulté, pas de syllabes avec p, t, b, d, k au début : on n'a pas le temps de
  les identifier (LOE I, p. 55).
- **Les sons faciles à confondre** (p et b, t et f…) ne s'apprennent jamais en même temps (LOE I, p. 23).
- **Les syllabes « directes » (consonne + voyelle) d'abord.** Les syllabes « inverses » (ouf, al) viennent plus
  tard, parce qu'en français la consonne finale est souvent muette (LOE I, p. 56-57).
- **Les groupes de consonnes** (fla, pri, ivre…) arrivent à la leçon X, après tous les sons simples (LOE I,
  p. 30), et les assemblages plus complexes encore après (leçon XII, p. 32).
- **La syllabe parlée** est travaillée une fois le mécanisme acquis (leçon XIX, LOE I, p. 35).
- Pas de nouveau son tant que les précédents ne sont pas bien sus. Le rythme est celui de l'enfant : les
  30 leçons prennent de six semaines à deux ans (LOE I, p. 22).
- Avant de lire, l'enfant doit bien prononcer. Mais faire des exercices d'articulation à un enfant qui n'a pas
  encore de langage ne sert à rien : la compréhension vient d'abord (LOE I, p. 16 ; TLDM, p. 141).

**Lien avec l'app.** Le petit train suit désormais le conseil n° 2 : une syllabe, puis deux, puis les groupes de
consonnes, puis tous les mots mêlés. On avance quand l'enfant réussit (`reference/wordend/policy.py`, règle 8).
Les livres des sons montrent les mots les plus courts d'abord. **À noter pour l'orthophoniste** : l'ordre de
Borel-Maisonny porte sur les **sons** (prolongeables avant instantanés) et sur la **forme de la syllabe** (directe
avant inverse) ; il n'est pas d'abord un compte de syllabes.

**Décision de l'utilisateur (06/10/2026) : ne plus se focaliser sur « ch » et « s ».** Le niveau 1 propose
les mots d'une syllabe de tous les sons, pris parmi les mots dessinés des livres (`python3 -m livres.train`) :
d'abord ceux qui finissent par une voyelle (jus, peau, dé, fée, lait, main, nez…, la syllabe « directe » de
Borel-Maisonny), avec un son d'attaque différent à chaque mot ; puis ceux qui finissent par une consonne (mur,
sac, lune, vert…), mêlés aux mots à fourgon (douche, vache…). Les mots sans fourgon
sont jugés sur leurs **syllabes**, comme dans les livres : le détecteur ne sait juger la consonne finale que pour
« ch » et « s ». La fin de « mur » (/ʁ/) n'est donc pas jugée par le micro.

## Les gestes et les bouches de Lou

Source de vérité : `eveil/outils/gestes/gestes.py`. « Bouche *(proposition)* » : le livre ne décrit pas la bouche
pour ce son ; c'est une proposition tirée de la phonétique courante du français, **à valider aussi**.

### Voyelles

| Son | Exemple | Main | Place | Mouvement | Évoque | Source | Bouche de Lou |
|---|---|---|---|---|---|---|---|
| **a** /a/ | vache | main ouverte, doigts écartés, paume tournée vers l'enfant | bras levé, la main à hauteur de la tête, loin du corps | on la tient immobile | la bouche grande ouverte | LOE I, p. 18, 24 ; atlas p. 61, fig. 2 | bouche grande ouverte |
| **o** /o/ | vélo | pouce et index joints en rond, les autres doigts serrés contre eux | devant soi, tourné vers l'enfant | aucun | la forme de la lettre o (et le son) | LOE I, p. 18, 24 ; atlas p. 63, fig. 4 (bas) | lèvres arrondies, ouverture moyenne *(proposition)* |
| **ou** /u/ | douche | d'abord le rond du o, puis deux doigts, puis la main qui rappelle le u | devant soi, le bras s'allonge pendant le son | geste lent en trois temps sur un seul son tenu | les deux lettres o et u ; le hurlement du loup | LOE I, p. 25 ; atlas p. 69, fig. 10 | lèvres très arrondies, petite ouverture *(proposition)* |
| **i** /i/ | niche | l'index seul dressé, les autres doigts repliés | avant-bras levé, coude contre le corps | aucun | la forme de la lettre i | LOE I, p. 24 ; atlas p. 68, fig. 9 | lèvres étirées, dents presque jointes *(proposition)* |
| **u** /y/ | ruche | index et majeur dressés et écartés, les autres repliés | devant soi, main levée | aucun | la forme de la lettre u (d'après la figure ; le texte ne le dit pas) | LOE I, atlas p. 67, fig. 8 | lèvres très arrondies, petite ouverture *(proposition)* |
| **é** /e/ | fée | main ouverte, doigts serrés, inclinée vers l'avant | posée sur le front, ou levée au-dessus de la tête, pointée en avant | aucun | l'accent aigu, penché vers l'avant | LOE I, p. 24 ; atlas p. 65, fig. 6 | lèvres étirées, dents presque jointes *(proposition)* |
| **è** /ɛ/ | pêche | main ouverte, doigts serrés | sur le sommet de la tête, rejetée en arrière ; la tête un peu levée | aucun | l'accent grave, penché vers l'arrière | LOE I, p. 26 ; atlas p. 66, fig. 7 | bouche à moitié ouverte, lèvres détendues |
| **eu** /ø/ | feu | l'index croisé sur le pouce | devant soi | aucun | la forme de la lettre œ | LOE I, p. 24, 28 ; atlas p. 63, fig. 4 (haut) | lèvres arrondies, ouverture moyenne *(proposition)* |
| **eu ouvert** /œ/ | fleur | l'index croisé sur le pouce | devant soi | aucun | la forme de la lettre œ | LOE I, p. 28 ; atlas p. 63, fig. 4 (haut) | bouche à moitié ouverte, lèvres détendues *(proposition)* |
| **e** /ə/ | cheval | l'index croisé sur le pouce (geste du eu) | devant soi | aucun | le geste du eu | LOE I, p. 29 (leçon IX) | bouche à moitié ouverte, lèvres détendues *(proposition)* |
| **an** /ɑ̃/ | orange | la main ouverte du a | portée sur le nez | aucun ; on accentue le son du nez | le a qui passe par le nez | LOE I, p. 24 ; atlas p. 62, fig. 3 | bouche grande ouverte *(proposition)* |
| **on** /ɔ̃/ | maison | le rond du o, doigts tendus pour bien montrer le cercle | au contact du nez | aucun | le o qui passe par le nez | LOE I, p. 24 ; atlas p. 64, fig. 5 | lèvres arrondies, ouverture moyenne *(proposition)* |
| **in** /ɛ̃/ | princesse | l'index du i dressé, poing fermé | devant le nez, au contact | aucun | le i qui passe par le nez | LOE I, p. 26 ; atlas p. 64 (remarque de la fig. 5) | lèvres étirées, dents presque jointes *(proposition)* |
| **oi** /wa/ | poisson | main fermée, puis ouverte d'un coup | devant soi | deux temps, au rythme d'un aboiement, sur une seule syllabe | la gueule du chien qui aboie ; le son qui finit comme un a (main ouverte) | LOE I, p. 19, 24 ; atlas p. 70, fig. 11 | lèvres arrondies, ouverture moyenne *(proposition)* |
| **oin** /wɛ̃/ | — | pouce, index et majeur allongés en bec | devant soi | le bec se ferme, s'ouvre, se referme (deux ou trois fois) | le bec du canard | LOE I, p. 24 ; atlas p. 71, fig. 12 | lèvres arrondies, ouverture moyenne *(proposition)* |

### Consonnes

| Son | Exemple | Main | Place | Mouvement | Évoque | Source | Bouche de Lou |
|---|---|---|---|---|---|---|---|
| **ch** /ʃ/ | douche | pouce et index écartés en pince, la courbe entre eux dessine un c | posés sur les deux joues | on garde la pose tout le temps du souffle | la lettre c (de ch) | LOE I, p. 23 ; atlas p. 76, fig. 16 | lèvres arrondies et poussées en avant, dents presque jointes *(proposition)* |
| **s** /s/ | tasse | l'index tendu | devant soi, sur le côté | lentement, on dessine un grand s en l'air tout le temps du sifflement | le serpent qui siffle ; la lettre s | LOE I, p. 23 ; atlas p. 74-75, fig. 15 | lèvres étirées, dents presque jointes *(proposition)* |
| **z** /z/ | fusée | l'index tendu | devant soi | un zigzag rapide, comme un éclair | le moustique en plein vol ; la lettre z ; la gorge vibre | LOE I, p. 18, 23 ; atlas p. 74-75, fig. 15 | lèvres étirées, dents presque jointes *(proposition)* |
| **j** /ʒ/ | girafe | l'index tendu | contre la joue | l'index s'avance vers la joue comme pour la piquer | la forme de la lettre j ; la gorge vibre | LOE I, p. 23 ; atlas p. 77, fig. 17 | lèvres arrondies et poussées en avant, dents presque jointes *(proposition)* |
| **f** /f/ | fée | main à plat | partant du milieu du corps | tout le bras glisse vers l'extérieur pendant le souffle | le souffle qui s'écoule ; la barre du f | LOE I, p. 19 ; atlas p. 72, fig. 13 | dents du haut posées sur la lèvre du bas *(proposition)* |
| **v** /v/ | vache | les deux mains, poignets joints, paumes ouvertes et écartées en V | devant soi ; un pouce peut aller vers la gorge | aucun | la forme de la lettre v ; la gorge vibre | LOE I, p. 23 ; atlas p. 73, fig. 14 | dents du haut posées sur la lèvre du bas *(proposition)* |
| **p** /p/ | pêche | le poing fermé, avant-bras levé | devant soi, en hauteur | le poing s'ouvre d'un coup au moment du « p » | la hampe et le rond de la lettre p ; l'explosion | LOE I, p. 25 ; atlas p. 81, fig. 20 | lèvres jointes |
| **b** /b/ | bouche | la main se ferme à moitié | en bas, presque à hauteur du ventre | le bras vient de l'extérieur vers le milieu du corps ; la main s'ouvre au « b » | le rond du b en bas de sa hampe ; la gorge vibre | LOE I, p. 26 ; atlas p. 82-83, fig. 21 | lèvres jointes |
| **t** /t/ | tasse | pouce et index qui pincent puis relâchent | en l'air, à hauteur de l'épaule | pincer, relâcher | pincer la barre du t | LOE I, p. 25 ; atlas p. 84-85, fig. 22 | bouche entrouverte, pointe de la langue derrière les dents du haut *(proposition)* |
| **d** /d/ | douche | le même pincement que t ; l'autre main fermée | l'autre main dans le bas du dos | pincer, relâcher | le rond du d derrière sa hampe ; la gorge vibre | LOE I, p. 32 ; atlas p. 84-85, fig. 22 | bouche entrouverte, pointe de la langue derrière les dents du haut *(proposition)* |
| **k** /k/ | cactus | l'index tendu | vers la bouche entrouverte | l'index s'avance vers la bouche au moment du « k » | la langue qui touche le fond du palais | LOE I, p. 25 ; atlas p. 86, fig. 23 | bouche entrouverte, langue en arrière (rien ne se voit à l'avant) |
| **g** /ɡ/ | glace | comme pour k, et le pouce | l'index vers la bouche, le pouce vers la gorge | comme pour k | comme k, avec la gorge qui vibre | LOE I, p. 34 ; atlas p. 87, fig. 24 | bouche entrouverte, langue en arrière (rien ne se voit à l'avant) *(proposition)* |
| **m** /m/ | mouche | pouce, index et majeur tendus, bouts posés à plat | sur une table | on appuie tant que dure le « mmm », on lève quand il s'arrête | la forme de la lettre m | LOE I, p. 18, 23 ; atlas p. 78-79, fig. 18 | lèvres jointes |
| **n** /n/ | niche | index et majeur | à cheval sur le nez | aucun | la forme de la lettre n ; le son qui passe par le nez | LOE I, p. 24 ; atlas p. 78-79, fig. 18 | bouche entrouverte, pointe de la langue derrière les dents du haut *(proposition)* |
| **gn** /ɲ/ | champignon | l'index | posé sur le nez | il glisse d'un côté du nez à l'autre | le son qui passe par le nez | LOE I, atlas p. 80, fig. 19 | bouche entrouverte, pointe de la langue derrière les dents du haut *(proposition)* |
| **l** /l/ | limace | l'index tendu vers le haut | devant la bouche | l'index monte, comme la pointe de la langue | la pointe de la langue levée ; la forme du l | LOE I, p. 18, 24 ; atlas p. 89, fig. 26 | bouche entrouverte, pointe de la langue derrière les dents du haut |
| **r** /ʁ/ | ruche | l'index replié | touche le côté du cou, sous la mâchoire | aucun : on sent la gorge qui gratte | « la lettre qui gratte » | LOE I, p. 18, 24 ; atlas p. 88, fig. 25 | bouche entrouverte, langue en arrière (rien ne se voit à l'avant) *(proposition)* |
| **ill** /j/ | grenouille | l'index tendu à l'horizontale | devant la bouche | il s'avance, comme le souffle qui sort | le souffle du son | LOE I, atlas p. 90, fig. 27 | lèvres étirées, dents presque jointes *(proposition)* |

### À trouver

| Son | Exemple | Main | Place | Mouvement | Évoque | Source | Bouche de Lou |
|---|---|---|---|---|---|---|---|
| **ui** /ɥ/ | nuage | à trouver | à trouver | à trouver | à trouver |  | bouche à moitié ouverte, lèvres détendues *(proposition)* |

## Points tranchés (validation du 06/10/2026 : « tels quels »)

Réponse : la planche est validée **telle quelle** — gn = geste de l'atlas ; Lou fait les gestes face à l'enfant,
sans les inverser ; d avec l'autre main dans le dos ; un seul geste pour o/ɔ et eu/œ ; les bouches « proposition »
sont acceptées ; « ui » reste sans geste (Lou montre seulement sa bouche) ; Lou est **animé**. Les questions
d'origine :

1. **Les gestes qui dessinent la LETTRE** (m, n, t, d, b, p, i, u, o, œ, s, z, v, ch) sont faits pour apprendre à
   **lire** (5-10 ans). L'app vise 3 ans et plus, à l'oral. Les garde-t-on tels quels, ou seulement ceux qui
   montrent l'articulation ?
2. **Gauche et droite** : Lou fait face à l'enfant. Fait-on le geste « en miroir », comme l'adulte face à la
   classe (LOE I, p. 19) ?
3. **Le d** se fait avec l'autre main **dans le dos** : c'est peu visible sur un portrait. Comment le montrer ?
4. **gn** : l'atlas (p. 80) et la leçon VII (p. 28) ne décrivent pas le même geste. Lequel garder ?
5. **o / ɔ, eu / œ, é / è** : le livre a un seul geste pour o et ɔ, un seul pour eu et œ, mais deux pour é et è.
   Cela convient-il à l'oral ?
6. **ui** (/ɥ/, « nuage », « parapluie ») : aucun geste trouvé. Il reste **à trouver**.
7. **Les bouches marquées « proposition »** : sont-elles justes ?
8. Faut-il un Lou **animé** (le geste en mouvement, l'auteure le recommande), ou une image fixe suffit-elle pour
   commencer ?
