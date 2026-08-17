//
//  TaskEditorView.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI
import SwiftData

struct TaskEditorView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    let task: Task?

    @State private var title: String
    @State private var notes: String

    @State private var taskType: TaskType
    @State private var schedule: TaskSchedule
    @State private var dueDate: Date
    @State private var reminder: TaskReminder

    @State private var recurrenceInterval: Int
    @State private var recurrenceUnit: RecurrenceUnit

    @State private var fixedFrequency: FixedFrequency
    @State private var fixedWeekdays: Set<Int>
    @State private var fixedDayOfMonth: Int
    @State private var fixedMonth: Int
    @State private var fixedDay: Int

    @FocusState private var focusedField: Field?
    @State private var showingDeleteConfirmation = false

    private enum Field {
        case title
    }

    init(task: Task? = nil) {
        self.task = task

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _taskType = State(initialValue: task?.taskType ?? .oneOff)
        _schedule = State(initialValue: task?.schedule ?? .dueDate)
        _dueDate = State(initialValue: task?.dueDate ?? Date())
        _reminder = State(initialValue: task?.reminder ?? .none)
        _recurrenceInterval = State(initialValue: task?.recurrenceInterval ?? 1)
        _recurrenceUnit = State(initialValue: task?.recurrenceUnit ?? .month)
        _fixedFrequency = State(initialValue: task?.fixedFrequency ?? .monthly)

        let currentWeekday = Calendar.current.component(
            .weekday,
            from: Date()
        )
        let taskWeekdays = task?.fixedWeekdays ?? []
        _fixedWeekdays = State(
            initialValue: Set(
                taskWeekdays.isEmpty
                    ? [currentWeekday]
                    : taskWeekdays
            )
        )

        _fixedDayOfMonth = State(
            initialValue: task?.fixedDayOfMonth
                ?? Calendar.current.component(.day, from: Date())
        )
        _fixedMonth = State(
            initialValue: task?.fixedMonth
                ?? Calendar.current.component(.month, from: Date())
        )
        _fixedDay = State(
            initialValue: task?.fixedDay
                ?? Calendar.current.component(.day, from: Date())
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        editorPanel {
                            TextField(
                                "Task name",
                                text: $title
                            )
                            .focused($focusedField, equals: .title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .foregroundStyle(DoAndDueStyle.text)
                            .padding(.vertical, 10)

                            editorDivider

                            TextField(
                                "Notes (optional)",
                                text: $notes,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .foregroundStyle(DoAndDueStyle.text)
                            .padding(.vertical, 10)
                        }

                        editorSection("Repeat") {
                            repeatOptionRow(
                                type: .oneOff,
                                title: "No repeat",
                                subtitle: "Complete it once, then it leaves your active list"
                            )
                            .padding(.vertical, 10)

                            editorDivider
                                .padding(.leading, 48)

                            repeatOptionRow(
                                type: .relaxedRecurring,
                                title: "After I complete it",
                                subtitle: "Next due date is based on when you finish"
                            )
                            .padding(.vertical, 10)

                            editorDivider
                                .padding(.leading, 48)

                            repeatOptionRow(
                                type: .fixedRecurring,
                                title: "On a schedule",
                                subtitle: "Uses the calendar even if you finish late"
                            )
                            .padding(.vertical, 10)

                            if taskType != .oneOff {
                                editorDivider
                                    .padding(.leading, 48)

                                recurrenceControls
                                    .padding(.vertical, 10)
                            }
                        }

                        editorSection("Due") {
                            dueDateOptionRow
                                .padding(.vertical, 10)

                            editorDivider
                                .padding(.leading, 48)

                            anytimeOptionRow
                                .padding(.vertical, 10)

                            if schedule == .dueDate {
                                editorDivider
                                    .padding(.leading, 48)

                                firstDueRow
                            }
                        }

                        editorSection("Reminder") {
                            reminderRow
                        }

                        if task != nil {
                            editorPanel(topSpacing: 20) {
                                Button(
                                    "Delete Task",
                                    role: .destructive
                                ) {
                                    showingDeleteConfirmation = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .background(DoAndDueStyle.screenBackground)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                focusTitleFieldIfNeeded()
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

    private var editorHeader: some View {
        ZStack {
            Text(task == nil ? "New Task" : "Edit Task")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(DoAndDueStyle.text)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(DoAndDueStyle.accent)

                Spacer()

                Button("Save") {
                    save()
                }
                .fontWeight(.semibold)
                .foregroundStyle(trimmedTitle.isEmpty ? DoAndDueStyle.text3 : DoAndDueStyle.accent)
                .disabled(trimmedTitle.isEmpty)
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

    private func editorSection<Content: View>(
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

            editorPanel(topSpacing: 0, content: content)
        }
    }

    private func editorPanel<Content: View>(
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

    private var editorDivider: some View {
        Divider()
            .overlay(DoAndDueStyle.separator)
    }

    private var dueDateOptionRow: some View {
        scheduleOptionRow(
            schedule: .dueDate,
            title: "On a date",
            subtitle: "Shows up based on its due date"
        )
    }

    private var anytimeOptionRow: some View {
        scheduleOptionRow(
            schedule: .anytime,
            title: "Anytime",
            subtitle: "Stays available without becoming overdue"
        )
    }

    private func scheduleOptionRow(
        schedule option: TaskSchedule,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            schedule = option
        } label: {
            HStack(spacing: 14) {
                Image(systemName: schedule == option ? "circle.inset.filled" : "circle")
                    .font(.title3)
                    .foregroundStyle(schedule == option ? DoAndDueStyle.accent : DoAndDueStyle.text3)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(DoAndDueStyle.text)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DoAndDueStyle.text2)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var firstDueRow: some View {
        HStack {
            Text("First due")
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            DatePicker(
                "First due",
                selection: $dueDate,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(DoAndDueStyle.accent)
            .colorMultiply(DoAndDueStyle.accent)
            .accessibilityHint("Double tap to choose a due date")
        }
        .padding(.vertical, 10)
    }

    private var reminderRow: some View {
        HStack {
            Text("Reminder")
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            Picker(
                "Reminder",
                selection: $reminder
            ) {
                ForEach(TaskReminder.allCases) { reminder in
                    Text(reminder.displayName)
                        .tag(reminder)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .padding(.vertical, 12)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func focusTitleFieldIfNeeded() {
        guard task == nil else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            focusedField = .title
        }
    }

    @ViewBuilder
    private var recurrenceControls: some View {
        if taskType == .relaxedRecurring {
            relaxedRecurrenceControls
        }

        if taskType == .fixedRecurring {
            Picker(
                "Frequency",
                selection: $fixedFrequency
            ) {
                ForEach(FixedFrequency.allCases) { frequency in
                    Text(frequency.displayName)
                        .tag(frequency)
                }
            }

            switch fixedFrequency {
            case .weekly:
                weeklyScheduleControls

            case .monthly:
                Stepper(
                    value: $fixedDayOfMonth,
                    in: 1...31
                ) {
                    HStack {
                        Text("Day of month")

                        Spacer()

                        Text(TaskPresentation.ordinal(fixedDayOfMonth))
                            .foregroundStyle(.secondary)
                    }
                }

            case .yearly:
                Picker(
                    "Month",
                    selection: $fixedMonth
                ) {
                    ForEach(1...12, id: \.self) { month in
                        Text(TaskPresentation.monthName(month))
                            .tag(month)
                    }
                }

                Stepper(
                    value: $fixedDay,
                    in: 1...31
                ) {
                    HStack {
                        Text("Day")

                        Spacer()

                        Text(TaskPresentation.ordinal(fixedDay))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        if let recurrencePreview {
            schedulePreviewRow(recurrencePreview)
        }
    }

    private func schedulePreviewRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline)
                .foregroundStyle(DoAndDueStyle.accent)
                .frame(width: 20)

            Text(text)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(DoAndDueStyle.accent)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DoAndDueStyle.accentLight)
        )
        .listRowInsets(
            EdgeInsets(
                top: 8,
                leading: 16,
                bottom: 8,
                trailing: 16
            )
        )
    }

    private var relaxedRecurrenceControls: some View {
        HStack(spacing: 12) {
            Text("Every")
                .foregroundStyle(DoAndDueStyle.text2)

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                intervalButton(
                    systemImage: "minus",
                    accessibilityLabel: "Decrease interval"
                ) {
                    recurrenceInterval = max(1, recurrenceInterval - 1)
                }
                .disabled(recurrenceInterval <= 1)

                Text("\(recurrenceInterval)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DoAndDueStyle.text)
                    .frame(width: 42, height: 34)
                    .contentTransition(.numericText())

                intervalButton(
                    systemImage: "plus",
                    accessibilityLabel: "Increase interval"
                ) {
                    recurrenceInterval = min(99, recurrenceInterval + 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DoAndDueStyle.controlBackground)
            )

            Picker(
                "Unit",
                selection: $recurrenceUnit
            ) {
                ForEach(RecurrenceUnit.allCases) { unit in
                    Text(unit.pluralName.capitalized)
                        .tag(unit)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(minWidth: 104, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private func intervalButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DoAndDueStyle.accent)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var weeklyScheduleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days")
                .font(.subheadline)
                .foregroundStyle(DoAndDueStyle.text2)

            HStack(spacing: 7) {
                weekdayPresetButton(
                    title: "Every day",
                    weekdays: [1, 2, 3, 4, 5, 6, 7]
                )

                weekdayPresetButton(
                    title: "Weekdays",
                    weekdays: [2, 3, 4, 5, 6]
                )

                weekdayPresetButton(
                    title: "Weekends",
                    weekdays: [1, 7]
                )
            }

            HStack(spacing: 7) {
                ForEach(1...7, id: \.self) { weekday in
                    weekdayButton(weekday)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func repeatOptionRow(
        type: TaskType,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            taskType = type
        } label: {
            HStack(spacing: 14) {
                Image(systemName: taskType == type ? "circle.inset.filled" : "circle")
                    .font(.title3)
                    .foregroundStyle(taskType == type ? DoAndDueStyle.accent : DoAndDueStyle.text3)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(DoAndDueStyle.text)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DoAndDueStyle.text2)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func weekdayPresetButton(
        title: String,
        weekdays: [Int]
    ) -> some View {
        let weekdaySet = Set(weekdays)
        let isSelected = fixedWeekdays == weekdaySet

        return Button {
            fixedWeekdays = weekdaySet
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : DoAndDueStyle.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? DoAndDueStyle.accent : DoAndDueStyle.accentLight)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func weekdayButton(_ weekday: Int) -> some View {
        let isSelected = fixedWeekdays.contains(weekday)

        return Button {
            toggleWeekday(weekday)
        } label: {
            Text(TaskPresentation.shortWeekdayName(weekday).prefix(1))
                .font(.caption)
                .fontWeight(.semibold)
                .frame(
                    width: 33,
                    height: 33
                )
                .foregroundStyle(isSelected ? .white : DoAndDueStyle.text)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? DoAndDueStyle.accent : DoAndDueStyle.surface2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? DoAndDueStyle.accent : DoAndDueStyle.border,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TaskPresentation.weekdayName(weekday))
    }

    private func toggleWeekday(_ weekday: Int) {
        if fixedWeekdays.contains(weekday) {
            guard fixedWeekdays.count > 1 else {
                return
            }

            fixedWeekdays.remove(weekday)
        } else {
            fixedWeekdays.insert(weekday)
        }
    }

    private var recurrencePreview: String? {
        TaskPresentation.editorPreview(
            taskType: taskType,
            dueDate: dueDate,
            recurrenceInterval: recurrenceInterval,
            recurrenceUnit: recurrenceUnit,
            fixedFrequency: fixedFrequency,
            fixedWeekdays: selectedFixedWeekdays,
            fixedDayOfMonth: fixedDayOfMonth,
            fixedMonth: fixedMonth,
            fixedDay: fixedDay
        )
    }

    private var selectedFixedWeekdays: [Int] {
        Array(fixedWeekdays).sorted()
    }

    private func save() {
        if let task {
            task.title = trimmedTitle
            task.notes = notes
            task.taskType = taskType
            task.schedule = schedule
            task.dueDate = schedule == .anytime ? nil : dueDate
            task.reminder = reminder
            task.recurrenceInterval = recurrenceInterval
            task.recurrenceUnit = recurrenceUnit
            task.fixedFrequency = fixedFrequency
            task.fixedWeekdays = taskType == .fixedRecurring && fixedFrequency == .weekly
                ? selectedFixedWeekdays
                : []
            task.fixedDayOfMonth = taskType == .fixedRecurring && fixedFrequency == .monthly
                ? fixedDayOfMonth
                : nil
            task.fixedMonth = taskType == .fixedRecurring && fixedFrequency == .yearly
                ? fixedMonth
                : nil
            task.fixedDay = taskType == .fixedRecurring && fixedFrequency == .yearly
                ? fixedDay
                : nil
            task.updatedAt = Date()

            do {
                try modelContext.save()

                let store = TaskStore(modelContext: modelContext)
                store.updateNotification(for: task)

                dismiss()
            } catch {
                print("Failed to save task: \(error)")
            }
        } else {
            let store = TaskStore(modelContext: modelContext)

            store.createTask(
                title: trimmedTitle,
                notes: notes,
                taskType: taskType,
                schedule: schedule,
                dueDate: schedule == .anytime ? nil : dueDate,
                reminder: reminder,
                recurrenceInterval: recurrenceInterval,
                recurrenceUnit: recurrenceUnit,
                fixedFrequency: fixedFrequency,
                fixedWeekday: taskType == .fixedRecurring && fixedFrequency == .weekly
                    ? selectedFixedWeekdays.first
                    : nil,
                fixedWeekdays: taskType == .fixedRecurring && fixedFrequency == .weekly
                    ? selectedFixedWeekdays
                    : [],
                fixedDayOfMonth: taskType == .fixedRecurring && fixedFrequency == .monthly
                    ? fixedDayOfMonth
                    : nil,
                fixedMonth: taskType == .fixedRecurring && fixedFrequency == .yearly
                    ? fixedMonth
                    : nil,
                fixedDay: taskType == .fixedRecurring && fixedFrequency == .yearly
                    ? fixedDay
                    : nil
            )

            dismiss()
        }
    }

    private func deleteTask() {
        guard let task else {
            return
        }

        let store = TaskStore(modelContext: modelContext)
        store.delete(task)

        dismiss()
    }
}

#Preview("New Task") {
    TaskEditorView()
        .modelContainer(PreviewData.modelContainer())
}

#Preview("Edit Recurring Task") {
    TaskEditorView(task: PreviewData.detailTask())
        .modelContainer(PreviewData.modelContainer())
}
