# 🧭 Veille concurrence — IA locale sur Mac

Fiches des offres qui occupent le même terrain que mes projets (IA 100 % locale,
Apple Silicon, agents). But : **savoir où je mène, où je suis en retard, et quoi
en faire** — pas dénigrer.

> **Règle de la fiche** : chaque affirmation sur un concurrent porte son niveau de
> preuve, comme dans mes audits techniques.
> - **VÉRIFIÉ** — testé ou mesuré par moi.
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
