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

        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "net.ankiweb.anki.sync",
                using: nil
            ) { task in
                self.handleBackgroundSync(task: task as! BGAppRefreshTask)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        if #available(iOS 13.0, *) {
            scheduleBackgroundSync()
        }
    }

    @available(iOS 13.0, *)
    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "net.ankiweb.anki.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    @available(iOS 13.0, *)
    private func handleBackgroundSync(task: BGAppRefreshTask) {
        scheduleBackgroundSync()
        task.setTaskCompleted(success: true)
    }
}
