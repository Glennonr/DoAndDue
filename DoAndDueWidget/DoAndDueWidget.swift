//
//  DoAndDueWidget.swift
//  DoAndDueWidget
//

import WidgetKit
import SwiftUI
import AppIntents

struct DoAndDueProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoAndDueEntry {
        DoAndDueEntry(
            date: Date(),
            tasks: WidgetTask.sampleTasks
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DoAndDueEntry) -> Void
    ) {
        let tasks = context.isPreview
            ? WidgetTask.sampleTasks
            : WidgetTaskSnapshotStore.loadTasks()

        completion(
            DoAndDueEntry(
                date: Date(),
                tasks: tasks
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DoAndDueEntry>) -> Void
    ) {
        let now = Date()
        let entry = DoAndDueEntry(
            date: now,
            tasks: WidgetTaskSnapshotStore.loadTasks()
        )
        let nextRefresh = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: now
        ) ?? now.addingTimeInterval(3600)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefresh)
            )
        )
    }
}

struct DoAndDueEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]

    var actionableTasks: [WidgetTask] {
        tasks
            .filter { $0.section != .upcoming }
            .sorted(by: WidgetTask.prioritySort)
    }

    var topTasks: [WidgetTask] {
        Array(actionableTasks.prefix(4))
    }
}

struct DoAndDueWidgetEntryView: View {
    @Environment(\.widgetFamily)
    private var family

    let entry: DoAndDueEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallDoAndDueWidget(entry: entry)

        case .systemMedium:
            MediumDoAndDueWidget(entry: entry)

        case .accessoryRectangular:
            RectangularDoAndDueWidget(entry: entry)

        default:
            MediumDoAndDueWidget(entry: entry)
        }
    }
}

struct SmallDoAndDueWidget: View {
    let entry: DoAndDueEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("D&D")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(WidgetStyle.accent)

            Spacer(minLength: 0)

            Text("\(entry.actionableTasks.count)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetStyle.text)
                .contentTransition(.numericText())

            Text(entry.actionableTasks.count == 1 ? "task today" : "tasks today")
                .font(.caption)
                .foregroundStyle(WidgetStyle.text2)
                .lineLimit(1)

            if let firstTask = entry.actionableTasks.first {
                Text(firstTask.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(firstTask.section == .overdue ? WidgetStyle.overdue : WidgetStyle.text2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetPadding()
        .widgetBackground()
        .widgetURL(entry.actionableTasks.first?.deepLinkURL ?? WidgetDeepLink.todayURL)
    }
}

struct MediumDoAndDueWidget: View {
    let entry: DoAndDueEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.8)
                    .foregroundStyle(WidgetStyle.accent)

                Spacer()

                if entry.actionableTasks.count > entry.topTasks.count {
                    Text("+\(entry.actionableTasks.count - entry.topTasks.count) more")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(WidgetStyle.text2)
                }
            }

            if entry.topTasks.isEmpty {
                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WidgetStyle.accent)

                    Text("All done")
                        .font(.headline)
                        .foregroundStyle(WidgetStyle.text)
                }

                Text("Nothing needs your attention.")
                    .font(.caption)
                    .foregroundStyle(WidgetStyle.text2)

                Spacer(minLength: 0)
            } else {
                VStack(spacing: 7) {
                    ForEach(entry.topTasks) { task in
                        WidgetTaskRow(task: task)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetPadding()
        .widgetBackground()
        .widgetURL(WidgetDeepLink.todayURL)
    }
}

struct RectangularDoAndDueWidget: View {
    let entry: DoAndDueEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.actionableTasks.isEmpty ? "checkmark.circle.fill" : "circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.actionableTasks.isEmpty ? "All done" : "\(entry.actionableTasks.count) tasks today")
                    .font(.headline)
                    .lineLimit(1)

                Text(entry.actionableTasks.first?.title ?? "Nothing needs your attention")
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .widgetURL(entry.actionableTasks.first?.deepLinkURL ?? WidgetDeepLink.todayURL)
    }
}

struct WidgetTaskRow: View {
    let task: WidgetTask

    var body: some View {
        HStack(spacing: 10) {
            Button(intent: CompleteTaskIntent(taskID: task.id.uuidString)) {
                Circle()
                    .stroke(task.section == .overdue ? WidgetStyle.overdue : WidgetStyle.text3, lineWidth: 1.6)
                    .frame(width: 18, height: 18)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(task.title)")

            Link(destination: task.deepLinkURL) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(WidgetStyle.text)
                        .lineLimit(1)

                    Text(task.detailText)
                        .font(.caption2)
                        .foregroundStyle(task.section == .overdue ? WidgetStyle.overdue : WidgetStyle.text2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks a Do & Due task complete from the widget.")

    @Parameter(title: "Task ID")
    var taskID: String

    init() {
        self.taskID = ""
    }

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let taskID = UUID(uuidString: taskID) else {
            return .result()
        }

        try WidgetCompletionCommandStore.appendCompletion(for: taskID)
        try WidgetTaskSnapshotStore.removeTask(withID: taskID)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.widgetKind)

        return .result()
    }
}

struct DoAndDueWidget: Widget {
    let kind = WidgetConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoAndDueProvider()) { entry in
            DoAndDueWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Do & Due")
        .description("See what needs your attention today.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular
        ])
    }
}

struct WidgetTask: Codable, Identifiable {
    enum Section: String, Codable {
        case overdue
        case today
        case anytime
        case upcoming
    }

    let id: UUID
    let title: String
    let recurrenceText: String?
    let dueDate: Date?
    let isAnytime: Bool
    let hasReminder: Bool
    let createdAt: Date

