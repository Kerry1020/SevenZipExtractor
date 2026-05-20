import XCTest
@testable import SevenZipExtractor

final class PreferencesStoreTests: XCTestCase {
    func testInMemoryPasswordStoreSavesLoadsAndClearsSessionPasswords() {
        let archiveURL = URL(fileURLWithPath: "/tmp/archive.7z")
        let store = InMemoryPasswordStore()

        store.save("secret", for: archiveURL)

        XCTAssertEqual(store.load(for: archiveURL), "secret")

        store.clearSessionPasswords()

        XCTAssertNil(store.load(for: archiveURL))
    }

    func testSaveThenLoadRoundTripsPreferencesThroughUserDefaults() throws {
        let suiteName = "\(#fileID).\(#function)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PreferencesStore(
            defaults: defaults,
            passwordStore: InMemoryPasswordStore()
        )
        let preferences = ExtractionPreferences(
            enabledFormats: [.zip, .sevenZip],
            destination: .fixedDirectory(URL(fileURLWithPath: "/tmp/extracted")),
            conflictPolicy: .replaceAll,
            passwordStorage: .rememberForSession,
            completionAction: .revealInFinder,
            showMultiVolumeGuidance: false
        )

        store.save(preferences)

        XCTAssertEqual(store.load(), preferences)
    }

    func testLoadReturnsDefaultValueWhenNoPreferencesAreStored() throws {
        let suiteName = "\(#fileID).\(#function)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PreferencesStore(
            defaults: defaults,
            passwordStore: InMemoryPasswordStore()
        )

        XCTAssertEqual(store.load(), ExtractionPreferences.defaultValue)
    }

    func testLoadReturnsDefaultValueWhenStoredDataIsInvalid() throws {
        let suiteName = "\(#fileID).\(#function)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set(Data("not-json".utf8), forKey: "extractionPreferences")

        let store = PreferencesStore(
            defaults: defaults,
            passwordStore: InMemoryPasswordStore()
        )

        XCTAssertEqual(store.load(), ExtractionPreferences.defaultValue)
    }
}
