// config.h — point de réglage unique du firmware (portable, sans dépendance).
#pragma once

#include <cstddef>

namespace klod {
namespace config {

// Files bornées (allocation statique). Dimensionnées large ; l'occupation réelle
// est suivie par high_water() et à confronter à la mesure (BENCHMARKS.md).
inline constexpr std::size_t kInQueueLen = 256;
inline constexpr std::size_t kOutQueueLen = 256;

// Cadence d'affichage des métriques de diagnostic sur le port série (ms).
inline constexpr unsigned long kMetricsPeriodMs = 1000;

}  // namespace config
}  // namespace klod
