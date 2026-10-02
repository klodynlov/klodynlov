# SilverBrain — connecteurs MCP « proches »

> Spécification des connecteurs par lesquels SilverBrain agit sur le monde extérieur :
> **appels**, **messages**, **agenda**. Tout passe par **MCP** (Model Context Protocol),
> déjà au cœur du portfolio. Principe directeur : l'utilisateur ne configure rien ; un
> **proche de confiance** active et paramètre les connecteurs, chacun sous **confirmation
> orale** et **garde-fous** stricts.

Vue d'ensemble : [SILVERBRAIN.md](SILVERBRAIN.md) · Profil : [SILVERBRAIN-PROFIL.md](SILVERBRAIN-PROFIL.md)
· Style : [SILVERBRAIN-STYLE.md](SILVERBRAIN-STYLE.md)

---

## 1. Principes communs à tous les connecteurs

- **SilverBrain est client MCP.** Klody orchestre ; chaque capacité externe est un **outil
  MCP** exposé par un petit serveur local. On réutilise le socle client/serveur MCP du
  projet Klody.
- **Activation par un proche, pas par le senior.** Les connecteurs sont installés et
  autorisés une fois, depuis l'interface aidant. L'utilisateur n'a aucun réglage à faire.
- **Confirmation avant toute action qui engage.** Appeler, envoyer, créer/supprimer un
  événement → une confirmation orale claire, une seule à la fois (voir règle R9 du
  [contrat de style](SILVERBRAIN-STYLE.md)).
- **Allowlist, jamais de champ libre dangereux.** Les destinataires possibles sont ceux du
  carnet (traits `proche` du profil). Pas de numéro/adresse arbitraire dicté à la volée
  sans double confirmation.
- **Local d'abord.** Les connecteurs privilégient des chemins locaux/on-device ; toute
  sortie réseau (passerelle SMS, téléphonie) est un choix explicite du proche, documenté.
- **Traçabilité.** Chaque action produit une entrée de **journal local** (horodatage,
  outil, cible, résultat), consultable par le proche autorisé.
- **Idempotence & annulation.** Les actions réversibles exposent une annulation (« annule
  le dernier message ») dans une courte fenêtre.

### Contrat d'un outil MCP (forme générale)

```jsonc
{
  "name": "contacts.call",
  "description": "Appeler un proche du carnet (par alias)",
  "inputSchema": {
    "type": "object",
    "properties": {
      "alias": { "type": "string", "description": "clé du trait proche, ex. 'fille'" }
    },
    "required": ["alias"]
  },
  "safety": {
    "confirmation": "required",          // jamais silencieux
    "allowlist": "profile.proche",       // cibles = carnet du profil
    "rate_limit": "5/heure",
    "audit": true
  }
}
```

Le bloc `safety` est **appliqué par l'hôte** (Klody), pas laissé à la discrétion du
modèle : la confirmation, l'allowlist et le quota sont des garde-fous de première classe.

---

## 2. Connecteur « Appels » — `contacts.*`

Passer un appel vocal vers un proche du carnet.

| Outil | Rôle | Confirmation |
|-------|------|:------------:|
| `contacts.resolve(alias)` | Résout « ma fille » → contact du profil | non (lecture) |
| `contacts.call(alias)` | Lance l'appel | **oui** |
| `contacts.hangup()` | Raccroche | non |
| `contacts.redial()` | Rappelle le dernier | **oui** |

**Résolution par alias.** Les cibles viennent des traits `proche` (`fille:Marie`,
`medecin:Dr_Martin`). « Appelle le docteur » → `contacts.call("medecin")`.

**Backends possibles** (choisis par le proche) : SIP/VoIP local, passerelle
téléphonie DECT, ou app d'appel du système. Le connecteur expose la même interface quel
que soit le backend.

**Garde-fous.**
- Confirmation orale nommée : « J'appelle votre fille Marie ? … J'appelle. »
- **Anti-appel accidentel** : un seuil de confiance d'intention élevé est requis ; en cas
  de doute → question fermée, pas d'appel.
