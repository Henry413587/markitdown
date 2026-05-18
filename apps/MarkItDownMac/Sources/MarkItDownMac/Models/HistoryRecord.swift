import Foundation

struct HistoryRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var createdAt: Date
    var sourcePath: String
    var outputPath: String?
    var status: ConversionStatus
    var errorMessage: String?

    init(item: ConversionItem) {
        self.id = UUID()
        self.createdAt = Date()
        self.sourcePath = item.sourceURL.path(percentEncoded: false)
        self.outputPath = item.outputURL?.path(percentEncoded: false)
        self.status = item.status
        self.errorMessage = item.errorMessage
    }

    var sourceName: String {
        URL(fileURLWithPath: sourcePath).lastPathComponent
    }
}
