# Tandem — To-Do Prototype (iOS)

A standalone SwiftUI prototype of the first Tandem feature from the PRD/TDD:
**to-do tasks with reminders**. No backend, no accounts — everything is stored
on-device with SwiftData, and reminders are local notifications.

## What it does

- Add, edit, complete, and delete tasks (title, notes, due date, priority)
- **Today / Week / All** scopes; the Today view also surfaces overdue open tasks
- Tasks grouped by day; completed tasks hidden unless "Show done" is tapped
- **Reminders**: per-task local notification at a chosen date/time
  (scheduled on save, cancelled on complete/delete, rescheduled on edit)
- **Repeating tasks**: daily or weekly — completing one automatically creates
  the next occurrence with its reminder

## Project layout

```
Tandem/
└── Tandem/
    ├── TandemApp.swift                  — @main app, SwiftData container
    ├── Models/
    │   └── TodoTask.swift                   — @Model + recurrence/priority enums
    ├── Services/
    │   └── NotificationManager.swift        — UNUserNotificationCenter wrapper
    └── Views/
        ├── ContentView.swift                — scopes, grouping, list, actions
        ├── TaskRowView.swift                — single task row
        └── AddEditTaskView.swift            — create/edit form
```

## Setup (Xcode 15 or later, iOS 17+)

1. In Xcode: **File → New → Project → iOS App**
   - Product name: `Tandem`
   - Interface: **SwiftUI**, Language: **Swift**
   - Storage: **SwiftData**
2. Delete the generated `Item.swift` (and the template `ContentView.swift`).
3. Drag the `Tandem/Tandem/` folder contents from this package into the
   project navigator (check "Copy items if needed" and your app target).
   With Xcode 16's file-synchronized groups this is just dropping the files
   into the project folder.
4. Build & run on a simulator or device. On first launch the app asks for
   notification permission — allow it so reminders can fire.

## Intentionally out of scope (per the PRD phases)

- Partner sharing / household sync (needs the backend + household tenancy
  from the TDD)
- Calendar, finance, and inventory modules
- Push notifications (server-driven) — reminders are local-only for now

## Next steps when you're ready

1. Move the model behind a repository protocol so a sync layer can be added
   without touching the views.
2. Add the household model (`Household`, `Member`) and assignment field from
   the TDD data model.
3. Wire CloudKit or the TDD's REST API for two-device sync.
