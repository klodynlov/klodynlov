// midi_io.cpp — implémentation Teensy des E/S MIDI. Squelette de RÉFÉRENCE.
//
// ⚠️ NON compilé / NON flashé / NON mesuré dans ce dépôt. Certaines
// correspondances d'API (valeurs renvoyées par getType(), canaux 1-indexés)
// sont marquées « à vérifier » : elles se confirment sur matériel, pas ici.
#include "midi/midi_io.h"

#if defined(__IMXRT1062__)  // Teensy 4.0 / 4.1

#include <Arduino.h>
#include <MIDI.h>  // FortySevenEffects (licence MIT) — MIDI DIN sur UART matériel
// #include <USBHost_t36.h>  // à activer quand un contrôleur/MPC est branché sur le port hôte

// DIN sur Serial1, 31250 bauds. Chemin de capture à faible jitter (§3).
MIDI_CREATE_INSTANCE(HardwareSerial, Serial1, DIN);

namespace klod {

// getType() (DIN comme usbMIDI) renvoie l'octet de statut sans le canal
// (p.ex. 0x90 = Note On) ; le nibble haut est notre MidiType. À vérifier.
static MidiType type_of(std::uint8_t status_byte) {
  return static_cast<MidiType>(status_byte >> 4);
}

void MidiIO::begin() {
  DIN.begin(MIDI_CHANNEL_OMNI);
  // usbMIDI est prêt d'office côté Teensyduino selon "USB Type" (MIDI / Serial+MIDI).
}

void MidiIO::poll(CycleClock& clock, InQueue& in) {
  // --- DIN : réception octet par octet, faible jitter → capture de référence ---
  while (DIN.read()) {
    MidiEvent e;
    e.timestamp = clock.now();  // horodatage à la lecture
    e.port = Port::kDin1;
    e.type = type_of(DIN.getType());
    e.channel = static_cast<std::uint8_t>(DIN.getChannel() - 1);  // 1..16 → 0..15
    e.data1 = DIN.getData1();
    e.data2 = DIN.getData2();
    in.push(e);  // la file compte elle-même les pertes (§28)
  }

  // --- USB périphérique : jitter à MESURER (batching de polling ~2,2 ms) ---
  while (usbMIDI.read()) {
    MidiEvent e;
    e.timestamp = clock.now();
    e.port = Port::kUsbDevice;
    e.type = type_of(usbMIDI.getType());
    e.channel = static_cast<std::uint8_t>(usbMIDI.getChannel() - 1);
    e.data1 = usbMIDI.getData1();
    e.data2 = usbMIDI.getData2();
    in.push(e);
  }

  // --- USB hôte : à câbler avec USBHost_t36 quand un contrôleur est présent ---
}

void MidiIO::send(const MidiEvent& e) {
  const std::uint8_t ch = static_cast<std::uint8_t>(e.channel + 1);  // 0..15 → 1..16
  switch (e.port) {
    case Port::kDin1:
      if (e.type == MidiType::kNoteOn) DIN.sendNoteOn(e.data1, e.data2, ch);
      else if (e.type == MidiType::kNoteOff) DIN.sendNoteOff(e.data1, e.data2, ch);
      else if (e.type == MidiType::kControlChange) DIN.sendControlChange(e.data1, e.data2, ch);
      break;
    case Port::kUsbDevice:
    default:
      if (e.type == MidiType::kNoteOn) usbMIDI.sendNoteOn(e.data1, e.data2, ch);
      else if (e.type == MidiType::kNoteOff) usbMIDI.sendNoteOff(e.data1, e.data2, ch);
      else if (e.type == MidiType::kControlChange) usbMIDI.sendControlChange(e.data1, e.data2, ch);
      break;
  }
}

}  // namespace klod

#else
#error "midi_io.cpp ne cible que le Teensy 4.x (Teensyduino)."
#endif
