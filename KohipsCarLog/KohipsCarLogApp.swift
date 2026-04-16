import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct KohipsCarLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trip.self, Vehicle.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // DB 손상 시 인메모리 폴백 (데이터 유실되지만 크래시 방지)
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - AppDelegate (Background Tasks)
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationManager.shared.requestPermission()
        NotificationManager.shared.registerCategories()

        // modelContext를 AppDelegate에서 주입 (startMonitoring보다 먼저)
        let container = (UIApplication.shared.delegate as? AppDelegate)
            .flatMap { _ in (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController }
        // Note: modelContext는 MainView 생성 시 TripViewModel.init에서 주입됨
        // startMonitoring은 위치 권한 요청 + 모션 감지만 시작, beginTrip은 modelContext 있을 때만 동작
        TripDetector.shared.startMonitoring()
        registerBackgroundTasks()
        return true
    }

    // Background task registration
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.kohipstech.carlog.refresh",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                TripDetector.shared.handleBackgroundRefresh(task: refreshTask)
            }
        }
    }
}
