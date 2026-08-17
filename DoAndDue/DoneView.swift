//
//  DoneView.swift
//  Do & Due
//

import SwiftUI
import SwiftData

struct DoneView: View {

    @Query(sort: \TaskCompletion.completedAt, order: .reverse)
    private var completions: [TaskCompletion]

    @State private var selectedTask: Task?

    private var visibleCompletions: [TaskCompletion] {
        completions.filter { $0.task != nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                screenHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if visibleCompletions.isEmpty {
                            EmptyTaskListView(
                                title: "Nothing completed yet",
                                message: "Completed tasks will appear here.",
                                systemImage: "checkmark.circle"
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
                            completionSection(
                                title: "Recent",
                                completions: visibleCompletions
                            )
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .background(DoAndDueStyle.rootScreenBackground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
        }
        .tint(DoAndDueStyle.accent)
    }

    private var screenHeader: some View {
        HStack(alignment: .center) {
            Text("Done")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()
        }
        .padding(.top, 44)
        .padding(.bottom, 18)
        .padding(.horizontal, DoAndDueStyle.headerHorizontalPadding)
        .background(DoAndDueStyle.rootScreenBackground)
    }

    private func completionSection(
        title: String,
        completions: [TaskCompletion]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TaskSectionHeader(
                title: title,
                count: completions.count
            )
            .padding(.leading, DoAndDueStyle.sectionHeaderHorizontalPadding)
            .padding(.top, DoAndDueStyle.sectionHeaderTopPadding)
            .padding(.bottom, DoAndDueStyle.sectionHeaderBottomPadding)

            VStack(spacing: 0) {
                ForEach(Array(completions.enumerated()), id: \.element.id) { index, completion in
                    completionRow(
                        completion,
                        showsDivider: index < completions.count - 1
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .fill(DoAndDueStyle.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
            )
            .padding(.horizontal, DoAndDueStyle.cardHorizontalPadding)
        }
    }

    private func completionRow(
        _ completion: TaskCompletion,
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                selectedTask = completion.task
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(DoAndDueStyle.accentLight)
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DoAndDueStyle.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(completion.task?.title ?? "Deleted task")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DoAndDueStyle.text)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(completionDateText(for: completion.completedAt))

                            if let task = completion.task,
                               let recurrenceText = TaskPresentation.recurrenceText(for: task) {
                                Text("·")
                                Text(recurrenceText)
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(DoAndDueStyle.text2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DoAndDueStyle.text3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(completion.task == nil)
            .accessibilityLabel("Open \(completion.task?.title ?? "completed task")")

            if showsDivider {
                TaskRowDivider()
            }
        }
    }

    private func completionDateText(
        for date: Date
    ) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Completed today"
        }

        if Calendar.current.isDateInYesterday(date) {
            return "Completed yesterday"
        }

        return "Completed " + date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}

#Preview {
    DoneView()
        .modelContainer(PreviewData.modelContainer())
}
