import SwiftUI

struct TopBarView: View {
    @EnvironmentObject private var library: LibraryViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search filename, keywords, AI captions...", text: $library.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .onSubmit {
                        searchFocused = false
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.12)))

            Picker("Mode", selection: $library.searchMode) {
                ForEach(LibraryViewModel.SearchMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)

            Divider()
                .frame(height: 24)

            filterToggle(title: "Faces", systemImage: "person.crop.square", isOn: $library.showFacesOnly)
            filterToggle(title: "Docs", systemImage: "doc.text.image", isOn: $library.showDocumentsOnly)
            filterToggle(title: "Screens", systemImage: "display", isOn: $library.showScreenshotsOnly)

            Divider()
                .frame(height: 24)

            Picker("AI Provider", selection: $library.aiProvider) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .frame(maxWidth: 200)

            Toggle("Local Only", isOn: $library.localOnlyMode)
                .toggleStyle(.switch)

            Spacer()
        }
    }

    private func filterToggle(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .help(title)
    }
}
