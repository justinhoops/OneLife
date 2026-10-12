import Foundation

struct SeededRandom: Codable, Equatable {
    var seed: UInt64
    private(set) var drawCount: UInt64 = 0

    mutating func next(in range: ClosedRange<Int>) -> Int {
        drawCount &+= 1
        let lower = UInt64(bitPattern: Int64(range.lowerBound))
        let upper = UInt64(bitPattern: Int64(range.upperBound))
        let width = upper &- lower &+ 1

        // A zero width represents the full Int range (2^64 values).
        guard width != 0 else {
            return Int(bitPattern: UInt(nextUInt64()))
        }

        // Reject the short modulo tail so every value in the requested range
        // has the same probability. SplitMix64's mixed high bits avoid the
        // short low-bit cycles of the previous LCG.
        let threshold = (0 &- width) % width
        var value = nextUInt64()
        while value < threshold { value = nextUInt64() }
        let offset = value % width
        return Int(bitPattern: UInt(lower &+ offset))
    }

    private mutating func nextUInt64() -> UInt64 {
        seed &+= 0x9E37_79B9_7F4A_7C15
        var value = seed
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
