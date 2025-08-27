//
//  NotchView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchView: View
{
    @StateObject var vm: NotchViewModel

    @State var dropTargeting: Bool = false

    // ★ 接住內容區傳上的目前頁碼
    @State private var currentPage: Int = 0   // 只用來顯示點點，不改內容邏輯
    private let pageCount: Int = 3            // 與內容區一致

    var notchSize: CGSize
    {
        switch vm.status
        {
        case .closed:
            var ans = CGSize(
                width: vm.deviceNotchRect.width - 4,
                height: vm.deviceNotchRect.height - 4
            )
            if ans.width < 0 { ans.width = 0 }
            if ans.height < 0 { ans.height = 0 }
            return ans
        case .opened:
            return vm.notchOpenedSize
        case .popping:
            return .init(
                width: vm.deviceNotchRect.width,
                height: vm.deviceNotchRect.height + 4
            )
        }
    } // end of notchSize

    var notchCornerRadius: CGFloat
    {
        switch vm.status
        {
        case .closed: 8
        case .opened: 32
        case .popping: 10
        }
    } // end of notchCornerRadius

    var body: some View
    {
        ZStack(alignment: .top)
        {
            notch
                .zIndex(0)
                .disabled(true)
                .opacity(vm.notchVisible ? 1 : 0.3)

            Group
            {
                if vm.status == .opened
                {
                    VStack(spacing: vm.spacing)
                    {
                        NotchHeaderView(vm: vm)   // Text("簡放島") 需已加 anchorPreference
                        NotchContentView(vm: vm)  // 內部用 .preference(CurrentPageKey, selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } // end of VStack
                    .padding(vm.spacing)
                    .frame(maxWidth: vm.notchOpenedSize.width,
                           maxHeight: vm.notchOpenedSize.height)
                    .zIndex(1)
                }
            } // end of Group
            .transition(
                .scale.combined(with: .opacity)
                    .combined(with: .offset(y: -vm.notchOpenedSize.height / 2))
                    .animation(vm.animation)
            )
        } // end of ZStack
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        // ★ 接收內容區的目前頁碼（單向資料流）
        .onPreferenceChange(CurrentPageKey.self)
        { value in
            self.currentPage = value
        }

        // ★ 用標題錨點把點點畫在標題右邊（僅顯示，不攔截事件）
        .overlayPreferenceValue(TitleAnchorKey.self)
        { anchor in
            GeometryReader
            { proxy in
                if let a = anchor
                {
                    let rect = proxy[a]

                    // ===== 可微調參數 =====
                    let spacingToTitle: CGFloat = 30  // 與標題右側距離（8~20）
                    let scale: CGFloat = 0.8           // 點點縮放（0.9~1.2）
                    // =====================

                    DotsIndicator(pageCount: pageCount,
                                  selection: .constant(currentPage)) // 只讀顯示
                        .scaleEffect(scale)
                        .position(
                            x: rect.maxX + spacingToTitle,  // 標題右側
                            y: rect.midY                    // 水平對齊標題
                        )
                        .allowsHitTesting(false)
                }
            } // end of GeometryReader
        } // end of overlayPreferenceValue
    } // end of body

    var notch: some View
    {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: notchSize.width + notchCornerRadius * 2,
                height: notchSize.height
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
                radius: 16
            )
    } // end of notch

    var notchBackgroundMaskGroup: some View
    {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchSize.width,
                height: notchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            .overlay
            {
                ZStack(alignment: .topTrailing)
                {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                } // end of ZStack
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - vm.spacing + 0.5, y: -0.5)
            } // end of overlay
            .overlay
            {
                ZStack(alignment: .topLeading)
                {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                } // end of ZStack
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + vm.spacing - 0.5, y: -0.5)
            } // end of overlay
    } // end of notchBackgroundMaskGroup

    @ViewBuilder
    var dragDetector: some View
    {
        RoundedRectangle(cornerRadius: notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))
            .contentShape(Rectangle())
            .frame(width: notchSize.width + vm.dropDetectorRange,
                   height: notchSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting)
            { isTargeted in
                if isTargeted, vm.status == .closed
                {
                    vm.notchOpen(.drag)
                    vm.hapticSender.send()
                }
                else if !isTargeted
                {
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset)
                        .contains(mouseLocation)
                    {
                        vm.notchClose()
                    }
                }
            } // end of onChange
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    } // end of dragDetector
} // end of struct NotchView

