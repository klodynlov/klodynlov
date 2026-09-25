# Suite Éveil — LibraryBrain face à la passe cloud

> Application du [protocole de comparaison](../eveil/librarybrain/COMPARAISON.md), figé le 25/09/2026
> **avant** toute réponse de LibraryBrain. Compagnon de [`EVEIL-SOURCES.md`](EVEIL-SOURCES.md)
> (passe cloud du 24/09/2026, 168 affirmations). Les réponses brutes, les passages et les codes
> restent **locaux** (`eveil/librarybrain/resultats/`, ignoré par git) : ce sont des extraits
> d'ouvrages sous droits, et ce dépôt est public.

## En bref

- **Couverture** : LibraryBrain trouve de quoi répondre à **11 questions sur 33** avec la
  bibliothèque telle quelle (33 %, IC 95 % 20–50 %), et à **15 sur 33** une fois ajoutés 17 PDF de la
  passe cloud (45 %, IC 95 % 30–62 %).
- **Accord** : **aucune contradiction** avec la passe cloud. Sur les 6 témoins où il prend position
  (P1), LibraryBrain donne le même verdict 3 fois sur 6 en lecture stricte (κ = 0,33) et 6 fois sur 6
  en lecture souple ; les 3 écarts sont des « nuance » face à des « confirmé ».
