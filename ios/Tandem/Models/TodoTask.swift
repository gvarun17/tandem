import Foundation
import SwiftData

enum TaskRecurrence: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"

    /// The next occurrence date for a repeating task, or nil if it does not repeat.
    func nextDate(from date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        }
    }
}

enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2

    var label: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}

@Model
final class TodoTask {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var reminderEnabled: Bool
    var reminderDate: Date
    var recurrenceRaw: String
    var priorityRaw: Int
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    /// Optional assignee. nil means the task is shared by the whole household.
    var member: Member?

    var recurrence: TaskRecurrence {
        get { TaskRecurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    init(title: String,
         notes: String = "",
         dueDate: Date = Date(),
         reminderEnabled: Bool = false,
         reminderDate: Date = Date(),
         recurrence: TaskRecurrence = .none,
         priority: TaskPriority = .normal,
         member: Member? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.reminderEnabled = reminderEnabled
        self.reminderDate = reminderDate
        self.recurrenceRaw = recurrence.rawValue
        self.priorityRaw = priority.rawValue
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
        self.member = member
    }
}
