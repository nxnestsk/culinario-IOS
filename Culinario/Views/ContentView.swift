import SwiftUI
import UniformTypeIdentifiers

// MARK: - Accent colour helper

extension Color {
    static let accent = Color(red: 0.78, green: 0.32, blue: 0.23)
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Pesquisar receitas…", text: $text)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Category Filter

struct CategoryFilterView: View {
    @EnvironmentObject var store: RecipeStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                Button {
                    store.selectedCategory = nil
                } label: {
                    Text("Todas")
                        .font(.subheadline).fontWeight(.medium)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(store.selectedCategory == nil ? Color.accent : Color(.systemGray5))
                        .foregroundColor(store.selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)
                }

                ForEach(RecipeCategory.allCases) { cat in
                    Button {
                        store.selectedCategory = (store.selectedCategory == cat) ? nil : cat
                    } label: {
                        HStack(spacing: 4) {
                            Text(cat.emoji)
                            Text(cat.label)
                                .font(.subheadline).fontWeight(.medium)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(store.selectedCategory == cat ? Color.accent : Color(.systemGray5))
                        .foregroundColor(store.selectedCategory == cat ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Sort & Count Bar

struct SortAndCountBar: View {
    @EnvironmentObject var store: RecipeStore

    var body: some View {
        HStack {
            Text("\(store.filteredRecipes.count) receita(s)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Menu {
                ForEach(SortOption.allCases) { opt in
                    Button {
                        store.sortOption = opt
                    } label: {
                        HStack {
                            Text(opt.rawValue)
                            if store.sortOption == opt {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(store.sortOption.rawValue)
                        .font(.caption)
                }
                .foregroundColor(.accent)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPick(url) }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let hasFilters: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("🍽️")
                .font(.system(size: 64))
            Text(hasFilters ? "Nenhuma receita encontrada" : "Ainda não tens receitas")
                .font(.headline)
                .foregroundColor(.secondary)
            if hasFilters {
                Text("Tenta alterar os filtros ou a pesquisa.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var store: RecipeStore

    @State private var showAddForm       = false
    @State private var showDiscover      = false
    @State private var showShoppingList  = false
    @State private var showImportPicker  = false
    @State private var exportURL: URL?
    @State private var showExportShare   = false
    @State private var selectedRecipe: Recipe? = nil
    @State private var surpriseRecipe: Recipe? = nil
    @State private var showImportSuccess = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var hasFilters: Bool {
        !store.searchText.isEmpty || store.selectedCategory != nil || store.showFavoritesOnly
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $store.searchText)
                    .padding(.top, 8)

                CategoryFilterView()
                    .padding(.top, 8)

                SortAndCountBar()
                    .padding(.top, 8)

                // Favorites toggle
                HStack {
                    Button {
                        store.showFavoritesOnly.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.showFavoritesOnly ? "heart.fill" : "heart")
                                .foregroundColor(.accent)
                            Text(store.showFavoritesOnly ? "Ver todas" : "Só favoritas")
                                .font(.caption)
                                .foregroundColor(.accent)
                        }
                    }
                    Spacer()
                    Text("❤️ \(store.favoriteCount) favorita(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                if store.filteredRecipes.isEmpty {
                    EmptyStateView(hasFilters: hasFilters)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.filteredRecipes) { recipe in
                                RecipeCardView(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Culinário")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        if let r = store.randomRecipe() {
                            surpriseRecipe = r
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundColor(.accent)
                    }
                    .help("Surpreende-me")
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showDiscover = true } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Button { showShoppingList = true } label: {
                        Image(systemName: "cart")
                    }
                    Menu {
                        Button {
                            if let url = store.exportJSON() {
                                exportURL = url
                                showExportShare = true
                            }
                        } label: {
                            Label("Exportar JSON", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showImportPicker = true
                        } label: {
                            Label("Importar JSON", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    Button { showAddForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        // Add recipe sheet
        .sheet(isPresented: $showAddForm) {
            RecipeFormView(recipe: nil)
                .environmentObject(store)
        }
        // Detail sheet
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
                .environmentObject(store)
        }
        // Surprise sheet
        .sheet(item: $surpriseRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
                .environmentObject(store)
        }
        // Discover sheet
        .sheet(isPresented: $showDiscover) {
            DiscoverView()
                .environmentObject(store)
        }
        // Shopping list sheet
        .sheet(isPresented: $showShoppingList) {
            ShoppingListView()
                .environmentObject(store)
        }
        // Export share sheet
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        // Import document picker
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker { url in
                store.importJSON(from: url)
                showImportSuccess = true
            }
        }
        .alert("Importação concluída", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("As receitas foram importadas com sucesso.")
        }
    }
}

// MARK: - ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
