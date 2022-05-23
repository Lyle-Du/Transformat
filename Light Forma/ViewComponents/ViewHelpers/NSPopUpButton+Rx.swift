//
//  NSPopUpButton+Rx.swift
//  Transformat
//
//  Created by QIU DU on 2/5/22.
//

import RxCocoa
import RxSwift

extension Reactive where Base: NSPopUpButton {
    
    var selectedIndex: ControlProperty<Int> {
        base.rx.controlProperty(
            getter: { control in
                control.indexOfSelectedItem
            }, setter: { control, index in
                control.selectItem(at: index)
            }
        )
    }
}
