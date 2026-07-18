# Pour les entreprises — IA qui ne quitte pas vos murs

> **Vos données ne peuvent pas aller dans le cloud ? C'est exactement mon
> terrain.** Je conçois et durcis des agents IA qui tournent **100 % en local /
> on-premise** — aucune donnée ne part vers un tiers.

---

## Le problème que je résous

La plupart des organisations qui hésitent devant l'IA ne manquent pas de cas
d'usage. Elles ont une **contrainte** : leurs données ne peuvent pas sortir.

> « On adorerait utiliser l'IA. Mais nos données ne peuvent pas quitter la
> maison. »

Santé, juridique, industrie, secteur public, finance… cette phrase se termine
trop souvent par un renoncement. Elle ne devrait pas. L'IA locale a suffisamment
mûri pour tenir des cas d'usage réels — à condition d'être **bien orchestrée et
bien sécurisée**.

---

## Pour qui

- Vous manipulez des **données sensibles ou réglementées** (RGPD, secret
  professionnel, propriété industrielle, données de santé).
- Le cloud est **exclu** — par la loi, par contrat, ou par principe.
- Vous voulez un agent IA **utile en production**, pas une démo.

---

## Ce que je fais

- **Cadrage** — transformer un besoin flou en cas d'usage IA « données
  sensibles » réaliste, avec ses critères de réussite.
- **Prototype local** — un agent qui tourne sur **votre** matériel (MLX / Ollama,
  modèles sur l'appareil), sans dépendance cloud.
- **Orchestration sérieuse** — routage adaptatif selon la difficulté, boucle
  ReAct qui va au bout, Best-of-N avec **vérification** (pas juste « garder la
  plus jolie réponse »).
- **Sécurité de niveau production** — sandbox multi-racines, anti-SSRF, commits
  signés, CI durcie (bandit / gitleaks / pip-audit / CodeQL).
- **Interopérabilité via MCP** — connecter l'agent à vos outils (client *et*
  serveur MCP) **sans exposer vos données** à un tiers.
- **Transfert** — documentation, tests, et une équipe capable de reprendre.

---

## Pourquoi moi

Je ne fais pas que le défendre en théorie — je le construis.

**[Klody Code AI](https://github.com/klodynlov/klody-code-ai)** : un agent de
code **100 % local** qui vise à rivaliser avec un agent cloud sur une machine
perso.

- 🔒 100 % privé (MLX / Apple Silicon) · sandbox multi-racines · anti-SSRF ·
  commits signés
- 🧭 Routeur adaptatif (easy/medium/hard × 6 types) · boucle ReAct · Best-of-N
- 🔌 Client **et** serveur MCP (connecteurs Gmail & web)
- ✅ **699 tests** · CI durcie · [étude de cas
  technique](https://github.com/klodynlov/klody-code-ai/blob/main/docs/CASE-STUDY.md)

J'explore aussi l'IA locale au service des gens — **SilverBrain** (assistant
vocal accessible) et **Dream × World** (mondes IA persistants et cohérents).

---

## Comment on travaille ensemble

1. **Appel de cadrage** (gratuit) — votre contrainte, votre cas d'usage, une
   première idée de faisabilité.
2. **Étude de faisabilité** — un périmètre chiffré, des critères de réussite
   clairs, sur votre matériel cible.
3. **Prototype** — un agent local qui traite votre cas réel, mesuré.
4. **Durcissement & transfert** — sécurité, tests, documentation, montée en
   autonomie de vos équipes.

---

## Parlons-en

Vous avez un cas d'usage IA dont les données **ne peuvent pas aller dans le
cloud** ?

📧 **volnyclaude@protonmail.com** · 💼 [LinkedIn](https://www.linkedin.com/in/claude-volny-94129894/)

> *L'IA sans le cloud. La confidentialité par défaut, pas en option.*
