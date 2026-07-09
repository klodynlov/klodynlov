# tools/

Petits utilitaires locaux.

## `classer_sessions.py`

Classe tes sessions **Claude Code** par catégories : par projet (les tiens),
par thème d'activité, par techno et par date. Aucune dépendance externe
(bibliothèque standard Python 3.8+). Le script est **en lecture seule** — il
parcourt `~/.claude/projects/` et ne modifie rien.

### Usage

```bash
# rapport Markdown affiché dans le terminal
python3 tools/classer_sessions.py

# écrire le rapport dans un fichier
python3 tools/classer_sessions.py --out rapport.md

# exporter aussi un CSV (pour trier/filtrer soi-même)
python3 tools/classer_sessions.py --csv sessions.csv

# pointer vers un autre dossier de sessions
python3 tools/classer_sessions.py --dir /chemin/vers/.claude/projects
```

### Ce qu'il produit

- **🚀 Par projet (les tiens)** — Klody Code AI, klody-ui, Dream × World,
  LibraryBrain, VocalBrain, profil GitHub.
- **📁 Par dossier de travail** — regroupement par `cwd` brut.
- **🎯 Par thème** — debug, feature, refactor, doc, tests, question, config/CI, sécurité.
- **🛠️ Par techno** — Python, Rust, TS/JS, MCP, SQL, Shell.
- **🕑 Détail chronologique** — date, projet, thème, nb de messages, durée, aperçu du prompt.

### Personnalisation

La reconnaissance des projets, des thèmes et des technos repose sur des
dictionnaires en haut du fichier (`PROJETS_CONNUS`, `THEMES`, `TECHNOS`).
Ajoute tes propres indices de chemin ou mots-clés selon tes conventions de
dossiers.
