import Foundation
import SwiftData

/// A recurring monthly spending limit for one category. The budget itself
/// carries no month: spending is matched by querying transactions whose
/// date falls inside the month being reported.
@Model
final class Budget {
    var id: UUID
    var category: String
    var monthlyLimitMinor: Int
    var createdAt: Date

    init(category: String, monthlyLimitMinor: Int) {
        self.id = UUID()
        self.category = category
        self.monthlyLimitMinor = monthlyLimitMinor
        self.createdAt = Date()
    }
}
