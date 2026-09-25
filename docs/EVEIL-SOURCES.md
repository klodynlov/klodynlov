# Suite Éveil — état de l'art sourcé et vérifié en contradiction

> Compagnon du [blueprint](EVEIL.md). Même méthode que l'état de l'art AIoT : chaque affirmation
> utile à la conception est **confirmée, nuancée, réfutée ou laissée non vérifiée**, avec ses sources.
> Dans le blueprint, **`[X#]` renvoie à l'affirmation n° # de l'axe X** ci-dessous.

**Date :** 2026-09-24 · **6 axes** · **168 affirmations examinées** · **≈ 170 références relevées**

> **Mise à jour du 25/09/2026** — comparaison avec LibraryBrain (texte intégral, bibliothèque locale) :
> [`EVEIL-SOURCES-LIBRARYBRAIN.md`](EVEIL-SOURCES-LIBRARYBRAIN.md). Seul changement ici : **A22 fermé**,
> appuyé sur des citations vérifiées dans les documents d'origine. Aucun autre verdict n'est modifié.

| Axe | Sujet | Affirmations | Bilan |
|---|---|---:|---|
| **A** | Développement phonologique FR/EN, bilinguisme, repérage | 23 | 15 confirmées · 3 nuancées · 0 réfutée · 5 non vérifiées |
| **B** | Interventions, apps, dosage, parents, validation | 27 | 14 confirmées · 9 nuancées · 1 réfutée · 3 non vérifiées |
| **C** | Parole d'enfant, ASR, acoustique des fricatives, corpus | 21 | 13 confirmées · 2 nuancées · 2 réfutées · 4 non vérifiées |
| **D** | Plateforme Apple (lue dans la doc officielle) | 38 | 28 confirmées · 4 nuancées · 2 réfutées · 4 non vérifiées |
| **E** | Réglementation, éthique, conformité | 30 | 23 confirmées · 5 nuancées · 1 réfutée · 1 non vérifiée |
| **F** | Marché, coloriage, graphomotricité, co-conception | 29 | 15 confirmées · 7 nuancées · 1 réfutée · 6 non vérifiées |

## Méthode et limites (à lire d'abord)

- Six recherches parallèles, une par axe, avec consigne stricte : ne citer que ce qui a été
  **réellement consulté** dans la session, écrire NON VÉRIFIÉ sinon.
- **Limites réelles de cette passe :** le proxy de l'environnement bloquait la lecture directe de la
  plupart des sites académiques et institutionnels (PubMed/PMC, ASHA, HAS, Eduscol, EUR-Lex,
  Légifrance, CNIL, FTC…), et le quota de recherche web de la session (200 requêtes) a été épuisé.
  Pour les axes A, B, C, E, F, beaucoup de verdicts reposent donc sur des **résumés et extraits**
  renvoyés par le moteur, ou sur des copies de textes officiels hébergées sur GitHub (signalé). L'axe
  **D (Apple)** a été lu **directement** dans la documentation officielle (endpoints JSON DocC).
