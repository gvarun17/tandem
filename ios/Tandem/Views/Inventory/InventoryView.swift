import SwiftUI
import SwiftData

/// Home tab: what's in stock (grocery + household inventory) and the
/// shared shopping list. Low-stock items surface in their own section;
/// bought shopping items can be merged into inventory in one tap.
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var inventoryItems: [InventoryItem]
    @Query(sort: \ShoppingItem.createdAt) private var shoppingItems: [ShoppingItem]

    @State private var segment: Segment = .inventory
    @State private var showingAddItem = false
    @State private var showingAddShopping = false
    @State private var editingItem: InventoryItem?
    @State private var editingShoppingItem: ShoppingItem?

    private enum Segment: String, CaseIterable {
        case inventory = "Inventory"
        case shopping = "Shopping"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("Section", selection: $segment) {
                    ForEach(Segment.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch segment {
                case .inventory: inventoryList
                case .shopping: shoppingList
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if segment == .inventory { showingAddItem = true }
                        else { showingAddShopping = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditInventoryItemView(item: nil)
            }
            .sheet(item: $editingItem) { item in
                AddEditInventoryItemView(item: item)
            }
            .sheet(isPresented: $showingAddShopping) {
                AddEditShoppingItemView(item: nil)
            }
            .sheet(item: $editingShoppingItem) { item in
                AddEditShoppingItemView(item: item)
            }
        }
    }

    // MARK: - Inventory

    private var lowStockItems: [InventoryItem] {
        inventoryItems.filter { $0.isLowStock }
    }

    private var inventoryList: some View {
        List {
            if !lowStockItems.isEmpty {
                Section("Running low") {
                    ForEach(lowStockItems) { item in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(item.name)
                            Spacer()
                            Text("\(formatQuantity(item.quantity)) \(item.unit) left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingItem = item }
                    }
                }
            }

            if inventoryItems.isEmpty {
                Text("Nothing in inventory yet. Tap + to add your first item.")
                    .foregroundStyle(.secondary)
            }

            ForEach(InventoryArea.allCases, id: \.self) { area in
                let areaItems = inventoryItems.filter { $0.area == area }
                if !areaItems.isEmpty {
                    Section(area.rawValue) {
                        ForEach(areaItems) { item in
                            InventoryItemRow(item: item) {
                                adjust(item, by: $0)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editingItem = item }
                        }
                        .onDelete { offsets in
                            offsets.map { areaItems[$0] }.forEach(deleteItem)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func adjust(_ item: InventoryItem, by delta: Double) {
        item.quantity = max(0, item.quantity + delta)
        item.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteItem(_ item: InventoryItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    // MARK: - Shopping

    private var boughtItems: [ShoppingItem] {
        shoppingItems.filter { $0.isBought }
    }

    private var shoppingList: some View {
        List {
            if shoppingItems.isEmpty {
                Text("The shopping list is empty. Tap + to add what you need.")
                    .foregroundStyle(.secondary)
            }
            Section {
                ForEach(shoppingItems) { item in
                    ShoppingItemRow(item: item) {
                        item.isBought.toggle()
                        try? modelContext.save()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingShoppingItem = item }
                }
                .onDelete { offsets in
                    offsets.map { shoppingItems[$0] }.forEach { entry in
                        modelContext.delete(entry)
                    }
                    try? modelContext.save()
                }
            }
            if !boughtItems.isEmpty {
                Section {
                    Button {
                        moveBoughtToInventory()
                    } label: {
                        Label("Move \(boughtItems.count) bought item(s) to inventory",
                              systemImage: "shippingbox.fill")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// Merges every bought shopping item into inventory by name
    /// (case-insensitive), then removes it from the shopping list.
    /// New items land in the grocery area with a threshold of 1.
    private func moveBoughtToInventory() {
        for entry in boughtItems {
            if let existing = inventoryItems.first(where: {
                $0.name.lowercased() == entry.name.lowercased()
            }) {
                existing.quantity += entry.quantity
                existing.updatedAt = Date()
            } else {
                modelContext.insert(InventoryItem(
                    name: entry.name,
                    area: .grocery,
                    quantity: entry.quantity,
                    unit: entry.unit,
                    lowStockThreshold: 1
                ))
            }
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

/// Formats a Double quantity without a trailing ".0" (2 → "2", 2.5 → "2.5").
func formatQuantity(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
}

private struct InventoryItemRow: View {
    let item: InventoryItem
    let onAdjust: (Double) -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .fontWeight(.medium)
                    if item.isLowStock {
                        badge("Low", color: .orange)
                    }
                    if item.isExpired {
                        badge("Expired", color: .red)
                    } else if item.isExpiringSoon() {
                        badge("Expiring soon", color: .orange)
                    }
                }
                if let expiry = item.expiryDate {
                    Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    onAdjust(-1)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Text("\(formatQuantity(item.quantity)) \(item.unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(minWidth: 52)
                Button {
                    onAdjust(1)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.title3)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

private struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isBought ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            Text(item.name)
                .strikethrough(item.isBought)
                .foregroundStyle(item.isBought ? .secondary : .primary)
            Spacer()
            Text("\(formatQuantity(item.quantity)) \(item.unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
