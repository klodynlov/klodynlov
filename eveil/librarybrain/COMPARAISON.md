# LibraryBrain ↔ passe cloud — protocole de comparaison

> **Figé le 25/09/2026, avant toute réponse de LibraryBrain.** Les questions
> ([`questions.md`](questions.md), Q1–Q33), le codage et les mesures ci-dessous ne changent plus
> une fois les premières réponses lues ; tout écart se déclare dans le rapport.
> `test_questions.py` garde l'empreinte des formulations.

## Ce qu'on compare

| | Passe cloud (24/09/2026) | Passe LibraryBrain (locale) |
|---|---|---|
| Corpus | Web ouvert ; proxy et quota → beaucoup de verdicts **sur résumés** | Bibliothèque personnelle (25 000+ documents), **texte intégral**, RAG local |
| Livrable | [`docs/EVEIL-SOURCES.md`](../../docs/EVEIL-SOURCES.md) — 168 affirmations | `docs/EVEIL-SOURCES-LIBRARYBRAIN.md` — ce protocole appliqué |

Trois questions, trois mesures :

1. **Couverture** — LibraryBrain trouve-t-il de quoi répondre ?
2. **Accord** — sur des points que la passe cloud a déjà tranchés, arrive-t-il au même verdict ?
3. **Apport** — ferme-t-il des NON VÉRIFIÉ, avec quelles sources nouvelles, et que change le texte intégral ?

Hors champ, et dit comme tel dans le rapport : l'axe **D** (plateforme Apple, déjà lue dans la
documentation officielle) et les faits de **marché** (F1–F17), pour lesquels le web reste la bonne source.

## Règles anti-contamination (non négociables)

1. **Rien de la passe cloud dans l'index avant la fin** : ni `docs/EVEIL.md`, ni
   `docs/EVEIL-SOURCES.md`, ni ce dépôt. Donc `recuperer_sources.py` **sans** `--avec-notes` —
   sinon LibraryBrain retrouve nos propres conclusions et la comparaison tourne en rond.
   *Contrôle avant P0* : chercher dans LibraryBrain « Suite Éveil », « Petit Train des mots »,
   « 168 affirmations ». Trouvé → retirer ces fichiers du dossier surveillé, attendre la
   réindexation, recontrôler ; impossible → le déclarer comme limite.
2. **À l'aveugle** : consigner la réponse brute, puis la **coder**, *avant* d'ouvrir les verdicts de
   `docs/EVEIL-SOURCES.md` (ne pas le lire pendant les phases 1 et 2). Limite connue : `CLAUDE.md`,
   chargé d'office, résume quelques conclusions.
3. **Mêmes conditions** pour toutes les requêtes : formulation exacte de `questions.md`, page
   indiquée (`/ask` ou `/consensus`), mêmes réglages, une conversation neuve par question si
   l'interface garde un historique. Relever la version (commit) de LibraryBrain, son modèle de
   génération et ses réglages de recherche.

## Les deux passes

| Passe | Corpus | Ce qu'elle mesure |
|---|---|---|
| **P0** | Bibliothèque **telle quelle** | Une preuve **indépendante** de la passe cloud |
| **P1** | P0 **+ PDF de [`sources.json`](sources.json)** (`recuperer_sources.py --dest …`, sans `--avec-notes`), indexation terminée | Ce que le **texte intégral** change aux lectures faites sur résumé |

Si les sources de la Suite Éveil sont déjà indexées, P0 est impossible : le dire et ne faire que P1.
Les liens de type `page` peuvent être enregistrés en PDF dans le même dossier avant P1 — le préciser.

## Phases

