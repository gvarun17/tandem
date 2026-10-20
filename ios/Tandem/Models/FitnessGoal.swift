import Foundation
import SwiftData

enum FitnessMetric: String, Codable, CaseIterable {
    case steps = "Steps"
    case workoutsMinutes = "Workout minutes"
    case weightKg = "Weight (kg)"

    /// Step size used by the manual progress stepper in the UI.
    var manualStep: Double {
        switch self {
        case .steps: return 500
        case .workoutsMinutes: return 10
        case .weightKg: return 0.5
        }
    }

    /// Compact unit label shown next to values.
    var unitLabel: String {
        switch self {
        case .steps: return "steps"
        case .workoutsMinutes: return "min"
        case .weightKg: return "kg"
        }
    }
}

enum GoalPeriod: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

/// A fitness target. For `workoutsMinutes`, progress is computed from
/// `WorkoutLog` entries in the current period. For the other metrics,
/// progress is entered manually into `currentValue` (HealthKit sync is
/// future work, per the TDD).
@Model
final class FitnessGoal {
    var id: UUID
    var metricRaw: String
    var targetValue: Double
    var currentValue: Double
    var periodRaw: String
    /// Who the goal belongs to. nil = a shared household goal.
    var member: Member?
    var createdAt: Date

    var metric: FitnessMetric {
        get { FitnessMetric(rawValue: metricRaw) ?? .workoutsMinutes }
        set { metricRaw = newValue.rawValue }
    }

    var period: GoalPeriod {
        get { GoalPeriod(rawValue: periodRaw) ?? .weekly }
        set { periodRaw = newValue.rawValue }
    }

    init(metric: FitnessMetric = .workoutsMinutes,
         targetValue: Double,
         currentValue: Double = 0,
         period: GoalPeriod = .weekly,
         member: Member? = nil) {
        self.id = UUID()
        self.metricRaw = metric.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.periodRaw = period.rawValue
        self.member = member
        self.createdAt = Date()
    }

    /// Progress 0...1 using manually entered progress.
    var manualProgress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1, currentValue / targetValue)
    }
}
