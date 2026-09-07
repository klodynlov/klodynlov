// test_event_queue.cpp — test natif de la file bornée, SANS Teensy.
//
//   c++ -std=c++17 -I../src -Wall -Wextra test_event_queue.cpp -o /tmp/tq && /tmp/tq
//
// C'est la seule partie du firmware vérifiable ici : de la logique pure. Le
// reste (horloge DWT, E/S MIDI) ne compile que sous Teensyduino et devra être
// MESURÉ sur matériel — voir ../README.md et docs/TECHNICAL_REALITY.md.

#include <cstdio>

#include "midi/midi_event.h"
#include "queue/event_queue.h"

using klod::EventQueue;
using klod::MidiEvent;
using klod::MidiType;

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond)                                                      \
  do {                                                                   \
    ++g_checks;                                                          \
    if (!(cond)) {                                                       \
      ++g_fails;                                                         \
      std::printf("  ÉCHEC ligne %d : %s\n", __LINE__, #cond);          \
    }                                                                    \
  } while (0)

static MidiEvent note(std::uint8_t n, std::uint64_t ts) {
  MidiEvent e;
  e.type = MidiType::kNoteOn;
  e.data1 = n;
  e.data2 = 100;
  e.timestamp = ts;
  return e;
}

// Capacité utile = N-1 (une case réservée pour distinguer plein/vide).
static void test_capacite() {
  EventQueue<MidiEvent, 4> q;
  CHECK(q.capacity() == 3);
  CHECK(q.empty());
  CHECK(!q.full());
  CHECK(q.size() == 0);
}

// FIFO : on ressort dans l'ordre d'entrée.
static void test_fifo() {
  EventQueue<MidiEvent, 8> q;
  for (std::uint8_t i = 0; i < 5; ++i) CHECK(q.push(note(i, i * 10)));
  CHECK(q.size() == 5);
  MidiEvent out;
  for (std::uint8_t i = 0; i < 5; ++i) {
    CHECK(q.pop(out));
    CHECK(out.data1 == i);
    CHECK(out.timestamp == static_cast<std::uint64_t>(i * 10));
  }
  CHECK(!q.pop(out));  // vide
  CHECK(q.empty());
}

// Débordement : push() refuse SANS écraser, et compte la perte (§28).
static void test_debordement_ne_perd_rien() {
  EventQueue<MidiEvent, 4> q;  // 3 utilisables
  CHECK(q.push(note(1, 0)));
  CHECK(q.push(note(2, 0)));
  CHECK(q.push(note(3, 0)));
  CHECK(q.full());
  CHECK(!q.push(note(99, 0)));  // refusé
  CHECK(!q.push(note(98, 0)));  // refusé
  CHECK(q.dropped() == 2);
  // Les éléments d'origine sont intacts et dans l'ordre.
  MidiEvent out;
  CHECK(q.pop(out) && out.data1 == 1);
  CHECK(q.pop(out) && out.data1 == 2);
  CHECK(q.pop(out) && out.data1 == 3);
  CHECK(q.empty());
}

// Enroulement : des milliers de push/pop entrelacés ne corrompent rien.
static void test_enroulement() {
  EventQueue<MidiEvent, 4> q;
  MidiEvent out;
  std::uint64_t expected = 0;
  std::uint64_t next = 0;
  for (int i = 0; i < 10000; ++i) {
    // On maintient la file à moitié pleine pour forcer l'enroulement.
    if (q.size() < 2) {
      CHECK(q.push(note(0, next++)));
    } else {
      CHECK(q.pop(out));
      CHECK(out.timestamp == expected++);
    }
  }
  while (q.pop(out)) CHECK(out.timestamp == expected++);
  CHECK(expected == next);
}

// Ligne de flottaison : occupation maximale correctement retenue.
static void test_high_water() {
  EventQueue<MidiEvent, 8> q;
  MidiEvent out;
  for (std::uint8_t i = 0; i < 5; ++i) q.push(note(i, 0));
  q.pop(out);
  q.pop(out);
  q.push(note(0, 0));  // redescend puis remonte, mais pas au-dessus de 5
  CHECK(q.high_water() == 5);
}

static void test_reset() {
  EventQueue<MidiEvent, 4> q;
  q.push(note(1, 0));
  q.push(note(2, 0));
  q.push(note(3, 0));
  q.push(note(4, 0));  // une perte
  CHECK(q.dropped() == 1);
  q.reset();
  CHECK(q.empty());
  CHECK(q.dropped() == 0);
  CHECK(q.high_water() == 0);
}

int main() {
  std::printf("test_event_queue (natif, sans Teensy)\n");
  test_capacite();
  test_fifo();
  test_debordement_ne_perd_rien();
  test_enroulement();
  test_high_water();
  test_reset();
  std::printf("%d vérifications, %d échec(s)\n", g_checks, g_fails);
  if (g_fails == 0) std::printf("OK\n");
  return g_fails == 0 ? 0 : 1;
}
