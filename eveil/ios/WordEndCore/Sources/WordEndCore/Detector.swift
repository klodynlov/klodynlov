// Detector.swift — le détecteur de fin de mot, portage ligne à ligne de
// `eveil/reference/wordend/detector.py`.
//
// Chaîne : trames → planchers de bruit → région de parole → noyaux syllabiques
// (pics d'énergie en bande « voyelle », voisés, séparés par un creux — critère
// à la de Jong & Wempe 2009) → segments de friction (énergie haute fréquence
// nettement au-dessus du plancher) → verdict comparé au mot cible.
//
// Principe directeur : ASYMÉTRIE DES ERREURS. Dire « il manque la fin » à un
// enfant qui l'a prononcée est l'erreur la plus coûteuse. On n'affirme une
// absence que sur une PREUVE d'absence ; dans le doute : `.unsure`, et
// l'interface reste neutre (`FeedbackPolicy`).

import Foundation

/// Ce que le détecteur doit savoir du mot cible.
public protocol TargetShape {
    /// Nombre de syllabes orales (noyaux vocaliques).
    var nuclei: Int { get }
    /// Consonne finale attendue (`"S"` = /ʃ/, `"s"` = /s/) ou nil.
    var coda: String? { get }
}

/// Cible minimale (tests, banc, mots personnels).
public struct Shape: TargetShape, Equatable, Sendable {
    public var nuclei: Int
    public var coda: String?
    public init(nuclei: Int, coda: String?) {
        self.nuclei = nuclei
        self.coda = coda
    }
}

/// Seuils du détecteur : valeurs de DÉPART, à recalibrer sur le corpus annoté
/// du protocole de validation (banc `wordend.bench`).
public struct DetectorConfig: Equatable, Sendable {
    public var bands = Bands()
    public var floorPercentile = 0.10
    public var vadOnDb = 10.0
    public var vadMinMs = 50.0
    public var vadMergeGapMs = 450.0             // un enfant peut segmenter (« mi… nouche »)
    public var otherRegionMaxBelowDb = 10.0       // 2e énoncé « comparable » ⇒ incertain
    public var envelopeSmoothFrames = 5
    public var nucleusMinAboveFloorDb = 15.0
    public var nucleusMaxBelowPeakDb = 20.0
    public var nucleusMaxZcrHz = 3000.0
    public var nucleusMaxHighRatio = 0.5
    public var nucleusMinDipDb = 3.0
    public var vowelOffsetDropDb = 10.0
    public var fricMinAboveFloorDb = 10.0
    public var fricMinHighRatio = 0.7
    public var fricMinZcrHz = 3000.0
    public var fricMinMs = 50.0
    public var fricMergeGapMs = 20.0
    public var codaMaxGapMs = 150.0
    public var absenceGuardMs = 30.0
    public var absenceWindowMs = 250.0
    public var absenceMaxAboveFloorDb = 6.0
    public var absenceMaxFraction = 0.2
    public var minSnrDb = 20.0
    public var epenthesisMinDropDb = 6.0
    public var clipLevel = 0.99
    public var clipMaxFraction = 0.005
    public var adultF0MaxHz = 165.0
    public var postalveolarMaxCentroidHz = 6000.0   // /ʃ/ vs /s/ — à calibrer (enfants)
    public init() {}
}

public enum VerdictKind: String, Codable, CaseIterable, Sendable {
    case noSpeech = "no_speech"
    case complete
    case missingFinalConsonant = "missing_final_consonant"
    case fewerSyllables = "fewer_syllables"
    case unsure
}

public struct Nucleus: Equatable, Sendable {
    public let frame: Int
    public let levelDb: Double
    public let onset: Int
    public let offset: Int
    public let f0Hz: Double?
}

public struct Frication: Equatable, Sendable {
    public let start: Int
    public let end: Int
    public let centroidHz: Double
    public let peakHighDb: Double
    public var frames: Int { end - start + 1 }
}

public struct SpeechRegion: Equatable, Sendable {
    public let start: Int
    public let end: Int
}

public struct Analysis: Sendable {
    public let frames: [FrameFeatures]
    public let floorRmsDb: Double
    public let floorLowDb: Double
    public let floorHighDb: Double
    public let envelope: [Double]
    public let speech: SpeechRegion?
    public let nuclei: [Nucleus]
    public let frications: [Frication]
    public let clippedFraction: Double
    public let snrDb: Double
    public let otherRegions: Int
}

