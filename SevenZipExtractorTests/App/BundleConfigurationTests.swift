import XCTest
@testable import SevenZipExtractor

final class BundleConfigurationTests: XCTestCase {
    func testAppBundleIncludesBundled7zzBinary() throws {
        let toolURL = try SevenZipToolLocator.bundledToolURL(bundle: appBundle)

        XCTAssertEqual(toolURL.lastPathComponent, "7zz")
        XCTAssertTrue(FileManager.default.fileExists(atPath: toolURL.path))
    }

    func testAppBundleDeclaresSupportedArchiveDocumentTypes() throws {
        let documentTypes = try XCTUnwrap(appBundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]])
        let contentTypes = documentTypes
            .flatMap { $0["LSItemContentTypes"] as? [String] ?? [] }

        XCTAssertTrue(contentTypes.contains("com.lingion.SevenZipExtractor.archive.7z"))
        XCTAssertTrue(contentTypes.contains("com.lingion.SevenZipExtractor.archive.zip"))
        XCTAssertTrue(contentTypes.contains("com.lingion.SevenZipExtractor.archive.rar"))
    }

    private var appBundle: Bundle {
        Bundle.main
    }
}
