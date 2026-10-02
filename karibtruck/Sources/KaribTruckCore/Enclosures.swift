/// Une enceinte à température maîtrisée (frigo, congélateur, vitrine chaude…).
public struct Enclosure: Identifiable, Equatable, Codable {
    public let id: String          // slug stable, ex. "frigo" (sert de clé dans le journal)
    public let name: String        // libellé affiché, ex. "Frigo"
    public let threshold: Threshold

    public init(id: String, name: String, threshold: Threshold) {
        self.id = id
        self.name = name
        self.threshold = threshold
    }

    // MARK: - Préréglages M0 (food truck en vente à emporter)
    // Configuration réelle de ce food truck : 1 vitrine chaude + 1 frigo domestique.
    // Les limites sont des valeurs de départ raisonnables, à ajuster avec le PMS.

    /// Frigo domestique : froid positif, ne doit pas dépasser 4 °C.
    public static let frigo = Enclosure(
        id: "frigo", name: "Frigo",
        threshold: Threshold(rule: .max, limitCelsius: 4.0))

    /// Vitrine chaude : maintien au chaud, ne doit pas descendre sous 63 °C.
    public static let vitrineChaude = Enclosure(
        id: "vitrine-chaude", name: "Vitrine chaude",
        threshold: Threshold(rule: .min, limitCelsius: 63.0))

    /// Le parc d'enceintes du M0.
    public static let defaultsM0: [Enclosure] = [frigo, vitrineChaude]
}
