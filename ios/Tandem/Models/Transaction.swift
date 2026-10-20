import Foundation
import SwiftData

enum TransactionKind: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

/// A single money movement. Amounts are stored as integer minor units
/// (paise/cents) so arithmetic never hits floating-point rounding.
@Model
final class Transaction {
    var id: UUID
    var amountMinor: Int
    var kindRaw: String
    var category: String
    var date: Date
    var note: String
    /// Who paid (expenses) or received (income). nil = shared/household.
    var paidBy: Member?
    var createdAt: Date

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    /// Signed value: income is positive, expenses are negative.
    var signedMinor: Int {
        kind == .income ? amountMinor : -amountMinor
    }

    init(amountMinor: Int,
         kind: TransactionKind = .expense,
         category: String = "Other",
         date: Date = Date(),
         note: String = "",
         paidBy: Member? = nil) {
        self.id = UUID()
        self.amountMinor = amountMinor
        self.kindRaw = kind.rawValue
        self.category = category
        self.date = date
        self.note = note
        self.paidBy = paidBy
        self.createdAt = Date()
    }
}

/// Suggested category lists offered in the transaction/budget pickers.
enum TransactionCategory {
    static let expense: [String] = [
        "Groceries", "Dining", "Transport", "Housing", "Utilities",
        "Health", "Entertainment", "Shopping", "Education", "Other"
    ]
    static let income: [String] = [
        "Salary", "Freelance", "Interest", "Refund", "Other income"
    ]

    static func suggestions(for kind: TransactionKind) -> [String] {
        kind == .income ? income : expense
    }
}
