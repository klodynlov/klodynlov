// EarGames.swift — les jeux d'écoute : le loto des bruits et « Où est… ? » (la logique).
//
// « Voire plus » qu'OrthoPicto (28/09/2026) : deux petits jeux d'ÉCOUTE, avec les dessins et les
// bruitages déjà dans l'app :
//   • le loto des bruits — un bruit joue (« meuh ») ; trois images ; laquelle fait ce bruit ?
//     (discrimination auditive, vocabulaire) ;
//   • « Où est… ? » — la voix demande « Où est la pêche ? » ; 2 à 4 images (compréhension
//     du vocabulaire).
// Jamais « faux » : toucher une autre image la fait sonner et la NOMME (« Ça, c'est le chat. »),
// puis on réécoute. Les manches se suivent dans un ORDRE FIXE (rien n'est tiré au hasard,
// docs/EVEIL.md § 4.6) : `round` avance d'une manche à l'autre. Fonctions pures : testées.

import EveilSounds
import PhraseCore

/// Une image du loto : son dessin, son bruit, son nom (avec l'article).
struct EarItem: Equatable, Sendable {
    let drawing: String
    let sound: SoundEffect
    let fr: String
    let en: String

    func name(locale: String) -> String { locale.hasPrefix("fr") ? fr : en }
}

/// Une manche : les images proposées (dans l'ordre d'affichage) et celle qu'on cherche.
struct EarRound: Equatable, Sendable {
    let choices: [String]       // dessins
    let answer: Int             // indice de la bonne image
}

enum EarGames {
    /// Les images du loto : des bruits bien distincts, reconnaissables à 3 ans.
    static let lotoItems: [EarItem] = [
        EarItem(drawing: "fr.vache", sound: .moo, fr: "la vache", en: "the cow"),
        EarItem(drawing: "fr.minouche", sound: .meow, fr: "le chat", en: "the cat"),
        EarItem(drawing: "fr.niche", sound: .woof, fr: "le chien", en: "the dog"),
        EarItem(drawing: "fr.perruche", sound: .tweet, fr: "l'oiseau", en: "the bird"),
        EarItem(drawing: "fr.mouche", sound: .buzz, fr: "la mouche", en: "the fly"),
        EarItem(drawing: "fr.ruche", sound: .beeBuzz, fr: "les abeilles", en: "the bees"),
        EarItem(drawing: "en.goose", sound: .honk, fr: "l'oie", en: "the goose"),
        EarItem(drawing: "en.mouse", sound: .squeak, fr: "la souris", en: "the mouse"),
        EarItem(drawing: "fr.police", sound: .siren, fr: "la police", en: "the police car"),
        EarItem(drawing: "en.bus", sound: .horn, fr: "le bus", en: "the bus"),
        EarItem(drawing: "fr.carrosse", sound: .clipClop, fr: "le carrosse", en: "the carriage"),
        EarItem(drawing: "fr.cloche", sound: .bell, fr: "la cloche", en: "the bell"),
        EarItem(drawing: "en.house", sound: .doorbell, fr: "la sonnette", en: "the doorbell"),
        EarItem(drawing: "fr.douche", sound: .shower, fr: "la douche", en: "the shower"),
        EarItem(drawing: "en.circus", sound: .fanfare, fr: "le cirque", en: "the circus"),
        EarItem(drawing: "fr.saucisse", sound: .sizzle, fr: "la saucisse", en: "the sausage"),
        EarItem(drawing: "fr.trousse", sound: .zipper, fr: "la trousse", en: "the pencil case"),
        EarItem(drawing: "en.fish", sound: .blub, fr: "le poisson", en: "the fish"),
        EarItem(drawing: "en.splash", sound: .splash, fr: "le plouf", en: "the splash"),
    ]

    static func lotoItem(_ drawing: String) -> EarItem? { lotoItems.first { $0.drawing == drawing } }

    /// Les noms à chercher dans « Où est… ? » : tous les noms dessinés du train des phrases.
    static var findNouns: [PhraseNoun] { PhraseLexicon.nouns }

    /// Une manche : `count` indices distincts dans `0..<pool`, dont le bon (celui qu'on cherche) à la
    /// place `round % count`. Le pas `step` est premier avec la taille des listes : en quelques
    /// manches, toutes les images ont été cherchées.
    static func pick(_ round: Int, pool: Int, count: Int, step: Int = 7) -> (indices: [Int], answer: Int) {
        let n = max(1, pool)
        let k = max(1, min(count, n))
        let target = ((round * step) % n + n) % n
        var picks = [target]
        var j = 1
        while picks.count < k && j <= n {
            let candidate = (target + j * 3) % n
            if !picks.contains(candidate) { picks.append(candidate) }
            j += 1
        }
        // La bonne image change de place d'une manche à l'autre.
        let slot = ((round % picks.count) + picks.count) % picks.count
        picks.swapAt(0, slot)
        return (picks, slot)
    }

    /// Manche du loto : trois images du loto.
    static func lotoRound(_ r: Int) -> EarRound {
        let p = pick(r, pool: lotoItems.count, count: 3)
        return EarRound(choices: p.indices.map { lotoItems[$0].drawing }, answer: p.answer)
    }

    /// Manche de « Où est… ? » : `count` images (2 à 4) parmi les noms dessinés (identifiants des noms).
    static func findRound(_ r: Int, count: Int) -> EarRound {
        let nouns = findNouns
        let p = pick(r, pool: nouns.count, count: min(4, max(2, count)), step: 5)
        return EarRound(choices: p.indices.map { nouns[$0].id }, answer: p.answer)
    }

    // MARK: Les phrases de la voix

    static func findQuestion(_ noun: PhraseNoun, locale: String) -> String {
        let np = PhraseGrammar.nounPhrase(noun, locale: locale)
        return locale.hasPrefix("fr") ? "Où est \(np) ?" : "Where is \(np)?"
    }

    static func yes(_ name: String, locale: String) -> String {
        locale.hasPrefix("fr") ? "Oui ! C'est \(name) !" : "Yes! It's \(name)!"
    }

    /// Ce qu'on dit quand l'enfant touche une AUTRE image : on la nomme, sans jamais dire « non ».
    static func thatIs(_ name: String, locale: String) -> String {
        locale.hasPrefix("fr") ? "Ça, c'est \(name)." : "That's \(name)."
    }
}
