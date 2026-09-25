// klod_lcd_hello.ino — test de l'ecran LCD 2004 I2C (Teensy 4.1)
//
// Affiche l'identite KLOD, un uptime et un battement : de quoi valider que
// l'ecran, le cablage et l'alimentation 3,3 V fonctionnent. Les vrais
// compteurs MIDI (in/out/dropped) viendront quand le DIN sera cable.
//
// ⚠️ Non flashe / non mesure dans ce depot : croquis de reference, a valider
//    sur la carte.
//
// Bibliotheque : "hd44780" par Bill Perry (Arduino IDE : Croquis > Inclure une
// bibliotheque > Gerer les bibliotheques > chercher "hd44780" > Installer).
// On la choisit parce qu'elle DETECTE seule l'adresse (0x27/0x3F) et le cablage
// du backpack : pas de reglage a deviner. Robuste sur Teensy.
//
// Arduino IDE : carte "Teensy 4.1", USB Type "Serial".
// (Caracteres LCD en ASCII : le HD44780 ne gere pas bien les accents.)

#include <Wire.h>
#include <hd44780.h>
#include <hd44780ioClass/hd44780_I2Cexp.h>

hd44780_I2Cexp lcd;               // adresse auto-detectee sur le bus 18/19
const int COLS = 20;
const int ROWS = 4;

void setup() {
  Serial.begin(115200);

  int status = lcd.begin(COLS, ROWS);
  if (status) {                   // != 0 => l'init a echoue
    Serial.print("LCD init echouee, code ");
    Serial.println(status);
    Serial.println("-> lance d'abord i2c_scan ; verifie 3V/GND/SDA=18/SCL=19.");
    hd44780::fatalError(status);  // fait clignoter la LED integree, puis boucle
  }

  lcd.setCursor(0, 0); lcd.print("KLOD Live Brain");
  lcd.setCursor(0, 1); lcd.print("GrooveDNA  ecran OK");
  lcd.setCursor(0, 3); lcd.print("MIDI in/out: a venir");
  Serial.println("LCD OK.");
}

void loop() {
  static uint32_t sec = 0;
  static bool beat = false;

  lcd.setCursor(0, 2);
  lcd.print("uptime: ");
  lcd.print(sec);
  lcd.print("s        ");         // espaces = efface la fin de ligne

  lcd.setCursor(COLS - 1, 0);
  lcd.print(beat ? '*' : ' ');    // battement : preuve visuelle que ca tourne

  beat = !beat;
  sec++;
  delay(1000);

  // --- Plus tard, quand le MIDI DIN sera cable : remplace l'uptime par les
  //     vrais compteurs de la file (cf. firmware/src/metrics/metrics.h) :
  //
  //   lcd.setCursor(0, 2);
  //   lcd.print("in:");  lcd.print(midi_in);
  //   lcd.print(" out:"); lcd.print(midi_out);
  //   lcd.setCursor(0, 3);
  //   lcd.print("drop:"); lcd.print(dropped);
  //   lcd.print(" q:");   lcd.print(queue_hwm);
}
