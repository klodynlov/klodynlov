// EveilTrainApp.swift — coquille de l'app iPad (cible Xcode, hors paquet Swift).
//
// Projet : `eveil/ios/App/EveilTrain.xcodeproj` (paquets locaux `eveil/ios` et
// `eveil/ios/WordEndCore` ; produits TrainPracticeUI, WordEndCore, EveilDesign,
// ColoringUI ; ressources : `PrivacyInfo.xcprivacy` et `eveil/lexique/*.json`).
// L'app s'ouvre sur l'accueil de la suite (`HomeView`). AUCUN entitlement
// iCloud, AUCUN SDK tiers.

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
            HomeView(parentAreaLocked: parentAreaLocked)
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
