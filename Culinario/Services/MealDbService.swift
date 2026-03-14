import Foundation

// MARK: - Response Wrappers

struct MealSearchResponse: Codable {
    let meals: [MealSummary]?
}

struct MealLookupResponse: Codable {
    let meals: [MealDetail]?
}

// MARK: - MealSummary

struct MealSummary: Codable, Identifiable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strMealThumb: String?

    var id: String { idMeal }
}

// MARK: - MealDetail

struct MealDetail: Codable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strTags: String?

    // Ingredients 1–20
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?

    // Measures 1–20
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?

    var ingredientPairs: [(name: String, measure: String)] {
        let names = [
            strIngredient1, strIngredient2, strIngredient3, strIngredient4,
            strIngredient5, strIngredient6, strIngredient7, strIngredient8,
            strIngredient9, strIngredient10, strIngredient11, strIngredient12,
            strIngredient13, strIngredient14, strIngredient15, strIngredient16,
            strIngredient17, strIngredient18, strIngredient19, strIngredient20
        ]
        let measures = [
            strMeasure1, strMeasure2, strMeasure3, strMeasure4,
            strMeasure5, strMeasure6, strMeasure7, strMeasure8,
            strMeasure9, strMeasure10, strMeasure11, strMeasure12,
            strMeasure13, strMeasure14, strMeasure15, strMeasure16,
            strMeasure17, strMeasure18, strMeasure19, strMeasure20
        ]

        var pairs: [(name: String, measure: String)] = []
        for (name, measure) in zip(names, measures) {
            let n = (name ?? "").trimmingCharacters(in: .whitespaces)
            let m = (measure ?? "").trimmingCharacters(in: .whitespaces)
            if !n.isEmpty {
                pairs.append((name: n, measure: m))
            }
        }
        return pairs
    }
}

// MARK: - Service

enum MealDbError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case noResults
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "URL inválido."
        case .networkError(let e): return "Erro de rede: \(e.localizedDescription)"
        case .noResults:           return "Nenhum resultado encontrado."
        case .decodingError(let e): return "Erro ao processar dados: \(e.localizedDescription)"
        }
    }
}

class MealDbService {
    static let shared = MealDbService()
    private let baseURL = "https://www.themealdb.com/api/json/v1/1"

    private init() {}

    func search(query: String) async throws -> [MealSummary] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search.php?s=\(encoded)") else {
            throw MealDbError.invalidURL
        }

        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            data = d
        } catch {
            throw MealDbError.networkError(error)
        }

        do {
            let response = try JSONDecoder().decode(MealSearchResponse.self, from: data)
            guard let meals = response.meals, !meals.isEmpty else {
                throw MealDbError.noResults
            }
            return meals
        } catch let err as MealDbError {
            throw err
        } catch {
            throw MealDbError.decodingError(error)
        }
    }

    func getMeal(id: String) async throws -> MealDetail {
        guard let url = URL(string: "\(baseURL)/lookup.php?i=\(id)") else {
            throw MealDbError.invalidURL
        }

        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            data = d
        } catch {
            throw MealDbError.networkError(error)
        }

        do {
            let response = try JSONDecoder().decode(MealLookupResponse.self, from: data)
            guard let meal = response.meals?.first else {
                throw MealDbError.noResults
            }
            return meal
        } catch let err as MealDbError {
            throw err
        } catch {
            throw MealDbError.decodingError(error)
        }
    }

    func convertToRecipe(meal: MealDetail) -> Recipe {
        let ingredients = meal.ingredientPairs.map { pair in
            // Try to split measure into quantity + unit
            let parts = pair.measure.split(separator: " ", maxSplits: 1)
            let qty  = parts.count > 0 ? String(parts[0]) : pair.measure
            let unit = parts.count > 1 ? String(parts[1]) : ""
            return Ingredient(name: pair.name, quantity: qty, unit: unit)
        }

        // Map TheMealDB category to our RecipeCategory
        let category: RecipeCategory
        switch (meal.strCategory ?? "").lowercased() {
        case "dessert":    category = .SOBREMESA
        case "starter":   category = .LANCHE
        case "side":      category = .SALADA
        case "breakfast": category = .PEQUENO_ALMOCO
        case "soup":      category = .SOPA
        case "vegetarian": category = .VEGETARIANO
        case "vegan":     category = .VEGETARIANO
        default:          category = .JANTAR
        }

        return Recipe(
            name: meal.strMeal,
            description: meal.strArea.map { "Cozinha \($0)" } ?? "",
            category: category,
            servings: 4,
            prepTimeMinutes: 20,
            cookTimeMinutes: 30,
            difficulty: .MEDIO,
            instructions: meal.strInstructions ?? "",
            imageUrl: meal.strMealThumb ?? "",
            ingredients: ingredients
        )
    }
}
