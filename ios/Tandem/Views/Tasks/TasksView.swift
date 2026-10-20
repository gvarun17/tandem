import SwiftUI
import SwiftData

enum TaskScope: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case all = "All"
}

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoTask.dueDate) private var tasks: [TodoTask]

    @State private var scope: TaskScope = .today
    @State private var showingAdd = false
    @State private var editingTask: TodoTask?
    @State private var showCompleted = false

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Scope", selection: $scope) {
                    ForEach(TaskScope.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(groupedTasks, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.tasks) { task in
                                TaskRowView(task: task) {
                                    toggleComplete(task)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                            }
                            .onDelete { offsets in
                                offsets.map { group.tasks[$0] }.forEach(delete)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .overlay {
                    if visibleTasks.isEmpty {
                        ContentUnavailableView(
                            "No tasks",
                            systemImage: "checklist",
                            description: Text("Tap + to add your first task.")
                        )
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showCompleted ? "Hide done" : "Show done") {
                        showCompleted.toggle()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditTaskView(task: nil)
            }
            .sheet(item: $editingTask) { task in
                AddEditTaskView(task: task)
            }
            .task {
                await NotificationManager.shared.requestAuthorization()
            }
        }
    }

    // MARK: - Filtering & grouping

    private var visibleTasks: [TodoTask] {
        let calendar = Calendar.current
        let now = Date()
        return tasks.filter { task in
            if task.isCompleted && !showCompleted { return false }
            switch scope {
            case .today:
                // Today plus anything overdue and still open.
                return calendar.isDateInToday(task.dueDate)
                    || (task.dueDate < now && !task.isCompleted)
            case .week:
                let start = calendar.startOfDay(for: now)
                guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: start)
                else { return true }
                return task.dueDate < weekEnd
            case .all:
                return true
            }
        }
    }

    private struct TaskGroup {
        let title: String
        let tasks: [TodoTask]
    }

    private var groupedTasks: [TaskGroup] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: visibleTasks) {
            calendar.startOfDay(for: $0.dueDate)
        }
        return byDay.keys.sorted().map { day in
            TaskGroup(title: dayLabel(day, calendar: calendar),
                      tasks: byDay[day] ?? [])
        }
    }

    private func dayLabel(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }

    // MARK: - Actions

    private func toggleComplete(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        if task.isCompleted {
            NotificationManager.shared.cancelReminder(for: task)
            spawnNextOccurrence(of: task)
        } else {
            NotificationManager.shared.scheduleReminder(for: task)
        }
        try? modelContext.save()
    }

    /// Completing a repeating task creates its next occurrence automatically.
    private func spawnNextOccurrence(of task: TodoTask) {
        guard let nextDue = task.recurrence.nextDate(from: task.dueDate) else { return }
        let nextReminder = task.recurrence.nextDate(from: task.reminderDate) ?? nextDue
        let next = TodoTask(title: task.title,
                            notes: task.notes,
                            dueDate: nextDue,
                            reminderEnabled: task.reminderEnabled,
                            reminderDate: nextReminder,
                            recurrence: task.recurrence,
                            priority: task.priority,
                            member: task.member)
        modelContext.insert(next)
        NotificationManager.shared.scheduleReminder(for: next)
    }

    private func delete(_ task: TodoTask) {
        NotificationManager.shared.cancelReminder(for: task)
        modelContext.delete(task)
        try? modelContext.save()
    }
}
