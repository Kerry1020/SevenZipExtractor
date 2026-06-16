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

        // Use Apple's standard LaunchServices archive UTIs rather than
        // custom com.lingion.SevenZipExtractor.archive.* ones — registering
        // a custom UTI would also require UTExportedTypeDeclarations in
        // Info.plist, and Apple already ships canonical types that Finder
        // and `open` recognize.
        XCTAssertTrue(contentTypes.contains("org.7-zip.7z-archive"))
        XCTAssertTrue(contentTypes.contains("com.pkware.zip-archive"))
        XCTAssertTrue(contentTypes.contains("com.rarlab.rar-archive"))
    }

    private var appBundle: Bundle {
        Bundle.main
    }
}
