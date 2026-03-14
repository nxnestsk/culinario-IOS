# Culinário — App iOS

Aplicação iOS em SwiftUI que replica a aplicação web de gestão de receitas Culinário.

## Requisitos

- Xcode 14 ou superior
- Alvo de implementação iOS 15.0+
- macOS Ventura ou superior (para Xcode 14+)

## Como Abrir no Xcode

### Opção A — Criar um novo projeto Xcode e adicionar os ficheiros

1. Abra o Xcode e escolha **File > New > Project…**
2. Seleccione **App** em iOS e clique em **Next**
3. Preencha:
   - **Product Name:** `Culinario`
   - **Team:** a sua conta de programador Apple (ou None para simulador)
   - **Organization Identifier:** por exemplo `com.seunome`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 15.0
4. Guarde o projecto em `c:\Users\megar\Desktop\culinario-ios\` (ou outro caminho)
5. Elimine os ficheiros `ContentView.swift` e `<AppName>App.swift` gerados automaticamente pelo Xcode
6. No **Project Navigator**, clique com o botão direito no grupo `Culinario` e escolha **Add Files to "Culinario"…**
7. Seleccione todas as pastas e ficheiros de `c:\Users\megar\Desktop\culinario-ios\Culinario\`:
   - `App/CulinarioApp.swift`
   - `Models/Recipe.swift`
   - `Models/Ingredient.swift`
   - `Models/RecipeCategory.swift`
   - `Models/RecipeDifficulty.swift`
   - `Store/RecipeStore.swift`
   - `Services/MealDbService.swift`
   - `Views/ContentView.swift`
   - `Views/RecipeCardView.swift`
   - `Views/RecipeDetailView.swift`
   - `Views/RecipeFormView.swift`
   - `Views/DiscoverView.swift`
   - `Views/ShoppingListView.swift`
8. Certifique-se de que **"Add to target: Culinario"** está seleccionado e clique em **Add**

### Opção B — Criar um `.xcodeproj` manualmente

Se tiver experiência com ficheiros de projecto Xcode, pode criar um `xcodeproj` que aponte directamente para os ficheiros fonte neste directório. A estrutura esperada é:

```
culinario-ios/
  Culinario/
    App/
      CulinarioApp.swift
    Models/
      Recipe.swift
      Ingredient.swift
      RecipeCategory.swift
      RecipeDifficulty.swift
    Store/
      RecipeStore.swift
    Services/
      MealDbService.swift
    Views/
      ContentView.swift
      RecipeCardView.swift
      RecipeDetailView.swift
      RecipeFormView.swift
      DiscoverView.swift
      ShoppingListView.swift
```

## Compilar e Executar

1. Seleccione um simulador iPhone (por exemplo iPhone 15 Pro) no menu de esquema
2. Prima **Cmd+R** para compilar e executar
3. A aplicação será lançada com 8 receitas portuguesas de exemplo pré-carregadas

## Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| CRUD | Adicionar, editar, duplicar e eliminar receitas |
| Categorias | 10 categorias com etiquetas em emoji |
| Dificuldade | 4 níveis com distintivos com código de cores |
| Favoritos | Botão de coração nos cartões e na vista de detalhe |
| Classificação por estrelas | 1–5 estrelas, seleccionáveis na vista de detalhe |
| Calculadora de doses | Escala as quantidades dos ingredientes dinamicamente |
| Temporizador de cozinha | Iniciar/pausar/reiniciar com apresentação MM:SS |
| Notas pessoais | Notas de texto livre por receita |
| Pesquisa | Pesquisa em tempo real com debounce por nome/descrição |
| Filtro por categoria | Deslocamento horizontal de etiquetas de categoria |
| Ordenação | 5 opções de ordenação via menu |
| Exportar / Importar | Exportação e importação JSON via folha de partilha / selector de documentos |
| Descobrir | Pesquisa na API TheMealDB e importação com um toque |
| Lista de compras | Selecção múltipla de receitas, lista combinada de ingredientes, partilhar |
| Surpreenda-me | Botão de receita aleatória na barra de ferramentas |
| Persistência | Gravação/carregamento automático de Documents/recipes.json |
| Dados de exemplo | 8 receitas portuguesas pré-carregadas no primeiro lançamento |

## Permissões de rede

A funcionalidade **Descobrir** chama `https://www.themealdb.com`. Certifique-se de que o seu `Info.plist` não bloqueia pedidos não-HTTPS. Como o TheMealDB utiliza HTTPS, funciona com as predefinições do App Transport Security — não é necessária configuração adicional.

## Esquema de cores

A cor de destaque é uma terracota quente `Color(red: 0.78, green: 0.32, blue: 0.23)` que corresponde ao `#c8523a` da aplicação web. É definida como uma extensão estática em `Color` no `ContentView.swift` e reutilizada em toda a aplicação.
