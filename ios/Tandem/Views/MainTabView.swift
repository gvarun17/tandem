import SwiftUI

/// Root tab bar. Six tabs: the five feature modules plus Household,
/// where members and household settings live.
struct MainTabView: View {
    var body: some View {
        TabView {
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            FinanceView()
                .tabItem { Label("Money", systemImage: "indianrupeesign.circle") }

            InventoryView()
                .tabItem { Label("Home", systemImage: "house") }

            FitnessView()
                .tabItem { Label("Fitness", systemImage: "heart.fill") }

            HouseholdView()
                .tabItem { Label("Household", systemImage: "person.2.fill") }
        }
        .task {
            await NotificationManager.shared.requestAuthorization()
        }
    }
}
