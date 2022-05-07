//
//  Rx+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 8/5/22.
//

import RxCocoa

extension Driver {
    
    func mapToOptional() -> SharedSequence<SharingStrategy, Element?> {
        return self.map { Optional($0) }
    }
}
