import SwiftUI
import SwiftData

struct AddEditBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil when creating a new budget.
    let budget: Budget?
    /// Categories that already have a budget (offered as duplicates guard).
    let existingCategories: [String]
    let currencyCode: String

    @State private var category = "Groceries"
    @State private var customCategory = ""
    @State private var limitText = ""

    private let customSentinel = "__custom__"

    private var availableCategories: [String] {
        TransactionCategory.expense.filter {
            $0 == category || !existingCategories.contains($0)
        }
    }

    private var isValid: Bool {
        guard let limit = Money.minor(fromText: limitText), limit > 0 else { return false }
        if category == customSentinel {
            let name = customCategory.trimmingCharacters(in: .whitespaces)
            return !name.isEmpty && !existingCategories.contains(name)
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    if budget == nil {
                        Picker("Category", selection: $category) {
                            ForEach(availableCategories, id: \.self) { option in
                                Text(option).tag(option)
                            }
                            Text("Custom…").tag(customSentinel)
                        }
                        if category == customSentinel {
                            TextField("Category name", text: $customCategory)
                        }
                    } else {
                        Text(category)
                    }
                }
                Section("Monthly limit") {
                    HStack {
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                        TextField("Limit", text: $limitText)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                    }
                }
                if budget != nil {
                    Section {
                        Button("Delete Budget", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(budget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let budget {
            category = budget.category
            limitText = Money.editableText(forMinor: budget.monthlyLimitMinor)
        } else if existingCategories.contains(category) {
            // Don't preselect a category that already has a budget.
            category = TransactionCategory.expense
                .first { !existingCategories.contains($0) } ?? customSentinel
        }
    }

    private func save() {
        guard let limit = Money.minor(fromText: limitText) else { return }
        if let budget {
            budget.monthlyLimitMinor = limit
        } else {
            let finalCategory = category == customSentinel
                ? customCategory.trimmingCharacters(in: .whitespaces)
                : category
            modelContext.insert(Budget(category: finalCategory, monthlyLimitMinor: limit))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let budget else { return }
        modelContext.delete(budget)
        try? modelContext.save()
        dismiss()
    }
}
