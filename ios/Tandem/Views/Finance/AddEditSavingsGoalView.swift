import SwiftUI
import SwiftData

struct AddEditSavingsGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil when creating a new goal.
    let goal: SavingsGoal?
    let currencyCode: String

    @State private var name = ""
    @State private var targetText = ""
    @State private var savedText = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let target = Money.minor(fromText: targetText), target > 0
        else { return false }
        if !savedText.isEmpty {
            guard let saved = Money.minor(fromText: savedText), saved >= 0 else { return false }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal name", text: $name)
                }
                Section("Amounts (\(currencyCode))") {
                    HStack {
                        Text("Target")
                        Spacer()
                        TextField("Target", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Saved so far")
                        Spacer()
                        TextField("0", text: $savedText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Deadline") {
                    Toggle("Set a deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("By", selection: $deadline, displayedComponents: [.date])
                    }
                }
                if goal != nil {
                    Section {
                        Button("Delete Goal", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
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
        guard let goal else { return }
        name = goal.name
        targetText = Money.editableText(forMinor: goal.targetMinor)
        savedText = Money.editableText(forMinor: goal.savedMinor)
        hasDeadline = goal.deadline != nil
        deadline = goal.deadline ?? Date()
    }

    private func save() {
        guard let target = Money.minor(fromText: targetText) else { return }
        let saved = Money.minor(fromText: savedText) ?? 0
        let finalDeadline = hasDeadline ? deadline : nil
        if let goal {
            goal.name = name
            goal.targetMinor = target
            goal.savedMinor = saved
            goal.deadline = finalDeadline
        } else {
            modelContext.insert(SavingsGoal(name: name,
                                            targetMinor: target,
                                            savedMinor: saved,
                                            deadline: finalDeadline))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let goal else { return }
        modelContext.delete(goal)
        try? modelContext.save()
        dismiss()
    }
}
