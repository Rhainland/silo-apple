#if !os(tvOS)
import SwiftUI

/// Editorial section header used below the phone hero — the same
/// pattern as `TVSectionHeader`, scaled to phones.
struct PhoneSectionHeader: View {
    let title: String
    var trailingText: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .siloScaledFont(size: 22, weight: .semibold, relativeTo: .title2)
                .foregroundColor(.siloOnSurface)

            Spacer(minLength: 8)

            if let trailingText, !trailingText.isEmpty {
                Text(trailingText)
                    .siloScaledFont(size: 13, weight: .medium, relativeTo: .footnote)
                    .foregroundColor(.siloSecondaryText)
            }
        }
    }
}
#endif
