//
//  PendingNotificationsDebugView.swift
//  Do & Due
//

#if DEBUG
import SwiftUI

struct PendingNotificationsDebugView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var snapshots: [PendingNotificationDebugSnapshot] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if snapshots.isEmpty {
                    EmptyTaskListView(
                        title: "No pending reminders",
                        message: "You have no scheduled notifications right now.",
                        systemImage: "bell.slash"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DoAndDueStyle.rootScreenBackground)
                } else {
                    List {
                        ForEach(snapshots) { snapshot in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(snapshot.title)
                                        .font(.headline)
                                        .foregroundStyle(DoAndDueStyle.text)

                                    Spacer()

                                    if snapshot.taskCount > 1 {
                                        Text("\(snapshot.taskCount) tasks")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DoAndDueStyle.accent)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(DoAndDueStyle.accentLight)
                                            )
                                    }
                                }

                                Text(snapshot.body)
                                    .font(.subheadline)
                                    .foregroundStyle(DoAndDueStyle.text2)

                                Text(triggerText(for: snapshot))
                                    .font(.caption)
                                    .foregroundStyle(DoAndDueStyle.text3)

                                Text(snapshot.identifier)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(DoAndDueStyle.text3)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(DoAndDueStyle.surfaceBackground)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(DoAndDueStyle.rootScreenBackground)
                }
            }
        }
        .background(DoAndDueStyle.rootScreenBackground)
        .tint(DoAndDueStyle.accent)
        .task {
            await loadSnapshots()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button("Done") {
                dismiss()
            }
            .font(.body.weight(.medium))

            Spacer()

            Text("Pending Reminders")
                .font(.headline)
                .foregroundStyle(DoAndDueStyle.text)

            Spacer()

            Button {
                Swift.Task {
                    await loadSnapshots()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("Refresh pending reminders")
        }
        .padding(.horizontal, DoAndDueStyle.headerHorizontalPadding)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(DoAndDueStyle.rootScreenBackground)
    }

    private func loadSnapshots() async {
        isLoading = true
        snapshots = await NotificationManager.shared.debugPendingNotifications()
        isLoading = false
    }

    private func triggerText(
        for snapshot: PendingNotificationDebugSnapshot
    ) -> String {
        guard let triggerDate = snapshot.triggerDate else {
            return "No trigger date"
        }

        return triggerDate.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }
}
#endif
