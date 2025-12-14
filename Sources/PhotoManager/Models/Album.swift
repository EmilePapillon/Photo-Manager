import Foundation

struct Album: Identifiable, Hashable {
    let id: UUID
    var name: String
    var assetIDs: Set<UUID>
}

struct SmartAlbumRule: Identifiable, Hashable {
    enum Field {
        case rating(min: Int)
        case keyword(String)
        case aiLabel(String)
        case dateRange(Date, Date)
        case hasFaces(Bool)
        case offline(Bool)
        case missing(Bool)
    }

    let id = UUID()
    var field: Field
}

struct SmartAlbum: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rules: [SmartAlbumRule]
}
