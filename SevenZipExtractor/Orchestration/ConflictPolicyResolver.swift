import Foundation

struct ConflictPolicyResolver {
    func policyForBackend(_ preference: ConflictPolicy) -> ConflictPolicy {
        preference
    }

    func mapAskCancellation() -> ExtractionResult {
        .failure(.cancelled)
    }
}
