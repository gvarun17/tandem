import SwiftUI
import SwiftData

struct AddEditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var members: [Member]

    /// nil when logging a new workout.
    let workout: WorkoutLog?

    @State private var type = "Run"
    @State private var duration = 30
    @State private var date = Date()
    @State private var member: Member?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(WorkoutType.suggestions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    Stepper("Duration: \(duration) min", value: $duration, in: 5...600, step: 5)
                    DatePicker("Date", selection: $date,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    if !members.isEmpty {
                        Picker("Who", selection: $member) {
                            Text("Together").tag(nil as Member?)
                            ForEach(members) { person in
                                Text(person.name).tag(person as Member?)
                            }
                        }
                    }
                    TextField("Note", text: $note, axis: .vertical)
                }

                if workout != nil {
                    Section {
                        Button("Delete Workout", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(workout == nil ? "Log Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let workout {
            type = workout.type
            duration = workout.durationMinutes
            date = workout.date
            member = workout.member
            note = workout.note
        } else {
            member = members.first { $0.isCurrentUser }
        }
    }

    private func save() {
        if let workout {
            workout.type = type
            workout.durationMinutes = duration
            workout.date = date
            workout.member = member
            workout.note = note
        } else {
            modelContext.insert(WorkoutLog(type: type,
                                           durationMinutes: duration,
                                           date: date,
                                           member: member,
                                           note: note))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let workout else { return }
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
}
