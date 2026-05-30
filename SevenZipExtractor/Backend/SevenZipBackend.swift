import Foundation

final class SevenZipBackend: SevenZipBackendProtocol {
    private let builder: SevenZipCommandBuilder
    private let runner: ProcessRunning
    private let parser = SevenZipOutputParser()

    init(toolURL: URL, runner: ProcessRunning) {
        self.builder = SevenZipCommandBuilder(toolURL: toolURL)
        self.runner = runner
    }

    func probeArchive(at archiveURL: URL, password: String?) async throws -> ArchiveProbe {
        let output = try await runner.run(
            builder.probeCommand(archiveURL: archiveURL, password: password)
        )
        return parser.parseProbeOutput(output.stdout + output.stderr, archiveURL: archiveURL)
    }

    func extractArchive(
        at archiveURL: URL,
        to destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult {
        let output = try await runner.runWithProgress(
            builder.extractCommand(
                archiveURL: archiveURL,
                destinationURL: destinationURL,
                password: password,
                conflictPolicy: conflictPolicy
            ),
            onProgress: { [weak self] progress in
                self?.onProgress?(progress)
            }
        )

        if output.exitCode == 0 {
            return .success(ExtractionSuccess(destinationURL: destinationURL))
        }

        return .failure(parser.parseExtractFailure(output.stdout + output.stderr))
    }

    /// Called when the backend runner supports progress; set by the coordinator.
    var onProgress: ((ExtractionProgress) -> Void)?

    func cancel() {
        runner.cancel()
    }
}
