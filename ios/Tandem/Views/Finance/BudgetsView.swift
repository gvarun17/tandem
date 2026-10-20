import SwiftUI
import SwiftData

/// Budgets segment of the Money tab: per-category progress against the
/// month's linear pace, plus spending that has no budget yet.
struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext

    let statuses: [CategoryBudgetStatus]
    let unbudgeted: [CategorySpending]
    let budgets: [Budget]
    let currencyCode: String

    @State private var showingAdd = false
    @State private var editingBudget: Budget?

    var body: some View {
        List {
            Section {
                if statuses.isEmpty {
                    Text("No budgets yet. Budgets unlock pace tracking and the safe-to-spend metric.")
                        .foregroundStyle(.secondary)
                }
                ForEach(statuses) { status in
                    BudgetStatusRow(status: status, currencyCode: currencyCode)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingBudget = budgets.first { $0.category == status.category }
                        }
                }
                .onDelete { offsets in
                    offsets
                        .compactMap { idx in budgets.first { $0.category == statuses[idx].category } }
                        .forEach(delete)
                }
            } header: {
                HStack {
                    Text("Monthly budgets")
                    Spacer()
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .textCase(nil)
                }
            }

            if !unbudgeted.isEmpty {
                Section("Spending without a budget") {
                    ForEach(unbudgeted) { item in
                        HStack {
                            Text(item.category)
                            Spacer()
                            Text(Money.string(item.spentMinor, currencyCode: currencyCode))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingAdd) {
            AddEditBudgetView(budget: nil, existingCategories: budgets.map(\.category),
                              currencyCode: currencyCode)
        }
        .sheet(item: $editingBudget) { budget in
            AddEditBudgetView(budget: budget, existingCategories: budgets.map(\.category),
                              currencyCode: currencyCode)
        }
    }

    private func delete(_ budget: Budget) {
        modelContext.delete(budget)
        try? modelContext.save()
    }
}

/// Progress bar for one category, colored by pace.
private struct BudgetStatusRow: View {
    let status: CategoryBudgetStatus
    let currencyCode: String

    private var paceColor: Color {
        switch status.pace {
        case .under: return .green
        case .onTrack: return .blue
        case .over: return .red
        }
    }

    private var paceLabel: String {
        switch status.pace {
        case .under: return "Under pace"
        case .onTrack: return "On pace"
        case .over: return "Over pace"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(status.category)
                    .fontWeight(.medium)
                Spacer()
                Text(paceLabel)
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(paceColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(paceColor)
            }
            ProgressView(value: status.fractionSpent)
                .tint(paceColor)
            HStack {
                Text("\(Money.string(status.spentMinor, currencyCode: currencyCode)) of \(Money.string(status.limitMinor, currencyCode: currencyCode))")
                Spacer()
                Text("\(Money.string(status.remainingMinor, currencyCode: currencyCode)) left")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
