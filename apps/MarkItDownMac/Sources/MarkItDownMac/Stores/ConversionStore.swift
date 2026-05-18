import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class ConversionStore {
    var items: [ConversionItem] = []
    var selectedItemID: UUID?
    var isConverting = false
    var outputMode: OutputLocationMode = .besideSource
    var selectedOutputFolder: URL?
    var importerRequestID = UUID()

    private let runner: MarkitdownRunner

    init() {
        self.runner = MarkitdownRunner(repositoryRoot: RepositoryLocator.findRepositoryRoot())
    }

    var canConvert: Bool {
        !items.isEmpty && !isConverting && items.contains { $0.status != .completed }
    }

    var selectedItem: ConversionItem? {
        guard let selectedItemID else { return items.first }
        return items.first { $0.id == selectedItemID }
    }

    var overallProgress: Double {
        guard !items.isEmpty else { return 0 }
        return items.map(\.progress).reduce(0, +) / Double(items.count)
    }

    func presentFileImporter() {
        importerRequestID = UUID()
    }

    func addFiles(_ urls: [URL]) {
        let fileURLs = expandDirectories(urls)
        let existingPaths = Set(items.map { $0.sourceURL.path(percentEncoded: false) })
        let newItems = fileURLs
            .filter { !existingPaths.contains($0.path(percentEncoded: false)) }
            .map(ConversionItem.init(sourceURL:))

        guard !newItems.isEmpty else { return }
        items.append(contentsOf: newItems)
        selectedItemID = selectedItemID ?? newItems.first?.id
    }

    func remove(_ item: ConversionItem) {
        items.removeAll { $0.id == item.id }
        if selectedItemID == item.id {
            selectedItemID = items.first?.id
        }
    }

    func clearQueue() {
        guard !isConverting else { return }
        items.removeAll()
        selectedItemID = nil
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        panel.message = "选择 Markdown 文件的保存位置"

        if panel.runModal() == .OK, let url = panel.url {
            selectedOutputFolder = url
            outputMode = .selectedFolder
        }
    }

    func convertAll() async {
        guard canConvert else { return }
        isConverting = true

        for index in items.indices {
            guard items[index].status != .completed else { continue }
            await convertItem(at: index)
        }

        isConverting = false
        let successCount = items.filter { $0.status == .completed }.count
        let failureCount = items.filter { $0.status == .failed }.count
        await NotificationService.shared.sendConversionFinished(successCount: successCount, failureCount: failureCount)
    }

    private func convertItem(at index: Int) async {
        items[index].status = .preparing
        items[index].progress = 0.15
        let outputURL = destinationURL(for: items[index].sourceURL)
        items[index].outputURL = outputURL

        do {
            items[index].status = .converting
            items[index].progress = 0.45

            let result = try await runner.convert(sourceURL: items[index].sourceURL, outputURL: outputURL)

            items[index].status = .writing
            items[index].progress = 0.85
            items[index].markdownPreview = result.markdown
            items[index].status = .completed
            items[index].progress = 1
            items[index].errorMessage = nil
            selectedItemID = items[index].id
        } catch {
            items[index].status = .failed
            items[index].progress = 1
            items[index].errorMessage = error.localizedDescription
        }
    }

    private func destinationURL(for sourceURL: URL) -> URL {
        let directory: URL
        switch outputMode {
        case .besideSource:
            directory = sourceURL.deletingLastPathComponent()
        case .selectedFolder:
            directory = selectedOutputFolder ?? sourceURL.deletingLastPathComponent()
        }

        return FileManager.default.uniqueMarkdownURL(for: sourceURL, in: directory)
    }

    private func expandDirectories(_ urls: [URL]) -> [URL] {
        var expanded: [URL] = []

        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
                continue
            }

            if !isDirectory.boolValue {
                expanded.append(url)
                continue
            }

            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            let files = enumerator.compactMap { entry -> URL? in
                guard let fileURL = entry as? URL else { return nil }
                let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true ? fileURL : nil
            }
            expanded.append(contentsOf: files)
        }

        return expanded
    }
}
