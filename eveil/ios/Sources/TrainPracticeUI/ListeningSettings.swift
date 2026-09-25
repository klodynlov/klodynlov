// ListeningSettings.swift — les réglages d'écoute DU JEU (pas ceux de la référence).
//
// Retour de l'utilisateur après le premier essai sur iPad (25/09/2026) : « le
// micro doit être plus réceptif ». Deux causes probables, deux réglages :
//
// 1. Le détecteur ÉCARTE exprès les voix graves d'adulte (F0 médiane < 165 Hz ⇒
//    « incertain ») : le jeu ne doit pas prendre le mot dit par un parent pour
//    celui de l'enfant. Mais un adulte qui ESSAIE le jeu n'est alors jamais
//    entendu. D'où « Essai par un adulte » (espace des grands, désactivé par
//    défaut) : seule cette garde est levée, toutes les autres restent.
// 2. Six secondes pour commencer à parler, c'est court pour un enfant de 3 ans
//    qui regarde encore le train arriver : le jeu en laisse dix.
//
// Les valeurs de départ de `DetectorConfig` ne changent pas : elles sont
// partagées avec la référence Python et les vecteurs de parité.

import WordEndCore

public enum ListeningSettings {
    /// Clé de l'espace des grands : « Essai par un adulte (voix grave acceptée) ».
    public static let adultTrialKey = "eveil.adultTrial"

    /// Détecteur du jeu : les seuils de départ, sauf la garde « voix d'adulte »
    /// quand un adulte essaie lui-même.
    public static func detectorConfig(adultTrial: Bool) -> DetectorConfig {
        var config = DetectorConfig()
        if adultTrial { config.adultF0MaxHz = 0 }
        return config
    }

    /// Flux du jeu : dix secondes pour commencer à parler (six dans la référence).
    public static func streamingConfig() -> StreamingConfig {
        var stream = StreamingConfig()
        stream.maxWaitMs = 10_000
        return stream
    }
}
