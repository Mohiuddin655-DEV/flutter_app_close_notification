import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let notificationId = "force_quit_channel"
    private var bgTask: UIBackgroundTaskIdentifier = .invalid
    private var rescheduleTimer: Timer?
    private let rescheduleInterval: TimeInterval = 5
    private let notificationDelay: TimeInterval = 7

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        handleForceQuit(controller: controller)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        startRescheduling()
        super.applicationDidEnterBackground(application)
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        stopRescheduling()
        super.applicationWillEnterForeground(application)
    }

    private func handleForceQuit(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "force_quit_service",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "start":
                self?.startRescheduling()
                result(nil)
            case "stop":
                self?.stopRescheduling()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startRescheduling() {
        // Prevent duplicate timers
        rescheduleTimer?.invalidate()
        rescheduleTimer = nil

        let application = UIApplication.shared

        if bgTask != .invalid {
            application.endBackgroundTask(bgTask)
        }

        bgTask = application.beginBackgroundTask { [weak self] in
            self?.rescheduleTimer?.invalidate()
            self?.rescheduleTimer = nil
            if let task = self?.bgTask {
                application.endBackgroundTask(task)
            }
            self?.bgTask = .invalid
        }

        // Schedule immediately
        scheduleNotification()

        // Keep rescheduling
        rescheduleTimer = Timer.scheduledTimer(
            withTimeInterval: rescheduleInterval,
            repeats: true
        ) { [weak self] _ in
            self?.scheduleNotification()
        }
    }

    private func stopRescheduling() {
        rescheduleTimer?.invalidate()
        rescheduleTimer = nil

        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        center.removeDeliveredNotifications(withIdentifiers: [notificationId])
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        content.title = "Don't force quit me!"
        content.body = "Quitting may result in inaccurate info like location, battery, etc. Tap to Reopen."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: notificationDelay,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

}
