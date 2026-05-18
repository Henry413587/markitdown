import SwiftUI
import UniformTypeIdentifiers

struct ConversionView: View {
    @Environment(ConversionStore.self) private var converter
    @Environment(HistoryStore.self) private var history
    @AppStorage("keepHistory") private var keepHistory = true

    @State private var isImporterPresented = false
    @State private var previewMode: PreviewMode = .rendered

    var body: some View {
        VStack(spacing: 0) {
            if converter.items.isEmpty {
                EmptyDropView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        isImporterPresented = true
                    }
            } else {
                ConversionWorkspaceView(previewMode: $previewMode)
            }
        }
        .navigationTitle("转换至 Markdown")
        .safeAreaInset(edge: .bottom) {
            ConversionFooterView()
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                converter.addFiles(urls)
            }
        }
        .onChange(of: converter.importerRequestID) {
            isImporterPresented = true
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            loadDroppedURLs(from: providers) { urls in
                converter.addFiles(urls)
            }
            return true
        }
        .onChange(of: converter.isConverting) { _, newValue in
            guard !newValue, keepHistory else { return }
            Task {
                let finished = converter.items.filter { $0.status.isTerminal }
                await history.add(finished)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .markitdownAddFiles)) { _ in
            converter.presentFileImporter()
        }
        .onReceive(NotificationCenter.default.publisher(for: .markitdownChooseOutputFolder)) { _ in
            converter.chooseOutputFolder()
        }
        .onReceive(NotificationCenter.default.publisher(for: .markitdownStartConversion)) { _ in
            Task {
                await converter.convertAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .markitdownClearQueue)) { _ in
            converter.clearQueue()
        }
    }

    private func loadDroppedURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        let collector = DroppedURLCollector()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }

                let url: URL?
                if let data = item as? Data,
                   let string = String(data: data, encoding: .utf8) {
                    url = URL(string: string)
                } else {
                    url = item as? URL
                }

                if let url {
                    collector.append(url)
                }
            }
        }

        group.notify(queue: .main) {
            completion(collector.urls)
        }
    }
}

private final class DroppedURLCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [URL] = []

    var urls: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ url: URL) {
        lock.lock()
        storage.append(url)
        lock.unlock()
    }
}

enum PreviewMode: String, CaseIterable, Identifiable {
    case rendered
    case source

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rendered:
            "预览"
        case .source:
            "源码"
        }
    }
}
