import Foundation
import UserNotifications

/// Schedules and cancels local notifications used as task reminders.
/// Prototype scope: on-device only, one notification per task, keyed by task id.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// (Re)schedules the reminder for a task. No-ops if reminders are off,
    /// the task is completed, or the reminder time has already passed.
    func scheduleReminder(for task: TodoTask) {
        cancelReminder(for: task)
        guard task.reminderEnabled, !task.isCompleted else { return }
        guard task.reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task reminder"
        content.body = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelReminder(for task: TodoTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    // MARK: - Event reminders

    private func eventIdentifier(for event: CalendarEvent) -> String {
        "event-\(event.id.uuidString)"
    }

    /// (Re)schedules the reminder for a calendar event. No-ops when the
    /// event has no reminder set or the time has already passed.
    func scheduleEventReminder(for event: CalendarEvent) {
        cancelEventReminder(for: event)
        guard let reminderDate = event.reminderDate, reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Event reminder"
        content.body = event.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: eventIdentifier(for: event),
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelEventReminder(for event: CalendarEvent) {
        center.removePendingNotificationRequests(withIdentifiers: [eventIdentifier(for: event)])
    }
}