- Conséquence : **aucun chiffre marqué NON VÉRIFIÉ n'est utilisé dans le produit**, et les points
  cliniques non vérifiés (critères HAS, normes d'intelligibilité, recommandations écrans) sont
  **renvoyés au panel d'experts** et à une seconde passe documentaire — typiquement dans
  **LibraryBrain** (§ dédiée en fin de document).

### ⛔ Réfuté — à ne pas réutiliser

| Id | Affirmation réfutée | Ce qui est vrai |
|---|---|---|
| B8 | « Un logiciel d'entraînement utilisé par des éducateurs améliore la parole des 4-5 ans » | Pas mieux que le contrôle (n = 123, d = 0,08) |
| C4 | « Lee, Potamianos & Narayanan 1999 couvre les 3-5 ans » | 5 à 17 ans (+ adultes) |
| C17 | « MyST, CSLU, CMU Kids couvrent les 3-5 ans et sont libres » | Non : grades 3-5 / K-10 / 6-11 ans ; non commercial ou payants |
| D2b | Noms d'API de la WWDC25 (`.offlineTranscription`, `allocatedLocales`…) | Noms finaux : `.transcription`, `.progressiveTranscription`, `reserve(locale:)`… |
| D2d | « `SpeechAnalyzer` exige l'autorisation de reconnaissance vocale » | Non : micro seulement (mais modèles téléchargés) |
| D4c | « `installTap` livre exactement la taille demandée » | « may choose another size » |
| E10 | « La voix est une donnée biométrique (art. 9) » | Seulement si traitée pour identifier ; mais déduire un trouble = donnée de santé probable |
| F12 | « Aucune app d'articulation bilingue FR/EN n'existe » | Speech Blubs (FR depuis 2020), OrthoPicto |
| A (hyp.) | « minouche → minou = effacement de syllabe » | Effacement de **consonne finale** (A1) |

---

## A · Développement phonologique, bilinguisme, repérage

| Id | Affirmation | Verdict | Sources |
|---|---|---|---|
| A1 | « douche → dou », « minouche → minou » = effacement de **consonne finale** (coda /ʃ/), pas de syllabe ; le -e écrit ne forme pas de syllabe orale. Réserves : prononciation méridionale avec schwa ; « minou » est un vrai mot | CONFIRMÉ | A[13] |
| A2 | « À 3 ans, c'est encore dans la norme » : omissions ponctuelles plausibles (/ʃ/ tardif, codas fricatives fragiles), mais un effacement **systématique** des codas est inhabituel en français → avis orthophonique | NUANCÉ | A[7][9][10][11][13] |
| A3 | Anglais : effacement de consonne finale éliminé vers 3;3 (Grunwell/Bowen) ; vers 4 ans selon un service citant Dodd 2003 | NUANCÉ | A[2][3] |
| A4 | Anglais : effacement de syllabe faible éliminé vers 4;0 (3;11 dans un tableau adapté de Dodd 2003, n = 684) | CONFIRMÉ | A[1][2][3] |
| A5 | Québécois : /t m n z/ avant 36 mois ; /s ʒ ʃ j/ après 53 mois ; initiale → médiane → finale (n = 156, 20-53 mois) | CONFIRMÉ | A[7] |
| A6 | Français : codas finales correctes à ≈ 80 % dès 2;6 ; plus produites en monosyllabes qu'en dissyllabes chez les plus jeunes (n = 141, 2;6-6;10) | CONFIRMÉ | A[9] |
| A7 | Français vers 2;6 : processus ≥ 10 % dans les 3 corpus = réduction de groupes et **antériorisation des palatales** (n = 120, dont 42 bilingues) | CONFIRMÉ | A[10] |
| A8 | Français à 3 ans (Belgique, n = 34) : substitutions et omissions fréquentes ; en monosyllabes, codas moins exactes que les attaques | CONFIRMÉ | A[12] |
| A9 | Anglais US : /ʃ/ acquis entre 4;0 et 4;11 (critère 90 %) ; /ʃ/ parmi les « late 8 » de Shriberg | CONFIRMÉ | A[4][6] |
| A10 | McLeod & Crowe 2018 : 27 langues dont le français, 64 études, 26 007 enfants ; la plupart des consonnes acquises à 5;0 | CONFIRMÉ | A[5] |
| A11 | Anglais : suppression de la syllabe faible **initiale** des mots accentués en 2ᵉ syllabe (*banana* → *nana*) | CONFIRMÉ | A[17] |
| A12 | Français : accent final de groupe ; allongement final dès 2 ans ; rapports adultes dès 2;6 | CONFIRMÉ | A[15][16][18] |
| A13 | Français : « les jeunes enfants suppriment la syllabe initiale » — surtout < 2 ans, études de cas ; syllabes médianes aussi | NUANCÉ | A[12][14][19] |
| A14 | Pas de biais trochaïque universel (9 anglophones, 5 francophones, 13-20 mois) | CONFIRMÉ | A[20] |
| A15 | Bilingues FR + autre langue : peu de différences sur les processus inhabituels ; codas/groupes meilleurs si l'autre langue en a beaucoup | CONFIRMÉ | A[9][10][16] |
| A16 | Les classifications anglophones des TSP se transposent mal au français | CONFIRMÉ | A[11][21] |
| A17 | Thèse Yamaguchi (Paris 3, 2012) : existence confirmée, contenu non lu | CONFIRMÉ (métadonnées) | A[8] |
| A18–A21 | Normes EVALO 2-6 · profils bilingues (Hambly 2013, IEPMCS) · intelligibilité à 3 ans · Eduscol (syllabe orale/écrite) | NON VÉRIFIÉ | — |
| A22 | Critères HAS/ANAES de repérage et d'orientation : signes d'alerte HAS entre 3 ans et 4 ans ½ (langage non intelligible pour les non-proches, pas de phrase constituée, compréhension altérée) ; profil 3 à l'ERTL4 → avis du médecin de PMI, et orientation directe possible vers l'orthophoniste en parallèle ; ANAES 2001 : plainte → évaluation individuelle et examen médical, bilan orthophonique selon sévérité, spécificité et persistance, prise en charge avant 4-5 ans si inintelligibilité, agrammatisme ou trouble de la compréhension (grade C). Seuils du DPL3 : non vérifiés | CONFIRMÉ — *LibraryBrain, vérifié dans le texte* (25/09/2026) | A[22][23][24] |
| A23 | Prévalence et résolution spontanée | NON VÉRIFIÉ | — |

**Sources A** (lu = résumé/extraits sauf mention) :
[1] Dodd, Holm, Hua & Crosbie (2003), *Clin. Ling. & Phon.* 17(8), doi:10.1080/0269920031000111348 ·
[2] Bowen, *Table 3 – Elimination of phonological processes* (speech-language-therapy.com) ·
[3] Coventry Children's SLT (2024), *Speech – What to expect and when* (PDF libre) ·
[4] Shriberg (1993), via [6] ·
[5] McLeod & Crowe (2018), *AJSLP* 27(4), doi:10.1044/2018_AJSLP-17-0100 (PDF listé) ·
[6] Crowe & McLeod (2020), *AJSLP* 29(4), doi:10.1044/2020_AJSLP-19-00168 (PDF listé) ·
[7] MacLeod, Sutton, Trudeau & Thordardottir (2011), *IJSLP* 13(2), doi:10.3109/17549507.2011.487543 ·
[8] Yamaguchi (2012), thèse Paris 3 (PDF listé sur talkbank.org) ·
[9] Kehoe (2021), *Coda consonant production in French-speaking children*, *Clin. Ling. & Phon.* 35(6), doi:10.1080/02699206.2020.1795723 (PDF listé, unige.ch) ·
[10] Kehoe (2025), *Usual and unusual phonological processes in monolingual and bilingual French-speaking children*, doi:10.1080/02699206.2025.2475064 ·
[11] Kehoe (2026), *Folia Phoniatr. Logop.* 78(1), doi:10.1159/000546710 ·
[12] *Exploring word production in three-year-old monolingual French-speaking children* (2023), doi:10.1080/02699206.2022.2092424 (manuscrit ORBi) ·
[13] Brosseau-Lapré, Rvachew, MacLeod, Findlay, Bérubé & Bernhardt (2018), *Rev. can. orthoph. audiol.* 42(1) (PDF libre) ·
[14] Demuth & Johnson (2003), *Can. J. Linguistics* 48(3/4) ·
[15] Allen (1983), *Phonetica* 40(4) ·
[16] Kehoe (2022), *Language and Speech*, doi:10.1177/00238309211030312 (libre, PMC9014682) ·
[17] Kehoe & Stoel-Gammon (1997), *JSLHR* 40(3) ·
[18] Goad & Buckley (2006), *Catalan J. Linguistics* 5 (PDF auteur) ·
[19] Rose (2000), thèse McGill (PDF listé, talkbank.org) ·
[20] Vihman, DePaolis & Davis (1998), *Child Development* 69(4) ·
[21] *Classification of speech sound disorders in French-speaking children* (PMID 42166379) ·
[22] HAS, *Bilan de santé en école maternelle* — rapport d'élaboration (avril 2026), p. 71, tableau 10 (lu en texte intégral via LibraryBrain) ·
[23] HAS, *Bilan de santé en école maternelle* — guide (avril 2026), p. 31 (idem) ·
[24] ANAES, *L'orthophonie dans les troubles spécifiques du développement du langage oral chez l'enfant de 3 à 6 ans*, recommandations (mai 2001), p. 8, 10 et 12 (idem).

---

## B · Interventions, apps éducatives, dosage, parents, validation

| Id | Affirmation | Verdict | Sources |
|---|---|---|---|
| B1 | Revue de 134 études (1979-2009), 46 approches ; modèle dominant : orthophoniste, séances de 30-60 min, 2-3/semaine | CONFIRMÉ | B[1] |
| B2 | Paires minimales = approche la plus étudiée ; aucune approche démontrée supérieure | NUANCÉ | B[1] |
| B3 | Contrastes minimaux **signifiants** : réduction de l'effacement de consonne finale, généralisation aux mots non entraînés (n = 2) | CONFIRMÉ | B[2] |
| B4 | Paires minimales classiques pour peu d'erreurs ; oppositions multiples pour les jeunes enfants aux TSP modérés-sévères | CONFIRMÉ | B[3][4] |
| B5 | Approche par cycles : 3 enfants 4;3-5;3, gains chez 2 sur 3 | NUANCÉ | B[5] |
| B6 | Stimulation auditive ciblée possible très tôt, avec les parents | NUANCÉ | B[6] |
| B7 | Données chiffrées sur la consonne finale pour cycles / oppositions multiples / stimulation auditive | NON VÉRIFIÉ | — |
| B8 | Logiciel d'input seul (éducateurs, 9 semaines, n = 123) | **RÉFUTÉ** (d = 0,08) | B[7] |
| B9 | Préscolaires (2;0-5;11, 25 études) : preuves les mieux gradées = discrimination phonémique et approches combinées | CONFIRMÉ | B[8] |
| B10 | ECR positifs en préscolaire (n = 30 ; n = 32, d = 0,89 et 1,04) ; aucun n'isole 3;0-3;5 | CONFIRMÉ | B[9][10] |
| B11 | Phonologie expressive : SMD 0,44 ; parents formés ≈ clinicien | CONFIRMÉ | B[11] |
| B12 | Feedback réduit/différé favorable à la rétention (KR vs KP) — principes issus de tâches non verbales, peu testés sur la parole | CONFIRMÉ / NUANCÉ | B[12] |
| B13 | Feedback basse fréquence en apraxie (n = 4) : effets hétérogènes | NUANCÉ | B[13] |
| B14 | Principes d'apprentissage moteur transposables aux troubles phonologiques | NON VÉRIFIÉ | — |
| B15 | Revue des thérapies par ordinateur (Furlong, Erickson & Morris **2017**) : 14 études, qualité modérée à faible | NUANCÉ | B[14] |
| B16 | Thérapeutes virtuels : aucune supériorité établie sur le présentiel | CONFIRMÉ | B[15] |
| B17 | Analyse automatique de la parole d'enfant : 32 articles (2007-2016) ; outils souvent < 80 % d'accord | NUANCÉ | B[16] |
| B18 | Tablette ≈ matériel sur table (ECR, n = 22, orthophoniste) | CONFIRMÉ | B[17] |
| B19 | IA en boucle pour /ɹ/ : 5/5 généralisent (faisabilité) | CONFIRMÉ | B[18] |
| B20 | Biofeedback (9-15 ans, ECR n = 108) : /ɹ/ acquis plus vite qu'en traitement moteur | CONFIRMÉ | B[19] |
| B21 | staRt : gratuit, 9-14 ans ; rien sous 9 ans | NUANCÉ | B[20][21][22] |
| B22 | Implication des parents : tâches hétérogènes, formation rarement décrite | CONFIRMÉ | B[23] |
| B23 | Parent + orthophoniste, oppositions multiples (5 enfants 3;3-5;11) — plan confirmé, résultats non lus | CONFIRMÉ (plan) | B[24] |
| B24 | Interventions langagières menées par les parents : 18 études, effets positifs (langage, pas TSP) | NUANCÉ | B[25] |
| B25 | **3 séances/semaine × 8 semaines > 1/semaine × 24** (même dose) ; 1/semaine ≈ contrôle (n = 54) | CONFIRMÉ | B[26] |
| B26 | Intensité cumulée = dose × fréquence × durée | CONFIRMÉ | B[27] |
| B27 | Hirsh-Pasek 2015 · Meyer 2021 · Radesky 2022 · *joint media engagement* · OMS 2019 · AAP 2016 · commission écrans 2024 · carnet de santé 2025 · 3-6-9-12 · WWC/SCRIBE · I-CVI (Lynn ; Polit & Beck) · Delphi | NON VÉRIFIÉ | — |

**Sources B** (lu = titre/URL/extrait) :
[1] Baker & McLeod (2011), *LSHSS* 42(2), doi:10.1044/0161-1461(2010/09-0075) ·
[2] Weiner (1981), *JSHD* 46(1), doi:10.1044/jshd.4601.97 ·
[3] Storkel (2022), *LSHSS* 53(3), doi:10.1044/2021_LSHSS-21-00105 (copie libre signalée) ·
[4] Williams (2000), *AJSLP* 9(4) ·
[5] Rudolph & Wendt (2014), *J. Commun. Disord.* 47 (PMC3959577) ·
[6] speech-language-therapy.com, *Auditory input…* ·
[7] McLeod et al. (2017), *JSLHR* 60(7), doi:10.1044/2017_JSLHR-S-16-0385 ·
[8] Wren, Harding, Goldbart & Roulstone (2018), *IJLCD* 53(3), doi:10.1111/1460-6984.12371 (e-space.mmu.ac.uk) ·
[9] Almost & Rosenbaum (1998), *DMCN* 40 ·
[10] Siemons-Lühring et al. (2021), *Children* 8 (PMC8700312) ·
[11] Law, Garrett & Nye, Cochrane CD004110 (résumé libre) ·
[12] Maas et al. (2008), *AJSLP* 17, doi:10.1044/1058-0360(2008/025) ·
[13] Maas, Butalla & Farinella (2012), *AJSLP* 21(3) ·
[14] Furlong, Erickson & Morris (2017), *J. Commun. Disord.* 68, doi:10.1016/j.jcomdis.2017.06.007 ·
[15] Chen et al. (2016), *Computer Speech & Language* 37, doi:10.1016/j.csl.2015.08.005 ·
[16] McKechnie et al. (2018), *IJSLP* 20(6), doi:10.1080/17549507.2018.1477991 ·
[17] Jesus, Martinez, Santos, Hall & Joffe (2019), *JSLHR* 62(11), doi:10.1044/2019_JSLHR-S-18-0301 (openaccess.city.ac.uk) ·
[18] Benway & Preston (2024), *AJSLP*, doi:10.1044/2024_AJSLP-23-00448 ·
[19] McAllister et al. (2025), *JSLHR* 69(4), doi:10.1044/2025_JSLHR-24-00909 ·
[20] McAllister Byun (2017), *JSLHR* 60(5) ·
[21] McAllister Byun et al. (2017), *JSLHR* (PMC5544407) ·
[22] Peterson et al. (2022), *LSHSS* (PMC9549922) ·
[23] Sugden, Baker, Munro & Williams (2016), *IJLCD* 51(6), doi:10.1111/1460-6984.12247 ·
[24] Sugden et al. (2020), *AJSLP* 29(1) (strathprints) ·
[25] Roberts & Kaiser (2011), *AJSLP* 20(3) ·
[26] Allen (2013), *JSLHR* 56(3), doi:10.1044/1092-4388(2012/11-0076) ·
[27] Warren, Fey & Yoder (2007), *MRDD Res. Rev.* 13.

---

## C · Parole d'enfant, reconnaissance vocale, acoustique

| Id | Affirmation | Verdict | Sources |
|---|---|---|---|
| C1 | ASR moins performante chez l'enfant (revue, 76 articles) ; Whisper-large-v3 sans adaptation : WER 19,9 % (OGI, K-10) et 12,6 % (MyST) ; CSLU scripté : 6-10 × LibriSpeech | CONFIRMÉ (≥ 5 ans) | C[1][2][5] |
| C2 | Maternelle nettement plus difficile ; 3-5 ans en classe : WER 57,8 % | NUANCÉ | C[4][6] |
| C3 | Formants plus élevés, variabilité inter- et intra-locuteur plus forte | CONFIRMÉ | C[3][27] |
| C4 | « Lee et al. 1999 couvre les 3-5 ans » | **RÉFUTÉ** (5-17 ans) | C[3] |
| C5 | Données d'enfants francophones : Lalilo (5-8 ans, interne), PAIDIALOGOS (7-16) ; aucun benchmark ASR FR 3-5 ans | NUANCÉ | C[7][8][24] |
| C6 | L'ASR généraliste « corrige » vers des mots réels et efface les disfluences | CONFIRMÉ | C[5][12][14] |
| C7 | Méprises de lecture (6-13 ans) : PER HuBERT 23,1 % vs 6,3 % adulte ; erreurs sur fricatives/affriquées chez les plus jeunes | CONFIRMÉ | C[13][15] |
| C8 | GOP corrélé aux juges si assez de parole ; Tabby Talks ; revue McKechnie (32 articles) | CONFIRMÉ | C[9][10][11] |
| C9 | de Jong & Wempe : pics d'intensité entre creux, pics non voisés rejetés ; seuil = quantile 0,99 − 25 dB ; creux > 2 dB ; voisement 30-450 Hz | CONFIRMÉ | C[16][17] |
| C10 | Méthode applicable aux enfants | NON VÉRIFIÉ (plafond 450 Hz trop bas ; Praat 50-800 Hz) | C[17][19] |
| C11 | Mermelstein (1975) : sonie 500-4 000 Hz, enveloppe convexe | CONFIRMÉ | C[18] |
| C12 | **Adultes** : pic /s/ 6 839 Hz, /ʃ/ 3 820 Hz ; centroïdes 6 133 et 4 229 Hz ; durée 178 ms ; −10 et −9 dB vs voyelle | CONFIRMÉ | C[20] |
| C13 | Valeurs en Hz des sibilantes chez les 3-5 ans | NON VÉRIFIÉ | C[25] |
| C14 | Énergie de /s/ au-delà de 7-8 kHz, mesurable jusqu'à 11-15 kHz ; un signal à 16 kHz tronque /s/ | CONFIRMÉ (adultes) | C[22] |
| C15 | Friction minimale pour identifier : /ʃ/ 30 ms, /s/ 50 ms ; [s] final allongé de 136 ms | CONFIRMÉ (adultes) | C[21][23] |
| C16 | Contraste couvert : l'enfant produit une différence que l'adulte n'entend pas | CONFIRMÉ | C[26][27] |
| C17 | « MyST, CSLU, CMU Kids couvrent les 3-5 ans et sont libres » | **RÉFUTÉ** ; TalkBank en CC BY-NC-SA 3.0 | C[28]–[32] |
| C18 | La réduction de bruit dégrade les fricatives | NON VÉRIFIÉ | C[35] |
| C19 | iOS : *voice processing* = AGC + annulation d'écho ; `.measurement` minimise le traitement ; ASR locale « moins précise » ; `contextualStrings` biaise | CONFIRMÉ | C[33] |
| C20 | Durées de fin d'énoncé propres aux enfants | NON VÉRIFIÉ (défauts Silero/faster-whisper seulement) | C[34] |
| C21 | Obligations COPPA/RGPD, consentement explicite, indicateur d'enregistrement | CONFIRMÉ | C[29][36] |

**Sources C** :
[1] Bhardwaj et al. (2022), *Applied Sciences* 12(9):4419, doi:10.3390/app12094419 (libre) ·
[2] Fan, Balaji Shankar & Alwan (2024), Interspeech, arXiv 2406.10507 ·
[3] Lee, Potamianos & Narayanan (1999), *JASA* 105(3), doi:10.1121/1.426686 ·
[4] Yeung & Alwan (2018), Interspeech, doi:10.21437/Interspeech.2018-2297 ·
[5] Attia, Liu et al. (2024), *Kid-Whisper*, arXiv 2309.07927 ·
[6] *Automated Analysis of Naturalistic Recordings in Early Childhood* (2025), arXiv 2509.18235 ·
[7] Gelin et al. (2021), *Speech Communication*, arXiv 2103.02899 ·
[8] LREC 2008, aclanthology.org/L08-1511 ·
[9] Witt & Young (2000), *Speech Communication* 30(2-3) ·
[10] Shahin et al. (2015), *Speech Communication* 70 ·
[11] McKechnie et al. (2018), cf. B[16] ·
[12] Ahn et al. (2024), *Clin. Ling. & Phon.* 39(10), arXiv 2403.08187 ·
[13] Gao et al. (2024), Interspeech, arXiv 2406.07060 ·
[14] Smith et al. (2025), Interspeech, arXiv 2505.23627 ·
[15] Horii et al. (2025), Interspeech (isca-archive) ·
[16] de Jong & Wempe (2009), *Behav. Res. Methods* 41(2), doi:10.3758/BRM.41.2.385 ·
[17] Script Praat « Syllable Nuclei » v2 (GPL-3), lu en entier ·
[18] Mermelstein (1975), *JASA* 58(4) ·
[19] Manuel Praat, *Intro 4.2* ·
[20] Jongman, Wayland & Wong (2000), *JASA* 108(3) ·
[21] Jongman (1989), *JASA* 85(4) ·
[22] Shadle, Chen, Koenig & Preston (2023), *JASA* 154(3), doi:10.1121/10.0021075 ·
[23] Oller (1973), *JASA* 54(5) ·
[24] Corpus français CHILDES/PhonBank (liste) ·
[25] Li, Edwards & Beckman (2009), *J. Phonetics* 37 ; Holliday et al. (2015), *JSLHR* 58 (références seules) ·
[26] Munson et al. (2010), *Clin. Ling. & Phon.* ·
[27] Beckman, Plummer, Munson & Reidy (2017), *Computer Speech & Language* ·
[28] Licence TalkBank CC BY-NC-SA 3.0 ·
[29] Pradhan, Cole & Ward (2024), corpus MyST, arXiv 2309.13347 ·
[30] Fiches LDC : CSLU Kids LDC2007S18, CMU Kids LDC97S63 ·
[31] SpeechOcean762 ·
[32] arXiv 2406.03235 ·
[33] Doc Apple AVAudioSession/Speech ·
[34] silero-vad, faster-whisper (code) ·
[35] Thèse UBC (titre seul) ·
[36] App Review Guidelines.

---

## D · Plateforme Apple (lue dans la documentation officielle, septembre 2026)

| Id | Fait | Verdict |
|---|---|---|
| D1a | `SFSpeechRecognizer.supportsOnDeviceRecognition`, `requiresOnDeviceRecognition` (iOS 13), non déprécié ; « on-device requests won't be as accurate » | CONFIRMÉ |
| D1b | fr-FR et en-US disponibles en local | NON VÉRIFIÉ — à tester à l'exécution |
| D1c | `requestAuthorization` + `NSSpeechRecognitionUsageDescription` requis même en local | CONFIRMÉ |
| D1d | Quotas / 1 min par tâche : limites serveur, pas locales | NUANCÉ |
| D2a | `SpeechAnalyzer`, `SpeechTranscriber`, `DictationTranscriber`, `SpeechDetector`, `AssetInventory` : iOS 26 | CONFIRMÉ |
| D2b | Noms WWDC25 (`.offlineTranscription`…) | RÉFUTÉ — `.transcription`, `.progressiveTranscription`, `reserve(locale:)`, `release(reservedLocale:)` |
| D2c | fr-FR supporté par `SpeechTranscriber` | NON VÉRIFIÉ — `supportedLocale(equivalentTo:)` |
| D2d | `SpeechAnalyzer` exige l'autorisation « reconnaissance vocale » | RÉFUTÉ — micro seulement |
| D2e | Exigences matérielles iPad | NUANCÉ — tester `SpeechTranscriber.isAvailable` |
| D2f | Modèles **téléchargés** par le système, partagés, désinscriptibles | CONFIRMÉ |
| D2g | iOS 27 : `CaptureInputSequenceProvider`, `AnalyzerInputConverter` | CONFIRMÉ |
| D3a | `SFCustomLanguageModelData`, `CustomPronunciation(grapheme:phonemes:)` (X-SAMPA), `customizedLanguageModel` : iOS 17 ; sans `requiresOnDeviceRecognition`, pas de personnalisation | CONFIRMÉ |
| D3b | `prepareCustomLanguageModel(for:clientIdentifier:configuration:)` déprécié en 26 → `prepareCustomLanguageModel(for:configuration:)` | NUANCÉ |
| D3c | Locales des prononciations personnalisées : `supportedPhonemes(locale:)` | NON VÉRIFIÉ (liste) |
| D3d | `DictationTranscriber.ContentHint` : `.customizedLanguage`, `.atypicalSpeech`, `.farField`, `.shortForm` | CONFIRMÉ |
| D4a | `AVAudioSession.Mode.measurement` minimise le traitement système | CONFIRMÉ |
| D4b | `setVoiceProcessingEnabled(_:)` : AEC, réduction de bruit, AGC — fausse la mesure | CONFIRMÉ |
| D4c | `installTap` : taille non garantie, hors thread principal ; déprécié en 27 → `installAudioTap(…tapProvider:)` | CONFIRMÉ (RÉFUTE « taille exacte ») |
| D4d | Micros iPad nativement à 48 kHz | NON VÉRIFIÉ — lire `sampleRate` |
| D5 | `vDSP.FFT` (iOS 13), `vDSP.DiscreteFourierTransform` (iOS 15), `vDSP.DFT` déprécié | CONFIRMÉ |
| D6a | Pas d'haptique sur l'iPad lui-même ; Apple Pencil Pro (et certains trackpads) sur iPad compatibles | CONFIRMÉ |
| D6b | `CHHapticEngine.capabilitiesForHardware().supportsHaptics` faux sur iPad | CONFIRMÉ (déduit) |
| D6c | `UICanvasFeedbackGenerator` (17.5) : `alignmentOccurred(at:)`, `pathCompleted(at:)` ; « Don't check the device type » | CONFIRMÉ (+ vérifié par nous) |
| D6d | iPad compatibles Pencil Pro : mini A17 Pro, Air M2-M4, Pro M4-M5 | NUANCÉ |
| D7a | Encres `.monoline`, `.fountainPen`, `.watercolor`, `.crayon` (17) ; `.reed` (26) | CONFIRMÉ |
| D7b | `drawingPolicy = .anyInput` (14), `drawingGestureRecognizer` (13), `PKDrawing.image(from:scale:)` (13) | CONFIRMÉ |
| D7c | iPadOS 27 : `PKStrokeRecognizer`, `PKStroke.id`, sélection | CONFIRMÉ |
| D7d | `PKStroke(ink:path:transform:mask:)` et `mask` (iOS 14) — base du « pochoir » | CONFIRMÉ (vérifié par nous) |
| D7e | `VNDocumentCameraViewController` (iOS 13), `VNDetectDocumentSegmentationRequest` (iOS 15) — mode papier | CONFIRMÉ (vérifié par nous) |
| D8a | SceneKit déprécié en 26 (« use RealityKit ») | CONFIRMÉ |
| D8b | SpriteKit, `SKWarpGeometryGrid` (iOS 10) supportés | CONFIRMÉ |
| D9 | `ModelConfiguration(cloudKitDatabase: .none)` désactive la synchro ; `.automatic` synchronise si entitlement iCloud | CONFIRMÉ |
| D10a | `isGuidedAccessEnabled`, notification, `UIGuidedAccessRestrictionDelegate`, `guidedAccessRestrictionState(forIdentifier:)` | CONFIRMÉ |
| D10b | `requestGuidedAccessSession` : appareils supervisés MDM uniquement | CONFIRMÉ |
| D11a | Règles 1.3 / 5.1.4 : contrôle parental ≠ consentement ; pas d'analytics/pub tiers ; politique de confidentialité ; tranches 5-, 6-8, 9-11 ; invite vocale pour les non-lecteurs | CONFIRMÉ |
| D11b | `PrivacyInfo.xcprivacy` : UserDefaults, raison `CA92.1` (depuis le 1ᵉʳ mai 2024) | CONFIRMÉ |
| D11c | Classifications 4+, 9+, 13+, 16+, 18+ ; `AgeRangeService` (Declared Age Range, 26) | CONFIRMÉ |
| D12 | Nouveautés 27 : `installAudioTap`, Speech, PencilKit ; cycle de vie par scènes obligatoire en UIKit | CONFIRMÉ |

**Sources D** (lues) : documentation Apple Speech (SFSpeechRecognizer, SpeechAnalyzer, SFSpeechLanguageModel,
mises à jour de juin 2026), WWDC19-256, WWDC23-10101, WWDC25-277, WWDC25-288, AVFAudio (AVAudioSession.Mode,
AVAudioNode, AVAudioInputNode), Accelerate (vDSP.FFT), Core Haptics, UIKit (UICanvasFeedbackGenerator,
UIGuidedAccessRestrictionDelegate), HIG *Playing haptics*, PencilKit (PKStroke, PKCanvasView, mises à jour
2026), VisionKit, Vision, SpriteKit, SwiftData (ModelConfiguration), App Review Guidelines, page *Kids apps*,
NSPrivacyAccessedAPITypeReasons, Declared Age Range, forum Apple (fil 790108) — developer.apple.com.

---

## E · Réglementation, éthique, conformité (analyse documentaire, pas un avis juridique)

| Id | Affirmation | Verdict | Sources |
|---|---|---|---|
| E1 | COPPA modifiée : vote 16/01/2025 (5-0) ; *Federal Register* 22/04/2025 ; en vigueur 23/06/2025 ; conformité 22/04/2026 | CONFIRMÉ | E[1][2] |
| E2 | Audio contenant la voix d'un enfant = *personal information* (§ 312.2) ; empreintes vocales ajoutées en 2025 | CONFIRMÉ | E[3] |
| E3 | Politique FTC 2017 (audio substitut de texte, détruit) — s'applique mal à une évaluation de prononciation | CONFIRMÉ | E[4][3] |
| E4 | Traitement 100 % sur l'appareil, rien de transmis ⇒ pas de « collecte » (FAQ FTC ; Apple idem) | CONFIRMÉ (réserve) | E[5][6] |
| E5 | Art. 45 loi Informatique et Libertés : consentement seul dès 15 ans | CONFIRMÉ | E[7] |
| E6 | CNIL, 8 recommandations pour les mineurs (juin 2021) | CONFIRMÉ | E[8] |
| E7 | Traitement local ⇒ éditeur non responsable de traitement | NUANCÉ (défendable, pas acquis) | E[9][10] |
| E8 | Accès micro via le système hors art. 5(3) ePrivacy si rien ne sort | CONFIRMÉ | E[11] |
| E9 | Art. 25 RGPD oblige le responsable ; considérant 78 « encourage » les éditeurs | CONFIRMÉ | E[12] |
| E10 | Voix = donnée biométrique | **RÉFUTÉ en principe** — mais déduire un trouble du langage = donnée de santé probable (CNIL) | E[12][13] |
| E11 | MDR art. 2(1) : destination déduite de l'étiquetage et de la promotion (art. 2(12)) | CONFIRMÉ | E[14] |
| E12 | Règle 11 : aide aux décisions diagnostiques/thérapeutiques ⇒ classe IIa au moins | CONFIRMÉ | E[15] |
| E13 | MDCG 2019-11 rév. 1 publiée le 17/06/2025 | CONFIRMÉ | E[16] |
| E14 | App qui « évalue la prononciation » = dispositif médical ? Non si finalité ludique sans allégation ; oui si elle promet de dépister/rééduquer | NUANCÉ | E[14][15][16] |
| E15 | Poppins marqué CE (dyslexie) | NON VÉRIFIÉ | E[17] |
| E16 | FDA *General Wellness* révisée (06/01/2026) : nommer un trouble fait sortir du « wellness » | CONFIRMÉ (secondaire) | E[18] |
| E17 | Référentiel HAS applis/objets connectés en santé (2016-2017) | NUANCÉ | E[19] |
| E18 | PECAN (décret 2023-232) | NUANCÉ — sans objet hors DM | E[20] |
| E19 | AI Act annexe III 3(b) : évaluation des acquis **en établissement** ⇒ usage familial hors champ ; risque si vendu aux écoles | CONFIRMÉ | E[21] |
| E20 | Art. 5(1)(b) (vulnérabilités dues à l'âge) applicable depuis le 02/02/2025 ; application générale 02/08/2026 | CONFIRMÉ | E[21] |
| E21 | « Digital Omnibus » : règlement (UE) 2026/1744 — reports du haut risque (annexe III → 02/12/2027) | CONFIRMÉ (secondaire) | E[22] |
| E22 | Si DM classe IIa+, l'IA devient à haut risque (art. 6(1)) | CONFIRMÉ | E[21][14] |
| E23 | CSP : L4341-1 (champ de l'orthophonie), L4344-4-2 (exercice illégal), L4344-5 (usurpation de titre) | CONFIRMÉ (copie 08/2024) | E[23] |
| E24 | Loi Jardé : 3 catégories ; cat. 2-3 : avis de CPP ; mineurs cat. 1-2 si impossible chez l'adulte | CONFIRMÉ | E[23] |
| E25 | Hors Jardé : sciences humaines et sociales en santé (R1121-1 II) ; valider la détection d'un trouble ⇒ probablement Jardé (cat. 3 si observationnelle) | CONFIRMÉ | E[23] |
| E26 | CNIL MR-001, MR-003, MR-004 ; art. 73 loi I&L | CONFIRMÉ | E[24][7] |
| E27 | Acte européen sur l'accessibilité : liste fermée de services, micro-entreprises exemptées ⇒ app éducative gratuite non visée | CONFIRMÉ | E[25] |
| E28 | WCAG 2.2 (12/12/2024) comme référentiel volontaire | NUANCÉ | E[26] |
| E29 | Apple 1.3 / 5.1.4 / 5.1.3 : contrôle parental, rien vers des tiers, politique de confidentialité, recherche en santé = consentement parental + comité d'éthique | CONFIRMÉ | E[27][28] |
| E30 | Speech : réseau par défaut ; `requiresOnDeviceRecognition = true` garde l'audio local | CONFIRMÉ | E[29] |

**Sources E** : [1] FTC, communiqué 16/01/2025 · [2] *Federal Register* 2025-05904 (22/04/2025) ·
[3] 16 CFR 312 (eCFR, copie XML sur GitHub) · [4] FTC, politique « voice recordings » 23/10/2017 ·
[5] FTC, *Complying with COPPA: FAQ* · [6] Apple, *App Privacy Details* (lu) · [7] Loi 78-17, art. 45 et 73
(Légifrance, copie GitHub) · [8] CNIL, 8 recommandations (06/2021) · [9] EDPB, lignes directrices 07/2020 ·
[10] RGPD, considérant 18 · [11] EDPB, lignes directrices 2/2023 (art. 5(3) ePrivacy) · [12] RGPD, art. 4(14),
9(1), 25, considérant 78 · [13] EDPB 02/2021 (assistants vocaux) ; CNIL, « Qu'est-ce qu'une donnée de santé ? » ·
[14] Règlement (UE) 2017/745, art. 2 · [15] Règle 11 (MDCG 2019-11) · [16] MDCG 2019-11 rév. 1 (17/06/2025) ·
[17] source secondaire (Poppins Clinical) · [18] FDA *General Wellness* (06/01/2026) · [19] HAS, référentiel
applis santé (version anglaise 03/2017) · [20] PECAN (secondaire) · [21] Règlement (UE) 2024/1689 ·
[22] Règlement (UE) 2026/1744 (sources secondaires concordantes) · [23] Code de la santé publique (copie 08/2024) ·
[24] CNIL, méthodologies de référence · [25] Directive (UE) 2019/882 · [26] W3C WCAG 2.2 ·
[27] App Review Guidelines (lu) · [28] Apple, *Kids apps* (lu) · [29] Doc Apple Speech (lu).

**Points à faire valider par un juriste :** statut RGPD de l'éditeur et mentions légales ;
qualification DM (UE) et FDA de **toutes** les allégations (fiche App Store, site, captures) — ANSM en cas
de doute ; disponibilité de la marque (INPI, EUIPO, USPTO) ; COPPA pour une app sans aucune connexion ;
cadre du protocole de validation (Jardé ou SHS, CPP, MR, AIPD) ; AI Act (système d'IA ? vente aux écoles ?).

---

## F · Marché, coloriage, graphomotricité, co-conception

| Id | Affirmation | Verdict | Sources |
|---|---|---|---|
| F1 | Speech Blubs : abonnement, 1-8 ans, modélisation vidéo par des pairs | NUANCÉ (prix variables) | F[1] |
| F2 | Speech Blubs a une version **française** (2020), vise aussi les bilingues | CONFIRMÉ | F[1] |
| F3 | « Validé par une étude UCLA publiée par l'ASHA » (Speech Blubs) | NON VÉRIFIÉ (marketing) | F[1] |
| F4 | Otsimo : ASR + ML, anglais seulement ; avis mitigés | CONFIRMÉ | F[4] |
| F5 | Articulation Station : passée à l'abonnement (Hive) | CONFIRMÉ | F[2] |
| F6 | Plusieurs apps : enregistrement-réécoute jugé par l'adulte, sans ASR revendiquée | NUANCÉ | F[2][3][11] |
| F7 | Apraxia World : évaluation automatique ; 10 enfants à domicile ; gains ; **parents trop indulgents** quand ils notent | CONFIRMÉ | F[5] |
| F8 | Apraxia World → SayBananas! (Say66) | CONFIRMÉ | F[6] |
| F9 | SpeechPrompts : pilote JADD 2016 (5-19 ans) | CONFIRMÉ | F[7] |
| F10 | staRt : gratuit, biofeedback du /r/, 9-14 ans | NUANCÉ | F[8] |
| F11 | Tiga Talk récompense la participation, pas l'exactitude | CONFIRMÉ | F[9] |
| F12 | « Aucune app d'articulation bilingue FR/EN » | **RÉFUTÉ** (Speech Blubs FR, OrthoPicto) | F[1][10] |
| F13 | GraphoGame Français : gratuit, sans pub ni achat ; efficacité : mémoire 2016 | CONFIRMÉ / NUANCÉ | F[14] |
| F14 | Lalilo : ASR sur la lecture à voix haute, GS-CE1, gratuit enseignants | CONFIRMÉ | F[15] |
| F15 | Poppins (7-11 ans) : remboursable sur prescription (2026) ; ECR n = 154 (éditeur) | CONFIRMÉ / NUANCÉ | F[16] |
| F16 | Quiver, Crayola Color Alive : coloriage papier → animation 3D en réalité augmentée | CONFIRMÉ | F[18][19] |
| F17 | Remplissage automatique fréquent (« Magic Color ») | CONFIRMÉ | F[20][22] |
| F18 | Disney Research (Magnenat et al. 2015) : le personnage 3D prend les couleurs du coloriage | CONFIRMÉ | F[23] |
| F19 | Animated Drawings (Meta, ACM TOG 2023) : MIT, archivé 03/09/2025, humanoïdes, Python | CONFIRMÉ (README lu) | F[24] |
| F20 | Pas d'haptique au doigt sur iPad ; Apple Pencil Pro seulement | CONFIRMÉ | F[25][26] |
| F21 | Reconnaissance locale « won't be as accurate » | CONFIRMÉ | F[27] |
| F22 | Apple : dessins, photos, vidéos d'un mineur = données personnelles | CONFIRMÉ | F[28] |
| F23 | Prise : palmaire (1-2) → digitale (2-3) → tripode statique (3-4) → dynamique (4-6) | NUANCÉ (secondaire) | F[29][30] |
| F24 | Âges Beery VMI (cercle, croix, carré, triangle) | NON VÉRIFIÉ | F[31] |
| F25 | Colorier dans les lignes : entre 3 et 5 ans, attendu vers 6 ans | NUANCÉ | F[32] |
| F26 | Programmes de maternelle (graphisme, geste graphique) | NON VÉRIFIÉ | — |
| F27 | Tablette vs papier (Gerth 2016, Alamargot & Morin 2015), doigt vs stylet | NON VÉRIFIÉ | — |
| F28 | Coloriage et motricité fine ; pochoirs ; étayage (Wood, Bruner & Ross 1976) | NON VÉRIFIÉ | F[21] |
| F29 | Cooperative Inquiry, Fun Toolkit, *This or That* | NON VÉRIFIÉ | — |

**Sources F** : [1] Speech Blubs (FAQ, blog) · [2] Little Bee Speech (Hive) · [3] Speech Sounds on Cue ·
[4] Otsimo · [5] Hair, Monroe et al. (2018) IDC doi:10.1145/3202185.3202733 ; (2021) ACM TACCESS
doi:10.1145/3433607 · [6] Say66 ; SayBananas! IJSLP 25(3) 2023 · [7] Simmons, Paul & Shic (2016) JADD 46(1) ·
[8] NYU Steinhardt (staRt) · [9] Tactica (Tiga Talk) · [10] Symbolicone (OrthoPicto) ·
[11] exercices-orthophonie.fr · [12] OrthoPhono (App Store) · [13] Récréalire (Planète des Alphas) ·
[14] LPC AMU/CNRS (GraphoGame, ANR-13-APPR-0003) · [15] Primàbord-Eduscol (Lalilo) · [16] Poppins ·
[17] Learn&Go (Kaligo) · [18] QuiverVision · [19] Crayola Color Alive (2014-2015) · [20] StoryToys (Disney
Coloring World) · [21] Sago Mini (Crayon Club) · [22] Kid Doodle · [23] Magnenat et al. (2015) IEEE TVCG 21 ·
[24] Smith, Zheng, Li, Jain & Hodgins (2023) ACM TOG 42(3), doi:10.1145/3592788 (github.com/facebookresearch/AnimatedDrawings) ·
[25] Apple, UICanvasFeedbackGenerator · [26] MacRumors (07/05/2024) · [27] Apple, requiresOnDeviceRecognition ·
[28] App Review Guidelines · [29] Growing Hands-On Kids et al. (citent Schneck & Henderson 1990) ·
[30] Rosenbloom & Horton (1971) DMCN 13 · [31] WPS (Beery VMI 6ᵉ éd.) · [32] cabinets d'ergothérapie.

---

## 📚 Investigation dans LibraryBrain

LibraryBrain (RAG local, 25 000+ documents) tourne **sur le Mac** (`127.0.0.1:8765`, base sur disque
externe) : il n'est pas joignable depuis la session cloud qui a produit ce document. Le relais est
donc organisé en quatre gestes, à faire en local :

1. **Enrichir le corpus** avec les sources en accès libre de cette passe : manifeste
   [`eveil/librarybrain/sources.json`](../eveil/librarybrain/sources.json) et script
   [`recuperer_sources.py`](../eveil/librarybrain/recuperer_sources.py) (stdlib, n'accepte que de vrais
   PDF, ne retélécharge jamais) → dépôt dans un dossier surveillé par l'indexeur (ex. `Santé/Orthophonie/`).
   Le canal **médecine** existant (`fetch_medical_fr.py --source has`) couvre déjà les recommandations HAS.
2. **Veille arXiv** : thèmes proposés pour `scripts/arxiv_topics.txt` dans
   [`eveil/librarybrain/arxiv_topics.eveil.txt`](../eveil/librarybrain/arxiv_topics.eveil.txt).
3. **Questions à poser** (pages `/ask` et `/consensus`) pour fermer les NON VÉRIFIÉ :
   [`eveil/librarybrain/questions.md`](../eveil/librarybrain/questions.md).
4. **Comparer les deux passes** selon un protocole figé d'avance
   ([`eveil/librarybrain/COMPARAISON.md`](../eveil/librarybrain/COMPARAISON.md)) : aux 18 questions
   s'ajoutent 15 **témoins** déjà tranchés ici (confirmés, nuancés et réfutés mêlés), posés en deux
   passes — bibliothèque telle quelle, puis avec les PDF ci-dessus — et codés à l'aveugle. Ce
   document n'est **pas** indexé avant la fin (pas de `--avec-notes`). Rapport attendu :
   `docs/EVEIL-SOURCES-LIBRARYBRAIN.md`.

**Fait le 25/09/2026** : trois passes (P0, contrôle P0b, P1 avec 17 des 28 sources), codage à l'aveugle,
rapport [`EVEIL-SOURCES-LIBRARYBRAIN.md`](EVEIL-SOURCES-LIBRARYBRAIN.md) — A22 fermé, aucune
contradiction avec les verdicts ci-dessus, 17 sources nouvelles, liste de sources à acquérir.
