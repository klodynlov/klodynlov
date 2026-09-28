// ColoringView.swift — l'Atelier de coloriage (app 2), « mode écran ».
//
// Pour les 3 ans et + : réussir à tous les coups. Une page est un DESSIN AU
// TRAIT : chaque aire fermée par les traits est une zone, comme sur papier.
// Le PINCEAU peint au doigt sans jamais déborder (pochoir : le trait reste dans la
// zone où il a commencé). TOUCHER pour remplir la zone d'un coup est un réglage de
// l'adulte (« Remplir d'un toucher », `SuiteSettings`), désactivé par défaut : les
// mouvements de la main font l'intérêt du coloriage. Les couleurs passent SOUS les traits, qui restent nets et visibles :
// rien ne fusionne. Grosses pastilles, annuler, tout effacer (annulable), choisir
// une page parmi de grandes vignettes, page suivante. Rien n'est enregistré ni
// envoyé. Le « mode papier » (photo d'un coloriage réel) viendra ensuite.
//
// Mise en page : portrait = outils à gauche, palette en bas ; paysage = palette en
// colonne à droite, pour garder la plus grande page possible. Pastilles et
// boutons s'adaptent à la place (iPad 11" portrait = 834 pt de large).
//
// Demandes de l'utilisateur (28/09/2026) : « rajouter des couleurs dans la palette,
// la gomme comme outil, plus un mode interactif que l'on peut activer au choix ».
//   • 24 couleurs (dont quatre couleurs de peau) : 3 rangées de 8 en portrait,
//     6 rangées de 4 en paysage — toutes visibles d'un coup, sans défiler ;
//   • la GOMME rend le papier blanc, et reste elle aussi dans la zone touchée ;
//   • le MODE INTERACTIF (bouton baguette magique, éteint par défaut) : la voix nomme
//     la couleur choisie (« bleu ciel ! »), chaque couleur chante sa note quand on
//     peint (gamme pentatonique : jamais de fausse note), et « J'ai fini ! » fait
//     prendre vie au dessin (il danse, les confettis tombent, fanfare, bravo).
//   Choisir un dessin et « page suivante » passent dans l'en-tête.
//
// Consignes (choix de l'utilisateur pour la suite, 28/09/2026), en mode interactif :
//   • la voix donne une consigne, « Colorie le soleil en jaune ! », affichée à la place du titre
//     (la toucher la redit) : une partie nommée de la page et une couleur (ColoringInstructions) ;
//   • réussie quand la partie a reçu assez de cette couleur : étincelles, « Bravo ! », la suivante ;
//   • jamais « faux » : colorier ailleurs ne coûte rien — au deuxième essai ailleurs, la consigne
//     se redit et un anneau montre où ; une autre couleur sur la bonne partie : « En jaune ! » et
//     la bonne pastille s'éclaire ;
//   • au plus cinq consignes par page, puis « Continue comme tu veux ».

#if canImport(SwiftUI) && canImport(AVFoundation)
import EveilDesign
import EveilSounds
import SwiftUI
import WordEndAudio

public struct ColoringView: View {
    public let locale: String
    public let onHome: (() -> Void)?

    @State private var studio: ColoringStudio
    @State private var colorIndex = 0
    @State private var tool: Tool = .fill
    @AppStorage(SuiteSettings.tapToFillKey) private var tapToFill = SuiteSettings.tapToFillDefault
    @AppStorage(SuiteSettings.coloringInteractiveKey) private var interactive = SuiteSettings.coloringInteractiveDefault
    @AppStorage(VoiceCatalog.settingKey) private var voiceId = ""
    @State private var cheer = false
    @State private var cheerTask: Task<Void, Never>?
    @State private var showPicker: Bool
    @State private var voice = ModelVoicePlayer()
    /// « J'ai fini ! » : l'instant où le dessin a pris vie (nil au repos).
    @State private var masterpieceAt: Date?
    /// Consignes du mode interactif : celles de la page, et celle en cours.
    @State private var instructions: [ColoringInstruction] = []
    @State private var step = 0
    /// L'aide : un anneau sur la partie demandée (après deux essais ailleurs).
    @State private var markAt: Date?
    /// La pastille à prendre (après une autre couleur sur la bonne partie).
    @State private var swatchHint: Int?
    @State private var misses = 0
    /// La zone où le dernier geste a commencé (le pinceau y reste).
    @State private var touchedZone = 0
    @State private var instructionTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(locale: String = "fr-FR", onHome: (() -> Void)? = nil) {
        self.init(locale: locale, onHome: onHome, studio: ColoringStudio(), showPicker: false)
    }

