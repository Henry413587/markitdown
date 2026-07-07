import Foundation

enum ConversionStatus: String, Codable {
    case waiting
    case preparing
    case converting
    case writing
    case completed
    case failed
    case cancelled

    var title: String {
        switch self {
        case .waiting:
            "等待转换"
        case .preparing:
            "准备中"
        case .converting:
            "转换中"
        case .writing:
            "写入文件"
        case .completed:
            "已完成"
        case .failed:
            "失败"
        case .cancelled:
            "已取消"
        }
    }

    var isTerminal: Bool {
        self == .completed || self == .failed || self == .cancelled
    }
}

struct ConversionItem: Identifiable, Codable, Hashable {
    var id: UUID
    var sourceURL: URL
    var outputURL: URL?
    var status: ConversionStatus
    var progress: Double
    var errorMessage: String?
    var markdownPreview: String
    var markdownByteCount: Int64?
    var isInlinePreviewSkipped: Bool

    init(sourceURL: URL) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.outputURL = nil
        self.status = .waiting
        self.progress = 0
        self.errorMessage = nil
        self.markdownPreview = ""
        self.markdownByteCount = nil
        self.isInlinePreviewSkipped = false
    }

    var fileName: String {
        sourceURL.lastPathComponent
    }

    var displayType: String {
        let ext = sourceURL.pathExtension
        return ext.isEmpty ? "未知" : ext.uppercased()
    }

    var outputFileName: String {
        outputURL?.lastPathComponent ?? sourceURL.deletingPathExtension().lastPathComponent + ".md"
    }
}
