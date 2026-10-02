// metrics.h — compteurs d'observabilité (portable, sans dépendance).
//
// Prévus dès le départ (§28) : sans mesure, aucun qualificatif « faible latence »
// n'est permis (§30). Les champs de jitter sont des EMPLACEMENTS à remplir par la
// mesure sur matériel (BENCHMARKS.md) — ils valent 0 tant que rien n'est mesuré.
#pragma once

#include <cstdint>

namespace klod {

struct Metrics {
  std::uint32_t midi_in = 0;          // événements lus
  std::uint32_t midi_out = 0;         // événements émis
  std::uint32_t dropped_in = 0;       // refusés faute de place (file pleine)
  std::uint32_t queue_high_water = 0; // occupation max de la file d'entrée

  // À MESURER (restent 0 ici) :
  std::uint64_t jitter_min_cycles = 0;
  std::uint64_t jitter_max_cycles = 0;
};

}  // namespace klod
