//
//  DotsIndicator.swift
//  NotchDrop
//
//  Created by 小孟 on 2025/8/24.
//

import SwiftUI

struct DotsIndicator: View
{
    let pageCount: Int
    @Binding var selection: Int

    private let dotSize: CGFloat = 6
    private let spacing: CGFloat = 8

    var body: some View
    {
        HStack(spacing: spacing)
        {
            ForEach(0..<pageCount, id: \.self)
            { index in
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .opacity(selection == index ? 1.0 : 0.35)
                    .scaleEffect(selection == index ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.18), value: selection)
            } // end of ForEach
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(.thinMaterial)
                .opacity(0.9)
        )
    } // end of body
} // end of struct DotsIndicator
