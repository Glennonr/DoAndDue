//
//  PreviewData.swift
//  Do & Due
//

import Foundation
import SwiftData

@MainActor
enum PreviewData {

    static func modelContainer() -> ModelContainer {
        let schema = Schema([
            Task.self,
            TaskCompletion.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        sampleTasks().forEach {
            container.mainContext.insert($0)
        }

        return container
    }

    static func detailTask() -> Task {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let task = Task(
            title: "Change HVAC filter",
            notes: "Use the 16x25x1 filters stored in the utility closet.",
            taskType: .relaxedRecurring,
            dueDate: calendar.date(byAdding: .day, value: 2, to: today),
            reminder: .oneDayBefore,
            recurrenceInterval: 3,
            recurrenceUnit: .month
        )

        [
            -91,
            -184,
            -276
        ].compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }.forEach { date in
            task.completions.append(
                TaskCompletion(
                    completedAt: date,
                    task: task
                )
            )
        }

        return task
    }

    static func sampleTasks() -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            Task(
                title: "Renew vehicle registration",
                notes: "Check the glove box for the notice.",
                taskType: .oneOff,
                dueDate: calendar.date(byAdding: .day, value: -3, to: today),
                reminder: .oneDayBefore
            ),
            Task(
                title: "Water the balcony plants",
                taskType: .relaxedRecurring,
                dueDate: calendar.date(byAdding: .hour, value: 9, to: today),
                reminder: .none,
                recurrenceInterval: 3,
                recurrenceUnit: .day
            ),
            Task(
                title: "Submit weekly timesheet",
                taskType: .fixedRecurring,
                dueDate: calendar.date(byAdding: .hour, value: 16, to: today),
                reminder: .atNineAM,
                fixedFrequency: .weekly,
                fixedWeekdays: [6]
            ),
            Task(
                title: "Organize utility closet",
                taskType: .oneOff,
                schedule: .anytime,
                dueDate: nil,
                reminder: .none
            ),
            detailTask(),
            Task(
                title: "Schedule dentist cleaning",
                taskType: .relaxedRecurring,
                dueDate: calendar.date(byAdding: .weekOfYear, value: 2, to: today),
                reminder: .oneDayBefore,
                recurrenceInterval: 6,
                recurrenceUnit: .month
            ),
            Task(
                title: "Renew passport",
                taskType: .oneOff,
                dueDate: calendar.date(byAdding: .month, value: 3, to: today),
                reminder: .none
            )
        ]
    }
}
