import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 6) {
                    Text(task.dueDate, style: .time)
                    if task.recurrence != .none {
                        Text("• \(task.recurrence.rawValue)")
                    }
                    if task.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let member = task.member {
                HStack(spacing: 4) {
                    Circle()
                        .fill(member.color)
                        .frame(width: 8, height: 8)
                    Text(member.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if task.priority == .high {
                Text("High")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.15), in: Capsule())
                    .foregroundStyle(.red)
            }
        }
    }
}
