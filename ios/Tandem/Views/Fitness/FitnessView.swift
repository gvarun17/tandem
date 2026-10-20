import SwiftUI
import SwiftData

/// Fitness tab: shared goals, a workout log, and the encouragement feed.
/// `workoutsMinutes` goals compute progress from the log; steps/weight
/// goals are updated manually (HealthKit sync is future work).
struct FitnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FitnessGoal.createdAt) private var goals: [FitnessGoal]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workouts: [WorkoutLog]
    @Query(sort: \Encouragement.date, order: .reverse) private var encouragements: [Encouragement]

    @State private var showingAddGoal = false
    @State private var showingAddWorkout = false
    @State private var showingAddCheer = false
    @State private var editingGoal: FitnessGoal?
    @State private var editingWorkout: WorkoutLog?

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                goalsSection
                workoutsSection
                cheersSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Fitness")
            .sheet(isPresented: $showingAddGoal) {
                AddEditFitnessGoalView(goal: nil)
            }
            .sheet(item: $editingGoal) { goal in
                AddEditFitnessGoalView(goal: goal)
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddEditWorkoutView(workout: nil)
            }
            .sheet(item: $editingWorkout) { workout in
                AddEditWorkoutView(workout: workout)
            }
            .sheet(isPresented: $showingAddCheer) {
                AddEncouragementView()
            }
        }
    }

    // MARK: - Goals

    private var goalsSection: some View {
        Section {
            if goals.isEmpty {
                Text("No fitness goals yet. Set one together — minutes, steps, or weight.")
                    .foregroundStyle(.secondary)
            }
            ForEach(goals) { goal in
                FitnessGoalRow(goal: goal,
                               progressValue: progressValue(for: goal),
                               onAdjustManual: { adjust(goal, by: $0) })
                    .contentShape(Rectangle())
                    .onTapGesture { editingGoal = goal }
            }
            .onDelete { offsets in
                offsets.map { goals[$0] }.forEach { goal in
                    modelContext.delete(goal)
                }
                try? modelContext.save()
            }
        } header: {
            HStack {
                Text("Goals")
                Spacer()
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .textCase(nil)
            }
        }
    }

    /// Current progress for a goal: computed from the workout log for
    /// minutes goals, manually stored for steps/weight goals.
    private func progressValue(for goal: FitnessGoal) -> Double {
        guard goal.metric == .workoutsMinutes else { return goal.currentValue }
        guard let interval = periodInterval(for: goal.period) else { return 0 }
        let matching = workouts.filter { workout in
            guard interval.contains(workout.date) else { return false }
            guard let owner = goal.member else { return true }
            return workout.member?.id == owner.id
        }
        return Double(matching.reduce(0) { $0 + $1.durationMinutes })
    }

    private func periodInterval(for period: GoalPeriod) -> DateInterval? {
        switch period {
        case .weekly: return calendar.dateInterval(of: .weekOfYear, for: Date())
        case .monthly: return calendar.dateInterval(of: .month, for: Date())
        }
    }

    private func adjust(_ goal: FitnessGoal, by delta: Double) {
        goal.currentValue = max(0, goal.currentValue + delta)
        try? modelContext.save()
    }

    // MARK: - Workouts

    private var workoutsSection: some View {
        Section {
            if workouts.isEmpty {
                Text("No workouts logged yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(workouts) { workout in
                WorkoutRowView(workout: workout)
                    .contentShape(Rectangle())
                    .onTapGesture { editingWorkout = workout }
            }
            .onDelete { offsets in
                offsets.map { workouts[$0] }.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        } header: {
            HStack {
                Text("Workouts")
                Spacer()
                Button {
                    showingAddWorkout = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .textCase(nil)
            }
        }
    }

    // MARK: - Cheers

    private var cheersSection: some View {
        Section {
            if encouragements.isEmpty {
                Text("No cheers yet. A little encouragement goes a long way.")
                    .foregroundStyle(.secondary)
            }
            ForEach(encouragements) { cheer in
                EncouragementRowView(cheer: cheer)
            }
            .onDelete { offsets in
                offsets.map { encouragements[$0] }.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        } header: {
            HStack {
                Text("Cheers")
                Spacer()
                Button {
                    showingAddCheer = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .textCase(nil)
            }
        }
    }
}

private struct FitnessGoalRow: View {
    let goal: FitnessGoal
    let progressValue: Double
    let onAdjustManual: (Double) -> Void

    private var progress: Double {
        guard goal.targetValue > 0 else { return 0 }
        return min(1, progressValue / goal.targetValue)
    }

    private var isComplete: Bool {
        goal.targetValue > 0 && progressValue >= goal.targetValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.metric.rawValue)
                    .fontWeight(.medium)
                if isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                Spacer()
                Text(goal.member?.name ?? "Household")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("· \(goal.period.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(isComplete ? .green : .accentColor)
            HStack {
                Text("\(formatValue(progressValue)) / \(formatValue(goal.targetValue)) \(goal.metric.unitLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if goal.metric != .workoutsMinutes {
                    HStack(spacing: 10) {
                        Button {
                            onAdjustManual(-goal.metric.manualStep)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        Button {
                            onAdjustManual(goal.metric.manualStep)
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? Int(value).formatted()
            : String(format: "%.1f", value)
    }
}

private struct WorkoutRowView: View {
    let workout: WorkoutLog

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.run")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    Text("\(workout.durationMinutes) min")
                    Text("·")
                    Text(workout.date, format: .dateTime.month().day())
                    if let member = workout.member {
                        Text("· \(member.name)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !workout.note.isEmpty {
                    Text(workout.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let member = workout.member {
                Circle().fill(member.color).frame(width: 8, height: 8)
            }
        }
    }
}

private struct EncouragementRowView: View {
    let cheer: Encouragement

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                if let from = cheer.fromMember {
                    HStack(spacing: 4) {
                        Circle().fill(from.color).frame(width: 8, height: 8)
                        Text(from.name).fontWeight(.medium)
                    }
                } else {
                    Text("Someone").fontWeight(.medium)
                }
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(cheer.toMember?.name ?? "everyone")
                    .fontWeight(.medium)
                Spacer()
                Text(cheer.date, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            Text(cheer.message)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
