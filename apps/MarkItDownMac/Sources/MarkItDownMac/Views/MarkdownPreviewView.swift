import AppKit
import SwiftUI

struct MarkdownPreviewView: View {
    @Environment(ConversionStore.self) private var converter
    @Binding var previewMode: PreviewMode

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(converter.selectedItem?.outputFileName ?? "Markdown 预览")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Picker("预览模式", selection: $previewMode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 132)

                Button {
                    openSelectedOutput()
                } label: {
                    Label("打开", systemImage: "arrow.up.right.square")
                }
                .disabled(converter.selectedItem?.outputURL == nil)
            }
            .padding()

            Divider()

            Group {
                if let item = converter.selectedItem {
                    if item.status == .failed {
                        FailureView(message: item.errorMessage ?? "转换失败。")
                    } else if item.markdownPreview.isEmpty {
                        ContentUnavailableView("等待转换", systemImage: "doc.text.magnifyingglass")
                    } else if previewMode == .source {
                        ScrollView {
                            Text(item.markdownPreview)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    } else {
                        RenderedMarkdownView(markdown: item.markdownPreview)
                    }
                } else {
                    ContentUnavailableView("选择一个文件", systemImage: "doc.text")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func openSelectedOutput() {
        guard let url = converter.selectedItem?.outputURL else { return }
        NSWorkspace.shared.open(url)
    }
}

struct RenderedMarkdownView: View {
    var markdown: String

    var body: some View {
        ScrollView {
            Text(attributedMarkdown)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }

    private var attributedMarkdown: AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

struct FailureView: View {
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("转换失败")
                .font(.title3)
            Text(message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
