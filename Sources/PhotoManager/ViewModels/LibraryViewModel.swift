import Foundation
import SwiftUI

final class LibraryViewModel: ObservableObject {
    enum SearchMode: String, CaseIterable, Identifiable {
        case keyword
        case semantic

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    @Published var assets: [Asset] = []
    @Published var albums: [Album] = []
    @Published var smartAlbums: [SmartAlbum] = []
    @Published var tasks: [TaskState] = []
    @Published var watchedFolders: [URL] = []

    @Published var searchQuery: String = ""
    @Published var searchMode: SearchMode = .keyword
    @Published var showFacesOnly: Bool = false
    @Published var showDocumentsOnly: Bool = false
    @Published var showScreenshotsOnly: Bool = false
    @Published var selectedAlbumID: UUID?
    @Published var selectedSmartAlbumID: UUID?
    @Published var selectedAsset: Asset?
    @Published var showMissingOnly: Bool = false
    @Published var showNeedsAI: Bool = false
    @Published var aiProvider: AIProvider = .openAI
    @Published var localOnlyMode: Bool = false

    var filteredAssets: [Asset] {
        assets.filter { asset in
            var matches = true

            if let selectedAlbumID, let album = albums.first(where: { $0.id == selectedAlbumID }) {
                matches = matches && album.assetIDs.contains(asset.id)
            }

            if let selectedSmartAlbumID,
               let smartAlbum = smartAlbums.first(where: { $0.id == selectedSmartAlbumID }) {
                matches = matches && evaluateSmartAlbum(smartAlbum, asset: asset)
            }

            if showMissingOnly {
                matches = matches && asset.status == .missing
            }

            if showNeedsAI {
                matches = matches && asset.needsAITags
            }

            if showFacesOnly {
                matches = matches && asset.aiTags.contains { $0.labels.contains(where: { $0.localizedCaseInsensitiveContains("face") }) }
            }

            if showDocumentsOnly {
                matches = matches && asset.aiTags.contains { $0.labels.contains(where: { $0.localizedCaseInsensitiveContains("document") }) }
            }

            if showScreenshotsOnly {
                matches = matches && asset.fileName.lowercased().contains("screenshot")
            }

            if !searchQuery.isEmpty {
                switch searchMode {
                case .keyword:
                    matches = matches && keywordSearch(asset: asset, query: searchQuery)
                case .semantic:
                    matches = matches && semanticSearchPlaceholder(asset: asset, query: searchQuery)
                }
            }

            return matches
        }
    }

    init() {
        seedMockData()
    }

    func importAssets(from urls: [URL]) {
        // Placeholder for import flow: generate bookmark data, capture quick hash, enqueue tasks.
        let newAssets = urls.map { url -> Asset in
            let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path))
            let createdAt = attrs?[.creationDate] as? Date ?? Date()
            return Asset(
                id: UUID(),
                bookmarkData: bookmark,
                resolvedURL: url,
                quickHash: UUID().uuidString.prefix(8).description,
                fullHash: nil,
                fileName: url.lastPathComponent,
                fileType: url.pathExtension,
                fileSize: fileSize,
                createdAt: createdAt,
                exifDate: createdAt,
                camera: nil,
                lens: nil,
                orientation: nil,
                dimensions: CGSize(width: 1200, height: 900),
                rating: 0,
                flagged: false,
                status: .available,
                keywords: [],
                aiTags: [],
                embedding: nil,
                folder: url.deletingLastPathComponent().lastPathComponent,
                needsAITags: true,
                thumbnail: Image(systemName: "photo")
            )
        }

