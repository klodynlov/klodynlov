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
    /// Atelier de coloriage : « Mode interactif » (demande de l'utilisateur, 28/09/2026 : « un mode
    /// interactif, que l'on peut activer au choix ») — la voix nomme la couleur choisie, chaque
    /// couleur chante sa note, et « J'ai fini ! » fait prendre vie au dessin. Désactivé par défaut ;
    /// l'enfant (ou l'adulte) l'allume d'un bouton de l'atelier.
    public static let coloringInteractiveKey = "eveil.coloring.interactive"
    public static let coloringInteractiveDefault = false
    /// Éveil à la lecture (le « mode écrit » d'OrthoPicto, 28/09/2026) : les mots écrits sous les
    /// pictos et la phrase écrite au-dessus du train. Activé par défaut (l'adulte lit, l'enfant voit
    /// que la phrase s'écrit) ; en capitales d'imprimerie au choix, comme à l'école maternelle.
    public static let writtenWordsKey = "eveil.writtenWords"
    public static let writtenWordsDefault = true
    public static let capitalsKey = "eveil.capitals"
    public static let capitalsDefault = false
    /// Les gestes de Lou (méthode Borel-Maisonny, validés par une orthophoniste le 06/10/2026) :
    /// Lou montre le geste et la bouche de chaque son, dans le petit train et les livres des sons
    /// (français seulement). Activé par défaut ; l'adulte peut les couper.
    public static let louGesturesKey = "eveil.lou.gestures"
    public static let louGesturesDefault = true
    /// La couleur de peau de Lou : c'est l'adulte qui la choisit (jamais imposée). Identifiant d'une
    /// `LouSkin` ; par défaut la peau de Lou du train des phrases.
    public static let louSkinKey = "eveil.lou.skin"
    public static let louSkinDefault = "lou"
}
#endif
