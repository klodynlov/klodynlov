<div align="center">

# Claude Volny  ·  `klodynlov`

### Je construis des **agents IA privés / local-first** — orchestration, sécurité, et code qui tient en production.

*Ingénieur logiciel · IA locale (MLX/Ollama) · MCP · Python · Rust/Tauri · React*

</div>

---

## 🧠 Projet phare — [Klody Code AI](https://github.com/klodynlov/klody-code-ai)

Un agent de code **100 % local** (aucune donnée ne quitte la machine) qui rivalise avec un
agent cloud sur une machine perso. Orchestration adaptative, client **et** serveur MCP,
sécurité de niveau production.

![Tests](https://img.shields.io/badge/tests-699%20passing-success)
![AI](https://img.shields.io/badge/IA-100%25%20local-orange)
![MCP](https://img.shields.io/badge/MCP-client%20%2B%20serveur-blueviolet)
![License](https://img.shields.io/badge/license-MIT-blue)

- 🔒 100 % privé (MLX / Apple Silicon) · sandbox multi-racines · anti-SSRF · commits signés
- 🧭 Routeur adaptatif (easy/medium/hard × 6 types), boucle ReAct qui va au bout, Best-of-N
- 🔌 Extensible via MCP — connecteurs Gmail & web, et Klody s'expose aux autres agents
- 📐 [**Étude de cas technique**](https://github.com/klodynlov/klody-code-ai/blob/main/docs/CASE-STUDY.md) — les décisions d'ingénierie

> Frontend desktop associé : [**klody-ui**](https://github.com/klodynlov/klody-ui) — Tauri 2 + React 19 + Tailwind 4 (thème clair/sombre/auto).

---

## 🛠️ Stack

**Langages** — Python · TypeScript · Rust
**IA / Agents** — MLX-LM · Ollama · ReAct · routage adaptatif · retrieval (tree-sitter + embeddings) · **MCP** (client & serveur)
**Backend** — FastAPI · WebSocket · SQLite (FTS5 + sqlite-vec)
**Front / Desktop** — React 19 · Tailwind 4 · Tauri 2
**Qualité** — pytest · CI durcie (bandit / gitleaks / pip-audit / CodeQL) · commits signés

---

## 🌱 Projet en lumière — [SilverBrain](docs/SILVERBRAIN.md)

Un assistant IA **intuitif, pensé pour les personnes que la technologie intimide** —
seniors et au-delà. On lui parle naturellement : il n'y a *rien à apprendre*.

![IA](https://img.shields.io/badge/IA-100%25%20local-orange)
![Accessibilité](https://img.shields.io/badge/accessibilit%C3%A9-langage%20adaptatif-6f42c1)
![MCP](https://img.shields.io/badge/MCP-connecteurs%20proches-blueviolet)
![Voix](https://img.shields.io/badge/interface-voix%20d'abord-0aa)

Quatre piliers :

1. 🧠 **Intuitif** — langage naturel uniquement, compréhension par intention, aucune commande à mémoriser.
2. 🧭 **Profilage conversationnel** — apprend à connaître la personne (sans questionnaire) pour l'orienter vers des thématiques **LibraryBrain** qui la concernent vraiment.
3. 📅 **Accompagnement** — rappels proactifs, aide à la lecture/mémoire, lien avec les proches (**MCP**), socle extensible.
4. 🗣️ **Formulation adaptative** — ajuste *comment* il parle (vocabulaire, rythme, ton) aux contraintes d'un public réfractaire à la technologie.

📖 [Concept & scénario](docs/SILVERBRAIN.md) · 🧬 [Modèle du profil](docs/SILVERBRAIN-PROFIL.md) · 🗣️ [Contrat de style](docs/SILVERBRAIN-STYLE.md) · 🔌 [Connecteurs MCP](docs/SILVERBRAIN-MCP.md) · 🎨 [Maquettes](docs/ui/landing.html)

> Réutilise VocalBrain (voix), LibraryBrain (thématiques/lecture) et Klody (orchestration + MCP) — 100 % local, aucune donnée dans le cloud.

---

## 🚀 Autres projets

- **LibraryBrain** — RAG local de livres (sqlite-vec + FTS5) qui alimente Klody.
- **VocalBrain** — outil autour de la voix / l'audio.
- **[Dream × World](https://github.com/klodynlov/dream-x-world)** — générateur de **mondes IA persistants & cohérents**, 100 % local. Un *Canon Engine* (retrieve → generate → vérif anti-contradiction → Best-of-N) garde le monde non-contradictoire dans la durée ; simulation temporelle multi-agents et monde exposé en **MCP** pour que les agents y jouent.

### 🔌 AIoT — l'IA locale rencontre les objets

Prolongement edge de la démarche local-first : l'inférence tourne **sur** l'objet, les données des capteurs ne quittent jamais le réseau. → [**Note de conception & état de l'art AIoT 2025-2026**](docs/aiot-edge-projects.md) (synthèse sourcée + feuilles de route).

- **[EdgeSense](edgesense/)** *(M0 codé ✓)* — passerelle **MCP** exposant capteurs & actionneurs (Raspberry Pi / ESP32) comme des *outils* que les agents locaux lisent et actionnent. Prolonge directement le positionnement *client & serveur MCP*. Le jalon M0 prouve la boucle *percevoir → agir* avec capteur/actionneur simulés (serveur MCP + garde-fous + journal tamper-evident, 9 tests).
- **TinyGuard** *(conception)* — surveillance vidéo/audio **100 % edge** : détection sur modèle quantifié (INT8), rien dans le cloud, alertes locales exposables en MCP.

- *(et d'autres explorations IA locale, audio, MCP…)*

## ✍️ Mon carnet — [Le Carnet](https://klodynlov.github.io/klodynlov/blog/)

J'écris, à but informatif, sur ce qui me touche et m'intéresse : IA locale, agents, MCP, ingénierie du quotidien. Un *pseudo LinkedIn, mais pour moi* — des textes qui restent, à une adresse stable.

- 🔒 [Pourquoi je fais tourner mes agents IA à 100 % en local](https://klodynlov.github.io/klodynlov/blog/posts/2026-07-13-agents-ia-100-local.html)
- 🔌 [MCP, expliqué simplement : donner des mains à un modèle de langage](https://klodynlov.github.io/klodynlov/blog/posts/2026-07-06-mcp-donner-des-mains.html)
- 🧭 [Faire en sorte qu'un agent de code aille vraiment au bout](https://klodynlov.github.io/klodynlov/blog/posts/2026-06-28-agent-aller-au-bout.html)

> Blog **100 % statique** (aucun build), en ligne sur **[klodynlov.github.io/klodynlov/blog](https://klodynlov.github.io/klodynlov/blog/)** — [comment ça marche](docs/blog/README.md)

---

## 📬 Me contacter

💼 [LinkedIn](https://www.linkedin.com/in/claude-volny-94129894/) · 📧 **volnyclaude@protonmail.com**

> Vous avez un cas d'usage IA dont les données **ne peuvent pas aller dans le cloud** ? C'est mon terrain — voir [Pour les entreprises](https://github.com/klodynlov/klody-code-ai/blob/main/docs/CONSULTING.md).