    /// Pour les tests et les captures : un atelier déjà préparé.
    init(locale: String, onHome: (() -> Void)?, studio: ColoringStudio, showPicker: Bool) {
        self.locale = locale
        self.onHome = onHome
        _studio = State(initialValue: studio)
        _showPicker = State(initialValue: showPicker)
    }

    enum Tool { case fill, brush, eraser }

    /// Les outils proposés : sans « Remplir d'un toucher », le pinceau et la gomme.
    nonisolated static func tools(tapToFill: Bool) -> [Tool] { tapToFill ? [.fill, .brush, .eraser] : [.brush, .eraser] }

    /// L'outil en main : celui choisi, s'il est proposé ; sinon le pinceau.
    nonisolated static func activeTool(_ chosen: Tool, tapToFill: Bool) -> Tool {
        tools(tapToFill: tapToFill).contains(chosen) ? chosen : .brush
    }

    private var active: Tool { Self.activeTool(tool, tapToFill: tapToFill) }

    /// 24 couleurs, dans l'ordre de l'arc-en-ciel puis les couleurs de peau et les neutres :
    /// en portrait 3 rangées de 8, en paysage 6 rangées de 4 (chaque rangée garde sa famille).
    nonisolated static let palette: [PaintColor] = [
        PaintColor(237, 51, 56, fr: "rouge", en: "red"),
        PaintColor(158, 30, 48, fr: "rouge foncé", en: "dark red"),
        PaintColor(228, 60, 150, fr: "rose vif", en: "hot pink"),
        PaintColor(255, 140, 191, fr: "rose", en: "pink"),
        PaintColor(255, 140, 26, fr: "orange", en: "orange"),
        PaintColor(255, 214, 26, fr: "jaune", en: "yellow"),
        PaintColor(255, 240, 150, fr: "jaune clair", en: "light yellow"),
        PaintColor(168, 222, 82, fr: "vert clair", en: "light green"),
        PaintColor(102, 199, 64, fr: "vert", en: "green"),
        PaintColor(28, 118, 58, fr: "vert foncé", en: "dark green"),
        PaintColor(32, 196, 186, fr: "turquoise", en: "turquoise"),
        PaintColor(51, 179, 242, fr: "bleu ciel", en: "light blue"),
        PaintColor(56, 92, 217, fr: "bleu", en: "blue"),
        PaintColor(30, 42, 112, fr: "bleu nuit", en: "navy blue"),
        PaintColor(148, 87, 219, fr: "violet", en: "purple"),
        PaintColor(204, 166, 240, fr: "mauve", en: "lilac"),
        PaintColor(252, 220, 192, fr: "peau claire", en: "light skin"),
        PaintColor(228, 172, 122, fr: "peau dorée", en: "golden skin"),
        PaintColor(166, 108, 68, fr: "peau brune", en: "brown skin"),
        PaintColor(98, 60, 38, fr: "peau foncée", en: "dark skin"),
        PaintColor(140, 89, 51, fr: "marron", en: "brown"),
        PaintColor(150, 152, 162, fr: "gris", en: "grey"),
        PaintColor(38, 38, 46, fr: "noir", en: "black"),
        PaintColor(247, 247, 247, fr: "blanc", en: "white"),
    ]

    /// La note de chaque couleur (mode interactif) : la palette monte la gamme pentatonique
    /// de `ding` (variantes 0…14), du rouge (le plus grave) au blanc (le plus aigu).
    nonisolated static func note(ofColor index: Int) -> Int {
        guard palette.count > 1 else { return 0 }
        return Int((Double(max(0, min(index, palette.count - 1))) * 14 / Double(palette.count - 1)).rounded())
    }

