import SwiftUI

struct SettingsView: View {
    @AppStorage("sendNotifications") private var sendNotifications = true
    @AppStorage("keepHistory") private var keepHistory = true

    var body: some View {
        Form {
            Section("转换") {
                Toggle("转换完成后发送系统通知", isOn: $sendNotifications)
            }

            Section("历史记录") {
                Toggle("保存历史操作记录", isOn: $keepHistory)
            }

            Section("执行环境") {
                Text("App 会优先调用系统中的 markitdown 命令；如果没有安装，则回退到当前仓库的 packages/markitdown/src。")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520)
    }
}
