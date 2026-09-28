// ColoringInstructions.swift — les consignes du mode interactif : « Colorie le soleil en jaune ! »
//
// Choix de l'utilisateur (28/09/2026) pour la suite du coloriage. En mode interactif, la voix
// donne une consigne : une partie nommée de la page (`ColoringPart`) et une couleur de la
// palette. Elle est réussie quand la partie a reçu assez de cette couleur (un toucher
// « remplir », ou quelques coups de pinceau) : on fête, puis vient la suivante. Jamais « faux » :
// colorier ailleurs ne coûte rien (la consigne se redit, un repère montre où) ; une autre couleur
// sur la bonne partie, c'est « En jaune ! » et la bonne pastille s'éclaire. La couleur imposée
// (le soleil jaune) est gardée ; sinon l'atelier en propose une franche, dans un ordre fixe
// (rien n'est tiré au hasard, docs/EVEIL.md § 4.6). Une partie « au choix » laisse l'enfant choisir
// (« Colorie les mains, de la couleur que tu veux ! ») : pour la peau, on n'impose jamais une
// couleur. Fonctions pures : testées.

#if canImport(CoreGraphics)
import CoreGraphics

/// Une consigne : une partie de la page, et la couleur demandée (index dans la palette ; `nil` :
/// au choix de l'enfant).
struct ColoringInstruction: Equatable {
    let part: ColoringPart
    let colorIndex: Int?
}

enum ColoringInstructions {
    /// Au plus tant de consignes par page : une séance courte, qu'on finit toujours.
    static let maxPerPage = 5
    /// La « couleur » d'une partie que l'enfant colorie de la couleur qu'il veut.
    static let anyColor = "au choix"
    /// Les couleurs franches proposées quand la page n'en impose pas, dans cet ordre.
    static let rotation = ["rouge", "bleu", "jaune", "vert", "orange", "violet", "rose", "marron"]

    /// Les consignes d'une page : le sujet d'abord, puis le décor. Une couleur imposée est gardée ;
    /// sinon, la suivante de la rotation qui n'est pas déjà demandée sur la page.
    static func list(for parts: [ColoringPart], palette: [PaintColor]) -> [ColoringInstruction] {
        let chosen = Array(parts.prefix(maxPerPage))
        var used = Set(chosen.compactMap(\.color))
        var next = 0
        var out: [ColoringInstruction] = []
        for part in chosen {
            if part.color == anyColor {
                out.append(ColoringInstruction(part: part, colorIndex: nil))
                continue
            }
            var name = part.color
            if name == nil {
                var k = 0
                while k < rotation.count, used.contains(rotation[(next + k) % rotation.count]) { k += 1 }
                let pick = rotation[(next + k) % rotation.count]
                next = (next + k + 1) % rotation.count
                used.insert(pick)
                name = pick
            }
            if let name, let index = palette.firstIndex(where: { $0.nameFR == name }) {
                out.append(ColoringInstruction(part: part, colorIndex: index))
            }
        }
        return out
    }

    /// « Colorie le soleil en jaune ! » / « Color the sun yellow! » ; au choix : « Colorie les mains,
    /// de la couleur que tu veux ! » / « Color the hands any color you like! »
    static func text(_ i: ColoringInstruction, palette: [PaintColor], locale: String) -> String {
        let fr = locale.hasPrefix("fr")
        guard let index = i.colorIndex else {
            return fr ? "Colorie \(i.part.fr), de la couleur que tu veux !" : "Color \(i.part.en) any color you like!"
        }
        let color = palette[index].name(locale: locale)
        return fr ? "Colorie \(i.part.fr) en \(color) !" : "Color \(i.part.en) \(color)!"
    }

    /// Le rappel quand la bonne partie reçoit une autre couleur : « En jaune ! » / « Yellow! »
    /// (aucun quand la couleur est au choix).
    static func colorReminder(_ i: ColoringInstruction, palette: [PaintColor], locale: String) -> String? {
        guard let index = i.colorIndex else { return nil }
        let color = palette[index].name(locale: locale)
        if locale.hasPrefix("fr") { return "En \(color) !" }
        let capitalized = color.prefix(1).uppercased() + String(color.dropFirst())
        return capitalized + "!"
    }

    /// Assez colorié : un huitième de la zone (un toucher « remplir », ou un bon coup de pinceau),
    /// au plus 2 % de la page (le ciel est immense), jamais moins de 120 pixels.
    static func isDone(painted: Int, area: Int, pageArea: Int) -> Bool {
        guard area > 0 else { return false }
        return painted >= max(120, min(area / 8, pageArea / 50))
    }
}
#endif
