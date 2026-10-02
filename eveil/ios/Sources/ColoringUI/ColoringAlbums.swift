// ColoringAlbums.swift — les albums : beaucoup de dessins, rangés par thème.
//
// Avec 70 pages, tout montrer d'un coup n'est plus possible sans vignettes minuscules.
// Les pages sont donc rangées en albums (le petit train, les animaux, le jardin…) :
// le choix des pages montre les albums en haut, un grand bouton-image chacun, et
// TOUTES les pages de l'album choisi d'un coup, sans défilement — la règle d'avant,
// album par album. D'où 12 pages au plus par album : c'est ce qui tient sur un iPad
// 11" en paysage avec des vignettes de 140 pt et plus.
//
// Les pages écrites à la main (PagesClassics/Animals/Things.swift) sont rangées ici ;
// les pages générées (PagesDessins.swift) portent leur album. L'outil
// eveil/outils/coloriages relit ce fichier pour vérifier l'atelier entier.

#if canImport(CoreGraphics)
import CoreGraphics

public struct ColoringAlbum: Identifiable, Sendable {
    public let id: String
    public let titleFR: String
    public let titleEN: String
    public let pages: [ColoringPage]

    public func title(locale: String) -> String { locale.hasPrefix("fr") ? titleFR : titleEN }
}

extension ColoringPages {
    /// Au plus 12 pages par album : toutes visibles d'un coup, même sur un iPad 11" en paysage.
    static let albumCapacity = 12

    public static let albums: [ColoringAlbum] = [
        album("train", fr: "Le petit train", en: "The little train", [train, cat]),
        album("animaux", fr: "Les animaux", en: "Animals", [cow, fish]),
        album("jardin", fr: "Le jardin", en: "The garden", [fly, hive, butterfly, flowers, snail]),
        album("maison", fr: "À la maison", en: "At home", [house, dogHouse]),
        album("miam", fr: "Miam !", en: "Yummy!", [iceCream]),
        album("route", fr: "En route !", en: "On the move", [boat, rocket]),
        album("fete", fr: "La fête", en: "Party time", [bell]),
    ]

    /// Un album : ses pages écrites à la main, puis ses pages générées.
    private static func album(_ id: String, fr: String, en: String, _ handDrawn: [ColoringPage]) -> ColoringAlbum {
        ColoringAlbum(id: id, titleFR: fr, titleEN: en, pages: handDrawn + (DrawnPages.byAlbum[id] ?? []))
    }
}
#endif
