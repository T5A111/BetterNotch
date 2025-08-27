//
//  PagerView.swift
//  NotchDrop
//
//  Created by 小孟 on 2025/8/24.
//

import SwiftUI
import AppKit

/// 單次手勢最多翻一頁的 PagerView（macOS）
/// - 修正：不從 momentum 開新會話、方向鎖、會話冷卻
/// - 行為：進行中只「跟手」，手勢結束「一次判斷」是否翻頁
struct PagerView<Content: View>: View
{
    @Binding var index: Int
    let pages: [Content]

    // ===== 可調參數（直接改數字即可） =====
    private let scrollGain: CGFloat = 8.0              // 兩指靈敏度（建議 1.0 ~ 2.0；>5 超高敏）
    private let maxStepRatioPerFrame: CGFloat = 0.18   // 單幀位移上限（× 寬；0.15 ~ 0.22）
    private let snapWindowRatio: CGFloat = 0.09        // 中線吸附窗（× 寬；0.06 ~ 0.12）
    private let decisionRatio: CGFloat = 0.20          // 翻頁門檻（× 寬；0.18 ~ 0.25）
    private let springResponse: CGFloat = 0.22         // 回彈彈簧（0.18 ~ 0.26）
    private let springDamping: CGFloat  = 0.94         // 回彈阻尼（0.88 ~ 0.98）

    private let directionEpsilonPx: CGFloat = 6.0      // 鎖定方向的最小位移（px；4 ~ 8）
    private let cooldownMs: Double = 80.0              // 會話冷卻時間（ms；60 ~ 120）
    // ===================================

    // 滑鼠拖曳（視覺跟手）
    @GestureState private var dragOffset: CGFloat = 0

    // 兩指滑（視覺跟手）
    @State private var scrollDragOffset: CGFloat = 0

    // —— 會話鎖：一次手勢最多只翻一頁 —— //
    private enum InputMode
    {
        case none, drag, scroll
    } // end of InputMode

    private enum Dir
    {
        case unknown, left, right
    } // end of Dir

    @State private var inputMode: InputMode = .none
    @State private var didCommit: Bool = false
    @State private var endGuardArmed: Bool = false

    // 方向鎖（本次手勢）
    @State private var lockedDir: Dir = .unknown

    // 會話冷卻：在這個時間點之前，拒絕開始新會話
    @State private var cooldownUntil: Date = .distantPast

    init(index: Binding<Int>, pages: [Content])
    {
        self._index = index
        self.pages = pages
    } // end of init

