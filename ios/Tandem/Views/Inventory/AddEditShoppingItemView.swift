import SwiftUI
import SwiftData

struct AddEditShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil when adding a new shopping-list entry.
    let item: ShoppingItem?

    @State private var name = ""
    @State private var quantityText = "1"
    @State private var unit = "pcs"

    private let unitSuggestions = ["pcs", "kg", "g", "L", "ml", "packs", "boxes", "bottles"]

    private var parsedQuantity: Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let quantity = parsedQuantity, quantity > 0
        else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Quantity", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                    Picker("Unit", selection: $unit) {
                        ForEach(unitSuggestions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                if item != nil {
                    Section {
                        Button("Delete Entry", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(item == nil ? "Add to List" : "Edit Entry")
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
        guard let item else { return }
        name = item.name
        quantityText = formatQuantity(item.quantity)
        unit = item.unit
    }

    private func save() {
        guard let quantity = parsedQuantity else { return }
        if let item {
            item.name = name
            item.quantity = quantity
            item.unit = unit
        } else {
            modelContext.insert(ShoppingItem(name: name, quantity: quantity, unit: unit))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let item else { return }
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
