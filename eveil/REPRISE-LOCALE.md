# Reprendre la Suite Éveil en local (Mac)

## Troisième tour (28/09/2026) : compiler et installer

La session cloud a poussé le troisième tour sans pouvoir le compiler : train des phrases, jeux
d'écoute, livres des sons, voix, décompte, étoiles et coloriage. Une session sur le Mac a déjà remis
`swift test` en marche le 28/09 (`fullScreenCover` absent de macOS) et ajouté l'icône de l'app.
Sur le Mac, ouvre Claude Code **à la racine du dépôt** et dis-lui : « suis la section *Troisième
tour* d'`eveil/REPRISE-LOCALE.md` ». Tu peux aussi coller ce prompt :

~~~text
Compile, teste et installe le troisième tour de la Suite Éveil, poussé depuis une session cloud qui ne pouvait pas compiler le Swift. Réponds en français.

0. git fetch origin ; git switch claude/ios-educational-apps-suite-dljtt6 ; git pull. Relis CLAUDE.md, section « Suite Éveil », puis « Troisième tour ».
1. Python (stdlib) : depuis la racine, python3 -m unittest discover -s eveil/outils (83 tests) ; depuis eveil/reference, python3 -m unittest discover -s wordend -t . (83 tests). Si c'est rouge, arrête-toi et montre-moi.
2. Swift, à relancer après chaque pull (swift test repasse sur macOS depuis le commit b936373 du 28/09) :
   - cd eveil/ios/WordEndCore && swift test ;
   - puis cd eveil/ios && swift test ;
   - puis xcodebuild -scheme EveilTrain-Package -destination 'generic/platform=iOS Simulator' build.
   Nouveautés à compiler :
   - la cible PhraseCore ;
   - le train des phrases (SentenceTrainView, SentenceStage, SentenceMotion, PictoArt) ;
   - les jeux d'écoute (EarGamesView) et les livres des sons (SoundBooksView, PracticeView en juge adulte) ;
   - la voix (VoiceCatalog, ModelVoicePlayer) ;
   - le coloriage (24 couleurs, gomme, mode interactif).
   Corrige les erreurs et les avertissements au plus près du code. Interdit :
   - désactiver un test ou élargir une tolérance ;
   - modifier à la main un fichier généré (PictoDessins.swift, PhraseLexiconData.swift, SoundBooksData.swift, PagesDessins.swift). Ils viennent d'eveil/outils : python3 -m <pictos|phrases|livres|coloriages>.generer.
   Si un test révèle un vrai défaut, corrige la source : le Python, puis régénère ; ou bien le Swift.
3. Planches : EVEIL_RENDER_DIR=/tmp/eveil-rendus swift test --filter SentenceStageTests, puis montre-moi les PNG des phrases jouées (phrase-*.png).
4. iPad : ouvre App/EveilTrain.xcodeproj, compile et installe sur mon iPad (commandes xcrun devicectl dans eveil/README.md). L'ID d'équipe Apple ne va jamais dans le dépôt.
5. Committe et pousse les corrections sur la même branche : git pull avant, jamais de force-push, messages en français. Consigne versions et résultats dans eveil/README.md et CLAUDE.md. Dis-moi combien de tests passent, les avertissements restants et ce qui a été corrigé.
~~~

## Premier tour (25/09/2026) : compiler et comparer à LibraryBrain

La session cloud qui a produit ce travail ne pouvait ni **compiler le Swift** (téléchargement de la
toolchain bloqué) ni **joindre LibraryBrain** (RAG local, `127.0.0.1:8765`). Ces deux chantiers se
font sur le Mac : ouvrir Claude Code **à la racine du dépôt** et coller le prompt ci-dessous.
La comparaison avec LibraryBrain suit un protocole figé d'avance :
[`librarybrain/COMPARAISON.md`](librarybrain/COMPARAISON.md).

