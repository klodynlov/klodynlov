# 🧭 Veille concurrence — IA locale sur Mac

Fiches des offres qui occupent le même terrain que mes projets (IA 100 % locale,
Apple Silicon, agents). But : **savoir où je mène, où je suis en retard, et quoi
en faire** — pas dénigrer.

> **Règle de la fiche** : chaque affirmation sur un concurrent porte son niveau de
> preuve, comme dans mes audits techniques.
> - **VÉRIFIÉ** — testé ou mesuré par moi.
> - **LU** — constaté dans son code source publié, mais non exécuté.
> - **DÉCLARÉ** — lu dans sa communication publique, non testé.
> - **INCONNU** — question ouverte, à vérifier.
>
> Mes propres chiffres viennent du [README](../README.md) (mesures du 3 septembre 2026).

---

## POP Switcher — [popswitcher.com](https://popswitcher.com/)

_Fiche créée le 2 octobre 2026 · niveau de preuve global : **DÉCLARÉ** (aucun test de l'app à ce jour)._

### En une phrase

App Mac **gratuite** qui orchestre des modèles d'IA locaux (chat, code, image, son,
documents) **sans Terminal** ni abonnement, pour un utilisateur seul sur sa machine.
Éditeur : entreprise individuelle française (mentions légales publiées).

### Ce qu'il annonce (DÉCLARÉ)

- Fonctionne **hors ligne sur Apple Silicon**, « aucune donnée dans le cloud **par défaut** ».
- Runtimes : **llama.cpp**, **stable-diffusion.cpp**, **ComfyUI**.
- **The One** : orchestrateur local qui découpe une mission, choisit des « rôles » IA
  et reprend là où on s'était arrêté.
- Mémoire persistante, contexte par rôle, **index documentaire RAG**, embeddings
  locaux, recherche vectorielle, jobs asynchrones.
- **Skills** (consignes métier, checklists, contraintes de sortie réutilisables),
  mode réflexion, **recherche web approfondie**, tâches IA planifiées.

### Comparaison brique par brique

