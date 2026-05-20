import XCTest
@testable import SevenZipExtractor

final class ExtractionPreferencesTests: XCTestCase {
    func testDefaultValueUsesApprovedDefaults() {
        let preferences = ExtractionPreferences.defaultValue

        XCTAssertEqual(preferences.destination, .sameDirectory)
        XCTAssertEqual(preferences.conflictPolicy, .ask)
        XCTAssertEqual(preferences.passwordStorage, .doNotSave)
        XCTAssertEqual(preferences.completionAction, .doNothing)
        XCTAssertTrue(preferences.showMultiVolumeGuidance)
        XCTAssertTrue(preferences.enabledFormats.contains(.zip))
        XCTAssertTrue(preferences.enabledFormats.contains(.sevenZip))
    }
}
