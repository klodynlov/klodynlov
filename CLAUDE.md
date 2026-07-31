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
- Reste possible (non demandé) : captures PNG dans le README.

#### 💼 Volet SaaS — `docs/SILVERBRAIN-SAAS.md` (branche `claude/saas-potential-apps-83bt61`)
Analyse : SilverBrain = **seul projet du portfolio avec payeur ≠ utilisateur** → candidat
produit récurrent. Modèle retenu : **calcul local + plan de contrôle distant** (le serveur
route des événements typés chiffrés E2E ; audio, transcriptions et profil ne quittent
jamais la box). Le **portail aidant** (jalon 4) devient le composant commercial.
- Segments, dans l'ordre : **A** famille B2C (apprendre) → **B** résidences services /
  SAAD B2B2C (**le modèle viable** : matériel en CAPEX exploitant + support N1 délégué)
  → **C** B2G (APA, CCAS ; long mais l'argument « données locales » y devient éligibilité).
- Ancrages sourcés : téléassistance 15-30 €/mois et **900 k abonnés** FR · **crédit
  d'impôt SAP 50 %** (⇒ 29 € ressentis 14,50 €) · 108 286 logements en résidences services ·
  **ElliQ** 249 $ + ~59 $/mois, 800+ unités via NY Office for the Aging (valide prix +
  canal public, mais cloud & anglophone → créneau européen/francophone libre).
- Économie unitaire (hypothèses) : le **support** et le **matériel** décident, pas le prix ;
  ~22 mois de récupération en B2C, immédiate en B2B2C ; équilibre ≈ 800 logements actifs.
- Risques n°1-3 : **latence/coût du matériel local** (MLX ≠ carte à 300 €) · rejet par le
  senior · **churn structurel 20-30 %/an** (décès, entrée en établissement).
- Garde-fous : rester **hors dispositif médical** (accompagner, pas secourir), AIPD
  obligatoire, périmètre v1 verrouillé contre la dérive « mouchard » (pas de transcriptions).
- **Prochaine action recommandée : jalon 0 « banc matériel »** (STT+SLM+TTS sur 3 cibles,
  latence < 1,2 s, coût) — il peut invalider le projet seul — puis porte 1 : 10 entretiens
  aidants (script en annexe du dossier). Aucun code produit avant.

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

### Autres projets (mentionnés au README, hors de ce dépôt)
Klody Code AI (agent de code local, projet phare) · klody-ui · LibraryBrain (RAG local) ·
VocalBrain (voix) · Dream × World (mondes IA persistants).

---

_Dernière mise à jour mémoire : suivi AIoT/EdgeSense au stade PR #4 (M0 codé, M1-M4 + TinyGuard en conception)._
