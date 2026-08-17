//
//  TaskDetailView.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    let task: Task

    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    private var sortedCompletions: [TaskCompletion] {
        task.completions.sorted {
            $0.completedAt > $1.completedAt
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                detailHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        detailPanel {
                            VStack(
                                alignment: .leading,
                                spacing: 10
                            ) {
                                Text(task.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(DoAndDueStyle.text)

                                if let recurrenceText = TaskPresentation.recurrenceText(for: task) {
                                    Label(recurrenceText, systemImage: "repeat")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(DoAndDueStyle.accent)
                                        .lineLimit(2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(DoAndDueStyle.accentLight)
                                        )
                                }

                                if !task.notes.isEmpty {
                                    Text(task.notes)
                                        .font(.body)
                                        .foregroundStyle(DoAndDueStyle.text2)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 11)
                        }

                        detailSection("Details") {
                            detailRow(
                                title: task.schedule == .anytime ? "Available" : "Next due",
                                value: TaskPresentation.scheduleText(for: task) ?? "None",
                                emphasized: true
                            )
                            detailDivider

                            detailRow(
                                title: "Reminder",
                                value: task.reminder.displayName
                            )
                            detailDivider

                            detailRow(
                                title: "Total completions",
                                value: "\(task.completions.count)"
                            )
                        }

                        if !sortedCompletions.isEmpty {
                            detailSection("History") {
                                ForEach(Array(sortedCompletions.enumerated()), id: \.element.id) { index, completion in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(DoAndDueStyle.accentLight)
                                                .frame(width: 28, height: 28)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(DoAndDueStyle.accent)
                                        }

                                        Text(
                                            completion.completedAt.formatted(
                                                date: .long,
                                                time: .omitted
                                            )
                                        )
                                        .font(.body)
                                        .foregroundStyle(DoAndDueStyle.text)

                                        Spacer()
                                    }
                                    .padding(.vertical, 9)

                                    if index < sortedCompletions.count - 1 {
                                        detailDivider
                                            .padding(.leading, 40)
                                    }
                                }
                            }
                        }

                        detailPanel(topSpacing: 10) {
                            Button(
                                "Delete Task",
                                role: .destructive
                            ) {
                                showingDeleteConfirmation = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .background(DoAndDueStyle.screenBackground)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(
                isPresented: $showingEditor
            ) {
                TaskEditorView(task: task)
            }
            .confirmationDialog(
                "Delete this task?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Delete",
                    role: .destructive
                ) {
                    deleteTask()
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {}
            }
        }
        .tint(DoAndDueStyle.accent)
    }

    private var detailHeader: some View {
        ZStack {
            Text("Task")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(DoAndDueStyle.text)

            HStack {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(DoAndDueStyle.accent)

                Spacer()

                Button("Edit") {
                    showingEditor = true
                }
                .foregroundStyle(DoAndDueStyle.accent)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(DoAndDueStyle.surfaceBackground)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(DoAndDueStyle.separator)
        }
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(DoAndDueStyle.text3)
                .padding(.horizontal, DoAndDueStyle.sectionHeaderHorizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 6)

            detailPanel(topSpacing: 0, content: content)
        }
    }

    private func detailPanel<Content: View>(
        topSpacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                .fill(DoAndDueStyle.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
        )
        .padding(.horizontal, DoAndDueStyle.cardHorizontalPadding)
        .padding(.top, topSpacing)
    }

    private var detailDivider: some View {
        Divider()
            .overlay(DoAndDueStyle.separator)
    }

    private func deleteTask() {
        let store = TaskStore(modelContext: modelContext)
        store.delete(task)
        dismiss()
    }

    private func detailRow(
        title: String,
        value: String,
        emphasized: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            Text(value)
                .fontWeight(emphasized ? .semibold : .regular)
                .foregroundStyle(emphasized ? DoAndDueStyle.accent : DoAndDueStyle.text2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

}

#Preview {
    let task = PreviewData.detailTask()

    TaskDetailView(task: task)
        .modelContainer(PreviewData.modelContainer())
}
