import SwiftUI
import SwiftData

struct AddEditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var members: [Member]

    /// nil when creating a new transaction.
    let transaction: Transaction?
    let currencyCode: String

    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var category = "Groceries"
    @State private var customCategory = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var paidBy: Member?

    private var categories: [String] {
        var list = TransactionCategory.suggestions(for: kind)
        if let transaction, !list.contains(transaction.category) {
            list.append(transaction.category)
        }
        return list
    }

    private var isValid: Bool {
        guard let amount = Money.minor(fromText: amountText), amount > 0 else { return false }
        if category == customSentinel {
            return !customCategory.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    private let customSentinel = "__custom__"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(TransactionKind.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.headline)
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { option in
                            Text(option).tag(option)
                        }
                        Text("Custom…").tag(customSentinel)
                    }
                    if category == customSentinel {
                        TextField("Category name", text: $customCategory)
                    }
                    DatePicker("Date", selection: $date,
                               displayedComponents: [.date, .hourAndMinute])
                    TextField("Note", text: $note, axis: .vertical)
                    if !members.isEmpty {
                        Picker(kind == .income ? "Received by" : "Paid by",
                               selection: $paidBy) {
                            Text("Shared").tag(nil as Member?)
                            ForEach(members) { member in
                                Text(member.name).tag(member as Member?)
                            }
                        }
                    }
                }

                if transaction != nil {
                    Section {
                        Button("Delete Transaction", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
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
            .onChange(of: kind) { _, newKind in
                let list = TransactionCategory.suggestions(for: newKind)
                if !list.contains(category), category != customSentinel {
                    category = list.first ?? "Other"
                }
            }
        }
    }

    private func load() {
        guard let transaction else { return }
        kind = transaction.kind
        amountText = Money.editableText(forMinor: transaction.amountMinor)
        let list = TransactionCategory.suggestions(for: transaction.kind)
        if list.contains(transaction.category) {
            category = transaction.category
        } else {
            category = customSentinel
            customCategory = transaction.category
        }
        date = transaction.date
        note = transaction.note
        paidBy = transaction.paidBy
    }

    private func save() {
        guard let amount = Money.minor(fromText: amountText) else { return }
        let finalCategory = category == customSentinel
            ? customCategory.trimmingCharacters(in: .whitespaces)
            : category
        if let transaction {
            transaction.amountMinor = amount
            transaction.kind = kind
            transaction.category = finalCategory
            transaction.date = date
            transaction.note = note
            transaction.paidBy = paidBy
        } else {
            let txn = Transaction(amountMinor: amount,
                                  kind: kind,
                                  category: finalCategory,
                                  date: date,
                                  note: note,
                                  paidBy: paidBy)
            modelContext.insert(txn)
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let transaction else { return }
        modelContext.delete(transaction)
        try? modelContext.save()
        dismiss()
    }
}
