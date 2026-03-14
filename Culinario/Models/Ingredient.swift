import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var quantity: String
    var unit: String

    init(id: UUID = UUID(), name: String, quantity: String, unit: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
}
