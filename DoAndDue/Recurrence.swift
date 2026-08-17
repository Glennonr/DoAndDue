//
//  Recurrence.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import Foundation

enum TaskType: String, CaseIterable, Identifiable, Sendable {
    case oneOff
    case relaxedRecurring
    case fixedRecurring

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneOff:
            return "One Time"
        case .relaxedRecurring:
            return "After Completion"
        case .fixedRecurring:
            return "Fixed Schedule"
        }
    }
}

enum TaskSchedule: String, CaseIterable, Identifiable, Sendable {
    case dueDate
    case anytime

    var id: String { rawValue }
}

enum RecurrenceUnit: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var singularName: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }

    var pluralName: String {
        switch self {
        case .day:
            return "days"
        case .week:
            return "weeks"
        case .month:
            return "months"
        case .year:
            return "years"
        }
    }
}

enum FixedFrequency: String, CaseIterable, Identifiable, Sendable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
}

enum RecurrenceEngine {

    static let calendar = Calendar.current

    // MARK: - Relaxed Recurrence

    static func nextRelaxedDate(
        after completionDate: Date,
        interval: Int,
        unit: RecurrenceUnit
    ) -> Date {
        let safeInterval = max(interval, 1)

        switch unit {
        case .day:
            return calendar.date(
                byAdding: .day,
                value: safeInterval,
                to: completionDate
            ) ?? completionDate

        case .week:
            return calendar.date(
                byAdding: .weekOfYear,
                value: safeInterval,
                to: completionDate
            ) ?? completionDate

        case .month:
            return calendar.date(
                byAdding: .month,
                value: safeInterval,
                to: completionDate
            ) ?? completionDate

        case .year:
            return calendar.date(
                byAdding: .year,
                value: safeInterval,
                to: completionDate
            ) ?? completionDate
        }
    }

    // MARK: - Fixed Recurrence

    static func nextFixedDate(
        after date: Date,
        frequency: FixedFrequency,
        weekday: Int?,
        dayOfMonth: Int?,
        month: Int?,
        day: Int?
    ) -> Date {
        nextFixedDate(
            after: date,
            frequency: frequency,
            weekdays: weekday.map { [$0] } ?? [],
            dayOfMonth: dayOfMonth,
            month: month,
            day: day
        )
    }

    static func nextFixedDate(
        after date: Date,
        frequency: FixedFrequency,
        weekdays: [Int],
        dayOfMonth: Int?,
        month: Int?,
        day: Int?
    ) -> Date {

        switch frequency {

        case .weekly:
            let selectedWeekdays = weekdays.isEmpty
                ? [calendar.component(.weekday, from: date)]
                : weekdays

            return nextWeeklyDate(
                after: date,
                weekdays: selectedWeekdays
            )

        case .monthly:
            return nextMonthlyDate(
                after: date,
                dayOfMonth: dayOfMonth ?? 1
            )

        case .yearly:
            return nextYearlyDate(
                after: date,
                month: month ?? calendar.component(.month, from: date),
                day: day ?? calendar.component(.day, from: date)
            )
        }
    }

    private static func nextWeeklyDate(
        after date: Date,
        weekdays: [Int]
    ) -> Date {
        let safeWeekdays = Array(
            Set(weekdays.filter { 1...7 ~= $0 })
        )

        let selectedWeekdays = safeWeekdays.isEmpty
            ? [calendar.component(.weekday, from: date)]
            : safeWeekdays

        let candidates = selectedWeekdays.compactMap { weekday in
            nextWeeklyDate(
                after: date,
                weekday: weekday
            )
        }

        return candidates.min() ?? date
    }

    private static func nextWeeklyDate(
        after date: Date,
        weekday: Int
    ) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)

        var components = DateComponents()
        components.weekday = weekday

        guard let next = calendar.nextDate(
            after: startOfDay,
            matching: components,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        if calendar.isDate(next, inSameDayAs: date) {
            return calendar.date(
                byAdding: .day,
                value: 7,
                to: next
            ) ?? next
        }

        return next
    }

    private static func nextMonthlyDate(
        after date: Date,
        dayOfMonth: Int
    ) -> Date {
        let safeDay = max(1, min(dayOfMonth, 31))
        let startOfCurrentMonth = calendar.dateInterval(
            of: .month,
            for: date
        )?.start ?? date

        for monthOffset in 0..<120 {
            guard
                let monthDate = calendar.date(
                    byAdding: .month,
                    value: monthOffset,
                    to: startOfCurrentMonth
                )
            else {
                continue
            }

            let components = calendar.dateComponents(
                [.year, .month],
                from: monthDate
            )

            guard
                let year = components.year,
                let month = components.month,
                let candidate = validDate(
                    year: year,
                    month: month,
                    day: safeDay
                ),
                candidate > date
            else {
                continue
            }

            return candidate
        }

        return date
    }

    private static func nextYearlyDate(
        after date: Date,
        month: Int,
        day: Int
    ) -> Date {
        let safeMonth = max(1, min(month, 12))
        let safeDay = max(1, min(day, 31))
        let currentYear = calendar.component(.year, from: date)

        for yearOffset in 0..<400 {
            let year = currentYear + yearOffset

            guard
                let candidate = validDate(
                    year: year,
                    month: safeMonth,
                    day: safeDay
                ),
                candidate > date
            else {
                continue
            }

            return candidate
        }

        return date
    }

    private static func validDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard let date = calendar.date(from: components) else {
            return nil
        }

        let resolvedComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard resolvedComponents.year == year,
              resolvedComponents.month == month,
              resolvedComponents.day == day else {
            return nil
        }

        return date
    }
}

enum TaskReminder: String, CaseIterable, Identifiable, Codable, Sendable {
    case none
    case atNineAM
    case oneDayBefore
    case oneWeekBefore

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .atNineAM:
            return "At 9:00 AM"
        case .oneDayBefore:
            return "1 day before"
        case .oneWeekBefore:
            return "1 week before"
        }
    }
}
