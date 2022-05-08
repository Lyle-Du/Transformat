//
//  UnitStorage.swift
//  Transformat
//
//  Created by QIU DU on 8/5/22.
//

import Foundation

final class UnitStorage: Dimension {
    
    override static func baseUnit() -> UnitStorage {
        return self.bytes
    }
    
    static let gigabytes: UnitStorage = UnitStorage(symbol: "GB", converter: UnitConverterLinear(coefficient: pow(10, 9)))

    static let megabytes: UnitStorage = UnitStorage(symbol: "MB", converter: UnitConverterLinear(coefficient: pow(10, 6)))

    static let kilobytes: UnitStorage = UnitStorage(symbol: "KB", converter: UnitConverterLinear(coefficient: pow(10, 3)))
    
    static let bytes: UnitStorage = UnitStorage(symbol: "Bytes", converter: UnitConverterLinear(coefficient: 1))
    
    static let bits: UnitStorage = UnitStorage(symbol: "bits", converter: UnitConverterLinear(coefficient: 1 / 8))
}

extension UnitStorage: CaseIterable {
    
    static let allCases: [UnitStorage] = [.gigabytes, .megabytes, .kilobytes, .bytes, .bits]
}
