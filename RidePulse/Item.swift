//
//  Item.swift
//  RidePulse
//
//  Created by Syed Hasnain Bukhari on 13/1/2569 BE.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
