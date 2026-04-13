import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct KohipsCarLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trip.self, Vehicle.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - AppDelegate (Background Tasks)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationManager.shared.requestPermission()
        NotificationManager.shared.registerCategories()
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
            TripDetector.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
}
