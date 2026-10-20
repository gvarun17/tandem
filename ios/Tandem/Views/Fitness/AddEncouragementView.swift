import SwiftUI
import SwiftData

/// Compose a cheer for the encouragement feed.
struct AddEncouragementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var members: [Member]

    @State private var message = ""
    @State private var fromMember: Member?
    @State private var toMember: Member?

    private var isValid: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Say something encouraging…", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                if members.isEmpty {
                    Section {
                        Text("Add members in the Household tab to cheer each other on by name. You can still post a cheer for the household.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("From / To") {
                        Picker("From", selection: $fromMember) {
                            Text("Anonymous").tag(nil as Member?)
                            ForEach(members) { person in
                                Text(person.name).tag(person as Member?)
                            }
                        }
                        Picker("To", selection: $toMember) {
                            Text("Everyone").tag(nil as Member?)
                            ForEach(members) { person in
                                Text(person.name).tag(person as Member?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Send a Cheer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                fromMember = members.first { $0.isCurrentUser }
            }
        }
    }

    private func save() {
        modelContext.insert(Encouragement(
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            fromMember: fromMember,
            toMember: toMember
        ))
        try? modelContext.save()
        dismiss()
    }
}
