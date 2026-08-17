//
//  AllTasksView.swift
//  Do & Due
//

import SwiftUI
import SwiftData

struct AllTasksView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Binding private var deepLinkedTaskID: UUID?

    @Query(sort: \Task.dueDate)
    private var tasks: [Task]

    @State private var showingAddTask = false
    @State private var isEditing = false
    @State private var deepLinkedTask: Task?

    init(deepLinkedTaskID: Binding<UUID?> = .constant(nil)) {
        _deepLinkedTaskID = deepLinkedTaskID
    }

    private var activeTasks: [Task] {
        tasks.filter {
            $0.isActive
        }
    }

    private var calendar: Calendar {
        Calendar.current
    }

    private var startOfToday: Date {
        calendar.startOfDay(for: Date())
    }

    private var overdueTasks: [Task] {
        activeTasks.filter { task in
            guard task.schedule != .anytime,
                  let dueDate = task.dueDate else {
                return false
            }

            return calendar.startOfDay(for: dueDate) < startOfToday
        }
    }

    private var remainingTasks: [Task] {
        activeTasks
            .filter { task in
                !overdueTasks.contains { $0.id == task.id }
            }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (left?, right?):
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.createdAt < rhs.createdAt
                }
            }
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
                        if activeTasks.isEmpty {
                            EmptyTaskListView(
                                title: "No tasks yet",
                                message: "Add something you want Do & Due to remember.",
                                systemImage: "checklist"
                            )
                            .background(
                                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                                    .fill(DoAndDueStyle.surfaceBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                                    .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
                            )
                            .padding(.horizontal, DoAndDueStyle.cardHorizontalPadding)
                            .padding(.top, 18)
                        } else {
                            if !overdueTasks.isEmpty {
                                taskSection(
                                    title: "Overdue",
                                    tasks: overdueTasks,
                                    background: DoAndDueStyle.overdueBackground,
                                    isOverdue: true
                                )
                            }

                            if !remainingTasks.isEmpty {
                                taskSection(
                                    title: "All Tasks",
                                    tasks: remainingTasks,
                                    background: DoAndDueStyle.quietRowBackground
                                )
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
            .sheet(item: $deepLinkedTask) { task in
                TaskDetailView(task: task)
            }
            .onAppear {
                presentDeepLinkedTaskIfPossible()
            }
            .onChange(of: deepLinkedTaskID) {
                presentDeepLinkedTaskIfPossible()
            }
            .onChange(of: orderedTaskState) {
                presentDeepLinkedTaskIfPossible()
            }
        }
        .tint(DoAndDueStyle.accent)
    }

    private var screenHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Tasks")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            if !activeTasks.isEmpty {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                }
                    .font(.body.weight(.medium))
                    .foregroundStyle(DoAndDueStyle.accent)
            }

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
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TaskRow(task: task)

                if isEditing {
                    Button(role: .destructive) {
                        deleteTask(task)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete \(task.title)")
                    .transition(
                        .move(edge: .trailing)
                            .combined(with: .opacity)
                    )
                }
            }

            if showsDivider {
                TaskRowDivider()
            }
        }
    }

    private func taskSection(
        title: String,
        tasks: [Task],
        background: Color,
        isOverdue: Bool = false
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
                        showsDivider: index < tasks.count - 1
                    )
                    .padding(.horizontal, 14)
                    .background(background)
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
            )
            .padding(.horizontal, DoAndDueStyle.cardHorizontalPadding)
        }
    }

    private func deleteTask(_ task: Task) {
        let wasLastActiveTask = activeTasks.count <= 1

        NotificationManager.shared
            .cancelNotification(
                for: task
            )

        modelContext.delete(task)

        do {
            try modelContext.save()

            if wasLastActiveTask {
                isEditing = false
            }
        } catch {
            print(
                "Failed to delete task: \(error)"
            )
        }
    }

    private func presentDeepLinkedTaskIfPossible() {
        guard let deepLinkedTaskID,
              deepLinkedTask?.id != deepLinkedTaskID,
              let task = activeTasks.first(where: { $0.id == deepLinkedTaskID }) else {
            return
        }

        isEditing = false
        showingAddTask = false
        deepLinkedTask = task
        self.deepLinkedTaskID = nil
    }
}

#Preview {
    AllTasksView()
        .modelContainer(PreviewData.modelContainer())
}
