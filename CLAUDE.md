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
**Statut : branche `claude/microbit-bluetooth-connection-jb4jwf`, basée sur `main`.**
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
**Statut : branche `claude/klod-live-brain-groovedna-hmm1nu`, basée sur `main`.**
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

### Autres projets (mentionnés au README, hors de ce dépôt)
Klody Code AI (agent de code local, projet phare) · klody-ui · LibraryBrain (RAG local) ·
VocalBrain (voix) · Dream × World (mondes IA persistants).

---

_Dernière mise à jour mémoire : nouvel axe **KLOD Live Brain / GrooveDNA** sur la branche
`claude/klod-live-brain-groovedna-hmm1nu` — moteur de *feel* rythmique (capture/transfert/
morphing, format versionné `KLOD_GROOVE_V1`), **couche musical prouvée en Python stdlib pur
(35 tests)** + audit Phase 0 (`TECHNICAL_REALITY.md`). Couche réflexe Teensy = FAISABLE, à
mesurer. Précédemment : connecteur `microbit/` (BLE + MCP, 33 tests) ; AIoT/EdgeSense au stade
PR #4 (M0 codé, M2-M4 + TinyGuard en conception)._