public struct Verdict: Equatable, Codable, Sendable {
    public var kind: VerdictKind
    public var heardNuclei: Int
    public var expectedNuclei: Int
    public var codaExpected: Bool
    public var codaHeard: Bool
    public var codaPlace: String?       // "postalveolar" (/ʃ/-like) | "alveolar" (/s/-like)
    public var codaMs: Double
    public var epenthesis: Bool
    public var snrDb: Double
    public var reasons: [String]
}

// MARK: - Analyse

typealias Run = (start: Int, end: Int)

func runs(_ flags: [Bool]) -> [Run] {
    var out: [Run] = []
    var start: Int?
    for (i, f) in flags.enumerated() {
        if f, start == nil {
            start = i
        } else if !f, let s = start {
            out.append((s, i - 1))
            start = nil
        }
    }
    if let s = start { out.append((s, flags.count - 1)) }
    return out
}

func merge(_ rs: [Run], maxGap: Int) -> [Run] {
    var merged: [Run] = []
    for r in rs {
        if let last = merged.last, r.start - last.end - 1 <= maxGap {
            merged[merged.count - 1] = (last.start, r.end)
        } else {
            merged.append(r)
        }
    }
    return merged
}

/// Premier indice minimisant `key` (comme `min(range, key=…)` en Python).
func argmin(_ range: ClosedRange<Int>, _ key: (Int) -> Double) -> Int {
    var best = range.lowerBound
    for i in range where key(i) < key(best) { best = i }
    return best
}

func speechRegions(_ frames: [FrameFeatures], floorRms: Double,
                   _ cfg: DetectorConfig) -> (SpeechRegion?, Int) {
    let active = frames.map { $0.rmsDb >= floorRms + cfg.vadOnDb }
    let rs = merge(runs(active), maxGap: WordEnd.msToFrames(cfg.vadMergeGapMs))
        .filter { $0.end - $0.start + 1 >= WordEnd.msToFrames(cfg.vadMinMs) }
    guard !rs.isEmpty else { return (nil, 0) }
    let peaks = rs.map { r in frames[r.start...r.end].map(\.lowDb).max()! }
    var main = 0
    for i in 1..<max(rs.count, 1) where peaks[i] > peaks[main] { main = i }
    var others = 0
    for i in rs.indices where i != main && peaks[i] >= peaks[main] - cfg.otherRegionMaxBelowDb {
        others += 1
    }
    return (SpeechRegion(start: rs[main].start, end: rs[main].end), others)
}

func findNuclei(_ env: [Double], _ frames: [FrameFeatures], _ region: SpeechRegion,
                floorLow: Double, _ cfg: DetectorConfig) -> [Nucleus] {
    let a = region.start
    let b = region.end
    var cands: [Int] = []
    for t in a...b {
        let left = t - 1 >= a ? env[t - 1] : -Double.infinity
        let right = t + 1 <= b ? env[t + 1] : -Double.infinity
        if env[t] > left && env[t] >= right {
            let f = frames[t]
            if env[t] >= floorLow + cfg.nucleusMinAboveFloorDb
                && f.zcrHz <= cfg.nucleusMaxZcrHz
                && f.highRatio <= cfg.nucleusMaxHighRatio {
                cands.append(t)
            }
        }
    }
    var kept: [Int] = []
    for t in cands {
        guard let q = kept.last else {
            kept.append(t)
            continue
        }
        let dip = env[q...t].min()!
        if env[q] - dip >= cfg.nucleusMinDipDb && env[t] - dip >= cfg.nucleusMinDipDb {
            kept.append(t)
        } else if env[t] > env[q] {
            kept[kept.count - 1] = t
        }
    }
    if let top = kept.map({ env[$0] }).max() {
        kept = kept.filter { env[$0] >= top - cfg.nucleusMaxBelowPeakDb }
    }
    var nuclei: [Nucleus] = []
    for (i, t) in kept.enumerated() {
        let loLim = i == 0 ? a : argmin(kept[i - 1]...t, { env[$0] })
        let hiLim = i == kept.count - 1 ? b : argmin(t...kept[i + 1], { env[$0] })
        let level = env[t] - cfg.vowelOffsetDropDb
        var s = t
        while s - 1 >= loLim && env[s - 1] >= level { s -= 1 }
        var e = t
        while e + 1 <= hiLim && env[e + 1] >= level { e += 1 }
        nuclei.append(Nucleus(frame: t, levelDb: env[t], onset: s, offset: e, f0Hz: nil))
    }
    return nuclei
}

