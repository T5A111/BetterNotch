//
//  NotchContentView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//  Last Modified by 冷月 on 2025/5/5.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

struct NotchContentView: View
{
    @StateObject var vm: NotchViewModel

    @State private var selectedTab = 0
    private let pageCount = 3

    var body: some View
    {
        ZStack
        {
            switch vm.contentType
            {
            case .normal:
                PagerView(index: $selectedTab,
                          pages:
                          [
                              AnyView(
                                  HStack(spacing: vm.spacing)
                                  {
                                      ShareView(vm: vm, type: .airdrop)
                                      ShareView(vm: vm, type: .generic)
                                      TrayView(vm: vm)
                                  } // end of HStack
                              ),
                              AnyView(
                                  placeholderPage(title: "Media",
                                                  icon: "photo",
                                                  color: .blue)
                              ),
                              AnyView(
                                  placeholderPage(title: "Calendar",
                                                  icon: "calendar",
                                                  color: .red)
                              )
                          ]) // end of PagerView
                .transition(.scale(scale: 0.8).combined(with: .opacity))

            case .menu:
                NotchMenuView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))

            case .settings:
                NotchSettingsView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } // end of switch
        } // end of ZStack
        .animation(vm.animation, value: vm.contentType)
        .clipped() // 整體再裁切一次，保險

        // ★ 只新增這一行：把目前頁碼往上丟給父層（不改你的任何邏輯）
        .preference(key: CurrentPageKey.self, value: selectedTab)
    } // end of body

    private func handleSwipeGesture(value: DragGesture.Value)
    {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        if abs(horizontalAmount) > abs(verticalAmount) * 2
        {
            if horizontalAmount < -50
            {
                withAnimation(vm.animation)
                {
                    selectedTab = min(selectedTab + 1, 2)
                }
            }
            else if horizontalAmount > 50
            {
                withAnimation(vm.animation)
                {
                    selectedTab = max(selectedTab - 1, 0)
                }
            }
        }
    } // end of handleSwipeGesture

    private func placeholderPage(title: String,
                                 icon: String,
                                 color: Color) -> some View
    {
        VStack(spacing: 12)
        {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            Text("Coming Soon")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        } // end of VStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(vm.cornerRadius)
    } // end of placeholderPage
} // end of struct NotchContentView

#Preview
{
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}

