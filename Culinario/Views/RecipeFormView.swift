import SwiftUI

struct RecipeFormView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss

    // nil = new recipe, non-nil = edit
    let existingRecipe: Recipe?

    @State private var name: String
    @State private var description: String
    @State private var category: RecipeCategory
    @State private var difficulty: RecipeDifficulty
    @State private var servings: Int
    @State private var prepTime: Int
    @State private var cookTime: Int
    @State private var imageUrl: String
    @State private var instructions: String
    @State private var notes: String
    @State private var ingredients: [Ingredient]

    @State private var showValidationAlert = false

    init(recipe: Recipe?) {
        self.existingRecipe = recipe
        _name         = State(initialValue: recipe?.name         ?? "")
        _description  = State(initialValue: recipe?.description  ?? "")
        _category     = State(initialValue: recipe?.category     ?? .ALMOCO)
        _difficulty   = State(initialValue: recipe?.difficulty   ?? .FACIL)
        _servings     = State(initialValue: recipe?.servings     ?? 2)
        _prepTime     = State(initialValue: recipe?.prepTimeMinutes ?? 15)
        _cookTime     = State(initialValue: recipe?.cookTimeMinutes ?? 30)
        _imageUrl     = State(initialValue: recipe?.imageUrl     ?? "")
        _instructions = State(initialValue: recipe?.instructions ?? "")
        _notes        = State(initialValue: recipe?.notes        ?? "")
        _ingredients  = State(initialValue: recipe?.ingredients  ?? [])
    }

    var isEditing: Bool { existingRecipe != nil }

    var body: some View {
        NavigationView {
            Form {

                // MARK: Basic Info
                Section(header: Text("Informação Geral")) {
                    TextField("Nome da receita *", text: $name)
                    TextField("Descrição", text: $description)
                    TextField("URL da imagem (opcional)", text: $imageUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                // MARK: Category & Difficulty
                Section(header: Text("Classificação")) {
                    Picker("Categoria", selection: $category) {
                        ForEach(RecipeCategory.allCases) { cat in
                            HStack {
                                Text(cat.emoji)
                                Text(cat.label)
                            }.tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Dificuldade", selection: $difficulty) {
                        ForEach(RecipeDifficulty.allCases) { diff in
                            Text(diff.label).tag(diff)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Servings & Time
                Section(header: Text("Tempo e Porções")) {
                    Stepper("Porções: \(servings)", value: $servings, in: 1...20)
                    Stepper("Preparação: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cozinha: \(cookTime) min", value: $cookTime, in: 0...300, step: 5)
                }

                // MARK: Ingredients
                Section(header: Text("Ingredientes")) {
                    ForEach($ingredients) { $ingredient in
                        IngredientRowView(ingredient: $ingredient)
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }

                    Button {
                        ingredients.append(Ingredient(name: "", quantity: "", unit: ""))
                    } label: {
                        Label("Adicionar Ingrediente", systemImage: "plus.circle.fill")
                            .foregroundColor(.accent)
                    }
                }

                // MARK: Instructions
                Section(header: Text("Instruções")) {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if instructions.isEmpty {
                                    Text("Escreve as instruções passo a passo (separa cada passo com uma nova linha)…")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }

                // MARK: Notes
                Section(header: Text("Notas Pessoais")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(
                            Group {
                                if notes.isEmpty {
                                    Text("Notas, truques ou variações…")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
            }
            .navigationTitle(isEditing ? "Editar Receita" : "Nova Receita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { saveRecipe() }
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
            }
            .alert("Nome obrigatório", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Por favor, introduz um nome para a receita.")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func saveRecipe() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showValidationAlert = true
            return
        }

        // Filter out empty ingredients
        let cleanedIngredients = ingredients.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        if isEditing, var updated = existingRecipe {
            updated.name             = name
            updated.description      = description
            updated.category         = category
            updated.difficulty       = difficulty
            updated.servings         = servings
            updated.prepTimeMinutes  = prepTime
            updated.cookTimeMinutes  = cookTime
            updated.imageUrl         = imageUrl
            updated.instructions     = instructions
            updated.notes            = notes
            updated.ingredients      = cleanedIngredients
            store.update(updated)
        } else {
            let recipe = Recipe(
                name: name,
                description: description,
                category: category,
                servings: servings,
                prepTimeMinutes: prepTime,
                cookTimeMinutes: cookTime,
                difficulty: difficulty,
                instructions: instructions,
                imageUrl: imageUrl,
                notes: notes,
                ingredients: cleanedIngredients
            )
            store.add(recipe)
        }
        dismiss()
    }
}

// MARK: - Ingredient Row

struct IngredientRowView: View {
    @Binding var ingredient: Ingredient

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ingrediente", text: $ingredient.name)
                .frame(maxWidth: .infinity)
            TextField("Qtd.", text: $ingredient.quantity)
                .frame(width: 60)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
            TextField("Un.", text: $ingredient.unit)
                .frame(width: 60)
                .multilineTextAlignment(.center)
        }
        .font(.subheadline)
    }
}
