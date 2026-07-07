import AppKit
import QuickLookUI
import SwiftUI

struct MarkdownPreviewView: View {
    @Environment(ConversionStore.self) private var converter
    @Binding var previewMode: PreviewMode

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(item: converter.selectedItem, previewMode: $previewMode)

            Divider()

            Group {
                if let item = converter.selectedItem {
                    if item.status == .failed {
                        FailureView(message: item.errorMessage ?? "转换失败。")
                    } else if previewMode == .source && MarkdownPreviewPolicy.requiresExternalSourceViewer(item) {
                        LargeMarkdownNotice(item: item)
                    } else if item.markdownPreview.isEmpty {
                        SourceFilePreview(item: item)
                    } else if previewMode == .source {
                        ScrollView {
                            Text(item.markdownPreview)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 28)
                        }
                    } else {
                        RenderedMarkdownView(markdown: item.markdownPreview)
                    }
                } else {
                    EmptyDropView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            converter.presentFileImporter()
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private enum MarkdownPreviewPolicy {
    static let inlinePreviewByteLimit = ConversionResult.inlinePreviewByteLimit

    static func requiresExternalSourceViewer(_ item: ConversionItem) -> Bool {
        item.isInlinePreviewSkipped || sourceByteCount(for: item) > inlinePreviewByteLimit
    }

    static func formattedSize(_ item: ConversionItem) -> String {
        ByteCountFormatter.string(fromByteCount: sourceByteCount(for: item), countStyle: .file)
    }

    private static func sourceByteCount(for item: ConversionItem) -> Int64 {
        if let outputFileSize = item.outputURL?.fileSize {
            return outputFileSize
        }

        return item.markdownByteCount ?? Int64(item.markdownPreview.utf8.count)
    }
}

private extension URL {
    var fileSize: Int64? {
        guard let size = try? resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return nil
        }

        return Int64(size)
    }
}

private struct LargeMarkdownNotice: View {
    var item: ConversionItem

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Markdown 文件较大")
                .font(.title2.weight(.semibold))

            Text("转换已完成，但生成的 Markdown 约 \(MarkdownPreviewPolicy.formattedSize(item))。在 App 内直接渲染源码或富文本预览可能导致界面无响应。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)

            HStack(spacing: 10) {
                Button {
                    openOutput()
                } label: {
                    Label("用外部软件打开", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    revealOutput()
                } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
            }
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openOutput() {
        guard let url = item.outputURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func revealOutput() {
        guard let url = item.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct SourceFilePreview: View {
    var item: ConversionItem

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("原文件预览", systemImage: "eye")
                    .font(.headline)
                Spacer()
                Button {
                    NSWorkspace.shared.open(item.sourceURL)
                } label: {
                    Label("打开原文件", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.plain)

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([item.sourceURL])
                } label: {
                    Label("显示", systemImage: "folder")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 10)
            .background(.bar)

            QuickLookPreview(url: item.sourceURL)
                .id(item.sourceURL)
        }
    }
}

private struct QuickLookPreview: NSViewRepresentable {
    var url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = true
        view.previewItem = url as NSURL
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as NSURL
    }
}

private struct DetailHeader: View {
    var item: ConversionItem?
    @Binding var previewMode: PreviewMode
    @Environment(ConversionStore.self) private var converter
    @State private var isShowingLargeSourceAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item?.fileName ?? "MarkItDown")
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)

                    Text(item?.sourceURL.deletingLastPathComponent().path(percentEncoded: false) ?? "Markdown 转换器")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let item {
                    Button {
                        Task {
                            await converter.convertItems(withIDs: [item.id])
                        }
                    } label: {
                        FileBadge(item: item)
                    }
                    .buttonStyle(.plain)
                    .disabled(converter.isConverting || item.status == .completed)
                    .help("转换当前文件")
                }
            }

            HStack(spacing: 12) {
                if let item {
                    StatusPill(status: item.status)

                    Text(item.outputFileName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Picker("预览模式", selection: previewModeSelection) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 132)

                Button {
                    openOutput()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .disabled(item?.outputURL == nil)
                .help("打开输出文件")

                Button {
                    revealOutput()
                } label: {
                    Image(systemName: "folder")
                }
                .disabled(item?.outputURL == nil)
                .help("在 Finder 中显示")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 24)
        .background(Color(nsColor: .textBackgroundColor))
        .alert("源码文件过大", isPresented: $isShowingLargeSourceAlert) {
            Button("使用默认应用打开") {
                openOutput()
            }
            Button("关闭", role: .cancel) {}
        } message: {
            Text("生成的 Markdown 源码文件较大，直接在 App 内查看可能导致界面无响应。需要查看源码时，请使用其他应用打开。")
        }
    }

    private var previewModeSelection: Binding<PreviewMode> {
        Binding {
            previewMode
        } set: { requestedMode in
            guard requestedMode == .source,
                  let item,
                  MarkdownPreviewPolicy.requiresExternalSourceViewer(item) else {
                previewMode = requestedMode
                return
            }

            previewMode = .rendered
            isShowingLargeSourceAlert = true
        }
    }

    private func openOutput() {
        guard let url = item?.outputURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func revealOutput() {
        guard let url = item?.outputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct FileBadge: View {
    var item: ConversionItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.quaternary)
            Image(systemName: symbol)
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(width: 56, height: 56)
    }

    private var symbol: String {
        switch item.status {
        case .completed:
            "checkmark"
        case .preparing, .converting, .writing:
            "hourglass"
        case .failed:
            "exclamationmark"
        default:
            "arrow.triangle.2.circlepath"
        }
    }

    private var tint: Color {
        switch item.status {
        case .completed:
            .green
        case .failed:
            .red
        default:
            .secondary
        }
    }
}

struct RenderedMarkdownView: View {
    var markdown: String

    var body: some View {
        ScrollView {
            Text(attributedMarkdown)
                .font(.system(size: 17))
                .lineSpacing(6)
                .textSelection(.enabled)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 44)
                .padding(.vertical, 28)
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
                .font(.title3.weight(.semibold))
            Text(message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
