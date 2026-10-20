import Foundation
import SwiftData

/// A short note of encouragement from one member to another — the
/// household's cheer feed. Either side may be nil (e.g. a cheer for the
/// whole household).
@Model
final class Encouragement {
    var id: UUID
    var message: String
    var fromMember: Member?
    var toMember: Member?
    var date: Date

    init(message: String,
         fromMember: Member? = nil,
         toMember: Member? = nil,
         date: Date = Date()) {
        self.id = UUID()
        self.message = message
        self.fromMember = fromMember
        self.toMember = toMember
        self.date = date
    }
}
