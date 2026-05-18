import SwiftUI

@main
struct MarkitdownMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var converter = ConversionStore()
    @State private var history = HistoryStore()

    var body: some Scene {
        WindowGroup("MarkItDown") {
            ContentView()
                .environment(converter)
                .environment(history)
                .frame(minWidth: 980, minHeight: 680)
                .task {
                    await history.load()
                    await NotificationService.shared.requestAuthorization()
                }
        }
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
