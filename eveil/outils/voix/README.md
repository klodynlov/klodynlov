# La voix du jeu : Supertonic 3, préparée à l'avance

Décision de l'utilisateur, 17/11/2026 :
1. essayer Supertonic 3 pour la voix ;
2. choisir le style **F5**. Les mesures le donnaient devant sur tout le niveau 1 : fin des mots à fourgon entendue
   9/13 contre 5/13 pour F3, syllabe juste 33/49 contre 25/49. L'écoute à l'aveugle aussi : 10 contre 6 face à F3 ;
3. l'intégrer **préparé à l'avance**.

| Fichier | Rôle |
|---|---|
| `supertonic_essai.py`, `verifier_fins.py`, `page_ecoute.py` | L'essai : les 5 voix F1–F5, avec Flo et Thomas (voix système) comme repères |
| `duel.py` | Le face-à-face F3 / F5 sur les 62 mots du niveau 1 |
| `generer.py` | Rend avec F5 tout ce que le petit train et les livres font dire, contrôle chaque énoncé avec le détecteur, écrit `ios/Sources/WordEndAudio/Resources/voix/` (fichiers m4a et `manifest.json`) |

Les rendus de l'essai, du duel et la liste des rejets vont dans `rendu/`, qui n'est pas versé dans le dépôt.

```bash
~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/generer.py   # rendre (environ 10-20 min)
python3 eveil/outils/voix/generer.py --check                                    # inventaire ↔ manifeste
```

## Moteur et licence

- **Moteur** : Supertonic 3 de Supertone, ONNX, révision Hugging Face `aafc6e3` (`supertone-oss-archive/supertonic-3`,
  dépôt archivé). L'environnement et les poids sont ceux de Klody Pocket (`~/KlodyPocket/build/voice-eval/`).
- **Poids sous OpenRAIL-M.** Les sorties (les fichiers audio) ne sont pas revendiquées par Supertone, mais deux
  restrictions d'usage s'appliquent :
  - (e) **dire que le contenu est généré par une machine** : l'espace des grands le dit, sous « Voix du train » ;
  - § 5 : **les utilisateurs doivent respecter les mêmes restrictions** : à reprendre dans les mentions / CGU
    avant une diffusion publique.
- Le jeu ne fait ni diagnostic ni avis médical (restriction l).

## Limites connues

- Supertonic lit des **lettres**, pas l'API. On ne peut pas lui imposer la prononciation, contrairement à la
  voix système de l'app.
- Les **sons seuls** (« ch » du fourgon, geste du son d'un livre) gardent la voix de l'iPad. Les bruitages du
  train (« chhh », « sss ») restent.
- Les **phrases** (train des phrases, jeux d'écoute) gardent la voix de l'iPad : elles sont trop nombreuses
  pour être préparées.
- **Contrôle** : un énoncé qui ne passe pas le détecteur, même avec une autre prise ou une réécriture
  (`REECRIRE`), n'a pas de fichier et garde la voix de l'iPad. Ces énoncés sont listés dans
  `rendu/rejets.json`, à écouter. Les réécritures sont listées aussi : le détecteur juge les syllabes et la
  consonne finale, pas les voyelles.
