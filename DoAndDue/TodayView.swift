//
//  TodayView.swift
//  Do & Due
//

import SwiftUI
import SwiftData

struct TodayView: View {

    @Query(sort: \Task.dueDate)
    private var tasks: [Task]

    @State private var showingAddTask = false
    #if DEBUG
    @State private var showingPendingNotifications = false
    #endif

    private var calendar: Calendar {
        Calendar.current
    }

    private var startOfToday: Date {
        calendar.startOfDay(for: Date())
    }

    private var startOfTomorrow: Date {
        calendar.date(
            byAdding: .day,
            value: 1,
            to: startOfToday
        )!
    }

    private var activeTasks: [Task] {
        tasks.filter {
            $0.isActive
        }
    }

    private var overdueTasks: [Task] {
        activeTasks.filter { task in
            guard let dueDate = task.dueDate else {
                return false
            }

            return task.schedule != .anytime &&
                   calendar.startOfDay(for: dueDate) < startOfToday
        }
    }

    private var todayTasks: [Task] {
        activeTasks.filter { task in
            guard let dueDate = task.dueDate else {
                return false
            }

            return task.schedule != .anytime &&
                   dueDate >= startOfToday &&
                   dueDate < startOfTomorrow
        }
    }

    private var upcomingTasks: [Task] {
        activeTasks.filter { task in
            guard let dueDate = task.dueDate else {
                return false
            }

            return task.schedule != .anytime &&
                   dueDate >= startOfTomorrow
        }
    }

    private var anytimeTasks: [Task] {
        activeTasks.filter { task in
            task.schedule == .anytime
        }
    }

    private var displayedUpcomingTasks: ArraySlice<Task> {
        upcomingTasks.prefix(10)
    }

    private var shouldShowAllDone: Bool {
        overdueTasks.isEmpty && todayTasks.isEmpty && anytimeTasks.isEmpty
    }

    private var orderedTaskState: String {
        activeTasks
            .map { task in
                "\(task.id.uuidString):\(task.dueDate?.timeIntervalSinceReferenceDate ?? 0)"
            }
            .joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                screenHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if !overdueTasks.isEmpty {
                            taskSection(
                                title: "Overdue",
                                tasks: overdueTasks,
                                background: DoAndDueStyle.overdueBackground,
                                isOverdue: true
                            )
                        }

                        if shouldShowAllDone {
                            AllDoneView()
                                .padding(.top, 18)
                        }

                        if !todayTasks.isEmpty {
                            taskSection(
                                title: "Today",
                                tasks: todayTasks,
                                background: DoAndDueStyle.quietRowBackground,
                                showsScheduleText: false
                            )
                        }

                        if !anytimeTasks.isEmpty {
                            taskSection(
                                title: "Anytime",
                                tasks: anytimeTasks,
                                background: DoAndDueStyle.quietRowBackground,
                                showsScheduleText: false
                            )
                        }

                        if !upcomingTasks.isEmpty {
                            taskSection(
                                title: "Upcoming",
                                tasks: Array(displayedUpcomingTasks),
                                background: DoAndDueStyle.quietRowBackground
                            )

                            if upcomingTasks.count > 10 {
                                Text("Showing the next 10 upcoming tasks.")
                                    .font(.footnote)
                                    .foregroundStyle(DoAndDueStyle.text2)
                                    .padding(.horizontal, DoAndDueStyle.headerHorizontalPadding)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .background(DoAndDueStyle.rootScreenBackground)
            .animation(
                .spring(response: 0.42, dampingFraction: 0.82),
                value: orderedTaskState
            )
            .toolbar(.hidden, for: .navigationBar)
            .sheet(
                isPresented: $showingAddTask
            ) {
                TaskEditorView()
            }
            #if DEBUG
            .sheet(
                isPresented: $showingPendingNotifications
            ) {
                PendingNotificationsDebugView()
            }
            #endif
        }
        .tint(DoAndDueStyle.accent)
    }

    private var screenHeader: some View {
        HStack(alignment: .center) {
            Text("Today")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            #if DEBUG
            Button {
                showingPendingNotifications = true
            } label: {
                Image(systemName: "bell.badge")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DoAndDueStyle.accent)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show pending reminders")
            #endif

            HeaderAddTaskButton {
                showingAddTask = true
            }
        }
        .padding(.top, 44)
        .padding(.bottom, 18)
        .padding(.horizontal, DoAndDueStyle.headerHorizontalPadding)
        .background(DoAndDueStyle.rootScreenBackground)
    }

    private func taskRow(
        _ task: Task,
        showsDivider: Bool,
        showsScheduleText: Bool
    ) -> some View {
        VStack(spacing: 0) {
            TaskRow(
                task: task,
                showsScheduleText: showsScheduleText
            )

            if showsDivider {
                TaskRowDivider()
            }
        }
    }

    private func taskSection(
        title: String,
        tasks: [Task],
        background: Color,
        isOverdue: Bool = false,
        showsScheduleText: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TaskSectionHeader(
                title: title,
                count: tasks.count,
                isOverdue: isOverdue
            )
            .padding(.leading, DoAndDueStyle.sectionHeaderHorizontalPadding)
            .padding(.top, DoAndDueStyle.sectionHeaderTopPadding)
            .padding(.bottom, DoAndDueStyle.sectionHeaderBottomPadding)

            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    taskRow(
                        task,
                        showsDivider: index < tasks.count - 1,
                        showsScheduleText: showsScheduleText
                    )
                    .padding(.horizontal, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
            )
            .padding(.horizontal, DoAndDueStyle.cardHorizontalPadding)
        }
    }

}

#Preview {
    TodayView()
        .modelContainer(PreviewData.modelContainer())
}
