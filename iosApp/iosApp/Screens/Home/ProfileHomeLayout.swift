import Foundation

/// The profile's own Home layout as the server stores it: one override set
/// per profile and page, the same layout the web app's Home Screen settings
/// and an admin's per-profile Home sections card edit. Home itself only
/// renders `/api/v2/home/sections` in server order; nothing here is kept on
/// the device.
enum ProfileHomeLayout {
    /// The override set to save after the profile reordered or showed/hid
    /// rows. `rows` is the full settings list in its new display order with
    /// each row's new `hidden` flag; `saved` is what the profile saved
    /// before.
    ///
    /// The save replaces the profile's whole override set, so this keeps
    /// everything else it saved: a row's saved override is copied unchanged
    /// except for its position and visibility, an admin row without one gets
    /// a new override that stores only those two, and saved overrides for
    /// rows not in the list (removed rows, for one) are kept as they are.
    static func overrides(
        rows: [APIv2ProfileSectionSetting],
        saved: [APIv2SectionOverride],
        newID: () -> String = { UUID().uuidString.lowercased() }
    ) -> [APIv2SectionOverride] {
        // The server applies the last override saved for a section, so the
        // last one wins here too; earlier duplicates are superseded.
        var savedIndex: [String: Int] = [:]
        for (index, override) in saved.enumerated() {
            savedIndex[matchKey(override)] = index
        }

        var used = Set<Int>()
        var result: [APIv2SectionOverride] = []
        for (position, row) in rows.enumerated() {
            let key = row.isCustom ? "custom:\(row.id)" : "section:\(row.id)"
            guard let index = savedIndex[key] else {
                // A profile-built row exists only through its saved override;
                // without one there is nothing to rebuild it from.
                guard !row.isCustom else { continue }
                result.append(APIv2SectionOverride(id: newID(), sectionId: row.id, position: position, hidden: row.hidden))
                continue
            }
            used.insert(index)
            var override = saved[index]
            if override.id.isEmpty { override.id = newID() }
            override.position = position
            override.hidden = row.hidden
            result.append(override)
        }

        let superseded = Set(savedIndex.values)
        for (index, override) in saved.enumerated() where !used.contains(index) && superseded.contains(index) {
            result.append(override)
        }
        return result
    }

    private static func matchKey(_ override: APIv2SectionOverride) -> String {
        override.sectionId.isEmpty ? "custom:\(override.id)" : "section:\(override.sectionId)"
    }
}
