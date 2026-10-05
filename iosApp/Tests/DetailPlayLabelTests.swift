import XCTest
@testable import Silo

final class DetailPlayLabelTests: XCTestCase {
    func testEpisodeInProgressReadsResume() throws {
        let episode = try episode(position: 600, duration: 3000)
        XCTAssertEqual(DetailPlayLabel.episode(episode), "Resume S1·E2")
    }

    func testEpisodeWithoutProgressReadsPlay() throws {
        XCTAssertEqual(DetailPlayLabel.episode(try episode(position: nil, duration: nil)), "Play S1·E2")
    }

    func testFirstThirtySecondsAndLastFiveSecondsReadPlay() throws {
        XCTAssertEqual(DetailPlayLabel.episode(try episode(position: 30, duration: 3000)), "Play S1·E2")
        XCTAssertEqual(DetailPlayLabel.episode(try episode(position: 2996, duration: 3000)), "Play S1·E2")
        XCTAssertEqual(DetailPlayLabel.episode(try episode(position: 31, duration: 3000)), "Resume S1·E2")
    }

    func testMovieLabelFollowsTheSameRule() throws {
        XCTAssertEqual(DetailPlayLabel.item(try userData(position: 1200, duration: 7200)), "Resume")
        XCTAssertEqual(DetailPlayLabel.item(try userData(position: 10, duration: 7200)), "Play")
        XCTAssertEqual(DetailPlayLabel.item(nil), "Play")
    }

    private func userData(position: Double?, duration: Double?) throws -> LeafItemUserData {
        var fields = ["\"played\":false"]
        if let position { fields.append("\"positionSeconds\":\(position)") }
        if let duration { fields.append("\"durationSeconds\":\(duration)") }
        if position != nil { fields.append("\"isInProgress\":true") }
        return try JSONDecoder().decode(
            LeafItemUserData.self,
            from: Data("{\(fields.joined(separator: ","))}".utf8)
        )
    }

    private func episode(position: Double?, duration: Double?) throws -> EpisodeListItem {
        EpisodeListItem(
            contentId: "episode-1-2",
            seasonNumber: 1,
            episodeNumber: 2,
            title: "Second",
            overview: nil,
            airDate: nil,
            runtime: nil,
            imdbId: nil,
            tmdbId: nil,
            tvdbId: nil,
            stillUrl: nil,
            stillThumbhash: nil,
            userData: try userData(position: position, duration: duration),
            files: nil
        )
    }
}
