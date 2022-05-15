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
        ControlEvent(events: self.delegate.methodInvoked(#selector(NSTextFieldDelegate.controlTextDidEndEditing(_:))).map { _ in () })
    }
    
    var didEndEditingText: Observable<String?> {
        didEndEditing.withLatestFrom(base.rx.text)
    }
}
