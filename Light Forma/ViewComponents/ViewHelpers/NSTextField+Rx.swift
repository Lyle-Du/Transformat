//
//  NSTextField+Rx.swift
//  Transformat
//
//  Created by QIU DU on 8/5/22.
//

import RxCocoa
import RxSwift

extension Reactive where Base: NSTextField {
    /// Reactive wrapper for `delegate` message.
    var didEndEditing: ControlEvent<()> {
        return ControlEvent(events: self.delegate.methodInvoked(#selector(NSTextFieldDelegate.controlTextDidEndEditing(_:))).map { _ in () })
    }
    
    var didEndEditingText: Observable<String?> {
        return didEndEditing.withLatestFrom(base.rx.text)
    }
}
