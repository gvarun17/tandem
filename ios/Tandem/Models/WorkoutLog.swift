import Foundation
import SwiftData

/// One logged workout. Feeds the `workoutsMinutes` fitness goals.
@Model
final class WorkoutLog {
    var id: UUID
    var type: String
    var durationMinutes: Int
    var date: Date
    /// Who did the workout. nil = together / unspecified.
    var member: Member?
    var note: String
    var createdAt: Date

    init(type: String,
         durationMinutes: Int,
         date: Date = Date(),
         member: Member? = nil,
         note: String = "") {
        self.id = UUID()
        self.type = type
        self.durationMinutes = durationMinutes
        self.date = date
        self.member = member
        self.note = note
        self.createdAt = Date()
    }
}

/// Common workout types offered in the picker (stored as plain strings so
/// custom types remain possible later).
enum WorkoutType {
    static let suggestions: [String] = [
        "Run", "Walk", "Cycle", "Swim", "Strength", "Yoga", "Sports", "Other"
    ]
}
