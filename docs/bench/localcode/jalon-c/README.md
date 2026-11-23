# Jalon C — runner du benchmark et premier lot (23/11/2026)

Prépare le benchmark public du [jalon C](../../../KLODY-ROADMAP.md) : Klody contre localcode
(agent local open source) contre un agent cloud, **mêmes tâches, même harnais**. Même Mac que
la [phase 1](../README.md) : M5 Max, 128 Go, macOS 27.3 bêta.

## Choix du harnais (VÉRIFIÉ dans le code)

- Les tâches de localcode (`evals/tasks/`, Apache 2.0) ont un format simple :
  - `workspace/` : le projet de départ ;
  - `instruction.md` : la consigne ;
  - `tests/test.sh` : un correcteur caché qui écrit `.eval/reward.json` ;
  - `solution/solve.sh` : la solution de référence (oracle).
- **Le harnais Inspect AI de localcode ne sait piloter que localcode** : son solver refuse tout
  autre modèle (`evals/localcode_evals/agent.py:438`).
- J'ai donc écrit un **runner autonome** (`runner/task_runner.py`), qui reproduit à l'identique
  le contrat de leur harnais (`agent.py:270-384`) :
  1. copie de `workspace/` dans `/tmp/localcode-evals/<tâche>-<agent>-<n>`, `git init` et commit ;
  2. lancement de l'agent ;
  3. écriture de `.eval/diff.txt`, la liste des fichiers modifiés selon `git status --porcelain`,
     avec le même filtre, plus `final.txt` (tout le texte du tour) ;
  4. `bash tests/test.sh`.
- Le `python3` du correcteur est épinglé : sinon, c'est celui du shell courant.
- **Pièges vérifiés** :
  - sans `diff.txt`, le contrôle de périmètre des correcteurs est muet, d'où de faux succès ;
  - les dossiers d'état des agents doivent être exclus symétriquement du diff. localcode exclut le
    sien (`.localcode-agent/`) ; Klody écrit `.klody/conventions.json`, que j'exclus de la même
    façon. Avant ce correctif, 10 essais Klody échouaient à tort, et `runner/regrade.py` les a
    recorrigés avec la règle finale.

## Oracles : 32 tâches sur 32 conformes (VÉRIFIÉ)

`evals/verify_oracles.py` de localcode, lancé sans modèle : chaque workspace intact échoue, et
chaque `solve.sh` réussit (`resultats/oracles_32.txt`).

## Premier lot : plomberie validée (VÉRIFIÉ)

6 tâches de régression (`fix-one-bug`, `add-test`, `fix-two-bugs`, `calc-docstrings`,
`no-test-edits`, `honest-status`) × 2 essais × 3 conditions, budget 900 s par tâche, un bloc par
agent.

| Condition | Modèle réellement servi | Réussite | Temps mur médian | RSS max (indicatif) |
|---|---|---|---|---|
| localcode, par défaut (Q8 + drafting), sans `--auto` | UD-Q8_K_XL | **12/12** | 12,3 s | 40 Go |
| Klody, routage auto (C1, « produit ») | `coder`, MLX 4 bits, 31/31 appels | **12/12** | 13,0 s | 55 Go |
| Klody, épinglé `brain` (C2, parité 8 bits) | `brain`, MLX 8 bits, 31/31 appels | **12/12** | 15,7 s | 47 Go |

- **Ce que ça prouve** :
  - le runner pilote les trois conditions ;
  - l'épinglage de Klody couvre **tous** les appels du tour ;
  - le modèle servi est journalisé à chaque essai ;
  - `final.txt` est bien lu (`honest-status` réussit dans les trois conditions).
- **Ce que ça ne prouve pas** : un classement. Ces tâches de régression saturent à 100 % pour
  tout le monde. Le jeu complet, dont les tâches « tracking », plus difficiles, et 12 tâches
  neutres, est en préparation.
- **Limites** :
  - RSS indicatif seulement : il compte les pages du modèle chargées en mémoire, et côté Klody
    tous les workers MLX résidents. La mesure publiée sera le `phys_footprint` ;
  - n = 2 par cellule ;
  - Klody est approuvé sur tout (politique « humain qui approuve les actions demandées »), et la
    politique définitive sera figée avant la campagne ;
  - localcode sans `--auto`, comme dans son harnais officiel.

## Rejouer

```bash
python3 -I runner/task_runner.py lot1 localcode fix-one-bug,add-test,fix-two-bugs,calc-docstrings,no-test-edits,honest-status 2
```
Agents disponibles : `localcode`, `klody` et `klody-brain`. Ensuite :
`python3 -I runner/regrade.py lot1`. Le runner suppose le clone de localcode dans
`~/bench-localcode/src` (ses tâches), son venv dans `~/bench-localcode/venv`, et Klody dans
`~/Projets/klody-code-ai`.
