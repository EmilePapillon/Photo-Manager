import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        List {
            Section("Library") {
                Button {
                    library.selectedAlbumID = nil
                    library.selectedSmartAlbumID = nil
                    library.showMissingOnly = false
                    library.showNeedsAI = false
                } label: {
                    Label("All Photos", systemImage: "photo.on.rectangle")
                }
                Toggle(isOn: $library.showMissingOnly) {
                    Label("Missing", systemImage: "exclamationmark.triangle")
                }
                Toggle(isOn: $library.showNeedsAI) {
                    Label("Needs AI tags", systemImage: "wand.and.stars")
                }
            }

            Section("Albums") {
                ForEach(library.albums) { album in
                    Button {
                        library.selectedAlbumID = album.id
                        library.selectedSmartAlbumID = nil
                    } label: {
                        HStack {
                            Label(album.name, systemImage: "folder")
                            Spacer()
                            Text("\(album.assetIDs.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Smart Albums") {
                ForEach(library.smartAlbums) { album in
                    Button {
                        library.selectedSmartAlbumID = album.id
                        library.selectedAlbumID = nil
                    } label: {
                        Label(album.name, systemImage: "sparkles")
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Watched Folders") {
                ForEach(library.watchedFolders, id: \.self) { folder in
                    Label(folder.lastPathComponent, systemImage: "eye")
                }
                Button {
                    // Placeholder: in real app show NSOpenPanel to add watched folder.
                    library.addWatchedFolder(URL(fileURLWithPath: "/Users/you/Pictures"))
                } label: {
                    Label("Add Folder", systemImage: "plus")
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Photo Manager")
    }
}
