import SwiftUI
import SwiftData

/// Household tab: the household's name and currency, its members
/// (local profiles used for assignment and attribution), and an about
/// note. In this beta there are no cloud accounts — members are managed
/// entirely on-device.
struct HouseholdView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Member.createdAt) private var members: [Member]

    @AppStorage("householdName") private var householdName = "Our Household"
    @AppStorage("currencyCode") private var currencyCode = "INR"

    @State private var showingAddMember = false
    @State private var editingMember: Member?

    private let currencies = ["INR", "USD", "EUR", "GBP", "AED", "SGD", "AUD", "CAD", "JPY"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Household") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Household name", text: $householdName)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }

                Section {
                    if members.isEmpty {
                        Text("No members yet. Add the people in your household so tasks, events, spending, and workouts can be attributed to them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(members) { member in
                        MemberRowView(member: member)
                            .contentShape(Rectangle())
                            .onTapGesture { editingMember = member }
                    }
                    .onDelete { offsets in
                        offsets.map { members[$0] }.forEach { member in
                            modelContext.delete(member)
                        }
                        try? modelContext.save()
                    }
                    Button {
                        showingAddMember = true
                    } label: {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Members")
                } footer: {
                    Text("Deleting a member keeps their tasks, events, and history — they just become unassigned.")
                }

                Section("About this beta") {
                    Text("Tandem on this device is the on-device beta: everything is stored locally with SwiftData and reminders are local notifications. Accounts, partner sync, and the cloud backend from the design docs arrive in a later release.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Household")
            .sheet(isPresented: $showingAddMember) {
                AddEditMemberView(member: nil)
            }
            .sheet(item: $editingMember) { member in
                AddEditMemberView(member: member)
            }
        }
    }
}

private struct MemberRowView: View {
    let member: Member

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(member.color)
                    .frame(width: 36, height: 36)
                Text(String(member.name.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text(member.name)
            if member.isCurrentUser {
                Text("You")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()
            Text("\(member.tasks.count + member.events.count + member.workouts.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
