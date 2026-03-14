import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var results: [MealSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var importedIDs: Set<String> = []
    @Published var importingID: String? = nil

    private var debounceTask: Task<Void, Never>? = nil

    func onQueryChange() {
        debounceTask?.cancel()
        errorMessage = nil
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
            return
        }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let meals = try await MealDbService.shared.search(query: query)
            results = meals
        } catch let err as MealDbError {
            if case .noResults = err {
                results = []
                errorMessage = "Nenhum resultado para "\(query)"."
            } else {
                errorMessage = err.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func importMeal(_ meal: MealSummary, into store: RecipeStore) {
        importingID = meal.idMeal
        Task {
            do {
                let detail = try await MealDbService.shared.getMeal(id: meal.idMeal)
                let recipe = MealDbService.shared.convertToRecipe(meal: detail)
                store.add(recipe)
                importedIDs.insert(meal.idMeal)
            } catch {
                print("Import error: \(error)")
            }
            importingID = nil
        }
    }
}

struct DiscoverView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = DiscoverViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Pesquisar receitas (ex: chicken, pasta…)", text: $vm.searchQuery)
                        .autocorrectionDisabled()
                        .onChange(of: vm.searchQuery) { _ in
                            vm.onQueryChange()
                        }
                    if !vm.searchQuery.isEmpty {
                        Button { vm.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                if vm.isLoading {
                    Spacer()
                    ProgressView("A pesquisar…")
                    Spacer()
                } else if let err = vm.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else if vm.results.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🌍")
                            .font(.system(size: 56))
                        Text(vm.searchQuery.isEmpty
                             ? "Pesquisa receitas do mundo inteiro"
                             : "Sem resultados")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if vm.searchQuery.isEmpty {
                            Text("Experimenta: \"chicken\", \"pasta\", \"beef\", \"chocolate\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    Spacer()
                } else {
                    List(vm.results) { meal in
                        MealRowView(
                            meal: meal,
                            isImported: vm.importedIDs.contains(meal.idMeal),
                            isImporting: vm.importingID == meal.idMeal
                        ) {
                            vm.importMeal(meal, into: store)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Descobrir Receitas")
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
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Meal Row

struct MealRowView: View {
    let meal: MealSummary
    let isImported: Bool
    let isImporting: Bool
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumb = meal.strMealThumb, let url = URL(string: thumb + "/preview") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(10)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 64, height: 64)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.strMeal)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(2)
                if let cat = meal.strCategory {
                    Text(cat)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let area = meal.strArea {
                    Text(area)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Import button
            if isImporting {
                ProgressView()
                    .frame(width: 36, height: 36)
            } else if isImported {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button(action: onImport) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accent)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
