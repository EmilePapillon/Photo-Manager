import Foundation

struct TaskState: Identifiable, Hashable {
    enum TaskKind: String {
        case bookmarkResolve
        case quickHash
        case exif
        case thumbnail
        case fullHash
        case aiTagging
        case embeddings
        case faces
    }

    enum Status: String {
        case pending
        case running
        case completed
        case failed
    }

    let id = UUID()
    var assetID: UUID
    var kind: TaskKind
    var status: Status
    var lastUpdated: Date
    var errorDescription: String?
}
