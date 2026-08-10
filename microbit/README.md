# `microbit/` — connecter un BBC micro:bit en Bluetooth

Percevoir et agir sur une carte **BBC micro:bit** depuis Python, via Bluetooth
Low Energy — en local, sans cloud, sans compte, sans passerelle.

| Percevoir | Agir |
|---|---|
| température, accéléromètre, boussole, boutons | afficheur LED (texte, motifs, icônes), UART |

Trois façons de s'en servir : la **bibliothèque** Python, la **démo** en ligne
de commande, ou le **serveur MCP** qui met la carte entre les mains d'un agent.

---

## Essayer tout de suite, sans matériel

Un micro:bit simulé est fourni : aucune carte, aucun dongle Bluetooth requis.

```bash
python3 -m microbit.demo --simule infos
python3 -m microbit.demo --simule suivre --duree 10
python3 -m microbit.demo --simule boucle --consigne 24
python3 -m unittest microbit.test_microbit -v     # 33 tests, aucune dépendance
```

`boucle` est la démonstration intéressante : **percevoir → décider → agir**.
La carte mesure la température, le programme décide, la carte affiche le
résultat — la même boucle qu'EdgeSense, avec du matériel au bout de la radio.

---

## Avec une vraie carte

### 1. Installer la dépendance

```bash
pip install -r microbit/requirements.txt
```

`bleak` fournit la pile BLE sur macOS, Linux (BlueZ) et Windows.

### 2. Flasher un programme qui **active** le Bluetooth

C'est l'étape que tout le monde saute, et la cause n°1 des « ça ne se connecte
pas ». Un micro:bit sorti de sa boîte **n'expose aucun service Bluetooth** : il
faut un programme qui les démarre.

> **MicroPython ne convient pas.** Le module `radio` de MicroPython est un
> protocole propriétaire, pas du BLE GATT. Il faut passer par **MakeCode** (ou
> C++/CODAL).

