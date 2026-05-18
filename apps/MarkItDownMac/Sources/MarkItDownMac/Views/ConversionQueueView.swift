import SwiftUI

struct ConversionQueueView: View {
    @Environment(ConversionStore.self) private var converter

    var body: some View {
        @Bindable var converter = converter

        VStack(spacing: 0) {
            Table(converter.items, selection: $converter.selectedItemID) {
                TableColumn("文件") { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.fileName)
                            .lineLimit(1)
                        Text(item.sourceURL.deletingLastPathComponent().path(percentEncoded: false))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .width(min: 180, ideal: 260)

                TableColumn("类型") { item in
                    Text(item.displayType)
                        .foregroundStyle(.secondary)
                }
                .width(54)

                TableColumn("大小") { item in
                    Text(item.sourceURL.fileSizeDescription)
                        .foregroundStyle(.secondary)
                }
                .width(70)

                TableColumn("状态") { item in
                    StatusPill(status: item.status)
                }
                .width(90)
            }

            if converter.isConverting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("正在转换")
                        .font(.headline)
                    ProgressView(value: converter.overallProgress)
                }
                .padding()
            }
        }
    }
}

struct StatusPill: View {
    var status: ConversionStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(status.title)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
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
