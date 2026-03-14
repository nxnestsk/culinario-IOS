import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image or emoji header
            ZStack(alignment: .topTrailing) {
                if !recipe.imageUrl.isEmpty, let url = URL(string: recipe.imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .clipped()
                        default:
                            emojiHeader
                        }
                    }
                    .frame(height: 110)
                    .clipped()
                } else {
                    emojiHeader
                }

                // Favorite heart
                Button {
                    store.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipe.favorite ? "heart.fill" : "heart")
                        .foregroundColor(recipe.favorite ? .red : .white)
                        .shadow(radius: 2)
                        .padding(8)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.subheadline).fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                if !recipe.description.isEmpty {
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Time and servings
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(recipe.totalTimeMinutes) min")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 3) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text("\(recipe.servings)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                HStack {
                    // Difficulty badge
                    Text(recipe.difficulty.label)
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(recipe.difficulty.color.opacity(0.15))
                        .foregroundColor(recipe.difficulty.color)
                        .cornerRadius(10)

                    Spacer()

                    // Stars
                    if recipe.rating > 0 {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= recipe.rating ? "star.fill" : "star")
                                    .font(.system(size: 9))
                                    .foregroundColor(star <= recipe.rating ? .yellow : .gray.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private var emojiHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accent.opacity(0.7), Color.accent.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(recipe.category.emoji)
                .font(.system(size: 44))
        }
        .frame(height: 110)
    }
}
