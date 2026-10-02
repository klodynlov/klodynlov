# KaribTruck — Note de cadrage : une app iPad pour piloter le food truck

> Cadrage d'un projet **KaribTruck** : app iPad de gestion pour un food truck de cuisine
> caribéenne (`karibtruck.fr`), en activité depuis ~6 mois. Objectif : sécuriser l'hygiène
> (HACCP / contrôle sanitaire), l'exploitation, et clarifier l'obligation « caisse ».
>
> Ce document est une **analyse de faisabilité et une reco d'architecture**, pas encore du
> code. Il tranche d'abord une question juridique piégeuse avant de proposer un périmètre.
> Vérifié sur sources à jour (août 2026). Rien ici ne vaut conseil d'un expert-comptable ou
> d'un juriste : les faits sont sourcés, les décisions restent à valider avec votre comptable.

---

## 0. La réponse en 30 secondes

Oui, une app iPad a du sens — **mais pas pour tout, et surtout pas pour la caisse.**

1. **Ne construisez pas votre caisse vous-même.** L'encaissement est un domaine
   **réglementé** (conditions techniques strictes + responsabilité de l'éditeur). Prenez un
   **logiciel de caisse du marché** qui vous fournit une **attestation** ou un **certificat**.
2. **Construisez l'app maison là où c'est libre et à forte valeur : l'hygiène / HACCP.**
   Relevés de température, traçabilité, DLC, nettoyage, checklists, non-conformités. Aucune
   certification requise — il faut juste des enregistrements **fiables, horodatés,
   inviolables et exportables** à présenter en cas de contrôle. C'est exactement là que la
   rigueur « pro » (tests, audit, journal inviolable) paie.
3. **La panique du « 1er septembre » est retombée.** L'échéance qui devait durcir les règles
   de caisse **au 1er septembre 2026 a été annulée** par la loi de finances 2026 (voir §2).
   L'obligation de fond, elle, demeure — sauf si vous êtes en franchise en base de TVA.

**Architecture cible : hybride.** Caisse conforme du commerce (encaissement) **+** app iPad
maison « KaribTruck » (hygiène + exploitation), les deux communiquant par export/API.

---

## 1. Le besoin, décodé

Vous avez formulé quatre choses ; elles ne relèvent pas du même régime juridique et il faut
les séparer, sinon on construit le mauvais objet :

| Besoin exprimé | Nature | Peut-on le coder soi-même ? |
|---|---|---|
| **HACCP / contrôle d'hygiène** | Obligation de **moyens et de preuve** (tenir des registres) | **Oui, pleinement.** Aucune certification. Sweet spot. |
| **Caisse (suivi, obligation loi)** | Obligation de **conformité technique** d'un logiciel | **Non, en pratique.** Responsabilité d'éditeur + 4 conditions techniques. |
| **« Tout gérer » (stocks, marchés, ventes)** | Exploitation, libre | **Oui.** Valeur métier, zéro contrainte légale. |
| **« App pro » (sécurité, test, audit, harnais)** | Exigence de qualité | **Oui** — c'est la manière de faire, pas un module. |

La clé du cadrage : **la caisse et l'hygiène sont deux mondes réglementaires opposés.** L'un
est verrouillé (on achète), l'autre est ouvert (on construit). Les mélanger dans « une app
qui gère tout » est l'erreur classique qui coûte cher.

---

## 2. Volet CAISSE — la vérité juridique (le piège à éviter)

### 2.1 L'obligation de fond (inchangée depuis 2018)

Si vous **encaissez des paiements de clients particuliers** au moyen d'un logiciel/système de
caisse, ce logiciel doit satisfaire **4 conditions** (dites « ISCA », art. 286-I-3°bis du
CGI) : **Inaltérabilité, Sécurisation, Conservation, Archivage** des données. Concrètement :
clôtures journalière / mensuelle / annuelle, cumuls « grand total » perpétuels, données
inaltérables et chaînées/signées, archivage exportable pour l'administration.

**Sanction** : **7 500 € par logiciel non conforme**, avec obligation de régularisation sous
**60 jours** (et rappel possible en cas de contrôle). Ce n'est pas symbolique.

### 2.2 La double bascule 2025 → 2026 (l'origine de votre « 1er septembre »)

La règle a changé **deux fois de sens** en 18 mois. C'est ce qui a créé la confusion :

```
2018 ────────────► 14 fév. 2025 ──────────► (prévu) 1er sept. 2026 ──────► 21 fév. 2026
 Attestation        LF 2025 art. 43 :         Fin du sursis :               LF 2026 art. 125 :
 éditeur OU          SUPPRESSION de            SEUL le certificat            RÉTABLISSEMENT de
 certificat OK       l'auto-attestation ;      d'organisme accrédité        l'attestation éditeur.
                     certificat accrédité      aurait été admis.            → l'échéance du
                     seul admis (sursis        (LNE ou Infocert)            1er sept. 2026 est
                     éditeurs → 31/08/2026)                                  ANNULÉE.
```

- **Loi de finances 2025 (art. 43, 14 fév. 2025)** : supprime l'attestation individuelle de
  l'éditeur ; **seul le certificat d'un organisme accrédité** (LNE, Infocert) faisait foi. Un
  sursis avait été laissé aux éditeurs jusqu'au **31 août 2026** pour se faire certifier — d'où
  la fameuse échéance du **1er septembre 2026** que vous avez entendue.
- **Loi de finances 2026 (art. 125, applicable depuis le 21 fév. 2026)** : **rétablit
  l'attestation individuelle de l'éditeur**. On peut de nouveau prouver la conformité par
  **attestation éditeur *ou* certificat d'organisme accrédité**. **L'échéance couperet du
  1er septembre 2026 est donc neutralisée.**

**Ce que ça veut dire pour vous, aujourd'hui :** pas de mur au 1er septembre. Mais
l'obligation de fond (§2.1) reste. Le bon réflexe : **exiger de votre éditeur de caisse son
attestation (ou certificat) en cours de validité**, et la conserver — c'est ce document que
l'inspecteur vous demandera, pas le code.

### 2.3 La dispense qui vous concerne peut-être : la franchise en base de TVA

**Point décisif, à valider avec votre comptable.** Sont **dispensés** de l'obligation de
caisse sécurisée les assujettis **en franchise en base de TVA** (ils ne collectent pas de
TVA), ainsi que ceux ne faisant que du B2B ou des opérations exonérées.

- Une **micro-entreprise en franchise en base** de TVA n'est **pas** soumise à l'obligation
  de logiciel de caisse certifié.
- **Mais** : cette dispense saute dès que vous **dépassez les seuils** de franchise (pour la
  vente à emporter, ordre de grandeur ~85 000 € de CA, seuil majoré ~93 500 € — **à
  confirmer pour l'année en cours**, ces montants ont bougé et un abaissement à 25 000 € a
  été discuté puis suspendu). À 6 mois d'activité et en croissance, **c'est un seuil qu'un
  food truck peut franchir** ; il faut donc anticiper.

> **Action n°1 (avant toute app)** : demandez à votre comptable votre **régime de TVA exact**
> et votre **projection de CA**. Réponse binaire :
> - **Franchise en base** → caisse certifiée non obligatoire (mais un outil de caisse propre
>   reste utile ; et vous devez tout de même émettre notes/factures et tenir un livre de
>   recettes).
> - **Assujetti à la TVA** (ou bientôt) → **caisse conforme obligatoire** : on prend un
>   logiciel du marché avec attestation/certificat.

### 2.4 Conséquence : pourquoi vous **ne devez pas** coder votre caisse

Même si l'« auto-certification » est de nouveau permise, **« auto »** = c'est **l'éditeur**
qui s'atteste lui-même. Si vous développez votre propre app de caisse, **vous devenez
l'éditeur** : vous engagez votre responsabilité pénale/fiscale et vous devez **réellement**
implémenter et prouver les 4 conditions ISCA (inaltérabilité forte, clôtures, cumuls
perpétuels, chaînage/signature, format d'archivage opposable). Techniquement faisable — c'est
d'ailleurs la même famille que le **journal append-only chaîné SHA-256** déjà présent dans ce
dépôt (EdgeSense, micro:bit) — mais **c'est un produit à part entière, un risque juridique, et
ça n'apporte aucune valeur différenciante** face à un food truck. Mauvais pari.

**Reco : achetez la caisse. Choisissez-la sur 5 critères :**
1. **Attestation/certificat** fournis, à jour, nominatifs (exigez le PDF avant d'acheter).
2. **Natif iPad** et **fonctionne hors-ligne** (un food truck a une connexion capricieuse).
3. **Export comptable** propre (FEC/CSV) pour votre comptable.
4. **TPE intégré / paiement** (sans-contact) adapté à la vente rapide.
5. **Coût mensuel** raisonnable et sans engagement piégeux.

Familles connues côté iPad (à vérifier : **exiger l'attestation/certificat**, ne rien
présumer) : SumUp, Zettle (PayPal), Square, L'Addition, Cashpad, Tiller, Zelty, Innovorder…
On comparera 3 candidats concrets une fois votre régime TVA confirmé.

*(À noter : depuis le 1er août 2023, l'impression systématique du ticket de caisse est
supprimée — le ticket n'est imprimé que sur demande du client. Une caisse récente gère ça.)*

---

## 3. Volet HYGIÈNE / HACCP — là où l'app maison gagne vraiment

Ici, **aucune certification logicielle n'est requise**. La loi impose de **tenir des
registres** et d'avoir un **Plan de Maîtrise Sanitaire (PMS)**. Un food truck est soumis
**aux mêmes exigences qu'un restaurant** (règlement CE 852/2004), adaptées à la mobilité.

### 3.1 Ce que la loi exige (et que l'app va digitaliser)

| Obligation | Ce que l'app KaribTruck fait |
|---|---|
| **PMS** (bonnes pratiques d'hygiène, HACCP, traçabilité) | Support vivant : procédures, points critiques, versionné |
| **Relevés de température** (enceintes froides, quotidiens, tracés) | Saisie 2 taps + horodatage inviolable + alerte hors-plage |
| **Traçabilité amont↔aval** (fournisseur → assiette et retour) | Photo étiquette, n° de lot, DLC/DLUO, fournisseur, réception |
| **Plan de nettoyage / désinfection** | Checklists récurrentes signées (ouverture / fermeture / hebdo) |
| **Gestion des non-conformités** | Fiche incident (rupture chaîne du froid, panne élec) + action |
| **Huiles de friture / plats témoins** | Suivi dédié (contrôle polaire, échantillons 5 jours) |
| **Formation hygiène** (≥ 14 h, au moins 1 personne) | Rappel d'échéance + stockage de l'attestation |

**Sanctions hygiène** : jusqu'à **15 000 €** et **fermeture administrative** en cas de danger
ou de récidive. La valeur de l'app : le jour du contrôle DDPP, vous sortez en 30 secondes un
**historique horodaté, complet et non rétro-daté** au lieu d'un classeur papier troué.

### 3.2 Contraintes spécifiques food truck (le PMS doit les couvrir)

Transport des denrées, gestion de la **réserve d'eau**, contrôle des équipements mobiles,
**procédure en cas de coupure élec / rupture de la chaîne du froid**, hygiène pendant les
déplacements entre emplacements. L'app doit connaître ces scénarios (checklists dédiées).

---

## 4. Architecture recommandée : **hybride**

```
┌─────────────────────────────────────────────────────────────────┐
│                          iPad (sur le camion)                     │
│                                                                   │
│   ┌───────────────────────┐        ┌────────────────────────┐    │
│   │  CAISSE (du marché)    │        │  KaribTruck (maison)   │    │
│   │  logiciel conforme     │        │  HACCP + exploitation  │    │
│   │  attestation/certif.   │        │  local-first, offline  │    │
│   │  encaissement + TPE    │        │  journal inviolable    │    │
│   └───────────┬───────────┘        └───────────┬────────────┘    │
│               │ export ventes (CSV/API)         │                 │
│               └──────────────┬──────────────────┘                 │
│                              ▼                                     │
│                   Tableau de bord unifié                          │
│         (CA du jour ⨯ pertes ⨯ alertes hygiène ⨯ stock)          │
└──────────────────────────────┬────────────────────────────────────┘
                               │ export PDF/CSV
                               ▼
                    Comptable  ·  Contrôle DDPP
```

- La **caisse** reste la source de vérité des encaissements (et porte la conformité fiscale).
- **KaribTruck** est la source de vérité **hygiène + exploitation** (stocks, DLC, fournisseurs,
  planning des marchés/emplacements, pertes, marges).
- Jonction faible : la caisse **exporte** ses ventes ; KaribTruck les **agrège** pour un
  tableau de bord unique. Pas de couplage fort, pas de dépendance risquée.

### Choix technique de l'app maison

- **100 % local-first, hors-ligne d'abord** (cohérent avec l'ADN de ce dépôt : IA/outils
  privés, local-first). Les données restent sur l'iPad ; sauvegarde chiffrée exportable.
- **Deux pistes de réalisation** (à trancher ensemble) :
  - **A. Native SwiftUI** — meilleure UX iPad, hors-ligne solide, Face ID, appareil photo
    (photos d'étiquettes), notifications locales. Coût : Mac + Xcode + compte Apple Developer
    (99 €/an). Langage Swift (nouveau vs le stack Python/Rust du profil).
  - **B. PWA locale (web installable)** — réutilise le savoir-faire web du profil, un seul
    code, installable sur l'écran d'accueil, service worker pour l'hors-ligne. Limites iOS
    (accès matériel plus restreint). Démarrage plus rapide, moins « Apple-natif ».
  - **Reco de départ** : viser une **PWA local-first** pour livrer vite un M0 utile, garder
    SwiftUI en option si l'UX terrain l'exige. Le **cœur métier** (modèle de données, journal
    inviolable, règles HACCP, exports) est écrit une fois, indépendant de l'UI.

---

## 5. Le « pro » : sécurité, tests, audit, harnais — comment on l'incarne

Vous voulez du sérieux. Voici comment il se matérialise concrètement, en réutilisant l'ADN
déjà éprouvé dans ce dépôt (`edgesense/`, `microbit/`) :

- **Journal inviolable (tamper-evident).** Chaque relevé de température, chaque contrôle est
  écrit dans un **journal append-only chaîné en SHA-256** (déjà implémenté et testé ici). On
  ne peut **ni modifier ni rétro-dater** un enregistrement sans casser la chaîne — la preuve
  de bonne foi devant la DDPP. Une correction se fait par **écriture rectificative**, jamais
  par effacement.
- **Local-first & confidentialité.** Données sur l'appareil, pas de cloud imposé, sauvegarde
  **chiffrée**. Verrouillage par Face ID / code.
- **Tests.** Suite de tests unitaires sur le **cœur métier stdlib pur** (modèle, règles de
  seuils, intégrité du journal, exports) — même discipline que les 9 tests EdgeSense / 33
  tests micro:bit déjà verts dans ce dépôt. Objectif : cœur testé à ~100 %.
- **Audit / traçabilité.** Tout est horodaté et attribué. Export **PDF « dossier de
  contrôle »** (relevés + nettoyage + traçabilité sur une période) en un tap.
- **Harnais / CI.** Intégration continue GitHub qui **exécute les tests à chaque push**, plus
  un **hook de démarrage** (le profil sait déjà faire des SessionStart hooks) pour que
  l'environnement soit reproductible. Lint + typecheck.
- **Allowlist & garde-fous.** Comme dans EdgeSense/micro:bit : les actions sensibles
  (suppression d'un lot, override d'une alerte) passent par une **liste blanche** explicite et
  laissent une trace.
- **Revue de sécurité** avant toute mise en service (le dépôt dispose déjà d'un flux
  `security-review`).

C'est cette colonne vertébrale qui distingue « un carnet Notes » d'un **outil de conformité**.

---

## 6. MVP proposé — **KaribTruck M0** (utile en 1 sprint)

Périmètre minimal qui **résout tout de suite votre faiblesse HACCP**, sans toucher à la
caisse :

1. **Relevés de température** : enceintes configurables, saisie 2 taps, plage cible, **alerte
   hors-plage**, historique horodaté inviolable.
2. **Checklists** : ouverture / fermeture / nettoyage, récurrentes, signées.
3. **Traçabilité réception** : photo étiquette + fournisseur + n° lot + DLC.
4. **Journal d'incidents** (non-conformité) + action corrective.
5. **Export « dossier de contrôle »** (PDF/CSV) sur une période.
6. **Socle pro** : cœur métier stdlib testé + journal SHA-256 + CI.

**Roadmap ensuite :**
- **M1 — Exploitation** : stocks & pertes, DLC en alerte, fournisseurs, **planning des
  emplacements/marchés**, marges.
- **M2 — Intégration caisse** : import des ventes du logiciel de caisse → **tableau de bord
  unifié** (CA ⨯ pertes ⨯ alertes hygiène).
- **M3 — Terrain** : mode natif si besoin (photo, notifications), sauvegarde chiffrée
  multi-appareils, second opérateur.
- **M4 — Intelligence locale** (optionnel, dans l'esprit du profil) : suggestions de réappro
  et d'anti-gaspi à partir de l'historique, **100 % on-device** (aucune donnée qui sort).

---

## 7. Risques & angles morts (à instrumenter tôt)

- **Régime TVA mal identifié** → on construit/achète la mauvaise chose. **Bloquant n°1** : à
  lever avec le comptable **avant** de coder (voir §2.3).
- **Adoption terrain** : si la saisie prend > 10 s en coup de feu, l'outil est abandonné.
  Contrainte de design : chaque geste courant en **≤ 2 taps**, utilisable d'une main, gras.
- **Hors-ligne réel** : tester sans réseau dès le M0 (le camion bouge, la 4G tombe).
- **Sauvegarde/perte de l'iPad** : sans backup chiffré, on perd la preuve de conformité.
  À traiter dès M0.
- **Double saisie caisse ↔ app** : tant que l'intégration (M2) n'est pas là, éviter de
  ressaisir les ventes à la main — cadrer l'export de la caisse **avant** de l'acheter.
- **Ne pas sur-construire** : la caisse reste achetée ; KaribTruck n'empiète jamais sur
  l'encaissement fiscal.

---

## 8. Ce que je **ne** construirai **pas**, et pourquoi

- **Un logiciel de caisse / d'encaissement.** Domaine réglementé, responsabilité d'éditeur, 4
  conditions ISCA à prouver, zéro valeur différenciante. → **On achète**, on exige
  l'attestation.
- **Un stockage cloud imposé des données clients.** Contraire au principe local-first et
  inutilement risqué (RGPD). → Données sur l'appareil, export à la demande.

---

## Décision demandée (pour lancer le M0)

1. **Votre régime de TVA** aujourd'hui et la projection de CA (franchise en base, ou
   assujetti ?) — réponse de votre comptable.
2. **Piste technique** : PWA local-first (démarrage rapide, reco) **ou** natif SwiftUI
   (UX iPad max, coût Apple) ?
3. **Feu vert MVP M0** tel que décrit au §6 ?

Dès ces trois réponses, on écrit le **cœur métier testé** (modèle HACCP + journal inviolable
+ exports) — la partie où ce dépôt a déjà un savoir-faire prouvé — puis l'UI.

---

## Sources

- [BOFiP — Suppression de l'attestation individuelle de l'éditeur (LF 2025, art. 43)](https://bofip.impots.gouv.fr/bofip/14667-PGP.html/ACTU-2025-00075)
- [BOFiP — Prorogation au 31 août 2026 du délai de certification par organisme accrédité](https://bofip.impots.gouv.fr/bofip/14826-PGP.html/ACTU-2025-00160)
- [Service Public Entreprendre — Rétablissement des logiciels de caisse auto-certifiés](https://entreprendre.service-public.gouv.fr/actualites/A18087?lang=fr)
- [LégiFiscal — LF 2026 : rétablissement de l'auto-certification des logiciels de caisse](https://www.legifiscal.fr/actualites-fiscales/4460-loi-finances-2026-retablissement-auto-certification-logiciels-caisse.html)
- [impots.gouv.fr — Champ d'application de l'obligation de logiciel de caisse sécurisé (dispense franchise en base)](https://www.impots.gouv.fr/professionnel/questions/quel-est-le-champ-dapplication-de-lobligation-de-detenir-un-logiciel-de)
- [economie.gouv.fr — Ce qu'il faut savoir sur la certification des logiciels de caisse](https://www.economie.gouv.fr/entreprises/gerer-son-entreprise-au-quotidien/gerer-sa-comptabilite-et-ses-demarches/ce-quil-faut-savoir-sur-la-certification-des-logiciels-de-caisse)
- [BOFiP — Obligation d'utilisation de logiciels/systèmes de caisse sécurisés (BOI-TVA-DECLA-30-10-30)](https://bofip.impots.gouv.fr/bofip/10691-PGP.html)
- [normes-haccp.com — Hygiène alimentaire food truck : guide 2025](https://normes-haccp.com/hygiene-alimentaire-food-truck/)
- [traqfood.com — Obligations HACCP : cadre légal, responsabilités, exigences](https://www.traqfood.com/fr/blog-methode-haccp/normes-haccp/obligation-haccp/)
- [Règlement (CE) n° 852/2004 relatif à l'hygiène des denrées alimentaires](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32004R0852)

---

_Note de cadrage — statut : analyse livrée, en attente de décision (régime TVA · piste
technique · feu vert M0). Aucun code écrit à ce stade : on cadre avant de construire._
