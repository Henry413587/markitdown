import SwiftUI

struct ContentView: View {
    @SceneStorage("selectedSection") private var selectedSection: AppSection = .convert
    @AppStorage("showPrimarySidebar") private var showPrimarySidebar = true
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            ReaderToolbar(
                selectedSection: selectedSection,
                searchText: $searchText,
                showPrimarySidebar: $showPrimarySidebar
            )

            Divider()

            HStack(spacing: 0) {
                if showPrimarySidebar {
                    SidebarView(selection: $selectedSection)
                        .frame(width: 252)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Divider()
                }

                Group {
                    switch selectedSection {
                    case .convert:
                        ConversionView(searchText: searchText)
                    case .history:
                        HistoryView(searchText: searchText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.snappy(duration: 0.18), value: showPrimarySidebar)
        }
    }
}

private struct ReaderToolbar: View {
    var selectedSection: AppSection
    @Binding var searchText: String
    @Binding var showPrimarySidebar: Bool

    @Environment(ConversionStore.self) private var converter

    var body: some View {
        HStack(spacing: 18) {
            Button {
                showPrimarySidebar.toggle()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .help(showPrimarySidebar ? "隐藏边栏" : "显示边栏")

            Button {
                NotificationCenter.default.post(name: .markitdownAddFiles, object: nil)
            } label: {
                Image(systemName: "plus")
            }
            .help("添加文件")

            Button {
                NotificationCenter.default.post(name: .markitdownChooseOutputFolder, object: nil)
            } label: {
                Image(systemName: "folder")
            }
            .help("选择保存位置")

            Button {
                Task {
                    await converter.convertAll()
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .disabled(!converter.canConvert)
            .help("开始转换")

            Button {
                NotificationCenter.default.post(name: .markitdownClearQueue, object: nil)
            } label: {
                Image(systemName: "trash")
            }
            .disabled(converter.items.isEmpty || converter.isConverting)
            .help("清空列表")

            Spacer()

            Text(selectedSection.title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(width: 280, height: 30)
            .background(.quaternary.opacity(0.65), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .font(.system(size: 16))
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(.bar)
    }
}
