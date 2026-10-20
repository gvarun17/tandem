import Foundation
import SwiftData

/// One entry on the shared shopping list. When bought items are moved to
/// inventory, quantities merge into `InventoryItem` by name.
@Model
final class ShoppingItem {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var isBought: Bool
    var createdAt: Date

    init(name: String,
         quantity: Double = 1,
         unit: String = "pcs",
         isBought: Bool = false) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isBought = isBought
        self.createdAt = Date()
    }
}
