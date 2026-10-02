/// Un modèle de checklist (ouverture, fermeture, nettoyage…). Seul le résultat
/// signé est journalisé (`KaribTruck.recordChecklistRun`) ; le modèle, lui,
/// est de la configuration.
public struct ChecklistTemplate: Identifiable, Equatable, Codable {
    public let id: String          // slug stable, ex. "ouverture" (clé dans le journal)
    public let name: String        // libellé affiché
    public let items: [String]

    public init(id: String, name: String, items: [String]) {
        self.id = id
        self.name = name
        self.items = items
    }

    // MARK: - Préréglages M0 (food truck en vente à emporter)
    // Points de départ tirés des bonnes pratiques d'hygiène ; à ajuster avec le PMS.

    public static let ouverture = ChecklistTemplate(
        id: "ouverture", name: "Ouverture",
        items: [
            "Mains lavées, tenue propre, cheveux attachés",
            "Savon, essuie-mains et gel disponibles",
            "Réserve d'eau propre remplie",
            "Plans de travail nettoyés et désinfectés",
            "Température du frigo relevée",
            "Vitrine chaude en chauffe (≥ 63 °C avant service)",
            "DLC des produits vérifiées",
            "Poubelle vide avec sac neuf",
        ])

    public static let fermeture = ChecklistTemplate(
        id: "fermeture", name: "Fermeture",
        items: [
            "Invendus chauds jetés (pas de remise en vente)",
            "Produits entamés filmés, étiquetés, datés",
            "Température du frigo relevée",
            "Plans de travail nettoyés et désinfectés",
            "Ustensiles et bacs lavés",
            "Sol nettoyé",
            "Poubelles vidées",
            "Eaux usées vidangées",
            "Gaz et électricité coupés",
        ])

    public static let nettoyage = ChecklistTemplate(
        id: "nettoyage", name: "Nettoyage hebdomadaire",
        items: [
            "Frigo vidé, nettoyé et désinfecté",
            "Hotte et filtres dégraissés",
            "Friteuse vidangée et nettoyée si besoin",
            "Réservoir d'eau propre désinfecté",
            "Réservoir d'eaux usées nettoyé",
            "Contrôle nuisibles (traces, pièges)",
            "Stock sec rangé, DDM vérifiées",
        ])

    public static let defaultsM0: [ChecklistTemplate] = [ouverture, fermeture, nettoyage]
}
