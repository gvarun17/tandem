import SwiftUI
import SwiftData

/// Month grid + agenda for the household calendar. Recurrence is handled
/// by `CalendarEvent.occurs(on:)`; the grid just asks, per day, whether
/// any event occurs and draws dots.
struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]

    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showingAdd = false
    @State private var editingEvent: CalendarEvent?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                monthHeader
                weekdayHeader
                monthGrid
                Divider()
                agendaList
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditEventView(event: nil, initialDate: selectedDate)
            }
            .sheet(item: $editingEvent) { event in
                AddEditEventView(event: event, initialDate: event.startDate)
            }
            .onAppear {
                displayedMonth = firstOfMonth(Date())
            }
        }
    }

    // MARK: - Header & grid

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(rotatedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(monthCells) { cell in
                if let day = cell.date {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
        .padding(.horizontal)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let dayEvents = events(on: day)
        return Button {
            selectedDate = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))
                    .frame(width: 30, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().stroke(Color.accentColor, lineWidth: 1)
                        }
                    }
                HStack(spacing: 2) {
                    ForEach(dayEvents.prefix(3), id: \.id) { event in
                        Circle()
                            .fill(event.member?.color ?? Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Agenda

    private var agendaList: some View {
        let dayEvents = events(on: selectedDate)
            .sorted { $0.startDate < $1.startDate }
        return List {
            Section(selectedDate.formatted(date: .complete, time: .omitted)) {
                if dayEvents.isEmpty {
                    Text("No events this day")
                        .foregroundStyle(.secondary)
                }
                ForEach(dayEvents) { event in
                    EventRowView(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture { editingEvent = event }
                }
                .onDelete { offsets in
                    offsets.map { dayEvents[$0] }.forEach(delete)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Date math

    private struct DayCell: Identifiable {
        let id = UUID()
        let date: Date?
    }

    private func firstOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private var monthCells: [DayCell] {
        let first = firstOfMonth(displayedMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: first)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells = (0..<leadingBlanks).map { _ in DayCell(date: nil) }
        for offset in 0..<daysInMonth {
            if let day = calendar.date(byAdding: .day, value: offset, to: first) {
                cells.append(DayCell(date: day))
            }
        }
        return cells
    }

    private var rotatedWeekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private func moveMonth(by offset: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth)
        else { return }
        displayedMonth = firstOfMonth(newMonth)
        if calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) {
            selectedDate = calendar.startOfDay(for: Date())
        } else {
            selectedDate = displayedMonth
        }
    }

    private func events(on day: Date) -> [CalendarEvent] {
        events.filter { $0.occurs(on: day, calendar: calendar) }
    }

    private func delete(_ event: CalendarEvent) {
        NotificationManager.shared.cancelEventReminder(for: event)
        modelContext.delete(event)
        try? modelContext.save()
    }
}

/// One agenda row: time range, title, owner chip, recurrence marker.
private struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    if event.isAllDay {
                        Text("All day")
                    } else {
                        Text("\(event.startDate, style: .time) – \(event.endDate, style: .time)")
                    }
                    if event.recurrence != .none {
                        Label(event.recurrence.rawValue, systemImage: "repeat")
                            .labelStyle(.titleAndIcon)
                    }
                    if event.reminderDate != nil {
                        Image(systemName: "bell.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let member = event.member {
                HStack(spacing: 4) {
                    Circle().fill(member.color).frame(width: 8, height: 8)
                    Text(member.name).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
