// i2c_scan.ino — scanner I2C pour KLOD Live Brain (Teensy 4.1)
//
// Scanne le bus I2C par defaut (broches 18 = SDA0, 19 = SCL0) et liste les
// adresses qui repondent. A lancer AVANT le croquis LCD : ca confirme que le
// cablage est bon (quelque chose repond) avant de soupconner l'ecran.
//
// ⚠️ Non flashe / non mesure dans ce depot : croquis de reference, a valider
//    sur la carte. La logique est standard (scan Wire).
//
// Attendu avec l'Audio Shield + le LCD branches :
//   0x0A         SGTL5000 (codec audio de l'Audio Shield)
//   0x27 ou 0x3F platine LCD (PCF8574 / PCF8574A)
//
// Arduino IDE : carte "Teensy 4.1", USB Type "Serial".
// Ouvre le Moniteur serie a 115200 bauds.

#include <Wire.h>

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 4000) { /* attendre le port serie, max 4 s */ }
  Wire.begin();                 // I2C0 sur les broches 18 (SDA) / 19 (SCL)
  Serial.println();
  Serial.println("KLOD - scanner I2C (bus 18/19)");
}

void loop() {
  byte count = 0;
  Serial.println("Scan en cours...");

  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    byte err = Wire.endTransmission();      // 0 = le peripherique a repondu (ACK)
    if (err == 0) {
      Serial.print("  trouve : 0x");
      if (addr < 16) Serial.print('0');
      Serial.print(addr, HEX);
      if (addr == 0x0A)                     Serial.print("  (SGTL5000 - codec audio)");
      else if (addr == 0x27 || addr == 0x3F) Serial.print("  (platine LCD PCF8574)");
      Serial.println();
      count++;
    }
  }

  if (count == 0) {
    Serial.println("  aucun peripherique.");
    Serial.println("  -> verifie VCC=3V (pas 5V), GND=G, SDA=18, SCL=19.");
  }
  Serial.print("Total : ");
  Serial.println(count);
  Serial.println();

  delay(3000);
}
