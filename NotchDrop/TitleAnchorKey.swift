//
//  TitleAnchorKey.swift
//  NotchDrop
//
//  Created by 小孟 on 2025/8/25.
//

import SwiftUI

struct TitleAnchorKey: PreferenceKey
{
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?,
                       nextValue: () -> Anchor<CGRect>?)
    {
        value = nextValue() ?? value
    } // end of reduce
} // end of TitleAnchorKey
