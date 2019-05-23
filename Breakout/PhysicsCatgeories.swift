//
//  PhysicsCatgeories.swift
//  Breakout
//
//  Created by James Ortiz on 5/11/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import Foundation

struct PhysicsCategories {
    static let none: UInt32 = 0
    static let paddle: UInt32 = 1
    static let ball: UInt32 = 1 << 1
    static let tile: UInt32 = 1 << 2
    static let boundary: UInt32 = 1 << 3
    static let bottom: UInt32 = 1 << 4
}
