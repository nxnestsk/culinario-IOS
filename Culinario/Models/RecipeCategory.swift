import Foundation

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    case PEQUENO_ALMOCO
    case ALMOCO
    case JANTAR
    case SOBREMESA
    case LANCHE
    case SOPA
    case SALADA
    case BEBIDA
    case SNACK
    case VEGETARIANO

    var id: String { rawValue }

    var label: String {
        switch self {
        case .PEQUENO_ALMOCO: return "Pequeno-Almoço"
        case .ALMOCO:         return "Almoço"
        case .JANTAR:         return "Jantar"
        case .SOBREMESA:      return "Sobremesa"
        case .LANCHE:         return "Lanche"
        case .SOPA:           return "Sopa"
        case .SALADA:         return "Salada"
        case .BEBIDA:         return "Bebida"
        case .SNACK:          return "Snack"
        case .VEGETARIANO:    return "Vegetariano"
        }
    }

    var emoji: String {
        switch self {
        case .PEQUENO_ALMOCO: return "🍳"
        case .ALMOCO:         return "🍽️"
        case .JANTAR:         return "🌙"
        case .SOBREMESA:      return "🍮"
        case .LANCHE:         return "🥪"
        case .SOPA:           return "🍲"
        case .SALADA:         return "🥗"
        case .BEBIDA:         return "🥤"
        case .SNACK:          return "🍿"
        case .VEGETARIANO:    return "🥦"
        }
    }
}
