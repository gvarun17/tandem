import Foundation

/// Whether a category is spending slower than, in line with, or faster
/// than a linear pace through the month — or past its limit entirely.
enum PaceStatus {
    case under    // behind the linear pace
    case onTrack  // roughly at the linear pace
    case over     // ahead of the linear pace, or past the limit
}

/// Spending vs budget for one category in one month.
struct CategoryBudgetStatus: Identifiable {
    let category: String
    let spentMinor: Int
    let limitMinor: Int
    let expectedByNowMinor: Int
    let pace: PaceStatus

    var id: String { category }

    var remainingMinor: Int { max(0, limitMinor - spentMinor) }

    var fractionSpent: Double {
        guard limitMinor > 0 else { return 0 }
        return min(1, Double(spentMinor) / Double(limitMinor))
    }
}

/// Spending in a category that has no budget, for the same month.
struct CategorySpending: Identifiable {
    let category: String
    let spentMinor: Int
    var id: String { category }
}

/// All dashboard numbers for one month, derived from raw transactions
/// and budgets. Pure value type — no SwiftData access in here.
struct FinanceSummary {
    let monthStart: Date
    let totalIncomeMinor: Int
    let totalExpensesMinor: Int
    let savingsRate: Double
    let categoryStatuses: [CategoryBudgetStatus]
    let unbudgetedSpending: [CategorySpending]
    let totalBudgetRemainingMinor: Int
    let safeToSpendTodayMinor: Int

    var netMinor: Int { totalIncomeMinor - totalExpensesMinor }
}

/// Pure finance calculations over in-memory data. Views fetch with
/// `@Query` and pass arrays in, keeping this trivially testable.
enum FinanceMetrics {

    static func summary(transactions: [Transaction],
                        budgets: [Budget],
                        monthContaining monthDate: Date,
                        calendar: Calendar = .current) -> FinanceSummary {
        let interval = calendar.dateInterval(of: .month, for: monthDate)
            ?? DateInterval(start: monthDate, duration: 0)
        let monthTxns = transactions.filter { interval.contains($0.date) }

        let income = monthTxns.filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amountMinor }
        let expenses = monthTxns.filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amountMinor }

        let savingsRate = income > 0
            ? Double(income - expenses) / Double(income)
            : 0

        var spentByCategory: [String: Int] = [:]
        for txn in monthTxns where txn.kind == .expense {
            spentByCategory[txn.category, default: 0] += txn.amountMinor
        }

        // Position within the month, relative to "now".
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
        let now = Date()
        let isCurrentMonth = calendar.isDate(monthDate, equalTo: now, toGranularity: .month)
        let isPastMonth = interval.end <= calendar.dateInterval(of: .month, for: now)?.start ?? now

        let daysElapsed: Int
        let daysRemaining: Int
        if isCurrentMonth {
            daysElapsed = calendar.component(.day, from: now)
            daysRemaining = max(1, daysInMonth - daysElapsed + 1)
        } else if isPastMonth {
            daysElapsed = daysInMonth
            daysRemaining = 0
        } else {
            daysElapsed = 0
            daysRemaining = daysInMonth
        }

        var statuses: [CategoryBudgetStatus] = []
        var totalRemaining = 0
        var budgetedCategories = Set<String>()
        for budget in budgets.sorted(by: { $0.category < $1.category }) {
            budgetedCategories.insert(budget.category)
            let spent = spentByCategory[budget.category] ?? 0
            let expected = daysInMonth > 0
                ? Int((Double(budget.monthlyLimitMinor) * Double(daysElapsed) / Double(daysInMonth)).rounded())
                : 0
            let pace: PaceStatus
            if spent > budget.monthlyLimitMinor {
                pace = .over
            } else if expected > 0 && Double(spent) > Double(expected) * 1.1 {
                pace = .over
            } else if expected > 0 && Double(spent) < Double(expected) * 0.9 {
                pace = .under
            } else {
                pace = .onTrack
            }
            statuses.append(CategoryBudgetStatus(
                category: budget.category,
                spentMinor: spent,
                limitMinor: budget.monthlyLimitMinor,
                expectedByNowMinor: expected,
                pace: pace
            ))
            totalRemaining += max(0, budget.monthlyLimitMinor - spent)
        }

        let unbudgeted = spentByCategory
            .filter { !budgetedCategories.contains($0.key) }
            .map { CategorySpending(category: $0.key, spentMinor: $0.value) }
            .sorted { $0.spentMinor > $1.spentMinor }

        let safeToSpend = daysRemaining > 0 ? totalRemaining / daysRemaining : 0

        return FinanceSummary(
            monthStart: interval.start,
            totalIncomeMinor: income,
            totalExpensesMinor: expenses,
            savingsRate: savingsRate,
            categoryStatuses: statuses,
            unbudgetedSpending: unbudgeted,
            totalBudgetRemainingMinor: totalRemaining,
            safeToSpendTodayMinor: safeToSpend
        )
    }
}