| Brique | POP Switcher (DÉCLARÉ) | Mes projets | Avantage |
|---|---|---|---|
| **Produit installable** | App prête, gratuite, sans Terminal | Klody « consulting-ready » prévu le 15/12 ([jalon D](KLODY-ROADMAP.md)) ; [SilverBrain](SILVERBRAIN.md) au stade concept + maquettes | **POP**, nettement |
| **Orchestration / agents** | The One, Skills, tâches planifiées | Klody : boucle ReAct, 69 outils, routeur adaptatif, Best-of-N en cours | **Moi** en profondeur, **POP** en accessibilité |
| **Code** | Un usage parmi d'autres | Produit phare, 2 829 tests | **Moi** |
| **RAG / mémoire** | Index RAG, embeddings, vecteurs, mémoire par rôle | Library Brain : 25 376 docs, 1,8 M chunks, réponses sourcées, refus quand la preuve manque | **Moi**, en rigueur et en échelle |
| **Image** | stable-diffusion.cpp, ComfyUI | Rien de packagé | **POP** |
| **Son / musique** | Génération audio | VocalBrain, SampleBrain, [GrooveDNA](../klod-live-brain/) (microtiming mesuré, 35 tests) | Pas le même sujet : génération vs analyse et transfert du *feel* |
| **Inférence** | llama.cpp & co. | MLX + [ram-aware-scheduler](https://github.com/klodynlov/ram-aware-scheduler) (plusieurs modèles, un budget RAM) | Égalité : étendue (POP) vs optimisation Apple Silicon (moi) |
| **MCP / monde physique** | Rien d'annoncé | MCP client + serveur, [micro:bit BLE](MICROBIT-BLUETOOTH.md), EdgeSense, Teensy | **Moi**, seul sur ce terrain |
| **Code source / auditabilité** | Aucun dépôt public trouvé (**INCONNU**) : probablement propriétaire, distribué en binaire | Klody sous licence MIT, 2 829 tests publics | **Moi** : un client peut auditer mon code |
| **Sécurité / preuves** | « Pas de cloud par défaut » + recherche web | Sandbox, anti-SSRF, CI sécurité, 0 requête tierce mesurée, discipline PROUVÉ/FAISABLE | **Moi** |
| **Public non technique** | Cœur de sa promesse | SilverBrain (seniors), pas encore de prototype | **POP** aujourd'hui |

### Lecture

**Pas le même client.** POP Switcher vend (gratuitement) une **app personnelle
généraliste**. Je vends du **déploiement et de l'ingénierie** pour des équipes
dont les données ne peuvent pas sortir. Nos briques se recoupent beaucoup, nos
clients peu.

**Où il me menace**
- **Il est installable aujourd'hui, moi pas encore.** Objection probable d'un
  prospect : « POP Switcher fait du RAG local gratuitement, pourquoi vous payer ? »
  C'est exactement l'écart que couvre le jalon D de Klody.
- **Il occupe déjà la promesse « IA locale sans Terminal »**, celle de SilverBrain.
  SilverBrain doit se différencier par la **voix d'abord**, la **formulation
  adaptative** et le **lien aux proches**, pas par « c'est local ».

**Où je mène**
- **L'équipe, pas l'individu** : audit, approbation humaine avant écriture,
  réponses sourcées, intégration au SI. Une app mono-poste ne couvre pas ça.
- **La preuve** : tests, mesures publiques, audits honnêtes. C'est ce qu'achète
  un DSI ou un DPO.
- **MCP et matériel** : aucun équivalent annoncé chez lui.
- **Auditabilité** : aucun code publié chez lui à ma connaissance ; le mien est
  ouvert et testé. Pour des données sensibles, pouvoir lire le code est un argument.
- **« Zéro cloud » nuancé chez lui** : une recherche web fait sortir des requêtes ;
  mon « 0 requête tierce » est mesuré. (Activation par défaut ou à la demande :
  **INCONNU**.)

### Décisions

1. **Ne pas l'affronter sur l'app grand public généraliste** : gratuit, multimodal,
   déjà sorti — terrain perdu d'avance.
2. **L'utiliser comme contraste dans le pitch**, sans le dénigrer : « une app
   personnelle, c'est très bien pour un particulier ; vos données d'équipe exigent
   traçabilité, garde-fous et preuves mesurées. » Il valide la catégorie.
3. **Prioriser le jalon D** (Klody installable par un tiers) : c'est le seul écart
   qu'il expose vraiment.

### À vérifier (protocole de test sur mon Mac)

Objectif : faire passer la fiche de **DÉCLARÉ** à **VÉRIFIÉ**, avec la même
méthode que mes propres mesures.

- [ ] **Trafic sortant** : app ouverte, usage normal, recherche web désactivée puis
      activée → hôtes contactés (pare-feu applicatif type Little Snitch / LuLu).
- [ ] **Hors ligne réel** : Wi-Fi coupé → chat, RAG, image, son fonctionnent-ils ?
- [ ] **Mémoire** : RAM consommée par usage (chat 7-8B, image, RAG chargé) ; tient-il
      sur un Mac 8 Go / 16 Go ?
- [ ] **The One avec un petit modèle** : sur 3 missions types, la décomposition
      tient-elle ? (Les modèles quantifiés perdent en raisonnement — voir
      `docs/aiot-edge-projects.md`, PR #4.)
- [ ] **RAG** : cite-t-il ses sources ? refuse-t-il quand la preuve manque ?
- [ ] **Distribution** : app signée et notarisée Apple ? licences des modèles
      embarqués affichées ?
- [ ] **MCP** : en parle-t-il ? Si oui, mes serveurs (micro:bit, EdgeSense)
      pourraient devenir des « rôles » appelables — interopérabilité plutôt que
      concurrence.
- [ ] **Code source** : le 2 octobre 2026, aucun dépôt trouvé sur GitHub ni sur
      Hugging Face (recherche web seulement ; API Hugging Face et site bloqués par
      la session). À confirmer depuis un navigateur
      ([GitHub](https://github.com/search?q=popswitcher&type=repositories),
      [Hugging Face](https://huggingface.co/search/full-text?q=popswitcher)) et
      dans l'écran « À propos » de l'app (licence, lien vers le code).
- [ ] **Modèle économique** : qu'est-ce qui financera la suite d'une app gratuite ?

### Sources

- [POP Switcher — IA locale pour Mac](https://popswitcher.com/)
- [Mentions légales — POP Switcher](https://www.popswitcher.com/mentions-legales.html)

---

## localcode — [mjwsolo/localcode](https://github.com/mjwsolo/localcode)

_Fiche créée le 23 novembre 2026 · version analysée : **0.5.43** (PyPI, 22/11/2026) ·
niveau de preuve global : **LU** (archive source et dépôt lus ; rien exécuté, faute de
Mac Apple Silicon dans la session)._

### En une phrase

Agent de code **open source (Apache 2.0)** pour Mac Apple Silicon : `uv pip install
localcode`, puis `localcode` dans le dossier du projet. Il choisit un modèle selon la RAM,
le télécharge et lance un serveur d'inférence local. C'est **exactement la promesse de
Klody**, et elle est déjà livrée.

### Ce qu'il y a dans la boîte (LU)

- **Deux binaires Mach-O arm64 embarqués dans la wheel** :
  - `llama-server` (25 Mo) : un **fork de llama.cpp** défini comme « upstream + série de
    patchs ». 13 patchs : cache KV **TurboQuant**, noyaux Metal précompilés et NVFP4,
    support de nouveaux modèles. Le rebase sur upstream est **automatisé chaque semaine**
    en CI.
  - `localcode-ui` (102 Mo) : l'agent lui-même, un **fork d'OpenCode** compilé avec Bun.
    Son source est public ([mjwsolo/opencode](https://github.com/mjwsolo/opencode)) et
    le commit exact du binaire (`FORK_COMMIT` 4cc1f15) y existe.
- Une couche **Python d'environ 16 000 lignes** : supervision, catalogue de modèles,
  téléchargement reprenable, garde mémoire, garde thermique, voix (whisper.cpp + Piper).
  Elle comprend aussi l'option `localcode api`, un endpoint OpenAI-compatible réutilisable
  par d'autres apps.
- **12 modèles, 169 quantifications** (Gemma 4, Qwen 3.6/3.8, DeepSeek V4 Flash…),
  téléchargés depuis Hugging Face. Minimum 16 Go de mémoire unifiée.
- **Qualité** : 81 fichiers de tests (635 fonctions `test_`), 33 tâches d'évaluation sur
  **Inspect AI** (UK AISI) plus Harness-Bench. Le projet annonce que chaque release est
  testée en live sur chaque modèle (**DÉCLARÉ**). 163 versions publiées depuis avril 2026 :
  **développement très actif**, mais toujours étiqueté alpha.

### Sécurité et réseau (LU, et c'est le cœur de la comparaison)

**Bien fait** (dans `ui/launch.py`) :
- Le seul fournisseur de modèles autorisé est le serveur local : toute autre utilisation
  de fournisseur est refusée. Les fonctions cloud d'OpenCode sont désactivées (partage,
  auto-update, téléchargement de LSP).
- La config du projet (qui peut exécuter du code) est **ignorée par défaut** et ne charge
  qu'avec `--trust-project`.
- Tout est lié à `127.0.0.1`, et chaque session a deux secrets aléatoires, donc une page
  web ne peut pas piloter le serveur local.
- La télémétrie locale est **opt-in** (désactivée par défaut). La doc ne mentionne aucun
  endpoint d'analytics.
- L'agent demande avant d'accéder à des chemins **hors du projet**.

**Le point faible**, confirmé par sa propre doc
([Network Boundary](https://mjwsolo.github.io/localcode/concepts/network-boundary/)) :
> « Les outils web, les outils MCP et les commandes shell s'exécutent tous **sans demande
> d'autorisation** » (traduit de l'anglais).
- Les commandes shell dans le projet, `webfetch` (vers n'importe quelle URL), la recherche
  DuckDuckGo et les outils MCP s'exécutent **sans approbation**.
- Il n'y a **aucun sandbox OS** : ni `sandbox-exec` ni Seatbelt dans le code. La seule
  barrière est un filtrage par chemin, et une commande shell peut joindre n'importe quel
  hôte.
- Conséquence **FAISABLE, non testée** : une injection de prompt (README piégé, page web
  lue par `webfetch`) peut faire exécuter du shell et sortir des données. Son
  `SECURITY.md` le reconnaît lui-même : « évitez de lancer LocalCode sur des dépôts
  sensibles sans comprendre les permissions ».

### Comparaison brique par brique

| Brique | localcode | Klody Code AI | Avantage |
|---|---|---|---|
| **Installation** | `pip install` + 1 commande, modèle choisi selon la RAM (LU) | « Consulting-ready » prévu le 15/12 ([jalon D](KLODY-ROADMAP.md)) | **localcode**, nettement |
| **Moteur d'inférence** | llama.cpp patché : TurboQuant, drafting spéculatif, *copy drafting*, noyaux Metal (LU) | MLX + [ram-aware-scheduler](https://github.com/klodynlov/ram-aware-scheduler) | **localcode** en profondeur d'optimisation ; MLX reste un bon choix pour la génération sur Apple Silicon |
| **Choix de modèles** | 12 familles, 169 quantifications, téléchargement reprenable | Modèles MLX | **localcode** |
| **Boucle d'agent** | OpenCode (communauté large), plan, détection de blocage, sans sous-agents (LU) | ReAct maison, 69 outils, routeur adaptatif, Best-of-N en cours | Égalité : base éprouvée (localcode) vs orchestration sur mesure (moi) |
| **Approbations** | Shell, web et MCP **sans approbation** dans le projet (LU + doc) | Lecture seule par défaut, **approbation humaine avant toute écriture sensible** | **Moi**, et c'est décisif pour une équipe |
| **Isolation / réseau** | Pas de sandbox OS ; `webfetch` vers toute URL (LU) | Sandbox multi-racines, anti-SSRF, 0 requête tierce mesurée | **Moi** |
| **RAG / mémoire** | Mémoire de tâche, pas de RAG documentaire (LU) | Library Brain : réponses sourcées, refus sans preuve | **Moi** |
| **MCP** | Client (ajout de serveurs locaux ou distants, OAuth) | Client **et** serveur, plus le matériel ([micro:bit](MICROBIT-BLUETOOTH.md), EdgeSense) | **Moi** côté serveur et matériel ; égalité côté client |
| **Ouverture / auditabilité** | Apache 2.0, toute la chaîne publique (agent, fork OpenCode, fork llama.cpp) | MIT, 2 829 tests publics | **Égalité**. L'argument « je suis auditable, eux non » ne tient plus ici |
| **Évaluation** | Inspect AI + Harness-Bench, gate de release par modèle | Benchmark public local vs cloud ([jalon C](KLODY-ROADMAP.md)) | **localcode** aujourd'hui sur l'outillage d'éval |
| **Voix** | Dictée (whisper.cpp) + synthèse (Piper) | VocalBrain | Égalité |
| **Plateforme** | Apple Silicon uniquement, ≥ 16 Go | Apple Silicon (MLX) | Égalité |

### Lecture

**C'est le concurrent le plus direct à ce jour.** POP Switcher était une app grand public
généraliste et propriétaire. localcode est un **agent de code local, open source,
installable en une commande**, très actif, avec une ingénierie d'inférence sérieuse. Il
coche trois des arguments que j'opposais à POP Switcher : code ouvert, tests publics,
spécialisation code.

**Où il me menace**
- **« Agent de code local open source sur Mac » est désormais un produit gratuit.** Si
  Klody se présente seulement comme ça, la question devient « pourquoi pas localcode ? ».
- **Il a déjà livré ce que vise mon jalon D**, et la barre monte : l'installation par un
  tiers devra tenir en une commande, avec choix automatique du modèle.
- **Il est en avance sur l'optimisation de l'inférence** : cache KV compressé, drafting,
  patchs Metal, et sur l'outillage d'évaluation.

**Où je mène**
- **La gouvernance.** Il a fait un choix de produit assumé : un développeur seul, sur son
  propre dépôt, sans friction. C'est l'inverse de ce qu'exige une équipe avec des données
  sensibles. Approbation avant écriture, sandbox, anti-SSRF, journal d'audit : mon offre
  B2B se joue exactement là, et sa propre politique de sécurité le reconnaît.
- **Le RAG sourcé** (Library Brain) et **MCP côté serveur et matériel** : rien
  d'équivalent chez lui.
- **L'intégration** : déploiement, accompagnement, adaptation au SI. Un outil gratuit ne
  vend pas ça.

### Décisions

1. **Repositionner le pitch de Klody** : non plus « agent de code local », mais « **agent
   de code local gouverné** : approbations, sandbox, audit, réponses sourcées ». localcode
   devient le contraste : « parfait pour un dev seul sur son dépôt ; vos dépôts d'équipe
   exigent des garde-fous. » Sans le dénigrer : il valide la catégorie.
2. **Le prendre comme référence dans le [jalon C](KLODY-ROADMAP.md)** : comparer local vs
   local vs cloud sur les mêmes tâches. Regarder si Inspect AI / Harness-Bench peuvent
   servir de base méthodologique (même harness = chiffres comparables).
3. **Relever la barre du jalon D** : viser « une commande + choix du modèle selon la RAM ».
4. **Étudier ce qu'il fait bien**, sans le copier : *copy drafting* (recopier au lieu de
   régénérer un fichier déjà lu, ×3,5 à ×4 annoncé), détection de blocage, compaction
   pilotée par le budget de contexte mesuré.
5. **Interopérabilité plutôt que concurrence** côté MCP : mes serveurs (micro:bit,
   EdgeSense) devraient se brancher sur localcode avec `localcode mcp add`. C'est une
   démo de plus pour eux, pas un risque.

### À vérifier (protocole de test sur mon Mac)

- [ ] **Installation réelle** : temps de `uv pip install localcode` plus le premier
      lancement (build, téléchargement, warm-up) sur un Mac 16 Go puis 32 Go+.
- [ ] **Trafic sortant** : session normale avec pare-feu applicatif (LuLu / Little Snitch).
      Seuls Hugging Face, DuckDuckGo et les URL demandées doivent apparaître.
- [ ] **Injection de prompt** : un dépôt de test dont le README demande de lire une URL
      puis d'exécuter une commande. Le shell part-il sans approbation ? Ensuite, même test
      sur Klody, en publiant les deux résultats.
- [ ] **Hors ligne** : Wi-Fi coupé une fois le modèle téléchargé, est-ce que tout
      fonctionne ?
- [ ] **Vitesse** : tokens/s et temps de première réponse, même modèle et même
      quantification, llama.cpp patché vs MLX (Klody). Vérifier le ×2 annoncé du drafting.
- [ ] **Qualité** : ses 33 tâches d'éval avec le modèle recommandé, puis les mêmes avec
      Klody.
- [ ] **Build reproductible** : le binaire `localcode-ui` de la wheel correspond-il au
      `FORK_COMMIT` publié ? (Le source existe, la reproductibilité n'est pas vérifiée.)
- [ ] **Licences des modèles** : affichées dans le picker avant téléchargement ?

### Sources

- [localcode sur PyPI](https://pypi.org/project/localcode/) (métadonnées et archive source 0.5.43)
- [Dépôt mjwsolo/localcode](https://github.com/mjwsolo/localcode) (commit 39c9128 du 22/11/2026)
- [Documentation](https://mjwsolo.github.io/localcode/), dont [Network Boundary](https://mjwsolo.github.io/localcode/concepts/network-boundary/)
- [Fork OpenCode mjwsolo/opencode](https://github.com/mjwsolo/opencode) (commit 4cc1f15)
- Homonymes à ne pas confondre : [burrito.space/localcode](https://tangled.org/burrito.space/localcode/raw/main/README.md)
  (lanceur d'agents existants sur Ollama) et [localcodeai/localcode](https://localcodeai.github.io/localcode/)
  (Apple Foundation Models + OpenCode, macOS 26).
