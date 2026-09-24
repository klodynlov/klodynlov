// AccelerateSpectrum.swift — backend vDSP optionnel pour le spectre de puissance.
//
// Pas nécessaire au budget CPU (512 points × 100 trames/s), mais demandé par le
// cahier des charges et utile si l'on monte en résolution. Contrat : même
// spectre de puissance que `RadixTwoFFT.powerSpectrum` (DFT mathématique, non
// mise à l'échelle), à la précision Float près — vérifié par
// `AccelerateParityTests` sur macOS/iOS.
//
// API vérifiée dans la doc Apple : `vDSP.FFT(log2n:radix:ofType:)` (iOS 13),
// `forward(input:output:)` sur `DSPSplitComplex` = FFT réelle « empaquetée ».

#if canImport(Accelerate)
import Accelerate

public final class AccelerateSpectrum {
    public let size: Int
    private let setup: vDSP.FFT<DSPSplitComplex>

    public init?(size: Int) {
        guard size >= 4, size & (size - 1) == 0 else { return nil }
        let log2n = vDSP_Length(Int(log2(Double(size))))
        guard let setup = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
            return nil
        }
        self.size = size
        self.setup = setup
    }

    /// |X[k]|² pour k = 0 … size/2, à l'échelle de la DFT mathématique.
    public func powerSpectrum(_ input: [Double]) -> [Double] {
        precondition(input.count == size)
        let half = size / 2
        // Empaquetage d'un signal réel : z[k] = x[2k] + i·x[2k+1].
        var realIn = [Float](repeating: 0, count: half)
        var imagIn = [Float](repeating: 0, count: half)
        for k in 0..<half {
            realIn[k] = Float(input[2 * k])
            imagIn[k] = Float(input[2 * k + 1])
        }
        var realOut = [Float](repeating: 0, count: half)
        var imagOut = [Float](repeating: 0, count: half)
        realIn.withUnsafeMutableBufferPointer { rIn in
            imagIn.withUnsafeMutableBufferPointer { iIn in
                realOut.withUnsafeMutableBufferPointer { rOut in
                    imagOut.withUnsafeMutableBufferPointer { iOut in
                        let src = DSPSplitComplex(realp: rIn.baseAddress!, imagp: iIn.baseAddress!)
                        var dst = DSPSplitComplex(realp: rOut.baseAddress!, imagp: iOut.baseAddress!)
                        setup.forward(input: src, output: &dst)
                    }
                }
            }
        }
        // FFT réelle vDSP : sortie = 2 × DFT ; composante continue dans realOut[0],
        // Nyquist dans imagOut[0].
        var power = [Double](repeating: 0, count: half + 1)
        let dc = Double(realOut[0]) / 2
        let nyquist = Double(imagOut[0]) / 2
        power[0] = dc * dc
        power[half] = nyquist * nyquist
        for k in 1..<half {
            let re = Double(realOut[k]) / 2
            let im = Double(imagOut[k]) / 2
            power[k] = re * re + im * im
        }
        return power
    }
}
#endif
