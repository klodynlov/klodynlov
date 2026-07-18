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
| C · Benchmark public vs agent cloud | → 15/11 | Méthodo + chiffres local (MLX) vs cloud, ouverts |
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

## 📊 Jalon C — Benchmark public face à un agent cloud *(→ 15 novembre)*

**But.** Prouver, chiffres à l'appui, qu'un agent **100 % local** tient face à un
agent cloud. *Dépend du jalon A (Best-of-N stabilisé) pour être crédible.*

- [ ] **Choix de la référence** — agent cloud comparé + jeu de tâches comparables. *@25/09*
- [ ] **Protocole reproductible** — mêmes tâches, mêmes critères, matériel décrit, seeds fixés. *@05/10*
- [ ] **Exécution des runs** — local (MLX) vs cloud, collecte des métriques (réussite, latence, coût). ⭐ *@20/10*
- [ ] **Analyse** — coût / confidentialité / qualité, honnête sur les limites. *@05/11*
- [ ] **Publication** — données et méthodologie **ouvertes**, reproductibles par un tiers. *@15/11*

**Terminé quand** : quelqu'un peut **rejouer** le benchmark depuis la méthodo
publiée et retrouver l'ordre de grandeur des résultats annoncés.

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
