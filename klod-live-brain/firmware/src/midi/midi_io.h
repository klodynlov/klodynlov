// midi_io.h — abstraction des E/S MIDI du Teensy (DIN, USB device, USB host).
//
// poll() lit tout ce qui est disponible, HORODATE à la lecture avec l'horloge
// haute résolution, et empile dans la file d'entrée. send() route un événement
// vers son port de sortie.
//
// ⚠️ Honnêteté du temps réel : l'horodatage USB reflète l'instant de LECTURE,
// pas l'arrivée sur le fil — l'USB regroupe les messages par intervalle de
// polling (voir docs/TECHNICAL_REALITY.md §3). Pour capturer du microtiming,
// privilégier la DIN. L'implémentation ne compile que sous Teensyduino et n'a
// PAS été testée ici.
#pragma once

#include "config.h"
#include "midi/midi_event.h"
#include "queue/event_queue.h"
#include "timing/cycle_clock.h"

namespace klod {

using InQueue = EventQueue<MidiEvent, config::kInQueueLen>;

class MidiIO {
 public:
  void begin();
  void poll(CycleClock& clock, InQueue& in);
  void send(const MidiEvent& e);
};

}  // namespace klod
