#if os(tvOS)
import SwiftUI

/// The box set a movie belongs to, under the tvOS movie page's hero: its
/// title and watched count, then its movies as poster cards in release order
/// and a View box set card at the end. The movie on screen is outlined and
/// labelled THIS FILM; moving down into the row lands on it, and the row
/// opens scrolled to it. A native focus graph like `TVSimilarRail`.
///
/// View box set is the last card rather than a button beside the heading, so
/// Down from the hero enters the cards instead of a lone button above them.
struct TVBoxSetRow: View {
    let boxSet: CatalogBoxSetDetail
    /// The movie whose page this is.
    let currentContentId: String

    @Environment(AppRouter.self) private var router
    @FocusState private var focusedItemId: String?

    private let cardWidth: CGFloat = 220
    private let cardSpacing: CGFloat = 44
    private let railVerticalPadding: CGFloat = 12
    private static let viewBoxSetId = "box-set-row:view"

    var body: some View {
        VStack(alignment: .leading, spacing: TVDetailLayout.sectionHeaderSpacing) {
            header
            rail
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            TVSectionHeader(title: boxSet.boxSet.title)
            Text(boxSet.boxSet.rowCaption)
                .font(.siloPosterMetadata)
                .foregroundColor(.siloSecondaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private var rail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                // Not lazy: a box set is a handful of films, and focus can
                // only enter the current film's card while it is loaded.
                HStack(alignment: .top, spacing: cardSpacing) {
                    ForEach(boxSet.items) { movie in
                        TVMediaCard(
                            title: movie.title,
                            posterUrl: movie.posterUrl ?? "",
                            posterThumbhash: movie.posterThumbhash,
                            mediaType: movie.type,
                            year: movie.year,
                            userState: movie.userState,
                            overlayData: OverlayData.from(movie),
                            action: { open(movie) },
                            cardWidth: cardWidth,
                            focusTreatment: .ring,
                            focusBinding: $focusedItemId,
                            focusContentId: movie.contentId,
                            contentId: movie.contentId,
                            marksCurrentFilm: movie.contentId == currentContentId
                        )
                        .id(movie.contentId)
                    }
                    if let route = Route.boxSet(boxSet.boxSet) {
                        viewBoxSetCard(route)
                    }
                }
                .padding(.vertical, railVerticalPadding)
            }
            .focusSection()
            .tvDefaultFocus(entryItemId, in: $focusedItemId)
            .scrollClipDisabled()
            .onAppear {
                guard boxSet.items.first?.contentId != currentContentId else { return }
                proxy.scrollTo(currentContentId, anchor: .center)
            }
        }
    }

    /// Down into the row lands on the film on screen when it is listed.
    private var entryItemId: String? {
        boxSet.items.contains { $0.contentId == currentContentId }
            ? currentContentId
            : boxSet.items.first?.contentId
    }

    private func viewBoxSetCard(_ route: Route) -> some View {
        TVMediaCard(
            title: "View box set",
            posterUrl: boxSet.boxSet.posterUrl ?? "",
            posterThumbhash: boxSet.boxSet.posterThumbhash,
            mediaType: "movie",
            subtitle: boxSet.boxSet.filmCountText,
            action: { router.navigate(to: route) },
            cardWidth: cardWidth,
            focusTreatment: .ring,
            focusBinding: $focusedItemId,
            focusContentId: Self.viewBoxSetId,
            boxSet: boxSet.boxSet
        )
    }

    private func open(_ movie: BrowseItem) {
        guard movie.contentId != currentContentId else { return }
        router.navigate(to: .itemDetail(browseItem: movie, libraryId: boxSet.boxSet.appLibraryId))
    }
}
#endif
