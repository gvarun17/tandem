import SwiftUI
import SwiftData

struct AddEditMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Member.createdAt) private var allMembers: [Member]

    /// nil when adding a new member.
    let member: Member?

    @State private var name = ""
    @State private var colorHex = Member.palette[3]
    @State private var isCurrentUser = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Toggle("This is me", isOn: $isCurrentUser)
                    Text("Only one member is marked as you — cheers and workouts default to that person.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5),
                              spacing: 14) {
                        ForEach(Member.palette, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 40, height: 40)
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if member != nil {
                    Section {
                        Button("Delete Member", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(member == nil ? "New Member" : "Edit Member")
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
        guard let member else {
            // First member added on a device is probably the user.
            isCurrentUser = allMembers.isEmpty
            return
        }
        name = member.name
        colorHex = member.colorHex
        isCurrentUser = member.isCurrentUser
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        // Keep a single "current user".
        if isCurrentUser {
            for other in allMembers where other.id != member?.id {
                other.isCurrentUser = false
            }
        }
        if let member {
            member.name = trimmed
            member.colorHex = colorHex
            member.isCurrentUser = isCurrentUser
        } else {
            modelContext.insert(Member(name: trimmed,
                                       colorHex: colorHex,
                                       isCurrentUser: isCurrentUser))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let member else { return }
        modelContext.delete(member)
        try? modelContext.save()
        dismiss()
    }
}
