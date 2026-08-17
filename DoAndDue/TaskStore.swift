//
//  TaskStore.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import Foundation
import SwiftData

@MainActor
final class TaskStore {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createTask(
        title: String,
        notes: String,
        taskType: TaskType,
        schedule: TaskSchedule,
        dueDate: Date?,
        reminder: TaskReminder,
        recurrenceInterval: Int,
        recurrenceUnit: RecurrenceUnit,
        fixedFrequency: FixedFrequency,
        fixedWeekday: Int?,
        fixedWeekdays: [Int] = [],
        fixedDayOfMonth: Int?,
        fixedMonth: Int?,
        fixedDay: Int?
    ) {

        let task = Task(
            title: title,
            notes: notes,
            taskType: taskType,
            schedule: schedule,
            dueDate: schedule == .anytime ? nil : dueDate,
            reminder: reminder,
            recurrenceInterval: recurrenceInterval,
            recurrenceUnit: recurrenceUnit,
            fixedFrequency: fixedFrequency,
            fixedWeekday: fixedWeekday,
            fixedWeekdays: fixedWeekdays,
            fixedDayOfMonth: fixedDayOfMonth,
            fixedMonth: fixedMonth,
            fixedDay: fixedDay
        )

        modelContext.insert(task)

        guard save() else {
            return
        }

        NotificationManager.shared
            .scheduleNotification(
                for: task
            )
    }

    // MARK: - Complete

    func complete(
        _ task: Task
    ) {

        let completionDate = Date()

        let completion = TaskCompletion(
            completedAt: completionDate,
            task: task
        )

        task.completions.append(completion)
        task.updatedAt = completionDate

        switch task.taskType {

        case .oneOff:

            task.schedule = .dueDate
            task.dueDate = nil

            NotificationManager.shared
                .cancelNotification(
                    for: task
                )

        case .relaxedRecurring:

            task.schedule = .dueDate
            task.dueDate =
                RecurrenceEngine.nextRelaxedDate(
                    after: completionDate,
                    interval:
                        task.recurrenceInterval,
                    unit:
                        task.recurrenceUnit
                )

        case .fixedRecurring:

            task.schedule = .dueDate
            task.dueDate =
                RecurrenceEngine.nextFixedDate(
                    after: completionDate,
                    frequency:
                        task.fixedFrequency,
                    weekdays:
                        task.fixedWeekdays,
                    dayOfMonth:
                        task.fixedDayOfMonth,
                    month:
                        task.fixedMonth,
                    day:
                        task.fixedDay
                )
        }

        guard save() else {
            return
        }

        if task.taskType != .oneOff {
            NotificationManager.shared
                .scheduleNotification(
                    for: task
                )
        }
    }

    // MARK: - Update Notification

    func updateNotification(
        for task: Task
    ) {

        NotificationManager.shared
            .cancelNotification(
                for: task
            )

        NotificationManager.shared
            .scheduleNotification(
                for: task
            )
    }

    // MARK: - Delete

    func delete(
        _ task: Task
    ) {

        NotificationManager.shared
            .cancelNotification(
                for: task
            )

        modelContext.delete(task)

        guard save() else {
            return
        }

    }

    // MARK: - Save

    @discardableResult
    func save() -> Bool {

        do {
            try modelContext.save()
            WidgetSnapshotWriter.writeSnapshot(from: modelContext)
            return true
        } catch {
            print(
                "Failed to save task: \(error)"
            )
            return false
        }
    }
}
