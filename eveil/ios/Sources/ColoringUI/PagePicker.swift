// PagePicker.swift — choisir un dessin : une grille de grandes vignettes.
//
// Un enfant de 3 ans ne lit pas : chaque page se reconnaît à son dessin (les
// traits, et les couleurs qu'il y a déjà mises). Une vignette touchée ouvre la
// page ; la croix, ou un toucher à côté du panneau, referme. Le titre écrit
// sous chaque vignette est pour l'adulte qui accompagne.
// Choix : TOUTES les pages visibles d'un coup, sans défilement (geste de plus,
// et page cachée = page oubliée) — on prend les plus grandes vignettes qui
// tiennent ; on ne défile que si elles deviendraient trop petites.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

struct PagePicker: View {
    let studio: ColoringStudio
    let locale: String
    let onPick: (Int) -> Void
    let onClose: () -> Void

    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        GeometryReader { geo in
            let panelWidth = min(geo.size.width - 40, 1100)
            let panelHeight = geo.size.height - 40
            let plan = GridPlan(count: studio.pages.count, width: panelWidth - 2 * GridPlan.padding,
                                height: panelHeight - 2 * GridPlan.padding - GridPlan.titleHeight - 18)
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .accessibilityHidden(true)
                VStack(spacing: 18) {
                    HStack {
                        Text(fr ? "Choisis un dessin" : "Pick a picture")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(EveilPalette.ink)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(EveilPalette.ink)
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(Color(white: 0.93)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(fr ? "Fermer" : "Close")
                    }
                    .frame(height: GridPlan.titleHeight)
                    if plan.fits {
                        grid(plan)
                        Spacer(minLength: 0)
                    } else {
                        ScrollView { grid(plan).padding(.bottom, 12) }
                            .scrollIndicators(.hidden)
                    }
                }
                .padding(GridPlan.padding)
                .frame(width: panelWidth)
                .frame(maxHeight: panelHeight)
                .fixedSize(horizontal: false, vertical: plan.fits)
                .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color(white: 0.99)))
                .compositingGroup()
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func grid(_ plan: GridPlan) -> some View {
        Grid(horizontalSpacing: GridPlan.gap, verticalSpacing: GridPlan.gap) {
            ForEach(0..<plan.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<plan.columns, id: \.self) { col in
                        let i = row * plan.columns + col
                        if i < studio.pages.count {
                            card(i, side: plan.thumb)
                        } else {
                            Color.clear.frame(width: plan.thumb, height: plan.thumb)
                        }
                    }
                }
            }
        }
    }

    private func card(_ i: Int, side: CGFloat) -> some View {
        let page = studio.pages[i]
        let current = i == studio.pageIndex
        return Button { onPick(i) } label: {
            VStack(spacing: 6) {
                ZStack {
                    Color.white
                    if let colored = studio.thumbnails[page.id] {
                        Image(decorative: colored, scale: 1).resizable().interpolation(.medium)
                    }
                    LineArtView(page: page).equatable()
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.08, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                        .stroke(current ? EveilPalette.go : Color.black.opacity(0.12), lineWidth: current ? 6 : 2)
                )
                .compositingGroup()
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                Text(page.title(locale: locale))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(EveilPalette.ink.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: side, height: GridPlan.labelHeight - 6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(page.title(locale: locale))
        .accessibilityAddTraits(current ? .isSelected : [])
    }
}

/// Combien de colonnes, et quelle taille de vignette, pour tout montrer d'un coup.
struct GridPlan {
    static let gap: CGFloat = 20
    static let padding: CGFloat = 26
    static let titleHeight: CGFloat = 64
    static let labelHeight: CGFloat = 34
    /// En dessous, une vignette devient trop petite pour un doigt et un dessin lisible : on défile.
    static let minimumThumb: CGFloat = 120

    let columns: Int
    let rows: Int
    let thumb: CGFloat
    let fits: Bool

    init(count: Int, width: CGFloat, height: CGFloat) {
        let n = max(count, 1)
        for c in 2...8 {
            let t = floor((width - CGFloat(c - 1) * Self.gap) / CGFloat(c))
            let r = (n + c - 1) / c
            let h = CGFloat(r) * (t + Self.labelHeight) + CGFloat(r - 1) * Self.gap
            if h <= height {
                if t >= Self.minimumThumb {
                    (columns, rows, thumb, fits) = (c, r, t, true)
                    return
                }
                break
            }
        }
        let c = width > 900 ? 4 : 3
        (columns, rows, thumb, fits) = (c, (n + c - 1) / c, floor((width - CGFloat(c - 1) * Self.gap) / CGFloat(c)), false)
    }
}
#endif
