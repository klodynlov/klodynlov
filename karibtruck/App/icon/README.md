# Logo & icône KaribTruck

Logo de la marque **Karib Truck — Saveurs Créoles**, redessiné proprement en
vectoriel (fond rose, soleil couchant, palmiers/cocotiers, case créole, vagues,
lettrage brush).

## Fichiers

- `icon.svg` — **icône de l'app** (sans sous-titre, lisible en petit). Source de
  `../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.
- `logo-full.svg` / `logo-full.png` — **logo complet** avec « Saveurs Créoles »
  (pour l'écran d'accueil de l'app). Aussi dans le catalogue d'assets sous
  `KaribLogo` → utilisable en SwiftUI : `Image("KaribLogo")`.

## Police du lettrage

Le lettrage utilise **Kaushan Script** (police brush libre, OFL), proche du logo
d'origine. Récupérable sans navigateur :

```bash
npm pack @fontsource/kaushan-script      # contient files/kaushan-script-latin-400-normal.woff2
```

> Si vous récupérez un jour le **fichier vectoriel d'origine** du logo (graphiste /
> imprimeur du covering), il donnera un lettrage au plus près ; ces SVG sont une
> reconstitution fidèle à l'esprit.

## Régénérer le PNG depuis le SVG

Les `.svg` référencent la police par son nom (`font-family:"Kaushan Script"`) : la
police doit être installée/embarquée au moment du rendu. Avec l'un de ces outils :

```bash
# rsvg-convert (avec la police installée sur le système)
rsvg-convert -w 1024 -h 1024 icon.svg -o ../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png

# ou Inkscape / cairosvg
```

Contraintes Apple respectées : **1024×1024, PNG, sans transparence, carré**
(iOS arrondit les coins).
