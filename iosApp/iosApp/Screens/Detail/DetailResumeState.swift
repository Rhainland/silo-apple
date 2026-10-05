import Foundation

/// The watch state a detail page's Play tap resumes from.
///
/// A detail page's item and episode list are snapshots from when the page
/// loaded. Another device can move the position while the page stays open,
/// so a Play tap re-reads the server's watch state and both the resume
/// prompt and the player start use that answer. The page's snapshot is only
/// the fallback when the server can't answer (offline, error, or slow).
enum DetailResumeState: Equatable {
    /// The server's current watch state; nil means it has none for the item.
    case refreshed(LeafItemUserData?)
    /// The server read was skipped, failed, or timed out.
    case unavailable

    /// How long a Play tap waits for the server before falling back to the
    /// page's snapshot, so a stalled request can't leave the tap unanswered.
    static let defaultTimeout: Duration = .seconds(3)

    /// The position to offer and resume from, or nil to play without a
    /// resume prompt. Fresh server state wins over the page snapshot, even
    /// when the server reports no progress at all.
    func resumePosition(cached: LeafItemUserData?) -> Double? {
        let userData: LeafItemUserData?
        switch self {
        case .refreshed(let fresh): userData = fresh
        case .unavailable: userData = cached
        }
        return PlaybackResumePoint.position(
            userData?.positionSeconds,
            duration: userData?.durationSeconds
        )
    }

    /// Runs `fetch`, mapping a thrown error or a fetch slower than `timeout`
    /// to `.unavailable`. The losing branch is cancelled.
    static func load(
        timeout: Duration = defaultTimeout,
        fetch: @escaping @Sendable () async throws -> LeafItemUserData?
    ) async -> DetailResumeState {
        await withTaskGroup(of: DetailResumeState?.self) { group in
            group.addTask {
                do {
                    let userData = try await fetch()
                    return Task.isCancelled ? nil : .refreshed(userData)
                } catch {
                    return .unavailable
                }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? .unavailable
        }
    }
}
