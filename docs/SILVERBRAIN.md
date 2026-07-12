# SilverBrain — assistant vocal du quotidien pour seniors

> **IA 100 % locale, pensée pour un public senior.** Un compagnon vocal qui aide au
> quotidien — rappels, contact avec les proches, lecture de courriers — sans qu'aucune
> donnée personnelle (santé, famille, habitudes) ne quitte la maison.

SilverBrain fait partie de la famille *Brain* (aux côtés de **LibraryBrain** et
**VocalBrain**) et réutilise l'infrastructure locale de **Klody Code AI** : modèles
sur l'appareil (MLX / Ollama), orchestration adaptative et exposition **MCP**.

---

## 🎯 Pourquoi ce public

Les assistants vocaux grand public envoient la voix et les données dans le cloud. Pour
une personne âgée, ces données sont particulièrement sensibles : rappels de médicaments,
rendez-vous médicaux, habitudes de vie, cercle familial. SilverBrain répond à un besoin
précis : **le même confort qu'un assistant vocal, mais avec la vie privée d'un carnet
papier.**

Trois principes de conception, orientés accessibilité :

- **Voix d'abord** — tout se fait à l'oral, aucune obligation de lire un écran ou de
  naviguer dans des menus.
- **Zéro configuration visible** — pas de comptes, pas de mots de passe, pas de mises à
  jour à gérer par l'utilisateur.
- **Tolérant** — comprend une formulation approximative, répète calmement, confirme avant
  toute action importante.

---

## 🧩 Fonctions

- 💊 **Rappels & routines** — médicaments, rendez-vous, arrosage des plantes ; annoncés à
  voix haute, avec confirmation.
- 📞 **Rester en lien** — « Appelle ma fille » / « Envoie un message à Paul » via des
  connecteurs choisis par la famille.
- 📬 **Lecture & compréhension** — lit un courrier ou un document à voix haute et en
  résume l'essentiel (s'appuie sur **LibraryBrain**).
- ❓ **Réponses simples** — météo, date, « à quelle heure passe l'aide à domicile ? ».
- 🆘 **Sécurité** — phrase de détresse configurable qui prévient un proche.

---

## 🏗️ Architecture (réutilise l'existant)

```
Voix ──► VocalBrain (STT/TTS local) ──► Klody (routeur + boucle ReAct)
                                              │
                        ┌─────────────────────┼─────────────────────┐
                        ▼                      ▼                     ▼
                  LibraryBrain          Connecteurs MCP        Rappels/agenda
              (lecture, résumés)     (téléphone, messages)      (local, SQLite)
```

- **Entrée / sortie** : STT + TTS locaux (VocalBrain) — la voix ne quitte jamais
  l'appareil.
- **Cerveau** : le routeur adaptatif de Klody classe la demande (easy/medium/hard) et
  privilégie les intentions simples et fréquentes pour une latence faible.
- **Actions** : exposées via **MCP** — la famille active uniquement les connecteurs
  souhaités (appels, messages, agenda), chacun avec confirmation.
- **Données** : rappels, contacts et journal stockés en **SQLite** local, chiffrés au
  repos.

---

## ♿ Accessibilité & confiance

- **Interface secondaire « gros boutons »** (Tauri 2 + React, thème très contrasté) pour
  l'aidant ou l'utilisateur qui préfère l'écran — texte agrandi, une action par vue.
- **Confirmation systématique** avant tout appel, message ou action irréversible.
- **Journal consultable par un proche de confiance** (avec accord de l'utilisateur), sans
  jamais exposer les données à un tiers ni au cloud.
- **Fonctionne hors-ligne** — utile en zone mal couverte, et garantit qu'aucune donnée ne
  transite.

---

## 🗺️ Statut

Concept / exploration au sein du portfolio IA locale. Les briques réutilisées
(VocalBrain, LibraryBrain, Klody, MCP) sont décrites dans le
[README principal](../README.md).
