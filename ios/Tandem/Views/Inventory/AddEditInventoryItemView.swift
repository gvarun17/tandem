import SwiftUI
import SwiftData

struct AddEditInventoryItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil when creating a new item.
    let item: InventoryItem?

    @State private var name = ""
    @State private var area: InventoryArea = .grocery
    @State private var quantityText = "1"
    @State private var unit = "pcs"
    @State private var thresholdText = "1"
    @State private var hasExpiry = false
    @State private var expiryDate = Date()

    private let unitSuggestions = ["pcs", "kg", "g", "L", "ml", "packs", "boxes", "bottles"]

    private func parseQuantity(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let quantity = parseQuantity(quantityText), quantity >= 0,
              let threshold = parseQuantity(thresholdText), threshold >= 0
        else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Area", selection: $area) {
                        ForEach(InventoryArea.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Stock") {
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
                    HStack {
                        Text("Low-stock alert at")
                        Spacer()
                        TextField("Threshold", text: $thresholdText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                    Text("The item is flagged as running low when the quantity is at or below the alert level.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Expiry") {
                    Toggle("Has an expiry date", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate, displayedComponents: [.date])
                    }
                }

                if item != nil {
                    Section {
                        Button("Delete Item", role: .destructive) { delete() }
                    }
                }
            }
            .navigationTitle(item == nil ? "New Item" : "Edit Item")
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
        area = item.area
        quantityText = formatQuantity(item.quantity)
        unit = item.unit
        thresholdText = formatQuantity(item.lowStockThreshold)
        hasExpiry = item.expiryDate != nil
        expiryDate = item.expiryDate ?? Date()
    }

    private func save() {
        guard let quantity = parseQuantity(quantityText),
              let threshold = parseQuantity(thresholdText) else { return }
        let expiry = hasExpiry ? expiryDate : nil
        if let item {
            item.name = name
            item.area = area
            item.quantity = quantity
            item.unit = unit
            item.lowStockThreshold = threshold
            item.expiryDate = expiry
            item.updatedAt = Date()
        } else {
            modelContext.insert(InventoryItem(name: name,
                                              area: area,
                                              quantity: quantity,
                                              unit: unit,
                                              lowStockThreshold: threshold,
                                              expiryDate: expiry))
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