- **Apport** : **A22 fermé** (critères HAS/ANAES de repérage et d'orientation), vérifié dans le texte.
  17 **sources nouvelles**, dont le rapport et le guide HAS *Bilan de santé en école maternelle*
  (avril 2026) et le texte des recommandations ANAES 2001. Le texte intégral change le codage de
  8 questions (7 gains, 1 perte).
- **Limite principale** : la bibliothèque ne contient presque aucune des **sources primaires**
  nommées par les questions (McLeod & Crowe, de Jong & Wempe, Lee et al., Nissen & Fox, Lynn,
  Beery…), et le modèle de LibraryBrain **refuse** souvent même quand ses passages franchissent le
  filtre de pertinence (6 refus de ce type sur 22).

## 1. Méthode

### 1.1 Conditions

| | |
|---|---|
| Dates | P0 le 25/09/2026, 08:59–09:15 · P0b 09:25–09:40 · dépôt des PDF 09:40 → indexés à 09:46 · P1 09:46–10:00 · codes figés à 10:08 · comparaison ensuite |
| LibraryBrain, P0 | service `com.librarybrain.server` démarré le 21/09/2026 09:13, sur le commit `14132cb` (HEAD d'alors, d'après le reflog) |
| LibraryBrain, P0b et P1 | redémarré (`launchctl kickstart -k`) sur `cddae68` + modifications non commitées d'une autre session (77 fichiers suivis, dont le chemin RAG). Avant redémarrage : import de l'application vérifié, aucune migration en attente (la 027 était appliquée depuis le 15/09), gate régressif de LibraryBrain au vert (refus 19/19, catégories 15/16, comme la référence ; génération non couverte par ce gate) |
| Modèle de génération | `unsloth/Qwen3.6-35B-A3B-MLX-8bit` par la passerelle Klody Core (:8090), 2 048 jetons au plus, température par défaut du serveur, préchauffé avant chaque passe |
| Recherche | plongements `BAAI/bge-m3` ; reclassement `BAAI/bge-reranker-v2-m3`, **refus sous 0,40** ; 5 passages cœur, au moins 10 livres distincts ; jambe translingue FR → EN ; réécriture de la requête sur refus ; routage sur 80 livres ; recherche web désactivée |
| Index | P0 et P0b : **25 773 documents, 1 845 382 passages** · P1 : **25 790 documents, 1 846 929 passages** (+ 17 PDF, + 1 547 passages) |

**Contrôle anti-contamination** (avant P0, en lecture seule dans la base) : aucune occurrence de
« Suite Éveil », « Petit Train des mots », « 168 affirmations », « OrthoSpeech » ni « EVEIL-SOURCES »
dans les 1,85 million de passages ; ce dépôt n'est pas indexé ; aucune des 28 sources de
`sources.json` n'était déjà présente. **P0 est donc une preuve indépendante de la passe cloud.**

### 1.2 Déroulé

1. **Interroger** : [`interroger.py`](../eveil/librarybrain/interroger.py) pose les 33 questions de
   [`questions.md`](../eveil/librarybrain/questions.md) **mot pour mot**, par les routes des pages
   (`/ask` → `GET /api/ask/stream`, format « explication », sans catégorie ni niveau, un fil neuf par
   question ; `/consensus` → `POST /api/consensus`, toutes catégories), 5 s entre deux questions.
   L'API ne rendant que titre, auteur et page, les **passages** sont relus en lecture seule dans la
   base de LibraryBrain. Trois passes : **P0** (bibliothèque telle quelle), **P0b** (idem après
   redémarrage, § 1.3), **P1** (+ les PDF de `sources.json`).
2. **Coder à l'aveugle**, d'après les passages et non d'après le texte généré : douze lots codés par
   des **codeurs indépendants, sans accès au dépôt** (sous-agents lancés hors du dépôt, sans même le
   `CLAUDE.md` qui résume quelques conclusions), sur une grille commune (§ 1.4). Revue de cohérence
   par l'agent principal, **sans modifier aucun code**. Codes figés (empreinte SHA-256 `29a2294a…`)
   **avant** l'ouverture de `EVEIL-SOURCES.md`.
3. **Vérifier dans le document d'origine** : chaque passage appuyant un SOURCÉ de Q1–Q18 ou une prise
   de position sur un témoin a été retrouvé dans le fichier source (texte de la page du PDF, OCR pour
   un scan, lecture directe des fichiers Markdown) — 15 vérifications, toutes positives.
4. **Comparer** : jointure par identifiant avec `EVEIL-SOURCES.md`, mesures par
   [`mesurer.py`](../eveil/librarybrain/mesurer.py) (`cohen_kappa` et `wilson` du banc de validation).

### 1.3 Écarts au protocole

1. **Passe de contrôle P0b ajoutée** (accord de l'utilisateur). P1 imposait de redémarrer le serveur :
   le routage par livre garde sa matrice en mémoire, et les livres ajoutés restent invisibles sans
   redémarrage. Or redémarrer changeait aussi le **code** servi (§ 1.1). P0 → P0b mesure l'effet du
   code ; P0b → P1 celui du texte intégral. **Résultat : aucun effet du code** (codes identiques sur
   les 33 questions).
2. **Sources absentes de P1** (accord de l'utilisateur) : A3 (connexion refusée), A5 et A6
   (McLeod & Crowe, refus 403 de l'éditeur), A18 (404), B25 (403) ; et les six sources de type
   « page » (A16, B8, B10, B17, B24, C1), non enregistrées en PDF. P1 compte donc **17 des 28**
   sources. F24 (56 Mo) a dû être repris par `curl -C -` après deux transferts tronqués, ce qui a mis
   au jour un défaut de `recuperer_sources.py` (corrigé).
3. **Interrogation par script** plutôt que dans le navigateur, aux mêmes routes et paramètres ; le
   modèle est préchauffé par un appel direct à la passerelle, hors LibraryBrain.
4. **Rattachement des passages** : un renvoi « Source i, p. X » est relié par la page (le prompt de
   LibraryBrain réordonne ses passages) ; un renvoi sans page, ou « Livre N » en mode consensus, ne
   désigne que le premier passage du livre. Les codeurs ont donc lu tous les passages récupérés.
5. **Codeurs** : des modèles, pas des humains — un codeur par question et par passe. Fidélité
   mesurée quand même : les réponses de P0 et P0b sont **identiques au caractère près** (génération
   reproductible, graine fixée) ; codées par des codeurs différents, sans accès l'un à l'autre, elles
   reçoivent les **mêmes codes sur les 33 questions**.
6. **Journalisation** : chaque question `/ask` s'inscrit dans le `query_log` de LibraryBrain
   (24 questions × 3 passes = 72 entrées), comme depuis le navigateur ; `/api/consensus` ne
   journalise rien.

### 1.4 Grille de codage

Le protocole définit SOURCÉ comme « au moins un passage cité et pertinent » ; pour distinguer PARTIEL,
la grille précise :

- **SOURCÉ** : un passage répond **directement au cœur** de la question (le fait précis demandé) et
  la réponse s'appuie dessus. **PARTIEL** : une partie seulement de la question, ou une réponse
  indirecte (sujet voisin, autre âge, **autre source que celle nommée**). **NON TROUVÉ** : refus, ou
  rien de pertinent.
- **Position** (témoins) par rapport à la proposition : **SOUTIENT** (tous ses éléments clés) ·
  **NUANCE** (une partie, ou avec des réserves qui en changent la portée) · **CONTREDIT** (un élément
  clé incompatible) · **NON TROUVÉ**.
- En cas de doute, le niveau le plus bas. Les hésitations déclarées donnent la fourchette du § 3.4.

## 2. Question par question

S = sourcé · P = partiel · NT = non trouvé · ✓ = passages retrouvés dans le document d'origine.
Causes des écarts (protocole) : (a) texte intégral contre résumé · (b) autre source · (c) raté de
récupération · (d) erreur de la passe cloud · (e) citation introuvable.

| Q | Id | Verdict cloud | P0 | P0b | P1 | Accord | Cause | Action |
|---|---|---|---|---|---|---|---|---|
| 1 | A22 | NON VÉRIFIÉ | S ✓ | S ✓ | S ✓ | — | — | **A22 fermé** (§ 4) |
| 2 | A22 | NON VÉRIFIÉ | P | P | S ✓ | — | — | A22 fermé (complément ANAES 2001) |
| 3 | A20 | NON VÉRIFIÉ | NT | NT | NT | — | (c) | Reste NON VÉRIFIÉ ; piste : HAS 2005 p. 87 (§ 5.3) ; acquérir Coplan & Gleason 1988, Hustad et al. 2021 |
| 4 | A23 | NON VÉRIFIÉ | P | P | NT | — | (c) | Reste NON VÉRIFIÉ ; prévalences voisines seulement (HAS 2005) ; en P1, refus malgré Beitchman 1986 cité par Brosseau-Lapré |
| 5 | A21 | NON VÉRIFIÉ | NT | NT | NT | — | — | Acquérir les documents Eduscol de maternelle |
| 6 | A18 | NON VÉRIFIÉ | NT | NT | NT | — | — | EVALO décrit (HAS 2009), sans normes ; acquérir le manuel EVALO 2-6 |
| 7 | A19 | NON VÉRIFIÉ | P | P | P | — | (b) | Reste NON VÉRIFIÉ ; piste : HAS 2009 (surdité) recommande d'évaluer dans chaque langue |
| 8 | C13 | NON VÉRIFIÉ | NT | NT | NT | — | — | Acquérir Nissen & Fox, Holliday et al. |
| 9 | C20 | NON VÉRIFIÉ | NT | NT | NT | — | — | Aucune source dans la bibliothèque |
| 10 | B27 | NON VÉRIFIÉ | P | P | P | — | (b) | Reste NON VÉRIFIÉ ; pistes : HAS 2021 (3-6-9-12), AAP cité par StatPearls (§ 5.3) |
| 11 | B27 | NON VÉRIFIÉ | NT | NT | NT | — | — | Acquérir Lynn 1986, Polit & Beck 2006 |
| 12 | F24 | NON VÉRIFIÉ | P | P | P | — | (b) | Reste NON VÉRIFIÉ (manuel Beery) ; piste : âges des figures chez Le Métayer (§ 5.3) |
| 13 | F29 | NON VÉRIFIÉ | NT | NT | NT | — | — | Acquérir Fun Toolkit, *This or That* |
| 14 | B8, B15 | RÉFUTÉ, NUANCÉ | NT | NT | NT | — | — | Inchangé |
| 15 | B14 | NON VÉRIFIÉ | NT | NT | P | — | (b) | Reste NON VÉRIFIÉ : Maas et al. 2008 traite des troubles **moteurs** de la parole |
| 16 | C18 | NON VÉRIFIÉ | P | P | P | — | (b) | Reste NON VÉRIFIÉ : appui indirect (Huang & Benesty 2004) |
| 17 | F27, F28 | NON VÉRIFIÉ | P | P | P | — | — | Sujets voisins seulement ; acquérir Gerth 2016, Alamargot & Morin 2015 |
| 18 | A2 | NUANCÉ | P | P | S ✓ | concordant | — | A2 inchangé ; appui en texte intégral : Kehoe 2021 (§ 5.2) |
| 19 | A1 | CONFIRMÉ | P · nuance ✓ | P · nuance ✓ | P · nuance ✓ | souple seulement | (b) | A1 inchangé (§ 5.1) |
| 20 | A3 | NUANCÉ | NT | NT | NT | — | — | — |
| 21 | A6 | CONFIRMÉ | NT | NT | S · soutient ✓ | **strict** | — | A6 désormais lu en texte intégral |
| 22 | A10 | CONFIRMÉ | NT | NT | NT | — | — | McLeod & Crowe à acquérir (PDF refusé) |
| 23 | B2 | NUANCÉ | NT | NT | P · nuance ✓ | **strict** | — | — |
| 24 | B8 | RÉFUTÉ | NT | NT | NT | — | — | — |
| 25 | B25 | CONFIRMÉ | P · nuance ✓ | P · nuance ✓ | P · nuance ✓ | souple seulement | (c) | B25 tient ; précision proposée (§ 5.1) |
| 26 | C4 | RÉFUTÉ | NT | NT | NT | — | — | — |
| 27 | C6 | CONFIRMÉ | NT | NT | P · nuance ✓ | souple seulement | (a) | C6 tient ; précision proposée (§ 5.1) |
| 28 | C9 | CONFIRMÉ | NT | NT | NT | — | — | de Jong & Wempe 2009 à acquérir |
| 29 | C17 | RÉFUTÉ | NT | NT | P · contredit ✓ | **strict** | — | Réfutation retrouvée en texte intégral |
| 30 | E10 | RÉFUTÉ | NT | NT | NT | — | — | — |
| 31 | E12 | CONFIRMÉ | NT | NT | NT | — | — | Refus du modèle ; acquérir le règlement (UE) 2017/745 et MDCG 2019-11 |
| 32 | E14 | NUANCÉ | NT | NT | NT | — | — | — |
| 33 | F25 | NUANCÉ | NT | NT | NT | — | — | — |

## 3. Mesures

### 3.1 Couverture et NON VÉRIFIÉ fermés

| Passe | Couverture (sourcé + partiel) | IC 95 % (Wilson) | NON VÉRIFIÉ fermés |
|---|---|---|---|
| P0 | 11/33 (33 %) | 20 – 50 % | 1 question (Q1) → A22 |
| P0b | 11/33 (33 %) | 20 – 50 % | 1 question (Q1) → A22 |
| P1 | 15/33 (45 %) | 30 – 62 % | 2 questions (Q1, Q2) → A22 |

Sur les 18 premières questions (celles qui visaient des NON VÉRIFIÉ), un seul identifiant se ferme,
A22. Les autres couvertures sont **partielles** : la bibliothèque parle du sujet, rarement de la
source ou du chiffre demandés.

### 3.2 Accord sur les témoins

| Passe | Lecture | Témoins avec position | Accord | κ de Cohen | Paires (LibraryBrain, cloud) |
|---|---|---|---|---|---|
| P0 / P0b | stricte | 2/15 | 0 % | 0,00 | (nuancé, confirmé) × 2 |
| P0 / P0b | souple | 2/15 | 100 % | non défini (une seule classe) | (tient, tient) × 2 |
| P1 | stricte | 6/15 | 50 % | 0,33 | (confirmé, confirmé) × 1 · (nuancé, confirmé) × 3 · (nuancé, nuancé) × 1 · (réfuté, réfuté) × 1 |
| P1 | souple | 6/15 | 100 % | 1,00 | (tient, tient) × 5 · (réfuté, réfuté) × 1 |

*Stricte* : trois classes (soutient ↔ confirmé, nuance ↔ nuancé, contredit ↔ réfuté). *Souple* :
tient (soutient ou nuance ; confirmé ou nuancé) contre réfuté. Avec n = 6, ces chiffres sont
**indicatifs**. Ce qui compte : **aucun témoin n'est contredit**, et le seul réfuté que LibraryBrain
aborde (C17) est retrouvé réfuté.

### 3.3 Apport du texte intégral (P0b → P1) et effet du code (P0 → P0b)

- **P0 → P0b : aucun codage ne change.** Les réponses sont identiques au caractère près, les
  sources identiques pour 32 questions sur 33 : le code servi par LibraryBrain n'a pas d'effet
  mesurable ici.
- **P0b → P1 : 8 codages changent**, 7 en mieux :
  - **Q2** P → S (texte des recommandations ANAES 2001 retrouvé) ;
  - **Q15** NT → P ;
  - **Q18** P → S (Kehoe 2021) ;
  - **Q21** NT → S, soutient (Kehoe 2021) ;
  - **Q23** NT → P, nuance (Allen 2013) ;
  - **Q27** NT → P, nuance (articles ASR) ;
  - **Q29** NT → P, contredit (corpus MyST, Smith 2025).

  Un seul en moins bien : **Q4** P → NT. Le modèle refuse désormais, alors qu'un passage cite une
  prévalence (Beitchman 1986, 11 %).
- 4 questions passent de refus à réponse (Q15, Q23, Q27, Q29), 2 en sens inverse (Q3, Q4).

### 3.4 Sensibilité aux hésitations des codeurs

Si l'on tranche vers le bas toutes les hésitations déclarées, et à l'inverse vers le haut :

| Passe | Couverture codée | Fourchette | Hésitations déclarées |
|---|---|---|---|
| P0 | 11/33 | 7 – 14 | Q17, Q18, Q19, Q25 (partiel ou non trouvé) ; Q3, Q6, Q21 (non trouvé ou partiel) |
| P1 | 15/33 | 13 – 16 | Q16, Q17 (partiel ou non trouvé) ; Q6 (non trouvé ou partiel) ; Q2 (sourcé ou partiel) ; Q25, Q27 (partiel ou sourcé) |

La conclusion tient dans toute la fourchette : couverture réelle mais minoritaire, en progrès avec le
texte intégral.

### 3.5 Pourquoi LibraryBrain ne trouve pas (22 NON TROUVÉ en P0)

| Motif | P0 | Lecture |
|---|---:|---|
| Filtre de pertinence (reclassement < 0,40) | 9 | la bibliothèque ne contient rien d'assez proche |
| Refus du modèle alors que le filtre passe (0,55 à 0,92) | 6 | passages voisins jugés insuffisants — prudent, mais parfois à tort (§ 5.3) |
| Refus en mode consensus | 4 | sans passage exposé par l'API : invérifiable |
| Réponse négative (« les sources ne contiennent pas… ») | 3 | honnête, rien à côté |

Trois réponses (Q2, Q10, Q17 en P0) contiennent en outre des **faits absents des passages** (réponse
en partie de mémoire). Aucun n'a été compté comme sourcé.

## 4. NON VÉRIFIÉ fermés

**A22 — critères HAS/ANAES de repérage et d'orientation** (Q1 en P0, P0b et P1 ; Q2 en P1).
LibraryBrain, vérifié dans le texte :

- **HAS, *Bilan de santé en école maternelle* — rapport d'élaboration (avril 2026), p. 71,
  tableau 10**. Il reprend la fiche HAS des signes d'alerte à l'intention du médecin de premier
  recours pour l'enfant de 3 ans à 4 ans et demi :
  - langage non intelligible pour les personnes non proches ;
  - pas de phrase constituée ;
  - compréhension altérée.

  La même page rappelle les signes d'appel de la Société française de pédiatrie à 3 ans.
- **HAS, *Bilan de santé en école maternelle* — guide (avril 2026), p. 31**. Un profil 3 à l'ERTL4
  (suspicion de retard ou de trouble du langage oral) requiert l'avis du médecin de PMI. En parallèle,
  l'enfant peut être orienté **directement** vers un orthophoniste.
- **ANAES, *L'orthophonie dans les troubles spécifiques du développement du langage oral chez
  l'enfant de 3 à 6 ans* (mai 2001), p. 8, 10 et 12** :
  - une plainte doit aboutir à une évaluation individuelle et à un examen médical ;
  - l'indication du bilan orthophonique dépend de la sévérité, de la spécificité et de la persistance
    du retard ;
  - avant 4–5 ans, une prise en charge est nécessaire en cas d'inintelligibilité, d'agrammatisme ou
    de trouble de la compréhension (grade C).

Non couvert : les seuils du DPL3, qui restent au panel. `EVEIL-SOURCES.md` est mis à jour en ce sens
(mention « LibraryBrain, vérifié dans le texte »).

## 5. Divergences et ce qu'elles apprennent

### 5.1 Les trois écarts stricts (nuance face à confirmé)

- **Q19 / A1** (« minou » pour « minouche » : effacement de consonne finale, pas de syllabe) —
  cause (b). Aucune source de la bibliothèque ne classe elle-même l'exemple. La typologie de Rocher
  (2021) distingue l'omission d'un son de celle d'une syllabe entière. En P1, Yamaguchi (2012,
  p. 174) rappelle une analyse où la coda finale est l'attaque d'une syllabe à noyau vide. Tout va
  dans le sens de A1, rien ne le contredit. **A1 inchangé.**
- **Q25 / B25** (3 séances par semaine pendant 8 semaines valent mieux qu'une par semaine pendant
  24) — cause (c). LibraryBrain a remonté la page des **limites** d'Allen (2013) plutôt que ses
  résultats.
  - Relu en entier, le résumé (p. 1) **confirme** B25 : essai randomisé, 54 enfants d'âge
    préscolaire, mieux à 3 séances par semaine, et 1 séance par semaine sans différence avec le
    contrôle.
  - Le texte intégral ajoute des limites de réalisation (p. 10) : ratio réel de 0,81 contre 2,48
    séances par semaine, environ 19,5 séances au lieu des 24 prévues, approche des oppositions
    multiples seulement.
  - **B25 tient.** Ces précisions sont *proposées*, à valider.
- **Q27 / C6** (l'ASR généraliste « corrige » vers des mots réels et efface les disfluences) —
  cause (a).
  - L'effacement des disfluences est confirmé (Kid-Whisper, 2024).
  - Gao et al. (2024), sur la lecture à voix haute d'enfants néerlandais, montrent que Whisper
    **ignore** le mot mal lu dans 73 % des cas, au lieu d'en transcrire la forme erronée ; Ahn et al.
    (2024) parlent, eux, de correction lexicale.
  - La décision produit qu'appuie C6 (l'ASR masque les erreurs de l'enfant, elle ne peut pas être
    juge) **tient**. Le mécanisme (« corrige *ou ignore* ») et la population (enfants lecteurs) sont
    des précisions *proposées*, à valider.

### 5.2 Accords appuyés par le texte intégral

- **Q21 / A6** : Kehoe (2021) — codas finales correctes à environ 80 % dès 2;6, plus souvent réalisées
  dans les mots d'une syllabe que dans ceux de deux chez les plus jeunes.
- **Q18 / A2** : le même article écrit que l'effacement de la consonne finale est « infrequent » chez
  l'enfant francophone au développement typique après 2 ans à 2;6. Cela appuie la nuance de A2 : un
  effacement **systématique** à 3 ans est inhabituel.
- **Q29 / C17** : le corpus MyST porte sur des élèves du CE2 au CM2 (grades 3 à 5), gratuit pour un
  usage non commercial (licence Creative Commons), l'usage commercial relevant d'une autre licence ;
  CMU Kids couvre les 6-11 ans. La réfutation cloud est retrouvée.

### 5.3 Matière présente mais non retenue (ratés de récupération)

- **Q3 (A20, intelligibilité à 3 ans)**. La HAS (2005, *Propositions portant sur le dépistage
  individuel chez l'enfant de 28 jours à 6 ans*, p. 87) indique qu'« à partir de 36 mois », « 80 % de
  la parole est compréhensible par des étrangers ». Ce passage est bien dans la bibliothèque, mais il
  n'est remonté que pour Q6. Ce n'est ni la source demandée (Coplan & Gleason ; Hustad) ni un
  passage cité pour Q3 : **A20 reste NON VÉRIFIÉ**, piste pour le panel.
- **Q2 en P0** : les indications par âge de l'ANAES 2001 (p. 11-12) sont dans la bibliothèque et
  remontent pour d'autres questions, pas pour celle-ci.
- **Q4 en P1** : refus du modèle, alors qu'un passage donne une prévalence du trouble des sons de la
  parole (Beitchman et al., 1986, cités par Brosseau-Lapré et al., 2018).
- **Pistes vérifiées dans le texte, sans fermeture** (autre source que celle demandée) :
  - Q12 : Le Métayer (*Rééducation cérébro-motrice du jeune enfant*, p. 46) donne cercle fermé à
    3 ans, croix à 3 ans ½, carré à 4 ans ½, triangle à 5 ans — ce ne sont pas les normes du Beery
    VMI ;
  - Q10 : StatPearls (*Obesity in Pediatric Patients*, 2025) attribue à l'AAP moins d'une heure
    d'écran par jour de 2 à 5 ans ; la HAS (2021) relaie la règle 3-6-9-12 ;
  - Q7 : la HAS (2009, surdité de l'enfant) recommande d'évaluer le langage dans chaque langue
    proposée à l'enfant.

## 6. Sources nouvelles

Citées par LibraryBrain à l'appui d'un code, et absentes de `EVEIL-SOURCES.md` (recherche par
auteur ou titre) :

| Source | Sert pour |
|---|---|
| HAS, *Bilan de santé en école maternelle*, rapport d'élaboration et guide (avril 2026) | Q1, Q4, Q10, Q18 — **A22** |
| ANAES, *L'orthophonie dans les troubles spécifiques du développement du langage oral chez l'enfant de 3 à 6 ans* (2001), texte des recommandations | Q1, Q2 — **A22** |
| HAS, *Propositions portant sur le dépistage individuel chez l'enfant de 28 jours à 6 ans* (2005) | Q2, Q3, Q4 |
| HAS, *Surdité de l'enfant : accompagnement des familles et suivi de l'enfant de 0 à 6 ans* (2009) | Q6, Q7, Q25 |
| HAS, *Cadre national de référence : évaluation globale de la situation des enfants en danger* (2021) | Q10 |
| Rocher, *J'aide mon enfant en retard de langage* (2021) | Q18, Q19 |
| Collectif, *Pratiquer l'orthophonie : expériences et savoir-faire de 33 orthophonistes* (2013) | Q7, Q23, Q25 |
| Le Métayer, *Rééducation cérébro-motrice du jeune enfant* | Q12, Q33 |
| Pfersdorff, *Votre enfant de 0 à 16 ans* (2021) | Q10, Q12, Q17 |
| Reynolds & Fletcher-Janzen (dir.), *Encyclopedia of Special Education* (2008) | Q12, Q25 |
| StatPearls : *Obesity in Pediatric Patients* (2025), *Hearing Aid Fitting for Children* (2023) | Q10, Q16 |
| Huang & Benesty (dir.), *Audio Signal Processing for Next-Generation Multimedia Communication Systems* (2004) | Q16 |
| Poirel (dir.), *Neurosciences cognitives développementales* (2020) | Q5, Q21 |
| Citées *dans* ces sources : Beitchman et al. (1986), Hilaire-Debove & Kehoe (2004), Ramey & Ramey (1998) | Q4, Q21, Q25 |

## 7. Sources à acquérir

D'après les 22 refus et la page `/gaps` de LibraryBrain (18 requêtes sans réponse le jour même) :

- **Refusées au téléchargement** : McLeod & Crowe (2018) et Crowe & McLeod (2020) (ASHA, 403) ;
  Coventry (2025) ; Goad & Buckley (2006) ; Roberts & Kaiser (2011). S'y ajoutent les six sources
  « page » (Kehoe 2022, Wren 2018, Siemons-Lühring 2021, Jesus 2019, Sugden 2020, Bhardwaj 2022).
- **Nommées par les questions, absentes de la bibliothèque** :
  - Coplan & Gleason (1988), Hustad et al. (2021) — intelligibilité ;
  - manuel EVALO 2-6 ;
  - documents Eduscol de maternelle ;
  - Nissen & Fox, Holliday et al. — centroïdes de /s/ et /ʃ/ ;
  - IEPMCS (2012), Hambly et al. (2013) — bilinguisme ;
  - OMS (2019), AAP (2016), rapport de la commission écrans (2024), carnet de santé (2025) — écrans ;
  - Lynn (1986), Polit & Beck (2006) — indices de validité de contenu ;
  - manuel du Beery VMI ;
  - Fun Toolkit et *This or That* ;
  - de Jong & Wempe (2009) ; Lee, Potamianos & Narayanan (1999) ;
  - Gerth et al. (2016), Alamargot & Morin (2015) — tablette et papier ;
  - règlement (UE) 2017/745 (annexe VIII, règle 11) et MDCG 2019-11 ;
  - lignes directrices du CEPD sur la voix.

## 8. Limites

- **Petits effectifs** : 15 témoins, dont 6 abordés en P1 ; κ et pourcentages sont indicatifs.
- **Codeurs automatiques**, un par question et par passe ; fourchette de sensibilité au § 3.4. Le
  relecteur (agent principal) avait en contexte le `CLAUDE.md` du dépôt, qui résume quelques
  conclusions cloud ; il n'a modifié aucun code.
- **Passages partiels** : l'API ne rend que le premier passage de chaque livre, et un renvoi sans page
  n'est pas rattachable. Une partie de ce que le modèle a lu a donc pu échapper aux codeurs, ce qui
  explique certains cas de « réponse de mémoire ».
- **Une seule interrogation par question et par passe**. La génération s'est révélée reproductible
  (P0 = P0b au caractère près) ; la sensibilité aux réglages (température, nombre de passages,
  seuil du filtre) n'est pas mesurée.
- **Version de LibraryBrain** : P0b et P1 tournent sur du code non commité d'une autre session. Le gate
  régressif couvre la recherche, pas la génération.
- **P1 incomplète** : 17 sources sur 28 (§ 1.3).

## 9. Suite

- **Validation humaine** : les précisions proposées pour B25 et C6 (§ 5.1, sans changement de
  verdict), et la ligne du blueprint (`EVEIL.md`, § phonologie) qui range encore les critères
  HAS/ANAES parmi les non vérifiés.
- **Acquérir** les sources du § 7, puis rejouer le protocole (P2) sur les questions restées
  partielles ou non trouvées.
- **Alors seulement**, comme prévu par le protocole : `recuperer_sources.py --avec-notes` et la veille
  arXiv ([`arxiv_topics.eveil.txt`](../eveil/librarybrain/arxiv_topics.eveil.txt)).
