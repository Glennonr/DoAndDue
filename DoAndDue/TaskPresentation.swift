//
//  TaskPresentation.swift
//  Do & Due
//

import Foundation

enum TaskPresentation {

    private static let weekdayNames: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.weekdaySymbols
    }()

    private static let shortWeekdayNames: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }()

    private static let monthNames: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.monthSymbols
    }()

    static func metadataText(for task: Task) -> String {
        let parts = [
            recurrenceText(for: task),
            scheduleText(for: task)
        ].compactMap { $0 }

        return parts.joined(separator: " · ")
    }

    static func scheduleText(for task: Task) -> String? {
        if task.schedule == .anytime {
            return "Anytime"
        }

        return task.dueDate.map { dueText(for: $0) }
    }

    static func recurrenceText(for task: Task) -> String? {
        switch task.taskType {
        case .oneOff:
            return "No repeat"

        case .relaxedRecurring:
            return relaxedRecurrenceText(
                interval: task.recurrenceInterval,
                unit: task.recurrenceUnit
            )

        case .fixedRecurring:
            return fixedRecurrenceText(
                frequency: task.fixedFrequency,
                weekdays: task.fixedWeekdays,
                dayOfMonth: task.fixedDayOfMonth,
                month: task.fixedMonth,
                day: task.fixedDay
            )
        }
    }

    static func editorPreview(
        taskType: TaskType,
        dueDate: Date,
        recurrenceInterval: Int,
        recurrenceUnit: RecurrenceUnit,
        fixedFrequency: FixedFrequency,
        fixedWeekdays: [Int],
        fixedDayOfMonth: Int,
        fixedMonth: Int,
        fixedDay: Int
    ) -> String? {
        switch taskType {
        case .oneOff:
            return nil

        case .relaxedRecurring:
            let nextDate = RecurrenceEngine.nextRelaxedDate(
                after: dueDate,
                interval: recurrenceInterval,
                unit: recurrenceUnit
            )

            return relaxedRecurrenceText(
                interval: recurrenceInterval,
                unit: recurrenceUnit
            ) + " after completion · Next: " + shortDateText(for: nextDate)

        case .fixedRecurring:
            let nextDate = RecurrenceEngine.nextFixedDate(
                after: dueDate,
                frequency: fixedFrequency,
                weekdays: fixedWeekdays,
                dayOfMonth: fixedDayOfMonth,
                month: fixedMonth,
                day: fixedDay
            )

            let summary = fixedRecurrenceText(
                frequency: fixedFrequency,
                weekdays: fixedWeekdays,
                dayOfMonth: fixedDayOfMonth,
                month: fixedMonth,
                day: fixedDay
            )

            return summary + " · Next: " + shortDateText(for: nextDate)
        }
    }

    static func dueText(for date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)

        if calendar.isDateInToday(date) {
            return "Due today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        if startOfDate < startOfToday {
            let days = calendar.dateComponents(
                [.day],
                from: startOfDate,
                to: startOfToday
            ).day ?? 0

            return "\(days) day\(days == 1 ? "" : "s") overdue"
        }

        return shortDateText(for: date)
    }

    static func shortDateText(for date: Date) -> String {
        date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

    static func longDateText(for date: Date) -> String {
        date.formatted(
            date: .long,
            time: .omitted
        )
    }

    static func relaxedRecurrenceText(
        interval: Int,
        unit: RecurrenceUnit
    ) -> String {
        let safeInterval = max(interval, 1)
        let unitName = safeInterval == 1
            ? unit.singularName
            : unit.pluralName

        return "Every \(safeInterval) \(unitName)"
    }

    static func fixedRecurrenceText(
        frequency: FixedFrequency,
        weekday: Int?,
        dayOfMonth: Int?,
        month: Int?,
        day: Int?
    ) -> String {
        fixedRecurrenceText(
            frequency: frequency,
            weekdays: weekday.map { [$0] } ?? [],
            dayOfMonth: dayOfMonth,
            month: month,
            day: day
        )
    }

    static func fixedRecurrenceText(
        frequency: FixedFrequency,
        weekdays: [Int],
        dayOfMonth: Int?,
        month: Int?,
        day: Int?
    ) -> String {
        switch frequency {
        case .weekly:
            return weeklyRecurrenceText(weekdays)

        case .monthly:
            guard let dayOfMonth else {
                return "Monthly"
            }

            return "Every \(ordinal(dayOfMonth)) of the month"

        case .yearly:
            guard let month,
                  let day else {
                return "Yearly"
            }

            return "Every \(monthName(month)) \(ordinal(day))"
        }
    }

    static func weeklyRecurrenceText(_ weekdays: [Int]) -> String {
        let normalizedWeekdays = normalizedWeekdays(weekdays)

        if normalizedWeekdays == [1, 2, 3, 4, 5, 6, 7] {
            return "Every day"
        }

        if normalizedWeekdays == [2, 3, 4, 5, 6] {
            return "Every weekday"
        }

        if normalizedWeekdays == [1, 7] {
            return "Every weekend"
        }

        let names = normalizedWeekdays.map(weekdayName)

        guard !names.isEmpty else {
            return "Weekly"
        }

        return "Every " + formattedList(names)
    }

    static func compactWeeklyRecurrenceText(_ weekdays: [Int]) -> String {
        let normalizedWeekdays = normalizedWeekdays(weekdays)

        if normalizedWeekdays == [1, 2, 3, 4, 5, 6, 7] {
            return "Daily"
        }

        if normalizedWeekdays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        }

        if normalizedWeekdays == [1, 7] {
            return "Weekends"
        }

        let names = normalizedWeekdays.map(shortWeekdayName)

        guard !names.isEmpty else {
            return "Weekly"
        }

        return formattedList(names)
    }

    static func weekdayName(_ weekday: Int) -> String {
        weekdayNames[safeIndex(for: weekday, upperBound: weekdayNames.count)]
    }

    static func shortWeekdayName(_ weekday: Int) -> String {
        shortWeekdayNames[safeIndex(for: weekday, upperBound: shortWeekdayNames.count)]
    }

    static func monthName(_ month: Int) -> String {
        monthNames[safeIndex(for: month, upperBound: monthNames.count)]
    }

    static func ordinal(_ number: Int) -> String {
        let suffix: String

        switch number % 100 {
        case 11, 12, 13:
            suffix = "th"

        default:
            switch number % 10 {
            case 1:
                suffix = "st"
            case 2:
                suffix = "nd"
            case 3:
                suffix = "rd"
            default:
                suffix = "th"
            }
        }

        return "\(number)\(suffix)"
    }

    private static func normalizedWeekdays(_ weekdays: [Int]) -> [Int] {
        Array(Set(weekdays.filter { 1...7 ~= $0 })).sorted()
    }

    private static func safeIndex(
        for oneBasedValue: Int,
        upperBound: Int
    ) -> Int {
        max(
            0,
            min(
                oneBasedValue - 1,
                upperBound - 1
            )
        )
    }

    private static func formattedList(_ values: [String]) -> String {
        switch values.count {
        case 0:
            return ""
        case 1:
            return values[0]
        case 2:
            return values.joined(separator: " and ")
        default:
            return values.dropLast().joined(separator: ", ") + ", and " + values.last!
        }
    }
}
