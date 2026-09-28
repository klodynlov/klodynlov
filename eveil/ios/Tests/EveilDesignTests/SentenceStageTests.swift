// SentenceStageTests.swift — la phrase jouée : chaque verbe bouge, puis revient au repos.
//
// Garanties sur les 20 mouvements du train des phrases (`SentenceMotion`), avec trois
// mises en scène (le sujet seul, avec un objet, dans un lieu) :
//   - au début, tout est au repos (pas de saut quand la phrase commence) ;
//   - à la fin, le sujet est revenu au repos, sauf ce que le verbe change pour de bon ;
//   - aucune valeur infinie, rien ne s'envole hors de la scène ;
//   - le mouvement bouge vraiment (au milieu, quelque chose a changé).
// Planches (`EVEIL_RENDER_DIR`) : `phrase-<verbe>.png`, cinq instants de la scène.

#if canImport(SwiftUI) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
@testable import EveilDesign
import SwiftUI
import XCTest

final class SentenceStageTests: XCTestCase {
    private let solo = SceneLayout(width: 1.8, subjectBase: CGPoint(x: 0.9, y: 0.9), subjectSize: 0.66)
    private let withObject = SceneLayout(width: 1.8, subjectBase: CGPoint(x: 0.54, y: 0.9), subjectSize: 0.6,
                                         objectBase: CGPoint(x: 1.3, y: 0.9), objectSize: 0.36)
    private let atPlace = SceneLayout(width: 1.8, subjectBase: CGPoint(x: 1.1, y: 0.7), subjectSize: 0.42)

    private func isRest(_ p: ActorPose) -> Bool {
        abs(p.dx) < 1e-6 && abs(p.dy) < 1e-6 && abs(p.rotation) < 1e-6 && abs(p.sx - 1) < 1e-6
            && abs(p.sy - 1) < 1e-6 && p.act == 0 && !p.eyesClosed && !p.turned && p.opacity == 1 && p.scale == 1
    }

    func testEveryVerbStartsAtRest() {
        for verb in SentenceMotion.verbs {
            for layout in [solo, withObject, atPlace] {
                let f = SentenceMotion.frame(verb: verb, t: 0, layout: layout)
                XCTAssertTrue(isRest(f.subject), "\(verb) : le sujet bouge dès t = 0 (\(f.subject))")
                XCTAssertTrue(isRest(f.object), "\(verb) : l'objet bouge dès t = 0 (\(f.object))")
            }
        }
    }

    func testEveryVerbEndsAtRestUnlessItChangesSomething() {
        for verb in SentenceMotion.verbs {
            let end = SentenceMotion.duration(verb)
            let f = SentenceMotion.frame(verb: verb, t: end, layout: withObject)
            if !SentenceMotion.lastingSubject.contains(verb) {
                XCTAssertTrue(isRest(f.subject), "\(verb) : le sujet n'est pas revenu au repos (\(f.subject))")
            }
            if !SentenceMotion.lastingObject.contains(verb) {
                var object = f.object
                object.rotation = object.rotation.truncatingRemainder(dividingBy: 360)   // deux tours = à l'endroit
                XCTAssertTrue(isRest(object), "\(verb) : l'objet n'est pas revenu (\(f.object))")
            }
        }
    }

    /// Les verbes du niveau 2 se jouent toujours avec un objet ; les autres seuls ou dans un lieu.
    private let transitive: Set<String> = ["manger", "boire", "pousser", "porter", "lancer", "laver", "attraper",
                                           "lecher", "sentir", "tirer"]

    func testMotionsAreFiniteAndStayOnStage() {
        for verb in SentenceMotion.verbs {
            for layout in transitive.contains(verb) ? [withObject] : [solo, atPlace] {
                var moved = false
                var t = 0.0
                while t <= SentenceMotion.duration(verb) {
                    let f = SentenceMotion.frame(verb: verb, t: t, layout: layout)
                    for pose in [f.subject, f.object] {
                        for v in [pose.dx, pose.dy, pose.sx, pose.sy, pose.scale] { XCTAssertTrue(v.isFinite, verb) }
                        XCTAssertTrue(pose.rotation.isFinite && pose.act.isFinite && pose.opacity.isFinite, verb)
                        XCTAssertTrue((0...1).contains(pose.act), "\(verb) : action \(pose.act)")
                        XCTAssertGreaterThan(pose.sx, 0, verb)
                        XCTAssertGreaterThan(pose.sy, 0.5, verb)
                    }
                    let x = layout.subjectBase.x + f.subject.dx
                    XCTAssertTrue((-0.2...(layout.width + 0.2)).contains(x), "\(verb) : sujet hors scène en x = \(x)")
                    XCTAssertGreaterThan(layout.subjectBase.y + f.subject.dy, 0.2, "\(verb) : le sujet s'envole trop haut")
                    for p in f.front + f.behind {
                        XCTAssertTrue(p.x.isFinite && p.y.isFinite && p.size.isFinite, verb)
                        XCTAssertTrue((-0.6...(layout.width + 0.6)).contains(p.x), "\(verb) : \(p.kind) hors scène")
                        XCTAssertTrue((-0.8...1.4).contains(p.y), "\(verb) : \(p.kind) hors scène")
                    }
                    if !isRest(f.subject) || !isRest(f.object) || !(f.front + f.behind).isEmpty { moved = true }
                    t += 0.05
                }
                XCTAssertTrue(moved, "\(verb) : rien ne bouge")
            }
        }
    }