1. **Interroger** — Q1–Q33 en P0, puis en P1 ; réponse brute consignée telle quelle.
2. **Coder**, sans les verdicts cloud, **d'après les passages cités** et non d'après le résumé
   généré (le modèle de LibraryBrain peut répondre de mémoire : sans passage, rien n'est prouvé).
   Pour chaque question × passe :
   - `couverture` : **SOURCÉ** (au moins un passage cité et pertinent) · **PARTIEL** ·
     **NON TROUVÉ** (« Je n'ai pas trouvé cette information dans votre bibliothèque », ou rien de pertinent) ;
   - `position` — témoins Q19–Q33 seulement, par rapport à la **proposition** de `questions.md` :
     **SOUTIENT** · **NUANCE** · **CONTREDIT** · **NON TROUVÉ** ;
   - `sources` : auteur, année, titre, page ou section — pas d'extrait long ;
   - `verifie` : passage retrouvé **dans le document d'origine** ? Obligatoire pour toute réponse
     qui fermerait un NON VÉRIFIÉ ou contredirait la passe cloud (un RAG peut mal attribuer).
3. **Comparer** — ouvrir enfin `docs/EVEIL-SOURCES.md` et joindre par identifiant.

## Mesures

Réutiliser `cohen_kappa` et `wilson` de [`eveil/reference/wordend/bench.py`](../reference/wordend/bench.py)
(stdlib : `sys.path.insert(0, "eveil/reference")`, puis `from wordend.bench import cohen_kappa, wilson`).

| Mesure | Définition |
|---|---|
| **Couverture** | (SOURCÉ + PARTIEL) / 33, par passe, avec IC 95 % de Wilson |
| **Accord** (témoins) | SOUTIENT ↔ CONFIRMÉ, NUANCE ↔ NUANCÉ, CONTREDIT ↔ RÉFUTÉ, sur les témoins où LibraryBrain prend position : % d'accord, κ de Cohen, matrice de confusion. Deux lectures : **stricte** (3 classes) et **souple** (soutient-ou-nuance contre contredit). n ≤ 15 : indicatif, le dire |
| **NON VÉRIFIÉ fermés** | Questions Q1–Q18 SOURCÉES **et** vérifiées, par passe |
| **Apport du texte intégral** | Questions dont le codage change entre P0 et P1 |
| **Sources nouvelles** | Références citées par LibraryBrain et absentes de `docs/EVEIL-SOURCES.md` (recherche par auteur + année) |
| **Divergences** | Pour chaque désaccord, une cause : (a) texte intégral contre résumé · (b) autre source · (c) raté de récupération · (d) erreur de la passe cloud · (e) citation introuvable — et l'action qui en découle |

## Où ranger quoi

- **Local, jamais poussé** — `eveil/librarybrain/resultats/` (ignoré par git) : `reponses.jsonl`,
  une ligne par question × passe (`q`, `passe`, `page`, `question`, `reponse`, `citations`,
  `couverture`, `position`, `sources`, `verifie`, `horodatage`). Ces réponses contiennent des
  extraits d'ouvrages sous droits, et **le dépôt est public**.
- **Publié** — `docs/EVEIL-SOURCES-LIBRARYBRAIN.md` : méthode (dates, version et modèle de
  LibraryBrain, nombre de documents indexés en P0 et en P1, écarts au protocole) · tableau
  `| Q | Id | Verdict cloud | P0 | P1 | Accord | Cause | Action |` · mesures · NON VÉRIFIÉ fermés
  (avec leur source vérifiée) · sources nouvelles · sources à acquérir (page `/gaps`) · limites.
  **Jamais plus de deux phrases citées d'un même ouvrage.**

## Ensuite

- `docs/EVEIL-SOURCES.md` : fermer les NON VÉRIFIÉ **vérifiés** (verdict, source, mention
  « LibraryBrain, vérifié dans le texte »). Toute **rétrogradation** d'un CONFIRMÉ, ou tout effet
  sur une décision de [`docs/EVEIL.md`](../../docs/EVEIL.md), attend une validation humaine.
- Alors seulement : `--avec-notes` et veille arXiv ([`arxiv_topics.eveil.txt`](arxiv_topics.eveil.txt)).
