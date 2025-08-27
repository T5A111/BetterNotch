//
//  CurrentPageKey.swift
//  NotchDrop
//
//  Created by 小孟 on 2025/8/25.
//

import SwiftUI

struct CurrentPageKey: PreferenceKey
{
    static var defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int)
    {
        value = nextValue()
    } // end of reduce
} // end of CurrentPageKey
