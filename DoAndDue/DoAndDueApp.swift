//
//  DoAndDueApp.swift
//  Do & Due
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI
import SwiftData

@main
struct DoAndDueApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Task.self,
            TaskCompletion.self
        ])
    }
}
