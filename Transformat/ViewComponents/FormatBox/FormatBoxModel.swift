//
//  FormatBoxModel.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

import Foundation

import RxCocoa
import RxSwift
import VLCKit

final class FormatBoxModel {
    
    let outputPath: Driver<String>
    let selectedFormatIndex: Driver<Int>
    let formatTitles = ContainerFormat.allCases.map { $0.titleWithFileExtension }
    
    private let mediaPlayer: VLCMediaPlayer
    private let savePanel: NSSavePanel
    private let userDefaults: UserDefaults
    
    private let disposeBag = DisposeBag()
    private let outputPathRelay = BehaviorRelay<URL?>(value: nil)
    private let selectedFormatRelay: BehaviorRelay<ContainerFormat>
    
    init(
        mediaPlayer: VLCMediaPlayer,
        savePanel: NSSavePanel = NSSavePanel(),
        userDefaults: UserDefaults = .standard)
    {
        self.mediaPlayer = mediaPlayer
        self.savePanel = savePanel
        self.userDefaults = userDefaults
        
        savePanel.allowedFileTypes = ContainerFormat.allCases.map(\.rawValue)
        savePanel.allowsOtherFileTypes = false
        savePanel.showsTagField = false
        
        if
            let selectedFormatString = userDefaults.string(forKey: StoreKeys.selectedFormat),
            let selectedFormat = ContainerFormat(rawValue: selectedFormatString)
        {
            selectedFormatRelay = BehaviorRelay<ContainerFormat>(value: selectedFormat)
        } else {
            selectedFormatRelay = BehaviorRelay<ContainerFormat>(value: .gif)
        }
        
        selectedFormatIndex = selectedFormatRelay.distinctUntilChanged()
            .compactMap { ContainerFormat.allCases.firstIndex(of: $0) }
            .asDriver(onErrorJustReturn: 0)
        
        outputPath = outputPathRelay.asDriver().map { $0?.path ?? "" }
        
        let selectedFormat = selectedFormatRelay.distinctUntilChanged()
        
        disposeBag.insert([
            selectedFormat.map { [$0.rawValue] }.bind(to: savePanel.rx.allowedFileTypes),
            selectedFormat.subscribe(onNext: { [userDefaults, outputPathRelay] selected in
                userDefaults.set(selected.rawValue, forKey: StoreKeys.selectedFormat)
                outputPathRelay.accept(nil)
            }),
        ])
    }
    
    func setOutputPath() {
        let url = mediaPlayer.media?.url?.deletingPathExtension().appendingPathExtension(selectedFormatRelay.value.rawValue)
        savePanel.nameFieldStringValue = "Untitled.\(selectedFormatRelay.value.rawValue)"
        if let filename = url?.lastPathComponent {
            savePanel.nameFieldStringValue = filename
        }
        
        if savePanel.runModal() == .OK {
            guard var url = savePanel.url else { return }
            if let format = ContainerFormat(rawValue: url.pathExtension) {
                selectedFormatRelay.accept(format)
            } else {
                url.deletePathExtension()
                url.appendPathExtension(selectedFormatRelay.value.rawValue)
            }
            outputPathRelay.accept(url)
        }
    }
}

extension FormatBoxModel {
    
    struct StoreKeys {
        static let selectedFormat = "FormatBoxModel.StoreKeys.selectedFormat"
    }
}

extension FormatBoxModel {
    
    var selectedIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            let selected = ContainerFormat.allCases[index]
            guard selected != target.selectedFormatRelay.value else {
                return
            }
            target.selectedFormatRelay.accept(selected)
            target.outputPathRelay.accept(nil)
        }
    }
}

extension FormatBoxModel {
    
    var fileURL: URL? {
        outputPathRelay.value
    }
    
    var format: ContainerFormat {
        selectedFormatRelay.value
    }
}
