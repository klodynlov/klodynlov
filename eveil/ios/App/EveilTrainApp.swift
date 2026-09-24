// EveilTrainApp.swift — coquille de l'app iPad (cible Xcode, hors paquet Swift).
//
// Création du projet : Xcode 16+ › New › App (iPad, SwiftUI, iPadOS 17+), ajouter
// les paquets locaux `eveil/ios` et `eveil/ios/WordEndCore` (File › Add Package
// Dependencies › Add Local…), lier `TrainPracticeUI` et `WordEndCore`, copier ce fichier + `PrivacyInfo.xcprivacy`, ajouter
// les clés de `Info-additions.plist`, et embarquer `eveil/lexique/*.json` dans
// les ressources de l'app. AUCUN entitlement iCloud, AUCUN SDK tiers.

import SwiftData
import SwiftUI
import TrainPracticeUI
import UIKit
import WordEndCore

@main
struct EveilTrainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("eveil.language") private var language = "fr-FR"
    @State private var parentAreaLocked = AppDelegate.parentAreaLocked
    private let container: ModelContainer

    init() {
        do {
            container = try PracticeStore.makeContainer()
        } catch {
            fatalError("Stockage local indisponible : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let lexicon = LexiconLoader.load(language == "en-US" ? "en-US" : "fr-FR") {
                    PracticeView(words: lexicon.words.filter { ($0.level ?? 1) == 1 },
                                 locale: lexicon.locale,
                                 cabooseSounds: lexicon.cabooseSounds,
                                 parentButtonHidden: parentAreaLocked)
                } else {
                    Text("Lexique introuvable dans le paquet de l'app.")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.guidedAccessChanged)) { _ in
                parentAreaLocked = AppDelegate.parentAreaLocked
            }
        }
        .modelContainer(container)
    }
}

enum LexiconLoader {
    static func load(_ locale: String) -> Lexicon? {
        guard let url = Bundle.main.url(forResource: locale, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? Lexicon.decode(data)
    }
}

/// Accès guidé : l'app ne peut pas le DÉCLENCHER (réservé aux appareils supervisés
/// par MDM — vérifié dans la doc Apple), mais elle propose au parent une
/// restriction personnalisée dans les options de l'Accès guidé.
/// À VALIDER SUR iPAD : avec `@UIApplicationDelegateAdaptor`, le délégué d'application
/// est un objet SwiftUI qui relaie vers celui-ci ; vérifier que l'écran d'options de
/// l'Accès guidé affiche bien la restriction « Espace des grands ».
final class AppDelegate: NSObject, UIApplicationDelegate, UIGuidedAccessRestrictionDelegate {
    static let parentAreaRestriction = "eveil.restriction.parentArea"
    static let guidedAccessChanged = Notification.Name("eveil.guidedAccessChanged")

    static var parentAreaLocked: Bool {
        UIAccessibility.isGuidedAccessEnabled
            && UIAccessibility.guidedAccessRestrictionState(forIdentifier: parentAreaRestriction) == .deny
    }

    var guidedAccessRestrictionIdentifiers: [String]? { [Self.parentAreaRestriction] }

    func textForGuidedAccessRestriction(withIdentifier restrictionIdentifier: String) -> String? {
        "Espace des grands"
    }

    func detailTextForGuidedAccessRestriction(withIdentifier restrictionIdentifier: String) -> String? {
        "Masque le bouton des réglages pendant l'Accès guidé."
    }

    func guidedAccessRestriction(withIdentifier restrictionIdentifier: String,
                                 didChange newRestrictionState: UIAccessibility.GuidedAccessRestrictionState) {
        NotificationCenter.default.post(name: Self.guidedAccessChanged, object: nil)
    }
}
