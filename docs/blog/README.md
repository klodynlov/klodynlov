# Le Carnet — le blog de `klodynlov`

Un blog personnel **100 % statique**, sans étape de build ni dépendance externe.
On m'y exprime « à but informatif » sur l'IA locale, les agents, MCP et l'ingénierie.

## Structure

```
docs/blog/
├── index.html              ← accueil + liste des articles
├── a-propos.html           ← qui je suis / la ligne éditoriale
├── template-article.html   ← modèle à copier pour un nouvel article
├── assets/
│   ├── blog.css            ← charte partagée (thème clair/sombre)
│   └── blog.js             ← bascule de thème + tableau POSTS
└── posts/
    └── AAAA-MM-JJ-titre.html
```

## Publier un nouvel article — 3 étapes

1. **Copier le modèle** dans `posts/` sous un nom daté :
   `posts/2026-08-01-mon-sujet.html`.
2. **Écrire le contenu** dans le bloc `<div class="prose">` (balises dispo :
   `<p>`, `<h2>`, `<h3>`, `<ul>/<li>`, `<blockquote>`, `<strong>`, `<em>`,
   `<code>`, et `<pre><code>…</code></pre>`). Penser à mettre à jour le
   `<title>`, la catégorie (`<span class="chip">`), la date et la durée de lecture.
3. **Référencer l'article** en ajoutant une entrée **en tête** du tableau
   `POSTS` dans `assets/blog.js` (les plus récents en premier) :

```js
{
  url: 'posts/2026-08-01-mon-sujet.html',
  titre: 'Mon titre',
  categorie: 'IA locale',
  date: '2026-08-01',
  dateLisible: '1ᵉʳ août 2026',
  lecture: '5 min',
  resume: "Une ou deux phrases d'accroche."
},
```

La carte apparaît alors automatiquement sur la page d'accueil.

## Aperçu en local

Ouvrir `docs/blog/index.html` directement dans un navigateur suffit
(aucun serveur requis).

## Mise en ligne (GitHub Pages)

Le déploiement est **automatisé** par GitHub Actions
(`.github/workflows/pages.yml`) : à chaque `push` sur `main` touchant `docs/`,
le dossier `docs/` est publié sur GitHub Pages (Pages est activé
automatiquement au premier passage, aucun réglage manuel requis).

- Blog : `https://klodynlov.github.io/blog/`
- La racine `https://klodynlov.github.io/` redirige vers le blog
  (`docs/index.html`).
