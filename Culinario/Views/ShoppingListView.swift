import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedRecipeIDs: Set<UUID> = []
    @State private var generatedItems: [ShoppingItem] = []
    @State private var listGenerated: Bool = false
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationView {
            List {
                // MARK: Recipe selection
                Section(header: Text("Seleccionar Receitas")) {
                    if store.recipes.isEmpty {
                        Text("Sem receitas disponíveis.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(store.recipes) { recipe in
                            Button {
                                if selectedRecipeIDs.contains(recipe.id) {
                                    selectedRecipeIDs.remove(recipe.id)
                                } else {
                                    selectedRecipeIDs.insert(recipe.id)
                                }
                                // Clear previous list when selection changes
                                listGenerated = false
                                generatedItems = []
                            } label: {
                                HStack {
                                    Text(recipe.category.emoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recipe.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text("\(recipe.servings) porç. · \(recipe.totalTimeMinutes) min")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedRecipeIDs.contains(recipe.id)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundColor(selectedRecipeIDs.contains(recipe.id) ? .accent : .secondary)
                                }
                            }
                        }
                    }
                }

                // MARK: Generate button
                if !selectedRecipeIDs.isEmpty {
                    Section {
                        Button {
                            generateList()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Gerar Lista (\(selectedRecipeIDs.count) receita(s))", systemImage: "cart.badge.plus")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .background(Color.accent)
                            .cornerRadius(10)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                // MARK: Generated shopping list
                if listGenerated {
                    Section(header:
                        HStack {
                            Text("Lista de Compras")
                            Spacer()
                            Button {
                                withAnimation {
                                    for i in generatedItems.indices {
                                        generatedItems[i].checked = false
                                    }
                                }
                            } label: {
                                Text("Desmarcar todos")
                                    .font(.caption)
                                    .foregroundColor(.accent)
                            }
                        }
                    ) {
                        if generatedItems.isEmpty {
                            Text("Sem ingredientes nas receitas seleccionadas.")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            ForEach($generatedItems) { $item in
                                Button {
                                    item.checked.toggle()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.checked ? .green : .secondary)
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.subheadline)
                                                .foregroundColor(item.checked ? .secondary : .primary)
                                                .strikethrough(item.checked)
                                            Text(item.quantityDisplay)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }

                    // Share + Clear buttons
                    Section {
                        Button {
                            showShareSheet = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Partilhar Lista", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .background(Color.accent)
                            .cornerRadius(10)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        Button(role: .destructive) {
                            generatedItems = []
                            listGenerated = false
                            selectedRecipeIDs = []
                        } label: {
                            HStack {
                                Spacer()
                                Label("Limpar Tudo", systemImage: "trash")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Lista de Compras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [buildShareText()])
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Generate List

    private func generateList() {
        let selectedRecipes = store.recipes.filter { selectedRecipeIDs.contains($0.id) }

        // Gather all ingredients
        var combined: [String: ShoppingItem] = [:]

        for recipe in selectedRecipes {
            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased().trimmingCharacters(in: .whitespaces)
                if key.isEmpty { continue }

                if combined[key] != nil {
                    // Append quantity info
                    let extra = "\(ingredient.quantity) \(ingredient.unit)".trimmingCharacters(in: .whitespaces)
                    combined[key]?.quantities.append(extra)
                } else {
                    let qty = "\(ingredient.quantity) \(ingredient.unit)".trimmingCharacters(in: .whitespaces)
                    combined[key] = ShoppingItem(
                        name: ingredient.name,
                        quantities: qty.isEmpty ? [] : [qty],
                        checked: false
                    )
                }
            }
        }

        generatedItems = combined.values.sorted { $0.name < $1.name }
        listGenerated = true
    }

    // MARK: - Share Text

    private func buildShareText() -> String {
        let recipeNames = store.recipes
            .filter { selectedRecipeIDs.contains($0.id) }
            .map { $0.name }
            .joined(separator: ", ")

        var lines = ["Lista de Compras — Culinário", "Receitas: \(recipeNames)", ""]
        for item in generatedItems {
            let check = item.checked ? "✅" : "☐"
            lines.append("\(check) \(item.name) — \(item.quantityDisplay)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Shopping Item Model

struct ShoppingItem: Identifiable {
    let id = UUID()
    let name: String
    var quantities: [String]
    var checked: Bool

    var quantityDisplay: String {
        quantities.filter { !$0.isEmpty }.joined(separator: " + ")
    }
}
