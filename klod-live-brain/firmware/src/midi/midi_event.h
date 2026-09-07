// midi_event.h — l'unité qui circule dans le firmware : un événement MIDI horodaté.
//
// POD, sans dépendance (ni Arduino, ni Teensy) : compilable en natif, ce qui
// permet de tester la file (event_queue.h) avec de vrais événements. C'est le
// pendant embarqué du `NoteEvent` de la couche musical côté hôte, mais côté
// réflexe on garde l'octet de statut MIDI brut et un horodatage haute
// résolution (cycles DWT, cf. timing/cycle_clock.h).

#pragma once

#include <cstdint>

namespace klod {

// Ports logiques : d'où vient / où va l'événement.
enum class Port : std::uint8_t {
  kDin1 = 0,      // MIDI DIN (UART) — chemin de capture à faible jitter
  kUsbDevice = 1, // USB MIDI (Teensy vu comme périphérique) — jitter à mesurer
  kUsbHost = 2,   // contrôleur/MPC branché sur le port hôte du Teensy
};

// Types MIDI usuels (nibble haut de l'octet de statut).
enum class MidiType : std::uint8_t {
  kNoteOff = 0x8,
  kNoteOn = 0x9,
  kAftertouch = 0xA,
  kControlChange = 0xB,
  kProgramChange = 0xC,
  kChannelPressure = 0xD,
  kPitchBend = 0xE,
  kSystem = 0xF,
};

struct MidiEvent {
  std::uint64_t timestamp = 0;  // cycles DWT accumulés (1,667 ns/cycle @600 MHz)
  Port port = Port::kDin1;
  MidiType type = MidiType::kNoteOn;
  std::uint8_t channel = 0;     // 0..15
  std::uint8_t data1 = 0;       // note / numéro de CC
  std::uint8_t data2 = 0;       // vélocité / valeur
};

}  // namespace klod
