/// Sens de la contrainte de température. Le piège food truck : une **vitrine
/// chaude** et un **frigo** ont des règles opposées, il faut gérer les deux.
public enum ThresholdRule: String, Codable, Equatable {
    case max   // Froid : la mesure ne doit PAS dépasser la limite (conforme si ≤ limite).
    case min   // Chaud : la mesure ne doit PAS descendre sous la limite (conforme si ≥ limite).
}

public enum ReadingStatus: String, Codable, Equatable {
    case ok
    case alert
}

/// Un seuil de température = une règle + une limite en °C.
public struct Threshold: Equatable, Codable {
    public let rule: ThresholdRule
    public let limitCelsius: Double

    public init(rule: ThresholdRule, limitCelsius: Double) {
        self.rule = rule
        self.limitCelsius = limitCelsius
    }

    /// Statut d'un relevé. La limite est inclusive (à la limite = conforme).
    public func evaluate(_ celsius: Double) -> ReadingStatus {
        switch rule {
        case .max: return celsius <= limitCelsius ? .ok : .alert
        case .min: return celsius >= limitCelsius ? .ok : .alert
        }
    }
}
