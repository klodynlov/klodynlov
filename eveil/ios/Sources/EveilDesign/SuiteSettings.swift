// SuiteSettings.swift — les réglages de l'espace des grands que partagent les deux jeux.
//
// L'espace des grands vit dans le module du petit train ; l'atelier de coloriage
// n'en dépend pas. La clé commune est donc ici, dans l'univers partagé de la suite.

#if canImport(SwiftUI)
public enum SuiteSettings {
    /// Atelier de coloriage : « Remplir d'un toucher ». Désactivé, l'enfant colorie au
    /// pinceau seul (qui reste dans sa zone) : plus de mouvements de la main, ce qui
    /// fait l'intérêt du coloriage (docs/EVEIL.md § 6.1). Décisions de l'utilisateur
    /// (25/09/2026) : réglable par l'adulte, et DÉSACTIVÉ par défaut — pinceau seul.
    public static let tapToFillKey = "eveil.coloring.tapToFill"
    public static let tapToFillDefault = false
}
#endif
