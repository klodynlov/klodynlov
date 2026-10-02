# CLAUDE.md — mémoire & état des projets

> Fichier de contexte pour les sessions Claude Code sur ce dépôt (profil `klodynlov`).
> Sert de **suivi d'avancement** des projets du portfolio. À tenir à jour.

## Nature du dépôt
Dépôt de **profil GitHub** (`klodynlov/klodynlov`) — vitrine d'un ingénieur « agents IA
privés / local-first ». Contient surtout de la **documentation** (README + `docs/`), plus
quelques modules de code de démonstration. Positionnement : IA 100 % locale, MCP (client &
serveur), Python/Rust, MLX/Ollama.

## Workflow
- Développement sur branches `claude/*`, PR (brouillon par défaut) vers `main`.
- Squash-merge. `main` est la référence.
- **Langue : répondre et documenter en français par défaut** — réponses de chat
  comprises, y compris les mises à jour automatiques de suivi de PR.

---

## État des projets

### ✅ SilverBrain — assistant IA pour public réfractaire à la technologie
**Statut : mergé dans `main` (PR #3).** Documentation + maquettes.
- Concept : assistant IA local intuitif (seniors et au-delà). 4 piliers — intuitif ·
  profilage conversationnel → thématiques LibraryBrain · accompagnement (rappels, lecture,
  proches) · **formulation adaptative**.
- Fichiers : `docs/SILVERBRAIN.md` (concept, scénario, Mermaid, archi), `-PROFIL.md`
  (modèle de données du profil), `-STYLE.md` (contrat de style), `-MCP.md` (connecteurs),
  `docs/ui/landing.html` + `ecran-accessible.html` (maquettes). README : « Projet en lumière ».
- Reste possible (non demandé) : dashboard aidant, captures PNG dans le README.

### 🚧 AIoT / EdgeSense — l'IA locale rencontre les objets
**Statut : PR #4 OUVERTE (brouillon), `clean`, non mergée.**
Branche `claude/aiot-projects-96qbia` · portée par la session `session_01HU6u9CxuwQnr4aa4Dm7iCz`
(≠ session SilverBrain) · 9 fichiers, +753.

- 📄 `docs/aiot-edge-projects.md` — état de l'art AIoT/edge-AI 2025-2026 **sourcé et
  vérifié en contradiction** (6 angles, 27 sources, 25 affirmations → 21 confirmées /
  4 réfutées) + 2 notes de conception. Points clés retenus : ExecuTorch 1.0 GA (oct. 2025) ;
  SLM quantifiés (Llama 3.2, Gemma 3 270M, Qwen2.5, SmolLM2) ; sur Apple Silicon MLX =
  génération / Ollama = prototypage (arXiv 2511.05502) ; MCP = couche capteurs↔agents
  (M×N → M+N) ; quantification INT8 ≈ ×4 mais perte de raisonnement (jusqu'à 32 %, moy.
  11 %, récupérable par fine-tuning court). **Réfuté** (à ne pas réutiliser) : archi
  MCP+MQTT événementielle « prouvée », CompactifAI −62 % énergie, coût CPU linéaire en
  tokens, ExecuTorch en prod Instagram/WhatsApp.
- 💻 `edgesense/` — **EdgeSense M0 codé ✓** : boucle *percevoir→décider→agir* avec capteur
  (température) + actionneur (chauffage) **simulés**.
  - `devices.py` (cœur **stdlib pur** : pièce simulée, catalogue, **allowlist stricte** des
    actionneurs, **journal append-only chaîné SHA-256** tamper-evident).
  - `server.py` (adaptateur **MCP** FastMCP : `list_devices` / `read_sensor` /
    `set_actuator` + ressource `edgesense://state`).
  - `demo.py` (thermostat maintient 20-22 °C) · `test_devices.py` (**9 tests unittest,
    verts**) · README module + config Claude Desktop d'exemple · `requirements.txt` (`mcp>=1.2`).
  - Vérif : `python3 demo.py` ✓ ; `python3 -m unittest test_devices -v` → 9/9 ✓ ;
    serveur MCP live nécessite `pip install mcp`.

**Reste à faire (conception, pas codé) :**
- EdgeSense **M1** matériel réel (DHT22/BME280 + relais sur Pi, cache SQLite) → **M2** temps
  réel (bus pub/sub, réaction à seuil) → **M3** sécurité (allowlist, bornes, **journal
  signé**, reconnexion) → **M4** multi-nœuds (plusieurs ESP32 → Pi passerelle).
- **TinyGuard** (projet B) : surveillance vidéo/audio 100 % edge (modèle quantifié INT8,
  ring-buffer local, exposition MCP) — **stade conception uniquement**.
- Jonction visée : `EdgeSense` (agir) + `TinyGuard` (percevoir) → `HomePilot` (domotique
  agentique locale, sans cloud).
- ⚠️ Risque n°1 : **push temps réel** — MCP seul insuffisant, valider tôt le transport
  pub/sub (M2). Angles morts à instrumenter : débit runtimes sur Jetson/Pi, thermique 24-7,
  plancher de précision SLM sub-1B après quantif 4-bit.

### 🚧 micro:bit en Bluetooth — matériel réel (jalon M1 « radio »)
**Statut : mergé dans `main` (PR #13).**
Indépendant du code d'EdgeSense (qui vit encore dans la PR #4 non mergée) : aucun import
croisé, seulement une continuité de récit et de discipline.

- 💻 `microbit/` — connecteur **BLE** pour BBC micro:bit : percevoir (température,
  accéléromètre, boussole, boutons) et agir (afficheur LED, UART).
  - `profile.py` (**stdlib pure** : UUIDs, codecs, **allowlist d'écriture** à 7
    caractéristiques — DFU refusé, une écriture y reprogrammerait la carte à distance).
  - `ble.py` (session bleak : scan, connexion, notifications, écritures ; client injectable).
  - `fake.py` (**micro:bit simulé** exposant l'API de bleak → tests et démos sans matériel).
  - `server.py` (**MCP** : 14 outils + ressource `microbit://state` ; compat SDK **1.x
    FastMCP et 2.x MCPServer**) · `demo.py` (`scan`/`infos`/`texte`/`icone`/`suivre`/`boucle`,
    toutes avec `--simule`) · `test_microbit.py` (**33 tests, verts**) · README + requirements.
  - 📄 `docs/MICROBIT-BLUETOOTH.md` (conception, 2 diagrammes Mermaid) + entrée README.
- **Vérifié ici** : 33/33 tests ✓ ; démos simulées ✓ ; serveur piloté par un **vrai client
  MCP en stdio** (initialize, 14 outils, ressource, chemin d'erreur) ✓.
  **Non vérifiable sans radio** : le chemin bleak vers une carte physique.
- 🔑 **Pièges du profil encodés et testés** (vérifiés contre la spec Lancaster) :
  UART **inversé** vs Nordic (écrire `…0003`, écouter `…0002`) · `UART TX` en **indicate**
  (CCCD `0x0200`), pas notify · service absent = firmware sans le service (on renvoie le bloc
  MakeCode à activer, pas un timeout) · texte LED = 20 **octets UTF-8** · matrice : bit 4 =
  colonne de gauche · température = celle du **processeur**, pas de la pièce.
- ⚠️ Confirme le **risque n°1** : MCP ne peut pas pousser → tampon borné de 200 événements
  relevé par `evenements_recents`. Vrai temps réel = bus pub/sub (M2), toujours ouvert.
- Prérequis matériel côté utilisateur : programme **MakeCode + extension Bluetooth**
  (MicroPython ne fait pas de BLE GATT) ; « No Pairing Required » recommandé.

### 🎵 KLOD Live Brain / KLOD GrooveDNA — coprocesseur musical temps réel
**Statut : mergé dans `main` (PR #16).**
Nouvel axe (musique temps réel + agentique). Indépendant des autres modules :
aucun import croisé, seulement la continuité de discipline (stdlib pur, tests
sans matériel, honnêteté PROUVÉ/FAISABLE).

- 🎯 Vision : **le Mac réfléchit, le Teensy exécute en temps réel.** Teensy 4.1 =
  réflexe (horloge, MIDI, scheduler) ; Mac Apple Silicon = cerveau (IA, mémoire,
  génération, MCP). Le LLM **jamais** dans la boucle temporelle critique.
- 💻 `klod-live-brain/host/groovedna/` — **GrooveDNA M0 PROUVÉ ✓** (couche
  « musical », **stdlib pure**, testée sans Teensy) :
  - `groove.py` (cœur : `NoteEvent`, `Grid`, `GrooveDNA`, `capture_groove`,
    `apply_groove(pattern, dna, amount)`, `morph_grooves(a, b, alpha)`,
    `groove_distance`, format **versionné `KLOD_GROOVE_V1`**).
  - `demo.py` (preuve exécutable du **critère §38**, chiffrée, reproductible) ·
    `test_groove.py` (**35 tests unittest, verts**) · README module + `__init__`.
  - Vérif : `cd klod-live-brain/host && python3 -m unittest groovedna.test_groove`
    → **35/35 ✓** ; `python3 -m groovedna.demo` ✓ (aucune dépendance).
- 📄 `klod-live-brain/docs/` — **audit Phase 0 produit** :
  `TECHNICAL_REALITY.md` (statuts + preuves + risques + 10 sources vérifiées),
  `GROOVEDNA_SPEC.md` (format + base maths des métriques), `ARCHITECTURE.md`
  (4 niveaux + frontière temps réel, 3 diagrammes Mermaid).
- 🔌 `klod-live-brain/firmware/` — **squelette réflexe Teensy 4.1 (FAISABLE, non
  mesuré)** : `main.cpp` (boucle passthrough horodatée), `timing/cycle_clock`
  (DWT, Teensy-only), `midi/midi_io` (DIN FortySevenEffects + usbMIDI, Teensy-only,
  correspondances API « à vérifier »), `queue/event_queue.h` (**file bornée,
  allocation statique, TESTÉE EN NATIF g++ → 15045 vérifs vertes**), `metrics.h`,
  `config.h`, `platformio.ini` · `sketches/` (croquis Arduino de bring-up :
  `i2c_scan` + `klod_lcd_hello` pour le LCD 2004 I²C, biblio hd44780, non flashés
  ici). ⚠️ Seule la file est vérifiée ici ; DWT/MIDI/sketches ne compilent que
  sous Teensyduino → **BENCHMARKS.md reste à produire sur matériel**.
- 🖥️ Matériel utilisateur : Teensy 4.1 + **LCD 2004 I²C (PCF8574)** câblé et
  **alimenté en 3,3 V** (rétroéclairage OK) ; Audio Shield Rev D **posé à part**
  (non empilé pour l'instant). Câblage LCD : 4 fils `VCC→3V · GND→G · SDA→18 ·
  SCL→19` (Teensy non tolérant 5 V ; bus I²C partageable avec le SGTL5000 0x0A ;
  LCD 0x27/0x3F). 2 schémas publiés en Artifact.
- ▶️ **REPRISE (en local sur le Mac — accès USB requis)** : flasher
  `klod-live-brain/firmware/sketches/i2c_scan` (attendu : `0x27`/`0x3F` au
  Moniteur série 115200) puis `klod_lcd_hello` (biblio **hd44780**) → « KLOD Live
  Brain » à l'écran. Prérequis : Arduino IDE + support Teensy (URL
  `package_teensy_index.json`), carte « Teensy 4.1 », USB Type « Serial ».
  Ensuite : MIDI DIN (broches 0/1) + affichage des vrais compteurs `metrics.h`.
  (Session passée du serveur distant au Mac ; contexte porté par ce fichier.)
- ✅ **Prouvé ici** : capture d'offsets mesurables (microtiming en fraction de
  noire, **indépendant du tempo**) ; transfert `amount` **linéaire** (0/25/50/
  75/100 %) vélocité comprise ; **aucune note perdue** ; morphing aux **bornes
  exactes** ; sérialisation versionnée **sans perte** ; métriques (swing,
  syncope=proxy grille métrique LHL, densité, variation=Jaccard, accents)
  cohérentes. Représentation = **groove template** (pas de params inventés),
  **rien d'aléatoire** (reproductible).
- 🔑 **Décisions clés encodées** : capture haute précision via **MIDI DIN**
  (UART, jitter sub-ms) **et non USB** (batching ~2,2 ms) → **risque n°1**
  confirmé et tranché par la doc. Horodatage Teensy = `ARM_DWT_CYCCNT`
  (1,667 ns, wrap ~7,16 s, à déverrouiller sur M7). Confirme **encore** le
  verrou micro:bit/EdgeSense : MCP ne pousse pas → plan de contrôle only.

**Reste à faire (non codé) :** styles caribéens (zouk/shatta/kompa…) appris
depuis de **vrais fichiers MIDI** (jamais des clichés inventés, §7) · **groove
personnel** du musicien (calculé sur perfs accumulées) · **portage Teensy amorcé**
(squelette + file bornée testée en natif) → reste timing/MIDI/scheduler sur
matériel + `BENCHMARKS.md` (jitter/latence/overruns à **mesurer** — FAISABLE non
mesuré) · puis IA / MCP / MPC / REAPER / Logic **seulement après** backends
réels. ⛔ NON VIABLE (à ne pas réutiliser) : LLM sur Teensy, Demucs sur Teensy,
API Akai/Logic inventées, « MCP pilote le DAW » sans adaptateur. 🟡 Beat tracking
audio = EXPÉRIMENTAL. **On ne passe pas à l'IA tant que la chaîne matérielle §38
n'est pas bouclée et chiffrée.**

### 🚂 Suite Éveil — apps iPad d'éveil (langage + motricité fine), 3 ans et +
**Statut : branche `claude/ios-educational-apps-suite-dljtt6`, basée sur `main`, PR brouillon.**
Nouvel axe (EdTech petite enfance, iPad, Swift/SwiftUI, 100 % on-device). Indépendant des autres
modules : aucun import croisé ; même discipline (référence stdlib testée, statuts honnêtes).

- 🎯 Deux apps gratuites, sans pub/achat/traçage : **App 1 « le Petit Train des mots »** (nom de
  code *OrthoSpeech* — **à renommer** : « orthophoniste » est un titre protégé, risque DM) et
  **App 2 « Atelier de coloriage »**. Blueprint : `docs/EVEIL.md` ; état de l'art sourcé :
  `docs/EVEIL-SOURCES.md` (168 affirmations, 6 axes, réfutés listés).
- 🔑 **Corrections du cahier des charges** (à ne pas réintroduire) : « minouche→minou » = effacement
  de **consonne finale** (coda /ʃ/), pas de syllabe → train = 1 wagon par syllabe **orale** + un
  **fourgon** pour la consonne finale · le **juge = l'acoustique**, l'ASR ne peut que rendre un
  verdict plus prudent (biais vers mots réels, WER énorme en maternelle) · **pas d'haptique au doigt
  sur iPad** (Pencil Pro seulement, `UICanvasFeedbackGenerator` 17.5) · SceneKit déprécié (iOS 26) ·
  **pas de score de langage ni de rapport pour professionnel** dans l'app publique (donnée de santé,
  MDR règle 11 → IIa) · Core ML « clarté phonétique » NON VIABLE en v1 (aucun corpus 3-5 ans FR
  sous licence) · Accès guidé : détectable, pas déclenchable (MDM).
- 💻 `eveil/reference/wordend/` — **détecteur de fin de mot PROUVÉ sur signaux synthétiques**
  (stdlib pure) : `dsp.py` (FFT, trames 21,3 ms/10 ms à 24 kHz, F0, SplitMix64), `detector.py`
  (noyaux à la de Jong & Wempe + friction finale + **asymétrie** : « fin absente » seulement sur
  preuve d'absence, sinon INCERTAIN avec raison), `streaming.py` (wagons allumés en direct, verdict
  final = chemin par lots), `policy.py` (jamais « faux », pointer seulement sur verdict sûr, pas de
  boucle d'échec, séances courtes), `lexicon.py` + `eveil/lexique/{fr-FR,en-US}.json` (conçus par
  langue, **propositions à valider**), `bench.py` (**banc de validation** orthophonistes : κ, fausse
  alerte + IC95 Wilson, porte GO/NO GO), `golden.py` (vecteurs de parité Python↔Swift), `demo.py`.
  Vérif : `cd eveil/reference && python3 -m unittest discover -s wordend -t .` → **69/69 ✓** ;
  0 fausse alerte sur 30 énoncés complets bruités (35→5 dB).
- 📱 `eveil/ios/` — Swift : paquet **autonome** `eveil/ios/WordEndCore` (portage **ligne à ligne**, Swift pur, testable
  Linux/Mac), `WordEndAudio` (session `.measurement`, micro→24 kHz en mémoire, `ListeningController`),
  `TrainPracticeUI` (train, mascotte, séance, contrôle parental, espace parent, SwiftData local
  `cloudKitDatabase: .none`) + `App/` (coquille, Accès guidé, `PrivacyInfo.xcprivacy`).
  ✅ **Compilé et testé sur le Mac le 25/09/2026** (macOS 27.0, Xcode 27.0, Swift 6.4, SDK iOS 27.0) :
  `cd eveil/ios/WordEndCore && swift test` → **19/19** dès la 1re compilation, dont parité 17 cas
  (mutation vérifiée : la parité mord ; limite : bande 50–80 ms du seuil de friction non sondée par
  les golden) · `cd eveil/ios && xcodebuild -scheme EveilTrain-Package -destination 'generic/platform=iOS
  Simulator' build` → **BUILD SUCCEEDED**, aussi appareil iOS, macOS et mode Swift 6, **0 avertissement**
  (4 avertissements de concurrence de `ListeningController` corrigés) · coquille `App/` type-checkée
  seule ; **projet Xcode + iPad réel faits avec l'utilisateur, pas à pas** (25/09/2026 : signature, micro).
  Dépréciation `installTap` → `installAudioTap(…)` confirmée dans le SDK iOS 27 (bascule liée au choix
  iPadOS 17/26).
- 🎨 **App iPad — ébauche JOUABLE, installée sur l'iPad réel de l'utilisateur (25/09/2026)**, construite
  avec lui : projet `eveil/ios/App/EveilTrain.xcodeproj` (cible iPad, paquets locaux, lexiques,
  confidentialité) · **accueil** · **petit train** plein écran · **mode démo** (`-eveil.demoMode 1` :
  pseudo-parole `Synth` dans le VRAI détecteur, rien dans le journal) · **atelier de coloriage**.
  **iPad réel** (iPad Pro 11" M1, iPadOS 27) : mode développeur activé par l'utilisateur, signature
  automatique avec son accord (profil d'équipe, **l'ID d'équipe ne va pas dans le dépôt public**),
  install/lancement par `xcrun devicectl` (commandes dans `eveil/README.md`).
  **Second tour, sur ses retours** (« plus de mots », « micro plus réceptif », « un mot bien dit on
  enchaîne », « un autre monde à chaque mot », « la mouche : on l'attrape, elle fait bzzz »,
  « coloriage : ne pas fusionner les formes ») :
  - micro : le détecteur écarte EXPRÈS les voix graves d'adulte (F0 < 165 Hz ⇒ incertain) → réglage
    **« Essai par un adulte »** (ne lève que cette garde) + **« Tester le micro »** (espace des grands :
    accès, vumètre, petit train, `ListeningDiagnosis` en clair) ; 10 s pour commencer à parler (6 dans la
    référence) ; `DetectorConfig()` et les vecteurs de parité **inchangés** ;
  - voyage : mot bien dit → fourgon accroché (« chhh »/« sss »), sifflet, départ vers le **monde
    suivant** (8 mondes, ordre fixe, `EveilDesign/World*`) ; ligne du voyage (6 gares/séance) ;
  - 45 mots (28 FR + 17 EN, propositions), tous niveaux mêlés (`WordDeck`, curseur mémorisé) ;
    un **dessin vivant par mot** (`WordArt*`, action au toucher) + **bestioles** qui volent derrière
    (`CritterLayer` ; on les attrape, elles font leur bruit) ; **53 bruitages calculés** (`EveilSounds`,
    aucun fichier son, sonie égalisée) ; **tout se tait pendant le mot modèle et l'écoute** ;
  - coloriage : **15 pages au trait, chaque zone fermée par des traits = une zone** (carte des zones
    1024² : remplir + pinceau-pochoir par zone, traits nets par-dessus, choix des dessins) ;
    **puis 70 pages (session cloud, 25/09/2026, demande « beaucoup d'images, toutes celles du petit
    train et plus, bien tracées »)** : +55 pages **dessinées en Python** dans `eveil/outils/coloriages/`
    (`pages_*.py` par album ; `traits.py` = même algorithme que `LineClipper` → traits visibles ;
    `zones.py` = carte des zones simulée comme `ZoneMap` → témoins/détails ; `analyse.py` = contrôles :
    toute zone < 0,3 % doit appartenir à un élément `detail`, sinon « miette », robustesse ± 1 px de
    trait et décalage sous-pixel, encres jamais recouvertes, contours sans croisement) → génère
    `ColoringUI/PagesDessins.swift` (`s.line(G.data(…))`, `s.ink`, `s.expectAll` ; lecteur
    `SketchPathData.swift`). **Un dessin par mot des 45** (même sujet que `WordArt`), éléments du
    train, et d'autres. **7 albums** (`ColoringAlbums.swift`, 12 pages max : tout visible d'un coup
    même en 11" paysage) ; `PagePicker` = rangée d'albums + grille de l'album. `ColoringPages.all` =
    albums aplatis. Python : 25 tests verts, `generer --check`. **Compilé et testé sur le Mac le 25/09** :
    0 avertissement ; `testEveryDrawnShapeIsItsOwnZone` a trouvé une fuite que la simulation Python
    laissait passer (blanc de l'œil du caniche rattaché à la tête : croissant < miette) → œil corrigé
    dans `pages_animaux.py`, page régénérée → ColoringUITests 30/30. La vérification finale = l'app.
    Planche : `docs/ui/eveil-app/7-coloriages.png`. Doublons évités : les 15 sujets Mac gardés tels quels ;
  - piège SwiftUI vu deux fois : une boucle `repeatForever` lancée dans `onAppear` « capture » la
    transition ou l'animation d'un parent (train qui clignote, qui tremble) → **tout mouvement est piloté
    par l'horloge** (`TimelineView`), train compris.
  Réalisé en partie par 4 sous-agents en worktrees (mondes/bestioles, dessins des mots, sons,
  coloriage), relus sur planches PNG (`EVEIL_RENDER_DIR`, `EVEIL_SOUNDS_DIR`) puis fusionnés.
  `cd eveil/ios && swift test` → **103 tests** (démo, écoute, sons, rendus, coloriage). Captures :
  `docs/ui/eveil-app/*.png`. **Mascotte provisoire choisie par l'utilisateur : un chat chef de gare.**
  Provisoire aussi : nom « Petit Train », identifiant `fr.klodynlov.eveil.petittrain`, iPadOS 17,
  dessins et bruitages (en attendant illustrateur et vrais sons). `docs/EVEIL.md` § 6 **mis à jour le
  25/09 avec l'accord de l'utilisateur** (zones comme sur papier, pochoir par zone sans PencilKit, pages
  vérifiables). **Décidé par l'utilisateur** : « Remplir d'un toucher » **réglable** dans l'espace des
  grands (`SuiteSettings.tapToFillKey`) et **désactivé par défaut** → pinceau seul tant que l'adulte ne
  l'active pas.
- 🔊 **Troisième tour (session cloud, 28/09/2026 ; ✅ compilé, testé et installé sur l'iPad le soir même, voir
  « Compilé sur le Mac, 28/09 » plus bas)**. Demandes : « upgrade au
  niveau d'OrthoPicto voire plus » (Symbolicone, orthophoniste : livres par son, phrases S-V-C avec pictos
  qui s'animent, 3 niveaux, mode écrit — cf. tranches ci-dessous), puis en cours de route : « voix féminine
  naturelle qui suit les syllabes », « décompte des répétitions », « score selon la prononciation » →
  **étoiles de jeu** (pas un score de langage, cf. EVEIL.md § 4.6/7.3 ; accepté comme compromis, à
  confirmer avec l'utilisateur), « coloriage : plus de couleurs, gomme, mode interactif au choix ».
  - ✅ Tranche 1 : `VoiceCatalog` (meilleure voix féminine installée : accent du jeu > naturelle (ni
    fantaisie ni Eloquence) > féminine > premium/améliorée/standard ; choix + « Écouter » + Voix
    personnelle dans l'espace des grands) ; `ModelVoicePlayer` : API imposée
    (`AVSpeechSynthesisIPANotationAttribute`), `speakSegments` (wagon allumé par syllabe, fourgon à la
    fin, puis mot entier ; réglage `eveil.syllableModel`) ; décompte `RepetitionPlan` (1-5, défaut 3,
    seul un verdict complet avance, pas de boucle d'échec par répétition ; `RepetitionMeter`) ; étoiles
    `Stars.earned` (3/2/2/1/0, jamais de perte ; `StarsView` : volée du train au compteur, trésor sur
    l'accueil, masquable/vidable). Réf. Python `policy.py`/`lexicon.py` → **82 tests** ; miroirs Swift
    dans `WordEndCore` + `VoiceCatalogTests`.
  - ✅ Toucher un wagon = sa syllabe (`wagonSegments`, dernière sans la coda), le fourgon = vapeur +
    consonne (`cabooseSegment`) ; hors écoute/modèle. Dings de validation (arpège do-mi-sol-do) par
    wagon allumé, JOUÉS APRÈS l'écoute (jamais micro ouvert : le détecteur les entendrait). 83 tests Python.
  - ✅ Coloriage : palette **24 couleurs** (4 peaux ; 3×8 portrait, 6×4 paysage ; `WorkshopLayout`
    recalculé, tests de mise en page à jour), **gomme** (`PaintLayer.transparent`, pochoir, rayon 0,04),
    dessins/page suivante dans l'en-tête, **mode interactif** (`SuiteSettings.coloringInteractiveKey`,
    off par défaut : voix qui nomme la couleur, note pentatonique par couleur, « J'ai fini ! » → dessin
    qui danse + `ConfettiLayer` + fanfare). ColoringUI dépend désormais d'EveilSounds et WordEndAudio.
    Consignes « Colorie le soleil en jaune » : faites ensuite (voir plus bas).
  - ✅ Tranche 2, **le train des phrases** (`SentenceTrainView`) : locomotive « qui ? » + un wagon par
    morceau (fait quoi / quoi / où), couleurs par rôle (jaune/vert/orange/bleu, à valider) ; niveaux
    2 wagons · 3 wagons · « où ? » ; plateau ≤ 6 pictos en rotation fixe ; la voix pose la question avec
    ce qui est choisi puis dit la phrase morceau par morceau, et la **scène la joue** (n'importe quelle
    phrase : 20 verbes, 30 sujets, 57 compléments, 8 lieux / 31 mises en scène). Mode écrit (mots,
    phrase colorée, capitales au choix, réglages dans l'espace des grands) ; « Il l'a dite ! » (juge
    adulte) → étoiles. Python : `outils/phrases` (lexique, grammaire FR/EN avec élision, niveaux,
    vecteurs de parité → cible Swift pure **`PhraseCore`** + `PhraseCoreTests`) et `outils/pictos`
    (Lou, 20 verbes, 8 lieux à **ancres** par préposition, mesurées par `scene.py` ; → `PictoDessins.swift`).
    Scène : `SentenceMotion` (fonctions pures, testées : repos au début/fin, rien hors scène) peinte par
    `StagePainter`. ⚠️ Une ancre = **bas-milieu du carré** du personnage, pieds 21/200 plus haut
    (`StagePainter.stand`, test `testEveryAnchorKeepsTheSubjectOnStage`).
  - ✅ Tranche 4, **jeux d'écoute** (`EarGamesView`) : loto des bruits (19 images à bruit unique, 3 par
    manche) et « Où est… ? » (2 à 4 images) ; jamais « non » : l'autre image est nommée puis on
    réécoute ; manches en ordre fixe (`EarGames.pick`, vérifié en Python). Accueil : cartes sur deux
    rangées.
  - ✅ Tranche 3, **livres des sons** (`SoundBooksView`, `outils/livres`, `PracticeView` en
    `judge: .listenAndAdult` — **micro comme au petit train** (retour iPad de l'utilisateur, 28/09 soir :
    « quand on répète il ne se passe rien » ; avant : `.adult`, sans micro), verdict sur les syllabes
    (`bookWord` : noyaux = wagons, pas de consonne finale), + « Il l'a dit ! » de l'adulte pour le son
    du livre (ferme le micro ; jamais deux fois le même mot) ; wagon du son étoilé + lettres colorées, conseils « pour les
    grands ») : **complète** — 103 mots tous dessinés (57 nouveaux pictos `mot.*` en deux lots de
    sous-agents, `pictos/mots_a.py` + `mots_b.py`, relus sur planches), **16 livres FR, 15 EN**
    (`python3 -m livres.generer --check`). `--en-cours` = seulement les mots déjà dessinés (utile si
    on ajoute des mots avant leurs dessins). Faibles à revoir avec un illustrateur : genou, neige,
    lapin, moto, nuage (air d'icône), nez.
    18 tests Python (`livres/test_livres.py`) ; Swift : `SoundBooksTests`, `SoundBooksViewTests`,
    `AdultJudgeTests`.
  - ✅ **Phrases des livres** (choix de l'utilisateur, 28/09, « la suite ») : étagère à 3 niveaux (mots ·
    phrases qui+verbe+quoi · « et où ? » qui+verbe+où), 6 phrases/niveau/livre choisies par
    `livres/phrases.py` (glouton déterministe : ≥ 1 nom avec le son, noms ×2, verbe/prép. ×1, pénalité
    de reprise) → `SoundBookSentence` (cartes, marques, 3 choix/wagon, texte de parité) dans
    `SoundBooksData.swift`. `BookSentenceView` : image de la phrase finie (`SentenceStage(settled:)`),
    la voix la lit, « À toi ! », reconstruction parmi 3 pictos (« où ? » = même lieu autre préposition
    + autre lieu ; `PlaceScene` montre le sujet à l'ancre), autre picto nommé + bon éclairé, puis la
    scène joue ; « Il l'a dite ! » → étoiles. Lettres du son : **syllabe puis place du son**
    (`sons.lettres_dans_syllabe`, aussi pour les pages de mots : « sac » coloriait le « c »), contrôle
    d'alignement écrit/API (a trouvé « os·trich », « croc·o·dile », corrigés). Lexique des phrases
    + 49 mots des livres (30 qui, 57 quoi ; « les ciseaux » : genre pluriel, jamais sujet).
    Python : livres 30 tests, phrases 13 ; Swift compilé le 28/09 (tests `SoundBooksTests`,
    `SoundBooksViewTests`, `SentenceStageTests` + planche `phrase-cartes-ou.png`).
  - 🐞 **L'app se fermait en ouvrant les livres des sons** (retour iPad, 28/09) : en Debug, Swift bâtit
    un littéral géant (`SoundBooksData`, 349 Ko d'un bloc) dans la pile du fil principal → débordement.
    Corrigé : une fonction par livre (`bookFr00()`…), `MAX_PAR_LITTERAL = 40`, test
    `test_jamais_un_litteral_geant`. **À confirmer par l'utilisateur sur l'iPad.** Règle : jamais de
    gros littéral généré d'un seul tenant (même motif que `PictoDessins`, une fonction par picto).
  - ✅ **Consignes de coloriage** (choix de l'utilisateur, 28/09, « la suite ») : en mode interactif,
    « Colorie le soleil en jaune ! » (affichée à la place du titre, la toucher la redit + anneau).
    Parties nommées par page (`ColoringPart` : fr/en avec article, couleur imposée ou nil, rang 0 sujet /
    1 décor, un point par zone ; `Sketch.part`, même nom = même partie). `ColoringInstructions` (pur,
    testé) : 5 au plus, tri (rang, ordre), couleur nil → rotation fixe rouge, bleu, jaune, vert, orange,
    violet, rose, marron sans reprendre une couleur déjà demandée ; réussie si une zone de la partie a
    ≥ max(120 px, min(aire/8, page/50)) pixels de la couleur (`PaintLayer.count`, exact sur les
    segments de la carte). Jamais « faux » : ailleurs → au 2e essai la consigne se redit + anneau ;
    autre couleur sur la bonne partie → « En jaune ! » + pastille éclairée ; déjà faite → sautée.
    Pages Python : `nomme(…)`/motifs nommés (soleil, nuage, herbe, mer, roue, tronc, feuilles, sapin,
    fleur…), le ciel ajouté seul (bleu ciel) quand herbe/mer, contrôles `analyse.nommer` (zone entière
    ≥ 0,4 %, pas sur un trait, un seul nom par zone, couleur de la palette), étiquettes sur les
    aperçus ; sujets des 55 pages nommés par 3 sous-agents (relus sur planches), puis relus ici :
    ordre par page `page(…, consignes=(…))` (le sujet avant sa feuille), animaux d'une couleur
    fusionnés (« la biche » marron, pas 4 consignes « en marron »), couleurs corrigées (os jaune clair,
    bois de l'élan, vitres bleu ciel…), la dent de la brosse à dents non nommée (jaune = contre-
    message). ⚠️ Le motif `nuage` sert aussi de buisson/feuillage/mousse/brocoli : le renommer avec
    `nomme(…)` (sinon « le nuage »). **« au choix »** (`AU_CHOIX`, `ColoringInstructions.anyColor`) :
    l'enfant choisit — pour la **peau jamais de couleur imposée** (les mains), aussi la tache, la
    voiture de police ; consigne sans couleur, réussie de n'importe quelle couleur posée. Total :
    305 parties, 279 consignes, ≥ 2 par page, 1re = sujet (`test_chaque_sujet_est_nomme`). 15 pages
    Swift nommées à la main sur leurs **points-témoins** (déjà vérifiés : zone propre, ≥ 0,3 %) + le
    ciel au coin.
  - ✅ **Le dessin prend vie** (choix de l'utilisateur, 28/09, « la suite ») : au « J'ai fini ! » (mode
    interactif), 6 s de fête où les **parties bougent avec les couleurs de l'enfant**. Donnée :
    `ColoringPart.motion` (`PartMotion` : `.roll` roue = disque intérieur seul · `.spin` · `.pulse(a)`
    grandit seulement · `.sway(°, pivot: .contact/.top/.part("le tronc"))` · `.drift` · `.float`) ;
    pages générées : table par nom + corrections par page dans `outils/coloriages/vivant.py`
    (`MOUVEMENTS`, `PAR_PAGE` : la queue de l'avion ne remue pas, la coccinelle respire, le tee-shirt
    tourne, la flèche vibre), émise dans PagesDessins.swift ; pages Swift à la main (chat et chien
    gagnent « la queue », 6e partie, hors consignes). Algorithme (`vivant.py` = référence relue sur
    planches → `LivingDrawing.swift`) : pièces = zones voisines de la partie + zones sans nom qui ne
    tiennent qu'à elle + trous bouchés ; attache = milieu du contact (pas le fond, pas une pièce qui
    bouge ; « porteur » : le tronc, sinon le bas ; « suspendue » : le haut) ; découpe (silhouette +
    traits qui la bordent, +1 px), fond rebouché par propagation des couleurs voisines, pièce
    transformée par-dessus (`LivingPaper`, TimelineView) ; roues : 3 tours entiers (période 1,8 s),
    tee-shirt 2 (2,7 s) → pas de saut au repos (bug trouvé par le test). ⚠️ Pièges vus : le carrelage
    autour d'une serviette fausse le contact (→ `.top`) ; un feuillage qui frôle la tête de la biche
    tirait l'attache (→ `.part("le tronc")`) ; une roue entamée par le sol montrait une encoche (→
    disque intérieur). 69/70 pages bougent (cirque : danse d'ensemble seulement). Python : 15 tests
    (`test_vivant.py`) ; Swift : `LivingDrawingTests` (temps, attaches de parité à 1,5 %, toutes les
    pages, rendus `vivant-*.png` via `EVEIL_RENDER_DIR`). Planche `docs/ui/eveil-app/9-dessin-vivant.png`.
    Toucher la page arrête la fête ; « Réduire les animations » la retire. À compiler sur le Mac.
    EN : « bleu ciel » = « light blue » (« Color the sky sky blue! » sonnait faux). Tests Swift :
    `ColoringPartsTests`, `ColoringInstructionsTests` (chaque consigne de chaque page se réussit d'un
    remplissage de sa couleur, jamais d'une autre). À compiler sur le Mac.
  - ✅ **Mode papier** (choix de l'utilisateur, 28/09, « la suite ») : bouton « Colorier sur papier »
    (`doc.viewfinder`, en bas de la **colonne d'outils** — pas l'en-tête : en portrait il écrasait la
    consigne ; colonne = 7 boutons au plus, `WorkshopLayout.toolColumnHeight` 8,6) → carte en 3 étapes (`PaperSheet` : imprimer, colorier,
    photographier ; aperçu de la page imprimée ; `ReadingDots` pilotés par l'horloge). **Imprimer** :
    PDF A4 fait en mémoire (`PaperPrint`, `PaperLayout` = mêmes nombres que `papier/mise_en_page.py` :
    carré 480 pt en (57,64 ; 150), 4 repères pleins de 26 pt centrés à 26 pt des coins, hors du dessin,
    ≥ 18 pt du bord), `UIPrintInteractionController` (niveaux de gris). **Photographier** :
    `VNDocumentCameraViewController` (délégué `nonisolated` → `Task { @MainActor }`, photo mise à
    l'endroit ≤ 2000 px → `PaperPhoto` `@unchecked Sendable`). **Lire** (`PaperScan.read`, hors du fil
    principal) : repères cherchés sur la photo réduite à ~900 px (papier = 90e centile, sombre < 0,45 ×,
    boîte 0,4–2,5 × le côté, rapport 0,6–1,67, remplie ≥ 80 %, la plus PROCHE de sa place dans 10 % de
    la largeur ; sinon la photo = la page ; **feuille de côté ou à l'envers** : 2 sens essayés, ceux qui
    la mettent en portrait, places attendues ramenées sur la photo par `fromUpright`, sans tourner de
    pixel ; le sens gagnant = meilleur accord en 256 px) → homographie (DLT 8×8) → carré redressé à la taille de la
    carte → **accord** = part des pixels au cœur des traits (4 voisins de trait) qui sont de l'encre (clarté < 0,4 × papier ET chroma
    < 60 ; seuil 0,5) ; sinon recherche parmi les 70 pages en 256 px → `.otherPage` (l'atelier OUVRE
    cette page, avec sa carte) ; **coups de crayon** : balance des blancs (95e centile, gains 0,8–3),
    colorié si chroma ≥ 45 ou clarté ≤ 150, près d'un trait (0,6 %) chroma ≥ 70 seulement, le reste
    transparent (grain du crayon). `PaintLayer.load` (annulable, `.all`) → **le dessin prend vie** même
    hors mode interactif (`paperArrived`, `paperPending` : la fête attend le `onChange` de la page) ;
    les **consignes de la page s'arrêtent** (couleurs de crayon ≠ palette : « en jaune » reviendrait
    pour un soleil déjà jaune) ; carte des zones pas encore prête → calculée dans la lecture. Illisible : « Je n'ai pas bien vu la page. On réessaie ? » + conseil pour les grands.
    `NSCameraUsageDescription` (pbxproj Debug/Release + `Info-additions.plist`). Python `outils/papier/`
    (11 tests, dont les 4 sens de la feuille, **dans les conditions de l'app** : photo 1,6 px/pt, carte 1024 → repères à 0,3 px, bonne
    page 1,0, autre 0,21, couleurs à ~20/255) ; planche `docs/ui/eveil-app/10-mode-papier.png` ;
    Swift `PaperModeTests` (le vrai PDF rendu, colorié, photographié de travers ; rendus `papier-*.png`).
    ⚠️ Performances Debug : boucles par pixel sur pointeurs bruts (comme `ZoneMap`), pas de tableau
    littéral par pixel. Relecture indépendante (sous-agent, API vérifiées dans la doc Apple et règles
    du langage dans les sources du compilateur) : **aucune erreur de compilation certaine**. À compiler
    sur le Mac, **puis à essayer avec une vraie imprimante**.
  - ✅ **Compilé sur le Mac, 28/09/2026 au soir** (macOS 27.0, Xcode 27.0, Swift 6.4, tête `51f6238` +
    correctif) : Python 127 + 83, Swift `WordEndCore` 30 + paquet `ios` **184** (ColoringUI 75 dont
    consignes 8, parties 2, vivant 9, papier 15), build simulateur iOS et iPad réel, **0 avertissement**.
    Mode papier (VisionKit, impression), bouton de la colonne d'outils et dessin vivant compilés du
    premier coup. **Un vrai défaut** (`testTheRightPageAndNotAnother`) : en petit (256 px) la bonne page
    ne faisait que 0,69 (Python 0,96 ; 0,70 même sur le PDF rendu sans photo) — `ZoneMap.rasterize`
    (CoreGraphics sans anticrénelage) fait un trait **~1 px plus large** que `zones.masque_traits` à
    toutes les tailles (part de trait 0,223/0,167 à 256), sans effet sur les zones, mais à 256 px il
    déborde le trait imprimé → l'accord comptait les bords gris. Correctif Python + Swift : **accord sur
    le cœur des traits** (les 4 voisins sont du trait) → 0,97 (Python 0,999), autre page 0,21 ; seuils
    et tests inchangés. Planches : `papier-lu` juste, cartes lisibles portrait/paysage ; à revoir
    (cosmétique, dessin vivant) : restes gris de l'ancien contour d'un nuage qui dérive
    (`vivant-locomotive`), fond sous les ailes du papillon rebouché à l'orange du corps. App installée
    sur l'iPad ; mode papier à essayer avec une vraie imprimante.
- 🛡️ `eveil/outils/verifier_confidentialite.py` — « rien ne quitte l'iPad » vérifié statiquement
  (réseau, SDK tiers, CloudKit, enregistrement audio, ASR serveur, photo enregistrée ou convertie en
  fichier interdits) → 0 violation, 8 tests ;
  ignore les produits de compilation (`.build/`, `.swiftpm/`, `DerivedData/`).
- 📚 LibraryBrain = RAG **local sur le Mac** (non joignable depuis le cloud) → relais
  `eveil/librarybrain/` : 28 sources en accès libre + `recuperer_sources.py` (à lancer en local),
  thèmes arXiv, 18 questions `/ask`·`/consensus` pour fermer les NON VÉRIFIÉ + 15 **témoins** déjà
  tranchés (confirmés, nuancés et réfutés mêlés, sans dire lesquels) → **protocole de comparaison
  figé** `eveil/librarybrain/COMPARAISON.md` : passe P0 (bibliothèque telle quelle) puis P1 (+ PDF
  de `sources.json`), codage à l'aveugle d'après les passages cités, κ/Wilson via `wordend.bench`,
  **jamais `--avec-notes` avant la fin** (sinon LibraryBrain retrouve nos conclusions), réponses
  brutes locales `eveil/librarybrain/resultats/` (gitignoré : extraits sous droits, dépôt public).
  `test_questions.py` fige l'empreinte des 33 formulations.
  ✅ **Comparaison faite le 25/09/2026** → `docs/EVEIL-SOURCES-LIBRARYBRAIN.md` : P0 (bibliothèque
  telle quelle), **P0b** (contrôle après redémarrage : P1 l'exige car le routage par livre est
  mémoïsé, et le code servi changeait), P1 (+ 17 des 28 PDF ; 11 refusés/pages déclarés absents).
  Couverture **11/33 → 15/33** ; **aucune contradiction** des verdicts cloud (témoins P1 : 3/6 strict,
  κ 0,33 ; 6/6 souple) ; **A22 fermé** (HAS BSEM avril 2026 + ANAES 2001, vérifié dans le texte) ;
  17 sources nouvelles ; P0 = P0b au caractère près (génération reproductible, code sans effet).
  **Validé par l'utilisateur le 25/09/2026** : précisions B25 (limites de réalisation d'Allen 2013) et
  C6 (l'ASR « corrige ou ignore » l'erreur ; données d'enfants lecteurs) reportées dans la colonne
  *Affirmation* — verdicts inchangés, et jamais « LibraryBrain, vérifié dans le texte » dans la colonne
  *Verdict* (`mesurer.py` y lit une fermeture) ; ligne HAS/ANAES d'`EVEIL.md` mise à jour [A22].
  Outils : `interroger.py` (routes des pages, passages relus en lecture seule dans la base),
  `mesurer.py` (couverture/Wilson, accord/κ). Codage par 12 codeurs aveugles (sous-agents lancés hors
  du dépôt), codes figés avant ouverture des verdicts. Pièges LibraryBrain vus : l'API ne rend pas le
  texte des passages ; `/api/consensus` ne journalise pas ; chemins de fichiers en NFD (voire mixtes) ;
  livres ajoutés invisibles sans redémarrage (`book_routing`).
- ⚠️ Limite de la passe documentaire : proxy bloquant la plupart des sites académiques + quota
  WebSearch (200) épuisé → beaucoup de verdicts sur résumés ; Apple lu directement (DocC JSON via curl).

- ▶️ **REPRISE (en local sur le Mac)** : prompt prêt à coller dans **`eveil/REPRISE-LOCALE.md`** →
  (1) ✅ `swift test` du cœur + build iOS du paquet app, (2) ✅ comparaison **LibraryBrain ↔ passe
  cloud** (rapport `docs/EVEIL-SOURCES-LIBRARYBRAIN.md`) — les deux faits le 25/09/2026.

**Reste à faire :** iPad réel : Accès guidé à vérifier (signature et micro faits le 25/09/2026) · voix
enregistrées, illustrations et sons définitifs à la place des provisoires · acquérir les sources du rapport
(§ 7) puis rejouer (P2) · alors seulement `--avec-notes` + veille arXiv · panel Delphi (mots, messages,
nom, mascotte, voix) · protocole V1 (Jardé/CPP/CNIL à qualifier, corpus, calibration via le banc) ·
App 2 : mode papier **à essayer** avec une vraie imprimante et de vrais crayons (codé le 28/09) · décisions ouvertes :
nom, iPadOS 17 vs 26, mode par défaut avant validation (écoute auto vs juge adulte).

### 🧭 Veille concurrence
**Statut : mergé dans `main` (PR #18).** `docs/CONCURRENCE.md` — une
fiche par concurrent, chaque affirmation marquée **VÉRIFIÉ / DÉCLARÉ / INCONNU**.
- **POP Switcher** (popswitcher.com) : app Mac gratuite, IA locale multimodale
  (llama.cpp, stable-diffusion.cpp, ComfyUI), orchestrateur *The One*, RAG, Skills.
  Niveau **DÉCLARÉ** (site bloqué par le proxy de session, infos issues de la
  recherche web). Lecture : app perso grand public vs mon offre B2B ; il expose
  surtout l'absence d'installable (→ prioriser jalon D de Klody) et occupe la
  promesse « sans Terminal » de SilverBrain. **Code source : aucun dépôt public
  trouvé** sur GitHub ni Hugging Face (INCONNU, probablement propriétaire) →
  argument d'auditabilité pour Klody (MIT, tests publics).
- 📣 Post LinkedIn n° 8 (`docs/LINKEDIN-POSTS.md`) : positionnement « une IA locale,
  ce n'est pas encore une IA de confiance », **sans nommer de concurrent**.
- Reste : dérouler le protocole de test de la fiche sur le Mac (trafic sortant,
  hors ligne, RAM, The One sur petit modèle, MCP).

### Autres projets (mentionnés au README, hors de ce dépôt)
Klody Code AI (agent de code local, projet phare) · klody-ui · LibraryBrain (RAG local) ·
VocalBrain (voix) · Dream × World (mondes IA persistants).

---

_Dernière mise à jour mémoire : **veille concurrence** mergée (PR #18) — fiche
`docs/CONCURRENCE.md` sur POP Switcher (niveau DÉCLARÉ, aucun code public trouvé) + post
LinkedIn n° 8 de positionnement. Statuts recalés sur `main` : micro:bit (PR #13) et KLOD Live
Brain / GrooveDNA (PR #16) mergés. Toujours ouvert : AIoT/EdgeSense (PR #4, M0 codé, M2-M4 +
TinyGuard en conception) ; reprise matérielle Teensy sur le Mac ; Suite Éveil (PR #17, brouillon). Avant : Suite Éveil — **troisième tour compilé sur le Mac** (28/09/2026 au soir :
214 tests Swift + 210 Python verts, 0 avertissement ; accord du mode papier calculé sur le cœur des traits ;
app installée sur l'iPad ; puis les livres des sons écoutent au micro comme le petit train). Avant : **mode papier** (28/09/2026, session cloud : imprimer la
page, la colorier aux vrais crayons, la photographier ; l'atelier retrouve les repères, reconnaît la page,
pose les coups de crayon et le dessin prend vie ; référence Python dans les conditions de l'app, Swift à
compiler sur le Mac puis à essayer avec une imprimante). Avant : **le dessin prend vie** (28/09/2026, session cloud : au
« J'ai fini ! », les parties bougent avec les couleurs de l'enfant — roues, queues, ailes, soleil, nuages ;
prototype Python relu sur planches, portage Swift à compiler sur le Mac). Avant : **consignes de coloriage** (28/09/2026, session cloud :
« Colorie le soleil en jaune ! » en mode interactif, parties nommées sur les 70 pages ; correctif du
plantage à l'ouverture des livres, à confirmer sur l'iPad ; à compiler sur le Mac). Avant : **phrases des livres** (28/09/2026, session cloud : 3 niveaux
par livre, 6 phrases à reconstruire par niveau, cartes « où ? » avec le sujet à sa place, lettres du son
alignées syllabe par syllabe ; à compiler sur le Mac). Avant : **troisième tour, tranches 2 et 4**
(train des phrases avec scènes animées, jeux d'écoute, livres des sons complets — 16 + 15 livres,
57 nouveaux pictos ; `swift test` remis en marche sur le Mac par la session locale, icône de l'app). Avant : **tranche 1** (voix féminine choisie et syllabique, décompte des répétitions,
étoiles de jeu, syllabes au toucher, dings, coloriage 24 couleurs + gomme + mode interactif).
Avant : **atelier de coloriage : 70 pages en 7 albums** (25/09/2026,
session cloud : 55 pages dessinées et vérifiées en Python dans `eveil/outils/coloriages/`, un dessin par mot
du petit train ; Swift à tester sur le Mac). Avant : **app sur l'iPad réel + second tour** (25/09/2026 : micro
« essai par un adulte » et test du micro, voyage de monde en monde, 45 mots dessinés, bestioles et
bruitages calculés, coloriage à zones sur 15 pages). Avant : **ébauche jouable** (accueil, petit train,
mode démo, coloriage ; mascotte provisoire chat chef de gare). Avant :
**comparaison LibraryBrain ↔ passe cloud faite**
(25/09/2026 : couverture 11/33 → 15/33, aucune contradiction, A22 fermé, rapport
`docs/EVEIL-SOURCES-LIBRARYBRAIN.md`) et **Swift compilé et testé sur le Mac** (cœur 19/19, paquet
app 0 avertissement ; projet Xcode + iPad à faire avec l'utilisateur).
Avant : **prompt de reprise locale** (`eveil/REPRISE-LOCALE.md`) et **protocole figé de comparaison
LibraryBrain ↔ passe cloud** (33 questions, 2 passes, à l'aveugle). Avant : nouvel axe **Suite Éveil** (apps iPad 3 ans et +) sur la branche
`claude/ios-educational-apps-suite-dljtt6` — blueprint + état de l'art sourcé (6 axes), détecteur
de fin de mot **prouvé sur signaux synthétiques (69 tests)** avec banc de validation, portage Swift
non compilé ici (syntaxe vérifiée). Précédemment : KLOD Live Brain / GrooveDNA (35 tests), connecteur
`microbit/` (33 tests), AIoT/EdgeSense au stade PR #4._
