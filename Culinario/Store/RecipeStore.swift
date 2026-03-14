import Foundation
import SwiftUI
import Combine

enum SortOption: String, CaseIterable, Identifiable {
    case recent    = "Mais recentes"
    case nameAZ    = "Nome A–Z"
    case time      = "Mais rápidas"
    case rating    = "Melhor avaliação"
    case favorites = "Favoritas primeiro"

    var id: String { rawValue }
}

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: RecipeCategory? = nil
    @Published var showFavoritesOnly: Bool = false
    @Published var sortOption: SortOption = .recent

    private let fileName = "recipes.json"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var fileURL: URL {
        documentsURL.appendingPathComponent(fileName)
    }

    init() {
        load()
        if recipes.isEmpty {
            loadSampleData()
            save()
        }
    }

    // MARK: - Filtered & Sorted Recipes

    var filteredRecipes: [Recipe] {
        var result = recipes

        // Search filter
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query)
            }
        }

        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // Favorites filter
        if showFavoritesOnly {
            result = result.filter { $0.favorite }
        }

        // Sort
        switch sortOption {
        case .recent:
            result.sort { $0.createdAt > $1.createdAt }
        case .nameAZ:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .time:
            result.sort { $0.totalTimeMinutes < $1.totalTimeMinutes }
        case .rating:
            result.sort { $0.rating > $1.rating }
        case .favorites:
            result.sort {
                if $0.favorite != $1.favorite { return $0.favorite }
                return $0.createdAt > $1.createdAt
            }
        }

        return result
    }

    var favoriteCount: Int {
        recipes.filter { $0.favorite }.count
    }

    // MARK: - CRUD

    func add(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
        save()
    }

    func update(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx] = recipe
            save()
        }
    }

    func delete(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Actions

    func toggleFavorite(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx].favorite.toggle()
            save()
        }
    }

    func setRating(_ recipe: Recipe, rating: Int) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx].rating = rating
            save()
        }
    }

    func duplicate(_ recipe: Recipe) {
        var copy = recipe
        copy.id = UUID()
        copy.name = "\(recipe.name) (cópia)"
        copy.createdAt = Date()
        copy.favorite = false
        recipes.insert(copy, at: 0)
        save()
    }

    func randomRecipe() -> Recipe? {
        recipes.randomElement()
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(recipes)
            try data.write(to: fileURL, options: [.atomicWrite])
        } catch {
            print("RecipeStore save error: \(error)")
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            recipes = try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            print("RecipeStore load error: \(error)")
        }
    }

    // MARK: - Export / Import

    func exportJSON() -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(recipes)
            let exportURL = documentsURL.appendingPathComponent("culinario_export.json")
            try data.write(to: exportURL, options: [.atomicWrite])
            return exportURL
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }

    func importJSON(from url: URL) {
        do {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([Recipe].self, from: data)
            // Merge: skip duplicates by id
            let existingIDs = Set(recipes.map { $0.id })
            let newRecipes = imported.filter { !existingIDs.contains($0.id) }
            recipes.insert(contentsOf: newRecipes, at: 0)
            save()
        } catch {
            print("Import error: \(error)")
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        let now = Date()

        recipes = [
            Recipe(
                id: UUID(),
                name: "Bacalhau à Brás",
                description: "Prato tradicional português com bacalhau desfiado, batata palha e ovos mexidos.",
                category: .ALMOCO,
                servings: 4,
                prepTimeMinutes: 20,
                cookTimeMinutes: 30,
                difficulty: .MEDIO,
                instructions: "Demolhe o bacalhau de véspera, mudando a água várias vezes.\nDesfie o bacalhau cozido, retirando peles e espinhas.\nFrite a cebola e o alho em azeite até ficarem transparentes.\nAdicione o bacalhau desfiado e a batata palha, misturando bem.\nJunte os ovos batidos e mexa em lume brando até ficarem cremosos.\nTempere com sal, pimenta e salsa picada. Decore com azeitonas pretas.",
                imageUrl: "",
                favorite: true,
                rating: 5,
                notes: "",
                createdAt: now.addingTimeInterval(-86400 * 7),
                ingredients: [
                    Ingredient(name: "Bacalhau salgado", quantity: "600", unit: "g"),
                    Ingredient(name: "Batata palha", quantity: "200", unit: "g"),
                    Ingredient(name: "Ovos", quantity: "6", unit: "unid."),
                    Ingredient(name: "Cebola", quantity: "2", unit: "unid."),
                    Ingredient(name: "Azeite", quantity: "4", unit: "colh. sopa"),
                    Ingredient(name: "Azeitonas pretas", quantity: "100", unit: "g")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Pastel de Nata",
                description: "Icónico pastel de creme português com massa folhada estaladiça e creme de gema de ovo.",
                category: .SOBREMESA,
                servings: 12,
                prepTimeMinutes: 30,
                cookTimeMinutes: 35,
                difficulty: .DIFICIL,
                instructions: "Prepare a massa folhada estendendo-a em camadas finas com manteiga.\nEnrole a massa e corte em rodelas. Forre as forminhas pressionando do centro para as bordas.\nMisture o leite, a farinha e o açúcar num tacho e leve ao lume mexendo sempre.\nQuando engrossar, retire do lume e junte as gemas batidas e a baunilha. Mexa bem.\nEncha as forminhas com o creme até 3/4 da capacidade.\nLeve ao forno a 270 °C por 10–12 minutos até ficarem com manchas escuras no topo.",
                imageUrl: "",
                favorite: true,
                rating: 5,
                notes: "O segredo é o forno bem quente.",
                createdAt: now.addingTimeInterval(-86400 * 6),
                ingredients: [
                    Ingredient(name: "Massa folhada", quantity: "500", unit: "g"),
                    Ingredient(name: "Leite gordo", quantity: "500", unit: "ml"),
                    Ingredient(name: "Açúcar", quantity: "200", unit: "g"),
                    Ingredient(name: "Gemas de ovo", quantity: "6", unit: "unid."),
                    Ingredient(name: "Farinha de trigo", quantity: "50", unit: "g"),
                    Ingredient(name: "Extrato de baunilha", quantity: "1", unit: "colh. chá")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Caldo Verde",
                description: "Sopa tradicional portuguesa com couve-galega, chouriço e azeite. Prato humilde e reconfortante.",
                category: .SOPA,
                servings: 6,
                prepTimeMinutes: 15,
                cookTimeMinutes: 35,
                difficulty: .FACIL,
                instructions: "Descasque e corte as batatas em cubos. Pique a cebola e o alho.\nCoza as batatas com a cebola e o alho em água temperada com sal.\nTriture tudo com a varinha mágica até obter um caldo homogéneo.\nAdicione a couve cortada em juliana muito fina e o chouriço às rodelas.\nCoza em lume brando por mais 5 minutos.\nRegue com fio de azeite e sirva com broa de milho.",
                imageUrl: "",
                favorite: false,
                rating: 4,
                notes: "",
                createdAt: now.addingTimeInterval(-86400 * 5),
                ingredients: [
                    Ingredient(name: "Batatas", quantity: "500", unit: "g"),
                    Ingredient(name: "Couve-galega", quantity: "200", unit: "g"),
                    Ingredient(name: "Chouriço", quantity: "150", unit: "g"),
                    Ingredient(name: "Cebola", quantity: "1", unit: "unid."),
                    Ingredient(name: "Azeite", quantity: "3", unit: "colh. sopa")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Francesinha",
                description: "Sande alentejana típica do Porto com carnes, queijo derretido e molho picante de cerveja.",
                category: .JANTAR,
                servings: 2,
                prepTimeMinutes: 20,
                cookTimeMinutes: 30,
                difficulty: .DIFICIL,
                instructions: "Grelhe as linguiças e o bife de porco. Monte as sandes com pão de forma, fiambre, linguiça e bife.\nCubra com mais uma fatia de pão por cima.\nCubra tudo com fatias de queijo e leve ao forno até derreter.\nPrepare o molho: refogue cebola, adicione tomate, cerveja, vinho do Porto e piri-piri. Deixe reduzir 15 min.\nColoque os ovos estrelados por cima e cubra com o molho quente.\nSirva com batatas fritas.",
                imageUrl: "",
                favorite: false,
                rating: 4,
                notes: "O molho pode ser feito com antecedência.",
                createdAt: now.addingTimeInterval(-86400 * 4),
                ingredients: [
                    Ingredient(name: "Pão de forma", quantity: "4", unit: "fatias"),
                    Ingredient(name: "Fiambre", quantity: "100", unit: "g"),
                    Ingredient(name: "Linguiça", quantity: "2", unit: "unid."),
                    Ingredient(name: "Bife de porco", quantity: "150", unit: "g"),
                    Ingredient(name: "Queijo flamengo", quantity: "150", unit: "g"),
                    Ingredient(name: "Cerveja", quantity: "200", unit: "ml")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Tosta de Abacate",
                description: "Pequeno-almoço saudável com abacate cremoso, limão e sementes em pão torrado.",
                category: .PEQUENO_ALMOCO,
                servings: 2,
                prepTimeMinutes: 10,
                cookTimeMinutes: 5,
                difficulty: .FACIL,
                instructions: "Torre as fatias de pão até ficarem crocantes.\nAmasse o abacate num prato com um garfo e tempere com sumo de limão, sal e pimenta.\nBarre generosamente a tosta com a mistura de abacate.\nPolvilhe com sementes de sésamo e flocos de malagueta.\nOpcionalmente, adicione um ovo estrelado por cima.",
                imageUrl: "",
                favorite: false,
                rating: 4,
                notes: "",
                createdAt: now.addingTimeInterval(-86400 * 3),
                ingredients: [
                    Ingredient(name: "Pão de mistura", quantity: "2", unit: "fatias"),
                    Ingredient(name: "Abacate maduro", quantity: "1", unit: "unid."),
                    Ingredient(name: "Limão", quantity: "0.5", unit: "unid."),
                    Ingredient(name: "Sementes de sésamo", quantity: "1", unit: "colh. sopa"),
                    Ingredient(name: "Flocos de malagueta", quantity: "1", unit: "pitada")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Açorda Alentejana",
                description: "Sopa alentejana de pão com coentros, alho e ovo escalfado. Simples e muito saborosa.",
                category: .ALMOCO,
                servings: 4,
                prepTimeMinutes: 10,
                cookTimeMinutes: 20,
                difficulty: .FACIL,
                instructions: "Pise o alho com sal num almofariz até obter uma pasta.\nAdicione os coentros frescos picados e continue a pisar.\nColoque a pasta numa tigela grande com o pão alentejano partido em pedaços.\nRegue com azeite e cubra com água a ferver. Tape e deixe repousar 5 minutos.\nEscalfe os ovos em água a ferver com um fio de vinagre.\nSirva a açorda com os ovos escalfados por cima e mais azeite.",
                imageUrl: "",
                favorite: false,
                rating: 4,
                notes: "Use pão alentejano do dia anterior.",
                createdAt: now.addingTimeInterval(-86400 * 2),
                ingredients: [
                    Ingredient(name: "Pão alentejano", quantity: "300", unit: "g"),
                    Ingredient(name: "Ovos", quantity: "4", unit: "unid."),
                    Ingredient(name: "Alho", quantity: "4", unit: "dentes"),
                    Ingredient(name: "Coentros frescos", quantity: "1", unit: "molho"),
                    Ingredient(name: "Azeite", quantity: "5", unit: "colh. sopa")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Smoothie de Manga",
                description: "Bebida tropical refrescante com manga, banana e leite de coco. Rápido e nutritivo.",
                category: .BEBIDA,
                servings: 2,
                prepTimeMinutes: 5,
                cookTimeMinutes: 0,
                difficulty: .FACIL,
                instructions: "Descasque e corte a manga e a banana em pedaços.\nColoque toda a fruta no copo do liquidificador.\nAdicione o leite de coco e o sumo de laranja.\nTriture tudo até obter uma mistura homogénea e cremosa.\nProve e ajuste a doçura com mel se necessário. Sirva de imediato com cubos de gelo.",
                imageUrl: "",
                favorite: false,
                rating: 5,
                notes: "",
                createdAt: now.addingTimeInterval(-86400 * 1),
                ingredients: [
                    Ingredient(name: "Manga madura", quantity: "1", unit: "unid."),
                    Ingredient(name: "Banana", quantity: "1", unit: "unid."),
                    Ingredient(name: "Leite de coco", quantity: "200", unit: "ml"),
                    Ingredient(name: "Sumo de laranja", quantity: "100", unit: "ml"),
                    Ingredient(name: "Mel", quantity: "1", unit: "colh. sopa")
                ]
            ),
            Recipe(
                id: UUID(),
                name: "Salada Niçoise",
                description: "Salada mediterrânica clássica com atum, ovos cozidos, feijão verde e azeitonas.",
                category: .SALADA,
                servings: 2,
                prepTimeMinutes: 20,
                cookTimeMinutes: 15,
                difficulty: .FACIL,
                instructions: "Coza os ovos durante 8 minutos, arrefeça e corte em quartos.\nBranqueie o feijão verde em água a ferver com sal por 3 minutos. Arrefeça em água gelada.\nCorteo os tomates cherry ao meio e as azeitonas se necessário.\nColoque a alface como base no prato.\nDisponha o atum escorrido, os ovos, o feijão verde, os tomates e as azeitonas.\nTempere com uma vinagrete de mostarda, azeite, vinagre e sal.",
                imageUrl: "",
                favorite: false,
                rating: 4,
                notes: "",
                createdAt: now,
                ingredients: [
                    Ingredient(name: "Atum em conserva", quantity: "200", unit: "g"),
                    Ingredient(name: "Ovos", quantity: "2", unit: "unid."),
                    Ingredient(name: "Feijão verde", quantity: "150", unit: "g"),
                    Ingredient(name: "Tomates cherry", quantity: "100", unit: "g"),
                    Ingredient(name: "Azeitonas pretas", quantity: "50", unit: "g"),
                    Ingredient(name: "Alface", quantity: "1", unit: "coração")
                ]
            )
        ]
    }
}
