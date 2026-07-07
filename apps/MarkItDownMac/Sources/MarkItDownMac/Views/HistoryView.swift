import AppKit
import SwiftUI

struct HistoryView: View {
    var searchText: String = ""

    @Environment(HistoryStore.self) private var history
    @State private var selectedRecordID: UUID?

    var filteredRecords: [HistoryRecord] {
        guard !searchText.isEmpty else { return history.records }
        return history.records.filter {
            $0.sourceName.localizedCaseInsensitiveContains(searchText)
            || ($0.outputPath ?? "").localizedCaseInsensitiveContains(searchText)
            || $0.status.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedRecord: HistoryRecord? {
        guard let selectedRecordID else { return filteredRecords.first }
        return filteredRecords.first { $0.id == selectedRecordID }
    }

    var body: some View {
        if filteredRecords.isEmpty {
            VStack(spacing: 0) {
                HistoryHeader(count: 0)

                Divider()

                HistoryEmptyState(isSearching: !searchText.isEmpty)
            }
            .background(Color(nsColor: .textBackgroundColor))
        } else {
            HSplitView {
                VStack(spacing: 0) {
                    HistoryHeader(count: filteredRecords.count)

                    Divider()

                    List(filteredRecords, selection: $selectedRecordID) { record in
                        HistoryRow(record: record, isSelected: selectedRecordID == record.id)
                            .tag(record.id)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .frame(minWidth: 360, idealWidth: 430, maxWidth: 520)
                .background(Color(nsColor: .textBackgroundColor))

                HistoryDetailView(record: selectedRecord)
                    .frame(minWidth: 520)
            }
        }
    }
}

private struct HistoryHeader: View {
    var count: Int
    @Environment(HistoryStore.self) private var history

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("历史记录")
                    .font(.headline)
                Text("\(count) 条记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await history.clear()
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .disabled(history.records.isEmpty)
            .help("清空历史")
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .background(.bar)
    }
}

private struct HistoryRow: View {
    var record: HistoryRecord
    var isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(record.status == .failed ? .red : .clear)
                .frame(width: 8, height: 8)
                .padding(.top, 20)

            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.quaternary)
                Image(systemName: record.status == .completed ? "doc.text" : "exclamationmark.triangle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.sourceName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                    Spacer()
                    Text(record.createdAt, style: .time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                }

                Text(record.outputPath ?? record.sourcePath)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                    .lineLimit(2)

                StatusPill(status: record.status, selected: isSelected)
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
}

private struct HistoryEmptyState: View {
    var isSearching: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isSearching ? "magnifyingglass" : "clock")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.tertiary)

            Text(isSearching ? "没有匹配的历史记录" : "暂无历史记录")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(isSearching ? "换一个关键词再试试" : "完成转换后，记录会显示在这里")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryDetailView: View {
    var record: HistoryRecord?

    var body: some View {
        if let record {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.sourceName)
                                .font(.largeTitle.weight(.bold))
                                .lineLimit(3)
                            Text(record.createdAt, format: .dateTime)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusPill(status: record.status)
                    }

                    Divider()
                }
                .padding(.horizontal, 44)
                .padding(.top, 44)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        DetailField(title: "源文件", value: record.sourcePath)

                        if let outputPath = record.outputPath {
                            DetailField(title: "Markdown", value: outputPath)
                        }

                        if let message = record.errorMessage, !message.isEmpty {
                            DetailField(title: "错误详情", value: message)
                        }

                        HStack {
                            Button("打开输出文件") {
                                open(record.outputPath)
                            }
                            .disabled(record.outputPath == nil)

                            Button("在 Finder 中显示") {
                                reveal(record.outputPath ?? record.sourcePath)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: 820, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 20)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        } else {
            ContentUnavailableView("暂无历史记录", systemImage: "clock")
        }
    }

    private func open(_ path: String?) {
        guard let path else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    private func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}

private struct DetailField: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(nil)
        }
    }
}
