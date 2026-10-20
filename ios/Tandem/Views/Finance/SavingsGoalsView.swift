import SwiftUI
import SwiftData

/// Savings goals segment of the Money tab: targets with progress and a
/// quick "add money" contribution action.
struct SavingsGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.createdAt) private var goals: [SavingsGoal]

    let currencyCode: String

    @State private var showingAdd = false
    @State private var editingGoal: SavingsGoal?
    @State private var contributingGoal: SavingsGoal?

    var body: some View {
        List {
            Section {
                if goals.isEmpty {
                    Text("No savings goals yet. Add one — a trip, a deposit, an emergency fund.")
                        .foregroundStyle(.secondary)
                }
                ForEach(goals) { goal in
                    SavingsGoalRow(goal: goal, currencyCode: currencyCode) {
                        contributingGoal = goal
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingGoal = goal }
                }
                .onDelete { offsets in
                    offsets.map { goals[$0] }.forEach(delete)
                }
            } header: {
                HStack {
                    Text("Savings goals")
                    Spacer()
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingAdd) {
            AddEditSavingsGoalView(goal: nil, currencyCode: currencyCode)
        }
        .sheet(item: $editingGoal) { goal in
            AddEditSavingsGoalView(goal: goal, currencyCode: currencyCode)
        }
        .sheet(item: $contributingGoal) { goal in
            ContributeView(goal: goal, currencyCode: currencyCode)
        }
    }

    private func delete(_ goal: SavingsGoal) {
        modelContext.delete(goal)
        try? modelContext.save()
    }
}

private struct SavingsGoalRow: View {
    let goal: SavingsGoal
    let currencyCode: String
    let onContribute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.name)
                    .fontWeight(.medium)
                if goal.isReached {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                Spacer()
                Button {
                    onContribute()
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            ProgressView(value: goal.progress)
                .tint(goal.isReached ? .green : .accentColor)
            HStack {
                Text("\(Money.string(goal.savedMinor, currencyCode: currencyCode)) of \(Money.string(goal.targetMinor, currencyCode: currencyCode))")
                Spacer()
                if goal.isReached {
                    Text("Reached")
                        .foregroundStyle(.green)
                } else {
                    Text("\(Money.string(goal.remainingMinor, currencyCode: currencyCode)) to go")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let deadline = goal.deadline {
                Text("By \(deadline.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Sheet that adds a contribution to a goal's saved amount.
private struct ContributeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal
    let currencyCode: String

    @State private var amountText = ""

    private var isValid: Bool {
        guard let amount = Money.minor(fromText: amountText) else { return false }
        return amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add to \(goal.name)") {
                    HStack {
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                    }
                    Text("Saved so far: \(Money.string(goal.savedMinor, currencyCode: currencyCode)) of \(Money.string(goal.targetMinor, currencyCode: currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let amount = Money.minor(fromText: amountText) else { return }
        goal.savedMinor += amount
        try? modelContext.save()
        dismiss()
    }
}
