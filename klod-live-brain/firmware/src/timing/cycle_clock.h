// cycle_clock.h — horloge haute résolution basée sur le compteur de cycles DWT.
//
// ⚠️ L'implémentation (cycle_clock.cpp) ne compile QUE sous Teensyduino
// (Cortex-M7). Elle n'a PAS été flashée ni mesurée dans ce dépôt. La résolution
// est documentée (1,667 ns/cycle @600 MHz) ; le JITTER de bout en bout, lui,
// reste à MESURER — voir docs/TECHNICAL_REALITY.md.
#pragma once

#include <cstdint>

namespace klod {

class CycleClock {
 public:
  // Déverrouille (spécifique M7) puis démarre le compteur de cycles.
  void begin();

  // Cycles écoulés depuis begin(), accumulés sur 64 bits. Le compteur matériel
  // est 32 bits et déborde en ~7,16 s à 600 MHz : now() DOIT être appelé plus
  // souvent que cela pour que l'accumulation reste correcte.
  std::uint64_t now();

  // Conversions (F_CPU cycles/s, nominalement 600 MHz sur Teensy 4.x).
  static double cycles_to_ns(std::uint64_t cycles);
  static double cycles_to_us(std::uint64_t cycles);

 private:
  std::uint32_t last_ = 0;
  std::uint64_t acc_ = 0;
};

}  // namespace klod
