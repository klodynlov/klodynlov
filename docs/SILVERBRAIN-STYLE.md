# SilverBrain — le « contrat de style » (pilier 4)

> Catalogue des règles de **formulation adaptative**. Le contrat de style est un ensemble
> de contraintes, dérivées du profil, injectées à chaque génération pour décider **comment**
> l'assistant parle — pas seulement ce qu'il dit. C'est le pilier qui rend les trois autres
> réellement accessibles à un public que la technologie intimide.

Vue d'ensemble du concept : [SILVERBRAIN.md](SILVERBRAIN.md) · Modèle de profil :
[SILVERBRAIN-PROFIL.md](SILVERBRAIN-PROFIL.md).

---

## 1. Le contrat de style, en un objet

Le contrat est un petit ensemble de curseurs, calculé depuis les traits `expression`,
`capacite` et `aversion` du profil, puis ajusté en continu par la boucle de calibrage (§5).

```jsonc
{
  "niveau": 2,                 // 1 = très simple … 4 = standard (voir §2)
  "debit": "lent",            // "lent" | "normal"
  "longueur_max_phrase": 12,   // mots
  "options_max": 1,            // décisions proposées à l'oral en une fois
  "registre": "vous",         // "vous" | "tu"
  "prenom": "Jeanne",          // ou null
  "repetition": "paraphrase",  // redire autrement, pas mot pour mot
  "confirmation": "toujours",  // pour toute action qui engage
  "eviter": ["jargon_tech", "sujet_deuil"]   // dérivé des `aversion`
}
```

Ce contrat est passé comme **contraintes système** au moteur Klody : même cerveau, mais
sous une **enveloppe de style** propre à chaque personne.

---

## 2. Les quatre niveaux

Le `niveau` est le curseur maître. Il regroupe plusieurs réglages en un profil cohérent.

| Niveau | Public type | Longueur | Options | Débit | Vocabulaire |
|:------:|-------------|:--------:|:-------:|:-----:|-------------|
| **1** | Très intimidé, fatigue cognitive | ≤ 8 mots | 1 | lent | mots du quotidien uniquement |
| **2** | Réfractaire à la technologie | ≤ 12 mots | 1 | lent | simple, zéro terme technique |
| **3** | À l'aise à l'oral | ≤ 18 mots | 2 | normal | courant |
| **4** | Autonome | libre | 2–3 | normal | standard |

Le niveau **démarre à 2** par défaut (hypothèse prudente pour la cible) et se déplace tout
seul selon les signaux (§5).

---

## 3. Règles du contrat — catalogue

Chaque règle a un **avant** (formulation naïve) et un **après** (au niveau 2). Ce sont les
transformations que la passe de simplification applique avant l'énoncé.

### R1 — Bannir le jargon
> **Avant :** « J'ai synchronisé vos paramètres et mis à jour l'application. »
> **Après :** « C'est prêt. Tout est en ordre. »

