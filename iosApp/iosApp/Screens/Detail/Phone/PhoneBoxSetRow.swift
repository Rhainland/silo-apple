#if !os(tvOS)
import SwiftUI

/// The box set a movie belongs to, under the movie page's hero: its title
/// and a View box set link, then its movies as poster cards in
/// release order. The movie on screen is outlined and labelled THIS FILM, and
/// the row opens scrolled to it. The page draws nothing until the box set
/// has loaded (see `ItemDetailViewModel.boxSet`).
struct PhoneBoxSetRow: View {
    let boxSet: CatalogBoxSetDetail
    /// The movie whose page this is.
    let currentContentId: String

    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
                .padding(.horizontal, SiloTheme.safePadding)
            cards
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(boxSet.boxSet.title)
                .siloScaledFont(size: 22, weight: .semibold, relativeTo: .title2)
                .foregroundColor(.siloOnSurface)
            Spacer(minLength: 8)
            if let route = Route.boxSet(boxSet.boxSet) {
                Button("View box set") { router.navigate(to: route) }
                    .siloScaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                    .foregroundColor(.siloOnSurface)
                    .buttonStyle(.plain)
            }
        }
    }

    private var cards: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: HorizontalMediaRailLayout.cardAlignment, spacing: 12) {
                    ForEach(boxSet.items) { movie in
                        card(movie)
                            .id(movie.contentId)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 4)
                .phoneMediaRailBounds()
            }
            .contentMargins(.horizontal, SiloTheme.safePadding, for: .scrollContent)
            .mediaRailScrolling()
            .onAppear {
                guard boxSet.items.first?.contentId != currentContentId else { return }
                proxy.scrollTo(currentContentId, anchor: .center)
            }
        }
    }

    private func card(_ movie: BrowseItem) -> some View {
        let isCurrent = movie.contentId == currentContentId
        // The current film's card opens nothing: its page is already here.
        return MediaCard(
            title: movie.title,
            posterUrl: movie.posterUrl ?? "",
            thumbhash: movie.posterThumbhash,
            mediaType: movie.type,
            year: movie.year,
            userState: movie.userState,
            overlayData: OverlayData.from(movie),
            action: {},
            contentId: isCurrent ? nil : movie.contentId,
            aspect: .poster,
            marksCurrentFilm: isCurrent
        )
    }
}
#endif
