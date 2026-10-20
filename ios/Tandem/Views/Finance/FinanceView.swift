import SwiftUI
import SwiftData

/// Money dashboard: month summary metrics, transactions, budgets, and
/// savings goals in three segments. All figures come from
/// `FinanceMetrics` (pure functions over the queried arrays).
struct FinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Budget.category) private var budgets: [Budget]
    @AppStorage("currencyCode") private var currencyCode = "INR"

    @State private var segment: Segment = .overview
    @State private var monthOffset = 0
    @State private var showingAddTransaction = false
    @State private var editingTransaction: Transaction?

    private enum Segment: String, CaseIterable {
        case overview = "Overview"
        case budgets = "Budgets"
        case goals = "Goals"
    }

    private let calendar = Calendar.current

    private var monthDate: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var summary: FinanceSummary {
        FinanceMetrics.summary(transactions: transactions,
                                 budgets: budgets,
                                 monthContaining: monthDate,
                                 calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                if segment != .goals {
                    monthSelector
                }
                Picker("Section", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch segment {
                case .overview:
                    overviewList
                case .budgets:
                    BudgetsView(statuses: summary.categoryStatuses,
                                unbudgeted: summary.unbudgetedSpending,
                                budgets: budgets,
                                currencyCode: currencyCode)
                case .goals:
                    SavingsGoalsView(currencyCode: currencyCode)
                }
            }
            .navigationTitle("Money")
            .toolbar {
                if segment == .overview {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddEditTransactionView(transaction: nil, currencyCode: currencyCode)
            }
            .sheet(item: $editingTransaction) { txn in
                AddEditTransactionView(transaction: txn, currencyCode: currencyCode)
            }
        }
    }

    // MARK: - Month selector

    private var monthSelector: some View {
        HStack {
            Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthDate, format: .dateTime.month(.wide).year())
                .font(.headline)
            if monthOffset != 0 {
                Button("Today") { monthOffset = 0 }
                    .font(.caption)
            }
            Spacer()
            Button { monthOffset += 1 } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Overview

    private var overviewList: some View {
        List {
            Section {
                metricCards
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))

            if monthTransactions.isEmpty {
                Section("Transactions") {
                    Text("No transactions this month. Tap + to add one.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedMonthTransactions, id: \.day) { group in
                    Section(dayLabel(group.day)) {
                        ForEach(group.transactions) { txn in
                            TransactionRowView(transaction: txn, currencyCode: currencyCode)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTransaction = txn }
                        }
                        .onDelete { offsets in
                            offsets.map { group.transactions[$0] }.forEach(delete)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var metricCards: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricCard(title: "Income",
                           value: Money.string(summary.totalIncomeMinor, currencyCode: currencyCode),
                           tint: .green)
                MetricCard(title: "Spent",
                           value: Money.string(summary.totalExpensesMinor, currencyCode: currencyCode),
                           tint: .red)
            }
            HStack(spacing: 10) {
                MetricCard(title: "Net saved",
                           value: Money.string(summary.netMinor, currencyCode: currencyCode),
                           tint: summary.netMinor >= 0 ? .green : .red)
                MetricCard(title: "Savings rate",
                           value: String(format: "%.0f%%", summary.savingsRate * 100),
                           tint: .blue)
            }
            HStack(spacing: 10) {
                MetricCard(title: "Safe to spend / day",
                           value: Money.string(summary.safeToSpendTodayMinor, currencyCode: currencyCode),
                           tint: .purple)
                MetricCard(title: "Budget remaining",
                           value: Money.string(summary.totalBudgetRemainingMinor, currencyCode: currencyCode),
                           tint: .orange)
            }
            if budgets.isEmpty {
                Text("Tip: add budgets in the Budgets tab to unlock safe-to-spend and pace tracking.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Grouping

    private var monthTransactions: [Transaction] {
        guard let interval = calendar.dateInterval(of: .month, for: monthDate) else {
            return transactions
        }
        return transactions.filter { interval.contains($0.date) }
    }

    private struct DayGroup {
        let day: Date
        let transactions: [Transaction]
    }

    private var groupedMonthTransactions: [DayGroup] {
        let byDay = Dictionary(grouping: monthTransactions) {
            calendar.startOfDay(for: $0.date)
        }
        return byDay.keys.sorted(by: >).map { day in
            DayGroup(day: day, transactions: byDay[day] ?? [])
        }
    }

    private func dayLabel(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .complete, time: .omitted)
    }

    private func delete(_ txn: Transaction) {
        modelContext.delete(txn)
        try? modelContext.save()
    }
}

/// A single summary tile on the finance dashboard.
private struct MetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// One transaction row: category + note on the left, signed amount right.
struct TransactionRowView: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: transaction.kind == .income
                  ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(transaction.kind == .income ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                    }
                    if let payer = transaction.paidBy {
                        Text("· \(payer.name)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
            Text((transaction.kind == .income ? "+" : "−")
                 + Money.string(transaction.amountMinor, currencyCode: currencyCode))
                .fontWeight(.medium)
                .foregroundStyle(transaction.kind == .income ? .green : .primary)
        }
    }
}
