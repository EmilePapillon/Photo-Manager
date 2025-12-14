import SwiftUI
import AppKit

struct AssetGridView: View {
    @EnvironmentObject private var library: LibraryViewModel
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(library.filteredAssets) { asset in
                    AssetCell(asset: asset)
                        .onTapGesture {
                            library.selectedAsset = asset
                        }
                        .contextMenu {
                            Button("Reveal in Finder") {
                                if let url = asset.resolvedURL {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                }
                            }
                            Button(asset.flagged ? "Unflag" : "Flag") {
                                toggleFlag(asset: asset)
                            }
                        }
                }
            }
            .padding()
        }
    }

    private func toggleFlag(asset: Asset) {
        guard let index = library.assets.firstIndex(where: { $0.id == asset.id }) else { return }
        library.assets[index].flagged.toggle()
    }
}

private struct AssetCell: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(.quaternary.opacity(0.2))
                    .aspectRatio(asset.dimensions.width / asset.dimensions.height, contentMode: .fit)
                    .overlay {
                        asset.thumbnail?
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .padding(6)
                            .foregroundStyle(.secondary)
                    }
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 4) {
                    if asset.flagged {
                        BadgeView(title: "Flagged", color: .orange, icon: "flag.fill")
                    }
                    if asset.status != .available {
                        let color: Color = asset.status == .missing ? .red : .gray
                        BadgeView(title: asset.status.rawValue.capitalized, color: color, icon: "exclamationmark.triangle.fill")
                    }
                    if asset.needsAITags {
                        BadgeView(title: "AI Pending", color: .blue, icon: "wand.and.stars")
                    }
                }
                .padding(8)
            }

            Text(asset.fileName)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 8) {
                Label("\(asset.rating)", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Label(asset.folder, systemImage: "folder")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background).shadow(radius: 1))
    }
}