    private var fr: Bool { locale.hasPrefix("fr") }
    private var color: PaintColor { Self.palette[colorIndex] }
    private var current: ColoringInstruction? { instructions.indices.contains(step) ? instructions[step] : nil }

    public var body: some View {
        GeometryReader { geo in
            let layout = WorkshopLayout(size: geo.size)
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.90), Color(red: 0.99, green: 0.92, blue: 0.84)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                // L'en-tête reste en haut ; la page (et la palette) se centrent dans la place restante.
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: layout.gap)
                    if layout.portrait {
                        HStack(alignment: .center, spacing: layout.gap) {
                            tools(layout)
                            paper(layout)
                        }
                        Spacer(minLength: layout.gap)
                        palette(layout)
                    } else {
                        HStack(alignment: .center, spacing: layout.gap) {
                            tools(layout)
                            paper(layout)
                            palette(layout)
                        }
                    }
                    Spacer(minLength: layout.gap)
                }
                .padding(layout.margin)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let start = masterpieceAt {
                    ConfettiLayer(start: start, colors: Self.palette.map(\.swiftUIColor))
                        .ignoresSafeArea()
                }
                if showPicker {
                    PagePicker(studio: studio, locale: locale,
                               onPick: { index in
                                   studio.open(index)
                                   closePicker()
                               },
                               onClose: closePicker)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            studio.start()
            SoundBoard.shared.isSuspended = false         // le train a pu laisser les sons coupés
            if interactive { startInstructions(after: 1.2) }
        }
        .onChange(of: studio.page.id) { _, _ in
            if interactive { startInstructions(after: 0.6) }
        }
        .onDisappear {
            instructionTask?.cancel()
            voice.stop()
        }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 18) {
            if let onHome {
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(EveilPalette.ink.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fr ? "Retour à l'accueil" : "Back home")
            }
            CatStationMaster(mood: cheer || masterpieceAt != nil ? .cheering : .hello, size: 80)
            if interactive, let current {
                instructionLabel(current)
            } else {
                Text(studio.page.title(locale: locale))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(EveilPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            toolButton("wand.and.stars", selected: interactive, size: WorkshopLayout.headerButton,
                       label: fr ? "Mode interactif" : "Interactive mode", action: toggleInteractive)
            toolButton("square.grid.2x2.fill", selected: false, size: WorkshopLayout.headerButton,
                       label: fr ? "Choisir un dessin" : "Pick a picture", action: openPicker)
            toolButton("arrow.right", selected: false, size: WorkshopLayout.headerButton,
                       label: fr ? "Page suivante" : "Next page") {
                masterpieceAt = nil
                studio.nextPage()
            }
        }
        .frame(height: WorkshopLayout.headerHeight)
        .padding(.horizontal, 8)
    }

    // MARK: Outils

    private func tools(_ layout: WorkshopLayout) -> some View {
        VStack(spacing: layout.tool * 0.18) {
            if tapToFill {
                toolButton("hand.tap.fill", selected: active == .fill, size: layout.tool, label: fr ? "Remplir" : "Fill") {
                    tool = .fill
                }
            }
            toolButton("paintbrush.pointed.fill", selected: active == .brush, size: layout.tool,
                       label: fr ? "Pinceau" : "Brush") { tool = .brush }
            toolButton("eraser.fill", selected: active == .eraser, size: layout.tool,
                       label: fr ? "Gomme" : "Eraser") { tool = .eraser }
            divider(layout)
            toolButton("arrow.uturn.backward", selected: false, size: layout.tool, label: fr ? "Annuler" : "Undo") {
                studio.undo()
            }
            .disabled(!studio.canUndo)
            .opacity(studio.canUndo ? 1 : 0.45)
            toolButton("sparkles", selected: false, size: layout.tool, label: fr ? "Tout effacer" : "Clear all") {
                studio.clear()
            }
            if interactive {
                divider(layout)
                // « J'ai fini ! » : le dessin prend vie (mode interactif).
                toolButton("checkmark", selected: masterpieceAt != nil, size: layout.tool,
                           label: fr ? "J'ai fini !" : "I'm done!", action: finishMasterpiece)
            }
        }
    }

    private func divider(_ layout: WorkshopLayout) -> some View {
        Capsule().fill(EveilPalette.ink.opacity(0.15)).frame(width: layout.tool * 0.7, height: 3)
    }

    private func toolButton(_ symbol: String, selected: Bool, size: CGFloat, label: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(selected ? .white : EveilPalette.ink)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                        .fill(selected ? EveilPalette.go : .white)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Palette

    @ViewBuilder
    private func palette(_ layout: WorkshopLayout) -> some View {
        let s = layout.swatch
        if layout.portrait {
            let perRow = WorkshopLayout.rowPaletteColumns
            VStack(spacing: s * 0.22) {
                ForEach(0..<(Self.palette.count / perRow), id: \.self) { row in
                    HStack(spacing: s * 0.22) {
                        ForEach(0..<perRow, id: \.self) { k in swatch(row * perRow + k, size: s) }
                    }
                }
            }
            .padding(.horizontal, s * 0.36)
            .padding(.vertical, s * 0.2)
            .background(RoundedRectangle(cornerRadius: s * 0.6, style: .continuous).fill(.white.opacity(0.85)))
        } else {
            let perRow = WorkshopLayout.gridPaletteColumns
            VStack(spacing: s * 0.22) {
                ForEach(0..<(Self.palette.count / perRow), id: \.self) { row in
                    HStack(spacing: s * 0.22) {
                        ForEach(0..<perRow, id: \.self) { k in swatch(row * perRow + k, size: s) }
                    }
                }
            }
            .padding(s * 0.3)
            .background(RoundedRectangle(cornerRadius: s * 0.6, style: .continuous).fill(.white.opacity(0.85)))
        }
    }

    private func swatch(_ i: Int, size: CGFloat) -> some View {
        let selected = i == colorIndex
        let hinted = i == swatchHint
        let c = Self.palette[i]
        return Button {
            colorIndex = i
            if tool == .eraser { tool = .brush }          // choisir une couleur, c'est vouloir peindre
            if hinted { swatchHint = nil }
            if interactive { say(c.name(locale: locale)) }
        } label: {
            Circle().fill(c.swiftUIColor)
                .overlay(Circle().stroke(selected ? EveilPalette.ink : Color.black.opacity(0.15),
                                         lineWidth: selected ? 5 : 2))
                .overlay(Circle().stroke(hinted ? EveilPalette.wagonLit : .clear, lineWidth: 6).padding(-9))
                .frame(width: size, height: size)
                .scaleEffect(selected || hinted ? 1.18 : 1)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .animation(reduceMotion ? nil : .spring(duration: 0.25), value: colorIndex)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(c.name(locale: locale))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Page à colorier

    private func paper(_ layout: WorkshopLayout) -> some View {
        // Le dessin danse quand il prend vie : l'horloge ne tourne que pendant la fête.
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: masterpieceAt == nil || reduceMotion)) { timeline in
            let w = Self.dance(since: masterpieceAt, at: timeline.date, reduceMotion: reduceMotion)
            PaperView(studio: studio, side: layout.side,
                      onBegin: touchBegan, onMove: touchMoved, onEnd: touchEnded)
                .overlay(alignment: .topLeading) {
                    if let markAt, let current {
                        InstructionMark(start: markAt, points: current.part.points, side: layout.side,
                                        color: Self.palette[current.colorIndex].swiftUIColor)
                    }
                }
                .scaleEffect(x: 1 + w.stretch, y: 1 - w.stretch, anchor: .bottom)
                .rotationEffect(.degrees(w.tilt))
        }
            .accessibilityElement()
            .accessibilityLabel(fr ? "Page à colorier : \(studio.page.title(locale: locale))"
                                   : "Coloring page: \(studio.page.title(locale: locale))")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }

    // MARK: Gestes

    private func touchBegan(_ unit: CGPoint) {
        touchedZone = studio.zone(near: unit)
        switch active {
        case .fill:
            if studio.fill(at: unit, color: color) { painted() }
        case .brush:
            studio.beginStroke(at: unit, color: color)
        case .eraser:
            studio.beginErase(at: unit)
        }
    }

    private func touchMoved(_ unit: CGPoint) {
        if active != .fill { studio.continueStroke(to: unit) }
    }

    private func touchEnded(_ unit: CGPoint) {
        guard active != .fill else { return }
        studio.continueStroke(to: unit)
        guard studio.endStroke() else { return }
        if active == .eraser {
            if interactive { SoundBoard.shared.play(.whooshSoft) }
        } else {
            painted()
        }
    }

    /// Une zone vient d'être coloriée : le chat se réjouit ; en mode interactif, la couleur chante
    /// et la consigne en cours est regardée.
    private func painted() {
        celebrate()
        if interactive {
            SoundBoard.shared.play(.ding, variant: Self.note(ofColor: colorIndex))
            checkInstruction(zone: touchedZone)
        }
    }

    // MARK: Consignes

    /// Les consignes de la page ouverte ; la première se dit après `delay` secondes.
    private func startInstructions(after delay: Double, intro: String = "") {
        instructionTask?.cancel()
        markAt = nil
        swatchHint = nil
        misses = 0
        step = 0
        instructions = interactive ? ColoringInstructions.list(for: studio.page.parts, palette: Self.palette) : []
        skipDone()
        var text = intro
        if let current {
            text += ColoringInstructions.text(current, palette: Self.palette, locale: locale)
        } else if !intro.isEmpty {
            text += fr ? "Choisis une couleur." : "Pick a color."
        }
        guard !text.isEmpty else { return }
        instructionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled { say(text) }
        }
    }

    /// Une consigne déjà faite (la page retrouvée, ou coloriée d'avance) ne se redemande pas.
    private func skipDone() {
        while let current, studio.isDone(current, palette: Self.palette) { step += 1 }
    }

    /// Après un coup de pinceau (ou un remplissage) dans la zone `zone`.
    private func checkInstruction(zone: Int) {
        guard let current else { return }
        if studio.isDone(current, palette: Self.palette) {
            // Réussi : étincelles, « Bravo ! », puis la consigne suivante.
            markAt = nil
            swatchHint = nil
            misses = 0
            SoundBoard.shared.play(.sparkle)
            step += 1
            skipDone()
            let next = self.current.map { ColoringInstructions.text($0, palette: Self.palette, locale: locale) }
            say(fr ? "Bravo !" : "Well done!")
            instructionTask?.cancel()
            instructionTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                guard !Task.isCancelled else { return }
                say(next ?? (fr ? "Tu as fait toutes les consignes ! Continue comme tu veux."
                                : "You did them all! Keep coloring as you like."))
            }
            return
        }
        let target = Set(current.part.points.map { studio.zone(near: $0) })
        if target.contains(zone) {
            // La bonne partie : avec une autre couleur, on rappelle laquelle (jamais « non »).
            if colorIndex != current.colorIndex {
                swatchHint = current.colorIndex
                say(ColoringInstructions.colorReminder(current, palette: Self.palette, locale: locale))
            }
        } else {
            // Ailleurs : ça ne coûte rien ; au deuxième essai, la consigne se redit et un anneau montre où.
            misses += 1
            if misses >= 2 {
                misses = 0
                showMark()
                say(ColoringInstructions.text(current, palette: Self.palette, locale: locale))
            }
        }
    }

    /// L'anneau d'aide sur la partie demandée ; il s'éteint seul (l'horloge ne tourne pas pour rien).
    private func showMark() {
        let start = Date()
        markAt = start
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(InstructionMark.duration * 1_000_000_000))
            if markAt == start { markAt = nil }
        }
    }

    /// La consigne en cours, à la place du titre : la toucher la redit (et montre où).
    private func instructionLabel(_ i: ColoringInstruction) -> some View {
        let text = ColoringInstructions.text(i, palette: Self.palette, locale: locale)
        return Button {
            showMark()
            say(text)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .bold))
                Text(text)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Circle().fill(Self.palette[i.colorIndex].swiftUIColor)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                    .frame(width: 30, height: 30)
            }
            .foregroundStyle(EveilPalette.ink)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Capsule().fill(.white.opacity(0.9)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityHint(fr ? "Touche pour réentendre la consigne" : "Tap to hear the instruction again")
    }

    // MARK: Mode interactif

    private func toggleInteractive() {
        interactive.toggle()
        if interactive {
            SoundBoard.shared.preload([.ding], variants: Array(0...14))
            SoundBoard.shared.preload([.whooshSoft, .fanfare, .sparkle])
            startInstructions(after: 0, intro: fr ? "Je t'aide à colorier ! " : "I'll help you color! ")
        } else {
            instructionTask?.cancel()
            instructions = []
            markAt = nil
            swatchHint = nil
            voice.stop()
            masterpieceAt = nil
        }
    }

    /// La voix du jeu (celle choisie dans l'espace des grands), sans file d'attente :
    /// une nouvelle phrase coupe la précédente.
    private func say(_ text: String) {
        voice.stop()
        voice.voiceIdentifier = voiceId
        Task { await voice.speak(text, locale: locale, pace: .sentence) }
    }

    /// « J'ai fini ! » : le dessin danse, les confettis tombent, fanfare et bravo.
    private func finishMasterpiece() {
        let start = Date()
        masterpieceAt = start
        SoundBoard.shared.play(.fanfare)
        say(fr ? "Bravo ! Quel beau dessin !" : "Well done! What a beautiful picture!")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(ConfettiLayer.duration * 1_000_000_000))
            if masterpieceAt == start { masterpieceAt = nil }
        }
    }

    /// La danse du dessin : il s'étire et se balance, de moins en moins, puis se pose.
    nonisolated static func dance(since start: Date?, at date: Date, reduceMotion: Bool) -> (stretch: CGFloat, tilt: Double) {
        guard let start, !reduceMotion else { return (0, 0) }
        let t = date.timeIntervalSince(start)
        let length = 1.8
        guard t > 0, t < length else { return (0, 0) }
        let fade = 1 - t / length
        return (CGFloat(0.035 * sin(2 * .pi * 2.5 * t) * fade), 2.2 * sin(2 * .pi * 1.25 * t) * fade)
    }

    private func celebrate() {
        cheerTask?.cancel()
        cheer = true
        cheerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled { cheer = false }
        }
    }

    private func openPicker() {
        masterpieceAt = nil
        studio.refreshThumbnail()
        if reduceMotion { showPicker = true } else { withAnimation(.spring(duration: 0.3)) { showPicker = true } }
    }

    private func closePicker() {
        if reduceMotion { showPicker = false } else { withAnimation(.spring(duration: 0.3)) { showPicker = false } }
    }
}

