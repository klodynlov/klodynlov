# 🗺️ Dream × World — feuille de route détaillée

Découpage des jalons **encore ouverts** de [Dream × World](https://github.com/klodynlov/dream-x-world)
en sous-tâches **datées**, jusqu'à l'horizon **31 mars 2027**.

Le cœur est déjà là — le **Canon Engine** (retrieve → generate → vérif
anti-contradiction → Best-of-N) qui garde un monde non-contradictoire dans la
durée. Cette roadmap couvre ce qui **reste** pour passer d'un moteur de cohérence
à un **monde vivant, jouable et prouvé sur la durée**.

> Suivi vivant : ce plan alimente [`objectifs.py`](../tools/objectifs.py).
> ```bash
> python3 tools/objectifs.py docs/dreamxworld.objectifs.txt --html dxw.html
> ```

**Vue d'ensemble**

| Jalon | Fenêtre | Résultat vérifiable |
|---|---|---|
| A · Simulation temporelle multi-agents | → 15/10 | N agents × M tours sans divergence |
| B · Monde exposé en serveur MCP jouable | → 15/12 | Un agent extérieur joue via MCP |
| C · Démo 100+ tours cohérente | → 15/02 | Run long rejouable, 0 contradiction canon |
| D · Sortie publique & showcase | → 20/03 | Un tiers installe et fait tourner un monde |

---

## ⏳ Jalon A — Simulation temporelle multi-agents stable *(→ 15 octobre)*

**But.** Faire vivre le monde dans le temps : plusieurs agents agissent et le
monde avance **sans diverger**, la cohérence étant vérifiée à chaque tour.

- [ ] **Modèle de temps** — tours, horloge du monde, événements datés. *@20/08*
- [ ] **Boucle multi-agents** — chaque agent agit, le monde avance d'un tour. ⭐ *@05/09*
- [ ] **Canon Engine à chaque tour** — vérification anti-contradiction en continu, pas seulement à la génération. ⭐ *@20/09*
- [ ] **Persistance de l'état** — monde sauvegardé entre tours (SQLite local). *@01/10*
- [ ] **Test de stabilité** — N agents × M tours sans divergence ni contradiction. *@15/10*

**Terminé quand** : une simulation de plusieurs agents sur plusieurs dizaines de
tours se termine **sans contradiction canon** et avec un état reproductible.

---

## 🔌 Jalon B — Monde exposé en serveur MCP jouable *(→ 15 décembre)*

**But.** Ouvrir le monde à des agents extérieurs via **MCP** : observer, agir,
avancer le temps. *Dépend du jalon A (boucle temporelle stable).*

- [ ] **Schéma des outils MCP** — observer le monde, agir, avancer le temps. *@30/10*
- [ ] **Lecture de l'état** — serveur MCP exposant lieux, personnages, faits. *@15/11*
- [ ] **Actions d'un agent joueur** — écriture via MCP + validation Canon avant application. ⭐ *@30/11*
- [ ] **Session jouable de bout en bout** — un client MCP joue un tour complet. *@15/12*

**Terminé quand** : un agent tiers, via un client MCP, observe le monde, agit, et
ses actions ne sont appliquées que si elles **passent la validation Canon**.

---

## 🎬 Jalon C — Démo publique d'un monde qui tient sur 100+ tours *(→ 15 février)*

**But.** La preuve du projet : un monde qui reste **cohérent sur la durée**,
rejouable et vérifiable. *Dépend des jalons A & B.*

- [ ] **Scénario de démo** — monde initial, agents, objectifs narratifs. *@30/12*
- [ ] **Run long** — 100+ tours, journal des faits + détection de contradictions. ⭐ *@20/01*
- [ ] **Vérification de cohérence** — 0 contradiction canon sur tout le run long. ⭐ *@01/02*
- [ ] **Mise en forme** — démo rejouable et visualisable. *@15/02*

**Terminé quand** : un monde tourne **100+ tours** et un contrôle automatique
confirme l'absence de contradiction sur l'ensemble du journal.

---

## 🚀 Jalon D — Sortie publique & showcase *(→ 20 mars)*

**But.** Rendre le projet **installable et racontable** par un tiers.

- [ ] **Guide de démarrage 100 % local** — installation + monde d'exemple. *@01/03*
- [ ] **Présentation** — article / vidéo (Canon Engine, run 100+ tours). *@10/03*
- [ ] **Revue finale + publication** — durcissement et diffusion. ⭐ *@20/03*

**Terminé quand** : une personne extérieure installe Dream × World en local et
fait tourner un monde d'exemple en suivant le guide, sans aide.

---

*Les dates sont des cibles de travail, pas des engagements ; elles vivent dans
[`dreamxworld.objectifs.txt`](dreamxworld.objectifs.txt) et se mettent à jour au
fil de l'avancement. Le code de Dream × World vit dans son
[dépôt dédié](https://github.com/klodynlov/dream-x-world).*
