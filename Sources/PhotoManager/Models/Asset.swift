import Foundation
import SwiftUI

struct Asset: Identifiable {
    enum Status: String {
        case available
        case missing
        case offline
    }

    let id: UUID
    var bookmarkData: Data?
    var resolvedURL: URL?
    var quickHash: String
    var fullHash: String?
    var fileName: String
    var fileType: String
    var fileSize: Int
    var createdAt: Date
    var exifDate: Date?
    var camera: String?
    var lens: String?
    var orientation: String?
    var dimensions: CGSize
    var rating: Int
    var flagged: Bool
    var status: Status
    var keywords: [Keyword]
    var aiTags: [AITag]
    var embedding: Embedding?
    var folder: String
    var needsAITags: Bool
    var thumbnail: Image?
}
