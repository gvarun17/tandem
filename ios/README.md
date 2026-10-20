# Tandem — iOS App (on-device beta)

The full Tandem feature set from the PRD/TDD, built as a native
SwiftUI + SwiftData app. This is the **on-device beta**: everything is
stored locally with SwiftData, household members are local profiles
(no cloud accounts), and reminders are local notifications. The
production backend, partner sync, and accounts from the TDD are future
work — the data model here is designed to map onto them.

## Features

Six tabs:

- **Tasks** — add/edit/complete/delete to-dos with due dates, priorities
  (Low/Normal/High), and optional assignment to a household member.
  Today / Week / All scopes with overdue surfacing, grouped by day.
  Daily/weekly repeats spawn the next occurrence on completion.
  Per-task local-notification reminders.
- **Calendar** — month grid with per-day event dots (colored by owner),
  tap a day for its agenda. Events support all-day, weekly/monthly
  repeats, notes, an optional owner, and a reminder notification.
- **Money** — income/expense transactions in integer minor units
  (paise/cents, never floats), grouped by day, with category and
  paid-by attribution. Dashboard metrics per TDD §finance: total
  income, total spent, net saved, **savings rate**, **safe-to-spend
  per day**, and budget remaining. Monthly per-category **budgets**
  with progress bars and pace status (under / on / over a linear pace
  through the month), plus a list of unbudgeted spending. **Savings
  goals** with targets, deadlines, progress, and one-tap contributions.
- **Home** — inventory in two areas (Grocery, Home) with quantities,
  units, +/− steppers, low-stock badges and a "Running low" section,
  and expiry badges (expiring within 3 days / expired). A shared
  **shopping list** whose bought items merge into inventory by name
  with one tap.
- **Fitness** — goals for steps, workout minutes, and weight over a
  weekly/monthly period, optionally per member. Workout-minutes
  progress is computed from the workout log; steps/weight progress is
  updated manually with +/− buttons (HealthKit sync is future work —
  see below). Plus a workout log and an **encouragement feed** for
  cheering each other on.
- **Household** — household name and currency (drives all money
  formatting), member management (name, color, "this is me"), and
  beta information.

## Project layout

```
Tandem/
└── Tandem/
    ├── TandemApp.swift                  — @main app, SwiftData container (all models)
    ├── Models/
    │   ├── TodoTask.swift               — task + recurrence/priority enums
    │   ├── Member.swift                 — household member + color palette
    │   ├── CalendarEvent.swift          — event + recurrence + occurs(on:)
    │   ├── Transaction.swift            — money movement (integer minor units)
    │   ├── Budget.swift                 — monthly per-category limit
    │   ├── SavingsGoal.swift            — savings target
    │   ├── InventoryItem.swift          — stocked item (grocery/home)
    │   ├── ShoppingItem.swift           — shopping-list entry
    │   ├── FitnessGoal.swift            — fitness target (steps/minutes/weight)
    │   ├── WorkoutLog.swift             — one logged workout
    │   └── Encouragement.swift          — a cheer in the feed
    ├── Services/
    │   ├── NotificationManager.swift    — task + event local notifications
    │   ├── Money.swift                  — minor-unit conversion & formatting
    │   └── FinanceMetrics.swift         — pure dashboard calculations
    └── Views/
        ├── MainTabView.swift            — the six-tab root
        ├── Tasks/      TasksView, TaskRowView, AddEditTaskView
        ├── Calendar/   CalendarView, AddEditEventView
        ├── Finance/    FinanceView, AddEditTransactionView, BudgetsView,
        │               AddEditBudgetView, SavingsGoalsView, AddEditSavingsGoalView
        ├── Inventory/  InventoryView, AddEditInventoryItemView, AddEditShoppingItemView
        ├── Fitness/    FitnessView, AddEditFitnessGoalView, AddEditWorkoutView,
        │               AddEncouragementView
        └── Household/  HouseholdView, AddEditMemberView
```

## Setup (Xcode 15 or later, iOS 17+)

1. In Xcode: **File → New → Project → iOS App**
   - Product name: `Tandem`
   - Interface: **SwiftUI**, Language: **Swift**
   - Storage: **SwiftData**
2. Delete the generated `Item.swift` and the template `ContentView.swift`.
3. Drag the `Tandem/Tandem/` folder contents from this package into the
   project navigator (check "Copy items if needed" and your app target).
   With Xcode 16's file-synchronized groups this is just dropping the
   files into the project folder — all 36 source files are picked up
   automatically.
4. Build & run on a simulator or device. On first launch the app asks
   for notification permission — allow it so reminders can fire.
5. Open the **Household** tab and add your members first; assignment
   pickers across the app light up once members exist.

## How this maps to the TDD

- **Household tenancy** → the `Member` model and optional assignment on
  tasks, events, transactions, workouts, and goals. In the beta these
  are local profiles; the TDD's accounts + household invites replace
  them when the backend lands.
- **Finance metrics** → implemented exactly as specified in
  `FinanceMetrics`: savings rate = (income − expenses) / income;
  budget pace compares spend against limit × daysElapsed/daysInMonth;
  safe-to-spend = remaining budget ÷ days left in the month. Money is
  integer minor units end-to-end.
- **Inventory ledgers** → simplified to quantity-on-hand with
  low-stock thresholds for the beta; the TDD's append-only stock
  ledger arrives with sync.
- **Fitness** → goals/log/encouragement are in; HealthKit is
  intentionally out of scope for this build, so steps and weight
  progress are manual entries (the UI says so).
- **Notifications** → local only (task and event reminders). Server
  push (APNs) comes with the backend.

## Intentionally out of scope for this beta

- Accounts, household invites, and any cloud sync (TDD backend phase)
- Bank connections / transaction import (manual + future CSV)
- HealthKit integration
- Home automation (TDD Phase 3)

## Next steps

1. Build the TDD backend (API + PostgreSQL with household tenancy and
   row-level security) and add a sync layer behind the existing models.
2. Replace local members with accounts + invites; keep the optional
   assignment relationships as-is.
3. Add HealthKit for automatic steps/workout/weight progress.
