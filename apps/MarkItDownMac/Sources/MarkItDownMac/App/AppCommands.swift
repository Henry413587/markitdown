import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("添加文件...") {
                NotificationCenter.default.post(name: .markitdownAddFiles, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("选择保存位置...") {
                NotificationCenter.default.post(name: .markitdownChooseOutputFolder, object: nil)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Divider()

            Button("开始转换") {
                NotificationCenter.default.post(name: .markitdownStartConversion, object: nil)
            }
            .keyboardShortcut(.return, modifiers: .command)

            Button("清空列表") {
                NotificationCenter.default.post(name: .markitdownClearQueue, object: nil)
            }
            .keyboardShortcut("l", modifiers: .command)
        }
    }
}
