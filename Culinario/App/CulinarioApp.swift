import SwiftUI

@main
struct CulinarioApp: App {
    @StateObject private var store = RecipeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
