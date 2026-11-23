// PracticeLog.swift — journal LOCAL (SwiftData), minimal par conception.
//
// Ce qui est stocké : la DOSE (séances, durées, mots pratiqués) et un état de
// jeu (combien de fois le fourgon a été accroché sur un mot) pour faire
// progresser les niveaux. Ce qui ne l'est JAMAIS : l'audio, un « score de
// langage », une interprétation clinique, un export vers un professionnel
// (cf. docs/EVEIL.md §7 — pas de donnée de santé déduite dans l'app publique).
//
// Persistance : `ModelConfiguration(cloudKitDatabase: .none)` — pas de
// synchronisation iCloud (vérifié dans la doc Apple : `.automatic` synchronise
// dès qu'un entitlement iCloud existe ; l'app n'en a pas, et on l'explicite).

#if canImport(SwiftData)
import Foundation
import SwiftData

@Model
public final class PracticeSession {
    public var startedAt: Date
    public var seconds: Double
    public var wordsPracticed: Int
    public var locale: String

    public init(startedAt: Date = .now, seconds: Double = 0, wordsPracticed: Int = 0, locale: String) {
        self.startedAt = startedAt
        self.seconds = seconds
        self.wordsPracticed = wordsPracticed
        self.locale = locale
    }
}

@Model
public final class WordProgress {
    @Attribute(.unique) public var wordId: String
    public var hookedCount: Int
    public var lastPracticed: Date

    public init(wordId: String, hookedCount: Int = 0, lastPracticed: Date = .now) {
        self.wordId = wordId
        self.hookedCount = hookedCount
        self.lastPracticed = lastPracticed
    }
}

public enum PracticeStore {
    /// Conteneur strictement local.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        return try ModelContainer(for: PracticeSession.self, WordProgress.self, configurations: config)
    }

    /// Temps d'écran de la journée (pour le budget quotidien réglé par le parent).
    public static func secondsToday(in context: ModelContext, calendar: Calendar = .current) -> Double {
        let start = calendar.startOfDay(for: .now)
        let predicate = #Predicate<PracticeSession> { $0.startedAt >= start }
        let sessions = (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
        return sessions.reduce(0) { $0 + $1.seconds }
    }
}
#endif
