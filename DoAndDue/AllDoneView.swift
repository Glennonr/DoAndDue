//
//  AllDoneView.swift
//  Do & Due
//
//  Created by Richie Glennon on 8/14/26.
//

import SwiftUI

struct AllDoneView: View {

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DoAndDueStyle.accent)
                .frame(width: 62, height: 62)
                .background(
                    Circle()
                        .fill(DoAndDueStyle.accentLight)
                )

            VStack(spacing: 4) {
                Text("All done for today!")
                    .font(.headline)
                    .foregroundStyle(DoAndDueStyle.text)

                Text("Nothing else needs your attention.")
                    .font(.subheadline)
                    .foregroundStyle(DoAndDueStyle.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 24)
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

#Preview {
    AllDoneView()
}
