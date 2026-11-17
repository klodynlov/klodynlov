// GoldenVectorsTests.swift — parité Swift ↔ Python.
//
// `Resources/golden_vectors.json` est produit par la référence Python
// (`python3 -m wordend.golden`, elle-même couverte par 70+ tests). Ici, on
// régénère les MÊMES signaux (même PRNG, même synthèse) et on exige les mêmes
// analyses et les mêmes verdicts. Si ce test passe, le portage Swift est fidèle.

import Foundation
import XCTest
@testable import WordEndCore

struct Golden: Decodable {
    struct Constants: Decodable {
        let analysisRate: Int
        let frameSize: Int
        let hopSize: Int
    }
    struct SplitMix: Decodable {
        let seed: UInt64
        let u64: [String]
        let unitSeed: UInt64
        let unit: [Double]
    }
    struct FFTCase: Decodable {
        let input: [Double]
        let re: [Double]
        let im: [Double]
    }
    struct Bins: Decodable {
        let low: [Int]
        let high: [Int]
        let centroid: [Int]
    }
    struct Params: Decodable {
        let seed: Int
        let f0Start: Double?
        let f0End: Double?
        let gainDb: Double?
        let snrDb: Double?
        let noise: String?
    }
    struct Target: Decodable {
        let nuclei: Int
        let coda: String?
    }
    struct Signal: Decodable {
        let count: Int
        let sum: Double
        let sumSquares: Double
        let probe: [String: Double]
    }
    struct AnalysisG: Decodable {
        let frames: Int
        let floorRmsDb: Double
        let floorLowDb: Double
        let floorHighDb: Double
        let speech: [Int]?
        let nuclei: [[Double?]]
        let frications: [[Double]]
        let clippedFraction: Double
        let snrDb: Double
    }
    struct Probe: Decodable {
        let index: Int
        let rmsDb: Double
        let lowDb: Double
        let highDb: Double
        let highRatio: Double
        let centroidHz: Double
        let zcrHz: Double
        let peak: Double
    }
    struct Case: Decodable {
        let name: String
        let spec: String
        let params: Params
        let target: Target
        let signal: Signal
        let analysis: AnalysisG
        let frameProbes: [Probe]
        let verdict: Verdict
    }
    let constants: Constants
    let splitmix64: SplitMix
    let fft: FFTCase
    let hannHead: [Double]
    let bandBins: Bins
    let cases: [Case]

    static func load() throws -> Golden {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Resources/golden_vectors.json")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Golden.self, from: Data(contentsOf: url))
    }
}

final class GoldenVectorsTests: XCTestCase {
    private var golden: Golden!

    override func setUpWithError() throws {
        golden = try Golden.load()
    }

    func testConstants() {
        XCTAssertEqual(golden.constants.analysisRate, WordEnd.analysisRate)
        XCTAssertEqual(golden.constants.frameSize, WordEnd.frameSize)
        XCTAssertEqual(golden.constants.hopSize, WordEnd.hopSize)
        XCTAssertEqual(WordEnd.binHz, 46.875)
    }

    func testSplitMix64IsBitExact() {
        var rng = SplitMix64(seed: golden.splitmix64.seed)
        for expected in golden.splitmix64.u64 {
            XCTAssertEqual(rng.nextU64(), UInt64(expected)!)
        }
        var r2 = SplitMix64(seed: golden.splitmix64.unitSeed)
        for expected in golden.splitmix64.unit {
            XCTAssertEqual(r2.nextUnit(), expected, accuracy: 1e-15)
        }
        XCTAssertEqual(SplitMix64(seed: 0).state, 0)
        var zero = SplitMix64(seed: 0)
        XCTAssertEqual(zero.nextU64(), 0xE220_A839_7B1D_CDAF)   // valeur de référence publiée
    }

    func testFFT() {
        let fft = RadixTwoFFT(size: golden.fft.input.count)
        let (re, im) = fft.transform(golden.fft.input)
        for k in re.indices {
            XCTAssertEqual(re[k], golden.fft.re[k], accuracy: 1e-9)
            XCTAssertEqual(im[k], golden.fft.im[k], accuracy: 1e-9)
        }
    }

    func testWindowAndBands() {
        for (i, h) in golden.hannHead.enumerated() {
            XCTAssertEqual(hannWindow[i], h, accuracy: 1e-15)
        }
        let bands = Bands()
        XCTAssertEqual([bandBins(bands.low).0, bandBins(bands.low).1], golden.bandBins.low)
        XCTAssertEqual([bandBins(bands.high).0, bandBins(bands.high).1], golden.bandBins.high)
        XCTAssertEqual([bandBins(bands.centroid).0, bandBins(bands.centroid).1], golden.bandBins.centroid)
    }