    var section: Section {
        guard !isAnytime,
              let dueDate else {
            return .anytime
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDueDay = calendar.startOfDay(for: dueDate)

        if startOfDueDay < startOfToday {
            return .overdue
        }

        if calendar.isDateInToday(dueDate) {
            return .today
        }

        return .upcoming
    }

    var detailText: String {
        let timingText: String

        switch section {
        case .overdue:
            timingText = overdueText
        case .today:
            timingText = "Due today"
        case .anytime:
            timingText = "Anytime"
        case .upcoming:
            timingText = dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "Upcoming"
        }

        if let recurrenceText {
            return "\(recurrenceText) · \(timingText)"
        }

        return timingText
    }

    var deepLinkURL: URL {
        URL(string: "doanddue://task/\(id.uuidString)") ?? WidgetDeepLink.tasksURL
    }

    private var overdueText: String {
        guard let dueDate else {
            return "Overdue"
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: dueDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0

        return "\(days) day\(days == 1 ? "" : "s") overdue"
    }

    static func prioritySort(_ lhs: WidgetTask, _ rhs: WidgetTask) -> Bool {
        if lhs.section.priority != rhs.section.priority {
            return lhs.section.priority < rhs.section.priority
        }

        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?):
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt < rhs.createdAt
        }
    }

    static let sampleTasks = [
        WidgetTask(
            id: UUID(),
            title: "Pay electric bill",
            recurrenceText: "No repeat",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isAnytime: false,
            hasReminder: true,
            createdAt: Date()
        ),
        WidgetTask(
            id: UUID(),
            title: "Change HVAC filter",
            recurrenceText: "Every 3 months",
            dueDate: Date(),
            isAnytime: false,
            hasReminder: false,
            createdAt: Date()
        ),
        WidgetTask(
            id: UUID(),
            title: "Organize utility closet",
            recurrenceText: "No repeat",
            dueDate: nil,
            isAnytime: true,
            hasReminder: false,
            createdAt: Date()
        )
    ]
}

private enum WidgetConstants {
    static let appGroupIdentifier = "group.RichardGlennon.DoAndDue"
    static let snapshotFileName = "today-widget-snapshot.json"
    static let completionCommandFileName = "widget-completion-commands.json"
    static let widgetKind = "DoAndDueWidget"
}

private enum WidgetDeepLink {
    static let todayURL = URL(string: "doanddue://today")!
    static let tasksURL = URL(string: "doanddue://tasks")!
}

private extension WidgetTask.Section {
    var priority: Int {
        switch self {
        case .overdue:
            return 0
        case .today:
            return 1
        case .anytime:
            return 2
        case .upcoming:
            return 3
        }
    }
}

private enum WidgetTaskSnapshotStore {
    static func loadTasks() -> [WidgetTask] {
        guard let data = try? Data(contentsOf: snapshotURL()),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
            return []
        }

        return tasks
    }

    static func removeTask(withID taskID: UUID) throws {
        let tasks = loadTasks().filter { $0.id != taskID }
        let data = try JSONEncoder().encode(tasks)
        try data.write(to: snapshotURL(), options: [.atomic])
    }

    private static func snapshotURL() throws -> URL {
        try appGroupContainerURL().appendingPathComponent(WidgetConstants.snapshotFileName)
    }
}

private enum WidgetCompletionCommandStore {
    static func appendCompletion(for taskID: UUID) throws {
        var commands = loadCommands()
        commands.append(
            WidgetCompletionCommand(
                id: UUID(),
                taskID: taskID,
                createdAt: Date()
            )
        )

        let data = try JSONEncoder().encode(commands)
        try data.write(to: commandURL(), options: [.atomic])
    }

    private static func loadCommands() -> [WidgetCompletionCommand] {
        guard let data = try? Data(contentsOf: commandURL()),
              let commands = try? JSONDecoder().decode([WidgetCompletionCommand].self, from: data) else {
            return []
        }

        return commands
    }

    private static func commandURL() throws -> URL {
        try appGroupContainerURL().appendingPathComponent(WidgetConstants.completionCommandFileName)
    }
}

private struct WidgetCompletionCommand: Codable {
    let id: UUID
    let taskID: UUID
    let createdAt: Date
}

private func appGroupContainerURL() throws -> URL {
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: WidgetConstants.appGroupIdentifier
    ) else {
        throw WidgetStoreError.missingAppGroupContainer
    }

    return containerURL
}

private enum WidgetStoreError: Error {
    case missingAppGroupContainer
}

private enum WidgetStyle {
    static let accent = Color(red: 79 / 255, green: 123 / 255, blue: 110 / 255)
    static let accentLight = Color(red: 234 / 255, green: 242 / 255, blue: 240 / 255)
    static let overdue = Color(red: 184 / 255, green: 84 / 255, blue: 80 / 255)
    static let text = Color.primary
    static let text2 = Color.secondary
    static let text3 = Color.secondary.opacity(0.7)
}

private extension View {
    func widgetPadding() -> some View {
        padding(14)
    }

    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(.fill.tertiary, for: .widget)
        } else {
            return padding(0).background(Color(.systemBackground))
        }
    }
}

#Preview(as: .systemSmall) {
    DoAndDueWidget()
} timeline: {
    DoAndDueEntry(date: .now, tasks: WidgetTask.sampleTasks)
}

#Preview(as: .systemMedium) {
    DoAndDueWidget()
} timeline: {
    DoAndDueEntry(date: .now, tasks: WidgetTask.sampleTasks)
}
