//
//  String+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import Foundation

extension String {
    
    func toTimeInterval() -> TimeInterval? {
        let timeComponents = components(separatedBy: ":")
        var result = Double.zero
        for (index, time) in timeComponents.reversed().enumerated() {
            guard let timeInvertal = TimeInterval(time) else {
                return nil
            }
            result += timeInvertal * pow(60, Double(index))
        }
        return result
    }
}

extension String {
    
    func equalsToIgnoreCase(_ string: String) -> Bool {
        lowercased() == string.lowercased()
    }
    
    func formatCString(_ string: String) -> String {
        replacingOccurrences(of: "%s", with: string)
    }
}
