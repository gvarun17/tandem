import SwiftUI
import SwiftData

@main
struct TandemApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TodoTask.self)
    }
}
