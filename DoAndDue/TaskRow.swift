//
//  TaskRow.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI
import SwiftData

struct TaskRow: View {

    @Environment(\.modelContext)
    private var modelContext

    let task: Task
    var showsScheduleText = true

    @State private var showingDetail = false
    @State private var isCompleting = false
    @State private var completionFeedbackTrigger = false

    private var isOverdue: Bool {
        guard task.schedule != .anytime,
              let dueDate = task.dueDate else {
            return false
        }

        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(
            for: Date()
        )
    }

    private var statusColor: Color {
        if isCompleting {
            return DoAndDueStyle.accent
        }

        return isOverdue ? DoAndDueStyle.overdue : DoAndDueStyle.text2
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                completeTask()
            } label: {
                completionCircle
            }
            .buttonStyle(.plain)
            .disabled(isCompleting)
            .accessibilityLabel(
                "Complete \(task.title)"
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(isCompleting ? DoAndDueStyle.text2 : DoAndDueStyle.text)
                    .strikethrough(isCompleting, color: DoAndDueStyle.text2)
                    .lineLimit(2)

                if isCompleting {
                    Text(completionMessage)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                        .lineLimit(2)
                } else {
                    metadataRow
                }
            }

            Spacer(minLength: 12)

            if task.reminder != .none && !isCompleting {
                Image(systemName: "bell")
                    .font(.caption)
                    .foregroundStyle(DoAndDueStyle.text2)
                    .accessibilityLabel("Reminder set")
            }
        }
        .padding(.vertical, 8)
        .opacity(isCompleting ? 0.72 : 1)
        .scaleEffect(isCompleting ? 0.985 : 1)
        .animation(.easeInOut(duration: 0.22), value: isCompleting)
        .sensoryFeedback(
            .impact(weight: .light, intensity: 0.75),
            trigger: completionFeedbackTrigger
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isCompleting else {
                return
            }

            showingDetail = true
        }
        .sheet(
            isPresented: $showingDetail
        ) {
            TaskDetailView(task: task)
                .tint(DoAndDueStyle.accent)
        }
    }

    private var completionMessage: String {
        task.taskType == .oneOff
            ? "Completed"
            : "Completed · Next date scheduled"
    }

    private var completionCircle: some View {
        ZStack {
            Circle()
                .fill(isCompleting ? DoAndDueStyle.accent : Color.clear)
                .overlay(
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                )

            if isCompleting {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .frame(width: 26, height: 26)
        .animation(.easeInOut(duration: 0.2), value: isCompleting)
    }

    private var metadataRow: some View {
        HStack(spacing: 5) {
            if let recurrenceText = TaskPresentation.recurrenceText(for: task) {
                Text(recurrenceText)
                    .font(.caption)
                    .foregroundStyle(DoAndDueStyle.text3)
                    .lineLimit(1)
            }

            if showsScheduleText,
               let scheduleText = TaskPresentation.scheduleText(for: task) {
                Text("·")
                    .font(.caption)
                    .foregroundStyle(DoAndDueStyle.text3)

                Text(scheduleText)
                    .font(.caption)
                    .fontWeight(isOverdue ? .semibold : .regular)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func completeTask() {
        guard !isCompleting else {
            return
        }

        completionFeedbackTrigger.toggle()

        withAnimation(.easeInOut(duration: 0.22)) {
            isCompleting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let store = TaskStore(
                modelContext: modelContext
            )

            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                store.complete(task)
                isCompleting = false
            }
        }
    }
}
