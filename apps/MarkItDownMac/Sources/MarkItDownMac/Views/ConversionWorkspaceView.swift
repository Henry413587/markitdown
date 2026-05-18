import SwiftUI

struct ConversionWorkspaceView: View {
    @Environment(ConversionStore.self) private var converter
    @Binding var previewMode: PreviewMode

    var body: some View {
        HSplitView {
            ConversionQueueView()
                .frame(minWidth: 430, idealWidth: 520)

            MarkdownPreviewView(previewMode: $previewMode)
                .frame(minWidth: 420)
        }
    }
}