    var body: some View
    {
        GeometryReader
        { geo in
            let width = max(1, geo.size.width)
            let decision = width * decisionRatio
            let snapWin  = width * snapWindowRatio
            let maxStep  = width * maxStepRatioPerFrame

            ZStack
            {
                HStack(spacing: 0)
                {
                    ForEach(pages.indices, id: \.self)
                    { i in
                        pages[i]
                            .frame(width: width,
                                   height: geo.size.height,
                                   alignment: .center)
                            .clipped()
                    } // end of ForEach
                } // end of HStack
                .offset(x: -CGFloat(index) * width
                            + dragOffset
                            + scrollDragOffset)
                .animation(.interactiveSpring(response: springResponse,
                                              dampingFraction: springDamping,
                                              blendDuration: 0.12),
                           value: index)

                // 滑鼠拖曳：整個手勢只在結束時判斷一次
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .local)
                        .onChanged
                        { _ in
                            if inputMode == .none && Date() >= cooldownUntil
                            {
                                beginNewSession(mode: .drag)
                            }
                        } // end of onChanged
                        .updating($dragOffset)
                        { value, state, _ in
                            guard inputMode == .drag else { return }
                            var proposed = value.translation.width

                            // 方向鎖：一旦鎖定，不允許穿越 0（只能靠近 0，不可跨越反向）
                            lockDirectionIfNeeded(total: proposed)
                            proposed = clampByDirection(proposed)

                            // 邊界限制：最前/最後一頁不可再往外拉
                            proposed = applyEdgeLimits(proposed, pageWidth: width)

                            // 中線吸附（僅吸回當前頁中心）
                            if abs(proposed) < snapWin
                            {
                                proposed = 0
                            }

                            state = proposed
                        } // end of updating
                        .onEnded
                        { value in
                            guard inputMode == .drag, endGuardArmed else { return }
                            endGuardArmed = false
                            let total = clampByDirection(value.translation.width)
                            commitOnce(total: total, threshold: decision)
                            resetSession()
                        } // end of onEnded
                ) // end of gesture
                .clipped()

                // 兩指滑：整個手勢只在結束時判斷一次
                TrackpadSwipeCatcher
                { rawDX, phase, momentum in
                    // 僅允許非 momentum 的 began/changed 開新會話
                    if inputMode == .none
                        && Date() >= cooldownUntil
                        && (phase.contains(.began)
                            || (phase.contains(.changed) && momentum.isEmpty))
                    {
                        beginNewSession(mode: .scroll)
                    }

                    // 僅在 scroll 主導時處理
                    guard inputMode == .scroll else { return }

                    if phase.contains(.began) || phase.contains(.changed)
                    {
                        // 靈敏度 + 單幀夾值，避免暴衝
                        let dxRaw = rawDX * scrollGain
                        let dx = max(-maxStep, min(maxStep, dxRaw))

                        var proposed = scrollDragOffset + dx

                        // 鎖定方向，並依鎖方向限制不可穿越 0
                        lockDirectionIfNeeded(total: proposed)
                        proposed = clampByDirection(proposed)

                        // 邊界限制：最前/最後一頁不可再往外拉
                        proposed = applyEdgeLimits(proposed, pageWidth: width)

                        // 中線吸附（僅吸回當前頁中心）
                        if abs(proposed) < snapWin
                        {
                            proposed = 0
                        }

                        scrollDragOffset = proposed
                        return
                    }

                    // 注意：trackpad 常會有 phase 與 momentum 各觸發一次 ended
                    if phase.contains(.ended) || momentum.contains(.ended)
                    {
                        guard endGuardArmed else { return }
                        endGuardArmed = false

                        let total = clampByDirection(scrollDragOffset)
                        commitOnce(total: total, threshold: decision)
                        resetSession()
                    }
                } // end of TrackpadSwipeCatcher
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            } // end of ZStack
            .clipped()
        } // end of GeometryReader
    } // end of body

    // MARK: - 會話控制
    private func beginNewSession(mode: InputMode)
    {
        inputMode = mode
        didCommit = false
        endGuardArmed = true
        lockedDir = .unknown
    } // end of beginNewSession

    // MARK: - 一次手勢只允許 commit 一次
    private func commitOnce(total: CGFloat, threshold: CGFloat)
    {
        guard !didCommit else { return }

        if total <= -threshold
        {
            index = min(index + 1, pages.count - 1) // 左滑 → 下一頁（+1）
        }
        else if total >= threshold
        {
            index = max(index - 1, 0)               // 右滑 → 上一頁（-1）
        }
        // 介於閾值內 → 回彈到原頁（由 index 綁定動畫處理）

        didCommit = true
        // 進入會話冷卻：短時間內不允許新會話啟動，避免放手瞬間又開新回合
        cooldownUntil = Date().addingTimeInterval(cooldownMs / 1000.0)
    } // end of commitOnce

    // MARK: - 清理本次手勢狀態（不要在此解 didCommit）
    private func resetSession()
    {
        scrollDragOffset = 0
        inputMode = .none
        lockedDir = .unknown
        // GestureState 的 dragOffset 由系統歸零 // end of resetSession
    } // end of resetSession

    // MARK: - 方向鎖工具
    private func lockDirectionIfNeeded(total: CGFloat)
    {
        if lockedDir == .unknown
        {
            if total <= -directionEpsilonPx
            {
                lockedDir = .left
            }
            else if total >= directionEpsilonPx
            {
                lockedDir = .right
            }
        }
    } // end of lockDirectionIfNeeded

    private func clampByDirection(_ proposed: CGFloat) -> CGFloat
    {
        switch lockedDir
        {
        case .left:
            // 允許往負向移動，若回彈只允許回到 0，不可穿越為正
            return min(0, proposed)
        case .right:
            // 允許往正向移動，若回彈只允許回到 0，不可穿越為負
            return max(0, proposed)
        case .unknown:
            return proposed
        }
    } // end of clampByDirection

    // MARK: - 邊界限制
    private func applyEdgeLimits(_ proposed: CGFloat, pageWidth: CGFloat) -> CGFloat
    {
        let canGoPrev = index > 0
        let canGoNext = index < pages.count - 1
        let leftLimit: CGFloat  = canGoPrev ?  pageWidth : 0    // 右滑為正
        let rightLimit: CGFloat = canGoNext ? -pageWidth : 0    // 左滑為負

        var v = proposed
        v = min(v,  leftLimit)
        v = max(v, rightLimit)
        return v
    } // end of applyEdgeLimits
} // end of struct PagerView





