import SwiftUI
import SwiftData

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var members: [Member]

    /// nil when creating a new event.
    let event: CalendarEvent?
    /// Day the event should start on when creating.
    var initialDate: Date = Date()

    @State private var title = ""
    @State private var notes = ""
    @State private var isAllDay = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var recurrence: EventRecurrence = .none
    @State private var reminderEnabled = false
    @State private var reminderDate = Date()
    @State private var assignedMember: Member?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Section("When") {
                    Toggle("All day", isOn: $isAllDay)
                    DatePicker("Starts", selection: $startDate,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker("Ends", selection: $endDate,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(EventRecurrence.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    if recurrence != .none {
                        Text("Repeats from the start date. Editing applies to the whole series.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("At", selection: $reminderDate,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }

                if !members.isEmpty {
                    Section("Who") {
                        Picker("Belongs to", selection: $assignedMember) {
                            Text("Whole household").tag(nil as Member?)
                            ForEach(members) { member in
                                Text(member.name).tag(member as Member?)
                            }
                        }
                    }
                }

                if event != nil {
                    Section {
                        Button("Delete Event", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
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
        if let event {
            title = event.title
            notes = event.notes
            isAllDay = event.isAllDay
            startDate = event.startDate
            endDate = event.endDate
            recurrence = event.recurrence
            reminderEnabled = event.reminderDate != nil
            reminderDate = event.reminderDate ?? event.startDate
            assignedMember = event.member
        } else {
            // New events start at the next hour on the selected day.
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: initialDate)
            let now = Date()
            components.hour = calendar.component(.hour, from: now) + 1
            components.minute = 0
            startDate = calendar.date(from: components) ?? initialDate
            endDate = startDate.addingTimeInterval(3600)
            reminderDate = startDate
        }
    }

    private func save() {
        let finalEnd = endDate < startDate ? startDate.addingTimeInterval(3600) : endDate
        let finalReminder = reminderEnabled ? reminderDate : nil
        let saved: CalendarEvent
        if let event {
            event.title = title
            event.notes = notes
            event.isAllDay = isAllDay
            event.startDate = startDate
            event.endDate = finalEnd
            event.recurrence = recurrence
            event.reminderDate = finalReminder
            event.member = assignedMember
            saved = event
        } else {
            saved = CalendarEvent(title: title,
                                  notes: notes,
                                  startDate: startDate,
                                  endDate: finalEnd,
                                  isAllDay: isAllDay,
                                  recurrence: recurrence,
                                  reminderDate: finalReminder,
                                  member: assignedMember)
            modelContext.insert(saved)
        }
        try? modelContext.save()
        NotificationManager.shared.scheduleEventReminder(for: saved)
        dismiss()
    }

    private func delete() {
        guard let event else { return }
        NotificationManager.shared.cancelEventReminder(for: event)
        modelContext.delete(event)
        try? modelContext.save()
        dismiss()
    }
}
