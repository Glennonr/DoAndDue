//
//  Task.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var notes: String

    var taskTypeRaw: String
    var reminderRaw: String

    // General recurrence settings
    var recurrenceInterval: Int
    var recurrenceUnitRaw: String

    // Fixed schedule settings
    var fixedFrequencyRaw: String
    var fixedWeekday: Int?
    var fixedWeekdaysRaw: String
    var fixedDayOfMonth: Int?
    var fixedMonth: Int?
    var fixedDay: Int?

    // Scheduling
    var scheduleRaw: String
    var dueDate: Date?

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TaskCompletion.task)
    var completions: [TaskCompletion]

    init(
        title: String,
        notes: String = "",
        taskType: TaskType = .oneOff,
        schedule: TaskSchedule = .dueDate,
        dueDate: Date? = Date(),
        reminder: TaskReminder = .none,
        recurrenceInterval: Int = 1,
        recurrenceUnit: RecurrenceUnit = .month,
        fixedFrequency: FixedFrequency = .monthly,
        fixedWeekday: Int? = nil,
        fixedWeekdays: [Int] = [],
        fixedDayOfMonth: Int? = nil,
        fixedMonth: Int? = nil,
        fixedDay: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.taskTypeRaw = taskType.rawValue
        self.reminderRaw = reminder.rawValue
        self.scheduleRaw = schedule.rawValue

        self.recurrenceInterval = recurrenceInterval
        self.recurrenceUnitRaw = recurrenceUnit.rawValue

        self.fixedFrequencyRaw = fixedFrequency.rawValue
        self.fixedWeekday = fixedWeekday
        self.fixedWeekdaysRaw = Task.serializedWeekdays(
            fixedWeekdays.isEmpty
                ? fixedWeekday.map { [$0] } ?? []
                : fixedWeekdays
        )
        self.fixedDayOfMonth = fixedDayOfMonth
        self.fixedMonth = fixedMonth
        self.fixedDay = fixedDay

        self.dueDate = dueDate

        self.createdAt = Date()
        self.updatedAt = Date()

        self.completions = []
    }

    var taskType: TaskType {
        get {
            TaskType(rawValue: taskTypeRaw) ?? .oneOff
        }
        set {
            taskTypeRaw = newValue.rawValue
        }
    }

    var recurrenceUnit: RecurrenceUnit {
        get {
            RecurrenceUnit(rawValue: recurrenceUnitRaw) ?? .month
        }
        set {
            recurrenceUnitRaw = newValue.rawValue
        }
    }

    var schedule: TaskSchedule {
        get {
            TaskSchedule(rawValue: scheduleRaw) ?? .dueDate
        }
        set {
            scheduleRaw = newValue.rawValue
        }
    }

    var fixedFrequency: FixedFrequency {
        get {
            FixedFrequency(rawValue: fixedFrequencyRaw) ?? .monthly
        }
        set {
            fixedFrequencyRaw = newValue.rawValue
        }
    }

    var fixedWeekdays: [Int] {
        get {
            let weekdays = fixedWeekdaysRaw
                .split(separator: ",")
                .compactMap { Int($0) }
                .filter { 1...7 ~= $0 }

            if !weekdays.isEmpty {
                return Array(Set(weekdays)).sorted()
            }

            return fixedWeekday.map { [$0] } ?? []
        }
        set {
            let weekdays = Array(Set(newValue.filter { 1...7 ~= $0 })).sorted()
            fixedWeekdaysRaw = Task.serializedWeekdays(weekdays)
            fixedWeekday = weekdays.first
        }
    }

    var isCompletedOneOff: Bool {
        taskType == .oneOff && dueDate == nil && schedule != .anytime
    }

    var isActive: Bool {
        !isCompletedOneOff
    }

    var latestCompletion: TaskCompletion? {
        completions.max {
            $0.completedAt < $1.completedAt
        }
    }

    var reminder: TaskReminder {
        get {
            TaskReminder(
                rawValue: reminderRaw
            ) ?? .none
        }
        set {
            reminderRaw = newValue.rawValue
        }
    }

    private static func serializedWeekdays(_ weekdays: [Int]) -> String {
        Array(Set(weekdays.filter { 1...7 ~= $0 }))
            .sorted()
            .map(String.init)
            .joined(separator: ",")
    }
}