// MARK: - L'anneau d'aide des consignes

/// Un anneau de la couleur demandée qui bat sur la partie à colorier, quelques secondes.
/// Piloté par l'horloge (TimelineView), comme tout mouvement de l'app.
struct InstructionMark: View {
    let start: Date
    let points: [CGPoint]
    let side: CGFloat
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let duration = 5.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            let fade = t < Self.duration - 1 ? 1 : max(0, Self.duration - t)
            let beat = reduceMotion ? 0 : sin(t * 2 * .pi * 1.1)
            ZStack(alignment: .topLeading) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    let d = side * (0.075 + 0.015 * beat)
                    Circle()
                        .stroke(.white, lineWidth: 11)
                        .overlay(Circle().stroke(color, lineWidth: 6))
                        .frame(width: d, height: d)
                        .position(x: p.x * side, y: p.y * side)
                }
            }
            .frame(width: side, height: side)
            .opacity(fade)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Mise en page

/// Tailles calculées d'après la place disponible (points).
struct WorkshopLayout {
    static let headerHeight: CGFloat = 92
    /// Boutons de l'en-tête (mode interactif, choisir un dessin, page suivante).
    static let headerButton: CGFloat = 64
    /// Palette en rangées (portrait) : 3 rangées de 8 pastilles.
    static let rowPaletteColumns = 8
    /// Largeur d'une rangée, en pastilles : 8 + 7 écarts de 0,22 + marges de 0,36.
    static let rowPaletteSwatches: CGFloat = 10.26
    /// Hauteur des 3 rangées, en pastilles : 3 + 2 écarts de 0,22 + marges de 0,2.
    static let rowPaletteHeight: CGFloat = 3.84
    /// Palette en colonne (paysage) : 6 rangées de 4 pastilles, écarts de 0,22, marges de 0,3.
    static let gridPaletteColumns = 4
    static let gridPaletteWidth: CGFloat = 5.26
    static let gridPaletteHeight: CGFloat = 7.7

