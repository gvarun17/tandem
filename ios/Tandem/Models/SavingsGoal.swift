import Foundation
import SwiftData

/// A savings target the household is working toward together.
@Model
final class SavingsGoal {
    var id: UUID
    var name: String
    var targetMinor: Int
    var savedMinor: Int
    var deadline: Date?
    var createdAt: Date

    /// 0...1 progress toward the target (0 when the target is unset).
    var progress: Double {
        guard targetMinor > 0 else { return 0 }
        return min(1, Double(savedMinor) / Double(targetMinor))
    }

    var remainingMinor: Int {
        max(0, targetMinor - savedMinor)
    }

    var isReached: Bool {
        targetMinor > 0 && savedMinor >= targetMinor
    }

    init(name: String,
         targetMinor: Int,
         savedMinor: Int = 0,
         deadline: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.targetMinor = targetMinor
        self.savedMinor = savedMinor
        self.deadline = deadline
        self.createdAt = Date()
    }
}
