// PagePicker.swift — choisir un dessin : les albums, puis une grille de grandes vignettes.
//
// Un enfant de 3 ans ne lit pas : chaque page se reconnaît à son dessin (les
// traits, et les couleurs qu'il y a déjà mises), chaque album à la vignette de sa
// première page. Une vignette touchée ouvre la page ; la croix, ou un toucher à
// côté du panneau, referme. Les titres écrits sont pour l'adulte qui accompagne.
// Choix : TOUTES les pages de l'album visibles d'un coup, sans défilement (geste de
// plus, et page cachée = page oubliée) — on prend les plus grandes vignettes qui
// tiennent ; on ne défile que si elles deviendraient trop petites. Avec 70 pages,
// c'est album par album (ColoringAlbums.swift : 12 pages au plus chacun) ; l'album
// ouvert d'abord est celui de la page en cours.

#if canImport(SwiftUI)
import EveilDesign
import SwiftUI

struct PagePicker: View {
    let studio: ColoringStudio
    let locale: String
    let onPick: (Int) -> Void
    let onClose: () -> Void
    /// L'album montré (`nil` : celui de la page ouverte).
    @State private var shownAlbum: Int?

    init(studio: ColoringStudio, locale: String, onPick: @escaping (Int) -> Void, onClose: @escaping () -> Void) {
        self.studio = studio
        self.locale = locale
        self.onPick = onPick
        self.onClose = onClose
    }

    private var fr: Bool { locale.hasPrefix("fr") }

    var body: some View {
        GeometryReader { geo in
            let groups = PageGroup.groups(for: studio.pages)
            let current = currentGroup(in: groups)
            let panelWidth = min(geo.size.width - 40, 1100)
            let panelHeight = geo.size.height - 40
            let inner = panelWidth - 2 * GridPlan.padding
            let plan = GridPlan(count: groups[current].pages.count, width: inner,
                                height: GridPlan.gridHeight(panel: panelHeight, albums: groups.count > 1))
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
                    if groups.count > 1 {
                        albumBar(groups, current: current, width: inner)
                    }
                    if plan.fits {
                        grid(plan, pages: groups[current].pages)
                        Spacer(minLength: 0)
                    } else {
                        ScrollView { grid(plan, pages: groups[current].pages).padding(.bottom, 12) }
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

    private func currentGroup(in groups: [PageGroup]) -> Int {
        if let shownAlbum, groups.indices.contains(shownAlbum) { return shownAlbum }
        return groups.firstIndex { $0.pages.contains(studio.pageIndex) } ?? 0
    }

    // MARK: Les albums

    private func albumBar(_ groups: [PageGroup], current: Int, width: CGFloat) -> some View {
        let side = AlbumBar.buttonWidth(count: groups.count, width: width)
        return HStack(spacing: AlbumBar.gap) {
            ForEach(groups.indices, id: \.self) { k in
                albumButton(groups[k], selected: k == current, side: side) { shownAlbum = k }
            }
        }
        .frame(height: AlbumBar.height)
    }

    private func albumButton(_ group: PageGroup, selected: Bool, side: CGFloat,
                             action: @escaping () -> Void) -> some View {
        let thumb = min(side - 8, AlbumBar.thumb)
        return Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Color.white
                    if let first = group.pages.first {
                        LineArtView(page: studio.pages[first]).equatable().padding(thumb * 0.06)
                    }
                }
                .frame(width: thumb, height: thumb)
                .clipShape(RoundedRectangle(cornerRadius: thumb * 0.2, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: thumb * 0.2, style: .continuous)
                        .stroke(selected ? EveilPalette.go : Color.black.opacity(0.12), lineWidth: selected ? 5 : 2)
                )
                Text(group.title(locale: locale))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(EveilPalette.ink.opacity(selected ? 1 : 0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: side, height: AlbumBar.labelHeight)
            }
            .frame(width: side)
            .scaleEffect(selected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(group.title(locale: locale))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Les pages de l'album

    private func grid(_ plan: GridPlan, pages: [Int]) -> some View {
        Grid(horizontalSpacing: GridPlan.gap, verticalSpacing: GridPlan.gap) {
            ForEach(0..<plan.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<plan.columns, id: \.self) { col in
                        let k = row * plan.columns + col
                        if k < pages.count {
                            card(pages[k], side: plan.thumb)
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

/// Un album tel que le choix des pages le montre : son titre et ses pages (index dans `studio.pages`).
struct PageGroup {
    let titleFR: String
    let titleEN: String
    let pages: [Int]

    func title(locale: String) -> String { locale.hasPrefix("fr") ? titleFR : titleEN }

    /// Les albums de `ColoringPages.albums`, rapportés aux pages de l'atelier ; les pages
    /// hors album (atelier de test) forment un dernier groupe.
    static func groups(for pages: [ColoringPage]) -> [PageGroup] {
        var indexOf: [String: Int] = [:]
        for (i, page) in pages.enumerated() { indexOf[page.id] = i }
        var groups: [PageGroup] = []
        var placed = Set<Int>()
        for album in ColoringPages.albums {
            let members = album.pages.compactMap { indexOf[$0.id] }
            guard !members.isEmpty else { continue }
            placed.formUnion(members)
            groups.append(PageGroup(titleFR: album.titleFR, titleEN: album.titleEN, pages: members))
        }
        let others = pages.indices.filter { !placed.contains($0) }
        if !others.isEmpty {
            groups.append(PageGroup(titleFR: "Autres dessins", titleEN: "More pictures", pages: others))
        }
        return groups
    }
}

/// La rangée des albums, au-dessus des pages.
enum AlbumBar {
    static let height: CGFloat = 96
    static let thumb: CGFloat = 66
    static let labelHeight: CGFloat = 22
    static let gap: CGFloat = 10

    /// Largeur d'un bouton d'album pour que la rangée tienne dans `width`.
    static func buttonWidth(count: Int, width: CGFloat) -> CGFloat {
        let n = CGFloat(max(count, 1))
        return min(130, floor((width - (n - 1) * gap) / n))
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

    /// Hauteur laissée à la grille dans un panneau de hauteur `panel` (titre, rangée des albums).
    static func gridHeight(panel: CGFloat, albums: Bool) -> CGFloat {
        panel - 2 * padding - titleHeight - 18 - (albums ? AlbumBar.height + 18 : 0)
    }

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