    let portrait: Bool
    let margin: CGFloat = 20
    let gap: CGFloat = 18
    /// Côté d'un bouton d'outil, d'une pastille de couleur, de la page.
    let tool: CGFloat
    let swatch: CGFloat
    let side: CGFloat

    init(size: CGSize) {
        portrait = size.height >= size.width
        let middle: CGFloat
        if portrait {
            // La palette garde 40 pt de marge de chaque côté (iPad 11" portrait : 834 pt).
            swatch = min(64, max(40, (size.width - 80) / Self.rowPaletteSwatches))
            middle = size.height - 2 * margin - Self.headerHeight - swatch * Self.rowPaletteHeight - 3 * gap
            tool = min(76, max(52, middle / 7.8))
            side = max(200, min(size.width - 2 * margin - tool - gap, middle))
        } else {
            middle = size.height - 2 * margin - Self.headerHeight - 2 * gap
            swatch = min(64, max(40, middle / Self.gridPaletteHeight))
            tool = min(76, max(52, middle / 7.8))
            side = max(200, min(middle, size.width - 2 * margin - tool - swatch * Self.gridPaletteWidth - 2 * gap))
        }
    }
}

// MARK: - Le papier

/// La page : papier blanc, couleurs de l'enfant, puis les traits nets par-dessus.
/// Un geste est reconnu à son point de départ : si le précédent a été interrompu
/// (geste système, sans « fin »), le toucher suivant repart bien d'un début.
struct PaperView: View {
    let studio: ColoringStudio
    let side: CGFloat
    let onBegin: (CGPoint) -> Void
    let onMove: (CGPoint) -> Void
    let onEnd: (CGPoint) -> Void
    @State private var gestureStart: CGPoint?

