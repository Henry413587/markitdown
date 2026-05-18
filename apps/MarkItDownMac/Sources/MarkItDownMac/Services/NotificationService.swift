import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            // Notification permission is optional for conversion.
        }
    }

    func sendConversionFinished(successCount: Int, failureCount: Int) async {
        let notificationsPreference = UserDefaults.standard.object(forKey: "sendNotifications") as? Bool
        guard notificationsPreference ?? true else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Markdown 转换完成"
        if failureCount == 0 {
            content.body = "已成功转换 \(successCount) 个文件。"
        } else {
            content.body = "已完成 \(successCount) 个，失败 \(failureCount) 个。"
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // The in-app completion state still tells the user what happened.
        }
    }
}
