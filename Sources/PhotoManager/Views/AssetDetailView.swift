import SwiftUI
import AppKit

struct AssetDetailView: View {
    @EnvironmentObject private var library: LibraryViewModel
    var asset: Asset?

    var body: some View {
        Group {
            if let asset {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        preview(for: asset)
                        metadataSection(for: asset)
                        aiSection(for: asset)
                        keywordSection(for: asset)
                        actions(for: asset)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("Select a photo", systemImage: "photo.on.rectangle")
            }
        }
        .background(.regularMaterial)
    }

    private func preview(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(asset.fileName)
                .font(.title2.bold())
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(.quaternary.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(asset.dimensions.width / asset.dimensions.height, contentMode: .fit)
                    .overlay {
                        asset.thumbnail?
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundStyle(.secondary)
                    }
                    .cornerRadius(12)
                if asset.status != .available {
                    BadgeView(title: asset.status.rawValue.capitalized, color: .red, icon: "exclamationmark.circle")
                        .padding()
                }
            }
        }
    }

    private func metadataSection(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metadata")
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                gridRow("Folder", value: asset.folder)
                gridRow("Type", value: asset.fileType.uppercased())
                gridRow("Size", value: ByteCountFormatter.string(fromByteCount: Int64(asset.fileSize), countStyle: .file))
                gridRow("Created", value: dateString(asset.createdAt))
                if let exifDate = asset.exifDate {
                    gridRow("EXIF Date", value: dateString(exifDate))
                }
                if let camera = asset.camera {
                    gridRow("Camera", value: camera)
                }
                if let lens = asset.lens {
                    gridRow("Lens", value: lens)
                }
                gridRow("Orientation", value: asset.orientation ?? "Unknown")
                gridRow("Dimensions", value: "\(Int(asset.dimensions.width)) × \(Int(asset.dimensions.height))")
                HStack {
                    Text("Rating")
                    Spacer()
                    Stepper("\(asset.rating)", value: binding(for: \.rating, asset: asset), in: 0...5)
                        .labelsHidden()
                }
                Toggle("Flagged", isOn: binding(for: \.flagged, asset: asset))
            }
        }
    }

    private func aiSection(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AI Tags")
                    .font(.headline)
                if asset.needsAITags {
                    BadgeView(title: "Pending", color: .blue, icon: "wand.and.stars")
                }
            }
            ForEach(asset.aiTags) { tag in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tag.caption)
                            .font(.subheadline)
                        Spacer()
                        BadgeView(title: tag.provider.displayName, color: tag.provider.isCloud ? .purple : .green, icon: "bolt.horizontal")
                    }
                    WrapLayout(tag.labels) { label in
                        Text(label)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    }
                    .font(.caption)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2)))
            }
            if asset.aiTags.isEmpty {
                Text("No AI tags yet. Run local or cloud tagger to populate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func keywordSection(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keywords")
                .font(.headline)
            WrapLayout(asset.keywords) { keyword in
                Text(keyword.name)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            }
            .font(.caption)
            Button {
                // Placeholder: show keyword editor UI.
            } label: {
                Label("Edit Keywords", systemImage: "pencil")
            }
            .buttonStyle(.bordered)
        }
    }

    private func actions(for asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(.headline)
            HStack {
                if let url = asset.resolvedURL {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                    }
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                }
                Button {
                    library.refreshBookmarks()
                } label: {
                    Label("Resolve Bookmark", systemImage: "link")
                }
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    private func gridRow(_ title: String, value: String) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func binding<Value>(for keyPath: WritableKeyPath<Asset, Value>, asset: Asset) -> Binding<Value> {
        Binding<Value>(
            get: {
                library.assets.first(where: { $0.id == asset.id })?[keyPath: keyPath] ?? asset[keyPath: keyPath]
            },
            set: { newValue in
                guard let index = library.assets.firstIndex(where: { $0.id == asset.id }) else { return }
                library.assets[index][keyPath: keyPath] = newValue
                library.selectedAsset = library.assets[index]
            }
        )
    }
}

// Simple wrapping layout for keywords and labels.
struct WrapLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data), id: \.self) { element in
                    content(element)
                        .padding(4)
                        .alignmentGuide(.leading) { dimension in
                            if width + dimension.width > geometry.size.width {
                                width = 0
                                height += dimension.height
                            }
                            let result = width
                            if element == data.last {
                                width = 0
                                height = 0
                            } else {
                                width += dimension.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if element == data.last {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
