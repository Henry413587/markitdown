import SwiftUI

struct ContentView: View {
    @SceneStorage("selectedSection") private var selectedSection: AppSection = .convert

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } detail: {
            switch selectedSection {
            case .convert:
                ConversionView()
            case .history:
                HistoryView()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                ConversionToolbar()
            }
        }
    }
}
