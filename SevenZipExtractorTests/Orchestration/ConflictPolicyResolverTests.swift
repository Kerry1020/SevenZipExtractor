import XCTest
@testable import SevenZipExtractor

final class ConflictPolicyResolverTests: XCTestCase {
    func testPolicyForBackendReturnsSamePreference() {
        let resolver = ConflictPolicyResolver()

        XCTAssertEqual(resolver.policyForBackend(.ask), .ask)
        XCTAssertEqual(resolver.policyForBackend(.skipAll), .skipAll)
        XCTAssertEqual(resolver.policyForBackend(.replaceAll), .replaceAll)
        XCTAssertEqual(resolver.policyForBackend(.autoRename), .autoRename)
    }

    func testMapAskCancellationReturnsCancelledFailure() {
        let resolver = ConflictPolicyResolver()

        XCTAssertEqual(resolver.mapAskCancellation(), .failure(.cancelled))
    }
}
