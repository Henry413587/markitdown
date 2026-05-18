import Foundation

enum OutputLocationMode: String, CaseIterable, Identifiable {
    case besideSource
    case selectedFolder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .besideSource:
            "保存到原文件旁边"
        case .selectedFolder:
            "保存到指定文件夹"
        }
    }
}
