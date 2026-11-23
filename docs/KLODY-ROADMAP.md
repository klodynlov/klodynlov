# 🗺️ Klody Code AI — feuille de route détaillée

Découpage des jalons **encore ouverts** de [Klody Code AI](https://github.com/klodynlov/klody-code-ai)
en sous-tâches **datées**, jusqu'à l'horizon **31 décembre 2026**.

Le socle est déjà en place — **699 tests**, **client & serveur MCP**, **routeur
adaptatif** (easy/medium/hard × 6 types), **CI durcie** (bandit / gitleaks /
pip-audit / CodeQL), sécurité de niveau production (sandbox multi-racines,
anti-SSRF, commits signés). Cette roadmap couvre ce qui **reste à faire** pour
passer d'un projet abouti à un projet **démontrable et prouvé**.

> Suivi vivant : ce plan alimente [`objectifs.py`](../tools/objectifs.py).
> ```bash
> python3 tools/objectifs.py docs/klody.objectifs.txt --html klody.html
> ```

**Vue d'ensemble**

| Jalon | Fenêtre | Résultat vérifiable |
|---|---|---|
| A · Best-of-N robuste (tâches « hard ») | → 15/09 | Gain mesuré de Best-of-N vs 1-passe sur un jeu « hard » |
| B · Étude de cas technique publiée | → 20/08 | Document public expliquant les décisions d'ingénierie |
| C · Benchmark public local vs local vs cloud | → 11/12 (glissé du 15/11) | Méthodo + chiffres Klody vs localcode vs cloud, sur les mêmes tâches, ouverts |
| D · Cap release « consulting-ready » | → 15/12 | Un tiers installe Klody **en une commande** (modèle choisi selon la RAM) et exécute une tâche réelle ; CI macOS qui le prouve |

---

## 🏆 Jalon A — Best-of-N robuste sur les tâches « hard » *(→ 15 septembre)*

**But.** Fiabiliser la génération multi-candidats et la **sélection** sur les
tâches difficiles — là où une passe unique échoue le plus souvent.

- [ ] **Jeu de tâches « hard » de référence** — harness reproductible, tâches versionnées. ⭐ *@05/08*
- [ ] **Génération N-candidats pilotée par le routeur** — budget de candidats selon easy/medium/hard. *@15/08*
- [ ] **Fonction de sélection du meilleur candidat** — tests + critique automatique, pas un simple vote. *@25/08*
- [ ] **Vérification adversariale** — rejeter les candidats *plausibles-mais-faux* avant sélection. ⭐ *@05/09*
- [ ] **Mesure du gain** — Best-of-N vs 1-passe sur le jeu « hard », chiffré et reproductible. *@15/09*

**Terminé quand** : sur le jeu « hard » figé, Best-of-N montre un gain de réussite
**mesuré et reproductible** face à la passe unique, sans régression sur easy/medium.

---

## 📐 Jalon B — Étude de cas technique publiée *(→ 20 août)*

**But.** Rendre lisibles les **décisions d'ingénierie** — pièce maîtresse du
positionnement « ingénieur IA locale ». *Peut avancer en parallèle du jalon A.*

- [ ] **Trame** — décisions d'ingénierie et trade-offs, fil conducteur. *@01/08*
- [ ] **Section sécurité** — sandbox multi-racines, anti-SSRF, commits signés, CI durcie. *@08/08*
- [ ] **Section orchestration** — routeur adaptatif, boucle ReAct qui va au bout, Best-of-N. *@14/08*
- [ ] **Relecture, publication et partage** — mise en ligne + relais LinkedIn. ⭐ *@20/08*

**Terminé quand** : l'étude de cas est publique, et un lecteur technique comprend
*pourquoi* chaque choix a été fait, pas seulement *ce qui* a été construit.

---

## 📊 Jalon C — Benchmark public local vs local vs cloud *(→ 11 décembre, glissé du 15/11)*

**But.** Prouver, chiffres à l'appui, qu'un agent **100 % local** tient face à un
agent cloud, **et** se situer face à l'agent local open source de référence,
[localcode](CONCURRENCE.md#localcode--mjwsololocalcode) : même machine, mêmes tâches,
même harnais.

**Décisions du 23/11** (plan conçu avec un sous-agent méthodologue, vérifié dans le code) :
- **Harnais** : un petit runner autonome au **format de tâches de localcode** (`workspace/` +
  grader caché `tests/test.sh` + contrat `.eval/`), qui pilote les trois agents. Pas
  d'adaptateur Inspect AI pour Klody à ce stade : son solver officiel refuse tout autre
  agent (`evals/localcode_evals/agent.py:438`) ; une **calibration unique** contre le
  harnais Inspect d'origine, côté localcode, prouvera que le runner rend les mêmes verdicts.
- **Jeu de 44 tâches en trois tiers, publié par tier** : 17 de localcode (8 régression,
  9 tracking ; on exclut celles qui mesurent son runtime ou ses outils propres), 15 de
  Klody (3 par catégorie medium, hard, expert, discovery, real_repo, tirées avec une graine
  publiée), **12 neutres** écrites avant tout essai (6 en français, 6 en anglais). Le chiffre
  de tête est celui du tier neutre ; l'écart entre tiers mesure le biais d'auteur.
- **Conditions** : C1 « produit tel que livré » (Klody en routage automatique, donc **4 bits**
  sur le code ; localcode par défaut, Q8 + drafting) = chiffre principal ; C2 « parité 8 bits »
  (Klody épinglé sur son worker `brain`) ; C3 (localcode en 4 bits) reportée au jalon D.
- **Métriques** : réussite k/n, pass@1, pass^5 ; temps mur ; tokens lus dans l'usage serveur
  (fin de l'estimation len/4 du banc Klody) ; débit utile ; RAM de pointe en
  `phys_footprint` ; approbations et refus ; coût cloud en $ par tâche réussie.
- **Biais contrôlés** : 5 essais par tâche, unité statistique = la tâche (IC par bootstrap) ;
  blocs par agent en ABBA, repos 120 s, GPU au repos ; même budget de temps (900 s) ;
  Klody via son **WebSocket avec approbations** (chemin de l'UI), politique d'approbation
  figée avant les essais ; état jetable, aucun MCP, réseau coupé pour les agents locaux.

- [x] **Choix de la référence** — localcode (local) + Claude Code (cloud, à confirmer). *23/11*
- [x] **Plomberie prouvée** — runner autonome : contrat `.eval/` reproduit, 32/32 oracles
      conformes (workspace intact = échec, solution = succès). *23/11*
- [x] **Premier lot** — 6 tâches × 2 essais × 3 conditions (localcode, Klody auto, Klody `brain`) :
      36/36, plomberie validée ([détails](bench/localcode/jalon-c/README.md)). *23/11*
- [ ] **Calibration Inspect** côté localcode (venv séparé, installation à valider). *@26/11*
- [ ] **Jeu complet** — export des 15 tâches Klody, 12 tâches neutres, usage serveur et
      `phys_footprint` côté Klody. *@29/11*
- [ ] **Gel du protocole** publié avant tout essai compté. *@30/11*
- [ ] **Campagne locale** C1 (44 × 5 × 2 agents) puis C2 (44 × 3, Klody). ⭐ *@05/12*
- [ ] **Cloud** — Claude Code sur les 44 tâches × 3 (CLI, permissions et budget à valider). *@07/12*
- [ ] **Analyse + publication** — données, méthodo et runner **ouverts**. *@11/12*

**Terminé quand** : quelqu'un peut **rejouer** le benchmark depuis la méthodo
publiée et retrouver l'ordre de grandeur des résultats annoncés.

**Déjà mesuré (phases 1-2, 23/11)** : vitesse de décodage localcode 147 tok/s (code, drafting)
contre Klody 102 tok/s (worker `brain` 8 bits) ; test d'injection comparé (106 essais).
Voir la [fiche localcode](CONCURRENCE.md#localcode--mjwsololocalcode).

---

## 🚀 Jalon D — Cap release « consulting-ready » *(→ 15 décembre, à recaler après le jalon C)*

**But.** Rendre Klody **installable et démontrable par un tiers** — support direct
de l'activité consulting. *Dépend des jalons A–C (produit stabilisé et prouvé).*

**La barre a monté** : [localcode](CONCURRENCE.md#localcode--mjwsololocalcode) s'installe en
`uv pip install localcode` puis `localcode`, choisit le modèle selon la RAM et va jusqu'à la
première réponse en ≈ 6 min 30 s, téléchargement compris (mesuré le 23/11). Cible du jalon :
**une commande + choix automatique du modèle selon la RAM**.

### État mesuré le 23/11 (installation de tiers, dossier vierge, M5 Max 128 Go)

Parcours du README en mode « autonome » : Klody + `mlx_lm.server`, sans gateway.

| Étape | Mesure |
|---|---|
| `git clone` du dépôt public | 1,2 s (12 Mo) |
| `pip install -r requirements.txt` **sans cache** | 31 s, 147 paquets (dont torch), venv de 1,6 Go |
| `pip install mlx-lm` | 2,2 s |
| `.env` | `cp .env.example` puis **6 lignes à modifier à la main** |
| `./scripts/start-mlx.sh` | serveur prêt en 2,3 s ; 1re réponse en 1,5 s (fichier du modèle déjà en cache disque) |
| Modèle Qwen 3.6 35B-A3B 8 bits | 36 Go, **non retéléchargé** ; ≈ 6 min estimées au débit mesuré en phase 1 |
| Première tâche réelle | **3/3 réussies** (`fix-one-bug`, `add-test`, `fix-two-bugs`), 13 à 15 s chacune |

Soit ≈ 1 min de machine plus le téléchargement du modèle. **Ce n'est pas le temps qui
bloque, c'est le parcours** :
- **10 étapes manuelles** et 5 prérequis ;
- le `.env` livré pointe sur le gateway :8090, qu'un tiers n'a pas : erreur de connexion
  immédiate ;
- **`klody-core` (gateway) et `library-brain` sont des dépôts privés**, donc le mode complet
  (routage brain/coder, budget RAM, LibraryBrain) est inaccessible à un tiers ;
  `requirements.txt` cite aussi `pip install -e ~/klody-core/memory` ;
- le modèle est **figé à 36 Go** : rien n'est prévu pour un Mac de 16 ou 32 Go ;
- `start-api.sh` force `HF_HUB_OFFLINE=1`, ce qui bloque le premier téléchargement des
  embeddings sur un Mac vierge ;
- la CI n'installe que sous Linux : **aucune installation sur Mac n'est testée** ;
- l'UI (`klody-ui`) se compile à la main (Node, Rust, Tauri), sans binaire distribué.

### Chemin proposé : « une commande + modèle selon la RAM » (non implémenté)

1. **Une commande** : `uv tool install klody` (paquet PyPI, ou `git+https://…` en attendant),
   puis `klody`. Au premier lancement, un assistant détecte la puce et la RAM, choisit le
   modèle, le télécharge (reprise + sha256), écrit `.env` lui-même, lance le serveur MLX
   supervisé et ouvre la CLI. Plus aucune édition manuelle.
2. **Choix du modèle selon la RAM**, en réutilisant
   [ram-aware-scheduler](https://github.com/klodynlov/ram-aware-scheduler) :
   - le dépôt public (217 lignes, 24 tests, sans I/O) est **en retard** sur la copie du
     gateway privé (`gateway/ram.py`, `sysmem.py`) : y remonter la lecture de la RAM
     (`vm_stat`, `hw.memsize`, `recommendedMaxWorkingSetSize` de Metal) et une fonction `fit()` ;
   - fonder `fit()` sur un **catalogue d'empreintes mesurées** (`phys_footprint` par modèle et
     par contexte), pas sur des formules : localcode a constaté des écarts jusqu'à ×2,3 ;
   - paliers à mesurer (FAISABLE, non mesuré) : 128 Go → 35B-A3B 8 bits (+ `coder` 4 bits) ;
     64 Go → 35B-A3B 4 bits ; 32 Go et 16 Go → modèle dense plus petit en 4 bits ;
   - le scheduler gouverne ensuite le budget (éviction LRU, plancher de sécurité) **sans
     dépendre du gateway privé**.
3. **Dépendances** : séparer l'exécution du développement (`[dev]` : ruff, mypy, bandit,
   pytest…), rendre `klody-memory` optionnel (dégradation déjà propre), lever
   `HF_HUB_OFFLINE` jusqu'au premier téléchargement.
4. **Preuve** : un job CI **macOS arm64 « installation de zéro »** avec un petit modèle, qui
   rejoue `fix-one-bug` du runner du jalon C. Le critère du jalon devient mesurable.
5. **UI** : binaire `klody-ui` signé et notarisé en téléchargement (plus tard ; l'expérience
   Apple Developer existe déjà sur d'autres apps).

- [ ] **Commande unique + assistant de premier lancement** (`klody`, `.env` généré). *@05/12*
- [ ] **ram-aware-scheduler v0.2** : lecture RAM + `fit()` sur empreintes mesurées, adopté
      par Klody et par le gateway (fin de la copie divergente). *@08/12*
- [ ] **Catalogue de modèles par palier de RAM** (16 / 32 / 64 / 128 Go), empreintes mesurées. *@08/12*
- [ ] **CI macOS « installation de zéro »** qui exécute une vraie tâche. ⭐ *@10/12*
- [ ] **Guide de démarrage 100 % local** — du `uv tool install` à la première tâche. *@12/12*
- [ ] **Revue de sécurité de release** — durcissement final, dont le confinement d'exécution
      révélé par le [test d'injection](bench/localcode/injection/README.md). ⭐ *@15/12*

**Terminé quand** : une personne extérieure installe Klody en local **en une commande** et
exécute une tâche réelle, sans aide, sur un Mac de 16 Go ou plus ; et la CI macOS le prouve.

---

*Les dates sont des cibles de travail, pas des engagements ; elles vivent dans
[`klody.objectifs.txt`](klody.objectifs.txt) et se mettent à jour au fil de
l'avancement. Le code de Klody Code AI vit dans son
[dépôt dédié](https://github.com/klodynlov/klody-code-ai).*
