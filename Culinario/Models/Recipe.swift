import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var category: RecipeCategory
    var servings: Int
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var difficulty: RecipeDifficulty
    var instructions: String
    var imageUrl: String
    var favorite: Bool
    var rating: Int        // 0–5
    var notes: String
    var createdAt: Date
    var ingredients: [Ingredient]

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        category: RecipeCategory = .ALMOCO,
        servings: Int = 2,
        prepTimeMinutes: Int = 15,
        cookTimeMinutes: Int = 30,
        difficulty: RecipeDifficulty = .FACIL,
        instructions: String = "",
        imageUrl: String = "",
        favorite: Bool = false,
        rating: Int = 0,
        notes: String = "",
        createdAt: Date = Date(),
        ingredients: [Ingredient] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.difficulty = difficulty
        self.instructions = instructions
        self.imageUrl = imageUrl
        self.favorite = favorite
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
        self.ingredients = ingredients
    }
}
