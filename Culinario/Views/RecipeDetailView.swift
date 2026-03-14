import SwiftUI
import Combine

struct RecipeDetailView: View {
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss

    let recipe: Recipe

    // Local live copy
    @State private var liveRecipe: Recipe

    // Portion calculator
    @State private var currentServings: Int

    // Timer state
    @State private var timerMinutesInput: String = ""
    @State private var totalTimerSeconds: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var timerRunning: Bool = false
    @State private var timerStarted: Bool = false
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Edit sheet
    @State private var showEditForm = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var shareText: String = ""

    init(recipe: Recipe) {
        self.recipe = recipe
        _liveRecipe = State(initialValue: recipe)
        _currentServings = State(initialValue: recipe.servings)
        _timerMinutesInput = State(initialValue: "\(recipe.cookTimeMinutes)")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Header image / emoji
                    headerSection

                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: Meta row
                        metaRow

                        Divider()

                        // MARK: Action buttons
                        actionRow

                        Divider()

                        // MARK: Portion calculator
                        portionCalculatorSection

                        Divider()

                        // MARK: Ingredients
                        ingredientsSection

                        Divider()

                        // MARK: Instructions
                        instructionsSection

                        Divider()

                        // MARK: Timer
                        timerSection

                        // MARK: Notes
                        if !liveRecipe.notes.isEmpty {
                            Divider()
                            notesSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(liveRecipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditForm = true
                    } label: {
                        Text("Editar")
                            .foregroundColor(.accent)
                    }
                }
            }
            .onReceive(timerPublisher) { _ in
                guard timerRunning else { return }
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    timerRunning = false
                }
            }
            .sheet(isPresented: $showEditForm, onDismiss: {
                // Refresh live copy from store
                if let updated = store.recipes.first(where: { $0.id == recipe.id }) {
                    liveRecipe = updated
                }
            }) {
                RecipeFormView(recipe: liveRecipe)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [shareText])
            }
            .alert("Eliminar receita?", isPresented: $showDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    store.delete(liveRecipe)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acção não pode ser desfeita.")
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if !liveRecipe.imageUrl.isEmpty, let url = URL(string: liveRecipe.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        emojiHeaderLarge
                    }
                }
                .frame(height: 220)
                .clipped()
            } else {
                emojiHeaderLarge
            }

            // Category badge overlay
            HStack(spacing: 6) {
                Text(liveRecipe.category.emoji)
                Text(liveRecipe.category.label)
                    .font(.caption).fontWeight(.semibold)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.thinMaterial)
            .cornerRadius(20)
            .padding(12)
        }
    }

    private var emojiHeaderLarge: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accent.opacity(0.8), Color.accent.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(liveRecipe.category.emoji)
                .font(.system(size: 80))
        }
        .frame(height: 220)
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: 0) {
            metaItem(icon: "clock", label: "Prep", value: "\(liveRecipe.prepTimeMinutes) min")
            Divider().frame(height: 40)
            metaItem(icon: "flame", label: "Cozinha", value: "\(liveRecipe.cookTimeMinutes) min")
            Divider().frame(height: 40)
            metaItem(icon: "person.2", label: "Porções", value: "\(liveRecipe.servings)")
            Divider().frame(height: 40)
            VStack(spacing: 4) {
                Text(liveRecipe.difficulty.label)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(liveRecipe.difficulty.color)
                Text("Nível")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func metaItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accent)
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 16) {
            // Favourite
            Button {
                store.toggleFavorite(liveRecipe)
                if let updated = store.recipes.first(where: { $0.id == liveRecipe.id }) {
                    liveRecipe = updated
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: liveRecipe.favorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(liveRecipe.favorite ? .red : .secondary)
                    Text(liveRecipe.favorite ? "Favorita" : "Favoritar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Stars
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            store.setRating(liveRecipe, rating: star)
                            if let updated = store.recipes.first(where: { $0.id == liveRecipe.id }) {
                                liveRecipe = updated
                            }
                        } label: {
                            Image(systemName: star <= liveRecipe.rating ? "star.fill" : "star")
                                .foregroundColor(star <= liveRecipe.rating ? .yellow : .gray.opacity(0.4))
                                .font(.title3)
                        }
                    }
                }
                Text("Avaliação")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Duplicate
            Button {
                store.duplicate(liveRecipe)
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundColor(.accent)
                    Text("Duplicar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Share
            Button {
                shareText = buildShareText()
                showShareSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.accent)
                    Text("Partilhar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Delete
            Button {
                showDeleteAlert = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                    Text("Eliminar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Portion Calculator

    private var portionCalculatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Calculadora de Porções", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundColor(.accent)

            HStack(spacing: 20) {
                Button {
                    if currentServings > 1 { currentServings -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }

                VStack {
                    Text("\(currentServings)")
                        .font(.title).fontWeight(.bold)
                    Text("porções")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    if currentServings < 50 { currentServings += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }

                if currentServings != liveRecipe.servings {
                    Button {
                        currentServings = liveRecipe.servings
                    } label: {
                        Text("Repor")
                            .font(.caption)
                            .foregroundColor(.accent)
                    }
                    .padding(.leading, 8)
                }
            }

            if currentServings != liveRecipe.servings {
                Text("As quantidades foram ajustadas para \(currentServings) porção(ões).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ingredientes", systemImage: "list.bullet")
                .font(.headline)
                .foregroundColor(.accent)

            if liveRecipe.ingredients.isEmpty {
                Text("Sem ingredientes registados.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(liveRecipe.ingredients) { ingredient in
                        HStack {
                            Circle()
                                .fill(Color.accent.opacity(0.6))
                                .frame(width: 8, height: 8)
                            Text(ingredient.name)
                                .font(.subheadline)
                            Spacer()
                            Text(scaledQuantity(ingredient))
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.accent)
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private func scaledQuantity(_ ingredient: Ingredient) -> String {
        guard liveRecipe.servings > 0 else { return ingredient.quantity }
        let unit = ingredient.unit.isEmpty ? "" : " \(ingredient.unit)"
        if let qty = Double(ingredient.quantity) {
            let scaled = qty * Double(currentServings) / Double(liveRecipe.servings)
            let formatted = scaled.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(scaled))
                : String(format: "%.1f", scaled)
            return "\(formatted)\(unit)"
        }
        return "\(ingredient.quantity)\(unit)"
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Instruções", systemImage: "text.book.closed")
                .font(.headline)
                .foregroundColor(.accent)

            let steps = liveRecipe.instructions
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if steps.isEmpty {
                Text("Sem instruções registadas.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.accent)
                                .clipShape(Circle())
                            Text(step)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Temporizador", systemImage: "timer")
                .font(.headline)
                .foregroundColor(.accent)

            // MM:SS display
            Text(timerDisplayString)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(remainingSeconds == 0 && timerStarted ? .green : .primary)

            // Input field
            if !timerStarted {
                HStack {
                    TextField("Minutos", text: $timerMinutesInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("minutos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Buttons
            HStack(spacing: 16) {
                Button {
                    if !timerStarted {
                        let mins = Int(timerMinutesInput) ?? 0
                        totalTimerSeconds = mins * 60
                        remainingSeconds = totalTimerSeconds
                        timerStarted = true
                        timerRunning = true
                    } else {
                        timerRunning.toggle()
                    }
                } label: {
                    Label(
                        !timerStarted ? "Iniciar" : (timerRunning ? "Pausar" : "Retomar"),
                        systemImage: !timerStarted ? "play.fill" : (timerRunning ? "pause.fill" : "play.fill")
                    )
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(timerRunning ? Color.orange : Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button {
                    timerRunning = false
                    timerStarted = false
                    remainingSeconds = 0
                    totalTimerSeconds = 0
                    timerMinutesInput = "\(liveRecipe.cookTimeMinutes)"
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var timerDisplayString: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notas Pessoais", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(.accent)
            Text(liveRecipe.notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Share text builder

    private func buildShareText() -> String {
        var lines = ["\(liveRecipe.name)", ""]
        lines.append("Categoria: \(liveRecipe.category.label)")
        lines.append("Tempo: \(liveRecipe.totalTimeMinutes) min | Porções: \(liveRecipe.servings)")
        lines.append("Dificuldade: \(liveRecipe.difficulty.label)")
        lines.append("")
        lines.append("Ingredientes:")
        for ing in liveRecipe.ingredients {
            lines.append("  - \(ing.name): \(ing.quantity) \(ing.unit)")
        }
        lines.append("")
        lines.append("Instruções:")
        let steps = liveRecipe.instructions
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for (i, step) in steps.enumerated() {
            lines.append("\(i+1). \(step)")
        }
        if !liveRecipe.notes.isEmpty {
            lines.append("")
            lines.append("Notas: \(liveRecipe.notes)")
        }
        return lines.joined(separator: "\n")
    }
}
