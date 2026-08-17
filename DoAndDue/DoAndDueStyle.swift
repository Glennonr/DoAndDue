//
//  DoAndDueStyle.swift
//  Do & Due
//

import SwiftUI
import UIKit

enum DoAndDueStyle {
    static let accent = adaptive(
        light: RGB(79, 123, 110),
        dark: RGB(122, 194, 176)
    )
    static let accentLight = adaptive(
        light: RGB(234, 242, 240),
        dark: RGB(50, 68, 66)
    )
    static let overdue = adaptive(
        light: RGB(184, 84, 80),
        dark: RGB(255, 118, 121)
    )
    static let overdueLight = adaptive(
        light: RGB(253, 243, 242),
        dark: RGB(70, 49, 52)
    )
    static let text = adaptive(
        light: RGB(28, 28, 30),
        dark: RGB(244, 244, 246)
    )
    static let text2 = adaptive(
        light: RGB(108, 108, 112),
        dark: RGB(184, 184, 188)
    )
    static let text3 = adaptive(
        light: RGB(174, 174, 178),
        dark: RGB(128, 128, 134)
    )
    static let surface = adaptive(
        light: RGB(255, 255, 255),
        dark: RGB(43, 43, 45)
    )
    static let surface2 = adaptive(
        light: RGB(242, 242, 247),
        dark: RGB(28, 28, 30)
    )
    static let border = adaptive(
        light: RGB(209, 209, 214),
        dark: RGB(70, 70, 74)
    )
    static let separator = adaptive(
        light: RGB(60, 60, 67, alpha: 0.12),
        dark: RGB(75, 75, 79, alpha: 0.72)
    )

    static let headerHorizontalPadding: CGFloat = 24
    static let cardHorizontalPadding: CGFloat = 16
    static let sectionHeaderHorizontalPadding: CGFloat = cardHorizontalPadding
    static let cardCornerRadius: CGFloat = 10
    static let listRowHorizontalPadding: CGFloat = 16
    static let listRowVerticalPadding: CGFloat = 3
    static let sectionHeaderTopPadding: CGFloat = 14
    static let sectionHeaderBottomPadding: CGFloat = 6

    static let screenBackground = surface2
    static let rootScreenBackground = screenBackground
    static let surfaceBackground = surface
    static let controlBackground = surface2
    static let quietRowBackground = surface
    static let overdueBackground = overdueLight

    private struct RGB {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        init(
            _ red: CGFloat,
            _ green: CGFloat,
            _ blue: CGFloat,
            alpha: CGFloat = 1
        ) {
            self.red = red / 255
            self.green = green / 255
            self.blue = blue / 255
            self.alpha = alpha
        }
    }

    private static func adaptive(
        light: RGB,
        dark: RGB
    ) -> Color {
        Color(
            UIColor { traits in
                let color = traits.userInterfaceStyle == .dark ? dark : light

                return UIColor(
                    red: color.red,
                    green: color.green,
                    blue: color.blue,
                    alpha: color.alpha
                )
            }
        )
    }
}

struct AddTaskButton: View {
    let action: () -> Void

    var body: some View {
        Button("Add Task", systemImage: "plus", action: action)
        .labelStyle(.iconOnly)
        .tint(DoAndDueStyle.accent)
    }
}

struct HeaderAddTaskButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(DoAndDueStyle.accent)
                .frame(width: 38, height: 38)
                .background {
                    Circle()
                        .fill(DoAndDueStyle.accentLight)
                }
                .overlay {
                    Circle()
                        .stroke(DoAndDueStyle.accent.opacity(0.28), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Task")
    }
}

struct TaskListRowStyle: ViewModifier {
    let background: Color
    let insets: EdgeInsets

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DoAndDueStyle.cardCornerRadius)
                    .stroke(DoAndDueStyle.separator, lineWidth: 0.5)
            )
            .listRowBackground(Color.clear)
            .listRowInsets(insets)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func taskListRow(
        background: Color,
        insets: EdgeInsets
    ) -> some View {
        modifier(
            TaskListRowStyle(
                background: background,
                insets: insets
            )
        )
    }
}

struct TaskRowDivider: View {
    var body: some View {
        Divider()
            .overlay(DoAndDueStyle.separator)
            .padding(.leading, 54)
    }
}

struct TaskSectionHeader: View {
    let title: String
    let count: Int
    var isOverdue = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(isOverdue ? DoAndDueStyle.overdue : DoAndDueStyle.text3)

            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isOverdue ? DoAndDueStyle.overdue : DoAndDueStyle.text3)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isOverdue ? DoAndDueStyle.overdueLight : DoAndDueStyle.accentLight)
                    )
            }
        }
    }
}

struct EmptyTaskListView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(DoAndDueStyle.accent)
                .frame(width: 62, height: 62)
                .background(
                    Circle()
                        .fill(DoAndDueStyle.accentLight)
                )

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DoAndDueStyle.text)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DoAndDueStyle.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 24)
    }
}