func findFrications(_ frames: [FrameFeatures], floorHigh: Double, _ cfg: DetectorConfig) -> [Frication] {
    let flags = frames.map {
        $0.highRatio >= cfg.fricMinHighRatio
            && $0.highDb >= floorHigh + cfg.fricMinAboveFloorDb
            && $0.zcrHz >= cfg.fricMinZcrHz
    }
    var out: [Frication] = []
    for r in merge(runs(flags), maxGap: WordEnd.msToFrames(cfg.fricMergeGapMs))
    where r.end - r.start + 1 >= WordEnd.msToFrames(cfg.fricMinMs) {
        let seg = frames[r.start...r.end]
        var total = 0.0
        for f in seg { total += f.centroidHz }
        out.append(Frication(start: r.start, end: r.end, centroidHz: total / Double(seg.count),
                             peakHighDb: seg.map(\.highDb).max()!))
    }
    return out
}

/// Analyse à partir de trames déjà calculées (chemin commun lots / flux).
public func analyzeFrames(_ frames: [FrameFeatures], samples: [Double],
                          config cfg: DetectorConfig = DetectorConfig(), withF0: Bool = true) -> Analysis {
    guard !frames.isEmpty else {
        return Analysis(frames: [], floorRmsDb: 0, floorLowDb: 0, floorHighDb: 0, envelope: [],
                        speech: nil, nuclei: [], frications: [], clippedFraction: 0, snrDb: 0,
                        otherRegions: 0)
    }
    let floorRms = percentile(frames.map(\.rmsDb), cfg.floorPercentile)
    let floorLow = percentile(frames.map(\.lowDb), cfg.floorPercentile)
    let floorHigh = percentile(frames.map(\.highDb), cfg.floorPercentile)
    let env = movingAverage(frames.map(\.lowDb), width: cfg.envelopeSmoothFrames)
    let (region, others) = speechRegions(frames, floorRms: floorRms, cfg)
    var nuclei: [Nucleus] = []
    var clipped = 0.0
    var snr = 0.0
    if let region {
        nuclei = findNuclei(env, frames, region, floorLow: floorLow, cfg)
        if withF0 {
            nuclei = nuclei.map {
                Nucleus(frame: $0.frame, levelDb: $0.levelDb, onset: $0.onset, offset: $0.offset,
                        f0Hz: estimateF0(samples, frameIndex: $0.frame))
            }
        }
        let s0 = region.start * WordEnd.hopSize
        let s1 = min(samples.count, region.end * WordEnd.hopSize + WordEnd.frameSize)
        if s1 > s0 {
            var count = 0
            for i in s0..<s1 where abs(samples[i]) >= cfg.clipLevel { count += 1 }
            clipped = Double(count) / Double(s1 - s0)
        }
        let top = nuclei.map(\.levelDb).max() ?? env[region.start...region.end].max()!
        snr = top - floorLow
    }
    let fr = findFrications(frames, floorHigh: floorHigh, cfg)
    return Analysis(frames: frames, floorRmsDb: floorRms, floorLowDb: floorLow, floorHighDb: floorHigh,
                    envelope: env, speech: region, nuclei: nuclei, frications: fr,
                    clippedFraction: clipped, snrDb: snr, otherRegions: others)
}

/// Analyse complète d'un énoncé (mono, flottants dans [-1, 1]).
public func analyze(_ samples: [Double], rate: Int = WordEnd.analysisRate,
                    config cfg: DetectorConfig = DetectorConfig()) -> Analysis {
    let x = rate == WordEnd.analysisRate ? samples : resample(samples, from: rate)
    return analyzeFrames(FeatureExtractor(bands: cfg.bands).frames(x), samples: x, config: cfg)
}

// MARK: - Verdict

func codaAfter(_ n: Nucleus, _ frications: [Frication], _ cfg: DetectorConfig) -> Frication? {
    let gap = WordEnd.msToFrames(cfg.codaMaxGapMs)
    return frications.first { n.frame <= $0.start && $0.start <= n.offset + gap }
}

func median(_ values: [Double]) -> Double {
    let s = values.sorted()
    let m = s.count / 2
    return s.count % 2 == 1 ? s[m] : 0.5 * (s[m - 1] + s[m])
}

/// Arrondi décimal identique à `round(x, n)` de Python : `printf` arrondit la valeur
/// binaire EXACTE (Darwin comme glibc), alors que `(x * 10ⁿ).rounded()` arrondirait un
/// produit déjà arrondi (ex. 2,675 → 2,68 au lieu de 2,67).
func roundTo(_ x: Double, _ digits: Int) -> Double {
    Double(String(format: "%.\(digits)f", x)) ?? x
}