> **Fait le 25/09/2026** : les deux chantiers sont faits (Swift compilé et testé,
> [`README.md`](README.md#sur-mac--compilé-et-testé-le-25092026) ; comparaison dans
> [`docs/EVEIL-SOURCES-LIBRARYBRAIN.md`](../docs/EVEIL-SOURCES-LIBRARYBRAIN.md)). Le prompt reste pour
> rejouer la comparaison (P2) après acquisition des sources manquantes.

~~~text
Reprise en local de la Suite Éveil (apps iPad d'éveil pour les 3 ans et +), commencée dans une session Claude Code cloud. Réponds et documente en français.

La session cloud n'a pas pu faire deux choses, qui sont l'objet de cette session :
(a) compiler et tester le Swift (téléchargement de la toolchain bloqué par le proxy) ;
(b) interroger LibraryBrain, mon RAG local sur ce Mac (127.0.0.1:8765), pour comparer ses réponses à la recherche web de la passe cloud (docs/EVEIL-SOURCES.md).
Les étapes 2 et 3 sont indépendantes : si l'une attend une réponse de ma part, avance sur l'autre.

0. Synchroniser
- git fetch origin. Si la PR #17 de klodynlov/klodynlov est fusionnée, pars de main à jour ; sinon git switch claude/ios-educational-apps-suite-dljtt6 puis git pull.
- Relis ensuite CLAUDE.md (la section « Suite Éveil » n'existe que sur cette branche tant que la PR n'est pas fusionnée), eveil/README.md et eveil/librarybrain/COMPARAISON.md.

1. Contrôle Python (stdlib seule)
- depuis eveil/reference : python3 -m unittest discover -s wordend -t .  → 69 tests verts
- depuis eveil/reference : python3 -m wordend.golden --check
- depuis eveil/reference : python3 ../outils/verifier_confidentialite.py  → 0 violation
- depuis la racine : python3 -m unittest discover -s eveil/librarybrain  → 20 tests verts
Si quelque chose est rouge, arrête-toi et montre-moi.

2. Swift : première vraie compilation
- Prérequis : Xcode 16+ sélectionné (xcode-select -p doit pointer vers Xcode.app et non vers CommandLineTools, sinon XCTest manque).
- cd eveil/ios/WordEndCore && swift test (parité Swift ↔ Python par golden_vectors.json, propriétés pédagogiques).
- Corrige le Swift pour qu'il colle à la référence Python. Interdit : retoucher golden_vectors.json à la main, élargir une tolérance, désactiver un test. Si c'est la référence Python qui doit changer : python3 -m wordend.golden, puis --check, puis les 69 tests.
- Couche app : dans eveil/ios, xcodebuild -list, puis xcodebuild -scheme <schéma du paquet, a priori EveilTrain-Package> -destination 'generic/platform=iOS Simulator' build (installer la plateforme iOS dans Xcode si demandé). La coquille eveil/ios/App/ ne compile que dans un projet Xcode : on le créera ensemble.
- Consigne les versions (macOS, Xcode, Swift) et les résultats dans eveil/README.md et CLAUDE.md : le statut « non compilé » tombe.
- L'app sur un vrai iPad (projet Xcode, signature, micro) : seulement avec moi, pas à pas.

3. LibraryBrain : comparer les deux passes
Suis eveil/librarybrain/COMPARAISON.md à la lettre : le protocole a été figé avant toute réponse. Non négociable :
- jamais docs/EVEIL*.md dans l'index avant la fin, donc recuperer_sources.py SANS --avec-notes (sinon LibraryBrain retrouve nos propres conclusions) ;
- passe P0 sur la bibliothèque telle quelle, puis P1 avec les PDF de sources.json, une fois indexés ;
- les 33 questions de eveil/librarybrain/questions.md, mot pour mot ;
- réponses brutes consignées, puis codées d'après les passages cités, AVANT d'ouvrir les verdicts de docs/EVEIL-SOURCES.md ;
- toute citation qui fermerait un NON VÉRIFIÉ ou contredirait la passe cloud est vérifiée dans le document d'origine ;
- réponses brutes dans eveil/librarybrain/resultats/ (ignoré par git) : ce sont des extraits d'ouvrages sous droits, et le dépôt est public.
Commence par trouver comment interroger LibraryBrain de façon scriptable : le service qui écoute sur le port 8765 (lsof -nP -iTCP:8765 -sTCP:LISTEN), son code, les routes derrière /ask et /consensus. Si ce n'est pas scriptable, préviens-moi avant de lancer 66 requêtes à la main. Demande-moi le dossier surveillé par l'indexeur avant P1.

4. Livrer
- Rapport docs/EVEIL-SOURCES-LIBRARYBRAIN.md, au format fixé par le protocole.
- docs/EVEIL-SOURCES.md : ne ferme que les NON VÉRIFIÉ appuyés sur une citation vérifiée (mention « LibraryBrain, vérifié dans le texte »). Pour rétrograder un CONFIRMÉ ou toucher une décision de docs/EVEIL.md, demande-moi d'abord.
- CLAUDE.md à jour ; commits clairs en français sur la branche ; git pull avant chaque push (une autre session peut avoir poussé) ; description de la PR #17 mise à jour.

Ne décide pas à ma place : nom de la suite (« OrthoSpeech » est à renommer), iPadOS 17 ou 26, mode par défaut avant validation (écoute automatique ou juge adulte), mascotte et voix, panel d'experts. Ne réintroduis aucune des affirmations corrigées listées dans CLAUDE.md.
~~~
