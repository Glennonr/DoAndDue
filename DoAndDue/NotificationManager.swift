//
//  NotificationManager.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let reminderHour = 9
    private let notificationIdentifierPrefix = "task-"
    private let batchIdentifierPrefix = "batch-"
    private let taskIDUserInfoKey = "doAndDueTaskID"
    private let notificationItemsUserInfoKey = "doAndDueNotificationItems"

    private init() {}

    #if DEBUG
    func debugPendingNotifications() async -> [PendingNotificationDebugSnapshot] {
        let requests = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        return requests
            .filter { isDoAndDueNotificationIdentifier($0.identifier) }
            .map(debugSnapshot)
            .sorted { lhs, rhs in
                switch (lhs.triggerDate, rhs.triggerDate) {
                case let (left?, right?):
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.identifier < rhs.identifier
                }
            }
    }
    #endif

    // MARK: - Permission

    func requestPermission(
        completion: @escaping (Bool) -> Void
    ) {
        center.requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in

            if let error {
                print(
                    "Notification permission error: \(error)"
                )
            }

            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func scheduleNotification(
        for task: Task
    ) {
        guard
            let dueDate = task.dueDate,
            task.reminder != .none
        else {
            cancelNotification(for: task)
            return
        }

        let item = ScheduledNotificationItem(
            taskID: task.id,
            title: task.title,
            body: notificationBody(reminder: task.reminder),
            notificationDate: reminderDate(
                for: dueDate,
                reminder: task.reminder
            )
        )

        center.getNotificationSettings { settings in

            switch settings.authorizationStatus {

            case .authorized, .provisional:
                DispatchQueue.main.async {
                    self.scheduleNotification(item)
                }

            case .notDetermined:
                DispatchQueue.main.async {
                    self.requestPermission { granted in
                        guard granted else {
                            return
                        }

                        self.scheduleNotification(item)
                    }
                }

            default:
                DispatchQueue.main.async {
                    self.cancelNotification(forTaskID: item.taskID)
                }
            }
        }
    }

    // MARK: - Schedule

    private func scheduleNotification(
        _ item: ScheduledNotificationItem
    ) {
        guard item.notificationDate > Date() else {
            cancelNotification(forTaskID: item.taskID)
            return
        }

        rewriteScheduledNotifications { existingItems in
            existingItems.filter { $0.taskID != item.taskID } + [item]
        }
    }

    private func rewriteScheduledNotifications(
        transform: @escaping ([ScheduledNotificationItem]) -> [ScheduledNotificationItem]
    ) {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                let currentItems = self.scheduledItems(from: requests)
                let updatedItems = transform(currentItems)
                    .filter { $0.notificationDate > Date() }

                let identifiersToRemove = requests
                    .map(\.identifier)
                    .filter { self.isDoAndDueNotificationIdentifier($0) }

                self.center.removePendingNotificationRequests(
                    withIdentifiers: identifiersToRemove
                )

                for group in Dictionary(grouping: updatedItems, by: { self.notificationKey(for: $0) }).values {
                    self.addNotification(for: group)
                }
            }
        }
    }

    private func addNotification(
        for items: [ScheduledNotificationItem]
    ) {
        guard let firstItem = items.first else {
            return
        }

        let sortedItems = items.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        let content = UNMutableNotificationContent()

        if sortedItems.count == 1 {
            content.title = firstItem.title
            content.body = firstItem.body
        } else {
            content.title = "\(sortedItems.count) tasks need attention"
            content.body = batchBody(for: sortedItems)
        }

        content.sound = .default
        content.userInfo = [
            notificationItemsUserInfoKey: sortedItems.map(\.dictionaryRepresentation)
        ]

        let components = Calendar.current.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute
            ],
            from: firstItem.notificationDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: sortedItems),
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print(
                    "Failed to schedule notification: \(error)"
                )
            }
        }
    }

    // MARK: - Cancel

    func cancelNotification(
        for task: Task
    ) {
        cancelNotification(forTaskID: task.id)
    }

    private func cancelNotification(
        forTaskID taskID: UUID
    ) {
        rewriteScheduledNotifications { existingItems in
            existingItems.filter { $0.taskID != taskID }
        }
    }

    // MARK: - Pending Items

    private func scheduledItems(
        from requests: [UNNotificationRequest]
    ) -> [ScheduledNotificationItem] {
        requests
            .filter { isDoAndDueNotificationIdentifier($0.identifier) }
            .flatMap(scheduledItems)
    }

    private func scheduledItems(
        from request: UNNotificationRequest
    ) -> [ScheduledNotificationItem] {
        if let itemDictionaries = request.content.userInfo[notificationItemsUserInfoKey] as? [[String: Any]] {
            return itemDictionaries.compactMap(ScheduledNotificationItem.init(dictionary:))
        }

        guard request.identifier.hasPrefix(notificationIdentifierPrefix),
              let taskID = UUID(uuidString: String(request.identifier.dropFirst(notificationIdentifierPrefix.count))),
              let notificationDate = triggerDate(from: request) else {
            return []
        }

        return [
            ScheduledNotificationItem(
                taskID: taskID,
                title: request.content.title,
                body: request.content.body,
                notificationDate: notificationDate
            )
        ]
    }

    private func triggerDate(
        from request: UNNotificationRequest
    ) -> Date? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }

        return Calendar.current.date(from: trigger.dateComponents)
    }

    #if DEBUG
    private func debugSnapshot(
        from request: UNNotificationRequest
    ) -> PendingNotificationDebugSnapshot {
        PendingNotificationDebugSnapshot(
            identifier: request.identifier,
            title: request.content.title,
            body: request.content.body,
            triggerDate: triggerDate(from: request),
            taskCount: scheduledItems(from: request).count
        )
    }
    #endif

    // MARK: - Helpers

    private func notificationIdentifier(
        for items: [ScheduledNotificationItem]
    ) -> String {
        guard let firstItem = items.first else {
            return batchIdentifierPrefix + UUID().uuidString
        }

        if items.count == 1 {
            return notificationIdentifierPrefix + firstItem.taskID.uuidString
        }

        return batchIdentifierPrefix + notificationKey(for: firstItem)
    }

    private func isDoAndDueNotificationIdentifier(
        _ identifier: String
    ) -> Bool {
        identifier.hasPrefix(notificationIdentifierPrefix) ||
            identifier.hasPrefix(batchIdentifierPrefix)
    }

    private func notificationKey(
        for item: ScheduledNotificationItem
    ) -> String {
        let components = Calendar.current.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute
            ],
            from: item.notificationDate
        )

        return [
            components.year,
            components.month,
            components.day,
            components.hour,
            components.minute
        ]
        .map { String($0 ?? 0) }
        .joined(separator: "-")
    }

    private func batchBody(
        for items: [ScheduledNotificationItem]
    ) -> String {
        let visibleTitles = items.prefix(2).map(\.title)
        let remainingCount = items.count - visibleTitles.count

        if remainingCount > 0 {
            return visibleTitles.joined(separator: ", ") + ", and \(remainingCount) more."
        }

        return visibleTitles.joined(separator: " and ") + "."
    }

    private func notificationBody(
        reminder: TaskReminder
    ) -> String {
        switch reminder {
        case .none, .atNineAM:
            return "Due today."

        case .oneDayBefore:
            return "Due tomorrow."

        case .oneWeekBefore:
            return "Due in one week."
        }
    }

    private func reminderDate(
        for dueDate: Date,
        reminder: TaskReminder
    ) -> Date {

        switch reminder {

        case .none:
            return dueDate

        case .atNineAM:
            return morningDate(for: dueDate)

        case .oneDayBefore:
            let reminderDay = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: dueDate
            ) ?? dueDate

            return morningDate(for: reminderDay)

        case .oneWeekBefore:
            let reminderDay = Calendar.current.date(
                byAdding: .day,
                value: -7,
                to: dueDate
            ) ?? dueDate

            return morningDate(for: reminderDay)
        }
    }

    private func morningDate(
        for date: Date
    ) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )

        components.hour = reminderHour
        components.minute = 0
        components.second = 0

        return Calendar.current.date(
            from: components
        ) ?? date
    }
}

#if DEBUG
struct PendingNotificationDebugSnapshot: Identifiable {
    let identifier: String
    let title: String
    let body: String
    let triggerDate: Date?
    let taskCount: Int

    var id: String {
        identifier
    }
}
#endif

private struct ScheduledNotificationItem {
    let taskID: UUID
    let title: String
    let body: String
    let notificationDate: Date

    var dictionaryRepresentation: [String: Any] {
        [
            "taskID": taskID.uuidString,
            "title": title,
            "body": body,
            "notificationDate": notificationDate.timeIntervalSinceReferenceDate
        ]
    }

    init(
        taskID: UUID,
        title: String,
        body: String,
        notificationDate: Date
    ) {
        self.taskID = taskID
        self.title = title
        self.body = body
        self.notificationDate = notificationDate
    }

    init?(dictionary: [String: Any]) {
        guard let taskIDString = dictionary["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString),
              let title = dictionary["title"] as? String,
              let body = dictionary["body"] as? String,
              let notificationDateInterval = dictionary["notificationDate"] as? TimeInterval else {
            return nil
        }

        self.taskID = taskID
        self.title = title
        self.body = body
        self.notificationDate = Date(timeIntervalSinceReferenceDate: notificationDateInterval)
    }
}
