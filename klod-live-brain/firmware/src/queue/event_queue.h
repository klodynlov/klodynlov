// event_queue.h — file d'événements circulaire bornée, à allocation statique.
//
// C'est la SEULE pièce du firmware qui soit indépendante du matériel : de la
// logique C++ pure, donc compilable et testable en natif (voir
// ../../test/test_event_queue.cpp), exactement dans l'esprit du reste du dépôt
// — prouver ce qui peut l'être sans carte.
//
// Propriétés (exigences du cahier des charges) :
//   * §33 — aucune allocation dynamique : le tampon est un tableau membre.
//   * §28 — observabilité : un dépassement n'écrase RIEN ; push() renvoie false
//           et incrémente `dropped` ; `high_water` retient l'occupation max.
//   * §27 — déterministe, sans exception, sans dépendance.
//
// Usage visé : producteur unique / consommateur unique (SPSC). Le producteur
// (interruption ou scrutation MIDI) appelle push() ; le consommateur (boucle
// principale) appelle pop(). ⚠️ Portage Teensy : pour un vrai usage ISR↔loop,
// marquer head_/tail_ `volatile` et garantir l'ordre des écritures (barrière) —
// hors périmètre de ce squelette, à valider sur matériel.

#pragma once

#include <cstddef>
#include <cstdint>

namespace klod {

template <typename T, std::size_t Capacity>
class EventQueue {
  static_assert(Capacity >= 2, "capacité minimale 2 (une case réservée)");

 public:
  // Ajoute un élément. Renvoie false si la file est pleine (rien n'est écrasé),
  // en incrémentant le compteur de pertes.
  bool push(const T& item) {
    const std::size_t next = advance(head_);
    if (next == tail_) {  // pleine
      ++dropped_;
      return false;
    }
    buffer_[head_] = item;
    head_ = next;
    const std::size_t n = size();
    if (n > high_water_) high_water_ = n;
    return true;
  }

  // Retire le plus ancien élément. Renvoie false si la file est vide.
  bool pop(T& out) {
    if (tail_ == head_) return false;  // vide
    out = buffer_[tail_];
    tail_ = advance(tail_);
    return true;
  }

  bool empty() const { return head_ == tail_; }
  bool full() const { return advance(head_) == tail_; }

  std::size_t size() const { return (head_ + Capacity - tail_) % Capacity; }

  // Une case est réservée pour distinguer « plein » de « vide ».
  std::size_t capacity() const { return Capacity - 1; }

  std::size_t high_water() const { return high_water_; }
  std::uint32_t dropped() const { return dropped_; }

  void reset() {
    head_ = tail_ = high_water_ = 0;
    dropped_ = 0;
  }

 private:
  static std::size_t advance(std::size_t i) { return (i + 1) % Capacity; }

  T buffer_[Capacity];
  std::size_t head_ = 0;        // prochaine écriture
  std::size_t tail_ = 0;        // prochaine lecture
  std::size_t high_water_ = 0;  // occupation maximale observée
  std::uint32_t dropped_ = 0;   // push() refusés (file pleine)
};

}  // namespace klod
