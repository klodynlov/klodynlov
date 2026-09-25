# Icône de l'app KaribTruck

`icon.svg` est la **source** de l'icône (food truck rose rumba, palmier, soleil,
ciel bleu). Le fichier livré à Xcode est le PNG 1024×1024 :

    ../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png

## Régénérer le PNG depuis le SVG

Avec l'un de ces outils (au choix) :

```bash
# librsvg
rsvg-convert -w 1024 -h 1024 icon.svg -o ../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png

# ou cairosvg (pip install cairosvg)
cairosvg icon.svg -W 1024 -H 1024 -o ../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png

# ou Inkscape
inkscape icon.svg -w 1024 -h 1024 -o ../KaribTruck/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```

Contraintes Apple respectées : **1024×1024, PNG, sans transparence, carré**
(iOS applique lui-même les coins arrondis). Une seule taille suffit (Xcode 14+/iOS).
