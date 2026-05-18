import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case convert
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .convert:
            "转换至 Markdown"
        case .history:
            "历史操作记录"
        }
    }

    var systemImage: String {
        switch self {
        case .convert:
            "doc.badge.plus"
        case .history:
            "clock.arrow.circlepath"
        }
    }
}
