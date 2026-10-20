import Foundation
import SwiftData
import SwiftUI

/// A person in the household. In this on-device beta, members are local
/// profiles (no cloud accounts yet) used for assignment and attribution.
@Model
final class Member {
    var id: UUID
    var name: String
    var colorHex: String
    var isCurrentUser: Bool
    var createdAt: Date

    // Inverse sides of the optional assignment/attribution relationships.
    // Deleting a member un-assigns their items rather than deleting them.
    @Relationship(deleteRule: .nullify, inverse: \TodoTask.member)
    var tasks: [TodoTask] = []

    @Relationship(deleteRule: .nullify, inverse: \CalendarEvent.member)
    var events: [CalendarEvent] = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.paidBy)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .nullify, inverse: \WorkoutLog.member)
    var workouts: [WorkoutLog] = []

    @Relationship(deleteRule: .nullify, inverse: \Encouragement.fromMember)
    var sentEncouragements: [Encouragement] = []

    @Relationship(deleteRule: .nullify, inverse: \Encouragement.toMember)
    var receivedEncouragements: [Encouragement] = []

    /// Curated palette offered in the member editor.
    static let palette: [String] = [
        "#FF9500", "#FF3B30", "#AF52DE", "#007AFF", "#34C759",
        "#FFCC00", "#FF2D55", "#5AC8FA", "#A2845E", "#8E8E93"
    ]

    /// SwiftUI color for this member (chips, dots, avatars).
    var color: Color { Color(hex: colorHex) }

    init(name: String,
         colorHex: String = "#007AFF",
         isCurrentUser: Bool = false) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isCurrentUser = isCurrentUser
        self.createdAt = Date()
    }
}

extension Color {
    /// Creates a color from a "#RRGGBB" hex string. Falls back to gray.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        var value: UInt64 = 0
        guard sanitized.count == 6, Scanner(string: sanitized).scanHexInt64(&value) else {
            self = .gray
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
