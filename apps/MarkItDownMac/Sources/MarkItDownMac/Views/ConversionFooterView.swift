import SwiftUI

struct ConversionFooterView: View {
    @Environment(ConversionStore.self) private var converter

    var body: some View {
        HStack(spacing: 12) {
            Picker("保存位置", selection: Bindable(converter).outputMode) {
                ForEach(OutputLocationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 190)

            if converter.outputMode == .selectedFolder {
                Text(converter.selectedOutputFolder?.path(percentEncoded: false) ?? "尚未选择文件夹")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Button("选择") {
                    converter.chooseOutputFolder()
                }
            }

            Spacer()

            if !converter.items.isEmpty {
                Button("清空列表") {
                    converter.clearQueue()
                }
                .disabled(converter.isConverting)

                Button {
                    Task {
                        await converter.convertAll()
                    }
                } label: {
                    Text(converter.items.count == 1 ? "转换" : "转换 \(converter.items.count) 个文件")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!converter.canConvert)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
