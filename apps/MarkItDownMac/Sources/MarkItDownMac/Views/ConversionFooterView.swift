import SwiftUI

struct ConversionFooterView: View {
    @Environment(ConversionStore.self) private var converter

    var body: some View {
        VStack(spacing: 10) {
            Picker("保存位置", selection: Bindable(converter).outputMode) {
                ForEach(OutputLocationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            if converter.outputMode == .selectedFolder {
                HStack(spacing: 8) {
                    Text(converter.selectedOutputFolder?.path(percentEncoded: false) ?? "尚未选择文件夹")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Button("选择") {
                        converter.chooseOutputFolder()
                    }
                }
            }

            if !converter.items.isEmpty {
                HStack {
                    Button {
                        converter.clearQueue()
                    } label: {
                        Label("清空", systemImage: "trash")
                    }
                    .disabled(converter.isConverting)

                    Spacer()

                    Button {
                        Task {
                            await converter.convertAll()
                        }
                    } label: {
                        Label(converter.items.count == 1 ? "转换" : "转换 \(converter.items.count) 个", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!converter.canConvert)
                }
            }
        }
    }
}
