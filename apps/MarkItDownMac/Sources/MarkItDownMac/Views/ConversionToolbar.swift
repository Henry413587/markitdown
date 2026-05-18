import SwiftUI

struct ConversionToolbar: View {
    @Environment(ConversionStore.self) private var converter

    var body: some View {
        Button {
            converter.presentFileImporter()
        } label: {
            Label("添加文件", systemImage: "plus")
        }

        Button {
            converter.chooseOutputFolder()
        } label: {
            Label("保存位置", systemImage: "folder")
        }

        Button {
            Task {
                await converter.convertAll()
            }
        } label: {
            Label("转换", systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(!converter.canConvert)
    }
}
