//
//  RecurrenceTests.swift
//  Do & DueTests
//

import Foundation
import SwiftData
import Testing
@testable import Do___Due

@Suite("Recurrence")
struct RecurrenceTests {

    private let calendar = Calendar.current

    @Test("Relaxed recurrence schedules from the completion date")
    func relaxedRecurrenceUsesCompletionDate() {
        let completionDate = date(2026, 8, 20)

        let nextDate = RecurrenceEngine.nextRelaxedDate(
            after: completionDate,
            interval: 3,
            unit: .month
        )

        #expect(dayComponents(nextDate) == DayComponents(2026, 11, 20))
    }

    @Test("Fixed weekly recurrence supports multiple selected weekdays")
    func fixedWeeklyUsesNextSelectedWeekday() {
        let monday = date(2026, 8, 17)

        let nextDate = RecurrenceEngine.nextFixedDate(
            after: monday,
            frequency: .weekly,
            weekdays: [2, 4, 6],
            dayOfMonth: nil,
            month: nil,
            day: nil
        )

        #expect(dayComponents(nextDate) == DayComponents(2026, 8, 19))
    }

    @Test("Fixed weekly recurrence moves to the following week when completed on a selected weekday")
    func fixedWeeklyDoesNotRepeatSameDay() {
        let friday = date(2026, 8, 21)

        let nextDate = RecurrenceEngine.nextFixedDate(
            after: friday,
            frequency: .weekly,
            weekdays: [2, 4, 6],
            dayOfMonth: nil,
            month: nil,
            day: nil
        )

        #expect(dayComponents(nextDate) == DayComponents(2026, 8, 24))
    }

    @Test("Fixed monthly recurrence skips months that do not contain the selected day")
    func fixedMonthlySkipsInvalidMonthDays() {
        let januaryThirtyFirst = date(2026, 1, 31)

        let nextDate = RecurrenceEngine.nextFixedDate(
            after: januaryThirtyFirst,
            frequency: .monthly,
            weekdays: [],
            dayOfMonth: 31,
            month: nil,
            day: nil
        )

        #expect(dayComponents(nextDate) == DayComponents(2026, 3, 31))
    }

    @Test("Fixed yearly recurrence skips non-leap years for February 29")
    func fixedYearlyHandlesLeapDay() {
        let leapDay = date(2024, 2, 29)

        let nextDate = RecurrenceEngine.nextFixedDate(
            after: leapDay,
            frequency: .yearly,
            weekdays: [],
            dayOfMonth: nil,
            month: 2,
            day: 29
        )

        #expect(dayComponents(nextDate) == DayComponents(2028, 2, 29))
    }

    @Test("Completing an anytime recurring task schedules its next due date")
    @MainActor
    func completingAnytimeRecurringTaskMakesItDateBasedAgain() throws {
        let container = try inMemoryContainer()
        let task = Task(
            title: "Clean garage",
            taskType: .relaxedRecurring,
            schedule: .anytime,
            dueDate: nil,
            reminder: .none,
            recurrenceInterval: 1,
            recurrenceUnit: .month
        )
        container.mainContext.insert(task)
        try container.mainContext.save()

        let store = TaskStore(modelContext: container.mainContext)
        store.complete(task)

        #expect(task.schedule == .dueDate)
        #expect(task.dueDate != nil)
        #expect(task.completions.count == 1)
    }

    private func inMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            TaskCompletion.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    private func dayComponents(_ date: Date) -> DayComponents {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        return DayComponents(
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

private struct DayComponents: Equatable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) {
        self.year = year
        self.month = month
        self.day = day
    }

    var description: String {
        "\(year)-\(month)-\(day)"
    }
}
