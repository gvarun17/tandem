import SwiftUI
import SwiftData

struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil when creating a new task.
    let task: TodoTask?

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var reminderEnabled = false
    @State private var reminderDate = Date()
    @State private var recurrence: TaskRecurrence = .none
    @State private var priority: TaskPriority = .normal

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("Schedule") {
                    DatePicker("Due", selection: $dueDate,
                               displayedComponents: [.date, .hourAndMinute])
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("At", selection: $reminderDate,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let task else { return }
        title = task.title
        notes = task.notes
        dueDate = task.dueDate
        reminderEnabled = task.reminderEnabled
        reminderDate = task.reminderDate
        recurrence = task.recurrence
        priority = task.priority
    }

    private func save() {
        let saved: TodoTask
        if let task {
            task.title = title
            task.notes = notes
            task.dueDate = dueDate
            task.reminderEnabled = reminderEnabled
            task.reminderDate = reminderDate
            task.recurrence = recurrence
            task.priority = priority
            saved = task
        } else {
            saved = TodoTask(title: title,
                             notes: notes,
                             dueDate: dueDate,
                             reminderEnabled: reminderEnabled,
                             reminderDate: reminderDate,
                             recurrence: recurrence,
                             priority: priority)
            modelContext.insert(saved)
        }
        try? modelContext.save()
        NotificationManager.shared.scheduleReminder(for: saved)
        dismiss()
    }
}
