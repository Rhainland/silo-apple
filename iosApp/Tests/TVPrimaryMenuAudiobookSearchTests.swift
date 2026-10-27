#if os(tvOS)
import XCTest
@testable import Silo

/// Apple TV search includes audiobooks exactly when the top bar shows an
/// audiobook destination, however that destination got into the menu.
final class TVPrimaryMenuAudiobookSearchTests: XCTestCase {
    private let movies = Library(id: 1, name: "Movies", type: "movies", sortOrder: 0, posterUrl: nil)
    private let books = Library(id: 4, name: "Audiobooks", type: "audiobooks", sortOrder: 1, posterUrl: nil)

    func testIncludesAudiobooksOnlyWhenTheMenuShowsAnAudiobookDestination() {
        let cases: [(String, [PrimaryMenuItem], [Library], Bool)] = [
            ("Audiobooks tab added in Customize Top Menu",
             [.builtin(.home), .builtin(.movies), .builtin(.audiobooks)], [movies, books], true),
            ("pinned audiobook library",
             [.builtin(.home), .library(libraryId: 4, label: "Audiobooks")], [movies, books], true),
            ("menu without audiobooks",
             [.builtin(.home), .builtin(.movies)], [movies, books], false),
            ("Audiobooks tab but no audiobook library",
             [.builtin(.home), .builtin(.audiobooks)], [movies], false),
            ("pinned movie library only",
             [.builtin(.home), .library(libraryId: 1, label: "Movies")], [movies, books], false),
        ]
        for (name, items, libraries, expected) in cases {
            XCTAssertEqual(
                TVPrimaryMenuProjection.includesAudiobooks(in: items, libraries: libraries),
                expected,
                name
            )
        }
    }
}
#endif
