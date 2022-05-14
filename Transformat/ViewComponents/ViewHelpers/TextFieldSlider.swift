//
//   Created by QIU DU on 14/5/22
//
//   Copyright © 2022 Qiu Du. All rights reserved.
//

import RxCocoa
import RxSwift

final class TextFieldSlider: NSControl {
    
    private(set) lazy var value: Driver<Double> = {
        Observable.merge(
            slider.rx.value.asObservable(),
            textDoubleValue)
        .map { $0 }
        .asDriver(onErrorJustReturn: slider.minValue)
    }()
    
    var stringFormat = "%.2f"
    
    let slider: NSSlider = {
        let slider = NSSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    let textField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let container: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let disposeBag = DisposeBag()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private let textDoubleValue = PublishSubject<Double>()
    
    private func commonInit() {
        container.addArrangedSubview(slider)
        container.addArrangedSubview(textField)
        addSubview(container)
        container.pinEdgesTo(view: self)
        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8),
        ])
        
        disposeBag.insert([
            slider.rx.value
                .map { [weak self] value in
                    guard let self = self else { return "" }
                    return String(format: self.stringFormat, value)
                }
                .asObservable()
                .subscribe(textField.rx.stringValue),
            
            textField.rx.didEndEditingText
                .compactMap { string -> Double? in
                    guard let string = string else { return nil }
                    return Double(string)
                }
                .map { [slider] in
                    $0.clamped(to: slider.minValue...slider.maxValue)
                }
                .subscribe(textDoubleValue),
        ])
    }
}

extension TextFieldSlider {
    
    var valueBinder: Binder<Double> {
        Binder(self) { target, value in
            let value = value.clamped(to: target.slider.minValue...target.slider.maxValue)
            target.slider.doubleValue = value
            target.textField.stringValue = String(format: target.stringFormat, value)
        }
    }
}
