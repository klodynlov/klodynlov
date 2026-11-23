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
| D · Cap release « consulting-ready » | → 15/12 | Un tiers installe et démontre Klody en local |

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

## 🚀 Jalon D — Cap release « consulting-ready » *(→ 15 décembre)*

**But.** Rendre Klody **installable et démontrable par un tiers** — support direct
de l'activité consulting. *Dépend des jalons A–C (produit stabilisé et prouvé).*

- [ ] **Packaging installable** — release versionnée, artefacts reproductibles. *@28/11*
- [ ] **Guide de démarrage 100 % local** — MLX / Ollama, du clone à la première tâche. *@08/12*
- [ ] **Revue de sécurité de release** — durcissement final avant diffusion. ⭐ *@15/12*

**Terminé quand** : une personne extérieure installe Klody en local en suivant le
guide et exécute une tâche réelle, sans aide.

---

*Les dates sont des cibles de travail, pas des engagements ; elles vivent dans
[`klody.objectifs.txt`](klody.objectifs.txt) et se mettent à jour au fil de
l'avancement. Le code de Klody Code AI vit dans son
[dépôt dédié](https://github.com/klodynlov/klody-code-ai).*
