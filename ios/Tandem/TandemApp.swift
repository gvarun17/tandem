import SwiftUI
import SwiftData

@main
struct TandemApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            TodoTask.self,
            Member.self,
            CalendarEvent.self,
            Transaction.self,
            Budget.self,
            SavingsGoal.self,
            InventoryItem.self,
            ShoppingItem.self,
            FitnessGoal.self,
            WorkoutLog.self,
            Encouragement.self
        ])
    }
}
