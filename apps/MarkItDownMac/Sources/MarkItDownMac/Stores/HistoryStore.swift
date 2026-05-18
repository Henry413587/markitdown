import Foundation
import Observation

@Observable
@MainActor
final class HistoryStore {
    private(set) var records: [HistoryRecord] = []

    private var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appending(path: "MarkitdownMac", directoryHint: .isDirectory)
            .appending(path: "history.json")
    }

    func load() async {
        do {
            let url = storageURL
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
                return
            }

            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([HistoryRecord].self, from: data)

            records = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            records = []
        }
    }

    func add(_ items: [ConversionItem]) async {
        let newRecords = items.map(HistoryRecord.init(item:))

        records.insert(contentsOf: newRecords, at: 0)

        await save()
    }

    func clear() async {
        records.removeAll()
        await save()
    }

    private func save() async {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)

            let url = storageURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            // History persistence is intentionally best-effort.
        }
    }
}
