import SwiftUI
import SwiftData

struct AddEditFitnessGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var members: [Member]

    /// nil when creating a new goal.
    let goal: FitnessGoal?

    @State private var metric: FitnessMetric = .workoutsMinutes
    @State private var period: GoalPeriod = .weekly
    @State private var targetText = ""
    @State private var member: Member?

    private var parsedTarget: Double? {
        Double(targetText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        guard let target = parsedTarget else { return false }
        return target > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Metric", selection: $metric) {
                        ForEach(FitnessMetric.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Period", selection: $period) {
                        ForEach(GoalPeriod.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    HStack {
                        Text("Target")
                        Spacer()
                        TextField("Target", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                        Text(metric.unitLabel)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if metric == .workoutsMinutes {
                        Text("Progress is counted automatically from logged workouts in the current \(period.rawValue.lowercased()) period.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Progress for this metric is updated manually with the + / − buttons on the Fitness tab.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !members.isEmpty {
                    Section("Who") {
                        Picker("Belongs to", selection: $member) {
                            Text("Whole household").tag(nil as Member?)
                            ForEach(members) { person in
                                Text(person.name).tag(person as Member?)
                            }
                        }
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
        metric = goal.metric
        period = goal.period
        targetText = goal.targetValue.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(goal.targetValue))
            : String(goal.targetValue)
        member = goal.member
    }

    private func save() {
        guard let target = parsedTarget else { return }
        if let goal {
            goal.metric = metric
            goal.period = period
            goal.targetValue = target
            goal.member = member
        } else {
            modelContext.insert(FitnessGoal(metric: metric,
                                            targetValue: target,
                                            period: period,
                                            member: member))
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
