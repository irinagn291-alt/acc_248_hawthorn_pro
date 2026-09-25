import Foundation

/// Cellar temperature shifts how fast a vintage crosses its peak window.
/// The tin fold stays the home. This is not a rack of years.
enum CellarBand: String, Equatable, Sendable {
    case young
    case approaching
    case ready
    case holding
    case pastPeak
}

enum CellarWindow {
    /// tempFactor = (cellarC − 13) * 0.5 years.
    static func tempFactor(cellarC: Double) -> Double {
        (cellarC - 13) * 0.5
    }

    static func agedYears(vintage: Int, year: Int, cellarC: Double) -> Double {
        Double(year - vintage) + tempFactor(cellarC: cellarC)
    }

    /// young, approaching, ready, holding, then pastPeak from vintage plus the peak window.
    static func band(vintage: Int, peakStart: Int, peakEnd: Int, year: Int, cellarC: Double) -> CellarBand {
        let age = agedYears(vintage: vintage, year: year, cellarC: cellarC)
        let start = Double(peakStart)
        let end = Double(peakEnd)
        if age < start - 1 { return .young }
        if age < start { return .approaching }
        if age < end { return .ready }
        if age < end + 1 { return .holding }
        return .pastPeak
    }
}
