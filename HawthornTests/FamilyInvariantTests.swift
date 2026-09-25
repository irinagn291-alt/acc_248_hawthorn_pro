import XCTest
@testable import Hawthorn

/// Surprise only offers recipes whose bottles are owned. A catalog roll is not a match.
final class FamilyInvariantTests: XCTestCase {
    func testSurpriseFiltersByOwnedBottles() {
        let negroni = Recipe(
            id: "negroni",
            name: "Negroni",
            method: "Stir.",
            primaryTriple: PrimaryTriple(bottleIDs: ["gin", "sweet-vermouth", "campari"])
        )
        let sour = Recipe(
            id: "whiskey-sour",
            name: "Whiskey Sour",
            method: "Shake.",
            primaryTriple: PrimaryTriple(bottleIDs: ["bourbon", "lemon", "simple"])
        )
        let owned: Set<String> = ["gin", "sweet-vermouth", "campari"]
        let visible = TinFold.surprise(in: [negroni, sour], owned: owned)
        XCTAssertEqual(visible.map(\.id), ["negroni"])
        XCTAssertNil(TinFold.sample(in: [negroni, sour], tagged: ["bourbon", "lemon", "simple"], owned: owned))
        XCTAssertEqual(
            TinFold.sample(in: [negroni, sour], tagged: owned, owned: owned)?.id,
            "negroni"
        )
    }

    /// tempFactor=(cellarC−13)*0.5 yr; young/approaching/ready/holding/pastPeak from vintage+peak window.
    func testCellarWindowMarksPastPeak() {
        XCTAssertEqual(CellarWindow.tempFactor(cellarC: 13), 0)
        XCTAssertEqual(CellarWindow.tempFactor(cellarC: 15), 1)
        XCTAssertEqual(CellarWindow.tempFactor(cellarC: 11), -1)
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2014, cellarC: 13),
            .young
        )
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2017, cellarC: 13),
            .approaching
        )
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2020, cellarC: 13),
            .ready
        )
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2025, cellarC: 13),
            .holding
        )
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2028, cellarC: 13),
            .pastPeak
        )
        XCTAssertEqual(
            CellarWindow.band(vintage: 2010, peakStart: 8, peakEnd: 15, year: 2016, cellarC: 15),
            .approaching
        )
        XCTAssertEqual(CellarWindow.agedYears(vintage: 2010, year: 2016, cellarC: 15), 7)
    }
}
