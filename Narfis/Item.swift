//
//  Item.swift
//  Narfis
//
//  Created by HashtagPro on 6/27/26.
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
