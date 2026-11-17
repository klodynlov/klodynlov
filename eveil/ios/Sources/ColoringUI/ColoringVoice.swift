// ColoringVoice.swift — tout ce que la voix de l'atelier peut dire (consignes, couleurs, bravos).
//
// Demande de l'utilisateur (17/11/2026) : la voix du petit train (Supertonic 3, style F5, préparée à
// l'avance) pour toutes les activités. `eveil/outils/voix/generer.py` ne recopie pas nos règles de
// texte : il lit l'inventaire qu'écrit le test `VoiceInventoryTests` à partir de `lines(locale:)`
// ci-dessous. L'atelier dit ces textes-là et pas d'autres : `ColoringView` et `PaperSheet` prennent leurs
// phrases ici, et les consignes viennent de `ColoringInstructions` sur les vraies pages.

#if canImport(SwiftUI) && canImport(AVFoundation)
import SwiftUI

public enum ColoringVoice {
    private static func fr(_ locale: String) -> Bool { locale.hasPrefix("fr") }

    /// Le mode interactif s'allume : « Je t'aide à colorier ! », puis la première consigne (deux morceaux).
    public static func intro(locale: String) -> String {
        fr(locale) ? "Je t'aide à colorier !" : "I'll help you color!"
    }

    /// Après l'intro, quand la page n'a plus de consigne.
    public static func pickColor(locale: String) -> String { fr(locale) ? "Choisis une couleur." : "Pick a color." }

    /// Une consigne réussie.
    public static func bravo(locale: String) -> String { fr(locale) ? "Bravo !" : "Well done!" }

    public static func allDone(locale: String) -> String {
        fr(locale) ? "Tu as fait toutes les consignes ! Continue comme tu veux."
                   : "You did them all! Keep coloring as you like."
    }

    /// « J'ai fini ! »
    public static func masterpiece(locale: String) -> String {
        fr(locale) ? "Bravo ! Quel beau dessin !" : "Well done! What a beautiful picture!"
    }

    /// La page coloriée sur papier arrive sur l'écran.
    public static func comesAlive(locale: String) -> String {
        fr(locale) ? "Bravo ! Ton dessin prend vie !" : "Well done! Your picture comes alive!"
    }

    public static func paperLooking(locale: String) -> String {
        fr(locale) ? "Je regarde ton dessin…" : "Let me look at your picture…"
    }

    public static func paperMissed(locale: String) -> String {
        fr(locale) ? "Je n'ai pas bien vu la page. On réessaie ?" : "I couldn't see the page well. Shall we try again?"
    }

    /// Tout ce que l'atelier peut dire dans cette langue, sans doublon, dans un ordre stable : les phrases
    /// fixes, le nom de chaque couleur (toucher une pastille en mode interactif), et pour chaque page ses
    /// consignes et leurs rappels (« En jaune ! »).
    public static func lines(locale: String) -> [String] {
        var out = [intro(locale: locale), pickColor(locale: locale), bravo(locale: locale), allDone(locale: locale),
                   masterpiece(locale: locale), comesAlive(locale: locale), paperLooking(locale: locale),
                   paperMissed(locale: locale)]
        let palette = ColoringView.palette
        out += palette.map { $0.name(locale: locale) }
        for page in ColoringPages.all {
            for i in ColoringInstructions.list(for: page.parts, palette: palette) {
                out.append(ColoringInstructions.text(i, palette: palette, locale: locale))
                if let reminder = ColoringInstructions.colorReminder(i, palette: palette, locale: locale) {
                    out.append(reminder)
                }
            }
        }
        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }
}
#endif
