import SwiftUI

struct EmptyDropView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(.secondary)

            Text("将需要转换的文件拖入 App 页面或点击上方加号")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(48)
        .frame(maxWidth: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator, style: StrokeStyle(lineWidth: 1, dash: [7, 7]))
        }
        .padding()
    }
}
