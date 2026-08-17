//
//  RootView.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.scenePhase)
    private var scenePhase

    @State private var selectedTab = RootTab.today
    @State private var deepLinkedTaskID: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(RootTab.today)

            AllTasksView(deepLinkedTaskID: $deepLinkedTaskID)
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }
                .tag(RootTab.tasks)

            DoneView()
                .tabItem {
                    Label("Done", systemImage: "checkmark.circle")
                }
                .tag(RootTab.done)
        }
        .tint(DoAndDueStyle.accent)
        .onAppear {
            processWidgetCompletions()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                processWidgetCompletions()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func processWidgetCompletions() {
        WidgetCompletionCommandStore.processPendingCompletions(modelContext: modelContext)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "doanddue" else {
            return
        }

        switch url.host {
        case "today":
            selectedTab = .today

        case "tasks":
            selectedTab = .tasks

        case "done":
            selectedTab = .done

        case "task":
            deepLinkedTaskID = taskID(from: url)
            selectedTab = .tasks

        default:
            selectedTab = .today
        }
    }

    private func taskID(from url: URL) -> UUID? {
        url.pathComponents
            .dropFirst()
            .compactMap(UUID.init(uuidString:))
            .first
    }
}

private enum RootTab: Hashable {
    case today
    case tasks
    case done
}
