# Tandem

Tandem is a shared life-management app for couples and families — one place to
manage, organize, and schedule daily activities, long-term goals, and
everything in between.

## Modules (MVP)

- **Tasks** — daily/weekly to-dos, shared and assigned, with reminders
- **Calendar** — one household calendar for both partners
- **Finance** — budgeting, spending, saving, and the metrics that matter
  (safe-to-spend, savings rate, budget pace, cash-flow forecast)
- **Inventory** — grocery stock with low-stock alerts, plus an inventory of
  everything in the home

Phase 1.5 adds **fitness** metrics and goals with mutual encouragement.
Phase 3 reserves a boundary for **home automation** (garage doors, lights).

## Repository structure

```
docs/   Product Requirement Document + Technical Design Document
ios/    iOS app — full-feature on-device beta (see ios/README.md)
```

## Status

Full-feature **on-device iOS beta built**: Tasks, Calendar, Money
(budgets, savings rate, safe-to-spend, budget pace), Home inventory +
shopping list, Fitness goals/log/encouragement, and local household
members — all in SwiftUI + SwiftData with local notifications, in
`ios/`. The PRD and TDD live in `docs/`.

Next, per the TDD: the cloud backend (accounts, household tenancy,
sync), then HealthKit integration and home automation (Phase 3).
