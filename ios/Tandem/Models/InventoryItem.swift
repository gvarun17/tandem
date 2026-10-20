import Foundation
import SwiftData

enum InventoryArea: String, Codable, CaseIterable {
    case grocery = "Grocery"
    case home = "Home"
}

/// One stocked item in the home — a grocery staple or a household item.
@Model
final class InventoryItem {
    var id: UUID
    var name: String
    var areaRaw: String
    var quantity: Double
    var unit: String
    var lowStockThreshold: Double
    var expiryDate: Date?
    var updatedAt: Date

    var area: InventoryArea {
        get { InventoryArea(rawValue: areaRaw) ?? .grocery }
        set { areaRaw = newValue.rawValue }
    }

    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }

    /// True when the item expires within the next 3 days (or already has).
    func isExpiringSoon(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let expiryDate else { return false }
        let today = calendar.startOfDay(for: now)
        guard let cutoff = calendar.date(byAdding: .day, value: 3, to: today) else { return false }
        return expiryDate < cutoff
    }

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return expiryDate < Calendar.current.startOfDay(for: Date())
    }

    init(name: String,
         area: InventoryArea = .grocery,
         quantity: Double = 1,
         unit: String = "pcs",
         lowStockThreshold: Double = 1,
         expiryDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.areaRaw = area.rawValue
        self.quantity = quantity
        self.unit = unit
        self.lowStockThreshold = lowStockThreshold
        self.expiryDate = expiryDate
        self.updatedAt = Date()
    }
}
