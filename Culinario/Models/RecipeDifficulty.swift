import SwiftUI

enum RecipeDifficulty: String, Codable, CaseIterable, Identifiable {
    case FACIL
    case MEDIO
    case DIFICIL
    case CHEF

    var id: String { rawValue }

    var label: String {
        switch self {
        case .FACIL:  return "Fácil"
        case .MEDIO:  return "Médio"
        case .DIFICIL: return "Difícil"
        case .CHEF:   return "Chef"
        }
    }

    var color: Color {
        switch self {
        case .FACIL:  return .green
        case .MEDIO:  return .orange
        case .DIFICIL: return Color(red: 0.85, green: 0.19, blue: 0.19)
        case .CHEF:   return .purple
        }
    }
}
