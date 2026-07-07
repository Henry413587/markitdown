import AppKit
import SwiftUI

struct ConversionQueueView: View {
    var searchText: String = ""

    @Environment(ConversionStore.self) private var converter

    private var filteredItems: [ConversionItem] {
        guard !searchText.isEmpty else { return converter.items }
        return converter.items.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText)
            || $0.sourceURL.path(percentEncoded: false).localizedCaseInsensitiveContains(searchText)
            || $0.status.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        @Bindable var converter = converter

        VStack(spacing: 0) {
            QueueHeader()

            Divider()

            if converter.items.isEmpty {
                EmptyListState()
            } else if filteredItems.isEmpty {
                ContentUnavailableView("没有匹配的文件", systemImage: "magnifyingglass")
            } else {
                List(selection: $converter.selectedItemIDs) {
                    ForEach(filteredItems) { item in
                        QueueRow(item: item, isSelected: converter.selectedItemIDs.contains(item.id))
                            .tag(item.id)
                            .contextMenu {
                                QueueContextMenu(item: item)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: converter.selectedItemIDs) { _, selectedIDs in
                    converter.selectedItemID = filteredItems.first(where: { selectedIDs.contains($0.id) })?.id
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                if converter.isConverting {
                    HStack {
                        Text("正在转换")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(converter.overallProgress * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: converter.overallProgress)
                }

                ConversionFooterView()
            }
            .padding(12)
            .background(.bar)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct QueueContextMenu: View {
    var item: ConversionItem
    @Environment(ConversionStore.self) private var converter

    private var targetIDs: Set<UUID> {
        converter.selectedItemIDs.contains(item.id) ? converter.selectedItemIDs : [item.id]
    }

    private var targetItems: [ConversionItem] {
        converter.items.filter { targetIDs.contains($0.id) }
    }

    var body: some View {
        Button("在访达里显示选中文件") {
            NSWorkspace.shared.activateFileViewerSelecting(targetItems.map(\.sourceURL))
        }

        Button(targetIDs.count == 1 ? "转换选中文件" : "转换 \(targetIDs.count) 个选中文件") {
            Task {
                await converter.convertItems(withIDs: targetIDs)
            }
        }
        .disabled(converter.isConverting)

        Divider()

        Button(targetIDs.count == 1 ? "从列表中移除" : "移除 \(targetIDs.count) 个选中文件", role: .destructive) {
            converter.removeItems(withIDs: targetIDs)
        }
        .disabled(converter.isConverting)
    }
}

private struct QueueHeader: View {
    @Environment(ConversionStore.self) private var converter

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("转换队列")
                    .font(.headline)
                Text("\(converter.items.count) 个文件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if converter.items.contains(where: { $0.status == .failed }) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .background(.bar)
    }
}

private struct QueueRow: View {
    var item: ConversionItem
    var isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(unreadColor)
                .frame(width: 8, height: 8)
                .padding(.top, 22)

            FileThumbnail(item: item)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.fileName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Text(item.displayType)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.88) : .secondary)
                }

                Text(item.sourceURL.deletingLastPathComponent().path(percentEncoded: false))
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                    .lineLimit(1)

                HStack {
                    StatusPill(status: item.status, selected: isSelected)
                    Spacer()
                    Text(item.sourceURL.fileSizeDescription)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
        )
        .foregroundStyle(isSelected ? .white : .primary)
    }

    private var unreadColor: Color {
        switch item.status {
        case .completed:
            .clear
        case .failed:
            .red
        default:
            .blue
        }
    }
}

struct StatusPill: View {
    var status: ConversionStatus
    var selected = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(status.title)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(selected ? .white.opacity(0.86) : .secondary)
    }

    private var color: Color {
        switch status {
        case .waiting:
            .secondary
        case .preparing, .converting, .writing:
            .blue
        case .completed:
            .green
        case .failed:
            .red
        case .cancelled:
            .orange
        }
    }
}

private struct FileThumbnail: View {
    var item: ConversionItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.quaternary)
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 48, height: 48)
    }

    private var symbol: String {
        switch item.sourceURL.pathExtension.lowercased() {
        case "doc", "docx":
            "doc.richtext"
        case "pdf":
            "doc.text"
        case "ppt", "pptx":
            "rectangle.on.rectangle"
        case "xls", "xlsx", "csv":
            "tablecells"
        case "jpg", "jpeg", "png", "gif", "webp":
            "photo"
        default:
            "doc"
        }
    }
}

private struct EmptyListState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("尚未添加文件")
                .font(.headline)
            Text("拖入文件后会显示在这里")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
