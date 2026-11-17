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
| `inventaire_activites.json` | **Écrit par l'app** (test Swift `VoiceInventoryTests`) : tout ce que disent le coloriage, les jeux d'écoute, le train des phrases et les phrases des livres ; lu par `generer.py` (aucune règle de texte recopiée en Python) |
| `exceptions_activites.json` | Écrit par `generer.py` : les phrases des activités restées sans fichier, avec ce que Whisper a entendu ; la seule liste d'exceptions admise par `VoiceInventoryTests` |
| `composer.py` | Miroir de `ClipJoiner.swift` (phrase libre = wagons enchaînés) et mesure A/B (composée, « sujet + verbe » d'un bloc, entière) avec Whisper et une page d'écoute à l'aveugle |
| `page_activites.py` | Page d'écoute des phrases douteuses des activités (sans fichier, gardées de justesse, lues autrement) |

Les rendus de l'essai, du duel et la liste des rejets vont dans `rendu/`, qui n'est pas versé dans le dépôt.

```bash
# 1. l'inventaire des activités, exporté par l'app (après tout changement d'un texte, d'une page, d'un livre)
cd eveil/ios && EVEIL_VOICE_INVENTORY=$PWD/../outils/voix/inventaire_activites.json \
    swift test --filter VoiceInventoryTests/testExportTheInventory && cd ../..
# 2. rendre (ce qui est déjà rendu est gardé ; tout refaire : --tout). Phrases : Supertonic puis Whisper.
HF_HUB_OFFLINE=1 ~/KlodyPocket/build/voice-eval/st-venv/bin/python eveil/outils/voix/generer.py
python3 eveil/outils/voix/generer.py --check                                    # inventaire ↔ manifeste
python3 eveil/outils/voix/page_activites.py <dossier>                           # les phrases à écouter
```

## Les autres activités (17/11/2026)

Demande de l'utilisateur : « utiliser le moteur de voix du petit train des mots pour toutes les autres activités ».
- **Inventaire exact, venu de l'app** : `ColoringVoice.lines`, `EarGames.voiceLines`, `PhrasePrompts.voiceLines`,
  `PhraseGrammar.voiceChunks`, `BookSentenceView.voiceLines` ; table centrale `VoiceInventory` (tests). Un test vérifie
  que le JSON versionné est à jour, un autre que chaque texte a son fichier (ou figure dans `exceptions_activites.json`).
- **Train des phrases libre** (≈ 10 400 phrases par langue) : pas rendu entier. Ses wagons le sont, et l'app enchaîne
  leurs fichiers (`ModelVoicePlayer.speak(parts:)`, `ClipJoiner` : silence coupé, ≈ 100 ms entre deux wagons). Une
  phrase entière préparée (celles des livres) passe d'abord ; s'il manque un seul wagon, toute la phrase est dite par
  la voix de l'iPad (jamais deux voix dans une phrase). Les questions finies (« Le chat mange quoi ? ») sont rendues
  entières.
- **Contrôle** : Whisper large-v3-turbo (MLX, hors ligne), WER normalisé (casse, accents, ponctuation, homophones
  « Lou/loup ») ≤ `SEUIL_WER` (0,2 : une phrase de moins de 5 mots doit être retrouvée exactement), 4 prises par
  lecture. Lectures (`DIRE_PHRASES`, `AUTRES_LECTURES`) : « Le chat dort… où ? » (le « où » final se collait au verbe),
  « l'osse ». Sans accord → pas de fichier, page d'écoute.
- **Débit** : les phrases sont en AAC 32 kbit/s, 24 kHz (les mots et syllabes restent à 64 kbit/s), et
  `sans_bourrage` retire les ≈ 3 Ko de remplissage qu'afconvert laisse dans chaque m4a (son identique, vérifié au
  décodage). Rendu du 17/11/2026 : 2 873 phrases des activités, 19,6 Mo (64 kbit/s : ≈ 42 Mo) ; 88 sans fichier.
- **Wagon seul** : Whisper entend mal un mot isolé (« rit » → « ré », « Lou » → « l'eau ») ; un wagon refusé seul est
  réécouté derrière trois porteurs préparés (« le chat rit », « le poisson rit », « la biche rit »), là où l'app le joue.
- **Mesure de la composition** (`composer.py`, 48 phrases libres) : composée, Whisper retrouve 46/48 phrases (entière :
  43/48), mais elle dure 35 % de plus qu'une phrase entière (chaque wagon garde sa prosodie de mot seul) ; « sujet +
  verbe » d'un bloc puis le complément : 41/48, +10 % de durée, 1 200 fichiers de plus → non retenu. Jugement final à
  l'oreille (page A/B à l'aveugle).

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
- Les **phrases libres** du train des phrases ne sont pas rendues entières : elles sont composées de leurs wagons
  (voir plus haut). Les phrases des autres activités ont leur fichier.
- **Contrôle** : un énoncé qui ne passe pas le détecteur, même avec une autre prise ou une réécriture
  (`REECRIRE`), n'a pas de fichier et garde la voix de l'iPad. Ces énoncés sont listés dans
  `rendu/rejets.json`, à écouter. Les réécritures sont listées aussi : le détecteur juge les syllabes et la
  consonne finale, pas les voyelles.
