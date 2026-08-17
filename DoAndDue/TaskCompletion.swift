
//
//  TaskCompletion.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import Foundation
import SwiftData

@Model
final class TaskCompletion {
    var id: UUID
    var completedAt: Date

    var task: Task?

    init(
        completedAt: Date = Date(),
        task: Task? = nil
    ) {
        self.id = UUID()
        self.completedAt = completedAt
        self.task = task
    }
}
