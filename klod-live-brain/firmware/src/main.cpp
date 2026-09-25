// main.cpp — jalon firmware V0 : MIDI passthrough horodaté + métriques.
//
// ⚠️ NON compilé / NON flashé / NON mesuré dans ce dépôt (pas de Teensy ici).
// Objectif de ce premier jalon, honnête et falsifiable :
//   1. §29 Test 1 — ce qui entre en MIDI ressort à l'identique (passthrough) ;
//   2. puis MESURER jitter / latence / events-sec / overruns → BENCHMARKS.md.
// Le scheduler déterministe, la capture GrooveDNA embarquée et le pont Mac
// viennent APRÈS, une fois ce socle chiffré (cahier des charges §31).
#include <Arduino.h>

#include "config.h"
#include "metrics/metrics.h"
#include "midi/midi_io.h"
#include "queue/event_queue.h"
#include "timing/cycle_clock.h"

using namespace klod;

static CycleClock g_clock;
static MidiIO g_midi;
static InQueue g_in;      // file bornée, allocation statique (testée en natif)
static Metrics g_metrics;

void setup() {
  Serial.begin(115200);
  g_clock.begin();
  g_midi.begin();
}

void loop() {
  // Percevoir : lire + horodater + empiler.
  g_midi.poll(g_clock, g_in);

  // Agir : pour la V0, simple passthrough. Le scheduler s'insérera ici.
  MidiEvent e;
  while (g_in.pop(e)) {
    ++g_metrics.midi_in;
    g_midi.send(e);
    ++g_metrics.midi_out;
  }

  // Observer : diagnostic périodique sur le port série.
  static unsigned long last = 0;
  const unsigned long nowMs = millis();
  if (nowMs - last >= config::kMetricsPeriodMs) {
    last = nowMs;
    g_metrics.dropped_in = g_in.dropped();
    g_metrics.queue_high_water = static_cast<std::uint32_t>(g_in.high_water());
    Serial.printf("in=%lu out=%lu dropped=%lu queue_hwm=%lu\n",
                  (unsigned long)g_metrics.midi_in,
                  (unsigned long)g_metrics.midi_out,
                  (unsigned long)g_metrics.dropped_in,
                  (unsigned long)g_metrics.queue_high_water);
  }
}