/// Compare l'analyse au mot cible. Voir le principe d'asymétrie en tête de fichier.
public func evaluate(_ an: Analysis, target: some TargetShape,
                     config cfg: DetectorConfig = DetectorConfig()) -> Verdict {
    let expected = target.nuclei
    let codaExpected = target.coda != nil
    let snrRounded = roundTo(an.snrDb, 2)
    func make(_ kind: VerdictKind, heard: Int, codaHeard: Bool = false, place: String? = nil,
              codaMs: Double = 0, epenthesis: Bool = false, reasons: [String]) -> Verdict {
        Verdict(kind: kind, heardNuclei: heard, expectedNuclei: expected, codaExpected: codaExpected,
                codaHeard: codaHeard, codaPlace: place, codaMs: codaMs, epenthesis: epenthesis,
                snrDb: snrRounded, reasons: reasons)
    }
    guard an.speech != nil else { return make(.noSpeech, heard: 0, reasons: ["no_speech"]) }
    guard !an.nuclei.isEmpty else { return make(.unsure, heard: 0, reasons: ["no_vowel_nucleus"]) }

    var reasons: [String] = []
    var blocking = false                  // interdit tout verdict autre qu'incertain
    if an.clippedFraction > cfg.clipMaxFraction {
        reasons.append("clipping")
        blocking = true
    }
    let f0s = an.nuclei.compactMap(\.f0Hz)
    if !f0s.isEmpty && median(f0s) < cfg.adultF0MaxHz {
        reasons.append("adult_voice_suspected")
        blocking = true
    }
    if an.otherRegions > 0 {
        reasons.append("multiple_utterances")
        blocking = true
    }
    let lowSnr = an.snrDb < cfg.minSnrDb
    if lowSnr { reasons.append("low_snr") }

    let nuclei = an.nuclei
    var heard = nuclei.count
    var coda = codaAfter(nuclei[nuclei.count - 1], an.frications, cfg)
    var epenthesis = false
    if coda == nil && heard >= 2 {
        let prev = nuclei[nuclei.count - 2]
        let last = nuclei[nuclei.count - 1]
        if let c = codaAfter(prev, an.frications, cfg), c.end < last.frame,
           last.levelDb <= prev.levelDb - cfg.epenthesisMinDropDb {
            coda = c
            heard -= 1
            epenthesis = true
            reasons.append("epenthetic_schwa")
        }
    }

    var place: String?
    var codaMs = 0.0
    if let coda {
        place = coda.centroidHz <= cfg.postalveolarMaxCentroidHz ? "postalveolar" : "alveolar"
        codaMs = Double(coda.frames) * WordEnd.frameMs
        if target.coda == "S" && place != "postalveolar" {
            reasons.append("place_differs")
        } else if target.coda == "s" && place != "alveolar" {
            reasons.append("place_differs")
        }
    }
    let codaMsRounded = roundTo(codaMs, 1)
    func verdict(_ kind: VerdictKind, _ extra: [String] = []) -> Verdict {
        make(kind, heard: heard, codaHeard: coda != nil, place: place, codaMs: codaMsRounded,
             epenthesis: epenthesis, reasons: reasons + extra)
    }

    if blocking { return verdict(.unsure) }
    if heard > expected { return verdict(.unsure, ["extra_nuclei"]) }
    if heard < expected { return lowSnr ? verdict(.unsure) : verdict(.fewerSyllables) }
    if !codaExpected || coda != nil { return verdict(.complete) }

    // Consonne finale attendue et non entendue : exiger une PREUVE d'absence.
    if lowSnr { return verdict(.unsure) }
    let last = nuclei[nuclei.count - 1]
    let w0 = last.offset + 1 + WordEnd.msToFrames(cfg.absenceGuardMs)
    let w1 = w0 + WordEnd.msToFrames(cfg.absenceWindowMs)
    if w1 > an.frames.count { return verdict(.unsure, ["truncated"]) }
    var above = 0
    for t in w0..<w1 where an.frames[t].highDb > an.floorHighDb + cfg.absenceMaxAboveFloorDb {
        above += 1
    }
    if Double(above) / Double(w1 - w0) > cfg.absenceMaxFraction {
        return verdict(.unsure, ["coda_ambiguous"])
    }
    return verdict(.missingFinalConsonant)
}

/// Raccourci : analyse + verdict.
public func detect(_ samples: [Double], target: some TargetShape, rate: Int = WordEnd.analysisRate,
                   config cfg: DetectorConfig = DetectorConfig()) -> Verdict {
    evaluate(analyze(samples, rate: rate, config: cfg), target: target, config: cfg)
}
