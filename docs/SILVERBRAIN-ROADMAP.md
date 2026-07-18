# 🗺️ SilverBrain — feuille de route détaillée

Découpage des jalons de [SilverBrain](SILVERBRAIN.md) en sous-tâches **datées**,
jusqu'à l'horizon **31 octobre 2026** (premier test utilisateur réel). Chaque
jalon réutilise une brique existante du portfolio (VocalBrain, LibraryBrain,
Klody, MCP) — l'enjeu est l'**assemblage accessible**, pas de repartir de zéro.

> Suivi vivant : ce plan alimente [`objectifs.py`](../tools/objectifs.py).
> ```bash
> python3 tools/objectifs.py docs/silverbrain.objectifs.txt --html silverbrain.html
> ```

**Vue d'ensemble**

| Jalon | Pilier(s) | Fenêtre | Résultat vérifiable |
|---|---|---|---|
| 1 · Socle vocal + intentions | 1 & 3 | → 08/08 | On parle, il comprend l'intention et agit |
| 2 · Profil local + LibraryBrain | 2 | → 05/09 | Un intérêt confirmé oriente une lecture pertinente |
| 3 · Contrat de style + calibrage | 4 | → 26/09 | La même info, deux formulations ; « hein ? » simplifie |
| 4 · MCP proches + interface aidant | 3 | → 17/10 | Un proche paramètre un appel, le senior ne règle rien |
| 5 · Test 3 seniors + durcissement | tous | → 31/10 | 3 sessions réelles, retours intégrés |

---

## 🎙️ Jalon 1 — Socle vocal + intentions *(→ 8 août)*

**But.** La boucle voix locale de bout en bout : parole → compréhension par
intention → action, entièrement sur l'appareil.

- [ ] **Boucle STT → Klody → TTS locale minimale** — VocalBrain relié à Klody, aucune donnée hors appareil. ⭐ *@25/07*
- [ ] **Classifieur d'intentions** — `rappel`, `lecture`, `appeler_un_proche`, `question_simple`, `détresse`. *@30/07*
- [ ] **Réparation douce** — confiance basse → question fermée, jamais de blocage « commande non reconnue ». *@04/08*
- [ ] **Confirmation avant action engageante** — une seule confirmation orale claire à la fois. *@06/08*
- [ ] **Mémoire de conversation** — résolution des références implicites (« et la deuxième page ? »). *@08/08*

**Terminé quand** : trois formulations différentes d'une même demande aboutissent
à la même intention, et toute action engageante passe par une confirmation.

---

## 🧭 Jalon 2 — Profil local + orientation LibraryBrain *(→ 5 septembre)*

**But.** Un profil qui **émerge de la conversation** (jamais de questionnaire) et
oriente les thématiques proposées. *Dépend du jalon 1 (flux d'intentions).*

- [ ] **Schéma SQLite chiffré des traits** — trait = valeur + confiance + fraîcheur + source. *@13/08*
- [ ] **Pipeline d'extraction de traits candidats** — depuis la conversation, en statut `propose`. ⭐ *@20/08*
- [ ] **Consentement à voix haute** — passage `propose` → `confirme` avant tout usage. *@25/08*
- [ ] **Requêtes traits → LibraryBrain** — recherche hybride sqlite-vec + FTS5 sur les intérêts confirmés. *@30/08*
- [ ] **Cold start + correction orale** — thématiques larges au démarrage, oubli d'un trait en un mot. *@05/09*

**Terminé quand** : un intérêt mentionné en conversation, une fois confirmé,
déclenche une lecture LibraryBrain réellement pertinente — et se corrige à l'oral.

---

## 🗣️ Jalon 3 — Contrat de style + boucle de calibrage *(→ 26 septembre)*

**But.** Le pilier différenciant : adapter *comment* l'assistant parle, et le
**recalibrer automatiquement** sur les signaux d'incompréhension. *Dépend du profil (jalon 2) pour le registre.*

- [ ] **Définir les 4 niveaux du contrat de style** — simplicité, débit, registre, longueur max. *@10/09*
- [ ] **Injecter le contrat comme contraintes système** — même moteur Klody, sous enveloppe de style par personne. *@15/09*
- [ ] **Passe de simplification / lisibilité** — Best-of-N pour les messages importants (jargon, une-idée-à-la-fois). ⭐ *@20/09*
- [ ] **Boucle de calibrage implicite** — « hein ? » / silences → simplifie et ralentit ; fluidité → inversement. *@26/09*

**Terminé quand** : une même information produit deux formulations distinctes
selon le profil, et un « répète ? » simplifie automatiquement l'énoncé suivant.

---

## 📞 Jalon 4 — Connecteurs MCP proches + interface aidant *(→ 17 octobre)*

**But.** Garder le lien avec les proches ; un aidant **paramètre**, le senior ne
règle rien. *Réutilise l'exposition MCP de Klody.*

- [ ] **Connecteur MCP appel + message** — activé et paramétré par la famille. ⭐ *@03/10*
- [ ] **Carnet de contacts nommé en clair** — « ma fille », « le docteur », résolu depuis le profil. *@08/10*
- [ ] **Interface aidant « gros boutons »** — Tauri 2 + React, fort contraste, résumé bienveillant (jamais les sujets sensibles sans accord). *@15/10*
- [ ] **Escalade douce** — rappel important non confirmé → represente calmement, puis prévient un proche si configuré. *@17/10*

**Terminé quand** : un proche active un connecteur d'appel depuis l'interface
aidant, et le senior déclenche l'appel à la voix, avec confirmation, sans réglage.

---

## 🧪 Jalon 5 — Test avec 3 seniors réels + durcissement *(→ 31 octobre)*

**But.** Confronter le prototype à de vrais utilisateurs et ajuster sur leurs
retours — la seule mesure qui compte pour ce public. *Dépend des jalons 1–4.*

- [ ] **Protocole de test** — tâches, consentement éclairé, mesures d'accessibilité (compréhension, ré-essais, abandon). *@20/10*
- [ ] **Sessions avec 3 utilisateurs seniors réels** — observation, pas de tutoriel préalable. ⭐ *@27/10*
- [ ] **Synthèse → ajustements** — retours intégrés aux intentions et au contrat de style. *@31/10*

**Terminé quand** : trois personnes n'ayant jamais utilisé l'outil accomplissent
une tâche réelle (rappel, lecture, appel) sans instruction préalable, et les
frictions observées sont consignées et priorisées.

---

## 🔭 Au-delà d'octobre (hors horizon actuel)

Pistes du socle extensible (pilier 3, « … et plus »), à activer une par une :
journal de bien-être vocal, assistant administratif (comprendre un courrier
officiel), rituels du soir, photos parlantes. Chacune réutilise le trio
**profil + LibraryBrain + MCP** sans complexifier l'usage.

---

*Les dates sont des cibles de travail, pas des engagements ; elles vivent dans
[`silverbrain.objectifs.txt`](silverbrain.objectifs.txt) et se mettent à jour au
fil de l'avancement.*
