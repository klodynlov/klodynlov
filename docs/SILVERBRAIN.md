# SilverBrain — assistant IA intuitif pour un public réfractaire aux nouvelles technologies

> **IA 100 % locale, conçue pour être évidente à utiliser.** On lui parle
> naturellement, comme à une personne. Il apprend à connaître son utilisateur au fil de
> la conversation, l'oriente vers les sujets qui le concernent, l'accompagne au quotidien
> — et adapte toujours sa façon de parler à quelqu'un que la technologie intimide.

SilverBrain fait partie de la famille *Brain* (aux côtés de **LibraryBrain** et
**VocalBrain**) et réutilise l'infrastructure locale de **Klody Code AI** : modèles sur
l'appareil (MLX / Ollama), orchestration adaptative et exposition **MCP**. Aucune donnée
personnelle ne quitte la machine.

---

## 🎯 Pour qui, et pourquoi

Cible : les personnes que la technologie **rebute ou intimide** — souvent des seniors,
mais pas seulement. Pour elles, l'obstacle n'est pas le besoin (rappels, lecture, lien
avec les proches) mais **l'interface** : menus, comptes, jargon, peur de « mal faire ».

SilverBrain lève cet obstacle avec un principe unique : **il n'y a rien à apprendre.**
On parle, il comprend, il s'adapte.

---

## 🧭 Comment ça marche

### 1. Intuitif — le langage naturel, rien d'autre
Aucune commande à mémoriser, aucun mot-clé magique. L'utilisateur formule sa demande
comme il la dirait à un proche (« je ne sais plus si j'ai pris mon comprimé ce matin »).
SilverBrain comprend l'intention, reformule si besoin, et **confirme calmement avant
d'agir**.

### 2. Profilage conversationnel (en langage naturel)
Dès les premiers échanges — puis en continu, sans questionnaire — l'assistant apprend à
connaître la personne : ses centres d'intérêt, son rythme, ce qui compte pour elle. Ce
profil, **stocké localement**, sert à **l'orienter vers des thématiques précises** issues
de **LibraryBrain** (lectures, sujets, souvenirs) qui lui correspondent vraiment, plutôt
que de la noyer sous des options génériques.

> Exemple : au fil des conversations, SilverBrain repère un goût pour le jardinage et
> l'histoire locale → il propose des lectures et des rappels autour de ces sujets, via
> LibraryBrain.

### 3. Accompagnement au quotidien
- 💊 **Rappels** — médicaments, rendez-vous, petites routines ; annoncés à voix haute,
  proposés au bon moment à partir du profil.
- 📖 **Aide à la lecture & à la mémoire** — lecture à voix haute de courriers et
  documents, résumés simples, aide-mémoire personnel et familial (moteur **LibraryBrain**).
- 📞 **Lien avec les proches** — « appelle ma fille », « envoie un message à Paul » via
  des connecteurs choisis par la famille.
- ➕ **… et plus** — le socle (profil + LibraryBrain + MCP) est extensible : nouvelles
  thématiques, nouveaux connecteurs, nouveaux rituels, sans complexifier l'usage.

### 4. Formulation adaptative — le cœur du projet
SilverBrain **tient compte des contraintes d'un public réfractaire à la technologie** et
adapte sa façon de s'exprimer :
- **Vocabulaire simple**, phrases courtes, zéro jargon technique.
- **Rythme réglable** : parle plus lentement, répète sans impatience, redit autrement si
  la personne n'a pas compris.
- **Rassure et déculpabilise** : jamais de « erreur », toujours une reformulation ; il
  n'y a pas de mauvaise manière de lui parler.
- **Une seule chose à la fois** : pas de listes d'options, une proposition claire et une
  confirmation.
- **Ton ajusté au profil** : le registre s'aligne sur la personne détectée lors du
  profilage.

---

## 🏗️ Architecture (réutilise l'existant)

```
Voix ──► VocalBrain (STT/TTS local) ──► Klody (routeur adaptatif + boucle ReAct)
                                              │
        ┌─────────────────┬───────────────────┼───────────────────┐
        ▼                 ▼                    ▼                   ▼
   Profil user      LibraryBrain         Connecteurs MCP     Rappels / agenda
 (local, SQLite)  (thématiques,        (appels, messages)    (local, SQLite)
                  lecture, résumés)
        │
        └──► oriente le choix des thématiques et le ton de la formulation
```

- **Entrée / sortie** : STT + TTS locaux (VocalBrain) — la voix ne quitte jamais
  l'appareil.
- **Cerveau** : le routeur adaptatif de Klody classe la demande (easy/medium/hard) ; le
  **profil** conditionne le choix des thématiques LibraryBrain **et** le style de
  formulation.
- **Mémoire du profil** : préférences et centres d'intérêt en **SQLite local**, chiffrés
  au repos ; construits en langage naturel, jamais via un formulaire.
- **Actions** : exposées via **MCP** — la famille active uniquement les connecteurs
  souhaités, chacun avec confirmation.

---

## ♿ Accessibilité & confiance

- **Zéro configuration visible** — pas de comptes, pas de mots de passe, pas de mise à
  jour à gérer.
- **Confirmation systématique** avant tout appel, message ou action irréversible.
- **Interface secondaire « gros boutons »** (Tauri 2 + React, fort contraste) pour un
  proche aidant, sans jamais imposer l'écran à l'utilisateur.
- **Paramétrage possible par un proche de confiance** (avec accord de l'utilisateur),
  localement, sans exposer les données à un tiers ni au cloud.
- **Fonctionne hors-ligne** — aucune donnée ne transite.

---

## 🗺️ Statut

Concept / exploration au sein du portfolio IA locale. Les briques réutilisées
(VocalBrain, LibraryBrain, Klody, MCP) sont décrites dans le
[README principal](../README.md).