    func testEveryCaseMatchesTheReference() {
        for c in golden.cases {
            var u = Utterance(spec: c.spec)
            u.seed = c.params.seed
            if let v = c.params.f0Start { u.f0Start = v }
            if let v = c.params.f0End { u.f0End = v }
            if let v = c.params.gainDb { u.gainDb = v }
            if let v = c.params.snrDb { u.snrDb = v }
            if let v = c.params.noise { u.noise = v }

            // 1. Signal synthétique identique
            let x = Synth.synthesize(u)
            XCTAssertEqual(x.count, c.signal.count, c.name)
            XCTAssertEqual(x.reduce(0, +), c.signal.sum, accuracy: 1e-6, c.name)
            XCTAssertEqual(x.reduce(0) { $0 + $1 * $1 }, c.signal.sumSquares, accuracy: 1e-6, c.name)
            for (key, value) in c.signal.probe {
                XCTAssertEqual(x[Int(key)!], value, accuracy: 1e-8, "\(c.name) x[\(key)]")
            }

            // 2. Analyse identique
            let an = analyze(x)
            let g = c.analysis
            XCTAssertEqual(an.frames.count, g.frames, c.name)
            XCTAssertEqual(an.floorRmsDb, g.floorRmsDb, accuracy: 1e-4, c.name)
            XCTAssertEqual(an.floorLowDb, g.floorLowDb, accuracy: 1e-4, c.name)
            XCTAssertEqual(an.floorHighDb, g.floorHighDb, accuracy: 1e-4, c.name)
            XCTAssertEqual(an.speech.map { [$0.start, $0.end] }, g.speech, c.name)
            XCTAssertEqual(an.nuclei.count, g.nuclei.count, c.name)
            for (n, e) in zip(an.nuclei, g.nuclei) {
                XCTAssertEqual(Double(n.frame), e[0]!, c.name)
                XCTAssertEqual(n.levelDb, e[1]!, accuracy: 1e-4, c.name)
                XCTAssertEqual(Double(n.onset), e[2]!, c.name)
                XCTAssertEqual(Double(n.offset), e[3]!, c.name)
                if let f0 = e[4] {
                    XCTAssertEqual(n.f0Hz ?? -1, f0, accuracy: 1e-3, c.name)
                } else {
                    XCTAssertNil(n.f0Hz, c.name)
                }
            }
            XCTAssertEqual(an.frications.count, g.frications.count, c.name)
            for (f, e) in zip(an.frications, g.frications) {
                XCTAssertEqual(Double(f.start), e[0], c.name)
                XCTAssertEqual(Double(f.end), e[1], c.name)
                XCTAssertEqual(f.centroidHz, e[2], accuracy: 1e-3, c.name)
            }
            XCTAssertEqual(an.clippedFraction, g.clippedFraction, accuracy: 1e-6, c.name)
            XCTAssertEqual(an.snrDb, g.snrDb, accuracy: 1e-4, c.name)

            for p in c.frameProbes {
                let f = an.frames[p.index]
                XCTAssertEqual(f.rmsDb, p.rmsDb, accuracy: 1e-4, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.lowDb, p.lowDb, accuracy: 1e-4, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.highDb, p.highDb, accuracy: 1e-4, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.highRatio, p.highRatio, accuracy: 1e-6, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.centroidHz, p.centroidHz, accuracy: 1e-3, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.zcrHz, p.zcrHz, accuracy: 1e-6, "\(c.name)#\(p.index)")
                XCTAssertEqual(f.peak, p.peak, accuracy: 1e-8, "\(c.name)#\(p.index)")
            }

            // 3. Verdict identique
            let v = evaluate(an, target: Shape(nuclei: c.target.nuclei, coda: c.target.coda))
            let e = c.verdict
            XCTAssertEqual(v.kind, e.kind, c.name)
            XCTAssertEqual(v.heardNuclei, e.heardNuclei, c.name)
            XCTAssertEqual(v.expectedNuclei, e.expectedNuclei, c.name)
            XCTAssertEqual(v.codaExpected, e.codaExpected, c.name)
            XCTAssertEqual(v.codaHeard, e.codaHeard, c.name)
            XCTAssertEqual(v.codaPlace, e.codaPlace, c.name)
            XCTAssertEqual(v.codaMs, e.codaMs, accuracy: 0.05, c.name)
            XCTAssertEqual(v.epenthesis, e.epenthesis, c.name)
            XCTAssertEqual(v.snrDb, e.snrDb, accuracy: 0.011, c.name)
            XCTAssertEqual(v.reasons, e.reasons, c.name)
        }
    }
}
