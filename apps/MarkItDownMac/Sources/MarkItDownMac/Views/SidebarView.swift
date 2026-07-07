import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection
    @Environment(ConversionStore.self) private var converter
    @Environment(HistoryStore.self) private var history

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SidebarSectionTitle("MarkItDown")

            VStack(spacing: 4) {
                SidebarRow(
                    title: "转换至 Markdown",
                    systemImage: "arrow.down.doc.fill",
                    tint: .orange,
                    count: pendingCount,
                    isSelected: selection == .convert
                ) {
                    selection = .convert
                }

                SidebarRow(
                    title: "历史操作记录",
                    systemImage: "clock.arrow.circlepath",
                    tint: .blue,
                    count: history.records.count,
                    isSelected: selection == .history
                ) {
                    selection = .history
                }
            }

            SidebarSectionTitle("当前任务")

            VStack(spacing: 4) {
                SidebarMetricRow(title: "队列文件", value: "\(converter.items.count)", systemImage: "doc.on.doc")
                SidebarMetricRow(title: "已完成", value: "\(completedCount)", systemImage: "checkmark.circle")
                SidebarMetricRow(title: "失败", value: "\(failedCount)", systemImage: "exclamationmark.triangle")
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.bar)
    }

    private var pendingCount: Int {
        converter.items.filter { $0.status != .completed }.count
    }

    private var completedCount: Int {
        converter.items.filter { $0.status == .completed }.count
    }

    private var failedCount: Int {
        converter.items.filter { $0.status == .failed }.count
    }
}

private struct SidebarSectionTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
    }
}

private struct SidebarRow: View {
    var title: String
    var systemImage: String
    var tint: Color
    var count: Int
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 18)

                Text(title)
                    .lineLimit(1)

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minWidth: 24, minHeight: 18)
                        .background(.secondary, in: Capsule())
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .contentShape(Rectangle())
            .background(isSelected ? Color.secondary.opacity(0.23) : .clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarMetricRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
    }
}
