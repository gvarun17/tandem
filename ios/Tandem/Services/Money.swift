import Foundation

/// Money helpers. All amounts in the app are integer minor units
/// (paise for INR, cents for USD, ...); this enum converts to and from
/// human-facing major-unit values and formats them per currency code.
enum Money {
    /// Formats minor units as a localized currency string,
    /// e.g. Money.string(123450, currencyCode: "INR") → "₹1,234.50".
    static func string(_ minor: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        let value = Double(minor) / 100
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Major-unit value (e.g. rupees) for display/editing.
    static func majorValue(ofMinor minor: Int) -> Double {
        Double(minor) / 100
    }

    /// Converts a major-unit amount entered by the user into minor units.
    static func minor(fromMajor major: Double) -> Int {
        Int((major * 100).rounded())
    }

    /// Parses a user-typed amount string ("1,234.50") into minor units.
    static func minor(fromText text: String) -> Int? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value >= 0 else { return nil }
        return minor(fromMajor: value)
    }

    /// Plain major-unit text for pre-filling amount fields (no symbol).
    static func editableText(forMinor minor: Int) -> String {
        let value = majorValue(ofMinor: minor)
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.2f", value)
    }
}
