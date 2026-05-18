import AppKit
import SwiftUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history
    @State private var searchText = ""
    @State private var selectedRecordID: UUID?

    var filteredRecords: [HistoryRecord] {
        guard !searchText.isEmpty else { return history.records }
        return history.records.filter {
            $0.sourceName.localizedCaseInsensitiveContains(searchText)
            || ($0.outputPath ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedRecord: HistoryRecord? {
        guard let selectedRecordID else { return filteredRecords.first }
        return filteredRecords.first { $0.id == selectedRecordID }
    }

    var body: some View {
        HSplitView {
            List(filteredRecords, selection: $selectedRecordID) { record in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.sourceName)
                            .lineLimit(1)
                        Spacer()
                        StatusPill(status: record.status)
                    }
                    Text(record.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(record.id)
            }
            .searchable(text: $searchText)
            .frame(minWidth: 320, idealWidth: 380)

            HistoryDetailView(record: selectedRecord)
                .frame(minWidth: 420)
        }
        .navigationTitle("历史操作记录")
        .toolbar {
            Button("清空历史") {
                Task {
                    await history.clear()
                }
            }
            .disabled(history.records.isEmpty)
        }
    }
}

struct HistoryDetailView: View {
    var record: HistoryRecord?

    var body: some View {
        if let record {
            Form {
                Section("文件") {
                    LabeledContent("源文件", value: record.sourcePath)
                    if let outputPath = record.outputPath {
                        LabeledContent("Markdown", value: outputPath)
                    }
                    LabeledContent("状态", value: record.status.title)
                    LabeledContent("时间") {
                        Text(record.createdAt, format: .dateTime)
                    }
                }

                if let message = record.errorMessage, !message.isEmpty {
                    Section("错误详情") {
                        Text(message)
                            .textSelection(.enabled)
                    }
                }

                Section {
                    HStack {
                        Button("打开输出文件") {
                            open(record.outputPath)
                        }
                        .disabled(record.outputPath == nil)

                        Button("在 Finder 中显示") {
                            reveal(record.outputPath ?? record.sourcePath)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
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
