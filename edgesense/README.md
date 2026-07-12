# EdgeSense — M0

**Pont MCP capteurs → agent local.** Un serveur [MCP](https://modelcontextprotocol.io)
qui expose des capteurs et actionneurs comme des *outils* qu'un agent local
(Klody, ou Claude Desktop branché sur un modèle Ollama/MLX) peut lire et
actionner. L'IA raisonne en local sur les données des objets — rien ne part dans
le cloud.

> Ce jalon **M0** prouve la boucle *percevoir → décider → agir → percevoir* avec un
> **capteur et un actionneur simulés** (pièce + chauffage), sans matériel. Voir la
> [note de conception](../docs/aiot-edge-projects.md#5-note-de-conception--projet-a-edgesense)
> pour l'architecture cible et les jalons M1–M4 (matériel réel, temps réel,
> sécurité, multi-nœuds).

## Contenu

| Fichier | Rôle | Dépendances |
|---|---|---|
| `devices.py` | cœur : monde simulé, catalogue, garde-fous, journal | **stdlib seule** |
| `server.py` | adaptateur MCP (expose le cœur aux agents) | `mcp>=1.2` |
| `demo.py` | boucle fermée sans MCP — preuve du concept | **stdlib seule** |
| `test_devices.py` | tests du cœur (`unittest`) | **stdlib seule** |

L'essentiel de la logique — et donc les tests — vit dans `devices.py` ; le serveur
MCP n'est qu'une fine couche. On peut tout valider **sans installer MCP**.

## Démarrage rapide

```bash
# 1. Prouver la boucle (aucune dépendance) :
python3 demo.py

# 2. Lancer les tests :
python3 -m unittest test_devices -v

# 3. Lancer le serveur MCP (pour un agent) :
pip install -r requirements.txt
python3 server.py
```

La démo affiche le thermostat en action : l'« agent » (politique codée en dur)
allume/éteint le chauffage pour maintenir 20–22 °C, et la température lue réagit
au tour suivant. Dans le vrai système, un **LLM local** remplace cette politique —
l'interface (`read_sensor` / `set_actuator`) ne change pas.

## Appareils exposés (M0)

| id | type | interface |
|---|---|---|
| `temp-1` | capteur de température (`°C`) | `read_sensor("temp-1")` |
| `heater-1` | actionneur chauffage (`on`/`off`) | `set_actuator("heater-1", "on")` |

**Outils MCP** : `list_devices`, `read_sensor`, `set_actuator`.
**Ressource MCP** : `edgesense://state` (instantané complet).

## Garde-fous (dès M0)

- **Allowlist stricte** : tout appareil hors catalogue ou tout état hors liste
  autorisée est refusé (`DeviceError`).
- **Journal tamper-evident** : chaque commande est inscrite dans un registre
  append-only à chaînage de hachage SHA-256 ; `verify_journal()` détecte toute
  falsification. La signature cryptographique complète arrive en M3.

## Brancher un agent (Claude Desktop)

Copier `claude_desktop_config.example.json` dans la config Claude Desktop et
adapter le chemin absolu vers `server.py`. L'agent voit alors les 3 outils et
peut piloter la pièce en langage naturel (« s'il fait moins de 20°, chauffe »).

Pour un agent **100 % local**, brancher le même serveur MCP sur un client relié à
Ollama/MLX plutôt qu'au cloud.
