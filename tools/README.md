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

# écrire le rapport Markdown dans un fichier
python3 tools/classer_sessions.py --out rapport.md

# rapport visuel : HTML autonome avec graphiques (à ouvrir dans le navigateur)
python3 tools/classer_sessions.py --html rapport.html

# exporter aussi un CSV (pour trier/filtrer soi-même)
python3 tools/classer_sessions.py --csv sessions.csv

# pointer vers un autre dossier de sessions
python3 tools/classer_sessions.py --dir /chemin/vers/.claude/projects
```

> Astuce : les options se combinent
> (`--out rapport.md --html rapport.html --csv sessions.csv`).

### Ce qu'il produit

- **🚀 Par projet (les tiens)** — Klody Code AI, klody-ui, Dream × World,
  LibraryBrain, VocalBrain, profil GitHub.
- **📁 Par dossier de travail** — regroupement par `cwd` brut.
- **🎯 Par thème** — debug, feature, refactor, doc, tests, question, config/CI, sécurité.
- **🛠️ Par techno** — Python, Rust, TS/JS, MCP, SQL, Shell.
- **🕑 Détail chronologique** — date, projet, thème, nb de messages, durée, aperçu du prompt.

Le rapport `--html` reprend ces angles sous forme visuelle : tuiles de stats,
barres par projet, donut par thème, barres par techno et timeline d'activité.
C'est un fichier **autonome** (SVG en ligne, thème clair/sombre, aucune
ressource externe) qui s'ouvre directement dans un navigateur.

### Personnalisation

La reconnaissance des projets, des thèmes et des technos repose sur des
dictionnaires en haut du fichier (`PROJETS_CONNUS`, `THEMES`, `TECHNOS`).
Ajoute tes propres indices de chemin ou mots-clés selon tes conventions de
dossiers.

## `objectifs.py`

Suit tes **ambitions** et leur avancement. Tu écris tes objectifs dans un
simple fichier texte (titre, horizon, description, jalons cochables) et le
script calcule la progression, met en avant les prochaines échéances et génère
un rapport lisible — Markdown ou dashboard HTML autonome. Aucune dépendance
externe (Python 3.8+). Il ne modifie que les fichiers de sortie que tu demandes.

### Usage

```bash
# rapport Markdown affiché dans le terminal
python3 tools/objectifs.py mes-objectifs.txt

# écrire le rapport Markdown dans un fichier
python3 tools/objectifs.py mes-objectifs.txt --out road.md

# dashboard visuel : HTML autonome (barres de progression, échéances)
python3 tools/objectifs.py mes-objectifs.txt --html road.html
```

Un exemple prêt à copier : [`objectifs.exemple.txt`](objectifs.exemple.txt).

### Mode portfolio (`--index`)

Agrège **plusieurs** fichiers `*.objectifs.txt` (un par projet) en un seul
tableau de bord : avancement global, une carte par projet, et les prochaines
échéances fusionnées tous projets confondus.

```bash
# tous les projets d'un dossier
python3 tools/objectifs.py --index docs/ --html portfolio.html

# ou une liste explicite de fichiers
python3 tools/objectifs.py --index docs/klody.objectifs.txt docs/silverbrain.objectifs.txt
```

Un dossier passé en argument est développé en ses fichiers `*.objectifs.txt`. Le
nom affiché de chaque projet vient d'une ligne `projet: …` en tête de fichier
(sinon il est déduit du nom de fichier).

### Format du fichier d'ambitions

```
# Titre de l'ambition
horizon: 2026-12-31            # échéance globale (AAAA-MM-JJ ou AAAA-MM)
statut: en cours              # texte libre
> Description sur une ou plusieurs lignes préfixées par « > ».
- [x] Jalon déjà atteint
- [ ] Jalon à faire @2026-08          # « @date » = échéance du jalon
- [ ] Jalon prioritaire ! @2026-09    # « ! » = jalon prioritaire
```

Les lignes vides et celles commençant par `//` sont ignorées. Garde ton fichier
d'ambitions **en local** (hors dépôt) si tu ne veux pas le publier ; la
[feuille de route synthétique](../docs/ROADMAP.md) reste, elle, versionnée.
