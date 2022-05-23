//
//  ClosedRange+Extensions.swift
//  TransVidForma
//
//  Created by QIU DU on 16/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

extension ClosedRange where Bound: AdditiveArithmetic {
    
    var interval: Bound {
        upperBound - lowerBound
    }
}

extension ClosedRange where Bound == Double {
    
    var mid: Bound {
        (upperBound + lowerBound) * 0.5
    }
}