        assets.append(contentsOf: newAssets)
        enqueueTasks(for: newAssets)
    }

    func toggleLocalOnlyMode(_ enabled: Bool) {
        localOnlyMode = enabled
    }

    func addWatchedFolder(_ url: URL) {
        if !watchedFolders.contains(url) {
            watchedFolders.append(url)
        }
    }

    func markMissingAssets() {
        assets = assets.map { asset in
            var updated = asset
            if let resolvedURL = asset.resolvedURL,
               !FileManager.default.fileExists(atPath: resolvedURL.path) {
                updated.status = .missing
            }
            return updated
        }
    }

    func refreshBookmarks() {
        // Placeholder bookmark resolution; in production use security-scoped access.
        assets = assets.map { asset in
            var updated = asset
            if let bookmarkData = asset.bookmarkData {
                var stale = false
                if let url = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                    updated.resolvedURL = url
                    updated.status = .available
                } else {
                    updated.status = .missing
                }
            }
            return updated
        }
    }

    func updateTask(_ taskID: UUID, status: TaskState.Status, error: String? = nil) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].status = status
        tasks[index].lastUpdated = Date()
        tasks[index].errorDescription = error
    }

    private func enqueueTasks(for assets: [Asset]) {
        let newTasks = assets.flatMap { asset in
            [
                TaskState(assetID: asset.id, kind: .bookmarkResolve, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .quickHash, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .exif, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .thumbnail, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .fullHash, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .aiTagging, status: .pending, lastUpdated: .now, errorDescription: nil),
                TaskState(assetID: asset.id, kind: .embeddings, status: .pending, lastUpdated: .now, errorDescription: nil)
            ]
        }
        tasks.append(contentsOf: newTasks)
    }

    private func keywordSearch(asset: Asset, query: String) -> Bool {
        let lowered = query.lowercased()
        let inFile = asset.fileName.lowercased().contains(lowered)
        let inKeywords = asset.keywords.contains { $0.name.lowercased().contains(lowered) }
        let inAITags = asset.aiTags.contains { tag in
            tag.caption.lowercased().contains(lowered) ||
            tag.labels.contains(where: { $0.lowercased().contains(lowered) })
        }
        return inFile || inKeywords || inAITags
    }

    private func semanticSearchPlaceholder(asset: Asset, query: String) -> Bool {
        guard let embedding = asset.embedding else {
            return false
        }
        // Placeholder semantic match: match provider and simple checksum with query hash.
        let checksum = embedding.vector.reduce(0, +)
        return query.count % 2 == 0 ? checksum.truncatingRemainder(dividingBy: 2) == 0 : checksum.truncatingRemainder(dividingBy: 2) != 0
    }

    private func evaluateSmartAlbum(_ album: SmartAlbum, asset: Asset) -> Bool {
        album.rules.allSatisfy { rule in
            switch rule.field {
            case .rating(let min):
                return asset.rating >= min
            case .keyword(let keyword):
                return asset.keywords.contains { $0.name.localizedCaseInsensitiveContains(keyword) }
            case .aiLabel(let label):
                return asset.aiTags.contains { $0.labels.contains(where: { $0.localizedCaseInsensitiveContains(label) }) }
            case .dateRange(let start, let end):
                let date = asset.exifDate ?? asset.createdAt
                return (start...end).contains(date)
            case .hasFaces(let expected):
                let hasFaces = asset.aiTags.contains { $0.labels.contains(where: { $0.localizedCaseInsensitiveContains("face") }) }
                return hasFaces == expected
            case .offline(let expected):
                return (asset.status == .offline) == expected
            case .missing(let expected):
                return (asset.status == .missing) == expected
            }
        }
    }

    private func seedMockData() {
        let keywords = [
            Keyword(name: "Travel"),
            Keyword(name: "Family"),
            Keyword(name: "Work"),
            Keyword(name: "Cat"),
            Keyword(name: "Landscape")
        ]

        func makeAITag(provider: AIProvider, labels: [String], caption: String) -> AITag {
            AITag(provider: provider, labels: labels, caption: caption, confidence: .random(in: 0.7...0.99), timestamp: .now)
        }

        let baseAssets: [Asset] = [
            Asset(
                id: UUID(),
                bookmarkData: nil,
                resolvedURL: URL(fileURLWithPath: "/Users/you/Pictures/IMG_0001.JPG"),
                quickHash: "a1b2c3d4",
                fullHash: nil,
                fileName: "IMG_0001.JPG",
                fileType: "jpg",
                fileSize: 3_200_000,
                createdAt: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now,
                exifDate: Calendar.current.date(byAdding: .day, value: -10, to: .now),
                camera: "iPhone 15 Pro",
                lens: "Main",
                orientation: "portrait",
                dimensions: CGSize(width: 4032, height: 3024),
                rating: 4,
                flagged: false,
                status: .available,
                keywords: [keywords[0], keywords[4]],
                aiTags: [makeAITag(provider: .appleVision, labels: ["mountain", "sky"], caption: "A clear mountain view")],
                embedding: Embedding(provider: .localCLIP, vector: Array(repeating: 0.1, count: 8)),
                folder: "Trips",
                needsAITags: false,
                thumbnail: Image(systemName: "mountain.2.fill")
            ),
            Asset(
                id: UUID(),
                bookmarkData: nil,
                resolvedURL: URL(fileURLWithPath: "/Users/you/Pictures/IMG_0002.JPG"),
                quickHash: "z9y8x7w6",
                fullHash: nil,
                fileName: "IMG_0002.JPG",
                fileType: "jpg",
                fileSize: 2_800_000,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
                exifDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
                camera: "iPhone 14",
                lens: "Wide",
                orientation: "landscape",
                dimensions: CGSize(width: 3024, height: 4032),
                rating: 5,
                flagged: true,
                status: .available,
                keywords: [keywords[1], keywords[3]],
                aiTags: [makeAITag(provider: .openAI, labels: ["cat", "indoors"], caption: "A cat sitting on a sofa")],
                embedding: Embedding(provider: .openAI, vector: Array(repeating: 0.2, count: 8)),
                folder: "Home",
                needsAITags: false,
                thumbnail: Image(systemName: "pawprint.fill")
            ),
            Asset(
                id: UUID(),
                bookmarkData: nil,
                resolvedURL: URL(fileURLWithPath: "/Users/you/Pictures/IMG_0003.PNG"),
                quickHash: "m1n2o3p4",
                fullHash: nil,
                fileName: "Screenshot 2023-12-01.png",
                fileType: "png",
                fileSize: 1_200_000,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
                exifDate: nil,
                camera: nil,
                lens: nil,
                orientation: "landscape",
                dimensions: CGSize(width: 2560, height: 1440),
                rating: 0,
                flagged: false,
                status: .missing,
                keywords: [keywords[2]],
                aiTags: [makeAITag(provider: .azure, labels: ["document", "screenshot"], caption: "Screenshot of a presentation")],
                embedding: Embedding(provider: .localCLIP, vector: Array(repeating: 0.5, count: 8)),
                folder: "Screenshots",
                needsAITags: true,
                thumbnail: Image(systemName: "desktopcomputer")
            )
        ]

        assets = baseAssets
        albums = [
            Album(id: UUID(), name: "Favorites", assetIDs: Set([baseAssets[0].id, baseAssets[1].id])),
            Album(id: UUID(), name: "Work", assetIDs: Set([baseAssets[2].id]))
        ]

        smartAlbums = [
            SmartAlbum(
                id: UUID(),
                name: "This Week",
                rules: [SmartAlbumRule(field: .dateRange(Date().addingTimeInterval(-7 * 86_400), Date()))]
            ),
            SmartAlbum(
                id: UUID(),
                name: "Needs AI tags",
                rules: [SmartAlbumRule(field: .aiLabel("missing"))]
            )
        ]

        enqueueTasks(for: baseAssets)
    }
}
