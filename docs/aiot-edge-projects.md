# AIoT & edge-AI local — état de l'art 2025-2026 et notes de conception

> **Nature de ce document.** Une synthèse sourcée de l'état de l'art AIoT / edge-AI
> (issue d'une recherche multi-sources vérifiée en contradiction), suivie de deux
> **notes de conception** pour des projets réalisables par un ingénieur solo, alignés
> avec une stack **local-first** : MLX/Ollama + MCP + Python/Rust.
>
> Méthode : 6 angles de recherche, 27 sources récupérées, 41 affirmations extraites,
> 25 vérifiées par vote adversarial à 3 voix (2/3 pour réfuter) → **21 confirmées,
> 4 réfutées**. Les affirmations réfutées sont listées explicitement pour ne pas
> s'appuyer dessus.

---

## 1. Pourquoi l'AIoT, pour ce profil

L'AIoT (*Artificial Intelligence of Things*) fait tourner l'IA **sur** l'objet / l'edge
plutôt que dans le cloud. C'est le prolongement naturel d'un positionnement
« IA 100 % locale / privée » : les données des capteurs ne quittent jamais le réseau
de l'utilisateur, la latence est déterministe, et le coût d'inférence bascule sur le
matériel de l'utilisateur.

## 2. État de l'art — ce qui est solidement établi

Chaque point ci-dessous a passé une vérification adversariale (vote 3-0 sauf mention).

### 2.1 L'inférence on-device est passée en production
ExecuTorch (Meta) a atteint la **1.0 GA en octobre 2025** : empreinte de base ~50 KB,
12+ backends matériels (Apple, Qualcomm, Arm, MediaTek, Vulkan), >80 % des LLM edge
populaires de HuggingFace fonctionnant « out of the box ». Des modèles à un milliard
de paramètres tournent désormais en temps réel sur mobile haut de gamme.
*(chiffres de lancement Meta/Arm, recoupés PyTorch blog + Arm Newsroom + Embedded.com)*

### 2.2 Une famille de petits modèles (SLM) quantifiés cible l'edge
Menu prêt à l'emploi pour un solo, tous disponibles en GGUF/MLX via Ollama :

| Modèle | Tailles | Note |
|---|---|---|
| Llama 3.2 | 1B / 3B | référence edge généraliste |
| Gemma 3 | jusqu'à **270M** | INT4 ≈ 0,75 % de batterie Pixel / 25 conversations |
| Phi-4-mini | 3.8B | raisonnement compact |
| SmolLM2 | 135M – 1.7B | très léger |
| Qwen2.5 | 0.5B – 1.5B | bon tool-calling |

### 2.3 Rôles des runtimes sur Apple Silicon (ta stack MLX/Ollama)
Benchmark contrôlé (arXiv 2511.05502, M2 Ultra 192 Go, Qwen-2.5, prompts jusqu'à 100k
tokens, novembre 2025) :

| Runtime | Rôle recommandé | Chiffres clés |
|---|---|---|
| **MLX** | moteur de **génération** (débit) | ~230 tok/s, 5-7 ms/token |
| **MLC-LLM** | meilleur **TTFT** sur prompts moyens | ~190 tok/s, ~13 ms/token |
| **llama.cpp** | single-stream léger, le plus efficace | — |
| **Ollama** | **prototypage / serving** (ergonomie dev) | débit/TTFT en retrait |
| PyTorch MPS | à éviter sur gros modèles / longs contextes | limité en mémoire |

> ⚠️ **Portée limitée** : ce classement vaut **sur Apple Silicon uniquement**. Aucun
> benchmark équivalent trouvé sur **Jetson (CUDA)** ou **Raspberry Pi (ARM CPU)** —
> l'avantage de MLX tient peut-être à la mémoire unifiée Apple. À mesurer soi-même sur
> cible SBC.

### 2.4 MCP = couche de traduction universelle capteurs ↔ agents
Les objets exposent leurs fonctions comme **serveurs MCP**, l'agent est **client** : la
complexité d'intégration passe de **M×N à M+N**. Déjà réel pour la domotique :
`ha-mcp` (homeassistant-ai/ha-mcp, ~85 outils, activement maintenu) expose Home
Assistant (capteurs, états, services, automatisations) en langage naturel, **en local
sur le LAN**.

> ⚠️ **Nuance confidentialité (vote 2-1)** : `ha-mcp` peut aussi se brancher sur un
> client MCP **cloud** (Claude.ai, ChatGPT) — dans ce mode, les données de la maison
> atteignent le LLM cloud. La confidentialité totale **exige de le coupler à un modèle
> local** (Ollama/MLX).

### 2.5 La quantification : levier central, mais pas gratuit
- 4 techniques de quantification post-training (Dynamic Range, Full Integer, Float16,
  Int16x8) : **~4× de réduction** d'empreinte en INT8, **~2×** en FP16.
  *(Springer LNNS 1066 / IntelliSys 2024 + docs Google AI Edge/TFLite ; ratios
  invariants issus de l'arithmétique de largeur de bits.)*
- **Contrepartie** : la quantification bas-bits agressive (AWQ, GPTQ) provoque jusqu'à
  **32,4 % de perte** (moyenne **11,3 %**) sur le raisonnement mathématique de Llama-3.
  *(arXiv 2501.03035)*. **Récupérable** par un fine-tuning court (~545 exemples,
  ~3 min sur 4 GPU) → garder un chemin de modèle plus précis (ou fine-tuné) pour les
  étapes de raisonnement critiques de l'agent.

### 2.6 TinyML = le palier le plus contraint
Déploiement sur microcontrôleurs (de quelques KB à quelques centaines de KB de RAM).
C'est cette limite mémoire qui **force** la quantification agressive. Enjeux d'ingénierie
principaux : optimisation, capacité de traitement, fiabilité, maintenance.
*(MDPI Electronics 2024, 13(17):3562 ; Springer LNNS 1066)*

## 3. Ce qui a été RÉFUTÉ — ne pas s'appuyer dessus

| Affirmation réfutée | Vote | Conséquence pratique |
|---|---|---|
| Archi **MCP + MQTT événementielle** (télémétrie via MQTT, actions via MCP) | 1-2 | MCP seul **non prouvé** suffisant pour le push capteur temps réel → prévoir un transport pub/sub séparé et le valider soi-même |
| CompactifAI (quantum-inspired) « −62 % d'énergie » | 0-3 | ne pas citer comme levier énergie |
| Coût d'inférence CPU **linéaire** en tokens | 1-2 | pas de modèle de coût simple garanti |
| ExecuTorch « en prod sur Instagram/WhatsApp/Messenger » | 1-2 | non confirmé |

## 4. Angles morts (à instrumenter soi-même)
- Débit réel des runtimes sur **Jetson / Raspberry Pi** (rien de comparable publié).
- Enveloppe **énergie/thermique** et **dérive de modèle (drift)** en fonctionnement
  **24-7 sur plusieurs mois** — signalés comme sous-documentés par la littérature.
- Plancher de précision d'un SLM sub-1B pour le **tool-calling agentique** après
  quantification 4-bit.

---

## 5. Note de conception — Projet A : `EdgeSense`

**Pont MCP capteurs → agent local.** Un serveur MCP qui expose les capteurs et
actionneurs d'un edge (Raspberry Pi, ESP32 en amont) comme des *outils* que des agents
locaux (p. ex. Klody) peuvent lire et actionner. L'IA raisonne en local sur les données
des objets.

**Pourquoi ce projet** : prolonge directement le positionnement *client **et** serveur
MCP*, et se démarque de la vague déjà encombrée « LLM + Home Assistant ».

### 5.1 Architecture

```
┌─────────────┐   MQTT/série   ┌──────────────────┐   MCP (stdio/HTTP)   ┌──────────────┐
│  Capteurs   │ ─────────────► │   EdgeSense       │ ◄──────────────────► │  Agent local  │
│  ESP32/GPIO │                │  (serveur MCP)    │   tools + resources  │  (Klody)      │
│  I²C, caméra│ ◄───────────── │                   │                      │  + MLX/Ollama │
└─────────────┘   commandes    │  ┌─────────────┐  │                      └──────────────┘
                               │  │ bus interne │  │
                               │  │  (pub/sub)  │  │  ← télémétrie temps réel
                               │  └─────────────┘  │     (transport séparé, cf. §3)
                               │  cache état SQLite│
                               └──────────────────┘
```

- **Serveur MCP** (Python, SDK MCP officiel) : expose des `tools`
  (`read_sensor`, `set_actuator`, `list_devices`, `subscribe`) et des `resources`
  (snapshot d'état, historique récent).
- **Bus interne pub/sub** : puisque l'archi MCP+MQTT événementielle **n'est pas
  prouvée** (§3), la télémétrie temps réel passe par un transport dédié (MQTT local, ou
  simple boucle asyncio + WebSocket) et MCP sert au *contrôle* et à la *lecture d'état*.
- **Cache d'état SQLite** : dernier état connu de chaque capteur + fenêtre glissante,
  pour répondre instantanément aux `resources` sans réveiller le matériel.
- **Cœur Rust optionnel** : la couche de collecte capteurs (série/I²C, boucle temps
  réel) est un bon candidat Rust ; le serveur MCP reste Python pour l'itération rapide.

### 5.2 Choix techniques
- **Modèle agent** : Qwen2.5 1.5B (bon tool-calling) ou Llama 3.2 3B via Ollama ;
  MLX si l'agent tourne sur un Mac hôte plutôt que sur le Pi.
- **Garde-fous sécurité** (réutilise l'ADN Klody) : allowlist d'actionneurs, bornes
  physiques (jamais de commande hors plage), journalisation signée des actions.
- **Transport MCP** : stdio en dev local, HTTP/SSE si l'agent est sur un autre hôte du
  LAN.

### 5.3 Feuille de route
1. **M0 — Squelette MCP** : serveur exposant 1 capteur simulé + 1 actionneur simulé ;
   un agent lit et actionne. *Preuve de boucle.*
2. **M1 — Matériel réel** : brancher un vrai capteur (DHT22/BME280) + relais sur Pi ;
   cache SQLite.
3. **M2 — Temps réel** : bus pub/sub pour la télémétrie ; l'agent réagit à un seuil.
4. **M3 — Sécurité & robustesse** : allowlist, bornes, journal signé, reconnexion.
5. **M4 — Multi-nœuds** : plusieurs ESP32 en amont d'un Pi passerelle.

### 5.4 Risques
- **Push temps réel** (le principal) : MCP seul insuffisant → valider tôt le transport
  pub/sub (M2), ne pas le repousser.
- Fiabilité série/I²C sur durée longue → prévoir watchdog + reconnexion dès M3.

---

## 6. Note de conception — Projet B : `TinyGuard`

**Surveillance vidéo/audio 100 % edge.** Détection d'événements (personne, son anormal)
par un modèle quantifié tournant **sur l'appareil** ; rien ne part dans le cloud.
Alertes locales, éventuellement routées vers un agent via MCP.

**Pourquoi ce projet** : incarne l'argument commercial « données qui ne peuvent pas
aller dans le cloud ».

### 6.1 Architecture

```
┌────────────┐  flux RTSP/I²S  ┌───────────────────┐  événements  ┌──────────────┐
│ Caméra/micro│ ──────────────► │   TinyGuard        │ ───────────► │ Alerting local│
│ (Pi5/Jetson)│                 │  détection edge    │              │ + MCP → agent │
└────────────┘                  │  ┌──────────────┐  │              └──────────────┘
                                │  │ vision quant.│  │  (INT8/FP16)
                                │  │ VAD + audio  │  │
                                │  └──────────────┘  │
                                │  ring-buffer local │  ← pré/post-roll clips
                                └───────────────────┘
```

- **Détection vision** : modèle quantifié (YOLO-nano / MobileNet-SSD en INT8) sur
  Pi 5 (CPU/NPU) ou Jetson (CUDA). **Débit à mesurer soi-même** — non benchmarké dans
  la littérature trouvée (§4).
- **Détection audio** : VAD léger + petit classifieur (bris de verre, alarme) façon
  TinyML.
- **Ring-buffer local** : ne conserve que les clips pré/post-événement, jamais un flux
  continu → minimise stockage **et** exposition des données.
- **Sortie** : notification locale ; option serveur MCP `TinyGuard` exposant
  `list_events`, `get_clip`, `get_status` pour qu'un agent (ou HomePilot) raisonne
  dessus.

### 6.2 Choix techniques
- **Runtime vision** : ONNX Runtime ou TFLite selon la cible ; sur Jetson, TensorRT.
- **Quantification** : INT8 (~4× de réduction) — mais **valider la précision** sur les
  classes utiles ; la perte est réelle sur les tâches fines (§2.5), donc mesurer le
  rappel sur « personne » avant de descendre en bas-bits.
- **Langage** : pipeline de capture/encodage en Rust (perf, gestion mémoire du
  ring-buffer) ; orchestration et modèle en Python.

### 6.3 Feuille de route
1. **M0 — Détection offline** : une image → boîte englobante, modèle INT8, mesurer
   FPS + rappel sur la cible.
2. **M1 — Flux temps réel** : RTSP → détection continue sur Pi5/Jetson ; ring-buffer.
3. **M2 — Audio** : VAD + 1 classe sonore (ex. alarme).
4. **M3 — Alerting** : notification locale + clips ; **budget énergie/thermique mesuré**
   sur 24-7 (angle mort §4 — instrumenter température/conso).
5. **M4 — Exposition MCP** : serveur MCP pour brancher un agent (jonction avec
   `EdgeSense` / `HomePilot`).

### 6.4 Risques
- **Débit sur ARM CPU** (le principal) : inconnu publié → prototyper M0 sur le vrai
  matériel avant de s'engager sur le reste.
- **Perte de rappel après quantification** → mesurer, garder un palier FP16 de secours.
- **Thermique 24-7** → mesurer tôt (M3), pas en fin de parcours.

---

## 7. Jonction des deux projets
`EdgeSense` (capteurs/actionneurs) et `TinyGuard` (perception) exposent tous deux du
**MCP** : un agent local unique peut alors *percevoir* (TinyGuard) et *agir* (EdgeSense),
ce qui ouvre la voie à un troisième projet, `HomePilot` (domotique agentique locale),
sans dépendance cloud.

---

## Sources principales
- Vikas Chandra (Meta), *On-Device LLMs: State of the Union 2026* — https://v-chandra.github.io/on-device-llms/
- *Production-Grade Local LLM Inference on Apple Silicon*, arXiv 2511.05502 (nov. 2025)
- *Quantization Meets Reasoning*, arXiv 2501.03035 (janv. 2025)
- Shabir et al., *Edge AI on Constrained IoT Devices: Quantization Strategies*, Springer LNNS 1066 / IntelliSys 2024
- *Advancements in TinyML*, MDPI Electronics 2024, 13(17):3562
- ExecuTorch 1.0 GA — PyTorch blog / Arm Newsroom
- `ha-mcp` — https://github.com/homeassistant-ai/ha-mcp

> Champ mouvant : les chiffres (débits, tailles de modèles, classements de runtimes)
> évoluent en quelques mois. Les résultats les plus forts sont des préprints
> oct.-nov. 2025 / fév. 2026 et des annonces de lancement. À réévaluer périodiquement.
