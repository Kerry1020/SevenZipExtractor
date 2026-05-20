import XCTest
@testable import SevenZipExtractor

final class AppLaunchSmokeTests: XCTestCase {
    func testLaunchModeSettingsEqualsItself() {
        XCTAssertEqual(LaunchMode.settings, .settings)
    }
}