    private func unit(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x / side, y: p.y / side) }

    var body: some View {
        ZStack {
            Color.white
            if let image = studio.image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.medium)
            }
            LineArtView(page: studio.page)
                .equatable()
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 0.04, style: .continuous))
        .compositingGroup()     // une seule ombre, celle de la feuille (pas une par trait)
        .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if gestureStart != value.startLocation {
                        gestureStart = value.startLocation
                        onBegin(unit(value.startLocation))
                        if value.location != value.startLocation { onMove(unit(value.location)) }
                    } else {
                        onMove(unit(value.location))
                    }
                }
                .onEnded { value in
                    gestureStart = nil
                    onEnd(unit(value.location))
                }
        )
    }
}

/// Les traits d'une page, en vectoriel (épaisseur proportionnelle à la taille).
struct LineArtView: View, Equatable {
    let page: ColoringPage

    /// Mêmes traits = même page : SwiftUI ne redessine pas les traits quand seules les couleurs changent.
    nonisolated static func == (a: LineArtView, b: LineArtView) -> Bool { a.page.id == b.page.id }

    var body: some View {
        let art = page.lineArt
        Canvas { ctx, size in
            let t = CGAffineTransform(scaleX: size.width, y: size.height)
            ctx.fill(Path(art.ink).applying(t), with: .color(EveilPalette.ink))
            ctx.stroke(Path(art.strokes).applying(t), with: .color(EveilPalette.ink),
                       style: StrokeStyle(lineWidth: art.lineWidth * size.width, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension PaintColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: 1)
    }
}

#Preview {
    ColoringView()
}
#endif