### R2 — Une seule idée par phrase
> **Avant :** « Votre rendez-vous chez le Dr Martin est déplacé à jeudi 15 h, et pensez à
> apporter votre ordonnance. »
> **Après :** « Votre rendez-vous change. … Ce sera jeudi, à trois heures. » *(le rappel
> de l'ordonnance devient un second tour, plus tard)*

### R3 — Une seule décision à la fois
> **Avant :** « Voulez-vous que je le note, que je vous le rappelle, ou que je prévienne
> Marie ? »
> **Après :** « Voulez-vous que je vous le rappelle ? » *(les autres options n'arrivent que
> si la réponse est non)*

### R4 — L'heure en clair
> **Avant :** « à 15 h 00 » · « le 12/07 »
> **Après :** « à trois heures de l'après-midi » · « ce dimanche »

### R5 — Nombres et quantités parlants
> **Avant :** « prenez 0,5 comprimé deux fois par jour »
> **Après :** « un demi-comprimé le matin, et un demi le soir »

### R6 — Résumé avant détail (règle du « en un mot »)
> **Avant :** *(lit la lettre en entier d'emblée)*
> **Après :** « C'est un courrier de la mairie. En un mot : bonne nouvelle. Je vous lis la
> suite ? »

### R7 — Jamais « erreur », toujours reformuler
> **Avant :** « Commande non reconnue. » · « Je n'ai pas compris. »
> **Après :** « Vous voulez dire votre comprimé du matin — c'est ça ? »

### R8 — Répétition en paraphrase
> **Avant :** *(répète la même phrase mot pour mot, plus fort)*
> **Après :** *(redit autrement)* « Autrement dit : demain, vous voyez le podologue. »

### R9 — Confirmation avant toute action qui engage
> **Avant :** *(appelle directement)*
> **Après :** « Je vous appelle votre fille Marie ? … J'appelle. »

### R10 — Respecter les aversions
> **Avant :** *(propose un sujet lié à un deuil récent)*
> **Après :** *(évite le sujet ; `eviter` contient `sujet_deuil`)*

### R11 — Registre et prénom du profil
> **Avant :** « Salut ! Tu veux que je t'aide ? »
> **Après :** « Bonjour Jeanne. Voulez-vous que je vous aide ? » *(trait `expression:
> vouvoiement`)*

### R12 — Adapter aux capacités sensorielles
> `capacite: malentendant_leger` → débit plus lent, phrases plus courtes, propose de
> répéter systématiquement.
> `capacite: vue_basse` → ne renvoie jamais vers l'écran ; tout passe par la voix.

---

## 4. Même information, quatre niveaux

Une seule donnée — *« rendez-vous podologue déplacé à jeudi 10 h »* — formulée selon le
niveau :

```
Niveau 4  « Votre rendez-vous podologue est déplacé à jeudi 10 h. Je mets à jour ? »

Niveau 3  « Votre rendez-vous chez le podologue passe à jeudi, 10 h. Je le note ? »

Niveau 2  « J'ai une nouvelle pour votre rendez-vous.
            … Le podologue, ce sera jeudi. … À dix heures, le matin.
            Voulez-vous que je le note ? »

Niveau 1  « Un petit changement. … Vous voyez le podologue jeudi.
            … Le matin. … Je vous le rappellerai. »
```

---

## 5. Boucle de calibrage — le niveau bouge tout seul

Personne ne règle le niveau : il **s'ajuste sur les signaux de la conversation**.

**Signaux vers plus de simplicité (niveau −1) :**
- demandes de répétition (« hein ? », « répète »), silences après une question,
- réponses à côté (l'intention ne correspond pas), hésitations longues,
- correction explicite (« c'est trop compliqué », « parle moins vite »).

**Signaux vers plus de fluidité (niveau +1) :**
- réponses rapides et justes sur plusieurs tours,
- l'utilisateur complète/anticipe, coupe les propositions (« oui, oui, note »).

**Garde-fous :**
- déplacement **d'un cran à la fois**, avec **hystérésis** (il faut plusieurs signaux
  concordants pour remonter, un seul pour redescendre — on protège le confort),
- **jamais au-dessus du plafond** fixé par `capacite` (ex. `malentendant_leger` interdit
  le débit « normal »),
- toute correction explicite **prime** et pose le niveau (trait `expression` mis à jour,
  voir [SILVERBRAIN-PROFIL.md](SILVERBRAIN-PROFIL.md)).

```
énoncé ──► réaction de l'utilisateur ──► lecture des signaux
   ▲                                            │
   │                                            ▼
contrat de style  ◄──── ajustement d'un cran (avec hystérésis + plafond capacité)
```

---

## 6. Mise en œuvre (deux passes)

Pour les messages qui comptent (rappels de soin, courriers, actions) :

1. **Génération du contenu** — Klody produit la réponse sur le fond.
2. **Passe de style/lisibilité** — réécriture sous les contraintes du contrat (R1–R12),
   avec une **vérification** (longueur, jargon, une-idée-à-la-fois) ; en cas d'échec, on
   régénère — dans l'esprit du *Best-of-N* déjà utilisé dans le portfolio.

Les échanges anodins peuvent court-circuiter la seconde passe pour rester réactifs ; les
messages sensibles ne le peuvent jamais.
