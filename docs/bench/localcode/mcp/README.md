# Interopérabilité MCP : micro:bit et EdgeSense sur localcode (phase 5, 23/11/2026)

But (décision 5 de la [fiche localcode](../../../CONCURRENCE.md#localcode--mjwsololocalcode)) :
brancher mes serveurs MCP sur localcode avec `localcode mcp add`, d'abord en simulé.

## Nos serveurs sont conformes (VÉRIFIÉ, client MCP standard en stdio)

| Serveur | Commande | Résultat |
|---|---|---|
| micro:bit (`microbit/`, main) | `python3 -m microbit.server --simule`, depuis la racine du dépôt | initialisation + liste en **0,26 s**, **14 outils** ; `connecter` puis `lire_temperature` → 24 °C (simulé) |
| micro:bit | `python3 <chemin>/microbit/server.py --simule` (commande du plan) | ❌ **échoue** : `ImportError: attempted relative import` (c'est un module de paquet). Notre README dit déjà `-m microbit.server` (`microbit/README.md:131`) : seule la commande du plan était fausse |
| EdgeSense (branche de la PR #4, M0) | `python3 edgesense/server.py` | 9 tests verts ; initialisation + liste en **0,25 s**, **3 outils** (`list_devices`, `read_sensor`, `set_actuator`) |

## localcode ne les expose pas au modèle en mode non interactif (VÉRIFIÉ, 0/6)

localcode 0.5.43, `localcode-ui run` (harnais `run_mcp.py`, dérivé du harnais du test
d'injection), modèle Qwen 3.6 Q8, projet jetable. Résumé par essai :
`essais_localcode_mcp.jsonl`.

| Essai | Où est déclaré le serveur | Issue |
|---|---|---|
| T1 | `localcode.json` du projet, écrit par `localcode mcp add`, + `--trust-project` | session menée à terme, **aucun outil MCP** ; `localcode mcp list --trust-project` répond « No MCP servers configured » |
| T2 | config de session, forme `{nom: {...}}` (celle de leurs évals) | aucun outil MCP |
| T3 | config de session, forme `{servers: {...}}` (celle écrite par `mcp add`) | **session bloquée** 180 s, aucune sortie |
| T4 | config utilisateur, forme `{nom: {...}}` | **session bloquée** 180 s, aucune sortie |
| T5 | config utilisateur, forme `{servers: {...}}` | l'agent répond « aucun outil MCP » |
| T6 (EdgeSense) | config utilisateur, forme `{nom: {...}}` | aucun outil MCP |

**Ce que fait l'agent faute d'outils MCP** (T1, T2, T6) : il lit la config et le code du
serveur, puis contourne par le shell :
- en T1 et T2, il écrit et exécute un script qui **importe directement le simulateur** ;
- en T6, il **parle JSON-RPC au serveur EdgeSense à la main**.

La réponse finale est juste (24 °C ; la liste des 3 outils EdgeSense), mais ce n'est pas
l'intégration MCP. C'est encore une illustration du shell libre mesuré en phase 2. Les
tentatives de lancer le serveur hors du projet ont déclenché `external_directory`,
rejeté automatiquement.

**Niveau de preuve** : localcode n'expose pas de serveur MCP stdio local en mode
`run --format json` dans ces 6 configurations (VÉRIFIÉ). La cause est **INCONNU** : forme de la
config, chargement paresseux, ou spécificité du mode non interactif. Pour le dire, il
faudrait lire le source du fork OpenCode. **Non testé** : le TUI interactif (`/mcps`), qui
est le parcours que leur doc décrit.

## Vraie carte micro:bit : non tentée

Sur ce Mac, la pile Bluetooth (`bleak`) ne fonctionne que depuis une application signée qui
détient la permission Bluetooth (TCC), pas depuis un processus Python lancé en ligne de
commande (contrainte déjà constatée sur un autre projet). Un serveur MCP en stdio, lancé par
un agent, n'aurait donc pas accès à la radio. **FAISABLE** seulement via une coque `.app`
signée autour du serveur.

## Pour la suite

1. Rejouer T1 dans le **TUI interactif** (`localcode --trust-project`, puis `/mcps`) : c'est la
   seule configuration documentée par localcode.
2. Rappel : lancer le serveur micro:bit avec `python3 -m microbit.server` (déjà documenté).
3. Côté Klody : le même test de branchement des deux serveurs (Klody est client MCP).
