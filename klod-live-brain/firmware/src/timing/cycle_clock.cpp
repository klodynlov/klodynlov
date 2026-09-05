// cycle_clock.cpp — implémentation DWT, spécifique Teensy 4.x (Cortex-M7).
//
// ⚠️ NON compilé / NON flashé / NON mesuré dans ce dépôt. Grounded sur la
// documentation (registres DWT du Cortex-M7, F_CPU du core Teensy) — à valider
// sur matériel.
#include "timing/cycle_clock.h"

#if defined(__IMXRT1062__)  // Teensy 4.0 / 4.1

#include <Arduino.h>  // fournit ARM_DEMCR, ARM_DWT_CTRL, ARM_DWT_CYCCNT, F_CPU

#ifndef F_CPU
#define F_CPU 600000000
#endif

namespace klod {

void CycleClock::begin() {
  // Sur Cortex-M7, activer la trace puis déverrouiller le DWT avant d'armer
  // CYCCNT. Teensyduino l'active souvent déjà au boot ; ces écritures sont
  // idempotentes. (LAR = 0xC5ACCE55 : clé de déverrouillage documentée.)
  ARM_DEMCR |= (1u << 24);                          // TRCENA
  *(volatile std::uint32_t*)0xE0001FB0 = 0xC5ACCE55;  // DWT->LAR
  ARM_DWT_CTRL |= (1u << 0);                        // CYCCNTENA
  ARM_DWT_CYCCNT = 0;
  last_ = ARM_DWT_CYCCNT;
  acc_ = 0;
}

std::uint64_t CycleClock::now() {
  const std::uint32_t cur = ARM_DWT_CYCCNT;
  // Soustraction non signée : correcte même quand le compteur 32 bits a débordé.
  acc_ += static_cast<std::uint32_t>(cur - last_);
  last_ = cur;
  return acc_;
}

double CycleClock::cycles_to_ns(std::uint64_t c) {
  return static_cast<double>(c) * 1e9 / static_cast<double>(F_CPU);
}

double CycleClock::cycles_to_us(std::uint64_t c) {
  return static_cast<double>(c) * 1e6 / static_cast<double>(F_CPU);
}

}  // namespace klod

#else
#error "cycle_clock.cpp ne cible que le Teensy 4.x (__IMXRT1062__)."
#endif
