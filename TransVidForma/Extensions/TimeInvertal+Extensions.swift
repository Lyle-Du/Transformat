//
//  TimeInvertal+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import Foundation

extension TimeInterval {
    
    func toTimeString() -> String? {
        
        guard let roundedToMillionseconds = Double(String(format: "%.6f", self)) else {
            return nil
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        
        if let formatted = formatter.string(from: roundedToMillionseconds) {
            let fraction = String(format: "%.6f", truncatingRemainder(dividingBy: 1))
            let truncatingFraction = fraction.split(separator: ".").last
            return [formatted, String(truncatingFraction ?? "000000")].joined(separator: ".")
        }
        return nil
    }
}
