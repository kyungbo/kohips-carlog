import Foundation
import UserNotifications

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    // MARK: - Trip Ended Notification (Rich)

    func sendTripEndedNotification(
        tripId: UUID,
        startAddress: String = "",
        endAddress: String = "",
        distanceKm: Double = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = "주행 완료 🚗"

        if !startAddress.isEmpty && !endAddress.isEmpty {
            content.body = "\(startAddress) → \(endAddress), \(String(format: "%.1f", distanceKm))km 주행 완료"
        } else {
            content.body = "\(String(format: "%.1f", distanceKm))km 주행을 업무용으로 등록할까요?"
        }

        content.sound = .default
        content.userInfo = ["tripId": tripId.uuidString]
        content.categoryIdentifier = "TRIP_ENDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trip-\(tripId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 24-Hour Unclassified Reminder

    func scheduleUnclassifiedReminder(
        tripId: UUID,
        startAddress: String,
        endAddress: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "미분류 주행이 있어요"
        content.body = "\(startAddress) → \(endAddress) 주행을 아직 분류하지 않았어요."
        content.sound = .default
        content.userInfo = ["tripId": tripId.uuidString]
        content.categoryIdentifier = "TRIP_ENDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder-\(tripId.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for tripId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["reminder-\(tripId.uuidString)"]
        )
    }

    // MARK: - Action Categories

    func registerCategories() {
        let businessAction = UNNotificationAction(
            identifier: "BUSINESS",
            title: "✅ 업무용",
            options: .foreground
        )
        let personalAction = UNNotificationAction(
            identifier: "PERSONAL",
            title: "❌ 개인용",
            options: .destructive
        )
        let laterAction = UNNotificationAction(
            identifier: "LATER",
            title: "⏰ 나중에 분류",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "TRIP_ENDED",
            actions: [businessAction, personalAction, laterAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let tripIdString = userInfo["tripId"] as? String,
              let tripId = UUID(uuidString: tripIdString) else {
            handler()
            return
        }

        switch response.actionIdentifier {
        case "BUSINESS":
            NotificationCenter.default.post(
                name: .quickClassifyBusiness,
                object: nil,
                userInfo: ["tripId": tripId]
            )
        case "PERSONAL":
            NotificationCenter.default.post(
                name: .quickClassifyPersonal,
                object: nil,
                userInfo: ["tripId": tripId]
            )
        case "LATER":
            break // 대기 — 24시간 리마인더가 이미 스케줄됨
        default:
            NotificationCenter.default.post(
                name: .openTripDetail,
                object: nil,
                userInfo: ["tripId": tripId]
            )
        }

        handler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let quickClassifyBusiness = Notification.Name("quickClassifyBusiness")
    static let quickClassifyPersonal = Notification.Name("quickClassifyPersonal")
    static let openTripDetail = Notification.Name("openTripDetail")
}
