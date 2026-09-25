// WordScenes.swift — chaque mot a son bruit et ses petites bêtes.
//
// Demande de l'utilisateur (25/09/2026) : « approfondir sur les images
// correspondantes, en permettant à l'utilisateur d'entendre le son que
// génèrera l'objet représentant le mot — exemple pour le mot mouche :
// animation de mouches qui volent en arrière-plan, et quand l'utilisateur
// attrape une mouche, il entend le son que fait la mouche ».
//
// Donc, pour chaque mot : le son de l'OBJET (on touche l'image : la vache fait
// « meuh ») et une nuée de petites choses qui volent derrière (on en attrape
// une : elle fait SON bruit). Quand le mot est lui-même une bestiole (mouche,
// abeille de la ruche, perruche), ce sont ses semblables qui volent.

import EveilDesign
import EveilSounds
import WordEndCore

struct WordScene: Equatable {
    let sound: SoundEffect          // l'objet du mot (toucher l'image)
    let critter: CritterKind        // ce qui vole derrière
    let count: Int

    static func forWord(_ word: TargetWord) -> WordScene {
        table[word.id] ?? WordScene(sound: .chime, critter: .star, count: 3)
    }

    /// Le son qu'on entend quand on attrape une bestiole.
    static func sound(of critter: CritterKind) -> SoundEffect {
        switch critter {
        case .fly: return .buzz
        case .bee: return .beeBuzz
        case .bird: return .tweet
        case .butterfly: return .flutter
        case .bubble: return .pop
        case .drop: return .drip
        case .note: return .ding
        case .spark: return .crackle
        case .leaf: return .rustle
        case .star: return .sparkle
        case .feather: return .whooshSoft
        case .paint: return .splat
        case .heart: return .kiss
        case .snowflake: return .twinkle
        }
    }

    /// Le fourgon qui s'accroche fait son symbole sonore : « chhh » la vapeur, « sss » le serpent.
    static func hookSound(coda: String?) -> SoundEffect? {
        switch coda {
        case "S": return .steam
        case "s": return .hiss
        default: return nil
        }
    }

    static let table: [String: WordScene] = [
        // Français
        "fr.douche": WordScene(sound: .shower, critter: .drop, count: 5),
        "fr.bouche": WordScene(sound: .kiss, critter: .heart, count: 4),
        "fr.niche": WordScene(sound: .woof, critter: .butterfly, count: 3),
        "fr.ruche": WordScene(sound: .beeBuzz, critter: .bee, count: 5),
        "fr.mouche": WordScene(sound: .buzz, critter: .fly, count: 4),
        "fr.vache": WordScene(sound: .moo, critter: .butterfly, count: 3),
        "fr.biche": WordScene(sound: .hooves, critter: .leaf, count: 5),
        "fr.tasse": WordScene(sound: .clink, critter: .heart, count: 3),
        "fr.minouche": WordScene(sound: .meow, critter: .butterfly, count: 3),
        "fr.perruche": WordScene(sound: .tweet, critter: .bird, count: 4),
        "fr.saucisse": WordScene(sound: .sizzle, critter: .spark, count: 4),
        "fr.trousse": WordScene(sound: .zipper, critter: .paint, count: 4),
        "fr.mousse": WordScene(sound: .bubbles, critter: .bubble, count: 6),
        "fr.buche": WordScene(sound: .crackle, critter: .spark, count: 5),
        "fr.tache": WordScene(sound: .splat, critter: .paint, count: 5),
        "fr.peche": WordScene(sound: .plop, critter: .leaf, count: 4),
        "fr.os": WordScene(sound: .crunch, critter: .butterfly, count: 3),
        "fr.police": WordScene(sound: .siren, critter: .star, count: 4),
        "fr.caniche": WordScene(sound: .yap, critter: .heart, count: 3),
        "fr.limace": WordScene(sound: .slime, critter: .drop, count: 5),
        "fr.carrosse": WordScene(sound: .clipClop, critter: .star, count: 5),
        "fr.cactus": WordScene(sound: .maracas, critter: .note, count: 4),
        "fr.cloche": WordScene(sound: .bell, critter: .note, count: 5),
        "fr.glace": WordScene(sound: .lick, critter: .snowflake, count: 5),
        "fr.fleche": WordScene(sound: .arrow, critter: .feather, count: 4),
        "fr.brosse": WordScene(sound: .brushing, critter: .bubble, count: 5),
        "fr.autruche": WordScene(sound: .footsteps, critter: .feather, count: 4),
        "fr.princesse": WordScene(sound: .sparkle, critter: .star, count: 5),
        // English
        "en.fish": WordScene(sound: .blub, critter: .bubble, count: 6),
        "en.dish": WordScene(sound: .clink, critter: .bubble, count: 4),
        "en.push": WordScene(sound: .scrape, critter: .star, count: 3),
        "en.wash": WordScene(sound: .water, critter: .bubble, count: 6),
        "en.goose": WordScene(sound: .honk, critter: .feather, count: 4),
        "en.moose": WordScene(sound: .bellow, critter: .leaf, count: 5),
        "en.ice": WordScene(sound: .iceClink, critter: .snowflake, count: 5),
        "en.piece": WordScene(sound: .click, critter: .star, count: 4),
        "en.bus": WordScene(sound: .horn, critter: .star, count: 3),
        "en.radish": WordScene(sound: .pop, critter: .leaf, count: 4),          // il saute hors de terre
        "en.tennis": WordScene(sound: .pok, critter: .star, count: 3),
        "en.brush": WordScene(sound: .brushing, critter: .heart, count: 3),
        "en.mouse": WordScene(sound: .squeak, critter: .butterfly, count: 3),
        "en.juice": WordScene(sound: .slurp, critter: .bubble, count: 5),
        "en.house": WordScene(sound: .doorbell, critter: .bird, count: 3),
        "en.circus": WordScene(sound: .fanfare, critter: .star, count: 5),
        "en.splash": WordScene(sound: .splash, critter: .drop, count: 6),
    ]
}
