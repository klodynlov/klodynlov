# Banc localcode : protocole et données brutes (phase 1)

Mesures du **23 novembre 2026** qui alimentent la fiche
[localcode](../../CONCURRENCE.md#localcode--mjwsololocalcode). Tout est rejouable
avec les scripts de ce dossier (Python stdlib + bash, aucune dépendance).

## Machine

| | |
|---|---|
| Mac | MacBook Pro `Mac17,7`, **Apple M5 Max** (18 cœurs : 6 Super + 12 Performance) |
| Mémoire | 128 Go unifiée |
| macOS | 27.3 **bêta** (26C5035r) |
| Alimentation | secteur, batterie 100 % |
| localcode | **0.5.43** (PyPI), venv isolé `uv`, Python 3.12.13 |
| Klody | Klody Core (gateway :8090), worker `brain` = `unsloth/Qwen3.6-35B-A3B-MLX-8bit` |

## Ce qui a été mesuré

| # | Mesure | Script | Données |
|---|---|---|---|
| 1 | Installation + premier lancement | à la main (`time`) | `resultats/first_response.json`, journal du superviseur |
| 2 | Trafic sortant | `scripts/netwatch.py` (lsof toutes les 1 s, processus localcode) | `resultats/trafic_resume.txt` |
| 3 | Hors ligne | `scripts/offline_test.sh` | `resultats/offline_test.log` |
| 4 | Vitesse localcode vs Klody, drafting on/off | `scripts/speedbench.py`, `run_speed_ab.sh` (v1), `run_speed_fresh.sh` (v2) | `resultats/speed_*.jsonl`, `speed_*.log` |
| 5 | Build reproductible de `localcode-ui` | `build_ui_binary.sh --check` (dépôt localcode) | `resultats/build_check.log` |

## Protocole de vitesse

- **Modèle** : Qwen 3.6 35B-A3B des deux côtés. localcode : `UD-Q8_K_XL` (GGUF, choix
  automatique pour 128 Go). Klody : `MLX-8bit`. Même modèle, quantification de même classe
  (8 bits), pas strictement identique.
- **Requête** : 3 prompts fixes (`P1_codegen`, `P2_explain`, `P3_refactor`, texte exact dans
  `speedbench.py`), température 0, `seed` 42, 600 tokens max, **raisonnement coupé** des deux
  côtés (`--reasoning off` pour llama-server ; `enable_thinking: false` pour MLX).
- **Mesure côté client**, en streaming : `ttft_s` (requête → 1er fragment) et
  `decode_tps` = (tokens − 1) / (t_dernier − t_premier) ; tokens lus dans `usage`.
- **Contrôle thermique** : chauffe de 1 200 tokens avant chaque passe, repos ≥ 120 s, GPU
  ≤ 10 % avant de reprendre, ordre ABBA.
- **Une seule charge lourde à la fois** : worker Klody déchargé pendant localcode, serveur
  localcode arrêté pendant Klody.
- **Drafting off** = commande `llama-server` **exacte** du superviseur
  (`resultats/llama_cmd_default.txt`) moins `--model-draft` et `--spec-type`.

### Piège rencontré (et corrigé)

Le banc v1 rejouait les mêmes prompts sur le même serveur. À température 0 la sortie est
identique, et le *copy drafting* (`ngram-mod`) **recopie** ce qu'il a déjà généré : la
vitesse « avec drafting » monte de 92 à 782 tok/s sur le même prompt. Le **banc v2**
démarre un serveur neuf à chaque répétition et joue chaque prompt une seule fois. Seuls les
chiffres v2 sont retenus pour le gain du drafting ; le v1 reste valable pour les conditions
sans drafting (Klody et localcode sans drafting), stables à ±2 %.

## Rejouer

```bash
uv venv ~/bench-localcode/venv && uv pip install --python ~/bench-localcode/venv/bin/python localcode==0.5.43
```
```bash
python3 -I scripts/netwatch.py ~/bench-localcode/logs/net.jsonl
```
Lancer `localcode` une fois pour télécharger le modèle, relever la commande
`llama-server` (`ps -o command= -p <pid>`) dans `~/bench-localcode/logs/llama_cmd_default.txt`,
arrêter le serveur du superviseur, puis :
```bash
bash scripts/run_speed_fresh.sh
```
Les scripts supposent `~/bench-localcode/{tools,logs}` ; adapter les chemins en tête de fichier.