    func testCuesHappenDuringTheMotion() {
        for verb in SentenceMotion.verbs {
            for (time, _) in SentenceMotion.cues(verb) {
                XCTAssertTrue((0...SentenceMotion.duration(verb)).contains(time), "\(verb) : son à \(time) s")
            }
        }
        let scene = SentenceScene(subject: "fr.vache", verb: "dormir", place: "lieu.boite", preposition: .dans)
        XCTAssertEqual(SentenceStage.duration(of: scene), SentenceStage.travel + SentenceMotion.duration("dormir"))
        XCTAssertTrue(SentenceStage.cues(of: scene).allSatisfy { $0.0 <= SentenceStage.duration(of: scene) })
    }

    /// À chaque ancre de chaque lieu, le sujet tient dans la scène : pieds au-dessus du bas, haut
    /// de la tête sous le haut. (L'ancre est le bas-milieu du carré du personnage, pas ses pieds :
    /// lue comme des pieds, « sur » enfonçait le chat dans la table et « devant » sortait en bas.)
    func testEveryAnchorKeepsTheSubjectOnStage() {
        let box = StagePainter.placeBox(width: 1.8)
        var checked = 0
        for id in PictoLibrary.ids where id.hasPrefix("lieu.") {
            guard let place = PictoLibrary.drawing(id) else { continue }
            for (preposition, anchor) in place.anchors {
                let stand = StagePainter.stand(at: anchor, in: box)
                XCTAssertLessThan(stand.base.y, 0.99, "\(id) \(preposition) : les pieds sortent en bas")
                XCTAssertGreaterThan(stand.base.y - 0.82 * stand.size, 0, "\(id) \(preposition) : la tête sort en haut")
                let feetInPlace = (stand.base.y - box.minY) / box.height * 200
                XCTAssertEqual(feetInPlace, anchor.y - 21 * anchor.size, accuracy: 1e-6, "\(id) \(preposition)")
                checked += 1
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 30, "les lieux du train des phrases ont leurs ancres")
    }

    /// Planches : cinq instants de quelques phrases (relues à l'œil sur Mac).
    @MainActor
    func testRenderFilmstrips() throws {
        let scenes: [(String, SentenceScene)] = [
            ("phrase-le-chat-mange-la-peche", SentenceScene(subject: "fr.minouche", verb: "manger", object: "fr.peche")),
            ("phrase-la-vache-dort-dans-la-boite",
             SentenceScene(subject: "fr.vache", subjectFacesLeft: true, verb: "dormir", place: "lieu.boite", preposition: .dans)),
            ("phrase-le-chien-pousse-le-bus",
             SentenceScene(subject: "fr.caniche", subjectFacesLeft: true, verb: "pousser", object: "en.bus")),
            ("phrase-la-souris-saute", SentenceScene(subject: "en.mouse", subjectFacesLeft: true, verb: "sauter")),
            ("phrase-l-oie-lance-la-balle",
             SentenceScene(subject: "en.goose", subjectFacesLeft: true, verb: "lancer", object: "en.tennis")),
            ("phrase-le-poisson-nage", SentenceScene(subject: "en.fish", subjectFacesLeft: true, verb: "nager")),
            ("phrase-lou-se-cache", SentenceScene(subject: "perso.lou", verb: "se_cacher")),
        ]
        for (name, scene) in scenes {
            let d = SentenceStage.duration(of: scene)
            let strip = HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { k in
                    Canvas { context, size in
                        StagePainter.paint(context, size: size, scene: scene, t: d * Double(k) / 4)
                    }
                    .frame(width: 320, height: 180)
                }
            }
            XCTAssertNotNil(RenderSupport.render(strip, size: CGSize(width: 5 * 320 + 24, height: 180), name: name))
        }
    }
}
#endif
