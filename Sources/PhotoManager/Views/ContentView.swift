import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            VStack(spacing: 0) {
                TopBarView()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                Divider()
                AssetGridView()
            }
            .navigationSplitViewColumnWidth(min: 500, ideal: 640)
        } detail: {
            AssetDetailView(asset: library.selectedAsset)
                .frame(minWidth: 300)
        }
        .toolbar(removing: .sidebarToggle)
    }
}
