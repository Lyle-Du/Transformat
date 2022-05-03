//
//  Comparable+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

extension Comparable {
    
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
