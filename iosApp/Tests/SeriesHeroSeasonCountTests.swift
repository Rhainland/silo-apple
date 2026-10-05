import XCTest
@testable import Silo

/// The hero counts the seasons the library holds, not the provider's
/// `season_count`, so it agrees with the season chips below it.
final class SeriesHeroSeasonCountTests: XCTestCase {
    func testLibrarySeasonCountSkipsSpecials() throws {
        let seasons = try [season(0, isSpecials: true), season(1), season(2)]
        XCTAssertEqual(seasons.librarySeasonCount, 2)
        XCTAssertEqual(try [season(0)].librarySeasonCount, 0)
    }

#if !os(tvOS)
    func testPhoneFactsLineUsesLibrarySeasonsOverProviderTotal() throws {
        let detail = try seriesDetail(seasonCount: 5)
        let seasons = try [season(0, isSpecials: true), season(1), season(2)]
        XCTAssertEqual(
            PhoneHeroMetadata.seriesFactsLine(from: detail, seasons: seasons),
            [.text("2008"), .text("2 Seasons")]
        )
        XCTAssertEqual(
            PhoneHeroMetadata.seriesFactsLine(from: detail, seasons: try [season(1)]),
            [.text("2008"), .text("1 Season")]
        )
    }

    func testPhoneFactsLineOmitsCountUntilSeasonsLoad() throws {
        let detail = try seriesDetail(seasonCount: 5)
        XCTAssertEqual(PhoneHeroMetadata.seriesFactsLine(from: detail, seasons: []), [.text("2008")])
    }

#else
    func testTVFactsLineUsesLibrarySeasonsOverProviderTotal() throws {
        let detail = try seriesDetail(seasonCount: 5)
        let seasons = try [season(0, isSpecials: true), season(1), season(2)]
        XCTAssertEqual(
            TVHeroMetadata.seriesFactsLine(from: detail, seasons: seasons),
            [.text("2008"), .text("2 Seasons")]
        )
    }

#endif

    private func season(_ number: Int, isSpecials: Bool? = nil) throws -> Season {
        let specials = isSpecials.map { ",\"isSpecials\":\($0)" } ?? ""
        return try JSONDecoder().decode(Season.self, from: Data(
            "{\"contentId\":\"season-\(number)\",\"seasonNumber\":\(number)\(specials)}".utf8
        ))
    }

    private func seriesDetail(seasonCount: Int) throws -> ItemDetail {
        let json = """
        {"content_id":"series","type":"series","title":"Show","year":2008,"season_count":\(seasonCount),"versions":[]}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ItemDetail.self, from: Data(json.utf8))
    }
}
