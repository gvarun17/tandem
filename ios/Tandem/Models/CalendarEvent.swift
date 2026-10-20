import Foundation
import SwiftData

enum EventRecurrence: String, Codable, CaseIterable {
    case none = "None"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

/// A household calendar event. Recurrence is intentionally simple for the
/// beta: weekly repeats on the same weekday, monthly on the same day of
/// month, starting from `startDate`.
@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var recurrenceRaw: String
    var reminderDate: Date?
    /// Optional owner. nil means the event belongs to the whole household.
    var member: Member?
    var createdAt: Date

    var recurrence: EventRecurrence {
        get { EventRecurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    init(title: String,
         notes: String = "",
         startDate: Date = Date(),
         endDate: Date = Date().addingTimeInterval(3600),
         isAllDay: Bool = false,
         recurrence: EventRecurrence = .none,
         reminderDate: Date? = nil,
         member: Member? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.recurrenceRaw = recurrence.rawValue
        self.reminderDate = reminderDate
        self.member = member
        self.createdAt = Date()
    }

    /// Whether this event has an occurrence on the given day.
    func occurs(on day: Date, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: startDate)
        let target = calendar.startOfDay(for: day)
        guard target >= start else { return false }
        switch recurrence {
        case .none:
            // A non-repeating event spans startDate...endDate.
            let end = calendar.startOfDay(for: endDate)
            return target >= start && target <= end
        case .weekly:
            return calendar.component(.weekday, from: startDate)
                == calendar.component(.weekday, from: day)
        case .monthly:
            return calendar.component(.day, from: startDate)
                == calendar.component(.day, from: day)
        }
    }
}
