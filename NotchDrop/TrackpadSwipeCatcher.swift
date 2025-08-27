//
//  TrackpadSwipeCatcher.swift
//  NotchDrop
//
//  Created by 小孟 on 2025/8/24.
//

import SwiftUI
import AppKit

struct TrackpadSwipeCatcher: NSViewRepresentable
{
    // 直接回傳 dx（不再取負號），讓方向與上一版相反
    var onScroll: (_ dx: CGFloat, _ phase: NSEvent.Phase, _ momentum: NSEvent.Phase) -> Void

    func makeNSView(context: Context) -> NSView
    {
        return CatcherView(onScroll: onScroll)
    } // end of makeNSView

    func updateNSView(_ nsView: NSView, context: Context)
    {
        // 無需更新 // end of updateNSView
    } // end of updateNSView

    // MARK: - NSView subclass
    final class CatcherView: NSView
    {
        private var onScroll: (_ dx: CGFloat,
                               _ phase: NSEvent.Phase,
                               _ momentum: NSEvent.Phase) -> Void
        private var monitor: Any?
        private var inside: Bool = false

        init(onScroll: @escaping (_ dx: CGFloat,
                                  _ phase: NSEvent.Phase,
                                  _ momentum: NSEvent.Phase) -> Void)
        {
            self.onScroll = onScroll
            super.init(frame: .zero)
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
            addTrackingArea(
                NSTrackingArea(rect: bounds,
                               options: [.mouseEnteredAndExited,
                                         .activeAlways,
                                         .inVisibleRect],
                               owner: self,
                               userInfo: nil)
            )
        } // end of init

        @available(*, unavailable)
        required init?(coder: NSCoder)
        {
            fatalError("init(coder:) has not been implemented")
        } // end of required

        override func updateTrackingAreas()
        {
            super.updateTrackingAreas()
            trackingAreas.forEach { removeTrackingArea($0) }
            addTrackingArea(
                NSTrackingArea(rect: bounds,
                               options: [.mouseEnteredAndExited,
                                         .activeAlways,
                                         .inVisibleRect],
                               owner: self,
                               userInfo: nil)
            )
        } // end of updateTrackingAreas

        override func mouseEntered(with event: NSEvent)
        {
            inside = true
            installMonitorIfNeeded()
        } // end of mouseEntered

        override func mouseExited(with event: NSEvent)
        {
            inside = false
            removeMonitorIfNeeded()
        } // end of mouseExited

        private func installMonitorIfNeeded()
        {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel)
            { [weak self] event in
                guard let self = self, self.inside else
                {
                    return event
                }

                let dx = event.hasPreciseScrollingDeltas
                    ? event.scrollingDeltaX
                    : event.deltaX

                // 直接用 dx（與上一版相反方向）
                self.onScroll(dx, event.phase, event.momentumPhase)
                return nil
            }
        } // end of installMonitorIfNeeded

        private func removeMonitorIfNeeded()
        {
            if let monitor
            {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        } // end of removeMonitorIfNeeded

        deinit
        {
            removeMonitorIfNeeded()
        } // end of deinit
    } // end of CatcherView
} // end of TrackpadSwipeCatcher