Dans [makecode.microbit.org](https://makecode.microbit.org) : *Extensions* →
**Bluetooth** (MakeCode retire alors les blocs `radio`, les deux sont
incompatibles), puis onglet **JavaScript** :

```js
bluetooth.startTemperatureService()
bluetooth.startAccelerometerService()
bluetooth.startButtonService()
bluetooth.startLEDService()
bluetooth.startUartService()

bluetooth.onBluetoothConnected(function () { basic.showIcon(IconNames.Yes) })
bluetooth.onBluetoothDisconnected(function () { basic.showIcon(IconNames.No) })
```

Puis **⚙️ Paramètres du projet → « No Pairing Required »** : sans cela, il faut
appairer la carte au préalable (A+B maintenus + reset → « PAIRING MODE! »).

Ne démarrer que les services utiles : sur micro:bit **v1** (nRF51, 16 ko de
RAM), tout activer d'un coup peut ne pas tenir en mémoire. La **v2** est à
l'aise.

> ⚠️ Le service LED prend la main sur l'afficheur. Éviter de le piloter en même
> temps depuis le programme embarqué : les deux se marchent dessus.

### 3. Connecter

```bash
python3 -m microbit.demo scan
python3 -m microbit.demo infos
python3 -m microbit.demo texte "Bonjour"
python3 -m microbit.demo suivre --duree 30
python3 -m microbit.demo boucle --consigne 22
```

---

## Bibliothèque

```python
import asyncio
from microbit import MicrobitBLE

async def main():
    async with await MicrobitBLE.first() as mb:      # la carte la plus proche
        print(await mb.read_temperature(), "°C")
        print(await mb.read_accelerometer())         # x=+0.01g y=-0.02g z=-0.99g

        await mb.show_icon("coeur")
        await mb.show_text("Salut")
        await mb.show(["#...#", ".#.#.", "..#..", ".#.#.", "#...#"])

        await mb.watch_buttons(lambda bouton, etat: print(bouton, etat.name))
        await mb.watch_temperature(print, period_ms=1000)
        await asyncio.sleep(30)

asyncio.run(main())
```

| Méthode | Rôle |
|---|---|
| `MicrobitBLE.scan()` · `.first()` · `.connect_to(adresse)` | découvrir et connecter |
| `read_temperature()` · `read_accelerometer()` · `read_bearing()` · `read_buttons()` | lire un capteur |
| `watch_temperature()` · `watch_accelerometer()` · `watch_buttons()` · `watch_bearing()` · `watch_uart()` | s'abonner aux notifications |
| `show_text()` · `show()` · `show_icon()` · `clear()` | piloter l'afficheur |
| `send_uart()` | parler au programme embarqué |
| `set_temperature_period()` · `set_accelerometer_period()` · `set_scrolling_delay()` | régler les cadences |
| `has(Service.X)` · `describe_services()` | savoir ce que la carte expose vraiment |

Les rappels peuvent être synchrones ou `async`. Une exception levée dans un
rappel est journalisée sans interrompre l'abonnement.

---

## Serveur MCP

Expose la carte à un agent : il perçoit et agit sur le monde physique.

```bash
python3 -m microbit.server            # carte réelle
python3 -m microbit.server --simule   # sans matériel
```

Configuration Claude Desktop (`claude_desktop_config.json`) :

```json
{
  "mcpServers": {
    "microbit": {
      "command": "python3",
      "args": ["-m", "microbit.server"],
      "cwd": "/chemin/vers/klodynlov"
    }
  }
}
```

**Outils** — `scanner`, `connecter`, `deconnecter`, `etat`, `lire_temperature`,
`lire_accelerometre`, `lire_boussole`, `lire_boutons`, `evenements_recents`,
`afficher_texte`, `afficher_icone`, `afficher_motif`, `effacer_affichage`,
`envoyer_uart`. **Ressource** — `microbit://state`.

> **Le temps réel, honnêtement.** MCP est un protocole requête/réponse : le
> serveur ne peut pas réveiller l'agent quand un bouton est pressé. On s'abonne
> donc aux notifications BLE dès la connexion et on les accumule dans un tampon
> borné (200 événements) que l'agent relève avec `evenements_recents`. Bon pour
> « que s'est-il passé ? », insuffisant pour réagir en millisecondes — ce
> verrou-là demande un vrai bus pub/sub (EdgeSense M2).

---

## Comment c'est construit

```
profile.py   UUIDs, codecs, allowlist d'écriture   ← stdlib pure, testable sans radio
ble.py       session BLE (bleak) : scan, connexion, lecture, notifications, écriture
fake.py      micro:bit simulé exposant l'API de bleak
demo.py      démonstration en ligne de commande
server.py    adaptateur MCP
```

Deux choix structurants :

**Le cœur ne connaît pas la radio.** Tout le décodage vit dans `profile.py`,
qui n'importe que la bibliothèque standard. Les 33 tests tournent sans `bleak`,
sans dongle et sans carte — donc en CI.

**Une allowlist décide de ce qui peut être écrit.** Même discipline que les
actionneurs d'EdgeSense : sept caractéristiques sont inscriptibles, avec leurs
bornes ; tout le reste est refusé *avant* d'atteindre la radio — à commencer
par le service **DFU**, dont une écriture déclencherait une reprogrammation à
distance de la carte.

---

## Trois pièges du profil Bluetooth du micro:bit

Chacun a coûté du temps à quelqu'un ; ils sont encodés et testés ici.

1. **L'UART est inversé.** Le micro:bit nomme ses caractéristiques du point de
   vue de la carte : `TX` (`…0002`) va de la carte vers le client, `RX`
   (`…0003`) est la cible d'écriture. C'est l'inverse de l'assignation Nordic
   habituelle. Un test verrouille ce sens.
2. **`UART TX` fonctionne en `indicate`, pas en `notify`.** Son CCCD attend
   `0x0200`, pas `0x0100`. Une implémentation qui force « notify » n'a jamais
   de données. bleak choisit le bon mode tout seul.
3. **Un service absent n'est pas une panne radio.** C'est un firmware sans le
   service. Le connecteur relève les services au moment de la connexion et
   renvoie le bloc MakeCode à activer plutôt qu'un timeout opaque.

## En cas de problème

| Symptôme | Cause la plus fréquente |
|---|---|
| `scan` ne trouve rien | Le programme flashé n'active pas le Bluetooth. Ou la carte est **déjà connectée** ailleurs (téléphone, autre terminal) : une carte connectée disparaît des scans. |
| La carte apparaît puis la connexion échoue | Appairage requis : activer « No Pairing Required » dans MakeCode, ou appairer (A+B+reset). |
| `ServiceUnavailable` | Le service n'est pas démarré dans le programme — le message indique le bloc MakeCode à ajouter. |
| Rien n'arrive sur l'UART | Vérifier que la carte émet bien (`bluetooth.uartWriteLine`) ; le délimiteur par défaut côté client est `\n`. |
| `texte trop long` | 20 **octets UTF-8**, pas 20 caractères : « é » en compte 2. |
| Déconnexions répétées | Piles faibles, distance, ou interférences 2,4 GHz. |
| Linux : `Bluetooth device is turned off` | `sudo systemctl start bluetooth` puis `bluetoothctl power on`. |

## Référence

[BBC micro:bit Bluetooth Profile](https://lancaster-university.github.io/microbit-docs/resources/bluetooth/bluetooth_profile.html)
(Lancaster University) — UUIDs, formats et propriétés GATT. Les valeurs codées
dans `profile.py` en sont issues et sont couvertes par les tests.
