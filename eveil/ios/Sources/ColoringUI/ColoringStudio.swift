// ColoringStudio.swift — l'état de l'atelier : la page ouverte, ses couleurs, ses zones.
//
// Fait le lien entre l'écran (gestes en coordonnées unité) et la logique pure
// (ZoneMap, PaintLayer) :
// - la carte des zones se calcule HORS du fil principal (tâche détachée), puis
//   reste en cache (les 3 dernières pages) ; la page suivante se prépare d'avance ;
// - une seule couche de couleurs sert toutes les pages : en changeant de page, on
//   garde un instantané compressé (et une vignette) de celle qu'on quitte — l'enfant
//   retrouve son dessin s'il y revient. Rien n'est enregistré sur disque ni envoyé ;
// - `@Observable` : seul le papier se redessine quand les couleurs changent.

#if canImport(SwiftUI)
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class ColoringStudio {
    /// Rayon du pinceau, en unité de page (≈ un doigt d'enfant).
    nonisolated static let brushRadius: CGFloat = 0.027
    /// Taille des vignettes du choix des pages (pixels).
    nonisolated static let thumbnailSide = 256

    let pages: [ColoringPage]
    private(set) var pageIndex = 0
    /// Carte des zones de la page ouverte (`nil` pendant son calcul).
    private(set) var map: ZoneMap?
    /// Les couleurs de la page ouverte, dessinées sous les traits.
    private(set) var image: CGImage?
    private(set) var canUndo = false
    /// Les pages déjà coloriées, en petit (pour le choix des pages).
    private(set) var thumbnails: [String: CGImage] = [:]

    @ObservationIgnored private var layer: PaintLayer?
    @ObservationIgnored private var saved: [String: PaintSnapshot] = [:]
    @ObservationIgnored private var maps: [String: ZoneMap] = [:]
    @ObservationIgnored private var recent: [String] = []
    @ObservationIgnored private var loading: Set<String> = []

    init(pages: [ColoringPage] = ColoringPages.all) {
        self.pages = pages
    }

    var page: ColoringPage { pages[pageIndex] }
    var isReady: Bool { map != nil }

    /// Premier affichage : prépare la couche, la carte de la page, et (en fond) les traits des autres pages.
    func start() {
        guard layer == nil else { return }
        layer = PaintLayer()
        image = layer?.makeImage()
        requestMap(for: page)
        let pages = pages
        Task.detached(priority: .utility) {
            for page in pages { _ = page.lineArt }
        }
    }

    /// Ouvre une page (en gardant les couleurs de celle qu'on quitte).
    func open(_ index: Int) {
        guard pages.indices.contains(index) else { return }
        let paint = ensureLayer()
        guard index != pageIndex else { return }
        saveCurrentPage()
        pageIndex = index
        paint.restore(saved[page.id])
        image = paint.makeImage()
        canUndo = false
        map = maps[page.id]
        if map == nil { requestMap(for: page) } else { touch(page.id); prefetchNext() }
    }

    func nextPage() { open((pageIndex + 1) % pages.count) }

    // MARK: Gestes (coordonnées unité)

    /// Remplit la zone sous le doigt ; `true` si la page a changé.
    @discardableResult
    func fill(at unit: CGPoint, color: PaintColor) -> Bool {
        guard let map, let layer else { return false }
        let zone = map.zone(near: unit)
        guard zone != 0, layer.fill(zone: zone, color: color.packed, in: map) else { return false }
        refresh()
        return true
    }

    /// Pose le pinceau : le trait restera dans la zone touchée.
    func beginStroke(at unit: CGPoint, color: PaintColor) {
        guard let map, let layer else { return }
        let zone = map.zone(near: unit)
        guard zone != 0 else { return }
        layer.beginStroke(at: pixel(unit, map), zone: zone, color: color.packed,
                          radius: Self.brushRadius * CGFloat(map.width), in: map)
        refresh()
    }

    func continueStroke(to unit: CGPoint) {
        guard let map, let layer, layer.isPainting else { return }
        layer.continueStroke(to: pixel(unit, map), in: map)
        refresh()
    }

    /// Lève le pinceau ; `true` si le trait a peint quelque chose.
    @discardableResult
    func endStroke() -> Bool {
        guard let map, let layer, layer.isPainting else { return false }
        let painted = layer.endStroke(in: map)
        refresh()
        return painted
    }

    func undo() {
        guard let layer, layer.undo(in: map) else { return }
        refresh()
    }

    func clear() {
        guard let layer, layer.clear(in: map) else { return }
        refresh()
    }

    /// Met à jour la vignette de la page ouverte (avant d'afficher le choix des pages).
    func refreshThumbnail() {
        guard let layer else { return }
        let snapshot = layer.snapshot()
        thumbnails[page.id] = snapshot.isBlank ? nil : layer.thumbnail(side: Self.thumbnailSide)
    }

    // MARK: Pour les tests et les rendus

    /// Calcule la carte de la page ouverte tout de suite (tests, captures).
    func loadSynchronously() {
        _ = ensureLayer()
        if map == nil {
            let fresh = ZoneMap(lineArt: page.lineArt)
            remember(fresh, for: page.id)
            map = fresh
        }
        refresh()
    }

    // MARK: Interne

    private func ensureLayer() -> PaintLayer {
        if let layer { return layer }
        let fresh = PaintLayer()
        layer = fresh
        return fresh
    }

    private func refresh() {
        image = layer?.makeImage()
        canUndo = layer?.canUndo ?? false
    }

    private func pixel(_ unit: CGPoint, _ map: ZoneMap) -> CGPoint {
        CGPoint(x: unit.x * CGFloat(map.width), y: unit.y * CGFloat(map.height))
    }

    private func saveCurrentPage() {
        guard let layer else { return }
        if let map { layer.endStroke(in: map) }
        let snapshot = layer.snapshot()
        if snapshot.isBlank {
            saved[page.id] = nil
            thumbnails[page.id] = nil
        } else {
            saved[page.id] = snapshot
            thumbnails[page.id] = layer.thumbnail(side: Self.thumbnailSide)
        }
    }

    private func requestMap(for page: ColoringPage) {
        let id = page.id
        if let known = maps[id] {
            if id == self.page.id { map = known }
            return
        }
        guard !loading.contains(id) else { return }
        loading.insert(id)
        Task { [weak self] in
            let fresh = await Task.detached(priority: .userInitiated) { ZoneMap(lineArt: page.lineArt) }.value
            guard let self else { return }
            self.loading.remove(id)
            self.remember(fresh, for: id)
            if self.page.id == id {
                self.map = fresh
                self.prefetchNext()
            }
        }
    }

    private func prefetchNext() {
        requestMap(for: pages[(pageIndex + 1) % pages.count])
    }

    private func remember(_ map: ZoneMap, for id: String) {
        maps[id] = map
        touch(id)
        while recent.count > 3, let oldest = recent.first(where: { $0 != page.id }) {
            recent.removeAll { $0 == oldest }
            maps[oldest] = nil
        }
    }

    private func touch(_ id: String) {
        recent.removeAll { $0 == id }
        recent.append(id)
    }
}
#endif
