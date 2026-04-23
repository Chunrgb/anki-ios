import UIKit
import Flutter
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register background sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "net.ankiweb.anki.sync",
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGAppRefreshTask)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundSync()
    }

    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "net.ankiweb.anki.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundSync(task: BGAppRefreshTask) {
        scheduleBackgroundSync()
        // Background sync via Flutter method channel
        task.setTaskCompleted(success: true)
    }
}