- **Heures calmes** configurables (ex. pas d'appel sortant après 21 h sauf détresse).
- **Détresse** : `contacts.call` avec priorité, déclenché par la phrase de détresse du
  profil, court-circuite les heures calmes vers le contact d'urgence.

**Exemple de flux.**
```
Jeanne — Je voudrais parler à Marie.
Klody  — resolve("fille") → Marie ; intention=appeler (confiance 0.9)
SB     — Vous voulez appeler votre fille Marie ? … Je l'appelle ?
Jeanne — Oui.
Klody  — contacts.call("fille")   (confirmé → autorisé ; audit)
```

---

## 3. Connecteur « Messages » — `messages.*`

Envoyer un message court à un proche, dicté en langage naturel.

| Outil | Rôle | Confirmation |
|-------|------|:------------:|
| `messages.compose(alias, texte)` | Prépare un brouillon (relu à voix haute) | non |
| `messages.send(alias, texte)` | Envoie | **oui** |
| `messages.cancel_last()` | Annule dans la fenêtre d'annulation | non |
| `messages.read_incoming(alias?)` | Lit les messages reçus à voix haute | non (lecture) |

**Relecture obligatoire avant envoi.** Le connecteur **relit le message** dans la
formulation de l'utilisateur puis demande confirmation — on n'envoie jamais une
transcription non validée.

**Backends possibles** : SMS via passerelle, messagerie familiale locale, e-mail simple
(réutilise le connecteur Gmail déjà présent dans l'écosystème Klody, si activé par le
proche).

**Garde-fous.**
- **Anti-erreur de destinataire** : l'alias est répété (« à votre fille Marie »).
- **Pas de contenu sensible sortant** sans confirmation renforcée (le profil marque
  certains sujets `sensible`).
- **Fenêtre d'annulation** de quelques secondes après l'ordre d'envoi.
- **Filtrage entrant** : `read_incoming` peut masquer spam/expéditeurs inconnus selon la
  politique du proche.

**Exemple de flux.**
```
Jeanne — Dis à Paul que je passerai dimanche.
SB     — compose("voisin","Je passerai dimanche.")
SB     — Je vais écrire à Paul : « Je passerai dimanche. » … Je l'envoie ?
Jeanne — Oui, envoie.
Klody  — messages.send("voisin","Je passerai dimanche.")   (confirmé ; annulable 5 s ; audit)
```

---

## 4. Connecteur « Agenda » — `agenda.*`

Gérer rendez-vous et rappels, en cohérence avec le `rythme` du profil.

| Outil | Rôle | Confirmation |
|-------|------|:------------:|
| `agenda.list(quand)` | Lit l'agenda (« aujourd'hui », « demain ») | non (lecture) |
| `agenda.create(titre, quand)` | Crée un événement/rappel | **oui** |
| `agenda.update(id, champs)` | Déplace/modifie | **oui** |
| `agenda.delete(id)` | Supprime | **oui** |
| `agenda.next_reminder()` | Prochain rappel à venir | non (lecture) |

**Temps en langage naturel.** « demain matin », « après la sieste », « tous les mardis »
sont résolus en s'appuyant sur le `rythme` détecté (voir profil). La restitution suit la
règle R4 du [contrat de style](SILVERBRAIN-STYLE.md) : « à trois heures de l'après-midi »,
pas « 15:00 ».

**Backends possibles** : store local (SQLite, hors-ligne), ou calendrier partagé avec un
proche (Google Calendar via MCP, si activé) — le proche voit et ajoute des rappels à
distance.

**Garde-fous.**
- **Rappels de soin (`sante_routine`)** : ne peuvent être supprimés que par confirmation
  explicite renforcée ; jamais périmés en silence (cohérent avec le modèle de profil).
- **Escalade douce** : un rappel critique non confirmé re-sonne calmement puis, si
  configuré, notifie un proche via `messages.*` — jamais d'alarme anxiogène.
- **Anti-doublon** : `create` rapproche par titre+plage horaire pour éviter les rappels en
  double.

**Exemple de flux.**
```
Jeanne — Rappelle-moi mes gouttes ce soir.
Klody  — quand="ce soir" → 18:00 (rythme: dîner ~19h → gouttes avant)
SB     — Je note un rappel pour vos gouttes, ce soir vers six heures. … C'est bon ?
Jeanne — Oui.
Klody  — agenda.create("gouttes","2026-07-12T18:00")   (confirmé ; audit)
```

---

## 5. Sécurité & confiance (transversal)

- **Périmètre minimal** : seuls les connecteurs activés par le proche existent ; rien par
  défaut.
- **Consentement matérialisé** : chaque connecteur a un état `activé/désactivé` visible
  dans l'interface aidant, révocable à tout moment.
- **Aucune exfiltration** : les backends locaux sont préférés ; tout backend réseau est
  opt-in, nommé, et journalisé. Pas de télémétrie.
- **Journal partagé avec le proche** (avec accord du senior) : qui a été appelé, quels
  messages envoyés, quels rappels — la transparence est un pilier de confiance pour ce
  public.
- **Dégradation gracieuse hors-ligne** : `agenda.*` et rappels fonctionnent sans réseau ;
  `contacts.call`/`messages.send` signalent clairement une indisponibilité plutôt que
  d'échouer en silence.

---

## 6. Feuille de route connecteurs

1. `agenda.*` **local** (hors-ligne) + escalade douce — socle des rappels.
2. `contacts.call` sur un backend simple + allowlist carnet.
3. `messages.*` avec relecture obligatoire et fenêtre d'annulation.
4. Backends « proches à distance » (calendrier partagé, messagerie familiale) via MCP.
5. `read_incoming` + filtrage entrant.
