//
//  WidgetSnapshotWriter.swift
//  Do & Due
//

import Foundation
import SwiftData
import WidgetKit

enum WidgetSnapshotWriter {
    static let appGroupIdentifier = "group.RichardGlennon.DoAndDue"
    static let snapshotFileName = "today-widget-snapshot.json"
    static let completionCommandFileName = "widget-completion-commands.json"
    static let widgetKind = "DoAndDueWidget"

    @MainActor
    static func writeSnapshot(from modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Task>()
            let tasks = try modelContext.fetch(descriptor)
            let snapshots = tasks
                .filter(\.isActive)
                .map(WidgetTaskSnapshot.init(task:))

            let data = try JSONEncoder().encode(snapshots)
            try data.write(to: snapshotURL(), options: [.atomic])
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        } catch {
            print("Failed to update widget snapshot: \(error)")
        }
    }

    private static func snapshotURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw WidgetSnapshotError.missingAppGroupContainer
        }

        return containerURL.appendingPathComponent(snapshotFileName)
    }
}

private struct WidgetTaskSnapshot: Codable {
    let id: UUID
    let title: String
    let recurrenceText: String?
    let dueDate: Date?
    let isAnytime: Bool
    let hasReminder: Bool
    let createdAt: Date

    init(task: Task) {
        self.id = task.id
        self.title = task.title
        self.recurrenceText = TaskPresentation.recurrenceText(for: task)
        self.dueDate = task.dueDate
        self.isAnytime = task.schedule == .anytime
        self.hasReminder = task.reminder != .none
        self.createdAt = task.createdAt
    }
}

enum WidgetCompletionCommandStore {
    @MainActor
    static func processPendingCompletions(modelContext: ModelContext) {
        do {
            let commands = try loadCommands()
            guard !commands.isEmpty else {
                WidgetSnapshotWriter.writeSnapshot(from: modelContext)
                return
            }

            let tasks = try modelContext.fetch(FetchDescriptor<Task>())
            let taskStore = TaskStore(modelContext: modelContext)
            var completedTaskIDs = Set<UUID>()

            for command in commands.sorted(by: { $0.createdAt < $1.createdAt }) {
                guard !completedTaskIDs.contains(command.taskID),
                      let task = tasks.first(where: { $0.id == command.taskID }),
                      task.isActive else {
                    continue
                }

                taskStore.complete(task)
                completedTaskIDs.insert(command.taskID)
            }

            try clearCommands()
            WidgetSnapshotWriter.writeSnapshot(from: modelContext)
        } catch {
            print("Failed to process widget completions: \(error)")
        }
    }

    private static func loadCommands() throws -> [WidgetCompletionCommand] {
        let commandURL = try commandURL()

        guard FileManager.default.fileExists(atPath: commandURL.path) else {
            return []
        }

        let data = try Data(contentsOf: commandURL)
        return try JSONDecoder().decode([WidgetCompletionCommand].self, from: data)
    }

    private static func clearCommands() throws {
        let commandURL = try commandURL()

        guard FileManager.default.fileExists(atPath: commandURL.path) else {
            return
        }

        try FileManager.default.removeItem(at: commandURL)
    }

    private static func commandURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetSnapshotWriter.appGroupIdentifier
        ) else {
            throw WidgetSnapshotError.missingAppGroupContainer
        }

        return containerURL.appendingPathComponent(WidgetSnapshotWriter.completionCommandFileName)
    }
}

private struct WidgetCompletionCommand: Codable {
    let id: UUID
    let taskID: UUID
    let createdAt: Date
}

private enum WidgetSnapshotError: Error {
    case missingAppGroupContainer
}
